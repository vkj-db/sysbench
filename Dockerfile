FROM ubuntu:xenial

RUN apt-get update

RUN apt-get -y install make automake libtool pkg-config libaio-dev git

# For MySQL support
RUN apt-get -y install libmysqlclient-dev libssl-dev

# For PostgreSQL support
RUN apt-get -y install libpq-dev

RUN apt-get -y install nano mysql-client

ADD https://api.github.com/repos/vkj-db/sysbench/git/refs/heads/modifications version.json
RUN git clone -b modifications https://github.com/vkj-db/sysbench.git sysbench

WORKDIR sysbench
RUN ./autogen.sh
RUN ./configure --with-mysql
RUN make -j
RUN make install

WORKDIR /root
RUN rm -rf sysbench

COPY run.sh .

CMD ["./run.sh"]
