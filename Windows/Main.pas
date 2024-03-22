unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Winsock, StdCtrls, ComObj, pcap, ComCtrls, ExtCtrls, Common, syncobjs,
  Registry, Exec;

const
  AF_HYPERV = 34;
  HV_PROTOCOL_RAW = 1;

  // Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\GuestCommunicationServices
  SvcGuid: TGUID = '{00000082-facb-11e6-bd58-64006a7986d3}';

  HV_GUID_ZERO: TGUID = '{00000000-0000-0000-0000-000000000000}';

type
  sockaddr_hv = record
    family: Word;
    reserved: Word;
    vmId: TGUID;
    serviceId: TGUID;
  end;

type
  TfrmMain = class(TForm)
    Timer1: TTimer;
    Panel1: TPanel;
    mmoLog: TRichEdit;
    Splitter1: TSplitter;
    Panel3: TPanel;
    lv: TListView;
    btnNetRefresh: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Panel4: TPanel;
    Label3: TLabel;
    lvVM: TListView;
    btnVMRefresh: TButton;
    procedure btnNetRefreshClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnVMRefreshClick(Sender: TObject);
    procedure lvVMDblClick(Sender: TObject);
  private
    ipkt: Integer;
    cs: THandle;
    procedure logMessage(var msg: TMessage); message 9999;
  public
  end;

  TPcapWorker = class
    pcap: Tpcap;
    szDevice: string;
    s: THandle;
    bMac: Boolean;
    mac: Int64;
    mac4: PDWord;
    mac2: PWord;
    pcap_errbuf: array[0..PCAP_ERRBUF_SIZE - 1] of Char;
    function execute(): Integer; stdcall;
    constructor Create(szDevice: string; s: THandle);
    destructor Destroy(); override;
  end;

  TVMClient = class
    s: THandle;
    procedure read(var b; len: Integer);
    function readLine(): string;
    procedure write(var b; len: Integer);
    procedure writeString(sz: string);
    procedure writeLine(sz: string);
    function execute(): Integer; stdcall;
    constructor Create(s: THandle);
    destructor Destroy(); override;
  end;

  TVMNetService = class
    s: THandle;
    szId: string;
    procedure Log(sz: string);
    function execute(): Integer; stdcall;
    constructor Create(szId: string);
    procedure Stop();
  end;

  TAdapter = class
    szName: string;
    szDesc: string;
    szPath: string;
    constructor Create(szName: string; szDesc: string; szPath: string);
  end;

var
  frmMain: TfrmMain;
  adapters: TThreadList;

const
  bcast: Int64 = $0000ffffffffffff;

implementation

{$R *.DFM}

constructor TAdapter.Create(szName: string; szDesc: string; szPath: string);
begin
  inherited Create();
  Self.szName := szName;
  Self.szDesc := szDesc;
  Self.szPath := szPath;
end;

procedure TfrmMain.logMessage(var msg: TMessage);
begin
  mmoLog.Lines.Add(PString(msg.LParam)^);
end;

procedure TVMNetService.Log(sz: string);
begin
  Common.Log('VMNetService [' + szId + ']: ' + sz);
end;

function TVMNetService.execute(): Integer;
var
  caddr: sockaddr_hv;
  len: Integer;
  cs: THandle;
begin
  try
    Log('started');
    while True do
    begin
      len := SizeOf(caddr);
      cs := accept(s, @caddr, @len);
      WinsockCheck('accept', cs);
      Log('client connected');
      TVMClient.Create(cs);
    end;
  except
    on E: Exception do
    begin
      Log(E.Message);
    end;
  end;
  if s <> 0 then closesocket(s);
end;

procedure TfrmMain.btnNetRefreshClick(Sender: TObject);
var
  devs: Ppcap_if;
  dev: Ppcap_if;
  li: TListItem;
  reg: TRegistry;
  sl: TStringList;
  i: Integer;
  szPath: string;
  szName: string;
  slNames: TStringList;
  psz: PString;
  lst: TList;
  pcap_errbuf: array[0..PCAP_ERRBUF_SIZE - 1] of Char;
begin
  reg := TRegistry.Create(KEY_READ or KEY_QUERY_VALUE	or KEY_ENUMERATE_SUB_KEYS);
  reg.RootKey := HKEY_LOCAL_MACHINE;
  szPath := '\SYSTEM\CurrentControlSet\Control\Network\{4D36E972-E325-11CE-BFC1-08002BE10318}';
  if not reg.OpenKey(szPath, False) then raise Exception.Create('Open failed');
  sl := TStringList.Create;
  reg.GetKeyNames(sl);
  slNames := TStringList.Create;
  for i := 0 to sl.Count - 1 do
  begin
    if not reg.OpenKey(szPath + '\' + sl[i] + '\Connection', False) then Continue;
    szName := reg.ReadString('Name');
    New(psz);
    psz^ := szName;
    slNames.AddObject('\Device\NPF_' + sl[i], Pointer(psz));
  end;
  sl.Free;
  reg.Free;

  if pcap_init(PCAP_CHAR_ENC_LOCAL, @pcap_errbuf[0]) <> 0 then
    raise Exception.Create(pcap_errbuf);
  if pcap_findalldevs(devs, @pcap_errbuf[0]) <> 0 then
    raise Exception.Create(pcap_errbuf);
  dev := devs;
  lv.Items.Clear;
  lst := adapters.LockList;
  try
    for i := 0 to lst.Count - 1 do
    begin
      TAdapter(lst[i]).Free;
    end;
    lst.Clear;
  finally
    adapters.UnlockList;
  end;
  while dev <> nil do
  begin
    li := lv.Items.Add();
    szName := dev.description;
    i := slNames.IndexOf(dev.name);
    if i >= 0 then
    begin
      szName := PString(slNames.Objects[i])^;
    end;
    li.Caption := szName;
    li.SubItems.Add(dev.description);
    li.SubItems.Add(dev.name);
    adapters.Add(TAdapter.Create(szName, dev.description, dev.name));
    dev := dev.next;
  end;
  pcap_freealldevs(devs);
end;

destructor TPcapWorker.Destroy;
begin
  if s <> 0 then closesocket(s);
  if pcap <> nil then
    pcap_close(pcap);
  inherited Destroy();
end;

constructor TPCapWorker.Create(szDevice: string; s: THandle);
var
  r: Integer;
begin
  inherited Create;
  Self.szDevice := szDevice;
  Self.s := s;
  Self.szDevice := szDevice;
  pcap := pcap_create(PChar(szDevice), @pcap_errbuf[0]);
  if pcap = nil then raise Exception.Create(pcap_errbuf);
  pcap_set_promisc(pcap, 1);
  pcap_set_timeout(pcap, 10);
  pcap_set_immediate_mode(pcap, 1);
  r := pcap_activate(pcap);
  if r <> 0 then raise Exception.Create('activate failed');

  CreateThread(execute);
end;

function TPCapWorker.execute(): Integer;
var
  r: Integer;
  pkt_header: PPcap_pkthdr;
  pkt_data: PChar;
  pkt: PByteArray;
begin
  try
    while True do
    begin
      r := pcap_next_ex(pcap, pkt_header, pkt_data);
      if r = 0 then Continue;
      if r <> 1 then Break;
      pkt := Pointer(pkt_data);
      if pkt = nil then
      begin
        if pkt_header = nil then
          raise Exception.Create('no pkt_header');
        Continue;
      end;
      if pkt_header.len <> pkt_header.caplen then
        raise Exception.Create('failed to read entire packet');
      if bMac then
      begin
        if (PDWord(@pkt[6])^ = mac4^) and (PWord(@pkt[10])^ = mac2^) then
          // Do not loop back injected packets
          Continue;
        if (PDWord(@pkt[0])^ = $FFFFFFFF) and (PWord(@pkt[4])^ = $FFFF) then
        begin
          // Send broadcasts
        end else
        if (PDWord(@pkt[0])^ <> mac4^) or (PWord(@pkt[4])^ <> mac2^) then
          // Do not send packets not for us
          Continue;
      end else
      begin
        // Only forward broadcasts
        if (PDWord(@pkt[0])^ <> $FFFFFFFF) and (PWord(@pkt[4])^ <> $FFFF) then
          Continue;
      end;
      if send(s, pkt_header.len, 4, 0) <> 4 then WinsockError('send');
      if send(s, pkt_data^, pkt_header.len, 0) <> pkt_header.len then WinsockError('send');
    end;
  except
    on E: Exception do
    begin
      Log('pcap: ' + E.Message);
    end;
  end;
  Free;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  hwndLog := Handle;
  btnNetRefresh.Click;
  btnVMRefresh.Click;
end;

procedure TfrmMain.btnVMRefreshClick(Sender: TObject);
var
  exec: TExec;
  sz: string;
  sl: TStringList;
  i: Integer;
  a: TStringArray;
  li: TListItem;
begin
  exec := TExec.Create('cmd /c %windir%\sysnative\hcsdiag list');
  sl := TStringList.Create;
  sl.Text := exec.execute();
  for i := 0 to sl.Count - 1 do
  begin
    if i mod 3 = 1 then
    begin
      a := split(sl[i], ',');
      if Length(a) = 4 then
      begin
        li := lvVM.Items.Add();
        li.Caption := Trim(a[2]);
        li.SubItems.Add(Trim(a[3]));
      end;
    end;
  end;
  sl.Free;
end;

procedure TfrmMain.lvVMDblClick(Sender: TObject);
var
  li: TListItem;
  svc: TVMNetService;
begin
  li := lvVM.Selected;
  if li = nil then Exit;
  if li.Data = nil then
  begin
    svc := TVMNetService.Create(li.Caption);
    li.Data := svc;
  end else
  begin
    svc := li.Data;
    svc.Stop();
    li.Data := nil;
  end;
end;

constructor TVMNetService.Create(szId: string);
var
  addr: sockaddr_hv;
begin
  Self.szId := szId;
  s := socket(AF_HYPERV, SOCK_STREAM, HV_PROTOCOL_RAW);
  if s = INVALID_SOCKET then WinsockError('socket');
  FillChar(addr, SizeOf(addr), 0);
  addr.family := AF_HYPERV;
  addr.reserved := 0;

  addr.vmId := StringToGUID('{' + szId + '}');
  addr.serviceId := SvcGuid;
  WinsockCheck('bind', bind(s, PSockAddrIn(@addr)^, SizeOf(addr)));
  WinsockCheck('listen', listen(s, 1));
  CreateThread(execute);
end;

destructor TVMClient.Destroy();
begin
  closesocket(s);
  inherited Destroy();
end;

constructor TVMClient.Create(s: THandle);
begin
  inherited Create();
  Self.s := s;
  CreateThread(execute);
end;

procedure TVMClient.read(var b; len: Integer);
var
  p: PByte;
  r: Integer;
begin
  p := @b;
  while len > 0 do
  begin
    r := recv(s, p^, len, 0);
    if r = 0 then raise Exception.Create('connection closed');
    if r < 0 then WinsockError('recv');
    Dec(len, r);
    Inc(p, len);
  end;
end;

function TVMClient.readLine(): string;
var
  c: Char;
begin
  Result := '';
  while True do
  begin
    read(c, 1);
    if c = #13 then Continue;
    if c = #10 then Break;
    Result := Result + c;
  end;
end;

procedure TVMClient.write(var b; len: Integer);
var
  p: PByte;
  r: Integer;
begin
  p := @b;
  while len > 0 do
  begin
    r := send(s, p^, len, 0);
    if r = 0 then raise Exception.Create('disconnected');
    if r < 0 then WinsockError('send');
    Dec(len, r);
    Inc(p, r);
  end;
end;

procedure TVMClient.writeString(sz: string);
begin
  write(sz[1], Length(sz));
end;

procedure TVMClient.writeLine(sz: string);
begin
  writeString(sz);
  writeString(#10);
end;

function TVMClient.execute(): Integer;
var
  buf: array of Byte;
  r: Integer;
  len: Integer;
  sz: string;
  lst: TList;
  adapter: TAdapter;
  i: Integer;
  a: TStringArray;
  pcap: TPcapWorker;
begin
  SetLength(buf, 65536);
  try
    while True do
    begin
      a := split(readLine(), ' ');
      if a[0] = 'list' then
      begin
        lst := adapters.LockList;
        try
          for i := 0 to lst.Count - 1 do
          begin
            adapter := lst[i];
            writeLine(adapter.szName + #9 + adapter.szDesc + #9 + adapter.szPath);
          end;
        finally
          adapters.UnlockList;
        end;
      end else
      if a[0] = 'connect' then
      begin
        if Length(a) < 2 then
        begin
          writeLine('missing argument');
          Break;
        end;
        if Length(a) <> 2 then
        begin
          writeLine('too many arguments');
          Break;
        end;
        adapter := nil;
        lst := adapters.LockList;
        try
          for i := 0 to lst.Count - 1 do
          begin
            adapter := lst[i];
            if adapter.szName = a[1] then Break;
            adapter := nil;
          end;
        finally
          adapters.UnlockList;
        end;
        if adapter = nil then
        begin
          writeLine('unknown adapter');
          Break;
        end;

        pcap := TPcapWorker.Create(adapter.szPath, s);

        writeLine('OK');
        while True do
        begin
          r := recv(s, len, 4, 0);
          if r <> 4 then WinsockError('recv');
          if len > 65536 then raise Exception.Create('Invalid len');
          r := recv(s, buf[0], len, 0);
          if r <> len then WinsockError('recv');
          //Writeln('Read ', len);
          if not pcap.bMac then
          begin
            Move(buf[6], pcap.mac, 6);
            pcap.mac4 := @pcap.mac;
            pcap.mac2 := Pointer(Cardinal(pcap.mac4) + 4);
            pcap.bMac := True;
            Log('MAC set to ' + Dump(pcap.mac, 6, ':'));
          end;
          if pcap_inject(pcap.pcap, buf[0], len) <> len then
            raise Exception.Create('pcap inject failed');
        end;
      end else
      begin
        writeLine('bad command');
      end;
      Break;
    end;
  except
    on E: Exception do
    begin
      Log(E.Message);
    end;
  end;
  Log('done');
  Free;
end;

procedure TVMNetService.Stop();
begin

end;

initialization
  adapters := TThreadList.Create;
end.
