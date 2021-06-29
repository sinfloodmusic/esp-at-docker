# Overview
esp-at-docker is a docker project you can use to build the  [esp-at firmware](https://github.com/espressif/esp-at) with a low amount of effort.  Basically AT-Firmware turns your ESP32 into a modem, taking ```AT``` type commands and connecting to WiFI, Bluetooth LE, Classic Bluetooth (disabled by default!), and other things.  

This is super useful if you want to just us RX/TX pins on a Serial Port on your MCU and add wireless or other capabilities.  You can even update the firmware to use SPI for these interactions so they're much faster than standard serial.  Depends on the speed you need.

Espressif's documentation for building seems to leave out a few things and I wanted to have a repeatable process for my ESP32-WROOM32.  This project assumes you are using the ESP32-WROOM32 but you can easily change the dockerfile to update for your specific ESP32 chip.

Please note I'm not an Ubuntu/Linux expert and there are far cleaner ways to accomplish some of the things you see below, but this works, and it works for me.  I'm sharing this to save someone else several hours of time that just wants to get to the fun stuff and try things out.  

If you have a pull request that cleans it up and makes it a bit cleaner, feel free to contribute.  My time is limited but will try to test out your change.


## Installation

Prerequisites:

* This project requires you have a working [docker](https://github.com/docker) setup on your Windows, Mac, or PC.

Clone this repo

```
git clone https://github.com/sinfloodmusic/esp-at-docker
```

If you are not using an ESP32-WROOM32 you'll want to update this line and use values for your chip, they are listed [here](https://docs.espressif.com/projects/esp-at/en/latest/Compile_and_Develop/How_to_clone_project_and_compile_it.html)
```
RUN mkdir /esp/esp-at/build && echo '{"platform": "PLATFORM_ESP32", "module": "WROOM-32", "description": "", "silence": 0}'  > /esp/esp-at/build/module_info.json
```

Build the dockerfile with this command.  This will also build the default firmware, and it will be **trapped** in the image.  This takes about 20-30 minutes for the whole build to complete.

The tag ```-t espat``` can be whatever you like.
```
docker build . -t espat
```

After that you can run this Docker image (interactively ```-it```) and configure the firmware however you would like.  However, you need to make sure you map a local volume from your host computer into the Docker container, or it will build and you won't be able to get it out.  :)

Mapping using the command below (to /esp/esp-at/build/factory) will dump the firmware into your /tmp/mycomputer on your local machine.  You can also map somewhere else and simply copy the firmware to that mount point if you like.

```
docker run -it -v /tmp:/esp/esp-at/build/factory espat
```

On launch, a helper script (```helper.sh```) will give you some direction on what to do.

If you run ```cd /esp/esp-at && ./build.py menuconfig``` it will launch the ```menuconfig``` which is an ncurses graphical environment where you can select the components you want as well as other configuration for your final firmware build.  Once you are happy, save and exit. 

You'll then be at the prompt in the container.  You can build your firmware with the following command:

```
cd /esp/esp-at && ./build.py build 
```

It will go pretty fast in most cases because you paid for that up front with the initial 20-30 minute docker build command when you built the image.

On build completion, your firmware will be in the container at ```/esp/esp-at/build/factory``` and if you mounted a volume to your host (like ```/tmp```) you'll see it built there.  If you didn't, you'll either need to do some curl gymnastics to get it out, or restart and map a volume to your container.

You can now flash your firmware.  I'm using ```esptool.py``` that I built using the standard esp-if installation process.  This container will not help you flash your firmware, it will just help you build it.

Note: When you configure the firmware, the output file that matters is called ```sdkconfig``` and is located here ```/esp/esp-at/sdkconfig```.  If you want a repeatable process, you'll want to keep that file as it will get blown away the next time you restart your container.
