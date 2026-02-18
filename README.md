# Deploy Vault Radar Agent to Kubernetes

This guide walks through a deployment of Vault Radar Agent to a Kubernetes cluster using Helm.
This is simply a bootstrap example and should be modified with best practices and thoroughly tested before any type of production deployment.

## Prerequisites

- Kubernetes cluster
- [HCP Vault Radar access](https://vault-radar-portal.cloud.hashicorp.com)
- HCP service principal and key
  - [Create a service principal](https://developer.hashicorp.com/hcp/docs/hcp/iam/service-principal#create-a-service-principal)
  - [Generate a service principal key](https://developer.hashicorp.com/hcp/docs/hcp/iam/service-principal/key#generate-a-service-principal-key)

## Create an Agent in the HCP Vault Radar Portal

- Create a service principal and key
  - [Create a service principal and service principal key](https://developer.hashicorp.com/hcp/docs/vault-radar/agent/deploy#create-a-service-principal)
  - Copy and save the "Client ID" and "Client Key" to use later
- Create an agent
  - Log in to the [HCP portal](https://portal.cloud.hashicorp.com)
  - Select "Vault Radar" from the navigation menu
  - In Vault Radar navigate to "Settings" then select "Agent" from the navigation menu
  - Select the "+ Add an Agent" button
  - Give it a name
  - Copy and save `HCP_PROJECT_ID` and `HCP_RADAR_AGENT_POOL_ID` to use later
  - Select the "Install Agent" button

## Set Environment Variables

Collect the following values before running any Helm commands:

- `HCP_CLIENT_ID` — Client ID from the HCP service principal
- `HCP_CLIENT_SECRET` — Client key from the HCP service principal
- `HCP_PROJECT_ID` — Project ID retrieved when creating the agent
- `HCP_RADAR_AGENT_POOL_ID` — Agent pool ID retrieved when creating the agent
- `VAULT_RADAR_GIT_TOKEN` — A Git token with read access to the target repositories
  - For GitHub or GitLab: use a personal access token (PAT)
  - For BitBucket and Azure DevOps: use the format `<username>:<PAT>`

Export these as environment variables in your shell:

```shell
export NAMESPACE=vault-radar
export HCP_PROJECT_ID=
export HCP_RADAR_AGENT_POOL_ID=
export HCP_CLIENT_ID=
export HCP_CLIENT_SECRET=
export VAULT_RADAR_GIT_TOKEN=
```

> **Note:** The image tag defaults to the `appVersion` declared in [Chart.yaml](Chart.yaml). To deploy a different version, add `--set image.tag=<version>` to any Helm command below.

## Deploy

### Dry Run

Validate the rendered manifests before installing:

```shell
helm upgrade --install --dry-run \
  --create-namespace \
  --namespace $NAMESPACE \
  --set env.normal.HCP_PROJECT_ID=$HCP_PROJECT_ID \
  --set env.normal.HCP_RADAR_AGENT_POOL_ID=$HCP_RADAR_AGENT_POOL_ID \
  --set env.normal.HCP_CLIENT_ID=$HCP_CLIENT_ID \
  --set env.secrets.HCP_CLIENT_SECRET=$HCP_CLIENT_SECRET \
  --set env.secrets.VAULT_RADAR_GIT_TOKEN=$VAULT_RADAR_GIT_TOKEN \
  vault-radar-agent . --debug
```

### Install

```shell
helm upgrade --install \
  --create-namespace \
  --namespace $NAMESPACE \
  --set env.normal.HCP_PROJECT_ID=$HCP_PROJECT_ID \
  --set env.normal.HCP_RADAR_AGENT_POOL_ID=$HCP_RADAR_AGENT_POOL_ID \
  --set env.normal.HCP_CLIENT_ID=$HCP_CLIENT_ID \
  --set env.secrets.HCP_CLIENT_SECRET=$HCP_CLIENT_SECRET \
  --set env.secrets.VAULT_RADAR_GIT_TOKEN=$VAULT_RADAR_GIT_TOKEN \
  vault-radar-agent .
```

To enable Vault Kubernetes auth, add the following flag to either command above:

```shell
--set rbac.enabled="true" \
```

### Uninstall

```shell
helm uninstall vault-radar-agent -n $NAMESPACE
```

## Advanced Configuration

### Setting Log Level

To deploy the agent with a specific log level, add the following flag to the install command:

```shell
--set env.optional.VAULT_RADAR_LOG_LEVEL="<log-level>" \
```

where `<log-level>` is your desired log level (e.g. `debug`, `info`, `warn`, `error`).

### Deploying with Multiple Workers

The chart supports multiple workers (Deployments) within a single Helm release. Each worker can be configured to handle specific job types using `AGENT_SERVICE_ENABLE_LIST` or `AGENT_SERVICE_DISABLE_LIST`.

> **Note:** You can only provide either `AGENT_SERVICE_ENABLE_LIST` or `AGENT_SERVICE_DISABLE_LIST` per worker, not both.

#### Single worker (default)

By default, the chart deploys a single worker that handles all job types. Use the [Install](#install) command above.

#### Multiple workers (separating job types)

To deploy separate workers for different job types (e.g., isolate PR scanning from other scans), add the following flags to the [Install](#install) command:

```shell
--set workers.items.default.env.AGENT_SERVICE_DISABLE_LIST="pull_request_scan" \
--set workers.items.prScan.enabled="true" \
--set workers.items.prScan.name="pr-scan" \
--set workers.items.prScan.replicaCount="2" \
--set workers.items.prScan.env.AGENT_SERVICE_ENABLE_LIST="pull_request_scan" \
```

This creates:

- **default** worker: handles all job types except PR scanning (1 replica)
- **pr-scan** worker: dedicated to PR scanning only (2 replicas)

Both workers share the same ServiceAccount and Secret, but can be scaled and configured independently.

#### Worker configuration options

Each worker in `workers.items` supports:

| Option         | Description                                                                                                | Default                                       |
| -------------- | ---------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| `enabled`      | Enable/disable the worker                                                                                  | `true`                                        |
| `name`         | Name suffix for the Deployment (required)                                                                  | —                                             |
| `replicaCount` | Number of replicas                                                                                         | `1`                                           |
| `resources`    | CPU/memory limits and requests as key-value pairs                                                          | `limits: 1000m/3072Mi, requests: 100m/1024Mi` |
| `nodeSelector` | Schedule pods on nodes with specific labels as key-value pairs (e.g., `disktype: ssd`)                     | `{}`                                          |
| `tolerations`  | Allow pods to be scheduled on nodes with matching taints as a list of toleration objects                   | `[]`                                          |
| `affinity`     | Advanced scheduling rules for pod placement as key-value pairs (node affinity, pod affinity/anti-affinity) | `{}`                                          |
| `env`          | Worker-specific environment variables as key-value pairs                                                   | `{}`                                          |

#### Enabling or disabling job types for a worker

Use the `env` option to control which job types a worker handles:

- `AGENT_SERVICE_ENABLE_LIST`: comma-separated list of job types to enable (worker handles **only** these)
- `AGENT_SERVICE_DISABLE_LIST`: comma-separated list of job types to disable (worker handles **all except** these)

> **Note:** You can only use one of these per worker, not both. When using `--set`, escape commas with `\,`.

##### Available job types

| Job Type            | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| `http`              | Handles HTTP webhook requests for on-demand scanning         |
| `resource_scan`     | Scans configured data sources (repos, buckets, etc.)         |
| `content_scan`      | Scans content/files for secrets                              |
| `pull_request_scan` | Scans pull requests and merge requests for secrets           |
| `secrets_copy`      | Copies discovered secrets to HashiCorp Vault for remediation |

Example — disable PR scanning and content scanning on the default worker:

```shell
--set workers.items.default.env.AGENT_SERVICE_DISABLE_LIST="pull_request_scan\,content_scan" \
```
