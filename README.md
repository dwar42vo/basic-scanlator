# Introduction

This repo is currently under construction...

A basic bash script that extracts raw text (OCR) using Google Vision Api from a list of images, translates the extracted raw text using Google Translate Api or Deepl Translate Api and typesets the translated text onto the images. This script is very much a WIP. Unintended results are to be expected.

This script is meant to be run on Windows 10's WSL 1 with Ubuntu 18.04 or 20.04 (will probably also work on WSL 2) installed or on the latest MobaXterm. It can also be run on Linux distros with a some minor code changes. The api keys are not provided. You must obtain them yourself by creating a free google cloud and deepl accounts.

# Prerequites

## Operating System

WSL with Ubuntu 18.04 or 20.04 installed or MobaXterm (https://mobaxterm.mobatek.net/download-home-edition.html) [e.g. MobaXterm_Installer_v22.1.zip]

Image Magick v7+ (https://imagemagick.org/script/download.php) [e.g. ImageMagick-7.1.0-portable-Q16-x64.zip]

JPEGView (https://sourceforge.net/projects/jpegview/files/latest/download) [e.g. JPEGView_1.0.37.zip]

These should be installed on C:\Program Files

## Command Line

grep v3+, curl and jq. These can be installed with the following commands on debian based distros.

```
apt-get update && apt-get upgrade (don't run if you're using the built-in MobaXterm Cygwin)
apt-get install coreutils grep curl jq
```

Also, make sure you have bash v4+ installed.

```
bash -version
```

## Script

Add your google and your deepl api keys to following variables at top of the script.

>gc_api_key="..."
>
>deepl_api_key="..."
