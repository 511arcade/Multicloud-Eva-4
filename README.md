# Cruz Azul ERP — Arquitectura Multicloud (AWS)

> **Asignatura:** TI3053_N5_C2 — Arquitectura Multicloud
> **Evaluación N°4 (35%):** Integración de AutoScaling, Elastic Load Balancing y CloudWatch
> **Ruta de trabajo mandatoria:** `/srv/cruz_azul-erp/`
> **Presupuesto del proyecto:** 2.000 USD (Capex + Opex)

Este repositorio contiene la **maqueta funcional** solicitada por el Jefe de TI de la cadena de
farmacias **Cruz Azul**: un aplicativo **Web ERP** desplegado en **AWS** con **Auto Scaling Group**,
**Elastic Load Balancing (ALB)**, base de datos **PostgreSQL dockerizada (IaaS)** y monitoreo con
**Amazon CloudWatch**, sobre un escenario de producción seguro (AAA + MFA + subredes privadas).

---

## 1. ¿Qué incluye este repositorio?

| Componente | Ruta | Descripción |
|---|---|---|
| Frontend Web ERP | [`app/`](app/) | Aplicación **Node.js + Express** con portal de autenticación **condicional por token (JWT)**. |
| Base de datos IaaS | [`database/`](database/) | **PostgreSQL dockerizado** (docker-compose) con esquema y datos de ejemplo. |
| Bootstrap EC2 | [`scripts/`](scripts/) | Scripts `user-data` para arrancar las instancias Web ERP y BD, más pruebas de estrés (benchmarking). |
| IaC — Terraform | [`infra/terraform/`](infra/terraform/) | VPC, subredes públicas/privadas, Launch Template, **ASG (min 1 / desired 4 / max 8)**, **ALB**, y **alarmas CloudWatch**. |
| IaC — AWS CLI | [`infra/aws-cli/`](infra/aws-cli/) | Scripts paso a paso equivalentes para ejecutar en el **AWS Academy Lab**. |
| Instrucciones manuales AWS | [`docs/`](docs/) | Guía paso a paso de la **consola AWS** (crear AMI, ELB, ASG, CloudWatch) en `.md` y `.doc` (Word). |
| Informe y arquitectura | [`docs/`](docs/) | Plantilla del **informe técnico-comercial** (APA7), diagrama por capas, cronograma y valorización a 1 año. |

---

## 2. Arquitectura de referencia (modelo por capas)

```
                                Internet
                                   │
                          ┌────────▼─────────┐
                          │   Route 53 (A)   │  cruz-azul-erp-alb-...elb.amazonaws.com
                          └────────┬─────────┘
   ══════════════════ CAPA DE BORDE / BALANCEO ══════════════════
                          ┌────────▼─────────┐
                          │ Application LB   │  (Listener :80 / :443)
                          │  Target Group    │  Health check /health
                          └────────┬─────────┘
   ══════════════════ CAPA DE APLICACIÓN (subred pública/privada) ══
        ┌───────────────┬──────────┴───────┬───────────────┐
   ┌────▼────┐     ┌────▼────┐        ┌────▼────┐      ┌────▼────┐
   │ EC2 Web │     │ EC2 Web │  ...   │ EC2 Web │      │ EC2 Web │   Auto Scaling Group
   │  ERP #1 │     │  ERP #2 │        │  ERP #3 │      │  ERP #4 │   min 1 / desired 4 / max 8
   └────┬────┘     └────┬────┘        └────┬────┘      └────┬────┘
        └───────────────┴──────────┬───────┴───────────────┘
   ══════════════════ CAPA DE DATOS (subred privada) ═══════════════
                          ┌────────▼─────────┐
                          │ EC2 BD PostgreSQL │  (Docker) — IaaS
                          │  Security Group   │  solo :5432 desde SG-Web
                          └───────────────────┘
   ══════════════════ CAPA DE ALMACENAMIENTO ══════════════════════
                          ┌───────────────────┐
                          │      AWS S3        │  Objetos + ACL
                          └───────────────────┘

   Monitoreo transversal: Amazon CloudWatch (métricas de CPU, alarmas de escalado in/out)
   Seguridad transversal: IAM (AAA), MFA, Security Groups, subredes privadas
```

> El diagrama editable (Excalidraw) se documenta en [`docs/03-diagrama-arquitectura.md`](docs/03-diagrama-arquitectura.md).

---

## 3. Requisitos previos

- Cuenta **AWS Academy Learner Lab** (o AWS con permisos EC2/ELB/ASG/CloudWatch/IAM/S3).
- **AWS CLI v2** configurado (`aws configure` con las credenciales del Lab).
- **Terraform >= 1.5** (opcional, para el despliegue automatizado).
- **Docker** y **docker-compose** (para levantar PostgreSQL localmente o dentro de la EC2 de BD).
- **Node.js >= 18** (para el frontend).

---

## 4. Cómo ejecutar localmente (PoC rápida en tu máquina)

```bash
# 1) Levantar la base de datos PostgreSQL (IaaS dockerizado)
cd database
docker-compose up -d

# 2) Instalar y arrancar el Frontend Web ERP
cd ../app
cp .env.example .env      # ajusta credenciales de BD y JWT_SECRET
npm install
npm start                  # http://localhost:3000
```

Credenciales de ejemplo (ver seed de BD): `admin@cruzazul.cl` / `Admin123!`

---

## 5. Cómo desplegar en AWS

Tienes **dos caminos equivalentes**. Elige uno:

- **Automatizado (Terraform):** ver [`infra/terraform/README.md`](infra/terraform/README.md).
- **Manual / Lab (AWS CLI):** ver [`infra/aws-cli/README.md`](infra/aws-cli/README.md).

Para las tareas que **deben** hacerse desde la consola de AWS (crear AMI a partir de instancias en
ejecución, seguimiento visual del balanceador, capturas para el informe/video), sigue la guía
detallada en **[`docs/04-instrucciones-consola-aws.md`](docs/04-instrucciones-consola-aws.md)**
(también disponible como documento Word: `docs/Instrucciones-Consola-AWS.doc`).

---

## 6. Mapeo de requerimientos del enunciado → entregables

| # | Requerimiento (10 pts c/u) | Dónde se resuelve |
|---|---|---|
| 1 | Descripción técnica + esquematización por capas (DDF/Excalidraw) | `docs/01-descripcion-tecnica.md`, `docs/03-diagrama-arquitectura.md` |
| 2 | Estructura de proyecto en `/srv/cruz_azul-erp/` gestionada en GitHub | Este repositorio + `docs/02-guia-github.md` |
| 3 | BD PostgreSQL bajo modelo IaaS (dockerizada en EC2) | `database/`, `scripts/userdata-db.sh` |
| 4 | Frontend Node.js + Express con auth condicional por token | `app/` |
| 5 | Crear AMI desde EC2 Web ERP y EC2 BD | `docs/04-instrucciones-consola-aws.md` §5 |
| 6 | Balanceador de carga (justificación del tipo) | `infra/terraform/alb.tf`, `docs/05-justificacion-balanceador.md` |
| 7 | Launch Template + Auto Scaling Group acotado | `infra/terraform/asg.tf`, `infra/aws-cli/` |
| 8 | Escalado automático en subred privada (evidencia) | `scripts/stress-test.sh`, `docs/04-...` §8 |
| 9 | Alarmas CloudWatch + monitoreo de escalado/terminación | `infra/terraform/cloudwatch.tf` |
| 10 | Valorización a 1 año + cronograma con roles y tiempos | `docs/06-valorizacion-cronograma.md` |

---

## 7. Estructura de directorios

```
/srv/cruz_azul-erp/
├── README.md
├── app/                     # Frontend Node.js + Express (Web ERP)
├── database/                # PostgreSQL dockerizado (IaaS)
├── scripts/                 # user-data EC2 + benchmarking
├── infra/
│   ├── terraform/           # IaC declarativa (VPC, ASG, ALB, CloudWatch)
│   └── aws-cli/             # Scripts paso a paso para el Lab
└── docs/                    # Informe, diagramas, instrucciones de consola, valorización
```

---

## 8. Seguridad (AAA + MFA)

- **Authentication:** portal web con login; emisión de **JWT** firmado (token de acceso condicional).
- **Authorization:** middleware que valida el token y el rol en cada recurso protegido.
- **Accounting:** registro de accesos (log) de inicios de sesión y consumo de recursos.
- **MFA:** se documenta la habilitación de MFA para el usuario IAM y, a nivel de app, se deja
  preparado un segundo factor TOTP (ver `docs/07-seguridad-aaa-mfa.md`).

---

## 9. Repositorio y video

**Repositorio:** [https://github.com/511arcade/Multicloud-Eva-4](https://github.com/511arcade/Multicloud-Eva-4)

**Video-cápsula (YouTube, "no listado", 7–10 min):**  
👉 `https://youtu.be/<PEGA_AQUI_TU_ID>`
