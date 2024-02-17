#!/bin/bash
# clone repo
git clone https://github.com/kubernetes-sigs/kubespray

# create python venv required python3-venv package (sudo apt install python3-venv)
VENVDIR=venv
KUBESPRAYDIR=kubespray
cd $KUBESPRAYDIR
python3 -m venv $VENVDIR
source $VENVDIR/bin/activate
pip install -U -r requirements.txt
