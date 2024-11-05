{{- define "testme.fullname" -}}
{{- .Values.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "testme.labels" -}}
app: {{ .Values.name }}
{{- end -}}

{{- define "testme.selectorLabels" -}}
app: {{ .Values.name }}
{{- end -}}
