## Argo CD Setup

**On CLI, run these step by step to setup the Argo CD**
```
kubectl create namespace argocd
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo-cd/argo-cd --namespace argocd --set server.service.type=LoadBalancer
```

Also check on CLI - Make sure Argo pods are running
```
kubectl get pods -n argo cd
```
If Argo CD application fails. Check Argocd Pods and services are running safely.  

**Wait for 2-3 minuties, Check in Loadbalancer, ensure Argo CD Loadbalancer is UP.**
```
export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
echo "Argo CD URL: https://$ARGOCD_SERVER"

export ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD admin password: $ARGOCD_PWD"
```
**Open the Link for Argo CD -  Username (admin), Password (check output)**

1. Connect the Repo First
2. Create 4 applications respectively.
3. Ensure all of them are up and running
4. Also on CLI, ensure everything is up for all 4 applications. 
```
kubectl get all
```
