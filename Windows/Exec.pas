unit Exec;

interface

uses Windows, Common, Classes, SysUtils;

type
  TExec = class
    hErrR: Cardinal;
    hInW: Cardinal;
    hOutR: Cardinal;
    szCommand: string;
    h: THandleStream;
    szError: string;
    szResult: string;
    function StdErrReader: Integer; stdcall;
    function StdOutReader: Integer; stdcall;
    constructor Create(szCommand: string);
    function execute(): string;
  end;

implementation

function TExec.StdErrReader: Integer;
var
  sz: string;
  br: Cardinal;
begin
  SetLength(sz, 128);
  try
    while True do
    begin
      if not ReadFile(hErrR, sz[1], 128, br, nil) then
        WinError('ReadFile');
      szError := szError + Copy(sz, 1, br);
    end;
  except
    on E: Exception do
    begin
      Writeln('StdErrReader: ' + E.Message);
    end;
  end;
  CloseHandle(hErrR);
end;

function TExec.StdOutReader: Integer; stdcall;
var
  sz: string;
  br: Cardinal;
begin
  SetLength(sz, 128);
  try
    while True do
    begin
      if not ReadFile(hOutR, sz[1], 128, br, nil) then
        WinError('ReadFile');
      szResult := szResult + (Copy(sz, 1, br));
    end;
  except
    on E: Exception do
    begin
      Writeln(E.Message);
    end;
  end;
end;

constructor TExec.Create(szCommand: string);
begin
  inherited Create();
  Self.szCommand := szCommand;
end;

function TExec.execute(): string;
var
  pi: _PROCESS_INFORMATION;
  si: _STARTUPINFOA;
  hErrW: Cardinal;
  hInR: Cardinal;
  hOutW: Cardinal;
  sa: _SECURITY_ATTRIBUTES;
  tid: Cardinal;
  tp: TThreadProc;
begin
  sa.nLength := SizeOf(sa);
  sa.bInheritHandle := True;
  sa.lpSecurityDescriptor := nil;
  CreatePipe(hErrR, hErrW, @sa, 0);
  SetHandleInformation(hErrR, HANDLE_FLAG_INHERIT, 0);
  CreatePipe(hInR, hInW, @sa, 1024 * 1024);
  SetHandleInformation(hInW, HANDLE_FLAG_INHERIT, 0);
  h := THandleStream.Create(hInW);
  CreatePipe(hOutR, hOutW, @sa, 0);
  SetHandleInformation(hOutR, HANDLE_FLAG_INHERIT, 0);
  si.cb := SizeOf(si);
  si.lpReserved := nil;
  si.lpDesktop := nil;
  si.lpTitle := nil;
  si.dwFlags := 0;
  si.cbReserved2 := 0;
  si.lpReserved2 := nil;
  si.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
  si.wShowWindow := SW_HIDE;
  si.hStdError := hErrW;
  si.hStdInput := hInR;
  si.hStdOutput := hOutW;
  CreateThread(StdErrReader);
  CreateThread(StdOutReader);
  if not CreateProcess(nil,
    PChar(szCommand),
    nil, nil, True, 0, nil, nil, si, pi) then
    WinError('CreateProcess');
  WaitForSingleObject(pi.hProcess, INFINITE);
  Result := szResult;
end;

end.
