---
published: true
type: idea
topics:
  - neovim
emoji: 📋
title: lemonadeでssh先のneovimとクリップボードを共有
---

> この記事は [https://knowledge.nazo6.dev/blog/lemonade-neovim-clipboard](https://knowledge.nazo6.dev/blog/lemonade-neovim-clipboard) とのクロスポストです。


[lemonade](https://github.com/lemonade-command/lemonade)を使えばTCP通信を用いてクリップボードを共有できます。

:::message
デフォルトでlemonadeは通信を暗号化しないので注意。
セキュアな通信がしたい場合[SSHポートフォワーディングを使うように案内されています](https://github.com/lemonade-command/lemonade#secure-tcp-connection)。
:::

# 手順
1. SSH元とSSH先にlemonadeを[ここ](https://github.com/lemonade-command/lemonade/releases)からダウンロードしてパスを通しておく。
2. SSH先のneovimにclipboard providerを設定する
```lua
local ssh_connection
for w in vim.env.SSH_CONNECTION:gmatch "[^%s]+" do
  ssh_connection = w
  break
end

vim.g.clipboard = {
  name = "lemonade2",
  copy = {
    ["+"] = { "lemonade", "copy", "--host=" .. ssh_connection },
    ["*"] = { "lemonade", "copy", "--host=" .. ssh_connection },
  },
  paste = {
    ["+"] = { "lemonade", "paste", "--host=" .. ssh_connection },
    ["*"] = { "lemonade", "paste", "--host=" .. ssh_connection },
  },
  cache_enabled = 0,
}
```
   hostは`~/.config/lemonade.toml`でも設定できますが、色々なipから繋げられるように動的に設定しています。
3. SSH元の`lemonade.toml`を設定する。
   `lemonade.toml`の`allow`を指定して接続できるクライアントを指定します。
   ```toml:lemonade.toml
   allow = 'ここにipをいれる'
```
4. これでssh先のneovimとクリップボードが共有されてるはずです。