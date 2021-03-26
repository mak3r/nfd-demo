## Demo Prep

From the Device Plugin Framework k8s docs:
You can deploy a device plugin as a DaemonSet, as a package for your node's operating system, or manually.
...
If you choose the DaemonSet approach you can rely on Kubernetes to: place the device plugin's Pod onto Nodes, to restart the daemon Pod after failure, and to help automate upgrades.
...
Kubernetes device plugin support is in beta. The API may change before stabilization, in incompatible ways.

* Annotations Before NFD Install *

      beta.kubernetes.io/arch: arm64
      beta.kubernetes.io/instance-type: k3s
      beta.kubernetes.io/os: linux
      k3s.io/hostname: turingpi-ctl
      k3s.io/internal-ip: 192.168.8.209
      kubernetes.io/arch: arm64
      kubernetes.io/hostname: turingpi-ctl
      kubernetes.io/os: linux
      node-role.kubernetes.io/master: "true"
      node.kubernetes.io/instance-type: k3s

* Annotations After NFD Install *

??


One of the pitfalls of this solution is that a misconfigured kernel may offer non-existent features
for example 
searching on loaded i2c module rtc_ds1307 
`lsmod | grep i2c`
shows it to be available but in fact, it was loaded as part of OS imaging
`cat /etc/modules`
`sudo modprobe rtc_ds1307`
but the image doesn't apply to this device

Can I detect gpio
Yes, use gpiodetect in suse packages

## Install gpio and i2c tooling
zypper in libgpiod i2c-tools

# DEMO PREP

1. Install k3s and rancher

    * [Install script for SLES](./scripts/rancher-install.sh)

1. Install k3s on turingpi devices

    * Options in my [turingpi](https://github.com/mak3r/turingpi) project

1. Capture label set for all nodes in a cluster using this script

    * [get-labels.sh](./scripts/get-labels.sh) -d zero
    * one file is create per node so we can diff the changes later

1. Grab the latest NFD templates and update to use aarch64 images that work

    ```
    curl -sfL "https://raw.githubusercontent.com/kubernetes-sigs/node-feature-discovery/v0.8.0/nfd-master.yaml.template" -o nfd-master.yaml 
    sed -i "" 's/k8s.gcr.io\/nfd\/node-feature-discovery:v0.8.0/mak3r\/node-feature-discovery:v0.7.0/g' nfd-master.yaml
    curl -sfL "https://raw.githubusercontent.com/kubernetes-sigs/node-feature-discovery/v0.8.0/nfd-worker-daemonset.yaml.template" -o nfd-worker-daemonset.yaml
    sed -i "" 's/k8s.gcr.io\/nfd\/node-feature-discovery:v0.8.0/mak3r\/node-feature-discovery:v0.7.0/g' nfd-worker-daemonset.yaml
    ```

1. Install NFD

    ```
    kubectl apply -f nfd-master.yaml
    kubectl apply -f nfd-worker-daemonset.yaml
    ```

1. Pull the labels again

    * [get-labels.sh](./scripts/get-labels.sh) -d one

1. Look at the USB entry

    * `for i in {1,2,3,4,5,7}; do echo "==tp$i usb=="; cat one/turingpi0$i.labels | grep usb; done | less`

1. Pull down the configmap

