---
description: "Red vs Blue: Codex challenges (adversarial tests, edge cases, attack vectors), Claude defends (fixes) — works for hardening any code, debugging, security review, and quality assurance"
argument-hint: "<code path or feature to stress-test>"
context: fork
allowed-tools: "*"
---

# Stress: Adversarial Red Team / Blue Team

**Red team (Codex):** Tries to break your code — writes adversarial tests, crafts malicious inputs,
finds race conditions, exploits edge cases, tests failure modes.

**Blue team (Claude):** Defends — fixes vulnerabilities, hardens edge cases, adds safeguards,
improves error handling.

**They go back and forth until the red team can't break it anymore.**

This is like intelligent fuzzing — but instead of random inputs, a different AI model
is actively reasoning about HOW to break your code. And it works because the attacker
and defender are different model families with different reasoning patterns.

## Why Cross-Model Matters Here

Same-model red team is weak: Claude attacking Claude's code won't find Claude's blind spots.
But Codex attacking Claude's code WILL — because Codex thinks about failure modes differently.

```
Round 1: Codex writes test that sends concurrent requests → Claude's code crashes
         Claude adds mutex → passes

Round 2: Codex writes test with 0-byte input → Claude's validation misses it
         Claude adds boundary check → passes

Round 3: Codex writes test that exceeds int32 max → Claude used wrong type
         Claude switches to BigInt → passes

Round 4: Codex can't find anything else to break → Code is hardened ✓
```

## Syntax

```bash
# Stress-test existing code
/omcx:stress src/auth/middleware.ts

# Stress-test a feature area
/omcx:stress the payment processing pipeline

# Stress-test with focus area
/omcx:stress --focus concurrency src/cache/connection-pool.ts

# Swap roles: Claude attacks, Codex defends
/omcx:stress --swap src/api/rate-limiter.ts

# Set max rounds
/omcx:stress --rounds 5 src/utils/parser.ts

# Scale red team for more attack diversity
/omcx:stress --attackers 3 src/auth/token-validator.ts
```

## Attack Categories

The red team systematically probes these categories:

| Category | Attack Examples |
|----------|----------------|
| **Boundary** | Empty input, max int, negative, unicode, null bytes |
| **Concurrency** | Race conditions, deadlocks, double-submit, stale reads |
| **Resource** | Memory exhaustion, connection leak, infinite loop, stack overflow |
| **Security** | Injection, path traversal, SSRF, auth bypass, privilege escalation |
| **State** | Invalid state transitions, partial failure, crash recovery |
| **Type** | Wrong types, coercion edge cases, prototype pollution |
| **Timing** | Timeout handling, slow consumers, clock skew |
| **Data** | Malformed JSON, encoding issues, huge payloads, deeply nested objects |

## Workflow

User request: $ARGUMENTS

### Round 0: Reconnaissance

Claude reads the target code and produces an attack surface analysis:

```
## Attack Surface

### Target
- Files: [list]
- Entry points: [functions/endpoints]
- Dependencies: [external calls]

### Initial Assessment
- Input validation: [weak/moderate/strong]
- Error handling: [weak/moderate/strong]
- Concurrency safety: [none/basic/robust]
- Type safety: [weak/moderate/strong]

### High-Value Attack Vectors
1. [most likely breakable area]
2. [second most likely]
3. [third]
```

### Round N: Attack (Red Team — Codex)

Codex writes adversarial test cases targeting the highest-value attack vectors:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json \
  "You are a red team attacker. Your goal is to BREAK this code.
   Write test cases that will cause crashes, incorrect behavior, security issues,
   or data corruption. Be creative and malicious.

   Target code:
   [code content]

   Previous rounds survived: [list of attacks that were already fixed]

   Write at least 5 new adversarial tests. Focus on:
   [highest-value attack vectors from reconnaissance]

   Framework: [detected or specified]"
```

**With `--attackers N`:** Launch N Codex tasks in parallel, each independently
crafting attacks. Merge all attack tests for maximum coverage.

### Round N: Defend (Blue Team — Claude)

Run the adversarial tests. For each failure:

```
Invoke oh-my-claudecode:ralph with:
"These adversarial tests found real vulnerabilities in the code.
 Fix each vulnerability WITHOUT breaking existing functionality.
 Do NOT modify the test files — make the code robust enough to pass them.

 Failing tests: [test output]
 Target files: [file list]"
```

### Round N: Escalation

After fixes, the red team escalates — tries harder:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json \
  "You are a red team attacker, Round $N. The defender fixed your previous attacks.
   They survived: [list of fixed attacks].

   Now try HARDER. Think of attacks the defender wouldn't expect:
   - Combine multiple attack vectors
   - Test recovery after partial failure
   - Try timing-based attacks
   - Test with adversarial but technically valid input

   Write 5+ new adversarial tests that are MORE sophisticated than last round."
```

### Termination Conditions

The stress test ends when:

1. **Red team exhausted** (3 consecutive rounds where all new tests pass immediately) → **Code is hardened**
2. **Max rounds reached** (default: 7, configurable with `--rounds`) → Report remaining weaknesses
3. **Blue team stuck** (same fix fails 3 times) → Escalate to user with specific vulnerability

### Final Report

```
## Stress Test Report

### Target
- [files and entry points tested]

### Rounds Summary
| Round | Attacks | Broke | Fixed | Survived |
|-------|---------|-------|-------|----------|
| 1 | 5 | 4 | 4 | 1 |
| 2 | 5 | 2 | 2 | 3 |
| 3 | 5 | 1 | 1 | 4 |
| 4 | 5 | 0 | — | 5 |

### Vulnerabilities Found & Fixed
1. [vulnerability] → [fix applied] (Round 1)
2. [vulnerability] → [fix applied] (Round 1)
3. [vulnerability] → [fix applied] (Round 2)
...

### Hardening Applied
- [input validation added]
- [concurrency fix]
- [error handling improved]
- [type safety strengthened]

### Remaining Risks
- [any known weaknesses red team couldn't exploit but flagged]

### Test Artifacts
- Adversarial test files: [paths] (keep these — they're regression tests now)
- Total adversarial tests: N
- All passing: ✓
```

## Key Insight

The adversarial tests produced by stress testing are **permanent regression tests**.
They protect against the exact class of bugs that a different AI model thought was
likely to exist. These are often edge cases that neither manual testing nor
traditional test generation would catch.

## Examples

```bash
# Harden authentication code
/omcx:stress src/auth/

# Focus on concurrency issues in the cache layer
/omcx:stress --focus concurrency src/cache/

# Quick 3-round stress test
/omcx:stress --rounds 3 src/api/rate-limiter.ts

# Maximum attack diversity
/omcx:stress --attackers 3 --rounds 5 src/payment/processor.ts

# Claude attacks, Codex defends (swap perspective)
/omcx:stress --swap src/utils/sanitizer.ts
```
