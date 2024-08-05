# # recipe to create the nomad-remote-tools-hub apmtools container via a dockerfile
FROM gitlab-registry.mpcdf.mpg.de/nomad-lab/nomad-remote-tools-hub/webtop:v0.0.1

# for testing the container locally without running in oauth errors
# FROM ghcr.io/linuxserver/webtop:amd64-ubuntu-openbox-version-e1079163
# FROM ghcr.io/linuxserver/webtop:amd64-ubuntu-xfce-version-c603dc47
# # found that newest system python is 3.8.something
# # rest should come only from and be managed through (mini)conda not pip!
# # start of borrowed from gitlabmpcdf customized webtop
# ENV CUSTOM_PORT=8888
# ENV PUID=1000
# ENV PGID=1000
# ports and volumes
# EXPOSE 8888
# VOLUME /config
# # end of borrowed from north webtop

USER root

# not update but upgrade, otherwise depending on when the container is build a particular version may no longer
# be available as a consequence of which the following specifically-versioned packages will not be installable

# set the environment already, knowing where miniconda will be installed
ENV PATH=/usr/local/miniconda3/bin:$PATH

RUN mkdir -p /home \
  && mkdir -p /home/imagej/ImageJ/plugins/FAIRmat \
  && mkdir -p /home/fiji/Fiji.app


# install operating system dependencies
# get and install miniconda and customize it into a specific base environment
RUN apt update \
  && apt-get install -y git \
  && apt-get install -y unzip \
  && apt-get install -y wget \
  && apt-get install -y libglu1-mesa-dev \
  && apt-get install -y build-essential \
  && apt-get install -y cmake \
  && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
  && chmod +x Miniconda3-latest-Linux-x86_64.sh \
  && bash ./Miniconda3-latest-Linux-x86_64.sh -b -p /usr/local/miniconda3 \
  && rm -f Miniconda3-latest-Linux-x86_64.sh \
  && cd /home \
  && conda config --add channels conda-forge \
  && conda config --set channel_priority strict \
  && conda install python=3.10.6 ipykernel=6.16.0 jupyterlab=3.4.7 nodejs=18.9.0 \
  && pip install jupyterlab_h5web[full]==6.0.1 \
  && conda clean -afy \ 
  && chown -R ${PUID}:${PGID} /usr/local/miniconda3 \
  && cd /home/fiji \
  && wget https://downloads.imagej.net/fiji/archive/20220922-1417/fiji-linux64.zip \
  && unzip fiji-linux64.zip \
  && rm -f fiji-linux64.zip \
  && cd /home/imagej \
  && wget https://wsr.imagej.net/distros/linux/ij153-linux64-java8.zip \
  && unzip ij153-linux64-java8.zip \
  && rm -f ij153-linux64-java8.zip \
  && chown -R ${PUID}:${PGID} /home

# get Michael Mohn et al. plugins for ImageJ (these have been developed for imagej)
# https://github.com/mmohn/SER_Reader.git (using e7828be)
# https://github.com/mmohn/Stack_Alignment.git (1563c59)
# we are using here the files from the respective repository commits as indicated in the brackets
# the individual plug-in *.java source code files in this repository were then compiled using Compile and run
# on a Linux instance of the same imagej version as is unzip in this container
# the compiled plug-ins have been made available in /home/imagej/ImageJ/plugins/FAIRmat
# in ImageJ, we have done the compilation on the same ImageJ version which is used in this
# container, using the Compile and Run, the resulting java and class files are copied into the image
COPY Cheatsheet.ipynb FAIRmat_S.png /home/
ADD FAIRmat /home/imagej/ImageJ/plugins/FAIRmat/
COPY 02-exec-cmd /config/custom-cont-init.d/02-exec-cmd

# customize the webtop autostart to spin up jupyter-lab
WORKDIR /home
