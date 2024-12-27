FROM debian:bullseye AS build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
RUN apt-get install \ 
    gnupg2 software-properties-common git curl wget build-essential \
    libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev \
    libjansson-dev libxml2-dev uuid-dev libedit-dev libopus-dev libsndfile1-dev \
    libcurl4-openssl-dev libspeex-dev libspeexdsp-dev libsndfile1-dev libogg-dev \
    libvorbis-dev autoconf automake libtool -y

RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz -O asterisk.tar.gz 
RUN tar -xvzf asterisk.tar.gz && rm asterisk.tar.gz && mv asterisk-* asterisk
WORKDIR /asterisk

RUN ./configure
RUN make menuselect.makeopts
RUN menuselect/menuselect --enable chan_ooh323 --enable codec_opus
RUN make
RUN make install
RUN make samples
RUN make config


FROM debian:bullseye AS base

RUN apt update -y
RUN apt install gnupg2 software-properties-common git curl wget build-essential autoconf automake libtool -y
RUN apt install  libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev \
    libjansson-dev libxml2-dev uuid-dev libedit-dev libopus-dev libsndfile1-dev \
    libcurl4-openssl-dev libspeex-dev libspeexdsp-dev libsndfile1-dev libogg-dev \
    libvorbis-dev -y
RUN apt clean

RUN adduser --quiet --disabled-password --gecos 'Asterisk' asterisk

COPY --from=build /etc/asterisk /etc/asterisk
COPY --from=build /usr/local/ /usr/local/
COPY --from=build /usr/lib/ /usr/lib/
COPY --from=build /usr/sbin/ /usr/sbin/
COPY --from=build /etc/init.d/asterisk /etc/init.d/asterisk

RUN mkdir -p /etc/asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk
RUN chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk

CMD ["service", "asterisk", "start", "&&", "/user/sbin/asterisk", "-f", "-vvv"]
