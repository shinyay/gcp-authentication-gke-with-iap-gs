# Identity-Aware Proxy for GKE Getting Started

`Identity-Aware Proxy` lets you establish a central authorization layer for applications accessed by HTTPS, so you can use an application-level access control model instead of relying on network-level firewalls.

![IAP](https://cloud.google.com/iap/images/iap-load-balancer.png)

## Description

|Functions|Identiy-Aware Proxy|VPN|
|---------|-------------------|---|
|Authentication|Cloud IAP|VPN Client|
|Connection|Google Account Cerdential|Login|
|Encrypt|HTTPS with SSL Certs for LB|Encrypted Communication Path|

### 1. Create Extenal IP Address

Create Reserved Statuc IP Address for Ingress.
In the case of `Ingress`, you should choose **Global** IP Address, not *Regional*

```
$ gcloud compute addresses create <ADDRESS_NAME> --global
```

#### List Address
```
$ gcloud compute addresses list
```

### 2. Add Your Domain to Cloud DNS

- [Cloud DNS Quickstart](https://cloud.google.com/dns/docs/quickstart)

#### 2.1. Create DNS zone

![cloud-dns](https://user-images.githubusercontent.com/3072734/99962127-f616bf00-2dd2-11eb-89de-67c7b4be2dc1.png)

- **DNS Name**
  - `Your Domain`
- **IPv4 Address**
  - `Reserved External IP Address`

#### 2.2. Configure Registrar (Example: [Freenom](https://my.freenom.com/))

```
$ gcloud dns managed-zones list
$ gcloud dns record-sets list --zone <MANAGED_ZONE>
```

Set NS Records to the following

- Services
  - My Domain
    - Manage Domain
      - Management Tools
        - Nameservers

#### 2.3. Confirm A Record
```
$ dig `YOUR-DOMAIN`

;; ANSWER SECTION:
YOUR.DOMAIN.		300	IN	A	11.22.333.444
```

```
$ nslookup `YOUR-DOMAIN`

Non-authoritative answer:
Name:	YOUR.DOMAIN
Address: 11.22.333.444
```

```
$ host `YOUR-DOMAIN`
```

### 3. Create GKE Cluster
#### 3.1 Enable GKE API
```
$ gcloud services enable container.googleapis.com
```

#### 3.2. Create GKE Cluster
```
$ gcloud container clusters create iap-gs-cluster --scopes cloud-platform --num-nodes 1 --enable-stackdriver-kubernetes --zone us-central1-c
```

### 4. Deploy App Container to GKE
### 4.1. Build Container Image with Cloud Build
```
$ gcloud builds submit --tag gcr.io/(gcloud config get-value project)/iap-app
```

### 4.2. Deploy app to GKE
```
$ sed -e "s|GCP_PROJECT|"(gcloud config get-value project)"|g" k8s/deploy-app.yml | kubectl apply -f -
```

### 5. Create Managed Certificate
- `k8s/certificate.yml`
  - YOUR DOMAIN

```
$ kubectl apply -f k8s/certificate.yml
```

### Create Ingress
- `k8s/ingress.yml`
  - YOUR STATIC IP ADDRESS NAME

```
$ kubectl apply -f k8s/ingress.yml
```

#### Confirm Ingress
```
$ kubectl get ingress
```

#### Confirm Managed Certificate
```
$ kubectl describe managedcertificate certificate
```

```
Status:
  Certificate Name:    mcrt-25e6f0ae-cc33-4dd0-be7c-c1bfcad6f555
  Certificate Status:  Provisioning
```
↓
About 15 mins
↓
```
Status:
  Certificate Name:    mcrt-25e6f0ae-cc33-4dd0-be7c-c1bfcad6f555
  Certificate Status:  Active
```

#### Confirm HTTPS Access
```
$ curl -X GET https://YOUR-DOMAIN/hello
```

### Configure OAuth Consent Screen
- [OAuth Consent Screen](https://console.cloud.google.com/apis/credentials/consent?_ga=2.73243667.145231038.1606091012-983599867.1599137884&_gac=1.249734004.1604543893.CjwKCAiAv4n9BRA9EiwA30WND9tYKNMuLjYNlsSBrI4JO3KyW7Wkyj7T5SL10VmdwDs8jNxCe6vRoxoChh0QAvD_BwE)

  - **App name**
    - Application Display Name
  - **User support email**
    - You email
  - **Developer contact information**
    - Your email

### OAuth Credentials
- [Credentials](https://console.cloud.google.com/apis/credentials?_ga=2.7746482.145231038.1606091012-983599867.1599137884&_gac=1.219319915.1604543893.CjwKCAiAv4n9BRA9EiwA30WND9tYKNMuLjYNlsSBrI4JO3KyW7Wkyj7T5SL10VmdwDs8jNxCe6vRoxoChh0QAvD_BwE)

- Create Credentials -> **OAuth client ID**
  - **Application Type**
    - `Web Application`
  - **Name**
    - `OAuth Cliend ID Display Name`

`CREATE`

- Cliend ID -> Detail
  - **Authorized redirect URIs**
    - `https://iap.googleapis.com/v1/oauth/clientIds/<CLIENT_ID>:handleRedirect`

`SAVE`

- Download JSON

### Add Members to Identity-Aware Proxy
- [IAP](https://console.cloud.google.com/security/iap?_ga=2.79167380.145231038.1606091012-983599867.1599137884&_gac=1.222007146.1604543893.CjwKCAiAv4n9BRA9EiwA30WND9tYKNMuLjYNlsSBrI4JO3KyW7Wkyj7T5SL10VmdwDs8jNxCe6vRoxoChh0QAvD_BwE)

- ADD MEMBER
  - Cloud IAP
    - `IAP-secured Web App User`

![IAP-secured Web App User](https://user-images.githubusercontent.com/3072734/100075829-cb387380-2e83-11eb-9e6b-bbd4a91c3542.png)

### Configure BackendConfig
- [Reference]{https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#iap}

#### Create Kubernetes Secret for OAuth Client
```
$ kubectl create secret generic secret-for-oauth \
    --from-literal=client_id=<CLIENT_ID_KEY> \
    --from-literal=client_secret=<CLIENT_SECRET_KEY>
```

- [CLIENT_ID/CLIENT_SECRET](https://console.cloud.google.com/apis/credentials?_ga=2.82107286.145231038.1606091012-983599867.1599137884&_gac=1.123965048.1604543893.CjwKCAiAv4n9BRA9EiwA30WND9tYKNMuLjYNlsSBrI4JO3KyW7Wkyj7T5SL10VmdwDs8jNxCe6vRoxoChh0QAvD_BwE)

#### Configure BackendConfig
- For GKE versions 1.16.8-gke.3 and higher: `cloud.google.com/v1`
- For earlier GKE version: `cloud.google.com/v1beta1`

```
$ kubectl apply -f k8s/backend-config.yml
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
