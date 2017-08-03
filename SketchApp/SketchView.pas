unit SketchView;

interface

uses
  Windows, Graphics, Dialogs,
  // для чтения размеров заготовки
  InputData, SysUtils, Classes;

type

  // Класс овечает за формирование внутреннего и внешнего контуров эскизов
  // в виде массива точек и за вывод их на экран
  TSketchView = class
  private
    flagPodrezLevTorec: boolean;
    razmLeftPodrez: single;
  public
    // Экранные размеры
    m_Screen: TRECT;
    // Смещение по оси Х и У при выводе детали
    m_dx, m_dy: integer;
    // Маштаб
    m_metric: single;

    // Массив наружных поверхностей
    OutSurf: TList;
    // Массив наружных поверхностей
    OutCon: TList;
    // Массив внутренних поверхностей
    InnerSurf: TList;
  protected
    // Увеличение(тоже в некотором роде маштаб)
    m_Zoom: real;

    // Массив наружных  поверхностей с промасштабированными координатами
    ScaleOutSurfaces: TList;
    // Массив наружных  поверхностей с промасштабированными координатами
    ScaleInSurfaces: TList;
    ScaleOutCon: TList;
    // Размеры заготовки
    DiamZagot, LenZagot: single;
    // Размеры детали
    DiamDetal, LenDetal: single;
  public
    // конструктор
    constructor Create;
    // установка масштаба для эскиза
    procedure SetMetric;
    // Вывод кривых на экран
    procedure Draw(canvas: TCanvas);
    // Создание поверхностей заготовки
    procedure CreateFirstSurface;
    // Очистка данных
    procedure Clear;

    // Вставка закрытого цилиндра
    procedure Insert_OutClosedSurf(currTrans: ptrTrans; flagLeft: boolean; numPrivLeft, numPrivRight: integer; leftTor, diamClosedCyl, lengthClosedCylindr, rightTorec, diamHalfopenedCyl, lengthHalfopenedCyl: single);

    // Вставка наружных полуоткрытых поверхностей (выемок)
    procedure Insert_OutHalfopenSurf(currTrans: ptrTrans; flagLeft: boolean; nomerPov: integer = 0; podrezTorec: single = 0; tochitPover: single = 0; faceOfReference: integer = 1);

    // Вставка наружных конусов
    procedure Insert_OutCon(currTrans: ptrTrans; flagLeft: boolean; P1, P2: TPOINT; faceOfReference: integer);
    // Вставка  конуса
    procedure Insert_Con(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);

    // Вставка  цилиндра
    procedure Insert_Cyl(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);

    // Вставка  цилиндра
    procedure Insert_Tor(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);

    // Вставка внутреннего открытого цилиндра (вырез)
    procedure Insert_InOpenCyl(currentTransition: ptrTrans; nomerPovTorec: integer; diametr: single);

    // Вставка внутренних полуоткрытых поверхностей (вырезов)
    procedure Insert_InHalfopenSurf(currTrans: ptrTrans; flagLeft: boolean; nomerPov: integer = 0; podrezTorec: single = 0; tochitPover: single = 0);

    // изменение размера левого или правого торца
    procedure Resize_Torec(currTrans: ptrTrans);

    // изменение размера цилиндра
    procedure Resize_Cylinder(currTrans: ptrTrans);
  private

    // Преобразование координат поверхностей с учетом смещений и масштаба
    procedure ConvertingPoint;

    // Находим индекс поверхности в listSurfaces к которой привязываемся, делая наружную выемку
    function GetOutsideSurfPriv(insertDiam: single; flagLeft: boolean): integer;

    // Находим -//- , делая внутренний вырез
    function GetInnerSurfPriv(insertDiam: single; flagLeft: boolean): integer;

    // Находим -//- , делая внутренний вырез
    function GetClosedPriv(leftTor: single; flagLeft: boolean): integer;

    // Процедура вставки поверхности
    procedure InsertSurf(flagSurf: integer; P1, P2: TPOINT; Index, number, Kod_PKDA, Kod_NUSL: integer);
  end;

implementation

uses
  SketchForm;

function Comp(Item1, Item2: Pointer): integer;
// С помощью этой функции реализуется	сортировка поверхностей по координате X
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

  // Проход всех наружных поверхностей
  for i := 0 to OutSurf.Count - 1 do
  begin
    // Преобразование первой  и второй точки поверхости
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

  // Проход всех внутренних  поверхностей
  for i := 0 to InnerSurf.Count - 1 do
    // Преобразование первой  и второй точки поверхости
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

  // Проход конусов
  for i := 0 to OutCon.Count - 1 do
    // Преобразование первой  и второй точки поверхости
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

  // вычисляем индекс поверхности-цилиндра, к которой будем привязывать выемку
  // на основе диаметра вставляемого цилиндра
  Id := GetOutsideSurfPriv(diamClosedCyl, flagLeft);
  nomerPov := currTrans.NPVA;

  existOutClosedCylinder := false;

  // проверяем, есть ли уже внутренний вырез
  // (если номер обрабатываемой поверхности уже существует в поверхностях эскиза)
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).number = nomerPov) then
    begin
      existOutClosedCylinder := true;
      i_existClosedCylinder := i;
      break;
    end;
  end;

  // находим размер привязки  и координату X левого торца
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).NUSL = 9907) then
      lengthDet := pSurf(OutSurf[i]).point[0].X;

    if (pSurf(OutSurf[i]).NUSL = 9901) then
      leftTorDet := pSurf(OutSurf[i]).point[0].X;
  end;

  if (not (flagLeft)) then
  begin

    // Вставляем левый полуоткрытый торец
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

      // если да, то изменяем лишь размеры
      if (existOutClosedCylinder) then
      begin
        pSurf(OutSurf[i_existClosedCylinder - 1]).point[0] := P1;
        pSurf(OutSurf[i_existClosedCylinder - 1]).point[1].X := P2.X;
        // И изменяем размеры цилиндра, который перед вставленным торцем
        pSurf(OutSurf[i_existClosedCylinder - 2]).point[1].X := P1.X;
      end
      // если нет, то вставляем поверхность
      else
      begin
        InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
        // И изменяем размеры цилиндра, который перед вставленным торцем
        pSurf(OutSurf[Id]).point[1].X := P1.X;
      end;

    end;

    // Вставляем закрытый цилиндр
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

      // если да, то изменяем лишь размеры
      if (existOutClosedCylinder) then
      begin
        pSurf(OutSurf[i_existClosedCylinder]).point[0] := P1;
        pSurf(OutSurf[i_existClosedCylinder]).point[1] := P2;
      end
      // если нет, то вставляем поверхность
      else
        InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
    end;

    // Вставляем правый полуоткрытый торец
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

      // если да, то изменяем лишь размеры
      if (existOutClosedCylinder) then
      begin
        pSurf(OutSurf[i_existClosedCylinder + 1]).point[0] := P1;
        pSurf(OutSurf[i_existClosedCylinder + 1]).point[1] := P2;
      end
      // если нет, то вставляем поверхность
      else
        InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
    end;

    // Вставляем правый полуоткрытый цилиндр
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

      // если да, то изменяем лишь размеры
      if (existOutClosedCylinder) then
      begin
        pSurf(OutSurf[i_existClosedCylinder + 2]).point[0] := P1;
        pSurf(OutSurf[i_existClosedCylinder + 2]).point[1].Y := P2.Y;
        pSurf(OutSurf[i_existClosedCylinder + 3]).point[0].Y := P2.Y;
      end
      // если нет, то вставляем поверхность
      else
        InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);

      // если да, то изменяем лишь размеры
      if not (existOutClosedCylinder) then
      begin
        // изменяем размеры правого торца
        for i := 0 to OutSurf.Count - 1 do
          if (pSurf(OutSurf[i]).NUSL = 9907) then
            pSurf(OutSurf[i]).point[0].Y := round(diamHalfopenedCyl);
      end;
    end;

  end
  else
  begin
    // Вставляем правый полуоткрытый торец
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
      // И изменяем размеры цилиндра, который перед вставленным торцем
      pSurf(OutSurf[Id]).point[0].X := P1.X;
    end;

    // Вставляем закрытый цилиндр
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

    // Вставляем левый полуоткрытый торец
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

    // Вставляем левый полуоткрытый цилиндр
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
      // изменяем размеры левого торца
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

  // вычисляем индекс поверхности-цилиндра, к которому будем привязывать выемку
  Id := GetOutsideSurfPriv(P2.Y, flagLeft);
  nomerPov := currTrans.NPVA;

  // находим размер привязки и координату X левого торца
  for i := 0 to OutSurf.Count - 1 do
    if (pSurf(OutSurf[i]).NUSL = 9907) then
      lengthDet := pSurf(OutSurf[i]).point[0].X;

  existOutCon := false;
  // проверяем, есть ли уже конус
  for i := 0 to OutCon.Count - 1 do
  begin
    if ((pSurf(OutCon[i]).number = nomerPov)) then
    begin
      existOutCon := true;
      i_existOutCon := i;
      break;
    end;
  end;

  // вставляем поверхности справа
  if (not (flagLeft)) then
  begin
    // Вставляем конус
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
        // изменяем размеры предыдущего  торца
        if (pSurf(OutSurf[i]).PKDA = 2132) and (pSurf(OutSurf[i]).point[0].X = P1.X) then
          pSurf(OutSurf[i]).point[1] := P1;
        // изменяем размеры последующего  цилиндра
        if (pSurf(OutSurf[i]).PKDA = 2112) and (pSurf(OutSurf[i]).point[0].Y = P2.Y) then
          pSurf(OutSurf[i]).point[0] := P2;
      end;

    end;
  end

  else // слева
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
      // изменяем размеры предыдущего  торца
      if (pSurf(OutSurf[i]).PKDA = 2132) and (pSurf(OutSurf[i]).point[0].X = P1.X) then
        pSurf(OutSurf[i]).point[0] := P1;
      // изменяем размеры последующего  цилиндра
      if (pSurf(OutSurf[i]).PKDA = 2112) and (pSurf(OutSurf[i]).point[0].Y = P2.Y) then
        pSurf(OutSurf[i]).point[1] := P2;
    end;

  end; // закрывает else

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

  // проверяем, есть ли уже выемка
  // (если номер обрабатываемой поверхности уже существует в поверхностях эскиза)
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
    // вычисляем индекс поверхности-цилиндра, к которому будем привязывать выемку
    Id := GetOutsideSurfPriv(tochitPover, flagLeft)
  else
    Id := nomerPov - 2;

  // вставляем поверхности справа
  if (not (flagLeft)) then
  begin
    // Вставляем правый полуоткрытый торец
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
        // если да, то изменяем лишь размеры
        if (existOutHalfopenCylinder) then
        begin
          pSurf(OutSurf[i_existOutHalfopenCylinder]).point[0].X := P1.X;
          pSurf(OutSurf[i_existOutHalfopenCylinder]).point[1] := P2;
          pSurf(OutSurf[i_existOutHalfopenCylinder - 1]).point[1].X := P2.X;
        end
        // если нет, то вставляем поверхность
        else
        begin
          InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
          // И изменяем размеры цилиндра, который перед вставленным торцем
          pSurf(OutSurf[Id]).point[1].X := P1.X;
        end;
      except
        ShowMessage(currTrans.NPVA.ToString());
      end; // закрываем try
    end;

    // Вставляем правый полуоткрытый цилиндр
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

        // если да, то изменяем лишь размеры
        if (existOutHalfopenCylinder) then
        begin
          pSurf(OutSurf[i_existOutHalfopenCylinder + 1]).point[0] := P1;
          pSurf(OutSurf[i_existOutHalfopenCylinder + 1]).point[1].Y := P2.Y;
          // pSurf(OutSurf[i_existOutHalfopenCylinder + 2]).point[0].Y := P2.Y;
        end
        // если нет, то вставляем поверхность
        else
        begin
          InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
          // Изменяем размер торца, который идет за вставленным цилиндром
          pSurf(OutSurf[Id + 3]).point[0].Y := P2.Y;
        end;

      except
        ShowMessage(currTrans.NPVA.ToString());
      end; // закрываем try

    end;

  end

  else // слева
  begin
    // Вставляем левый полуоткрытый цилиндр
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

        // если да, то изменяем лишь размеры
        if (existOutHalfopenCylinder) then
        begin
          pSurf(OutSurf[i_existOutHalfopenCylinder]).point[0].Y := P1.Y;
          pSurf(OutSurf[i_existOutHalfopenCylinder]).point[1] := P2;
          pSurf(OutSurf[i_existOutHalfopenCylinder - 1]).point[1].Y := P2.Y;
        end
        // если нет, то вставляем поверхность
        else
        begin

          InsertSurf(1, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
          // Изменяем размер торца, который идет до  вставленного цилиндра
          pSurf(OutSurf[Id - 1]).point[1].Y := P1.Y;
        end;
      except
        ShowMessage(currTrans.NPVA.ToString());
      end; // закрываем try
    end;

    // Вставляем левый полуоткрытый торец
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

        // если да, то изменяем лишь размеры
        if (existOutHalfopenCylinder) then
        begin
          pSurf(OutSurf[i_existOutHalfopenCylinder + 1]).point[0] := P1;
          pSurf(OutSurf[i_existOutHalfopenCylinder + 1]).point[1].X := P2.X;

          pSurf(OutSurf[i_existOutHalfopenCylinder + 2]).point[0].X := P2.X;
        end
        // если нет, то вставляем поверхность
        else
        begin
          InsertSurf(1, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
          // Изменяем размер цилиндра, который идет после  вставленного торца
          pSurf(OutSurf[Id]).point[0].X := P1.X;
        end;

      except
        ShowMessage(currTrans.NPVA.ToString());
      end; // закрываем try
    end;

  end; // закрывает else
end;

procedure TSketchView.Insert_Tor(nomerPov: integer; flagLeft: boolean; P1, P2: TPOINT);
var
  i, Id, i_existOutTor: integer;
  Index: integer;
  Kod_PKDA, Kod_NUSL: integer;
  lengthDet: single;
  existOutTor: boolean;
begin

  // вычисляем индекс поверхности-цилиндра, к которому будем привязывать выемку
  Id := GetOutsideSurfPriv(P2.Y, flagLeft);

  existOutTor := false;
  // проверяем, есть ли уже торец
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

  // берем координату Y из привязочного цилиндра
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
  // // изменяем размеры цилиндра, связанного с конусом
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

  // вычисляем индекс поверхности-цилиндра, к которому будем привязывать выемку
  Id := GetOutsideSurfPriv(P2.Y, flagLeft);

  existOutCon := false;
  // проверяем, есть ли уже конус
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
    // изменяем размеры цилиндра, связанного с конусом
    pSurf(OutSurf[Id]).point[0].X := P2.X;
    pSurf(OutSurf[Id]).point[0].Y := P2.Y;
    pSurf(OutSurf[Id]).point[1].Y := P2.Y;
    // изменяем размеры второго цилиндра, связанного с конусом

    // нужно пройти все конусы, найти связанный и изменить его размер
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

  // вычисляем индекс поверхности-цилиндра, к которому будем привязывать выемку
  Id := GetOutsideSurfPriv(P2.Y, flagLeft);

  existOutCyl := false;
   // проверяем, есть ли уже конус
  for i := 0 to OutSurf.Count - 1 do
  begin
    if ((pSurf(OutSurf[i]).number = nomerPov)) then
    begin
      existOutCyl := true;
      i_existOutCyl := i;
      break;
    end;
  end;

//  // координаты цилиндра
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

  // Вставляем цилиндр

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

  // находим размер привязки  и координату X левого торца
  for i := 0 to OutSurf.Count - 1 do
    if (pSurf(OutSurf[i]).NUSL = 9907) then
      lengthDet := pSurf(OutSurf[i]).point[0].X;

  if (nomerPov = 0) then
  begin
    podrezTorec := currTrans.SizesFromTP[1] + lengthDet;
    tochitPover := currTrans.SizesFromTP[0];
    nomerPov := currTrans.NPVA;
  end;

  // Чтобы округляло до большего целого числа если после запятой 5. Т.к. в функции Round
  // Округление использует банковские правила, где точная половина значения вызывает округление к четному числу
  if (Frac(podrezTorec) = 0.5) then
    podrezTorec := podrezTorec + 0.1;
  if (Frac(tochitPover) = 0.5) then
    tochitPover := tochitPover + 0.1;

  // вычисляем индекс поверхности-цилиндра, к которому будем привязывать выемку
  Id := GetInnerSurfPriv(tochitPover, flagLeft);

  existInnerHalfopenCylinder := false;

  // проверяем, есть ли уже внутренний вырез
  // (если номер обрабатываемой пов-ти уже существует во внутренних пов-тях эскиза)
  for i := 0 to InnerSurf.Count - 1 do
  begin
    if (pSurf(InnerSurf[i]).number = nomerPov) then
    begin
      existInnerHalfopenCylinder := true;
      i_existInnerCylinder := i;
      break;
    end;
  end;

  if (not (flagLeft)) then // вставляем поверхности справа
  begin
    podrezTorec := ABS(LenDetal - podrezTorec);
    // Вставляем правый внутренний полуоткрытый цилиндр
    begin
      P1.X := round(pSurf(OutSurf[Id]).point[0].X);
      P2.X := round(pSurf(OutSurf[Id]).point[0].X - podrezTorec);
      P1.Y := round(tochitPover);
      P2.Y := round(tochitPover);
      Kod_PKDA := -2112;
      Kod_NUSL := 9912;
      Index := Id + 1;

      // если да, то изменяем лишь размеры
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurf[i_existInnerCylinder]).point[0] := P1;
        pSurf(InnerSurf[i_existInnerCylinder]).point[1] := P2;
      end
      // если нет, то вставляем поверхность
      else
        InsertSurf(2, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
    end;

    // Вставляем правый внутренний полуоткрытый торец
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

      // подправляем размеры цилиндров
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
      end; // закрыли for

    end;
  end // закрываем "if (not(flagLeft)).."

  else // вставляем поверхности слева
  begin

    // Вставляем левый внутренний полуоткрытый цилиндр
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

    // Вставляем левый внутренний полуоткрытый торец
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

      // подправляем размеры цилиндров
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
      end; // закрыли for

    end;

  end;
end;

procedure TSketchView.Insert_InOpenCyl(currentTransition: ptrTrans; nomerPovTorec: integer; diametr: single);
var
  i: integer;
  surface, surface1: pSurf;
  existInnerOpenCylinder: boolean;
  // Координаты поверхности
  P1, P2: TPOINT;
  Index: integer;
  Kod_PKDA, Kod_NUSL: integer;
begin

  existInnerOpenCylinder := false;

  // проверяем, есть ли уже внутренний открытый цилиндр
  for i := 0 to InnerSurf.Count - 1 do
  begin
    if (pSurf(InnerSurf[i]).NUSL = 9910) then
    begin
      existInnerOpenCylinder := true;
      break;
    end;
  end;

  // если да, то изменяем лишь размеры
  if (existInnerOpenCylinder) then
  begin
    pSurf(InnerSurf[i]).point[0].Y := round(diametr);
    pSurf(InnerSurf[i]).point[1].Y := round(diametr);
  end
  // если нет, то вставляем поверхность
  else
  begin
    P1.X := round(pSurf(OutSurf[0]).point[0].X);
    // вырез на всю длину детали
    P2.X := round(pSurf(OutSurf[OutSurf.Count - 1]).point[0].X);
    P1.Y := round(diametr);
    P2.Y := round(diametr);

    Kod_PKDA := -2111;
    Kod_NUSL := 9910;
    Index := 0;
    InsertSurf(2, P1, P2, Index, nomerPovTorec, Kod_PKDA, Kod_NUSL);

  end;
end;

// Считает масштаб вывода детали на экран и сдвиг по осям X и Y
// m_metric - масштаб; m_dx, m_dy - смещение
procedure TSketchView.SetMetric;
var
  len, heig: single;
  lm, hm: single;
begin

  // Принимаем входные данные из класса InputData
  DiamZagot := TInputData.GetDiamZagot;
  LenZagot := TInputData.GetLengthZagot;

  // Принимаем входные данные из класса InputData
  DiamDetal := TInputData.GetDiamDetal;
  LenDetal := TInputData.GetLengthDetal;

  // мах длина детали
  len := LenZagot;
  // мах высота детали
  heig := DiamZagot;

  lm := ((m_Screen.Right - m_Screen.Left) / m_Zoom) / len;
  hm := ((m_Screen.Bottom - m_Screen.Top) / (m_Zoom)) / heig;
  if lm < hm then
    m_metric := lm
  else
    m_metric := hm;
  // смещение при выводе
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
  // находим цилиндр максимального диаметра
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).PKDA = 2111) then
    begin

      // изменяем диаметр открытого цилиндра
      pSurf(OutSurf[i]).point[0].Y := round(newSize);
      pSurf(OutSurf[i]).point[1].Y := round(newSize);

      for j := 0 to MainForm.ProcessTrans.m_InputData.listSurface.Count - 1 do
        if ((pSurf(MainForm.ProcessTrans.m_InputData.listSurface[j]).PKDA = 2111)) then
        begin
          PKDA1 := MainForm.ProcessTrans.GetSurfParam(pSurf(MainForm.ProcessTrans.m_InputData.listSurface[j]).L_POVB).PKDA;
          PKDA2 := MainForm.ProcessTrans.GetSurfParam(pSurf(MainForm.ProcessTrans.m_InputData.listSurface[j]).R_POVV).PKDA;
        end;

//      // если максимальный диаметр между торцами, тогда изменяем размеры торцев
//      if (((PKDA1 = 2132) or (PKDA1 = 2131)) and ((PKDA2 = 2132) or (PKDA2 = 2131))) or (OutCon.Count = 0) then
//      begin
//        // изменяем максимальную координату левого торца
//        if (pSurf(OutSurf[i - 1]).point[1].Y > pSurf(OutSurf[i - 1]).point[0].Y) then
//          pSurf(OutSurf[i - 1]).point[1].Y := round(newSize)
//        else
//          pSurf(OutSurf[i - 1]).point[0].Y := round(newSize);
//
//        // изменяем максимальную координату правого торца
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

  // находим длину правого торца
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).NUSL = 9907) then
      maxsLenth := pSurf(OutSurf[i]).point[0].X;
  end;

  for i := 0 to OutSurf.Count - 1 do
    if (pSurf(OutSurf[i]).PKDA = 2131) then
      // если подрезаем правый торец
      if (pSurf(OutSurf[i]).NUSL = 9907) and (Kod_NUSL = 9907) then
      begin
      //  pSurf(OutSurf[i - 1]).point[1].X := round(newSize);
        pSurf(OutSurf[i]).point[0].X := round(newSize);
        pSurf(OutSurf[i]).point[1].X := round(newSize);

        // если до этого подрезали левый торец, то прибавляем величину отрезки к размеру правого торца
        if (flagPodrezLevTorec) then
        begin
          pSurf(OutSurf[i - 1]).point[1].X := pSurf(OutSurf[i - 1]).point[1].X + round(razmLeftPodrez);
          pSurf(OutSurf[i]).point[0].X := pSurf(OutSurf[i]).point[0].X + round(razmLeftPodrez);
          pSurf(OutSurf[i]).point[1].X := pSurf(OutSurf[i]).point[1].X + round(razmLeftPodrez);
        end;

        // проходим внутренние поверхности. Если они выступают за торец, то "укорачиваем"
        for j := 0 to InnerSurf.Count - 1 do
        begin
          if (pSurf(InnerSurf[j]).point[1].X > pSurf(OutSurf[i]).point[1].X) then
            pSurf(InnerSurf[j]).point[1].X := pSurf(OutSurf[i]).point[1].X;
          if (pSurf(InnerSurf[j]).point[0].X > pSurf(OutSurf[i]).point[1].X) then
            pSurf(InnerSurf[j]).point[0].X := pSurf(OutSurf[i]).point[1].X;
        end;

        break;
      end
      // если подрезаем левый торец
      else if (pSurf(OutSurf[i]).NUSL = 9901) and (Kod_NUSL = 9901) then
      begin
       // pSurf(OutSurf[i + 1]).point[0].X := round(maxsLenth - newSize);
        pSurf(OutSurf[i]).point[0].X := round(maxsLenth - newSize);
        pSurf(OutSurf[i]).point[1].X := round(maxsLenth - newSize);

        // проходим внутренние поверхности.
        for j := 0 to InnerSurf.Count - 1 do
        begin
          if (pSurf(InnerSurf[j]).point[0].X < pSurf(OutSurf[i]).point[0].X) then
            pSurf(InnerSurf[j]).point[0].X := pSurf(OutSurf[i]).point[0].X;

          if (pSurf(InnerSurf[j]).point[1].X < pSurf(OutSurf[i]).point[0].X) then
            pSurf(InnerSurf[j]).point[1].X := pSurf(OutSurf[i]).point[0].X;
        end;

        // Если мы подрезали торец слева, то добавляем  размер подрезки ко всем последующим переходам подрезки
        flagPodrezLevTorec := true;
        razmLeftPodrez := round(maxsLenth - newSize);

        break;
      end;

end;

procedure TSketchView.CreateFirstSurface;
var
  surface: pSurf;
begin

  // Поверхность №1
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

  // Поверхность №2
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

  // Поверхность №3
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

// Отрисовка поверхностей
procedure TSketchView.Draw(canvas: TCanvas);
var
  i: integer;
  point: array[0..1] of TPOINT;
  textCoord: string;
begin

  // // сортирует поверхности последовательно на основании возрастания координат
  OutSurf.Sort(Comp);
  // InnerSurfaces.Sort(Comp);
  // преобразование координат поверхностей для нормального отображения на форме
  ConvertingPoint;

  with canvas do
  begin
    // отрисовка внешних поверхностей
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
        TextOut( (* координаты *) point[0].X + 3, point[0].Y + 2, textCoord);

        MoveTo(point[0].X, point[0].Y);
        LineTo(point[1].X, point[1].Y);
      end;
    end;

    // рисуем ось
    begin
      Pen.Style := psDot;
      Pen.Width := 1;
      point[1] := pSurf(ScaleOutSurfaces[ScaleOutSurfaces.Count - 1]).point[1];
      point[0] := pSurf(ScaleOutSurfaces[0]).point[0];

      TextOut(point[1].X + 3, point[1].Y + 2,
        (* текст *) '(' + pSurf(OutSurf[OutSurf.Count - 1]).point[1].X.ToString + ', ' + pSurf(OutSurf[OutSurf.Count - 1]).point[1].Y.ToString + ' )');

      MoveTo(point[1].X, point[1].Y);
      LineTo(point[0].X, point[0].Y);
    end;

    // рисуем внутренний контур
    begin
      Pen.Style := psSolid;

      Pen.Color := clBlack;
      Pen.Width := 2;
      if ScaleInSurfaces.Count > 0 then
        // отрисовка внутренних поверхностей
        for i := 0 to ScaleInSurfaces.Count - 1 do
        begin
          point[0] := pSurf(ScaleInSurfaces[i]).point[0];
          point[1] := pSurf(ScaleInSurfaces[i]).point[1];

          TextOut(point[0].X + 3, point[0].Y + 2, '(' + pSurf(InnerSurf[i]).point[0].X.ToString + ', ' + pSurf(InnerSurf[i]).point[0].Y.ToString + ' )');

          MoveTo(point[0].X, point[0].Y);
          LineTo(point[1].X, point[1].Y);
        end;
    end;

    // рисуем конусы
    begin
      Pen.Style := psSolid;
      Pen.Color := clRed;
      Pen.Width := 2;
      if ScaleOutCon.Count > 0 then
        // перебор конусов
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

// Находим поверхность привязки для вставляемого выреза
function TSketchView.GetClosedPriv(leftTor: single; flagLeft: boolean): integer;
var
  i, number: integer;
begin

  number := 1;
  // Находим индекс поверхности "цилиндр для привязки"
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
    // Находим индекс поверхности "правый торец"
    for i := 0 to OutSurf.Count - 1 do
    begin
      if ((pSurf(OutSurf[i]).PKDA = 2131) and (pSurf(OutSurf[i]).NUSL = 9907)) then
        number := i;
    end
  else
    // Находим индекс поверхности "левый торец"
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
  // true, если прошли максимальный диаметр
  flagMaxDiam: boolean;
begin

  numberSurf := -1;

  // находим индекс поверхности с максимальным диаметром
  for i := 0 to OutSurf.Count - 1 do
  begin
    if (pSurf(OutSurf[i]).PKDA = 2111) then
      numberMaxSurf := i;
  end;

  flagMaxDiam := false;
  for i := 0 to OutSurf.Count - 1 do
  begin

    // установление флага максимального диаметра
    if (pSurf(OutSurf[i]).PKDA = 2111) then
      flagMaxDiam := true;

    // если вставляемый вырез справа и вставляем после полуоткрытого цилиндра
    if ((flagMaxDiam) and (not (flagLeft))) then
    begin
      if (pSurf(OutSurf[i]).PKDA = 2112) and (pSurf(OutSurf[i]).point[0].Y >= insertDiam) then
      begin
        numberSurf := i;
        // А здесь не выходим из цикла почему-то
        // break;
      end;
    end;

    // если вставляемый вырез слева и вставляем до полуоткрытого цилиндра
    if (not (flagMaxDiam) and (flagLeft)) then
    begin
      if (pSurf(OutSurf[i]).PKDA = 2112) and (pSurf(OutSurf[i]).point[0].Y > insertDiam) then
      begin
        numberSurf := i;
        // если нашли диаметр, удовлетворяющий условию, то сразу выходим из цикла
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

