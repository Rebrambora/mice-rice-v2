#!/bin/bash
if [[ -e ~/notes/note.txt ]];then
	echo 'yes note'
else
	cat > ~/notes/note.txt	
	echo 'no note'
fi
