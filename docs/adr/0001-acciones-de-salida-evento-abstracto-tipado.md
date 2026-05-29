# ADR-0001 — Acciones de salida: evento abstracto tipado (no eventos por tipo)

- **Estado:** Aceptado
- **Fecha:** 2026-05-29
- **Contexto relacionado:** `event-storming.md` (bloque transversal de mensajería), `mvp-scope.md` (cola de acciones de salida).

## Contexto

El cerebro emite "acciones de salida" que la capa no-code ejecuta sobre WhatsApp: bienvenida, contenido del día N (1..7), follow-up 1/2, CTA final, y posibles recordatorios futuros. Surgió la pregunta de cómo modelar estos eventos en el event log:

- **Opción A — eventos concretos por tipo:** `BienvenidaEncolada`, `ContenidoDiaNEncolada`, `BienvenidaEnviada`, `ContenidoDiaNEnviada`, `Followup1Enviada`, …
- **Opción B — evento abstracto tipado:** `AcciónEncolada { action_type, params }` + `AcciónResuelta { status }`.

## Decisión

Adoptamos la **Opción B**: un evento abstracto con discriminador tipado.

```
AcciónEncolada { action_type, params, dedupe_key }
AcciónResuelta { status: enviada | fallida, reason? }

// enum cerrado, dos familias:
action_type ∈
    // mensajes:
    { bienvenida, contenido_diario, followup_1, followup_2, cta_final, [recordatorio] }
    // gestión de grupo (no es un mensaje, pero reusa la misma cola/maquinaria):
    ∪ { alta_grupo }
params:  contenido_diario → { day: N };   alta_grupo → { grupo_id / referencia }
```

- El **día N es un parámetro (`params.day`), no un tipo de evento.**
- Se **colapsan** `AcciónEnviada` y `AcciónFallida` en un único `AcciónResuelta` con `status`.
- **`alta_grupo`** es una operación de **gestión de grupo** (no un mensaje con plantilla/variables). Se incluye en la cola porque comparte el mismo ciclo de vida y garantías de entrega (idempotencia, throttling, retry, ack); su `params` difiere (no lleva plantilla). El `MessagingPort` expone, entonces, dos capacidades: *enviar mensaje* y *gestionar grupo*.

## Fundamento

El heurístico aplicado: *modelar eventos concretos separados solo cuando tienen significado distinto o disparan reacciones distintas en el dominio.* En este caso, todas las acciones de salida comparten:

- **Mismo ciclo de vida**: `encolada → enviada/fallida`.
- **Mismo payload**: `{ recipiente, plantilla, variables, dedupe_key }`.
- **Misma reacción**: ninguna policy del dominio reacciona distinto según el tipo de acción enviada; las reacciones cuelgan de eventos de **entrada** (`VideoVisto`, `PagoP60Recibido`), no de las salidas.
- **Misma maquinaria**: idempotencia, throttling, retry y ack se aplican igual a todas.

Eventos concretos solo duplicarían la misma lógica N veces y provocarían explosión combinatoria cuando crezca el contenido (día 8, `followup_3`, recordatorios nuevos).

## Consecuencias

**Positivas**
- Event log limpio (~14 tipos de evento en vez de >16 que crecen con cada plantilla nueva).
- Una sola maquinaria de cola (idempotencia/throttling/retry/ack) para todas las acciones.
- Analítica por tipo vía `GROUP BY action_type` (ej. "% de fallos en followup_2") sin proliferar eventos.
- Type-safety: `action_type` es un enum cerrado, no un string libre.

**Negativas / a vigilar**
- Los consumidores que quieran reaccionar a un tipo puntual deben filtrar por `action_type`.
- Si en el futuro una acción concreta (ej. `cta_final`) debe disparar una policy propia, se la **promueve** a evento concreto en ese momento. Esta decisión no lo impide.

## Alternativas descartadas

- **Opción A (eventos por tipo):** descartada por explosión combinatoria, duplicación de lógica y porque el día N es un dato, no un tipo.
