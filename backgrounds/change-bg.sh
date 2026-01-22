#!/bin/bash
picdir=~/backgrounds

curpic=$(ls $picdir | grep ".jpg" | grep -E -v "current" | shuf -n 1)
cp $picdir/$curpic $picdir/current.jpg
swaybg -i $picdir/current.jpg -m fill
