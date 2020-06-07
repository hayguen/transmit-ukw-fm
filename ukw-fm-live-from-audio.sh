#!/bin/bash

# prerequisites and dependencies:
#   wget, arecord (alsa-utils), mpxgen, csdr und libiio-utils
#   run './setup.sh' once


# insert/replace with IP address of Adalm Pluto
IP="192.168.2.1"

# set transmit frequency in Hz
FREQ="104300000"

# RF attenuation? 0 is none
TXGAIN="0"

# RF Bandfilter - upsampling filter already filters to 180 kHz
RFBW="300000"

# do not change following settings
# Samplerate, Buffer und Upsampling Filter
FS="768000"
BUFSIZ=$[ $FS / 20 ]
FILT=$(cat AD936x_LP_180kHz_521kSPS.ftr)
FILT_EN="1"

echo -e "\nsetting filter_fir_en of ad9361-phy .."
iio_attr -u ip:$IP -d ad9361-phy filter_fir_config "$FILT"
iio_attr -u ip:$IP -c ad9361-phy voltage0 filter_fir_en 1
iio_attr -u ip:$IP -c ad9361-phy voltage2 filter_fir_en 1
iio_attr -u ip:$IP -c ad9361-phy voltage3 filter_fir_en 1

echo -e "\nsetting sampling_frequency of ad9361-phy .."
iio_attr -u ip:$IP -o -c ad9361-phy voltage0 sampling_frequency $FS
iio_attr -u ip:$IP -o -c ad9361-phy voltage2 sampling_frequency $FS

echo -e "\nsetting frequency .."
iio_attr -u ip:$IP -c ad9361-phy TX_LO frequency $FREQ

echo -e "\nsetting RF output bandwidth .."
iio_attr -u ip:$IP -o -c ad9361-phy voltage0 rf_bandwidth $RFBW
iio_attr -u ip:$IP -o -c ad9361-phy voltage2 rf_bandwidth $RFBW
iio_attr -u ip:$IP -o -c ad9361-phy voltage3 rf_bandwidth $RFBW

echo -e "\nsetting TX Gain to $TXGAIN .."
iio_attr -u ip:$IP -o -c ad9361-phy voltage0 hardwaregain $TXGAIN

echo -e "\nsampling_frequency:"
iio_attr -u ip:$IP -o -c ad9361-phy . sampling_frequency
iio_attr -u ip:$IP -d ad9361-phy tx_path_rates

# at arecord: you might need to specify soundcard like this "-Dplughw:0,0"
# modify/adjust PI and PS with mpxgen
arecord -fS16_LE -r 48000 -c 2 - \
 | mpxgen --audio - --pi FFFF --ps "mpxgen pluto" --rds 0 --output-file - \
 | csdr convert_s16_f \
 | csdr fmmod_fc \
 | csdr fir_interpolate_cc 4 \
 | csdr convert_f_s16 \
 | iio_writedev -u ip:$IP -b $BUFSIZ  cf-ad9361-dds-core-lpc

