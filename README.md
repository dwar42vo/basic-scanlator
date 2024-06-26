# Introduction

A basic bash script that extracts raw text using Google Vision API from a list of manga or webtoon images, translates the extracted raw text using Google Translate API or Deepl Translate API and typesets the result onto the images. 

This script is meant to be run on Windows 10's WSL 1 with Ubuntu 18.04 or 20.04 (also works on WSL 2) installed, the latest Cygwin or on the latest MobaXterm. It can also be run on Linux distros with a few minor code changes. The API keys are not provided; you must obtain them yourself by creating free Google Cloud and Deepl accounts.

This script only supports Japanese, Chinese and Korean as source languages. The default font used by this script is Arial, but you can change it to any font you have installed on your system. 

Lastly, this script is a WIP. Unintended results are to be expected.

# Prerequisites

## Operating System

WSL with Ubuntu 18.04 or 20.04 installed, [Cywin](https://www.cygwin.com/) [setup-x86_64.exe] or [MobaXterm](https://mobaxterm.mobatek.net/download-home-edition.html) [MobaXterm_Installer_v22.1.zip]

[CC Wild Words](https://freefontsfamily.com/cc-wild-words-roman-font-free/) [CC Wild Words Roman.ttf]

[ImageMagick v7+](https://imagemagick.org/script/download.php) [ImageMagick-7.1.0-portable-Q16-x64.zip]

[JPEGView](https://sourceforge.net/projects/jpegview/files/latest/download) [JPEGView_1.0.37.zip]

These last two should be installed on C:\Program Files. JPEGView is optional if quietness is set to a value between 1 and 3.

## Command Line

grep v3+, curl and jq can be installed with the following commands on Debian based distros:

```
apt-get update && apt-get upgrade (don't run this if you're using the built-in MobaXterm Cygwin)
apt-get install coreutils grep curl jq
```

Also, make sure you have bash v4+ installed.

```
bash -version
```

## API

### Google Cloud

Register [here](https://console.cloud.google.com/freetrial).

Once you have done so:

1. Go to APIs & Services -> Enabled APIs & Services and click on Enable APIs & Services. 

2. Search for Cloud Vision API and Cloud Translation API and click on the Enable button.

3. Go to APIs & Services -> Credentials and click Create Credentials -> API Key.

4. (Optional) Under the API Keys tab, click on the new generated key to edit it. 

    - Set Application restrictions to IP addresses and add your public IP.
    
    - Set API restrictions to Restricted and select Cloud Vision API and Cloud Translation API.
    
5) Finally, copy & paste your API key to the script.


Pricing:

According to the documentation, the first 1 000 requests per month to the [Google Cloud Vision API](https://cloud.google.com/vision/pricing), and the first 500 000 characters per month to the [Google Cloud Translate API](https://cloud.google.com/translate/pricing) are free.

### Deepl 

Register [here](https://www.deepl.com/pro-checkout/account?productId=1200&yearly=false&trial=false).

Once you have done so:

1. Go to Account -> Account and under Authentication Key for DeepL API, copy & paste your API key to the script.


Pricing:

Unlike Google Cloud, you don't have to worry about credit card charges.

## Script

Add your google and your deepl api keys to the gc_api_key and deepl_api_key variables at top of the script. 

>gc_api_key="" --> gc_api_key="a4db08b7-5729-4ba9-8c08-f2df493465a1"
>
>deepl_api_key="" --> deepl_api_key="279a2e9d-83b3-c416-7e2d-f721593e42a0:fx"

# Components

>basic_scanlator.sh

>ruler.png: A 500px ruler. The distance represented by each tick mark, from longest to shortest, is 50px, 10px and 5px.

# Features

The script takes a number of arguments, 3 of which are required. These are "Source Language", "Target Language" and "Translation Engine". Other arguments, such as "Mode", "Font", "Input-Image-Format", "Optimizations", "Translation File" and "Generate Read File" are optional. There are also three other special arguments, "Quietness" (-q|-qq|-qqq), "Advance Typeset Mode" (-a) and "Debug" (-d). Quietness is a value from 0 (default) to 3. The higher the value, the more output will be supressed. Advance Typeset Mode tries to find the edges of text bubbles and sets the offsets accordingly.

The valid values for each of these are:

1. Source Language: jp (Japanese), zh (Simplified Chinese) and ko (Korean)
    
2. Target Language: en (English) and any other language supported by each of the Translation Engines. Read their respective documentations [here](https://cloud.google.com/translate/docs/languages) and [here](https://www.deepl.com/docs-api/translating-text/) to find out which are currently supported. 
    
3. Translation Engine: google and deepl
    
4. Mode: automatic (default), interactive, ocr-only, no-typeset, typeset-from-file, interactive-typeset-from-file and typeset-from-all

5. Optimizations: webtoon (default) and manga

6. Image Format: jpg (default), png and webp

    - Automatic: Runs without any user input. Extracts raw text, translates and typesets results.
   
    - Interactive: Requests user input for a number of things, namely changing either the extracted raw text or the translated text before typesetting, setting new offset values for text boxes and font sizes. 
        
    - OCR Only: Only extracts raw text to a file named rawtext.txt.
    
    - No Typeset: Extracts raw text to a file named rawtext.txt and translation to a file named autotranstext.txt
        
    - Typeset from File: Uses a text file named transtext.txt for the translated text. The translated strings on the file should follow the order by which Google Vision API extracts text and not the order of the various text bubbles.
    
    - Typeset from All: Uses a text file named all.txt for the translated text, bounding box coordinates and offsets, font name, font size, font color and text bubble clean color.
        
    - Interactive Typeset from File: A combination of "Interactive" and "Typeset from file".

# Usage

First off, place the script on the same folder as the manga or webtoon images you wish to process, and then run the script with the intended arguments.

The full list of arguments is as follows:

```
./basic_scanlator.sh [ -s source_language ] [ -t target_language ] [ -e translation_engine ] ( -m mode ) ( -i image_format ) ( -r transfile ) ( -o manga|webtoon ) ( -f font ) ( --fmin size ) ( --fmax size ) ( --fcolor color ) ( -c color ) (-w posx,posy) (--w1p tl|tr|bl|br) (-ww posx2,posy2) (--w2p tl|tr|bl|br) (-cc) (-a) (-g) (-q|-qq|-qqq) (-d)
```

To get the full list of fonts installed on your system:
```
./basic_scanlator.sh -l
```

To get the help message:
```
./basic_scanlator.sh -h
```

## Examples 

If you wish to translate a Japanese manga to English interactively, run:

```
./basic_scanlator.sh -s jp -t en -e deepl -m interactive
```


https://user-images.githubusercontent.com/110120271/181649471-15220046-9bfa-4c02-aa83-957bfe0fb84c.mp4


If you wish to translate a Korean webtoon to English with your own translation, create a file named transtext.txt, place it on the same folder as the script and the images you wish to process and add in your translated text. 

This file cannot contain any carriage return characters. You can use Notepad++ to convert the end of lines to Unix format if needed (Edit -> EOL Converversion -> Unix). 

If you type the word "Ignore" on the transtext.txt file, the text block the script is currently on will be skipped; this is useful to avoid SFX and watermarks.

```
./basic_scanlator.sh -s ko -t en -e google -m typeset-from-file
```


https://user-images.githubusercontent.com/110120271/181768039-b538a0cc-c13f-4564-a324-ab3dc635ddc3.mp4

### Other Examples

```
./basic_scanlator.sh -s ko -t en -e google -m automatic -a -q -w 190 1340 --w1p bl -d
```

Explanation: Translate from Korean to English with Google Translate automatically. Use font Arial (default). Font color black (default). Clean text bubbles with color white (-c) (default). Enable webtoon optimatizations (default) (-o). Find text bubble border edges before typeseting (-a). Don't open images on GUI (-q). Conceal watermark on bottom left (--w1p bl) edge of the images with top right box coordinate at x=190 y=1340 (-w 190 1340). Show debug messages (-d).

```
./basic_scanlator.sh -s zh -t en -e deepl -m typeset-from-file -f CC-Wild-Words-Roman --fmin 12 --fmax 22 --font-color Red -cc -o manga -a -q -w 190 1340 --w1p bl -g 
```

Explanation: Translate from Chinese to English with Deepl Translate. Use translated strings from transtext.txt. Use font CC-Wild-Words-Roman. Min font size 12. Max font size 22. Font color red. Clean text bubbles with the color of the text bubbles (-cc). Enable manga optimatizations (-o). Find text bubble border edges before typeseting (-a). Don't open images on GUI (-q). Conceal watermark on bottom left (--w1p bl) edge of the images before OCR with top right box coordinate at x=190 y=1340 (-w 190 1340). Generate a .html page of the processed images (-g).

```
./basic_scanlator.sh -s zh -t en -e deepl -m typeset-from-all -qqq -o manga
```
Explanation: Use translated strings, font and clean text bubbles color from all.txt. Enable manga optimatizations (-o). No output, except errors (-qqq).

