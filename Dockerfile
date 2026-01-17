FROM --platform=linux/amd64 ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
# Set timezone VN (install tzdata first to avoid error)
RUN apt update -y && apt install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    novnc \
    websockify \
    sudo \
    xterm \
    init \
    systemd \
    snapd \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    neofetch \
    btop \
    python3 \
    python3-pip \
    wmctrl \
    openssh-server \
    wget \
    gnupg \
    lsb-release
# Install Netdata
RUN wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh && sh /tmp/netdata-kickstart.sh --release-channel stable --non-interactive
# Suppress Netdata cloud config warning
RUN mkdir -p /var/lib/netdata/cloud.d/ && touch /var/lib/netdata/cloud.d/cloud.conf
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs
RUN apt update -y && apt install -y \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps
RUN apt install software-properties-common -y
RUN add-apt-repository ppa:mozillateam/ppa -y
RUN echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
RUN apt update -y && apt install -y firefox
RUN apt update -y && apt install -y xubuntu-icon-theme
RUN mkdir -p /root/.vnc
RUN (echo '1234' && echo '1234') | vncpasswd && chmod 600 /root/.vnc/passwd
# Setup SSH
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'root:lemem1234' | chpasswd
# Create xstartup for XFCE
RUN echo '#!/bin/sh' > /root/.vnc/xstartup && \
    echo '[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources' >> /root/.vnc/xstartup && \
    echo 'vncconfig -iconic &' >> /root/.vnc/xstartup && \
    echo 'dbus-launch --exit-with-session xfce4-session' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup
RUN echo '<!DOCTYPE html><html><head><title>duyhoangg.v2</title><script>window.location.replace("vnc.html?autoconnect=1&resize=scale&fullscreen=1");</script></head><body></body></html>' > /usr/share/novnc/index.html
RUN touch /root/.Xauthority
# Expose ports (SSH 22, Netdata 19999, VNC 5901/6080)
EXPOSE 22 19999 5901 6080
# CMD: Chạy tất cả services (SSH & Netdata background, wait init, rồi VNC)
CMD bash -c "unset SESSION_MANAGER && unset DBUS_SESSION_BUS_ADDRESS && \
    /usr/sbin/sshd -D & \
    /usr/sbin/netdata & \
    sleep 10 && \
    # Đợi Netdata init (khoảng 5-10s) \
    vncserver -localhost no -geometry 1920x1080 -xstartup /root/.vnc/xstartup :1 && \
    openssl req -new -subj \"/C=JP\" -x509 -days 365 -nodes -out self.pem -keyout self.pem && \
    websockify -D --web=/usr/share/novnc/ --cert=self.pem 6080 localhost:5901 && \
    tail -f /dev/null"
