FROM ubuntu:16.04
MAINTAINER jinwoo <jinwoo@yellomobile.com>

ARG VERSION
ENV VERSION $VERSION
RUN echo $VERSION

RUN sed -i 's/archive.ubuntu.com/ftp.daum.net/g' /etc/apt/sources.list

WORKDIR /root
RUN groupadd --gid 1000 mysql
RUN useradd --uid 1000 --gid 1000 mysql
RUN apt-get update && apt-get install -y software-properties-common
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
RUN add-apt-repository "deb [arch=amd64] http://ftp.kaist.ac.kr/mariadb/repo/${VERSION}/ubuntu xenial main"
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-server curl gzip
ADD files/my.cnf /etc/mysql/my.cnf
ADD files/client.cnf /etc/my.cnf.d/client.cnf
RUN rm -rf /var/lib/mysql/*
ADD files/run.sh /usr/local/bin/run
RUN chmod 750 /usr/local/bin/run

EXPOSE 3306
