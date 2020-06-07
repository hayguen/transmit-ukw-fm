#!/bin/bash

BASEDIR=$(pwd)

# development stuff
sudo apt-get install git build-essential

# wget
sudo apt-get install wget

# arecord
sudo apt-get install alsa-utils

# mpxgen
sudo apt-get install libsndfile1-dev libao-dev libsamplerate0-dev
git clone https://github.com/Anthony96922/mpxgen
cd mpxgen/src
make
sudo install -m 0755 mpxgen /usr/local/bin/
cd "${BASEDIR}"

# csdr
sudo apt-get install libfftw3-dev
git clone https://github.com/ha7ilm/csdr
cd csdr
make
sudo make install
cd "${BASEDIR}"

# libiio-utils (iio_attr und iio_writedev)
# https://github.com/analogdevicesinc/libiio
sudo apt-get install libiio-utils
# from https://github.com/analogdevicesinc/iio-oscilloscope/tree/master/filters
wget https://raw.githubusercontent.com/analogdevicesinc/iio-oscilloscope/master/filters/AD936x_LP_180kHz_521kSPS.ftr
