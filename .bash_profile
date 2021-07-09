
export CLICOLOR=YES
export LSCOLORS="GxFxCxDxBxegedabagaced"
export HOMEBREW_NO_AUTO_UPDATE=1
export EDITOR=vi
export HISTCONTROL=erasedups
export HISTSIZE=10000
export HISTTIMEFORMAT="%d/%m/%y %T "

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='\[\e[0;34m\]\u\[\e[0m\]@\[\e[0;34m\]\h\[\e[0m\]:\[\e[0;36m\]$(pwd) >\[\e[0m\] '
else
    export PS1='$(whoami)@$(hostname):$(pwd)> '
fi
 
export PATH=/usr/local/bin/:$PATH


# alias for rm safety
alias rm="/bin/rm -i"

# sourcing any keys/creds that need to be exported as ENV vars
source ~/.creds

# Send VT100 "Report Device OK" every 60 seconds to keep SSH from timing out
notidle() { printf "\033[0n"; sleep 60; notidle; }
