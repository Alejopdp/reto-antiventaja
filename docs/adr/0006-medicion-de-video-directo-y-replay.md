# ADR-0006 — Medición de vídeo: directo en vivo + replay

- **Estado:** Aceptado (enfoque de diseño interno, [DISEÑO]). Pendientes menores: plan de Zoom (Q54) y host definitivo del replay (Q55).
- **Fecha:** 2026-07-01
- **Origen:** cierre del hotspot H3, con Q1 confirmado (híbrido: contenido/comunidad al grupo, replay 1:1) en el handoff del 4-jun. Verificado contra Zoom API y hosts de vídeo (ver Fundamento).

## Contexto

El motor de follow-up necesita saber, **por persona**, qué consumió del contenido de conversión. Hay dos piezas: el **directo dominical en vivo** (la venta) y su **replay**. El hotspot H3 alertaba que los hosts (Wistia) identifican al espectador por su `visitor.id`, no por nuestro `token` → la señal de comportamiento por persona quedaba en riesgo.

## Decisión

Medimos **nosotros**, en **dos superficies**, ambas atadas al `token`:

1. **Replay en página tokenizada propia.** El link 1:1 llega por WhatsApp. El progreso lo mide **nuestro reproductor** por eventos JS (`timeupdate`, `pause`, `seeking/seeked`, `ended`, `ratechange`, `visibilitychange/beforeunload`) → pings `VideoView{token, watchedSeconds, percentWatched, completed}`. El `percentWatched` se calcula por **segundos efectivamente vistos** (intervalos únicos), **no** por la posición máxima de la barra (anti-gaming). El **umbral de "completo" es propio** (Q20), no los umbrales fijos del host.
2. **Directo en vivo (Zoom).** Registro por participante → **link de join único** por WhatsApp; webhooks `participant_joined/left` + Reports API → `LiveAttendance{token, joinedAt, leftAt, durationSeconds}`, atado por `registrant_id ↔ token`.

El **host de vídeo es commodity** de entrega/seguridad/costo detrás del `VideoTrackingPort` (ADR-0005). Default: **Cloudflare Stream** (HLS automático + CDN + playback firmado + *bring-your-own-player*) o mínimo viable **mp4 en S3 + HTML5 + URL firmada**. **Wistia se descarta.**

## Fundamento (verificado)

- Zoom expone datos por participante (join/leave/duración) por API/webhooks/Reports; el **registro por participante** genera link único → permite atar la asistencia al token. Requiere Zoom **Pro+** con registro (Q54).
- Los eventos JS del reproductor (HTML5 o cualquier player con API) cubren %, saltos, pausa, cierre y 2x → analítica propia suficiente; hace **innecesaria** la analítica del host.
- Cloudflare Stream: ~$1/1000 min, HLS automático, playback firmado, tu propio player; S3+HTML5 viable pero sin HLS adaptativo y con CDN/URL firmada a cargo nuestro.

## Consecuencias

- **Resuelve H3** (medición atada a nuestro token, no al host) y **H4** (umbral propio, no 25/50/75/100 de Wistia).
- **Dos señales** para el motor de follow-up/segmentación: *asistió-al-directo* y *vio-el-replay*. Enriquece Q41 (participación) y alimenta "alertas por inacción" + reprogramación (handoff §5).
- Cambia el `VideoTrackingPort`: de `parseWebhook(host)` a `parseReplayProgress(nuestro tracker)` + `parseLiveAttendance(Zoom)`. Actualizados `contracts/ports.md` y `contracts/http-boundary.md`.
- El tracking client-side es adecuado para *engagement* (no es antifraude estricto); se acepta como limitación.

## Alternativas descartadas

- **Depender del webhook del host** (Wistia): bloqueado por la limitación del token (H3) y los umbrales fijos (H4).
- **Wistia como host:** innecesario; su valor (player de marketing + heatmaps) no aporta a "por persona por token".
- **Mux:** mejor analítica/DRM pero más caro, y su analítica no la usamos (medimos nosotros); queda para si se necesita DRM.

## Relación

ADR-0005 (host commodity detrás de puerto), ADR-0002 (el event log guarda `VideoView`/`LiveAttendance` como eventos). Q54, Q55, Q20, Q41. Cierra H3 y H4.
