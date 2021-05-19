# kubedeploy
Simple blue/green deployment plugin

`kube-deploy` helps you to implement blue/green deployment in your k8s cluster:

### Installation

#### Manual

Since `kube-deploy` is written in Bash, you should be able to install it to any POSIX environment that has Bash installed.


- Download the `kube-deploy` script.
- Either:
  - save it to somewhere in your `PATH`,
  - or save it to a directory, then create symlinks to `kube-deploy` from
    somewhere in your `PATH`, like `/usr/local/bin`
- Make `kube-deploy` executable (`chmod +x ...`)

```bash
$ git clone git@github.com:afshinpaydar/kubedeploy.git
$ cp kubedeploy/bin/kubectl-deploy /usr/local/bin/
$ chmod +x /usr/local/bin/kubectl-deploy
```

### Usage

```bash
$ kubectl deploy -h
Usage: kubectl-deploy [-n <namespace>] [-t <timeout>] <service> <docker-image-url>
Arguments:
service REQUIRED: The name of the service the script should trigger the Blue/Green deployment
docker-image-url REQUIRED: URL of Docker image and should follow this format: registry/<user>/<image>:<tag>
-t OPTIONAL: How long to wait for the deployment to be available, defaults to 120 seconds, must be greater than 60
-n OPTIONAL: the namespace scope for this CLI request, default is the CURRENT ACTIVE Namespace

```
### Kubernetes cluster setup
`kubectl-deploy` expect two `Deployment`s and one `Service`, that points to one of those in the active k8s cluster & namespace.
name of `Deployments` and `Service` doesn’t matter and could be anything, and also how the `Service` exposed to outside of
Kubernetes cluster.
**But the Deployments must have `env: blue|green` lables and Service must have `.spec.selector.env=blue|green`**
**Otherwise deployment will fails with below Error:**
```sh
Error: The resources in the current k8s namespace doesn't compatible with Blue/Green deployment!!!
```

e.g: Sample k8s design on current namespace:
```bash
$ kubectl get deployment
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
prod-blue                    2/2     2            2           4h1m
prod-green                   0/0     0            0           4h1m

$ kubectl get svc
NAME                   TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
prod-com               ClusterIP   10.68.5.134   <none>        80/TCP    4h4m
```
