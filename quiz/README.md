# Quiz Offline

MVP de un sistema de concurso interactivo **offline** construido con **Godot 4.6** y **MQTT**.

La app está pensada para funcionar en red local sin internet, con un flujo de show en 3 roles:

- **Presentador**: controla la partida, carga preguntas, arbitra respuestas y puntajes.
- **Pantalla**: muestra el estado público del concurso.
- **Concursante**: responde desde una tablet asociada a un equipo.

## Estado actual

El proyecto ya tiene un MVP funcional validado técnicamente:

- App Godot multimodo con selector de rol.
- Flujo MQTT local funcionando con Mosquitto.
- Selector real de preguntas para presentador:
  - filtro por ronda
  - selección por pregunta
  - aleatoria por ronda
  - preview privada
- Seguimiento de preguntas usadas en sesión.
- Persistencia local básica del presentador en `user://presenter_session.json`.
- Corrección explícita de respuesta:
  - pendiente
  - correcta
  - incorrecta
- Arbitraje y locks por equipo más finos.
- Smoke tests y pruebas headless/E2E auxiliares para validación técnica.

## Estructura principal

```text
quiz/
├── README.md
├── prd.md
└── godot/
    ├── project.godot
    ├── main.tscn
    ├── addons/mqtt/
    ├── autoload/
    ├── data/
    ├── scenes/
    ├── scripts/
    └── tests/
```

## Stack

- **Godot 4.6**
- **Mosquitto / MQTT**
- **JSON local** para preguntas

## Arquitectura

El sistema actual mantiene una arquitectura simple y pragmática para el MVP:

- `AppState`: estado compartido de app/rol/partida.
- `ContentRepo`: carga de preguntas desde JSON.
- `GameService`: lógica de juego, arbitraje, persistencia local y sincronización.
- `MqttBus`: wrapper del addon MQTT.

El presentador sigue siendo la autoridad del sistema.

## Requisitos

- **Godot 4.6**
- **Mosquitto** levantado en red local o en la misma máquina

Ejemplo local típico:

- host: `127.0.0.1`
- puerto: `1883`

## Cómo abrir el proyecto

1. Abrí **Godot 4.6**.
2. Importá el proyecto desde:

```text
quiz/godot/project.godot
```

3. Ejecutá `main.tscn`.
4. Elegí rol:
   - Presentador
   - Concursante
   - Pantalla

## Cómo probar con Mosquitto local (Windows)

Si tenés Mosquitto instalado en Windows, por ejemplo en:

```text
C:\Program Files\mosquitto
```

podés arrancarlo así:

```powershell
& "C:\Program Files\mosquitto\mosquitto.exe" -p 1883 -v
```

Luego abrís varias instancias de la app y elegís distintos roles.

## Flujo actual del MVP

### Presentador

- selecciona ronda y pregunta
- carga pregunta
- abre turno
- recibe primera respuesta válida
- corrige como correcta o incorrecta
- revela
- ajusta puntajes

### Concursante

- espera turno
- responde A/B/C/D cuando está habilitado
- recibe feedback visual de estado y corrección

### Pantalla

- muestra pregunta
- muestra marcador
- muestra locks / equipo activo / feedback público

## Datos

El banco inicial de ejemplo está en:

```text
quiz/godot/data/preguntas.json
```

## Notas importantes

- El proyecto está orientado a uso **offline/local**.
- La persistencia actual es **básica** y solo del lado del presentador.
- El addon MQTT fue vendoreado y parchado para soportar correctamente **UTF-8** en payloads.

## Próximos pasos naturales

- audio/soundboard real
- minijuegos
- integración con pulsadores ESP32
- mejora visual/animaciones show-ready
- endurecer más la lógica de arbitraje

## Documento funcional

La visión completa del producto está en:

```text
quiz/prd.md
```
