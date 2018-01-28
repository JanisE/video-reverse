#!/bin/bash

# Works for small videos (can reverse the whole video at one go):
# for movieFile in in/* ; do ffmpeg -y -i "$movieFile" -vf reverse -af areverse "./out/$(basename "$movieFile")"; done

#
# Works for large videos (splits the video, reverses each chunk separately, joins them back together):
#

loglevel=info
#loglevel=fatal

for movieFile in ./in/* 
do
	rm ./tmp/* 2> /dev/null

	fileName="$(basename "$movieFile")";

	# MP4 samples were all right, but AVI didn't work without "-reset_timestamps 1".
	#
	# Reversing buffers the whole movie into memory.
	# "-segment_time 30" caused ffmpeg to use 3 GB of RAM.
	# Let this be small enough, so a computer with max 4 GB RAM can run it too.
	ffmpeg -loglevel $loglevel -fflags +genpts -y -i "$movieFile" -codec copy -f segment -segment_time 10 -reset_timestamps 1 -segment_list ./tmp/tmp.ffcat "./tmp/chunk-%03d-$fileName";

	for chunkFile in ./tmp/chunk*
	do
		chunkFileName="$(basename "$chunkFile")";
		reversedChunkFile="./tmp/rev-$chunkFileName";

		# "-qscale:v" for AVI, "-crf" for MP4.
		ffmpeg -loglevel $loglevel -y -i "$chunkFile" -vf reverse -qscale:v 5 -crf 21 -af areverse "$reversedChunkFile";
		mv "$reversedChunkFile" "$chunkFile"
	done

	echo "ffconcat version 1.0" > ./tmp/reversed.ffcat
	tail -n +2 ./tmp/tmp.ffcat | tac >> ./tmp/reversed.ffcat

	# "-safe 0" - to accept file names with spaces.
	ffmpeg -loglevel $loglevel -y -safe 0 -i "./tmp/reversed.ffcat" -codec copy "./out/$fileName";
done;

rm ./tmp/* 2> /dev/null
