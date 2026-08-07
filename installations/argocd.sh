#After creating cluster

#!/bin/bash


kubectl create namespace argocd
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo-cd/argo-cd \
  --namespace argocd \
  --set server.service.type=LoadBalancer
export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
echo "Argo CD URL: https://$ARGOCD_SERVER"

export ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD admin password: $ARGOCD_PWD"
