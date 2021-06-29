#   Rebuild this file
#   docker build . -t espat

#   This container has everything setup but you'll want to mount an output directory for when you build your firmware
#   or it will be stuck inside this container for you to admire.
#   docker run -it -v ~/dev/myfolder:/esp/esp-at/build/factory espat

#   ESP guide: https://docs.espressif.com/projects/esp-at/en/latest/Compile_and_Develop/How_to_clone_project_and_compile_it.html

#   ESP currently using 4.2 version of IDF
FROM ubuntu:20.04

# Install build dependencies (and vim + picocom for editing/debugging)

#   tzdata forces some interaction and we don't want that.
RUN apt-get -qq update && DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN apt-get -qq update \
    && apt-get install -y gcc git wget curl make libncurses-dev flex bison gperf \
                          cmake ninja-build \
                          ccache \
                          vim picocom \
                          python3 python3-pip python3-venv libusb-1.0-0-dev
                          # \
    #&& apt-get clean \
    #&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


#   1.  First, set up the development environment for ESP-IDF according to Step 1 to 4 of ESP-IDF Get Started Guide (click the corresponding link in the table above to navigate to the documentation).

#   Getting Started 1: (Install Linux)
#   Getting Started 2: (Get ESP-IDF) - This takes bout 10 mins.
RUN mkdir /esp && cd /esp && git clone -b release/v4.2 --recursive https://github.com/espressif/esp-idf.git

#   Set python3 as default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10
RUN echo "alias pip='pip3'" >> ~/.bashrc

#   Upgrade pip
RUN pip3 install --upgrade pip

#   Getting Started 4. Set up the environment variables
RUN echo "alias ls='ls --color=auto'" >> ~/.bashrc
RUN echo "alias grep='grep --color=auto'" >> ~/.bashrc
RUN echo "alias fgrep='fgrep --color=auto'" >> ~/.bashrc
RUN echo "alias egrep='egrep --color=auto'" >> ~/.bashrc
#RUN echo "alias get_idf='. /esp/esp-idf/export.sh'" >> ~/.bashrc

#   Getting Started 3: (Install tools)
RUN cd /esp/esp-idf && ./install.sh 

#RUN source ~/.bashrc
#RUN get_idf

#   Run interactively to test creating a hello world project...
#   docker -it run espat
#   get_idf
#   cd /esp
#   cp -r $IDF_PATH/examples/get-started/hello_world .
#   cd /esp/hello_world
#   idf.py set-target esp32
#   idf.py menuconfig
#   idf.py build


#   2.  Get ESP-AT
RUN cd /esp && git clone --recursive https://github.com/espressif/esp-at.git

# Install missing python package
RUN python -m pip install pyyaml xlrd click future pyparsing==2.0.3 pyelftools gdbgui==0.13.2.0 pygdbmi==0.9.0.2 pyserial reedsolo==1.5.4 cryptography bitstring ecdsa

#   Setup for esp32 for a non-interactive situation
RUN mkdir /esp/esp-at/build && echo '{"platform": "PLATFORM_ESP32", "module": "WROOM-32", "description": "", "silence": 0}'  > /esp/esp-at/build/module_info.json

#   Use the esp-idf found in our esp-at directory, not the vanilla one we started with

#   We also need to exit 0 because this will throw an error.  The build goes right into actually trying to compile without 
#   setting up the environment first.  Which doesn't make sense as this build menuconfig command is actually downloading
#   esp-idf to setup the environment.  A little cart before the horse so we need to work around it.
RUN cd /esp/esp-at && ./build.py menuconfig ; exit 0

ENV IDF_PATH=/esp/esp-at/esp-idf

#   Build defaults...  ncurses terminal won't work during a docker build but you can do this interactively later.
#   This build primes the pump and gets everything mostly built.
RUN . /esp/esp-at/esp-idf/export.sh && python -m pip install xlrd pyyaml && cd /esp/esp-at && ./build.py build

#   Run this interactivevly if you want to make some changes to your firmware.  Make sure to mount
#   a volume to this container so you copy the file out.
#   i.e.  docker run -it -v ~/dev/myfolder:/esp/esp-at/build/factory espat /bin/bash
#   
#   Configure: cd /esp/esp-at && ./build.py menuconfig
#   Build: cd /esp/esp-at && ./build.py build

COPY ./helper.sh /
RUN chmod +x /helper.sh

#   This will drop you in a shell by default.
CMD ["/helper.sh"]
