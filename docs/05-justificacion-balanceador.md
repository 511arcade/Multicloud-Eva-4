# 05 — Justificación del balanceador de carga

## Decisión: Application Load Balancer (ALB)

Para el aplicativo **Web ERP** de Cruz Azul se elige un **Application Load Balancer (ALB)**,
que opera en la **capa 7 (HTTP/HTTPS)** del modelo OSI.

## Comparativa

| Criterio | ALB (Capa 7) ✅ | NLB (Capa 4) | CLB (clásico) |
|---|---|---|---|
| Protocolo del ERP (HTTP/HTTPS) | Nativo | Solo TCP/UDP | HTTP/TCP (legado) |
| Health check a nivel de app (`/health`) | Sí | Limitado | Básico |
| Ruteo por path/host | Sí | No | No |
| Integración con Auto Scaling + Target Groups | Excelente | Buena | Limitada |
| Terminación TLS y reglas | Sí | Parcial | Sí (legado) |
| Recomendado por AWS para apps web | **Sí** | Para alto rendimiento TCP | Deprecado |

## Fundamentos
1. **El ERP es una aplicación web HTTP/HTTPS**, por lo que el ALB es el balanceador idóneo.
2. Permite **health checks a nivel de aplicación** (`GET /health`), sacando de rotación las
   instancias no sanas y mejorando la disponibilidad.
3. Se integra de forma nativa con el **Auto Scaling Group** vía **Target Group**, registrando y
   desregistrando instancias automáticamente durante el escalado.
4. Habilita **enrutamiento avanzado** (por ruta/host) y **terminación TLS** para el consumo seguro.
5. El **CLB (Classic)** está en desuso y el **NLB** está orientado a tráfico TCP/UDP de muy alto
   rendimiento, innecesario para una app web transaccional como este ERP.

## Seguimiento
El seguimiento del balanceador se realiza a través del **nombre DNS del ALB (registro A)**,
por ejemplo: `cruz-azul-erp-alb-123456789.us-east-1.elb.amazonaws.com`.
