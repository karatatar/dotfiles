#!/usr/bin/env bash
# vim: filetype=sh
set -euo pipefail

spacevim::is_installed() {
   cat "$HOME/.config/nvim/init.vim" 2>/dev/null | grep -q "space-vim" 2>/dev/null
}

spacevim::depends_on() {
   coll::new curl nvim
}

spacevim::install() {
   bash <(curl -fsSL https://raw.githubusercontent.com/liuchengxu/space-vim/master/install.sh)
}

