## Install Kubernetes Cluster on LXD Container

### Installation
In this setup I'm using [containerd](https://github.com/containerd/containerd) as CRI and [Flannel](https://github.com/flannel-io/flannel) as CNI.
- [Install LXD](https://linuxcontainers.org/lxd/getting-started-cli/) and configure the LXD Daemon using `lxd init`.
```sh
:~# lxd init
Would you like to use LXD clustering? (yes/no) [default=no]: 
Do you want to configure a new storage pool? (yes/no) [default=yes]: 
Name of the new storage pool [default=default]: 
Name of the storage backend to use (btrfs, dir, lvm) [default=btrfs]: dir
Would you like to connect to a MAAS server? (yes/no) [default=no]: 
Would you like to create a new local network bridge? (yes/no) [default=yes]: 
What should the new bridge be called? [default=lxdbr0]: 
What IPv4 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: 
What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: 
Would you like LXD to be available over the network? (yes/no) [default=no]: 
Would you like stale cached images to be updated automatically? (yes/no) [default=yes] 
Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]:
```
> **Note :-** Choose option `dir` for LXD storage backend and leave other options as default.
- Clone this repo and use `kubelxc` to provision and manage the cluster
```sh
Usage: kubelxc [provision | destroy | start | stop]
```
- `kubelxc provision` to provision the cluster. 
> By default this will only provision Master node and a single Worker node. \
> Edit `kubelxc` file and add worker nodes to this variable `NODES="kmaster kworker1"`.\
> The Master node name should be `kmaster`.
