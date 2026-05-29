-- Reto Antiventaja — esquema de referencia (PostgreSQL)
-- Estado: spec de diseño (no migración productiva). Deriva de domain-model.md y ADR-0002.
-- Convención: snake_case; timestamptz en UTC; PII (whatsapp_number, email) no se loguea en claro.

-- ───────────────────────── enums ─────────────────────────
CREATE TYPE cohort_status   AS ENUM ('borrador', 'activa', 'cerrada');
CREATE TYPE participant_state AS ENUM (
  'pendiente_verificacion', 'rechazado', 'aceptado', 'en_grupo',
  'post_presentacion', 'convertido', 'revertido', 'baja'  -- 'baja' provisional (Q2)
);
CREATE TYPE segment         AS ENUM ('no_vio', 'parcial', 'completo');
CREATE TYPE action_type     AS ENUM (
  'bienvenida', 'contenido_diario', 'followup_1', 'followup_2', 'cta_final', 'recordatorio', -- mensajes
  'alta_grupo'  -- gestión de grupo (ADR-0001)
);
CREATE TYPE action_status   AS ENUM ('pendiente', 'enviada', 'fallida');
CREATE TYPE event_source    AS ENUM ('form', 'ops', 'automatizador', 'video', 'psp', 'scheduler', 'sistema');

-- ───────────────────────── cohort ─────────────────────────
CREATE TABLE cohort (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  start_date      date NOT NULL,
  timezone        text NOT NULL DEFAULT 'Europe/Madrid',
  presentation_at timestamptz,                       -- evento fijo de cohorte (H8); null = sin fijar
  status          cohort_status NOT NULL DEFAULT 'borrador',
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- ───────────────────────── participant ────────────────────
CREATE TABLE participant (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cohort_id                   uuid NOT NULL REFERENCES cohort(id),
  full_name                   text NOT NULL,
  whatsapp_number             text NOT NULL,         -- E.164
  email                       text,
  token                       text NOT NULL,         -- opaco, único; viaja en links (video/pago)
  referred_by_raw             text,                  -- texto libre del formulario (Modelo A, Q38)
  referred_by_participant_id  uuid REFERENCES participant(id),  -- resuelto; CHECK no-self abajo
  -- NOTA (Q43): el impulsor podría no ser un participante → posible entidad `promoter` propia.
  state                       participant_state NOT NULL DEFAULT 'pendiente_verificacion',
  segment                     segment,               -- atributo, no estado (domain-model §4)
  current_day                 smallint CHECK (current_day BETWEEN 0 AND 7),  -- relativo a joined_group_at (Q31)
  accepted_at                 timestamptz,
  joined_group_at             timestamptz,
  converted_p60_at            timestamptz,
  reverted_at                 timestamptz,
  opted_out_at                timestamptz,
  created_at                  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT participant_token_unique UNIQUE (token),
  CONSTRAINT participant_cohort_wpp_unique UNIQUE (cohort_id, whatsapp_number),  -- dedup en cohorte (Q6)
  CONSTRAINT participant_no_self_referral CHECK (referred_by_participant_id IS NULL OR referred_by_participant_id <> id)  -- Q5
);
CREATE INDEX participant_wpp_idx     ON participant (whatsapp_number);
CREATE INDEX participant_state_idx   ON participant (cohort_id, state);
CREATE INDEX participant_referrer_idx ON participant (referred_by_participant_id);

-- ───────────────────────── event (append-only) ────────────
-- Fuente de verdad (ADR-0002). El estado materializado de participant se deriva de aquí.
CREATE TABLE event (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- orden de inserción
  participant_id    uuid REFERENCES participant(id),
  cohort_id         uuid REFERENCES cohort(id),
  type              text NOT NULL,    -- p.ej. 'ParticipanteAceptadoEnCohorte' (catálogo en domain-model §5)
  payload           jsonb NOT NULL DEFAULT '{}',
  source            event_source NOT NULL,
  provider_event_id text,             -- idempotencia de ingesta (webhooks)
  occurred_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX event_participant_idx ON event (participant_id, occurred_at);
CREATE INDEX event_type_idx        ON event (type);
-- idempotencia de entrada: no reprocesar el mismo evento del proveedor (Q26/Q32)
CREATE UNIQUE INDEX event_provider_unique ON event (source, provider_event_id)
  WHERE provider_event_id IS NOT NULL;

-- ───────────────────────── outbound_action (cola) ─────────
CREATE TABLE outbound_action (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_id uuid NOT NULL REFERENCES participant(id),
  action_type    action_type NOT NULL,
  params         jsonb NOT NULL DEFAULT '{}',   -- p.ej. {"day":3} para contenido_diario
  dedupe_key     text NOT NULL,                 -- idempotencia de salida (ADR-0001)
  status         action_status NOT NULL DEFAULT 'pendiente',
  attempts       smallint NOT NULL DEFAULT 0,
  scheduled_for  timestamptz NOT NULL DEFAULT now(),
  sent_at        timestamptz,
  fail_reason    text,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT outbound_dedupe_unique UNIQUE (dedupe_key)
);
-- pull de la cola: pendientes vencidas, en orden (respeta throttling en la query, H11)
CREATE INDEX outbound_pending_idx ON outbound_action (status, scheduled_for)
  WHERE status = 'pendiente';

-- ───────────────────────── notas ──────────────────────────
-- · Cohorte ≠ Grupo de WhatsApp: el grupo es canal (MessagingPort), no entidad propia en MVP.
-- · Reembolso (H6) revierte estado vía evento; no hay tabla de comisiones (fuera de MVP).
-- · Encuestas (H10): se persisten como event(type='EncuestaRespondida'); sin tabla dedicada en MVP.
-- · Pendiente Q43: si el impulsor se tipa, agregar tabla `promoter` y FK desde participant.
