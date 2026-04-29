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
 * - default-allow git, but block destructive push variants
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

type LeadingOptionSpec = {
  stopTokens?: string[];
  optionsWithArgument?: string[];
  attachedValueOptions?: string[];
};

const MAX_RECURSION_DEPTH = 3;

const transparentWrappers = new Set(["command", "builtin", "noglob", "nocorrect", "time", "nohup"]);

const shellExecutables = new Set(["bash", "sh", "dash", "zsh", "fish"]);

const wrapperOptionSpecs: Record<string, LeadingOptionSpec> = {
  sudo: {
    optionsWithArgument: ["-u", "-g", "-h", "-p", "-C", "-T", "-r", "-t"],
    attachedValueOptions: [
      "--user",
      "--group",
      "--host",
      "--prompt",
      "--close-from",
      "--command-timeout",
      "--chdir",
    ],
  },
  doas: {
    optionsWithArgument: ["-u", "--user"],
    attachedValueOptions: ["--user"],
  },
  nice: {
    optionsWithArgument: ["-n", "--adjustment"],
    attachedValueOptions: ["--adjustment"],
  },
  ionice: {
    optionsWithArgument: ["-c", "-n", "-t", "-p", "-P", "--class", "--classdata", "--pid", "--pgid"],
    attachedValueOptions: ["--class", "--classdata", "--pid", "--pgid"],
  },
  chrt: {
    optionsWithArgument: ["-p", "-P", "-T", "-D", "--pid", "--max", "--sched-runtime", "--sched-deadline", "--sched-period"],
    attachedValueOptions: ["--pid", "--max", "--sched-runtime", "--sched-deadline", "--sched-period"],
  },
  stdbuf: {
    optionsWithArgument: ["-i", "-o", "-e"],
  },
  timeout: {
    optionsWithArgument: ["-k", "-s", "--kill-after", "--signal"],
    attachedValueOptions: ["--kill-after", "--signal"],
  },
};

const ghAllowedCommandPrefixes = [
  ["version"],
  ["--version"],
  ["help"],
  ["--help"],
  ["-h"],
  ["auth", "status"],
  ["repo", "view"],
  ["issue", "list"],
  ["issue", "view"],
  ["pr", "list"],
  ["pr", "view"],
  ["release", "list"],
] as const;

const ghAllowedCommandSummary = ghAllowedCommandPrefixes.map((parts) => `gh ${parts.join(" ")}`).join(", ");

const ghGlobalOptionSpec: LeadingOptionSpec = {
  stopTokens: ["version", "--version", "help", "--help", "-h"],
  optionsWithArgument: ["-R", "--repo", "--hostname"],
  attachedValueOptions: ["--repo", "--hostname"],
};

const gitGlobalOptionSpec: LeadingOptionSpec = {
  optionsWithArgument: [
    "-c",
    "-C",
    "--git-dir",
    "--work-tree",
    "--namespace",
    "--exec-path",
    "--super-prefix",
    "--config-env",
  ],
  attachedValueOptions: [
    "--git-dir",
    "--work-tree",
    "--namespace",
    "--exec-path",
    "--super-prefix",
    "--config-env",
  ],
};

const terraformGlobalOptionSpec: LeadingOptionSpec = {
  optionsWithArgument: ["-chdir"],
  attachedValueOptions: ["-chdir"],
};

const kubectlGlobalOptionSpec: LeadingOptionSpec = {
  optionsWithArgument: [
    "-n",
    "--namespace",
    "--context",
    "--cluster",
    "--user",
    "--kubeconfig",
    "--request-timeout",
    "-f",
    "--filename",
  ],
  attachedValueOptions: [
    "--namespace",
    "--context",
    "--cluster",
    "--user",
    "--kubeconfig",
    "--request-timeout",
    "--filename",
  ],
};

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

function normalizeExecutable(token: string): string {
  const parts = token.split(/[\\/]/).filter(Boolean);
  return parts.at(-1) ?? token;
}

function stripLeadingOptions(tokens: string[], spec: LeadingOptionSpec = {}): string[] {
  const stopTokens = new Set(spec.stopTokens ?? []);
  const optionsWithArgument = new Set(spec.optionsWithArgument ?? []);
  const attachedValueOptions = spec.attachedValueOptions ?? [];
  let i = 0;

  while (i < tokens.length) {
    const token = tokens[i]!;

    if (token === "--") {
      return tokens.slice(i + 1);
    }

    if (stopTokens.has(token)) {
      return tokens.slice(i);
    }

    if (optionsWithArgument.has(token)) {
      i += 2;
      continue;
    }

    if (attachedValueOptions.some((option) => token.startsWith(`${option}=`))) {
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
    const head = remaining[0]!;

    if (isEnvAssignment(head)) {
      remaining = remaining.slice(1);
      continue;
    }

    if (head === "env") {
      remaining = unwrapEnv(remaining.slice(1));
      continue;
    }

    if (transparentWrappers.has(head)) {
      remaining = remaining.slice(1);
      continue;
    }

    const wrapperSpec = wrapperOptionSpecs[head];
    if (wrapperSpec) {
      remaining = stripLeadingOptions(remaining.slice(1), wrapperSpec);
      continue;
    }

    return remaining.length > 0 ? remaining : null;
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
    executable: normalizeExecutable(argv[0]!),
    argv,
    segment,
  };
}

function extractNestedShellCommand(match: CommandMatch): string | null {
  if (!shellExecutables.has(match.executable)) {
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

function matchesPrefix(actual: readonly string[], expected: readonly string[]): boolean {
  if (actual.length < expected.length) {
    return false;
  }

  return expected.every((part, index) => actual[index] === part);
}

function isAllowedGhCommand(argv: string[]): boolean {
  const commandPath = stripLeadingOptions(argv.slice(1), ghGlobalOptionSpec);
  return ghAllowedCommandPrefixes.some((prefix) => matchesPrefix(commandPath, prefix));
}

function stripGitGlobalOptions(args: string[]): string[] {
  return stripLeadingOptions(args, gitGlobalOptionSpec);
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

function isBlockedTerraformMutation(argv: string[]): boolean {
  const terraformArgs = stripLeadingOptions(argv.slice(1), terraformGlobalOptionSpec);
  return terraformArgs[0] === "apply" || terraformArgs[0] === "destroy";
}

function isBlockedKubectlApply(argv: string[]): boolean {
  const kubectlArgs = stripLeadingOptions(argv.slice(1), kubectlGlobalOptionSpec);
  return kubectlArgs[0] === "apply";
}

function evaluatePolicy(match: CommandMatch): PolicyViolation | null {
  for (const policy of commandPolicies) {
    if (match.executable !== policy.executable) {
      continue;
    }

    if (policy.mode === "defaultBlock") {
      if (!policy.isAllowed(match)) {
        return {
          policyName: policy.name,
          reason: policy.summary,
          segment: match.segment,
        };
      }

      continue;
    }

    if (policy.isBlocked(match)) {
      return {
        policyName: policy.name,
        reason: policy.summary,
        segment: match.segment,
      };
    }
  }

  return null;
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

    const directViolation = evaluatePolicy(match);
    if (directViolation) {
      return directViolation;
    }

    const nestedShellCommand = extractNestedShellCommand(match);
    if (!nestedShellCommand) {
      continue;
    }

    const nestedViolation = findPolicyViolation(nestedShellCommand, depth + 1);
    if (nestedViolation) {
      return nestedViolation;
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
  return [
    "Shell command policy in this session:",
    `- gh commands are blocked by default. Allowed exceptions: ${ghAllowedCommandSummary}.`,
    "- git is allowed by default, but destructive git push variants are blocked: -f, --force, --force-with-lease, --force-if-includes, --mirror, --delete, :branch deletion refspecs, and +refspec forms.",
    "- terraform is allowed by default, but terraform apply and terraform destroy are blocked.",
    "- kubectl is allowed by default, but kubectl apply is blocked.",
    "- If a blocked command would be useful, explain that it is blocked instead of trying to run it.",
  ].join("\n");
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

    const message = formatBlockedMessage(violation);
    if (ctx.hasUI) {
      ctx.ui.notify(message, "warning");
    }

    return {
      block: true,
      reason: message,
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
