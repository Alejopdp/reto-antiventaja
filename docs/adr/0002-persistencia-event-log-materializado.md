# ADR-0002 — Persistencia: event log append-only + estado materializado

- **Estado:** Aceptado
- **Fecha:** 2026-05-29
- **Relacionado:** `domain-model.md` (§2 agregados, event log), `engineering-guidelines.md`, Q37.

## Contexto

El dominio es event-driven: los eventos son la fuente de verdad y el estado del participante se deriva de ellos. La pregunta (Q37) es cómo persistir: ¿event sourcing completo (reproyectar siempre desde los eventos) o estado materializado junto al log?

## Decisión

**Event log append-only como fuente de verdad + estado materializado** (no event sourcing completo).

- Tabla `event` append-only: cada hecho de dominio se persiste con `participant_id?`, `type`, `payload`, `occurred_at`, `source`.
- Las entidades (`participant`, `cohort`, `outbound_action`) mantienen **estado materializado** para queries simples y rápidas (dashboards, filtros).
- El estado materializado se actualiza en la misma transacción que el evento que lo origina (o por un reductor determinista). El log permite auditar/reconstruir.

## Fundamento

- El event log da **auditoría y trazabilidad** (clave para atribución y para el timeline del participante) sin el costo de reproyectar todo en cada lectura.
- El estado materializado evita la complejidad de proyecciones/snapshots de un event sourcing puro — innecesaria para 300+/cohorte single-tenant.
- Coherente con los guardrails anti-sobreingeniería (`engineering-guidelines.md` §7).

## Consecuencias

**Positivas:** lecturas simples y baratas; auditoría completa; tolerancia a eventos fuera de orden si el reductor es determinista (Q32).
**Negativas / a vigilar:** hay que mantener consistencia entre log y estado materializado (misma transacción / reductor único como punto de verdad). Si en el futuro se necesitaran proyecciones múltiples, se evalúa CQRS — fuera de MVP.

## Alternativas descartadas
- **Event sourcing completo:** sobreingeniería para el volumen y alcance del MVP.
- **Solo estado (sin log):** perdería auditoría/atribución/timeline, que son valor de negocio.
