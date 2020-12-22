#!/usr/bin/bash

# run this script to initialize environment and install dependencies
# change python3.7 to the version of python in the host system
# NOTE: python version is greater than or equal to 3.6

rm -rf venv
mkdir venv
python3.7 -m venv venv
source ./venv/bin/activate
pip install -r  requirements.txt --upgrade
echo 'export PYTHONPATH="${PYTHONPATH}:'${PWD}'"'  >> ./venv/bin/activate