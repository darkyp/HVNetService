unit Common;

interface

uses Windows, SysUtils, Winsock;

type
  TStringArray = array of string;

type
  TThreadProc = function: Integer of object; stdcall;

function CreateThread(tp: TThreadProc): THandle;
function Dump(var p; len: Integer; szSep: string = ' '): string;
procedure WinsockError(szDesc: string);
procedure WinsockCheck(szDesc: string; r: Integer);
procedure WinError(szDesc: string);
function split(sz: string; szSep: string): TStringArray;
procedure Log(sz: string);

var
  wsd: TWSAData;
  hwndLog: THandle;

implementation

procedure WinError(szDesc: string);
begin
  raise Exception.Create(szDesc + ' ' + SysErrorMessage(GetLastError));
end;

procedure WinsockError(szDesc: string);
begin
  raise Exception.Create(szDesc + ' ' + SysErrorMessage(WSAGetLastError));
end;

procedure WinsockCheck(szDesc: string; r: Integer);
begin
  if r = SOCKET_ERROR then WinsockError(szDesc);
end;

function CreateThread(tp: TThreadProc): THandle;
var
  tid: Cardinal;
begin
  Result := Windows.CreateThread(nil, 0,
    Pointer(PDWORD(Integer(@tid)+12)^),
    Pointer(PDWORD(Integer(@tid)+16)^),
    0, tid);
end;

function Dump(var p; len: Integer; szSep: string = ' '): string;
var
  p1: PByte;
begin
  p1 := @p;
  Result := '';
  while len > 0 do
  begin
    if Length(Result) > 0 then Result := Result + szSep;
    Result := Result + Format('%.2X', [p1^]);
    Inc(p1);
    Dec(len);
  end;
end;

function split(sz: string; szSep: string): TStringArray;
var
  szPart: string;
  szSearch: string;
  c: Char;
  i: Integer;
begin
  SetLength(Result, 0);
  for i := 1 to Length(sz) do
  begin
    c := sz[i];
    szSearch := szSearch + c;
    if szSearch = szSep then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result) - 1] := szPart;
      szPart := '';
    end else
    begin
      szPart := szPart + c;
      szSearch := '';
    end;
  end;
  if (szSearch = szSep) or (Length(szPart) > 0) or (Length(Result) = 0) then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := szPart;
    szPart := '';
  end;
end;

procedure Log(sz: string);
begin
  SendMessage(hwndLog, 9999, 0, Integer(@sz));
end;

initialization
  WSAStartup($0101, wsd);

end.
