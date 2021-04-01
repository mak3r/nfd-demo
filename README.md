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

# Demo Setup

1. Install k3s and rancher

    * [Install Rancher](./scripts/rancher-install.sh)

1. Install k3s on turingpi devices

    * Options in my [turingpi](https://github.com/mak3r/turingpi) project
    * Basic Demo is easiest with [single cluster](https://github.com/mak3r/turingpi/scripts/cluster-1m6w.sh)
    * Gitops demo can be done with [seven clusters](https://github.com/mak3r/turingpi/scripts/cluster-7mw.sh)

1. Grab the latest NFD templates and update to use aarch64 images that work

    ```
    curl -sfL "https://raw.githubusercontent.com/kubernetes-sigs/node-feature-discovery/v0.8.0/nfd-master.yaml.template" -o nfd-master.yaml 
    sed -i "" 's/k8s.gcr.io\/nfd\/node-feature-discovery:v0.8.0/mak3r\/node-feature-discovery:v0.7.0/g' nfd-master.yaml
    curl -sfL "https://raw.githubusercontent.com/kubernetes-sigs/node-feature-discovery/v0.8.0/nfd-worker-daemonset.yaml.template" -o nfd-worker-daemonset.yaml
    sed -i "" 's/k8s.gcr.io\/nfd\/node-feature-discovery:v0.8.0/mak3r\/node-feature-discovery:v0.7.0/g' nfd-worker-daemonset.yaml
    ```

# Demo steps

1. **Start Recording**

	* `asciinema rec -i 2.5 nfd-demo.cast`
	* `clear`

1. Show nodes

	* `kubectl get node`

1. Capture basic label set for all nodes in a cluster using this script

	* `./scripts/get-labels.sh -d zero`
		* [./scripts/get-labels.sh](./scripts/get-labels.sh) -d zero
	* one file is created per node so we can diff the changes later
	* `cat ./zero/turingpi01.labels`


1. Install NFD

    ```
    kubectl apply -f k8s-config/nfd-master.yaml
    kubectl apply -f k8s-config/nfd-worker-daemonset.yaml
    ```

1. **Pause one minute for NFD labels to get applied**


1. Pull the labels again and check USB entries

    ```
    clear && \
    ./scripts/get-labels.sh -d one && \
    cat ./one/turingpi01.labels
    ```

1. Edit the configmap data

    * `kubectl edit configmap nfd-worker-conf -n node-feature-discovery`
    * Uncomment the following lines
        
        ```
        sources:
          usb:
            deviceClassWhitelist:
              - "03"
            deviceLabelFields:
              - "class"
              - "vendor"
              - "device"
        ```

1. **Pause one minute for NFD labels to get applied**

	
1. Pull the labels again and check USB entries

    ```
    clear && \
    ./scripts/get-labels.sh -d two && \
    for i in {1,2,3,4,5,7}; do \
      echo "==tp$i usb=="; \
      cat two/turingpi0$i.labels | grep usb; \
    done
    ```
    
1. **Pause one minute for NFD labels to get applied**
	
1. Pull the labels again and check USB entries

    ```
    clear && \
    ./scripts/get-labels.sh -d two && \
    for i in {1,2,3,4,5,7}; do \
      echo "==tp$i usb=="; \
      cat two/turingpi0$i.labels | grep usb; \
    done
    ```
 
 1. Edit the configmap to add a custom feature

	* `kubectl edit configmap nfd-worker-conf -n node-feature-discovery`
    
    ```
    custom:
      - name: "i2c-power-management"
        matchOn:
          - loadedKMod: ["i2c_dev", "i2c_bcm2835"]
    ```

1. Pull the labels again and check I2C entries

    ```
    clear && \
    ./scripts/get-labels.sh -d three && \
    for i in {1,2,3,4,5,7}; do \
      echo "==tp$i usb,i2c=="; \
      cat three/turingpi0$i.labels | grep usb; \
      cat three/turingpi0$i.labels | grep i2c; \
    done
    ```

1. Show the local feature

	* `ssh tp1`
	
	```
    sudo mkdir -p /etc/kubernetes/node-feature-discovery/source.d
    cat <<- EOF > gpio
      #!/bin/sh 
      echo "gpio" 
      echo "gpio_40=INPUT" 
    EOF
    mv gpio /etc/kubernetes/node-feature-discovery/source.d/
    sudo chmod +x /etc/kubernetes/node-feature-discovery/source.d/gpio
    ```
    * exit

1. **Pause one minute for NFD labels to get applied**


1. Pull the labels again and check GPIO entries

    ```
    clear && \
    ./scripts/get-labels.sh -d four && \
    for i in {1,2,3,4,5,7}; do \
      echo "==tp$i usb,i2c,gpio=="; \
      cat four/turingpi0$i.labels | grep usb; \
      cat four/turingpi0$i.labels | grep i2c; \
      cat four/turingpi0$i.labels | grep gpio; \
    done
    ```

1. **Pause one minute for NFD labels to get applied**

    
# Demo Teardown

1. Remove NFD

	```
	kubectl delete -f k8s-config/nfd-master.yaml
	kubectl delete -f k8s-config/nfd-worker-daemonset.yaml
	kubectl get all -n node-feature-discovery
	kubectl delete ns node-feature-discovery
	```
	
1. Remove node labels

	```
	./scripts/delete-labels.sh
	rm -rf zero one two three four
	```
	
1. Cleanup local feature on node 1

	```
	ssh tp1
	sudo rm /etc/kubernetes/node-feature-discovery/source.d/gpio
	exit
	```


# Utility

## Pull the configmap data 

* `kubectl get configmap nfd-worker-conf -n node-feature-discovery -o jsonpath='{.data.nfd-worker\.conf}'`