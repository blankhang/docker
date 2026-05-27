SET IMAGE_NAME=blankhang/ubuntu2404:openjdk17

docker build -t %IMAGE_NAME% .
docker push %IMAGE_NAME%