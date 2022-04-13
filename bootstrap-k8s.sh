#!/bin/bash    

echo "[TASK 1] Install containerd runtime"
apt update -qq >/dev/null 2>&1
apt install -qq -y containerd apt-transport-https >/dev/null 2>&1
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd >/dev/null 2>&1

# Add yum repo file for Kubernetes
echo "[TASK 2] Add apt repo file for kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - >/dev/null 2>&1
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/dev/null 2>&1

# Install Kubernetes
echo "[TASK 3] Install Kubernetes (kubeadm, kubelet and kubectl)"
apt update -qq >/dev/null 2>&1
apt install -y kubelet kubeadm kubectl >/dev/null 2>&1
apt-mark hold kubelet kubeadm kubectl >/dev/null 2>&1

# Start and Enable kubelet service
echo "[TASK 4] Enable and start kubelet service"
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/default/kubelet
systemctl enable --now kubelet >/dev/null 2>&1

# Install additional required packages
echo "[TASK 5] Install additional packages"
apt install -y -q net-tools sudo sshpass less >/dev/null 2>&1

# Hack required to provision K8s v1.15+ in LXC containers
echo "[TASK 6] Patch to provision K8s v1.15+ in LXC containers"
mknod /dev/kmsg c 1 11

# Make the above settings persistent
[[ -f /etc/rc.local ]] && echo "mknod /dev/kmsg c 1 11" >> /etc/rc.local || cat > /etc/rc.local <<'EOF' 
#!/bin/bash
mknod /dev/kmsg c 1 11
EOF
chmod +x /etc/rc.local

#######################################
# To be executed only on master nodes #
#######################################

if [[ $(hostname) =~ .*master*.* ]]
then
  # Set Root password
  echo "[TASK 7] Set root password"
  ( echo "root123";echo "root123" ) | passwd root >/dev/null 2>&1
  # Install Openssh server
  echo "[TASK 8] Install and configure ssh"
  apt install -y -q openssh-server >/dev/null 2>&1
  sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
  sed -i '/^#PermitRootLogin.*/a PermitRootLogin yes' /etc/ssh/sshd_config
  systemctl restart sshd
  
  # Initialize Kubernetes
  echo "[TASK 9] Initialize Kubernetes Cluster"
  kubeadm init --pod-network-cidr=10.20.0.0/16 --ignore-preflight-errors=all >> /root/kubeinit.log 2>&1
  
  # Copy Kube admin config
  echo "[TASK 10] Copy kube admin config to root user .kube directory"
  mkdir /root/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config
  echo 'source <(kubectl completion bash)' >>~/.bashrc

  # Deploy flannel network
  echo "[TASK 11] Deploy flannel network"
  wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -q -O /tmp/kube-flannel.yml
  sed -i 's|10.244.0.0/16|10.20.0.0/16|g' /tmp/kube-flannel.yml
  kubectl apply -f /tmp/kube-flannel.yml > /dev/null 2>&1

  # Generate Cluster join command
  echo "[TASK 12] Generate and save cluster join command to /joincluster.sh"
  joinCommand=$(kubeadm token create --print-join-command 2>/dev/null) 
  echo "$joinCommand --ignore-preflight-errors=all" > /joincluster.sh

fi

#######################################
# To be executed only on worker nodes #
#######################################

if [[ $(hostname) =~ .*worker*.* ]]
then
  # Join worker nodes to the Kubernetes cluster
  echo "[TASK 7] Join node to Kubernetes Cluster"
  sshpass -p "root123" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster:/joincluster.sh /joincluster.sh 2>/tmp/joincluster.log
  bash /joincluster.sh >> /tmp/joincluster.log 2>&1

fi

# To Fix disk pressure taint issue
echo "[Final Task] Fixing Disk Pressure Taint Issue"
cat <<EOF >> /var/lib/kubelet/config.yaml
eviction-hard:
  memory.available<100Mi
  nodefs.available<1%
  nodefs.inodesFree<1%
  imagefs.available<1%
  imagefs.inodesFree<1%
EOF
systemctl restart kubelet
