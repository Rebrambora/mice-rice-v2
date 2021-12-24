#!/bin/bash


USER_CONFIG_DEFAULTS="CLIENT_ID=\"\"\nCLIENT_SECRET=\"\"";
USER_CONFIG_FILE="${HOME}/.shpotify.cfg";
if ! [[ -f "${USER_CONFIG_FILE}" ]]; then
	    touch "${USER_CONFIG_FILE}";
	        echo -e "${USER_CONFIG_DEFAULTS}" > "${USER_CONFIG_FILE}";
fi
source "${USER_CONFIG_FILE}";

# Set the percent change in volume for vol up and vol down
VOL_INCREMENT=10
cecho(){
bold=$(tput bold);
green=$(tput setaf 2);
reset=$(tput sgr0);
echo $bold$green"$1"$reset;
	}
showArtist() {
echo `osascript -e 'tell application "Spotify" to artist of current track as string'`;
}
showAlbum() {
echo `osascript -e 'tell application "Spotify" to album of current track as string'`;
}
showTrack() {
echo `osascript -e 'tell application "Spotify" to name of current track as string'`;
}
showStatus () {
state=`osascript -e 'tell application "Spotify" to player state as string'`;
cecho "Spotify is currently $state.";
duration=`osascript -e 'tell application "Spotify"
set durSec to (duration of current track / 1000) as text
set tM to (round (durSec / 60) rounding down) as text
if length of ((durSec mod 60 div 1) as text) is greater than 1 then
set tS to (durSec mod 60 div 1) as text
else
set tS to ("0" & (durSec mod 60 div 1)) as text
end if
set myTime to tM as text & ":" & tS as text
end tell
return myTime'`;
position=`osascript -e 'tell application "Spotify"
set pos to player position
set nM to (round (pos / 60) rounding down) as text
if length of ((round (pos mod 60) rounding down) as text) is greater than 1 then
set nS to (round (pos mod 60) rounding down) as text
else
set nS to ("0" & (round (pos mod 60) rounding down)) as text
end if
set nowAt to nM as text & ":" & nS as text
end tell
return nowAt'`;

echo -e $reset"Artist: $(showArtist)\nAlbum: $(showAlbum)\nTrack: $(showTrack) \nPosition: $position / $duration";
}

if [ $# = 0 ]; then
showHelp;
else
if [ ! -d /Applications/Spotify.app ] && [ ! -d $HOME/Applications/Spotify.app ]; then
echo "The Spotify application must be installed."
exit 1
fi

if [ $(osascript -e 'application "Spotify" is running') = "false" ]; then
osascript -e 'tell application "Spotify" to activate' || exit 1
sleep 2
fi
fi
while [ $# -gt 0 ]; do
arg=$1;

case $arg in
"play"    )
if [ $# != 1 ]; then
# There are additional arguments, so find out how many
array=( $@ );
len=${#array[@]};
SPOTIFY_SEARCH_API="https://api.spotify.com/v1/search";
SPOTIFY_TOKEN_URI="https://accounts.spotify.com/api/token";
if [ -z "${CLIENT_ID}" ]; then
cecho "Invalid Client ID, please update ${USER_CONFIG_FILE}";
showAPIHelp;
exit 1;
fi
if [ -z "${CLIENT_SECRET}" ]; then
cecho "Invalid Client Secret, please update ${USER_CONFIG_FILE}";
showAPIHelp;
exit 1;
fi
SHPOTIFY_CREDENTIALS=$(printf "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d "\n"|tr -d '\r');
SPOTIFY_PLAY_URI="";

getAccessToken() {
cecho "Connecting to Spotify's API";

SPOTIFY_TOKEN_RESPONSE_DATA=$( \
curl "${SPOTIFY_TOKEN_URI}" \
--silent \
-X "POST" \
-H "Authorization: Basic ${SHPOTIFY_CREDENTIALS}" \
if ! [[ "${SPOTIFY_TOKEN_RESPONSE_DATA}" =~ "access_token" ]]; then
cecho "Autorization failed, please check ${USER_CONFG_FILE}"
cecho "${SPOTIFY_TOKEN_RESPONSE_DATA}"
showAPIHelp
exit 1
fi
SPOTIFY_ACCESS_TOKEN=$( \
printf "${SPOTIFY_TOKEN_RESPONSE_DATA}" \
| command grep -E -o '"access_token":".*",' \
| sed 's/"access_token"://g' \
| sed 's/"//g' \
| sed 's/,.*//g' \
)
}
searchAndPlay() {
type="$1"
Q="
getAccessToken;
cecho "Searching ${type}s for: $Q";

SPOTIFY_PLAY_URI=$( \
curl -s -G $SPOTIFY_SEARCH_API \
-H "Authorization: Bearer ${SPOTIFY_ACCESS_TOKEN}" \
-H "Accept: application/json" \
--data-urlencode "q=$Q" \
-d "type=$type&limit=1&offset=0" \
| command grep -E -o "spotify:$type:[a-zA-Z0-9]+" -m 1
}

case $2 in
"list"  )
_args=${array[@]:2:$len};
Q=$_args;

getAccessToken;

cecho "Searching playlists for: $Q";

results=$( \
curl -s -G $SPOTIFY_SEARCH_API --data-urlencode "q=$Q" -d "type=playlist&limit=10&offset=0" -H "Accept: application/json" -H "Authorization: Bearer ${SPOTIFY_ACCESS_TOKEN}" \
| command grep -E -o "spotify:playlist:[a-zA-Z0-9]+" -m 10 \
)

count=$( \
echo "$results" | command grep -c "spotify:playlist" \
)

if [ "$count" -gt 0 ]; then
random=$(( $RANDOM % $count));

SPOTIFY_PLAY_URI=$( \
echo "$results" | awk -v random="$random" '/spotify:playlist:[a-zA-Z0-9]+/{i++}i==random{print; exit}' \
)
fi;;

"album" | "artist" | "track"    )
_args=${array[@]:2:$len};
searchAndPlay $2 "$_args";;

"uri"  )
SPOTIFY_PLAY_URI=${array[@]:2:$len};;

*   )
_args=${array[@]:1:$len};
searchAndPlay track "$_args";;
esac

if [ "$SPOTIFY_PLAY_URI" != "" ]; then
if [ "$2" = "uri" ]; then
cecho "Playing Spotify URI: $SPOTIFY_PLAY_URI";
else
cecho "Playing ($Q Search) -> Spotify URI: $SPOTIFY_PLAY_URI";
fi

osascript -e "tell application \"Spotify\" to play track \"$SPOTIFY_PLAY_URI\"";

else
cecho "No results when searching for $Q";
fi

else

# play is the only param
cecho "Playing Spotify.";
osascript -e 'tell application "Spotify" to play';
fi
break ;;

"pause"    )
state=`osascript -e 'tell application "Spotify" to player state as string'`;
if [ $state = "playing" ]; then
cecho "Pausing Spotify.";
else
cecho "Playing Spotify.";
fi

osascript -e 'tell application "Spotify" to playpause';
break ;;

"stop"    )
state=`osascript -e 'tell application "Spotify" to player state as string'`;
if [ $state = "playing" ]; then
cecho "Pausing Spotify.";
osascript -e 'tell application "Spotify" to playpause';
else
cecho "Spotify is already stopped."
fi

break ;;

"quit"    ) cecho "Quitting Spotify.";
osascript -e 'tell application "Spotify" to quit';
exit 0 ;;

"next"    ) cecho "Going to next track." ;
osascript -e 'tell application "Spotify" to next track';
showStatus;
break ;;

"prev"    ) cecho "Going to previous track.";
osascript -e '
tell application "Spotify"
set player position to 0
previous track
end tell';
showStatus;
break ;;

"replay"  ) cecho "Replaying current track.";
osascript -e 'tell application "Spotify" to set player position to 0'
break ;;

"vol"    )
vol=`osascript -e 'tell application "Spotify" to sound volume as integer'`;
if [[ $2 = "" || $2 = "show" ]]; then
cecho "Current Spotify volume level is $vol.";
break ;
elif [ "$2" = "up" ]; then
if [ $vol -le $(( 100-$VOL_INCREMENT )) ]; then
newvol=$(( vol+$VOL_INCREMENT ));
cecho "Increasing Spotify volume to $newvol.";
else
newvol=100;
cecho "Spotify volume level is at max.";
fi
elif [ "$2" = "down" ]; then
if [ $vol -ge $(( $VOL_INCREMENT )) ]; then
newvol=$(( vol-$VOL_INCREMENT ));
cecho "Reducing Spotify volume to $newvol.";
else
newvol=0;
cecho "Spotify volume level is at min.";
fi
elif [[ $2 =~ ^[0-9]+$ ]] && [[ $2 -ge 0 && $2 -le 100 ]]; then
newvol=$2;
cecho "Setting Spotify volume level to $newvol";
else
echo "Improper use of 'vol' command"
echo "The 'vol' command should be used as follows:"
echo "  vol up                       # Increases the volume by $VOL_INCREMENT%.";
echo "  vol down                     # Decreases the volume by $VOL_INCREMENT%.";
echo "  vol [amount]                 # Sets the volume to an amount between 0 and 100.";
echo "  vol                          # Shows the current Spotify volume.";
exit 1;
fi

osascript -e "tell application \"Spotify\" to set sound volume to $newvol";
break ;;

"toggle"  )
if [ "$2" = "shuffle" ]; then
osascript -e 'tell application "Spotify" to set shuffling to not shuffling';
curr=`osascript -e 'tell application "Spotify" to shuffling'`;
cecho "Spotify shuffling set to $curr";
elif [ "$2" = "repeat" ]; then
osascript -e 'tell application "Spotify" to set repeating to not repeating';
curr=`osascript -e 'tell application "Spotify" to repeating'`;
cecho "Spotify repeating set to $curr";
fi
break ;;

"status" )
if [ $# != 1 ]; then
# There are additional arguments, a status subcommand
case $2 in
"artist" )
showArtist;
break ;;

break ;;

"track" )
showTrack;
break ;;
esac
else
# status is the only param
showStatus;
fi
break ;;
"info" )
info=`osascript -e 'tell application "Spotify"
set durSec to (duration of current track / 1000)
set tM to (round (durSec / 60) rounding down) as text
if length of ((durSec mod 60 div 1) as text) is greater than 1 then
set tS to (durSec mod 60 div 1) as text
else
set tS to ("0" & (durSec mod 60 div 1)) as text
end if
set myTime to tM as text & "min " & tS as text & "s"
set pos to player position
set nM to (round (pos / 60) rounding down) as text
if length of ((round (pos mod 60) rounding down) as text) is greater than 1 then
set nS to (round (pos mod 60) rounding down) as text
else
set nS to ("0" & (round (pos mod 60) rounding down)) as text
end if
set nowAt to nM as text & "min " & nS as text & "s"
set info to "" & "\nArtist:         " & artist of current track
set info to info & "\nTrack:          " & name of current track
set info to info & "\nAlbum Artist:   " & album artist of current track
set info to info & "\nAlbum:          " & album of current track
set info to info & "\nSeconds:        " & durSec
set info to info & "\nSeconds played: " & pos
set info to info & "\nDuration:       " & mytime
 set info to info & "\nNow at:         " & nowAt
set info to info & "\nPlayed Count:   " & played count of current track
set info to info & "\nTrack Number:   " & track number of current track
set info to info & "\nPopularity:     " & popularity of current track
set info to info & "\nId:             " & id of current track
set info to info & "\nSpotify URL:    " & spotify url of current track
set info to info & "\nArtwork:        " & artwork url of current track
set info to info & "\nPlayer:         " & player state
set info to info & "\nVolume:         " & sound volume
set info to info & "\nShuffle:        " & shuffling
set info to info & "\nRepeating:      " & repeating
end tell
return info'`
cecho "$info";
break ;;
"share"     )
uri=`osascript -e 'tell application "Spotify" to spotify url of current track'`;
remove='spotify:track:'
url=${uri#$remove}
url="https://open.spotify.com/track/$url"
if [ "$2" = "" ]; then
cecho "Spotify URL: $url"
cecho "Spotify URI: $uri"
echo "To copy the URL or URI to your clipboard, use:"
echo "\`spotify share url\` or"
echo "\`spotify share uri\` respectively."
elif [ "$2" = "url" ]; then
cecho "Spotify URL: $url";
echo -n $url | pbcopy
elif [ "$2" = "uri" ]; then
cecho "Spotify URI: $uri";
echo -n $uri | pbcopy
fi
break ;;

"pos"   )
cecho "Adjusting Spotify play position."
osascript -e "tell application \"Spotify\" to set player position to $2";
break ;;

"help" )
showHelp;
break ;;
* )
showHelp;
exit 1;

esac
done

