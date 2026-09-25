# macOS dotfiles

Apple Silicon搭載のMac（macOS 14以降）向けに、開発ツールと設定をまとめて導入するchezmoiリポジトリです。Homebrewは`/opt/homebrew`を使用します。

## 導入内容

- HomebrewのCLI・アプリ：[Brewfile](dot_Brewfile)
- Node.js・Rust：[mise設定](private_dot_config/mise/config.toml)
- Cursor Agent・Antigravity CLI（`agy`）・Claude Code：公式インストーラーで導入
- Zsh・Zinitプラグイン・Powerlevel10k・Git・GitHub CLI・Ghosttyの設定
- Vim：[amix/vimrc](https://github.com/amix/vimrc)のAwesome版。既存の`~/.vimrc`はバックアップしてから設定

Claude Codeは自動更新に対応したネイティブ版を導入します。追加CLIは既存コマンドがあれば導入をスキップします。

Docker Desktopは公式DMGから別途導入してください。Xcode本体、SSH鍵、APIキー、各サービスの認証は自動設定しません。

## セットアップ

```bash
git clone https://github.com/HiroFumiko/dotsfile-base-for-me.git
cd dotsfile-base-for-me
./scripts/bootstrap.sh
```

Gitが使えない場合は、GitHubからZIPをダウンロードして展開し、そのディレクトリで`./scripts/bootstrap.sh`を実行します。

- Command Line Toolsが未導入の場合はインストール画面が開きます。完了後にbootstrapを再実行してください。
- Gitの名前・メールアドレスを初回に入力します。Homebrew導入時には管理者パスワードを求められる場合があります。
- 既存の設定はリポジトリの内容で更新されます。bootstrapは差分を表示した後、そのまま適用します。

完了後は新しいターミナルを開き、[手動確認リスト](docs/post-install-checklist.md)に沿ってアプリの起動・認証を確認してください。

導入に失敗した場合は原因を解消し、初期化前ならbootstrap、設定適用中なら`chezmoi apply`を再実行します。導入後のツール更新は各ツールの更新機能で行います。

## ローカル設定

APIキーや端末固有の設定は`~/.config/zsh/local.zsh`に記述します。ひな型は`~/.config/zsh/local.zsh.example`です。`local.zsh`はGit管理外で、Zsh初期化の最後に読み込まれます。

Gitの追加設定は`~/.config/git/local.config`に記述できます。設定変更をリポジトリへ取り込むには`chezmoi re-add`を使い、コミット前に差分を確認してください。

## 検証

導入済みツール・設定ファイルの存在を確認します。アプリの動作や認証状態は別途確認してください。

```bash
./scripts/check.sh
```

リポジトリの回帰テストは、実際のツールをインストールせずに実行できます（Python 3が必要です）。

```bash
python3 scripts/test-bootstrap.py
bash scripts/test-cli-install.sh
bash scripts/test-vim-install.sh
zsh -f scripts/test-shell.zsh
zsh -f scripts/test-completion.zsh
```
