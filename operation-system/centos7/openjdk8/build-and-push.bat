SET IMAGE_NAME=blankhang/centos7:openjdk8-amd64

docker build -t %IMAGE_NAME% .
docker push %IMAGE_NAME%