#!/bin/bash

echo "Update and Upgrade System..."
sudo apt-get update && sudo apt-get upgrade -y

echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y

echo "Install some sys utils..."
sudo apt-get install -y git gcc

echo "Install python..."
sudo apt-get install -y python2 python3

echo "To use spell-checking within the editor, you MUST have aspell 0.50 or later installed on your server..."
sudo apt-get install -y aspell dictionaries-common libaspell15 aspell-de aspell-es aspell-fr aspell-en aspell-pt-br aspell-pt-pt aspell-doc spellutils

