unit SketchView;

interface

uses
  Windows, Graphics, Dialogs,
  // ��� ������ �������� ���������
  InputData, SysUtils, Classes;

type

  // ����� ������� �� ������������ ����������� � �������� �������� �������
  // � ���� ������� ����� � �� ����� �� �� �����
  TSketchView = class
  private
    flagPodrezLevTorec: boolean;
    razmLeftPodrez: single;
  public
    // �������� �������
    m_Screen: TRECT;
    // �������� �� ��� � � � ��� ������ ������
    m_dx, m_dy: integer;
    // ������
    m_metric: single;

    // ������ �������� ������������
    OutSurf: TList;
    // ������ �������� ������������
    OutCon: TList;
    // ������ ���������� ������������
    InnerSurf: TList;
  protected
    // ����������(���� � ��������� ���� ������)
    m_Zoom: real;

    // ������ ��������  ������������ � �������������������� ������������
    ScaleOutSurfaces: TList;
    // ������ ��������  ������������ � �������������������� ������������
    ScaleInSurfaces: TList;
    ScaleOutCon: TList;
    // ������� ���������
    DiamZagot, LenZagot: single;
    // ������� ������
    DiamDetal, LenDetal: single;
  public
    // �����������
    constructor Create;
    // ��������� �������� ��� ������
    procedure SetMetric;
    // ����� ������ �� �����
    procedure Draw(canvas: TCanvas);
    // �������� ������������ ���������
    procedure CreateFirstSurface;
    // ������� ������
    procedure Clear;

    // ������� ��������� ��������
    procedure Insert_OutClosedSurf(currTrans: ptrTrans; flagLeft: boolean; numPrivLeft, numPrivRight: integer; leftTor, diamClosedCyl, lengthClosedCylindr, rightTorec, diamHalfopenedCyl, lengthHalfopenedCyl: single);

    // ������� �������� ������������ ������������ (������)
    procedure Insert_OutHalfopenSurf(currTrans: ptrTrans; flagLeft: boolean; nomerPov: integer = 0; podrezTorec: single = 0; tochitPover: single = 0; faceOfReference: integer = 1);

    // ������� �������� �������
    procedure Insert_OutCon(currTrans: ptrTrans; flagLeft: boolean; P1, P2: TPOINT; faceOfReference: integer);
    // �������  ������
    procedure Insert_Con(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);

    // �������  ��������
    procedure Insert_Cyl(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);

    // �������  ��������
    procedure Insert_Tor(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);

    // ������� ����������� ��������� �������� (�����)
    procedure Insert_InOpenCyl(currentTransition: ptrTrans; nomerPovTorec: integer; diametr: single);

    // ������� ���������� ������������ ������������ (�������)
    procedure Insert_InHalfopenSurf(currTrans: ptrTrans; flagLeft: boolean; nomerPov: integer = 0; podrezTorec: single = 0; tochitPover: single = 0);

    // ��������� ������� ������ ��� ������� �����
    procedure Resize_Torec(currTrans: ptrTrans);

    // ��������� ������� ��������
    procedure Resize_Cylinder(currTrans: ptrTrans);
  private

    // �������������� ��������� ������������ � ������ �������� � ��������
    procedure ConvertingPoint;

    // ������� ������ ����������� � listSurfaces � ������� �������������, ����� �������� ������
    function GetOutsideSurfPriv(insertDiam: single; flagLeft: boolean): integer;

    // ������� -//- , ����� ���������� �����
    function GetInnerSurfPriv(insertDiam: single; flagLeft: boolean): integer;

    // ������� -//- , ����� ���������� �����
    function GetClosedPriv(leftTor: single; flagLeft: boolean): integer;

    // ��������� ������� �����������
    procedure InsertSurf(flagSurf: integer; P1, P2: TPOINT; Index, number, Kod_PKDA, Kod_NUSL: integer);
  end;

implementation

uses
  SketchForm;

function Comp(Item1, Item2: Pointer): integer;
// � ������� ���� ������� �����������	���������� ������������ �� ���������� X
begin
  if ((pSurf(Item1).point[0].X) + (pSurf(Item1).point[1].X)) < ((pSurf(Item2).point[0].X) + (pSurf(Item2).point[1].X)) then
    Result := -1
  else if ((pSurf(Item1).point[0].X) + (pSurf(Item1).point[1].X)) > ((pSurf(Item2).point[0].X) + (pSurf(Item2).point[1].X)) then
    Result := 1
  else
    Result := 0;

end;

procedure TSketchView.Clear;
var
  i: integer;
  surface1: pSurf;
begin
  OutSurf.Clear;

  OutCon.Clear;
  ScaleOutCon.Clear;

  InnerSurf.Clear;

  ScaleInSurfaces.Clear;

  ScaleOutSurfaces.Clear;
  for i := 0 to 2 do
  begin
    surface1 := nil;
    new(surface1);
    ScaleOutSurfaces.Add(surface1);
  end;

  flagPodrezLevTorec := false;
  razmLeftPodrez := 0;

end;

procedure TSketchView.ConvertingPoint;
var
  i, j, k: integer;
  buffX: integer;
begin

  // ������ ���� �������� ������������
  for i := 0 to OutSurf.Count - 1 do
  begin
    // �������������� ������  � ������ ����� ����������
    for j := 0 to 1 do
    begin
      if (pSurf(OutSurf[i]).point[j].X = 0) then
        pSurf(ScaleOutSurfaces[i]).point[j].X := round(m_dx)
      else
        pSurf(ScaleOutSurfaces[i]).point[j].X := round((m_dx + pSurf(OutSurf[i]).point[j].X * m_metric));

      if (pSurf(OutSurf[i]).point[j].Y = 0) then
        pSurf(ScaleOutSurfaces[i]).point[j].Y := round(m_dy)
      else
        pSurf(ScaleOutSurfaces[i]).point[j].Y := round((m_dy + pSurf(OutSurf[i]).point[j].Y * m_metric));

    end;

  end;

  // ������ ���� ����������  ������������
  for i := 0 to InnerSurf.Count - 1 do
    // �������������� ������  � ������ ����� ����������
    for j := 0 to 1 do
    begin
      if (pSurf(InnerSurf[i]).point[j].X = 0) then
        pSurf(ScaleInSurfaces[i]).point[j].X := round(m_dx)
      else
        pSurf(ScaleInSurfaces[i]).point[j].X := round((m_dx + pSurf(InnerSurf[i]).point[j].X * m_metric));

      if (pSurf(InnerSurf[i]).point[j].Y = 0) then
        pSurf(ScaleInSurfaces[i]).point[j].Y := round(m_dy)
      else
        pSurf(ScaleInSurfaces[i]).point[j].Y := round((m_dy + pSurf(InnerSurf[i]).point[j].Y * m_metric));

    end;

  // ������ �������
  for i := 0 to OutCon.Count - 1 do
    // �������������� ������  � ������ ����� ����������
    for j := 0 to 1 do
    begin
      if (pSurf(OutCon[i]).point[j].X = 0) then
        pSurf(ScaleOutCon[i]).point[j].X := round(m_dx)
      else
        pSurf(ScaleOutCon[i]).point[j].X := round((m_dx + pSurf(OutCon[i]).point[j].X * m_metric));

      if (pSurf(OutCon[i]).point[j].Y = 0) then
        pSurf(ScaleOutCon[i]).point[j].Y := round(m_dy)
      else
        pSurf(ScaleOutCon[i]).point[j].Y := round((m_dy + pSurf(OutCon[i]).point[j].Y * m_metric));

    end;

end;

constructor TSketchView.Create;
var
  i: integer;
  surface1: pSurf;
begin
  m_Zoom := 1.4;
  m_dx := 0;
  m_dy := 0;
  OutSurf := TList.Create;
  InnerSurf := TList.Create;
  OutCon := TList.Create;

  ScaleInSurfaces := TList.Create;
  ScaleOutSurfaces := TList.Create;
  ScaleOutCon := TList.Create;
  for i := 0 to 2 do
  begin
    surface1 := nil;
    new(surface1);
    ScaleOutSurfaces.Add(surface1);
  end;

  flagPodrezLevTorec := false;
  razmLeftPodrez := 0;
end;

procedure TSketchView.Insert_OutClosedSurf(currTrans: ptrTrans; flagLeft: boolean; numPrivLeft, numPrivRight: integer; leftTor, diamClosedCyl, lengthClosedCylindr, rightTorec, diamHalfopenedCyl, lengthHalfopenedCyl: single);
var
  i, Id: integer;
  P1, P2: TPOINT;
  Index: integer;
  number, Kod_PKDA, Kod_NUSL: integer;
  nomerPov: integer;
  lengthDet, leftTorDet: single;
  existOutClosedCylinder: boolean;
  i_existClosedCylinder: integer;
begin

  // ��������� ������ �����������-��������, � ������� ����� ����������� ������
  // �� ������ �������� ������������ ��������
  Id := GetOutsideSurfPriv(diamClosedCyl, flagLeft);
  nomerPov := currTrans.NPVA;

  existOutClosedCylinder := false;

  // ���������, ���� �� ��� ���������� �����
  // (���� ����� �������������� ����������� ��� ���������� � ������������ ������)
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).number = nomerPov) then
    begin
      existOutClosedCylinder := true;
      i_existClosedCylinder := i;
      break;
    end;
  end;

  // ������� ������ ��������  � ���������� X ������ �����
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).NUSL = 9907) then
      lengthDet := pSurf(OutSurf[i]).point[0].X;

    if (pSurf(OutSurf[i]).NUSL = 9901) then
      leftTorDet := pSurf(OutSurf[i]).point[0].X;
  end;

  if (not (flagLeft)) then
  begin

    // ��������� ����� ������������ �����
    begin
      P1.X := round(leftTor);
      P2.X := P1.X;
      P2.Y := round(pSurf(OutSurf[Id]).point[1].Y);
      P1.Y := round(diamClosedCyl);
      Kod_PKDA := 2132;
      Kod_NUSL := 9905;
      Index := Id + 1;
      number := nomerPov - 1;

      if (flagPodrezLevTorec) then
      begin
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P1.X;
      end;

      // ���� ��, �� �������� ���� �������
      if (existOutClosedCylinder) then
      begin
        pSurf(OutSurf[i_existClosedCylinder - 1]).point[0] := P1;
        pSurf(OutSurf[i_existClosedCylinder - 1]).point[1].X := P2.X;
        // � �������� ������� ��������, ������� ����� ����������� ������
        pSurf(OutSurf[i_existClosedCylinder - 2]).point[1].X := P1.X;
      end
      // ���� ���, �� ��������� �����������
      else
      begin
        InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
        // � �������� ������� ��������, ������� ����� ����������� ������
        pSurf(OutSurf[Id]).point[1].X := P1.X;
      end;

    end;

    // ��������� �������� �������
    begin
      P1.X := round(leftTor);
      P2.X := round(leftTor + lengthClosedCylindr);
      P1.Y := round(diamClosedCyl);
      P2.Y := round(diamClosedCyl);
      Kod_PKDA := 2112;
      Kod_NUSL := 9906;
      Index := Id + 2;

      if (flagPodrezLevTorec) then
      begin
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P2.X + round(razmLeftPodrez);
      end;

      // ���� ��, �� �������� ���� �������
      if (existOutClosedCylinder) then
      begin
        pSurf(OutSurf[i_existClosedCylinder]).point[0] := P1;
        pSurf(OutSurf[i_existClosedCylinder]).point[1] := P2;
      end
      // ���� ���, �� ��������� �����������
      else
        InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
    end;

    // ��������� ������ ������������ �����
    begin
      P1.X := round(leftTor + lengthClosedCylindr);
      P2.X := P1.X;
      P1.Y := round(diamClosedCyl);
      P2.Y := round(diamHalfopenedCyl);
      number := nomerPov + 1;
      Kod_PKDA := 2132;
      Kod_NUSL := 9903;
      Index := Id;

      if (flagPodrezLevTorec) then
      begin
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P1.X;
      end;

      // ���� ��, �� �������� ���� �������
      if (existOutClosedCylinder) then
      begin
        pSurf(OutSurf[i_existClosedCylinder + 1]).point[0] := P1;
        pSurf(OutSurf[i_existClosedCylinder + 1]).point[1] := P2;
      end
      // ���� ���, �� ��������� �����������
      else
        InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
    end;

    // ��������� ������ ������������ �������
    begin
      P1.X := round(leftTor + lengthClosedCylindr);
      P2.X := round(lengthDet);
      P1.Y := round(diamHalfopenedCyl);
      P2.Y := round(diamHalfopenedCyl);
      Kod_PKDA := 2112;
      Kod_NUSL := 9902;
      number := nomerPov + 2;
      Index := Id + 1;

      if (flagPodrezLevTorec) then
        P1.X := P1.X + round(razmLeftPodrez);

      // ���� ��, �� �������� ���� �������
      if (existOutClosedCylinder) then
      begin
        pSurf(OutSurf[i_existClosedCylinder + 2]).point[0] := P1;
        pSurf(OutSurf[i_existClosedCylinder + 2]).point[1].Y := P2.Y;
        pSurf(OutSurf[i_existClosedCylinder + 3]).point[0].Y := P2.Y;
      end
      // ���� ���, �� ��������� �����������
      else
        InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);

      // ���� ��, �� �������� ���� �������
      if not (existOutClosedCylinder) then
      begin
        // �������� ������� ������� �����
        for i := 0 to OutSurf.Count - 1 do
          if (pSurf(OutSurf[i]).NUSL = 9907) then
            pSurf(OutSurf[i]).point[0].Y := round(diamHalfopenedCyl);
      end;
    end;

  end
  else
  begin
    // ��������� ������ ������������ �����
    begin
      P1.X := round(rightTorec);
      P2.X := P1.X;
      P1.Y := round(diamClosedCyl);
      P2.Y := round(pSurf(OutSurf[Id]).point[1].Y);
      Kod_PKDA := 2132;
      Kod_NUSL := 9905;
      Index := Id + 1;

      if (flagPodrezLevTorec) then
      begin
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P1.X;
      end;

      InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
      // � �������� ������� ��������, ������� ����� ����������� ������
      pSurf(OutSurf[Id]).point[0].X := P1.X;
    end;

    // ��������� �������� �������
    begin
      P1.X := round(rightTorec);

      P2.X := round(leftTor);
      P1.Y := round(diamClosedCyl);
      P2.Y := P1.Y;
      Kod_PKDA := 2112;
      number := nomerPov + 1;
      Kod_NUSL := 9906;
      Index := Id + 2;

      if (flagPodrezLevTorec) then
      begin
        P1.X := round(P1.X + razmLeftPodrez);
        P2.X := round(P2.X + razmLeftPodrez);
      end;

      InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
    end;

    // ��������� ����� ������������ �����
    begin
      P1.X := round(leftTor);
      P2.X := P1.X;
      P1.Y := round(diamClosedCyl);
      P2.Y := round(diamHalfopenedCyl);
      number := nomerPov - 1;
      Kod_PKDA := 2132;
      Kod_NUSL := 9903;

      if (flagPodrezLevTorec) then
      begin
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P1.X;
        // pSurf(OutsideSurfaces[Id + 2]).point[1].X := X1;
      end;

      InsertSurf(1, P1, P2, Id, number, Kod_PKDA, Kod_NUSL);
    end;

    // ��������� ����� ������������ �������
    begin
      P1.X := round(leftTorDet);
      P2.X := round(leftTor);
      P1.Y := round(diamHalfopenedCyl);
      P2.Y := round(diamHalfopenedCyl);
      Kod_PKDA := 2112;
      Kod_NUSL := 9902;
      Index := Id + 1;

      if (flagPodrezLevTorec) then
      begin
        P1.X := round(P1.X + razmLeftPodrez);
        P2.X := round(P2.X + razmLeftPodrez);
      end;

      InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
      // �������� ������� ������ �����
      for i := 0 to OutSurf.Count - 1 do
        if (pSurf(OutSurf[i]).NUSL = 9901) then
          pSurf(OutSurf[i]).point[1].Y := round(diamHalfopenedCyl);
    end;
  end;

end;

procedure TSketchView.Insert_OutCon(currTrans: ptrTrans; flagLeft: boolean; P1, P2: TPOINT; faceOfReference: integer);
var
  i, Id, i_existOutCon: integer;
  Index: integer;
  nomerPov, Kod_PKDA, Kod_NUSL: integer;
  lengthDet: single;
  existOutCon: boolean;
begin

  // ��������� ������ �����������-��������, � �������� ����� ����������� ������
  Id := GetOutsideSurfPriv(P2.Y, flagLeft);
  nomerPov := currTrans.NPVA;

  // ������� ������ �������� � ���������� X ������ �����
  for i := 0 to OutSurf.Count - 1 do
    if (pSurf(OutSurf[i]).NUSL = 9907) then
      lengthDet := pSurf(OutSurf[i]).point[0].X;

  existOutCon := false;
  // ���������, ���� �� ��� �����
  for i := 0 to OutCon.Count - 1 do
  begin
    if ((pSurf(OutCon[i]).number = nomerPov)) then
    begin
      existOutCon := true;
      i_existOutCon := i;
      break;
    end;
  end;

  // ��������� ����������� ������
  if (not (flagLeft)) then
  begin
    // ��������� �����
    begin

      Kod_PKDA := 2122;
      Kod_NUSL := 9906;
      Index := Id + 1;

      if (flagPodrezLevTorec and (faceOfReference = 1)) then
      begin
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P2.X + round(razmLeftPodrez);
      end;

      if not (existOutCon) then
        InsertSurf(3, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL)
      else
      begin
        pSurf(OutCon[i_existOutCon]).point[0] := P1;
        pSurf(OutCon[i_existOutCon]).point[1] := P2;
      end;

      for i := 0 to OutSurf.Count - 1 do
      begin
        // �������� ������� �����������  �����
        if (pSurf(OutSurf[i]).PKDA = 2132) and (pSurf(OutSurf[i]).point[0].X = P1.X) then
          pSurf(OutSurf[i]).point[1] := P1;
        // �������� ������� ������������  ��������
        if (pSurf(OutSurf[i]).PKDA = 2112) and (pSurf(OutSurf[i]).point[0].Y = P2.Y) then
          pSurf(OutSurf[i]).point[0] := P2;
      end;

    end;
  end

  else // �����
  begin

    Kod_PKDA := 2122;
    Kod_NUSL := 9906;
    Index := Id + 1;

    if (flagPodrezLevTorec) then
    begin
      P1.X := P1.X + round(razmLeftPodrez);
      P2.X := P2.X + round(razmLeftPodrez);
    end;

    if not (existOutCon) then
      InsertSurf(3, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL)
    else
    begin
      pSurf(OutCon[i_existOutCon]).point[0] := P1;
      pSurf(OutCon[i_existOutCon]).point[1] := P2;
    end;

    for i := 0 to OutSurf.Count - 1 do
    begin
      // �������� ������� �����������  �����
      if (pSurf(OutSurf[i]).PKDA = 2132) and (pSurf(OutSurf[i]).point[0].X = P1.X) then
        pSurf(OutSurf[i]).point[0] := P1;
      // �������� ������� ������������  ��������
      if (pSurf(OutSurf[i]).PKDA = 2112) and (pSurf(OutSurf[i]).point[0].Y = P2.Y) then
        pSurf(OutSurf[i]).point[1] := P2;
    end;

  end; // ��������� else

end;

procedure TSketchView.Insert_OutHalfopenSurf(currTrans: ptrTrans; flagLeft: boolean; nomerPov: integer; podrezTorec, tochitPover: single; faceOfReference: integer);
var
  Id, i, i_existOutHalfopenCylinder: integer;
  P1, P2: TPOINT;
  Index: integer;
  number, Kod_PKDA, Kod_NUSL: integer;
  existOutHalfopenCylinder: boolean;
begin

  existOutHalfopenCylinder := false;

  // ���������, ���� �� ��� ������
  // (���� ����� �������������� ����������� ��� ���������� � ������������ ������)
  for i := 0 to OutSurf.Count - 1 do
  begin
    if ((pSurf(OutSurf[i]).number = nomerPov)) then
    begin
      existOutHalfopenCylinder := true;
      i_existOutHalfopenCylinder := i;
      break;
    end;
  end;
  if not (existOutHalfopenCylinder) then
    // ��������� ������ �����������-��������, � �������� ����� ����������� ������
    Id := GetOutsideSurfPriv(tochitPover, flagLeft)
  else
    Id := nomerPov - 2;

  // ��������� ����������� ������
  if (not (flagLeft)) then
  begin
    // ��������� ������ ������������ �����
    begin
      try
        P1.X := round(podrezTorec);
        P2.X := P1.X;
        P1.Y := round(pSurf(OutSurf[Id]).point[1].Y);
        P2.Y := round(tochitPover);
        Kod_PKDA := 2132;
        Kod_NUSL := 9905;
        Index := Id + 1;

        if (flagPodrezLevTorec and (faceOfReference = 1)) then
        begin
          P1.X := P1.X + round(razmLeftPodrez);
          P2.X := P1.X;
        end;
        // ���� ��, �� �������� ���� �������
        if (existOutHalfopenCylinder) then
        begin
          pSurf(OutSurf[i_existOutHalfopenCylinder]).point[0].X := P1.X;
          pSurf(OutSurf[i_existOutHalfopenCylinder]).point[1] := P2;
          pSurf(OutSurf[i_existOutHalfopenCylinder - 1]).point[1].X := P2.X;
        end
        // ���� ���, �� ��������� �����������
        else
        begin
          InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
          // � �������� ������� ��������, ������� ����� ����������� ������
          pSurf(OutSurf[Id]).point[1].X := P1.X;
        end;
      except
        ShowMessage(currTrans.NPVA.ToString());
      end; // ��������� try
    end;

    // ��������� ������ ������������ �������
    begin
      try
        P1.X := round(podrezTorec);
        P2.X := round(pSurf(OutSurf[Id + 2]).point[1].X);
        P1.Y := round(tochitPover);
        P2.Y := round(tochitPover);
        Kod_PKDA := 2112;
        number := nomerPov + 1;
        Kod_NUSL := 9906;
        Index := Id + 2;

        if (flagPodrezLevTorec and (faceOfReference = 1)) then
          P1.X := P1.X + round(razmLeftPodrez);

        // ���� ��, �� �������� ���� �������
        if (existOutHalfopenCylinder) then
        begin
          pSurf(OutSurf[i_existOutHalfopenCylinder + 1]).point[0] := P1;
          pSurf(OutSurf[i_existOutHalfopenCylinder + 1]).point[1].Y := P2.Y;
          // pSurf(OutSurf[i_existOutHalfopenCylinder + 2]).point[0].Y := P2.Y;
        end
        // ���� ���, �� ��������� �����������
        else
        begin
          InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
          // �������� ������ �����, ������� ���� �� ����������� ���������
          pSurf(OutSurf[Id + 3]).point[0].Y := P2.Y;
        end;

      except
        ShowMessage(currTrans.NPVA.ToString());
      end; // ��������� try

    end;

  end

  else // �����
  begin
    // ��������� ����� ������������ �������
    begin
      try
        P1.X := round(pSurf(OutSurf[Id]).point[0].X);
        P2.X := round(podrezTorec);
        P1.Y := round(tochitPover);
        P2.Y := round(tochitPover);
        Kod_PKDA := 2112;
        Kod_NUSL := 9902;
        Index := Id + 1;

        if (flagPodrezLevTorec) then
          P2.X := P2.X + round(razmLeftPodrez);

        // ���� ��, �� �������� ���� �������
        if (existOutHalfopenCylinder) then
        begin
          pSurf(OutSurf[i_existOutHalfopenCylinder]).point[0].Y := P1.Y;
          pSurf(OutSurf[i_existOutHalfopenCylinder]).point[1] := P2;
          pSurf(OutSurf[i_existOutHalfopenCylinder - 1]).point[1].Y := P2.Y;
        end
        // ���� ���, �� ��������� �����������
        else
        begin

          InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
          // �������� ������ �����, ������� ���� ��  ������������ ��������
          pSurf(OutSurf[Id - 1]).point[1].Y := P1.Y;
        end;
      except
        ShowMessage(currTrans.NPVA.ToString());
      end; // ��������� try
    end;

    // ��������� ����� ������������ �����
    begin
      try
        P1.X := round(podrezTorec);
        P2.X := P1.X;
        P1.Y := round(tochitPover);
        P2.Y := round(pSurf(OutSurf[Id]).point[0].Y);
        number := nomerPov - 1;
        Kod_PKDA := 2132;
        Kod_NUSL := 9903;
        Index := Id + 2;

        if (flagPodrezLevTorec) then
        begin
          P1.X := P1.X + round(razmLeftPodrez);
          P2.X := P1.X;
        end;

        // ���� ��, �� �������� ���� �������
        if (existOutHalfopenCylinder) then
        begin
          pSurf(OutSurf[i_existOutHalfopenCylinder + 1]).point[0] := P1;
          pSurf(OutSurf[i_existOutHalfopenCylinder + 1]).point[1].X := P2.X;

          pSurf(OutSurf[i_existOutHalfopenCylinder + 2]).point[0].X := P2.X;
        end
        // ���� ���, �� ��������� �����������
        else
        begin
          InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
          // �������� ������ ��������, ������� ���� �����  ������������ �����
          pSurf(OutSurf[Id]).point[0].X := P1.X;
        end;

      except
        ShowMessage(currTrans.NPVA.ToString());
      end; // ��������� try
    end;

  end; // ��������� else
end;

procedure TSketchView.Insert_Tor(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);
var
  i, Id, i_existOutTor: integer;
  Index: integer;
  Kod_PKDA, Kod_NUSL: integer;
  lengthDet: single;
  existOutTor: boolean;
begin

  // ��������� ������ �����������-��������, � �������� ����� ����������� ������
  Id := GetOutsideSurfPriv(P2.Y, flagLeft);

  existOutTor := false;
  // ���������, ���� �� ��� �����
  for i := 0 to OutSurf.Count - 1 do
  begin
    if ((pSurf(OutSurf[i]).number = nomerPov)) then
    begin
      existOutTor := true;
      i_existOutTor := i;
      break;
    end;
  end;

  if (flagPodrezLevTorec) then
  begin
    P1.X := P1.X + round(razmLeftPodrez);
    P2.X := P2.X + round(razmLeftPodrez);
  end;

  Kod_PKDA := 2132;
  Kod_NUSL := 9903;
  Index := Id + 1;

  // ����� ���������� Y �� ������������ ��������
  P1.Y := pSurf(OutSurf[Id]).point[0].Y;

  if not (existOutTor) then
    InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL)
  else
  begin
    pSurf(OutSurf[i_existOutTor]).point[0] := P1;
    pSurf(OutSurf[i_existOutTor]).point[1] := P2;
  end;

  // if flagLeft then
  // begin
  // // �������� ������� ��������, ���������� � �������
  // pSurf(OutSurf[Id]).point[0].X := P2.X;
  // pSurf(OutSurf[Id]).point[0].Y := P2.Y;
  // pSurf(OutSurf[Id]).point[1].Y := P2.Y;
  // end
  // else
  // begin
  // pSurf(OutSurf[Id]).point[1].X := P2.X;
  // pSurf(OutSurf[Id]).point[0].Y := P2.Y;
  // pSurf(OutSurf[Id]).point[0].Y := P2.Y;
  // end;
end;

procedure TSketchView.InsertSurf(flagSurf: integer; P1, P2: TPOINT; Index, number, Kod_PKDA, Kod_NUSL: integer);
var
  surface, surfNil: pSurf;
begin
  new(surface);
  surface.point[0] := P1;
  surface.point[1] := P2;
  surface.number := number;
  surface.PKDA := Kod_PKDA;
  surface.NUSL := Kod_NUSL;

  new(surfNil);
  if (flagSurf = 1) then
  begin
    OutSurf.Insert(Index, surface);
    ScaleOutSurfaces.Add(surfNil);
  end
  else if (flagSurf = 2) then
  begin
    InnerSurf.Add(surface);
    ScaleInSurfaces.Add(surfNil);
  end
  else if (flagSurf = 3) then
  begin
    OutCon.Add(surface);
    ScaleOutCon.Add(surfNil);
  end;
end;

procedure TSketchView.Insert_Con(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);
var
  i, Id, i_existOutCon: integer;
  Index: integer;
  Kod_PKDA, Kod_NUSL: integer;
  lengthDet: single;
  existOutCon: boolean;
begin

  // ��������� ������ �����������-��������, � �������� ����� ����������� ������
  Id := GetOutsideSurfPriv(P2.Y, flagLeft);

  existOutCon := false;
  // ���������, ���� �� ��� �����
  for i := 0 to OutCon.Count - 1 do
  begin
    if ((pSurf(OutCon[i]).number = nomerPov)) then
    begin
      existOutCon := true;
      i_existOutCon := i;
      break;
    end;
  end;

  if (flagPodrezLevTorec) then
  begin
    P1.X := P1.X + round(razmLeftPodrez);
    P2.X := P2.X + round(razmLeftPodrez);
    ;
  end;

  Kod_PKDA := 2122;
  Kod_NUSL := 9906;
  Index := Id + 1;

  if not (existOutCon) then
    InsertSurf(3, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL)
  else
  begin
    pSurf(OutCon[i_existOutCon]).point[0] := P1;
    pSurf(OutCon[i_existOutCon]).point[1] := P2;
  end;

  if flagLeft then
  begin
    // �������� ������� ��������, ���������� � �������
    pSurf(OutSurf[Id]).point[0].X := P2.X;
    pSurf(OutSurf[Id]).point[0].Y := P2.Y;
    pSurf(OutSurf[Id]).point[1].Y := P2.Y;
    // �������� ������� ������� ��������, ���������� � �������

    // ����� ������ ��� ������, ����� ��������� � �������� ��� ������
    // ....

  end
  else
  begin
    pSurf(OutSurf[Id]).point[1].X := P2.X;
    pSurf(OutSurf[Id]).point[0].Y := P2.Y;
    pSurf(OutSurf[Id]).point[0].Y := P2.Y;
  end;
end;

procedure TSketchView.Insert_Cyl(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);
var
  i, Id, i_existOutCyl: integer;
  Index: integer;
  Kod_PKDA, Kod_NUSL: integer;
  lengthDet: single;
  existOutCyl: boolean;
begin

  // ��������� ������ �����������-��������, � �������� ����� ����������� ������
  Id := GetOutsideSurfPriv(P2.Y, flagLeft);

  existOutCyl := false;
   // ���������, ���� �� ��� �����
  for i := 0 to OutSurf.Count - 1 do
  begin
    if ((pSurf(OutSurf[i]).number = nomerPov)) then
    begin
      existOutCyl := true;
      i_existOutCyl := i;
      break;
    end;
  end;

//  // ���������� ��������
//  if (flagLeft) then
//    P1.X := round(pSurf(OutSurf[Id - 1]).point[0].X)
//  else if (not (flagLeft)) then
//    P2.X := round(pSurf(OutSurf[Id + 1]).point[0].X);

  if (flagPodrezLevTorec) then
  begin
    if flagLeft then
      P2.X := P2.X + round(razmLeftPodrez)
    else
      P1.X := P1.X + round(razmLeftPodrez);
  end;

  // ��������� �������

  Kod_PKDA := 2112;
  Kod_NUSL := 9906;
  Index := Id + 1;

  if not (existOutCyl) then
    InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL)
  else
  begin
    pSurf(OutSurf[i_existOutCyl]).point[0] := P1;
    pSurf(OutSurf[i_existOutCyl]).point[1] := P2;
  end;

end;

procedure TSketchView.Insert_InHalfopenSurf(currTrans: ptrTrans; flagLeft: boolean; nomerPov: integer = 0; podrezTorec: single = 0; tochitPover: single = 0);
var
  i, j, j_tor, i_lTor, i_rTor: integer;
  surface, surface1: pSurf;
  Id: integer;
  P1, P2: TPOINT;
  Index: integer;
  number, Kod_PKDA, Kod_NUSL: integer;
  existInnerHalfopenCylinder: boolean;
  i_existInnerCylinder: integer;
  lengthDet, razx: integer;
begin

  // ������� ������ ��������  � ���������� X ������ �����
  for i := 0 to OutSurf.Count - 1 do
    if (pSurf(OutSurf[i]).NUSL = 9907) then
      lengthDet := pSurf(OutSurf[i]).point[0].X;

  if (nomerPov = 0) then
  begin
    podrezTorec := currTrans.SizesFromTP[1] + lengthDet;
    tochitPover := currTrans.SizesFromTP[0];
    nomerPov := currTrans.NPVA;
  end;

  // ����� ��������� �� �������� ������ ����� ���� ����� ������� 5. �.�. � ������� Round
  // ���������� ���������� ���������� �������, ��� ������ �������� �������� �������� ���������� � ������� �����
  if (Frac(podrezTorec) = 0.5) then
    podrezTorec := podrezTorec + 0.1;
  if (Frac(tochitPover) = 0.5) then
    tochitPover := tochitPover + 0.1;

  // ��������� ������ �����������-��������, � �������� ����� ����������� ������
  Id := GetInnerSurfPriv(tochitPover, flagLeft);

  existInnerHalfopenCylinder := false;

  // ���������, ���� �� ��� ���������� �����
  // (���� ����� �������������� ���-�� ��� ���������� �� ���������� ���-��� ������)
  for i := 0 to InnerSurf.Count - 1 do
  begin
    if (pSurf(InnerSurf[i]).number = nomerPov) then
    begin
      existInnerHalfopenCylinder := true;
      i_existInnerCylinder := i;
      break;
    end;
  end;

  if (not (flagLeft)) then // ��������� ����������� ������
  begin
    podrezTorec := ABS(LenDetal - podrezTorec);
    // ��������� ������ ���������� ������������ �������
    begin
      P1.X := round(pSurf(OutSurf[Id]).point[0].X);
      P2.X := round(pSurf(OutSurf[Id]).point[0].X - podrezTorec);
      P1.Y := round(tochitPover);
      P2.Y := round(tochitPover);
      Kod_PKDA := -2112;
      Kod_NUSL := 9912;
      Index := Id + 1;

      // ���� ��, �� �������� ���� �������
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurf[i_existInnerCylinder]).point[0] := P1;
        pSurf(InnerSurf[i_existInnerCylinder]).point[1] := P2;
      end
      // ���� ���, �� ��������� �����������
      else
        InsertSurf(2, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
    end;

    // ��������� ������ ���������� ������������ �����
    begin
      P1.X := round(pSurf(OutSurf[Id]).point[0].X - podrezTorec);
      P2.X := P1.X;
      P1.Y := round(tochitPover);
      P2.Y := 0;
      Kod_PKDA := -2132;
      number := nomerPov + 1;
      Kod_NUSL := 9913;
      Index := Id + 1;
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurf[i_existInnerCylinder + 1]).point[0] := P1;
        pSurf(InnerSurf[i_existInnerCylinder + 1]).point[1] := P2;
      end
      else
        InsertSurf(2, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);

      // ����������� ������� ���������
      for j := 0 to InnerSurf.Count - 1 do
      begin
        if (pSurf(InnerSurf[j]).PKDA = -2112) or (pSurf(InnerSurf[j]).PKDA = -2111) then
        begin
          if ((pSurf(InnerSurf[j]).point[0].X > P2.X) and (pSurf(InnerSurf[j]).point[1].X < P2.X) and (pSurf(InnerSurf[j]).number <> nomerPov)) then
          begin
            pSurf(InnerSurf[j]).point[0].X := P2.X;
            break;
          end;
          if ((pSurf(InnerSurf[j]).point[1].X > P2.X) and (pSurf(InnerSurf[j]).point[0].X < P2.X) and (pSurf(InnerSurf[j]).number <> nomerPov)) then
          begin
            pSurf(InnerSurf[j]).point[1].X := P2.X;
            break;
          end;
        end;
      end; // ������� for

    end;
  end // ��������� "if (not(flagLeft)).."

  else // ��������� ����������� �����
  begin

    // ��������� ����� ���������� ������������ �������
    begin

      P1.X := round(pSurf(OutSurf[0]).point[0].X);
      P2.X := round(pSurf(OutSurf[0]).point[0].X + podrezTorec);
      P1.Y := round(tochitPover);
      P2.Y := round(tochitPover);
      Kod_PKDA := -2112;
      Kod_NUSL := 9912;
      Index := Id + 1;
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurf[i_existInnerCylinder]).point[0].Y := P1.Y;
        pSurf(InnerSurf[i_existInnerCylinder]).point[1] := P2;
      end
      else
        InsertSurf(2, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
    end;

    // ��������� ����� ���������� ������������ �����
    begin
      P1.X := round(pSurf(OutSurf[0]).point[0].X + podrezTorec);
      P2.X := P1.X;
      P1.Y := round(tochitPover);
      P2.Y := 0;
      Kod_PKDA := -2132;
      number := nomerPov + 1;
      Kod_NUSL := 9913;
      Index := Id + 1;
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurf[i_existInnerCylinder + 1]).point[0] := P1;
        pSurf(InnerSurf[i_existInnerCylinder + 1]).point[1] := P2;
      end
      else
        InsertSurf(2, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);

      // ����������� ������� ���������
      for j := 0 to InnerSurf.Count - 1 do
      begin
        if (pSurf(InnerSurf[j]).PKDA = -2112) or (pSurf(InnerSurf[j]).PKDA = -2111) then
        begin
          if ((pSurf(InnerSurf[j]).point[0].X < P2.X) and (pSurf(InnerSurf[j]).point[1].X > P2.X) and (pSurf(InnerSurf[j]).number <> nomerPov)) then
          begin
            pSurf(InnerSurf[j]).point[0].X := P2.X;
            break;
          end;
          if ((pSurf(InnerSurf[j]).point[1].X < P2.X) and (pSurf(InnerSurf[j]).point[0].X > P2.X) and (pSurf(InnerSurf[j]).number <> nomerPov)) then
          begin
            pSurf(InnerSurf[j]).point[1].X := P2.X;
            break;
          end;
        end;
      end; // ������� for

    end;

  end;
end;

procedure TSketchView.Insert_InOpenCyl(currentTransition: ptrTrans; nomerPovTorec: integer; diametr: single);
var
  i: integer;
  surface, surface1: pSurf;
  existInnerOpenCylinder: boolean;
  // ���������� �����������
  P1, P2: TPOINT;
  Index: integer;
  Kod_PKDA, Kod_NUSL: integer;
begin

  existInnerOpenCylinder := false;

  // ���������, ���� �� ��� ���������� �������� �������
  for i := 0 to InnerSurf.Count - 1 do
  begin
    if (pSurf(InnerSurf[i]).NUSL = 9910) then
    begin
      existInnerOpenCylinder := true;
      break;
    end;
  end;

  // ���� ��, �� �������� ���� �������
  if (existInnerOpenCylinder) then
  begin
    pSurf(InnerSurf[i]).point[0].Y := round(diametr);
    pSurf(InnerSurf[i]).point[1].Y := round(diametr);
  end
  // ���� ���, �� ��������� �����������
  else
  begin
    P1.X := round(pSurf(OutSurf[0]).point[0].X);
    // ����� �� ��� ����� ������
    P2.X := round(pSurf(OutSurf[OutSurf.Count - 1]).point[0].X);
    P1.Y := round(diametr);
    P2.Y := round(diametr);

    Kod_PKDA := -2111;
    Kod_NUSL := 9910;
    Index := 0;
    InsertSurf(2, P1, P2, Index, nomerPovTorec, Kod_PKDA, Kod_NUSL);

  end;
end;

// ������� ������� ������ ������ �� ����� � ����� �� ���� X � Y
// m_metric - �������; m_dx, m_dy - ��������
procedure TSketchView.SetMetric;
var
  len, heig: single;
  lm, hm: single;
begin

  // ��������� ������� ������ �� ������ InputData
  DiamZagot := TInputData.GetDiamZagot;
  LenZagot := TInputData.GetLengthZagot;

  // ��������� ������� ������ �� ������ InputData
  DiamDetal := TInputData.GetDiamDetal;
  LenDetal := TInputData.GetLengthDetal;

  // ��� ����� ������
  len := LenZagot;
  // ��� ������ ������
  heig := DiamZagot;

  lm := ((m_Screen.Right - m_Screen.Left) / m_Zoom) / len;
  hm := ((m_Screen.Bottom - m_Screen.Top) / (m_Zoom)) / heig;
  if lm < hm then
    m_metric := lm
  else
    m_metric := hm;
  // �������� ��� ������
  m_dx := m_Screen.Left + round((m_Screen.Right - m_Screen.Left - len * m_metric) / 2);
  m_dy := (m_Screen.Top + round((m_Screen.Bottom - m_Screen.Top) / 2) - 150);

end;

procedure TSketchView.Resize_Cylinder(currTrans: ptrTrans);
var
  i, j: integer;
  newSize: single;
  PKDA1, PKDA2: integer;
begin
  newSize := currTrans.SizesFromTP[0];
  // ������� ������� ������������� ��������
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).PKDA = 2111) then
    begin

      // �������� ������� ��������� ��������
      pSurf(OutSurf[i]).point[0].Y := round(newSize);
      pSurf(OutSurf[i]).point[1].Y := round(newSize);

      for j := 0 to MainForm.ProcessTrans.m_InputData.listSurface.Count - 1 do
        if ((pSurf(MainForm.ProcessTrans.m_InputData.listSurface[j]).PKDA = 2111)) then
        begin
          PKDA1 := MainForm.ProcessTrans.GetSurfParam(pSurf(MainForm.ProcessTrans.m_InputData.listSurface[j]).L_POVB).PKDA;
          PKDA2 := MainForm.ProcessTrans.GetSurfParam(pSurf(MainForm.ProcessTrans.m_InputData.listSurface[j]).R_POVV).PKDA;
        end;

//      // ���� ������������ ������� ����� �������, ����� �������� ������� ������
//      if (((PKDA1 = 2132) or (PKDA1 = 2131)) and ((PKDA2 = 2132) or (PKDA2 = 2131))) or (OutCon.Count = 0) then
//      begin
//        // �������� ������������ ���������� ������ �����
//        if (pSurf(OutSurf[i - 1]).point[1].Y > pSurf(OutSurf[i - 1]).point[0].Y) then
//          pSurf(OutSurf[i - 1]).point[1].Y := round(newSize)
//        else
//          pSurf(OutSurf[i - 1]).point[0].Y := round(newSize);
//
//        // �������� ������������ ���������� ������� �����
//        if (pSurf(OutSurf[i + 1]).point[1].Y > pSurf(OutSurf[i + 1]).point[0].Y) then
//          pSurf(OutSurf[i + 1]).point[1].Y := round(newSize)
//        else
//          pSurf(OutSurf[i + 1]).point[0].Y := round(newSize);
//
//      end;

    end;
  end;
end;

procedure TSketchView.Resize_Torec(currTrans: ptrTrans);
var
  i, j: integer;
  maxsLenth: single;
  newSize: single;
  Kod_NUSL: integer;
begin

  newSize := currTrans.SizesFromTP[2];
  Kod_NUSL := currTrans.NUSL;

  // ������� ����� ������� �����
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).NUSL = 9907) then
      maxsLenth := pSurf(OutSurf[i]).point[0].X;
  end;

  for i := 0 to OutSurf.Count - 1 do
    if (pSurf(OutSurf[i]).PKDA = 2131) then
      // ���� ��������� ������ �����
      if (pSurf(OutSurf[i]).NUSL = 9907) and (Kod_NUSL = 9907) then
      begin
      //  pSurf(OutSurf[i - 1]).point[1].X := round(newSize);
        pSurf(OutSurf[i]).point[0].X := round(newSize);
        pSurf(OutSurf[i]).point[1].X := round(newSize);

        // ���� �� ����� ��������� ����� �����, �� ���������� �������� ������� � ������� ������� �����
        if (flagPodrezLevTorec) then
        begin
          pSurf(OutSurf[i - 1]).point[1].X := pSurf(OutSurf[i - 1]).point[1].X + round(razmLeftPodrez);
          pSurf(OutSurf[i]).point[0].X := pSurf(OutSurf[i]).point[0].X + round(razmLeftPodrez);
          pSurf(OutSurf[i]).point[1].X := pSurf(OutSurf[i]).point[1].X + round(razmLeftPodrez);
        end;

        // �������� ���������� �����������. ���� ��� ��������� �� �����, �� "�����������"
        for j := 0 to InnerSurf.Count - 1 do
        begin
          if (pSurf(InnerSurf[j]).point[1].X > pSurf(OutSurf[i]).point[1].X) then
            pSurf(InnerSurf[j]).point[1].X := pSurf(OutSurf[i]).point[1].X;
          if (pSurf(InnerSurf[j]).point[0].X > pSurf(OutSurf[i]).point[1].X) then
            pSurf(InnerSurf[j]).point[0].X := pSurf(OutSurf[i]).point[1].X;
        end;

        break;
      end
      // ���� ��������� ����� �����
      else if (pSurf(OutSurf[i]).NUSL = 9901) and (Kod_NUSL = 9901) then
      begin
       // pSurf(OutSurf[i + 1]).point[0].X := round(maxsLenth - newSize);
        pSurf(OutSurf[i]).point[0].X := round(maxsLenth - newSize);
        pSurf(OutSurf[i]).point[1].X := round(maxsLenth - newSize);

        // �������� ���������� �����������.
        for j := 0 to InnerSurf.Count - 1 do
        begin
          if (pSurf(InnerSurf[j]).point[0].X < pSurf(OutSurf[i]).point[0].X) then
            pSurf(InnerSurf[j]).point[0].X := pSurf(OutSurf[i]).point[0].X;

          if (pSurf(InnerSurf[j]).point[1].X < pSurf(OutSurf[i]).point[0].X) then
            pSurf(InnerSurf[j]).point[1].X := pSurf(OutSurf[i]).point[0].X;
        end;

        // ���� �� ��������� ����� �����, �� ���������  ������ �������� �� ���� ����������� ��������� ��������
        flagPodrezLevTorec := true;
        razmLeftPodrez := round(maxsLenth - newSize);

        break;
      end;

end;

procedure TSketchView.CreateFirstSurface;
var
  surface: pSurf;
begin

  // ����������� �1
  new(surface);
  surface.point[0] := TPOINT.Create(0, 0);
  surface.point[1] := TPOINT.Create(0, round(DiamZagot));

  surface.number := 1;
  surface.L_POVB := 0;
  surface.R_POVV := 2;
  surface.PKDA := 2131;
  surface.NUSL := 9901;
  surface.PRIV := 3;
  OutSurf.Add(surface);

  // ����������� �2
  new(surface);
  surface.point[0] := TPOINT.Create(0, round(DiamZagot));
  surface.point[1] := TPOINT.Create(round(LenZagot), round(DiamZagot));
  surface.number := 102;
  surface.L_POVB := 1;
  surface.R_POVV := 3;
  surface.PKDA := 2111;
  surface.NUSL := 9900;
  surface.PRIV := 0;
  OutSurf.Add(surface);

  // ����������� �3
  new(surface);
  surface.point[0] := TPOINT.Create(round(LenZagot), round(DiamZagot));
  surface.point[1] := TPOINT.Create(round(LenZagot), 0);
  surface.number := 103;
  surface.L_POVB := 2;
  surface.R_POVV := 0;
  surface.PKDA := 2131;
  surface.NUSL := 9907;
  surface.PRIV := 1;
  OutSurf.Add(surface);

end;

// ��������� ������������
procedure TSketchView.Draw(canvas: TCanvas);
var
  i: integer;
  point: array[0..1] of TPOINT;
  textCoord: string;
begin

  // // ��������� ����������� ��������������� �� ��������� ����������� ���������
  OutSurf.Sort(Comp);
  // InnerSurfaces.Sort(Comp);
  // �������������� ��������� ������������ ��� ����������� ����������� �� �����
  ConvertingPoint;

  with canvas do
  begin
    // ��������� ������� ������������
    begin
      Pen.Width := 2;
      Pen.Color := clBlack;
      Pen.Style := psSolid;
      font.Name := 'ARIAL';
      font.Height := 10;
      for i := 0 to ScaleOutSurfaces.Count - 1 do
      begin
        point[0] := pSurf(ScaleOutSurfaces[i]).point[0];
        point[1] := pSurf(ScaleOutSurfaces[i]).point[1];

        textCoord := '(' + pSurf(OutSurf[i]).point[0].X.ToString + ', ' + pSurf(OutSurf[i]).point[0].Y.ToString + ' )';
        TextOut( (* ���������� *) point[0].X + 3, point[0].Y + 2, textCoord);

        MoveTo(point[0].X, point[0].Y);
        LineTo(point[1].X, point[1].Y);
      end;
    end;

    // ������ ���
    begin
      Pen.Style := psDot;
      Pen.Width := 1;
      point[1] := pSurf(ScaleOutSurfaces[ScaleOutSurfaces.Count - 1]).point[1];
      point[0] := pSurf(ScaleOutSurfaces[0]).point[0];

      TextOut(point[1].X + 3, point[1].Y + 2,
        (* ����� *) '(' + pSurf(OutSurf[OutSurf.Count - 1]).point[1].X.ToString + ', ' + pSurf(OutSurf[OutSurf.Count - 1]).point[1].Y.ToString + ' )');

      MoveTo(point[1].X, point[1].Y);
      LineTo(point[0].X, point[0].Y);
    end;

    // ������ ���������� ������
    begin
      Pen.Style := psSolid;

      Pen.Color := clBlack;
      Pen.Width := 2;
      if ScaleInSurfaces.Count > 0 then
        // ��������� ���������� ������������
        for i := 0 to ScaleInSurfaces.Count - 1 do
        begin
          point[0] := pSurf(ScaleInSurfaces[i]).point[0];
          point[1] := pSurf(ScaleInSurfaces[i]).point[1];

          TextOut(point[0].X + 3, point[0].Y + 2, '(' + pSurf(InnerSurf[i]).point[0].X.ToString + ', ' + pSurf(InnerSurf[i]).point[0].Y.ToString + ' )');

          MoveTo(point[0].X, point[0].Y);
          LineTo(point[1].X, point[1].Y);
        end;
    end;

    // ������ ������
    begin
      Pen.Style := psSolid;
      Pen.Color := clRed;
      Pen.Width := 2;
      if ScaleOutCon.Count > 0 then
        // ������� �������
        for i := 0 to ScaleOutCon.Count - 1 do
        begin
          point[0] := pSurf(ScaleOutCon[i]).point[0];
          point[1] := pSurf(ScaleOutCon[i]).point[1];

          TextOut(point[0].X - 15, point[0].Y - 25, '(' + pSurf(OutCon[i]).point[0].X.ToString + ', ' + pSurf(OutCon[i]).point[0].Y.ToString + ' )');

          TextOut(point[1].X - 15, point[1].Y - 25, '(' + pSurf(OutCon[i]).point[1].X.ToString + ', ' + pSurf(OutCon[i]).point[1].Y.ToString + ' )');

          MoveTo(point[0].X, point[0].Y);
          LineTo(point[1].X, point[1].Y);
        end;
    end;

  end;

end;

// ������� ����������� �������� ��� ������������ ������
function TSketchView.GetClosedPriv(leftTor: single; flagLeft: boolean): integer;
var
  i, number: integer;
begin

  number := 1;
  // ������� ������ ����������� "������� ��� ��������"
  for i := 0 to OutSurf.Count - 1 do
  begin
    if ((pSurf(OutSurf[i]).PKDA = 2112) or (pSurf(OutSurf[i]).PKDA = 2132)) then
      if ((pSurf(OutSurf[i]).point[1].X >= leftTor) and (pSurf(OutSurf[i]).point[0].X < leftTor)) then
        number := i;
  end;

  Result := number;
end;

function TSketchView.GetInnerSurfPriv(insertDiam: single; flagLeft: boolean): integer;
var
  i, number: integer;
  maxLength: single;
begin

  if (not (flagLeft)) then
    // ������� ������ ����������� "������ �����"
    for i := 0 to OutSurf.Count - 1 do
    begin
      if ((pSurf(OutSurf[i]).PKDA = 2131) and (pSurf(OutSurf[i]).NUSL = 9907)) then
        number := i;
    end
  else
    // ������� ������ ����������� "����� �����"
    for i := 0 to OutSurf.Count - 1 do
    begin
      if ((pSurf(OutSurf[i]).PKDA = 2131) and (pSurf(OutSurf[i]).NUSL = 9901)) then
        number := i;
    end;

  Result := number;
end;

function TSketchView.GetOutsideSurfPriv(insertDiam: single; flagLeft: boolean): integer;
var
  i, numberSurf, numberMaxSurf: integer;
  // true, ���� ������ ������������ �������
  flagMaxDiam: boolean;
begin

  numberSurf := -1;

  // ������� ������ ����������� � ������������ ���������
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).PKDA = 2111) then
      numberMaxSurf := i;
  end;

  flagMaxDiam := false;
  for i := 0 to OutSurf.Count - 1 do
  begin

    // ������������ ����� ������������� ��������
    if (pSurf(OutSurf[i]).PKDA = 2111) then
      flagMaxDiam := true;

    // ���� ����������� ����� ������ � ��������� ����� ������������� ��������
    if ((flagMaxDiam) and (not (flagLeft))) then
    begin
      if (pSurf(OutSurf[i]).PKDA = 2112) and (pSurf(OutSurf[i]).point[0].Y >= insertDiam) then
      begin
        numberSurf := i;
        // � ����� �� ������� �� ����� ������-��
        // break;
      end;
    end;

    // ���� ����������� ����� ����� � ��������� �� ������������� ��������
    if (not (flagMaxDiam) and (flagLeft)) then
    begin
      if (pSurf(OutSurf[i]).PKDA = 2112) and (pSurf(OutSurf[i]).point[0].Y > insertDiam) then
      begin
        numberSurf := i;
        // ���� ����� �������, ��������������� �������, �� ����� ������� �� �����
        break;
      end;
    end;
  end;

  if (numberSurf = -1) then
    Result := numberMaxSurf
  else
    Result := numberSurf;
end;

end.

