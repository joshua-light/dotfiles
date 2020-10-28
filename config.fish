# Greeting message is disabled.
set -g -x fish_greeting ''

# PATH variable is changed here.
set PATH $PATH ~/.local/bin/
set PATH $PATH ~/.cargo/bin/
set PATH $PATH /opt/mssql-tools/bin/
set PATH $PATH /snap/bin/

# Configs.
alias nvrc="nvim ~/.config/nvim/init.vim"
alias frc="nvim ~/.config/fish/config.fish"

# Python.
alias activate="source venv/bin/activate.fish"

# Git.
alias gdev="git checkout develop"
alias gmdev="git merge develop"
alias gmas="git checkout master"
alias gmmas="git merge master"
alias gs="git status"
alias ga="git add ."
alias gr="git pull --rebase"
alias gp="git push"
alias gf="git fetch --prune"
alias gbr="git checkout -b "

# Apps.
alias vim="nvim"
alias v="nvim ."

# Customized prompt.
function fish_prompt
    # Username.
    set_color c678dd
    echo -n (whoami)

    # `@` character.
    set_color f92672
    echo -n "@"

    # Hostname.
    set_color dcdcaa
    echo -n (prompt_hostname)

    echo -n " "

    # Current dir.
    set_color 636872
    echo -n "["
    echo -n (prompt_pwd)
    echo -n "]"

    echo -n " "

    # `>` character.
    set_color f92672
    echo -n ">"

    echo -n " "

    set_color normal
end

# Customized colors.
set fish_color_normal bbbbbb
set fish_color_command c678dd --bold
set fish_color_quote ce9178
set fish_color_redirection c678dd
set fish_color_end f92672
set fish_color_error ff3333 --bold
set fish_color_param dcdcaa
set fish_color_comment 636872
set fish_color_match 61afef
set fish_color_selection 3f4450
set fish_color_search_match dcdcaa
set fish_color_operator f92672
set fish_color_escape f92672
set fish_color_escape d19a66
set fish_color_cancel 7f848e
