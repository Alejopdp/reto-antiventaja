# Engineering Guidelines

> Barandas para implementar el MVP de forma consistente (pensado para varios agentes/devs en paralelo). TDD, inyección de dependencias y desacople de capas **en el punto justo, sin sobreingeniería**. Deriva de `domain-model.md`, `contracts/` y `tasks.md`.

## 1. Capas (hexagonal) y estructura de carpetas

```
src/
├── domain/            # núcleo PURO: entidades, value objects, máquina de estados,
│                      # policies, eventos. Sin I/O, sin imports de infra ni de Next.
├── application/       # casos de uso / command handlers. Orquestan el dominio y
│                      # dependen de los PUERTOS (interfaces), no de adapters.
├── ports/             # interfaces (MessagingPort, VideoTrackingPort, PaymentPort,
│                      # repos). Las define la aplicación; las implementa infra.
├── infrastructure/    # adapters concretos: Drizzle repos, adaptadores de WhatsApp/
│                      # video/PSP, cola, scheduler. Implementan los puertos.
├── app/               # Next.js App Router: rutas HTTP (webhooks, /actions/*),
│                      # formulario público, dashboard. Es el borde, fino.
└── composition/       # composition root: arma las dependencias concretas y las inyecta.
```

## 2. Regla de dependencias (la más importante)

**Las dependencias apuntan hacia adentro.** `domain` no importa nada; `application` importa `domain` + `ports`; `infrastructure` y `app` importan hacia adentro pero **el dominio/aplicación NUNCA importan infra ni Next**. Si una clase de dominio necesita la hora o un id, recibe un `Clock`/`IdGenerator` por puerto (no `Date.now()`/`crypto` directos) — así el core es testeable y determinista.

## 3. Inyección de dependencias

- **Constructor injection** simple. Los casos de uso reciben sus puertos por constructor.
- **Composition root** único (`composition/`) que instancia adapters reales y los cablea. En tests se inyectan fakes.
- **NO** usar un contenedor de DI pesado salvo que el cableado se vuelva inmanejable (no lo será en un MVP). Funciones/factories explícitas alcanzan.

## 4. Estrategia de testing (TDD)

Pirámide: **mucho unit (dominio), algo de integración (adapters), poco e2e**.

| Capa | Tipo de test | Cómo |
|---|---|---|
| `domain` | **Unit, TDD puro** | Máquina de estados, policies, reducer del event log, idempotencia. Sin mocks (es puro). Red→green→refactor. |
| `application` | **Unit con fakes** | Casos de uso contra puertos fake en memoria. Verifican los criterios Given/When/Then de `use-cases.md`. |
| `infrastructure` | **Contract + integration** | Cada adapter pasa un **contract test** del puerto (mismo set de tests para fake y real). Webhooks: parse + idempotencia. DB: contra Postgres real (testcontainer/local). |
| `app` (HTTP) | **Integration** | Endpoints: verificación de firma, idempotencia por `providerEventId`, `ack` terminal. |
| e2e | **Pocos, críticos** | El walking skeleton de Wave 1 (registro→aceptar→alta_grupo→ack→bienvenida). |

Regla práctica: **escribir el test del caso de uso antes que el handler** (los Given/When/Then ya están en `use-cases.md`, son el backlog de tests).

## 5. Convenciones

- **Lenguaje ubicuo** (`domain-model.md`): los nombres de código = los del glosario. Eventos en pasado (`ParticipanteAceptadoEnCohorte`), comandos en imperativo (`AceptarEnCohorte`).
- **Idempotencia siempre**: salida por `dedupeKey`; entrada por `providerEventId` (ver `contracts/`).
- **Tiempos** en UTC + zona; el "día N" se ancla a `joinedGroupAt` (Q31). Nada de `Date.now()` en el dominio (pasar `Clock`).
- **Errores**: en el dominio/aplicación, resultados explícitos (no excepciones para flujo esperado); los adapters traducen errores del proveedor a tipos de dominio o `null` (→ bandeja).
- **PII**: el teléfono es dato personal (GDPR, España) — no loguear PII en claro; ver `nfr-and-security.md` (pendiente).
- **Estado**: append-only en el event log; el estado materializado se deriva (ADR-0002).

## 6. Definition of Done (por tarea de `tasks.md`)

- Tests (unit/integration según capa) en verde y cubriendo los criterios del/los UC referenciados.
- Sin violaciones de la regla de dependencias (§2).
- Idempotencia verificada donde aplique.
- Sin secretos en el código; variables por entorno.
- Lint/format/build OK.

## 7. Guardrails anti-sobreingeniería (qué NO hacer en el MVP)

- ❌ Event sourcing completo, CQRS, sagas. (Event log + estado materializado alcanza — ADR-0002.)
- ❌ Microservicios. Es un monolito modular (Next.js).
- ❌ Contenedor de DI / framework de mensajería pesado.
- ❌ Abstracciones especulativas: **3 líneas repetidas > una abstracción innecesaria**. Abstraer al tercer caso real, no antes.
- ❌ Genéricos/“capas de repositorio genéricas” prematuras.
- ✅ Lo que SÍ: los 3 puertos (porque hay incertidumbre real de proveedor), el event log (porque la atribución/auditoría lo valen), idempotencia (porque el canal reintenta).
