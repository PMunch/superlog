import "../superlog"
import loggertypes
import strutils

proc someProc*(task: string) =
  echo task
  log "Task \"" & task & "\" failed succesfully"
  logUnseen "This message is never seen anywhere, not even in the binary"
  try:
    var x = parseInt("not an int")
  except ValueError as e:
    log e
  echo "Done"
