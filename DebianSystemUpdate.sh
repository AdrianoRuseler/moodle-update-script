#!/bin/bash

echo "Update and Upgrade System..."
sudo apt-get update && sudo apt-get upgrade -y

echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y

echo "Install some sys utils..."
sudo apt-get install -y git

echo "Install python..."
sudo apt-get install -y python2 python3

echo "Install maxima (Stack question type for Moodle) ..."
sudo apt-get install -y maxima

echo "To be able to generate graphics from DOT files, you must have installed the dot executable..."
sudo apt-get install -y graphviz

echo "To use spell-checking within the editor, you MUST have aspell 0.50 or later installed on your server..."
sudo apt-get install -y aspell dictionaries-common libaspell15 aspell-de aspell-es aspell-fr aspell-en aspell-pt-br aspell-pt-pt aspell-doc spellutils

