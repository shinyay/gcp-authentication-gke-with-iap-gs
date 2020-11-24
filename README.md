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

### Configure BackendConfig

#### Create Kubernetes Secret for OAuth Client
```
$ kubectl create secret generic secret-for-oauth \
    --from-literal=client_id=<CLIENT_ID_KEY> \
    --from-literal=client_secret=<CLIENT_SECRET_KEY>
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
