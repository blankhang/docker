SET IMAGE_NAME=blankhang/centos7:openjdk17-amd64

docker build -t %IMAGE_NAME% .
docker push %IMAGE_NAME%