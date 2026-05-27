FROM redis:8.8.0-alpine

MAINTAINER blankhang@gmail.com

ENV TZ=Asia/Shanghai

COPY redis.conf /usr/local/etc/redis/redis.conf

EXPOSE 6379

# redis with notify-keyspace-events Ex ON

CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
