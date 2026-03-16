{{/*
Generate the fullname: use .Values.name if set, otherwise chart name
*/}}
{{- define "microservice.fullname" -}}
{{- .Values.name | default .Chart.Name -}}
{{- end -}}

{{/*
Common labels applied to all resources
*/}}
{{- define "microservice.labels" -}}
app.kubernetes.io/name: {{ include "microservice.fullname" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{/*
Selector labels (used in Deployment + Service to match pods)
*/}}
{{- define "microservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "microservice.fullname" . }}
{{- end -}}
