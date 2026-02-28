FROM ubuntu:22.04

# Prevent interactive prompts and set locale
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

# 1. Install core utilities and repository tools
RUN apt-get update && apt-get install -y \
    sudo curl wget gnupg apt-transport-https software-properties-common \
    ca-certificates unzip git nano htop \
    dbus dbus-x11 x11-xserver-utils locales \
    && apt-get clean

# 2. Add Brave Browser Repository
RUN curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list

# 3. Add Google Chrome Repository
RUN curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg >> /dev/null && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list

# 4. Install XFCE Desktop, XRDP, Browsers, and Terminal
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies xrdp xfce4-terminal \
    google-chrome-stable brave-browser \
    && apt-get clean

# 5. FIX: Modify Chrome & Brave shortcuts to run without sandbox (Required for Docker)
RUN sed -i 's/Exec=\/usr\/bin\/google-chrome-stable %U/Exec=\/usr\/bin\/google-chrome-stable --no-sandbox --disable-dev-shm-usage %U/g' /usr/share/applications/google-chrome.desktop && \
    sed -i 's/Exec=\/usr\/bin\/brave-browser-stable %U/Exec=\/usr\/bin\/brave-browser-stable --no-sandbox --disable-dev-shm-usage %U/g' /usr/share/applications/brave-browser.desktop

# 6. Generate locales and force the lightweight terminal
RUN locale-gen en_US.UTF-8 && \
    update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal

# 7. FIX: Generate a Machine ID (Prevents random D-Bus and system errors)
RUN dbus-uuidgen > /etc/machine-id

# 8. Create a standard user (Username: craxid | Password: craxid)
RUN useradd -m -s /bin/bash craxid && \
    echo "craxid:craxid" | chpasswd && \
    usermod -aG sudo craxid

# 9. Allow anybody to start the X server
RUN mkdir -p /etc/X11 && echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# 10. Tell XRDP exactly how to start XFCE with D-Bus enabled
RUN echo '#!/bin/sh\n\
export XDG_SESSION_DESKTOP=xfce\n\
export XDG_CURRENT_DESKTOP=XFCE\n\
exec dbus-launch --exit-with-session startxfce4' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# 11. Create the master startup script
RUN echo '#!/bin/bash\n\
rm -rf /var/run/xrdp/*\n\
mkdir -p /var/run/dbus\n\
dbus-daemon --system\n\
/usr/sbin/xrdp-sesman\n\
/usr/sbin/xrdp -n\n' > /start.sh && chmod +x /start.sh

# Expose the RDP port
EXPOSE 3389

CMD ["/bin/bash", "/start.sh"]
