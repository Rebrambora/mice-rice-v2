#!/bin/bash/

upower -i $(upower -e |grep battery) | grep --color=never -E "percentage" | grep -o -E '[%0-9]+'
