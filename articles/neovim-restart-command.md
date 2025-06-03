---
published: true
type: idea
topics:
  - lua
  - neovim
emoji: 💭
title: Neovimを再起動するコマンドを作ったら結構よかった
---

# Luaのリロード

Neovim盆栽をしていると設定をリロードしたい時が結構というかかなりあります。Vimscriptであれば`source ~/.vimrc`とすればまあ大体うまくいっていた気がするのですがLuaではそうもいきません。
Luaの`require`のキャッシュを消してやればもう一度読み込めるとかは言われていますが世の中のLuaプラグインはsetupを2回以上呼んだりするとおかしくなったりする物が大抵なのでこの方法でもあんまりうまくいきません。

# 再起動が一番

そんなわけでそういう時はneovimを再起動してやるのが一番なんですが前の状態が復元されないといろいろ面倒くさいです。
そこで再起動前のセッションを保存して次回の起動時に自動でそのセッションを読み込んでくれる簡単なコマンドを書きました。

```lua
local restart_cmd = nil

if vim.g.neovide then
  if vim.fn.has "wsl" == 1 then
    restart_cmd = "silent! !nohup neovide.exe --wsl &"
  else
    restart_cmd = "silent! !neovide.exe"
  end
elseif vim.g.fvim_loaded then
  if vim.fn.has "wsl" == 1 then
    restart_cmd = "silent! !nohup fvim.exe &"
  else
    restart_cmd = [=[silent! !powershell -Command "Start-Process -FilePath fvim.exe"]=]
  end
end

vim.api.nvim_create_user_command("Restart", function()
  if vim.fn.has "gui_running" then
    if restart_cmd == nil then
      vim.notify("Restart command not found", vim.log.levels.WARN)
    end
  end

  require("possession.session").save("restart", { no_confirm = true })
  vim.cmd [[silent! bufdo bwipeout]]

  vim.g.NVIM_RESTARTING = true

  if restart_cmd then
    vim.cmd(restart_cmd)
  end

  vim.cmd [[qa!]]
end, {})

vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    if vim.g.NVIM_RESTARTING then
      vim.g.NVIM_RESTARTING = false
      require("possession.session").load "restart"
      require("possession.session").delete("restart", { no_confirm = true })
      vim.opt.cmdheight = 1
    end
  end,
})
```

これで`Restart`コマンドが定義できましたが、CUIでは実際には再起動しているのではなくセッションを保存して終了するだけです。次のnvimの起動時にセッションを読み込みます。GUIで起動された時には本物の再起動になります。

セッションの保存には[possession.nvim](https://github.com/jedrzejboczar/possession.nvim)を使っています。他のプラグインであったり通常の`:mksession`でもまあ同じ感じだと思います。

## 追記(2025/06)
Neovim 0.12 (現時点のnightly)で`restart`コマンドが実装されました！これはNeovimのUI部分はそのまま、コア部分のみを再起動できるコマンドです(NeovimではUI部分がclient,コア部分がserverと呼ばれており、このコマンドはserverを再起動します)。これを使えばNeovimを終了することなく再起動を行うことができます。GUIクライアントについてはそれぞれで対応が必要なようですがそのうちできるようになるでしょう

ただ、`restart`コマンドではセッションは復元されないので私は`possession.nvim`を用いて以下のようにセッション復元を行う`Restart`コマンドを使っています。

```lua
vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    if vim.g.NVIM_RESTARTING then
      vim.g.NVIM_RESTARTING = false
      local session = require "possession.session"
      local ok = pcall(session.load, "restart")
      if ok then
        require("possession.session").delete("restart", { no_confirm = true })
        vim.opt.cmdheight = 1
      end
    end
  end,
})

vim.api.nvim_create_user_command("Restart", function()
  require("possession.session").save("restart", { no_confirm = true })
  vim.cmd [[silent! bufdo bwipeout]]

  vim.g.NVIM_RESTARTING = true

  vim.cmd [[restart!]]
end, {})

```

# 感想

自動でセッションのロード/保存をしている人にとってはあまり気にする問題ではないのかもしれませんが自分は普段セッションをあまり使わないのでこのコマンドでNeovim盆栽イテレーションを速く回せるようになった気がします。
設定をいじってる時以外でもなんか調子悪いから再起動したいけどこのワークスペースを維持したいという時にも便利です。


> この記事は [https://note.nazo6.dev/blog/neovim-restart-command](https://note.nazo6.dev/blog/neovim-restart-command) とのクロスポストです。