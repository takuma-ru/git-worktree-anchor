# git-worktree-anchor

## GWSL: Git Worktree Shared Linker

GWSL は、Git worktree を用いた開発環境において、Git 管理外のローカル設定ファイルを各 worktree へ配置するための補助機構である。

`.git/shared/` に配置されたファイルを、`post-checkout` フックの実行時に作業ツリー直下へシンボリックリンクとして展開する。これにより、`.env.local` や `.vscode/settings.local.json` のような、リポジトリへコミットしない開発用ファイルを複数の worktree 間で共有できる。

## 前提

- Git 管理下のリポジトリで使用すること。
- macOS、Linux、または WSL 上の Bash 環境を想定する。
- 対象リポジトリには `.git/shared/` と `.git/hooks/post-checkout` が設定済みであること。
- `.git/` 配下の内容は Git のコミット対象ではないため、別のクローンで使用する場合は同じ設定を再度作成する必要がある。

## 共有ファイルの登録

共有したいファイルを `.git/shared/` 配下に配置する。

例:

```bash
mkdir -p .git/shared/.vscode
cp .env.local .git/shared/.env.local
cp .vscode/settings.local.json .git/shared/.vscode/settings.local.json
```

`.git/shared/` 配下のディレクトリ構造は、作業ツリー側にもそのまま反映される。

例えば、次のファイルを配置した場合:

```text
.git/shared/.env.local
.git/shared/.vscode/settings.local.json
```

フック実行後、作業ツリー側には次のリンクが作成される。

```text
.env.local -> .git/shared/.env.local
.vscode/settings.local.json -> .git/shared/.vscode/settings.local.json
```

## 実行方法

通常は、ブランチのチェックアウト時に Git が `post-checkout` フックを実行する。

```bash
git checkout <branch>
```

worktree を追加した後に対象 worktree 内でチェックアウトが発生すると、`.git/shared/` に登録されたファイルが自動的にリンクされる。

手動で動作確認する場合は、次のように実行する。

```bash
.git/hooks/post-checkout
```

## 動作確認

次の手順で、`.env.local` のリンク作成を確認できる。

```bash
echo "EXAMPLE=1" > .git/shared/.env.local
.git/hooks/post-checkout
ls -l .env.local
```

`.env.local` が `.git/shared/.env.local` を参照するシンボリックリンクとして表示されれば、設定は有効である。

## 注意事項

`.env.local` が既に作業ツリー側に存在する場合、フックは処理を終了する。これは既存のローカル設定を不用意に上書きしないためである。

共有対象に機密情報を含める場合は、`.git/shared/` が Git 管理外であることを確認すること。また、ファイルの取り扱いは各開発環境の権限管理に従うこと。

この仕組みは Git フックに依存するため、フックが無効化されている環境、または `.git/hooks/post-checkout` に実行権限がない環境では動作しない。
