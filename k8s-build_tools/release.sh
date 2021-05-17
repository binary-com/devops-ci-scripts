#!/usr/bin/env bash

# Usage:
#         build_tools deriv-app production_V20210102_6 ( -debug )

# This release script deploys a blue/green application. We expect it to be called from circleci.
# We use full versions throughout instead of blue/green so that there's transparency all the way down about what's actually serving
# We spin down the dormant application in order to save resources
# There's an HPA in play, so we ensure we pre-heat the dormant app before we switch it over

# We take the full tag to be the version. Currently that includes production_, and shouldn't,
# but we're not going to hack around that edge case. It won't actually matter given the implementation below

# This prototypoe is currently in deriv-com, but could be abstracted and injected into a build_tools/ for all our blue-green apps

# Argument passing
APP_NAME=$1
VERSION=$2
DEBUG=$3

if [[ -n $DEBUG ]]; then 
  set -x
fi

# Instead of leaving the other version running, we'll set it to dormant
# This should make it easier to find. We'll also unset it's image
DORMANT_VERSION=dormant

# This is an arbitrary choice of 60s timeout. It can be changed if necessary.
RELEASE_TIMEOUT=60s

if [[ -z $APP_NAME || -z $VERSION ]]; then
  echo "FATAL: Please pass APP_NAME and VERSION as arguments"
  exit 1
fi

# Find what version is currently deployed
CURRENT_VERSION=$(kubectl get -o jsonpath="{.spec.selector.version}" services/$APP_NAME)

if [[ -z $CURRENT_VERSION ]]; then
  echo "FATAL: Unable to find current version deployed"
  exit 1
fi

# Find which deployment is live, using a label selector
OLD_DEPLOYMENT=$(kubectl get deployment -l version=${CURRENT_VERSION},app=${APP_NAME} -o jsonpath='{.items[*].metadata.name}')

if [[ -z $OLD_DEPLOYMENT ]]; then
  echo "FATAL: Unable to find live deployment for $CURRENT_VERSION"
  exit 1
fi

# Find which deployment is dormant
NEW_DEPLOYMENT=$(kubectl get deployment -l version=${DORMANT_VERSION},app=${APP_NAME} -o jsonpath='{.items[*].metadata.name}')

if [[ -z $NEW_DEPLOYMENT ]]; then
  echo "FATAL: Unable to find spare dormant deployment"
  exit 1
fi

if [[ $NEW_DEPLOYMENT == $OLD_DEPLOYMENT ]]; then
  # This hasn't been observed, but just in case we end up with multiple labels somehow
  echo "FATAL: Something is wrong, Dormant and Live are somehow the same"
  exit 1
fi

# Need to know in advance what to scale the dormant deployment to, and apply that immediately after the image setting
# We use the hpa because we don't want to get caught out when it was about to scale but hasn't yet
# ( Could probably do this in one command, but I think it'd require eval'ing the output and we don't want to ever do that!
DESIRED_REPLICAS=$(kubectl get hpa/${APP_NAME} -o jsonpath='{.status.desiredReplicas}')

# But Desired replicas from the HPA can be < minimum, so we need to take that into account
# Min Replicas over Current, in case there's an issue with the current deployment
MIN_REPLICAS=$(kubectl get hpa/${APP_NAME} -o jsonpath='{.spec.minReplicas}')

TARGET_REPLICAS=$(( DESIRED_REPLICAS > MIN_REPLICAS ? DESIRED_REPLICAS : MIN_REPLICAS ))

# TODO - Setup the kubectl context so that kubectl works without arguments. We should not have to pass things like --server to it

kubectl patch deployment $NEW_DEPLOYMENT -p $(cat <<_END_OF_PATCH
{\
"metadata":{"labels":{"version":"${VERSION}"}},\
"spec":{\
"template":{"metadata":{"labels":{"version":"${VERSION}"}},\
"spec":{"containers":[{"name":"$APP_NAME","image":"${DOCKERHUB_ORGANISATION}/$APP_NAME:$VERSION"}]\
}}}}
_END_OF_PATCH
)

kubectl scale --replicas=$TARGET_REPLICAS deployment/$NEW_DEPLOYMENT

# Rollout will block until timeout or rollout is complete
kubectl rollout status --watch --timeout=$RELEASE_TIMEOUT deployment/$NEW_DEPLOYMENT
if [[ $? != 0 ]]; then
  # The deployment failed. We don't need to do rollback, because we haven't switched the service over
  # Better to leave it in a state we can introsepct
  echo "FATAL: Rollout of new version failed! Release aborted. Deployment status:"
  kubectl describe deployment/$NEW_DEPLOYMENT

  # Set the new deployment to be dormant again ready for the next release
  kubectl patch deployment $NEW_DEPLOYMENT -p $(cat <<_END_OF_PATCH
{\
"metadata":{"labels":{"version":"${DORMANT_VERSION}"}},\
"spec":{\
"template":{"metadata":{"labels":{"version":"${DOMRANT_VERSION}"}}\
}}}
_END_OF_PATCH
  )

  echo "INFO: Scaling the dormant deployment back down to 0"
  kubectl scale --replicas=0 deployment/$NEW_DEPLOYMENT
  exit 1
fi

# Now the rollout is ready, we can switch the traffic over
kubectl patch service $APP_NAME -p '{"spec":{"selector":{"version":"'${VERSION}'"}}}'
# And switch the hpa over
kubectl patch hpa $APP_NAME -p '{"spec":{"scaleTargetRef":{"name":"'${NEW_DEPLOYMENT}'"}}}'

# It's just a catch to be careful in case the drain doesn't work.
sleep 2

# We can scale the old deployment down to save resources
kubectl scale --replicas=0 deployment/$OLD_DEPLOYMENT

# Set the old deployment to be dormant ready for the next release
kubectl patch deployment $OLD_DEPLOYMENT -p $(cat <<_END_OF_PATCH
{\
"metadata":{"labels":{"version":"${DORMANT_VERSION}"}},\
"spec":{\
"template":{"metadata":{"labels":{"version":"${DOMRANT_VERSION}"}}\
}}}
_END_OF_PATCH
)

echo "Success: Release complete"
