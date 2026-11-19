#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '


# Added by Antigravity CLI installer
export PATH="/home/darshan/.local/bin:$PATH"

# Default terminal
export TERMINAL=foot

# Case-insensitive shell behavior
shopt -s nocaseglob 2>/dev/null  # Case-insensitive globbing
shopt -s cdspell 2>/dev/null     # Auto-correct minor directory spelling/case in cd

# Zoxide initialization
eval "$(zoxide init bash)"
alias nvchad="nvim"

# Smart cd: checks local directory (with case-insensitivity), falls back to zoxide
function cd() {
    if [[ $# -eq 0 ]]; then
        __zoxide_cd ~
        return
    fi
    if [[ $# -eq 1 && "$1" == "-" ]]; then
        __zoxide_cd "${OLDPWD}"
        return
    fi
    if [[ $# -gt 1 || "$1" == -* ]]; then
        \builtin cd "$@"
        return
    fi
    if (\builtin cd -- "$1") &>/dev/null; then
        __zoxide_cd "$1"
        return
    fi

    # Case-insensitive match in current/specified directory
    local target="$1"
    local dir="."
    local base="$target"
    if [[ "$target" == */* ]]; then
        dir="${target%/*}"
        [[ -z "$dir" ]] && dir="/"
        base="${target##*/}"
    fi

    if [[ -d "$dir" ]]; then
        local f
        local match=""
        for f in "$dir"/*; do
            if [[ -d "$f" ]]; then
                local name="${f##*/}"
                if [[ "${name,,}" == "${base,,}" ]]; then
                    match="$f"
                    break
                fi
            fi
        done
        if [[ -n "$match" ]]; then
            __zoxide_cd "$match"
            return
        fi
    fi

    # Fallback to zoxide search
    local result
    if result="$(command zoxide query --exclude "$(__zoxide_pwd)" -- "$@")"; then
        __zoxide_cd "$result"
    else
        \builtin cd "$@"
    fi
}

if type -t __zoxide_z_complete &>/dev/null; then
    complete -F __zoxide_z_complete -o filenames -- cd
fi

# Starship prompt
eval "$(starship init bash)"

export PATH="$HOME/.cargo/bin:$PATH"
