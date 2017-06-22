unit SketchView;

interface

uses Windows, Graphics, Dialogs, Generics.Collections, Generics.Defaults,
  // ��� ������ �������� ���������
  InputData,
  SysUtils, Classes;

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

  protected
    // ����������(���� � ��������� ���� ������)
    m_Zoom: real;

    // ������ �������� ������������
    OutsideSurfaces: TList;
    // ������ ���������� ������������
    InnerSurfaces: TList;
    // ������ ��������  ������������ � �������������������� ������������
    ScaleSurfaces: TList;
    // ������ ��������  ������������ � �������������������� ������������
    InnerScaleSurfaces: TList;

    // ������� ���������
    DiamZagot, LenZagot: single;

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

    // ������� �������� ������������ ������������ (������)
    procedure Insert_OutsideHalfopenSurfaces(currTrans: ptrTrans;
      flagLeft: boolean; nomerPriv: integer = 0; nomerPov: integer = 0;
      podrezTorec: single = 0; tochitPover: single = 0);

    // ������� ����������� ��������� �������� (�����)
    procedure Insert_OpenInnerCylinder(currentTransition: ptrTrans;
      nomerPovTorec: integer; diametr: single);

    // ������� ���������� ������������ ������������ (�������)
    procedure Insert_InnerHalfopenSurfaces(currTrans: ptrTrans;
      flagLeft: boolean; nomerPovTorec: integer = 0; podrezTorec: single = 0;
      tochitPover: single = 0);

    // ��������� ������� ������ ��� ������� �����
    procedure Resize_Torec(newSize: single; Uslov_kod_pover_A_NUSL: integer);

  private
    // �������������� ��������� ������������ � ������ �������� � ��������
    procedure ConvertingPoint;

    // ������� ������ ����������� � listSurfaces � ������� �������������, ����� �������� ������
    function GetOutsideSurfPriv(insertDiam: single; flagLeft: boolean): integer;

    // ������� -//- , ����� ���������� �����
    function GetInnetSurfPriv(insertDiam: single; flagLeft: boolean): integer;

    // ��������� ������� �����������
    procedure InsertSurf(flagOutsideSurf: boolean;
      X1, X2, Y1, Y2, Index, number, Kod_PKDA, Kod_NUSL: integer);
  end;

implementation

function Comp(Item1, Item2: Pointer): integer;
// � ������� ���� ������� �����������	���������� ������������ �� ���������� X
begin
  if ((pSurf(Item1).point[0].X) + (pSurf(Item1).point[1].X)) <
    ((pSurf(Item2).point[0].X) + (pSurf(Item2).point[1].X)) then
    Result := -1
  else if ((pSurf(Item1).point[0].X) + (pSurf(Item1).point[1].X)) >
    ((pSurf(Item2).point[0].X) + (pSurf(Item2).point[1].X)) then
    Result := 1
  else
    Result := 0
end;

// �����������
procedure TSketchView.Clear;
var
  i: integer;
  surface1: pSurf;
begin
  OutsideSurfaces.Clear;

  InnerSurfaces.Clear;

  InnerScaleSurfaces.Clear;

  ScaleSurfaces.Clear;
  for i := 0 to 2 do
  begin
    surface1 := nil;
    new(surface1);
    ScaleSurfaces.Add(surface1);
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
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    // �������������� ������  � ������ ����� ����������
    for j := 0 to 1 do
    begin
      if (pSurf(OutsideSurfaces[i]).point[j].X = 0) then
        pSurf(ScaleSurfaces[i]).point[j].X := round(m_dx)
      else
        pSurf(ScaleSurfaces[i]).point[j].X :=
          round((m_dx + pSurf(OutsideSurfaces[i]).point[j].X * m_metric));

      if (pSurf(OutsideSurfaces[i]).point[j].Y = 0) then
        pSurf(ScaleSurfaces[i]).point[j].Y := round(m_dy)
      else
        pSurf(ScaleSurfaces[i]).point[j].Y :=
          round((m_dy + pSurf(OutsideSurfaces[i]).point[j].Y * m_metric));

    end;

  end;

  // ������ ���� ����������  ������������
  for i := 0 to InnerScaleSurfaces.Count - 1 do
    // �������������� ������  � ������ ����� ����������
    for j := 0 to 1 do
    begin
      if (pSurf(InnerSurfaces[i]).point[j].X = 0) then
        pSurf(InnerScaleSurfaces[i]).point[j].X := round(m_dx)
      else
        pSurf(InnerScaleSurfaces[i]).point[j].X :=
          round((m_dx + pSurf(InnerSurfaces[i]).point[j].X * m_metric));

      if (pSurf(InnerSurfaces[i]).point[j].Y = 0) then
        pSurf(InnerScaleSurfaces[i]).point[j].Y := round(m_dy)
      else
        pSurf(InnerScaleSurfaces[i]).point[j].Y :=
          round((m_dy + pSurf(InnerSurfaces[i]).point[j].Y * m_metric));

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
  OutsideSurfaces := TList.Create;
  InnerSurfaces := TList.Create;
  InnerScaleSurfaces := TList.Create;
  ScaleSurfaces := TList.Create;
  for i := 0 to 2 do
  begin
    surface1 := nil;
    new(surface1);
    ScaleSurfaces.Add(surface1);
  end;

  flagPodrezLevTorec := false;
  razmLeftPodrez := 0;
end;

procedure TSketchView.Insert_OutsideHalfopenSurfaces(currTrans: ptrTrans;
  flagLeft: boolean; nomerPriv: integer; nomerPov: integer;
  podrezTorec, tochitPover: single);
var
  surface, surface1: pSurf;
  Id: integer;
  X1, X2, Y1, Y2: integer;
  Index: integer;
  number, Kod_PKDA, Kod_NUSL: integer;
  // ����� ����������� �����������
  numPriv: integer;
begin

  numPriv := currTrans.PRIV;
  // �����   �������� ��������� ��� ������ "������-���������"
  if (nomerPov = 0) then
  begin
    // �������� �������
    podrezTorec := currTrans.SizesFromTP[2];
    tochitPover := currTrans.SizesFromTP[0];
    nomerPov := currTrans.NPVA;

    numPriv := nomerPriv;
  end;

  // ��������� ������ �����������-��������, � �������� ����� ����������� ������
  Id := GetOutsideSurfPriv(tochitPover, flagLeft);

  // ��������� ����������� ������
  if (not(flagLeft)) then
  begin
    // ����� ��������� ����� ����� �� �������� "������-���������",
    // �� ������ �������� ������������� �� �������� ������ �����

    // ��������� ������ ������������ �����
    begin
      // ����� ������ �������� �� ����� 1(�� �������� � ������ �����)
      if (numPriv <> 1) then
      begin
        X1 := round(pSurf(OutsideSurfaces[Id + 1]).point[1].X - podrezTorec);
        X2 := X1;
      end
      else
      begin
        X1 := round(podrezTorec);
        X2 := X1;
      end;
      Y1 := round(pSurf(OutsideSurfaces[Id]).point[1].Y);
      Y2 := round(tochitPover);
      Kod_PKDA := 2132;
      Kod_NUSL := 9905;
      Index := Id + 1;
      InsertSurf(true, X1, X2, Y1, Y2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
      // � �������� ������� ��������, ������� ����� ����������� ������
      pSurf(OutsideSurfaces[Id]).point[1].X := X1;
    end;

    // ��������� ������ ������������ �������
    begin
      if (numPriv <> 1) then
        X1 := round(pSurf(OutsideSurfaces[Id + 2]).point[1].X - podrezTorec)
      else
        X1 := round(podrezTorec);

      X2 := round(pSurf(OutsideSurfaces[Id + 2]).point[1].X);
      Y1 := round(tochitPover);
      Y2 := round(tochitPover);
      Kod_PKDA := 2112;
      number := nomerPov + 1;
      Kod_NUSL := 9906;
      Index := Id + 2;
      InsertSurf(true, X1, X2, Y1, Y2, Index, number, Kod_PKDA, Kod_NUSL);
      // �������� ������ �����, ������� ���� �� ����������� ���������
      pSurf(OutsideSurfaces[Id + 3]).point[0].Y := Y2;
    end;
  end

  else // �����
  begin
    // ��������� ����� ������������ �������
    begin
      X1 := round(pSurf(OutsideSurfaces[Id]).point[0].X);
      if (numPriv <> 1) then
      begin
        X2 := round(pSurf(OutsideSurfaces[Id]).point[0].X + podrezTorec);
      end
      else
      begin
        X2 := round(podrezTorec);
      end;
      Y1 := round(tochitPover);
      Y2 := round(tochitPover);
      Kod_PKDA := 2112;
      Kod_NUSL := 9902;
      Index := Id + 1;
      InsertSurf(true, X1, X2, Y1, Y2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
      // �������� ������ �����, ������� ���� ��  ������������ ��������
      pSurf(OutsideSurfaces[Id - 1]).point[1].Y := Y1;
    end;

    // ��������� ����� ������������ �����
    begin
      if (numPriv <> 1) then
      begin
        X1 := round(pSurf(OutsideSurfaces[Id]).point[0].X + podrezTorec);
        X2 := X1;
      end
      else
      begin
        X1 := round(podrezTorec);
        X2 := X1;
      end;
      // ���� ��������� ����� �����
      if (flagPodrezLevTorec) then
      begin
        X1 := X1 + round(razmLeftPodrez);
        X2 := X1;
        pSurf(OutsideSurfaces[Id + 1]).point[1].X := X1;
        pSurf(OutsideSurfaces[Id]).point[0].X := X1;
      end;
      Y1 := round(tochitPover);
      Y2 := round(pSurf(OutsideSurfaces[Id]).point[0].Y);
      number := nomerPov - 1;
      Kod_PKDA := 2132;
      Kod_NUSL := 9903;

      InsertSurf(true, X1, X2, Y1, Y2, Id, number, Kod_PKDA, Kod_NUSL);

      // �������� ������ ��������, ������� ���� �����  ������������ �����
      pSurf(OutsideSurfaces[Id + 1]).point[0].X := X1;
    end;

  end; // ��������� else
end;

procedure TSketchView.InsertSurf(flagOutsideSurf: boolean;
  X1, X2, Y1, Y2, Index, number, Kod_PKDA, Kod_NUSL: integer);
var
  surface, surfNil: pSurf;
begin
  new(surface);
  surface.point[0].X := X1;
  surface.point[1].X := X2;
  surface.point[0].Y := Y1;
  surface.point[1].Y := Y2;
  surface.number := number;
  // surface.Nomer_Pover_L_POVB := 0;
  // surface.Nomer_Pover_R_POVV := 2;
  surface.PKDA := Kod_PKDA;
  surface.NUSL := Kod_NUSL;
  // surface.Nomer_Pover_PRIV := 3;
  // ����� ����������� ���������: �������� ��� ����������

  new(surfNil);
  if (flagOutsideSurf) then
  begin
    OutsideSurfaces.Insert(Index, surface);
    ScaleSurfaces.Add(surfNil);
  end
  else
  begin
    InnerSurfaces.Add(surface);
    InnerScaleSurfaces.Add(surfNil);
  end;
end;

procedure TSketchView.Insert_InnerHalfopenSurfaces(currTrans: ptrTrans;
  flagLeft: boolean; nomerPovTorec: integer = 0; podrezTorec: single = 0;
  tochitPover: single = 0);
var
  i: integer;
  surface, surface1: pSurf;
  Id: integer;
  X1, X2, Y1, Y2: integer;
  Index: integer;
  number, Kod_Pover_A_PKDA, Uslov_kod_pover_A_NUSL: integer;

  existInnerHalfopenCylinder: boolean;
begin

  if (nomerPovTorec = 0) then
  begin
    podrezTorec := currTrans.SizesFromTP[1];
    tochitPover := currTrans.SizesFromTP[0];
    nomerPovTorec := currTrans.NPVA;
  end;

  // ����� ��������� �� �������� ������ ����� ���� ����� ������� 5. �.�. � ������� Round
  // ���������� ���������� ���������� �������, ��� ������ �������� �������� �������� ���������� � ������� �����
  if (Frac(podrezTorec) <= 0.5) then
    podrezTorec := podrezTorec + 0.1;
  if (Frac(tochitPover) <= 0.5) then
    tochitPover := tochitPover + 0.1;

  // ��������� ������ �����������-��������, � �������� ����� ����������� ������
  Id := GetInnetSurfPriv(tochitPover, flagLeft);

  existInnerHalfopenCylinder := false;

  // ���������, ���� �� ��� ���������� �����
  // (���� ����� �������������� ����������� ��� ���������� �� ���������� ������������ ������)
  for i := 0 to InnerSurfaces.Count - 1 do
  begin
    if (pSurf(InnerSurfaces[i]).number = nomerPovTorec) then
    begin
      existInnerHalfopenCylinder := true;
      break;
    end;
  end;

  if (not(flagLeft)) then // ��������� ����������� ������
  begin
    // ��������� ������ ���������� ������������ �������
    begin

      X1 := round(pSurf(OutsideSurfaces[Id]).point[0].X);
      X2 := round(pSurf(OutsideSurfaces[Id]).point[0].X - podrezTorec);
      Y1 := round(tochitPover);
      Y2 := round(tochitPover);
      Kod_Pover_A_PKDA := -2112;
      Uslov_kod_pover_A_NUSL := 9912;
      Index := Id + 1;
      // ���� ��, �� �������� ���� �������
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurfaces[i]).point[0].X := X1;
        pSurf(InnerSurfaces[i]).point[1].X := X2;
        pSurf(InnerSurfaces[i]).point[0].Y := Y1;
        pSurf(InnerSurfaces[i]).point[1].Y := Y2;
      end
      // ���� ���, �� ��������� �����������
      else
        InsertSurf(false, X1, X2, Y1, Y2, Index, nomerPovTorec,
          Kod_Pover_A_PKDA, Uslov_kod_pover_A_NUSL);
    end;

    // ��������� ������ ���������� ������������ �����
    begin

      X1 := round(pSurf(OutsideSurfaces[Id]).point[0].X - podrezTorec);
      X2 := round(pSurf(OutsideSurfaces[Id]).point[0].X - podrezTorec);
      Y1 := round(tochitPover);
      Y2 := 0;
      Kod_Pover_A_PKDA := -2132;
      number := nomerPovTorec + 1;
      Uslov_kod_pover_A_NUSL := 9913;
      Index := Id + 1;
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurfaces[i]).point[0].X := X1;
        pSurf(InnerSurfaces[i]).point[1].X := X2;
        pSurf(InnerSurfaces[i]).point[0].Y := Y1;
        pSurf(InnerSurfaces[i]).point[1].Y := Y2;
      end
      else
        InsertSurf(false, X1, X2, Y1, Y2, Index, number, Kod_Pover_A_PKDA,
          Uslov_kod_pover_A_NUSL);
    end;
  end // ��������� "if ((flagLeft)).."

  else // ��������� ����������� �����
  begin

    // ��������� ����� ���������� ������������ �������
    begin
      X1 := round(pSurf(OutsideSurfaces[0]).point[0].X);
      X2 := round(pSurf(OutsideSurfaces[0]).point[0].X + podrezTorec);
      Y1 := round(tochitPover);
      Y2 := round(tochitPover);
      Kod_Pover_A_PKDA := -2112;
      Uslov_kod_pover_A_NUSL := 9912;
      Index := Id + 1;
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurfaces[i]).point[0].X := X1;
        pSurf(InnerSurfaces[i]).point[1].X := X2;
        pSurf(InnerSurfaces[i]).point[0].Y := Y1;
        pSurf(InnerSurfaces[i]).point[1].Y := Y2;
      end
      else
        InsertSurf(false, X1, X2, Y1, Y2, Index, nomerPovTorec,
          Kod_Pover_A_PKDA, Uslov_kod_pover_A_NUSL);
    end;

    // ��������� ����� ���������� ������������ �����
    begin
      X1 := round(pSurf(OutsideSurfaces[0]).point[0].X + podrezTorec);
      X2 := round(pSurf(OutsideSurfaces[0]).point[0].X + podrezTorec);
      Y1 := round(tochitPover);
      Y2 := 0;
      Kod_Pover_A_PKDA := -2132;
      number := nomerPovTorec + 1;
      Uslov_kod_pover_A_NUSL := 9913;
      Index := Id + 1;
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurfaces[i + 1]).point[0].X := X1;
        pSurf(InnerSurfaces[i + 1]).point[1].X := X2;
        pSurf(InnerSurfaces[i + 1]).point[0].Y := Y1;
        pSurf(InnerSurfaces[i + 1]).point[1].Y := Y2;
      end
      else
        InsertSurf(false, X1, X2, Y1, Y2, Index, number, Kod_Pover_A_PKDA,
          Uslov_kod_pover_A_NUSL);
    end;

  end;

  i := InnerSurfaces.Count;

  // �������� ������� ���������� ��������� � �������� ����������
  while i <> 0 do
  begin
    i := i - 1;
    if ((pSurf(InnerSurfaces[i]).PKDA = -2112) and
      (pSurf(InnerSurfaces[i]).point[0].Y < Y1)) then
    begin
      case flagLeft of
        true:
          pSurf(InnerSurfaces[i]).point[0].X := X2;
        false:
          pSurf(InnerSurfaces[i]).point[0].X := X1;
      end;
      break;
    end;

    if ((pSurf(InnerSurfaces[i]).PKDA = -2111) and
      (pSurf(InnerSurfaces[i]).point[0].Y < Y1)) then
    begin
      case flagLeft of
        true:
          pSurf(InnerSurfaces[i]).point[0].X := X2;
        false:
          pSurf(InnerSurfaces[i]).point[1].X := X1;
      end;
      break;
    end;
  end;

end;

procedure TSketchView.Insert_OpenInnerCylinder(currentTransition: ptrTrans;
  nomerPovTorec: integer; diametr: single);
var
  i: integer;
  surface, surface1: pSurf;
  existInnerOpenCylinder: boolean;
  X1, X2, Y1, Y2: integer;
  Index: integer;
  Kod_Pover_A_PKDA, Uslov_kod_pover_A_NUSL: integer;

begin

  existInnerOpenCylinder := false;

  // ���������, ���� �� ��� ���������� �������� �������
  for i := 0 to InnerSurfaces.Count - 1 do
  begin
    if (pSurf(InnerSurfaces[i]).NUSL = 9910) then
    begin
      existInnerOpenCylinder := true;
      break;
    end;
  end;

  // ���� ��, �� �������� ���� �������
  if (existInnerOpenCylinder) then
  begin
    pSurf(InnerSurfaces[i]).point[0].Y := round(diametr);
    pSurf(InnerSurfaces[i]).point[1].Y := round(diametr);
  end
  // ���� ���, �� ��������� �����������
  else
  begin

    X1 := round(pSurf(OutsideSurfaces[0]).point[0].X);
    // ����� �� ��� ����� ������
    X2 := round(pSurf(OutsideSurfaces[OutsideSurfaces.Count - 1]).point[0].X);
    Y1 := round(diametr);
    Y2 := round(diametr);

    Kod_Pover_A_PKDA := -2111;
    Uslov_kod_pover_A_NUSL := 9910;
    Index := 0;
    InsertSurf(false, X1, X2, Y1, Y2, Index, nomerPovTorec, Kod_Pover_A_PKDA,
      Uslov_kod_pover_A_NUSL);

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
  m_dx := m_Screen.Left +
    round((m_Screen.Right - m_Screen.Left - len * m_metric) / 2);
  m_dy := (m_Screen.Top + round((m_Screen.Bottom - m_Screen.Top) / 2) - 150);

end;

procedure TSketchView.Resize_Torec(newSize: single;
  Uslov_kod_pover_A_NUSL: integer);
var
  i, j: integer;
  maxsLenth: single;
begin

  // ������� ����� ������� �����
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    if (pSurf(OutsideSurfaces[i]).NUSL = 9907) then
      maxsLenth := pSurf(OutsideSurfaces[i]).point[0].X;
  end;

  for i := 0 to OutsideSurfaces.Count - 1 do
    if (pSurf(OutsideSurfaces[i]).PKDA = 2131) then
      // ���� ��������� ������ �����
      if (pSurf(OutsideSurfaces[i]).NUSL = 9907) and
        (Uslov_kod_pover_A_NUSL = 9907) then
      begin
        pSurf(OutsideSurfaces[i - 1]).point[1].X := round(newSize);
        pSurf(OutsideSurfaces[i]).point[0].X := round(newSize);
        pSurf(OutsideSurfaces[i]).point[1].X := round(newSize);

        // �������� ���������� �����������
        for j := 0 to InnerSurfaces.Count - 1 do
        begin
          if (pSurf(InnerSurfaces[j]).point[0].X > round(newSize)) then
            pSurf(InnerSurfaces[j]).point[0].X := round(newSize);

          if (pSurf(InnerSurfaces[j]).point[1].X > round(newSize)) then
            pSurf(InnerSurfaces[j]).point[1].X := round(newSize);
        end;

        // ���� �� ����� ��������� ����� �����, �� ���������� �������� ������� � ������� ������� �����
        if (flagPodrezLevTorec) then
        begin
          pSurf(OutsideSurfaces[i - 1]).point[1].X :=
            pSurf(OutsideSurfaces[i - 1]).point[1].X + round(razmLeftPodrez);
          pSurf(OutsideSurfaces[i]).point[0].X := pSurf(OutsideSurfaces[i])
            .point[0].X + round(razmLeftPodrez);
          pSurf(OutsideSurfaces[i]).point[1].X := pSurf(OutsideSurfaces[i])
            .point[1].X + round(razmLeftPodrez);
        end;
        break;
      end
      // ���� ��������� ����� �����
      else if (pSurf(OutsideSurfaces[i]).NUSL = 9901) and
        (Uslov_kod_pover_A_NUSL = 9901) then
      begin
        pSurf(OutsideSurfaces[i + 1]).point[0].X := round(maxsLenth - newSize);
        pSurf(OutsideSurfaces[i]).point[0].X := round(maxsLenth - newSize);
        pSurf(OutsideSurfaces[i]).point[1].X := round(maxsLenth - newSize);

        // �������� ���������� �����������
        for j := 0 to InnerSurfaces.Count - 1 do
        begin
          if (pSurf(InnerSurfaces[j]).point[0].X < round(maxsLenth - newSize))
          then
            pSurf(InnerSurfaces[j]).point[0].X := round(maxsLenth - newSize);

          if (pSurf(InnerSurfaces[j]).point[1].X < round(maxsLenth - newSize))
          then
            pSurf(InnerSurfaces[j]).point[1].X := round(maxsLenth - newSize);
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
  surface.point[0].X := 0;
  surface.point[0].Y := 0;
  surface.point[1].X := 0;
  surface.point[1].Y := round(DiamZagot);
  surface.number := 1;
  surface.L_POVB := 0;
  surface.R_POVV := 2;
  surface.PKDA := 2131;
  surface.NUSL := 9901;
  surface.PRIV := 3;
  OutsideSurfaces.Add(surface);

  // ����������� �2
  new(surface);
  surface.point[0].X := 0;
  surface.point[0].Y := round(DiamZagot);
  surface.point[1].X := round(LenZagot);
  surface.point[1].Y := round(DiamZagot);
  surface.number := 2;
  surface.L_POVB := 1;
  surface.R_POVV := 3;
  surface.PKDA := 2111;
  surface.NUSL := 9900;
  surface.PRIV := 0;
  OutsideSurfaces.Add(surface);

  // ����������� �3
  new(surface);
  surface.point[0].X := round(LenZagot);
  surface.point[0].Y := round(DiamZagot);
  surface.point[1].X := round(LenZagot);
  surface.point[1].Y := 0;
  surface.number := 3;
  surface.L_POVB := 2;
  surface.R_POVV := 0;
  surface.PKDA := 2131;
  surface.NUSL := 9907;
  surface.PRIV := 1;
  OutsideSurfaces.Add(surface);

end;

// ��������� ������������
procedure TSketchView.Draw(canvas: TCanvas);
var
  i: integer;
  point: array [0 .. 1] of TPOINT;
  textCoord: string;
begin

  // ��������� ����������� ��������������� �� ��������� ����������� ���������
  OutsideSurfaces.Sort(Comp);
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
      for i := 0 to ScaleSurfaces.Count - 1 do
      begin
        point[0].X := pSurf(ScaleSurfaces[i]).point[0].X;
        point[0].Y := pSurf(ScaleSurfaces[i]).point[0].Y;
        point[1].X := pSurf(ScaleSurfaces[i]).point[1].X;
        point[1].Y := pSurf(ScaleSurfaces[i]).point[1].Y;

        textCoord := '(' + pSurf(OutsideSurfaces[i]).point[0].X.tostring + ', '
          + pSurf(OutsideSurfaces[i]).point[0].Y.tostring + ' )';
        TextOut( (* ���������� *) point[0].X + 3, point[0].Y + 2, textCoord);

        MoveTo(point[0].X, point[0].Y);
        LineTo(point[1].X, point[1].Y);
      end;
    end;

    // ������ ���
    begin
      Pen.Style := psDot;
      Pen.Width := 1;
      point[1].X := pSurf(ScaleSurfaces[ScaleSurfaces.Count - 1]).point[1].X;
      point[1].Y := pSurf(ScaleSurfaces[ScaleSurfaces.Count - 1]).point[1].Y;
      point[0].X := pSurf(ScaleSurfaces[0]).point[0].X;
      point[0].Y := pSurf(ScaleSurfaces[0]).point[0].Y;

      TextOut(point[1].X + 3, point[1].Y + 2,
        (* ����� *) '(' + pSurf(OutsideSurfaces[OutsideSurfaces.Count - 1])
        .point[1].X.tostring + ', ' +
        pSurf(OutsideSurfaces[OutsideSurfaces.Count - 1])
        .point[1].Y.tostring + ' )');

      MoveTo(point[1].X, point[1].Y);
      LineTo(point[0].X, point[0].Y);
    end;

    // ������ ���������� ������
    begin
      Pen.Style := psSolid;
      Pen.Width := 2;
      if InnerScaleSurfaces.Count > 0 then
        // ��������� ���������� ������������
        for i := 0 to InnerScaleSurfaces.Count - 1 do
        begin
          point[0].X := pSurf(InnerScaleSurfaces[i]).point[0].X;
          point[0].Y := pSurf(InnerScaleSurfaces[i]).point[0].Y;
          point[1].X := pSurf(InnerScaleSurfaces[i]).point[1].X;
          point[1].Y := pSurf(InnerScaleSurfaces[i]).point[1].Y;

          TextOut(point[0].X + 3, point[0].Y + 2, '(' + pSurf(InnerSurfaces[i])
            .point[0].X.tostring + ', ' + pSurf(InnerSurfaces[i])
            .point[0].Y.tostring + ' )');

          MoveTo(point[0].X, point[0].Y);
          LineTo(point[1].X, point[1].Y);
        end;
    end;

  end;

end;

// ������� ����������� �������� ��� ������������ ������
function TSketchView.GetInnetSurfPriv(insertDiam: single;
  flagLeft: boolean): integer;
var
  i, number: integer;
  maxLength: single;
  // true, ���� ������ ������������ �������
  // flagMaxDiam: boolean;
begin

  if (not(flagLeft)) then
    // ������� ������ ����������� "������ �����"
    for i := 0 to OutsideSurfaces.Count - 1 do
    begin
      if ((pSurf(OutsideSurfaces[i]).PKDA = 2131) and
        (pSurf(OutsideSurfaces[i]).NUSL = 9907)) then
        number := i;
    end
  else
    // ������� ������ ����������� "����� �����"
    for i := 0 to OutsideSurfaces.Count - 1 do
    begin
      if ((pSurf(OutsideSurfaces[i]).PKDA = 2131) and
        (pSurf(OutsideSurfaces[i]).NUSL = 9901)) then
        number := i;
    end;

  Result := number;

end;

function TSketchView.GetOutsideSurfPriv(insertDiam: single;
  flagLeft: boolean): integer;
var
  i, numberSurf, numberMaxSurf: integer;
  // true, ���� ������ ������������ �������
  flagMaxDiam: boolean;
begin

  numberSurf := -1;

  // ������� ������ ����������� � ������������ ���������
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    if (pSurf(OutsideSurfaces[i]).PKDA = 2111) then
      numberMaxSurf := i;
  end;

  flagMaxDiam := false;
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin

    // ������������ ����� ������������� ��������
    if (pSurf(OutsideSurfaces[i]).PKDA = 2111) then
      flagMaxDiam := true;

    // ���� ����������� ����� ������ � ��������� ����� ������������� ��������
    if ((flagMaxDiam) and (not(flagLeft))) then
    begin
      if (pSurf(OutsideSurfaces[i]).PKDA = 2112) and
        (pSurf(OutsideSurfaces[i]).point[0].Y > insertDiam) then
      begin
        numberSurf := i;
        // � ����� �� ������� �� ����� ������-��
        // break;
      end;
    end;

    // ���� ����������� ����� ����� � ��������� �� ������������� ��������
    if (not(flagMaxDiam) and (flagLeft)) then
    begin
      if (pSurf(OutsideSurfaces[i]).PKDA = 2112) and
        (pSurf(OutsideSurfaces[i]).point[0].Y > insertDiam) then
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
