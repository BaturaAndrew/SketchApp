unit SketchView;

interface

uses Windows, Graphics, Dialogs, Generics.Collections, Generics.Defaults,
  // для чтения размеров заготовки
  InputData,
  SysUtils, Classes;

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
    OutsideSurfaces: TList;
  protected
    // Увеличение(тоже в некотором роде маштаб)
    m_Zoom: real;

    // Массив внутренних поверхностей
    InnerSurfaces: TList;
    // Массив наружных  поверхностей с промасштабированными координатами
    ScaleSurfaces: TList;
    // Массив наружных  поверхностей с промасштабированными координатами
    InnerScaleSurfaces: TList;

    // Размеры заготовки
    DiamZagot, LenZagot: single;

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
    procedure Insert_OutsideClosedSurfaces(currTrans: ptrTrans;
      flagLeft: boolean; numPrivLeft, numPrivRight: integer;
      leftTor, diamClosedCyl, lengthClosedCylindr, rightTorec,
      diamHalfopenedCyl, lengthHalfopenedCyl: single);

    // Вставка наружных полуоткрытых поверхностей (выемок)
    procedure Insert_OutsideHalfopenSurfaces(currTrans: ptrTrans;
<<<<<<< HEAD
      flagLeft: boolean;  nomerPov: integer = 0;
      podrezTorec: single = 0; tochitPover: single = 0);
=======
      flagLeft: boolean; nomerPov: integer = 0; podrezTorec: single = 0;
      tochitPover: single = 0);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46

    // Вставка внутреннего открытого цилиндра (вырез)
    procedure Insert_OpenInnerCylinder(currentTransition: ptrTrans;
      nomerPovTorec: integer; diametr: single);

    // Вставка внутренних полуоткрытых поверхностей (вырезов)
    procedure Insert_InnerHalfopenSurfaces(currTrans: ptrTrans;
      flagLeft: boolean; nomerPov: integer = 0; podrezTorec: single = 0;
      tochitPover: single = 0);

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
    procedure InsertSurf(flagOutsideSurf: boolean; P1, P2: TPOINT;
      Index, number, Kod_PKDA, Kod_NUSL: integer);

  end;

implementation

function Comp(Item1, Item2: Pointer): integer;
// С помощью этой функции реализуется	сортировка поверхностей по координате X
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

  // Проход всех наружных поверхностей
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    // Преобразование первой  и второй точки поверхости
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

  // Проход всех внутренних  поверхностей
  for i := 0 to InnerScaleSurfaces.Count - 1 do
    // Преобразование первой  и второй точки поверхости
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

procedure TSketchView.Insert_OutsideClosedSurfaces(currTrans: ptrTrans;
  flagLeft: boolean; numPrivLeft, numPrivRight: integer;
  leftTor, diamClosedCyl, lengthClosedCylindr, rightTorec, diamHalfopenedCyl,
  lengthHalfopenedCyl: single);
var

  i, Id: integer;
  P1, P2: TPOINT;
  Index: integer;
  number, Kod_PKDA, Kod_NUSL: integer;

  nomerPov: integer;
  lengthDet, leftTorDet: single;
<<<<<<< HEAD
=======
  existOutClosedCylinder: boolean;
  i_existClosedCylinder: integer;
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
begin

  // вычисляем индекс поверхности-цилиндра, к которой будем привязывать выемку
  // на основе диаметра вставляемого цилиндра
  Id := GetOutsideSurfPriv(diamClosedCyl, flagLeft);
  nomerPov := currTrans.NPVA;

<<<<<<< HEAD
=======
  existOutClosedCylinder := false;

  // проверяем, есть ли уже внутренний вырез
  // (если номер обрабатываемой поверхности уже существует во внутренних поверхностях эскиза)
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    if (pSurf(OutsideSurfaces[i]).number = nomerPov) then
    begin
      existOutClosedCylinder := true;
      i_existClosedCylinder := i;
      break;
    end;
  end;

>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
  // находим размер привязки  и координату X левого торца
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    if (pSurf(OutsideSurfaces[i]).NUSL = 9907) then
      lengthDet := pSurf(OutsideSurfaces[i]).point[0].X;

    if (pSurf(OutsideSurfaces[i]).NUSL = 9901) then
      leftTorDet := pSurf(OutsideSurfaces[i]).point[0].X;
  end;

  if (not(flagLeft)) then
  begin

    // Вставляем левый полуоткрытый торец
    begin
<<<<<<< HEAD
      X1 := round(leftTor);
      X2 := X1;
      Y2 := round(pSurf(OutsideSurfaces[Id]).point[1].Y);
      Y1 := round(diamClosedCyl);
=======
      P1.X := round(leftTor);
      P2.X := P1.X;
      P2.Y := round(pSurf(OutsideSurfaces[Id]).point[1].Y);
      P1.Y := round(diamClosedCyl);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      Kod_PKDA := 2132;
      Kod_NUSL := 9905;
      Index := Id + 1;
      number := nomerPov - 1;

      if (flagPodrezLevTorec) then
      begin
<<<<<<< HEAD
        X1 := X1 + round(razmLeftPodrez);
        X2 := X1;
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Index, number, Kod_PKDA, Kod_NUSL);
      // И изменяем размеры цилиндра, который перед вставленным торцем
      pSurf(OutsideSurfaces[Id]).point[1].X := X1;
=======
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P1.X;
      end;

      // если да, то изменяем лишь размеры
      if (existOutClosedCylinder) then
      begin
        pSurf(OutsideSurfaces[i_existClosedCylinder - 1]).point[0].Y := P1.Y;
      end
      // если нет, то вставляем поверхность
      else
      begin
        InsertSurf(true, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);

        // И изменяем размеры цилиндра, который перед вставленным торцем
        pSurf(OutsideSurfaces[Id]).point[1].X := P1.X;
      end;
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
    end;

    // Вставляем закрытый цилиндр
    begin
<<<<<<< HEAD
      X1 := round(leftTor);
      X2 := round(leftTor + lengthClosedCylindr);
      Y1 := round(diamClosedCyl);
      Y2 := round(diamClosedCyl);
=======
      P1.X := round(leftTor);
      P2.X := round(leftTor + lengthClosedCylindr);
      P1.Y := round(diamClosedCyl);
      P2.Y := round(diamClosedCyl);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      Kod_PKDA := 2112;
      Kod_NUSL := 9906;
      Index := Id + 2;
      if (flagPodrezLevTorec) then
      begin
<<<<<<< HEAD
        X1 := X1 + round(razmLeftPodrez);
        X2 := X2 + round(razmLeftPodrez);
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
    end;

    // Вставляем правый полуоткрытый торец
    begin
      X1 := round(leftTor + lengthClosedCylindr);
      X2 := X1;
      Y1 := round(diamClosedCyl);
      Y2 := round(diamHalfopenedCyl);
      number := nomerPov + 1;
      Kod_PKDA := 2132;
      Kod_NUSL := 9903;
      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
        X1 := X1 + round(razmLeftPodrez);
        X2 := X1;
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Id, number, Kod_PKDA, Kod_NUSL);
=======
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P2.X + round(razmLeftPodrez);
      end;

      // если да, то изменяем лишь размеры
      if (existOutClosedCylinder) then
      begin
        pSurf(OutsideSurfaces[i_existClosedCylinder]).point[0] := P1;
        pSurf(OutsideSurfaces[i_existClosedCylinder]).point[1] := P2;
      end
      // если нет, то вставляем поверхность
      else
        InsertSurf(true, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
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
      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P1.X;
      end;
      // если да, то изменяем лишь размеры
      if (existOutClosedCylinder) then
      begin
        pSurf(OutsideSurfaces[i_existClosedCylinder + 1]).point[0] := P1;
        pSurf(OutsideSurfaces[i_existClosedCylinder + 1]).point[1] := P2;
      end
      // если нет, то вставляем поверхность
      else
        InsertSurf(true, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
    end;

    // Вставляем правый полуоткрытый цилиндр
    begin

<<<<<<< HEAD
      X1 := round(leftTor + lengthClosedCylindr);
      X2 := round(lengthDet);
      Y1 := round(diamHalfopenedCyl);
      Y2 := round(diamHalfopenedCyl);
=======
      P1.X := round(leftTor + lengthClosedCylindr);
      P2.X := round(lengthDet);
      P1.Y := round(diamHalfopenedCyl);
      P2.Y := round(diamHalfopenedCyl);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      Kod_PKDA := 2112;
      Kod_NUSL := 9902;
      number := nomerPov + 2;
      Index := Id + 1;

      if (flagPodrezLevTorec) then
<<<<<<< HEAD
        X1 := X1 + round(razmLeftPodrez);
      InsertSurf(true, X1, X2, Y1, Y2, Index, number, Kod_PKDA, Kod_NUSL);

      // изменяем размеры правого торца
      for i := 0 to OutsideSurfaces.Count - 1 do
        if (pSurf(OutsideSurfaces[i]).NUSL = 9907) then
          pSurf(OutsideSurfaces[i]).point[0].Y := round(diamHalfopenedCyl);
=======
        P1.X := P1.X + round(razmLeftPodrez);

      // если да, то изменяем лишь размеры
      if (existOutClosedCylinder) then
      begin
        pSurf(OutsideSurfaces[i_existClosedCylinder + 2]).point[0].Y := P1.Y;
        pSurf(OutsideSurfaces[i_existClosedCylinder + 2]).point[1].Y := P2.Y;
        pSurf(OutsideSurfaces[i_existClosedCylinder + 3]).point[0].Y := P2.Y;
      end
      // если нет, то вставляем поверхность
      else
        InsertSurf(true, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);

      // если да, то изменяем лишь размеры
      if not(existOutClosedCylinder) then
      begin
        // изменяем размеры правого торца
        for i := 0 to OutsideSurfaces.Count - 1 do
          if (pSurf(OutsideSurfaces[i]).NUSL = 9907) then
            pSurf(OutsideSurfaces[i]).point[0].Y := round(diamHalfopenedCyl);
      end;
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
    end;

  end
  else
  begin

    // Вставляем правый полуоткрытый торец
    begin
<<<<<<< HEAD
      X1 := round(rightTorec);
      X2 := X1;
      Y2 := round(pSurf(OutsideSurfaces[Id]).point[1].Y);
      Y1 := round(diamClosedCyl);
=======
      P1.X := round(rightTorec);
      P2.X := P1.X;
      P1.Y := round(diamClosedCyl);
      P2.Y := round(pSurf(OutsideSurfaces[Id]).point[1].Y);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      Kod_PKDA := 2132;
      Kod_NUSL := 9905;
      Index := Id + 1;
      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
<<<<<<< HEAD
        X1 := X1 + round(razmLeftPodrez);
        X2 := X1;
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
=======
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P1.X;
      end;
      InsertSurf(true, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      // И изменяем размеры цилиндра, который перед вставленным торцем
      pSurf(OutsideSurfaces[Id]).point[0].X := P1.X;
    end;
    //
    // Вставляем закрытый цилиндр
    begin
<<<<<<< HEAD
      Y1 := round(diamClosedCyl);
      Y2 := Y1;
      X2 := round(leftTor);
      X1 := round(rightTorec);
=======

      P1.X := round(rightTorec);
      P2.X := round(leftTor);
      P1.Y := round(diamClosedCyl);
      P2.Y := P1.Y;

>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      Kod_PKDA := 2112;
      number := nomerPov + 1;
      Kod_NUSL := 9906;
      Index := Id + 2;
      if (flagPodrezLevTorec) then
      begin
<<<<<<< HEAD
        X2 := round(X2 + razmLeftPodrez);
        X1 := round(X1 + razmLeftPodrez);
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Index, number, Kod_PKDA, Kod_NUSL);
=======
        P1.X := round(P1.X + razmLeftPodrez);
        P2.X := round(P2.X + razmLeftPodrez);
      end;
      InsertSurf(true, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
    end;

    // Вставляем левый полуоткрытый торец
    begin
<<<<<<< HEAD
      X1 := round(leftTor);
      X2 := X1;
      Y1 := round(diamClosedCyl);
      Y2 := round(diamHalfopenedCyl);
=======
      P1.X := round(leftTor);
      P2.X := P1.X;
      P1.Y := round(diamClosedCyl);
      P2.Y := round(diamHalfopenedCyl);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      number := nomerPov - 1;
      Kod_PKDA := 2132;
      Kod_NUSL := 9903;

      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
<<<<<<< HEAD
        X1 := X1 + round(razmLeftPodrez);
        X2 := X1;
        // pSurf(OutsideSurfaces[Id + 2]).point[1].X := X1;
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Id, number, Kod_PKDA, Kod_NUSL);
=======
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P1.X;
        // pSurf(OutsideSurfaces[Id + 2]).point[1].X := X1;
      end;
      InsertSurf(true, P1, P2, Id, number, Kod_PKDA, Kod_NUSL);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
    end;

    // Вставляем левый полуоткрытый цилиндр
    begin
<<<<<<< HEAD
      X2 := round(leftTor);
      X1 := round(leftTorDet);
      Y1 := round(diamHalfopenedCyl);
      Y2 := round(diamHalfopenedCyl);
=======
      P1.X := round(leftTorDet);
      P2.X := round(leftTor);
      P1.Y := round(diamHalfopenedCyl);
      P2.Y := round(diamHalfopenedCyl);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      Kod_PKDA := 2112;
      Kod_NUSL := 9902;
      Index := Id + 1;
      if (flagPodrezLevTorec) then
      begin
<<<<<<< HEAD
        X2 := round(X2 + razmLeftPodrez);
        X1 := round(X1 + razmLeftPodrez);
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
=======
        P1.X := round(P1.X + razmLeftPodrez);
        P2.X := round(P2.X + razmLeftPodrez);
      end;
      InsertSurf(true, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      // изменяем размеры левого торца
      for i := 0 to OutsideSurfaces.Count - 1 do
        if (pSurf(OutsideSurfaces[i]).NUSL = 9901) then
          pSurf(OutsideSurfaces[i]).point[1].Y := round(diamHalfopenedCyl);
    end;
  end;

end;

procedure TSketchView.Insert_OutsideHalfopenSurfaces(currTrans: ptrTrans;
<<<<<<< HEAD
  flagLeft: boolean;  nomerPov: integer;
  podrezTorec, tochitPover: single);
=======
  flagLeft: boolean; nomerPov: integer; podrezTorec, tochitPover: single);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
var
  Id: integer;
  P1, P2: TPOINT;
  Index: integer;
  number, Kod_PKDA, Kod_NUSL: integer;
begin

<<<<<<< HEAD
  numPriv := currTrans.PRIV;
  // когда   вызываем процедуру для случая "точить-подрезать"
//  if (nomerPov = 0) then
//  begin
//    // выбираем размеры
////    podrezTorec := currTrans.SizesFromTP[2];
//    tochitPover := currTrans.SizesFromTP[0];
//    nomerPov := currTrans.NPVA;
//  end;

=======
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
  // вычисляем индекс поверхности-цилиндра, к которому будем привязывать выемку
  Id := GetOutsideSurfPriv(tochitPover, flagLeft);

  // вставляем поверхности справа
  if (not(flagLeft)) then
  begin
    // Вставляем правый полуоткрытый торец
    begin
<<<<<<< HEAD
      X1 := round(podrezTorec);
      X2 := X1;
      Y1 := round(pSurf(OutsideSurfaces[Id]).point[1].Y);
      Y2 := round(tochitPover);
      Kod_PKDA := 2132;
      Kod_NUSL := 9905;
      Index := Id + 1;
      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
        X1 := X1 + round(razmLeftPodrez);
        X2 := X2 + round(razmLeftPodrez);
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
=======
      P1.X := round(podrezTorec);
      P2.X := P1.X;
      P1.Y := round(pSurf(OutsideSurfaces[Id]).point[1].Y);
      P2.Y := round(tochitPover);
      Kod_PKDA := 2132;
      Kod_NUSL := 9905;
      Index := Id + 1;

      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P2.X + round(razmLeftPodrez);
      end;

      InsertSurf(true, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      // И изменяем размеры цилиндра, который перед вставленным торцем
      pSurf(OutsideSurfaces[Id]).point[1].X := P1.X;
    end;

    // Вставляем правый полуоткрытый цилиндр
    begin
<<<<<<< HEAD
      X1 := round(podrezTorec);
      X2 := round(pSurf(OutsideSurfaces[Id + 2]).point[1].X);
      Y1 := round(tochitPover);
      Y2 := round(tochitPover);
=======
      P1.X := round(podrezTorec);
      P2.X := round(pSurf(OutsideSurfaces[Id + 2]).point[1].X);
      P1.Y := round(tochitPover);
      P2.Y := round(tochitPover);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      Kod_PKDA := 2112;
      number := nomerPov + 1;
      Kod_NUSL := 9906;
      Index := Id + 2;
<<<<<<< HEAD
      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
        X1 := X1 + round(razmLeftPodrez);
        // X2 := X2 + round(razmLeftPodrez);
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Index, number, Kod_PKDA, Kod_NUSL);
=======

      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
        P1.X := P1.X + round(razmLeftPodrez);

      InsertSurf(true, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      // Изменяем размер торца, который идет за вставленным цилиндром
      pSurf(OutsideSurfaces[Id + 3]).point[0].Y := P2.Y;
    end;

  end

  else // слева
  begin
    // Вставляем левый полуоткрытый цилиндр
    begin
<<<<<<< HEAD
      X1 := round(pSurf(OutsideSurfaces[Id]).point[0].X);
      X2 := round(podrezTorec);
      Y1 := round(tochitPover);
      Y2 := round(tochitPover);
      Kod_PKDA := 2112;
      Kod_NUSL := 9902;
      Index := Id + 1;
      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
       // X1 := X1 + round(razmLeftPodrez);
         X2 := X2 + round(razmLeftPodrez);
      end;
      InsertSurf(true, X1, X2, Y1, Y2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
=======
      P1.X := round(pSurf(OutsideSurfaces[Id]).point[0].X);
      P2.X := round(podrezTorec);
      P1.Y := round(tochitPover);
      P2.Y := round(tochitPover);
      Kod_PKDA := 2112;
      Kod_NUSL := 9902;
      Index := Id + 1;

      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
        P2.X := P2.X + round(razmLeftPodrez);

      InsertSurf(true, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      // Изменяем размер торца, который идет до  вставленного цилиндра
      pSurf(OutsideSurfaces[Id - 1]).point[1].Y := P1.Y;
    end;

    // Вставляем левый полуоткрытый торец
    begin
<<<<<<< HEAD
      X1 := round(podrezTorec);
      X2 := X1;
      Y1 := round(tochitPover);
      Y2 := round(pSurf(OutsideSurfaces[Id]).point[0].Y);
      number := nomerPov - 1;
      Kod_PKDA := 2132;
      Kod_NUSL := 9903;

      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
        X1 := X1 + round(razmLeftPodrez);
        X2 := X1;
//        pSurf(OutsideSurfaces[Id + 1]).point[1].X := X1;
//        pSurf(OutsideSurfaces[Id]).point[0].X := X1;
      end;

      InsertSurf(true, X1, X2, Y1, Y2, Id, number, Kod_PKDA, Kod_NUSL);
=======
      P1.X := round(podrezTorec);
      P2.X := P1.X;
      P1.Y := round(tochitPover);
      P2.Y := round(pSurf(OutsideSurfaces[Id]).point[0].Y);
      number := nomerPov - 1;
      Kod_PKDA := 2132;
      Kod_NUSL := 9903;
      Index := Id + 2;
      // Если подрезали левый торец
      if (flagPodrezLevTorec) then
      begin
        P1.X := P1.X + round(razmLeftPodrez);
        P2.X := P1.X;
      end;

      InsertSurf(true, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
      // Изменяем размер цилиндра, который идет после  вставленного торца
      pSurf(OutsideSurfaces[Id]).point[0].X := P1.X;
    end;

  end; // закрывает else
end;

procedure TSketchView.InsertSurf(flagOutsideSurf: boolean; P1, P2: TPOINT;
  Index, number, Kod_PKDA, Kod_NUSL: integer);
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
  flagLeft: boolean; nomerPov: integer = 0; podrezTorec: single = 0;
  tochitPover: single = 0);
var
  i: integer;
  surface, surface1: pSurf;
  Id: integer;
  P1, P2: TPOINT;
  Index: integer;
  number, Kod_PKDA, Kod_NUSL: integer;
  existInnerHalfopenCylinder: boolean;
  i_existInnerCylinder: integer;
begin

  if (nomerPov = 0) then
  begin
    podrezTorec := currTrans.SizesFromTP[1];
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
  // (если номер обрабатываемой поверхности уже существует во внутренних поверхностях эскиза)
  for i := 0 to InnerSurfaces.Count - 1 do
  begin
    if (pSurf(InnerSurfaces[i]).number = nomerPov) then
    begin
      existInnerHalfopenCylinder := true;
      i_existInnerCylinder := i;
      break;
    end;
  end;

  if (not(flagLeft)) then // вставляем поверхности справа
  begin
    // Вставляем правый внутренний полуоткрытый цилиндр
    begin

      P1.X := round(pSurf(OutsideSurfaces[Id]).point[0].X);
      P2.X := round(pSurf(OutsideSurfaces[Id]).point[0].X - podrezTorec);
      P1.Y := round(tochitPover);
      P2.Y := round(tochitPover);
      Kod_PKDA := -2112;
      Kod_NUSL := 9912;
      Index := Id + 1;
      // если да, то изменяем лишь размеры
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurfaces[i_existInnerCylinder]).point[0] := P1;
        pSurf(InnerSurfaces[i_existInnerCylinder]).point[1] := P2;
      end
      // если нет, то вставляем поверхность
      else
        InsertSurf(false, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
    end;

    // Вставляем правый внутренний полуоткрытый торец
    begin

      P1.X := round(pSurf(OutsideSurfaces[Id]).point[0].X - podrezTorec);
      P2.X := round(pSurf(OutsideSurfaces[Id]).point[0].X - podrezTorec);
      P1.Y := round(tochitPover);
      P2.Y := 0;
      Kod_PKDA := -2132;
      number := nomerPov + 1;
      Kod_NUSL := 9913;
      Index := Id + 1;
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurfaces[i_existInnerCylinder + 1]).point[0] := P1;
        pSurf(InnerSurfaces[i_existInnerCylinder + 1]).point[1] := P2;
      end
      else
        InsertSurf(false, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
    end;
  end // закрываем "if ((flagLeft)).."

  else // вставляем поверхности слева
  begin

    // Вставляем левый внутренний полуоткрытый цилиндр
    begin
      P1.X := round(pSurf(OutsideSurfaces[0]).point[0].X);
      P2.X := round(pSurf(OutsideSurfaces[0]).point[0].X + podrezTorec);
      P1.Y := round(tochitPover);
      P2.Y := round(tochitPover);
      Kod_PKDA := -2112;
      Kod_NUSL := 9912;
      Index := Id + 1;
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurfaces[i_existInnerCylinder]).point[0] := P1;
        pSurf(InnerSurfaces[i_existInnerCylinder]).point[1] := P2;
      end
      else
        InsertSurf(false, P1, P2, Index, nomerPov, Kod_PKDA, Kod_NUSL);
    end;

    // Вставляем левый внутренний полуоткрытый торец
    begin
      P1.X := round(pSurf(OutsideSurfaces[0]).point[0].X + podrezTorec);
      P2.X := round(pSurf(OutsideSurfaces[0]).point[0].X + podrezTorec);
      P1.Y := round(tochitPover);
      P2.Y := 0;
      Kod_PKDA := -2132;
      number := nomerPov + 1;
      Kod_NUSL := 9913;
      Index := Id + 1;
      if (existInnerHalfopenCylinder) then
      begin
        pSurf(InnerSurfaces[i_existInnerCylinder + 1]).point[0] := P1;
        pSurf(InnerSurfaces[i_existInnerCylinder + 1]).point[1] := P2;
      end
      else
        InsertSurf(false, P1, P2, Index, number, Kod_PKDA, Kod_NUSL);
    end;

  end;

  i := InnerSurfaces.Count;

  // изменяем размеры внутренних цилиндров с меньшими диаметроми
  while i <> 0 do
  begin
    i := i - 1;
    if ((pSurf(InnerSurfaces[i]).PKDA = -2112) and
      (pSurf(InnerSurfaces[i]).point[0].Y < P1.Y)) then
    begin
      case flagLeft of
        true:
          pSurf(InnerSurfaces[i]).point[0].X := P2.X;
        false:
          pSurf(InnerSurfaces[i]).point[0].X := P1.X;
      end;
      break;
    end;

    if ((pSurf(InnerSurfaces[i]).PKDA = -2111) and
      (pSurf(InnerSurfaces[i]).point[0].Y < P1.Y)) then
    begin
      case flagLeft of
        true:
          pSurf(InnerSurfaces[i]).point[0].X := P2.X;
        false:
          pSurf(InnerSurfaces[i]).point[1].X := P1.X;
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
  // Координаты поверхности
  P1, P2: TPOINT;
  Index: integer;
  Kod_PKDA, Kod_NUSL: integer;

begin

  existInnerOpenCylinder := false;

  // проверяем, есть ли уже внутренний открытый цилиндр
  for i := 0 to InnerSurfaces.Count - 1 do
  begin
    if (pSurf(InnerSurfaces[i]).NUSL = 9910) then
    begin
      existInnerOpenCylinder := true;
      break;
    end;
  end;

  // если да, то изменяем лишь размеры
  if (existInnerOpenCylinder) then
  begin
    pSurf(InnerSurfaces[i]).point[0].Y := round(diametr);
    pSurf(InnerSurfaces[i]).point[1].Y := round(diametr);
  end
  // если нет, то вставляем поверхность
  else
  begin
    P1.X := round(pSurf(OutsideSurfaces[0]).point[0].X);
    // вырез на всю длину детали
    P2.X := round(pSurf(OutsideSurfaces[OutsideSurfaces.Count - 1]).point[0].X);
    P1.Y := round(diametr);
    P2.Y := round(diametr);

    Kod_PKDA := -2111;
    Kod_NUSL := 9910;
    Index := 0;
    InsertSurf(false, P1, P2, Index, nomerPovTorec, Kod_PKDA, Kod_NUSL);

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
  m_dx := m_Screen.Left +
    round((m_Screen.Right - m_Screen.Left - len * m_metric) / 2);
  m_dy := (m_Screen.Top + round((m_Screen.Bottom - m_Screen.Top) / 2) - 150);

end;

procedure TSketchView.Resize_Cylinder(currTrans: ptrTrans);
var
<<<<<<< HEAD
  i, j: integer;
=======
  i: integer;
>>>>>>> f153781d92d17c696446f9ebeb3d5f50e16f4b46
  newSize: single;
begin
  newSize := currTrans.SizesFromTP[0];
  // находим цилиндр максимального диаметра
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    if (pSurf(OutsideSurfaces[i]).PKDA = 2111) then
    begin

      // изменяем диаметр открытого цилиндра
      pSurf(OutsideSurfaces[i]).point[0].Y := round(newSize);
      pSurf(OutsideSurfaces[i]).point[1].Y := round(newSize);

      // изменяем максимальную координату левого торца
      if (pSurf(OutsideSurfaces[i - 1]).point[1].Y >
        pSurf(OutsideSurfaces[i - 1]).point[0].Y) then
        pSurf(OutsideSurfaces[i - 1]).point[1].Y := round(newSize)
      else
        pSurf(OutsideSurfaces[i - 1]).point[0].Y := round(newSize);

      // изменяем максимальную координату правого торца
      if (pSurf(OutsideSurfaces[i - 1]).point[1].Y >
        pSurf(OutsideSurfaces[i + 1]).point[0].Y) then
        pSurf(OutsideSurfaces[i + 1]).point[1].Y := round(newSize)
      else
        pSurf(OutsideSurfaces[i + 1]).point[0].Y := round(newSize);

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
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    if (pSurf(OutsideSurfaces[i]).NUSL = 9907) then
      maxsLenth := pSurf(OutsideSurfaces[i]).point[0].X;
  end;

  for i := 0 to OutsideSurfaces.Count - 1 do
    if (pSurf(OutsideSurfaces[i]).PKDA = 2131) then
      // если подрезаем правый торец
      if (pSurf(OutsideSurfaces[i]).NUSL = 9907) and (Kod_NUSL = 9907) then
      begin
        pSurf(OutsideSurfaces[i - 1]).point[1].X := round(newSize);
        pSurf(OutsideSurfaces[i]).point[0].X := round(newSize);
        pSurf(OutsideSurfaces[i]).point[1].X := round(newSize);

        // если до этого подрезали левый торец, то прибавляем величину отрезки к размеру правого торца
        if (flagPodrezLevTorec) then
        begin
          pSurf(OutsideSurfaces[i - 1]).point[1].X :=
            pSurf(OutsideSurfaces[i - 1]).point[1].X + round(razmLeftPodrez);
          pSurf(OutsideSurfaces[i]).point[0].X := pSurf(OutsideSurfaces[i])
            .point[0].X + round(razmLeftPodrez);
          pSurf(OutsideSurfaces[i]).point[1].X := pSurf(OutsideSurfaces[i])
            .point[1].X + round(razmLeftPodrez);
        end;

        // проходим внутренние поверхности. Если они выступают за торец, то "укорачиваем"
        for j := 0 to InnerSurfaces.Count - 1 do
        begin
          if (pSurf(InnerSurfaces[j]).point[1].X > pSurf(OutsideSurfaces[i])
            .point[1].X) then
            pSurf(InnerSurfaces[j]).point[1].X := pSurf(OutsideSurfaces[i])
              .point[1].X;
          if (pSurf(InnerSurfaces[j]).point[0].X > pSurf(OutsideSurfaces[i])
            .point[1].X) then
            pSurf(InnerSurfaces[j]).point[0].X := pSurf(OutsideSurfaces[i])
              .point[1].X;
        end;

        break;
      end
      // если подрезаем левый торец
      else if (pSurf(OutsideSurfaces[i]).NUSL = 9901) and (Kod_NUSL = 9901) then
      begin
        pSurf(OutsideSurfaces[i + 1]).point[0].X := round(maxsLenth - newSize);
        pSurf(OutsideSurfaces[i]).point[0].X := round(maxsLenth - newSize);
        pSurf(OutsideSurfaces[i]).point[1].X := round(maxsLenth - newSize);

        // проходим внутренние поверхности.
        for j := 0 to InnerSurfaces.Count - 1 do
        begin
          if (pSurf(InnerSurfaces[j]).point[0].X < pSurf(OutsideSurfaces[i])
            .point[0].X) then
            pSurf(InnerSurfaces[j]).point[0].X := pSurf(OutsideSurfaces[i])
              .point[0].X;

          if (pSurf(InnerSurfaces[j]).point[1].X < pSurf(OutsideSurfaces[i])
            .point[0].X) then
            pSurf(InnerSurfaces[j]).point[1].X := pSurf(OutsideSurfaces[i])
              .point[0].X;
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
  OutsideSurfaces.Add(surface);

  // Поверхность №2
  new(surface);
  surface.point[0] := TPOINT.Create(0, round(DiamZagot));
  surface.point[1] := TPOINT.Create(round(LenZagot), round(DiamZagot));
  surface.number := 2;
  surface.L_POVB := 1;
  surface.R_POVV := 3;
  surface.PKDA := 2111;
  surface.NUSL := 9900;
  surface.PRIV := 0;
  OutsideSurfaces.Add(surface);

  // Поверхность №3
  new(surface);
  surface.point[0] := TPOINT.Create(round(LenZagot), round(DiamZagot));
  surface.point[1] := TPOINT.Create(round(LenZagot), 0);
  surface.number := 3;
  surface.L_POVB := 2;
  surface.R_POVV := 0;
  surface.PKDA := 2131;
  surface.NUSL := 9907;
  surface.PRIV := 1;
  OutsideSurfaces.Add(surface);

end;

// Отрисовка поверхностей
procedure TSketchView.Draw(canvas: TCanvas);
var
  i: integer;
  point: array [0 .. 1] of TPOINT;
  textCoord: string;
begin

  // сортирует поверхности последовательно на основании возрастания координат
  OutsideSurfaces.Sort(Comp);
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
      for i := 0 to ScaleSurfaces.Count - 1 do
      begin
        point[0] := pSurf(ScaleSurfaces[i]).point[0];
        point[1] := pSurf(ScaleSurfaces[i]).point[1];

        textCoord := '(' + pSurf(OutsideSurfaces[i]).point[0].X.tostring + ', '
          + pSurf(OutsideSurfaces[i]).point[0].Y.tostring + ' )';
        TextOut( (* координаты *) point[0].X + 3, point[0].Y + 2, textCoord);

        MoveTo(point[0].X, point[0].Y);
        LineTo(point[1].X, point[1].Y);
      end;
    end;

    // рисуем ось
    begin
      Pen.Style := psDot;
      Pen.Width := 1;
      point[1] := pSurf(ScaleSurfaces[ScaleSurfaces.Count - 1]).point[1];
      point[0] := pSurf(ScaleSurfaces[0]).point[0];

      TextOut(point[1].X + 3, point[1].Y + 2,
        (* текст *) '(' + pSurf(OutsideSurfaces[OutsideSurfaces.Count - 1])
        .point[1].X.tostring + ', ' +
        pSurf(OutsideSurfaces[OutsideSurfaces.Count - 1])
        .point[1].Y.tostring + ' )');

      MoveTo(point[1].X, point[1].Y);
      LineTo(point[0].X, point[0].Y);
    end;

    // рисуем внутренний контур
    begin
      Pen.Style := psSolid;
      Pen.Width := 2;
      if InnerScaleSurfaces.Count > 0 then
        // отрисовка внутренних поверхностей
        for i := 0 to InnerScaleSurfaces.Count - 1 do
        begin
          point[0] := pSurf(InnerScaleSurfaces[i]).point[0];
          point[1] := pSurf(InnerScaleSurfaces[i]).point[1];

          TextOut(point[0].X + 3, point[0].Y + 2, '(' + pSurf(InnerSurfaces[i])
            .point[0].X.tostring + ', ' + pSurf(InnerSurfaces[i])
            .point[0].Y.tostring + ' )');

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
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    if ((pSurf(OutsideSurfaces[i]).PKDA = 2112) or
      (pSurf(OutsideSurfaces[i]).PKDA = 2132)) then
      if ((pSurf(OutsideSurfaces[i]).point[1].X >= leftTor) and
        (pSurf(OutsideSurfaces[i]).point[0].X < leftTor)) then
        number := i;
  end;

  Result := number;
end;

function TSketchView.GetInnerSurfPriv(insertDiam: single;
  flagLeft: boolean): integer;
var
  i, number: integer;
  maxLength: single;
begin

  if (not(flagLeft)) then
    // Находим индекс поверхности "правый торец"
    for i := 0 to OutsideSurfaces.Count - 1 do
    begin
      if ((pSurf(OutsideSurfaces[i]).PKDA = 2131) and
        (pSurf(OutsideSurfaces[i]).NUSL = 9907)) then
        number := i;
    end
  else
    // Находим индекс поверхности "левый торец"
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
  // true, если прошли максимальный диаметр
  flagMaxDiam: boolean;
begin

  numberSurf := -1;

  // находим индекс поверхности с максимальным диаметром
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin
    if (pSurf(OutsideSurfaces[i]).PKDA = 2111) then
      numberMaxSurf := i;
  end;

  flagMaxDiam := false;
  for i := 0 to OutsideSurfaces.Count - 1 do
  begin

    // установление флага максимального диаметра
    if (pSurf(OutsideSurfaces[i]).PKDA = 2111) then
      flagMaxDiam := true;

    // если вставляемый вырез справа и вставляем после полуоткрытого цилиндра
    if ((flagMaxDiam) and (not(flagLeft))) then
    begin
      if (pSurf(OutsideSurfaces[i]).PKDA = 2112) and
        (pSurf(OutsideSurfaces[i]).point[0].Y > insertDiam) then
      begin
        numberSurf := i;
        // А здесь не выходим из цикла почему-то
        // break;
      end;
    end;

    // если вставляемый вырез слева и вставляем до полуоткрытого цилиндра
    if (not(flagMaxDiam) and (flagLeft)) then
    begin
      if (pSurf(OutsideSurfaces[i]).PKDA = 2112) and
        (pSurf(OutsideSurfaces[i]).point[0].Y > insertDiam) then
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
