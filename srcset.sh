#!/bin/bash

basedir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

usage() {
	echo "usage: $0 [-hmzug] [-q quality] [—t type] [-s sizes] [-o outdirectory] [-f filename] filename"
	echo "usage: $0 [-hmzug] [—n findname] [-q quality] [—t type] [-s sizes] [-o outpath] [-f filepath] filepath"
	echo ""
	echo "For general usage take a look at the original srcset.sh documentation on github"
	echo "adrianboston/srcset.sh: <https://github.com/adrianboston/srcset.sh>"
	echo ""
	echo "This fork is meant as watchdog for new files in a web directory (e.g. periodically"
	echo "called by a cronjob), which should run in the background."
	echo ""
	echo "Additional attributes:"
	echo "-g : gitignore - write the created images into a .gitignore file"
	echo "-u : subdirectory - place the created images in a subdirectory. The name"
	echo "     of the subdirectory is identical to the name of the source image file."
	echo ""
	echo "The set of image widths / quality settings can be configured in the file"
	echo "srcset.conf, which must be in the same directory as this srcset.sh."
	echo "If the file does not exist, it will be created with some default values."
	echo ""
	echo "The filename of every already processed image will be attached to the file"
	echo "\"processed_images\" within the same directory as this srcset.sh."
	echo "The files from the list in \"processed_images\" will be skipped in future"
	echo "calls of this script."
}

adddate() {
	while IFS= read -r line; do
		printf '%s: %s\n' "$(date)" "$line"
	done
}

convert_file() {
	# path and no filenames
	path=${filename%/*}

	# path and filename with no extension or type
	pathfile=${filename%.*}

	# filename with no path
	nopath="${filename##*/}"

	# extension or type (jpg, png, etc) either from current file OR from -t option
	if ! [ -z "$desttype" ]; then
		type="$desttype"
	else
		type="${filename##*.}"
	fi

	# if out directory is empty then either create files in the same directory
	# as source file, or place the files in a subdirectory with the name of the
	# source file (if the -u \"filenamedir\" option is set)
	if [ -z "$outdir" ]; then
		if ! [ -z "$filenamedir" ]; then
			nopathnoext="${nopath%.*}"
			outprefix="$pathfile/$nopathnoext"

			# make a directory with all parents if needed -- unless running a test
			if [ -z "$istest" ]; then
				mkdir -p "$pathfile/"
			fi
		else
			outprefix="$pathfile"
		fi
	else
		outprefix="$outdir/$pathfile"
		nopathnoext="${nopath%.*}"

		# make a directory with all parents if needed -- unless running a test
		if [ -z "$istest" ]; then
			mkdir -p "$outdir/$path"
		fi
	fi

	# change convert options as needed. recommend that psd files use -flatten
	# uuse convert defalt quality that is the best possible
	if ! [ -z "$isinterlace" ]; then
		options="-strip -interlace Plane"
	fi

	if ! [ -z "$quality" ]; then
		options="$options -quality $quality"
	fi

	echo ""
	echo "Resizing $filename" | adddate | tee -a $basedir/srcset.log

	if [ -z "$istest" ]; then
		# Various resizes
		for i in "${!resp_width[@]}"; do
			convert $options -quality ${resp_quality[$i]} -resize ${resp_width[$i]} "$filename" "$outprefix-${resp_width[$i]}w.$type"
			echo "$outprefix-${resp_width[$i]}w.$type" | adddate | tee -a $basedir/srcset.log
			if [ -z "$gitignore" ]; then
				echo "$(basename $outprefix-${resp_width[$i]}w.$type)" >>$(dirname $outprefix-${resp_width[$i]}w.$type)/.gitignore
			fi
		done
		echo "--------------------------------" | tee -a $basedir/srcset.log
		echo "$nopath" >>$basedir/processed_images
	else
		for i in "${!resp_width[@]}"; do
			echo convert $options -quality ${resp_quality[$i]} -resize ${resp_width[$i]} "$filename" "$outprefix-${resp_width[$i]}w.$type"
		done
		echo "would write now \"$nopath\" to the file \"$basedir/processed_images\"..."
	fi

	outprefix="$prefix$outprefix"

	str=''

	# if 'save' argument then save to file
	if [ -z "$ismarkup" ] || ! [ -z "$istest" ]; then
		#echo "$str"
		echo ""
	else
		echo "$str" >"$outprefix-srcset.html"
		echo "more $outprefix-   srcset.html"
	fi
}

find_files() {
	find "$dirname" -type f \( -name "$pattern" $(printf " -a ! -name %s " $(cat $basedir/processed_images)) $(printf " -a ! -name *-%sw.* " ${resp_width[*]}) -a ! -name "*-srcw.*" \) -exec echo new file found: {} \; -exec "$0" -p "$prefix" -t "$desttype" -o "$outdir" $filenamedir $isinterlace $ismarkup $istest -f {} \;

}

# —————————————————————————————— main ——————————————————————————————
dirname=""
filename=""
outdir=""
gitignore=""
filenamedir=""
quality=""
ismarkup=""
istest=""
isinterlace=""
pattern="*.jpg"
desttype=""
sizes="(min-width: 768px) 50vw, 100vw"
prefix=""

#check if the file for the processed images exists. Create the file, if it does not exist
if [ ! -f "$basedir/processed_images" ]; then
	touch $basedir/processed_images
fi

#check if the conf file exists. Create the file with some default values, if it does not exist
if [ ! -f "$basedir/srcset.conf" ]; then
	echo "#This is the default configuration with a set of various response image sizes and quality settings." >>$basedir/srcset.conf
	echo "#You can define the quality for each image width separately." >>$basedir/srcset.conf
	echo "resp_width=(  240 320 480 640 720 960 1100 1300 1500 1800 1920 2100 )" >>$basedir/srcset.conf
	echo "resp_quality=( 88  80  78  76  74  72   65   59   56   53   48   45 )" >>$basedir/srcset.conf
fi

#load configuration
. $basedir/srcset.conf

# now get options
while getopts ":f:n:p:q:o:s:t:hmziug" option; do
	case "$option" in
	f)
		tmp="$OPTARG"
		;;
	n)
		pattern="$OPTARG"
		;;
	p)
		prefix="$OPTARG"
		;;
	q)
		quality="$OPTARG"
		;;
	o)
		outdir="$OPTARG"
		# strip any trailing slash from the dir_name value
		outdir="${outdir%/}"
		;;
	s)
		sizes="$OPTARG"
		;;
	g)
		gitignore="-$option"
		;;
	u)
		filenamedir="-$option"
		;;
	m)
		# This trick is used for rercusive shells (see the find arguments)
		ismarkup="-$option"
		;;
	z)
		istest="-$option"
		;;
	i)
		isinterlace="-$option"
		;;
	t)
		desttype="$OPTARG"
		;;
	h)
		usage
		exit 0
		;;
	:)
		echo "Error: -$OPTARG requires an argument" >&2
		usage
		exit 1
		;;
	\?)
		echo "Error: unknown option -$OPTARG" >&2
		usage
		exit 1
		;;
	esac
done

# LAST parameter *may* to be file or directory. if none specifed (using -f) then use last argument
if [ -z "$tmp" ]; then
	isfile="${!#}"
else
	isfile="$tmp"
fi

# need either filename or dir so error
if [ -z "$isfile" ] || [ -b "$isfile" ] || [ -c "$isfile" ] || ! [ -e "$isfile" ]; then
	echo "Error: Needs valid filename or directory as argument" >&2
	usage
	exit 1
fi

# if filename is not empty then we convert a single file
if [ -f "$isfile" ]; then
	filename="$isfile"
	convert_file
	exit 1
fi

if [ -d "$isfile" ]; then
	dirname="$isfile"
	# strip any trailing slash from the filename value
	dirname="${dirname%/}"
	find_files
	exit 1
fi

echo 'File or directory is required $isfile' >&2
usage
exit 1
