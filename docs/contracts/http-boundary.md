# Frontera HTTP — webhooks de entrada y cola de acciones

> El contrato concreto entre nuestro app y el mundo externo: lo que **entra** (formulario propio, automatizador de WhatsApp, host de vídeo, PSP) y lo que **sale** (la cola que la capa no-code consume). Todos los webhooks: idempotentes y verificados por firma/secreto.

## Entrada

### `POST /register` — alta desde el formulario propio (adaptador primario)
```jsonc
// body
{ "fullName": "Marina López", "whatsappNumber": "+34612345678",
  "email": "marina@ej.com",            // opcional
  "referredByRaw": "Carla Giménez",    // texto libre (Modelo A, Q38)
  "consent": true }
// 200 → { "participantId": "...", "token": "..." }   (genera token; estado PENDIENTE_VERIFICACION)
```

### `POST /webhooks/group-join` — el número se unió al grupo (automatizador)
```jsonc
{ "whatsappNumber": "+34612345678", "groupId": "...", "occurredAt": "...", "providerEventId": "..." }
// matchea por número (H1); si no matchea → bandeja Ops
```

### `POST /track/replay` — progreso del replay (nuestro reproductor tokenizado) ✅ ADR-0006
```jsonc
{ "token": "...", "watchedSeconds": 812, "percentWatched": 74, "completed": false,
  "event": "timeupdate|pause|seeked|ended|unload", "providerEventId": "..." }
// lo normaliza VideoTrackingPort.parseReplayProgress → VideoView (medición propia, no del host)
```

### `POST /webhooks/live-attendance` — asistencia al directo en vivo (Zoom) ✅ Q54
```jsonc
{ "token": "...", "joinedAt": "...", "leftAt": "...", "durationSeconds": 1560, "providerEventId": "..." }
// registro con link único → registrant_id ↔ token; lo normaliza VideoTrackingPort.parseLiveAttendance → LiveAttendance
```

### `POST /webhooks/payment` — pago/reembolso (PSP)
Body específico del PSP; lo normaliza `PaymentPort.parseWebhook` → `PaymentEvent{ kind, token?, ... }`.

### `POST /webhooks/survey` — respuesta a encuesta/dinámica (opcional)
```jsonc
{ "token": "...", "surveyId": "...", "answers": { /* libre */ }, "providerEventId": "..." }
// se persiste como EncuestaRespondida; sin cálculo en MVP (H10)
```

## Salida — la capa no-code consume la cola

### `GET /actions/pending?limit=N` — acciones por enviar
```jsonc
// 200 →
[ { "id": "act_123", "actionType": "contenido_diario",
    "recipient": { "whatsappNumber": "+34612345678" },
    "params": { "day": 5 }, "scheduledFor": "..." },
  { "id": "act_124", "actionType": "alta_grupo",
    "recipient": { "whatsappNumber": "+34699338771" }, "params": { "groupId": "..." } } ]
// respeta throttling (H11) y scheduledFor; no devuelve acciones futuras
```

### `POST /actions/{id}/ack` — confirmación de ejecución (cierra el loop)
```jsonc
{ "status": "enviada" }                       // → AcciónResuelta(enviada)
{ "status": "fallida", "reason": "rate_limit" } // → AcciónResuelta(fallida); reintento según Q28
```

## Reglas
- **Auth:** webhooks con firma/HMAC; `/actions/*` con secreto de la capa no-code.
- **Idempotencia entrada:** `providerEventId` único; reprocesar = no-op.
- **Idempotencia salida:** una acción se entrega una vez; el `ack` es terminal (salvo reintento explícito → nueva acción con el mismo propósito).
- **Throttling:** `/actions/pending` no excede el ritmo seguro del canal (H11); el resto queda en cola.
