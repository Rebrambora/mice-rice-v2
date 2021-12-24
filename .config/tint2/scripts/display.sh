#!/bin/bash/

if (( $(spotify-now -e "80")==80 )); then
    echo "*sad spotify noises*" 
else

spotify-now -i "%title - %artist" -p "▶"
fi
