#!/bin/bash

set -e

path=./mockup.aseprite
target=aseprite.fnl

rm -f $target 

echo "Beginning Export"
echo "; autogenerated by ./scripts/aseprite-export.sh" >> $target 
echo "{" >> $target 

for layer in $(aseprite -b --list-layers $path); do
  echo $layer
  aseprite -b --layer $layer $path --trim --save-as "./assets/export-{layer}.png"
  echo ":$layer (let [img (love.graphics.newImage \"assets/export-$layer.png\")] (img:setFilter :nearest :nearest) {: img :width (img:getWidth) :height (img:getHeight)}) " >> $target
done

echo "}" >> $target

