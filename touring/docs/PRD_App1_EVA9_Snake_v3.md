# PRD: App 1 — Password EVA-9 + Mini-juego Snake

**Proyecto:** Test de Touring — Escape Room Educativo sobre IA
**Prueba:** P2 — Huella Digital
**Sala:** Sala 2 (Archivo de Datos)
**Público:** Jóvenes 12-18 años, 5-6 jugadores
**Duración en tablet:** ~5-7 minutos (2 min password + 1-3 min snake + transiciones)
**Fecha:** Abril 2026
**Versión:** 3.1 (landscape)

---

## 1. Resumen Ejecutivo

App Godot 4.x para Android (tablet, **landscape**). Una única escena principal con **5 estados** gestionados por un `StateMachine` central. El Game Master (GM) activa la revelación de un mensaje de EVA-9 que muestra la contraseña **PERFIL**. Los jugadores la introducen para desbloquear un **mini-juego Snake**. Al completarlo (15 ítems), la serpiente se transforma en la letra **U** con un mensaje pedagógico de la Dra. Torres sobre lo "Único" de la huella digital.

**Flujo resumido:**
```
INIT (2s) → WAITING (GM trigger) → REVEAL (typewriter) → PASSWORD (input) → TRANSITION (shader) → SNAKE (juego) → VICTORIA (U)
```

---

## 2. Diagrama de Estados

```
                    ┌──────────────┐
                    │    INIT      │
                    └──────┬───────┘
                           │ (2s auto)
                    ┌──────▼───────┐
               ┌───►│   WAITING    │◄──────────────────────────┐
               │    └──────┬───────┘                           │
               │           │ (triple-tap sup. izq.)            │
               │    ┌──────▼───────┐                           │
               │    │   REVEAL     │                           │
               │    └──────┬───────┘                           │
               │           │ (typewriter completa)             │
               │    ┌──────▼───────┐                           │
               │    │   PASSWORD   │                           │
               │    └──────┬───────┘                           │
               │           │ (input "PERFIL")                  │
               │    ┌──────▼───────┐                           │
               │    │  TRANSITION  │                           │
               │    └──────┬───────┘                           │
               │           │ (animación termina)               │
               │    ┌──────▼───────┐     ┌──────────────┐     │
               │    │    SNAKE     ├─────►│  GAME OVER   │     │
               │    └──────┬───────┘ choque└──────┬───────┘     │
               │           │              retry    │             │
               │           │ (long. ≥ 15)          │             │
               │    ┌──────▼───────┐                │             │
               │    │   VICTORIA   │◄───────────────┘             │
               │    └──────┬───────┘                              │
               │           │                                      │
               └───────────┘ (GM reinicio → limpia estado) ──────┘
```

**Reglas de transición:**
- Toda transición es unidireccional hacia adelante (excepto Game Over → Snake y GM Reset → Init)
- No existe botón "atrás" del sistema (kiosk mode)
- El GM puede forzar saltos: `WAITING → REVEAL`, `SNAKE → VICTORIA`, `CUALQUIERA → INIT`

---

## 3. Paleta de Colores y Tipografía

### 3.1. Paleta de Color

| Token | Hex | Uso |
|-------|-----|-----|
| `bg_primary` | `#0A0A0F` | Fondo principal (negro azulado) |
| `bg_terminal` | `#0D1117` | Fondo de "terminal" en REVEAL/PASSWORD |
| `neon_green` | `#00FF88` | Texto terminal, acentos positivos, EVA-9 |
| `neon_magenta` | `#FF00FF` | Ítems del Snake, acentos de datos |
| `neon_cyan` | `#00DDFF` | Links, hints, elementos secundarios |
| `error_red` | `#FF2244` | Password incorrecto, game over |
| `text_primary` | `#E8E8E8` | Texto principal legible |
| `text_dim` | `#5A6070` | Texto secundario, esperando... |
| `ui_surface` | `#1A1A2E` | Paneles, cards, teclado virtual |
| `ui_border` | `#2A2A3E` | Bordes sutiles, separadores |

### 3.2. Tipografía

| Elemento | Fuente | Tamaño | Peso |
|----------|--------|--------|------|
| Título EVA-9 | `JetBrainsMono` (MSDF) | 48sp | Bold |
| Texto terminal/typewriter | `JetBrainsMono` (MSDF) | 28sp | Regular |
| Password input | `JetBrainsMono` (MSDF) | 36sp | Bold |
| Botones teclado | `JetBrainsMono` (MSDF) | 24sp | Medium |
| Score Snake | `JetBrainsMono` (MSDF) | 20sp | Regular |
| Mensaje victoria | `Inter` (MSDF) | 22sp | Regular |
| Label Dra. Torres | `Inter` (MSDF) | 18sp | Italic |

> **Nota MSDF:** Todas las fuentes se importan como MSDF para mantener nitidez con efectos Glow, Glitch y Dissolve. Se usa un `ShaderMaterial` personalizado con outline + glow.

---

## 4. Layout de Pantalla (Landscape, tablet ~10")

```
┌────────────────────────────────────────────────────────────────────────────┐
│ [GM]                                                                 [GM] │ ← 48px
│  triple-tap                                                    triple-tap │    esquinas
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│                                                                            │
│                     ÁREA DE CONTENIDO PRINCIPAL                            │ ← Variable según estado
│                     (centrado vertical y horizontal)                       │
│                                                                            │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│                         ZONA DE INTERACCIÓN                                │ ← Teclado / Score bar
│                         (240px altura, solo en PASSWORD)                   │
└────────────────────────────────────────────────────────────────────────────┘

Dimensiones de referencia: 1920 × 1200 (10" tablet landscape)
Safe area: 48px horizontal, 24px vertical
DPI target: mdpi ~160dpi (assets en 1x, Godot escala)
Orientación: Landscape forzada (handheld landscape left)
```

### 4.1. Layout por Estado

**WAITING / INIT:**
- Centro: texto "Esperando conexión de archivos..." + puntos animados
- Sin zona de interacción

**REVEAL:**
- Centro: texto typewriter en bloque de 60% ancho máximo (≈1150px), alineado a izquierda con margen lateral
- Sin zona de interacción

**PASSWORD:**
- Centro-superior: display de password (6 guiones bajos → letras), centrado
- Abajo (240px): teclado virtual QWERTY (3 filas, solo A-Z + borrar + enter)
- Lateral derecho: vacío (la ventaja del landscape — el teclado no compite con el display)

**SNAKE:**
- Centro: grid del juego rectangular (ver sección 5.6), centrado
- Superior-derecha: score "DATOS: 0/15"
- Grid ocupa ~70% del alto de pantalla, dejando márgenes cómodos

**VICTORIA:**
- Centro: animación de la serpiente formando la U en el grid
- Debajo del grid: mensaje Dra. Torres, centrado

---

## 5. Descripción Detallada de Estados

### 5.1. INIT → WAITING

**Visual:**
- Pantalla negra (`bg_primary`).
- Logo EVA-9 aparece con fade-in (1s, Ease.InOut).
- Glitch sutil: 2 frames de desplazamiento horizontal (±4px) a los 0.5s y 1.5s.

**Duración:** 2 segundos, transición automática.

**Criterio de aceptación:**
- [ ] Logo visible y centrado tras 1s
- [ ] Glitch sutil perceptible pero no molesto
- [ ] Transición a WAITING automática a los 2s sin intervención

---

### 5.2. WAITING (Estado Pasivo)

**Visual:**
- Texto `"Esperando conexión de archivos..."` centrado, color `text_dim`.
- Puntos animados: ciclo de 3 puntos ("...", "  .", ". .") cada 1.5s.
- Opcional: partículas de "polvo digital" cayendo lentamente (20 partículas, `neon_cyan` a 10% opacidad).

**GM Trigger:** Triple-tap en esquina superior izquierda (zona 48x48px) dentro de 800ms.

**Criterio de aceptación:**
- [ ] Animación de puntos fluida
- [ ] Triple-tap responde correctamente (debounce de 800ms)
- [ ] No se activa accidentalmente con toques normales

---

### 5.3. REVEAL (Narrativa)

**Texto completo:**
> "Cada expediente es un PERFIL. Vuestra huella digital no es privada — es un producto. Encontrad la clave en lo que compartís."

**Efecto:** Typewriter a 30ms/char, color `neon_green`, con cursor parpadeando al final.
**Audio:** Beep de terminal por carácter (SFX `type_click.wav`, 40ms, volumen -12dB).
**Duración estimada:** ~5.5s para el texto completo.

**Comportamiento post-typewriter:**
- Cursor parpadea 3 veces más tras terminar.
- Fade del cursor (0.3s).
- Pausa de 1s.
- Transición automática a PASSWORD.

**Si el GM quiere saltar:** Triple-tap en cualquier momento completa el texto instantáneamente y pasa a PASSWORD.

**Criterio de aceptación:**
- [ ] Typewriter fluido a 30ms/char sin frames perdidos
- [ ] Audio sincronizado con cada carácter
- [ ] Transición automática tras completar
- [ ] GM skip funciona correctamente

---

### 5.4. PASSWORD (Interacción)

**Display:**
- 6 guiones bajos centrados: `_ _ _ _ _ _`
- Al escribir, cada guión se reemplaza por la letra con un micro-bounce (scale 1.0 → 1.2 → 1.0, 150ms).

**Teclado virtual:**
- Layout QWERTY (3 filas) con solo letras A-Z.
- Fila extra: botón BORRAR (ancho 2 teclas) + botón ENVIAR (ancho 2 teclas).
- Tecla: 80x64px mínimo (aprovechando ancho landscape), `ui_surface` fondo, `text_primary` texto.
- Tecla pulsada: `neon_green` fondo, `bg_primary` texto (150ms).

**Validación:**
- Input: "PERFIL" (case-insensitive, el teclado solo tiene mayúsculas).
- Máximo 6 caracteres. Ignorar input extra.
- **Error:** Shake horizontal (±10px, 4 oscilaciones, 300ms), texto rojo `error_red`, vibración doble (50ms + pausa 100ms + 50ms). Display se limpia tras 1s.
- **Acierto:** Flash `neon_green` (200ms), vibración corta (80ms), transición inmediata a TRANSITION.

**Haptics:** Vibración de 30ms al pulsar cualquier tecla.

**Criterio de aceptación:**
- [ ] Teclado responde sin lag perceptible (< 16ms)
- [ ] Validación case-insensitive funciona
- [ ] Animación de error visible y haptics correctos
- [ ] No se puede submit con < 6 caracteres
- [ ] No se puede submit campo vacío

---

### 5.5. TRANSITION (Efecto Visual)

**Acción:** El texto "ACCESO CONCEDIDO" aparece en `neon_green` durante 1s, luego se desintegra pixel a pixel. Los píxeles caen y se reagrupan para formar el tablero del Snake.

**Implementación:**
- `ShaderMaterial` con dissolve usando noise threshold (perlin noise).
- Duración total: 2 segundos.
  - 0.0-0.5s: "ACCESO CONCEDIDO" aparece con glow.
  - 0.5-1.5s: Dissolve de texto → partículas caen.
  - 1.0-2.0s: Grid del Snake se forma desde las partículas (overlap).

**Fallback (si shader falla):** Fade cruzado simple (texto fade-out 0.5s → negro 0.3s → grid fade-in 0.5s).

**Criterio de aceptación:**
- [ ] Transición visual fluida en tablet target
- [ ] Fallback funciona si shader no es soportado
- [ ] No hay frame drops visibles (< 3 frames perdidos)
- [ ] Transición al estado SNAKE al completarse

---

### 5.6. SNAKE (Mini-juego)

#### Especificación del Grid

| Parámetro | Valor |
|-----------|-------|
| Tamaño grid | **25 × 15** celdas (rectangular, más ancho que alto) |
| Tamaño celda | 44px (en resolución de referencia 1920×1200) |
| Área de juego | 1100 × 660 px, centrada en pantalla |
| Longitud inicial serpiente | 3 segmentos |
| Posición inicial | Centro del grid, dirección: derecha |
| Velocidad | 150ms por tick (constante, no aumenta) |
| Wrap-around | Sí (sin paredes, la serpiente sale de un lado y entra por el otro) |
| Ítems en pantalla | 1 ítem activo a la vez |
| Objetivo | Recoger 15 ítems |

> **Por qué 25×15:** En landscape, la proporción de la pantalla es ~16:10. Un grid de 25×15 (5:3) se ajusta bien sin deformar celdas y deja margen para UI (score, mensajes). La serpiente tiene más espacio horizontal para movimiento fluido — el eje principal de juego.

#### Controles

- **Swipe táctil:** Umbral mínimo 20px, dirección determinada por eje dominante.
- **Vibración:** 30ms al cambiar dirección.
- **Anti-reverso:** No se puede ir en dirección opuesta (evita muerte instantánea).

#### Ítems "Datos"

- Color: `neon_magenta` con glow pulsante (escala 0.8 → 1.0 ciclo 500ms).
- Al recoger: vibración media (100ms), sonido `eat.wav` (80ms, tono ascendente).
- Score display: "DATOS: X/15" en esquina superior derecha, `neon_green`.

#### Colisión (Game Over)

- **Condición:** La serpiente choca consigo misma (no hay paredes).
- **Visual:** Serpiente parpadea en `error_red` (3 veces, 100ms c/u).
- **Audio:** `game_over.wav` (buzzer grave, 200ms).
- **Opción:** Botón "REINTENTAR" centrado aparece tras 1s.
- **Al reintentar:** Reset completo (serpiente longitud 3, score 0, misma posición inicial).

#### Victoria (longitud ≥ 18 = 3 inicial + 15 comida)

- **Trigger automático** al recoger el ítem 15.
- Transición inmediata a estado VICTORIA (sin pantalla intermedia).

**Criterio de aceptación:**
- [ ] Grid se dibuja correctamente a 25×15
- [ ] Swipe responsive sin lag (< 1 tick de delay)
- [ ] Wrap-around funciona en los 4 bordes
- [ ] Anti-reverso funciona correctamente
- [ ] Game Over solo por auto-colisión
- [ ] Retry resetea todo correctamente
- [ ] Victoria se trigger a los 15 ítems exactos

---

### 5.7. VICTORIA (Transformación Final)

**Animación: La Serpiente → Letra U**

Los segmentos de la serpiente (18 total) se deslizan mediante `Tween` hacia posiciones predefinidas que forman la letra **U**.

**Path2D de la U (grid 25×15):**
```
Forma: ┐           ┌
       │           │
       │           │
       └───────────┘

Dimensiones en celdas: 14 ancho × 10 alto
Posición: centrada en el grid 25×15
  Offset X: (25 - 14) / 2 = 5.5 → columna 5 a 19
  Offset Y: (15 - 10) / 2 = 2.5 → fila 2 a 12

Distribución de 18 segmentos (eje: columna, fila):

  Brazo izquierdo (5):  (6,2), (6,4), (6,6), (6,8), (6,10)
  Base inferior (6):    (7,12), (9,12), (11,12), (13,12), (15,12), (17,12)
  Brazo derecho (5):    (18,10), (18,8), (18,6), (18,4), (18,2)
  Esquinas (2):         (6,12), (18,12)

  Total: 5 + 6 + 5 + 2 = 18 segmentos ✓

  La U será ancha (14 celdas) y proporcional al grid landscape.
  Más legible que en portrait donde quedaba comprimida.
```

**Timeline:**
- 0.0-0.5s: Pausa, serpiente se "congela" en su posición actual.
- 0.5-2.5s: Segmentos se deslizan a sus posiciones objetivo (Ease.InOut, staggered 50ms entre segmentos).
- 2.5-3.0s: Glow pulse en la U completa.
- 3.0-3.5s: Fade del grid/snake, aparece fondo limpio.
- 3.5-5.0s: Mensaje Dra. Torres aparece con fade-in.

**Mensaje Dra. Torres:**
> "La letra U es porque tu huella digital es ÚNICA. No hay dos iguales en el mundo. Pero en internet, esa unicidad se convierte en un rastro que otros pueden seguir. ¿Sabés dónde dejás la tuya?"

**Haptics:** Vibración ascendente durante la formación (patrón: 20ms, 40ms, 60ms, 80ms, 100ms con 100ms entre cada uno).

**Criterio de aceptación:**
- [ ] 18 segmentos se posicionan formando una U reconocible
- [ ] Tween es fluido sin glitches
- [ ] Mensaje de Dra. Torres es legible
- [ ] Vibración ascendente funciona correctamente
- [ ] Estado persistido para recovery tras crash

---

## 6. Estructura del Proyecto Godot

```
touring-app1/
├── project.godot                    # Config: landscape, kiosk, 60fps cap
├── export_presets.cfg               # Android export
├── README.md
│
├── src/
│   ├── main/
│   │   ├── main.tscn                # Escena raíz (contiene StateMachine)
│   │   └── main.gd                  # Script raíz, orquesta estados
│   │
│   ├── state_machine/
│   │   ├── state_machine.gd         # Componente StateMachine genérico
│   │   └── state.gd                 # Clase base State
│   │
│   ├── states/
│   │   ├── init_state.gd
│   │   ├── waiting_state.gd
│   │   ├── reveal_state.gd
│   │   ├── password_state.gd
│   │   ├── transition_state.gd
│   │   ├── snake_state.gd
│   │   └── victory_state.gd
│   │
│   ├── snake/
│   │   ├── snake_grid.gd            # Lógica del grid 25×15
│   │   ├── snake_player.gd          # Movimiento, colisión, crecimiento
│   │   ├── snake_item.gd            # Ítems "datos"
│   │   └── snake_input.gd           # Procesamiento de swipe
│   │
│   ├── ui/
│   │   ├── virtual_keyboard.tscn    # Escena del teclado QWERTY
│   │   ├── virtual_keyboard.gd
│   │   ├── password_display.tscn    # Display de 6 caracteres
│   │   ├── password_display.gd
│   │   └── gm_overlay.tscn          # Menú emergente GM
│   │
│   ├── effects/
│   │   ├── typewriter.gd            # Componente typewriter reutilizable
│   │   ├── dissolve_transition.gd   # Shader dissolve
│   │   └── glitch_effect.gd         # Efecto glitch para logo
│   │
│   ├── gm/
│   │   ├── gm_controller.gd         # Triple-tap detection
│   │   └── gm_menu.gd               # Menú emergente opciones
│   │
│   └── persistence/
│       └── state_saver.gd           # Guardado/restauración de estado
│
├── assets/
│   ├── fonts/
│   │   ├── JetBrainsMono-Bold_MSDF.tres
│   │   ├── JetBrainsMono-Regular_MSDF.tres
│   │   ├── Inter-Regular_MSDF.tres
│   │   └── Inter-Italic_MSDF.tres
│   │
│   ├── audio/
│   │   ├── type_click.wav           # Beep terminal (40ms)
│   │   ├── eat.wav                  # Recoger ítem (80ms, ascendente)
│   │   ├── game_over.wav            # Game over (200ms, grave)
│   │   ├── victory.wav              # Victoria (500ms, fanfarria suave)
│   │   ├── error.wav                # Password incorrecto (100ms, buzz)
│   │   └── turn.wav                 # Cambio dirección snake (30ms, tick)
│   │
│   ├── shaders/
│   │   ├── dissolve.gdshader        # Efecto disolución
│   │   ├── msdf_text.gdshader       # Texto con glow + outline
│   │   └── glitch.gdshader          # Efecto glitch
│   │
│   └── sprites/
│       ├── eva9_logo.png            # Logo EVA-9 (SVG import)
│       └── snake_segment.png        # Segmento base (8x8 con border)
│
└── docs/
    └── PRD_App1_EVA9_Snake_v3.md    # Este documento
```

---

## 7. Arquitectura de Signals

```gdscript
# Central EventBus (Autoload)
signal game_state_changed(from: StringName, to: StringName)
signal gm_trigger_activate()          # WAITING → REVEAL
signal gm_trigger_menu()              # Abrir menú GM
signal gm_skip_snake()                # SNAKE → VICTORIA
signal gm_reset_all()                 # Cualquiera → INIT
signal password_submitted(text: String)
signal password_accepted()
signal password_rejected()
signal snake_ate_item()
signal snake_died()
signal snake_victory()
signal transition_complete()
signal state_persisted(state_name: StringName)
signal state_restored(state_name: StringName)
```

**Flujo de datos:**
- `StateMachine` emite `game_state_changed` en cada transición.
- `StateSaver` escucha `game_state_changed` y persiste hitos (PASSWORD desbloqueado, VICTORIA alcanzado).
- Los estados individuales NO se comunican entre sí — todo pasa por `StateMachine` o `EventBus`.

---

## 8. Persistencia y Recovery

### 8.1. Hitos persistentes

```ini
# user://room_state.cfg
[progress]
milestone=PASSWORD_UNLOCKED    # o SNAKE_STARTED, VICTORY_REACHED
timestamp=1713020400

[snake]
score=0                         # Solo relevante si milestone=SNAKE_STARTED
```

### 8.2. Reglas de recovery

| Milestone guardado | Comportamiento al reiniciar app |
|---------------------|-------------------------------|
| `PASSWORD_UNLOCKED` | Saltar directamente a estado SNAKE (sin password) |
| `VICTORY_REACHED` | Mostrar directamente estado VICTORIA |
| Sin archivo | Arrancar desde INIT normalmente |

**NO se persiste el estado del Snake en juego** (posición, dirección, etc.). Si la app crashea durante el Snake, se reinicia el juego desde longitud 3.

---

## 9. Controles del Game Master (GM)

| Acción | Gesto | Resultado |
|--------|-------|-----------|
| **Activar Juego** | Triple-tap esquina sup. izquierda (800ms) | `WAITING` → `REVEAL` |
| **Menú de Emergencia** | Triple-tap esquina sup. derecha (800ms) | Abre overlay GM |
| **Saltar Snake** | Botón en Menú GM | `SNAKE` → `VICTORIA` |
| **Reiniciar Todo** | Botón en Menú GM (con confirmación) | Borra `room_state.cfg`, vuelve a `INIT` |
| **Saltar Password** | Botón en Menú GM | Si está en `PASSWORD`, fuerza `TRANSITION` |

**Menú GM Overlay:**
- Semi-transparente (`bg_primary` a 80% opacidad).
- Botones grandes (mínimo 120x80px) para cada acción.
- Botón "CERRAR" para descartar.
- **Confirmación requerida** para "Reiniciar Todo" (doble tap en el botón).

---

## 10. Audio Design

| Evento | Archivo | Duración | Características |
|--------|---------|----------|----------------|
| Typewriter char | `type_click.wav` | 40ms | Click corto, tono 800Hz, -12dB |
| Tecla pulsada | `turn.wav` | 30ms | Tick suave, 600Hz, -18dB |
| Ítem recogido | `eat.wav` | 80ms | Tono ascendente 400→800Hz, -6dB |
| Password correcto | `eat.wav` | 80ms | Reutilizar con pitch +20% |
| Password incorrecto | `error.wav` | 100ms | Buzz grave 200Hz, -6dB |
| Game Over | `game_over.wav` | 200ms | Buzzer descendente 400→100Hz, -6dB |
| Victoria | `victory.wav` | 500ms | Fanfarria suave, 3 notas (C5-E5-G5), -6dB |

> Todos los archivos en formato `.wav` (16-bit, 44100Hz, mono). No usar MP3 por latencia en Android.

---

## 11. Asset List

| Asset | Formato | Origen | Estado |
|-------|---------|--------|--------|
| Logo EVA-9 | PNG (SVG import) | Diseño gráfico | Pendiente |
| JetBrainsMono-Bold | TTF → MSDF | Google Fonts (OFL) | Pendiente |
| JetBrainsMono-Regular | TTF → MSDF | Google Fonts (OFL) | Pendiente |
| Inter-Regular | TTF → MSDF | Google Fonts (OFL) | Pendiente |
| Inter-Italic | TTF → MSDF | Google Fonts (OFL) | Pendiente |
| SFX: type_click | WAV | Generado / freesound.org | Pendiente |
| SFX: eat | WAV | Generado / freesound.org | Pendiente |
| SFX: error | WAV | Generado / freesound.org | Pendiente |
| SFX: game_over | WAV | Generado / freesound.org | Pendiente |
| SFX: victory | WAV | Generado / freesound.org | Pendiente |
| SFX: turn | WAV | Generado / freesound.org | Pendiente |
| Shader: dissolve | GDShader | Custom | Pendiente |
| Shader: msdf_text | GDShader | Custom | Pendiente |
| Shader: glitch | GDShader | Custom | Pendiente |

---

## 12. Requisitos Técnicos

### Motor y Plataforma

| Requisito | Valor |
|-----------|-------|
| Motor | Godot 4.3+ |
| Target | Tablets Android 8.0+ (API 26+) |
| Orientación | **Landscape forzada** (handheld landscape left, lock rotation) |
| Resolución referencia | **1920 × 1200** (10" tablet landscape) |
| Scaling | `canvas_items` mode, aspect `keep` |

### Rendimiento

| Estado | FPS Target | Justificación |
|--------|------------|---------------|
| INIT, WAITING, PASSWORD | 30 FPS | Estados estáticos, ahorro de batería |
| REVEAL, TRANSITION, SICTORY | 60 FPS | Animaciones, tweens, efectos |
| SNAKE | 60 FPS | Gameplay responsivo |

**Optimizaciones:**
- Desactivar `_process` en estados inactivos (`process_mode = DISABLED`).
- Usar `Timer` nodes para el tick del Snake (no `_process` con delta).
- MSDF fonts para evitar text atlas gigantes.

### Modo Kiosk

- App configurada como launcher por defecto en las tablets.
- `ime_aware = false` en project.godot (evita teclado del sistema).
- Capturar botón back: `get_tree().quit()` override → no hacer nada.
- Barra de estado y navegación ocultas (immersive sticky mode via Android plugin).

---

## 13. Edge Cases y Robustez

| Situación | Comportamiento esperado |
|-----------|------------------------|
| Rotación de tablet | Ignorada (landscape lock) |
| App en background | Pausar todo (Timer + Tween pause) |
| App se cierra durante Snake | Al reabrir: ir a SNAKE con score 0 (según milestone) |
| App se cierra durante Victoria | Al reabrir: ir a VICTORIA directamente |
| GM reinicia durante Tween | Cancelar todos los Tweens, limpiar estado |
| Toques simultáneos en Snake | Solo registrar el primer swipe válido |
| Jugador no toca nada por 60s | Sin acción automática (el GM controla el ritmo) |
| Password con espacios | Ignorar espacios (solo procesar A-Z) |
| Triple-tap accidental | Zona de 48x48px + ventana 800ms = falso positivo extremadamente raro |

---

## 14. Checklist de Testing

### Funcionalidad Core
- [ ] Flujo completo INIT → WAITING → REVEAL → PASSWORD → TRANSITION → SNAKE → VICTORIA funciona sin errores
- [ ] Password "PERFIL" (case-insensitive) desbloquea correctamente
- [ ] Password incorrecto muestra error + shake + vibración
- [ ] Snake: wrap-around funciona en los 4 bordes
- [ ] Snake: anti-reverso funciona (no se muere al ir dirección opuesta)
- [ ] Snake: colisión consigo misma = Game Over
- [ ] Snake: al llegar a 15 ítems → VICTORIA automática
- [ ] Victoria: serpiente forma una U reconocible

### GM Controls
- [ ] Triple-tap sup. izq. activa REVEAL desde WAITING
- [ ] Triple-tap sup. der. abre menú GM
- [ ] Saltar Snake funciona
- [ ] Reiniciar Todo limpia persistencia y vuelve a INIT
- [ ] Menú GM tiene confirmación en "Reiniciar Todo"

### Rendimiento y Robustez
- [ ] FPS se mantiene en target en cada estado
- [ ] No hay frame drops visibles en TRANSITION
- [ ] App se recupera correctamente tras cierre forzado
- [ ] Modo kiosk impide salir de la app
- [ ] Rotación bloqueada (landscape)

### UX
- [ ] Fuente MSDF legible a 1 metro con efecto Glow
- [ ] Swipe del Snake responsive (umbral 20px)
- [ ] Vibración funciona en modelo específico de tablet
- [ ] Teclado virtual no tiene lag perceptible

---

## 15. Notas de Implementación

### Convenciones
- **Naming:** `snake_case` para archivos y variables, `PascalCase` para clases y `class_name`.
- **Señales:** declarar en el nodo que las emite, conectar en `_ready()`.
- **Constantes:** todos los "magic numbers" como constantes al inicio del script (grid size, tick speed, etc.).
- **Tipado estático:** obligatorio en TODAS las variables y firmas de funciones.

### Orden sugerido de implementación
1. Proyecto base + StateMachine + EventBus
2. INIT → WAITING (visual + GM trigger)
3. REVEAL (typewriter + audio)
4. PASSWORD (teclado + validación)
5. SNAKE (grid + movimiento + colisión + items)
6. TRANSITION (shader dissolve)
7. VICTORIA (tween + mensaje)
8. Persistencia y recovery
9. Modo kiosk y polish final

---

*Documento v3.1 — PRD mejorado para el Test de Touring — Escape Room Educativo*
