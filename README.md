# Introduction

This repo is currently under construction...

A basic bash script that extracts raw text using Google Vision Api from a list of manga or webtoon jpg images, translates the extracted raw text using Google Translate Api or Deepl Translate Api and typesets the translated text onto the images. 

This script is meant to be run on Windows 10's WSL 1 with Ubuntu 18.04 or 20.04 (will probably also work on WSL 2) installed, the latest Cygwin or on the latest MobaXterm. It can also be run on Linux distros with a few minor code changes. The API keys are not provided; you must obtain them yourself by creating a free google cloud and deepl accounts.

This script only supports Japanese, Chinese and Korean as source languages. This script is very much a WIP. Unintended results are to be expected.

# Prerequites

## Operating System

WSL with Ubuntu 18.04 or 20.04 installed, Cywin (https://www.cygwin.com/) [setup-x86_64.exe] or MobaXterm (https://mobaxterm.mobatek.net/download-home-edition.html) [e.g. MobaXterm_Installer_v22.1.zip]

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

# Usage

The script takes 4 arguments, which are "Source Language", "Target Language", "Translation Engine" and "Mode". Mode is opcional. 

The valid values for each of these are:

1. Source Language: jp (Japanese), zh (Simplified Chinese) and ko (Korean)
    
2. Target Language: en (English) and any ohter language supported by each of the Translation Engines
    
3. Translation Engine: google and deepl
    
4. Mode: interactive (default), automatic, ocr-only, typeset-from-file and interactive-typeset-from-file
    
   - a) Interactive: Requests user input for a number of thing, namely changing either the extracted raw text or the translated text before typesetting, setting new offset for text boxes and font sizes. 
        
    b) Automatic: Runs without any user input. Extracts raw text, translates and typeset results.
        
    c) OCR Only: Only extracts raw text to a file named rawtext.txt.
        
    d) Typeset from File: Uses a text file named transtext.txt as the translated text.
        
    e) Interactive Typeset from File: A combination of a) and d).
