---
title: "Neovim専用おすすめプラグイン集"
emoji: "🔖"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["Neovim", "Vim"]
published: false
---

# Neovim 専用プラグインについて

Neovim は Vim に積極的に新機能を取り入れることを目的としたコミュニティ主導のフォークです。従来の Vimscript に加えて Lua の実行環境である LuaJIT が搭載されていることが最大の特徴で、この Lua を使ってプラグインや設定を書くことができます。Lua には、

- Vimscript に比べて文法が馴染みやすい
- 速い(LuaJIT は数あるスクリプト言語実行環境のなかでも特に高速なことで有名)
- LSP や tree-sitter などの Neovim の新機能が Lua から使うことが実質前提になっている

といったメリットがあるため、最近、Lua で書かれた Neovim 専用プラグインが急速に増加しています。

Neovim の公式サイトには Vimscript を非推奨にすることは無いと書かれていますが、海外コミュニティを見るとなるべく Vimscript を排除して Lua のプラグインを使おうとする傾向が強くなっており、これからさらに Vim と Neovim 間のプラグインの分断が進むと思われます。
この傾向が良いのか悪いのかは分かりませんが、この記事ではそんな Neovim 専用プラグインについて主に自分が使っているものをカテゴリ別に紹介していきたいと思います。

## この記事で扱うプラグインについて

- 原則 Neovim 専用で、Lua で書かれているもの

## 環境

- Windows/Linux
- Neovim 0.6 以上

# プラグインマネージャ

## [packer.nvim](https://github.com/wbthomason/packer.nvim)

Lua 製パッケージマネージャでは圧倒的優勢でほぼこれ一択。Vim にネイティブ搭載されているパッケージ管理機能(`:packadd`)を基盤としていて、遅延読み込みなどのパフォーマンスチューニング機能も豊富なパッケージマネージャです。

解説記事としては
https://qiita.com/delphinus/items/8160d884d415d7425fcc
こちらの記事が一番詳しくまとまっていて良いと思います。

ただ、`dein.vim`と比較すると速度が遅くなったとのことですが、少なくとも自分の環境においてはあまり差がありませんでした。アップデートによって改善が続いているので、 パフォーマンス面で不安があって乗り換えをためらっているという方も是非一度試してみてほしいと思います。

# ファイラー

## [nvim-tree](https://github.com/kyazdani42/nvim-tree.lua)

高機能なファイラです。Neovim に組込まれている`vim.loop`という API(実態は libuv)を利用しているため高速です。また、Git や後述の nvim-lsp と連携することができ、いい感じの設定をすると ↓ のようになります。

![](/images/neovim-plugins/nvim-tree.png)

# 見た目系

## [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)

ステータスラインは Neovim 専用のものだけでも様々なプラグインが乱立していてカオスな様相ですが、おそらく一番メジャーであると思われるプラグインです。設定も直感的でわかりやすいと思います。

## [windline.nvim](https://github.com/windwp/windline.nvim)

筆者が使っているステータスラインプラグインです。デフォルトで用意されている設定以外を使おうとするとまあまあ設定が難しいですが、その分細かいところまで調整ができます。また、`Floating window statusline`という面白い機能があり、ステータスラインを floating window 上に置いてバッファごとのステータスラインを隠すことによって、VSCode などのように一画面一ステータスラインを実現することができます。ただまだバグが多く自分は使っていません。

自分の設定はこんな感じです ↓

![](/images/neovim-plugins/windline.png)

## [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)

画面上部に開いているバッファの一覧をタブのように表示してくれます。nvim-lsp に対応しています。また、マウスでも操作できるのが地味に便利です。

## [nvim-scrollview](https://github.com/dstein64/nvim-scrollview)

バッファごとにスクロールバーを表示してくれるプラグインです。見た目だけでなく実際にマウスで動かせるので非常に重宝しています。

# ファジーファインダ

## [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

乱立しがちと言われるファジーファインダーですが、Lua 製の物となるとほぼこの`telescope.nvim`一択と言っていいのではないかと思います。他にもファジーファインダはあるのですが、多くのプラグインが telescope のソースを提供しているため、telescope を使ったほうがいいと思います。

# LSP/補完

LSP(Language Server Protocol)は、あらゆるエディタと言語の組み合わせで補完などの機能を提供するためのプロトコルです。Neovim 0.5 以降 LSP クライアントが標準搭載されており、高速な LSP クライアント実装を利用できます。
LSP の設定の詳細については別の記事を書いたので是非見てみてください。

https://zenn.dev/articles/c2f16b07798bab/edit

## [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)

実質の必須プラグインです。確かに LSP クライアントはプラグインなしで利用できるのですが、LSP サーバーを起動する方法や事前に必要な設定は言語ごとに異なるため、言語ごとの設定を提供するこのプラグインが必要になります。

## [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer)

こちらもほぼ必須と言っていいのではないかと思います。LSP サーバーを Neovim 内からインストールするためのプラグインです。`LspInstallInfo`コマンドでインストールするための UI がでてくるので使いやすいです。

## [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

Neovim Lua 界では実質の標準と言えるプラグインです。LSP への対応度が高く、また VSCode での動作を再現できるように作られていることが多いので妙な動作に困ることなく使えるのではないかと思います。
また、最近 cmdline の補完に対応してさらに便利になりました。

## [lsp_signature.nvim](https://github.com/ray-x/lsp_signature.nvim)

関数内の引数を入力しているときにシグネチャヘルプを表示するためのプラグインです。

# Treesitter (シンタックスハイライト)

`tree-sitter`は軽量な構文解析エンジンです。LSP との違いは、単一ファイルのみによる解析であり、さらにネイティブバイナリを使用するため高速です。Neovim では主にシンタックスハイライトのために使われますが、他の用途にも使うことができます。

## [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

Neovim での目玉新機能の一つがこの tree-sitter です。tree-sitter はもともと Atom エディタのために開発されたもので、ファイルにまたがらない構文解析を高速で実行し、高度なシンタックスハイライト等を提供します。そして tree-sitter は Neovim に組み込みではありますが、各言語用のパーサをダウンロードしたりなどする必要があるので、それをよしなにやってくれるのがこのプラグインです。

## [nvim-treesitter-context](https://github.com/romgrk/nvim-treesitter-context)

先述の他の用途の一例です。下の画像のように、現在いるブロックをわかりやすく表示してくれるプラグインです。

![](/images/neovim-plugins/nvim-treesitter-context.png)

# カラースキーム

カラースキームは基本的には`treesitter`に対応したものを選ぶといいと思います。そうでないとせっかく`treesitter`を有効にしてもうまくハイライトされません。
