program LogoPark;

uses
  Vcl.Forms,
  Winapi.Windows,
  LogoParkMainForm in 'LogoParkMainForm.pas' {FrmLOGOMain};

var xHand: THandle; k: Integer;

{$R *.res}

begin
  xHand:=CreateMutex(nil,false,'Global\{9A4089F7-D248-4EB0-7F38-C598CF0037C0}');
k := GetLastError();
if (k=ERROR_ALREADY_EXISTS)or(k=ERROR_ACCESS_DENIED) then
  begin
    //MsgToLog ('Попытка запуска второго экземпляра.');
    Application.Terminate;
    Exit;
  end;


  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmLOGOMain, FrmLOGOMain);
  Application.Run;
end.
