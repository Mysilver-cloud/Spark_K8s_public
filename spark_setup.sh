
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


ERROR Message:

++ id -u
+ myuid=185
++ id -g
+ mygid=185
+ set +e
++ getent passwd 185
+ uidentry=sparkuser:x:185:185:,,,:/home/sparkuser:/bin/bash
+ set -e
+ '[' -z sparkuser:x:185:185:,,,:/home/sparkuser:/bin/bash ']'
+ '[' -z /opt/java/openjdk ']'
+ SPARK_CLASSPATH=':/opt/spark/jars/*'
+ env
+ grep SPARK_JAVA_OPT_
+ sort -t_ -k4 -n
+ sed 's/[^=]*=\(.*\)/\1/g'
++ command -v readarray
+ '[' readarray ']'
+ readarray -t SPARK_EXECUTOR_JAVA_OPTS
+ '[' -n '' ']'
+ '[' -z ']'
+ '[' -z ']'
+ '[' -n '' ']'
+ '[' -z ']'
+ '[' -z x ']'
+ SPARK_CLASSPATH='/opt/spark/conf::/opt/spark/jars/*'
+ SPARK_CLASSPATH='/opt/spark/conf::/opt/spark/jars/*:/opt/spark/work-dir'
+ case "$1" in
+ shift 1
+ CMD=("$SPARK_HOME/bin/spark-submit" --conf "spark.driver.bindAddress=$SPARK_DRIVER_BIND_ADDRESS" --conf "spark.executorEnv.SPARK_DRIVER_POD_IP=$SPARK_DRIVER_BIND_ADDRESS" --deploy-mode client "$@")
+ exec /usr/bin/tini -s -- /opt/spark/bin/spark-submit --conf spark.driver.bindAddress=192.168.78.208 --conf spark.executorEnv.SPARK_DRIVER_POD_IP=192.168.78.208 --deploy-mode client --properties-file /opt/spark/conf/spark.properties --class org.apache.spark.examples.SparkPi local:/opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar 1000
Files local:/opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar from /opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar to /opt/spark/work-dir/spark-examples_2.12-3.5.3.jar
24/11/06 14:48:04 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
24/11/06 14:48:04 INFO SparkContext: Running Spark version 3.5.3
24/11/06 14:48:04 INFO SparkContext: OS info Linux, 6.8.0-1012-aws, amd64
24/11/06 14:48:04 INFO SparkContext: Java version 17.0.13
24/11/06 14:48:04 INFO ResourceUtils: ==============================================================
24/11/06 14:48:04 INFO ResourceUtils: No custom resources configured for spark.driver.
24/11/06 14:48:04 INFO ResourceUtils: ==============================================================
24/11/06 14:48:04 INFO SparkContext: Submitted application: Spark Pi
24/11/06 14:48:04 INFO ResourceProfile: Default ResourceProfile created, executor resources: Map(cores -> name: cores, amount: 1, script: , vendor: , memory -> name: memory, amount: 1024, script: , vendor: , offHeap -> name: offHeap, amount: 0, script: , vendor: ), task resources: Map(cpus -> name: cpus, amount: 1.0)
24/11/06 14:48:04 INFO ResourceProfile: Limiting resource is cpus at 1 tasks per executor
24/11/06 14:48:04 INFO ResourceProfileManager: Added ResourceProfile id: 0
24/11/06 14:48:04 INFO SecurityManager: Changing view acls to: sparkuser
24/11/06 14:48:04 INFO SecurityManager: Changing modify acls to: sparkuser
24/11/06 14:48:04 INFO SecurityManager: Changing view acls groups to: 
24/11/06 14:48:04 INFO SecurityManager: Changing modify acls groups to: 
24/11/06 14:48:04 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users with view permissions: sparkuser; groups with view permissions: EMPTY; users with modify permissions: sparkuser; groups with modify permissions: EMPTY
24/11/06 14:48:04 INFO Utils: Successfully started service 'sparkDriver' on port 7078.
24/11/06 14:48:04 INFO SparkEnv: Registering MapOutputTracker
24/11/06 14:48:04 INFO SparkEnv: Registering BlockManagerMaster
24/11/06 14:48:04 INFO BlockManagerMasterEndpoint: Using org.apache.spark.storage.DefaultTopologyMapper for getting topology information
24/11/06 14:48:04 INFO BlockManagerMasterEndpoint: BlockManagerMasterEndpoint up
24/11/06 14:48:04 INFO SparkEnv: Registering BlockManagerMasterHeartbeat
24/11/06 14:48:04 INFO DiskBlockManager: Created local directory at /var/data/spark-23a649d3-1f8b-4c51-8778-685b9417add0/blockmgr-6f02ca41-dfaf-4e0f-a6eb-06b943ddf7df
24/11/06 14:48:05 INFO MemoryStore: MemoryStore started with capacity 1048.8 MiB
24/11/06 14:48:05 INFO SparkEnv: Registering OutputCommitCoordinator
24/11/06 14:48:05 INFO JettyUtils: Start Jetty 0.0.0.0:4040 for SparkUI
24/11/06 14:48:05 INFO Utils: Successfully started service 'SparkUI' on port 4040.
24/11/06 14:48:05 INFO SparkContext: Added JAR local:/opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar at file:/opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar with timestamp 1730904484407
24/11/06 14:48:05 WARN SparkContext: The JAR local:/opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar at file:/opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar has been added already. Overwriting of added jar is not supported in the current version.
24/11/06 14:48:05 INFO SparkKubernetesClientFactory: Auto-configuring K8S client using current context from users K8S config file
24/11/06 14:48:20 ERROR SparkContext: Error initializing SparkContext.
org.apache.spark.SparkException: External scheduler cannot be instantiated
        at org.apache.spark.SparkContext$.org$apache$spark$SparkContext$$createTaskScheduler(SparkContext.scala:3204)
        at org.apache.spark.SparkContext.<init>(SparkContext.scala:577)
        at org.apache.spark.SparkContext$.getOrCreate(SparkContext.scala:2883)
        at org.apache.spark.sql.SparkSession$Builder.$anonfun$getOrCreate$2(SparkSession.scala:1099)
        at scala.Option.getOrElse(Option.scala:189)
        at org.apache.spark.sql.SparkSession$Builder.getOrCreate(SparkSession.scala:1093)
        at org.apache.spark.examples.SparkPi$.main(SparkPi.scala:30)
        at org.apache.spark.examples.SparkPi.main(SparkPi.scala)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:77)
        at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.base/java.lang.reflect.Method.invoke(Method.java:569)
        at org.apache.spark.deploy.JavaMainApplication.start(SparkApplication.scala:52)
        at org.apache.spark.deploy.SparkSubmit.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:1029)
        at org.apache.spark.deploy.SparkSubmit.doRunMain$1(SparkSubmit.scala:194)
        at org.apache.spark.deploy.SparkSubmit.submit(SparkSubmit.scala:217)
        at org.apache.spark.deploy.SparkSubmit.doSubmit(SparkSubmit.scala:91)
        at org.apache.spark.deploy.SparkSubmit$$anon$2.doSubmit(SparkSubmit.scala:1120)
        at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:1129)
        at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
Caused by: java.lang.reflect.InvocationTargetException
        at java.base/jdk.internal.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
        at java.base/jdk.internal.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:77)
        at java.base/jdk.internal.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
        at java.base/java.lang.reflect.Constructor.newInstanceWithCaller(Constructor.java:500)
        at java.base/java.lang.reflect.Constructor.newInstance(Constructor.java:481)
        at org.apache.spark.scheduler.cluster.k8s.KubernetesClusterManager.makeExecutorPodsAllocator(KubernetesClusterManager.scala:179)
        at org.apache.spark.scheduler.cluster.k8s.KubernetesClusterManager.createSchedulerBackend(KubernetesClusterManager.scala:133)
        at org.apache.spark.SparkContext$.org$apache$spark$SparkContext$$createTaskScheduler(SparkContext.scala:3198)
        ... 19 more
Caused by: io.fabric8.kubernetes.client.KubernetesClientException
        at io.fabric8.kubernetes.client.dsl.internal.OperationSupport.waitForResult(OperationSupport.java:520)
        at io.fabric8.kubernetes.client.dsl.internal.OperationSupport.handleResponse(OperationSupport.java:535)
        at io.fabric8.kubernetes.client.dsl.internal.OperationSupport.handleGet(OperationSupport.java:478)
        at io.fabric8.kubernetes.client.dsl.internal.BaseOperation.handleGet(BaseOperation.java:741)
        at io.fabric8.kubernetes.client.dsl.internal.BaseOperation.requireFromServer(BaseOperation.java:185)
        at io.fabric8.kubernetes.client.dsl.internal.BaseOperation.get(BaseOperation.java:141)
        at io.fabric8.kubernetes.client.dsl.internal.BaseOperation.get(BaseOperation.java:92)
        at org.apache.spark.scheduler.cluster.k8s.ExecutorPodsAllocator.$anonfun$driverPod$1(ExecutorPodsAllocator.scala:96)
        at scala.Option.map(Option.scala:230)
        at org.apache.spark.scheduler.cluster.k8s.ExecutorPodsAllocator.<init>(ExecutorPodsAllocator.scala:94)
        ... 27 more
Caused by: java.util.concurrent.TimeoutException
        at io.fabric8.kubernetes.client.utils.AsyncUtils.lambda$withTimeout$0(AsyncUtils.java:42)
        at io.fabric8.kubernetes.client.utils.Utils.lambda$schedule$6(Utils.java:473)
        at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:539)
        at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
        at java.base/java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:304)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635)
        at java.base/java.lang.Thread.run(Thread.java:840)
24/11/06 14:48:20 INFO SparkContext: SparkContext is stopping with exitCode 0.
24/11/06 14:48:20 INFO SparkUI: Stopped Spark web UI at http://spark-pi-bff2ac9301f25229-driver-svc.default.svc:4040
24/11/06 14:48:20 INFO MapOutputTrackerMasterEndpoint: MapOutputTrackerMasterEndpoint stopped!
24/11/06 14:48:21 INFO MemoryStore: MemoryStore cleared
24/11/06 14:48:21 INFO BlockManager: BlockManager stopped
24/11/06 14:48:21 INFO BlockManagerMaster: BlockManagerMaster stopped
24/11/06 14:48:21 WARN MetricsSystem: Stopping a MetricsSystem that is not running
24/11/06 14:48:21 INFO OutputCommitCoordinator$OutputCommitCoordinatorEndpoint: OutputCommitCoordinator stopped!
24/11/06 14:48:21 INFO SparkContext: Successfully stopped SparkContext
Exception in thread "main" org.apache.spark.SparkException: External scheduler cannot be instantiated
        at org.apache.spark.SparkContext$.org$apache$spark$SparkContext$$createTaskScheduler(SparkContext.scala:3204)
        at org.apache.spark.SparkContext.<init>(SparkContext.scala:577)
        at org.apache.spark.SparkContext$.getOrCreate(SparkContext.scala:2883)
        at org.apache.spark.sql.SparkSession$Builder.$anonfun$getOrCreate$2(SparkSession.scala:1099)
        at scala.Option.getOrElse(Option.scala:189)
        at org.apache.spark.sql.SparkSession$Builder.getOrCreate(SparkSession.scala:1093)
        at org.apache.spark.examples.SparkPi$.main(SparkPi.scala:30)
        at org.apache.spark.examples.SparkPi.main(SparkPi.scala)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:77)
        at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.base/java.lang.reflect.Method.invoke(Method.java:569)
        at org.apache.spark.deploy.JavaMainApplication.start(SparkApplication.scala:52)
        at org.apache.spark.deploy.SparkSubmit.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:1029)
        at org.apache.spark.deploy.SparkSubmit.doRunMain$1(SparkSubmit.scala:194)
        at org.apache.spark.deploy.SparkSubmit.submit(SparkSubmit.scala:217)
        at org.apache.spark.deploy.SparkSubmit.doSubmit(SparkSubmit.scala:91)
        at org.apache.spark.deploy.SparkSubmit$$anon$2.doSubmit(SparkSubmit.scala:1120)
        at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:1129)
        at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
Caused by: java.lang.reflect.InvocationTargetException
        at java.base/jdk.internal.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
        at java.base/jdk.internal.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:77)
        at java.base/jdk.internal.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
        at java.base/java.lang.reflect.Constructor.newInstanceWithCaller(Constructor.java:500)
        at java.base/java.lang.reflect.Constructor.newInstance(Constructor.java:481)
        at org.apache.spark.scheduler.cluster.k8s.KubernetesClusterManager.makeExecutorPodsAllocator(KubernetesClusterManager.scala:179)
        at org.apache.spark.scheduler.cluster.k8s.KubernetesClusterManager.createSchedulerBackend(KubernetesClusterManager.scala:133)
        at org.apache.spark.SparkContext$.org$apache$spark$SparkContext$$createTaskScheduler(SparkContext.scala:3198)
        ... 19 more
Caused by: io.fabric8.kubernetes.client.KubernetesClientException
        at io.fabric8.kubernetes.client.dsl.internal.OperationSupport.waitForResult(OperationSupport.java:520)
        at io.fabric8.kubernetes.client.dsl.internal.OperationSupport.handleResponse(OperationSupport.java:535)
        at io.fabric8.kubernetes.client.dsl.internal.OperationSupport.handleGet(OperationSupport.java:478)
        at io.fabric8.kubernetes.client.dsl.internal.BaseOperation.handleGet(BaseOperation.java:741)
        at io.fabric8.kubernetes.client.dsl.internal.BaseOperation.requireFromServer(BaseOperation.java:185)
        at io.fabric8.kubernetes.client.dsl.internal.BaseOperation.get(BaseOperation.java:141)
        at io.fabric8.kubernetes.client.dsl.internal.BaseOperation.get(BaseOperation.java:92)
        at org.apache.spark.scheduler.cluster.k8s.ExecutorPodsAllocator.$anonfun$driverPod$1(ExecutorPodsAllocator.scala:96)
        at scala.Option.map(Option.scala:230)
        at org.apache.spark.scheduler.cluster.k8s.ExecutorPodsAllocator.<init>(ExecutorPodsAllocator.scala:94)
        ... 27 more
Caused by: java.util.concurrent.TimeoutException
        at io.fabric8.kubernetes.client.utils.AsyncUtils.lambda$withTimeout$0(AsyncUtils.java:42)
        at io.fabric8.kubernetes.client.utils.Utils.lambda$schedule$6(Utils.java:473)
        at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:539)
        at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
        at java.base/java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:304)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635)
        at java.base/java.lang.Thread.run(Thread.java:840)
24/11/06 14:48:21 INFO ShutdownHookManager: Shutdown hook called
24/11/06 14:48:21 INFO ShutdownHookManager: Deleting directory /var/data/spark-23a649d3-1f8b-4c51-8778-685b9417add0/spark-05066eb6-5d4d-4143-b3fd-e01e1f117694
24/11/06 14:48:21 INFO ShutdownHookManager: Deleting directory /tmp/spark-e2c183e9-c1c7-4928-b6a6-597d4a7d61ce