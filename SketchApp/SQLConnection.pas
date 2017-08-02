unit SQLConnection;

interface

uses
  SysUtils, IniFiles, Forms, Dialogs, ADODB, Windows;

type

  // ����� ������� �� ����������� � ���� MSSQL � ���������� �������� ��������
  TSqlConnection = class

  public
    serverName: String;
    databaseName: String;

  public

    function SetConnection: TAdoConnection;
    // ������������� ��������� x������� ��������� ��� ������ ������ � ��������
    procedure SetSpReadTransitions(detal: integer);
    // �����������
    constructor Create;

  protected
    procedure ReadIni;
    function GetComputerNetName: string;
  end;

implementation

// �����������

uses DataModule;

constructor TSqlConnection.Create;
begin
  serverName := 'local';
  databaseName := 'agro_mex';
  SetConnection;

end;

function TSqlConnection.GetComputerNetName: string;
var
  buffer: array [0 .. 255] of Char;
  size: dword;
begin
  size := 256;
  if GetComputerName(buffer, size) then
    Result := buffer
  else
    Result := ''
end;

function TSqlConnection.SetConnection: TAdoConnection;

var
  st0, st1, st2, st4, st5, constr1, constr2, str: String;

begin

  // ������ ����� .ini
  ReadIni;

  serverName := GetComputerNetName;
  // ShowMessage(serverName+' '+databaseName);

  // ����������� � ��
  DataModule.DataModule1.ADOConnection1.Connected := False;

  st0 := 'Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=False;User ID=sa;Initial Catalog=';
  st1 := 'Provider=SQLOLEDB.1;Persist Security Info=False;User ID=sa;Initial Catalog=';
  st2 := ';Data Source=';
  st4 := ';Use Procedure for Prepare=1;Auto Translate=True;Packet Size=4096;Workstation ID=';
  st5 := ';Use Encryption for Data=False;Tag with column collation when possible=False';
  str := 'Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=agro_mex;Data Source=LAB113N12';
  constr1 := st0 + databaseName + st2 + serverName + st4 + st5;
  constr2 := st1 + databaseName + st2 + serverName + st4 + st5;

  try // ������������� � ����� �������������� - Windows .
    if DataModule.DataModule1.ADOConnection1.Connected = False then
    begin
      DataModule.DataModule1.ADOConnection1.ConnectionString := constr1;
      DataModule.DataModule1.ADOConnection1.Connected := True;
    end;
  except
    try // ������������� � ����� �������������� - SQL.

      if DataModule.DataModule1.ADOConnection1.Connected = False then
      begin
        DataModule.DataModule1.ADOConnection1.ConnectionString := constr2;
        DataModule.DataModule1.ADOConnection1.Connected := True;
      end;
    except
      MessageDlg('��� ������� � ���� ������ ' + databaseName + ' �� ������� ' +
        serverName + '.' + #13 + ' ���������� � ���������� ��������������! ',
        mtError, [mbOK], 0);
      Exit;
    end; // try

  end;
  DataModule.DataModule1.ADOConnection1.Open;

  Result := DataModule.DataModule1.ADOConnection1;
end;

procedure TSqlConnection.ReadIni();

var
  IniFile1: TIniFile;
begin
  // ������ Sapr.ini �����
  Try
    IniFile1 := TIniFile.Create(GetCurrentDir + '\Sapr.ini');
    // serverName := IniFile1.ReadString('BD', 'server', 'local');
    databaseName := IniFile1.ReadString('BD', 'alias_bd', 'agro_mex');
  Finally
    IniFile1.Free;
    IniFile1 := NIL;
  end;
end;

procedure TSqlConnection.SetSpReadTransitions(detal: integer);
begin

  // �������������� �������� ���������
  DataModule.DataModule1.ADOSpReadTransitions := TADOStoredProc.Create(nil);

  // ������������� ConnectionString
  DataModule.DataModule1.ADOSpReadTransitions.Connection :=
    DataModule.DataModule1.ADOConnection1;

  // ������������� ��� ��
  DataModule.DataModule1.ADOSpReadTransitions.ProcedureName :=
    'Read_Transitions1';

  DataModule.DataModule1.ADOSpReadTransitions.Parameters.Refresh;
  // ������ �������� ����������
  DataModule.DataModule1.ADOSpReadTransitions.Parameters.ParamByName
    ('@v_kodDetal').Value := detal;

  DataModule.DataModule1.ADOSpReadTransitions.Open;
  DataModule.DataModule1.ADOSpReadTransitions.First;
  // ��������� � ������ �������
end;

end.
