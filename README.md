# macOS dotfiles

新しいMacへ、現在とほぼ同じ使い勝手の開発環境を、その時点の最新版で再構築するためのchezmoiリポジトリです。

新Macの初回構築時に一度実行し、ツールの導入と設定配置を自動化します。アプリの動作・認証・初回設定の完了判定は対象外で、導入後に本人が[手動確認リスト](docs/post-install-checklist.md)で確認します。このリポジトリをバージョン更新のために再実行する運用は想定せず、更新は各ツール・パッケージ管理ツールの仕組みに任せます。

対象はmacOS 14以降のApple Silicon（Mシリーズ）搭載Macです。Homebrewは`/opt/homebrew`を使用します。Intel Macは対象外です。

## 方針

- Homebrewのformula/caskは`~/.Brewfile`から最新版を導入する
- シェル、Git、mise、Powerlevel10k、Ghosttyなどの設定はchezmoiで管理する
- Powerlevel10k本体はHomebrewで導入し、Zinitでは導入しない
- プロジェクト固有のランタイムと依存関係は各リポジトリの設定・lockfileを優先する
- SSH鍵、APIキー、認証情報、履歴、キャッシュは管理しない
- Xcodeやログインが必要なアプリは手動手順として残す
- OMXはCodexハーネス側で管理するプラグインのため、dotfilesでは導入・設定・runtimeリンクを管理しない

## 追加CLIの導入方針

以下は追加CLIの導入方針です。必要な3種類は導入処理に反映済みです。不要なCLIを既存Macからアンインストールする処理はありません。

| CLI | 新Macへ引き継ぐ |
|---|---|
| Cursor Agent（`agent` / `cursor-agent`） | 必要 |
| Antigravity CLI（`agy`） | 必要 |
| Proton Pass CLI（`pass-cli`） | 不要 |
| Maestro（`maestro`） | 不要 |
| Android Platform Tools（`adb` / `fastboot`） | 不要 |
| Claude Code（`claude`） | 必要 |
| CodeGraph（`codegraph`） | 不要 |
| Antigravity IDE用CLI（`agy-ide`） | 不要 |
| OpenClaude（`openclaude`） | 不要 |
| Kaggle CLI（`kaggle`） | 不要 |
| QMK・ARM・AVRツール群 | 不要 |

Cursorは今回の選択肢のCursor Agent、`agy`は`agy-ide`とは別のCLIとして扱います。必要な追加CLIは公式インストーラーで導入します。

追加の選定で`oh-my-claude-sisyphus`・`pyenv`・`emacs`も導入対象から除外しました。pyenvのシェル初期化・PATH・プロンプト設定・導入後チェックも外しています。

`neofetch`・`chromedriver`も導入対象外です。Maestro専用に追加したOpenJDK・Java環境設定と、Proton Pass／Maestro用のtapも除外しています。

### 導入元

| CLI | 新Macでの導入元 |
|---|---|
| Cursor Agent | [公式インストーラー](https://cursor.com/install) |
| `agy` | [公式インストーラー](https://antigravity.google/cli/install.sh) |
| Claude Code | [公式ネイティブインストーラー](https://claude.ai/install.sh) |

Claude Codeは[公式推奨のネイティブ導入方式](https://code.claude.com/docs/en/setup)を使用し、導入後はバックグラウンドで自動更新されます。`claude`を起動し、認証・初回設定を行ってください。

Cursor Agent・`agy`・Claude Codeは、chezmoiの設定ファイル配置前に未導入の場合だけ公式インストーラーを実行します。curlによるダウンロードが完了してからbashで実行します。インストーラーによるシェル設定変更後、chezmoiが管理設定を配置します。途中で失敗した場合は原因を解消して`chezmoi apply`を再実行します。個別に再試行する場合は`bash scripts/install-extra-cli.sh`を実行できます（未導入のCLIをインストールします）。既に`claude`が存在する場合は導入元を変更しません。

Android Platform Tools・Android SDK・エミュレーターは自動導入の対象外です。

## 新しいMacでのセットアップ

### 最初の準備

1. 対象がmacOS 14以降のApple Silicon搭載Macであることを確認します。
2. [このリポジトリ](https://github.com/HiroFumiko/dotsfile-base-for-me)を新Macへ取得します。Gitが使える場合は`git clone https://github.com/HiroFumiko/dotsfile-base-for-me.git`を実行し、未導入の場合はZIPを取得して展開する方法でも構いません。
3. ターミナルで、取得したリポジトリのディレクトリへ移動します。以下のコマンドはそのディレクトリ内で実行します。

### 自動導入

```bash
./scripts/bootstrap.sh
```

スクリプトはHomebrewとchezmoiを用意し、このリポジトリの設定を適用します。Homebrewの導入は`bootstrap.sh`だけで行うため、新Macでは必ずこのスクリプトから開始します。Gitの名前とメールアドレスは初回適用時に入力します。

- Command Line Toolsが未導入の場合、インストール画面を開いてスクリプトは終了します。画面の操作を完了してから、`./scripts/bootstrap.sh`を再実行してください。
- Homebrew導入時にパスワード入力や確認を求められた場合は、本人がターミナル上で対応してください。パスワードを文書やエージェントへのメッセージに記載する必要はありません。
- Gitの名前とメールアドレスには、新Macでコミット時に使用する値を入力します。
- `Installation complete.`が表示されたら自動導入は完了です。新しいターミナルを開き、[導入後の手動確認リスト](docs/post-install-checklist.md)へ進みます。

### 途中で失敗した場合

通常は初回に一度実行します。再実行は導入失敗の復旧用で、バージョン更新のためには使いません。

- Homebrew・chezmoiの準備や初期化が終わる前に停止した場合は、原因を解消して`./scripts/bootstrap.sh`を再実行します。
- chezmoiによる適用中に停止した場合は、失敗した工程とエラーを確認し、原因を解消して`chezmoi apply`を再実行します。
- 成功済みの処理にはスキップ条件がありますが、すべての処理が実行されないとは限りません。再実行時にも表示される差分や出力を確認してください。
- 既存ファイル・ディレクトリとの衝突は、自動削除して解決しないでください。Vim設定のバックアップについては下記の「Vim」を参照してください。

### 変更内容の事前確認

Homebrewとchezmoiが導入済みで、適用前に変更内容だけ確認したい場合は次を実行します。

```bash
chezmoi init --source "$PWD"
chezmoi diff
```

## 外部エージェントへ実行を任せる場合

実行範囲はツールの導入と設定配置までです。次のルールで引き継ぎます。

1. 対応OS・チップと作業ディレクトリを確認し、`./scripts/bootstrap.sh`から開始する。
2. 本人によるパスワード入力・インストーラー画面の操作が必要な場合は、その工程を案内して待つ。
3. 失敗時は、失敗した工程・コマンド・エラーを報告する。原因が明らかな場合は上記の再試行手順に従う。
4. 既存ツールや設定の削除、不要物の整理、更新目的の再実行を勝手に行わない。Gitコミット・リモート設定も今回の導入作業には含めない。
5. 導入処理が成功したら終了し、本人へ[手動確認リスト](docs/post-install-checklist.md)を渡す。アプリのログイン・初回設定・実用上の動作確認を自動処理の完了条件に加えない。

## Vim

Vim設定は[amix/vimrcのAwesome版](https://github.com/amix/vimrc#how-to-install-the-awesome-version)を使用します。初回適用時に公式リポジトリを`~/.vim_runtime`へ浅くcloneし、公式の`install_awesome_vimrc.sh`で`~/.vimrc`を生成します。

`.vimrc`と`.vim_runtime`はchezmoiのファイル管理対象外です。参照設定のコピーはこのリポジトリに置きません。既存の公式checkoutは更新せず再利用し、既存の`.vimrc`は上書き前に`~/.vimrc.before-amix.XXXXXX`へバックアップします。別の取得元や不完全なディレクトリがある場合は、自動削除せずエラーで停止します。

導入失敗後は原因を解消して`chezmoi apply`で再試行できます。導入時に設定の再生成が必要な場合は`bash scripts/install-vim.sh`を実行します。

`bash scripts/test-vim-install.sh`で、新規導入・既存設定のバックアップ・異なる取得元の拒否・clone失敗を一時ディレクトリ内で検証できます。Gitと公式インストーラーはモックし、現MacのVim設定は変更しません。

## ローカル専用設定

zsh設定は次の役割で分けています。

| ファイル | 役割 |
|---|---|
| `~/.zshrc` | シェル・プロンプト・ランタイムの初期化、基本alias |
| `~/.config/zsh/personal.zsh` | Mac間で共有する個別設定：OpenMPビルド設定 |
| `~/.config/zsh/local.zsh` | 秘密値・端末ごとの上書き。最後に読み込み、Git管理外 |

個別設定は`private_dot_config/zsh/personal.zsh`にまとめています。参照するCLIや作業ディレクトリ自体をインストールするものではありません。

APIキーなど、Gitへ保存しない値は次のファイルに置きます。

```text
~/.config/zsh/local.zsh
```

雛形は適用後の`~/.config/zsh/local.zsh.example`です。`local.zsh`自体はこのリポジトリでは管理しません。

## 次のMacに向けた設定の記録

設定ファイルを変更した後はchezmoiへ取り込みます。

```bash
chezmoi re-add
chezmoi cd
git status
```

新しいアプリをHomebrewで追加した場合は、`~/.Brewfile`も更新します。Brewfileはバージョンを固定しないため、新しいMacでは原則として実行時点の最新版が入ります。

## 導入後の確認

本人が[手動確認リスト](docs/post-install-checklist.md)に沿って確認します。アプリ別の詳細な初回設定手順や、使用可能かどうかの自動判定はこのリポジトリでは管理しません。

## 検証

```bash
./scripts/check.sh
```

`check.sh`は任意の導入物チェックです。ツール・ファイルの存在とBrewfileの充足状態だけを確認し、アプリの実起動・認証・プロジェクトのビルドは行いません。

設定整理時の回帰確認は`zsh -f scripts/test-shell.zsh`で実行します。実際のプラグインや秘密値を読み込まず、alias・環境変数・PATHを確認します。

補完の回帰確認は`zsh -f scripts/test-completion.zsh`で実行します。一時的な`ZDOTDIR`とプラグインのモックを使い、実際の`compinit`でGit・追加補完・Zinitの補完登録を確認します。独立したシェルを2回起動し、初回の補完キャッシュ作成と2回目の起動を検証します。現Macのプラグインや秘密値は読み込みません。

導入処理の回帰確認は`bash scripts/test-cli-install.sh`で実行します。ダウンロード・インストーラーをモックし、既存CLIのスキップ、新規導入、ダウンロード失敗、インストーラー失敗、導入後のコマンド欠落を確認します。実際のCLI導入や削除は行いません。

bootstrapの回帰確認は、開発用のPython 3環境で`python3 scripts/test-bootstrap.py`を実行します。CLT・Homebrew・chezmoiをモックし、取得途中で失敗したスクリプトが実行されないこと、既存Homebrewのスキップ、導入失敗時の停止を確認します。新Macへの通常の導入処理にPython 3は不要です。
