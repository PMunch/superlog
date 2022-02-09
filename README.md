# Superlog concept
Based on an idea I had while replying to a [forum topic](https://forum.nim-lang.org/t/8880#58038).
The general idea is that this would be a zero-cost pluggable logger. Each
module that wants to support logging simply imports the superlog module,
defines its loggable types, and then call `log` with a severity and one of its
loggable types as the arguments. Like this:

```nim
log info, LogInfo(msg: "Hello world")
```

Note that in this example `LogInfo` just contains a string, but the objects can
contain anything the library wants to log.

Then a module which imports this module can first import superlog and the
loggable types from the library. Then it can register a logging procedure for
that module like so:

```nim
var currentSeverity = debug

proc myLogger*(sev: Severity, message: LogInfo) =
  if sev > currentSeverity:
    echo now().format("yyyy-MM-dd HH:mm:sszzz"), ": ", message.msg

registerLogger(LogInfo, myLogger)
```

When this is done it imports the module proper and all the `log` statements in
the module will now be replaced with a call to the registered log procedure for
that log type. Types which doesn't have a registered procedure will simply
expand to an empty statement and that call simply doesn't create any code on
runtime.

## Enrichment
For fun I also implemented the ability to inspect the signature of the
registered procedure. This allows the logging procedure to grab other
information from the loggers scope. Maybe most useful is `instantiationInfo`:

```nim
var currentSeverity = debug

proc myLogger*(sev: Severity, instInfo: InstantiationInfo, message: LogInfo) =
  if sev > currentSeverity:
    var instStr = instInfo.filename & ":" & $instInfo.line & ":" & $instinfo.column
    echo now().format("yyyy-MM-dd HH:mm:sszzz"), ": ", message.msg, " {", instStr, "}"

registerLogger(LogInfo, myLogger)
```

Currently all the arguments are optional, you can use `Severity`,
`InstantiationInfo`, and `Locals[T]` (which returns the tuple from [locals()](https://nim-lang.org/docs/system.html#locals).
Any unknown argument is replaced with the message, which of course can be a
type class so you can use the same logger proc for different types:

```nim
var currentSeverity = debug

proc myLogger*(sev: Severity, instInfo: InstantiationInfo, message: LogInfo or ExceptionInfo) =
  if sev > currentSeverity:
    stdout.write now().format("yyyy-MM-dd HH:mm:sszzz") & ": "
    when message is LogInfo:
      stdout.write message.msg
    else:
      stdout.write "Exception ", message.ex.msg
    stdout.writeLine " [" & instInfo.filename & ":" & $instInfo.line & ":" & $instinfo.column & "]"

registerLogger(LogInfo, myLogger)
registerLogger(ExceptionInfo, myLogger)
```

## Benefits
The benefits of implementing a logger this way is that library owners don't
have to worry about the cost of logging, users can simply not define a logger
for a type. And users are free to do whatever they want with the logged data.
Some good applications (courtesy of Araq):

- You can use the library in a GUI setting.
- You can i18n the error messages.
- You can store the results in a database.
- You can aggregate results.
- You can filter and ignore results.

And of course close to my own heart you could also import libraries with
logging in a microcontroller or other super-restricted context and don't worry
about the overhead. You could of course even write the messages out over
serial, or just blink a coloured LED based on severity.

## Improvements
To improve this proof of concept it should move away from creating type paths
manually and instead use something like `macros.signatureHash`. All the body
generation logic should also be moved into the registration macro, this makes
it possible to write other registration macros which does other things than
adding a procedure call.

Another improvement would be to implement generics and define a
`LogMessage[module: static[string]]` type and a companying
`log(severity: Severity, message: string)` template. The template would grab
the  current module and create a message of the correct type and log with that.
The module could then get away without having a separate loggingtypes file if
it only wants to log strings. And the user would then be able to register a
callback for every `LogMessage` regardless of module, or it could register them
for a specific module. In essence this would make the simple case of just
logging strings much easier.
