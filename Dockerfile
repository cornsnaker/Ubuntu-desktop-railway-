# Upgraded to the latest stable LTS for 2026 workflows
FROM ubuntu:24.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 1. Install core utilities, full Ubuntu GNOME desktop, and XRDP
# (Note: ubuntu-desktop-minimal provides the default Ubuntu shell, dock, and theme without bloatware)
RUN apt-get update && apt-get install -y \
    sudo curl wget gnupg apt-transport-https software-properties-common \
    ca-certificates unzip git nano htop locales \
    ubuntu-desktop-minimal xrdp xorgxrdp ssl-cert \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Add Repositories for Google Chrome and VS Code (seen in IMG_20260528_112013_343.jpg)
RUN curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg >> /dev/null && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/packages.microsoft.gpg >> /dev/null && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list

# 3. Install Chrome and VS Code
RUN apt-get update && apt-get install -y \
    google-chrome-stable code \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. PERFORMANCE TWEAKS: Optimize XRDP for low latency
RUN sed -i 's/tcp_nodelay=false/tcp_nodelay=true/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/g' /etc/xrdp/xrdp.ini && \
    echo "tcp_send_buffer_bytes=4194304" >> /etc/xrdp/xrdp.ini && \
    echo "tcp_recv_buffer_bytes=4194304" >> /etc/xrdp/xrdp.ini

# 5. BROWSER & APP FIXES: Disable sandbox for Docker compatibility
RUN sed -i 's/Exec=\/usr\/bin\/google-chrome-stable %U/Exec=\/usr\/bin\/google-chrome-stable --no-sandbox --disable-dev-shm-usage %U/g' /usr/share/applications/google-chrome.desktop

# 6. Setup User & Permissions
RUN useradd -m -s /bin/bash craxid && \
    echo "craxid:craxid" | chpasswd && \
    usermod -aG sudo craxid && \
    adduser xrdp ssl-cert

# 7. CRITICAL FIX: Configure XRDP to load the authentic Ubuntu GNOME Session
# This forces the desktop environment to launch with the Ubuntu Dock, style, and extensions enabled.
RUN echo "export XDG_CURRENT_DESKTOP=Ubuntu:GNOME" > /home/craxid/.xsessionrc && \
    echo "export GNOME_SHELL_SESSION_MODE=ubuntu" >> /home/craxid/.xsessionrc && \
    echo "export XDG_DATA_DIRS=/usr/share/ubuntu:/usr/local/share:/usr/share" >> /home/craxid/.xsessionrc && \
    echo "export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg" >> /home/craxid/.xsessionrc && \
    chown craxid:craxid /home/craxid/.xsessionrc

# 8. Final Startup Script
RUN echo '#!/bin/bash\n\
rm -f /var/run/xrdp/xrdp*.pid\n\
mkdir -p /var/run/dbus\n\
dbus-uuidgen --ensure=/etc/machine-id\n\
dbus-daemon --system --fork\n\
/usr/sbin/xrdp-sesman\n\
exec /usr/sbin/xrdp -n\n' > /start.sh && chmod +x /start.sh

EXPOSE 3389
CMD ["/start.sh"]
