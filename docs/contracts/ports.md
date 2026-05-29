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

## 2) VideoTrackingPort — entrada (host de vídeo → core)  ⚠️ depende de Q1

Normaliza el webhook del host (Wistia/Vimeo) a un evento de dominio. Requiere que el replay se entregue 1:1 con el `token` (H3).

```ts
interface VideoView {
  token: Token;
  percentWatched: number;   // 0..100; máximo acumulado entre sesiones (H4)
  occurredAt: ISODateTime;
  providerEventId: string;  // idempotencia
}

interface VideoTrackingPort {
  /** Devuelve null si el webhook no es válido o no trae token identificable. */
  parseWebhook(raw: unknown, headers: Record<string, string>): VideoView | null;
}
```

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
