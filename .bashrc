# ~/.bashrc: executed by bash(1) for non-login shells.
# v0.1.4

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi


# set term color spec
export TERM=xterm-256color

# colors
DARK_GRAY="\[\e[1;90m\]"
YELLOW_ORANGE="\[\e[38;5;214m\]"
WHITE="\[\e[1;97m\]"
LIGHT_GRAY="\[\e[0;37m\]"
LIGHT_GREEN="\[\e[38;5;46m\]"
COLORLESS="\[\e[0m\]"

# detect git repository
function is_git_repository {
    git branch > /dev/null 2>&1
}

# determine branch/state of git repository
function set_git_state {
    git_status="$(git status 2> /dev/null)"

    # set color based on state
    if [[ ${git_status} =~ "nothing to commit" ]]; then
        state="${DARK_GRAY}"
    elif [[ ${git_status} =~ "Changes to be committed" ]]; then
        state="${LIGHT_GREEN}"
    else
        state="${YELLOW_ORANGE}"
    fi

    # determine position relative to remote
    remote_pattern="# Your branch is (.*) of"
    diverge_pattern="# Your branch and (.*) have diverged"
    if [[ ${git_status} =~ ${remote_pattern} ]]; then
        if [[ ${BASH_REMATCH[1]} == "ahead" ]]; then
            remote="↑"
        else
            remote="↓"
        fi
    elif [[ ${git_status} =~ ${diverge_pattern} ]]; then
        remote="X"
    else
        remote=""
    fi

    # determine branch name
    name_pattern="On branch ([^${IFS}]*)"
    if [[ ${git_status} =~ ${name_pattern} ]]; then
        branch_name=${BASH_REMATCH[1]}
    else
        branch_name="error!"
    fi

    GIT_STATE="${DARK_GRAY}(${state}${branch_name}${DARK_GRAY})"
}

# determine virtualenv (Python) state of current env
function set_virtualenv() {
    if test -z "$VIRTUAL_ENV" ; then
        VIRTUALENV=""
    else
        VIRTUALENV="${DARK_GRAY}(${WHITE}`basename \"$VIRTUAL_ENV\"`${DARK_GRAY})${COLORLESS}"
    fi

}

# return prompt symbol based on return value of previous command
function set_prompt_symbol () {
    if test $1 -eq 0 ; then
        PROMPT_SYMBOL="\$${COLORLESS} "
    else
        PROMPT_SYMBOL="${YELLOW_ORANGE}\$${COLORLESS} "
    fi
}

# set full bash prompt
function set_bash_prompt () {
    set_prompt_symbol $?
    set_virtualenv

    if is_git_repository ; then
        set_git_state
    else
        GIT_STATE=""
    fi

    # <user@host>
    base_prompt="${DARK_GRAY}<${YELLOW_ORANGE}\u${WHITE}@\h${DARK_GRAY}>"
    # [/working/dir]
    working_dir="${DARK_GRAY}[${LIGHT_GRAY}\w${DARK_GRAY}]"

    #PS1="\[\e[1;90m\]<\[\e[38;5;214m\]\u\[\e[1;97m\]@\h\[\e[1;90m\]>[\[\e[0;37m\]\w\[\e[1;90m\]]\$\[\e[m\] "
    PS1="${VIRTUALENV}${base_prompt}${working_dir}${GIT_STATE}${PROMPT_SYMBOL}"

    export PS1
}
PROMPT_COMMAND=set_bash_prompt

# shortcut for virtualenv commands
function venv {
    if [ -z "$1" ]; then
        if test -z "$VIRTUAL_ENV" ; then
            echo "No virtualenv active."
        else
            deactivate
        fi
    elif [ "$1" = "-n" ]; then
        if [ "$2" = "-p" ]; then
            if [ -z "$3" ]; then
                echo "No path provided to Python executable"
            elif [ -z "$4" ]; then
                echo "No path provided for virtualenv"
            else
                virtualenv -p $3 $4
            fi
        else
            virtualenv $2
        fi
    elif [ "$1" = "-d" ]; then
        deactivate
    else
        source $1/bin/activate
    fi
}

# truncate file and open in vim
function truncvim {
    if [ -z "$1" ]; then
        echo "No filename supplied"
    else
        truncate $1 -s 0
        vim $1
    fi
}

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
