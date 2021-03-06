# ==============================
# Constants
# ==============================

export LOCAL_BIN="${DOTFILES}/local/bin"
export LOCAL_TMP="${DOTFILES}/local/tmp"
export LOCAL_ZSHRC="${DOTFILES}/local/zshrc"
export LOCAL_GITCONFIG="${DOTFILES}/local/gitconfig"

export TMP_DIR="$(fs::tmp)"
export BIN_DIR="$(fs::bin)"
export MAIN_BIN_DIR="${DOTFILES}/bin"

# ==============================
# Helpers
# ==============================

has_tag() {
   str::contains "$@"
}

get_git_info() {
   cd "$DOTFILES"

   git log -n 1 --pretty=format:'%ad - %h' --date=format:'%Y-%m-%d %Hh%M' \
      || echo "unknown version"
}


# ==============================
# Filesystem
# ==============================

setup_folders_and_files() {

   echo
   log::note "Setting up folder and file hierarchy..."
   mkdir -p "$LOCAL_BIN" || true
   mkdir -p "$LOCAL_TMP" || true
   mkdir -p "$BIN_DIR" || true
   mkdir -p "$TMP_DIR" || true
   mkdir -p "$LOCAL_BIN" || true
   mkdir -p "$MAIN_BIN_DIR" || true
   touch "$LOCAL_ZSHRC" || true
   touch "$LOCAL_GITCONFIG" || true

}


# ==============================
# Fixes
# ==============================

fix_locales() {
   if platform::command_exists locale-gen; then
      echo
      log::note "Fixing locales..."
      locale-gen en_US en_US.UTF-8
   fi
}


# ==============================
# Prompts
# ==============================

feedback::maybe() {
   local -r fn="$1"
   local -r value="$2"
   if [ -n "$value" ]; then
      echo "$value"
   else
      shift 2
      "$fn" "$@"
   fi
}

feedback::maybe_text() {
   feedback::maybe feedback::text "$@"
}

feedback::maybe_select_option() {
   feedback::maybe feedback::select_option "$@"
}

feedback::maybe_confirmation() {
   local -r value="$1"
   if [ -n "$value" ]; then
      if $value; then
         return 0
      else
         return 1
      fi
   else
      shift
      feedback::confirmation "$@"
   fi
}


setup_git_credentials() {

   if ! grep -q "email" "$LOCAL_GITCONFIG" 2> /dev/null; then
      echo
      log::note "Your git credentials aren't setup"
      local -r fullname="$(feedback::maybe_text "${DOT_INSTALL_NAME:-}" "What is your name?")"
      local -r email="$(feedback::maybe_text "${DOT_INSTALL_EMAIL:-}" "What is your email?")"
      echo -e "[user]\n   name = $fullname\n   email = $email" > "$LOCAL_GITCONFIG"
   fi

}

setup_docopts() {

   if [[ -n "${DOT_DOCOPTS:-}" ]]; then
      return 0
   fi

   echo
   local -r backend="$(echo "bash python go" | tr ' ' '\n' | feedback::maybe_select_option "${DOT_INSTALL_DOCOPTS:-}" "What backend do you want for docopts?")"

      if [[ -z "${backend:-}" ]]; then
         log::error "Invalid option"
         exit 3
      fi

      echo "export DOT_DOCOPTS=$backend" >> "$LOCAL_ZSHRC"

      case $backend in
         go) dot pkg add docopts-go ;;
         python) dot pkg add python ;;
         bash) dot pkg add docoptsh ;;
      esac

   }

   setup_nvim_fallback() {

      if ! platform::command_exists nvim; then
         echo
         log::warning "neovim isn't installed"
         if feedback::maybe_confirmation "${DOT_INSTALL_NVIM:-}" "Do you want to setup a fallback?"; then
            if ! platform::command_exists vi && ! platform::command_exists vim; then
               dot pkg add nvim
            fi
            if platform::command_exists vi && ! platform::command_exists vim; then
               sudo ln -s "$(which vi)" "${BIN_DIR}/vim" || true
            elif platform::command_exists vim; then
               sudo ln -s "$(which vim)" "${BIN_DIR}/vim" || true
            fi
            sudo ln -s "$(which vim)" "${BIN_DIR}/nvim"
         fi
      fi

   }

   setup_sudo_fallback() {

      if ! platform::command_exists sudo; then
         echo
         log::warning "the sudo command doesn't exist in this system"
         if feedback::maybe_confirmation "${DOT_INSTALL_SUDO:-}" "Do you want to setup a fallback?"; then
            mkdir -p "$LOCAL_BIN" || true
            cp "${MAIN_BIN_DIR}/\$" "${LOCAL_BIN}/sudo"
            chmod +x "${LOCAL_BIN}/sudo" || true
            export PATH="${LOCAL_BIN}:${PATH}"
            if ! platform::command_exists sudo; then
               sudo() {
                  "$@"
               }
               export -f sudo
            fi
         fi
      fi

   }

   use_fzf() {

      if [[ -n "${DOT_FZF:-}" ]]; then
         return 0
      fi

      use=false
      echo
      if feedback::maybe_confirmation "${DOT_INSTALL_FZF:-}" "Do you want to use FZF?"; then
         dot pkg add fzf
         use=true
      fi

      echo "export DOT_FZF=$use" >> "$LOCAL_ZSHRC"

   }

   ps1_code() {
      echo
      echo 'if [ $SH = "bash" ]; then '
      printf '   export PS1="'
      echo "$1\""
      echo 'fi'
   }

   set_random_ps1() {
      if grep -q "PS1" "$LOCAL_ZSHRC"; then
         return 0
      fi
      local -r ps1="$(dot shell bash ps1)"
      local -r code="$(ps1_code "$ps1")"
      echo "$code" >> "$LOCAL_ZSHRC"
   }

   use_fasd() {

      if [[ -n "${DOT_FASD:-}" ]]; then
         return 0
      fi

      use=false
      echo
      if feedback::maybe_confirmation "${DOT_INSTALL_FASD:-}" "Do you want to use FASD?"; then
         dot pkg add fasd
         use=true
      fi

      echo "export DOT_FASD=$use" >> "$LOCAL_ZSHRC"

   }

   install_brew() {
      if platform::command_exists brew || fs::is_dir /home/linuxbrew; then
         :
      else
         if feedback::maybe_confirmation "${DOT_INSTALL_BREW:-}" "Do you want to install brew?"; then
            dot pkg add brew
         fi
      fi
   }

   install_batch() {
      if "${DOT_INSTALL_BATCH:-true}"; then
         dot pkg batch prompt "$1"
      fi
   }


   # ==============================
   # Plugins
   # ==============================

   install_nvim_plugins() {

      if platform::command_exists nvim && echo && feedback::maybe_confirmation "${DOT_INSTALL_NVIM_PLUGINS:-}" "Do you want to install neovim plugins?"; then
         log::note "Installing neovim plugins..."
         nvim +silent +PlugInstall +qall >/dev/null
      fi

   }

   install_tmux_plugins() {

      if platform::command_exists tmux && echo && feedback::maybe_confirmation "${DOT_INSTALL_TMUX_PLUGINS:-}" "Do you want to install tmux plugins?"; then
         log::note "Installing tpm plugins..."
         export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/"
         bash "${TMUX_PLUGIN_MANAGER_PATH}tpm/bin/install_plugins" >/dev/null
         bash "${TMUX_PLUGIN_MANAGER_PATH}tpm/bin/update_plugins" all >/dev/null
      fi

   }

   install_zplug_plugins() {

      if platform::command_exists zplug && echo && feedback::maybe_confirmation "${DOT_INSTALL_ZPLUG_PLUGINS:-}" "Do you want to install zplug plugins?"; then
         log::note "Installing ZPlug plugins..."
         zplug install 2>/dev/null
      fi

   }


   # ==============================
   # Symlinks and custom configs
   # ==============================

   update_dotfiles() {
      DOTLINK="${1:-unix}" "${DOTFILES}/bin/dotlink" set --create-dirs --verbose
   }

   update_dotfiles_common() {
      echo
      update_dotfiles
   }

   update_dotfiles_osx() {
      log::note "Configuring for OSX..."
      update_dotfiles "osx"
   }

   update_dotfiles_linux() {
      log::note "Configuring for Linux..."
      update_dotfiles "linux"
   }

   update_dotfiles_wsl() {
      log::note "Configuring for WSL..."
      update_dotfiles "linux"
   }

   update_dotfiles_arm() {
      log::note "Configuring for ARM..."
      log::note "No custom config for ARM"
   }

   update_dotfiles_x86() {
      log::note "Configuring for x86..."
      log::note "No custom config for x86"
   }

   update_dotfiles_android() {
      log::note "Configuring for Android..."
      log::note "Installing essential dependencies..."
   }

   # ==============================
   # git
   # ==============================

   self_update() {
      cd "$DOTFILES"

      git fetch
      if [[ $(project_status) = "behind" ]]; then
         cd "$DOTFILES"
         log::note "Attempting to update itself..."
         git pull && exit 0 || log::error "Failed"
      fi
   }

   update_submodules() {

      echo
      log::note "Attempting to update submodules..."
      cd "$DOTFILES"
      git pull
      git submodule init
      git submodule update
      git submodule status
      git submodule update --init --recursive

   }

   project_status() {
      cd "$DOTFILES"

      local -r UPSTREAM=${1:-'@{u}'}
      local -r LOCAL=$(git rev-parse @)
      local -r REMOTE=$(git rev-parse "$UPSTREAM")
      local -r BASE=$(git merge-base @ "$UPSTREAM")

      if [[ "$LOCAL" = "$REMOTE" ]]; then
         echo "synced"
      elif [[ "$LOCAL" = "$BASE" ]]; then
         echo "behind"
      elif [[ "$REMOTE" = "$BASE" ]]; then
         echo "ahead"
      else
         echo "diverged"
      fi
   }
