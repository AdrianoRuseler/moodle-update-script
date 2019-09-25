#!/bin/bash

sudo apt-get update && sudo apt-get upgrade -y

sudo apt-get autoremove -y && sudo apt-get autoclean -y

echo "Instal some sys utils..."
sudo apt-get install -y git gcc

echo "To use spell-checking within the editor, you MUST have aspell 0.50 or later installed on your server..."
sudo apt-get install -y aspell dictionaries-common libaspell15 aspell-de aspell-es aspell-fr aspell-en aspell-pt-br aspell-pt-pt aspell-doc spellutils

