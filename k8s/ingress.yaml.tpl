apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devops-status-page
  namespace: devops-status
spec:
  ingressClassName: nginx
  rules:
    - host: __APP_HOST__
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: devops-status-page
                port:
                  number: 80
