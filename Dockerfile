FROM ubuntu:20.04

LABEL 	original.maintainer="Dimitri Vasdekis <dvasdekis@gmail.com>" \
	current.maintainer="florentchandelier"

# Set Env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV TWS_MAJOR_VRSN=978
ENV IBC_VERSION=3.8.2
ENV IBC_INI=/root/IBController/IBController.ini
ENV IBC_PATH=/opt/IBController
ENV TWS_PATH=/root/Jts
ENV TWS_CONFIG_PATH=/root/Jts
ENV LOG_PATH=/opt/IBController/Logs
ENV JAVA_PATH=/opt/i4j_jres/1.8.0_152-tzdata2019c/bin
ENV APP=GATEWAY

# Install needed packages
RUN apt-get -qq update -y && apt-get -qq install -y unzip xvfb libxtst6 libxrender1 libxi6 socat software-properties-common curl supervisor x11vnc tmpreaper python3-pip

# TZ aligned with NYSE
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# make dirs
RUN mkdir -p /opt/TWS
RUN mkdir -p /opt/IBController/ && mkdir -p /opt/IBController/Logs
RUN mkdir -p /root/Jts/
RUN mkdir ~/.vnc

# Install IB TWS
WORKDIR /opt/TWS
COPY ./ibgateway-stable-standalone-linux-9782c-x64.sh /opt/TWS/ibgateway-stable-standalone-linux-x64.sh
RUN chmod a+x /opt/TWS/ibgateway-stable-standalone-linux-x64.sh
RUN yes n | /opt/TWS/ibgateway-stable-standalone-linux-x64.sh
RUN rm /opt/TWS/ibgateway-stable-standalone-linux-x64.sh
# Overwrite vmoptions file
RUN rm -f /root/Jts/ibgateway/978/ibgateway.vmoptions
COPY ./ibgateway.vmoptions /root/Jts/ibgateway/978/ibgateway.vmoptions

# Install IBController
WORKDIR /opt/IBController/
COPY ./IBCLinux-3.8.2/  /opt/IBController/
RUN chmod -R u+x *.sh && chmod -R u+x scripts/*.sh
COPY ./ib/IBController.ini /root/IBController/IBController.ini
COPY ./ib/jts.ini /root/Jts/jts.ini

# Must be set after install of IBGateway
ENV DISPLAY :0

# Auto VNC Configuration
RUN /usr/bin/x11vnc -storepasswd 1234 /etc/vncpwd

# Install Python requirements
RUN pip3 install supervisor
COPY ./restart-docker-vm.py /root/restart-docker-vm.py
COPY ./config/supervisor/*.conf /etc/supervisor/conf.d/

CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
