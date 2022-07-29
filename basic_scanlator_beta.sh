#!/bin/bash

# Prerequite packages: apt-get install coreutils grep curl jq

IMAGEMAGICKDIR="/mnt/c/Program Files/ImageMagick"

IMAGEVIEWERDIR="/mnt/c/Program Files/JPEGView64"

gc_api_key="..."

deepl_api_key="..."

if [[ $# -lt 3 ]]
then
	echo -e "Usage:\n\t${0} [Source Language] [Target Language] [Translation Engine] (Mode)\n\n\tAvailable Source Languages: jp, zh, ko\n\n\tAvailable Translation Engines: google, deepl\n\n\tAvailable Operation Modes: interactive (default), automatic, ocr-only, typeset-from-file, interactive-typeset-from-file\n"
	exit 1
fi

sourcelang=${1}
targetlang=${2}
transengine=${3}
mode=${4}

if [[ $mode == "" ]]
then
	mode="interactive"
fi

if [[ $mode != "interactive" ]] && [[ $mode != "automatic" ]] && [[ $mode != "ocr-only" ]] && [[ $mode != "typeset-from-file" ]] && [[ $mode != "interactive-typeset-from-file" ]]
then
	echo "Invalid operation mode."
	exit 2
fi

if [[ $sourcelang != "jp" ]] && [[ $sourcelang != "zh" ]] && [[ $sourcelang != "ko" ]]
then
	echo "This script only supports Japanese, Chinese and Korean as a source language."
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

if [[ $sourcelang == "jp" ]]
then
	sourcelang="ja"
fi

if [[ $targetlang == "en" ]] && [[ $transengine == "deepl" ]]
then
	targetlang="en-gb"
fi

if [[ $mode == "typeset-from-file" ]] || [[ $mode == "interactive-typeset-from-file" ]]
then
	if [[ ! -f transtext.txt ]]
	then
		echo "transtext.txt does not exist."
		exit 2
	fi
fi

if [[ ! -f ruler.png ]]
then
	echo "Could not find ruler.png"
	exit 2
fi

[[ -f rawtext.txt ]] && rm rawtext.txt

[[ -f read.html ]] && rm read.html

transstringcount=0

for img in $(ls -v *.jpg)
do

imgconv=$(echo $img | tr "jpg" "png")

"$IMAGEMAGICKDIR"/convert.exe $img $imgconv

echo "Selected image: $imgconv"

"$IMAGEVIEWERDIR"/JPEGView.exe "$imgconv" &

imgwidth=$("$IMAGEMAGICKDIR"/identify.exe -ping -format '%h' $imgconv)

imgheight=$("$IMAGEMAGICKDIR"/identify.exe -ping -format '%h' $imgconv)

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
			transstring=$(cat transtext.txt | tail -n +$transstringcount | head -n +1)
			
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
			
		fi
	fi
	
	if [[ $transengine == "deepl" ]]
	then
		if [[ $mode == "typeset-from-file" ]] || [[ $mode == "interactive-typeset-from-file" ]]
		then
		
			echo "Using user provided translated string."
			transstringcount=$(( $transstringcount + 1 ))
			transstring=$(cat transtext.txt | tail -n +$transstringcount | head -n +1)
			
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
			
		fi
	fi
	
	x1boffset=0
	x3boffset=5
	y1boffset=0
	y3boffset=5
	
	fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font CC-Wild-Words-Roman -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
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
				fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font CC-Wild-Words-Roman -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
				echo "Font size $fontsize automatically selected as best fit."
			fi
			
		fi
		
		sleep 1
		"$IMAGEMAGICKDIR"/convert.exe $imgconvtmp -fill white -stroke none -draw "rectangle $(($x1b - 5 - $x1boffset)),$(($y1b - 5 - $y1boffset)) $(($x3b + 5 + $x3boffset)),$(($y3b + 5 + $y3boffset))" $imgconv
		
		sleep 1
		"$IMAGEMAGICKDIR"/convert.exe $imgconv \( -font CC-Wild-Words-Roman -fill black -pointsize $fontsize -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) -gravity center -background none caption:"$transstring" \) -gravity northwest -geometry +$(($x1b - $x1boffset))+$(($y1b - $y1boffset)) -composite $imgconv

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
							
								fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font CC-Wild-Words-Roman -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
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

/mnt/c/Windows/System32/cmd.exe /c start taskkill /IM JPEGView.exe

done

echo "All images have been successfully processed."

echo "Generating read.html... "

echo -e "<html>\n<body bgcolor=0>\n<center>" >> read.html
 
for image in $(ls -v *.png) 
do 
	echo "<img src=./$image><br>" >> read.html 
done

echo -e "</center>\n</body>\n</html>" >> read.html

sed -i '/ruler.png/d' read.html

curdir="$(echo $(pwd) | sed 's/\//\\/g' | cut -c 6):$(echo $(pwd) | sed 's/\//\\/g' | cut -c 7-)"

[[ -f "/mnt/c/Program Files (x86)/Mozilla Firefox"/firefox.exe ]] && "/mnt/c/Program Files (x86)/Mozilla Firefox"/firefox.exe file:///"$curdir"/read.html || echo "Could not find Firefox browser."

exit 1

