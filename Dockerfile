FROM ubuntu:22.04

# Prevent interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install XFCE, VNC server, and noVNC
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    tightvncserver \
    novnc websockify \
    curl \
    python3 \
    && apt-get clean

# Set up the VNC password (change 'railway' to something else)
RUN mkdir -p ~/.vnc && \
    echo "railway" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Expose the port Railway will use
EXPOSE 8080

# Start script to launch VNC and noVNC
CMD vncserver :1 -geometry 1280x720 -depth 24 && \
    websockify --web /usr/share/novnc/ 8080 localhost:5901
