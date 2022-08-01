#!/bin/bash

# Prerequite packages: apt-get install coreutils grep curl jq

IMAGEMAGICKDIR="/mnt/c/Program Files/ImageMagick"

IMAGEVIEWERDIR="/mnt/c/Program Files/JPEGView64"

CMDDIR="/mnt/c/Windows/System32"

BROWSERDIR="/mnt/c/Program Files (x86)/Mozilla Firefox"

gc_api_key="..."

deepl_api_key="..."

if [[ $# -eq 0 ]]
then
	echo -e "Usage:\n\t${0} [ -s source_language ] [ -t target_language ] [ -e translation_engine ] ( -m mode ) ( -f font ) ( -r transfile )\n\n\tAvailable Source Languages: jp, zh, ko\n\n\tAvailable Translation Engines: google, deepl\n\n\tAvailable Operation Modes: interactive (default), automatic, ocr-only, no-typeset, typeset-from-file, interactive-typeset-from-file\n"
	exit 1
fi

if [[ $# -eq 1 ]]
then

	case "$1" in
		
		-h|--help)
			
			echo -e "Usage:\n\t${0} [ -s source_language ] [ -t target_language ] [ -e translation_engine ] ( -m mode ) ( -f font ) ( -r transfile )\n\n\tAvailable Source Languages: jp, zh, ko\n\n\tAvailable Translation Engines: google, deepl\n\n\tAvailable Operation Modes: interactive (default), automatic, ocr-only, no-typeset, typeset-from-file, interactive-typeset-from-file\n"
			exit 1
			;;
		
		-l|--font-list)
			
			echo -e "Available Fonts: $("$IMAGEMAGICKDIR"/convert.exe -list font | grep "Font:" | cut -d " " -f4 | sed 's/\r//g' | tr '\n' ',' | sed 's/,/, /g' | rev | cut -c 3- | rev)\n"
			exit 1
			;;
			
		-)
			
			echo "Invalid option: -"
			exit 1
			;;
			
		-*)
			
			echo "Invalid option: $1"
			exit 1
			;;
			
		*) 
			
			echo "No option supplied."
			exit 1
			;;
			
	esac
fi

if [[ $# -gt 10 ]]
then

	echo "Too many arguments supplied."
	exit 1
	
fi

if [[ ! $# -lt 6 ]]
then
	
	while [[ $# -gt 0 ]]
	do
		
		case "$1" in
		 
			-s|--sourcelang)  
			
				shift 
				sourcelang=${1}
				;;
				
			-t|--targetlang)   
					  
				shift
				targetlang=${1}
				;;
				
			-e|--transengine)    

				shift  
				transengine=${1}
				;;
			
			-m|--mode)
				
				shift
				mode=${1}
				;;
				
			-f|--font)
				
				shift
				font=${1}
				;;
				
			-r|--transfile)
				
				shift
				transfile=${1}
				;;
			
			-)
			
				echo "Invalid option: -"
				exit 1
				;;
			
			-*)
			
				echo "Invalid option: $1"
				exit 1
				;;
			
			*) 
				
				break
				;;
				
			esac
			
		shift 
		
	done
	
else

	echo "Too few arguments supplied."
	exit 1

fi

if [[ $mode == "" ]]
then
	mode="interactive"
fi

if [[ $mode != "interactive" ]] && [[ $mode != "automatic" ]] && [[ $mode != "ocr-only" ]] && [[ $mode != "no-typeset" ]] && [[ $mode != "typeset-from-file" ]] && [[ $mode != "interactive-typeset-from-file" ]]
then
	echo "Invalid operation mode."
	exit 2
fi

if [[ $font == "" ]]
then
	font="CC-Wild-Words-Roman"
fi

"$IMAGEMAGICKDIR"/convert.exe -list font | grep "Font:" | cut -d " " -f4 | grep -w "$font" &>> /dev/null
if [[ $? != 0 ]]
then
	echo -e "Font $font is not installed on your system.\nType \"${0} -l\" to see the full list of available fonts."
	exit 2
fi

if [[ $sourcelang == "" ]]
then
	echo "No source language specified."
	exit 2
fi

if [[ $sourcelang != "jp" ]] && [[ $sourcelang != "zh" ]] && [[ $sourcelang != "ko" ]]
then
	echo "This script only supports Japanese, Chinese and Korean as a source language."
	exit 2
fi

if [[ $sourcelang == "jp" ]]
then
	sourcelang="ja"
fi

if [[ $targetlang == "" ]]
then
	echo "No target language specified."
	exit 2
fi

if [[ $targetlang == "en" ]] && [[ $transengine == "deepl" ]]
then
	targetlang="en-gb"
fi

if [[ $transengine == "" ]]
then
	echo "No translation engine specified."
	exit 2
fi

if [[ $transengine != "google" ]] && [[ $transengine != "deepl" ]]
then
	echo "Invalid translation engine."
	exit 2
fi

if [[ $sourcelang == "ko" ]] && [[ $transengine == "deepl" ]]
then
	echo "Deepl does not currently support Korean language."
	exit 2
fi

if [[ $mode == "typeset-from-file" ]] || [[ $mode == "interactive-typeset-from-file" ]]
then

	transstringcount=0
	
	if [[ $transfile == "" ]]
	then
		transfile="transtext.txt"
	fi
	
	if [[ ! -f transtext.txt ]]
	then
		echo "transtext.txt does not exist."
		exit 2
	fi
	
	if [[ ! -f $transfile ]]
	then
		echo "$transfile does not exist."
		exit 2
	fi
	
fi

if [[ ! -f ruler.png ]]
then
	echo "Auto-generating ruler.png"
	echo 'iVBORw0KGgoAAAANSUhEUgAAAfUAAAAJCAIAAACkDSKQAAAACXBIWXMAAAsTAAALEwEAmpwYAAAGsGlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDggNzkuMTY0MDM2LCAyMDE5LzA4LzEzLTAxOjA2OjU3ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjEuMCAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIyLTA3LTI4VDEyOjA2OjE0KzAxOjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMi0wNy0yOFQyMTowNjo1NSswMTowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMi0wNy0yOFQyMTowNjo1NSswMTowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJzUkdCIElFQzYxOTY2LTIuMSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpiNWE3OTk5Ny1mOWIyLTY3NDItOWY0OC01NTcxMGIwNTRjODYiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6YzM0NzBjNWQtMDkwNC1hMDRjLWFhZGEtMGM2MjVjMmI4ZDA5IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6YzM0NzBjNWQtMDkwNC1hMDRjLWFhZGEtMGM2MjVjMmI4ZDA5Ij4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpjMzQ3MGM1ZC0wOTA0LWEwNGMtYWFkYS0wYzYyNWMyYjhkMDkiIHN0RXZ0OndoZW49IjIwMjItMDctMjhUMTI6MDY6MTQrMDE6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMS4wIChXaW5kb3dzKSIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZGY4YmYwMDUtYWQ1Yi1kNTRmLWE1MDMtNTI0ZjFlNjMyZDY3IiBzdEV2dDp3aGVuPSIyMDIyLTA3LTI4VDEzOjMzOjEzKzAxOjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjEuMCAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmI1YTc5OTk3LWY5YjItNjc0Mi05ZjQ4LTU1NzEwYjA1NGM4NiIgc3RFdnQ6d2hlbj0iMjAyMi0wNy0yOFQyMTowNjo1NSswMTowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjAgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PhaI56QAAAEkSURBVGiB7dq9DoIwFAXg03tJNGHSDXbfyA0f0d2HcfVnUNlMZAAcahxMxCYGvJVztnKB+w1tSEodgGO5rNstzEQlz2YbqkJCVXioCg9V4bGsSrrvQJvCXevmMGT1o5sqqqiiiqqPKnl5QN1CJX9eyeZrtOnwVaqooooqqr5UJQCaZqqyAIAW2Xy9P69UUj8csro7Faoj6mvEXNcTVXMqVmOfV1H0NWLubw0yDMMw/xkHYH9eidz82H8ffjLcnQrVajx9jZhtvorD2OdVFH2NmPt7VQJA5Ob//Krkx3IJd/Eb9n4rZ8BqObK+JsyqlUEVq7HPq0j6mjD3twYd3p+P1B/9+dXO80ZUUUUVVVSFqLrORz4ee7NP31+1O1RRRRVVVIWo7o2+8wHROkyBAAAAAElFTkSuQmCC' | base64 -d  > ruler.png
fi

[[ -f rawtext.txt ]] && rm rawtext.txt

[[ -f autotranstext.txt ]] && rm autotranstext.txt

[[ -f read.html ]] && rm read.html

for img in $(ls -v *.jpg)
do

imgconv=$(echo $img | tr "jpg" "png")

"$IMAGEMAGICKDIR"/convert.exe $img $imgconv

echo "Selected image: $imgconv"

"$IMAGEVIEWERDIR"/JPEGView.exe "$imgconv" &

#imgwidth=$("$IMAGEMAGICKDIR"/identify.exe -ping -format '%h' $imgconv)

#imgheight=$("$IMAGEMAGICKDIR"/identify.exe -ping -format '%h' $imgconv)

#"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill white -draw "rectangle 15,8 180,24" watercls_$imgconv

#"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill white -draw "rectangle 1320,$(( $imgheight - 88 )) 1584,$(( $imgheight - 16 ))" watercls_$imgconv

#base64 watercls_$imgconv > $imgconv.txt

base64 $imgconv > $imgconv.txt

echo -e "{\"requests\": [{\"image\": {\"content\": \"$(cat $imgconv.txt)\"},\"features\": [{\"type\": \"TEXT_DETECTION\"}]}]}" > ocrresquest.json

echo "OCRing image... "

curl -s -X POST -H "X-Goog-Api-Key: $gc_api_key" -H "Content-Type: application/json; charset=utf-8" -d @ocrresquest.json "https://vision.googleapis.com/v1/images:annotate" > ocrresponse.json

#rm watercls_$imgconv

rm $imgconv.txt

l=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks | length' ocrresponse.json)

echo "Number of text blocks found: $l"

i=0
while [[ $i != $l ]]
do

	echo "Fetching bounding box coordinates... "
	
	if [[ $i == 0 ]]
	then
	
		x1b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].boundingBox.vertices[0].x' ocrresponse.json)	
		x2b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].boundingBox.vertices[1].x' ocrresponse.json)
		x3b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].boundingBox.vertices[2].x' ocrresponse.json)
		x4b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].boundingBox.vertices[3].x' ocrresponse.json)
		
		y1b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].boundingBox.vertices[0].y' ocrresponse.json)
		y2b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].boundingBox.vertices[1].y' ocrresponse.json)
		y3b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].boundingBox.vertices[2].y' ocrresponse.json)
		y4b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].boundingBox.vertices[3].y' ocrresponse.json)
		
		diffy2by1b=$(( $y2b - $y1b ))

		if [[ ${diffy2by1b/#-/} -gt 5 ]]
		then
			i=$(($i+1))
			echo "Skipping diagonal bounding box."
			continue
		fi
		
	else
		
		if [[ $nextblockjoin == 1 ]]
		then
		
			if [[ $x1bn -lt $x1b ]]
			then
				x1b="$x1bn"
			fi
			
			if [[ $x3bn -gt $x3b ]]
			then
				x3b="$x3bn"
			fi
			
			y3b="$y3bn"
			
		else
		
			x1b="$x1bn"
			x3b="$x3bn"
			y1b="$y1bn"
			y3b="$y3bn"
			
		fi
		
	fi

	imgconvtmp=$( echo $imgconv | cut -d "." -f1 )
	imgconvtmp=$( echo $imgconvtmp\_tmp.png )
	imgconvtmp2=$( echo $imgconvtmp\_tmp2.png )
	
	cp $imgconv $imgconvtmp

	sleep 1
	"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill "rgba(228,237,47,0.5)" -stroke black -draw "rectangle $x1b,$y1b $x3b,$y3b" $imgconv
	
	echo "Extracting raw string... "
	
	breaks=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].paragraphs[].words[].symbols[].property.detectedBreak.type' ocrresponse.json | cut -d "\"" -f2)
	
	unset breakpos
	
	breakcont=0
	
	j=1
	for break in $breaks
	do
	
		if [[ "$break" == "SPACE" ]]
		then
			breakpos[$j]="SPACE"
		fi
		
		if [[ "$break" == "EOL_SURE_SPACE" ]] || [[ "$break" == "LINE_BREAK" ]]
		then
			breakcont=$(($breakcont+1))
			breakpos[$j]="SPACE"
		fi
		
		j=$(($j+1))
		
	done
	
	text=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$i"'].paragraphs[].words[].symbols[].text' ocrresponse.json | cut -d "\"" -f2)
	
	rawstring=""
	
	k=1
	for char in $text
	do
		if [[ "${breakpos[$k]}" == "SPACE" ]] && [[ $sourcelang == "ko" ]]
		then
			rawstring+="$char "
		else
			rawstring+="$char"
		fi
		k=$(($k+1))
	done

	[[ $sourcelang == "ko" ]] && rawstring=$(echo ${rawstring::${#rawstring}-1})
	
	x1bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$(($i+1))"'].boundingBox.vertices[0].x' ocrresponse.json)
	x2bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$(($i+1))"'].boundingBox.vertices[1].x' ocrresponse.json)
	x3bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$(($i+1))"'].boundingBox.vertices[2].x' ocrresponse.json)
	x4bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$(($i+1))"'].boundingBox.vertices[3].x' ocrresponse.json)
	
	y1bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$(($i+1))"'].boundingBox.vertices[0].y' ocrresponse.json)
	y2bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$(($i+1))"'].boundingBox.vertices[1].y' ocrresponse.json)
	y3bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$(($i+1))"'].boundingBox.vertices[2].y' ocrresponse.json)
	y4bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$(($i+1))"'].boundingBox.vertices[3].y' ocrresponse.json)
	
	if [[ $(echo $rawstring | grep -o -P '[\p{Hangul}]') == "" ]] && [[ $sourcelang == "ko" ]]
	then
		sleep 1
		mv $imgconvtmp $imgconv
		i=$(($i+1))
		echo "Selected raw string: $rawstring"
		echo "Skipping raw string."
		continue
	fi 
	
	if [[ $(echo $rawstring | grep -o -P '[\p{Han}]') == "" ]] && [[ $sourcelang == "zh" ]]
	then
		sleep 1
		mv $imgconvtmp $imgconv
		i=$(($i+1))
		echo "Selected raw string: $rawstring"
		echo "Skipping raw string."
		continue
	fi
	
	if ( [[ $(echo $rawstring | grep -o -P '[\p{Han}]') == "" ]] && [[ $(echo $rawstring | grep -o -P '[\p{Hiragana}]') == "" ]] && [[ $(echo $rawstring | grep -o -P '[\p{Katakana}]') == "" ]] ) && [[ $sourcelang == "jp" ]]
	then
		sleep 1
		mv $imgconvtmp $imgconv
		i=$(($i+1))
		echo "Selected raw string: $rawstring"
		echo "Skipping raw string."
		continue
	fi
	
	if [[ $nextblockjoin == 1 ]]
	then
		rawstring="$prevrawstring $rawstring"
		nextblockjoin=0
	fi

	diffy2bny1bn=$(( $y2bn - $y1bn ))

	if [[ $x1bn != "null" ]] && [[ $y1bn -gt $y3b ]] && [[ $y1bn -lt $(( $y3b + (($y3b - $y1b) / $breakcont) )) ]] && [[ ${diffy2bny1bn/#-/} -lt 5 ]] && ( [[ $sourcelang == "ko" ]] || [[ $sourcelang == "zh" ]] )
	then
		nextblockjoin=1
		prevrawstring="$rawstring"
		sleep 1
		mv $imgconvtmp $imgconv
		i=$(($i+1))
		echo "Selected raw string: $rawstring"
		echo "Next block will be joined."
		continue
	fi

	echo "Selected raw string: $rawstring"
	
	echo "$rawstring" >> rawtext.txt
	
	if [[ $mode == "interactive" ]]
	then
	
		read -e -p "Type edited raw string, type skip or press enter to translate current raw string... " string
	
		if [[ "$string" == "skip" ]]
		then
			sleep 1
			mv $imgconvtmp $imgconv
			i=$(($i+1))
			echo "Skipping raw string as per user request."
			continue
		fi
	
		if [[ "$string" != "" ]]
		then
			rawstring="$string"
		fi
		
	fi
	
	if [[ $mode == "ocr-only" ]]
	then
		sleep 1
		mv $imgconvtmp $imgconv
		i=$(($i+1))
		continue
	fi
	
	if [[ $transengine == "google" ]]
	then
	
		if [[ $mode == "typeset-from-file" ]] || [[ $mode == "interactive-typeset-from-file" ]]
		then
		
			echo "Using user provided translated string."
			transstringcount=$(( $transstringcount + 1 ))
			transstring=$(cat $transfile | tail -n +$transstringcount | head -n +1)
			
			if [[ $transstring == "Ignore" ]] || [[ $transstring == "ignore" ]]
			then
				sleep 1
				mv $imgconvtmp $imgconv
				i=$(($i+1))
				echo "Ignoring as per user input."
				continue
			fi
			
		else
		
			echo -e "{\n \"q\": \"$rawstring\",\n \"source\": \"$sourcelang\",\n \"target\": \"$targetlang\",\n \"format\": \"text\"\n}" > transresquest.json
			echo "Translating raw string... "
			transstring=$(curl -s -X POST -H "X-Goog-Api-Key: $gc_api_key" -H "Content-Type: application/json; charset=utf-8" -d @transresquest.json "https://translation.googleapis.com/language/translate/v2" | jq '.data.translations[].translatedText' | sed 's/\"//g' | sed 's/\\//g')
			echo "$transstring" >> autotranstext.txt
			
		fi
	fi
	
	if [[ $transengine == "deepl" ]]
	then
		if [[ $mode == "typeset-from-file" ]] || [[ $mode == "interactive-typeset-from-file" ]]
		then
		
			echo "Using user provided translated string."
			transstringcount=$(( $transstringcount + 1 ))
			transstring=$(cat $transfile | tail -n +$transstringcount | head -n +1)
			
			if [[ $transstring == "Ignore" ]] || [[ $transstring == "ignore" ]]
			then
				sleep 1
				mv $imgconvtmp $imgconv
				i=$(($i+1))
				echo "Ignoring as per user input."
				continue
			fi
			
		else
		
			echo "Translating raw string... "
			transstring=$(curl -s "https://api-free.deepl.com/v2/translate" -d "auth_key=$deepl_api_key" -d "text=$rawstring" -d "source_lang=$sourcelang" -d "target_lang=$targetlang" | jq '.translations[].text' | sed 's/\"//g' | sed 's/\\//g')
			echo "$transstring" >> autotranstext.txt
			
		fi
	fi
	
	if [[ $mode == "no-typeset" ]]
	then
		sleep 1
		mv $imgconvtmp $imgconv
		i=$(($i+1))
		continue
	fi
	
	x1boffset=0
	x3boffset=5
	y1boffset=0
	y3boffset=5
	
	fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font $font -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
	echo "Font size $fontsize automatically selected as best fit."

	while true
	do

		echo "Translated string: $transstring"
	
		if [[ $mode == "interactive" ]] || [[ $mode == "interactive-typeset-from-file" ]]
		then
	
			read -e -p "Type edited translated string or press enter to typeset current translated string... " string
	
			if [[ "$string" != "" ]]
			then
				transstring="$string"
				fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font $font -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
				echo "Font size $fontsize automatically selected as best fit."
			fi
			
		fi
		
		sleep 1
		"$IMAGEMAGICKDIR"/convert.exe $imgconvtmp -fill white -stroke none -draw "rectangle $(($x1b - 5 - $x1boffset)),$(($y1b - 5 - $y1boffset)) $(($x3b + 5 + $x3boffset)),$(($y3b + 5 + $y3boffset))" $imgconv
		
		sleep 1
		"$IMAGEMAGICKDIR"/convert.exe $imgconv \( -font $font -fill black -pointsize $fontsize -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) -gravity center -background none caption:"$transstring" \) -gravity northwest -geometry +$(($x1b - $x1boffset))+$(($y1b - $y1boffset)) -composite $imgconv

		if [[ $mode == "interactive" ]] || [[ $mode == "interactive-typeset-from-file" ]]
		then

			while true
			do

				read -e -p "Do you wish to proceed to the next text bubble (y/n)? " string
		
				if [[ $string == Y ]] || [[ $string == y ]] || [[ $string == Yes ]] || [[ $string == yes ]]
				then
					
					break 2
				
				elif [[ $string != N ]] && [[ $string != n ]] && [[ $string != No ]] && [[ $string != no ]]
				then
				
					continue
				
				else
					
					sleep 1
					"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill "rgba(228,237,47,0.5)" -stroke none -draw "rectangle $(($x1b - 5 - $x1boffset)),$(($y1b - 5 - $y1boffset)) $(($x3b + 5 + $x3boffset)),$(($y3b + 5 + $y3boffset))" $imgconv
				
					sleep 1
					"$IMAGEMAGICKDIR"/convert.exe $imgconv \( ruler.png -alpha set -channel A -evaluate set 50% \) -set colorspace sRGB -gravity northwest -geometry +$(($x1b - 106 - $x1boffset))+$(($y1b - 10 - $y1boffset)) -composite $imgconv
			
					sleep 1
					"$IMAGEMAGICKDIR"/convert.exe $imgconv \( ruler.png -alpha set -channel A -evaluate set 50% -rotate -90 \) -set colorspace sRGB -gravity northwest -geometry +$(($x1b - 10 - $x1boffset))+$(($y1b - 106 - $y1boffset)) -composite $imgconv
				
					while true
					do
				
						read -e -p "Type new x1 (left), x3 (right), y1 (up) and y3 (down) offsets (0,5,0,5) or press enter to continue... " string
				
						if [[ $string != "" ]]
						then
				
							stringx1=$(echo $string | cut -d "," -f1)
							stringx3=$(echo $string | cut -d "," -f2)
							stringy1=$(echo $string | cut -d "," -f3)
							stringy3=$(echo $string | cut -d "," -f4)
					
							if [[ "$stringx1" =~ ^-?[0-9]+$ ]] && [[ "$stringx3" =~ ^-?[0-9]+$ ]] && [[ "$stringy1" =~ ^-?[0-9]+$ ]] && [[ "$stringy3" =~ ^-?[0-9]+$ ]] 
							then
						
								x1boffset="$stringx1"
								x3boffset="$stringx3"
								y1boffset="$stringy1"
								y3boffset="$stringy3"
								
								sleep 1
								cp $imgconv $imgconvtmp2
								
								sleep 1
								"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill "rgba(23,235,108,0.5)" -stroke none -draw "rectangle $(($x1b - 5 - $x1boffset)),$(($y1b - 5 - $y1boffset)) $(($x3b + 5 + $x3boffset)),$(($y3b + 5 + $y3boffset))" $imgconv
							
								fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font $font -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
								echo "Font size $fontsize automatically selected as best fit."
						
								read -e -p "Do you wish to continue (y/n)? " string
		
								if [[ $string == Y ]] || [[ $string == y ]] || [[ $string == Yes ]] || [[ $string == yes ]]
								then
									
									break
				
								elif [[ $string != N ]] && [[ $string != n ]] && [[ $string != No ]] && [[ $string != no ]]
								then
								
									echo "Invalid option."
									break
				
								else
								
									sleep 1
									mv $imgconvtmp2 $imgconv
									continue
						
								fi
							
							else
						
								echo "Typed input is not number seperated list."
								break
							
							fi
							
						else
						
							break
					
						fi
				
					done
				
					read -p "Type new font type or press enter to continue... " string

					if [[ $string != "" ]]
					then

						"$IMAGEMAGICKDIR"/convert.exe -list font | grep "Font:" | cut -d " " -f4 | grep -w "$string" &>> /dev/null
						if [[ $? != 0 ]]
						then
							echo "Font $string does not exist."
						else
							font="$string"
							fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font $font -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
							echo "Font size $fontsize automatically selected as best fit."
						fi
					
					fi
				
					read -p "Type new font size or press enter to continue... " string
				
					if [[ $string == "" ]]
					then
						break
					fi
				
					if [[ "$string" =~ ^[0-9]+$ ]]
					then
						[[ $string -gt $fontsize ]] && echo "Typed input is greater than recommended best fit. Clipping is likely to occur."
						fontsize="$string"
						break
					else
						echo "Typed input is not a number."
						break
					fi
				
				fi
			
			done
			
		else
		
			break
			
		fi
		
	done
	
	rm $imgconvtmp
	
	i=$(($i+1))
	
done

"$CMDDIR"/cmd.exe /c start taskkill /IM JPEGView.exe

done

echo "All images have been successfully processed."

read -p "Place the all the images on the folder and then press any key or press enter to exit... " string

if [[ $string != "" ]]
then

	echo "Generating read.html... "

	echo -e "<html>\n<body bgcolor=0>\n<center>" >> read.html
 
	for image in $(ls -v *.png) 
	do 
		echo "<img src=./$image><br>" >> read.html 
	done

	echo -e "</center>\n</body>\n</html>" >> read.html

	sed -i '/ruler.png/d' read.html

	curdir="$(echo $(pwd) | sed 's/\//\\/g' | cut -c 6):$(echo $(pwd) | sed 's/\//\\/g' | cut -c 7-)"

	[[ -f "$BROWSERDIR"/firefox.exe ]] && "$BROWSERDIR"/firefox.exe file:///"$curdir"/read.html || echo "Could not find Firefox browser."

fi

exit 0

