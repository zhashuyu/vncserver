# k8s中所有使用的docker 镜像无需手动配置timezone均在pods中使用node的时区

FROM debian:9.8
MAINTAINER syzha@fiberhome.com

# 在新建了文件locale.gen后，安装locales软件时会自动初始化locale
# debian中新建用户的同时需要创建家目录的话需要添加-m参数，即使使用了-d参数
# ADD docker gitinfo.sh entrypoint.sh /usr/bin/
# ADD jdk-8u144-linux-x64.tar.gz apache-maven-3.5.0-bin.tar.gz /opt/
# openjdk-8-jre amd64 8u212-b01-1~deb9u1
# wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.8.0.x86_64.tar.gz | tar xz --strip 1 -C /
# apt-get install -y supervisor xfce4 xfce4-terminal \
# && apt-get purge -y pm-utils xscreensaver*
# python-numpy used for websockify/novnc
# 配置键盘时使用
# defconf自动配置时使用
#   DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm \
    DEBIAN_FRONTEND=noninteractive
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen \
    && sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install ttf-wqy-zenhei vim net-tools locales bzip2 git subversion git-svn curl jq wget --no-install-recommends --no-install-suggests --no-upgrade -y \
    && apt-get install openssh-client less python-numpy tigervnc-standalone-server tigervnc-common openjdk-8-jdk xfce4 xinit x11-xserver-utils xserver-xorg xterm supervisor xfce4-terminal ibus-pinyin pm-utils -y \ 
    && apt remove --purge pulseaudio -y \
    && apt clean \
    && apt autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && git config --system core.quotepath false

# firefox-esr/stable 60.6.1esr-1~deb9u1 amd64
# chromium/stable 72.0.3626.122-1~deb9u1 amd64
RUN apt update \
    && apt install firefox-esr chromium -y

ARG CACHEBUST=1
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
    # PATH=/opt/apache-jmeter-5.1.1/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    HOME=/home/default \
    DEBUG=true \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901 \
    NO_VNC_HOME=/opt/noVNC \
    VNC_PW=vncpassword \
    DISPLAY=:1 \
    TERM=xterm \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x800 \
    VNC_VIEW_ONLY=false \
    PATH="/opt/apache-jmeter-5.1.1/bin:${PATH}"

# 安装calibre-ebook\fonts
# echo "Install noVNC - HTML5 based VNC viewer"
# wget -qO- https://github.com/novnc/noVNC/archive/v1.0.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME
# use older version of websockify to prevent hanging connections on offline containers, see https://github.com/ConSol/docker-headless-vnc-container/issues/50
# wget -qO- https://github.com/novnc/websockify/archive/v0.6.1.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify
# create index.html to forward automatically to `vnc_lite.html`
# prevent vncconfig windows from popuup
# sed -i "/vncconfig/d" /etc/X11/Xvnc-session \
RUN sed -i "/vncconfig/d" /etc/X11/Xvnc-session \
    && echo "export XMODIFIERS=@im=ibus" >> /usr/bin/startxfce4 \
    && echo "export GTK_IM_MODULE=ibus" >> /usr/bin/startxfce4 \
    && echo "export QT_IM_MODULE=ibus" >> /usr/bin/startxfce4 \
    && useradd -d /home/default -m -u 1000 -g 100 -s /bin/bash default \
    && echo "default:default" | chpasswd \
    && echo "root:chk8c2eYcet#" | chpasswd \
    && curl -s http://172.17.0.1:8000/xfce.tar.gz -o /tmp/xfce.tar.gz \
    && tar xf /tmp/xfce.tar.gz --strip 1 -C $HOME \
    && curl -s http://172.17.0.1:8000/noVNC-v1.0.0.tar.gz -o /tmp/noVNC-v1.0.0.tar.gz \
    && mkdir -p $NO_VNC_HOME \
    && tar xf /tmp/noVNC-v1.0.0.tar.gz --strip 1 -C $NO_VNC_HOME \
    && mkdir -p $NO_VNC_HOME/utils/websockify \
    && curl -s http://172.17.0.1:8000/websockify-v0.6.1.tar.gz -o /tmp/websockify-v0.6.1.tar.gz \
    && tar xf /tmp/websockify-v0.6.1.tar.gz --strip 1 -C $NO_VNC_HOME/utils/websockify \
    && chmod +x -v $NO_VNC_HOME/utils/*.sh \
    && ln -s $NO_VNC_HOME/vnc_lite.html $NO_VNC_HOME/index.html \
    && curl -s http://172.17.0.1:8000/entrypoint.sh -o /usr/bin/entrypoint.sh \
    && chmod +x /usr/bin/entrypoint.sh \
    && chown default:users /home/default -R

RUN curl -s http://172.17.0.1:8000/apache-jmeter-5.1.1-origin.tgz -o /tmp/apache-jmeter-5.1.1.tgz \
    && tar xf /tmp/apache-jmeter-5.1.1.tgz -C /opt \
    && rm -rf /tmp/*


EXPOSE $VNC_PORT $NO_VNC_PORT

WORKDIR /home/default
USER 1000

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["--wait"]
