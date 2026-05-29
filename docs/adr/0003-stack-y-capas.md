# ADR-0003 — Stack y organización de capas

- **Estado:** Aceptado (stack) — alineado a `mvp-scope.md` y `engineering-guidelines.md`
- **Fecha:** 2026-05-29

## Contexto

Necesitamos un stack para el "cerebro" (formulario público + dashboard interno + API de webhooks/cola) que sea productivo, tipado y compatible con la arquitectura hexagonal y el event log.

## Decisión

- **Lenguaje:** TypeScript.
- **Framework:** Next.js 15 (App Router) — sirve el formulario público, el dashboard interno y las rutas HTTP (webhooks + cola de acciones) en un solo monolito modular.
- **ORM / DB:** Drizzle + **PostgreSQL** (transaccional, JSONB para `payload` de eventos, índices por `token`/`whatsapp_number`/`dedupe_key`).
- **UI:** Tailwind + shadcn/ui (los wireframes ya usan esa dirección visual).
- **Organización de capas:** hexagonal según `engineering-guidelines.md` (domain / application / ports / infrastructure / app / composition).

## Fundamento

- TS + Next.js: un solo lenguaje front+back, tipado de los contratos (`contracts/`), ecosistema maduro.
- Postgres: encaja con event log + estado materializado (ADR-0002), transaccional, JSONB.
- Monolito modular: simple de operar para un MVP single-tenant; la hexagonalidad deja la puerta abierta a extraer piezas si algún día hiciera falta (no en MVP).

## Consecuencias

Positivas: productividad, tipos extremo a extremo, despliegue simple. Negativas: acoplamiento al ecosistema JS/TS (aceptable). El scheduler (contenido diario, timeouts) se resuelve con cron + cola; ver infraestructura en ADR-0004.

## Alternativas descartadas
- Backend separado (NestJS/FastAPI) + front aparte: más piezas sin beneficio claro para el MVP.
