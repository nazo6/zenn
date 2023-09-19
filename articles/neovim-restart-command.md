---
published: true
created: 2023-05-02T00:00:00+09:00
updated: 2023-05-02T00:00:00+09:00
tags:
  - tech/software/neovim
type: idea
slug: neovim-restart-command
topics:
  - lua
  - neovim
emoji: 💭
title: Neovimを再起動するコマンドを作ったら結構よかった
---
> この記事は [https://knowledge.nazo6.dev/blog/2023/05/02/neovim-restart-command](https://knowledge.nazo6.dev/blog/2023/05/02/neovim-restart-command) とのクロスポストです。



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

# 感想

自動でセッションのロード/保存をしている人にとってはあまり気にする問題ではないのかもしれませんが自分は普段セッションをあまり使わないのでこのコマンドでNeovim盆栽イテレーションを速く回せるようになった気がします。
設定をいじってる時以外でもなんか調子悪いから再起動したいけどこのワークスペースを維持したいという時にも結構便利でよかったです。
