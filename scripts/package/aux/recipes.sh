#!/usr/bin/env bash
# vim: filetype=sh

source "${DOTFILES}/scripts/core/main.sh"

TMP_DIR="$(fs::tmp)"
MODULES_FOLDER="${DOTFILES}/modules"

recipe::folder() {
   echo "${TMP_DIR}/${1}"
}

git::url() {
   local -r user="$1"
   local -r repo="$2"
   local -r host="${DOT_GIT_HOST:-github.com}"

   local -r git_name="$(git config user.name || echo "")"
   local -r rsa_file="$HOME/.ssh/id_rsa"

   if platform::command_exists ssh && [[ -n "$git_name" ]] && [[ -f "$rsa_file" ]]; then
      echo "git@${host}:${user}/${repo}.git"
   else
      echo "https://${host}/${user}/${repo}"
   fi
}

recipe::shallow_git_clone() {
   local -r user="$1"
   local -r repo="$2"
   local -r folder="$(recipe::folder "$repo")"
   mkdir -p "$folder" || true
   sudo chmod 777 "$folder" || true
   yes | git clone "$(git::url $user $repo)" --depth 1 "$folder" || true
}

recipe::shallow_github_clone() {
   export DOT_GIT_HOST="${DOT_GIT_HOST:-github.com}"
   recipe::shallow_git_clone "$@"
}

recipe::shallow_gitlab_clone() {
   export DOT_GIT_HOST="${DOT_GIT_HOST:-gitlab.com}"
   recipe::shallow_git_clone "$@"
}

recipe::make() {
   local -r repo="$1"
   cd "$(recipe::folder "$repo")"
   make && sudo make install
}

recipe::abort_installed() {
   local -r cmd="$1"
   log::warning "${cmd} already installed"
   exit 0
}

recipe::abort_if_installed() {
   local -r cmd="$1"
   if platform::command_exists "$cmd"; then
      recipe::abort_installed "$cmd"
   fi
}

recipe::has_submodule() {
   local -r module="$1"
   local -r probe_file="${2:-}"

   local -r module_path="${MODULES_FOLDER}/${module}"

   if [[ -n $probe_file ]]; then
      local -r probe_path="${module_path}/${probe_file}"
      fs::is_file "$probe_path"
   else
      fs::is_dir "$module_path"
   fi
}

recipe::clone_as_submodule() {
   local -r user="$1"
   local -r repo="$2"
   local -r module="${3:-$repo}"

   local -r module_path="${MODULES_FOLDER}/${module}"
   git::url $user $repo
   yes | git clone "$(git::url $user $repo)" --depth 1 "$module_path"

   cd "$module_path"
   git submodule init &2> /dev/null \
      && git submodule update &2> /dev/null \
      || true
}

recipe::install_from_git() {
   local -r repo="$(echo "$@" | tr ' ' '/')"

   local -r package="$(basename "$repo")"
   local -r path="/opt/${package}"

   cd "/opt"
   git clone "https://github.com/${repo}" --depth 1
   cd "$path"

   if [ -f build.sh ]; then
      ./build.sh
   elif [ -f Makefile ]; then
      make install
   fi
}
