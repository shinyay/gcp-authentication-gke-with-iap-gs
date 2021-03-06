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

#### 1.1. List Address
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

#### 3.3. Confirm GKE Cluster
```
$ kubectl config current-context
$ kubectl config get-clusters
```

#### 3.4. Retrieve kubeconfig entry
```
$ gcloud container clusters get-credentials <CLUSTER_NAME>
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

```
$ kubectl get pods -o wide
```

### 5. Create Managed Certificate

- **ManagedCertificate v1beta2 API** : For GKE cluster versions `1.15 and later`
- **ManagedCertificate v1 API** : For GKE cluster versions `1.17.9-gke.6300 and later`

#### 5.1. Create Managed Certificate
- [Using Google-managed SSL certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs#setting_up_the_managed_certificate)

Replace `YOUR_DOMAIN` in [k8s/certificate.yml](k8s/certificate.yml)

```yaml
apiVersion: networking.gke.io/v1beta2
kind: ManagedCertificate
metadata:
  name: certificate
spec:
  domains:
    - YOUR_DOMAIN
```

```
$ sed -e "s|YOUR_DOMAIN|XXXXX|g" k8s/certificate.yml | kubectl apply -f -
```

#### 5.2. Confirm Managed Certificate
```
$ kubectl get managedcertificate
$ kubectl describe managedcertificate certificate
```

### 6. Create Ingress with Managed Certificate
#### 6.1. Create NodePort to expose the App
- [k8s/service-app.yml](k8s/service-app.yml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app
spec:
  ports:
    - port: 8080
      targetPort: 8080
  selector:
    app: app
  type: NodePort
```

```
$ kubectl apply -f k8s/service-app.yml
$ kubectl get services -o wide
```

#### 6.2. Create Ingress with Managed Certificate
Replace `STATIC_IP` in [k8s/ingress.yml](k8s/ingress.yml)

  - You can confirm your static ip address: `gcloud compute addresses list`

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress
  annotations:
    kubernetes.io/ingress.global-static-ip-name: STATIC_IP
    networking.gke.io/managed-certificates: certificate
spec:
  backend:
    serviceName: app
    servicePort: 8080
```

```
$ sed -e "s|STATIC_IP|XXXXX|g" k8s/ingress.yml | kubectl apply -f -
```

#### 6.3. Confirm Ingress
```
$ kubectl get ingress
```

#### 6.4. Confirm Managed Certificate
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

#### 6.5. Confirm HTTPS Access
```
$ curl -X GET https://YOUR-DOMAIN/hello
```

### 7. Enable IAP for GKE
- [Enabling IAP for GKE](https://cloud.google.com/iap/docs/enabling-kubernetes-howto)

#### 7.1. Configure Configure OAuth Consent Screen
- [OAuth Consent Screen](https://console.cloud.google.com/apis/credentials/consent?_ga=2.73243667.145231038.1606091012-983599867.1599137884&_gac=1.249734004.1604543893.CjwKCAiAv4n9BRA9EiwA30WND9tYKNMuLjYNlsSBrI4JO3KyW7Wkyj7T5SL10VmdwDs8jNxCe6vRoxoChh0QAvD_BwE)

![oauth-consent-screen](https://user-images.githubusercontent.com/3072734/100300443-61ca7900-2fd9-11eb-9b73-d7074c624400.png)

Configure the following items.

  - **App name**
    - Application Display Name
  - **User support email**
    - You email
  - **Developer contact information**
    - Your email

#### 7.2. Create OAuth Credentials
- [Credentials](https://console.cloud.google.com/apis/credentials?_ga=2.7746482.145231038.1606091012-983599867.1599137884&_gac=1.219319915.1604543893.CjwKCAiAv4n9BRA9EiwA30WND9tYKNMuLjYNlsSBrI4JO3KyW7Wkyj7T5SL10VmdwDs8jNxCe6vRoxoChh0QAvD_BwE)

<details><summary>Create Credentials -> OAuth client ID</summary><div>
<img width="" alt="input-source" src="https://user-images.githubusercontent.com/3072734/100300661-d998a380-2fd9-11eb-971e-b7f9522d7aaf.png">
</div></details>

- **Application Type**
  - `Web Application`
- **Name**
  - `OAuth Cliend ID Display Name`

![OAuth Client ID](https://user-images.githubusercontent.com/3072734/100301172-f41f4c80-2fda-11eb-8c6e-912260c4f1dd.png)

#### 7.3. OAuth Authorized Redirect URI

![authorized-redirect-uri](https://user-images.githubusercontent.com/3072734/100301478-8f182680-2fdb-11eb-83f1-ca57dcf59d51.png)

- **Authorized redirect URIs**
  - `https://iap.googleapis.com/v1/oauth/clientIds/<CLIENT_ID>:handleRedirect`

Download JSON

![download](https://user-images.githubusercontent.com/3072734/100301626-df8f8400-2fdb-11eb-9d72-cbc1b74d5c46.png)


#### 7.4. Add Members to Identity-Aware Proxy
- [IAP](https://console.cloud.google.com/security/iap?_ga=2.79167380.145231038.1606091012-983599867.1599137884&_gac=1.222007146.1604543893.CjwKCAiAv4n9BRA9EiwA30WND9tYKNMuLjYNlsSBrI4JO3KyW7Wkyj7T5SL10VmdwDs8jNxCe6vRoxoChh0QAvD_BwE)

ADD MEMBER as `Cloud IAP/IAP-secured Web App User`

![IAP-secured Web App User](https://user-images.githubusercontent.com/3072734/100075829-cb387380-2e83-11eb-9e6b-bbd4a91c3542.png)

#### 7.5. Configure BackendConfig
- [Reference]{https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#iap}

Create Kubernetes Secret for OAuth Client.

You can retrieve <CLIENT_ID_KEY> and <CLIENT_SECRET_KEY> from [OAuth Credential](https://console.cloud.google.com/apis/credentials?_ga=2.82107286.145231038.1606091012-983599867.1599137884&_gac=1.123965048.1604543893.CjwKCAiAv4n9BRA9EiwA30WND9tYKNMuLjYNlsSBrI4JO3KyW7Wkyj7T5SL10VmdwDs8jNxCe6vRoxoChh0QAvD_BwE) created before.

```
$ kubectl create secret generic secret-for-oauth \
    --from-literal=client_id=<CLIENT_ID_KEY> \
    --from-literal=client_secret=<CLIENT_SECRET_KEY>
```
```
$ kubectl get secret
$ kubectl describe secret
```

#### 7.6. Configure BackendConfig
- For GKE versions 1.16.8-gke.3 and higher: `cloud.google.com/v1`
- For earlier GKE version: `cloud.google.com/v1beta1`

```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: config-default
spec:
  iap:
    enabled: true
    oauthclientCredentials:
      secretName: secret-for-oauth
```

```
$ kubectl apply -f k8s/backend-config.yml
```

```
$ kubectl get backendconfig
$ kubectl describe backendconfig config-default
```

#### 7.7. Associate NodePort with BackendConfig to trigger turn on IAP
Add the following resources to `service-app.yml` : [(Added YAML)](k8s/service-app-backend-config.yml)

```yaml
metadata:
  annotations:
    beta.cloud.google.com/backend-config: '{"default": "config-default"}'
```

```
$ kubectl apply -f k8s/service-app-backend-config.yml
```

![toggle-on](https://user-images.githubusercontent.com/3072734/100313135-4cfcde00-2ff7-11eb-9a40-5a8bd7ca37ff.png)

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
