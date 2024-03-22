program HVNetworkService;

{$R 'app.res' 'app.rc'}

uses
  Forms,
  Main in 'Main.pas' {frmMain},
  pcap in 'pcap.pas',
  Common in 'Common.pas',
  Exec in 'Exec.pas';

{$R *.RES}

begin
  IsMultiThread := True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
