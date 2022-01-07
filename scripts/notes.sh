#!/bin/bash

xterm -T "Notes" -n "Notes" -geometry 80x35+1430+600 -fg white -bg black -hold -e '

if [[ ! -e ~/notes/ ]]; then
	mkdir ~/notes
fi

echo -e "Press n to make new note, l to open last opened note, \na number to open specific note or q to quit"
read var
while [ ! $var == 'q' ] 
do
num_newn=$(( $(ls -t ~/notes | grep -o -E '[0-9]+' | sort -nr | grep -o -E -m 1 '[0-9]+') + 1))
num_lastn=$(ls -t ~/notes | grep -o -E -m 1 '[0-9]+')
if [[ $var == 'n' ]]; then
	newname='file'$num_newn'.txt'
	vim ~/notes/$newname 
elif [[ $var == 'l' ]]; then
	lastname='file'$num_lastn'.txt'
	vim ~/notes/$lastname
elif [[ -n $(echo "$var" | grep -o -E -m 1 '[0-9]+') ]]; then
	specname='file'$var'.txt'
	vim ~/notes/$specname
else
	echo "I like you, you rebellious scoundrel, nevertheless try again or my script cannot do anything for you. Just for once - follow the rules or better - make a better script of yours ;-) - my amateurish knowledge is...well amateurish..." 
fi
read var
if [[ $var == 'q' ]]; then
	xdotool key super+q
fi
done
'

