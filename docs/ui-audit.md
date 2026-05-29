# Reto Antiventaja — Auditoría de interactividad y cobertura de dominio

> Revisión de TODOS los controles de los wireframes: cuáles no tienen handler (a corregir en el prototipo) y, más importante, cuáles **son comandos de dominio** que el `event-storming.md` no refleja.
> Fecha: 2026-05-29

## Leyenda
- **UI**: interacción puramente de interfaz (filtro, búsqueda, navegación, orden, paginación). No es dominio; solo necesita handler visual.
- **DOMINIO**: dispara un comando del sistema → debe existir en el event-storming (comando + evento + actor).
- Estado: ✅ funciona · ❌ sin handler.

---

## Hallazgo principal (dominio)

El event-storming modela **solo el ciclo de vida del participante**. Los wireframes del panel interno destaparon una familia entera que falta: **operación interna por Ops y Organizador**. Comandos/eventos nuevos a incorporar:

| Comando (actor) | Evento | Origen en UI |
|---|---|---|
| `CrearCohorte` (Organizador) | `CohorteCreada` | Cohortes · "Nueva cohorte" |
| `ActualizarCohorte` (Organizador) | `CohorteActualizada` | Cohortes · "Guardar cambios" |
| `CambiarEstadoCohorte` (Organizador) | `CohorteEstadoCambiado` (borrador→activa→cerrada) | Cohortes · toggle estado |
| `ReintentarAcción` (Ops) | `AcciónEncolada` (reintento) | Salud · "Reintentar" |
| `ResolverAtribuciónManual` (Ops) | `AtribuciónResuelta` | Atribución · "Asignar impulsor" |
| `MarcarSinInvitador` (Ops) | `AtribuciónDescartada` | Atribución · "Sin invitador" |
| `ReenviarAcceso` (Ops) | `AcciónEncolada(alta_grupo/bienvenida)` | Detalle · "Reenviar acceso" |
| `DarDeBaja` (Ops/Participante) | `ParticipanteDadoDeBaja` | Detalle · "Dar de baja" (Q2) |

> **Actores**: esto confirma a **Organizador** y **Ops** como actores activos del core (no solo el Scheduler y el Participante). `ResolverAtribución` ya existía como *policy automática* post-conversión; ahora aparece también su variante **manual** (Ops desde la bandeja).
> **Export CSV** es una lectura (read model), no un comando de dominio.

---

## Inventario por pantalla

### dashboard-cohortes.html
| Control | Estado | Tipo | Mapea a |
|---|---|---|---|
| "Nueva cohorte" | ❌ | DOMINIO | `CrearCohorte` |
| Estado: Borrador/Activa/Cerrada | ❌ | DOMINIO | `CambiarEstadoCohorte` |
| "Guardar cambios" | ❌ | DOMINIO | `ActualizarCohorte` |
| "Cancelar" | ❌ | UI | reset form |
| Filas de la tabla (seleccionar para editar) | ❌ | UI | cargar en panel |

### dashboard-salud.html
| Control | Estado | Tipo | Mapea a |
|---|---|---|---|
| Filtros Todas/Pendientes/Fallidas | ❌ | UI | filtrar cola |
| "Reintentar" (fila fallida) | ❌ | DOMINIO | `ReintentarAcción` |

### dashboard-atribucion.html
| Control | Estado | Tipo | Mapea a |
|---|---|---|---|
| "Asignar impulsor" | ❌ | DOMINIO | `ResolverAtribuciónManual` |
| "Sin invitador" | ❌ | DOMINIO | `MarcarSinInvitador` |
| "ordenar por conversiones" | ❌ | UI | ordenar tabla |
| "ver todo" / "resolver →" | ❌ | UI | navegación |

### dashboard-participantes.html
| Control | Estado | Tipo | Mapea a |
|---|---|---|---|
| Filtros de estado (6) | ⚠️ solo estilo | UI | filtrar tabla (no filtra de verdad) |
| Búsqueda | ❌ | UI | filtrar por texto |
| Paginación (Anterior/1/2/3/Siguiente) | ❌ | UI | paginar |
| ~~"Exportar CSV"~~ | 🗑️ | — | **eliminado — fuera de MVP** |
| Filas | ✅ | UI | → detalle |

### dashboard-participante.html
| Control | Estado | Tipo | Mapea a |
|---|---|---|---|
| "Reenviar acceso" | ❌ | DOMINIO | `ReenviarAcceso` |
| "Dar de baja" | ❌ | DOMINIO | `DarDeBaja` (Q2) |

### dashboard-overview.html
| Control | Estado | Tipo | Mapea a |
|---|---|---|---|
| Selector "Cohorte: Mayo 2026" | ❌ | UI | cambiar cohorte |
| "ver todo" / "ir a verificar" | ✅/❌ | UI | navegación |

### dashboard-verificacion.html
| Control | Estado | Tipo | Mapea a |
|---|---|---|---|
| Aceptar / Rechazar / lote / modal | ✅ | DOMINIO | `VerificarRegistro` (ya modelado) |
| Selector "Cohorte: Mayo 2026" | ❌ | UI | cambiar cohorte |

### Público (registro / aceptado / estados / experiencia)
| Control | Estado | Tipo | Nota |
|---|---|---|---|
| registro: submit + switch | ✅ | DOMINIO | `RegistrarParticipante` |
| experiencia: submit + switch | ✅ | DOMINIO | `RegistrarExperiencia` |
| estados: switch + reintentar | ✅ | UI | — |
| aceptado: "Unirme al grupo" / "Vuelve a intentarlo" | ❌ | UI | link externo (WhatsApp) |

---

## Plan de corrección (prototipo)

1. **Helper de toast** compartido en las pantallas internas que no lo tienen.
2. **Handlers UI**: filtros que filtren de verdad (participantes, salud), búsqueda, orden, paginación visual, selector de cohorte (toast/demo), links de navegación.
3. **Handlers DOMINIO** (con feedback que nombre el comando): cohortes (crear/guardar/estado), salud (reintentar), atribución (asignar/sin invitador), detalle (reenviar/baja).
4. **Docs de dominio**: agregar a `event-storming.md` el bloque de **operación interna** y a `domain-model.md` los comandos/eventos/actores nuevos.
