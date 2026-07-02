# 06 — Valorización a 1 año y cronograma

> Presupuesto tope del proyecto: **2.000 USD (Capex + Opex)**. Los valores son estimaciones
> referenciales para `us-east-1`; ajústalos con la **AWS Pricing Calculator** para el informe final.

## A. Valorización (12 meses de operación)

### Capex (costos de implementación — una vez)
| Ítem | Detalle | USD |
|---|---|---|
| Diseño e ingeniería de arquitectura | Diagrama, IaC, hardening | 400 |
| Desarrollo/adaptación del Web ERP | Frontend Node.js + auth | 300 |
| Configuración y pruebas (PoC) | ASG, ALB, CloudWatch, benchmarking | 200 |
| **Subtotal Capex** | | **900** |

### Opex (costos recurrentes — estimación anual)
| Servicio AWS | Supuesto | USD/mes | USD/año |
|---|---|---|---|
| EC2 Web ERP (ASG) | Prom. 2 × t3.micro on-demand | ~15 | ~180 |
| EC2 BD PostgreSQL | 1 × t3.micro | ~7.5 | ~90 |
| Application Load Balancer | 1 ALB + LCU | ~18 | ~216 |
| NAT Gateway | 1 (horas + datos) | ~35 | ~420 |
| Almacenamiento S3 | < 50 GB + requests | ~2 | ~24 |
| CloudWatch | Alarmas + dashboard | ~3 | ~36 |
| Transferencia de datos | Salida moderada | ~3 | ~36 |
| **Subtotal Opex** | | | **~1.002** |

### Total estimado a 1 año
| | USD |
|---|---|
| Capex | 900 |
| Opex (12 meses) | ~1.002 |
| **Total** | **~1.902** |
| **Presupuesto** | **2.000** |
| **Holgura** | **~98** |

> **Optimización:** para reducir Opex se puede prescindir del NAT (ASG en subred pública) o usar
> instancias Spot/Savings Plans, liberando presupuesto para más pruebas.

## B. Cronograma del proyecto (roles y tiempos)

| Fase | Actividades | Responsable (rol) | Duración |
|---|---|---|---|
| 1. Análisis y diseño | Levantamiento, diagrama por capas, DDF | Arquitecto Cloud | 3 días |
| 2. Infraestructura base | VPC, subredes, SG, NAT, IAM/MFA | Ingeniero DevOps | 3 días |
| 3. Base de datos IaaS | EC2 + PostgreSQL dockerizado, esquema/seed | Administrador BD | 2 días |
| 4. Frontend Web ERP | Node.js/Express, auth por token | Desarrollador | 4 días |
| 5. AMI + Launch Template | Imágenes y plantilla de lanzamiento | Ingeniero DevOps | 1 día |
| 6. ALB + Auto Scaling | Balanceador, ASG, políticas | Ingeniero Cloud | 2 días |
| 7. CloudWatch + pruebas | Alarmas, benchmarking, evidencias | QA / DevOps | 2 días |
| 8. Documentación y video | Informe APA7 + videocápsula | Líder de proyecto | 3 días |
| | | **Total** | **~20 días hábiles** |

### Diagrama de Gantt (referencial)
```
Fase 1  ██
Fase 2    ██
Fase 3      █
Fase 4       ████
Fase 5           █
Fase 6            ██
Fase 7              ██
Fase 8                ███
        Semana 1   Semana 2   Semana 3   Semana 4
```
