# Identity-Aware Proxy for GKE Getting Started

Overview

## Description
### Prerequisite
#### Extenal IP Address
```
$ gcloud compute addresses create <ADDRESS_NAME> --global
```

#### List Address
```
$ gcloud compute addresses list
```

#### Cloud DNS

![cliud-dns](https://user-images.githubusercontent.com/3072734/99962127-f616bf00-2dd2-11eb-89de-67c7b4be2dc1.png)

##### Add Record Set
- **DNS Name**
  - `Your Domain`
- **IPv4 Address**
  - `Reserved External IP Address`

#### Configure Registrar (Freenom)
- Services
  - My Domain
    - Manage Domain
      - Management Tools
        - Nameservers

#### Confirm A Record
```
$ dig YOUR-DOMAIN

;; ANSWER SECTION:
YOUR.DOMAIN.		300	IN	A	11.22.333.444
```

```
$ nslookup YOUR-DOMAIN

Non-authoritative answer:
Name:	YOUR.DOMAIN
Address: 11.22.333.444
```

### Create GKE Cluster
#### Enable GKE API
```
$ gcloud services enable container.googleapis.com
```


#### Create GKE Cluster
```
$ gcloud container clusters create iap-gs-cluster --scopes cloud-platform --num-nodes 1 --enable-stackdriver-kubernetes --zone us-central1-c
```

### Build Container Image
```
$ gcloud builds submit --tag gcr.io/(gcloud config get-value project)/iap-app
```

### Deploy app to GKE
```
$ sed -e "s|GCP_PROJECT|"(gcloud config get-value project)"|g" k8s/deploy-app.yml | kubectl apply -f -
```

### Create Managed Certificate
- `k8s/ingress.yml`
  - YOUR DOMAIN

```
$ kubectl apply -f k8s/certificate.yml
```

### Create Ingress
#### Configure Ingress
- `k8s/ingress.yml`
  - YOUR STATIC IP ADDRESS NAME

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.global-static-ip-name: YOUR_IP_NAME # Name of Static IP Address
:
:
---
apiVersion: networking.gke.io/v1beta1
kind: ManagedCertificate
metadata:
  name: certificate
spec:
  domains:
    - YOUR_DOMAIN_NAME # Name of Your Domain
```

## Demo

## Features

- feature:1
- feature:2

## Requirement

## Usage

## Installation

## Licence

Released under the [MIT license](https://gist.githubusercontent.com/shinyay/56e54ee4c0e22db8211e05e70a63247e/raw/34c6fdd50d54aa8e23560c296424aeb61599aa71/LICENSE)

## Author

[shinyay](https://github.com/shinyay)
