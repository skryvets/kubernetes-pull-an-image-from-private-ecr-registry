#!/usr/bin/env bash

kube_namespaces=($(kubectl get secret --all-namespaces | grep regcred | awk '{print $1}'))
for i in "${kube_namespaces[@]}"
do
   :
   echo "$(date): Updating secret for namespace - $i"
   kubectl delete secret regcred --namespace $i
   kubectl create secret docker-registry regcred \
   --docker-server=${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com \
   --docker-username=AWS \
   --docker-password=$(/usr/local/bin/aws ecr get-login-password) \
   --namespace=$i
done