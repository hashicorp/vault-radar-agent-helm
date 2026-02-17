# Deploy Vault Radar Agent to Kubernetes

This guide walks through a deployment of Vault Radar Agent to a kubernetes cluster using Helm.
This is simply a bootstrap example and should be modified with best practices and thoroughly tested before any type of production deployment.

### Prerequisites

- Kubernetes Cluster
- [HCP Vault Radar access](https://vault-radar-portal.cloud.hashicorp.com)
- HCP Service principal and key
  - [Create a service principal](https://developer.hashicorp.com/hcp/docs/hcp/iam/service-principal#create-a-service-principal)
  - [Generate a service principal key](https://developer.hashicorp.com/hcp/docs/hcp/iam/service-principal/key#generate-a-service-principal-key)

## Create a Agent in the HCP Vault Radar portal

- Create Service principal and key
  - [Create a service principal and service principal key](https://developer.hashicorp.com/hcp/docs/vault-radar/manage/agent/overview#create-a-service-principal)
  - Copy and save the "Client ID" and "Client Key" to use later
- Create Agent
  - Login to the [HCP portal](https://portal.cloud.hashicorp.com)
  - Select "Vault Radar" from the navigation menu
  - In Vault Radar navigate to "Settings" then select "Agent" from the navigation menu
  - Select the "+ Add a Agent button
  - Give it a name
  - Copy and save `HCP_PROJECT_ID` and `HCP_RADAR_AGENT_POOL_ID` to use later
  - Select the "Install Agent" button

### Set environment variables

- Retrieve `Client ID` and `Client Key` from when the HCP service principal was created
  - Client ID = `HCP_CLIENT_ID`
  - Client Key = `HCP_CLIENT_SECRET`
- Retrieve `Project ID` and `Vault Radar Agent Pool ID` from when the Agent was created
- HCP Project ID = `HCP_PROJECT_ID`
- HCP Vault Radar Agent Pool ID = `HCP_RADAR_AGENT_POOL_ID`
- Obtain a `Git Token` that has read access to the desired target repos that Agent will be accessing
  - Git Token = `VAULT_RADAR_GIT_TOKEN`
    - For GitHub or GitLab use a personal access token (PAT)
    - For BitBucket and Azure DevOps, it should be in the format as `<username>:<PAT>`
- In the code block below replace the placeholder values with their respective values

```
export NAMESPACE=vault-radar
export IMAGE_TAG=latest
export HCP_PROJECT_ID=
export HCP_RADAR_AGENT_POOL_ID=
export HCP_CLIENT_ID=
export HCP_CLIENT_SECRET=
export VAULT_RADAR_GIT_TOKEN=
```

## Its go time!

### Deploy Agent to Kubernetes

```
helm upgrade --install \
--create-namespace \
--namespace $NAMESPACE \
--set image.tag=$IMAGE_TAG \
--set env.normal.HCP_PROJECT_ID=$HCP_PROJECT_ID \
--set env.normal.HCP_RADAR_AGENT_POOL_ID=$HCP_RADAR_AGENT_POOL_ID \
--set env.normal.HCP_CLIENT_ID=$HCP_CLIENT_ID \
--set env.secrets.HCP_CLIENT_SECRET=$HCP_CLIENT_SECRET \
--set env.secrets.VAULT_RADAR_GIT_TOKEN=$VAULT_RADAR_GIT_TOKEN \
agent ./agent
```

If you want to use vault kubernetes auth, add the following to the install command:

```
--set rbac.enabled="true" \
```

## Advanced Configuration

For advanced settings including log levels, multiple workers, and job type configuration, see the [Helm Chart README](../helm/README.md).

## Teardown Vault Radar Agent / Cleanup

```
helm uninstall agent -n $NAMESPACE
```
