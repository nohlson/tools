#!/bin/bash
#a script to move a file to a driectory, assumed to be the directory in the websites resources, and edit the html document and add code snipped for new song at the keyword <!--next-->
#nateohlson 2016




if (("$#" < 3)); then
	echo "Usage: ./addsongtosite /path/to/song /path/to/music/archive /path/to/music.html"
	exit
fi
FILENAME=$1
PATHTOMUSIC=$2
PATHTOHTML=$3
SONGNAME=$(basename "$1")
songsansext=${SONGNAME%.*}
newfullfilepath=$PATHTOMUSIC$SONGNAME



if [ ! -f "$FILENAME" ]; then
    echo "Song not found!"
    exit
fi
if [ ! -f "$PATHTOHTML" ]; then
    echo "HTML not found!"
    exit
fi
if [ -f "$newfullfilepath" ]; then
    echo "File already exists in music directory"
    exit
fi


#copy the song to the music directory
echo "Copying file to directory..."
cp "$FILENAME" "$PATHTOMUSIC"
if [ $? -eq 0 ]; then
    echo "Copied"
else
    echo "Copying failed"
    exit
fi

backslash="/"
newpathtosong=$PATHTOMUSIC$backslash$SONGNAME

sednewline="\\n"
nn='\n'

replacementstring="<li><a href=\"music/$SONGNAME\"><b>nohlson</b> - $songsansext</a></li>$sednewline$nn             <!--next-->$nn"




#Sed command to replace the <!--next--> identifier with the replacement string
sedargument="s@<!--next-->@"
endarg="@g"
sedargument=$sedargument$replacementstring$endarg

#sed 's/<!--next-->/$replacementstring/g' "$PATHTOHTML"
echo "Editing HTML file...."
sed -i "$sedargument" "$PATHTOHTML"
if [ $? -eq 0 ]; then
    echo "Edited"
else
    echo "Editing failed"
    exit
fi

echo "Success"
