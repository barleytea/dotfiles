# Orcaの設定を別の端末で再現する

Orca 1.4.272のCLIヘルプ、同じ版の公開ソース、公式ドキュメントで確認した手順。対象はOrca IDEを導入済みのmacOSとLinuxのデスクトップ。LinuxでCLIを使う場合は `orca-ide` と読み替える。GUIのないNixOSホストでは、Orcaの画面操作は別のデスクトップから行う。Windowsは今回の手順の検証対象外。 [インストールとCLI名](https://orca.dev/docs/install)

| 正本 | 反映先と方法 |
|---|---|
| `darwin/home-manager/ghostty/config/config` / `nixos/home-manager/ghostty/config/config` | Orcaのターミナル設定へプレビュー付きで取り込む |
| `modules/home/orca/bots/pm/` | UIで登録したPMのSoulと専用スキルへ必要な変更を反映する |
| `modules/home/orca/bots/reviewer/SOUL.md` | UIで登録したReviewerのSoulへ必要な変更を反映する |
| 各端末のOrca設定とリポジトリ外のローカルメモ | 端末固有の選択や個別の運用情報を必要に応じて管理する |

## ターミナル

Orcaの初回起動時のGhostty取り込み、または **Settings → Terminal → Import from Ghostty** を使う。**Choose config file** で対象OSのチェックアウト内にある上記ファイルを選ぶ。フォント、サイズ、テーマ、余白など、プレビューに出る項目と変更値を確認して **Apply changes** を選ぶ。既存設定があれば、残したい変更は先に控え、適用後に端末側で調整する。再実行時もプレビューで差を確認する。テーマとフォントの再現は端末で利用できるリソースに依存する。Ghostty固有のキー割り当てなど、未対応項目は取り込みの対象外。 [Terminal](https://orca.dev/docs/terminal) · [1.4.272のマッピング](https://github.com/stablyai/orca/blob/v1.4.272/src/main/ghostty/mapper.ts)

既存のGhostty設定を共通の出発点にするため、この設定値は稼働中のOrcaから取得した値とは比較していない。アプリ全体の宣言的な読み込みや一括エクスポートは、確認した設定リファレンスとCLIに見当たらなかった。ほかのアプリ設定は **Settings** で端末ごとに選ぶ。初回のClaude Code・Codex設定の取り込みは、各エージェントの既存環境を取り込む機能。 [設定リファレンス](https://orca.dev/docs/settings) · [CLIリファレンス](https://orca.dev/docs/cli/reference)

## Botの初回登録と更新

1. 新しい端末は **Bots → ＋ → New bot → Start from scratch** で **PM** または **Reviewer** を作成する。実行先とエージェントは端末側で選ぶ。登録済みの端末では該当Botを選ぶ。1.4.272の `orca bot create --offer` はBotチャットから承認カードを出すコマンド。 [Bots quickstart](https://orca.dev/docs/bots)
2. Botの設定でSoulを開き、**Open as file** で開いた `SOUL.md` の親フォルダを確認する。専用スキルがすでにあれば、Skills欄に出る `skills/` の親フォルダからも確認できる。ローカルBotなら手元のシェル、別ホストで動くBotならその実行ホストのシェルを使う。実行ホスト上にdotfilesをチェックアウトし、miseを使える状態で、確認済みのBotフォルダを指定する。別ホストのパスは手元のシェルに渡さない。シェルに入れない場合は、Orcaで開けるSoulや、実行ホスト向けのエディタで開けるスキルを正本と目視で比較する。開けないファイルは実行ホストを操作できる人に反映を依頼する。差分には端末側のMarkdownが出るため、画面共有・公開ログ・CIを避ける。

   ```bash
   mise run orca-bot-diff pm "/path/to/registered-pm-folder"
   mise run orca-bot-diff reviewer "/path/to/registered-reviewer-folder"
   ```

3. 表示された差分をレビューして、SoulはOrcaの編集画面で反映する。PMの専用スキルはBotが実行中でないときに、Botフォルダの `skills/barleytea-development/SKILL.md` を実行ホストのファイルを扱えるエディタで作成またはマージする。手編集がある場合は必要な箇所だけ取り込む。再度コマンドを実行し、残った差分が意図したものか確かめる。新規チャットで反映を確認する。PMはSkills表示で専用スキルの読み込みも確認する。Reviewerは次節に従う。ステータスは一致が `0`、不足・差分ありが `1`、入力や読み取りのエラーが `2`。比較対象は正本にあるSoulと各スキルの `SKILL.md`。 [Bot security](https://orca.dev/docs/bots/security) · [1.4.272の専用スキルの読み込み](https://github.com/stablyai/orca/blob/v1.4.272/src/main/bots/bot-own-skills.ts)
4. ローカルで改善した内容は、公開できる文章だけを選んでdotfiles側へ手で反映する。ターミナルの変更を共通化する場合も、Orcaの設定画面で値を確認し、対応するGhosttyの項目をレビューして更新する。接続、アクセス権、通知、アカウントは各端末で必要に応じて管理する。個人情報を含む補足が必要ならリポジトリ外に置く。

比較タスクは読み取り専用。信頼できるチェックアウトと、指定した実行ホスト上の信頼済みBotフォルダで使う。Orcaへの登録状態は判定しない。macOS標準のルート別名を除いてディレクトリのシンボリックリンクを拒否し、比較するファイルはリンク数が1の通常ファイルに限る。検査後のファイルやディレクトリの差し替えや、マウントによる付け替えは検出できない。他者が書き換えられる場所や更新中のフォルダには使わない。

別のBotを管理するときは `modules/home/orca/bots/<名前>/SOUL.md` と必要な `skills/<スキル名>/SKILL.md` を用意する。Home ManagerやグローバルAgent Skillsの同期からは、Orcaのデータを操作しない。

別アプリからの **Import from another app…** は、旧アプリの定義を調べて取り込み計画を作る機能。Orca間には別にBotの共有リンクと受信時のレビュー画面がある。既存Botの共有画面で対象を選んでリンクを発行し、受信側で内容をレビューして新規Botを作成する。発行時に選んだ内容がアップロードされる。ここで管理する定義は、登録済みBotにも差分を見ながら反映できる。 [別アプリからの取り込み](https://orca.dev/docs/bots/import) · [1.4.272のBot共有画面](https://github.com/stablyai/orca/blob/v1.4.272/src/renderer/src/components/bots/sharing/BotShareFlow.tsx)

## Reviewerのレビュースキル

Reviewerの正本はSoulのみ。実行ホストで、Botが使うエージェントからai-guardrailsの `review-*` と `review-ui-design` を読めるようにする。DarwinとNixOSの固定版はai-guardrailsのPR #2を含み、Home Manager構成では `review-ui-design` の配置先がClaude Code向けの `~/.claude/skills/` とCodex向けの `~/.agents/skills/` に定義されている。別ホストなら、そのホストのBot実行ユーザーに配置する。手元の設定を更新しても別ホストのスキルは更新されない。 [ai-guardrails #2](https://github.com/barleytea/ai-guardrails/pull/2)

OrcaのBotと通常のエージェントでスキルの探索先が異なる場合がある。Reviewerの新規チャットで対象スキルを使えることを確かめる。見つからなければ、実行ホストのBotフォルダに正規のスキルを `skills/<スキル名>/SKILL.md` として配置し、Skills表示と新規チャットで再確認する。この配置を使う場合は、ai-guardrails更新時にローカルのコピーも見直す。レビュー依頼には対象の差分・画面と、対象プロジェクトのデザイン標準を参照できる場所を添える。 [Orca 1.4.272の専用スキル実装](https://github.com/stablyai/orca/blob/v1.4.272/src/main/bots/bot-own-skills.ts)
