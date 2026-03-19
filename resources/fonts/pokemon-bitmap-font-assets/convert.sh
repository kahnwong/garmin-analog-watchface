#!/bin/bash

magick 0-og.png -colorspace gray -negate -resize 30x30 0.png
magick 1-og.png -colorspace gray -negate -resize 30x30 1.png
magick 2-og.png -colorspace gray -negate -resize 30x30 2.png
