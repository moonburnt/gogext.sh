#!/bin/bash

#Bash script to unpack gog's linux game installers, inspired by gogrepo.py
scriptname=`basename "$0"`

if [ -z "$1" ]; then	#"-z" stands for "if null"
	echo "Input is empty. Usage:" $scriptname "game-to-unpack"
	exit 1
else
	filename="$1"
	echo "Unpacking the game:" $filename
fi

if [ -f $filename ]; then
	echo "Found game named" $filename", proceed"
else
	echo "Couldnt find such game, abort"
	exit 1
fi

#First of all - lets check for first 10kbytes of installer in order to find offset size. Since the result of command below should literally be bash variable - we are just importing it there
eval "$(dd count=10240 if=$filename bs=1 | grep "head -n" | head -n 1)"
#But, just in case something went wrong and file structure has been changed - lets check if import was successfull and we actually obtained what we needed
if [ -z "$offset" ]; then
	echo "Couldnt find the correct offset, abort"
	exit
else
	echo "Makeself script size: $offset"
fi

#Now lets do the same, but in order to obtain size of mojosetup archive
eval "$(dd count=10240 if=$filename bs=1 | grep "filesizes=" | head -n 1)"

if [ -z "$filesizes" ]; then
	echo "Couldnt find size of mojosetup archive, abort"
	exit 1
else
	echo "MojoSetup archive size: $filesizes"
fi

#With all necessary data gathered - lets finally unpack our files!
echo "Extracting makeself script as unpacker.sh"
dd count=$offset if=$filename of=unpacker.sh bs=1
echo "Extracting MojoSetup archive as mojosetup.tag.gz"
dd skip=$offset count=$filesizes if=$filename of=mojosetup.tar.gz bs=1
#dd skip=$sum if=$filename of=data.zip ibs=1 obs=16384
echo "Extracting game files as data.zip"
dd skip=$(($offset+$filesizes)) if=$filename of=data.zip ibs=1

echo "Done"
exit 0
