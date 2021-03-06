#!/usr/bin/env bash

if platform::is_osx && platform::command_exists ggrep; then
   sed() { gsed "$@"; }
   awk() { gawk "$@"; }
   find() { gfind "$@"; }
   grep() { ggrep "$@"; }
   head() { ghead "$@"; }
   mktemp() { gmktemp "$@"; }
   ls() { gls "$@"; }
   date() { gdate "$@"; }
   shred() { gshred "$@"; }
   cut() { gcut "$@"; }
   tr() { gtr "$@"; }
   od() { god "$@"; }
   cp() { gcp "$@"; }
   cat() { gcat "$@"; }
   sort() { gsort "$@"; }
   kill() { gkill "$@"; }
   xargs() { gxargs "$@"; }
   readlink() { greadlink "$@"; }
   export -f sed awk find head mktemp date shred cut tr od cp cat sort kill xargs readlink
fi
