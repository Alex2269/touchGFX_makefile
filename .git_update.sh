#!/bin/sh

   # create:
   #******************************************
   echo "# touchGFX_makefile" >> README.md
   git init
   git add .
   git commit -m "$(date "+%Y-%m-%d")"
   git branch -M main
   git remote add origin git@github.com:Alex2269/touchGFX_makefile.git
   git push -u origin main
   git pull
   #******************************************

   # update:
   #******************************************
   git status
   git add .
   git commit -m "$(date "+%Y-%m-%d")"
   git push -u origin main
   git pull
   #******************************************

