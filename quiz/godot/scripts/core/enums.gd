class_name Enums
extends RefCounted

enum AppRole {
	NONE,
	PRESENTER,
	CONTESTANT,
	DISPLAY,
}

enum GamePhase {
	IDLE,
	QUESTION,
	REVEAL,
	RESULTS,
	MINIGAME,
	LOCKED,
}

enum AnswerFeedbackStatus {
	NONE,
	PENDING,
	CORRECT,
	INCORRECT,
}

enum TeamLockState {
	READY,
	LOCKED_OUT,
	ACTIVE,
	FROZEN,
}


static func role_name(role: int) -> String:
	match role:
		AppRole.PRESENTER:
			return "Presentador"
		AppRole.CONTESTANT:
			return "Equipo"
		AppRole.DISPLAY:
			return "Pantalla"
		_:
			return "Sin rol"


static func phase_name(phase: int) -> String:
	match phase:
		GamePhase.QUESTION:
			return "Pregunta"
		GamePhase.REVEAL:
			return "Revelación"
		GamePhase.RESULTS:
			return "Resultados"
		GamePhase.MINIGAME:
			return "Minijuego"
		GamePhase.LOCKED:
			return "Respuesta tomada"
		_:
			return "En espera"


static func answer_feedback_name(status: int) -> String:
	match status:
		AnswerFeedbackStatus.PENDING:
			return "Pendiente"
		AnswerFeedbackStatus.CORRECT:
			return "Correcta"
		AnswerFeedbackStatus.INCORRECT:
			return "Incorrecta"
		_:
			return "Sin feedback"


static func team_lock_state_name(state: int) -> String:
	match state:
		TeamLockState.LOCKED_OUT:
			return "Bloqueado"
		TeamLockState.ACTIVE:
			return "Con turno"
		TeamLockState.FROZEN:
			return "En pausa"
		_:
			return "Listo"
