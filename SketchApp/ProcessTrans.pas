unit ProcessTrans;

interface

uses SysUtils, Dialogs, Classes, InputData, Generics.Collections, SketchView;

type

  // ��������� �� ������
  ptrTransition = InputData.ptrTrans;

  // ����� ��������� ��������� ��� ������������ ������������
  TProcessingTransition = class

    // �������������  ������� ������
    procedure InitSQL;

  public
    // �����������
    constructor Create;

    // ������ ���� ��������� ��� ���������� ������� ������� �� ���
    procedure ProcessingTransition(i_transition: integer);

  private

    procedure MakeOutsideHalfOpenCylinder;

    procedure CutTorec;

    procedure MakeInnerOpenCylinder;

    procedure MakeInnerHalfOpenCylinder;

    function PositionCut: boolean;

    function IsClosed(NPVA: integer): boolean;

    // ���� � ��������� ���� ��������� ��������� ��������, �� �������� ������ � ����������� �����������
    function IfClosedCylindr(POVV: integer; var podrezTorec: single;
      var PRIV: integer): boolean;

    // ����������� ValueListEditor1  ����������� � ������� ��������
    procedure FillList(trans: ptrTransition);
  public
    // ������ �������� ������� ������ (���������� � ��������)
    m_InputData: TInputData;

  private

    i_trans: integer;
    // �������� �������� �������� -
    // ��� ������, ����� ��� ��������� ��������� ����� 2 ��������
    skipTrans: integer;
  end;

implementation

{ TProcessingTransition }

uses
  SketchForm;

constructor TProcessingTransition.Create;
begin
  m_InputData := TInputData.Create;
  i_trans := 0;
  skipTrans := 0;
end;

// ����������� ��������� ������
function TProcessingTransition.PositionCut: boolean;
begin

  // ����� ������ ������ �� ���� ������� "������ �����������, ���������� ..."
  if ((m_InputData.currTrans.PKDA = 2112) and
    (m_InputData.currTrans.SizesFromTP[2] <> 0)) then
  begin
    if ((m_InputData.currTrans.R_POVV > m_InputData.currTrans.L_POVB)) then
      // ������ �����
      result := true
    else // ����� - ������
      result := false;
  end;

  // ������ ����� �� ���� �������
  if (m_InputData.currTrans.PKDA = -3212) then
    if ((m_InputData.currTrans.R_POVV < m_InputData.currTrans.L_POVB)) then
      // ������ �����
      result := true
    else // ����� - ������
      result := false;

  // ����� ������ ������ �� 2 ��������
  if ((m_InputData.currTrans.PKDA = 2132) or (m_InputData.joinTrans.PKDA = 2132)
    or (m_InputData.currTrans.PKDA = -2132) or
    (m_InputData.joinTrans.PKDA = -2132)) then
  begin
    // ������������� ������ ������� �� ���� "������ ����������� - ��������� �����"
    if ((m_InputData.currTrans.PKDA = 2132) or
      (m_InputData.currTrans.PKDA = -2132)) then

      if ((m_InputData.currTrans.R_POVV > m_InputData.currTrans.L_POVB)) then
        // ������ ������
        result := false
      else // ����� - �����
        result := true;
    // ������������� ������ ������� �� ���� "������ ����������� - ��������� �����"
    if ((m_InputData.joinTrans.PKDA = 2132) or
      (m_InputData.joinTrans.PKDA = -2132)) then
      if ((m_InputData.joinTrans.R_POVV > m_InputData.joinTrans.L_POVB)) then
        // ������ ������
        result := false
      else // ����� - �����
        result := true;
  end;

end;

procedure TProcessingTransition.ProcessingTransition(i_transition: integer);
var
  str: string;

  x, y, w: integer;

  MaxWidth: integer;
begin
  // currOrJoin := false;
  i_trans := i_transition + skipTrans;
  if ((i_trans) < (m_InputData.countTransitions)) then
  begin

    // ������� ValueListEditor1
    while MainForm.ValueListEditor1.Strings.Count > 0 do
      MainForm.ValueListEditor1.DeleteRow(1);

    // ������ ������ �������� ��������
    m_InputData.ReadCurrentTransition(m_InputData.currTrans, i_trans);

    // ���� ����� ����� ��� ������ �����
    if (m_InputData.currTrans.PKDA = 2131) then
      CutTorec;

    // ���� ������ ������������ ������
    if ((m_InputData.currTrans.PKDA = 2132) or
      (m_InputData.currTrans.PKDA = 2112) or (m_InputData.currTrans.PKDA = 3212))
    then
      MakeOutsideHalfOpenCylinder;

    // ���� ������ ������
    str := IntToStr(m_InputData.currTrans.PKDA);
    if (m_InputData.currTrans.PKDA < 0) then
      // ������ �������� ���������
      if (str[str.length] = '1') then
        MakeInnerOpenCylinder
        // ������ ���������� ������������ �������
      else if (str[str.length] = '2') then
        MakeInnerHalfOpenCylinder;
  end;

end;

// ��������� �����
procedure TProcessingTransition.CutTorec;
begin
  MainForm.m_sketchView.Resize_Torec(m_InputData.currTrans.SizesFromTP[2],
    m_InputData.currTrans.NUSL);
  FillList(m_InputData.currTrans);
end;

// ����� ���������� � ������� ��������
procedure TProcessingTransition.FillList(trans: ptrTransition);
var
  s1, s2: string;
begin

  begin
    MainForm.ValueListEditor1.InsertRow('',
      '������� �  ' + i_trans.ToString, true);
    MainForm.ValueListEditor1.InsertRow('NPVA', trans.NPVA.ToString, true);
    MainForm.ValueListEditor1.InsertRow('L_POVB', trans.L_POVB.ToString, true);
    MainForm.ValueListEditor1.InsertRow('R_POVV', trans.R_POVV.ToString, true);
    MainForm.ValueListEditor1.InsertRow('PKDA', trans.PKDA.ToString, true);
    MainForm.ValueListEditor1.InsertRow('NUSL', trans.NUSL.ToString, true);
    MainForm.ValueListEditor1.InsertRow('PRIV', trans.PRIV.ToString, true);
    MainForm.ValueListEditor1.InsertRow('Razm1; Razm2; Razm3;',
      trans.SizesFromTP[0].ToString + ';    ' + trans.SizesFromTP[1].ToString +
      ';    ' + trans.SizesFromTP[2].ToString, true);

    if (trans.PerexUserText.length > 35) then
    begin
      s1 := Copy(trans.PerexUserText, 1, 35);
      s2 := Copy(trans.PerexUserText, 36, trans.PerexUserText.length);

      MainForm.ValueListEditor1.InsertRow('Perex', s1, true);
      MainForm.ValueListEditor1.InsertRow('', s2, true);
    end
    else
      MainForm.ValueListEditor1.InsertRow('Perex', trans.PerexUserText, true);
  end;

end;

function TProcessingTransition.IfClosedCylindr(POVV: integer;
  var podrezTorec: single; var PRIV: integer): boolean;
var
  i: integer;
  isNotPOVV: boolean;
begin

  // ���� ���� POVV � ���������, �� true
  isNotPOVV := true;

  // �������������, ���� �� � ��������� ��������� �����������  POVV
  for i := 0 to m_InputData.listTrans.Count - 1 do
    if (pSurf(m_InputData.listTrans[i]).number = POVV) then
      isNotPOVV := false;

  if (isNotPOVV) then
    // ���������� �������� ����������� � ���������� ���������
    for i := 0 to m_InputData.listSurface.Count - 1 do
      if (pSurf(m_InputData.listSurface[i]).number = POVV) then
      begin
        podrezTorec := pSurf(m_InputData.listSurface[i]).Sizes[0];
        PRIV := pSurf(m_InputData.listSurface[i]).PRIV;
      end;

  result := isNotPOVV;

end;

procedure TProcessingTransition.InitSQL;
var
  detal: integer;
begin

  m_InputData := TInputData.Create;
  i_trans := 0;
  skipTrans := 0;
  detal := StrToInt(MainForm.Kod_detal.Text);
  // ������ ������ � ��������������� ��������� ��� ������ � ����� Kod_detal
  m_InputData.ReadSQLDataTransitions(detal);

end;

function TProcessingTransition.IsClosed(NPVA: integer): boolean;
var
  i: integer;
  NPVA_PrevCylindr, NPVA_NextCylindr: integer;
  diam, diamPrevCylindr, diamNextCylindr: single;

begin

  NPVA_PrevCylindr := NPVA - 2;
  NPVA_NextCylindr := NPVA + 2;

  // ���������� �������� ����������� � ���������� ���������
  for i := 0 to m_InputData.listSurface.Count - 1 do
  begin
    if (pSurf(m_InputData.listSurface[i]).number = NPVA) then
      diam := pSurf(m_InputData.listSurface[i]).Sizes[0];

    if (pSurf(m_InputData.listSurface[i]).number = NPVA_PrevCylindr) then
      diamPrevCylindr := pSurf(m_InputData.listSurface[i]).Sizes[0];

    if (pSurf(m_InputData.listSurface[i]).number = NPVA_NextCylindr) then
      diamNextCylindr := pSurf(m_InputData.listSurface[i]).Sizes[0];

  end;
  // ���� ������� �������� �������� ������ ��������� ����������� � ����������, �� �������� �������
  if (diam < diamPrevCylindr) and (diam < diamNextCylindr) then
    result := true
  else
    result := false;

end;

// ������� �������� ������������ ������(������������� �������� � �����)
procedure TProcessingTransition.MakeOutsideHalfOpenCylinder;
var
  i: integer;
  // ���� true, �� ����� �����, ����� - ������
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPovTorec: integer;
  nomerPriv: integer;
begin

  // �������, ����� ��� ��������� ������ ����� ���� ��������� ���������
  // (������ ����������� � ��������� �����)
  if ((m_InputData.currTrans.PKDA = 2132) or
    ((m_InputData.currTrans.PKDA = 2112) and (m_InputData.currTrans.SizesFromTP
    [2] = 0))) then

  begin

    // ������ ������ ��������, ����������  � �������
    m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1);

  end;
  // ����������� ��������� ������
  flagLeft := PositionCut;

  // ����  ������������ 1 �������
  // � �������� ����� ����� ������� � ��������� �����
  if (((m_InputData.currTrans.PKDA = 2112) or
    (m_InputData.currTrans.PKDA = 3212)) and
    // (����� � �������� "������..." ���� ������ ..TP14 )
    (m_InputData.currTrans.SizesFromTP[2] <> 0)) then
  begin

    // ����������, �� ����� ����������� �������������(��� ������� "��������� ����� ��.." )
    // ����� PRIV �� ����������� POVV ������� �����������
    for i := 0 to m_InputData.listSurface.Count - 1 do
      if (m_InputData.currTrans.R_POVV = pSurf(m_InputData.listSurface[i])
        .number) then
        nomerPriv := pSurf(m_InputData.listSurface[i]).PRIV;

    MainForm.m_sketchView.Insert_OutsideHalfopenSurfaces(m_InputData.currTrans,
      flagLeft, nomerPriv);

    FillList(m_InputData.currTrans);
  end

  // ���� ������������ 2 ��������
  else
  begin

    // ������������� ������ ������� �� ����
    if (m_InputData.currTrans.PKDA = 2132) then
    begin
      // ����� ����� ������
      podrezTorec := m_InputData.currTrans.SizesFromTP[2];
      // �� ������� ��������� �������
      tochitPover := m_InputData.joinTrans.SizesFromTP[0];
      // ����� ����������� ������ �����
      nomerPovTorec := m_InputData.currTrans.NPVA;

      IfClosedCylindr(m_InputData.currTrans.R_POVV, podrezTorec, nomerPriv);

      // ��������� �����������
      MainForm.m_sketchView.Insert_OutsideHalfopenSurfaces
        (m_InputData.currTrans, flagLeft, 0, nomerPovTorec, podrezTorec,
        tochitPover);

      // ���� ����� ������ ������������ ����� 2 ��������, �� ���� ������� ����������
      skipTrans := skipTrans + 1;
    end;

    // ������������� ������ ������� �� ����
    if (m_InputData.joinTrans.PKDA = 2132) then
    begin
      podrezTorec := m_InputData.joinTrans.SizesFromTP[2];
      tochitPover := m_InputData.currTrans.SizesFromTP[0];
      nomerPovTorec := m_InputData.joinTrans.NPVA;

      IfClosedCylindr(m_InputData.currTrans.R_POVV, podrezTorec, nomerPriv);

      MainForm.m_sketchView.Insert_OutsideHalfopenSurfaces
        (m_InputData.joinTrans, flagLeft, 0, nomerPovTorec, podrezTorec,
        tochitPover);

      skipTrans := skipTrans + 1;
    end;

    FillList(m_InputData.currTrans);
    FillList(m_InputData.joinTrans);
  end;
end;

// ������� ����������� ������������� ��������
procedure TProcessingTransition.MakeInnerHalfOpenCylinder;
var
  i: integer;
  // ���� true, �� ����� �����, ����� - ������
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPovTorec: integer;
begin

  // �������, ����� ��� ��������� ������ ����� ���� ��������� ���������
  // (������ ����������� � ��������� �����)
  if ((m_InputData.currTrans.PKDA = -2132) or
    ((m_InputData.currTrans.PKDA = -2112) and (m_InputData.currTrans.SizesFromTP
    [2] = 0))) then
    // ������ ������ ��������, ����������  � �������
    m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1);

  // ����������� ��������� ������
  flagLeft := PositionCut;

  // ���� � �������� ����� ����� ������� � ��������� �����
  if (m_InputData.currTrans.PKDA = -3212) then
  begin
    MainForm.m_sketchView.Insert_InnerHalfopenSurfaces(m_InputData.currTrans,
      flagLeft);

    FillList(m_InputData.currTrans);
  end
  else
    // ������������� ������ ������� �� ����
    if (m_InputData.currTrans.PKDA = -2132) then
    begin
      // ����� ����� ������
      podrezTorec := m_InputData.currTrans.SizesFromTP[2];
      // �� ������� ��������� �������
      tochitPover := m_InputData.joinTrans.SizesFromTP[0];
      // ����� ����������� ������ �����
      nomerPovTorec := m_InputData.currTrans.NPVA;

      // ��������� �����������
      MainForm.m_sketchView.Insert_InnerHalfopenSurfaces(m_InputData.currTrans,
        flagLeft, nomerPovTorec, podrezTorec, tochitPover);
      // ���� ����� ������ ������������ ����� 2 ��������, �� ���� ������� ����������
      skipTrans := skipTrans + 1;
    end
    else
      // ������������� ������ ������� �� ����
      if (m_InputData.joinTrans.PKDA = -2132) then
      begin
        podrezTorec := m_InputData.joinTrans.SizesFromTP[2];
        tochitPover := m_InputData.currTrans.SizesFromTP[0];
        nomerPovTorec := m_InputData.joinTrans.NPVA;

        MainForm.m_sketchView.Insert_InnerHalfopenSurfaces
          (m_InputData.currTrans, flagLeft, nomerPovTorec, podrezTorec,
          tochitPover);

        skipTrans := skipTrans + 1;
      end;
  FillList(m_InputData.currTrans);
  FillList(m_InputData.joinTrans);

end;

// ������� ����������� ��������� ��������
procedure TProcessingTransition.MakeInnerOpenCylinder;
var
  i: integer;
  diametr, length: single;
  nomerPovTorec: integer;
begin

  // length := m_InputData.jointTrans.SizesFromTP[1];
  diametr := m_InputData.currTrans.SizesFromTP[0];
  nomerPovTorec := m_InputData.currTrans.NPVA;

  MainForm.m_sketchView.Insert_OpenInnerCylinder(m_InputData.currTrans,
    nomerPovTorec, diametr);

  FillList(m_InputData.currTrans);
end;

end.
