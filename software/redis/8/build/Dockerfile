FROM redis:8

MAINTAINER blankhang@gmail.com

ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

#RUN apt update

#RUN apt install -y curl tzdata \
#    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
#    && echo ${TZ} > /etc/timezone \
#    && dpkg-reconfigure --frontend noninteractive tzdata \
#    && rm -rf /var/lib/apt/lists/*

COPY redis.conf /usr/local/etc/redis/redis.conf

EXPOSE 6379

# redis with notify-keyspace-events Ex ON 

CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
