#!/bin/bash

URL='https://www.twitch.tv/adrianoruseler'
FOLDER='/sharedfolders/Incomplete'


DOW=$(date +%u) # day of week (1..7); 1 is Monday

if [[ $DOW -eq 1 ]]; then 
    echo "Monday"	
elif [[ $DOW -eq 2 ]]; then 
	echo "Terca!"
elif [[ $DOW -eq 5 ]]; then 
	echo "Sexta!"
elif [[ $DOW -eq 6 ]]; then 
	echo "Sabado!"
else
    echo "Not this day of the week!"
	exit 0	
fi


HOD=$(date +%H)
if (( 15 <= $HOD && $HOD < 23 )); then 
    echo "between 8PM and 11PM"
else
    echo "Maybe is not online at this hour!"
	exit 0	
fi

NAME=$(date +\%Y-\%m-\%d-\%H.\%M)

cd $FOLDER

if [ -f twitchrunning.txt ]; then
	echo "twitchrunning.txt exists"
	exit 0	
fi

echo $URL >> twitchrunning.txt

if ! youtube-dl --list-formats $URL; then
    echo "some_command returned an error"
	rm twitchrunning.txt
else
	echo "All good!!"
	youtube-dl -f bestaudio -x --audio-format m4a --output $NAME.m4a
fi




*/1 *   *   *   * /root/twitchruseler.sh






HOD=$(date +%H)
if (( 15 <= 10#$H && 10#$H < 23 )); then 
    echo "between 4PM and 11PM"
else
    echo "Maybe is not online!"
fi

HOD=$(date +%H)
if (( 15 <= $H && $H < 23 )); then 
    echo "between 4PM and 11PM"
else
    echo "Maybe is not online!"
fi


HOD=$(date +%H)
if (( 12 <= $H && $H < 16 )); then 
    echo "between 4PM and 11PM"
else
    echo "Maybe is not online!"
fi