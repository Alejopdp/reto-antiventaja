# Contratos — frontera del sistema

> Las interfaces que definen los 3 puertos de la arquitectura hexagonal y la frontera HTTP con la capa no-code. El **core de dominio depende solo de estas interfaces**, nunca de herramientas concretas (ver ADR-0001 y `domain-model.md`).
> Estado: borrador de diseño (no implementado). TypeScript como lenguaje de referencia (stack Next.js + TS).

## Archivos
- [`ports.md`](./ports.md) — los 3 puertos (`MessagingPort`, `VideoTrackingPort`, `PaymentPort`) + tipos compartidos.
- [`http-boundary.md`](./http-boundary.md) — endpoints HTTP: webhooks de entrada y cola de acciones de salida (lo que consume/llama la capa no-code, el host de vídeo y el PSP).

## Convenciones transversales

- **Identidad (el crux):** cada participante tiene un `token` opaco y único. Viaja en todo link de contenido/vídeo/pago para resolver identidad. El número de WhatsApp se normaliza a **E.164**. Matching por número cuando no hay token; lo no resuelto va a bandeja de Ops.
- **Idempotencia:**
  - *Entrada* (webhooks): deduplicar por el id de evento del proveedor (`providerEventId`). Reprocesar el mismo webhook no debe duplicar efectos (Q26, Q32).
  - *Salida* (acciones): `dedupeKey` único por `(participantId, propósito)`; nunca dos acciones con el mismo `dedupeKey` (ADR-0001).
- **Orden:** ningún handler asume orden estricto de eventos; el estado se computa por reglas tolerantes (Q32).
- **Tiempos:** ISO-8601 con zona; el "día N" se ancla a `joinedGroupAt` (Q31).
- **Seguridad:** webhooks verificados por firma/secreto compartido; la cola de acciones requiere auth de la capa no-code.
- **Errores:** los adaptadores traducen errores del proveedor; el core recibe tipos de dominio o `null` (descartado, va a bandeja).

## ⚠️ Dependencia de Q1
`VideoTrackingPort` y toda la segmentación de follow-up **asumen entrega 1:1 con link tokenizado**. Si el cliente decide contenido/replay en **broadcast al grupo**, este puerto no recibe datos por persona y el flujo D (follow-up) cambia de raíz. Ver `open-questions.md` Q1.
