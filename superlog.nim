import tables, macros

var activeLoggers {.compileTime.}: Table[string, NimNode]

type
  Severity* = enum
    debug,
    info,
    notice,
    warning,
    error,
    critical,
    alert,
    emergency
  ModuleName* = string
  InstantiationInfo* = typeof(instantiationInfo())
  Locals*[T] = T

let
  # Ability to add extra information from the loggers scope to the message
  extraTypes {.compileTime.} = {
    "Severity": newIdentNode("severity"),
    "InstantiationInfo": nnkCall.newTree(newIdentNode("instantiationInfo")),
    "Locals": nnkCall.newTree(newIdentNode("locals"))
  }.toTable

macro log*(sev: Severity, x: typed): untyped =
  var typeName = if x.getTypeInst.kind in {nnkRefTy}:
    x.getTypeInst[0]
  else:
    x.getTypeInst
  var
    moduleName = typeName.owner.strVal
    typePath = moduleName & "." & typeName.strVal
  echo "Trying to fetch logger for ", typePath
  if activeLoggers.hasKey(typePath):
    var
      log = activeLoggers[typePath]
      infoIdent = newIdentNode("message")
      severityIdent = extraTypes["Severity"]
    result = quote do:
      block:
        let
          `severityIdent` = `sev`
          `infoIdent` = `x`
        `log`
  else:
    result = newStmtList()
  echo result.repr

macro registerLogger*(x: typedesc, y: proc): untyped =
  var typePath = x.owner.strVal & "." & x.strVal
  echo "Registering logger for ", typePath
  var call = nnkCall.newTree(y)
  let procType = y.getTypeImpl
  assert procType.kind == nnkProcTy, "Logger must be a proc"
  assert procType[0][0].kind == nnkEmpty, "Logger can't return anything"
  for field in procType[0][1..^1]:
    case field[1].kind:
    of nnkSym:
      call.add if extraTypes.hasKey(field[1].strVal):
        extraTypes[field[1].strVal]
      else:
        newIdentNode("message")
    of nnkBracketExpr:
      if extraTypes.hasKey(field[1][0].strVal):
        call.add extraTypes[field[1][0].strVal]
    else: discard

  activeLoggers[typePath] = call

