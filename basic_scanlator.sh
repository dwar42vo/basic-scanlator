#!/bin/bash

# Original Author: Dwarvo Lasorsk
# Current Revision: 20220819 (v0.8)

# Prerequite Packages: apt-get install coreutils grep curl jq

# Directories of Executables Declaration 
IMAGEMAGICKDIR="/mnt/c/Program Files/ImageMagick"
IMAGEVIEWERDIR="/mnt/c/Program Files/JPEGView64"
CMDDIR="/mnt/c/Windows/System32"
FIREFOXDIR="/mnt/c/Program Files (x86)/Mozilla Firefox"
CHROMEDIR="/mnt/c/Program Files (x86)/Google/Chrome/Application"

# API Keys Declaration
gc_api_key="..."
deepl_api_key="..."

# Argument Parsing
if [[ $# -eq 0 ]]
then
	echo -e "Usage:\n\t${0} [ -s source_language ] [ -t target_language ] [ -e translation_engine ] ( -m mode ) ( -f font ) ( -o manga|webtoon ) ( -r transfile )\n\n\tAvailable Source Languages: jp, zh, ko\n\n\tAvailable Translation Engines: google, deepl\n\n\tAvailable Operation Modes: interactive (default), automatic, ocr-only, no-typeset, typeset-from-file, interactive-typeset-from-file\n\n\tAvailable Optimizations: webtoon (default), manga\n"
	exit 1
fi

if [[ $# -eq 1 ]]
then

	case "$1" in
		
		-h|--help)
			
			echo -e "Usage:\n\t${0} [ -s source_language ] [ -t target_language ] [ -e translation_engine ] ( -m mode ) ( -f font ) ( -o manga|webtoon ) ( -r transfile )\n\n\tAvailable Source Languages: jp, zh, ko\n\n\tAvailable Translation Engines: google, deepl\n\n\tAvailable Operation Modes: interactive (default), automatic, ocr-only, no-typeset, typeset-from-file, interactive-typeset-from-file\n\n\tAvailable Optimizations: webtoon (default), manga\n"
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

if [[ $# -gt 16 ]]
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
				
			-o|--optimize)
			
				shift
				optimize=${1}
				;;
				
			-i|--input-image-format)
			
				shift
				input_image_format=${1}
				;;
			
			-a|--advanced-typeset-box)
			
				advanced_typeset_box_calc=1
				;;
			
			-q)
			
				quietness=1
				;;
			
			-qq)
			
				quietness=2
				;;
				
			-qqq)
			
				quietness=3
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

# Argument Validation
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

if [[ $optimize == "" ]]
then
	optimize="none"
fi

if [[ $optimize != "manga" ]] && [[ $optimize != "webtoon" ]] && [[ $optimize != "none" ]]
then
	echo "Invalid optimization."
	exit 2
fi

if [[ $input_image_format == "" ]]
then
	input_image_format="jpg"
fi

input_image_format=$( echo "$input_image_format" | tr '[:upper:]' '[:lower:]' )
if [[ $input_image_format != "jpg" ]] && [[ $input_image_format != "png" ]] && [[ $input_image_format != "webp" ]]
then
	echo "Unsupported or invalid input image format."
	exit 2
fi

if [[ $advanced_typeset_box_calc == "" ]]
then
	advanced_typeset_box_calc=0
fi

if [[ $advanced_typeset_box_calc == 1 ]] && ( [[ $mode == "ocr-only" ]] || [[ $mode == "no-typeset" ]] )
then
	echo "Advanced typeset box calculator cannot be used with modes ocr-only and no-typeset."
	exit 2
fi

if [[ $quietness == "" ]]
then
	quietness=0
fi

if [[ $quietness -gt 0 ]] && [[ $mode != "automatic" ]] && [[ $mode != "ocr-only" ]] && [[ $mode != "no-typeset" ]] && [[ $mode != "typeset-from-file" ]]
then
	echo "Quietness can only be used with modes automatic, ocr-only, no-typeset and typeset-from-file."
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
	
	if [[ ! -f $transfile ]]
	then
		echo "$transfile does not exist."
		exit 2
	fi
	
fi

# Ruler Auto-Generation
if [[ ! -f ruler.png ]]
then
	echo "Auto-generating ruler.png"
	echo 'iVBORw0KGgoAAAANSUhEUgAAAfUAAAAJCAIAAACkDSKQAAAACXBIWXMAAAsTAAALEwEAmpwYAAAGsGlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDggNzkuMTY0MDM2LCAyMDE5LzA4LzEzLTAxOjA2OjU3ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjEuMCAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIyLTA3LTI4VDEyOjA2OjE0KzAxOjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyMi0wNy0yOFQyMTowNjo1NSswMTowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMi0wNy0yOFQyMTowNjo1NSswMTowMCIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIHBob3Rvc2hvcDpJQ0NQcm9maWxlPSJzUkdCIElFQzYxOTY2LTIuMSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpiNWE3OTk5Ny1mOWIyLTY3NDItOWY0OC01NTcxMGIwNTRjODYiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6YzM0NzBjNWQtMDkwNC1hMDRjLWFhZGEtMGM2MjVjMmI4ZDA5IiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6YzM0NzBjNWQtMDkwNC1hMDRjLWFhZGEtMGM2MjVjMmI4ZDA5Ij4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpjMzQ3MGM1ZC0wOTA0LWEwNGMtYWFkYS0wYzYyNWMyYjhkMDkiIHN0RXZ0OndoZW49IjIwMjItMDctMjhUMTI6MDY6MTQrMDE6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMS4wIChXaW5kb3dzKSIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZGY4YmYwMDUtYWQ1Yi1kNTRmLWE1MDMtNTI0ZjFlNjMyZDY3IiBzdEV2dDp3aGVuPSIyMDIyLTA3LTI4VDEzOjMzOjEzKzAxOjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjEuMCAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmI1YTc5OTk3LWY5YjItNjc0Mi05ZjQ4LTU1NzEwYjA1NGM4NiIgc3RFdnQ6d2hlbj0iMjAyMi0wNy0yOFQyMTowNjo1NSswMTowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjAgKFdpbmRvd3MpIiBzdEV2dDpjaGFuZ2VkPSIvIi8+IDwvcmRmOlNlcT4gPC94bXBNTTpIaXN0b3J5PiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PhaI56QAAAEkSURBVGiB7dq9DoIwFAXg03tJNGHSDXbfyA0f0d2HcfVnUNlMZAAcahxMxCYGvJVztnKB+w1tSEodgGO5rNstzEQlz2YbqkJCVXioCg9V4bGsSrrvQJvCXevmMGT1o5sqqqiiiqqPKnl5QN1CJX9eyeZrtOnwVaqooooqqr5UJQCaZqqyAIAW2Xy9P69UUj8csro7Faoj6mvEXNcTVXMqVmOfV1H0NWLubw0yDMMw/xkHYH9eidz82H8ffjLcnQrVajx9jZhtvorD2OdVFH2NmPt7VQJA5Ob//Krkx3IJd/Eb9n4rZ8BqObK+JsyqlUEVq7HPq0j6mjD3twYd3p+P1B/9+dXO80ZUUUUVVVSFqLrORz4ee7NP31+1O1RRRRVVVIWo7o2+8wHROkyBAAAAAElFTkSuQmCC' | base64 -d  > ruler.png
fi

# Auto-Generated Files Removal 
[[ -f rawtext.txt ]] && rm rawtext.txt
[[ -f autotranstext.txt ]] && rm autotranstext.txt
[[ -f read.html ]] && rm read.html

# Functions
fetch_coordinates () {

	if [[ $2 == 0 ]]
	then
		x1b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[0].x' ocrresponse.json)	
		x2b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[1].x' ocrresponse.json)
		x3b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[2].x' ocrresponse.json)
		x4b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[3].x' ocrresponse.json)
		
		y1b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[0].y' ocrresponse.json)
		y2b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[1].y' ocrresponse.json)
		y3b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[2].y' ocrresponse.json)
		y4b=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[3].y' ocrresponse.json)
	fi
	
	if [[ $2 == 1 ]]
	then
		x1bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[0].x' ocrresponse.json)
		x2bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[1].x' ocrresponse.json)
		x3bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[2].x' ocrresponse.json)
		x4bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[3].x' ocrresponse.json)
	
		y1bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[0].y' ocrresponse.json)
		y2bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[1].y' ocrresponse.json)
		y3bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[2].y' ocrresponse.json)
		y4bn=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks['"$1"'].boundingBox.vertices[3].y' ocrresponse.json)
	fi

}

find_box_border_coordinates () {

	if [[ $9 == 0 ]] && [[ $8 == x ]]; then xcrop="200"; ycrop="1"; mirror="-flop"; offoper="-"; fi
	if [[ $9 == 0 ]] && [[ $8 == y ]]; then xcrop="1"; ycrop="200"; mirror="-flip"; offoper="-"; fi
	if [[ $9 == 1 ]] && [[ $8 == x ]]; then xcrop="200"; ycrop="1"; mirror=""; offoper="+"; fi 
	if [[ $9 == 1 ]] && [[ $8 == y ]]; then xcrop="1"; ycrop="200"; mirror=""; offoper="+"; fi
	
	for line in $( "$IMAGEMAGICKDIR"/convert.exe $img -set colorspace Gray -alpha off -gravity northwest -crop $xcrop\x$ycrop+$1+$2 $mirror txt:- | awk -F " " '{print $1$2}' | tail -n +2 ) 
	do
	
#		echo "Debug: $line"
		color=$( echo $line | cut -d ":" -f2 | tr -d "(" | tr -d ")" ) 
		if [[ $color -le 128 ]] 
		then 
			
			if [[ $8 == x ]]
			then
				offset=$(( $(echo "$line" | cut -d ":" -f1 | cut -d "," -f1 ) - $3 ))
				[[ $quietness -lt 1 ]] && "$IMAGEMAGICKDIR"/convert.exe $imgconv -fill red -stroke black -draw "circle $(( $4 $offoper $offset )),$5 $(( $6 $offoper $offset )),$7" $imgconv
			fi
			
			if [[ $8 == y ]] 
			then
				offset=$(( $(echo "$line" | cut -d ":" -f1 | cut -d "," -f2 ) - $3 ))
				[[ $quietness -lt 1 ]] && "$IMAGEMAGICKDIR"/convert.exe $imgconv -fill red -stroke black -draw "circle $4,$(( $5 $offoper $offset )) $6,$(( $7 $offoper $offset ))" $imgconv
			fi
				
			break
		
		fi
	
	done
	
	echo $offset

}

box_border_coordinates_pick_min () {

	if [[ $1 != "" ]]
	then
		if [[ $2 != "" ]]
		then
			if [[ $1 -ge 0 ]] && [[ $2 -ge 0 ]]
			then
				[[ $2 -gt $1 ]] && offset="$1" || offset="$2"
			fi
		else
			if [[ $1 -ge 0 ]]
			then
				offset="$1"
			fi
		fi
	fi
	
	echo $offset

}

font_size_optimizer () {

	[[ $optimize == "manga" ]] && ifs=("0" "6" "8" "14" "18" "22" "26" "32" "38");
	[[ $optimize == "webtoon" ]] && ifs=("0" "12" "16" "22" "26" "30" "34" "40" "46");

	if [[ $fontsize -lt ${ifs[1]} ]]
	then
					
		while [[ $fontsize -lt ${ifs[2]} ]]
		do
			x1boffset=$(( $x1boffset + 5 ))
			x3boffset=$(( $x3boffset + 5 ))
			fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font $font -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
		done
					
		[[ $quietness -lt 2 ]] && echo "Font size too small. Automatically reajusted x1 (left) and x3 (right) to $x1boffset and $x3boffset."
		[[ $quietness -lt 2 ]] && echo "Font size automatically reajusted to $fontsize."
					
	fi
	
	if [[ $fontsize -gt ${ifs[3]} ]] && [[ $fontsize -le ${ifs[5]} ]]
	then
		fontsize=${ifs[3]}
		[[ $quietness -lt 2 ]] && echo "Font size too large. Resizing to $fontsize."
	fi
	
	if [[ $fontsize -gt ${ifs[5]} ]] && [[ $fontsize -le ${ifs[7]} ]]
	then
		fontsize=${ifs[4]}
		[[ $quietness -lt 2 ]] && echo "Font size too large. Resizing to $fontsize."
	fi
	
	if [[ $fontsize -gt ${ifs[7]} ]] && [[ $fontsize -le ${ifs[8]} ]]
	then
		fontsize=${ifs[5]}
		[[ $quietness -lt 2 ]] && echo "Font size too large. Resizing to $fontsize."
	fi
	
	if [[ $fontsize -gt ${ifs[8]} ]]
	then
		fontsize=${ifs[6]}
		[[ $quietness -lt 2 ]] && echo "Font size too large. Resizing to $fontsize."
	fi

}

# Image Cycle
for img in $(ls -v *.$input_image_format)
do

# Image to PNG Conversion
if [[ "$input_image_format" != "png" ]]
then

	imgconv=$( echo $img | tr ".$input_image_format" ".png" )
	"$IMAGEMAGICKDIR"/convert.exe $img $imgconv
	
else

	[[ $img == "ruler.png" ]] && continue
	imgconv=$( echo $img | sed 's/.png/mod.png/' )
	cp $img $imgconv
	
fi

[[ $quietness -lt 3 ]] && echo "Selected image: $imgconv"

# Opening of Image with JPEGView
[[ $quietness -lt 1 ]] && "$IMAGEVIEWERDIR"/JPEGView.exe "$imgconv" &

imgwidth=$("$IMAGEMAGICKDIR"/identify.exe -ping -format '%w' $imgconv)
imgheight=$("$IMAGEMAGICKDIR"/identify.exe -ping -format '%h' $imgconv)

# Watermark Removal (Optional)
#"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill white -draw "rectangle 15,8 180,24" watercls_$imgconv
#"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill white -draw "rectangle $(( $imgwidth - 150 )),$(( $imgheight - 32 )) $imgwidth,$imgheight" watercls_$imgconv

# OCR Request
#base64 watercls_$imgconv > $imgconv.txt
base64 $imgconv > $imgconv.txt

echo -e "{\"requests\": [{\"image\": {\"content\": \"$(cat $imgconv.txt)\"},\"features\": [{\"type\": \"TEXT_DETECTION\"}]}]}" > ocrresquest.json

[[ $quietness -lt 3 ]] && echo "OCRing image... "

curl -s -X POST -H "X-Goog-Api-Key: $gc_api_key" -H "Content-Type: application/json; charset=utf-8" -d @ocrresquest.json "https://vision.googleapis.com/v1/images:annotate" > ocrresponse.json

[[ -f watercls_$imgconv ]] && rm watercls_$imgconv
[[ -f $imgconv.txt ]] && rm $imgconv.txt

numtb=$(jq '.responses[0].fullTextAnnotation.pages[0].blocks | length' ocrresponse.json)

[[ $quietness -lt 2 ]] && echo "Number of text blocks found: $numtb"

# Bounding Box Cycle
i=0
while [[ $i != $numtb ]]
do

	[[ $quietness -lt 2 ]] && echo "Fetching bounding box coordinates... "
	
	if [[ $i == 0 ]]
	then
	
		fetch_coordinates $i 0
		
		# Fix rotated coordinates
		if [[ $y1b -gt $y3b ]] && [[ $x1b -lt $x3b ]]
		then
			ytmp=$y1b
			y1b=$y3b
			y3b=$ytmp
		fi
		
		if [[ $y2b -lt $y4b ]] && [[ $x2b -lt $x4b ]]
		then
			xtmp=$x2b
			x2b=$x4b
			x4b=$xtmp
		fi
		
		# Ignore diagonal bounding box
		diffy2by1b=$(( $y2b - $y1b ))
		diffy4by3b=$(( $y4b - $y3b ))

		if [[ ${diffy2by1b/#-/} -gt 5 ]] && [[ ${diffy4by3b/#-/} -gt 5 ]]
		then
		
			fetch_coordinates $(($i+1)) 1
			
			i=$(($i+1))
			[[ $quietness -lt 2 ]] && echo "Skipping diagonal bounding box."
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
			x2b="$x2bn"
			x3b="$x3bn"
			x4b="$x4bn"
			
			y1b="$y1bn"
			y2b="$y2bn"
			y3b="$y3bn"
			y4b="$y4bn"
			
			# Fix rotated coordinates
			if [[ $y1b -gt $y3b ]] && [[ $x1b -lt $x3b ]]
			then
				ytmp=$y1b
				y1b=$y3b
				y3b=$ytmp
			fi
		
			if [[ $y2b -lt $y4b ]] && [[ $x2b -lt $x4b ]]
			then
				xtmp=$x2b
				x2b=$x4b
				x4b=$xtmp
			fi
		
			# Ignore diagonal bounding box
			diffy2by1b=$(( $y2b - $y1b ))
			diffy4by3b=$(( $y4b - $y3b ))

			if [[ ${diffy2by1b/#-/} -gt 5 ]] && [[ ${diffy4by3b/#-/} -gt 5 ]]
			then
			
				fetch_coordinates $(($i+1)) 1
			
				i=$(($i+1))
				[[ $quietness -lt 2 ]] && echo "Skipping diagonal bounding box."
				continue
			
			fi
			
		fi
		
	fi
	
	echo "Debug: X: $x1b $x2b $x3b $x4b || Y: $y1b $y2b $y3b $y4b"

	imgconvtmpname=$( echo $imgconv | cut -d "." -f1 )
	imgconvtmp=$( echo $imgconvtmpname\_tmp.png )
	imgconvtmp2=$( echo $imgconvtmpname\_tmp2.png )
	imgconvtmp3=$( echo $imgconvtmpname\_tmp3.png )
	
	[[ $quietness -lt 1 ]] && cp $imgconv $imgconvtmp

	sleep 1
	[[ $quietness -lt 1 ]] && "$IMAGEMAGICKDIR"/convert.exe $imgconv -fill "rgba(228,237,47,0.5)" -stroke black -draw "rectangle $x1b,$y1b $x3b,$y3b" $imgconv
	
	# Raw String Extraction Phase
	[[ $quietness -lt 3 ]] && echo "Extracting raw string... "
	
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
	
	fetch_coordinates $(($i+1)) 1
	
	if [[ $(echo $rawstring | grep -o -P '[\p{Hangul}]') == "" ]] && [[ $sourcelang == "ko" ]]
	then
		sleep 1
		[[ $quietness -lt 1 ]] && mv $imgconvtmp $imgconv
		i=$(($i+1))
		[[ $quietness -lt 2 ]] && echo "Selected raw string: $rawstring"
		[[ $quietness -lt 2 ]] && echo "Skipping raw string."
		continue
	fi 
	
	if [[ $(echo $rawstring | grep -o -P '[\p{Han}]') == "" ]] && [[ $sourcelang == "zh" ]]
	then
		sleep 1
		[[ $quietness -lt 1 ]] && mv $imgconvtmp $imgconv
		i=$(($i+1))
		[[ $quietness -lt 2 ]] && echo "Selected raw string: $rawstring"
		[[ $quietness -lt 2 ]] && echo "Skipping raw string."
		continue
	fi
	
	if ( [[ $(echo $rawstring | grep -o -P '[\p{Han}]') == "" ]] && [[ $(echo $rawstring | grep -o -P '[\p{Hiragana}]') == "" ]] && [[ $(echo $rawstring | grep -o -P '[\p{Katakana}]') == "" ]] ) && [[ $sourcelang == "ja" ]]
	then
		sleep 1
		[[ $quietness -lt 1 ]] && mv $imgconvtmp $imgconv
		i=$(($i+1))
		[[ $quietness -lt 2 ]] && echo "Selected raw string: $rawstring"
		[[ $quietness -lt 2 ]] && echo "Skipping raw string."
		continue
	fi
	
	if [[ $nextblockjoin == 1 ]] && [[ $sourcelang == "ko" ]]
	then
		rawstring="$prevrawstring $rawstring"
		nextblockjoin=0
	fi
	
	if [[ $nextblockjoin == 1 ]] && ( [[ $sourcelang == "jp" ]] || [[ $sourcelang == "zh" ]] )
	then
		rawstring="$prevrawstring$rawstring"
		nextblockjoin=0
	fi

	diffy2bny1bn=$(( $y2bn - $y1bn ))
	diffy4bny3bn=$(( $y4bn - $y3bn ))

	if [[ $x1bn != "null" ]] && [[ $y1bn -gt $y3b ]] && [[ $y1bn -lt $(( $y3b + (($y3b - $y1b) / $breakcont) )) ]] && [[ ${diffy2bny1bn/#-/} -lt 5 ]] && [[ ${diffy4bny3bn/#-/} -lt 5 ]] && [[ $sourcelang != "ja" ]]
	then
		nextblockjoin=1
		prevrawstring="$rawstring"
		sleep 1
		[[ $quietness -lt 1 ]] && mv $imgconvtmp $imgconv
		i=$(($i+1))
		[[ $quietness -lt 2 ]] && echo "Selected raw string: $rawstring"
		[[ $quietness -lt 2 ]] && echo "Next block will be joined."
		continue
	fi

	[[ $quietness -lt 2 ]] && echo "Selected raw string: $rawstring"
	
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
		[[ $quietness -lt 1 ]] && mv $imgconvtmp $imgconv
		i=$(($i+1))
		continue
	fi
	
	# Translation Phase
	if [[ $transengine == "google" ]]
	then
	
		if [[ $mode == "typeset-from-file" ]] || [[ $mode == "interactive-typeset-from-file" ]]
		then
		
			[[ $quietness -lt 3 ]] && echo "Using user provided translated string."
			transstringcount=$(( $transstringcount + 1 ))
			transstring=$(cat $transfile | tail -n +$transstringcount | head -n +1)
			
			if [[ $transstring == "Ignore" ]] || [[ $transstring == "ignore" ]]
			then
				sleep 1
				[[ $quietness -lt 1 ]] && mv $imgconvtmp $imgconv
				i=$(($i+1))
				[[ $quietness -lt 2 ]] && echo "Ignoring as per user input."
				continue
			fi
			
		else
		
			echo -e "{\n \"q\": \"$rawstring\",\n \"source\": \"$sourcelang\",\n \"target\": \"$targetlang\",\n \"format\": \"text\"\n}" > transresquest.json
			[[ $quietness -lt 3 ]] && echo "Translating raw string... "
			transstring=$(curl -s -X POST -H "X-Goog-Api-Key: $gc_api_key" -H "Content-Type: application/json; charset=utf-8" -d @transresquest.json "https://translation.googleapis.com/language/translate/v2" | jq '.data.translations[].translatedText' | sed 's/\"//g' | sed 's/\\//g')
			echo "$transstring" >> autotranstext.txt
			
		fi
	fi
	
	if [[ $transengine == "deepl" ]]
	then
		if [[ $mode == "typeset-from-file" ]] || [[ $mode == "interactive-typeset-from-file" ]]
		then
		
			[[ $quietness -lt 3 ]] && echo "Using user provided translated string."
			transstringcount=$(( $transstringcount + 1 ))
			transstring=$(cat $transfile | tail -n +$transstringcount | head -n +1)
			
			if [[ $transstring == "Ignore" ]] || [[ $transstring == "ignore" ]]
			then
				sleep 1
				[[ $quietness -lt 1 ]] && mv $imgconvtmp $imgconv
				i=$(($i+1))
				[[ $quietness -lt 2 ]] && echo "Ignoring as per user input."
				continue
			fi
			
		else
		
			[[ $quietness -lt 3 ]] && echo "Translating raw string... "
			transstring=$(curl -s "https://api-free.deepl.com/v2/translate" -d "auth_key=$deepl_api_key" -d "text=$rawstring" -d "source_lang=$sourcelang" -d "target_lang=$targetlang" | jq '.translations[].text' | sed 's/\"//g' | sed 's/\\//g')
			echo "$transstring" >> autotranstext.txt
			
		fi
	fi
	
	[[ $quietness -lt 2 ]] && echo "Translated string: $transstring"
	
	if [[ $mode == "no-typeset" ]]
	then
		sleep 1
		[[ $quietness -lt 1 ]] && mv $imgconvtmp $imgconv
		i=$(($i+1))
		continue
	fi
	
	# Typeset Phase
	x1boffset=0
	x3boffset=5
	y1boffset=0
	y3boffset=5
	
	if [[ $advanced_typeset_box_calc == 1 ]]
	then
		
		x1boffset1="" 
		x1boffset3=""
		x3boffset1=""
		x3boffset3=""
		
		y1boffset1="" 
		y1boffset3="" 
		y3boffset1=""
		y3boffset3=""
		
		[[ $quietness -lt 3 ]] && echo "Calculating optimal offset values..."
		
		x1boffset1=$( find_box_border_coordinates $(( $x1b - 200 )) $y1b 10 $(( $x1b - 10 )) $y1b $(( $x1b - 10 )) $(( $y1b + 2 )) x 0 )
		x3boffset1=$( find_box_border_coordinates $(( $x3b + 5 )) $y1b 5 $(( $x3b + 10 )) $y1b $(( $x3b + 10 )) $(( $y1b + 2 )) x 1 )
		y1boffset1=$( find_box_border_coordinates $x1b $(( $y1b - 200 )) 20 $x1b $(( $y1b - 20 )) $(( $x1b + 2 )) $(( $y1b - 20 )) y 0 )
		y3boffset1=$( find_box_border_coordinates $x1b $(( $y3b + 5 )) 15 $x1b $(( $y3b + 20 )) $(( $x1b + 2 )) $(( $y3b + 20 )) y 1 )
		
		x1boffset3=$( find_box_border_coordinates $(( $x1b - 200 )) $y3b 10 $(( $x1b - 10 )) $y3b $(( $x1b - 10 )) $(( $y3b + 2 )) x 0 )
		x3boffset3=$( find_box_border_coordinates $(( $x3b + 5 )) $y3b 5 $(( $x3b + 10 )) $y3b $(( $x3b + 10 )) $(( $y3b + 2 )) x 1 )
		y1boffset3=$( find_box_border_coordinates $x3b $(( $y1b - 200 )) 20 $x3b $(( $y1b - 20 )) $(( $x3b + 2 )) $(( $y1b - 20 )) y 0 )
		y3boffset3=$( find_box_border_coordinates $x3b $(( $y3b + 5 )) 15 $x3b $(( $y3b + 20 )) $(( $x3b + 2 )) $(( $y3b + 20 )) y 1 )
		
		echo "Debug: $x1boffset1 $x1boffset3 | $x3boffset1 $x3boffset3 | $y1boffset1 $y1boffset3 | $y3boffset1 $y3boffset3"
		
		x1boffsettmp=$( box_border_coordinates_pick_min $x1boffset1 $x1boffset3 )
		[[ $x1boffsettmp != "" ]] && x1boffset=$x1boffsettmp
		x1boffsettmp=$( box_border_coordinates_pick_min $x1boffset3 $x1boffset1 )
		[[ $x1boffsettmp != "" ]] && x1boffset=$x1boffsettmp
		x3boffsettmp=$( box_border_coordinates_pick_min $x3boffset1 $x3boffset3 )
		[[ $x3boffsettmp != "" ]] && x3boffset=$x3boffsettmp
		x3boffsettmp=$( box_border_coordinates_pick_min $x3boffset3 $x3boffset1 )
		[[ $x3boffsettmp != "" ]] && x3boffset=$x3boffsettmp
		
		y1boffsettmp=$( box_border_coordinates_pick_min $y1boffset1 $y1boffset3 )
		[[ $y1boffsettmp != "" ]] && y1boffset=$y1boffsettmp
		y1boffsettmp=$( box_border_coordinates_pick_min $y1boffset3 $y1boffset1 )
		[[ $y1boffsettmp != "" ]] && y1boffset=$y1boffsettmp
		y3boffsettmp=$( box_border_coordinates_pick_min $y3boffset1 $y3boffset3 )
		[[ $y3boffsettmp != "" ]] && y3boffset=$y3boffsettmp
		y3boffsettmp=$( box_border_coordinates_pick_min $y3boffset3 $y3boffset1 )
		[[ $y3boffsettmp != "" ]] && y3boffset=$y3boffsettmp
		
		echo "Debug2: $x1boffset1 $x1boffset3 | $x3boffset1 $x3boffset3 | $y1boffset1 $y1boffset3 | $y3boffset1 $y3boffset3"
		
		[[ $quietness -lt 2 ]] && echo "Offset x1 (left) with value $x1boffset automatically acquired."
		[[ $quietness -lt 2 ]] && echo "Offset x3 (right) with value $x3boffset automatically acquired."
		
		[[ $quietness -lt 2 ]] && echo "Offset y1 (up) with value $y1boffset automatically acquired."
		[[ $quietness -lt 2 ]] && echo "Offset y3 (down) with value $y3boffset automatically acquired."
		
		if [[ $x1boffset -lt 10 ]] && [[ $x3boffset -lt 10 ]] && [[ $y3boffset -lt 10 ]] && [[ $y1boffset -gt 20 ]]
		then
			y1boffset="$y3boffset"
			[[ $quietness -lt 2 ]] && echo "Offset y1 (up) too large. Setting y1 to y3 value $y1boffset"
		fi
		
		if [[ $x1boffset -lt 10 ]] && [[ $x3boffset -lt 10 ]] && [[ $y1boffset -lt 10 ]] && [[ $y3boffset -gt 20 ]]
		then
			y3boffset="$y1boffset"
			[[ $quietness -lt 2 ]] && echo "Offset y3 (down) too large. Setting y3 to y1 value $y1boffset"
		fi
		
		diffy3boffy1boff=$(( $y3boffset - $y1boffset ))
		
		if [[ ${diffy3boffy1boff/#-/} -ge 25 ]]
		then
			if [[ $y3boffset -gt $y1boffset ]]
			then
				y3boffset="$y1boffset"
				[[ $quietness -lt 2 ]] && echo "Offset y3 (down) too large. Setting y3 to y1 value $y1boffset"
			else
				y1boffset="$y3boffset"
				[[ $quietness -lt 2 ]] && echo "Offset y1 (up) too large. Setting y1 to y3 value $y3boffset"
			fi
		fi
		
	fi
	
	fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font $font -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
	[[ $quietness -lt 2 ]] && echo "Font size $fontsize automatically selected as best fit."
	
	font_size_optimizer
	
	fontcolor="black"
	fontweight="normal"
	fontstyle="normal"
	fontstrokecolor="none"
	fontstrokewidth="0"
	
	while true
	do

		[[ $quietness -lt 2 ]] && echo "Selected translated string: $transstring"
	
		if [[ $mode == "interactive" ]] || [[ $mode == "interactive-typeset-from-file" ]]
		then
	
			read -e -p "Type edited translated string or press enter to typeset current translated string... " string
	
			if [[ "$string" != "" ]]
			then
			
				transstring="$string"
				
				fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font $font -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
				echo "Font size $fontsize automatically selected as best fit."
				
				font_size_optimizer
				
			fi
			
		fi
		
		sleep 1
		clsfillcolor=$("$IMAGEMAGICKDIR"/convert.exe $img -gravity northwest -crop 1x1+$(( ($x3b + $x1b) / 2 ))+$(($y1b - 5)) txt:- | awk -F " " '{print $3}' | tail -n +2)
		
		if [[ $optimize == "manga" ]]
		then
		
			sleep 1
			[[ $quietness -gt 0 ]] && "$IMAGEMAGICKDIR"/convert.exe $imgconv -fill "$clsfillcolor" -stroke none -draw "rectangle $(($x1b - 5)),$(($y1b - 5)) $(($x3b + 5)),$(($y3b + 5))" $imgconv
			[[ $quietness -lt 1 ]] && "$IMAGEMAGICKDIR"/convert.exe $imgconvtmp -fill "$clsfillcolor" -stroke none -draw "rectangle $(($x1b - 5)),$(($y1b - 5)) $(($x3b + 5)),$(($y3b + 5))" $imgconv
			
			sleep 1
			"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill "$clsfillcolor" -stroke none -draw "arc $(($x1b - 5 - $x1boffset)),$(($y1b - 5 - $y1boffset)) $(($x3b + 5 + $x3boffset)),$(($y3b + 5 + $y3boffset)) 0,360" $imgconv

		fi
		
		if [[ $optimize == "webtoon" ]] || [[ $optimize == "none" ]]
		then

			sleep 1
			[[ $quietness -gt 0 ]] && "$IMAGEMAGICKDIR"/convert.exe $imgconv -fill "$clsfillcolor" -stroke none -draw "rectangle $(($x1b - 5)),$(($y1b - 5)) $(($x3b + 5)),$(($y3b + 5))" $imgconv
			[[ $quietness -lt 1 ]] && "$IMAGEMAGICKDIR"/convert.exe $imgconvtmp -fill "$clsfillcolor" -stroke none -draw "rectangle $(($x1b - 5)),$(($y1b - 5)) $(($x3b + 5)),$(($y3b + 5))" $imgconv

		fi	
		
		sleep 1
		"$IMAGEMAGICKDIR"/convert.exe $imgconv \( -font $font -pointsize $fontsize -fill $fontcolor -weight $fontweight -style $fontstyle -stroke $fontstrokecolor -strokewidth $fontstrokewidth -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) -gravity center -background none caption:"$transstring" \) -gravity northwest -geometry +$(($x1b - $x1boffset))+$(($y1b - $y1boffset)) -composite $imgconv

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
				
					echo "Invalid option."
					continue
				
				else
					
					sleep 1
					cp $imgconv $imgconvtmp2
					
					sleep 1
					"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill "rgba(228,237,47,0.5)" -stroke none -draw "rectangle $(($x1b - 5 - $x1boffset)),$(($y1b - 5 - $y1boffset)) $(($x3b + 5 + $x3boffset)),$(($y3b + 5 + $y3boffset))" $imgconv
				
					sleep 1
					"$IMAGEMAGICKDIR"/convert.exe $imgconv \( ruler.png -alpha set -channel A -evaluate set 50% \) -set colorspace sRGB -gravity northwest -geometry +$(($x1b - 106 - $x1boffset))+$(($y1b - 10 - $y1boffset)) -composite $imgconv
			
					sleep 1
					"$IMAGEMAGICKDIR"/convert.exe $imgconv \( ruler.png -alpha set -channel A -evaluate set 50% -rotate -90 \) -set colorspace sRGB -gravity northwest -geometry +$(($x1b - 10 - $x1boffset))+$(($y1b - 106 - $y1boffset)) -composite $imgconv
				
					echo "Welcome to basic typeset tweaker. "
					echo
					echo "1) Change offset values."
					echo "2) Change font type."
					echo "3) Change font size."
					echo "4) Change font color."
					echo "5) Change font style."
					echo "6) Change font weight."
					echo "7) Change font stroke color."
					echo "8) Change font stroke width."
					echo "9) Exit."
					echo
					
					while true
					do
					
						echo "Current Values -> Offset: ($x1boffset,$x3boffset,$y1boffset,$y3boffset) | Font: $font | Font Size: $fontsize | Font Color: $fontcolor | Font Weight: $fontweight | Font Style: $fontstyle | Font Stroke Color: $fontstrokecolor | Font Stroke Width: $fontstrokewidth"
						
						read -e -p "Type the number corresponding to one of the preceding options... " string
						
						case "$string" in
						
							1)
							
								read -e -p "Type new x1 (left), x3 (right), y1 (up) and y3 (down) offsets ($x1boffset,$x3boffset,$y1boffset,$y3boffset) or press enter to continue... " string
				
								if [[ $string != "" ]]
								then
						
									stringx1=$(echo $string | cut -d "," -f1)
									stringx3=$(echo $string | cut -d "," -f2)
									stringy1=$(echo $string | cut -d "," -f3)
									stringy3=$(echo $string | cut -d "," -f4)								
							
									if [[ "$stringx1" =~ ^-?[0-9]+$ ]] && [[ "$stringx3" =~ ^-?[0-9]+$ ]] && [[ "$stringy1" =~ ^-?[0-9]+$ ]] && [[ "$stringy3" =~ ^-?[0-9]+$ ]] 
									then
										
										sleep 1
										cp $imgconv $imgconvtmp3
										
										sleep 1
										"$IMAGEMAGICKDIR"/convert.exe $imgconv -fill "rgba(23,235,108,0.5)" -stroke none -draw "rectangle $(($x1b - 5 - $stringx1)),$(($y1b - 5 - $stringy1)) $(($x3b + 5 + $stringx3)),$(($y3b + 5 + $stringy3))" $imgconv		
								
										while true
										do
								
											read -e -p "Do you wish to save your inputed offset values (y/n)? " string
					
											if [[ $string == Y ]] || [[ $string == y ]] || [[ $string == Yes ]] || [[ $string == yes ]]
											then
												
												x1boffset="$stringx1"
												x3boffset="$stringx3"
												y1boffset="$stringy1"
												y3boffset="$stringy3"
												fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font $font -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
												echo "Font size $fontsize automatically selected as best fit."
												sleep 1
												mv $imgconvtmp3 $imgconv
												continue 2
							
											elif [[ $string != N ]] && [[ $string != n ]] && [[ $string != No ]] && [[ $string != no ]]
											then
											
												echo "Invalid option."
												continue
							
											else
											
												sleep 1
												mv $imgconvtmp3 $imgconv
												continue 2
									
											fi
											
										done
									
									else
								
										echo "Typed input is not number seperated list."
										continue
									
									fi
									
								else
								
									continue
							
								fi
							
							;;
							
							2)
							
								read -e -p "Type new font type ($font) or press enter to continue... " string

								if [[ $string != "" ]]
								then

									"$IMAGEMAGICKDIR"/convert.exe -list font | grep "Font:" | cut -d " " -f4 | grep -w "$string" &>> /dev/null
									if [[ $? != 0 ]]
									then
										echo "Font $string does not exist."
										continue
									else
										font="$string"
										fontsize=$("$IMAGEMAGICKDIR"/convert.exe -font $font -fill black -size $(( ($x3b + $x3boffset) - ($x1b - $x1boffset) ))x$(( ($y3b + $y3boffset) - ($y1b - $y1boffset) )) caption:"$transstring" -format "%[caption:pointsize]" info:)
										echo "Font size $fontsize automatically selected as best fit."
										continue
									fi
					
								fi
							
							;;
							
							3)
							
								read -e -p "Type new font size ($fontsize) or press enter to continue... " string
				
								if [[ $string != "" ]]
								then

									if [[ "$string" =~ ^[0-9]+$ ]]
									then
										[[ $string -gt $fontsize ]] && echo "Typed input is greater than recommended best fit. Clipping is likely to occur."
										fontsize="$string"
										continue
									else
										echo "Typed input is not a whole number."
										continue
									fi
									
								fi
							
							;;
							
							4) 
							
								echo "Typical colors: white black red orange yellow green cyan blue purple"
								
								read -e -p "Type new font color ($fontcolor) or press enter to continue... " string
				
								if [[ $string != "" ]]
								then

									fontcolor="$string"
									
								fi
								
							;;
							
							5) 
							
								echo "Available styles: normal italic oblique"
								
								read -e -p "Type new font style ($fontstyle) or press enter to continue... " string
				
								if [[ $string != "" ]]
								then

									if [[ "$string" == "normal" ]] || [[ "$string" == "italic" ]] || [[ "$string" == "oblique" ]] 
									then
										fontstyle="$string"
										continue
									else
										echo "Invalid style."
										continue
									fi
									
								fi
								
							;;
							
							6)
							
								echo "Available weights: thin extralight light normal medium demibold bold extrabold heavy"
								
								read -e -p "Type new font weight ($fontweight) or press enter to continue... " string
				
								if [[ $string != "" ]]
								then

									if [[ "$string" == "thin" ]] || [[ "$string" == "extralight" ]] || [[ "$string" == "light" ]] || [[ "$string" == "normal" ]] || [[ "$string" == "medium" ]] || [[ "$string" == "demibold" ]] || [[ "$string" == "bold" ]] || [[ "$string" == "extrabold" ]] || [[ "$string" == "heavy" ]]
									then
										fontweight="$string"
										continue
									else
										echo "Invalid weight."
										continue
									fi
									
								fi
							
							;;
							
							7) 
							
								echo "Typical colors: white black red orange yellow green cyan blue purple"
								
								read -e -p "Type new font stroke color ($fontstrokecolor) or press enter to continue... " string
				
								if [[ $string != "" ]]
								then

									fontstrokecolor="$string"
									
								fi
								
							;;

							8)
							
								read -e -p "Type new font stroke width ($fontstrokewidth) or press enter to continue... " string
				
								if [[ $string != "" ]]
								then

									if [[ "$string" =~ ^[0-9]+$ ]]
									then
										fontstrokewidth="$string"
										continue
									else
										echo "Typed input is not a whole number."
										continue
									fi
									
								fi
							
							;;
							
							9)
							
								sleep 1
								mv $imgconvtmp2 $imgconv
								break 2
								
							;;
							
							*)
							
								echo "Invalid option."
								continue
							
							;;
						
						esac
						
					done
				
				fi
			
			done
			
		else
		
			break
			
		fi
		
	done
	
	sleep 1
	[[ $quietness -lt 1 ]] && rm $imgconvtmp
	
	i=$(($i+1))
	
done

sleep 1
[[ $quietness -lt 1 ]] && "$CMDDIR"/cmd.exe /c start taskkill /IM JPEGView.exe

done

echo "All images have been successfully processed."

[[ $quietness -lt 3 ]] && read -p "Place the all the images on the folder and then press any key or press enter to exit... " string2

if [[ $string2 != "" ]]
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
	
	if [[ -f "$FIREFOXDIR"/firefox.exe ]]
	then
	
		"$FIREFOXDIR"/firefox.exe file:///"$curdir"/read.html
		
	elif [[ -f "$CHROMEDIR"/chrome.exe ]]
	then
	
		"$CHROMEDIR"/chrome.exe file:///"$curdir"/read.html
		
	else
	
		echo "Could not find Firefox or Chrome browser."
		
	fi
	
fi

exit 0
