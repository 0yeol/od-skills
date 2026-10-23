# od-skills

[nexu-io/open-design](https://github.com/nexu-io/open-design)의 디자인 스킬 169개를
모든 AI 코딩 에이전트(Claude Code, Codex, OpenCode, Qwen, iFlow, Gemini, Kiro, pi 등)에서
쓸 수 있게 한 번에 설치하는 패키지.

실제 파일은 `~/.agents/skills/` 공유 위치에 놓고, 각 에이전트 스킬 디렉터리에는
심볼릭 링크로 연결합니다. 설치된 에이전트만 연결되고, 없는 에이전트는 건너뜁니다.

## 설치 (Homebrew)

```sh
brew tap 0yeol/tap https://github.com/0yeol/homebrew-tap
brew install od-skills
od-skills install        # 에이전트 연결 (brew 설치 후 1회)
```

## 설치 (curl)

```sh
curl -fsSL https://raw.githubusercontent.com/0yeol/od-skills/main/install.sh | bash
```

## 사용

```sh
od-skills install [--force]   # 설치/업데이트 (멱등)
od-skills list                # 설치된 스킬 목록
od-skills uninstall           # 전체 제거 (에이전트 링크 포함)
```

업데이트: `brew upgrade od-skills && od-skills install`

## 규칙

- 이름이 같은 스킬이 이미 있으면(직접 설치한 것) 그대로 두고 건너뜁니다. `--force`로 덮어쓰기.
- Homebrew 업그레이드 후에는 `od-skills install`을 다시 실행해야 반영됩니다.

## 포함 내용

`skills/` — upstream `skills/` 디렉터리에서 `SKILL.md`가 있는 169개 스킬 그대로
(Apache-2.0). upstream의 제품 렌더링 템플릿(`design-templates/`, `design-systems/`)과
데몬(`apps/`)은 제외 — 스킬 자체는 모두 독립적으로 동작합니다.

동기화 시점: upstream commit `e03d5c2` (main).

## 라이선스

Apache-2.0. 스킬 원본 저작권은 [nexu-io/open-design](https://github.com/nexu-io/open-design) 프로젝트에 있습니다.
