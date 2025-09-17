SET IMAGE_NAME=blankhang/ubuntu2404:openjdk25

docker build -t %IMAGE_NAME% .
docker push %IMAGE_NAME%