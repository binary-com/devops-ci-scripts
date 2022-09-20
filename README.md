# FE deployment mechanism

- get the `fe_k8s_secrets` LP entry which consists of necessary kubernetes secrets
- get the `CA_CRT` value and save that as `ca.crt` file in the same path as deployment script `release.sh`
- save this file as `variables.sh` and use `source` to append the variables in current shell

```
#!/usr/bin/env bash
export KUBE_SERVER="LP_COPIED_VALUE"
export SERVICEACCOUNT_TOKEN="LP_COPIED_VALUE"
export CA="ca.crt"
export DOCKERHUB_ORGANISATION="regentmarkets"
export NAMESPACE="sinbad-software-staging"          # you need to change the namespace name where you want to trigger changes
export APP_NAME="sinbad-software"                   # you need to change the app_name here 
export APP_VERSION="latest"
```
- FE docker image url is `${DOCKERHUB_ORGANISATION}/${APP_NAME}:${APP_VERSION}`. most of our FE apps are public docker image.
- **APP_NAME** points to <app> label in k8s [blue deployment template](https://github.com/regentmarkets/kubernetes-frontend/blob/5ea7df9de4fb636a09c6c0b653d8475d17e5e58b/aws-eks-infra/sinbad-software/staging/deployment.yml#L17). this value points to the app that we are planning to deploy 
- **APP_VERSION** points to <version> label in k8s [blue deployment template](https://github.com/regentmarkets/kubernetes-frontend/blob/5ea7df9de4fb636a09c6c0b653d8475d17e5e58b/aws-eks-infra/sinbad-software/staging/deployment.yml#L18). this value can only be `latest`, `latest-staging` or any `FE release tag`. this variable decides which FE app docker image version will be pulled from dockerhub and deployed into cluster

- in order to use the script to trigger deployment to a specific app you need to run the following

```
./release.sh ${APP_NAME} ${APP_VERSION}
```

- if you want to run in debug mode then you need to run the following
```
./release.sh ${APP_NAME} ${APP_VERSION} -debug
```

# Troubleshooting

in case of urgent deployment there is another way to release changes using `kubectl patch`. you dont need CA or SERVICEACCOUNT_TOKEN for that. switiching to AWS CLI production profile should be enough

```
kubectl -n TARGET_NAMESPACE patch deployment K8S_GREEN_DEPLOYMENT_RESOURCE_NAME -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"APP_NAME","image":"regentmarkets/APP_NAME:APP_VERSION"}]}}}}'

```

before running the command you need the following
- FE docker image ( you can get it from dockerhub )
- namespace name
- k8s green deployment resource name
- app name as usual
- app version name ( if not `latest` then retrieve it from FE team )

for instance if you want to release tag `production_V20220831_0` in staging.firstsource.io site then the command would be

```
kubectl -n firstsource-io-staging patch deployment firstsource-io-green -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"firstsource-io","image":"regentmarkets/firstsource-io:production_V20220831_0"}]}}}}'
```

