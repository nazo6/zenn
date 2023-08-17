-- lazy.nvimをインストール
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }
end
vim.opt.runtimepath:prepend(lazypath)

-- プラグインをインストール
require("lazy").setup({
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },

  { "L3MON4D3/LuaSnip" },

  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "saadparwaiz1/cmp_luasnip" },

  -- null-ls
  { "jose-elias-alvarez/null-ls.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
}, {})

local lsp_settings = {
  -- LSPクライアントがバッファにアタッチされたときに実行される
  on_attach = function(client, bufnr)
    -- LSPサーバーの組み込みフォーマット機能を無効にするには下の行をコメントアウト
    -- 例えばtypescript-language-serverにはコードのフォーマット機能が付いているが代わりにprettierでフォーマットしたいときなどに使う
    -- client.resolved_capabilities.document_formatting = false

    local set = vim.keymap.set
    set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
    set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
    set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
    set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
    set("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
    set("n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>")
    set("n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>")
    set("n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>")
    set("n", "<space>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
    set("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>")
    set("n", "<space>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>")
    set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
    set("n", "<space>e", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>")
    set("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>")
    set("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")
    set("n", "<space>q", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>")
    set("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>")
  end,
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
}

require("mason").setup()
require("mason-lspconfig").setup()
require("mason-lspconfig").setup_handlers {
  function(server_name)
    require("lspconfig")[server_name].setup(lsp_settings)
  end,
}

-- nvim-cmp(補完) の設定
vim.opt.completeopt = "menu,menuone,noselect"

local cmp = require "cmp"
cmp.setup {
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = {
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm { select = true },
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
  }),
}

-- null-ls (formatter/linter)の設定
local null_ls = require "null-ls"
null_ls.setup {
  sources = {
    null_ls.builtins.formatting.prettier.with {
      prefer_local = "node_modules/.bin",
    },
  },
}
