## Install Kubernetes Cluster on LXD Container

### Installation
In this setup I'm using [containerd](https://github.com/containerd/containerd) as CRI and [Flannel](https://github.com/flannel-io/flannel) as CNI.
- Install LXD and Clone this Repo
- Use `kubelxc` to provision and manage the cluster
```sh
Usage: kubelxc [provision | destroy | start | stop]
```
- `kubelxc provision` to provision the cluster. 
> By default this will only provision Master node and a single Worker node. \
> Edit `kubelxc` file and add worker nodes to this variable `NODES="kmaster kworker1"`.\
> The Master node name should be `kmaster`.
