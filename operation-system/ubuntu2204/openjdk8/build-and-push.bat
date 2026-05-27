SET IMAGE_NAME=blankhang/ubuntu2204:openjdk8-amd64

docker build -t %IMAGE_NAME% .
docker push %IMAGE_NAME%