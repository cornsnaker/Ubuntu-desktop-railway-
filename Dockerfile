FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Desktop, VNC, SSH and Docker tools
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    tightvncserver \
    openssh-server \
    curl wget vim docker.io \
    && apt-get clean

# Setup SSH and VNC directories
RUN mkdir -p /run/sshd ~/.vnc

# Set VNC & Root Password (Default: craxid)
# VNC passwords must be truncated to 8 chars by the system
RUN echo "craxid" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd && \
    echo "root:craxid" | chpasswd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Create a startup script for the GUI
RUN echo '#!/bin/bash' > /start.sh && \
    echo '/usr/sbin/sshd' >> /start.sh && \
    echo 'vncserver :1 -geometry 1280x720 -depth 24' >> /start.sh && \
    echo 'tail -f ~/.vnc/*.log' >> /start.sh && \
    chmod +x /start.sh

# Expose SSH (22) and VNC (5901)
EXPOSE 22 5901

CMD ["/bin/bash", "/start.sh"]
