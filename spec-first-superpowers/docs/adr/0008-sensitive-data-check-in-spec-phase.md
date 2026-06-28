# 0008. Phase 3 で機微情報チェックリスト + 適用規制 trigger 提示

## Status

Accepted (2026-06-25)

## Context

エンプラ特有要素のうち「コンプライアンス (法令 / 業界規制 適合)」を本コレクションでどう扱うかが論点。具体的な規制チェック (GDPR / 個人情報保護法 / PCI-DSS / HIPAA 等) は外部ツール / 法務に委ねるべきだが、本コレクションが何もしないと「機微情報を扱う設計なのに規制を確認し忘れる」silent failure を防げない。

本コレクションは汎用 spec フローを目指すので、規制の具体チェックは入れず **trigger 提示** に絞る。

## Decision

enhance-brainstorming Phase 3 の `security-engineer` 常時 dispatch (ADR-0005 / ADR-0001 のセキュリティレビュー 2 層) 時に、**機微情報チェックリスト** を確認する step を組み込む:

1. design.md の内容から、以下を扱うかをチェック:
   - 個人情報 (PII: 氏名 / 住所 / 電話番号 / メール / マイナンバー / 生年月日 等)
   - 決済データ (クレジットカード番号 / 銀行口座 / 取引履歴)
   - 医療データ (PHI: 診療記録 / 検査結果 / 病歴)
   - 認証情報 (パスワード / トークン / 秘密鍵)
2. 該当した場合、user に **適用される可能性のある規制を提示**:
   - PII → 個人情報保護法 (日本) / GDPR (EU) / CCPA (米国カリフォルニア州) 等
   - 決済 → PCI-DSS
   - 医療 → HIPAA (米国) / 医療法 (日本)
   - 認証情報 → OWASP ASVS / 各種セキュリティ標準
3. user に「適用規制を確認の上、本 PR スコープで対応 / 別 PR / Skip のいずれかを判断してください」と促す
4. dispatch log (ADR-0007) として design.md のレビュー履歴に「機微情報チェック結果 + user 判断」を記録

具体的な規制チェック (GDPR の article 別検証 / PCI-DSS の SAQ 別検証等) は **本コレクションのスコープ外**、外部ツール (Privado / Bearer / GitLab Compliance Center 等) または法務に委ねる。

## Consequences

- 機微情報を扱う設計を Spec フェーズで漏れなく検出 (silent failure 回避)
- 規制の具体チェックは外部ツール / 法務に委ね、本コレクションは trigger 提示のみ — 環境依存を最小化
- 「機微情報なし」と user が判定した場合も dispatch log にその根拠を残す (= 監査証跡)
- 機微情報あり時に user が「Skip (別 PR で対応)」を選んだ場合、review-response.md の Skip 判定セクションに該当を記録

## Alternatives Considered

- 規制ごとの具体チェック step を本コレクションに入れる — 規制が多すぎる + 規制改定への追従コスト + プロジェクトごとに適用規制が異なる、で破綻。却下
- 機微情報チェックを行わない — silent failure pattern を誘発。却下
