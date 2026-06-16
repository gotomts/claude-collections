# agents リポジトリをハーネスの単一ホームにする（fleet は廃止）

AI による自律的な開発のためのスキル・エージェント・オーケストレーター・設計判断（CONTEXT/ADR）を、すべて `agents` リポジトリに集約し、一体で育てる。`dotfiles/claude/fleet`（dev×8/rev×3/pr-publisher）はいずれ廃止し、その後継は `agents` リポジトリで育てる。リポジトリ名は後で変更しうる。

## Status

accepted

## Considered Options

- **却下: スキルは dotfiles/claude/skills、設計判断のみ agents、という分割（当初案）**。ハーネスを「自律開発のためのスキル・エージェント集」として一体で育てる方針に反する。配送・バージョン・設計が分散し、育てにくい。

## Consequences

- 個人常用スキル（`dotfiles/claude/skills`）と**ハーネス用スキル/エージェント（`agents`）は別管理**になる。ローカル/remote への配送（symlink / inject）方法は別途設計。
- fleet の remote inject hook（`inject-fleet.sh`）の後継をどうするか要検討（agents リポジトリからの注入）。
- リポジトリ改名時に、CONTEXT/ADR 内のパス参照等の更新が要る。
- dotfiles 側 AGENTS.md の fleet 記述は、廃止時に棚卸しが必要。
