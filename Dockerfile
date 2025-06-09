FROM golang:1.24 AS builder

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
    AQUATONE_VERSION=1.7.0 \
    METABIGOR_VERSION=2.0.0

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

# Aquatone
WORKDIR /opt/aquatone
RUN wget https://github.com/michenriksen/aquatone/releases/download/v${AQUATONE_VERSION}/aquatone_linux_amd64_${AQUATONE_VERSION}.zip && \
    unzip aquatone_linux_amd64_${AQUATONE_VERSION}.zip && \
    mv aquatone /usr/bin && rm -rf *.zip

# Rustscan + Metabigor
ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=$PATH:/usr/local/cargo/bin
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal && \
    cargo install rustscan && \
    wget https://github.com/j3ssie/metabigor/releases/download/v${METABIGOR_VERSION}/metabigor_v${METABIGOR_VERSION}_linux_amd64.tar.gz && \
    tar -xvf metabigor_v${METABIGOR_VERSION}_linux_amd64.tar.gz && \
    mv metabigor /usr/bin && \
    rm -rf metabigor* $CARGO_HOME/registry $CARGO_HOME/git $RUSTUP_HOME

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
