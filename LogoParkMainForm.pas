unit LogoParkMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  inifiles, WinAPI.MSXML, System.Win.ComObj, WinAPI.ActiveX,
  Vcl.StdCtrls, IdBaseComponent, IdComponent, IdRawBase, IdRawClient,
  IdIcmpClient, Vcl.OleCtrls;

type
   TXMLHTTPEvent = procedure of object;
   TIXMLHTTPEvent = class(TInterfacedObject, IDispatch)
    private
      FOnTriggered: TXMLHTTPEvent;
    public
   { IDispatch }
      function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; virtual; stdcall;
      function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; virtual; stdcall;
      function GetTypeInfoCount(out Count: Integer): HResult; virtual; stdcall;
      function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
           Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; virtual; stdcall;
      { Event }
      property OnTriggered: TXMLHTTPEvent read FOnTriggered write FOnTriggered;
    end;


  TFrmLOGOMain = class(TForm)
    Timer1: TTimer;
    IdIcmpClient1: TIdIcmpClient;
    GroupBox1: TGroupBox;
    ShI1: TShape;
    ShI3: TShape;
    Label1: TLabel;
    Label2: TLabel;
    ShQ1: TShape;
    ShQ2: TShape;
    Label9: TLabel;
    Label10: TLabel;
    Edit1: TEdit;
    Button6: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ShQ1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ShQ2MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);



  private
    { Private declarations }
    function LogoXMLRequest (sRefererPage: string; sSecHint: string; sRequestBody: string):string;
    function LogoXMLLogin(): string;
    function GetLogoVariables(): string;
    function SetLogoVariables(): boolean;
    function Ping(const AHost : string; const ATimes : integer; out AvgMS:Double) : Boolean;
    function TestDraw():boolean;
    function CheckIsLogoRunning(): boolean;
    function LogoXMLLogout(): boolean;
  public
    { Public declarations }
    procedure ReadyStateChange;
  end;

   TVarRec = record
    Range: integer;
    Number: integer;
    RecievedNum:string;
    VarType: integer;
    Value: integer;
    PendingVal: integer;

  end;
  UTF8BytesArray = array of byte;
  TVarIntArray = array of TVarRec;

var
  FrmLOGOMain: TFrmLOGOMain;

  EventXHR: TIXMLHTTPEvent;
  XMLHttpRequest: IXMLHttpRequest;
  sSecurityHint: string;
  VarIntArray: TVarIntArray;
  bLogoIsRunning: boolean;
  iLogoPolingCount: integer;
  XMLHttpRequestBusy:boolean;

  {CONFIG}
  iTimer1Interval, iPrestartDelay: integer;
  bEnableTimer1 : boolean;
  bEnableHiddenMsgToLog: boolean;

  {LOGO}
  bEnableLogo: boolean;
  sLogoMainIP, sUserName, sPassword: string;
  sLogoVarList: string;
  iXMLRequestTimeOut: integer;
  iMaxPolingCountNumPerLoginSession: integer;
   bXMLRequestAsinc: boolean;




const
 FormCaption='LogoPark 1.0';
 IniFileName= 'LogoPark.ini';
 sLogoPageLogin= '/logo_login.shtm?!App-Language=1';
 sLogoPageVariable= '/logo_variable_01.shtm?!App-Language=1&Security-Hint=';
 sLogoPageSystem= '/logo_system_01.shtm?!App-Language=1&Security-Hint=';
 lvrVM=132; lvrI=129; lvrNetI=16; lvrQ=130; lvrNetQ=17; lvrM=131; lvrAI=18; lvrNetAI=21; lvrAQ=19; lvrNetAQ=22; lvrAM=20; lvrCursKey=12; lvrFuncKey=13; lvrShifKey=14;
 lvtBOOL=1; lvtBYTE=2; lvtWORD=4; lvtDWORD=6;
 RS_UNINITIALIZED = 0;
 RS_LOADING = 1;
 RS_LOADED = 2;
 RS_INTERACTIVE = 3;
 RS_COMPLETED = 4;
 IID_NULL: TGUID = '{00000000-0000-0000-0000-000000000000}';



implementation

{$R *.dfm}

///////LOGGING PROCEDURE///////////////////////////
procedure MsgToLog(s_msg:string);
var
FileIsThere:boolean;
sFN, Timestamp:string;
aFile:textfile;
begin
Timestamp:=  DateTimeToStr(Now());
OutputDebugString(Pchar(Timestamp+' >>> '+s_msg));
sFN:= ParamStr(0);
sFN:= copy(sFN,0,Length(sFN)-Length(ExtractFileExt(sFN)))+'.log';

{$I-}
AssignFile(aFile, sFN);
FileMode := 0;  {Set file access to read only }
Reset(aFile);
CloseFile(aFile);
{$I+}
FileIsThere := (IOResult = 0) and (sFN <> '');

{$I-}
assignfile(afile,sFN);
FileMode := 2;
If not FileIsThere then
rewrite(afile) else append(afile);
Writeln(afile,Timestamp+' >>> '+s_msg);
Flush(aFile);
CloseFile(afile);
{$I+}
end;





procedure GlobalInit();
var
 Ini: Tinifile;
 TS1, TS2, TS3 : TStringList;
 i1, i2, i3: Integer;
begin
 //jpening file
  Ini:=TiniFile.Create(extractfilepath(paramstr(0))+IniFileName);
  if (not Ini.SectionExists('CONFIG')) then
  begin
    MsgToLog('Ini file '+ IniFileName+ ' is not found.');
    {CONFIG}
    iTimer1Interval:=500;
    bEnableTimer1:=false;
    iPrestartDelay:=1000;
    bEnableHiddenMsgToLog:=false;
    {LOGO}
    bEnableLogo:=false;
    sLogoMainIP:= '192.168.132.10';
    sUserName:= 'Web User';
    sPassword:='';
    sLogoVarList:='I-1,2,3;Q-1,2,3;NV-1';
    iXMLRequestTimeOut:=15000;
    iMaxPolingCountNumPerLoginSession:= 0;
    bXMLRequestAsinc:=false;


    Ini.WriteInteger('CONFIG', 'iTimer1Interval', iTimer1Interval);
    Ini.WriteBool('CONFIG','bEnableTimer1',bEnableTimer1);
    Ini.WriteInteger('CONFIG', 'iPrestartDelay', iPrestartDelay);
    Ini.WriteBool('CONFIG','bEnableHiddenMsgToLog',bEnableHiddenMsgToLog);

    Ini.WriteBool('LOGO','bEnableLogo',bEnableLogo);
    Ini.WriteString('LOGO','sLogoMainIP',sLogoMainIP);
    Ini.WriteString('LOGO','sUserName',sUserName);
    Ini.WriteString('LOGO','sPassword',sPassword);
    Ini.WriteString('LOGO','sLogoVarList',sLogoVarList);
    Ini.WriteInteger('LOGO', 'iXMLRequestTimeOut', iXMLRequestTimeOut);
    Ini.WriteInteger('LOGO', 'iMaxPolingCountNumPerLoginSession', iMaxPolingCountNumPerLoginSession);
    Ini.WriteBool('LOGO','bXMLRequestAsinc',bXMLRequestAsinc);



     MsgToLog('Created default ini file '+ IniFileName);
  end;

  iTimer1Interval:=Ini.ReadInteger('CONFIG', 'iTimer1Interval', 500);
  bEnableTimer1:=Ini.ReadBool('CONFIG','bEnableTimer1',false);
  iPrestartDelay:=Ini.ReadInteger('CONFIG', 'iPrestartDelay', 1000);
  bEnableHiddenMsgToLog:=Ini.ReadBool('CONFIG','bEnableHiddenMsgToLog',false);

  bEnableLogo:=Ini.ReadBool('LOGO','bEnableLogo',false);
  sLogoMainIP:=Ini.ReadString('LOGO','sLogoMainIP','');
  sUserName:=Ini.ReadString('LOGO','sUserName','Web User');
  sPassword:=Ini.ReadString('LOGO','sPassword','');
  sLogoVarList:=Ini.ReadString('LOGO','sLogoVarList','I-1,2,3;Q-1,2,3;NV-1');
  iXMLRequestTimeOut:=Ini.ReadInteger('LOGO', 'iXMLRequestTimeOut', 15000);
  iMaxPolingCountNumPerLoginSession:=Ini.ReadInteger('LOGO', 'iMaxPolingCountNumPerLoginSession', 0);
  bXMLRequestAsinc:=Ini.ReadBool('LOGO','bXMLRequestAsinc',false);


  Ini.Free;

  sSecurityHint:='0';
  bLogoIsRunning:=false;
  iLogoPolingCount:=0;

  TS1 := TStringList.Create;
  TS1.Delimiter := ';';
  TS2 := TStringList.Create;
  TS2.Delimiter := '-';
  TS3 := TStringList.Create;
  TS3.Delimiter := ',';
  TS1.DelimitedText := sLogoVarList;
  i3:=0;
  if TS1.Count>0 then for i1 := 0 to TS1.Count-1 do
     begin
       TS2.DelimitedText := TS1.Strings[i1];
       TS3.DelimitedText := TS2.Strings[1];
       if TS3.Count>0 then for i2 := 0 to TS3.Count-1 do
         begin
           setlength(VarIntArray, i3+1);
           VarIntArray[i3].Number:=strtoint(TS3.Strings[i2]);
           if TS2.Strings[0] = 'VM' then begin VarIntArray[i3].Range:=lvrVM; VarIntArray[i3].VarType:=lvtWORD; end
           else if TS2.Strings[0] = 'I' then begin VarIntArray[i3].Range:=lvrI; VarIntArray[i3].VarType:=lvtBOOL; end
           else if TS2.Strings[0] = 'NetI' then begin VarIntArray[i3].Range:=lvrNetI; VarIntArray[i3].VarType:=lvtBOOL; end
           else if TS2.Strings[0] = 'Q' then begin VarIntArray[i3].Range:=lvrQ; VarIntArray[i3].VarType:=lvtBOOL; end
           else if TS2.Strings[0] = 'NetQ' then begin VarIntArray[i3].Range:=lvrNetQ; VarIntArray[i3].VarType:=lvtBOOL; end
           else if TS2.Strings[0] = 'M' then begin VarIntArray[i3].Range:=lvrM; VarIntArray[i3].VarType:=lvtBOOL; end
           else if TS2.Strings[0] = 'AI' then begin VarIntArray[i3].Range:=lvrAI; VarIntArray[i3].VarType:=lvtWORD; end
           else if TS2.Strings[0] = 'NetAI' then begin VarIntArray[i3].Range:=lvrNetAI; VarIntArray[i3].VarType:=lvtWORD; end
           else if TS2.Strings[0] = 'AQ' then begin VarIntArray[i3].Range:=lvrAQ; VarIntArray[i3].VarType:=lvtWORD; end
           else if TS2.Strings[0] = 'NetAQ' then begin VarIntArray[i3].Range:=lvrNetAQ; VarIntArray[i3].VarType:=lvtWORD; end
           else if TS2.Strings[0] = 'AM' then begin VarIntArray[i3].Range:=lvrAM; VarIntArray[i3].VarType:=lvtWORD; end
           else if TS2.Strings[0] = 'CursKey' then begin VarIntArray[i3].Range:=lvrCursKey; VarIntArray[i3].VarType:=lvtBOOL; end
           else if TS2.Strings[0] = 'FuncKey' then begin VarIntArray[i3].Range:=lvrFuncKey; VarIntArray[i3].VarType:=lvtBOOL; end
           else if TS2.Strings[0] = 'ShifKey' then begin VarIntArray[i3].Range:=lvrShifKey; VarIntArray[i3].VarType:=lvtBOOL; end
           else begin VarIntArray[i3].Range:=0; VarIntArray[i3].VarType:=0 end;
           inc(i3);
         end;

     end;

  FreeAndNil(TS1);
end;

procedure TFrmLOGOMain.ReadyStateChange;
begin
  case XMLHttpRequest.readyState of
   RS_UNINITIALIZED: begin if bEnableHiddenMsgToLog then MsgToLog('Uninitialized'); end;
   RS_LOADING: begin if bEnableHiddenMsgToLog then MsgToLog('Loading'); end;
   RS_LOADED: begin if bEnableHiddenMsgToLog then MsgToLog('Loaded'); end;
   RS_INTERACTIVE: begin if bEnableHiddenMsgToLog then MsgToLog('Interactive'); end;
   RS_COMPLETED: begin if bEnableHiddenMsgToLog then MsgToLog('Completed');XMLHttpRequestBusy:=false; end;
  end;
end;

 { TIXMLHTTPEvent }

function TIXMLHTTPEvent.GetIDsOfNames(const IID: TGUID; Names: Pointer;
NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
Result := E_NOTIMPL;
end;

function TIXMLHTTPEvent.GetTypeInfo(Index, LocaleID: Integer;
out TypeInfo): HResult;
begin
Result := E_NOTIMPL;
end;

function TIXMLHTTPEvent.GetTypeInfoCount(out Count: Integer): HResult;
begin
Result := E_NOTIMPL;
Count := 0;
end;

function TIXMLHTTPEvent.Invoke(DispID: Integer; const IID: TGUID;
LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo,
ArgErr: Pointer): HResult;
begin
if not IsEqualIID(iid, IID_NULL) then
begin
Result := DISP_E_UNKNOWNINTERFACE;
Exit;
end;
try
if Assigned(FOnTriggered) then
FOnTriggered;
Result := 0;
except
on E: Exception do
begin
Result := DISP_E_EXCEPTION;
end;
end;
end;

function TFrmLOGOMain.Ping(const AHost : string; const ATimes : integer; out AvgMS:Double) : Boolean;
 var
  R : array of Cardinal;
  i : integer;
begin
  Result := True;
  AvgMS := 0;
  if ATimes>0 then
    with TIdIcmpClient.Create(Self) do
    try
        Host := AHost;
        ReceiveTimeout:=999; //TimeOut of ping
        SetLength(R,ATimes);
        {Pinguer le client}
        for i:=0 to Pred(ATimes) do
        begin
            try
              Ping();
              Application.ProcessMessages;
              R[i] := ReplyStatus.MsRoundTripTime;
            except
              Result := False;
              Exit;

            end;
          if ReplyStatus.ReplyStatusType<>rsEcho Then result := False;
        end;

        for i:=Low(R) to High(R) do
        begin
          Application.ProcessMessages;
          AvgMS := AvgMS + R[i];
        end;
        AvgMS := AvgMS / i;
    finally
        Free;
    end;
end;

function MakeCRC32(oUINT8Array: array of byte): Longint;
const
g_u32CRC32Table : array [0..255] of DWORD = (
$00000000, $77073096, $EE0E612C, $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3, $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
$1DB71064, $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7, $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
$3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B, $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
$26D930AC, $51DE003A, $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F, $2802B89E, $5F058808, $C60CD9B2, $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
$76DC4190, $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433, $7807C9A2, $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
$6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457, $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
$4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB, $4369E96A, $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
$5005713C, $270241AA, $BE0B1010, $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F, $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
$EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683, $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
$F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB, $196C3671, $6E6B06E7, $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
$D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B, $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
$CB61B38C, $BC66831A, $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F, $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
$9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713, $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
$86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1, $18B74777, $88085AE6, $FF0F6A70, $66063BCA, $11010B5C, $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
$A00AE278, $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB, $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
$BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF, $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);
var
  u32CRC: DWORD;
  u8TableUnitLocation: byte;
  iIndex: integer;

begin
u32CRC:= 4294967295;
for  iIndex:=low(oUINT8Array) to  high(oUINT8Array) do
   begin
   u8TableUnitLocation := (u32CRC AND $FF) XOR oUINT8Array[iIndex];
		u32CRC := (u32CRC shr 8) XOR g_u32CRC32Table[u8TableUnitLocation];
   end;
  result:= not u32CRC;
end; {MakeCRC32}

function String2UTF8(sSrc: UTF8string): UTF8BytesArray;
var
  i : integer;
begin
     for i:=low(sSrc) to high(sSrc) do
     begin
       setlength (result,i);
       result[i-1]:=ord(sSrc[i]);
     end;
end;



function TFrmLOGOMain.LogoXMLRequest (sRefererPage: string; sSecHint: string; sRequestBody: string):string;
 var

  iStart, iStop: DWORD;
  bExpiredFlag: boolean;
begin

  if bEnableHiddenMsgToLog then MsgToLog('RequestXML: '+sRequestBody);
  if bEnableHiddenMsgToLog then MsgToLog('RefererPage: '+sRefererPage);
  if bEnableHiddenMsgToLog then MsgToLog('SecurityHint: '+sSecHint);
  if bEnableHiddenMsgToLog then MsgToLog('XMLHttpRequest.readyState: '+inttostr(XMLHttpRequest.readyState));

   iStart := GetTickCount;
  bExpiredFlag:=false;
  repeat
    iStop := GetTickCount;
    if ((iStop - iStart) >= DWORD(iXMLRequestTimeOut)) then bExpiredFlag:= true;
    Application.ProcessMessages;
           FrmLOGOMain.Repaint;
  until ((not XMLHttpRequestBusy) or (bExpiredFlag));
  if bExpiredFlag then
  begin
    XMLHttpRequest.abort;
    msgtolog('XMLHttpRequest is busy since last invoke of open-send procedure');
    result:='';
    exit;
  end;


  XMLHttpRequestBusy:=true;


  try
  XMLHttpRequest.open('POST', 'http://'+sLogoMainIP+'/AJAX', bXMLRequestAsinc, sUserName, sPassword);  //http://192.168.132.10/AJAX   EmptyParam, EmptyParam

  except
      MsgToLog('Error while invoke XMLHttpRequest.open');
      exit;
  end;

  XMLHttpRequest.setRequestHeader('content-Type','text/plain;charset=utf-8'); //text/plain;charset=windows-1251
  XMLHttpRequest.setRequestHeader('Accept','*/*');
  XMLHttpRequest.setRequestHeader('Accept-Encoding','gzip, deflate');
  XMLHttpRequest.setRequestHeader('Accept-Language','ru,en;q=0.8');
  XMLHttpRequest.setRequestHeader('App-Language','1');
  XMLHttpRequest.setRequestHeader('Connection','keep-alive');
  XMLHttpRequest.setRequestHeader('Content-Length',inttostr(length(sRequestBody)));
  XMLHttpRequest.setRequestHeader('Host',sLogoMainIP);
  XMLHttpRequest.setRequestHeader('Origin:http','http://'+sLogoMainIP);
  XMLHttpRequest.setRequestHeader('Security-Hint',sSecHint);
  if (pos('&Security-Hint=',sRefererPage)>0) then sRefererPage:=sRefererPage+sSecHint;
  XMLHttpRequest.setRequestHeader('Referer:http','//'+sLogoMainIP+sRefererPage);
  XMLHttpRequest.setRequestHeader('User-Agent','Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 YaBrowser/16.7.1.20937 Yowser/2.5 Safari/537.36');
  XMLHttpRequest.send(sRequestBody);
  iStart := GetTickCount;
  bExpiredFlag:=false;
  repeat
    iStop := GetTickCount;
    if ((iStop - iStart) >= DWORD(iXMLRequestTimeOut)) then bExpiredFlag:= true;
    Application.ProcessMessages;
           FrmLOGOMain.Repaint;
  until ((XMLHttpRequest.readyState = RS_COMPLETED) or (bExpiredFlag));
  if bExpiredFlag then
  begin
    XMLHttpRequest.abort;
    msgtolog('XMLHttpRequest timeout');
    result:='';
    exit;
  end;
  XMLHttpRequestBusy:=false;

  if XMLHttpRequest.status=200 then
      begin
       result:=XMLHttpRequest.responseText;
       if bEnableHiddenMsgToLog then MsgToLog('Request status: '+inttostr(XMLHttpRequest.status)+' Response text: ' +result);
      end
      else if XMLHttpRequest.status=403 then
      begin
         MsgToLog('Request status: 403. Deny access.');
         MsgToLog('Trying to login one more time.');
         sSecurityHint:='0';
         result:='';
      end
      else
      begin
        result:='';
      end;

end;

function TFrmLOGOMain.LogoXMLLogin(): string;
var
  dAvgMS:Double;
  bLogoPingOk: boolean;
  m_iKey1A1, m_iKey1A2, m_iKey1B1, m_iKey1B2: int64;
  iResponseCode, m_iKey2: int64;
  iPasswordToken, iServerChallengeToken: int64;
  sPasswordToken: UTF8string;
  sResponse1, sResponse2, m_iRef: string;
  TS : TStringList;
begin
          try
                XMLHttpRequest:=CreateComObject(CLASS_XMLHTTP) as IXMLHttpRequest;
                if XMLHttpRequest <> nil then
                  begin
                     MsgToLog('COM object XMLHttpRequest created seccessfully');
                     if bXMLRequestAsinc then EventXHR := TIXMLHTTPEvent.Create;
                     if bXMLRequestAsinc then EventXHR.OnTriggered := ReadyStateChange;
                     if bXMLRequestAsinc then XMLHttpRequest.onreadystatechange:=EventXHR;
                     XMLHttpRequestBusy:=false;
                end else MsgToLog('COM object XMLHttpRequest creating attempt failed.');
       except
                MsgToLog('Creating COM object XMLHttpRequest attempt failed.');
                XMLHttpRequest:= nil;
       end;
   if XMLHttpRequest = nil then exit;
   if sSecurityHint<>'0' then exit;
   MsgToLog('Trying to login LOGO by IP: '+ sLogoMainIP);
   bLogoPingOk:=Ping (sLogoMainIP, 3, dAvgMS);
   if bLogoPingOk then
       begin
          msgtolog('LOGO Ping is ok. Average time: '+floattostr(dAvgMS)+'mc.');
       end
       else
       begin
            msgtolog('LOGO Ping failed.');
            result:='0';
            exit;
       end;
  TS := TStringList.Create;
  TS.Delimiter := ',';
  result:='0';

  m_iKey1A1:= trunc(random()*4294967296) shr 0;   //3161842215
  m_iKey1A2:= trunc(random()*4294967296) shr 0;   //2789757040
  m_iKey1B1:= trunc(random()*4294967296) shr 0;  //4046921212
  m_iKey1B2:= trunc(random()*4294967296) shr 0;  //1671728075

  sResponse1:=LogoXMLRequest(sLogoPageLogin,'p',
              'UAMCHAL:3,4,'+inttostr(m_iKey1A1)+','+inttostr(m_iKey1A2)+','+inttostr(m_iKey1B1)+','+inttostr(m_iKey1B2));
  if sResponse1='' then
  begin
    MsgToLog('Request UAMCHAL failed');
    Result:='0';
    Exit;
  end;
  TS.DelimitedText := sResponse1;
  iResponseCode:=strtoint64(TS.Strings[0]);
  m_iRef:=TS.Strings[1];
  m_iKey2:=strtoint64(TS.Strings[2]);
  if iResponseCode=700 then
  begin
     sPasswordToken:= UTF8String(sPassword + '+' + inttostr(m_iKey2));
     sPasswordToken:=copy(sPasswordToken,1,32);
     iPasswordToken := (MakeCRC32(String2UTF8(sPasswordToken)) xor m_iKey2) shr 0;
     iServerChallengeToken := (m_iKey1A1 xor m_iKey1A2 xor m_iKey1B1 xor m_iKey1B2 xor m_iKey2) shr 0;
     sResponse2:=LogoXMLRequest(sLogoPageLogin,m_iRef,
              'UAMLOGIN:'+sUserName+','+inttostr(iPasswordToken)+','+inttostr(iServerChallengeToken));
     if sResponse2='' then
     begin
         MsgToLog('Request UAMLOGIN failed');
         Result:='0';
         Exit;
     end;
     TS.DelimitedText := sResponse2;
     iResponseCode:=strtoint(TS.Strings[0]);
     if iResponseCode=700 then
     begin
         result:=TS.Strings[1];
         iLogoPolingCount:=0;
     end
     else
     begin
         MsgToLog('Request UAMLOGIN returned response code: '+inttostr(iResponseCode) +' Must be 700');
         Result:='0';
         Exit;
     end;
  end
  else
  begin
     MsgToLog('Request UAMCHAL returned response code: '+inttostr(iResponseCode) +' Must be 700');
     Result:='0';
     Exit;
  end;
  FreeAndNil(TS);
   if result<>'0' then
     begin
        MsgToLog('Login LOGO access granted. SecurityHint is: '+ result);

     end
     else
     begin
       MsgToLog('LOGO login failed.');
       result:='0';
       exit;
     end;
end;

function TFrmLOGOMain.LogoXMLLogout(): boolean;
var
sResponse, sRequest: string;
begin
   result:=false;
   if XMLHttpRequest = nil then exit;
    if sSecurityHint = '0' then
    begin
      sSecurityHint:=LogoXMLLogin();
      if sSecurityHint = '0' then begin exit; XMLHttpRequest:= nil; end;
    end;
    sRequest:= 'UAMLOGOUT:'+sSecurityHint;
    sResponse:= LogoXMLRequest(sLogoPageLogin,sSecurityHint,sRequest);
    if sResponse = '700' then begin result:=true ; sSecurityHint:='0';end
    else if sResponse = '403' then msgtolog ('Access deny (error 403)while Logout')
    else msgtolog('Abnormal response to '+sRequest+' request: '+sResponse);
    XMLHttpRequest:= nil;
    EventXHR:=nil;

end;

 function TFrmLOGOMain.CheckIsLogoRunning(): boolean;
var
sResponse, sRequest: string;
begin
    result:=false;
    if sSecurityHint = '0' then
    begin
      sSecurityHint:=LogoXMLLogin();
      if sSecurityHint = '0' then exit;
    end;
    sRequest:= 'GETSTDG';
    sResponse:= LogoXMLRequest(sLogoPageSystem,sSecurityHint,sRequest);
    if sResponse = '<r><s>Running</s></r>' then  result:=true
    else if sResponse = '<r><s>Stop</s></r>' then  result:=false
    else msgtolog('Abnormal response to GETSTDG request: '+sResponse);


end;





function TFrmLOGOMain.SetLogoVariables(): boolean;
var
  sResponse, sRequest, sPValue: string;
  i: integer;
begin
     if length(VarIntArray)=0 then
     begin
       result:=false;
       exit;
     end;
  if sSecurityHint = '0' then
    begin
      sSecurityHint:=LogoXMLLogin();
      if sSecurityHint = '0' then
      begin
      result:=false;
        exit;
      end;
    end;

     sRequest:='SETVARS:';
      for i:=low(VarIntArray) to high(VarIntArray) do
       begin
          if VarIntArray[i].Value<>VarIntArray[i].PendingVal then
          begin
            if ((sRequest<>'SETVARS:') and (sRequest<>'')) then  sRequest:=  sRequest + ';';
            case  VarIntArray[i].VarType of
               lvtBOOL : sPValue:=format('%.2d', [VarIntArray[i].PendingVal]);
               lvtBYTE : sPValue:=format('%.2d', [VarIntArray[i].PendingVal]);
               lvtWORD : sPValue:=format('%.4d', [VarIntArray[i].PendingVal]);
               lvtDWORD : sPValue:=format('%.8d', [VarIntArray[i].PendingVal]);
               else sPValue:=format('%.2d', [VarIntArray[i].PendingVal]);
            end;
            sRequest:=sRequest+'v'+inttostr(i)+','+ inttostr(VarIntArray[i].Range)+',0,'+inttostr(VarIntArray[i].Number)+','+inttostr(VarIntArray[i].VarType)+',1,'+sPValue;
          end;
       end;

     if length(sRequest)<15 then
     begin
       result:=false;
       exit;
     end;
     sResponse:=LogoXMLRequest(sLogoPageVariable,sSecurityHint,sRequest);
     if length(sResponse)> 4 then result:=true else result:=false;

     if not result then msgtolog('Abnormal response to SETVARS request: '+sResponse);


end;

function TFrmLOGOMain.GetLogoVariables(): string;
var
  XMLDOMDocument: IXMLDOMDocument;
  TheNode         : IXMLDOMNode;
  TheRoot         : IXMLDOMElement;
  sResponse1, sRequest: string;
  i, NC: integer;
begin
        if sSecurityHint = '0' then
    begin
      sSecurityHint:=LogoXMLLogin();
      if sSecurityHint = '0' then
      begin
      result:='';
        exit;
      end;
    end;;

  if length(VarIntArray)>0 then sRequest:='GETVARS:';
  if length(VarIntArray)>0 then for i := low(VarIntArray) to high(VarIntArray) do
  begin
     if ((sRequest<>'GETVARS:') and (sRequest<>'')) then  sRequest:=  sRequest + ';';
     sRequest:=sRequest+'v'+inttostr(i)+','+ inttostr(VarIntArray[i].Range)+',0,'+inttostr(VarIntArray[i].Number)+','+inttostr(VarIntArray[i].VarType)+',1';
  end;

  if length(sRequest)>0 then
  begin
     sResponse1:=LogoXMLRequest(sLogoPageVariable,sSecurityHint,sRequest);
     result:=sResponse1;
  end
  else
  begin
     result:='';
     exit;
  end;
    if sResponse1='' then
    begin
      msgtolog ('No response from LOGO while poling LOGO variables values.');
      exit;
    end;
  if sResponse1='403' then
    begin
      msgtolog ('Access deny (error 403)while poling LOGO variables values');
      sSecurityHint:='0';
      XMLHttpRequest:= nil;
      sSecurityHint:=LogoXMLLogin();
      exit;
    end;

       XMLDOMDocument:=CoDOMDocument.Create;
       XMLDOMDocument.async:=false;
       XMLDOMDocument.loadXML(result);
       TheRoot:=XMLDOMDocument.DocumentElement;
       if XMLDOMDocument.parseError.errorCode <> 0 then msgtolog('XML Load error:' + XMLDOMDocument.parseError.reason);

       TheNode:=  XMLDOMDocument.getElementsByTagName('rs').item[0];
       NC:=TheNode.childNodes.length;
       for i:=0 to NC - 1 do
       begin
          VarIntArray[i].Value:= strtointdef(TheNode.childNodes.item[i].attributes.getNamedItem('v').text,0);
          VarIntArray[i].PendingVal:=VarIntArray[i].Value;

          if bEnableHiddenMsgToLog then msgtolog( TheNode.childNodes.item[i].attributes.getNamedItem('i').text + ' '+TheNode.childNodes.item[i].attributes.getNamedItem('e').text + ' '+TheNode.childNodes.item[i].attributes.getNamedItem('v').text);
       end;
      XMLDOMDocument:=nil;
      if iMaxPolingCountNumPerLoginSession>0 then
      begin
        inc(iLogoPolingCount);
        if iLogoPolingCount>iMaxPolingCountNumPerLoginSession then
        begin
           LogoXMLLogout();
           sSecurityHint:=LogoXMLLogin();
           if sSecurityHint = '0' then
               begin
                 result:='';
                 exit;
               end;
        end;

      end;

end;





procedure TFrmLOGOMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
msgtolog('Main form is about to close. Application LogoPark will be terminated.');
if sSecurityHint<>'0' then LogoXMLLogout();

end;

procedure TFrmLOGOMain.FormCreate(Sender: TObject);


begin
  FrmLogoMain.Caption:=FormCaption;
  MsgToLog('Startup and variables setup');
  GlobalInit;
  sleep(iPrestartDelay);
  if bEnableLogo then
    begin
       sSecurityHint:=LogoXMLLogin();
    end;



  Timer1.Interval:=iTimer1Interval;
  Timer1.Enabled:= bEnableTimer1;
  if Timer1.Enabled then MsgToLog('Timer # 1 enabled with interval '+inttostr(iTimer1Interval)+ 'ms')
    else MsgToLog('Timer # 1 was not enabled.');


end;

//TIMED PROCEDURE///////////////////////
procedure TFrmLOGOMain.Timer1Timer(Sender: TObject);
var
  sCapStat, sPoleStatus: string;
begin
 Timer1.Enabled:=false;
 if bEnableLogo then
  begin

    bLogoIsRunning:=CheckIsLogoRunning();
    if bLogoIsRunning then sCapStat:=' Running' else sCapStat:=' Not running';  ;
    FrmLogoMain.Caption:=FormCaption + ' '+ sLogoMainIP + sCapStat ;
    SetLogoVariables();
    sPoleStatus:=GetLogoVariables();
    if length(sPoleStatus)>0  then TestDraw();
  end;

 Timer1.Enabled:=true;
end;




function TFrmLOGOMain.TestDraw():boolean;
begin
  if VarIntArray[2].Value>0 then ShI1.Brush.Color:=clBlue else ShI1.Brush.Color:=clWhite;
  if VarIntArray[3].Value>0 then ShI3.Brush.Color:=clBlue else ShI3.Brush.Color:=clWhite;
  if VarIntArray[0].Value>0 then ShQ1.Brush.Color:=clRed else ShQ1.Brush.Color:=clWhite;
  if VarIntArray[1].Value>0 then ShQ2.Brush.Color:=clGreen else ShQ2.Brush.Color:=clWhite;
  result:=true;
end;



procedure TFrmLOGOMain.ShQ1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 if (Sender as TShape).Brush.Color=clWhite then
   begin
     (Sender as TShape).Brush.Color:=clRed;
      VarIntArray[0].PendingVal:=1;
   end
   else
   begin
     (Sender as TShape).Brush.Color:=clWhite;
     VarIntArray[0].PendingVal:=0;
   end;
end;






procedure TFrmLOGOMain.ShQ2MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
   if (Sender as TShape).Brush.Color=clWhite then
   begin
     (Sender as TShape).Brush.Color:=clGreen;
      VarIntArray[1].PendingVal:=1;
   end
   else
   begin
     (Sender as TShape).Brush.Color:=clWhite;
     VarIntArray[1].PendingVal:=0;
   end;
end;

end.
