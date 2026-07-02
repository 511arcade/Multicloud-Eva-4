# 04 — Instrucciones paso a paso en la Consola de AWS

> Estas son las tareas que **debes realizar manualmente en la consola de AWS** (o que conviene
> hacer en consola para capturar evidencia para el informe y el video). Está también disponible
> como documento Word: **`Instrucciones-Consola-AWS.doc`**.

---

## Requisito previo: iniciar el AWS Academy Learner Lab
1. Ingresa a AWS Academy → tu curso → **Learner Lab** → **Start Lab** (espera el punto verde).
2. Clic en **AWS** para abrir la consola. Trabaja en la región habilitada (normalmente `us-east-1`).
3. Si vas a usar la CLI, copia las credenciales desde **AWS Details → AWS CLI**.

---

## §3. Base de datos PostgreSQL (IaaS dockerizado)
1. **EC2 → Launch Instance**. Nombre `cruz-azul-db`. AMI: **Amazon Linux 2023**. Tipo `t3.micro`.
2. Red: tu **VPC**, **subred privada**, Security Group **SG-DB** (5432 solo desde SG-Web).
3. En **User data** (Advanced details) pega el contenido de `scripts/userdata-db.sh`
   (ajusta la URL del repo y la contraseña).
4. Lanza la instancia. Al arrancar instalará Docker y levantará PostgreSQL en el puerto 5432.
5. Anota la **IP privada** de esta instancia (la usará el Web ERP en su `.env`).

---

## §4. Frontend Web ERP (primera instancia, para crear la AMI)
1. **EC2 → Launch Instance**. Nombre `cruz-azul-web-base`. AMI: **Amazon Linux 2023**. Tipo `t3.micro`.
2. Red: **subred pública** temporalmente (para instalar), SG **SG-Web**.
3. **User data**: pega `scripts/userdata-web.sh` y reemplaza `CHANGE_ME_DB_PRIVATE_IP` por la IP
   privada de la BD y `JWT_SECRET` por un valor aleatorio.
4. Lanza y espera. Verifica en el navegador `http://<IP-pública>:3000/health` → debe responder `ok`.

---

## §5. Crear las AMIs (requerimiento #5)
Debes crear una AMI a partir de la instancia **Web ERP** y otra de la **BD** en ejecución.

1. **EC2 → Instancias** → selecciona `cruz-azul-web-base`.
2. **Acciones → Imagen y plantillas → Crear imagen**.
3. Nombre: `ami-cruz-azul-web`. Descripción y **Sin reinicio** opcional. Clic **Crear imagen**.
4. Repite con la instancia de BD → nombre `ami-cruz-azul-db`.
5. Ve a **EC2 → AMIs** y espera estado **available**. **Copia el AMI ID** del Web ERP.
6. Ese AMI ID se usa en el Launch Template (Terraform `ami_id` o script `02-...` variable `AMI_ID`).

> **Captura de evidencia:** pantalla de "Crear imagen" y la lista de AMIs en estado *available*.

---

## §6. Balanceador de carga (requerimiento #6)
> Elegimos un **Application Load Balancer (ALB)** — justificación en `05-justificacion-balanceador.md`.

1. **EC2 → Load Balancers → Create Load Balancer → Application Load Balancer**.
2. Nombre `cruz-azul-erp-alb`. Esquema **internet-facing**. IP type IPv4.
3. **Network mapping**: tu VPC, marca las **dos subredes públicas** (dos AZ).
4. **Security groups**: selecciona **SG-ALB**.
5. **Listeners and routing**: Listener HTTP :80 → **Create target group**:
   - Tipo **Instances**, nombre `cruz-azul-erp-tg`, protocolo HTTP puerto **3000**.
   - **Health check** path `/health`, código `200`. Crear.
6. Vuelve al asistente del ALB, selecciona el target group recién creado, **Create load balancer**.
7. Copia el **DNS name** del ALB (registro A) para el seguimiento y el informe.

---

## §7. Launch Template + Auto Scaling Group (requerimiento #7)
1. **EC2 → Launch Templates → Create launch template**.
   - Nombre `cruz-azul-erp-lt`. AMI: **`ami-cruz-azul-web`** (la que creaste). Tipo `t3.micro`.
   - Security group: **SG-Web**. Key pair opcional.
   - (Si usas AMI base en vez de la personalizada, pega `scripts/userdata-web.sh` en *User data*).
2. **EC2 → Auto Scaling Groups → Create Auto Scaling group**.
   - Nombre `cruz-azul-erp-asg`. Selecciona el **launch template**.
   - Red: tu VPC y las **dos subredes privadas**.
   - **Load balancing**: *Attach to an existing load balancer* → *from your target groups* →
     `cruz-azul-erp-tg`. Health check type: **ELB**.
   - **Group size**: **Desired = 4**, **Minimum = 1**, **Maximum = 8**.
   - **Scaling policies**: *Target tracking* → métrica **Average CPU utilization** → **60%**.
   - Crear el grupo. Verás cómo lanza 4 instancias y se registran como *healthy* en el TG.

> **Captura de evidencia:** el ASG con 4 instancias *InService* y el Target Group *healthy*.

---

## §8. Escalado automático en subred privada (requerimiento #8)
1. Confirma que las instancias del ASG están en **subredes privadas** (columna Subnet ID).
2. Ejecuta la prueba de estrés contra el DNS del ALB:
   ```bash
   bash scripts/stress-test.sh http://<DNS-DEL-ALB> 50 300
   ```
   O usa el endpoint de carga de CPU (requiere token de admin):
   `GET http://<DNS-DEL-ALB>/erp/api/cpu-load?ms=15000`
3. En unos minutos la CPU promedio superará el 60% y el ASG hará **scale-out** (nuevas instancias).
4. Al detener la carga, tras el cooldown, hará **scale-in** (terminación de instancias).

> **Captura de evidencia:** *Activity history* del ASG mostrando "Launching a new EC2 instance"
> y luego "Terminating EC2 instance".

---

## §9. Alarmas de CloudWatch (requerimiento #9)
Si creaste el ASG con Target Tracking, CloudWatch genera las alarmas automáticamente. Para crear
alarmas explícitas y monitorear:
1. **CloudWatch → Alarms → Create alarm → Select metric**.
2. **EC2 → By Auto Scaling Group** → `cruz-azul-erp-asg` → **CPUUtilization** (Average, 60s).
3. Condición: **Greater/Equal 60** → acción: **Auto Scaling → scale-out**. Nombre `cpu-high`.
4. Repite con **Lower/Equal 20** → **scale-in**. Nombre `cpu-low`.
5. **CloudWatch → Dashboards**: crea `cruz-azul-erp-dashboard` con widgets de CPU e instancias
   en servicio para el informe/video.

> **Captura de evidencia:** alarmas en estado **In alarm/OK** durante la prueba y el dashboard.

---

## §10. Seguridad adicional (AAA + MFA)
1. **IAM → Users →** tu usuario **→ Security credentials → Assign MFA device** (app TOTP).
   *(En el Learner Lab el usuario es fijo; documenta el procedimiento con capturas del panel MFA).*
2. A nivel de aplicación, activa `MFA_ENABLED=true` en el `.env` del Web ERP y registra un
   `mfa_secret` para el usuario (ver `07-seguridad-aaa-mfa.md`).

---

## Limpieza al finalizar
- Consola: elimina ASG → ALB/TG → Launch Template → AMIs → instancias → NAT/EIP → VPC.
- O ejecuta `bash infra/aws-cli/99-cleanup.sh` / `terraform destroy`.
- **Stop Lab** en AWS Academy para no consumir presupuesto.
