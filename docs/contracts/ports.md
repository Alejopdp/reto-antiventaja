# Puertos (interfaces del core)

> TypeScript de referencia. El core usa SOLO estas interfaces; cada herramienta concreta (automatizador de WhatsApp, host de vídeo, PSP) es un adaptador que las implementa.

## Tipos compartidos

```ts
type Token = string;          // opaco, único y estable por participante
type E164 = string;           // móvil normalizado, p.ej. "+34612345678"
type ISODateTime = string;    // ISO-8601 con zona

type Segment = 'no_vio' | 'parcial' | 'completo';

type ActionType =
  // familia mensajes:
  | 'bienvenida' | 'contenido_diario' | 'followup_1' | 'followup_2' | 'cta_final' | 'recordatorio'
  // familia gestión de grupo (no es un mensaje; reusa la cola — ADR-0001):
  | 'alta_grupo';

interface OutboundAction {
  id: string;
  participantId: string;
  actionType: ActionType;
  params: Record<string, unknown>;   // p.ej. { day: 3 } para contenido_diario
  dedupeKey: string;                  // único; evita duplicados
  scheduledFor: ISODateTime;
}
```

## 1) MessagingPort — salida (el core ordena; la capa no-code ejecuta)

El core no envía WhatsApp directamente: **encola** una acción. La entrega es asíncrona vía la cola + `ack` (ver `http-boundary.md`). Cubre las dos familias de `ActionType` (mensajes y gestión de grupo).

```ts
interface MessagingPort {
  /** Encola una acción de salida de forma idempotente por dedupeKey. */
  enqueue(action: OutboundAction): Promise<void>;
}
```

## 2) VideoTrackingPort — entrada (mundo de vídeo → core)  ✅ H3/H4 resueltos (ADR-0006)

Dos superficies de medición **propias**, ambas atadas al `token` (no al `visitor.id` del host):
- **Replay:** se entrega en una **página tokenizada propia**; el progreso lo mide **nuestro** reproductor (eventos JS) y se ingesta como pings. El host (Cloudflare Stream / S3+HTML5, Q55) es **commodity de entrega**: no dependemos de su webhook ni de sus umbrales.
- **Directo en vivo (Zoom):** asistencia por persona vía registro con link único + webhooks/Reports (Q54).

```ts
interface VideoView {              // replay (nuestro reproductor)
  token: Token;
  percentWatched: number;          // 0..100, por segundos efectivamente vistos (no la posición máxima de la barra)
  watchedSeconds: number;          // segundos únicos vistos acumulados
  completed: boolean;              // alcanzó el umbral propio (Q20)
  occurredAt: ISODateTime;
  providerEventId: string;         // idempotencia (id del ping)
}

interface LiveAttendance {         // directo en vivo (Zoom)
  token: Token;                    // resuelto por registrant_id ↔ token
  joinedAt: ISODateTime;
  leftAt?: ISODateTime;
  durationSeconds: number;
  occurredAt: ISODateTime;
  providerEventId: string;
}

interface VideoTrackingPort {
  /** Replay: normaliza el ping de progreso de NUESTRO reproductor tokenizado. null si inválido / sin token. */
  parseReplayProgress(raw: unknown, headers: Record<string, string>): VideoView | null;
  /** Directo: normaliza el webhook de asistencia de Zoom. null si inválido / sin token. */
  parseLiveAttendance(raw: unknown, headers: Record<string, string>): LiveAttendance | null;
}
```

> El `Segment` (`no_vio|parcial|completo`) lo deriva el dominio a partir de `watchedSeconds`/`percentWatched` + asistencia al directo; umbral en Q20. El host de vídeo entra detrás de este puerto como commodity (ADR-0005/0006).

## 3) PaymentPort — entrada (PSP → core)

Normaliza pagos y reembolsos. El matching al participante usa `token` (metadata del checkout, H5) y, como fallback, móvil/email.

```ts
interface PaymentEvent {
  kind: 'payment' | 'refund';
  reference: string;        // id del PSP — idempotencia
  token?: Token;            // si se pasó como metadata del checkout (preferido)
  whatsappNumber?: E164;    // fallback de matching
  email?: string;           // fallback de matching
  amount: number;
  currency: string;         // p.ej. "EUR" (P60 = 60 €)
  occurredAt: ISODateTime;
  providerEventId: string;
}

interface PaymentPort {
  verifySignature(raw: unknown, headers: Record<string, string>): boolean;
  parseWebhook(raw: unknown, headers: Record<string, string>): PaymentEvent | null;
}
```

> Si un `PaymentEvent` no resuelve a ningún participante → bandeja de Ops (Q21). El reembolso revierte el estado (Q42/H6).
