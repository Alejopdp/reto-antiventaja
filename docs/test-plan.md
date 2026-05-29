# Plan de pruebas

> Mapea los casos de uso (`use-cases.md`) a tipos de test y define el "definition of done". Es el backlog de TDD: los Given/When/Then ya escritos son los tests a implementar primero. Estrategia y capas en `engineering-guidelines.md` §4.

## Pirámide
- **Unit (dominio):** máquina de estados, policies, reducer del event log, idempotencia. Puro, sin mocks. **Se escribe primero (TDD).**
- **Unit (aplicación):** casos de uso contra **puertos fake** en memoria.
- **Contract + integration (infra):** cada adapter pasa el mismo contract test del puerto; DB contra Postgres real; webhooks parse+firma+idempotencia.
- **E2E (pocos):** el walking skeleton de Wave 1.

## UC → tests

| UC | Capa principal | Aserciones clave |
|---|---|---|
| UC-01 Registro | app + dominio | crea participante `pendiente_verificacion`, genera token único, emite `ParticipanteRegistrado`+`AtribuciónCapturada`; **dup en cohorte → 409** (Q6) |
| UC-02 Aceptar | aplicación | `→ aceptado`, emite evento, **encola `alta_grupo`** (idempotente) |
| UC-03 Rechazar | aplicación | `→ rechazado`, **no encola nada** |
| UC-04 Alta+bienvenida | aplicación + infra | group-join matchea por E.164 → `en_grupo`, programa contenido, encola `bienvenida`; sin match → bandeja |
| UC-05 Contenido diario | dominio + scheduler | día N relativo a `joined_group_at`; `dedupe_key=participante:díaN` **no reenvía** |
| UC-06 Encuesta | app | persiste `EncuestaRespondida`; sin cálculo |
| UC-07 Presentación P60 | aplicación | emite evento de cohorte, encola `replay` |
| UC-08 Segmentación (⚠️Q1) | dominio | `<80% parcial`, `≥80% completo`, sin visionado→`no_vio`; **re-segmentación monótona + cancela follow-ups obsoletos** (Q17) |
| UC-09 Follow-up por segmento | dominio | encola `followup_1/2/cta` correcto, idempotente por segmento |
| UC-10 Timeout replay | scheduler + dominio | sin `VideoVisto` en ventana → `no_vio` + `followup_1` |
| UC-11 Pago→conversión | infra + dominio | match por token/fallback → `convertido` + `AtribuciónResuelta`; **sin match → bandeja** (Q21); **dup por reference → no-op** (Q23) |
| UC-12 Reembolso | dominio | `convertido → revertido` |
| UC-13 Experiencia | app | persiste `ExperienciaCompletada`; no bloquea lifecycle |
| UC-14 Cohortes (CRUD/estado) | aplicación | crea/edita/cambia estado; emite eventos de cohorte |
| UC-15 Reintentar acción | aplicación | re-encola acción fallida; idempotencia de propósito (Q28) |
| UC-16 Reenviar acceso | aplicación | re-encola `alta_grupo`/`bienvenida` |
| UC-17 Atribución manual | aplicación | asignar→`AtribuciónResuelta`; sin invitador→`AtribuciónDescartada` |
| UC-18 Baja/opt-out (⚠️Q2) | dominio | `→ baja`; **invariante: no encolar ninguna acción a `baja`/`rechazado`** |

## Tests transversales (no por UC)
- **Idempotencia de entrada:** reprocesar un webhook con el mismo `providerEventId` no duplica efectos.
- **Idempotencia de salida:** dos acciones con el mismo `dedupe_key` → una sola.
- **Firma de webhooks:** payload sin firma válida → rechazado.
- **Reducer determinista:** dado un set de eventos (incluido **fuera de orden**, Q32), el estado materializado es el esperado.
- **Contract test de puertos:** fake y adapter real pasan el mismo set (Messaging/Video/Payment).
- **Auth de la cola:** `/actions/*` sin secreto → 401.

## Definition of Done (por tarea)
Tests de las capas que toca en verde + cubriendo los UC referenciados · regla de dependencias respetada · idempotencia verificada donde aplique · sin secretos/PII en código ni logs · lint/format/build OK. (Ver `engineering-guidelines.md` §6.)
