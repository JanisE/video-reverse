
:: Works for small videos (can reverse the whole video at one go):
:: for %%m in (.\in\*) do ffmpeg -y -i "%%~m" -vf reverse -af areverse ".\out\%%~nm%%~xm"

::
:: Works for large videos (splits the video, reverses each chunk separately, joins them back together):
::

@echo off
setlocal ENABLEEXTENSIONS

set logLevel=info
:: set logLevel=fatal

for %%m in (.\in\*) do call :ReverseMovie "%%m"

del /Q .\tmp\* 2> NUL

goto :EOF

:ReverseMovie
	del /Q .\tmp\* 2> NUL
	
	set movieFile=%~1
	set fileName=%~n1%~x1

	:: MP4 samples were all right, but AVI didn't work without "-reset_timestamps 1".
	::
	:: Reversing buffers the whole movie into memory.
	:: "-segment_time 30" caused ffmpeg to use 3 GB of RAM.
	:: Let this be small enough, so a computer with max 4 GB RAM can run it too.
	ffmpeg -loglevel %logLevel% -fflags +genpts -y -i "%movieFile%" -codec copy -f segment -segment_time 10 -reset_timestamps 1 -segment_list .\tmp\tmp.ffcat ".\tmp\chunk-%%03d-%fileName%"

	for %%c in (.\tmp\chunk*) do call :ReverseChunk "%%c"

	echo ffconcat version 1.0 > .\tmp\reversed.ffcat
	findstr /V "ffconcat version" .\tmp\tmp.ffcat | sort /R >> .\tmp\reversed.ffcat

	:: ffmpeg could not find the chunks if not relative to the current directory, even if relative to "reversed.ffcat".
	cd .\tmp
	:: "-safe 0" - to accept file names with spaces.
	..\ffmpeg -loglevel %logLevel% -y -safe 0 -i ".\reversed.ffcat" -codec copy "..\out\%fileName%"
	cd ..

	goto :EOF

:ReverseChunk
	set chunkFile=%~1
	set chunkFileName=%~n1%~x1
	set reversedChunkFile=.\tmp\rev-%chunkFileName%

	:: "-qscale:v" for AVI, "-crf" for MP4.
	ffmpeg -loglevel %logLevel% -y -i "%chunkFile%" -vf reverse -qscale:v 5 -crf 21 -af areverse "%reversedChunkFile%"
	move "%reversedChunkFile%" "%chunkFile%"

	goto :EOF