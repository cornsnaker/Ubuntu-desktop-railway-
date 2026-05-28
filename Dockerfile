# Upgraded to the latest stable LTS for 2026 workflows
FROM ubuntu:24.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

# 1. Install core utilities and XFCE4 (Lightest desktop for speed)
RUN apt-get update && apt-get install -y \
    sudo curl wget gnupg apt-transport-https software-properties-common \
    ca-certificates unzip git nano htop \
    dbus dbus-x11 x11-xserver-utils locales \
    xfce4 xfce4-goodies xrdp xorgxrdp \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Add Chrome & Brave Repositories (Latest versions)
RUN curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list && \
    curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg >> /dev/null && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list

# 3. Install Browsers
RUN apt-get update && apt-get install -y \
    google-chrome-stable brave-browser \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. PERFORMANCE TWEAKS: Optimize XRDP for low latency
RUN sed -i 's/tcp_nodelay=false/tcp_nodelay=true/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/g' /etc/xrdp/xrdp.ini && \
    echo "tcp_send_buffer_bytes=4194304" >> /etc/xrdp/xrdp.ini && \
    echo "tcp_recv_buffer_bytes=4194304" >> /etc/xrdp/xrdp.ini

# 5. BROWSER FIXES: Disable sandbox for Docker compatibility
RUN sed -i 's/Exec=\/usr\/bin\/google-chrome-stable %U/Exec=\/usr\/bin\/google-chrome-stable --no-sandbox --disable-dev-shm-usage --disable-gpu %U/g' /usr/share/applications/google-chrome.desktop && \
    sed -i 's/Exec=\/usr\/bin\/brave-browser-stable %U/Exec=\/usr\/bin\/brave-browser-stable --no-sandbox --disable-dev-shm-usage --disable-gpu %U/g' /usr/share/applications/brave-browser.desktop

# 6. Setup User & Permissions
RUN useradd -m -s /bin/bash craxid && \
    echo "craxid:craxid" | chpasswd && \
    usermod -aG sudo craxid && \
    adduser xrdp ssl-cert

# 7. Configure XFCE Startup
RUN echo "xfce4-session" > /home/craxid/.xsession && \
    chown craxid:craxid /home/craxid/.xsession

# 8. Final Startup Script
RUN echo '#!/bin/bash\n\
rm -f /var/run/xrdp/xrdp*.pid\n\
mkdir -p /var/run/dbus\n\
dbus-uuidgen > /etc/machine-id\n\
dbus-daemon --system --fork\n\
/usr/sbin/xrdp-sesman\n\
/usr/sbin/xrdp -n\n' > /start.sh && chmod +x /start.sh

EXPOSE 3389
CMD ["/start.sh"]
