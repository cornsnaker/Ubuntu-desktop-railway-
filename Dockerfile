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
RUN sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/xrdp/Xwrapper.config

# Set Root password for RDP login
RUN echo "root:craxid" | chpasswd

# Create startup script
RUN echo '#!/bin/bash\n\
rm -rf /var/run/xrdp/*\n\
/usr/sbin/xrdp-sesman\n\
/usr/sbin/xrdp -n\n' > /start.sh && chmod +x /start.sh

# RDP default port
EXPOSE 3389

CMD ["/bin/bash", "/start.sh"]
