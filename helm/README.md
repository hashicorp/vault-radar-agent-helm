### Pre-requisites

- Kubernetes Cluster
- HCP Service principal and key
  - [Create a service principal](https://developer.hashicorp.com/hcp/docs/hcp/iam/service-principal#create-a-service-principal)
  - [Generate a service principal-key](https://developer.hashicorp.com/hcp/docs/hcp/iam/service-principal/key#generate-a-service-principal-key)

### Environment Variables

```
export ENV=
export NAMESPACE=
export IMAGE_TAG=
export HCP_PROJECT_ID=
export HCP_RADAR_AGENT_POOL_ID=
export HCP_CLIENT_ID=
export HCP_CLIENT_SECRET=
export VAULT_RADAR_GIT_TOKEN=
eval $(hcloud envhcp $ENV)
```

### Dry Run

```
helm upgrade --install --dry-run \
--create-namespace \
--namespace $NAMESPACE \
--set image.tag=$IMAGE_TAG \
--set env.normal.HCP_API_ADDRESS=$HCP_API_ADDRESS \
--set env.normal.HCP_AUTH_URL=$HCP_AUTH_URL \
--set env.normal.HCP_PROJECT_ID=$HCP_PROJECT_ID \
--set env.normal.HCP_RADAR_AGENT_POOL_ID=$HCP_RADAR_AGENT_POOL_ID \
--set env.normal.HCP_CLIENT_ID=$HCP_CLIENT_ID \
--set env.secrets.HCP_CLIENT_SECRET=$HCP_CLIENT_SECRET \
--set env.secrets.VAULT_RADAR_GIT_TOKEN=$VAULT_RADAR_GIT_TOKEN \
agent ./agent --debug
```

If you want to use vault kubernetes auth, run command

```
helm upgrade --install --dry-run \
--create-namespace \
--namespace $NAMESPACE \
--set image.tag=$IMAGE_TAG \
--set env.normal.HCP_API_ADDRESS=$HCP_API_ADDRESS \
--set env.normal.HCP_AUTH_URL=$HCP_AUTH_URL \
--set env.normal.HCP_PROJECT_ID=$HCP_PROJECT_ID \
--set env.normal.HCP_RADAR_AGENT_POOL_ID=$HCP_RADAR_AGENT_POOL_ID \
--set env.normal.HCP_CLIENT_ID=$HCP_CLIENT_ID \
--set env.secrets.HCP_CLIENT_SECRET=$HCP_CLIENT_SECRET \
--set env.secrets.VAULT_RADAR_GIT_TOKEN=$VAULT_RADAR_GIT_TOKEN \
--set rbac.enabled="true" \
agent ./agent --debug
```

### Install

```
helm upgrade --install \
--create-namespace \
--namespace $NAMESPACE \
--set image.tag=$IMAGE_TAG \
--set env.normal.HCP_API_ADDRESS=$HCP_API_ADDRESS \
--set env.normal.HCP_AUTH_URL=$HCP_AUTH_URL \
--set env.normal.HCP_PROJECT_ID=$HCP_PROJECT_ID \
--set env.normal.HCP_RADAR_AGENT_POOL_ID=$HCP_RADAR_AGENT_POOL_ID \
--set env.normal.HCP_CLIENT_ID=$HCP_CLIENT_ID \
--set env.secrets.HCP_CLIENT_SECRET=$HCP_CLIENT_SECRET \
--set env.secrets.VAULT_RADAR_GIT_TOKEN=$VAULT_RADAR_GIT_TOKEN \
agent ./agent --debug
```

If you want to use vault kubernetes auth, run command

```
helm upgrade --install \
--create-namespace \
--namespace $NAMESPACE \
--set image.tag=$IMAGE_TAG \
--set env.normal.HCP_API_ADDRESS=$HCP_API_ADDRESS \
--set env.normal.HCP_AUTH_URL=$HCP_AUTH_URL \
--set env.normal.HCP_PROJECT_ID=$HCP_PROJECT_ID \
--set env.normal.HCP_RADAR_AGENT_POOL_ID=$HCP_RADAR_AGENT_POOL_ID \
--set env.normal.HCP_CLIENT_ID=$HCP_CLIENT_ID \
--set env.secrets.HCP_CLIENT_SECRET=$HCP_CLIENT_SECRET \
--set env.secrets.VAULT_RADAR_GIT_TOKEN=$VAULT_RADAR_GIT_TOKEN \
--set rbac.enabled="true" \
agent ./agent --debug
```

### Uninstall

```
helm uninstall agent -n $NAMESPACE
```

### Setting log level

To deploy agent with a particular log level, add the following to the install command:

```
--set env.optional.VAULT_RADAR_LOG_LEVEL="<log-level>" \
```

where `<log-level>` is your desired log level (e.g. `debug`, `info`, etc.).

### Deploying with workers enabled or disabled

The chart supports multiple workers (Deployments) within a single Helm release. Each worker can be configured to handle specific job types using `AGENT_SERVICE_ENABLE_LIST` or `AGENT_SERVICE_DISABLE_LIST`.

> **Note:** You can only provide either `AGENT_SERVICE_ENABLE_LIST` or `AGENT_SERVICE_DISABLE_LIST` per worker, not both.

#### Single worker (default)

By default, the chart deploys a single worker that handles all job types. Use the [Install](#install) command above.

#### Multiple workers (separating job types)

To deploy with separate workers for different job types (e.g., separate PR scanning from other scans), add the following to the [Install](#install) command:

```
--set workers.items.default.env.AGENT_SERVICE_DISABLE_LIST="pull_request_scan" \
--set workers.items.prScan.enabled="true" \
--set workers.items.prScan.name="pr-scan" \
--set workers.items.prScan.replicaCount="2" \
--set workers.items.prScan.env.AGENT_SERVICE_ENABLE_LIST="pull_request_scan" \
```

This creates:

- **default** worker: Handles all job types except PR scanning (1 replica)
- **pr-scan** worker: Dedicated to PR scanning only (2 replicas)

Both workers share the same ServiceAccount and Secret, but can be scaled and configured independently.

#### Worker configuration options

Each worker in `workers.items` supports:

| Option         | Description                                                                                                | Default                                       |
| -------------- | ---------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| `enabled`      | Enable/disable the worker                                                                                  | `true`                                        |
| `name`         | Name suffix for the Deployment (required)                                                                  | -                                             |
| `replicaCount` | Number of replicas                                                                                         | `1`                                           |
| `resources`    | CPU/memory limits and requests as key-value pairs                                                          | `limits: 1000m/3072Mi, requests: 100m/1024Mi` |
| `nodeSelector` | Schedule pods on nodes with specific labels as key-value pairs (e.g., `disktype: ssd`)                     | `{}`                                          |
| `tolerations`  | Allow pods to be scheduled on nodes with matching taints as a list of toleration objects                   | `[]`                                          |
| `affinity`     | Advanced scheduling rules for pod placement as key-value pairs (node affinity, pod affinity/anti-affinity) | `{}`                                          |
| `env`          | Worker-specific environment variables as key-value pairs                                                   | `{}`                                          |

#### Enabling or disabling job types for a worker

Use the `env` option to control which job types a worker handles:

- `AGENT_SERVICE_ENABLE_LIST`: Comma-separated list of job types to enable (worker handles **only** these)
- `AGENT_SERVICE_DISABLE_LIST`: Comma-separated list of job types to disable (worker handles **all except** these)

**Note:** You can only use one of these per worker, not both. Commas must be escaped with `\,` when using `--set`.

##### Available job types

| Job Type            | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| `http`              | Handles HTTP webhook requests for on-demand scanning         |
| `resource_scan`     | Scans configured data sources (repos, buckets, etc.)         |
| `content_scan`      | Scans content/files for secrets                              |
| `pull_request_scan` | Scans pull requests and merge requests for secrets           |
| `secrets_copy`      | Copies discovered secrets to HashiCorp Vault for remediation |

Example - disable PR scanning and content scanning on the default worker:

```
--set workers.items.default.env.AGENT_SERVICE_DISABLE_LIST="pull_request_scan\,content_scan" \
```
