---
description: "Forge: the ultimate cross-model workflow for ANY task — plan → test → build → harden → review. Works for features, bugs, refactoring, analysis, debugging, and everything in between."
argument-hint: "<any task description>"
context: fork
allowed-tools: "*"
---

# Forge: The Cross-Model Forge

**One command. Every omcx advantage. Works for any task.**

Forge chains every cross-model capability into a single pipeline.
It works for any task: new features, bug fixes, refactoring, debugging,
analysis, migration, or anything else you throw at it.

Each phase adapts to the task:
- For new features: full blind TDD → build → stress → review
- For bug fixes: analyze → test the fix → harden → review
- For refactoring: plan → build → stress existing tests → review
- For analysis/debugging: plan → investigate → cross-model verify findings

**Two different AI models challenge each other's work at every stage.**

## What Makes Forge Unique

```
/omcx:forge implement payment processing with refund support
```

This single command triggers:

1. 🧠 Claude PLANS the architecture (deep reasoning)
2. 🧪 Codex writes TESTS from spec only (blind — can't share Claude's assumptions)
3. 🔨 Claude BUILDS from tests only (blind — tests ARE the spec)
4. ⚔️  Codex ATTACKS the code (adversarial stress testing)
5. 🛡️  Claude DEFENDS and fixes (hardening)
6. 🔍 Codex REVIEWS the final code (structured + adversarial)
7. 📊 Claude SYNTHESIZES everything into a confidence report

At every stage, a different model challenges the other's work.
The code survives because it passed scrutiny from two independent perspectives.

## Syntax

```bash
# Standard forge
/omcx:forge implement user authentication with OAuth2 and MFA

# With options
/omcx:forge --test-writers 3 --stress-rounds 5 implement payment pipeline

# Quick forge (fewer rounds, faster)
/omcx:forge --quick add rate limiting to API endpoints

# Thorough forge (more attackers, more rounds)
/omcx:forge --thorough implement the transaction reconciliation engine

# Specify test framework
/omcx:forge --framework vitest implement connection pool with retry

# Scale both models
/omcx:forge --builders 3:claude,2:codex --attackers 3 implement notification system
```

### Presets

| Flag | Test Writers | Builders | Stress Rounds | Attackers |
|------|-------------|----------|---------------|-----------|
| (default) | 1 Codex | Claude ralph | 3 | 1 Codex |
| `--quick` | 1 Codex | Claude ralph | 1 | 1 Codex |
| `--thorough` | 3 Codex | 2:claude,1:codex | 5 | 3 Codex |

## The Forge Pipeline

User request: $ARGUMENTS

---

### Phase 1: ARCHITECT (Claude)

**Model: Claude Opus — deep reasoning for complex requirements**

Claude analyzes the request and produces:

1. **Architecture plan** — components, interfaces, dependencies
2. **Clean specification** — behavioral contract, NO implementation hints
3. **Attack surface preview** — what areas are most vulnerable

```
Invoke oh-my-claudecode:plan with: "$ARGUMENTS"
```

Then extract a clean spec for the blind test phase:

```
## Specification (for test writer)

### Interface
[function signatures, API contract]

### Requirements
[what MUST be true — behavioral, not structural]

### Edge Cases
[boundaries, failure modes, concurrent access]

### Security Considerations
[auth, input validation, data safety]
```

**Fallback:** Codex generates the plan if Claude is unavailable.

---

### Phase 2: BLIND TEST (Codex writes tests)

**Model: Codex — tests from spec only, zero knowledge of implementation**

Codex sees ONLY the clean spec from Phase 1. Not the architecture plan.
Not the original user request. Just the behavioral contract.

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json \
  "Write comprehensive tests for this specification. You do NOT know how it will be built.
   Test every requirement, edge case, error condition, and boundary value.
   Think about what a DIFFERENT developer might get wrong.

   Specification:
   [clean spec]

   Framework: [detected/specified]
   Write tests ONLY — no production code."
```

**With `--test-writers N`:** N parallel Codex tasks, each independently writing tests.
Merge the most thorough coverage from each.

**Fallback:** Claude test-engineer writes tests if Codex is unavailable.

---

### Phase 3: BUILD (Claude implements from tests)

**Model: Claude ralph — implements knowing ONLY the tests**

Claude sees ONLY the test files. Not the spec. Not the plan.
The tests ARE the specification.

```
Invoke oh-my-claudecode:ralph with:
"Make ALL these tests pass. The tests are your only specification.
 Do NOT modify any test files. Only create/modify production code.
 Test files: [paths from Phase 2]"
```

**With `--builders N:claude,M:codex`:** Mixed team build — complex tasks to Claude,
scoped tasks to Codex. Cross-model review of each piece afterward.

**Fallback:** Codex rescue --write if Claude is unavailable.

---

### Phase 4: STRESS (Codex attacks, Claude defends)

**Red team: Codex — adversarial tests trying to break the code**
**Blue team: Claude — fixes vulnerabilities**

Now that the code passes functional tests, harden it against adversarial input:

```bash
# Round N: Codex attacks
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json \
  "Red team attack. Break this code with adversarial tests.
   Categories: boundary, concurrency, security, resource, state, timing, data.
   Previous attacks survived: [list]
   Try HARDER than last round.
   Target: [file paths]"
```

```
# Round N: Claude defends
Invoke oh-my-claudecode:ralph with:
"Fix these adversarial test failures without breaking existing tests.
 Failing: [test output]"
```

Repeat for `--stress-rounds` (default: 3) or until red team can't break it.

**With `--attackers N`:** N parallel Codex red teamers for maximum attack diversity.

**Fallback:** Claude architect as red team if Codex unavailable.

---

### Phase 5: REVIEW (Codex validates the final code)

**Model: Codex — structured + adversarial review of the battle-tested code**

The code has already survived blind testing and stress testing.
Now Codex does a final structured review for anything the attack rounds missed:

```bash
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")
SCOPE_FLAG=""
[ "$DIFF_BYTES" -gt 500000 ] && SCOPE_FLAG="--scope working-tree"

node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json $SCOPE_FLAG
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" adversarial-review --wait --json $SCOPE_FLAG
```

**Fix any critical/high findings:** Route by complexity (simple → Codex, complex → Claude).
Re-review. Max 3 fix cycles.

**Fallback:** Claude code-reviewer + architect if Codex unavailable.

---

### Phase 6: CONFIDENCE REPORT (Claude synthesizes everything)

**Model: Claude — synthesizes all evidence into a confidence assessment**

```
## Forge Report: [feature name]

### Architecture (Claude)
- [key design decisions]

### Blind Test Results
- Test writer: Codex (independent from implementer)
- Tests written: N cases across M files
- First-run pass rate: X/N
- Blind spots caught: [what Codex tested that Claude wouldn't have]

### Implementation (Claude)
- Files: [list]
- Built from tests only (never saw the spec directly)

### Stress Test Results
- Rounds: N attack/defend cycles
- Vulnerabilities found & fixed: M
- Attack categories covered: [list]
- Red team final verdict: couldn't break it after round N

### Code Review (Codex)
- Structured: [verdict] — [N findings]
- Adversarial: [N concerns]
- Fix cycles: N

### Test Artifacts (keep these!)
- Functional tests: [paths] (from blind test phase)
- Adversarial tests: [paths] (from stress phase)
- Total test coverage: N test cases

### Confidence Level
| Dimension | Rating | Evidence |
|-----------|--------|----------|
| Correctness | ★★★☆ | [blind tests + functional tests pass] |
| Edge cases | ★★★★ | [cross-model blind spots caught N issues] |
| Security | ★★★☆ | [stress test found and fixed M vulns] |
| Robustness | ★★★★ | [survived N attack rounds] |
| Code quality | ★★★☆ | [Codex review: verdict] |

### Overall: FORGED ✓
This code has been independently tested, attacked, and reviewed
by two different AI model families. [N] blind-spot issues and [M]
vulnerabilities were caught and fixed that single-model development
would have missed.
```

## Abort Conditions

Stop and report if:
- Phase 3 (build) fails after 5 iterations and Codex fallback also fails
- Phase 4 (stress) exceeds max rounds with unfixable vulnerabilities
- Phase 5 (review) has critical findings after 3 fix cycles
- Both models are unavailable for the same phase

## Why Forge Exists

Every other omcx command uses ONE cross-model technique:
- `pipeline` → strength-based routing
- `auto-ralph` → build + validate loop
- `blind-test` → cross-model TDD
- `stress` → adversarial hardening
- `auto-validate` → cross-model review
- `race` → parallel competition

**Forge uses ALL of them in sequence.**
The result is code with the highest confidence level omcx can produce.

## Examples

```bash
# Standard forge for a critical feature
/omcx:forge implement payment processing with refund and dispute handling

# Quick forge for simpler features
/omcx:forge --quick add email notification on user signup

# Thorough forge for security-critical code
/omcx:forge --thorough implement JWT token rotation with refresh flow

# Maximum hardening for financial code
/omcx:forge --test-writers 3 --stress-rounds 7 --attackers 3 implement ledger reconciliation

# With team scaling for large features
/omcx:forge --builders 3:claude,2:codex --thorough implement the entire search subsystem
```
