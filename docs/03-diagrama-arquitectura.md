# 03 — Diagrama de arquitectura (modelo por capas)

> Fuente editable recomendada: **Excalidraw** (https://excalidraw.com). Exporta como PNG y
> anéxalo al informe. A continuación, el diagrama de referencia y los elementos a dibujar.

```
                                   Internet / Cliente Web
                                            │
                                   ┌────────▼─────────┐
                                   │   Route 53 (A)   │
                                   └────────┬─────────┘
   ══════════════════════ CAPA DE BORDE / BALANCEO ══════════════════════
                          ┌─────────────────▼──────────────────┐
                          │   Application Load Balancer (ALB)   │
                          │   Listener :80/:443  ·  SG-ALB      │
                          │   Target Group  ·  Health /health   │
                          └─────────────────┬──────────────────┘
   ══════════════════════ CAPA DE APLICACIÓN (subredes privadas) ═════════
        ┌──────────────┬──────────────┴───────┬──────────────┐
   ┌────▼────┐    ┌────▼────┐            ┌────▼────┐     ┌────▼────┐
   │ EC2 Web │    │ EC2 Web │    ...     │ EC2 Web │     │ EC2 Web │   Auto Scaling Group
   │  ERP    │    │  ERP    │            │  ERP    │     │  ERP    │   min 1 / desired 4 / max 8
   │ :3000   │    │ :3000   │            │ :3000   │     │ :3000   │   SG-Web
   └────┬────┘    └────┬────┘            └────┬────┘     └────┬────┘
        └──────────────┴──────────────┬───────┴──────────────┘
   ══════════════════════ CAPA DE DATOS (subred privada) ════════════════
                          ┌───────────▼────────────┐
                          │  EC2 PostgreSQL (Docker)│  IaaS
                          │  :5432  ·  SG-DB        │
                          └─────────────────────────┘
   ══════════════════════ CAPA DE ALMACENAMIENTO ════════════════════════
                          ┌─────────────────────────┐
                          │        AWS S3           │  Objetos + ACL
                          └─────────────────────────┘

   Monitoreo transversal:  Amazon CloudWatch (CPUUtilization, alarmas high/low, dashboard)
   Seguridad transversal:  IAM (AAA) · MFA · Security Groups por capa · NAT Gateway
```

## Elementos a representar en Excalidraw
1. Nube de AWS englobando todo, con una **VPC 10.0.0.0/16**.
2. Dos **subredes públicas** (ALB + NAT) y dos **subredes privadas** (Web ERP + BD) en 2 AZ.
3. Flechas de tráfico: Internet → ALB → EC2 Web (Target Group) → EC2 BD.
4. Íconos de **CloudWatch** conectados al ASG (métricas/alarmas) y a las políticas de escalado.
5. Íconos de **IAM/MFA** y candados en los Security Groups para resaltar la seguridad.
6. Ícono de **S3** conectado desde la capa de aplicación.
