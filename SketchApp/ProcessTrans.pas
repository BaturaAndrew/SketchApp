unit ProcessTrans;

interface

uses Windows, SysUtils, Dialogs, Classes, InputData, Generics.Collections,
  SketchView;

type

  paramSurfSizes = array [0 .. 3] of single;

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

    function GetSurfSize(NPVA: integer): paramSurfSizes;
  private

    procedure MakeOutHalfOpenCyl;

    procedure MakeOutClosedCyl;

    procedure MakeOutCon;

    procedure CutTorec;

    procedure CutCylinder;

    procedure MakeInOpenCyl;

    procedure MakeInHalfOpenCyl;

    function PositionCut: boolean;

    function IsClosed(NPVA: integer): boolean;

    // ���� � ��������� ���� ��������� ��������� ��������, �� �������� ������ � ����������� �����������
    function IfClosedCylindr(POVV: integer; var podrezTorec: single;
      var PRIV: integer): boolean;

    // ����������� ValueListEditor1  ����������� � ������� ��������
    procedure FillList(trans: ptrTransition);

    // ���������� ������� ��������
    function CalculatedSizePodrez(nomerSurf: integer): single;
    // ���������� ������� ��������
    function CalculatedInnerSizePodrez(nomerSurf: integer): single;
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

function TProcessingTransition.CalculatedInnerSizePodrez
  (nomerSurf: integer): single;
var
  i: integer;
  size: single;
  NPVA: integer;
begin
  size := 0;
  NPVA := nomerSurf;

  // GetSurfSize(NPVA)[3]; [3] - PRIV
  while GetSurfSize(NPVA)[3] <> 1 do
  begin
    if (NPVA > GetSurfSize(NPVA)[3]) then
      size := size + GetSurfSize(NPVA)[0]
    else
      size := size - GetSurfSize(NPVA)[0];

    NPVA := round(GetSurfSize(NPVA)[3]);
  end;

  // if (NPVA > GetSurfSize(NPVA)[3]) then
  // size := size + GetSurfSize(NPVA)[0]
  // else
  size := GetSurfSize(NPVA)[0] - size;

  result := size;
end;

function TProcessingTransition.CalculatedSizePodrez(nomerSurf: integer): single;
var
  i, j: integer;
  size, lengthDet: single;
  NPVA, NUSL: integer;
begin
  size := 0;
  NPVA := nomerSurf;

  // GetSurfSize(NPVA)[3]; [3] - PRIV
  while GetSurfSize(NPVA)[3] <> 1 do
  begin
    if (NPVA > GetSurfSize(NPVA)[3]) then
      size := size + GetSurfSize(NPVA)[0]
    else
      size := size - GetSurfSize(NPVA)[0];

    NPVA := round(GetSurfSize(NPVA)[3]);
  end;
  lengthDet := 0;
  // ������� ������ ��������  � ���������� X ������ �����
  for i := 0 to m_InputData.listSurface.Count - 1 do
  begin
    if (pSurf(m_InputData.listSurface[i]).NUSL = 9907) and
      (pSurf(m_InputData.listSurface[i]).number = NPVA) then
    begin

      // ������� ������ ��������  � ���������� X ������ �����
      for j := 0 to MainForm.m_sketchView.OutsideSurfaces.Count - 1 do
      begin
        if (pSurf(MainForm.m_sketchView.OutsideSurfaces[j]).NUSL = 9907) then
        begin
          lengthDet := pSurf(MainForm.m_sketchView.OutsideSurfaces[j])
            .point[0].X;
          break;
        end;
      end;

    end;
  end;

  if (lengthDet > 0) then
  begin
    if (NPVA > GetSurfSize(NPVA)[3]) then
      size := size + lengthDet
    else
      size := size - lengthDet;
  end
  else
  begin
    if (NPVA > GetSurfSize(NPVA)[3]) then
      size := size + GetSurfSize(NPVA)[0]
    else
      size := size - GetSurfSize(NPVA)[0];
  end;
  result := size;
end;

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
  if (((m_InputData.currTrans.PKDA = 2112) or
    (m_InputData.currTrans.PKDA = 3212)) and
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

  // ������ ������� �����
  if (m_InputData.currTrans.PKDA = 2122) then
    if ((m_InputData.currTrans.R_POVV < m_InputData.currTrans.L_POVB)) then
      // ����� �����
      result := false
    else // ����� - ������
      result := true;

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
begin
  // ����� ������������� ��������.
  // ����� skipTrans>0, ����� ���������� ��������������� ���������� ���������
  i_trans := i_transition + skipTrans;

  // ������� ������ � ���������� ���������.
  m_InputData.ClearPrevTransitions;

  if ((i_trans) < (m_InputData.countTransitions)) then
  begin

    // ������� ValueListEditor1
    while MainForm.ValueListEditor1.Strings.Count > 0 do
      MainForm.ValueListEditor1.DeleteRow(1);

    // ������ ������ �������� �������� �  ���������� currTrans
    m_InputData.ReadCurrentTransition(m_InputData.currTrans, i_trans);

    // ���� ��������� ����� ��� ������ �����
    if (m_InputData.currTrans.PKDA = 2131) then
      CutTorec;

    // ���� ����� ������������ �������
    if ((m_InputData.currTrans.PKDA = 2111) and
      (m_InputData.currTrans.SizesFromTP[0] > 0)) then
      CutCylinder;

    // // ���� ����� ������� �����
    // if (m_InputData.currTrans.PKDA = 2122) then
    // MakeOutsideCon;

    // ���������, ��� ������: ������������ �������
    begin

      begin
        // ���� � ��������� ������ ������� - "������"
        if ((m_InputData.currTrans.PKDA = 2112) or
          (m_InputData.currTrans.PKDA = 3212)) then
          // � ����� ������� - �� ��������
          if not(IsClosed(m_InputData.currTrans.NPVA)) then
            MakeOutHalfOpenCyl;
        // ���� � ��������� ������ ������� - "���������"
        if (m_InputData.currTrans.PKDA = 2132) then
          // � ����� ������� - �� ��������
          if not(IsClosed(m_InputData.currTrans.R_POVV)) then
            MakeOutHalfOpenCyl;
      end;

      // ��� ��������  �������
      if (m_InputData.currTrans.PKDA = 2112) then
        if (IsClosed(m_InputData.currTrans.NPVA)) then
          MakeOutClosedCyl;
    end;

    // ���� ������ ������
    str := IntToStr(m_InputData.currTrans.PKDA);
    if (m_InputData.currTrans.PKDA < 0) then
      // ������ �������� ���������
      if (str[str.length] = '1') then
        MakeInOpenCyl
        // ������ ���������� ������������ �������
      else if (str[str.length] = '2') then
        MakeInHalfOpenCyl;

  end;
end;

// ��������� �����
procedure TProcessingTransition.CutCylinder;
begin
  MainForm.m_sketchView.Resize_Cylinder(m_InputData.currTrans);
  FillList(m_InputData.currTrans);
end;

procedure TProcessingTransition.CutTorec;
begin
  MainForm.m_sketchView.Resize_Torec(m_InputData.currTrans);
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

function TProcessingTransition.GetSurfSize(NPVA: integer): paramSurfSizes;
var
  i: integer;
  mass: paramSurfSizes;
begin
  for i := 0 to 3 do
    mass[i] := 0;

  // ������� ������� �����������
  for i := 0 to m_InputData.listSurface.Count - 1 do
    if (pSurf(m_InputData.listSurface[i]).number = NPVA) then
    begin
      mass[0] := pSurf(m_InputData.listSurface[i]).Sizes[0];
      mass[1] := pSurf(m_InputData.listSurface[i]).Sizes[1];
      mass[2] := pSurf(m_InputData.listSurface[i]).Sizes[2];
      mass[3] := pSurf(m_InputData.listSurface[i]).PRIV;
      break;
    end;

  result := mass;

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

// ������� ��������� ��������
procedure TProcessingTransition.MakeOutClosedCyl;
var
  i: integer;
  // ���� true, �� ����� �����, ����� - ������
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPovTorec: integer;
  // ������ ����������� ������������
  numPrivLeft, numPrivRight: integer;
  leftTor, diamClosedCyl, lengthClosedCylindr, rightTorec, diamHalfopenedCyl,
    lengthHalfopenedCyl: single;
begin

  // ������ ������ ��������, ����������  � �������
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1);
  // ������ ������ ��������, ����������  � �������
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans2, i_trans + 2);

  // ����������� ��������� ��������� ��������
  flagLeft := PositionCut;

  diamClosedCyl := m_InputData.currTrans.SizesFromTP[0];
  lengthClosedCylindr := GetSurfSize(m_InputData.currTrans.NPVA)[1];
  diamHalfopenedCyl := m_InputData.joinTrans2.SizesFromTP[0];
  lengthHalfopenedCyl := GetSurfSize(m_InputData.joinTrans2.NPVA)[1];

  // ��������� ������� ��� ������ � ����������� �� ������������ ������������ ����. ��������
  if flagLeft then
  begin
    leftTor := CalculatedSizePodrez(m_InputData.currTrans.L_POVB);
    rightTorec := CalculatedSizePodrez(m_InputData.joinTrans.NPVA);
  end
  else if not(flagLeft) then
  begin
    leftTor := CalculatedSizePodrez(m_InputData.joinTrans.NPVA);
    rightTorec := CalculatedSizePodrez(m_InputData.currTrans.L_POVB);
  end;

  MainForm.m_sketchView.Insert_OutClosedSurf(m_InputData.currTrans, flagLeft,
    numPrivLeft, numPrivRight, leftTor, diamClosedCyl, lengthClosedCylindr,
    rightTorec, diamHalfopenedCyl, lengthHalfopenedCyl);

  FillList(m_InputData.currTrans);
  FillList(m_InputData.joinTrans);
  FillList(m_InputData.joinTrans2);

  // ���� ������ �������� �������, �� ������������ ����� 3 �������� � ��� �������� ����������
  skipTrans := skipTrans + 2;

end;

procedure TProcessingTransition.MakeOutCon;
var
  i: integer;
  // ���� true, �� ����� �����, ����� - ������
  flagLeft: boolean;

  P1, P2: TPOINT;
begin

  // ������ ������ ��������, ����������  � �������
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans - 1);
  // ������ ������ ��������, ����������  � �������
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans2, i_trans - 2);

  // ����������� ��������� ������
  flagLeft := PositionCut;

  P1.Y := round(m_InputData.currTrans.SizesFromTP[0]);
  P1.X := round(m_InputData.joinTrans2.SizesFromTP[2]);
  P2.Y := round(m_InputData.joinTrans.SizesFromTP[0]);
  P2.X := round(P1.X + m_InputData.currTrans.SizesFromTP[1]);

  MainForm.m_sketchView.Insert_OutsideCon(m_InputData.currTrans,
    flagLeft, P1, P2);

  FillList(m_InputData.currTrans);
end;

procedure TProcessingTransition.MakeOutHalfOpenCyl;
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
  if (((m_InputData.currTrans.PKDA = 2112) and
    (m_InputData.currTrans.SizesFromTP[2] = 0) and
    (m_InputData.currTrans.SizesFromTP[0] > 0))) then
  begin
    if (m_InputData.countTransitions > i_trans + 1) then
      // ������ ������ ��������, ����������  � �������
      m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1);
  end;
  if (m_InputData.currTrans.PKDA = 2132) then
  begin
    if (m_InputData.countTransitions > i_trans + 1) then
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

    podrezTorec := CalculatedSizePodrez(m_InputData.currTrans.R_POVV);
    tochitPover := m_InputData.currTrans.SizesFromTP[0];

    MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.currTrans,
      flagLeft, nomerPriv, podrezTorec, tochitPover);

    FillList(m_InputData.currTrans);
  end

  // ���� ������������ 2 ��������
  else
  begin

    // ������������� ������ ������� �� ����
    if (m_InputData.currTrans.PKDA = 2132) then
    begin
      // ����� ����� ������
      podrezTorec := CalculatedSizePodrez(m_InputData.currTrans.NPVA);
      // �� ������� ��������� �������
      tochitPover := m_InputData.joinTrans.SizesFromTP[0];
      // ����� ����������� ������ �����
      nomerPovTorec := m_InputData.currTrans.NPVA;

      // ��������� �����������
      MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.currTrans,
        flagLeft, nomerPovTorec, podrezTorec, tochitPover);

      // ���� ����� ������ ������������ ����� 2 ��������, �� ���� ������� ����������
      skipTrans := skipTrans + 1;
    end;

    // ������������� ������ ������� �� ����
    if (m_InputData.joinTrans.PKDA = 2132) then
    begin
      podrezTorec := CalculatedSizePodrez(m_InputData.joinTrans.NPVA);
      tochitPover := m_InputData.currTrans.SizesFromTP[0];
      nomerPovTorec := m_InputData.joinTrans.NPVA;

      MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.joinTrans,
        flagLeft, nomerPovTorec, podrezTorec, tochitPover);

      skipTrans := skipTrans + 1;
    end;

    FillList(m_InputData.currTrans);
    FillList(m_InputData.joinTrans);
  end;
end;

// ������� ����������� ������������� ��������
procedure TProcessingTransition.MakeInHalfOpenCyl;
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
    MainForm.m_sketchView.Insert_InHalfopenSurf(m_InputData.currTrans,
      flagLeft);

    FillList(m_InputData.currTrans);
  end
  else // ���� ������������ �� 2 ��������
    // ������������� ������ ������� �� ����
    if (m_InputData.currTrans.PKDA = -2132) then
    begin

      // ��������� ������ �������� � ����������� �� ������������ ������������ ����. ��������

      // ����� ����� ������
      // podrezTorec := m_InputData.currTrans.SizesFromTP[2];
      podrezTorec := CalculatedInnerSizePodrez(m_InputData.currTrans.NPVA);

      // �� ������� ��������� �������
      tochitPover := m_InputData.joinTrans.SizesFromTP[0];
      // ����� ����������� ������ �����
      nomerPovTorec := m_InputData.currTrans.NPVA;

      // ��������� �����������
      MainForm.m_sketchView.Insert_InHalfopenSurf(m_InputData.currTrans,
        flagLeft, nomerPovTorec, podrezTorec, tochitPover);
      // ���� ����� ������ ������������ ����� 2 ��������, �� ���� ������� ����������
      skipTrans := skipTrans + 1;
    end
    else
      // ������������� ������ ������� �� ����
      if (m_InputData.joinTrans.PKDA = -2132) then
      begin
        podrezTorec := CalculatedInnerSizePodrez(m_InputData.joinTrans.NPVA);
        // podrezTorec := m_InputData.joinTrans.SizesFromTP[2];
        tochitPover := m_InputData.currTrans.SizesFromTP[0];
        nomerPovTorec := m_InputData.joinTrans.NPVA;

        MainForm.m_sketchView.Insert_InHalfopenSurf(m_InputData.currTrans,
          flagLeft, nomerPovTorec, podrezTorec, tochitPover);

        skipTrans := skipTrans + 1;
      end;
  FillList(m_InputData.currTrans);
  FillList(m_InputData.joinTrans);

end;

// ������� ����������� ��������� ��������
procedure TProcessingTransition.MakeInOpenCyl;
var
  i: integer;
  diametr, length: single;
  nomerPovTorec: integer;
begin

  // length := m_InputData.jointTrans.SizesFromTP[1];
  diametr := m_InputData.currTrans.SizesFromTP[0];
  nomerPovTorec := m_InputData.currTrans.NPVA;

  MainForm.m_sketchView.Insert_InOpenCyl(m_InputData.currTrans,
    nomerPovTorec, diametr);

  FillList(m_InputData.currTrans);
end;

end.
