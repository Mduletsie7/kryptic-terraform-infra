az acr login --name krypticRegistry1
docker pull mdulearning/krypticthadonbeats:v1
docker tag mdulearning/krypticthadonbeats:v1 krypticRegistry1.azurecr.io/krypticthadonbeats
docker push krypticRegistry1.azurecr.io/krypticthadonbeats

