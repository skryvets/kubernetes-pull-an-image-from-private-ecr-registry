# Publish image to ECR

- Step 1. Build an image:

      docker build -t nodejs-hello-world-app .
      
- Step 2(Optional). Run locally if you need to:

      docker run -p 3000:3000 nodejs-hello-world-app

- Step 3. Authorize with AWS ECR:

      aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com

- Step 4. Tag your image with AWS ECR registry:

      docker images # shows image ids

      docker tag ${DOCKER_IMAGE_ID} ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-repository:tag

- Step 4. Push the image using the docker push command:

      docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-repository:tag


# Refresh ECR token

## First approach (using host os script):

```bash
# Create a log file that cron job will output to
sudo touch /var/log/aws-ecr-update-credentials.log

# Make a current user owner of the file so that cronjob running under his/its account can write to it
sudo chown $USER /var/log/aws-ecr-update-credentials.log

# Create an empty file where the script would reside
sudo touch /usr/local/bin/aws-ecr-update-credentials.sh

# Allow cronjob to execute the script under the user
sudo chown $USER /usr/local/bin/aws-ecr-update-credentials.sh\

# Make the script executable
sudo chmod +x /usr/local/bin/aws-ecr-update-credentials.sh 
```

### Add the script to the recently created `/usr/local/bin/aws-ecr-update-credentials.sh` file:

```bash
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
```
Don't forget to replace `${AWS_ACCOUNT}` and `${AWS_REGION}` with corresponding values or add these as an environment variables.


### Last step - add cronjob

```bash
#open crontab file
crontab -e

#job
0 */10 * * * /usr/local/bin/aws-ecr-update-credentials.sh >> /var/log/aws-ecr-update-credentials.log 2>&1

```

## Second approach (using k8s CronJob resource):

```bash
# In the git repo navigate to the folder below
cd ecr-token-refresh/2-k8s-cron-job
cp manifest-ecr-helper-creds-sample.yml manifest-ecr-helper-creds.yml

# Fill out all the required variables in manifest-ecr-helper-creds.yml and then deploy using commands below

kubectl apply -f manifest-ecr-helper-creds.yml
kubectl apply -f manifest-ecr-helper.yml
```

