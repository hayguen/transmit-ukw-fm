#!/bin/bash

BASEDIR=$(pwd)

OPT_CARRIERS="car"
if [ "$1" = "${OPT_CARRIERS}" ]; then
  echo "setup is installing the dependencies for transmit_carriers.sh only - without ukw/mpxgen"
else
  echo "setup is installing all dependencies, required for ukw/mpxgen"
fi

echo "continuing in 3 seconds .. press Ctrl+C to abort .."
sleep 3

# development stuff
sudo apt-get install git build-essential

# wget
sudo apt-get install wget

if [ ! "$1" = "${OPT_CARRIERS}" ]; then
  # arecord
  sudo apt-get install alsa-utils

  # mpxgen
  sudo apt-get install libsndfile1-dev libao-dev libsamplerate0-dev
  git clone https://github.com/Anthony96922/mpxgen
  cd mpxgen/src
  make
  sudo install -m 0755 mpxgen /usr/local/bin/
fi
cd "${BASEDIR}"

# csdr
sudo apt-get install libfftw3-dev
#git clone https://github.com/ha7ilm/csdr
git clone https://github.com/hayguen/csdr.git
cd csdr
make
sudo make install
cd "${BASEDIR}"

# libiio-utils (iio_attr und iio_writedev)
# https://github.com/analogdevicesinc/libiio
sudo apt-get install libiio-utils
# from https://github.com/analogdevicesinc/iio-oscilloscope/tree/master/filters
wget https://raw.githubusercontent.com/analogdevicesinc/iio-oscilloscope/master/filters/AD936x_LP_180kHz_521kSPS.ftr
