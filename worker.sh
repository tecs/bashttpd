#!/bin/bash

source $2
source "$CONFIG_PATH/$1"

if [ "" != "$3" ] ; then
	ss () {
		echo $1 | sed -e 's/[\/&]/\\&/g'
	}
	request () {
		if [ ! -r "$1" ] ; then
			error 403
		fi
		
		FILENAME=$1
		HANDLER=cat
		CT=$(file -b --mime-type "$FILENAME")
		
		for IND in ${HANDLERS[*]} ; do
			if [ "${FILENAME#*.}" == "${IND%:*}" ] ; then
				HANDLER=${IND#*:}
				CT="text/html"
			fi
		done
		
		export QUERY_STRING="$query"
		echo -e "HTTP/1.1 200 OK\r"
		echo -e "Content-Type: $CT\r"
		echo -e "\r"
		
		$HANDLER $FILENAME
	
		echo -e "\r"
		
		exit 0
	}
	
	filelist () {
		REPEAT=$(grep -E '<FILELIST>(.*)<\/FILELIST>' doc/index.htm | sed -r 's/<FILELIST>(.*)<\/FILELIST>/\1/')
		FILELIST=$(
			cd "$1"
			for f in `ls`; do
				href="${url%/}/$f"
				echo $REPEAT | sed -e "s/FILE_NAME/$(ss "$f")/" -e "s/FILE_HREF/$(ss "$href")/"
			done
		)
		
		echo -e "HTTP/1.1 200 OK\r"
		echo -e "Content-Type: text/html\r"
		echo -e "\r"
		sed -e "s/DIRNAME/$(ss "$1")/" -e "s/UP_HREF/$(ss "${url%/}/..")/" -e "s/<FILELIST>.*<\/FILELIST>/$(ss "$FILELIST")/" doc/index.htm
		echo -e "\r"
		
		exit 0
	}
	error () {
		err=404
		if [ -f "doc/$1.htm" ] ; then
			err=$1
		fi
		
		echo -e "HTTP/1.1 $err\r"
		echo -e "Content-Type: text/html\r"
		echo -e "\r"
		sed -e "s/ERRNO/$err/" doc/$err.htm
		echo -e "\r"
		
		exit 0
	}

	read request

	while /bin/true; do
		read header
		[ "$header" == $'\r' ] && break;
	done

	url="${request#GET }"
	url="${url% HTTP/*}"
	query="${url#*\?}"
	url="${url%%\?*}"
	filename="$ROOT$url"
	
	if [ -f "$filename" ]; then
		request $filename
	else
		if [ -d "$filename" ]; then
			for IND in ${INDEX[*]} ; do
				if [ -f "$filename/$IND" ] ; then
					request "$filename/$IND"
				fi
			done
			
			if [ "$LISTING" == "1" ] ; then
				filelist $filename;
			else
				error 403
			fi
		else
			error 404
		fi
	fi
else
	while true ; do
		rm -f "$CONN_PATH/$1"
		mkfifo "$CONN_PATH/$1"
		
		cat "$CONN_PATH/$1" | 
			nc -l $PORT | 
				./worker.sh $1 $2 "exec" > "$CONN_PATH/$1"
	done
fi