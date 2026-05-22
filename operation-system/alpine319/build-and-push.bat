SET IMAGE_NAME=alpine319-amd64

docker build -t %IMAGE_NAME% .
docker push %IMAGE_NAME%