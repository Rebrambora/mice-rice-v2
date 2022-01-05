alias baterka='upower -i $(upower -e | grep '\battery') | grep --color=never -E "state|to\ full|to\ empty|percentage"'
alias la='ls -a'
alias lt='ls -t'
alias wifi='nmcli dev wifi list'

