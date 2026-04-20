# PRD: Sistema de Concurso Interactivo "Flash-Show" (Offline)
## Versión 2.1

---

## 1. Resumen del Proyecto

Plataforma tecnológica para gestionar concursos de preguntas y mini-juegos analógicos. El sistema es totalmente portátil y funciona sin internet. El núcleo de la red (Broker MQTT y Control) reside en la Tablet del Presentador, permitiendo que la pantalla de visualización (TV o Proyector) sea un cliente intercambiable.

---

## 2. Objetivos y Visión

- **Portabilidad Total**: El sistema puede montarse en cualquier lugar con solo un router y las tablets.
- **Flexibilidad de Pantalla**: Compatibilidad con cualquier salida de video (TV, Proyector, Monitor) mediante un cliente Android o PC.
- **Control Centralizado**: El presentador tiene el control total de la lógica, el audio y la red desde su dispositivo.
- **Experiencia TV**: Recrear la estética y fluidez de un concurso televisivo profesional.

---

## 3. Arquitectura del Sistema

### 3.1 Hardware

| Componente | Cantidad | Descripción |
|------------|----------|-------------|
| **Tablet Presentador** | 1 | Tablet Android. Ejecuta Broker MQTT (Mosquitto vía Termux) + App de Control. Es el cerebro del sistema. |
| **Pantalla Principal** | 1 | Proyector o TV conectado a un dispositivo que ejecute la App de Pantalla (Godot): TV Box Android, proyector Android, o laptop con Godot. |
| **Tablets Equipo** | 3 | Tablets Android (Equipos 1, 2 y 3). Pantalla táctil para seleccionar respuestas. |
| **Pulsadores ESP32** | 3 + 1 repuesto | ESP32 con botones industriales (Equipos 1, 2 y 3). |
| **Router Wi-Fi** | 1 | Router local sin salida a internet. IPs estáticas para 8-9 dispositivos. |
| **Audio** | 1 | Salida de audio conectada al dispositivo de la Pantalla Principal (sincronización visual/auditiva). |
| **Material MiniJuegos** | 1 kit | Bolígrafos, botellas, gomitas, galletas, donuts, cuerdas, cintas, etc. (ver banco de minijuegos). |

### 3.2 Software Stack

| Componente | Tecnología |
|------------|------------|
| **Motor de Juego** | Godot Engine — App única con 3 modos: Pantalla, Presentador, Jugador |
| **Protocolo** | MQTT (Broker: Mosquitto corriendo en la Tablet del Presentador vía Termux) |
| **Firmware Pulsadores** | C++ (Arduino IDE) con librería PubSubClient |
| **Datos** | Archivos JSON locales para preguntas, minijuegos y rankings |
| **Automatización** | Scripts Python en Termux para procesar rankings complejos (opcional) |

---

## 4. Requisitos Funcionales

### 4.1 Rol: Presentador (Tablet Servidor) — EL CEREBRO

- **Host del Broker**: Mantener Mosquitto activo en segundo plano vía Termux.
- **Gestión de Juego**: Controlar flujo de preguntas, activar/desactivar pulsadores, corregir puntos, lanzar minijuegos.
- **Visor Privado**: Ver la respuesta correcta y tarjetas de apoyo (mímica, retos) que el público NO ve.
- **Control de Audio**: Lanzar efectos de sonido que se reproducen en la Pantalla Principal vía MQTT.
- **Arbitraje Manual**: Botones para sumar/restar puntos en mini-juegos analógicos.
- **Dashboard de Puntuación**: Marcador en tiempo real de los 3 equipos.
- **Banco de Preguntas**: Carga de preguntas desde JSON. Selección por ronda, categoría o aleatoria.
- **Gestión de MiniJuegos**: Activar modo minijuego, mostrar instrucciones en pantalla, cronómetro.
- **Botonera de Sonidos**: Soundboard para efectos manuales (aplausos, tensión, buzzer, fanfarria).

### 4.2 Rol: Pantalla Principal (TV/Proyector) — EL SHOW

- **Modo Esclavo**: Escucha mensajes MQTT y renderiza la interfaz visual del concurso.
- **Reproductor de Medios**: Música de fondo y efectos sonoros recibidos por la red local.
- **Animaciones**: Feedback visual inmediato ante cualquier evento (acierto, error, buzzer, cuenta atrás).
- **Marcador**: Puntuación en tiempo real de los 3 equipos, siempre visible.
- **Modo Pregunta**: Muestra pregunta + 4 opciones. Resalta la correcta cuando el presentador lo indica.
- **Modo MiniJuego**: Muestra instrucciones, cronómetro y nombre del minijuego activo.
- **Modo Resultados**: Ranking final con animaciones.

### 4.3 Rol: Equipos (Tablets Jugador) — LA INTERFAZ

- **Input Táctil**: Selección de respuestas A/B/C/D cuando el presentador habilita el turno.
- **Identidad Fija**: Cada tablet fijada a un ID de equipo (1, 2 o 3). Colores y logos distintos.
- **Feedback**: "¡Tu turno!", "Correcto ✅", "Incorrecto ❌", "Esperando...".
- **Bloqueo**: Input deshabilitado hasta que el presentador lo permita.

### 4.4 Rol: Pulsadores (ESP32) — EL GATILLO

- **Velocidad**: Detección de pulsación física por interrupciones. Envío inmediato del mensaje `concurso/pulsar`.
- **Conectividad**: Conexión automática al Wi-Fi del router y al Broker MQTT.
- **Prioridad**: QoS 1 para asegurar entrega del mensaje.
- **LED Indicador**: LED que se enciende al pulsar (feedback visual para el jugador).
- **Debounce**: Configuración de debounce para evitar pulsaciones dobles (50-100ms).

---

## 5. Especificaciones Técnicas (MQTT Topics)

| Topic | Dirección | Payload |
|-------|-----------|---------|
| `concurso/estado` | Presentador → Todos | `{ "estado": "pregunta", "pregunta_id": 42, "timeout": 15 }` |
| `concurso/estado` | Presentador → Todos | `{ "estado": "minijuego", "minijuego_id": 5, "timeout": 60 }` |
| `concurso/estado` | Presentador → Todos | `{ "estado": "resultados", "ranking": [...] }` |
| `concurso/estado` | Presentador → Todos | `{ "estado": "bloqueo", "equipo": 1 }` |
| `concurso/pulsar` | ESP32 → Todos | `{ "equipo": 1, "timestamp": 1713345678 }` |
| `concurso/respuesta` | Jugador → Presentador | `{ "equipo": 2, "opcion": "B" }` |
| `concurso/puntos` | Presentador → Pantalla | `{ "equipo": 3, "total": 450 }` |
| `concurso/tablet/lock` | Presentador → Jugador | `true` / `false` |
| `concurso/audio` | Presentador → Pantalla | `{ "fx": "aplausos" }` |
| `concurso/audio` | Presentador → Pantalla | `{ "music": "tension_start" }` |

---

## 6. Banco de Contenidos

### 6.1 Banco de Preguntas

- **80 preguntas** organizadas en 5 rondas (ver `preguntas.json`)
- Formato JSON compatible con Godot
- Cada pregunta: id, ronda, categoría, texto, 4 opciones, correcta, dato_curioso, tiempo, dificultad
- **Rondas**:
  1. ⚡ **Ronda Veloz** — 20 preguntas, 10s, fácil/medio
  2. 🖼️ **Ronda Imagen** — 15 preguntas, 15s, descripción visual
  3. 🤯 **Ronda Curiosidades** — 15 preguntas, 15s, datos sorprendentes
  4. 🧠 **Palencia Profunda** — 15 preguntas, 20s, difícil
  5. 🎯 **Ronda Desafío** — 15 preguntas/retos, 15-30s, mixto
- **Categorías**: historia, monumentos, gastronomía, naturaleza, personajes, tradiciones, deportes, geografía, cultura_pop, datos_insólitos

### 6.2 Banco de MiniJuegos

- **20 minijuegos** de interior (ver `minijuegos.json`)
- Formato JSON con: nombre, categoría, descripción, material, participantes, reglas, tiempo, dificultad
- **Categorías**: destreza, precisión, equilibrio, velocidad, cerebro, trabajo_equipo
- **Puntuación estándar**: 1º = 100 pts, 2º = 60 pts, 3º = 30 pts
- **Integración**: El presentador activa el modo minijuego desde la app → la Pantalla muestra instrucciones + cronómetro → el presentador asigna puntos manualmente

### 6.3 Banco de Sonidos

- Efectos: buzzer, acierto, error, aplausos, tensión, fanfarria, cuenta atrás, gong
- Música: tema inicio, música de fondo (tensa suave), música de victoria
- Formato: MP3/WAV almacenados localmente en cada dispositivo
- Reproducción: vía MQTT (comando desde Presentador → Pantalla)

---

## 7. Requisitos No Funcionales

- **Latencia**: Tiempo entre pulsación física y reacción en pantalla < 100ms.
- **Estabilidad del Broker**: La Tablet del Presentador debe tener desactivado cualquier ahorro de energía para Termux.
- **Configuración de Red**: Router con IPs estáticas. La Tablet del Presentador siempre en `192.168.1.10` (ejemplo) para que los ESP32 conozcan el Broker.
- **Interfaz Adaptativa**: Apps de Godot responsivas para distintos tamaños de tablet.
- **Autonomía**: El sistema debe aguantar 4 horas de uso continuo (gestión de batería en tablets).
- **Arranque Único**: Un único botón de "Encendido" debe dejar el sistema listo para jugar.
- **Backup Local**: Puntuaciones guardadas localmente en la Tablet del Presentador cada cambio.
- **Reset Rápido**: Botón de "Emergencia" para reiniciar el estado de la pregunta/minijuego actual.

---

## 8. Plan de Implementación

### Fase 1 — Servidor Móvil (Semana 1)
- [ ] Instalación de Termux + Mosquitto en la tablet del presentador
- [ ] Configuración de IPs estáticas en el router
- [ ] Programación básica de los ESP32 (Wi-Fi + MQTT)
- [ ] Test de conexión ESP32 → Tablet (verificar latencia < 100ms)
- [ ] Script de auto-arranque de Mosquitto en Termux

### Fase 2 — App Multimodo Godot (Semana 2)
- [ ] Pantalla de inicio con **switch de rol**: Presentador / Jugador / Pantalla
- [ ] Desarrollo de la arquitectura Master/Slave en Godot
- [ ] UI de la Pantalla Principal (marcador, preguntas, animaciones)
- [ ] UI de la Tablet del Presentador (dashboard de control, visor privado)
- [ ] UI de las Tablets de Jugador (selección de respuesta, feedback)
- [ ] Implementación del protocolo MQTT en Godot
- [ ] Sistema de carga de preguntas desde JSON
- [ ] Si rol = Jugador: selector de ID de equipo (1, 2 o 3)

### Fase 3 — Sincronización (Semana 3)
- [ ] Lógica de **Bloqueo de Pulsadores**: el primer mensaje `concurso/pulsar` que llega al broker gana el turno y bloquea el resto
- [ ] Confirmación visual inmediata en Pantalla ("¡Equipo X pulsó primero!")
- [ ] Bloqueo de tablets de los equipos perdedores hasta próximo turno
- [ ] Timeout de bloqueo configurable por el presentador
- [ ] Gestión de empates (doble pulsación simultánea < 10ms)

### Fase 4 — Contenidos y UI (Semana 4)
- [ ] Integración del banco de preguntas (80 preguntas, 5 rondas)
- [ ] Modo MiniJuego: instrucciones en pantalla, cronómetro, arbitraje manual
- [ ] Sistema de audio (efectos + música de fondo)
- [ ] Animaciones: transiciones, feedback visual, cuenta atrás
- [ ] Botonera de sonidos en la tablet del presentador
- [ ] Test de la experiencia completa (flujo concurso real)

### Fase 5 — Pruebas y Pulido (Semana 5)
- [ ] Simulacro completo con 3 equipos
- [ ] Ajuste de debounce en pulsadores ESP32
- [ ] Pruebas de audio y visibilidad con el proyector/TV real
- [ ] Pruebas de batería (4 horas continuas)
- [ ] Test de estabilidad del Broker MQTT
- [ ] Documentación de uso y troubleshooting
- [ ] Preparación del kit de material para mini-juegos

---

## 9. Estructura de Archivos

```
quiz-battle-palencia/
├── prd.md                          # Este documento
├── preguntas.json                  # Banco de 80 preguntas
├── preguntas.md                    # Versión legible
├── minijuegos.json                 # Banco de 20 minijuegos
├── godot/
│   ├── project.godot               # Proyecto Godot
│   ├── scenes/
│   │   ├── pantalla.tscn           # Escena Pantalla Principal
│   │   ├── presentador.tscn        # Escena Presentador
│   │   └── jugador.tscn            # Escena Jugador
│   ├── scripts/
│   │   ├── mqtt_client.gd          # Cliente MQTT genérico
│   │   ├── game_manager.gd         # Lógica del juego
│   │   ├── question_loader.gd      # Cargador de preguntas JSON
│   │   └── audio_manager.gd        # Gestión de audio
│   └── assets/
│       ├── audio/                  # Efectos y música
│       └── fonts/                  # Tipografías
├── esp32/
│   ├── pulsador/pulsador.ino       # Firmware ESP32
│   └── platformio.ini              # Config PlatformIO (opcional)
├── scripts/
│   ├── setup_termux.sh             # Setup de Termux + Mosquitto
│   ├── start_mosquitto.sh          # Auto-arranque del broker
│   └── backup_rankings.py          # Backup de puntuaciones
└── hardware/
    └── wiring_diagram.png          # Diagrama de conexiones ESP32
```

---

## 10. Consideraciones de Seguridad y Respaldo

- **Backup Offline**: Puntuaciones guardadas en la Tablet del Presentador cada vez que cambian (previene pérdida por apagón).
- **Reset de Emergencia**: Botón en la tablet del presentador para reiniciar el estado actual sin perder puntuaciones acumuladas.
- **Failover Manual**: Si un ESP32 falla, el presentador puede asignar el buzzer manualmente desde la tablet.
- **Logs**: Registro de eventos del juego para auditoría post-concurso (opcional).
