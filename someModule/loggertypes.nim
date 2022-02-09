type
  LogInfo* = object
    msg*: string
  ExceptionInfo* = object
    ex*: ValueError
  UnloggedInfo* = object
    unseenMsg*: string

import "../superlog"
template log*(x: string) = log(info, LogInfo(msg: x))
template logUnseen*(x: string) = log(info, UnloggedInfo(unseenMsg: x))
template log*(x: ref ValueError) = log(error, ExceptionInfo(ex: x[]))
