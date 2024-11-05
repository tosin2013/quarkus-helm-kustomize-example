apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.name }}-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>{{ .Values.custom.title | default "Custom Nginx Page" }}</title>
    </head>
    <body>
      <h1>{{ .Values.custom.heading | default "Welcome to My Custom Nginx Page!" }}</h1>
    </body>
    </html>
