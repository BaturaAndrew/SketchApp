unit ProcessTrans;

interface

uses Windows, SysUtils, Dialogs, Classes, InputData, Generics.Collections,
  SketchView;

type

  paramSurfSizes = array [0 .. 5] of single;

  // указатель на запись
  ptrTransition = InputData.ptrTrans;

  // класс обработки переходов для формирования поверхностей
  TProcessingTransition = class

    // Инициализация  входных данных
    procedure InitSQL;

  public
    // конструктор
    constructor Create;

    // Проход всех переходов для построения эскизов каждого из них
    procedure ProcessingTransition(i_transition: integer);

    function GetSurfSize(NPVA: integer): paramSurfSizes;
    function GetPKDA(NPVA: integer): integer;
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

    // Заполенение ValueListEditor1  информацией о текущем переходе
    procedure FillList(trans: ptrTransition);

    // Вычисление размера подрезки
    function CalcOutSizeTor(nomerSurf: integer): single;
    // Вычисление размера подрезки
    function CalcInSizeTor(nomerSurf: integer): single;
  public
    // Объект хранящий входные данные (информация о переходе)
    m_InputData: TInputData;

  private

    i_trans: integer;
    // итератор пропуска перехода -
    // для случая, когда для обработки требуется сразу 2 перехода
    skipTrans: integer;
  end;

implementation

{ TProcessingTransition }

uses
  SketchForm;

function TProcessingTransition.CalcInSizeTor(nomerSurf: integer): single;
var
  i: integer;
  size: single;
  NPVA: integer;
begin
  size := 0;
  NPVA := nomerSurf;

  // GetSurfSize(NPVA)[5]; [5] - PRIV
  while GetSurfSize(NPVA)[5] <> 1 do
  begin
    if (NPVA > GetSurfSize(NPVA)[5]) then
      size := size + GetSurfSize(NPVA)[0]
    else
      size := size - GetSurfSize(NPVA)[0];

    NPVA := round(GetSurfSize(NPVA)[5]);
  end;

  // if (NPVA > GetSurfSize(NPVA)[5]) then
  // size := size + GetSurfSize(NPVA)[0]
  // else
  size := GetSurfSize(NPVA)[0] - size;

  result := size;
end;

function TProcessingTransition.CalcOutSizeTor(nomerSurf: integer): single;
var
  i, j: integer;
  size, lengthDet: single;
  NPVA, NUSL: integer;
begin
  size := 0;
  NPVA := nomerSurf;

  // GetSurfSize(NPVA)[5]; [0, 1, 2, 3, 4] - размеры, [5] - PRIV
  while GetSurfSize(NPVA)[5] <> 1 do
  begin
    if (NPVA > GetSurfSize(NPVA)[5]) then
      size := size + GetSurfSize(NPVA)[0]
    else
      size := size - GetSurfSize(NPVA)[0];

    NPVA := round(GetSurfSize(NPVA)[5]);
  end;
  lengthDet := 0;
  // находим текущую длину детали
  for i := 0 to m_InputData.listSurface.Count - 1 do
  begin
    if (pSurf(m_InputData.listSurface[i]).NUSL = 9907) and
      (pSurf(m_InputData.listSurface[i]).number = NPVA) then
    begin

      // находим размер привязки
      for j := 0 to MainForm.m_sketchView.OutSurf.Count - 1 do
      begin
        if (pSurf(MainForm.m_sketchView.OutSurf[j]).NUSL = 9907) then
        begin
          lengthDet := pSurf(MainForm.m_sketchView.OutSurf[j]).point[0].X;
          break;
        end;
      end;

    end;
  end;

  if (lengthDet > 0) then
  begin
    if (NPVA > GetSurfSize(NPVA)[5]) then
      size := size + lengthDet
    else
      size := size - lengthDet;
  end
  else
  begin
    if (NPVA > GetSurfSize(NPVA)[5]) then
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

// Определение положения выемок по коду NUSL
function TProcessingTransition.PositionCut: boolean;
var
  NUSL: integer;
begin

  NUSL := m_InputData.currTrans.NUSL;
  if ((NUSL = 9906) or (NUSL = 9905) or (NUSL = 9915) or (NUSL = 9916)) then
    // выемка справа
    result := false;
  // иначе - слева
  if ((NUSL = 9902) or (NUSL = 9903) or (NUSL = 9912) or (NUSL = 9913)) then
    result := true;

end;

procedure TProcessingTransition.ProcessingTransition(i_transition: integer);
var
  str: string;
  PKDA: integer;
begin

  // очищаем данные о предыдущих переходах.
  m_InputData.ClearPrevTransitions;
  // очищаем ValueListEditor1
  while MainForm.ValueListEditor1.Strings.Count > 0 do
    MainForm.ValueListEditor1.DeleteRow(1);

  // номер обрабатываемо перехода.
  // Когда skipTrans>0, тогда пропускаем соответствующее количество переходов
  i_trans := i_transition + skipTrans;

  if ((i_trans) < (m_InputData.countTransitions)) then
  begin

    // Читаем данные текущего перехода в  переменную currTrans
    m_InputData.ReadCurrentTransition(m_InputData.currTrans, i_trans);

    PKDA := m_InputData.currTrans.PKDA;

    // Если подрезаем левый или правый торец
    if (PKDA = 2131) then
      CutTorec;

    // Если точим максимальный цилиндр
    if ((PKDA = 2111) and (m_InputData.currTrans.SizesFromTP[0] > 0)) then
      CutCylinder;

    // Если точим внешний конус
    if (PKDA = 2122) then
      MakeOutCon;

    // проверяем, что делаем:
    begin
      // полуоткрытый цилиндр
      begin
        // если в переходах первый переход - "точить"
        if ((PKDA = 2112) or (PKDA = 3212) or (PKDA = 3222)) then
          // и новый цилиндр - не закрытый
          if not(IsClosed(m_InputData.currTrans.NPVA)) then
            MakeOutHalfOpenCyl;
        // если в переходах первый переход - "подрезать"
        if (PKDA = 2132) then
          // и новый цилиндр - не закрытый
          if not(IsClosed(m_InputData.currTrans.R_POVV)) then
            MakeOutHalfOpenCyl;
      end;

      // или закрытый  цилиндр
      if (PKDA = 2112) then
        if (IsClosed(m_InputData.currTrans.NPVA)) then
          MakeOutClosedCyl;
    end;

    // Если делаем вырезы
    str := IntToStr(PKDA);
    if (PKDA < 0) then
      // делаем сквозное отверстие
      if (str[str.length] = '1') then
        MakeInOpenCyl
        // делаем внутренний полуоткрытый цилиндр
      else if (str[str.length] = '2') then
        MakeInHalfOpenCyl;

  end;
end;

// Подрезать торец
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

// Вывод информации о текущем переходе
procedure TProcessingTransition.FillList(trans: ptrTransition);
var
  s1, s2: string;
begin

  begin
    MainForm.ValueListEditor1.InsertRow('',
      'Переход №  ' + i_trans.ToString, true);
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
  for i := 0 to 5 do
    mass[i] := 0;

  // находим размеры поверхности
  for i := 0 to m_InputData.listSurface.Count - 1 do
    if (pSurf(m_InputData.listSurface[i]).number = NPVA) then
    begin
      mass[0] := pSurf(m_InputData.listSurface[i]).Sizes[0];
      mass[1] := pSurf(m_InputData.listSurface[i]).Sizes[1];
      mass[2] := pSurf(m_InputData.listSurface[i]).Sizes[2];
      mass[3] := pSurf(m_InputData.listSurface[i]).Sizes[3];
      mass[4] := pSurf(m_InputData.listSurface[i]).Sizes[4];
      mass[5] := pSurf(m_InputData.listSurface[i]).PRIV;
      break;
    end;

  result := mass;

end;

procedure TProcessingTransition.InitSQL;
var
  detal: integer;
begin

  m_InputData := TInputData.Create;
  i_trans := 0;
  skipTrans := 0;
  detal := StrToInt(MainForm.Kod_detal.Text);
  // Читаем данные о технологических переходах для детали с кодом Kod_detal
  m_InputData.ReadSQLDataTransitions(detal);

end;

function TProcessingTransition.IsClosed(NPVA: integer): boolean;
var
  i: integer;
  NPVA_PrevCylindr, NPVA_NextCylindr: integer;
  diam, diamPrevCylindr, diamNextCylindr: single;
  PKDA: integer;
begin

  NPVA_PrevCylindr := NPVA - 2;
  NPVA_NextCylindr := NPVA + 2;
  diamPrevCylindr := 0;
  diamNextCylindr := 0;
  // Отыскиваем диаметры предыдущего и следующего цилиндров
  for i := 0 to m_InputData.listSurface.Count - 1 do
  begin
    if (pSurf(m_InputData.listSurface[i]).number = NPVA) then
      diam := pSurf(m_InputData.listSurface[i]).Sizes[0];

    PKDA := pSurf(m_InputData.listSurface[i]).PKDA;

    if (pSurf(m_InputData.listSurface[i]).number = NPVA_PrevCylindr) and
      ((PKDA = 2112) or (PKDA = 2111) or (PKDA = 2122)) then
      diamPrevCylindr := pSurf(m_InputData.listSurface[i]).Sizes[0];

    if (pSurf(m_InputData.listSurface[i]).number = NPVA_NextCylindr) and
      ((PKDA = 2112) or (PKDA = 2111) or (PKDA = 2122)) then
      diamNextCylindr := pSurf(m_InputData.listSurface[i]).Sizes[0];

  end;
  if (diamPrevCylindr <> 0) and (diamNextCylindr <> 0) then
  begin
    // если диаметр текущего цилиндра меньше диаметров предыдущего и следующего, то закрытый цилиндр
    if (diam < diamPrevCylindr) and (diam < diamNextCylindr) then
      result := true
    else
      result := false;
  end
  else
    result := false;

end;

function TProcessingTransition.GetPKDA(NPVA: integer): integer;
var
  i: integer;
begin

  for i := 0 to m_InputData.listSurface.Count - 1 do
    if (pSurf(m_InputData.listSurface[i]).number = NPVA) then
      result := pSurf(m_InputData.listSurface[i]).PKDA;

end;

// Вставка закрытого цилиндра
procedure TProcessingTransition.MakeOutClosedCyl;
var
  i: integer;
  // если true, то вырез слева, иначе - справа
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPovTorec: integer;
  // номера привязочных поверхностей
  numPrivLeft, numPrivRight: integer;
  leftTor, diamClosedCyl, lengthClosedCylindr, rightTorec, diamHalfopenedCyl,
    lengthHalfopenedCyl: single;
begin

  // читаем данные перехода, связанного  с текущим
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1);
  // читаем данные перехода, связанного  с текущим
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans2, i_trans + 2);

  // определение положение закрытого цилиндра
  flagLeft := PositionCut;

  diamClosedCyl := m_InputData.currTrans.SizesFromTP[0];
  lengthClosedCylindr := GetSurfSize(m_InputData.currTrans.NPVA)[1];
  diamHalfopenedCyl := m_InputData.joinTrans2.SizesFromTP[0];
  lengthHalfopenedCyl := GetSurfSize(m_InputData.joinTrans2.NPVA)[1];

  // Вычисляем размеры для торцев в зависимости от расположения относительно макс. диаметра
  if flagLeft then
  begin
    // leftTor := CalculatedSizePodrez(m_InputData.currTrans.L_POVB);
    leftTor := m_InputData.joinTrans.SizesFromTP[2];
    rightTorec := CalcOutSizeTor(m_InputData.joinTrans.NPVA);
  end
  else if not(flagLeft) then
  begin
    // leftTor := CalculatedSizePodrez(m_InputData.joinTrans.NPVA);
    leftTor := m_InputData.joinTrans.SizesFromTP[2];
    rightTorec := CalcOutSizeTor(m_InputData.currTrans.L_POVB);
  end;

  MainForm.m_sketchView.Insert_OutClosedSurf(m_InputData.currTrans, flagLeft,
    numPrivLeft, numPrivRight, leftTor, diamClosedCyl, lengthClosedCylindr,
    rightTorec, diamHalfopenedCyl, lengthHalfopenedCyl);

  FillList(m_InputData.currTrans);
  FillList(m_InputData.joinTrans);
  FillList(m_InputData.joinTrans2);

  // если делаем закрытый цилиндр, то обрабатываем сразу 3 перехода и два перехода пропускаем
  skipTrans := skipTrans + 2;

end;

procedure TProcessingTransition.MakeOutCon;
var
  i: integer;
  // если true, то вырез слева, иначе - справа
  flagLeft: boolean;

  P1, P2: TPOINT;
  d_con: single;
begin

  // читаем данные перехода, связанного  с текущим
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans - 1);
  // читаем данные перехода, связанного  с текущим
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans2, i_trans - 2);

  // определение положения конуса
  flagLeft := PositionCut;

  // P1.Y := round(m_InputData.currTrans.SizesFromTP[0]);
  if (GetSurfSize(m_InputData.currTrans.NPVA)[0] <
    GetSurfSize(m_InputData.currTrans.NPVA)[4]) then
    d_con := GetSurfSize(m_InputData.currTrans.NPVA)[4]
  else
    d_con := GetSurfSize(m_InputData.currTrans.NPVA)[0];

  P1.Y := round(d_con);
  // P1.X := round(m_InputData.joinTrans2.SizesFromTP[2]);
  P1.X := round(CalcOutSizeTor(m_InputData.currTrans.R_POVV));

  if (flagLeft) then
    P2.X := P1.X - round(GetSurfSize(m_InputData.currTrans.NPVA)[1])
  else if (not(flagLeft)) then
    P2.X := P1.X + round(GetSurfSize(m_InputData.currTrans.NPVA)[1]);

  P2.Y := round(m_InputData.joinTrans.SizesFromTP[0]);
  // проекция длины конуса
  // P2.X := round(m_InputData.currTrans.SizesFromTP[1]);
  // P2.X := round(GetSurfSize(m_InputData.currTrans.NPVA)[1]);
  MainForm.m_sketchView.Insert_OutCon(m_InputData.currTrans, flagLeft, P1, P2);

  FillList(m_InputData.currTrans);
end;

procedure TProcessingTransition.MakeOutHalfOpenCyl;
var
  i: integer;
  // если true, то вырез слева, иначе - справа
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPovTorec: integer;
  nomerPriv: integer;
  NPVA, PKDA, POVB, POVV: integer;
  d1_con, d2_con, horizProjection: integer;
  existCon: boolean;
  P1, P2: TPOINT;
begin
  existCon := false;

  NPVA := m_InputData.currTrans.NPVA;
  PKDA := m_InputData.currTrans.PKDA;
  POVB := m_InputData.currTrans.L_POVB;
  POVV := m_InputData.currTrans.R_POVV;

  // Условие, когда для отрисовки эскиза нужна информация о 2-м переходе
  if (((PKDA = 2112) or (PKDA = 3222)) and
    (m_InputData.currTrans.SizesFromTP[2] = 0) and
    (m_InputData.currTrans.SizesFromTP[0] > 0)) then
  begin
    if (m_InputData.countTransitions > i_trans + 1) then
      // если цилиндр между торцами
      if (((GetPKDA(POVB) = 2132) or ((GetPKDA(POVB) = 2131))) and
        ((GetPKDA(POVV) = 2132) or ((GetPKDA(POVV) = 2131)))) then
        // читаем данные перехода, связанного  с текущим
        m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1)
        // иначе между торцем и цилиндром
      else
      begin
        existCon := true;
        m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1)
      end;
  end;
  if (PKDA = 2132) then
  begin
    if (m_InputData.countTransitions > i_trans + 1) then
      m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1);
  end;

  // определение положение выемок
  flagLeft := PositionCut;

  if not(existCon) then
  begin

    // Если  обрабатываем 1 переход
    // в переходе сразу точим цилиндр и подрезаем торец
    if (((PKDA = 2112) or (PKDA = 3212)) and
      // (когда в переходе "точить..." есть размер ..TP14 )
      (m_InputData.currTrans.SizesFromTP[2] <> 0)) then
    begin

      podrezTorec := CalcOutSizeTor(m_InputData.currTrans.R_POVV);
      tochitPover := m_InputData.currTrans.SizesFromTP[0];
      // номер поверхности нового торца
      if not(flagLeft) then
        nomerPovTorec := NPVA - 1
      else
        nomerPovTorec := NPVA + 1;

      MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.currTrans,
        flagLeft, nomerPovTorec, podrezTorec, tochitPover);

      FillList(m_InputData.currTrans);
    end

    // Если обрабатываем 2 перехода
    else
    begin

      // Рассматриваем первый переход из пары
      if (PKDA = 2132) then
      begin
        // новая длина детали
        podrezTorec := CalcOutSizeTor(NPVA);
        // на сколько подрезаем цилиндр
        tochitPover := m_InputData.joinTrans.SizesFromTP[0];
        // номер поверхности нового торца
        nomerPovTorec := NPVA;

        // вставляем поверхности
        MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.currTrans,
          flagLeft, nomerPovTorec, podrezTorec, tochitPover);

        // если делая выемку обрабатываем сразу 2 перехода, то один переход пропускаем
        skipTrans := skipTrans + 1;
      end;

      // Рассматриваем второй переход из пары
      if (m_InputData.joinTrans.PKDA = 2132) then
      begin
        podrezTorec := CalcOutSizeTor(m_InputData.joinTrans.NPVA);
        tochitPover := m_InputData.currTrans.SizesFromTP[0];
        nomerPovTorec := m_InputData.joinTrans.NPVA;

        MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.joinTrans,
          flagLeft, nomerPovTorec, podrezTorec, tochitPover);

        skipTrans := skipTrans + 1;
      end;

      FillList(m_InputData.currTrans);
      FillList(m_InputData.joinTrans);
    end;

  end // закрываем if not(existCyl)
  // если подрезаемый цилиндр между торцем и конусом
  else
  begin

    // проходим поверхности и ищим  конус
    for i := 0 to m_InputData.listSurface.Count - 1 do
      if (pSurf(m_InputData.listSurface[i]).number = POVV) then
      begin
        d1_con := round(pSurf(m_InputData.listSurface[i]).Sizes[0]);
        d2_con := round(pSurf(m_InputData.listSurface[i]).Sizes[4]);
        horizProjection := round(pSurf(m_InputData.listSurface[i]).Sizes[1]);
      end;

    podrezTorec := CalcOutSizeTor(m_InputData.currTrans.L_POVB);

    if (flagLeft) then
      podrezTorec := podrezTorec + GetSurfSize(NPVA)[1]
    else if (not(flagLeft)) then
      podrezTorec := podrezTorec - GetSurfSize(NPVA)[1];

    tochitPover := m_InputData.currTrans.SizesFromTP[0];
    nomerPovTorec := NPVA;

    // координаты цилиндра
    P1.X := round(podrezTorec);
    P2.X := round(podrezTorec);
    P1.Y := round(tochitPover);
    P2.Y := round(tochitPover);
    MainForm.m_sketchView.Insert_Cyl(NPVA, flagLeft, P1, P2);

    // координаты конуса
    P1.Y := round(m_InputData.currTrans.SizesFromTP[0]);
    P1.X := round(podrezTorec);

    if (d1_con > d2_con) then
      P2.Y := d1_con
    else
      P2.Y := d2_con;

    if (flagLeft) then
      P2.X := P1.X + horizProjection
    else
      P2.X := P1.X - horizProjection;
    MainForm.m_sketchView.Insert_Con(POVB, flagLeft, P1, P2);

    skipTrans := skipTrans + 1;
  end;
end;

// Вставка внутреннего полуоткрытого цилиндра
procedure TProcessingTransition.MakeInHalfOpenCyl;
var
  i: integer;
  // если true, то вырез слева, иначе - справа
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPovTorec: integer;
begin

  // Условие, когда для отрисовки эскиза нужна пара связанных переходов
  // (точить поверхность и подрезать торец)
  if ((m_InputData.currTrans.PKDA = -2132) or
    ((m_InputData.currTrans.PKDA = -2112) and (m_InputData.currTrans.SizesFromTP
    [2] = 0))) then
    // читаем данные перехода, связанного  с текущим
    m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1);

  // определение положения выреза
  flagLeft := PositionCut;

  // Если в переходе сразу точим цилиндр и подрезаем торец
  if (m_InputData.currTrans.PKDA = -3212) then
  begin
    MainForm.m_sketchView.Insert_InHalfopenSurf(m_InputData.currTrans,
      flagLeft);

    FillList(m_InputData.currTrans);
  end
  else // Если обрабатываем за 2 перехода
    // Рассматриваем первый переход из пары
    if (m_InputData.currTrans.PKDA = -2132) then
    begin

      // Вычисляем размер подрезки в зависимости от расположения относительно макс. диаметра

      // новая длина детали
      // podrezTorec := m_InputData.currTrans.SizesFromTP[2];
      podrezTorec := CalcInSizeTor(m_InputData.currTrans.NPVA);

      // на сколько подрезаем цилиндр
      tochitPover := m_InputData.joinTrans.SizesFromTP[0];
      // номер поверхности нового торца
      nomerPovTorec := m_InputData.currTrans.NPVA;

      // вставляем поверхности
      MainForm.m_sketchView.Insert_InHalfopenSurf(m_InputData.currTrans,
        flagLeft, nomerPovTorec, podrezTorec, tochitPover);
      // если делая выемку обрабатываем сразу 2 перехода, то один переход пропускаем
      skipTrans := skipTrans + 1;
    end
    else
      // Рассматриваем второй переход из пары
      if (m_InputData.joinTrans.PKDA = -2132) then
      begin
        podrezTorec := CalcInSizeTor(m_InputData.joinTrans.NPVA);
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

// Вставка внутреннего открытого цилиндра
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
