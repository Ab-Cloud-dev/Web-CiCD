## -----------------------------
## Update system & install tools
## -----------------------------
# Update package lists to fetch latest versions
sudo apt-get update -y
# Install required tools: apt-transport-https (for HTTPS repos), curl (for downloading files)
sudo apt install apt-transport-https curl -y


## -----------------------------
## Install containerd (container runtime)
## -----------------------------
# Add Docker GPG key for verifying downloads
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository (required for containerd package)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update apt repo index again to include Docker repo
sudo apt-get update
# Install containerd runtime
sudo apt-get install containerd.io -y


## -----------------------------
## Configure containerd
## -----------------------------
# Create containerd config directory
sudo mkdir -p /etc/containerd
# Generate default containerd configuration
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Switch containerd to use systemd cgroups (required by Kubernetes)
sudo sed -i -e 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd to apply changes
sudo systemctl restart containerd


## -----------------------------
## Install Kubernetes components
## -----------------------------
# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes apt repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt repo index with Kubernetes packages
sudo apt-get update
# Install kubelet (node agent), kubeadm (cluster setup tool), kubectl (K8s CLI)
sudo apt-get install -y kubelet kubeadm kubectl
# Prevent automatic updates that may break cluster compatibility
sudo apt-mark hold kubelet kubeadm kubectl
# Enable kubelet service at startup
sudo systemctl enable --now kubelet


## -----------------------------
## Kernel & Swap adjustments
## -----------------------------
# Disable swap (mandatory for Kubernetes)
sudo swapoff -a
# Load br_netfilter module (required for Kubernetes networking)
sudo modprobe br_netfilter
# Enable IP forwarding for networking between pods/nodes
sudo sysctl -w net.ipv4.ip_forward=1
