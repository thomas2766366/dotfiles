#!/bin/bash
picdir=~/backgrounds
user=$(id -un)
uid=$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus
gnome_shell=$(ps --user=$user | grep gnome-shell$)
if [ ! -z "$gnome_shell" ]; then
  curpic=$(ls $picdir | grep -E -i "(jpg)$" | shuf -n 1)
  cp $picdir/$curpic $picdir/current.jpg
  gsettings set org.gnome.desktop.background picture-uri $picdir/$curpic
  gsettings set org.gnome.desktop.background picture-uri-dark $picdir/$curpic
fi
