extends Node

@export var _logs = {}
@export var warning_count := 0
@export var error_count := 0

const self_print_level := Logger.LogLevel.VERBOSE
const self_archive_level := Logger.LogLevel.VERBOSE

# References to the global and local logger instances.
var _global_logger: Logger
var _print_logger: Logger

enum {
	SILENT = 0,
	ERROR = 1,
	WARNING = 2,
	INFO = 3,
	DEBUG = 4,
	VERBOSE = 5
}


func _init():
	_print_logger = Logger.new().second_init("Print", self_print_level, self_archive_level, Logger.LogType.SINGLETON)
	add_child(_print_logger)
	_global_logger = create_logger("Global", VERBOSE, VERBOSE)


## Method to register a logger.
## Adds a new logger to the logging system.
func register_logger(logger: Logger):
	if logger.id in _logs:
		if _logs[logger.id] != logger:
			_print_logger.error("A logger with the identifier '%s' is already registered." % logger.id)
		# Else, we already added this logger in the create_logger call.
		return
	_logs[logger.id] = logger
	_print_logger.info("Registered %s logger of type %s." % [logger.id, Logger.LogType.find_key(logger.log_type).to_camel_case()])
	if $"/root/Console":
		logger.console = $"/root/Console"


## Method to unregister a logger.
## Removes a logger from the logging system.
func unregister_logger(logger: Logger):
	if logger.id in _logs:
		_logs.erase(logger.id)
		_print_logger.info("Un-Registered %s logger of type %s." % [logger.id, Logger.LogType.find_key(logger.log_type).to_camel_case()])
	else:
		_print_logger.error("A logger with the identifier '%s' is not registered." % logger.id)


## Creates and returns the logger instance for the selected module.
## Will always overwrite the logger's print_level and archive_level with the
## provided values. If you need to reference the logger before it is created
## (such as during _ready calls in scene creation), you can safely call
## get_logger(id, true) to generate the logger object. The object will default to VERBOSE,
## but will have its levels updated when create_logger is finally called.
func create_logger(identifier, print_level, archive_level) -> Logger:
	var id = _get_id(identifier)
	if id in _logs:
		_print_logger.debug("get_or_create_logger found existing logger %s." % id)
		var logger: Logger = _logs[id]
		logger.print_level = print_level
		logger.archive_level = archive_level
		return logger
	else:
		_print_logger.debug("get_or_create_logger creating new logger %s." % id)
		var logger = Logger.new().second_init(id, Logger.LogLevel.values()[print_level], \
				Logger.LogLevel.values()[archive_level], _get_type(identifier))
		add_child(logger)
		_logs[id] = logger
		return logger


## Returns the logger instance for the selected module.
## Will throw an error and return null if no logger can be found matching identifier.
## Use get_or_create = true to bypass the error. This is useful for referencing a
## logger that you instance elsewhere in the scene. See get_or_create_logger for
## additional details about logger creation.
func get_logger(identifier, get_or_create := false) -> Logger:
	var id = _get_id(identifier)
	if id in _logs:
		_print_logger.verbose("get_logger found existing logger %s." % id)
		return _logs[id]
	elif get_or_create:
		return create_logger(identifier, VERBOSE, VERBOSE)
	else:
		_print_logger.throw_assert("No logger exists with name %s." % id)
		return null


## Prints to the selected logger instance at the specified level.
## If no level is indicated, prints at DEBUG level.
func from(identifier, message: String, level = Logger.LogLevel.DEBUG):
	var logger_id = _get_id(identifier)
	if _logs.has(logger_id):
		_logs[logger_id].print_at_level(message, level)
	else:
		_print_logger.throw_assert("No log with this identifier: %s" % logger_id)


## Pass-through to the Global print singleton.
## Logs and error and throws an assert with the given message.
## Asserts guarantee that execution pauses if the following code would crash.
func throw_assert(message: String):
	_global_logger.throw_assert(message)


## Pass-through to the Global print singleton.
## Prints an error to screen and pushes to console.
## By default, this will dump the entire message history to the console.
## If you just want to print the current error, set dump_error to false.
func error(message: String, dump_error := true):
	_global_logger.error(message, dump_error)


## Pass-through to the Global print singleton.
## Prints a warning to screen and pushes to console.
func warning(message):
	_global_logger.warning(message)


## Pass-through to the Global print singleton.
## Prints an info message to screen and console.
func info(message):
	_global_logger.info(message)


## Pass-through to the Global print singleton.
## Prints a debug message to screen and console.
func debug(message):
	_global_logger.debug(message)


## Pass-through to the Global print singleton.
## Prints a verbose message to screen and console.
## Uses print_verbose, so it will only display if (OS.is_stdout_verbose() returns true)
func verbose(message):
	_global_logger.verbose(message)


## Turns off all loggers.
## Loggers will still increment the warning_count and error_count in the Print singleton.
func silence_all():
	for id in _logs.keys():
		_logs[id].print_level = Logger.LogLevel.SILENT
		_logs[id].archive_level = Logger.LogLevel.SILENT


## Sets all loggers to only print errors.
func silence_non_error_printing():
	for id in _logs.keys():
		_logs[id].print_level = Logger.LogLevel.ERROR


## Resets warning and error counts to zero.
func start_all():
	for id in _logs.keys():
		_logs[id].start()
	_print_logger.info("All loggers reset.")


## Resets the warning count to zero. Useful for unit testing.
func clear_warnings():
	warning_count = 0


## Resets the error count to zero. Useful for unit testing.
func clear_errors():
	error_count = 0


## Helper function to get a human-readable string reference to the identifier.
## Determines the identifier type and returns it as a string.
## Valid identifier types include:
##    String
##        used as-is
##    Object or Resource
##        Converted to the resource path in the tree.
##    Other/Unknown
##        Any object can be used as a key, but it will convert with str() and may
##        not be easily human-readable as a result.
func _get_id(identifier) -> String:
	var id = ""
	match _get_type(identifier):
		Logger.LogType.SINGLETON:
			id = identifier
		Logger.LogType.OBJECT:
			id = str(identifier.get_path())
		Logger.LogType.UNKNOWN:
			id = str(identifier)
	return id


## Helper function to get the type of a logger.
## Determines the type of the logger based on the identifier.
func _get_type(identifier) -> Logger.LogType:
	var type = Logger.LogType.UNKNOWN
	if identifier is String:
		type = Logger.LogType.SINGLETON
	elif is_instance_valid(identifier):
		type = Logger.LogType.OBJECT
	return type
