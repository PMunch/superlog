import superlog
import times

var currentSeverity = warning

import someModule/loggertypes

# This procedure can take several arguments in any order, the superlogger will
# automatically add the supported types in the call. This way we can get
# information from the application being logged that it might not even
# explicitly expose to us (Hint: Locals[T] is supported and will return a tuple
# of all the locals in the logging scope, use with care).

proc myLogger*(sev: Severity, instInfo: InstantiationInfo, message: LogInfo or ExceptionInfo) =
  if sev > currentSeverity:
    var instStr = instInfo.filename & ":" & $instInfo.line & ":" & $instinfo.column
    when message is LogInfo:
      echo now().format("yyyy-MM-dd HH:mm:sszzz"), ": ", message.msg, " [", instStr, "]"
    else:
      echo now().format("yyyy-MM-dd HH:mm:sszzz"), ": Exception ", message.ex.msg, " [", instStr, "]"

# We also don't have to define paths, can simply pass the types in directly
registerLogger(LogInfo, myLogger)
registerLogger(ExceptionInfo, myLogger)

# All of the above could of course be wrapped into some kind of block statement
# if that was defined in superlogger. Currently I've just added severity as
# a special field as it is very commonly used, but more information like module
# name and instantiation information could be added as well (as long as care is
# taken to not leak it into the code when it isn't used):
# registerLogger(LogInfo, ExceptionInfo):
#   if sev > currentSeverity:
#     when message is LogInfo:
#       echo now().format("yyyy-MM-dd HH:mm:sszzz"), ": ", message.msg
#     else:
#       echo now().format("yyyy-MM-dd HH:mm:sszzz"), ": Exception ", message.ex.msg

import someModule/someModule

someProc("greet")
currentSeverity = debug
someProc("greet")
