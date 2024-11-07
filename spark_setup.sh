
# Install Spark in dicrectory /home/opt/
sudo wget https://dlcdn.apache.org/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz
sudo tar zxvf spark-3.5.3-bin-hadoop3.tgz
sudo mv spark-3.5.3-bin-hadoop3 spark
# Build docker imager from opt/spark/bin/docker-image-tool.sh
./docker-image-tool.sh -t spark-k8s build  
# Tag the local image to the remote image Repo + Push to the public image repo
sudo docker login -u "myusername" -p "mypassword" docker.io
sudo docker tag spark:spark-k8s mysilvercloud/spark-k8s:tagname                                                                                                                      <aws:Anh> <region:eu-central-1>
sudo docker push mysilvercloud/spark-k8s:tagname
# Add Path so LINUX can run command
export PATH=$PATH:/opt/spark/bin
############################################################################################################################



# Install JAVA
sudo apt install -y default-jre
############################################################################################################################



# Create Service Account and Cluster Role Binding to the Service Account
kubectl create serviceaccount <name>
kubectl create clusterrolebinding <role-name> --clusterrole=edit --serviceaccount=default:<name-of-service-acc> --namespace=<namespace name ie. = default>
# Or create YAML files then run kubectl apply -f <filename> to create Service Account, Cluster Role & Cluster Role Binding
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spark
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: spark-cluster-role
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: spark-cluster-role-binding
subjects:
- kind: ServiceAccount
  name: spark
  namespace: default
roleRef:
  kind: ClusterRole
  name: spark-cluster-role
  apiGroup: rbac.authorization.k8s.io
# New Kubernetes version doesn't generate token when create Service Account
# We need to create a Secret, then attach the Secret to the Service Account via YAML file
apiVersion: v1
kind: Secret
metadata:
  name: spark-token
  annotations:
    kubernetes.io/service-account.name: "spark"
type: kubernetes.io/service-account-token
############################################################################################################################




# Run Spark
  spark-submit --name spark-pi \
  --master k8s://https://10.0.1.105:6443  \
  --deploy-mode cluster \
  --class org.apache.spark.examples.SparkPi \
  --conf spark.kubernetes.driver.pod.name=sparkdriver \
  --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
  --conf spark.kubernetes.namespace=default \
  --conf spark.executor.instances=2 \
  --conf spark.kubernetes.container.image=mysilvercloud/spark-k8s:spark5 \
  --conf spark.kubernetes.driver.container.image=mysilvercloud/spark-k8s:spark5 \
  --conf spark.kubernetes.container.image.pullPolicy=Always \
  --conf spark.kubernetes.client.timeout=600 \
  --conf spark.kubernetes.client.connection.timeout=600 \
  --conf spark.driver.memory=2g \
  --conf spark.kubernetes.authenticate.submission.oauthTokenFile=/var/run/secrets/kubernetes.io/serviceaccount/token \
  --conf spark.kubernetes.authenticate.subdmission.caCertFile=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  --conf spark.jars.ivy="/tmp" \
  local:/opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar 1000
############################################################################################################################