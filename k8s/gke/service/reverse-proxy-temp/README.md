# Reverse Proxy HTTP LoadBalancer

This folder contains a simple LoadBalancer service to expose the reverse-proxy service via HTTP with a public IP address.

## Architecture

- **LoadBalancer service**: Directly exposes port 6193 (HTTP) with a public IP
- **Backend**: Routes traffic to existing `reverse-proxy-sp1` pods on port 6193

## Prerequisites

- GKE cluster with the `layer8` namespace
- Existing `reverse-proxy-sp1` deployment running (from `gke/service/reverse-proxy/`)
- `kubectl` configured to access your cluster

## Deployment Steps

### 1. Deploy LoadBalancer Service

```bash
cd gke/service/reverse-proxy-temp

kubectl apply -f service-loadbalancer-http.yaml
```

### 2. Get External IP Address

Wait for the LoadBalancer to provision an external IP:

```bash
kubectl get svc reverse-proxy-lb -n layer8 -w
```

Once the `EXTERNAL-IP` changes from `<pending>` to an actual IP address, you can access your service.

## Access the Service

After deployment, access your reverse-proxy via HTTP:

```bash
# Get the external IP
EXTERNAL_IP=$(kubectl get svc reverse-proxy-lb -n layer8 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test HTTP on port 6193
curl http://$EXTERNAL_IP:6193

# Or open in browser
echo "http://$EXTERNAL_IP:6193"
```

## Verify Deployment

```bash
# Check service status
kubectl get svc reverse-proxy-lb -n layer8

# Check backend pods
kubectl get pods -n layer8 -l app=reverse-proxy-sp1

# Describe service
kubectl describe svc reverse-proxy-lb -n layer8
```

## Using a Static IP (Optional)

To use a reserved static IP address:

1. Reserve a static IP in GCP:
```bash
gcloud compute addresses create reverse-proxy-ip --region=<your-region>
```

2. Get the IP address:
```bash
gcloud compute addresses describe reverse-proxy-ip --region=<your-region>
```

3. Edit `service-loadbalancer-http.yaml` and add the `loadBalancerIP` field:
```yaml
spec:
  type: LoadBalancer
  loadBalancerIP: "YOUR_STATIC_IP_HERE"
  ports:
  ...
```

4. Reapply the service:
```bash
kubectl apply -f service-loadbalancer-http.yaml
```

## Cleanup

To remove the LoadBalancer:

```bash
kubectl delete -f service-loadbalancer-http.yaml
```

## Troubleshooting

### LoadBalancer stuck in pending
```bash
# Check service events
kubectl describe svc reverse-proxy-lb -n layer8

# Verify GKE has permission to create load balancers
gcloud compute forwarding-rules list
```

### Connection refused
```bash
# Verify reverse-proxy-sp1 pods are running
kubectl get pods -n layer8 -l app=reverse-proxy-sp1

# Check pod logs
kubectl logs -n layer8 -l app=reverse-proxy-sp1

# Verify service endpoints
kubectl get endpoints reverse-proxy-lb -n layer8
```

### Test connectivity from within cluster
```bash
# Test internal service
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n layer8 -- curl http://reverse-proxy-sp1:6193
```

## Files

- `service-loadbalancer-http.yaml`: LoadBalancer service exposing port 6193 via HTTP
- `README.md`: This file
