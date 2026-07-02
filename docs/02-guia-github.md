# 02 — Estructura y control de versiones (GitHub)

El enunciado exige que el proyecto se genere en un nodo local/remoto bajo la ruta de trabajo
**`/srv/cruz_azul-erp/`** y sea gestionado desde **GitHub**.

## Crear el repositorio y publicar

```bash
# 1) Ubicar el proyecto en la ruta mandatoria (en el servidor/EC2)
sudo mkdir -p /srv
sudo chown "$USER" /srv
cp -r ./ /srv/cruz_azul-erp     # o clona directamente ahí
cd /srv/cruz_azul-erp

# 2) Inicializar git y primer commit
git init
git add .
git commit -m "feat: maqueta funcional Cruz Azul ERP (ASG + ALB + CloudWatch)"

# 3) Crear el repo remoto y publicar (reemplaza <usuario>)
git branch -M main
git remote add origin https://github.com/<usuario>/cruz_azul-erp.git
git push -u origin main
```

## Flujo de trabajo sugerido (control de avances)
- Rama `main`: versión estable/entregable.
- Ramas `feature/*`: cada requerimiento (frontend, bd, infra, docs).
- Commits atómicos con prefijos convencionales: `feat:`, `fix:`, `docs:`, `chore:`.
- Etiqueta la entrega: `git tag v1.0-eva4 && git push --tags`.

## Recuerda
Agrega el **enlace del repositorio** en la sección final del informe técnico-comercial y
comparte acceso al docente para revisión.
