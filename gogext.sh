#!/bin/bash

#Bash script to unpack gog's linux game installers. Basically a rewrire of Yepoleb's awesome gogextract.py: https://github.com/Yepoleb/gogextract
scriptname=`basename "$0"`

#First of all - lets check if we actually got any arguments passed to our script
#Checking for first argument which stands for name of game file, we are about to unpack. If empty - display help regarding script's usage and exit
if [ -z "$1" ]; then
	echo "Input is empty. Usage: $scriptname <input file> <output dir>"
	exit 1
else
	filename="$1"
	echo "Unpacking the game: $filename"
fi
#Checking if file we just passed to script actually exist and is file. If not - exit
if [ -f $filename ]; then
	echo "Found game named $filename, proceed"
else
	echo "Couldnt find such game, abort"
	exit 1
fi

#Checking if script has received second argument, which should define output directory. If not - using defaults. If yes - either making directory named after argument (in case it doesnt exist at all), doing nothing (in case it already exists and is directory) or exit with error (in case it exists but not a directory)
if [ -z "$2" ]; then
	echo "Using default output directory"
	outputdir="./"
else
	mkdir -p "$2" || exit 1
	outputdir="$2/"
	echo "Output directory has been set to $outputdir"
fi

#Now to unpacker itself. Lets check for first 10kbytes of installer in order to find offset size. Since the result of command below should literally be bash variable - we are just importing it there
eval "$(dd count=10240 if=$filename bs=1 status=none | grep "head -n" | head -n 1)"
#But, just in case something went wrong and file structure has been changed - lets check if import was successfull and we actually obtained what we needed
if [ -z "$offset" ]; then
	echo "Couldnt find the correct offset, abort"
	exit 1
else
	echo "Makeself script size: $offset"
fi

#Now lets do the same, but in order to obtain size of mojosetup archive
eval "$(dd count=10240 if=$filename bs=1 status=none | grep "filesizes=" | head -n 1)"

if [ -z "$filesizes" ]; then
	echo "Couldnt find size of mojosetup archive, abort"
	exit 1
else
	echo "MojoSetup archive size: $filesizes"
fi

#With all necessary data gathered - lets finally unpack our files!
echo "Extracting makeself script as unpacker.sh"
dd count="$offset" if="$filename" of="$outputdir"unpacker.sh bs=1 status=none
echo "Extracting MojoSetup archive as mojosetup.tag.gz"
dd skip="$offset" count="$filesizes" if=$filename of="$outputdir"mojosetup.tar.gz bs=1 status=none
#dd skip=$sum if=$filename of=data.zip ibs=1 obs=16384
echo "Extracting game files as data.zip (may take a while)"
dd skip="$(($offset+$filesizes))" if="$filename" of="$outputdir"data.zip ibs=1 status=none

echo "Done"
exit 0
