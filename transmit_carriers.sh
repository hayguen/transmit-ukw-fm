#!/bin/bash

# insert/replace with IP address of Adalm Pluto
IP="192.168.2.1"
CSDR="/usr/bin/csdr"

if [ ! -f AD936x_LP_180kHz_521kSPS.ftr ]; then
  wget https://raw.githubusercontent.com/analogdevicesinc/iio-oscilloscope/master/filters/AD936x_LP_180kHz_521kSPS.ftr
fi
if [ ! -f AD936x_LP_256kHz_768kSPS.ftr ]; then
  wget https://raw.githubusercontent.com/analogdevicesinc/iio-oscilloscope/master/filters/AD936x_LP_256kHz_768kSPS.ftr
fi
if [ ! -f AD936x_LP_333kHz_1MSPS.ftr ]; then
  wget https://raw.githubusercontent.com/analogdevicesinc/iio-oscilloscope/master/filters/AD936x_LP_333kHz_1MSPS.ftr
fi
if [ ! -f AD936x_LP_666kHz_2MSPS.ftr ]; then
  wget https://raw.githubusercontent.com/analogdevicesinc/iio-oscilloscope/master/filters/AD936x_LP_666kHz_2MSPS.ftr
fi



FILTER_FILE="AD936x_LP_333kHz_1MSPS.ftr"
FS="1000000"

if [ "$1" = "SR1M" ] || [ "$1" = "sr1m" ]; then
  FILTER_FILE="AD936x_LP_333kHz_1MSPS.ftr"
  FS="1000000"
  shift
elif [ "$1" = "SR2M" ] || [ "$1" = "sr2m" ]; then
  FILTER_FILE="AD936x_LP_666kHz_2MSPS.ftr"
  FS="2000000"
  shift

elif [ "$1" = "LP180" ] || [ "$1" = "lp180" ]; then
  FILTER_FILE="AD936x_LP_180kHz_521kSPS.ftr"
  FS="521000"
  shift
elif [ "$1" = "LP256" ] || [ "$1" = "lp256" ]; then
  FILTER_FILE="AD936x_LP_256kHz_768kSPS.ftr"
  FS="768000"
  shift
fi
echo "using filter file ${FILTER_FILE} with samplerate ${FS}"


GENERATOR="gen_dc_s16"
if [ "$1" = "C" ] || [ "$1" = "c" ]; then
  GENERATOR="gen_dc_s16"
  shift
elif [ "$1" = "L" ] || [ "$1" = "l" ]; then
  GENERATOR="gen_neg_fs4_s16"
  shift
elif [ "$1" = "U" ] || [ "$1" = "u" ]; then
  GENERATOR="gen_pos_fs4_s16"
  shift

elif [ "$1" = "CU" ] || [ "$1" = "cu" ]; then
  GENERATOR="gen_dc_pos_fs4_s16"
  shift
elif [ "$1" = "LC" ] || [ "$1" = "lc" ]; then
  GENERATOR="gen_dc_neg_fs4_s16"
  shift
elif [ "$1" = "LU" ] || [ "$1" = "lu" ]; then
  GENERATOR="gen_pos_neg_fs4_s16"
  shift
elif [ "$1" = "LCU" ] || [ "$1" = "lcu" ]; then
  GENERATOR="gen_dc_pos_neg_fs4_s16"
  shift

elif [ "$1" = "R" ] || [ "$1" = "r" ]; then
  GENERATOR="gen_pos_neg_fs2_s16"
  shift
elif [ "$1" = "CR" ] || [ "$1" = "cr" ] || [ "$1" = "RC" ] || [ "$1" = "rc" ] || [ "$1" = "RCR" ] || [ "$1" = "rcr" ]; then
  GENERATOR="gen_dc_pos_neg_fs2_s16"
  shift
fi


FREQUNIT="kHz"
FREQUNITZEROS="000"
if [ "$1" = "k" ] || [ "$1" = "K" ]; then
  FREQUNIT="kHz"
  FREQUNITZEROS="000"
  shift
elif [ "$1" = "m" ] || [ "$1" = "M" ]; then
  FREQUNIT="MHz"
  FREQUNITZEROS="000000"
  shift
fi


if [ -z "$1" ]; then
  echo "usage: $0 [SR1M|SR2M] [L|C|U|R] [K|M] <begin_freq_in_${FREQUNIT}> [<end_freq_in_${FREQUNIT}> <step_freq_in_${FREQUNIT}> <tx_gain_in_dB>]"
  echo "  SR1M/SR2M : set samplerate to 1 MHz or 2 MHz"
  echo "  L/C/U/R :   produce carrier(s) at (C)enter, (L)ower or (U)pper sideband (fs/4), (R)eversals (fs/2)"
  echo "              and the combinations: LC, CU, LU,  R, CR"
  echo "  K/M :       unit for frequencies: kHz or MHz"
  echo "  tx_gain_in_dB: 0 or negative values - Adalm Pluto supports -71 .. 0"
  echo ""
  echo "when started you can press following keys for control:"
  echo "  'b'                  for begin  frequency"
  echo "  'c'                  for center frequency"
  echo "  'e'                  for end    frequency"
  echo "  cursor left  or 'p'  for frequency down / prev"
  echo "  cursor right or 'n'  for frequency   up / next"
  echo "  cursor up    or 'u'  for transmit gain up"
  echo "  cursor down  or 'd'  for transmit gain down"
  echo "  'q'                  to quit"
  echo ""
  exit 1
fi

# set transmit frequency in FREQUNIT
F_BEG="$1"
if [ -z "$2" ]; then
  F_END="${F_BEG}"
  F_STEP="0"
else
  F_END="$2"
  F_STEP="1"
fi
if [ ! -z "$3" ]; then
  F_STEP="$3"
fi
if [ ${F_STEP} -gt 0 ]; then
  F_CENTER=$[ ${F_BEG} + ( ( ( ${F_END} - ${F_BEG} ) / 2 ) / ${F_STEP} ) * ${F_STEP} ]
else
  F_CENTER="${F_BEG}"
fi
if [ -z "$4" ]; then
  # RF gain: 0 is maximum power .. negative values are attenuation
  TXGAIN="0"
else
  TXGAIN="$4"
fi

echo "band center is ${F_CENTER} ${FREQUNIT}"
echo "band step is ${F_STEP} ${FREQUNIT}"
echo "transmit gain is ${TX_GAIN} dB"
FREQ="${F_CENTER}"

# RF Bandfilter - upsampling filter already filters to 180 kHz
RFBW="300000"

# do not change following settings
# Samplerate, Buffer und Upsampling Filter
BUFSIZ=$[ $FS / 20 ]
FILT=$(cat "${FILTER_FILE}")
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
iio_attr -u ip:$IP -c ad9361-phy TX_LO frequency ${FREQ}${FREQUNITZEROS}

echo -e "\nsetting RF output bandwidth .."
iio_attr -u ip:$IP -o -c ad9361-phy voltage0 rf_bandwidth $RFBW
iio_attr -u ip:$IP -o -c ad9361-phy voltage2 rf_bandwidth $RFBW
iio_attr -u ip:$IP -o -c ad9361-phy voltage3 rf_bandwidth $RFBW

echo -e "\nsetting TX Gain to $TXGAIN .."
iio_attr -u ip:$IP -o -c ad9361-phy voltage0 hardwaregain $TXGAIN

echo -e "\nsampling_frequency:"
iio_attr -u ip:$IP -o -c ad9361-phy . sampling_frequency
iio_attr -u ip:$IP -d ad9361-phy tx_path_rates

echo "======================================================"
echo "press 'b' for begin  frequency"
echo "press 'c' for center frequency"
echo "press 'e' for end    frequency"
echo "press cursor left  or 'p' for frequency down / prev"
echo "press cursor right or 'n' for frequency   up / next"
echo "press cursor up    or 'u' for transmit gain up"
echo "press cursor down  or 'd' for transmit gain down"
echo "press 'q' to quit"
echo "======================================================"

# run streaming in background
( ${CSDR} ${GENERATOR} \
 | iio_writedev -u ip:$IP -b $BUFSIZ  cf-ad9361-dds-core-lpc ) &
SUBSHELLPID=$!
CPID=$(pgrep -P ${SUBSHELLPID} csdr)
#echo "pid of subshell is ${SUBSHELLPID}"
#echo "pid of csdr in subshell is ${CPID}"

while : ; do
  echo -e "\n$C waiting to read"
  read -n 1 k <&1
  kh=$(echo -n "$k" |od -A n -t x1)
  #echo "read 1st: '${kh}'"
  N=""
  if [ "${kh}" = " 1b" ]; then
    #echo -n "escaped char: "
    read -n 1 k <&1
    kh=$(echo -n "$k" |od -A n -t x1)
    #echo "read 2nd: '${kh}'"
    if [ "${kh}" = " 5b" ]; then
      #echo -n "escaped with [: "
      read -n 1 k <&1
      kh=$(echo -n "$k" |od -A n -t x1)
      #echo "read 3rd: '${kh}'"
      if [ "$k" = "D" ]; then
        N="prev"  # Left
      elif [ "$k" = "C" ]; then
        N="next"  # Right
      elif [ "$k" = "A" ]; then
        N="up"   # Up
      elif [ "$k" = "B" ]; then
        N="down" # Down
      fi
      #echo "pressed 3-byte key '$k' hex '${kh}' special $N"
    fi
  elif [ "$k" = "q" ]; then
    echo "pressed 'q'. terminating"
    echo "killing pid of csdr ${CPID}"
    kill ${CPID}
    break
  elif [ "$k" = "b" ]; then
    N="begin"
  elif [ "$k" = "c" ]; then
    N="center"
  elif [ "$k" = "e" ]; then
    N="end"
  elif [ "$k" = "p" ]; then
    N="prev"
  elif [ "$k" = "n" ]; then
    N="next"
  elif [ "$k" = "u" ]; then
    N="up"
  elif [ "$k" = "d" ]; then
    N="down"
  fi

  if [ "$N" = "begin" ]; then
    FREQ="${F_BEG}"
    echo -e "\nsetting frequency ${FREQ} ${FREQUNIT} at TX Gain ${TXGAIN} dB"
    iio_attr -u ip:$IP -c ad9361-phy TX_LO frequency ${FREQ}${FREQUNITZEROS}
  elif [ "$N" = "end" ]; then
    FREQ="${F_END}"
    echo -e "\nsetting frequency ${FREQ} ${FREQUNIT} at TX Gain ${TXGAIN} dB"
    iio_attr -u ip:$IP -c ad9361-phy TX_LO frequency ${FREQ}${FREQUNITZEROS}
  elif [ "$N" = "center" ]; then
    FREQ="${F_CENTER}"
    echo -e "\nsetting frequency ${FREQ} ${FREQUNIT} at TX Gain ${TXGAIN} dB"
    iio_attr -u ip:$IP -c ad9361-phy TX_LO frequency ${FREQ}${FREQUNITZEROS}
  elif [ "$N" = "prev" ]; then
    FREQ=$[ ${FREQ} - ${F_STEP} ]
    echo -e "\nsetting frequency ${FREQ} ${FREQUNIT} at TX Gain ${TXGAIN} dB"
    iio_attr -u ip:$IP -c ad9361-phy TX_LO frequency ${FREQ}${FREQUNITZEROS}
  elif [ "$N" = "next" ]; then
    FREQ=$[ ${FREQ} + ${F_STEP} ]
    echo -e "\nsetting frequency ${FREQ} ${FREQUNIT} at TX Gain ${TXGAIN} dB"
    iio_attr -u ip:$IP -c ad9361-phy TX_LO frequency ${FREQ}${FREQUNITZEROS}
  elif [ "$N" = "up" ]; then
    TXGAIN=$[ ${TXGAIN} + 1 ]
    echo -e "\nsetting TX Gain to ${TXGAIN} dB at frequency ${FREQ} ${FREQUNIT}"
    iio_attr -u ip:$IP -o -c ad9361-phy voltage0 hardwaregain $TXGAIN
  elif [ "$N" = "down" ]; then
    TXGAIN=$[ ${TXGAIN} - 1 ]
    echo -e "\nsetting TX Gain to ${TXGAIN} dB at frequency ${FREQ} ${FREQUNIT}"
    iio_attr -u ip:$IP -o -c ad9361-phy voltage0 hardwaregain $TXGAIN
  fi
done

