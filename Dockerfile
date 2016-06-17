FROM ubuntu:14.04.3
MAINTAINER jinwoo <jinwoo@yellomobile.com>

RUN sed -i 's/archive.ubuntu.com/ftp.daum.net/g' /etc/apt/sources.list

WORKDIR /root
RUN groupadd --gid 1000 mysql
RUN useradd --uid 1000 --gid 1000 mysql
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
RUN apt-get install -y software-properties-common
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
RUN add-apt-repository 'deb [arch=amd64,i386] http://ftp.kaist.ac.kr/mariadb/repo/10.1/ubuntu trusty main'
RUN apt-get update
RUN apt-get -y install mariadb-server curl gzip
ADD my.cnf /etc/mysql/my.cnf
ADD client.cnf /etc/my.cnf.d/client.cnf
RUN rm -rf /var/lib/mysql/*
ADD run /usr/local/bin/run
RUN chmod 750 /usr/local/bin/run

EXPOSE 3306
