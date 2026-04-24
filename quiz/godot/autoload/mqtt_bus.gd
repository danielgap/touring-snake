extends Node

signal connected()
signal disconnected()
signal connection_error(reason: String)
signal adapter_missing()
signal message_received(topic: String, payload: Variant)

const DEFAULT_HOST: String = "127.0.0.1"
const DEFAULT_PORT: int = 1883

var _adapter: Node = null
var _connected: bool = false
var _subscriptions: Dictionary = {}


func _ready() -> void:
	_adapter = get_node_or_null("MQTT")
	_bind_adapter()
	if not _has_adapter_api():
		emit_signal("adapter_missing")


func _bind_adapter() -> void:
	if _adapter == null:
		return

	_connect_adapter_signal("broker_connected", Callable(self, "_on_adapter_connected"))
	_connect_adapter_signal("broker_disconnected", Callable(self, "_on_adapter_disconnected"))
	_connect_adapter_signal("broker_connection_failed", Callable(self, "_on_adapter_connection_failed"))
	_connect_adapter_signal("received_message", Callable(self, "_on_adapter_message_received"))


func connect_to_broker(host: String = DEFAULT_HOST, port: int = DEFAULT_PORT) -> bool:
	if _adapter == null or not _adapter.has_method("connect_to_broker"):
		emit_signal("connection_error", "MQTT adapter missing connect_to_broker(broker_url)")
		return false

	var broker_url: String = _broker_url(host, port)
	var result: Variant = _adapter.call("connect_to_broker", broker_url)
	if result is bool and not result:
		_connected = false
		emit_signal("connection_error", "MQTT connect_to_broker failed for %s" % broker_url)
		return false

	return true


func disconnect_from_broker() -> bool:
	if _adapter == null:
		_connected = false
		return false

	var emits_disconnect_signal: bool = _adapter.has_signal("broker_disconnected")
	if _adapter.has_method("disconnect_from_broker"):
		_adapter.call("disconnect_from_broker")
	elif _adapter.has_method("disconnect_from_server"):
		_adapter.call("disconnect_from_server")
	elif _adapter.has_method("disconnect"):
		_adapter.call("disconnect")
	else:
		_connected = false
		return false

	_connected = false
	if not emits_disconnect_signal:
		emit_signal("disconnected")
	return true


func subscribe_topic(topic: String, qos: int = 0) -> bool:
	_subscriptions[topic] = qos
	if _adapter == null or not _adapter.has_method("subscribe"):
		return false
	if not _connected:
		return true
	var result: Variant = _adapter.call("subscribe", topic, qos)
	return false if result is bool and not result else true


func unsubscribe_topic(topic: String) -> bool:
	_subscriptions.erase(topic)
	if _adapter == null or not _adapter.has_method("unsubscribe"):
		return false
	if not _connected:
		return true
	var result: Variant = _adapter.call("unsubscribe", topic)
	return false if result is bool and not result else true


func publish_json(topic: String, payload: Variant, retain: bool = false, qos: int = 0) -> bool:
	var json_payload: String = MessageCodec.encode_json(payload)
	if _adapter == null or not _adapter.has_method("publish"):
		return false

	var result: Variant = _adapter.call("publish", topic, json_payload, retain, qos)
	return false if result is bool and not result else true


func is_broker_connected() -> bool:
	return _connected


func get_diag_info() -> String:
	if _adapter != null and _adapter.has_method("get_diag_info"):
		return _adapter.call("get_diag_info")
	return "no adapter"


func _connect_adapter_signal(signal_name: String, callable: Callable) -> void:
	if not _adapter.has_signal(signal_name):
		return
	if _adapter.is_connected(signal_name, callable):
		return
	_adapter.connect(signal_name, callable)


func _has_adapter_api() -> bool:
	if _adapter == null:
		return false
	return _adapter.has_method("connect_to_broker") \
		or _adapter.has_method("subscribe") \
		or _adapter.has_method("publish") \
		or _adapter.has_signal("broker_connected") \
		or _adapter.has_signal("received_message")


func _broker_url(host: String, port: int) -> String:
	return "tcp://%s:%d/" % [host, port]


func _on_adapter_connected() -> void:
	_connected = true
	for topic: String in _subscriptions.keys():
		var qos: int = int(_subscriptions[topic])
		_adapter.call("subscribe", topic, qos)
	emit_signal("connected")


func _on_adapter_disconnected() -> void:
	_connected = false
	emit_signal("disconnected")


func _on_adapter_connection_failed(reason: Variant = null) -> void:
	_connected = false
	var failure_reason: String = "MQTT broker connection failed"
	if reason != null:
		failure_reason = String(reason)
	emit_signal("connection_error", failure_reason)


func _on_adapter_message_received(topic: Variant, payload: Variant = "") -> void:
	var decoded_payload: Variant = payload
	if payload is String:
		var maybe_json: Variant = JSON.parse_string(payload)
		if maybe_json != null or payload.strip_edges() == "null":
			decoded_payload = maybe_json
	emit_signal("message_received", String(topic), decoded_payload)
