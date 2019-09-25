#!/bin/bash

echo "Update and Upgrade System..."
sudo apt-get update && sudo apt-get upgrade -y

echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y

echo "Add locales pt_BR, en_US, es_ES, de_DE, fr_FR, pt_PT..."
sudo sed -i '/^#.* pt_BR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_US.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* es_ES.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* de_DE.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* fr_FR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* pt_PT.* /s/^#//' /etc/locale.gen
sudo locale-gen

echo "Install some sys utils..."
sudo apt-get install -y git

echo "Install python..."
sudo apt-get install -y python2 python3

echo "To be able to generate graphics from DOT files, you must have installed the dot executable..."
sudo apt-get install -y graphviz

echo "To use spell-checking within the editor, you MUST have aspell 0.50 or later installed on your server..."
sudo apt-get install -y aspell dictionaries-common libaspell15 aspell-de aspell-es aspell-fr aspell-en aspell-pt-br aspell-pt-pt aspell-doc spellutils

echo "Install maxima, gcc and gnuplot (Stack question type for Moodle) ..."
sudo apt-get install -y maxima gcc gnuplot
