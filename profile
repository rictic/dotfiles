alias gs='git status'
alias gca='git commit -a'
alias gd='git diff'
alias gc='git commit'
alias gb='git checkout -b'
alias gclean='git branch --merged | grep -v "\*" | grep -v master | grep -v dev | xargs -n 1 git branch -d'
alias l='ls -a -l -h'

alias npx="npx --no-install"


export PATH="$PATH:~/bin"
export EDITOR='code -w'

