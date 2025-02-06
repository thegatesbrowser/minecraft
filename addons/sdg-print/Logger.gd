class_name Logger extends Node
# An individual logger for a module or individual object.
# Can print to the standard output (print()) and to the in-game console.
# Prints can be turned on or off by setting set_print_level.
#
# If a module's prints are disabled, they will not be printed to the screen,
# but they will still be saved to a buffer. If an error is encountered (logger.error()),
# the entire buffer will be printed. You can call start() to clear the buffer.
#
# Additionally, creates a log of all prints 

enum LogLevel {
	SILENT = 0,
	ERROR = 1,
	WARNING = 2,
	INFO = 3,
	DEBUG = 4,
	VERBOSE = 5
}

enum LogType {
	SINGLETON,
	OBJECT,
	UNKNOWN
}

## Custom ID that appears in logs for this module. Must be unique, registration will
## fail if there are multiple loggers with the same name.
## If left blank, will be set based on the parent's path in the scene tree.
@export var id := ""
@export var print_level : LogLevel = LogLevel.SILENT
@export var archive_level : LogLevel = LogLevel.DEBUG
var log_type : LogType = LogType.OBJECT
var console = null
var message_history := ""


## Set up everything that we can't do in an _init call (because Godot calls _init on nodes in the scene tree.
## Returns self so you can chain Logger.new.init(...)
func second_init(id := "", print_level := LogLevel.VERBOSE, archive_level := LogLevel.VERBOSE, log_type := LogType.OBJECT) -> Logger:
	self.id = id
	self.name = str(id)
	self.print_level = print_level
	self.archive_level = archive_level
	self.log_type = log_type
	return self


## Register with the Print singleton when ready.
## If this logger is a child of an existing node, will update the ID accordingly.
func _ready():
	if id == "":
		id = str(get_parent().get_path()).replace("/root/", "")
	Print.register_logger(self)
	start()


## Clears the message history for this logger instance.
## This effectively lets you start a new task. If an error is thrown,
## the entire message history will be printed, starting from this call.
## You can optionally provide a message to print (default level is DEBUG).
func start(message := "", level = LogLevel.DEBUG):
	message_history = ""
	if message != "":
		print_at_level(message, level)


## Throws an error if the statement is false.
## Also throws an assert so program execution will halt.
func assert_that(is_true, message := ""):
	if !is_true:
		throw_assert(message)


## Logs and error and throws an assert with the given message.
## Asserts guarantee that execution pauses if the following code would crash.
func throw_assert(message: String):
		error(message)
		assert(false)


## Prints an error to screen and pushes to console.
## By default, this will dump the entire message history to the console.
## If you just want to print the current error, set dump_error to false.
func error(message: String, dump_error := true):
	# Add to the global error count. (useful for unit testing errors)
	Print.error_count += 1
	var message_formatted = "[color=red]ERROR:   " + message + "[/color]"
	# Store this message in case we need it again!
	if archive_level >= LogLevel.ERROR:
		message_history += '\n' + message_formatted
	# Print this message to the screen and console.
	if print_level >= LogLevel.ERROR:
		_print_console(message_formatted)
		push_error(message)
		if dump_error:
			_error_dump()


## Prints a warning to screen and pushes to console.
func warning(message):
	# Add to the global warning count. (useful for unit testing warnings)
	Print.warning_count += 1
	var message_formatted = "[color=orange]WARNING: " + message + "[/color]" 
	# Archive this message if necessary.
	if archive_level >= LogLevel.WARNING:
		message_history += '\n' + message_formatted
	# Print this message to the screen and console.
	if print_level >= LogLevel.WARNING:
		_print_console(message_formatted)
		push_warning(message)
		# Print the warning to Output as well as pusing to Debugger. This way, it won't get missed!
		if OS.has_feature("editor"):
			print_rich(message_formatted)


## Prints an info message to screen and console.
func info(message):
	message = "[color=cyan]INFO:    [/color]" + message
	# Archive this message if necessary.
	if archive_level >= LogLevel.INFO:
		message_history += '\n' + message
	# Print this message to the screen and console.
	if print_level >= LogLevel.INFO:
		_print_console(message)
		print_rich(message)


## Prints a debug message to screen and console.
func debug(message):
	message = "[color=green]DEBUG:   [/color]" + message
	# Archive this message if necessary.
	if archive_level >= LogLevel.DEBUG:
		message_history += '\n' + message
	# Print this message to the screen and console.
	if print_level >= LogLevel.DEBUG:
		_print_console(message)
		print_rich(message)


## Prints a verbose message to screen and console.
## Uses print_verbose, so it will only display if (OS.is_stdout_verbose() returns true)
func verbose(message):
	message = "[color=purple]VERBOSE: [/color]" + message
	# Archive this message if necessary.
	if archive_level >= LogLevel.VERBOSE:
		message_history += '\n' + message
	# Print this message to the screen and console.
	if print_level >= LogLevel.VERBOSE:
		_print_console(message)
		print_rich(message)


## Set the minimum level for prints to be sent to the screen and console.
func set_print_level(level: LogLevel):
	print_level = level


## Set the minimum level for prints to be saved to the message history.
func set_archive_level(level: LogLevel):
	archive_level = level


## Prints a message at a specific level. Equivalent to calling error, info, etc.
func print_at_level(message: String, level: LogLevel):
	match level:
		LogLevel.ERROR:
			error(message)
		LogLevel.WARNING:
			warning(message)
		LogLevel.INFO:
			info(message)
		LogLevel.DEBUG:
			debug(message)
		LogLevel.VERBOSE:
			verbose(message)
		LogLevel.SILENT:
			error("Attempted to print at ''SILENT'' logging level.")
		_:
			error("Attempted to print at an invalid logging level.")


## Unregister before deletion.
func _exit_tree():
	Print.unregister_logger(self)


## Prints the entire message history.
func _error_dump():
	print_rich("[b][color=magenta]-=-=- Error Encountered! %s Module History Starts Here -=-=-[/color][/b]" % [id] + \
			message_history + "\n[b][color=magenta]-=-=- Error Encountered! %s Module History Ends Here   -=-=-[/color][/b]" % [id])


## Print to the in-game console (if it exists)
func _print_console(message: String):
	if console:
		console.Text.append_text(message + "\n")
