FROM golang:1.24.4 AS builder

ENV GO111MODULE=on \
    GOBIN=/go/bin

RUN go install github.com/owasp-amass/amass/v4/...@master && \
    go install github.com/tomnomnom/anew@latest && \
    go install github.com/tomnomnom/assetfinder@latest && \
    go install github.com/tomnomnom/httprobe@latest && \
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    go install github.com/projectdiscovery/katana/cmd/katana@latest && \
    go install github.com/tomnomnom/fff@latest && \
    go install github.com/jaeles-project/gospider@latest && \
    go install github.com/ffuf/ffuf/v2@latest

FROM ubuntu:24.04
COPY --from=builder /go/bin /usr/bin

ENV DEBIAN_FRONTEND=noninteractive \
    VERSION=1.4.3

RUN apt update && \
		apt install -y python3 python3-pip dnsutils nmap wget unzip curl && \
		apt-get update && \
    apt-get install -y \
    iputils-ping \
    git \
    curl \
    unzip \
    wget && \
		pip3 install arjun dirsearch --break-system-packages

WORKDIR /opt/chromium
RUN apt-get install -yq libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2-dev libxtst6 xauth xvfb\
    ca-certificates fonts-liberation libnss3 lsb-release xdg-utils wget

RUN git clone https://github.com/scheib/chromium-latest-linux && \
    cd chromium-latest-linux && ./update.sh && \
    ln -s /opt/chromium/chromium-latest-linux/latest/chrome /usr/bin/chromium

# install aquatone binary
WORKDIR /opt/aquatone
RUN wget https://github.com/michenriksen/aquatone/releases/download/v${VERSION}/aquatone_linux_amd64_${VERSION}.zip && \
    unzip aquatone_linux_amd64_${VERSION}.zip && \
    cp aquatone /usr/bin

# install cargo and rustscan, metabigor
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
		/bin/bash -c 'source "$HOME/.cargo/env" && cargo install rustscan' && \
		wget https://github.com/j3ssie/metabigor/releases/download/v2.0.0/metabigor_v2.0.0_linux_amd64.tar.gz && \
		tar -xvf metabigor_v2.0.0_linux_amd64.tar.gz && mv metabigor /usr/bin

RUN apt install -y nano time openssh-server && \
		mkdir -p /var/run/sshd && \
# authorize SSH connection with root account
		echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
# change password root
		echo "root:recon_cbjslab"|chpasswd
# RUN service ssh restart

RUN mkdir /root/wordlists
COPY ./fuzz-Bo0oM.txt /root/wordlists
COPY ./common.txt /root/wordlists 
WORKDIR /root
CMD ["/usr/sbin/sshd", "-D"]
