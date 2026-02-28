FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install XFCE, xrdp, tools, AND Epiphany Web Browser
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    xrdp \
    dbus-x11 x11-xserver-utils \
    sudo curl wget \
    epiphany-browser \
    && apt-get clean

# Create a non-root user (GUI apps crash if run as root)
RUN useradd -m -s /bin/bash craxid && \
    echo "craxid:craxid" | chpasswd && \
    usermod -aG sudo craxid

# Allow anybody to start the X server
RUN mkdir -p /etc/X11 && echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Tell XRDP exactly how to start XFCE with D-Bus enabled
RUN echo '#!/bin/sh\n\
export XDG_SESSION_DESKTOP=xfce\n\
export XDG_CURRENT_DESKTOP=XFCE\n\
exec dbus-launch --exit-with-session startxfce4' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# Create startup script
RUN echo '#!/bin/bash\n\
rm -rf /var/run/xrdp/*\n\
mkdir -p /var/run/dbus\n\
dbus-daemon --system\n\
/usr/sbin/xrdp-sesman\n\
/usr/sbin/xrdp -n\n' > /start.sh && chmod +x /start.sh

# Expose the RDP port
EXPOSE 3389

CMD ["/bin/bash", "/start.sh"]
