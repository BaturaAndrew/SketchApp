unit InputData;

interface

uses SysUtils, Dialogs, Classes, ADODB, Windows;

type
  paramSurfArray = array [0 .. 5] of integer;

  // ��������� �� ������
  ptrTrans = ^RTransition;

  // record - ��� �������� ���������� � ��������
  RTransition = record

    // ����� ����������� ����������� � ��������
    NPVA: smallint;
    // ����� �������������� �����������
    L_POVB: integer;
    // ����� ����������� �����������
    R_POVV: integer;
    // ��� �����������
    PKDA: integer;
    // �������� ��� �����������
    NUSL: integer;
    // ����� ����������� ��������
    PRIV: integer;

    // ������� Razmer1_DB_pover_TP11, Razmer3_L_pover_TP13, Privaz_Razmer_L1_TP14
    SizesFromTP: array [0 .. 2] of single;

    // ����� ��������
    PerexUserText: string;
  end;

  pSurf = ^RSurface;

  // record - ��� �������� ���������� � �����������
  RSurface = record
    // ���������� �����������
    point: array [0 .. 1] of TPOINT;
    // ����� �����������
    number: integer;
    // ����� �������������� �����������
    L_POVB: integer;
    // ����� ����������� �����������
    R_POVV: integer;
    // ��� �����������
    PKDA: integer;
    // �������� ��� �����������
    NUSL: integer;
    // ����� ����������� ��������
    PRIV: integer;
    // Par1, Par2, Par3 , Par4, Par5
    Sizes: array [0 .. 5] of single;
  end;

  // ����� �������� �� ������ ������ �� ���� � �� �� ��������
  TInputData = class

  class var
    maxDiamZagot, lengthZagot: single;
    maxDiamDetal, lengthDetal: single;
  public
    // ���������� ���������
    countTransitions: integer;

    // ������, �������� ���������� � ������� ��������
    currTrans: ptrTrans;
    // ������, �������� ���������� � ��������, ��������� � �������
    joinTrans: ptrTrans;
    // ������ �������, ��������� � ������� (��� �������� ���������)
    joinTrans2: ptrTrans;

    // list ��� �������� ���������� � ������������
    listSurface: TList;

    // list ��� �������� ���������� � ���������
    listTrans: TList;

  public
    class function GetDiamZagot: single;
    class function GetLengthZagot: single;
    class function GetDiamDetal: single;
    class function GetLengthDetal: single;
    // �����������
    constructor Create;
    // ������  ������ � ��������� ��������������� ������ �� ���� SQL
    procedure ReadSQLDataTransitions(detal: integer);
    // ������ ���������� � ������� ��������
    procedure ReadCurrentTransition(var currentTransition: ptrTrans;
      i_trans: integer);
    // ������� �������� ���������� ������
    procedure ClearPrevTransitions;

  private
    // ���������� ��������� �����������, ����������� � ��������
    function GetSurfParam(detal: integer; id: integer): paramSurfArray;

  end;

implementation

uses
  // �������� �������� ��������� � ������ ����������� ��� ����� �������
  DataModule;

// �����������   TInfModel
constructor TInputData.Create;
begin
  countTransitions := 0;
  listTrans := TList.Create;
  listSurface := TList.Create;
  currTrans := nil;
  new(currTrans);
  joinTrans := nil;
  new(joinTrans);
  joinTrans2 := nil;
  new(joinTrans2);

end;

class function TInputData.GetLengthZagot: single;
begin
  Result := Self.lengthZagot;
end;

class function TInputData.GetDiamZagot: single;
begin
  Result := maxDiamZagot;
end;

class function TInputData.GetLengthDetal: single;
begin
  Result := Self.lengthDetal;
end;

class function TInputData.GetDiamDetal: single;
begin
  Result := maxDiamDetal;
end;

function TInputData.GetSurfParam(detal: integer; id: integer): paramSurfArray;
var
  i: integer;
  mass: paramSurfArray;
begin
  for i := 0 to 5 do
    mass[i] := 0;

  // ��������������  ������
  DataModule1.ADOQuery := TADOQuery.Create(nil);
  // ������������� ConnectionString
  DataModule1.ADOQuery.Connection := DataModule1.ADOConnection1;
  // ������� ������� ������� ������ � �������� ������ ����� � �������� SQL
  DataModule1.ADOQuery.Close;
  DataModule1.ADOQuery.SQL.Clear;
  DataModule1.ADOQuery.SQL.Add
    ('SELECT Nomer_Pover_L_POVB, Nomer_Pover_R_POVV, Kod_Pover_A_PKDA , ' +
    'Uslov_kod_pover_A_NUSL, Nomer_Pover_PRIV FROM    Detal_Poverhnost ' +
    ' WHERE (Kod_detal = :kod_detal) AND (Flag_Arxiv = 1) and (Nomer_Pover_A_NPVA_TP01=:ParamID)');
  // ������ ����������
  DataModule1.ADOQuery.Parameters.ParamByName('kod_detal').Value := detal;
  DataModule1.ADOQuery.Parameters.ParamByName('ParamID').Value := id;
  // ���������� ������� � ��������� ��������
  DataModule1.ADOQuery.Active := true;
  for i := 0 to 4 do
    mass[i] := DataModule1.ADOQuery.Fields[i].AsInteger;

  Result := mass;
end;

procedure TInputData.ReadCurrentTransition(var currentTransition: ptrTrans;
  i_trans: integer);
var
  i: integer;
begin

  currentTransition.NPVA := ptrTrans(listTrans[i_trans]).NPVA;
  currentTransition.L_POVB := ptrTrans(listTrans[i_trans]).L_POVB;
  currentTransition.R_POVV := ptrTrans(listTrans[i_trans]).R_POVV;
  currentTransition.PKDA := ptrTrans(listTrans[i_trans]).PKDA;
  currentTransition.NUSL := ptrTrans(listTrans[i_trans]).NUSL;
  currentTransition.PRIV := ptrTrans(listTrans[i_trans]).PRIV;
  currentTransition.PerexUserText := ptrTrans(listTrans[i_trans]).PerexUserText;

  for i := 0 to 2 do
    currentTransition.SizesFromTP[i] := ptrTrans(listTrans[i_trans])
      .SizesFromTP[i];

end;

procedure TInputData.ClearPrevTransitions;
begin
  currTrans := nil;
  new(currTrans);
  joinTrans := nil;
  new(joinTrans);
  joinTrans2 := nil;
  new(joinTrans2);
end;

procedure TInputData.ReadSQLDataTransitions(detal: integer);
var
  transition: ptrTrans;
  surfase: pSurf;
  i: integer;
  tempDataSet: TCustomADODataSet;
  paramsSurf: paramSurfArray;
begin

  // ������� �������� ��������� ���������� ������
  ClearPrevTransitions;

  // ������������� ��������� �������� ���������
  // sqlData1 - ������, ���������� �  ����� Datamodule
  sqlConnect.SetSpReadTransitions(detal);

  // ����������� ������� Recordset
  tempDataSet := DataModule1.ADOSpReadTransitions;

  // ������ ������� ���������
  if (tempDataSet.Fields[0].AsInteger > tempDataSet.Fields[1].AsInteger) then
    maxDiamZagot := tempDataSet.Fields[0].AsInteger
  else
    maxDiamZagot := tempDataSet.Fields[1].AsInteger;
  if (tempDataSet.Fields[2].AsInteger > tempDataSet.Fields[3].AsInteger) then
  begin
    lengthZagot := tempDataSet.Fields[2].AsInteger;
    lengthDetal := tempDataSet.Fields[3].AsInteger;
  end
  else
  begin
    lengthZagot := tempDataSet.Fields[3].AsInteger;
    lengthDetal := tempDataSet.Fields[2].AsInteger;
  end;

  // ��������� Select � ����������� � ���������
  tempDataSet.Recordset := DataModule1.ADOSpReadTransitions.NextRecordSet(i);
  while not tempDataSet.Eof do
  begin

    countTransitions := countTransitions + 1;

    // ���������� ���������� � �������� � listTrans
    transition := nil;
    new(transition);
    // ������� � ���������� Nomer_Pover_A_NPVA_TP01 �������� ������ �����������
    transition.NPVA := tempDataSet.Fields[0].AsInteger;

    // ������� �� ��������
    transition.SizesFromTP[0] := tempDataSet.Fields[1].AsSingle;
    transition.SizesFromTP[1] := tempDataSet.Fields[2].AsSingle;
    transition.SizesFromTP[2] := tempDataSet.Fields[3].AsSingle;
    transition.PerexUserText := tempDataSet.Fields[4].AsString;
    // �������� �����������
    paramsSurf := GetSurfParam(detal, transition.NPVA);
    transition.L_POVB := paramsSurf[0];
    transition.R_POVV := paramsSurf[1];
    transition.PKDA := paramsSurf[2];
    transition.NUSL := paramsSurf[3];
    transition.PRIV := paramsSurf[4];

    listTrans.Add(transition);
    tempDataSet.Next;
  end;

  // ��������� Select � ����������� � ���� ������������ ������
  tempDataSet.Recordset := DataModule1.ADOSpReadTransitions.NextRecordSet(i);
  while not tempDataSet.Eof do
  begin
    // ���������� ���������� � ������������
    surfase := nil;
    new(surfase);
    // �������� �����������
    surfase.number := tempDataSet.Fields[0].AsInteger;
    surfase.L_POVB := tempDataSet.Fields[1].AsInteger;
    surfase.R_POVV := tempDataSet.Fields[2].AsInteger;
    surfase.PKDA := tempDataSet.Fields[3].AsInteger;
    surfase.NUSL := tempDataSet.Fields[4].AsInteger;
    surfase.PRIV := tempDataSet.Fields[5].AsInteger;
    surfase.Sizes[0] := tempDataSet.Fields[6].AsInteger;
    surfase.Sizes[1] := tempDataSet.Fields[7].AsInteger;
    surfase.Sizes[2] := tempDataSet.Fields[8].AsInteger;
    surfase.Sizes[3] := tempDataSet.Fields[9].AsInteger;
    surfase.Sizes[4] := tempDataSet.Fields[10].AsInteger;

    listSurface.Add(surfase);
    tempDataSet.Next;
  end;

end;

end.
