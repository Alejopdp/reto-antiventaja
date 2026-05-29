# Requisitos no funcionales y seguridad

> Lo que el equipo de implementación debe respetar más allá de la funcionalidad. Mercado **España (UE)** → GDPR aplica. Deriva de `domain-model.md`, `contracts/`, `engineering-guidelines.md`.

## Escala y rendimiento
- **Volumen:** ~300+ participantes por cohorte, recurrente; picos en (a) verificación/alta al inicio y (b) envío de contenido diario.
- **Cola de salida:** drenada con **throttling** configurable para no superar el ritmo seguro del canal no-oficial (H11). Backlog esperado; no es error.
- **Webhooks de entrada:** respuesta rápida e idempotente; el trabajo pesado se difiere a la cola/jobs.
- Latencia no crítica (no es real-time); prioridad: **no perder ni duplicar** eventos/acciones.

## Fiabilidad e idempotencia
- **Entrada:** deduplicar por `providerEventId` (reprocesar = no-op). Tolerancia a orden (Q32).
- **Salida:** un `dedupeKey` único por propósito; el `ack` es terminal; reintentos explícitos (Q28).
- Si el app o la capa no-code caen: los webhooks se reintentan desde el proveedor; la cola persiste y se drena al volver.

## Observabilidad
- Logs **estructurados sin PII en claro** (ver abajo). Métricas: tamaño de cola, acciones `fallida`, tasa de `ack`, conversiones. Alertas a Ops ante fallos (pantalla Salud).

## Seguridad
- **Webhooks**: verificación de **firma/HMAC** por proveedor (`PaymentPort.verifySignature`, etc.). Rechazar lo no verificado.
- **Cola `/actions/*`**: protegida con secreto compartido de la capa no-code.
- **Secretos** solo por variables de entorno; nunca en el repo.
- **Token** del participante: opaco, no adivinable (aleatorio suficientemente largo); viaja en links de contenido/video/pago.
- Superficie mínima: sin portal de participante (Q42) reduce el área de ataque.

## Datos personales / GDPR (España, UE)
- **Datos que tratamos:** nombre, **teléfono (PII)**, email (opcional), atribución (texto libre), eventos de comportamiento. **NO** datos financieros (el Excel solo se entrega; no se captura — decisión de scope).
- **Base legal:** consentimiento explícito en el registro (checkbox; ya en el wireframe).
- **Minimización:** pedir solo lo necesario (Q3 define los campos).
- **Derechos:** baja/opt-out (Q2 / `DarDeBaja`) y borrado a pedido; definir **retención** de datos por cohorte.
- **Residencia:** región **UE** (ADR-0004).
- **No PII en logs**: enmascarar teléfono/email en logs y trazas.

## Cumplimiento de terceros (riesgos a vigilar)
- **WhatsApp/Meta ToS:** la automatización no-oficial sobre grupos puede violar términos y derivar en **baneo del número** (H11, Q47). Mitigación: diseño **canal-agnóstico** (plan B = API oficial sin tocar el core) + throttling. La investigación de integraciones cuantifica este riesgo.
- **Promesas financieras:** el contenido del cliente debe cuidar la publicidad de resultados económicos (regulación). No es responsabilidad del software, pero se señala.

## Definición de "suficiente" para el MVP (anti-sobreingeniería)
No hace falta HA multi-región, ni auditoría tipo SOC2, ni cifrado a nivel de campo, ni borrado automatizado complejo. Sí: firma de webhooks, secretos por entorno, consentimiento, opt-out, región UE, y no loguear PII. El resto se evalúa si el producto crece.
