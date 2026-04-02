extends Node
class_name OpenAIImageService

signal generation_started(prompt: String, size: String, quality: String)
signal generation_succeeded(prompt: String, save_path: String, absolute_path: String)
signal generation_failed(message: String)

const CONFIG_PATH: String = "user://openai_image.cfg"
const OUTPUT_DIR: String = "user://generated_images"
const API_URL: String = "https://api.openai.com/v1/images/generations"
const DEFAULT_MODEL: String = "gpt-image-1.5"
const DEFAULT_SIZE: String = "1024x1024"
const DEFAULT_QUALITY: String = "medium"
const SUPPORTED_SIZES: Array[String] = ["1024x1024", "1536x1024", "1024x1536"]
const SUPPORTED_QUALITIES: Array[String] = ["low", "medium", "high"]

var default_size: String = DEFAULT_SIZE
var default_quality: String = DEFAULT_QUALITY

var _http_request: HTTPRequest = null
var _api_key: String = ""
var _saved_api_key: String = ""
var _key_source: String = "missing"
var _busy: bool = false

func _ready() -> void:
	_ensure_http_request()
	load_config()

func load_config() -> void:
	default_size = DEFAULT_SIZE
	default_quality = DEFAULT_QUALITY
	_saved_api_key = ""
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		_saved_api_key = String(config.get_value("auth", "api_key", "")).strip_edges()
		default_size = _sanitize_size(String(config.get_value("image", "size", DEFAULT_SIZE)))
		default_quality = _sanitize_quality(String(config.get_value("image", "quality", DEFAULT_QUALITY)))
	if _saved_api_key != "":
		_api_key = _saved_api_key
		_key_source = "saved"
		return
	_api_key = _load_env_api_key()
	_key_source = "env" if _api_key != "" else "missing"

func save_config() -> int:
	var config := ConfigFile.new()
	config.set_value("auth", "api_key", _saved_api_key)
	config.set_value("image", "size", default_size)
	config.set_value("image", "quality", default_quality)
	return config.save(CONFIG_PATH)

func set_api_key(api_key: String) -> int:
	_saved_api_key = api_key.strip_edges()
	_api_key = _saved_api_key
	_key_source = "saved" if _api_key != "" else "missing"
	return save_config()

func clear_saved_api_key() -> int:
	_saved_api_key = ""
	_api_key = _load_env_api_key()
	_key_source = "env" if _api_key != "" else "missing"
	return save_config()

func has_api_key() -> bool:
	return _api_key != ""

func get_api_key_source() -> String:
	return _key_source

func get_masked_api_key() -> String:
	if _api_key.length() <= 8:
		return _api_key
	return "%s...%s" % [_api_key.left(6), _api_key.right(4)]

func set_defaults(size: String, quality: String) -> int:
	default_size = _sanitize_size(size)
	default_quality = _sanitize_quality(quality)
	return save_config()

func get_supported_sizes() -> Array[String]:
	return SUPPORTED_SIZES.duplicate()

func get_supported_qualities() -> Array[String]:
	return SUPPORTED_QUALITIES.duplicate()

func is_busy() -> bool:
	return _busy

func generate_image(prompt: String, size: String = "", quality: String = "") -> Dictionary:
	var clean_prompt: String = prompt.strip_edges()
	if clean_prompt == "":
		return _make_error("Prompt is required.")
	if _busy:
		return _make_error("An image request is already running.")
	if not has_api_key():
		return _make_error("Configure an OpenAI API key first.")

	_ensure_http_request()
	var request_size: String = _sanitize_size(size if size != "" else default_size)
	var request_quality: String = _sanitize_quality(quality if quality != "" else default_quality)
	var payload: Dictionary = {
		"model": DEFAULT_MODEL,
		"prompt": clean_prompt,
		"size": request_size,
		"quality": request_quality,
		"n": 1,
		"output_format": "png",
	}
	var headers := PackedStringArray([
		"Authorization: Bearer %s" % _api_key,
		"Content-Type: application/json",
	])

	_busy = true
	generation_started.emit(clean_prompt, request_size, request_quality)
	var request_err: int = _http_request.request(
		API_URL,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if request_err != OK:
		_busy = false
		var send_error: String = "Request failed to start: %s" % error_string(request_err)
		generation_failed.emit(send_error)
		return _make_error(send_error)

	var response: Array = await _http_request.request_completed
	_busy = false
	return _consume_generation_response(clean_prompt, response)

func _consume_generation_response(prompt: String, response: Array) -> Dictionary:
	var request_result: int = int(response[0])
	var response_code: int = int(response[1])
	var body: PackedByteArray = response[3]
	var body_text: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(body_text)

	if request_result != HTTPRequest.RESULT_SUCCESS:
		var transport_error: String = "Network request failed with code %d." % request_result
		generation_failed.emit(transport_error)
		return _make_error(transport_error)

	if response_code < 200 or response_code >= 300:
		var api_error: String = _extract_api_error(parsed)
		var message: String = "OpenAI error (%d): %s" % [response_code, api_error]
		generation_failed.emit(message)
		return _make_error(message)

	if typeof(parsed) != TYPE_DICTIONARY:
		var parse_error := "The API returned an unreadable payload."
		generation_failed.emit(parse_error)
		return _make_error(parse_error)

	var response_dict: Dictionary = parsed
	var data: Array = response_dict.get("data", [])
	if data.is_empty():
		var empty_error := "The API returned no image data."
		generation_failed.emit(empty_error)
		return _make_error(empty_error)

	var image_entry: Dictionary = data[0]
	var image_base64: String = String(image_entry.get("b64_json", ""))
	if image_base64 == "":
		var missing_data_error := "The API response had no b64 image payload."
		generation_failed.emit(missing_data_error)
		return _make_error(missing_data_error)

	var image_bytes: PackedByteArray = Marshalls.base64_to_raw(image_base64)
	if image_bytes.is_empty():
		var decode_error := "Image base64 decode returned no bytes."
		generation_failed.emit(decode_error)
		return _make_error(decode_error)

	var image := Image.new()
	var load_err: int = image.load_png_from_buffer(image_bytes)
	if load_err != OK:
		var image_error := "PNG decode failed: %s" % error_string(load_err)
		generation_failed.emit(image_error)
		return _make_error(image_error)

	var ensure_dir_err: int = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if ensure_dir_err != OK and ensure_dir_err != ERR_ALREADY_EXISTS:
		var dir_error := "Could not create output directory: %s" % error_string(ensure_dir_err)
		generation_failed.emit(dir_error)
		return _make_error(dir_error)

	var save_path: String = _build_output_path()
	var save_err: int = image.save_png(save_path)
	if save_err != OK:
		var save_error := "Image save failed: %s" % error_string(save_err)
		generation_failed.emit(save_error)
		return _make_error(save_error)

	var absolute_path: String = ProjectSettings.globalize_path(save_path)
	generation_succeeded.emit(prompt, save_path, absolute_path)
	return {
		"ok": true,
		"save_path": save_path,
		"absolute_path": absolute_path,
		"texture": ImageTexture.create_from_image(image),
		"revised_prompt": String(image_entry.get("revised_prompt", "")),
		"status_code": response_code,
	}

func _load_env_api_key() -> String:
	for env_name in ["OPENAI_IMAGE_API_KEY", "OPENAI_API_KEY"]:
		var env_value: String = OS.get_environment(env_name).strip_edges()
		if env_value != "":
			return env_value
	return ""

func _ensure_http_request() -> void:
	if _http_request != null:
		return
	_http_request = HTTPRequest.new()
	_http_request.timeout = 180.0
	add_child(_http_request)

func _sanitize_size(size: String) -> String:
	return size if SUPPORTED_SIZES.has(size) else DEFAULT_SIZE

func _sanitize_quality(quality: String) -> String:
	return quality if SUPPORTED_QUALITIES.has(quality) else DEFAULT_QUALITY

func _extract_api_error(parsed: Variant) -> String:
	if typeof(parsed) != TYPE_DICTIONARY:
		return "Unknown error"
	var response_dict: Dictionary = parsed
	var error_data: Variant = response_dict.get("error", {})
	if typeof(error_data) != TYPE_DICTIONARY:
		return "Unknown error"
	var error_dict: Dictionary = error_data
	var message: String = String(error_dict.get("message", "")).strip_edges()
	return message if message != "" else "Unknown error"

func _build_output_path() -> String:
	var timestamp: int = int(Time.get_unix_time_from_system())
	var suffix: int = Time.get_ticks_msec() % 100000
	var file_name := "openai_%d_%d.png" % [timestamp, suffix]
	return "%s/%s" % [OUTPUT_DIR, file_name]

func _make_error(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message,
	}
