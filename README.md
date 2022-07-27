# Introduction

This repo is currently under construction...

A basic bash script that extracts raw text using Google Vision Api from a list of manga or webtoon jpg images, translates the extracted raw text using Google Translate Api or Deepl Translate Api and typesets the result onto the images. 

This script is meant to be run on Windows 10's WSL 1 with Ubuntu 18.04 or 20.04 (will probably also work on WSL 2) installed, the latest Cygwin or on the latest MobaXterm. It can also be run on Linux distros with a few minor code changes. The API keys are not provided; you must obtain them yourself by creating a free google cloud and deepl accounts.

This script only supports Japanese, Chinese and Korean as source languages. The font used by this script is CC Wild Words Roman, but you can change it to any font you have installed on your system. 

Lastly, this script is very much a WIP. Unintended results are to be expected.

# Prerequites

## Operating System

WSL with Ubuntu 18.04 or 20.04 installed, Cywin (https://www.cygwin.com/) [setup-x86_64.exe] or MobaXterm (https://mobaxterm.mobatek.net/download-home-edition.html) [e.g. MobaXterm_Installer_v22.1.zip]

CC Wild Words (https://freefontsfamily.com/cc-wild-words-roman-font-free/) [CC Wild Words Roman.ttf]

Image Magick v7+ (https://imagemagick.org/script/download.php) [e.g. ImageMagick-7.1.0-portable-Q16-x64.zip]

JPEGView (https://sourceforge.net/projects/jpegview/files/latest/download) [e.g. JPEGView_1.0.37.zip]

These last two should be installed on C:\Program Files

## Command Line

grep v3+, curl and jq can be installed with the following commands on Debian based distros:

```
apt-get update && apt-get upgrade (don't run if you're using the built-in MobaXterm Cygwin)
apt-get install coreutils grep curl jq
```

Also, make sure you have bash v4+ installed.

```
bash -version
```

## Script

Add your google and your deepl api keys to the gc_api_key and deepl_api_key variables at top of the script. 

>gc_api_key="your-google-api-key"
>
>deepl_api_key="your-deepl-api-key"

# Features

The script takes 4 arguments, which are "Source Language", "Target Language", "Translation Engine" and "Mode". Mode is opcional. 

The valid values for each of these are:

1. Source Language: jp (Japanese), zh (Simplified Chinese) and ko (Korean)
    
2. Target Language: en (English) and any ohter language supported by each of the Translation Engines
    
3. Translation Engine: google and deepl
    
4. Mode: interactive (default), automatic, ocr-only, typeset-from-file and interactive-typeset-from-file
    
    - Interactive: Requests user input for a number of thing, namely changing either the extracted raw text or the translated text before typesetting, setting new offset values for text boxes and font sizes. 
        
    - Automatic: Runs without any user input. Extracts raw text, translates and typeset results.
        
    - OCR Only: Only extracts raw text to a file named rawtext.txt.
        
    - Typeset from File: Uses a text file named transtext.txt as the translated text. The translated strings on the file should follow the order by which Google Vision Api extracts text and not the order of the various text bubbles.
        
    - Interactive Typeset from File: A combination of Interactive and Typeset from File.


# Usage

First, place the script on the same folder as the manga or webtoon jpg images you wish to process. Then run the script with the intended arguments. 

For example, if you wish to translate a Korean webtoon interatively:

```
./basic_scanlator.sh ko en google
```
