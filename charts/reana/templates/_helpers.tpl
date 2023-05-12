{{/* Start of SLATE req*/}}
{{- define "reana.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "reana.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "reana.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* End of SLATE req*/}}

{{/*
Create a default fully qualified app name.
We truncate the prefix at 13 chars because some Kubernetes name fields are
limited to 63 characters (by the DNS naming spec) and because REANA components
are created with a certain naming schema they should not, in total, overpass
this limit. For example, if prefix would be `my-awesome-reana`, 17 chars, when
a yadage workflow would be spawned would break the 63 char limit of the DNS
naming spec: `my-reana-batch-yadage-3c640169-d3b7-41ad-9c09-392c903fc1d8`
*/}}
{{- define "reana.prefix" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 13 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 13 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

# Centralise prefixing of service account names
{{- define "reana.prefixed_infrastructure_svaccount_name" -}}
{{- include "reana.prefix" . -}}-infrastructure
{{- end -}}
{{- define "reana.prefixed_runtime_svaccount_name" -}}
{{- include "reana.prefix" . -}}-runtime
{{- end -}}

{{/* Create the specification of the shared volume. */}}
{{- define "reana.shared_volume" -}}
{{- if not (eq .Values.shared_storage.backend "hostpath") -}}
persistentVolumeClaim:
  claimName: {{ include "reana.prefix" . }}-shared-persistent-volume
  readOnly: false
{{- else -}}
hostPath:
  path: {{ .Values.shared_storage.hostpath.root_path }}
{{- end -}}
{{- end -}}

{{/*
Create the specification of the infrastructure volume used by MQ and database.
If the infrastructure volume is not defined, the default shared volume is used instead.
*/}}
{{- define "reana.infrastructure_volume" -}}
{{- if .Values.infrastructure_storage -}}
{{- if not (eq .Values.infrastructure_storage.backend "hostpath") -}}
persistentVolumeClaim:
  claimName: {{ include "reana.prefix" . }}-infrastructure-persistent-volume
  readOnly: false
{{- else -}}
hostPath:
  path: {{ .Values.infrastructure_storage.hostpath.root_path }}
{{- end -}}
{{- else -}}
{{ template "reana.shared_volume" . }}
{{- end -}}
{{- end -}}
