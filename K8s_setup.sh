# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sysctl net.ipv4.ip_forward
# END
############################################################################################################################




## Container Runtime
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# To install the latest version, run:
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# This version above, will install containerd.io, which contains RunC already, but NOT CNI plugins

# Verify that the Docker Engine installation is successful by running the hello-world image.
sudo docker run hello-world

# If you intend to start containerd via systemd or
# your linux uses cgroup V2, then use systemD
# Check which cgroup version your system uses:
stat -fc %T /sys/fs/cgroup/
# Run systemd
# Create a file containerd.service
# navigate to /usr/local/lib/systemd/system/ and run
sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

# then run this:
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# if it ask for password, run:
sudo -i
passwd ubuntu

# Enable CRI plugin for containerD. Enter this line into /etc/containerd/config.toml
enabled_plugins = ["cri"]
[plugins."io.containerd.grpc.v1.cri".containerd]
  endpoint = "unix:///var/run/containerd/containerd.sock"

# Then restart containerD
sudo systemctl restart containerd
# Generate default containerd config from containerd binary to config.toml << This might cause ERROR
sudo containerd config default | sudo tee /etc/containerd/config.toml # You might need to create the directory if not exist
# check the content of the file 
# Look for the line with SystemdCgroup, if value is false, set to true.
sudo cat /etc/containerd/config.toml  

# checks whether the containerd service is currently active via systemd
sudo systemctl is-active containerd.service
# If not run this to activate containerd:
sudo systemctl enable containerd.service
sudo systemctl start containerd.service
# check status of containerD via systemd
sudo systemctl status containerd.service
## End of Container Runtime
############################################################################################################################




## Disable Swap 
# K8s recommend to disable swap, a virtual RAM which use Hard Disk memory as RAM:
# first check if any swap is running:
swapon --show

# If it shows anything
# Locate the line in the "/etc/fstab" file that specifies the swap partition. 
# This line will include the word "swap" and the device file path for the swap partition.
# Example: # /dev/sda3  none  swap  sw  0  0

# Reboot the system to take effect
sudo reboot

# Check if swap is disable, it should shows nothing:
swapon --show
## End of SWAP
############################################################################################################################




## CRICTL
# Install Crictl (comman line tool for container)
VERSION="v1.31.1"
sudo wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
sudo rm -f crictl-$VERSION-linux-amd64.tar.gz

# Install critest: validation test suites for kubelet CRI.
VERSION="v1.31.1"
sudo wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/critest-$VERSION-linux-amd64.tar.gz
sudo tar zxvf critest-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
sudo rm -f critest-$VERSION-linux-amd64.tar.gz

# Create a Crictl.yaml.  is used to configure crictl 
# so you don't have to repeatedly specify the runtime sock used to connect crictl to the container runtime:
# For Dockerd Sock: 
sudo vim /etc/crictl.yaml
# Enter the codes below to Vim
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: true
## END OF CRICTL
############################################################################################################################




## Nerdctl, command line for Docker
# first install BREW
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# ==> Next steps:
# - Run these commands in your terminal to add Homebrew to your PATH:
    echo >> /home/ubuntu/.bashrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/ubuntu/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# - Install Homebrew's dependencies if you have sudo access:
    sudo apt-get install -y build-essential
#  For more information, see:
    https://docs.brew.sh/Homebrew-on-Linux
# - We recommend that you install GCC:
    brew install gcc
# - Run brew help to get started
# - Further documentation:
    https://docs.brew.sh
# then install Nerdctl
brew install nerdctl
# NOTE: installing Nerdctl causing ubuntu not recognize the path of of Nerdctl binary
# the result is you can't run sudo, while Nerdctl require sudo or install rootless set up tool
# to solve that, export to the path where Nerdctl binary is installed in Brew
export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin/nerdctl
# run sudo
sudo /home/linuxbrew/.linuxbrew/bin/nerdctl info
## END OF NERDCTL
############################################################################################################################




## Install K8s: Kubeadm, Kubectl, Kubelet
# Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# (Optional) Enable the kubelet service before running kubeadm:
sudo systemctl enable --now kubelet
## END OF K8S
############################################################################################################################




## SET SYSTEMD CGROUP for Kubelet: RUN ON MASTER NODE
# This KubeletConfiguration can include the cgroupDriver field which controls the cgroup driver of the kubelet.
kubeadm version
# If have older kubeadm, follow these steps:
sudo vim /etc/kubernetes/manifests/config.yaml # might need to create a directory if doesn't exist
# copy this to Vim file:
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta4
kubernetesVersion: v1.31.0
networking:
  podSubnet: "192.168.0.0/16"
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd

# run this to apply the config.yaml
sudo kubeadm init --config /etc/kubernetes/manifests/config.yaml

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$(HOME)/.kube/config

# you can reset then init again to check if kubeadm is working properly with container runtime
sudo kubeadm reset
sudo kubeadm init
## END OF SYSTEMD CGROUP for Kubelet
############################################################################################################################




## CNI Calico: ONLY MASTER NODE
# Install the Tigera Calico operator and custom resource definitions.
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml

watch kubectl get pods -n calico-system
# Remove the taints on the control plane so that you can schedule pods on it.
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
# It should return the following.
node/<your-hostname> untainted
# Confirm that you now have a node in your cluster with the following command.
kubectl get nodes -o wide
# It should return something like the following.
NAME              STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
<your-hostname>   Ready    master   52m   v1.12.2   10.128.0.28   <none>        Ubuntu 18.04.1 LTS   4.15.0-1023-gcp   docker://18.6.1

# Install calicoctl command line tool for Calico:
# Consider navigating to a location that's in your PATH. For example, /usr/local/bin/.
sudo cd /usr/local/bin/
sudo curl -L https://github.com/projectcalico/calico/releases/download/v3.28.2/calicoctl-linux-amd64 -o calicoctl
sudo chmod +x ./calicoctl

# Install calicoctl command line tool for Calico:

# Example of ENV 
export DATASTORE_TYPE=kubernetes
calicoctl get workloadendpoints