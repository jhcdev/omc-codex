# omc-codex

> Codex integration for oh-my-claudecode — Claude Code에서 OpenAI Codex로 코드 리뷰, 작업 위임, 적대적 리뷰를 수행

## 설치

### Claude Code Plugin Marketplace

```bash
/plugin install codex
```

### 수동 설치

```bash
git clone https://github.com/jhcdev/omc-codex.git ~/.claude/plugins/marketplaces/omc-codex
```

`~/.claude/settings.json`에 추가:

```json
{
  "enabledPlugins": {
    "codex@omc-codex": true
  },
  "extraKnownMarketplaces": {
    "omc-codex": {
      "source": {
        "source": "url",
        "url": "https://raw.githubusercontent.com/jhcdev/omc-codex/main/.claude-plugin/marketplace.json"
      }
    }
  }
}
```

### setup-dev-env.sh로 전체 설치

```bash
# 전체 설치 (처음)
bash setup-dev-env.sh all

# 플러그인만 패치 (업데이트 시)
bash setup-dev-env.sh plugin-only
```

## 요구사항

| 도구 | 필수 여부 | 비고 |
|------|----------|------|
| Node.js >= 18.18 | 필수 | 런타임 |
| Claude Code | 필수 | 호스트 환경 |
| Codex CLI (`@openai/codex`) | 선택 | 없으면 Claude 에이전트로 fallback |
| oh-my-claudecode (omc) | 선택 | 기존 omc 스킬과 병행 사용 |

---

## 명령어 레퍼런스

### 코드 리뷰

#### `/codex:review`
Codex built-in reviewer를 사용한 구조화된 코드 리뷰.
JSON schema 기반 결과 (verdict, findings with severity/file/line range/confidence).

```bash
# 포그라운드 리뷰 (결과 대기)
/codex:review --wait

# 백그라운드 리뷰
/codex:review --background

# 특정 브랜치 대비 리뷰
/codex:review --base main

# 워킹트리 리뷰 (커밋되지 않은 변경사항)
/codex:review --scope working-tree
```

#### `/codex:adversarial-review`
설계 선택과 가정을 도전적으로 검증하는 적대적 리뷰.
일반 리뷰와 달리 구현 결함이 아닌 설계 약점에 초점.

```bash
# 기본 적대적 리뷰
/codex:adversarial-review --wait

# 특정 영역에 집중
/codex:adversarial-review --wait auth flow and session management

# 백그라운드 실행
/codex:adversarial-review --background
```

### 작업 위임

#### `/codex:rescue`
Codex에게 버그 수정, 조사, 구현 작업을 위임.

```bash
# 버그 수정 위임 (쓰기 모드)
/codex:rescue --write fix the race condition in auth middleware

# 조사만 요청 (읽기 전용)
/codex:rescue investigate why tests fail on CI

# 이전 Codex 대화 이어가기
/codex:rescue --resume apply the top fix

# 새 대화로 시작 강제
/codex:rescue --fresh rewrite the caching layer

# 백그라운드 실행
/codex:rescue --background --write implement pagination for the API

# 특정 모델 지정
/codex:rescue --model spark quick fix for typo
```

### 리뷰 게이트

#### `/codex:setup`
Codex CLI 설치 상태, 인증, 리뷰 게이트 확인 및 설정.

```bash
/codex:setup
/codex:setup --enable-review-gate
/codex:setup --disable-review-gate
```

리뷰 게이트를 활성화하면 세션 종료 시 Codex가 자동으로 코드 리뷰를 실행합니다.
ALLOW면 정상 종료, BLOCK이면 수정 필요를 안내합니다.

### 작업 관리

#### `/codex:status`
```bash
/codex:status                    # 전체 작업 목록
/codex:status task-abc123        # 특정 작업 상세
/codex:status task-abc123 --wait # 완료 대기
```

#### `/codex:result`
```bash
/codex:result                    # 최근 작업 결과
/codex:result task-abc123        # 특정 작업 결과
```

#### `/codex:cancel`
```bash
/codex:cancel                    # 실행 중인 작업 취소
/codex:cancel task-abc123        # 특정 작업 취소
```

---

## omc + Codex 조합 레시피

omc-codex는 omc의 기존 스킬과 같은 세션에서 자유롭게 섞어 쓸 수 있습니다.

### 레시피 1: Plan → Codex 구현 → 구조화 리뷰

Claude가 설계하고, Codex가 구현하고, Codex가 리뷰하는 풀 사이클.

```bash
# 1. Claude Opus가 아키텍처 설계
/oh-my-claudecode:plan "결제 시스템에 환불 기능 추가"

# 2. 설계 기반으로 Codex에게 구현 위임
/codex:rescue --write implement refund feature per the plan above

# 3. 구조화된 리뷰로 품질 확인
/codex:review --wait

# 4. 리뷰 이슈 수정 요청
/codex:rescue --resume fix the issues from the review above
```

### 레시피 2: Codex 구현 + omc ralph 검증 루프

```bash
# 1. Codex에게 기능 구현 위임
/codex:rescue --write implement the new caching layer with Redis

# 2. omc ralph로 테스트 통과까지 자동 반복
/oh-my-claudecode:ralph "캐싱 레이어 테스트 전부 통과시켜. 실패하면 수정하고 재실행."
```

### 레시피 3: 이중 리뷰 파이프라인

```bash
# 1. Codex 구조화 리뷰 (구현 버그 탐지)
/codex:review --wait

# 2. Codex 적대적 리뷰 (설계 약점 도전)
/codex:adversarial-review --wait

# 3. Claude가 두 리뷰 결과를 종합 분석
"위 두 리뷰 결과를 종합해서 우선순위별로 정리해줘"
```

### 레시피 4: omc team + Codex 백그라운드 리뷰

```bash
# 1. Codex 백그라운드 리뷰 시작
/codex:review --background

# 2. 동시에 omc team으로 병렬 작업
/oh-my-claudecode:team 2:executor "모듈 A 리팩토링, 모듈 B 테스트 추가"

# 3. 팀 완료 후 Codex 리뷰 결과 확인
/codex:result
```

### 레시피 5: deep-dive → Codex 수정 → 리뷰 게이트

```bash
# 1. 리뷰 게이트 활성화
/codex:setup --enable-review-gate

# 2. Claude deep-dive로 원인 분석
/oh-my-claudecode:deep-dive "API 응답 시간이 3초 넘는 원인 분석"

# 3. Codex에게 최적화 위임
/codex:rescue --write optimize the N+1 query based on the analysis above

# 4. 세션 종료 시 자동 리뷰 게이트 실행
```

### 레시피 6: autopilot + Codex 최종 검증

```bash
# 1. autopilot으로 전체 자동화
/oh-my-claudecode:autopilot "사용자 알림 시스템 구현"

# 2. Codex 교차 검증
/codex:review --wait
/codex:adversarial-review --wait
```

### 조합 선택 가이드

| 상황 | 추천 조합 |
|------|----------|
| 새 기능 구현 (설계~리뷰) | 레시피 1: Plan → Codex rescue → review |
| 구현 후 품질 보장 | 레시피 2: Codex rescue → ralph 검증 루프 |
| PR 전 최종 검증 | 레시피 3: 이중 리뷰 파이프라인 |
| 시간 절약 (병렬) | 레시피 4: team + Codex 백그라운드 리뷰 |
| 성능/버그 수정 | 레시피 5: deep-dive → Codex rescue → 리뷰 게이트 |
| 전체 자동화 + 교차검증 | 레시피 6: autopilot → Codex 리뷰 |

---

## Codex 없을 때 동작

| 상황 | 동작 |
|------|------|
| Codex CLI 미설치 | Claude 에이전트로 자동 전환 |
| Codex 미인증 | `!codex login` 안내 + Claude 대체 선택지 |
| Codex 실행 중 장애 | 에러 반환, Claude로 재라우팅 |
| omc도 없음 | `/codex:review`, `rescue` 등은 독립 동작 |

---

## 아키텍처

```
┌─────────────────────────────────────────────────┐
│ Claude Code Session                              │
│                                                  │
│  ┌──────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ omc      │  │ omc-codex    │  │ Claude    │ │
│  │ skills   │  │ plugin       │  │ agents    │ │
│  │          │  │              │  │           │ │
│  │ ralph    │  │ /review ─────┼──┼→ Codex    │ │
│  │ ultrawork│  │ /adv-review ─┼──┼→ app-     │ │
│  │ team     │  │ /rescue ─────┼──┼→ server   │ │
│  │ autopilot│  │ /codex-gate  │  │           │ │
│  │ plan     │  │              │  │ (fallback)│ │
│  │ analyze  │  │ codex-       │  │ executor  │ │
│  │ ...      │  │ workflow     │  │ reviewer  │ │
│  └──────────┘  └──────────────┘  └───────────┘ │
│                       │                          │
│              ┌────────┴────────┐                 │
│              │  Hooks          │                 │
│              │  SessionStart   │                 │
│              │  SessionEnd     │                 │
│              │  Stop (gate)    │                 │
│              └─────────────────┘                 │
└─────────────────────────────────────────────────┘
```

## 고유 가치 (omc만으로는 불가능한 것)

1. **구조화된 코드 리뷰** — Codex app-server의 built-in reviewer, JSON schema 결과 (severity/file/line/confidence)
2. **리뷰 게이트** — 세션 종료 전 자동 코드 리뷰 강제 (Stop hook, BLOCK/ALLOW)
3. **Thread resume** — `--resume`으로 이전 Codex 대화 이어가기
4. **Graceful fallback** — Codex 없어도 Claude 에이전트로 자동 전환

## Skills

| Skill | 설명 |
|-------|------|
| `codex-cli-runtime` | Codex companion 런타임 호출 내부 계약 |
| `codex-result-handling` | Codex 출력 결과 표시 가이드 |
| `gpt-5-4-prompting` | Codex/GPT-5.4 프롬프트 작성 가이드 |

## Agents

| Agent | 설명 |
|-------|------|
| `codex-rescue` | 근본 원인 분석, 회귀 격리, Codex를 통한 수정 시도 |

## 파일 구조

```
omc-codex/
├── .claude-plugin/
│   ├── plugin.json              # 플러그인 메타데이터
│   └── marketplace.json         # 마켓플레이스 등록 정보
├── commands/                    # 슬래시 커맨드
│   ├── review.md                # 구조화된 코드 리뷰
│   ├── adversarial-review.md    # 적대적 리뷰
│   ├── rescue.md                # 작업 위임
│   ├── setup.md                 # 설정 확인
│   ├── status.md                # 작업 상태
│   ├── result.md                # 결과 조회
│   └── cancel.md                # 작업 취소
├── agents/
│   └── codex-rescue.md          # Codex 포워딩 에이전트
├── skills/
│   ├── codex-cli-runtime/       # 내부 런타임 계약
│   ├── codex-result-handling/   # 결과 표시 가이드
│   └── gpt-5-4-prompting/      # 프롬프트 작성 가이드
├── hooks/hooks.json             # SessionStart/End, Stop 훅
├── scripts/                     # 런타임 (codex-companion + lib)
├── prompts/                     # 리뷰 프롬프트 템플릿
├── schemas/                     # 리뷰 출력 JSON schema
├── LICENSE
└── README.md
```

## License

MIT — See [LICENSE](LICENSE) for details.

## Credits

Based on [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) by OpenAI.
