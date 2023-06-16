SET IMAGE_NAME=blankhang/centos7:openjdk11-amd64

docker build -t %IMAGE_NAME% .
docker push %IMAGE_NAME%