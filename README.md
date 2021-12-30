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
## References

* [DO K8s TF Resource](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/kubernetes_cluster)
* [DO Droplet Pricing Page](https://slugs.do-api.dev/)
* [Day-2 Operations-ready DigitalOcean Kubernetes (DOKS) for Developers](https://github.com/digitalocean/Kubernetes-Starter-Kit-Developers)
* [How To Use Terraform with DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean)
* [Kubernetes on DigitalOcean ](https://docs.digitalocean.com/products/kubernetes/)
* [Kubernetes for Full-Stack Developers](https://www.digitalocean.com/community/curriculums/kubernetes-for-full-stack-developers)
* [DO API Reference](https://docs.digitalocean.com/reference/api/api-reference/)