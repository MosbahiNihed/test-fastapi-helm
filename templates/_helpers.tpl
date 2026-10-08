{{/*
Env vars of the app container:
every item of .Values.env: {name, value} (DB_HOST, DB_PORT, ...) or
{name, valueFrom} (DB_USER, DB_PASSWORD from the credentials Secret)
*/}}
{{- define "test-fastapi.env" -}}
{{- $names := list -}}
{{- range .Values.env }}{{ $names = append $names .name }}{{ end -}}
{{- if not (has "DB_HOST" $names) }}{{ fail "env must contain DB_HOST" }}{{ end -}}
{{- range .Values.env }}
- name: {{ .name }}
  {{- if hasKey . "valueFrom" }}
  valueFrom:
    {{- toYaml .valueFrom | nindent 4 }}
  {{- else }}
  value: {{ .value | quote }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Liquibase image: repository as is if it has a tag, else repository:image.tag.
*/}}
{{- define "test-fastapi.liquibaseImage" -}}
{{- $repo := .Values.liquibase.repository -}}
{{- if regexMatch ":[^/]+$" $repo -}}
{{- $repo -}}
{{- else -}}
{{- printf "%s:%s" $repo .Values.image.tag -}}
{{- end -}}
{{- end -}}
