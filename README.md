# transmit-ukw-fm
Generate Stereo WFM signal with RDS and transmit with Adalm Pluto SDR

# setup

```
git clone https://github.com/hayguen/transmit-ukw-fm.git
cd transmit-ukw-fm
./setup.sh
```

if you just want the simple signal generator, amend 'car' to the setup call:
```
./setup.sh car
```

then, adjust configuration at top of ukw-fm-live-from-audio.sh
  or transmit_carriers.sh

```
nano ukw-fm-live-from-audio.sh
nano transmit_carriers.sh
```

# run/test

```
cd transmit-ukw-fm
./ukw-fm-live-from-audio.sh
```

or

```
cd transmit-ukw-fm
./transmit_carriers.sh
```


# legal

for transmission over an antenna, you need to check your local laws!
this script is just for demonstration .. with attenuator(s) and cable directly into an SDR receiver.
