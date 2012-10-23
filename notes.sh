#!/bin/bash

[ -z $EDITOR ] && EDITOR=vi
shopt -s nocasematch
cd $MEMEX_DIR
LIST_CMD="ls -1t"

_usage() {
      echo "Usage: $0 [-c <text>] [-t <tag>] -h list"
      echo "       $0 add|edit <note name>"	
	  echo "          -c <text>         Filter notes that contain text"
  	  echo "          -t <tag>          Filter notes tagged with tag"
	  echo "          -h                Listing shows the notes' header (first line)"
}

_editnote() {
	ext=$([[ ! $1 =~ \.txt$ ]] && echo ".txt")
	notefile=$MEMEX_DIR/${1}${ext}
	if [ -f $notefile ]
	then
		$EDITOR $notefile
		exit 0
	else
		echo Note $1 not found 2>&1
		exit 1
	fi
}

_addnote() {
	# Remove blanks from file names
	notename=$(echo $1 | tr [:blank:]  _)
	ext=$([[ ! $notename =~ \.txt$ ]] && echo ".txt")
	
	notefile=$MEMEX_DIR/${notename}${ext}

	# Check if already exists a note with the given name
	if [ -f $notefile ]
	then
		echo Note \"$notename\" already exists, edit? \(y/n\)
		read answer
		
		[[ $answer = "y" ]] && $EDITOR $notefile
		exit 0
	fi
	
	# New note
	tmpfile=$(mktemp /tmp/noteXXXXX.txt)
	
	echo -e "\n\ntags:" >> $tmpfile
	
	checksum=$(md5sum $tmpfile)
	$EDITOR $tmpfile
	newchecksum=$(md5sum $tmpfile)
	
	if [ ! "$checksum" = "$newchecksum" ]
	then
		mv $tmpfile $notefile
	else
		rm -f $tmpfile
	fi
}

FILE_LIST=$(ls *txt *TXT 2> /dev/null)
TAGS_FILTER="head -1v "

while [ -n "$FILE_LIST" ] && getopts :c:t:h OPTION
do
	case $OPTION in
		c )
			FILE_LIST=$(grep -li $OPTARG $FILE_LIST)
			;;
		t )
			FILE_LIST=$(egrep -li "^tags:(.*,)* *$OPTARG *(,|$)" $FILE_LIST)
			;;
		h )
			LIST_CMD="head -1v "
			;;
		\?)
			echo Unknown option -$OPTARG >&2
			_usage
			exit 1
			;;
		:)
			echo Option -$OPTARG requires an argument >&2
			_usage
			exit 1
			;;
	esac
done

shift $((OPTIND-1))

ACTION=$1
if [ -z $ACTION ]
then
	ACTION=list
fi

case $ACTION in 
"list")
	[[ -n $FILE_LIST ]] && $LIST_CMD $FILE_LIST
	;;
"add")
	input=$2
	if [[ -z "$2" ]]; then
        echo -n "Enter a name for the new note: "
        read input
    fi
    _addnote $input
	;;
"edit")
	if [[ -z "$2" ]]; then
        echo Edit what?
        _usage
        exit 1
    else
    	_editnote $2
    fi
	;;
*)
	echo Action $ACTION unknown
	_usage
	exit 1
	;;
esac