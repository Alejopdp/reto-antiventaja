# Preguntas para el cliente — agenda de reunión

> Versión en lenguaje claro de lo que necesitamos definir para construir el MVP. Ordenado por prioridad: lo de arriba **bloquea** el desarrollo. Donde tenemos una recomendación, la marcamos para que decidir sea rápido.
> (Las referencias `Q##` son para nuestro seguimiento interno — ver `open-questions.md`.)

---

## 🔴 Bloque 1 — Lo que más nos traba (decidir primero)

**1. ¿El contenido y el replay se ven en el grupo o de forma individual?** `(Q1)`
Si todo se manda al grupo (todos juntos), no podemos saber **quién vio qué** ni hacer seguimiento personalizado. El seguimiento automático por comportamiento (a quién no vio, lo invitamos distinto que a quien vio todo) **solo funciona si el replay se entrega de forma individual** a cada persona (con un enlace propio).
→ *Recomendación: comunidad/dinámicas en el grupo, pero replay y videos clave individuales.*

**2. WhatsApp: ¿con qué herramienta y cómo se suma la gente al grupo?** `(Q47, Q48)`
- Técnicamente **no se puede agregar a un número desconocido a un grupo** (WhatsApp lo bloquea por anti-spam) → la gente se suma con un **enlace de invitación**. ¿Lo aceptan así?
- Tenemos a **Kapso (somos partners)**, que es una vía **oficial** (sin riesgo de que bloqueen el número, y mejor para la ley de datos). Su función de **grupos está por lanzarse** → ¿avanzamos con ellos y preguntamos por acceso anticipado? La alternativa (no oficial, tipo Whapi) ya hace grupos pero **arriesga el baneo del número**.

**3. ¿Cómo se da de baja alguien que no quiere más mensajes?** `(Q2)`
En España es obligatorio poder darse de baja. ¿Una palabra clave ("BAJA") por WhatsApp? Definámoslo.

**4. El contenido del reto: ¿quién lo produce y qué alcance tiene?** `(Q46)`
- Los videos/audios/textos de los 7 días, ¿los hacen ustedes? (Nosotros **no generamos contenido**, solo lo entregamos.) ¿Está listo?
- **Importante:** el sistema, ¿maneja solo el **reto gratis de 7 días** (hasta que la persona paga), o también los **60 días del plan pago (P60)**? Hoy diseñamos hasta el pago; los 60 días serían una etapa aparte.

**5. Reglas del seguimiento automático.** `(Q45)`
¿Cuántos mensajes de seguimiento mandamos, con qué frecuencia y hasta cuándo insistir? ¿Hay seguimiento también para quien no entró al grupo o no participó? ¿Quién escribe esos mensajes?

---

## 🟠 Bloque 2 — Decisiones del reto

**6. "¿Quién te invitó?" e impulsores.** `(Q43, Q4)`
Hoy es un campo de texto libre → el ranking de quién trae gente no agrupa bien (errores, apodos). ¿Tienen una **lista de impulsores** conocidos para asignar correctamente? ¿El que invita es siempre otro participante o puede ser alguien externo?

**7. Verificación de inscriptos.** `(Q8, Q9, Q10)`
¿Qué hace que acepten o rechacen a alguien? ¿Al rechazado se le avisa? ¿Puede volver a intentar? ¿Cuánto tardan en verificar (para avisarle a la persona qué esperar)?

**8. Datos del formulario.** `(Q3)`
¿Qué piden exactamente? (nombre, WhatsApp, email, quién invitó…). Cuantos menos campos, más gente se anota.

**9. Personas que repiten.** `(Q7)`
Alguien que estuvo en una cohorte anterior y vuelve, ¿es la misma persona (con historial) o una nueva?

**10. ¿Quién usa el panel interno?** `(Q13)`
¿Una persona o varias? ¿Todas ven todo o hay roles?

---

## 🟡 Bloque 3 — Pago y cierre

**11. Cobro del P60.** `(Q21–Q24)`
Recomendamos **Stripe con Bizum** (cobro local en España, ~60 €). ¿Es un pago único o admite cuotas? ¿Cómo manejamos reembolsos?

**12. ¿Y si alguien paga sin haber hecho el reto?** `(Q21)`
¿Se acepta? ¿Cómo lo registramos?

**13. Testimonio final.** `(Q25)`
¿Es obligatorio? ¿Pueden usar el testimonio públicamente (con nombre)?

---

## 🟢 Bloque 4 — Setup y estilo

**14. Herramientas actuales.** `(Q46, setup)`
¿Qué usan hoy para WhatsApp, para alojar los videos y para cobrar?

**15. Grupos y tamaño.** `(H9)`
¿Una cohorte = un grupo de WhatsApp? ¿Cuántas personas esperan por cohorte?

**16. Idioma, zona horaria y horarios.** `(Q15, Q29)`
Confirmamos España (es-ES). ¿A qué hora se manda el contenido diario?

**17. Tono "anti-ventaja".** `(Q12)`
¿Hay lineamientos de cómo deben sonar los mensajes (cercano, sin venta agresiva)? Impacta el contenido.

---

## Nota legal a tener presente (no es pregunta, es un cuidado)
En España multaron con 70.000 € a una empresa por **añadir a alguien a un grupo de WhatsApp sin su consentimiento**. Por eso el formulario pide consentimiento explícito y habrá baja fácil. Conviene tenerlo claro con el cliente.
