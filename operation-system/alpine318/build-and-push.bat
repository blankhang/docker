SET IMAGE_NAME=alpine318-amd64

docker build -t %IMAGE_NAME% .
docker push %IMAGE_NAME%