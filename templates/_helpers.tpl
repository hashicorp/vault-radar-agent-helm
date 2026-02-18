{{/*
Expand the name of the chart.
*/}}
{{- define "vault-radar-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vault-radar-agent.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | lower | replace " " "-" | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | lower | replace " " "-" | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | lower | replace " " "-" | trunc 63 | trimSuffix "-" }}
{{- end }}{{- end }}{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "vault-radar-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vault-radar-agent.labels" -}}
app: {{ include "vault-radar-agent.fullname" . }}
helm.sh/chart: {{ include "vault-radar-agent.chart" . }}
{{ include "vault-radar-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vault-radar-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vault-radar-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create env variables
*/}}
{{- define "vault-radar-agent.listEnvVariables" -}}
{{- range $key, $val := .Values.env.secrets }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: "{{ include "vault-radar-agent.fullname" $ }}"
      key: {{ $key }}
{{- end }}
{{- range $key, $val := .Values.env.normal }}
- name: {{ $key }}
  value: {{ $val | required (printf "required parameter %s is missing" $key) | quote }}
{{- end }}
{{- range $key, $val := .Values.env.optional }}
- name: {{ $key }}
  value: {{ $val | default "" | quote }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vault-radar-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "vault-radar-agent.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create cluster role binding name to use
*/}}
{{- define "vault-radar-agent.clusterRoleBindingName" -}}
{{- include "vault-radar-agent.fullname" . -}}
{{- end -}}

{{/*
Validate workers: at least one enabled, deployment names don't exceed 63 chars
*/}}
{{- define "vault-radar-agent.validateWorkers" -}}
{{- $fullname := include "vault-radar-agent.fullname" . -}}
{{- $enabledWorkers := 0 -}}
{{- range $name, $worker := .Values.workers.items -}}
{{- if not $worker.name -}}
{{- fail (printf "Worker '%s' is missing required field 'name'" $name) -}}
{{- end -}}
{{- if $worker.enabled -}}
{{- $enabledWorkers = add $enabledWorkers 1 -}}
{{- $deploymentName := printf "%s-%s" $fullname $worker.name -}}
{{- if gt (len $deploymentName) 63 -}}
{{- fail (printf "Deployment name '%s' exceeds 63 characters (%d). Shorten fullnameOverride or worker name." $deploymentName (len $deploymentName)) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if eq $enabledWorkers 0 -}}
{{- fail "At least one worker must be enabled in workers.items" -}}
{{- end -}}
{{- end -}}
