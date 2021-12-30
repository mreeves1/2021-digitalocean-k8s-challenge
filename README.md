# 2021-digitalocean-k8s-challenge
See https://www.digitalocean.com/community/pages/kubernetes-challenge

I'm going to use terraform to create and manage the K8s cluster where possible.

## Prerequisites

Install and setup various things needed to create and manage the Digital Ocean Kubernetes Cluster.
These instructions are for windows but should be similar for other OSes.

1. [Create a Digital Ocean personal access token (PAT)](https://cloud.digitalocean.com/account/api/tokens/new)
1. Save this to the user's environment variables as TF_VAR_DIGITALOCEAN_TOKEN
1. Open a new powershell and run this to verify:  
   `echo $Env:TF_VAR_DIGITALOCEAN_TOKEN`
1. Install the following with [Chocolatey](https://chocolatey.org/)  
   ```
   $ choco install doctl
   $ choco install kubernetes-cli
   $ choco install kubernetes-helm
   $ choco install lens
   $ choco install terraform
   ```
1. Authenticate the digital ocean cli tool
   ```
   $ doctl auth init # Use the PAT you created above
   ``` 

## Create and Connect to the Kubernetes Cluster
1. [Create a VPC in sf03 named sfo3-vpc-01](https://cloud.digitalocean.com/networking/vpc)
   Obviously you can modify this but not all regions are available for kubernetes
   ```
   $ doctl kubernetes options regions
   Slug    Name
   nyc1    New York 1
   sgp1    Singapore 1
   lon1    London 1
   nyc3    New York 3
   ams3    Amsterdam 3
   fra1    Frankfurt 1
   tor1    Toronto 1
   blr1    Bangalore 1
   sfo3    San Francisco 3
   ```
1. Create the cluster with Terraform
   ```
   $ cd tf
   $ terraform init
   $ terraform plan -out plan.out
   $ terraform apply plan.out
   # Wait for ~ 5 minutes and note the "Creation complete" output so you know your k8s cluster ID:
   # Example: digitalocean_kubernetes_cluster.dev-01: Creation complete after 5m23s [id=abcd1234-abcd-1234-abcd-abcdef123456]
1. Set up kubeconfig so you can talk to the k8s cluster
   ```
   $ doctl kubernetes cluster kubeconfig save abcd1234-abcd-1234-abcd-abcdef123456
   Notice: Adding cluster credentials to kubeconfig file found in "C:\\Users\\mreeves1\\.kube\\config"
   Notice: Setting current-context to do-sfo3-dev-01
   ```
1. Run a few commands to verify things are working
   ``` 
   $ kubectl get nodes
   NAME            STATUS   ROLES    AGE   VERSION
   default-abc123   Ready    <none>   38m   v1.20.11
   default-def456   Ready    <none>   38m   v1.20.11
   
   kubectl get pods -A
   NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
   kube-system   cilium-bdzhj                       1/1     Running   0          39m
   kube-system   cilium-mfqld                       1/1     Running   0          39m
   kube-system   cilium-operator-7fd9d7b9dc-mt7gj   1/1     Running   0          41m
   kube-system   coredns-57877dc48d-9ns8z           1/1     Running   0          41m
   kube-system   coredns-57877dc48d-qxnvm           1/1     Running   0          41m
   kube-system   csi-do-node-8dvtk                  2/2     Running   0          39m
   kube-system   csi-do-node-jsnmv                  2/2     Running   0          39m
   kube-system   do-node-agent-fbvvh                1/1     Running   0          39m
   kube-system   do-node-agent-vmfqx                1/1     Running   0          39m
   kube-system   kube-proxy-2tqxf                   1/1     Running   0          39m
   kube-system   kube-proxy-fsfvv                   1/1     Running   0          39m
   ```

## Install Falco

They suggest you [install falco on the host nodes](https://falco.org/docs/getting-started/installation/) 
but we want to install on the k8s cluster as a [daemonset](https://falco.org/docs/getting-started/deployment/)
using [helm](https://github.com/falcosecurity/charts/tree/master/falco).

```
$ kubectl create ns falco-system
$ helm repo add falcosecurity https://falcosecurity.github.io/charts
$ helm repo update
$ helm upgrade --install --atomic falco falcosecurity/falco --namespace falco-system
Release "falco" does not exist. Installing it now.
NAME: falco
LAST DEPLOYED: Wed Dec 29 16:52:22 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Falco agents are spinning up on each node in your cluster. After a few
seconds, they are going to start monitoring your containers looking for
security issues.

No further action should be required.

Tip:
You can easily forward Falco events to Slack, Kafka, AWS Lambda and more with falcosidekick.
Full list of outputs: https://github.com/falcosecurity/charts/falcosidekick.
You can enable its deployment with `--set falcosidekick.enabled=true` or in your values.yaml.
See: https://github.com/falcosecurity/charts/blob/master/falcosidekick/values.yaml for configuration values.

```

## Test Falco

**Get a shell in a cilium pod:**
```
$ kubectl exec --stdin --tty cilium-gnxtg -n kube-system -- /bin/bash
```

**Check the falco logs:**
```
$ kubectl logs falco-xdd6s -n falco-system | Select-String cilium
# An excerpt of interesting entries:
03:07:17.708277937: Notice A shell was spawned in a container with an attached terminal (user=root user_loginuid=-1 k8s.ns=kube-system
k8s.pod=cilium-gnxtg container=95aabc064e2a shell=bash parent=runc cmdline=bash terminal=34816 container_id=95aabc064e2a
image=docker.io/digitalocean/cilium) k8s.ns=kube-system k8s.pod=cilium-gnxtg container=95aabc064e2a
03:08:07.158098336: Warning Shell history had been deleted or renamed (user=root user_loginuid=-1 type=openat command=bash
fd.name=/root/.bash_history name=/root/.bash_history path=<NA> oldpath=<NA> k8s.ns=kube-system k8s.pod=cilium-gnxtg container=95aabc064e2a)
k8s.ns=kube-system k8s.pod=cilium-gnxtg container=95aabc064e2a

# There is also a lot of noise:
03:09:31.411265124: Notice Packet socket was created in a container (user=root user_loginuid=-1 command=cilium-agent --kvstore=etcd
--kvstore-opt=etcd.config=/var/lib/etcd-config/etcd.config --config-dir=/tmp/cilium/config-map --enable-node-port=true --enable-host-port=true
--enable-health-check-nodeport=false --kube-proxy-replacement=partial --enable-host-reachable-services=false --enable-egress-gateway=false
--arping-refresh-period=30s socket_info=domain=17(AF_PACKET) type=3 proto=1544  container_id=95aabc064e2a container_name=cilium-agent
image=docker.io/digitalocean/cilium:1.10.1-con-4989-actual) k8s.ns=kube-system k8s.pod=cilium-gnxtg container=95aabc064e2a k8s.ns=kube-system
```

## Learnings

1. Don't copy-paste things you don't understand.  
   I initially had this taint on my node pool and this prevented falco pods from launching. 
   Strangely there were no events in the falco-system namespace to give me a hint.  
   ```
       taint {
         key    = "workloadKind"
         value  = "database"
         effect = "NoSchedule"
       }
   ```
1. As part of troubleshooting the above I decided to upgrade my cluster to 1.21.x and also decided 2 gigs of RAM per
   node was too little and upgraded to 4 gig droplets.
   1. Upgrading the k8s version was mostly fine and not disruptive
   2. Upgrading the droplet instance type of the node_pool destroyed the entire cluster! Probably best to use a separate
      [node pool resource](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/kubernetes_node_pool)
      instead of the node_pool attribute in the digitalocean_kubernetes_cluster TF resource! 

## Thanks

Many thanks to [diogoheyoh](https://github.com/IrregularLine/digital-ocean-challenge) for the assist on comparing my 
cluster/config to theirs.

## References

* [DO K8s TF Resource](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/kubernetes_cluster)
* [DO Droplet Pricing Page](https://slugs.do-api.dev/)
* [Day-2 Operations-ready DigitalOcean Kubernetes (DOKS) for Developers](https://github.com/digitalocean/Kubernetes-Starter-Kit-Developers)
* [How To Use Terraform with DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean)
* [Kubernetes on DigitalOcean ](https://docs.digitalocean.com/products/kubernetes/)
* [Kubernetes for Full-Stack Developers](https://www.digitalocean.com/community/curriculums/kubernetes-for-full-stack-developers)
* [DO API Reference](https://docs.digitalocean.com/reference/api/api-reference/)