---
description: "Blind TDD: one model writes tests/checks from spec, the other implements/fixes from those tests — works for new features, bug fixes, refactoring, and any task where independent verification matters"
argument-hint: "<spec or feature description>"
context: fork
allowed-tools: "*"
---

# Blind Test: Cross-Model TDD

**The problem:** When the same model writes tests AND code, it makes the same assumptions
in both. Tests pass, but real-world edge cases get missed — because the test writer and
the coder share identical blind spots.

**The solution:** One model writes tests knowing ONLY the spec. The other implements
knowing ONLY the tests. They literally can't share blind spots because they never
see each other's reasoning.

**This is impossible with a single model. It requires two different model families.**

## Why This Works

```
Traditional TDD (same model):
  Claude writes tests → Claude writes code → Tests pass ✓
  BUT: Claude's tests don't test what Claude's code won't handle

Blind TDD (cross-model):
  Codex writes tests → Claude writes code → Tests may fail ✗
  BECAUSE: Codex tested edge cases Claude wouldn't think of
  FIX: Claude handles those edge cases → genuinely robust code
```

- Different models have different assumptions about input validation
- Different models think of different edge cases and failure modes
- Different models structure error handling differently
- The gap between their assumptions IS where bugs live

## Syntax

```bash
# Default: Codex writes tests, Claude implements
/omcx:blind-test implement a rate limiter that handles burst traffic

# Swap: Claude writes tests, Codex implements
/omcx:blind-test --swap implement input validation for user registration

# Specify test framework
/omcx:blind-test --framework vitest implement connection pool with retry
/omcx:blind-test --framework pytest implement LRU cache with TTL

# Scale test writers for more coverage
/omcx:blind-test --test-writers 3 implement payment processing pipeline
```

## Workflow

User request: $ARGUMENTS

### Phase 1: Extract Clean Spec

Claude extracts a clean, model-agnostic specification from the user's request:

```
## Specification (for test writer — NO implementation hints)

### Purpose
[What the feature does, from a user/caller perspective]

### Interface
[Function signatures, input/output types, API contract]

### Requirements
[Behavioral requirements — what MUST be true]

### Constraints
[Performance, security, compatibility requirements]

### Edge Cases to Consider
[Explicitly listed edge cases the user cares about]
```

**Critical:** The spec contains NO implementation hints. It describes WHAT, not HOW.
The test writer must not be influenced by how the implementer might build it.

### Phase 2: Blind Test Writing

**Default: Codex writes tests** (Codex is fast and systematic for test generation)

Send ONLY the spec to Codex (NOT the original user request, which may contain implementation hints):

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json \
  "Write comprehensive tests for this specification. You do NOT know how it will be implemented.
   Test every requirement, edge case, error condition, and boundary.
   Think about what a DIFFERENT developer might get wrong.

   Specification:
   [clean spec from Phase 1]

   Framework: [vitest/jest/pytest/etc.]
   Write tests ONLY. Do not implement any production code."
```

**With `--test-writers N`:** Launch N Codex tasks in parallel, each independently writing tests.
Then merge all test files (deduplicate, keep the most thorough version of each test).

**With `--swap`:** Claude writes tests instead:
```
Agent(subagent_type="oh-my-claudecode:test-engineer", model="opus",
  prompt="Write comprehensive tests for this spec. You do NOT know how it will be implemented. [spec]")
```

**Fallback:** If primary test writer unavailable, swap to the other model.

### Phase 3: Blind Implementation

**Default: Claude implements** (Claude excels at complex multi-file implementation)

Send ONLY the test file(s) to Claude (NOT the original spec — the tests ARE the spec):

```
Invoke oh-my-claudecode:ralph with:
"Make ALL these tests pass. The tests are your specification.
 Do NOT modify any test files. Only create/modify production code.
 [test file paths]"
```

**With `--swap`:** Codex implements from the tests:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json \
  "Make ALL these tests pass. Do NOT modify test files. Only write production code.
   Test files: [paths]"
```

**Fallback:** If primary implementer unavailable, swap to the other model.

### Phase 4: Confrontation

Run the tests:

```bash
# Run tests and capture output
[appropriate test runner command based on framework]
```

**If all tests pass on first try:**
- This is suspicious — the tests might not be thorough enough
- Run Phase 5 (adversarial hardening) to add more edge cases

**If some tests fail:**
- This is GOOD — it means the models found each other's blind spots
- The implementer fixes failures (stay in ralph loop or Codex --resume)
- Re-run tests
- Max 5 fix cycles

**If most tests fail:**
- The spec might be ambiguous — Claude reviews both test and implementation
- Clarify spec, regenerate tests for ambiguous parts

### Phase 5: Adversarial Hardening (optional but recommended)

After all tests pass, flip the roles for one more round:

1. **Implementer reviews tests:** "Are there edge cases these tests missed?"
   - Claude (who implemented) suggests additional test cases
2. **Test writer reviews implementation:** "Is there anything the tests don't cover?"
   - Codex (who tested) reviews implementation for uncovered paths
3. Add any new tests discovered
4. Fix any new failures

This catches the residual blind spots from each model's perspective.

### Phase 6: Report

```
## Blind Test Report

### Specification
- [1-2 line summary]

### Test Phase
- Test writer: Codex / Claude
- Tests written: N test cases across M files
- Edge cases covered: [list]

### Implementation Phase
- Implementer: Claude / Codex
- Files created: [list]

### Confrontation
- First run: X/N tests passed
- Blind spot findings: [what the test writer caught that the implementer missed]
- Fix iterations: N
- Final: all N tests passing ✓

### Adversarial Hardening
- Additional tests from implementer: +N
- Additional findings from test writer: +N
- All passing after hardening: ✓

### Blind Spot Analysis
Key differences in model assumptions:
- [what Codex tested that Claude wouldn't have]
- [what Claude implemented that Codex wouldn't have tested]
- [genuine bugs caught by cross-model approach]
```

## Examples

```bash
# API endpoint with complex validation
/omcx:blind-test implement user registration with email verification and rate limiting

# Algorithm with tricky edge cases
/omcx:blind-test implement a merge interval algorithm that handles overlapping and adjacent ranges

# Swap for variety — Claude writes tests, Codex implements
/omcx:blind-test --swap implement a retry mechanism with exponential backoff and jitter

# Maximum test coverage — 3 independent test writers
/omcx:blind-test --test-writers 3 implement payment processing with refund support

# Specify framework
/omcx:blind-test --framework pytest implement an LRU cache with TTL expiration
```
