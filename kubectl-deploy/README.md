# kubedeploy
Simple blue/green deployment kubectl plugin

`kube-deploy` plugin helps you to manage deployments in your k8s cluster:

### Blue/Green deployment
`kubectl-deploy bluegreen` expect two Deployments and one Service, that points to one of those in the active k8s cluster
the name of Deployments and Service doesn’t matter and could be anything,
and also how the Service exposed to outside of Kubernetes cluster.

![Blue/Green](img/blue-green.png?raw=true "Blue/Green Deployment")

### Installation
```
# assumes you have kubectl command line and a working KUBECONFIG
$ make
$ make install
$ kubectl deploy version
$ docker run -it kubectl-deploy:latest deploy version
```
#### Manual (Linux)
```sh
$ curl -sS  https://github.com/devops-ci-scripts/kubectl-deploy/releases/latest/kubectl-deploy-x86-64-linux -o kubectl-deploy
$ sudo mv kubectl-deploy /usr/local/bin/
$ chmod +x kubectl-deploy
$ kubectl deploy version
```

### How it works


### Usage
```
$ kubectl deploy bluegreen SERVICENAME NEWVERSIN

$ kubectl deploy -h
Kubectl plugin to manage deployment strategy

Usage:
  kubectl-deploy [command]

Available Commands:
  bluegreen   blue/green deployment
  completion  generate the autocompletion script for the specified shell
  help        Help about any command
  show        Differentiate between current deployment and intended
  version     Shows the version of kubectl-deploy plugin

Flags:
      --config string   config file (default is $HOME/.kubectl-deploy.yaml or $HOME/.kube/.kubectl-deploy.yaml)
  -h, --help            help for kubectl-deploy

Use "kubectl-deploy [command] --help" for more information about a command.


$ kubectl deploy bluegreen -h
**************************************************************************************************************
| "bluegreen" helps you to implement blue/green deployment in your k8s cluster                               |
| "bluegreen" expect two Deployments and one Service, that points to one of those                            |
| in the active k8s cluster.                                                                                 |
| the name of Deployments must ends with '-blue' and '-green' but Service name                               |
| could be anything, and also how the Service exposed to outside of Kubernetes cluster.                      |
**************************************************************************************************************

Usage:
  kubectl-deploy bluegreen SERVICENAME NEWVERSION [flags]

Flags:
  -h, --help   help for bluegreen

Global Flags:
      --config string   config file (default is $HOME/.kubectl-deploy.yaml or $HOME/.kube/.kubectl-deploy.yaml)
```

### Plugin configurations

Configuration file name is `.kubectl-deploy.yaml` and default location for config file is `$HOME/.kubectl-deploy.yaml` or
$HOME/.kube/.kubectl-deploy.yaml. This file contains DockerRegistryName/ImageName and TimeOut parameter for deployment.
```
~/.kube/.kubectl-deploy.yaml
DockerRegistryName: kubedeploy
ImageName: nginx
TimeOut: 60

```

### License

Kubectl Deployments plugin is [MIT licensed](LICENSE).
