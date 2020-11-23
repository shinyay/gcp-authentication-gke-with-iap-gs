# Identity-Aware Proxy for GKE Getting Started

Overview

## Description
### Prerequisite
#### Extenal IP Address

#### Cloud DNS

![cliud-dns](https://user-images.githubusercontent.com/3072734/99962127-f616bf00-2dd2-11eb-89de-67c7b4be2dc1.png)

##### Add Record Set
- **DNS Name**
  - `Your Domain`
- **IPv4 Address**
  - `Reserved External IP Address`

### Create GKE Cluster
#### Enable GKE API
```
$ gcloud services enable container.googleapis.com
```


#### Create GKE Cluster
```
$ gcloud container clusters create iap-gs-cluster --scopes cloud-platform --num-nodes 1 --enable-stackdriver-kubernetes --zone us-central1-c
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
