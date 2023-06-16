SET IMAGE_NAME=alpine-3.18-amd64

docker build -t %IMAGE_NAME% .
docker push %IMAGE_NAME%