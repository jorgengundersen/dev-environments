import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Project-local shell command guard for pi.
 *
 * Auto-loaded from .pi/extensions/.
 *
 * Goals:
 * - keep the policy easy to extend for other commands later
 * - block both LLM bash tool calls and user ! / !! shell commands
 * - default-block GitHub CLI (gh) except a small non-destructive allowlist
 * - default-allow git, but block force-push variants
 *
 * Notes:
 * - Shell parsing here is intentionally best-effort. It handles common command
 *   separators, simple quoting, env assignments, common wrapper commands, and
 *   one level of nested shell indirection such as `bash -lc '...'`.
 * - This is a workflow guard, not a hard sandbox. Other extensions can still
 *   execute arbitrary code via pi.exec().
 */

type CommandMatch = {
  executable: string;
  argv: string[];
  segment: string;
};

type PolicyViolation = {
  policyName: string;
  reason: string;
  segment: string;
};

type CommandPolicy =
  | {
      name: string;
      mode: "defaultBlock";
      executable: string;
      summary: string;
      isAllowed: (match: CommandMatch) => boolean;
    }
  | {
      name: string;
      mode: "defaultAllow";
      executable: string;
      summary: string;
      isBlocked: (match: CommandMatch) => boolean;
    };

const MAX_RECURSION_DEPTH = 3;

const ghAllowedCommandSummary = [
  "gh --version",
  "gh help",
  "gh auth status",
  "gh repo view",
  "gh issue list",
  "gh issue view",
  "gh pr list",
  "gh pr view",
  "gh release list",
].join(", ");

const commandPolicies: CommandPolicy[] = [
  {
    name: "gh-default-block",
    mode: "defaultBlock",
    executable: "gh",
    summary: `Block gh by default. Allowed exceptions: ${ghAllowedCommandSummary}.`,
    isAllowed: (match) => isAllowedGhCommand(match.argv),
  },
  {
    name: "git-push-mutation-block",
    mode: "defaultAllow",
    executable: "git",
    summary:
      "Allow git by default, but block destructive git push variants: -f, --force, --force-with-lease, --force-if-includes, --mirror, --delete, :branch deletion refspecs, and +refspec forms.",
    isBlocked: (match) => isBlockedGitPushMutation(match.argv),
  },
  {
    name: "terraform-apply-destroy-block",
    mode: "defaultAllow",
    executable: "terraform",
    summary: "Allow terraform by default, but block terraform apply and terraform destroy.",
    isBlocked: (match) => isBlockedTerraformMutation(match.argv),
  },
  {
    name: "kubectl-apply-block",
    mode: "defaultAllow",
    executable: "kubectl",
    summary: "Allow kubectl by default, but block kubectl apply.",
    isBlocked: (match) => isBlockedKubectlApply(match.argv),
  },
];

function splitShellSegments(script: string): string[] {
  const segments: string[] = [];
  let current = "";
  let quote: "'" | '"' | null = null;
  let escaped = false;

  const flush = () => {
    const trimmed = current.trim();
    if (trimmed) {
      segments.push(trimmed);
    }
    current = "";
  };

  for (let i = 0; i < script.length; i += 1) {
    const ch = script[i]!;
    const next = script[i + 1] ?? "";

    if (escaped) {
      current += ch;
      escaped = false;
      continue;
    }

    if (ch === "\\" && quote !== "'") {
      current += ch;
      escaped = true;
      continue;
    }

    if (quote) {
      current += ch;
      if (ch === quote) {
        quote = null;
      }
      continue;
    }

    if (ch === "'" || ch === '"') {
      current += ch;
      quote = ch;
      continue;
    }

    if (ch === "\n" || ch === ";") {
      flush();
      continue;
    }

    if ((ch === "&" && next === "&") || (ch === "|" && next === "|")) {
      flush();
      i += 1;
      continue;
    }

    if (ch === "|") {
      flush();
      continue;
    }

    current += ch;
  }

  flush();
  return segments;
}

function tokenizeShell(segment: string): string[] {
  const tokens: string[] = [];
  let current = "";
  let quote: "'" | '"' | null = null;
  let escaped = false;

  const flush = () => {
    if (current !== "") {
      tokens.push(current);
      current = "";
    }
  };

  for (let i = 0; i < segment.length; i += 1) {
    const ch = segment[i]!;

    if (escaped) {
      current += ch;
      escaped = false;
      continue;
    }

    if (quote === "'") {
      if (ch === "'") {
        quote = null;
      } else {
        current += ch;
      }
      continue;
    }

    if (quote === '"') {
      if (ch === '"') {
        quote = null;
      } else if (ch === "\\") {
        escaped = true;
      } else {
        current += ch;
      }
      continue;
    }

    if (/\s/.test(ch)) {
      flush();
      continue;
    }

    if (ch === "'") {
      quote = ch;
      continue;
    }

    if (ch === '"') {
      quote = ch;
      continue;
    }

    if (ch === "\\") {
      escaped = true;
      continue;
    }

    current += ch;
  }

  flush();
  return tokens;
}

function isEnvAssignment(token: string): boolean {
  return /^[A-Za-z_][A-Za-z0-9_]*=/.test(token);
}

function unwrapOptionWrapper(
  tokens: string[],
  optionsWithArgument: string[] = [],
  longOptionsWithArgument: string[] = [],
): string[] {
  const optionsWithArgumentSet = new Set(optionsWithArgument);
  let i = 0;

  while (i < tokens.length) {
    const token = tokens[i]!;

    if (token === "--") {
      return tokens.slice(i + 1);
    }

    if (optionsWithArgumentSet.has(token)) {
      i += 2;
      continue;
    }

    if (longOptionsWithArgument.some((option) => token.startsWith(`${option}=`))) {
      i += 1;
      continue;
    }

    if (token.startsWith("-")) {
      i += 1;
      continue;
    }

    return tokens.slice(i);
  }

  return [];
}

function unwrapEnv(tokens: string[]): string[] {
  let i = 0;
  while (i < tokens.length) {
    const token = tokens[i]!;

    if (token === "--") {
      return tokens.slice(i + 1);
    }

    if (token === "-u" || token === "--unset") {
      i += 2;
      continue;
    }

    if (token.startsWith("-")) {
      i += 1;
      continue;
    }

    if (isEnvAssignment(token)) {
      i += 1;
      continue;
    }

    return tokens.slice(i);
  }

  return [];
}

function unwrapLeadingWrappers(tokens: string[]): string[] | null {
  let remaining = [...tokens];

  while (remaining.length > 0) {
    if (isEnvAssignment(remaining[0]!)) {
      remaining = remaining.slice(1);
      continue;
    }

    switch (remaining[0]) {
      case "env":
        remaining = unwrapEnv(remaining.slice(1));
        continue;
      case "command":
      case "builtin":
      case "noglob":
      case "nocorrect":
      case "time":
      case "nohup":
        remaining = remaining.slice(1);
        continue;
      case "sudo":
        remaining = unwrapOptionWrapper(remaining.slice(1), ["-u", "-g", "-h", "-p", "-C", "-T", "-r", "-t"], [
          "--user",
          "--group",
          "--host",
          "--prompt",
          "--close-from",
          "--command-timeout",
          "--chdir",
        ]);
        continue;
      case "doas":
        remaining = unwrapOptionWrapper(remaining.slice(1), ["-u"], ["--user"]);
        continue;
      case "nice":
        remaining = unwrapOptionWrapper(remaining.slice(1), ["-n"], ["--adjustment"]);
        continue;
      case "ionice":
        remaining = unwrapOptionWrapper(remaining.slice(1), ["-c", "-n", "-t", "-p", "-P"], ["--class", "--classdata", "--pid", "--pgid"]);
        continue;
      case "chrt":
        remaining = unwrapOptionWrapper(remaining.slice(1), ["-p", "-P", "-T", "-D"], ["--pid", "--max", "--sched-runtime", "--sched-deadline", "--sched-period"]);
        continue;
      case "stdbuf":
        remaining = unwrapOptionWrapper(remaining.slice(1), ["-i", "-o", "-e"], []);
        continue;
      case "timeout":
        remaining = unwrapOptionWrapper(remaining.slice(1), ["-k", "-s", "--kill-after", "--signal"], []);
        continue;
      default:
        return remaining.length > 0 ? remaining : null;
    }
  }

  return remaining.length > 0 ? remaining : null;
}

function extractCommandMatch(segment: string): CommandMatch | null {
  const tokens = tokenizeShell(segment);
  const argv = unwrapLeadingWrappers(tokens);
  if (!argv || argv.length === 0) {
    return null;
  }

  return {
    executable: argv[0]!,
    argv,
    segment,
  };
}

function extractNestedShellCommand(match: CommandMatch): string | null {
  if (!["bash", "sh", "dash", "zsh", "fish"].includes(match.executable)) {
    return null;
  }

  const args = match.argv.slice(1);
  for (let i = 0; i < args.length; i += 1) {
    const token = args[i]!;

    if (token === "--") {
      return null;
    }

    if (token === "-c" || token === "--command") {
      return args[i + 1] ?? null;
    }

    if (/^-[^-]*c[^-]*$/.test(token)) {
      return args[i + 1] ?? null;
    }

    if (token.startsWith("-")) {
      continue;
    }

    return null;
  }

  return null;
}

function stripGhGlobalOptions(args: string[]): string[] {
  let i = 0;
  while (i < args.length) {
    const token = args[i]!;

    if (token === "--") {
      return args.slice(i + 1);
    }

    if (token === "version" || token === "--version" || token === "help" || token === "--help" || token === "-h") {
      return args.slice(i);
    }

    if (token === "-R" || token === "--repo" || token === "--hostname") {
      i += 2;
      continue;
    }

    if (token.startsWith("--repo=") || token.startsWith("--hostname=")) {
      i += 1;
      continue;
    }

    if (token.startsWith("-")) {
      i += 1;
      continue;
    }

    break;
  }

  return args.slice(i);
}

function matchesPrefix(actual: string[], expected: string[]): boolean {
  if (actual.length < expected.length) {
    return false;
  }

  return expected.every((part, index) => actual[index] === part);
}

function isAllowedGhCommand(argv: string[]): boolean {
  const commandPath = stripGhGlobalOptions(argv.slice(1));

  return (
    matchesPrefix(commandPath, ["version"]) ||
    matchesPrefix(commandPath, ["--version"]) ||
    matchesPrefix(commandPath, ["help"]) ||
    matchesPrefix(commandPath, ["--help"]) ||
    matchesPrefix(commandPath, ["-h"]) ||
    matchesPrefix(commandPath, ["auth", "status"]) ||
    matchesPrefix(commandPath, ["repo", "view"]) ||
    matchesPrefix(commandPath, ["issue", "list"]) ||
    matchesPrefix(commandPath, ["issue", "view"]) ||
    matchesPrefix(commandPath, ["pr", "list"]) ||
    matchesPrefix(commandPath, ["pr", "view"]) ||
    matchesPrefix(commandPath, ["release", "list"])
  );
}

function stripGitGlobalOptions(args: string[]): string[] {
  let i = 0;
  while (i < args.length) {
    const token = args[i]!;

    if (token === "--") {
      return args.slice(i + 1);
    }

    if (
      token === "-c" ||
      token === "-C" ||
      token === "--git-dir" ||
      token === "--work-tree" ||
      token === "--namespace" ||
      token === "--exec-path" ||
      token === "--super-prefix" ||
      token === "--config-env"
    ) {
      i += 2;
      continue;
    }

    if (
      token.startsWith("--git-dir=") ||
      token.startsWith("--work-tree=") ||
      token.startsWith("--namespace=") ||
      token.startsWith("--exec-path=") ||
      token.startsWith("--super-prefix=") ||
      token.startsWith("--config-env=")
    ) {
      i += 1;
      continue;
    }

    if (token.startsWith("-")) {
      i += 1;
      continue;
    }

    break;
  }

  return args.slice(i);
}

function isGitForceFlag(token: string): boolean {
  if (
    token === "--force" ||
    token.startsWith("--force=") ||
    token === "--force-with-lease" ||
    token.startsWith("--force-with-lease=") ||
    token === "--force-if-includes" ||
    token.startsWith("--force-if-includes=") ||
    token === "--mirror"
  ) {
    return true;
  }

  return /^-[^-]*f[^-]*$/.test(token);
}

function isGitDeletePushFlag(token: string): boolean {
  return token === "--delete";
}

function isGitDeleteRefspec(token: string): boolean {
  return /^:[^:]+$/.test(token);
}

function isBlockedGitPushMutation(argv: string[]): boolean {
  const gitArgs = stripGitGlobalOptions(argv.slice(1));
  if (gitArgs[0] !== "push") {
    return false;
  }

  return gitArgs.slice(1).some(
    (token) =>
      isGitForceFlag(token) ||
      isGitDeletePushFlag(token) ||
      isGitDeleteRefspec(token) ||
      token.startsWith("+"),
  );
}

function stripTerraformGlobalOptions(args: string[]): string[] {
  let i = 0;
  while (i < args.length) {
    const token = args[i]!;

    if (token === "--") {
      return args.slice(i + 1);
    }

    if (token === "-chdir") {
      i += 2;
      continue;
    }

    if (token.startsWith("-chdir=")) {
      i += 1;
      continue;
    }

    if (token.startsWith("-")) {
      i += 1;
      continue;
    }

    break;
  }

  return args.slice(i);
}

function isBlockedTerraformMutation(argv: string[]): boolean {
  const terraformArgs = stripTerraformGlobalOptions(argv.slice(1));
  return terraformArgs[0] === "apply" || terraformArgs[0] === "destroy";
}

function stripKubectlGlobalOptions(args: string[]): string[] {
  let i = 0;
  while (i < args.length) {
    const token = args[i]!;

    if (token === "--") {
      return args.slice(i + 1);
    }

    if (
      token === "-n" ||
      token === "--namespace" ||
      token === "--context" ||
      token === "--cluster" ||
      token === "--user" ||
      token === "--kubeconfig" ||
      token === "--request-timeout" ||
      token === "-f" ||
      token === "--filename"
    ) {
      i += 2;
      continue;
    }

    if (
      token.startsWith("--namespace=") ||
      token.startsWith("--context=") ||
      token.startsWith("--cluster=") ||
      token.startsWith("--user=") ||
      token.startsWith("--kubeconfig=") ||
      token.startsWith("--request-timeout=") ||
      token.startsWith("--filename=")
    ) {
      i += 1;
      continue;
    }

    if (token.startsWith("-")) {
      i += 1;
      continue;
    }

    break;
  }

  return args.slice(i);
}

function isBlockedKubectlApply(argv: string[]): boolean {
  const kubectlArgs = stripKubectlGlobalOptions(argv.slice(1));
  return kubectlArgs[0] === "apply";
}

function findPolicyViolation(script: string, depth = 0): PolicyViolation | null {
  if (depth > MAX_RECURSION_DEPTH) {
    return null;
  }

  for (const segment of splitShellSegments(script)) {
    const match = extractCommandMatch(segment);
    if (!match) {
      continue;
    }

    for (const policy of commandPolicies) {
      if (match.executable !== policy.executable) {
        continue;
      }

      if (policy.mode === "defaultBlock") {
        if (!policy.isAllowed(match)) {
          return {
            policyName: policy.name,
            reason: policy.summary,
            segment,
          };
        }
      } else if (policy.isBlocked(match)) {
        return {
          policyName: policy.name,
          reason: policy.summary,
          segment,
        };
      }
    }

    const nestedShellCommand = extractNestedShellCommand(match);
    if (nestedShellCommand) {
      const nestedViolation = findPolicyViolation(nestedShellCommand, depth + 1);
      if (nestedViolation) {
        return nestedViolation;
      }
    }
  }

  return null;
}

function formatBlockedMessage(violation: PolicyViolation): string {
  return [
    `Blocked by pi block-commands extension (${violation.policyName}).`,
    violation.reason,
    `Matched command segment: ${violation.segment}`,
  ].join("\n");
}

function describePolicies(): string {
  return [
    "pi block-commands policy",
    "",
    ...commandPolicies.map((policy) => `- ${policy.name}: ${policy.summary}`),
  ].join("\n");
}

function buildSystemPromptPolicyNote(): string {
  const lines = [
    "Shell command policy in this session:",
    `- gh commands are blocked by default. Allowed exceptions: ${ghAllowedCommandSummary}.`,
    "- git is allowed by default, but destructive git push variants are blocked: -f, --force, --force-with-lease, --force-if-includes, --mirror, --delete, :branch deletion refspecs, and +refspec forms.",
    "- terraform is allowed by default, but terraform apply and terraform destroy are blocked.",
    "- kubectl is allowed by default, but kubectl apply is blocked.",
    "- If a blocked command would be useful, explain that it is blocked instead of trying to run it.",
  ];

  return lines.join("\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("command-blocks", {
    description: "Show active shell command blocking rules",
    handler: async (_args, ctx) => {
      const summary = describePolicies();

      if (ctx.hasUI) {
        await ctx.ui.editor("Active shell command blocking rules", summary);
      } else {
        console.log(summary);
      }
    },
  });

  pi.on("before_agent_start", async (event) => {
    return {
      systemPrompt: `${event.systemPrompt}\n\n${buildSystemPromptPolicyNote()}`,
    };
  });

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") {
      return undefined;
    }

    const violation = findPolicyViolation(String(event.input.command ?? ""));
    if (!violation) {
      return undefined;
    }

    if (ctx.hasUI) {
      ctx.ui.notify(formatBlockedMessage(violation), "warning");
    }

    return {
      block: true,
      reason: formatBlockedMessage(violation),
    };
  });

  pi.on("user_bash", async (event, ctx) => {
    const violation = findPolicyViolation(event.command);
    if (!violation) {
      return undefined;
    }

    const message = formatBlockedMessage(violation);
    if (ctx.hasUI) {
      ctx.ui.notify(message, "warning");
    }

    return {
      result: {
        output: message,
        exitCode: 1,
        cancelled: false,
        truncated: false,
      },
    };
  });
}
