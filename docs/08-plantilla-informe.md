# Plantilla — Informe Técnico-Comercial (INACAP / APA7)

> Formato institucional INACAP (Carta), Norma APA7 para estudiantes. Copia esta estructura a tu
> procesador de texto. El informe corresponde al **50%** de la evaluación; el video al otro 50%.

## Portada
- Logo INACAP · Nombre de la asignatura: **Arquitectura Multicloud (TI3053_N5_C2)**
- Título: *Integración de AutoScaling, Elastic Load Balancing y CloudWatch para el ERP de Cruz Azul*
- Integrantes · Docente: Marcos Pozas S. · Fecha de entrega: **02 de julio, 12:25 hrs**

## Índice de contenidos
1. Introducción (caso de estudio)
2. Objetivos (general y específicos)
3. Descripción técnica de la problemática
4. Arquitectura propuesta (modelo por capas + DDF/Excalidraw)
5. Tecnologías involucradas
6. Desarrollo y testeo del escenario (PoC)
   - 6.1 Estructura del proyecto en `/srv/cruz_azul-erp/` (GitHub)
   - 6.2 Base de datos PostgreSQL (IaaS dockerizado)
   - 6.3 Frontend Web ERP con acceso condicional por token
   - 6.4 Creación de AMIs
   - 6.5 Balanceador de carga (justificación)
   - 6.6 Launch Template + Auto Scaling Group
   - 6.7 Escalado automático en subred privada (benchmarking)
   - 6.8 Alarmas y monitoreo con CloudWatch
7. Resultados esperados y obtenidos
8. Justificación de decisiones
9. Valorización a 1 año y cronograma (roles y tiempos)
10. Conclusiones y comentarios finales
11. Referencias (APA7)
12. Anexos
    - Enlace al repositorio GitHub/GitLab
    - Enlace a la videocápsula (YouTube, no listado)

## Recomendaciones de evidencia (capturas)
- Repositorio en GitHub y estructura de carpetas.
- `docker ps` con PostgreSQL corriendo y conexión desde el frontend.
- Portal de login (con y sin MFA) y dashboard mostrando la instancia atendiendo.
- Consola de AMIs en estado *available*.
- ALB con Target Group *healthy* y su DNS.
- ASG con 4 instancias en subred privada; *Activity history* de scale-out/scale-in.
- Alarmas de CloudWatch *In alarm/OK* y el dashboard de CPU durante el benchmarking.
- Tabla de valorización y cronograma.
```
