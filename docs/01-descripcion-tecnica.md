# 01 — Descripción técnica de la problemática

## Contexto (caso de estudio)
La cadena de farmacias **Cruz Azul** requiere integrar mecanismos de **monitoreo, escalado y balanceo
de carga** para su aplicativo **ERP** desplegado en un Cloud Service Provider. Por políticas de
cumplimiento de la organización, es **mandatorio** utilizar **Amazon Web Services (AWS)**.

## Objetivo
Construir una **maqueta funcional** de una infraestructura segura de producción que integre:
- **Cómputo:** instancias EC2 en un **Auto Scaling Group** (deseada 4 / mínima 1 / máxima 8).
- **Balanceo:** **Elastic Load Balancing** (Application Load Balancer) para distribuir el tráfico.
- **Base de datos:** **PostgreSQL** bajo modelo **IaaS** (dockerizado en EC2).
- **Almacenamiento de objetos:** **AWS S3** con **ACL** para acceso a objetos.
- **Monitoreo:** **Amazon CloudWatch** con alarmas y benchmarking del rendimiento.
- **Seguridad (AAA + MFA):** acceso condicional por token, autorización por rol y MFA.

## Modelo por capas (seguridad de la arquitectura)

| Capa | Componentes | Controles de seguridad |
|---|---|---|
| **Borde / Balanceo** | Route 53, Application Load Balancer | SG-ALB (solo 80/443 desde Internet), health checks |
| **Aplicación** | EC2 Web ERP (Node.js/Express) en ASG | SG-Web (solo :3000 desde el ALB), subredes privadas, JWT |
| **Datos** | EC2 PostgreSQL (Docker) | SG-DB (solo :5432 desde SG-Web), subred privada aislada |
| **Almacenamiento** | AWS S3 | ACL por objeto, cifrado, versionado, bloqueo público |
| **Transversal** | IAM, CloudWatch | AAA, MFA, alarmas, dashboard de métricas |

## Flujo de una petición
1. El cliente web accede al **DNS del ALB** (registro A).
2. El ALB reparte la petición entre las instancias **sanas** del Target Group (health check `/health`).
3. La instancia Web ERP valida el **token JWT** (acceso condicional) antes de servir recursos.
4. La app consulta la **BD PostgreSQL** en la subred privada (solo alcanzable desde SG-Web).
5. **CloudWatch** monitorea la CPU; al superar el umbral dispara el **escalado** del ASG.

## Diagrama de Despliegue Físico (DDF)
Ver el diagrama por capas en [`03-diagrama-arquitectura.md`](03-diagrama-arquitectura.md)
(fuente editable en **Excalidraw**).
