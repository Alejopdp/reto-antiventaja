# ADR-0004 — Cloud y hosting de datos

- **Estado:** **Propuesto (a confirmar con el dueño)**
- **Fecha:** 2026-05-29

## Contexto

Hay que elegir dónde corre el app (Next.js), dónde vive Postgres, y cómo se ejecutan las tareas programadas (contenido diario, timeouts del replay) y la cola de acciones. Volumen: ~300+/cohorte, recurrente, single-tenant, mercado **España** (preferible región UE por GDPR).

## Decisión propuesta (no cerrada)

- **Hosting del app:** **Vercel** (encaja con Next.js; cron jobs nativos para el scheduler; despliegue simple).
- **Base de datos:** **Postgres gestionado en región UE** — candidato **Neon** (vía Vercel Marketplace) o equivalente; alternativa **AWS RDS** (eu-west-1) si se prefiere AWS.
- **Cola / jobs:** cron de Vercel + tabla `outbound_action` como cola (drenada por la capa no-code); para necesidades durables, evaluar Vercel Queues. Sin broker dedicado en MVP.
- **Región:** UE (GDPR / latencia España).

## Trade-offs / a decidir

- **Vercel + Neon**: máxima velocidad de arranque, ops mínima, alineado al stack. Menos control de infra.
- **AWS (RDS + ECS/Lambda)**: más control y coherencia si el dueño ya opera en AWS; más setup. *(Nota: otros proyectos del entorno usan AWS, pero este repo es de otra organización/owner — decidir según preferencia del dueño de Reto Antiventaja.)*

## Por qué queda "Propuesto"

La elección de cloud es del dueño y conviene cruzarla con la **investigación de integraciones** (PSP/host de video/automatizador) y con dónde quieran operar. No bloquea el inicio: la arquitectura hexagonal + Drizzle hacen que el core sea agnóstico del hosting; cambiar de cloud no toca dominio/aplicación.

## Consecuencias
Una vez confirmado, este ADR pasa a "Aceptado" y se fija región UE + el proveedor de DB. Hasta entonces, los agentes asumen Vercel + Postgres UE como default reversible.
