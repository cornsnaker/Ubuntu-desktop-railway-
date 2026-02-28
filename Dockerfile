FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install XFCE, xrdp, and tools
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    xrdp \
    dbus-x11 x11-xserver-utils \
    curl wget sudo \
    && apt-get clean

# Configure xrdp to use XFCE
RUN echo "xfce4-session" > /etc/skel/.xsession

# FIX: Manually create the Xwrapper config in the correct directory
RUN mkdir -p /etc/X11 && echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Set Root password for RDP login
RUN echo "root:craxid" | chpasswd

# Create startup script (Now including dbus-daemon for better XFCE stability)
RUN echo '#!/bin/bash\n\
rm -rf /var/run/xrdp/*\n\
mkdir -p /var/run/dbus\n\
dbus-daemon --system\n\
/usr/sbin/xrdp-sesman\n\
/usr/sbin/xrdp -n\n' > /start.sh && chmod +x /start.sh

# RDP default port
EXPOSE 3389

CMD ["/bin/bash", "/start.sh"]
