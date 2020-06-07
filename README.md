# transmit-ukw-fm
Generate Stereo WFM signal with RDS and transmit with Adalm Pluto SDR

# setup

```
git clone https://github.com/hayguen/transmit-ukw-fm.git
cd transmit-ukw-fm
./setup.sh
```

then, adjust configuration at top of ukw-fm-live-from-audio.sh

```
nano ukw-fm-live-from-audio.sh
```

# run/test

```
cd transmit-ukw-fm
./ukw-fm-live-from-audio.sh
```

# legal

for transmission over an antenna, you need to check your local laws!
this script is just for demonstration .. with attenuator(s) and cable directly into an SDR receiver.
