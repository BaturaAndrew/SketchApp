unit ProcessTrans;

interface

uses
  Windows, SysUtils, Dialogs, Classes, InputData, SketchView;

type

  // класс обработки переходов для формирования поверхностей
  TProcessingTransition = class

    // Инициализация  входных данных
    procedure InitSQL;
  public
    // конструктор
    constructor Create;

    // Проход всех переходов для построения эскизов каждого из них
    procedure ProcessingTransition(i_transition: integer);
    function GetSurfParam(NPVA: integer): psurf;
  private
    procedure MakeOutHalfOpenCyl;
    procedure MakeOutClosedCyl;
    procedure MakeOutCon_Tor_and_Cyl;
    procedure MakeOutCon_Tor_and_Tor;
    procedure MakeOutCon_Tor_and_Tor1;
    procedure MakeOutTor;
    procedure MakeOutCyl;
    procedure CutTorec;
    procedure CutCylinder;
    procedure MakeInOpenCyl;
    procedure MakeInHalfOpenCyl;

    // Вспомогательные методы

    // Заполенение ValueListEditor1  информацией о текущем переходе
    procedure FillList(trans: InputData.ptrTrans);
    // определение позиции для вставки
    function PositionCut: boolean;
     //  определиние, закрытый вырез или полуоткрытый
    function IsClosed(NPVA: integer): boolean;
    // Вычисление размера подрезки
    function CalcOutSizeTor(nomerSurf: integer): single;
    // Вычисление размера внутренней подрезки
    function CalcInSizeTor(nomerSurf: integer): single;
    // Между какими поверхностями расположен конус
    function Between_the_Cone(NPVA: integer): integer;
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

function TProcessingTransition.Between_the_Cone(NPVA: integer): integer;
var
  i: integer;
  size: single;
  POVV, POVB, PKDA_POVV, PKDA_POVB: Integer;
begin
// находим POVB и POVV
  for i := 0 to m_InputData.listSurface.Count - 1 do
    if (pSurf(m_InputData.listSurface[i]).number = NPVA) then
    begin
      POVV := pSurf(m_InputData.listSurface[i]).R_POVV;
      POVB := pSurf(m_InputData.listSurface[i]).L_POVB;
      break;
    end;
  PKDA_POVB := GetSurfParam(POVB).PKDA;
  PKDA_POVV := GetSurfParam(POVV).PKDA;
  if ((PKDA_POVV = 2131) or (PKDA_POVV = 2132)) and ((PKDA_POVB = 2131) or (PKDA_POVB =
    2132)) then
   // конус между торцами
    Result := 1;

  if ((PKDA_POVV = 2131) or (PKDA_POVV = 2132)) and ((PKDA_POVB = 2112) or (PKDA_POVB =
    2111)) or ((PKDA_POVB = 2131) or (PKDA_POVB = 2132)) and ((PKDA_POVV = 2112) or (PKDA_POVV
    = 2111)) then
   // конус между цилиндром и торцем
    Result := 2;

  if ((PKDA_POVV = 2112) or (PKDA_POVV = 2111)) and ((PKDA_POVB = 2112) or (PKDA_POVB =
    2111)) then
   // конус между конусами
    Result := 3;
end;

function TProcessingTransition.CalcInSizeTor(nomerSurf: integer): single;
var
  i: integer;
  size: single;
  NPVA: integer;
begin
  size := 0;
  NPVA := nomerSurf;

  while GetSurfParam(NPVA).PRIV <> 1 do
  begin
    if (NPVA > GetSurfParam(NPVA).PRIV) then
      size := size + GetSurfParam(NPVA).Sizes[0]
    else
      size := size - GetSurfParam(NPVA).Sizes[0];

    NPVA := round(GetSurfParam(NPVA).PRIV);
  end;

  size := GetSurfParam(NPVA).Sizes[0] - size;

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

  while GetSurfParam(NPVA).PRIV <> 1 do
  begin
    if (NPVA > GetSurfParam(NPVA).PRIV) then
      size := size + GetSurfParam(NPVA).Sizes[0]
    else
      size := size - GetSurfParam(NPVA).Sizes[0];

    NPVA := round(GetSurfParam(NPVA).PRIV);
  end;
  lengthDet := 0;
  // находим текущую длину детали
  for i := 0 to m_InputData.listSurface.Count - 1 do
  begin
    if (pSurf(m_InputData.listSurface[i]).NUSL = 9907) and (pSurf(m_InputData.listSurface[i]).number
      = NPVA) then
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
    if (NPVA > GetSurfParam(NPVA).PRIV) then
      size := size + lengthDet
    else
      size := size - lengthDet;
  end
  else
  begin
    if (NPVA > GetSurfParam(NPVA).PRIV) then
      size := size + GetSurfParam(NPVA).Sizes[0]
    else
      size := size - GetSurfParam(NPVA).Sizes[0];
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
  PKDA, PKDA_L, PKDA_R: integer;
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
    if (PKDA = 2122) and (Between_the_Cone(m_InputData.currTrans.NPVA) = 2) then
      MakeOutCon_Tor_and_Cyl;
    if (PKDA = 2122) and (Between_the_Cone(m_InputData.currTrans.NPVA) = 1) then
      MakeOutCon_Tor_and_Tor1;

    PKDA_L := GetSurfParam(m_InputData.currTrans.L_POVB).PKDA;
    PKDA_R := GetSurfParam(m_InputData.currTrans.R_POVV).PKDA;
    // проверяем, что делаем:
    begin
      // полуоткрытый цилиндр
      begin
        // если в переходах первый переход - "точить"
        if ((PKDA = 2112) or (PKDA = 3212) or (PKDA = 3222)) then
          // и новый цилиндр - не закрытый
          if not (IsClosed(m_InputData.currTrans.NPVA)) then
            MakeOutHalfOpenCyl;
        // если в переходах первый переход - "подрезать"
        if (PKDA = 2132) then
        // полуоткрытый торец между цилиндрами
          if ((PKDA_L = 2112) or (PKDA_L = 1711) or (PKDA_L = 2111)) and ((PKDA_R = 2112)
            or (PKDA_R = 1711) or (PKDA_R = 2111)) then
          begin
          // и новый цилиндр - не закрытый
            if not (IsClosed(m_InputData.currTrans.R_POVV)) then
              MakeOutHalfOpenCyl;
          end
          //? Вставить условие сравнения поверхностей, между которыми расположен торец
          // торец связан с конусом. Конус между торцами
          else if Between_the_Cone(m_InputData.currTrans.R_POVV) = 1 then
            MakeOutCon_Tor_and_Tor
          //?
          // торец связан с конусом. Конус между цилиндром и торцем
          else if Between_the_Cone(m_InputData.currTrans.R_POVV) = 2 then
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
procedure TProcessingTransition.FillList(trans: InputData.ptrTrans);
var
  s1, s2: string;
begin

  begin
    MainForm.ValueListEditor1.InsertRow('', 'Переход №  ' + FloatToStr(i_trans), true);
    MainForm.ValueListEditor1.InsertRow('NPVA', FloatToStr(trans.NPVA), true);
    MainForm.ValueListEditor1.InsertRow('L_POVB', FloatToStr(trans.L_POVB), true);
    MainForm.ValueListEditor1.InsertRow('R_POVV', FloatToStr(trans.R_POVV), true);
    MainForm.ValueListEditor1.InsertRow('PKDA', FloatToStr(trans.PKDA), true);
    MainForm.ValueListEditor1.InsertRow('NUSL', FloatToStr(trans.NUSL), true);
    MainForm.ValueListEditor1.InsertRow('PRIV', FloatToStr(trans.PRIV), true);
    MainForm.ValueListEditor1.InsertRow('Razm1; Razm2; Razm3;', FloatToStr(trans.SizesFromTP
      [0]) + ';    ' + FloatToStr(trans.SizesFromTP[1]) + ';    ' + FloatToStr(trans.SizesFromTP
      [2]), true);

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

function TProcessingTransition.GetSurfParam(NPVA: integer): psurf;
var
  i: integer;
  surfase: psurf;
begin
  surfase := nil;
  new(surfase);

  // находим параметры поверхности
  for i := 0 to m_InputData.listSurface.Count - 1 do
    if (pSurf(m_InputData.listSurface[i]).number = NPVA) then
    begin
      surfase.number := pSurf(m_InputData.listSurface[i]).number;
      surfase.L_POVB := pSurf(m_InputData.listSurface[i]).L_POVB;
      surfase.R_POVV := pSurf(m_InputData.listSurface[i]).R_POVV;
      surfase.PKDA := pSurf(m_InputData.listSurface[i]).PKDA;
      surfase.NUSL := pSurf(m_InputData.listSurface[i]).NUSL;
      surfase.PRIV := pSurf(m_InputData.listSurface[i]).PRIV;
      surfase.Sizes[0] := pSurf(m_InputData.listSurface[i]).Sizes[0];
      surfase.Sizes[1] := pSurf(m_InputData.listSurface[i]).Sizes[1];
      surfase.Sizes[2] := pSurf(m_InputData.listSurface[i]).Sizes[2];
      surfase.Sizes[3] := pSurf(m_InputData.listSurface[i]).Sizes[3];
      surfase.Sizes[4] := pSurf(m_InputData.listSurface[i]).Sizes[4];
      break;
    end;

  result := surfase;

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

    if (pSurf(m_InputData.listSurface[i]).number = NPVA_PrevCylindr) and ((PKDA = 2112) or
      (PKDA = 2111) or (PKDA = 2122)) then
      diamPrevCylindr := pSurf(m_InputData.listSurface[i]).Sizes[0];

    if (pSurf(m_InputData.listSurface[i]).number = NPVA_NextCylindr) and ((PKDA = 2112) or
      (PKDA = 2111) or (PKDA = 2122)) then
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
  lengthClosedCylindr := GetSurfParam(m_InputData.currTrans.NPVA).Sizes[1];
  diamHalfopenedCyl := m_InputData.joinTrans2.SizesFromTP[0];
  lengthHalfopenedCyl := GetSurfParam(m_InputData.joinTrans2.NPVA).Sizes[1];

  // Вычисляем размеры для торцев в зависимости от расположения относительно макс. диаметра
  if flagLeft then
  begin
    // leftTor := CalculatedSizePodrez(m_InputData.currTrans.L_POVB);
    leftTor := m_InputData.joinTrans.SizesFromTP[2];
    rightTorec := CalcOutSizeTor(m_InputData.joinTrans.NPVA);
  end
  else if not (flagLeft) then
  begin
    // leftTor := CalculatedSizePodrez(m_InputData.joinTrans.NPVA);
    leftTor := m_InputData.joinTrans.SizesFromTP[2];
    rightTorec := CalcOutSizeTor(m_InputData.currTrans.L_POVB);
  end;

  MainForm.m_sketchView.Insert_OutClosedSurf(m_InputData.currTrans, flagLeft, numPrivLeft,
    numPrivRight, leftTor, diamClosedCyl, lengthClosedCylindr, rightTorec,
    diamHalfopenedCyl, lengthHalfopenedCyl);

  FillList(m_InputData.currTrans);
  FillList(m_InputData.joinTrans);
  FillList(m_InputData.joinTrans2);

  // если делаем закрытый цилиндр, то обрабатываем сразу 3 перехода и два перехода пропускаем
  skipTrans := skipTrans + 2;

end;

procedure TProcessingTransition.MakeOutCon_Tor_and_Cyl;
var
  i: integer;
  // если true, то вырез слева, иначе - справа
  flagLeft: boolean;
  P1, P2: TPOINT;
  //d_con: single;
  faceOfReference: integer;
begin
  // читаем данные перехода, связанного  с текущим
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans - 1);
  // читаем данные перехода, связанного  с текущим
  m_InputData.ReadCurrentTransition(m_InputData.joinTrans2, i_trans - 2);

  // определение положения конуса
  flagLeft := PositionCut;

//  // P1.Y := round(m_InputData.currTrans.SizesFromTP[0]);
//  if (GetSurfSize(m_InputData.currTrans.NPVA)[0] < GetSurfSize(m_InputData.currTrans.NPVA)[4]) then
//    d_con := GetSurfSize(m_InputData.currTrans.NPVA)[4]
//  else
//    d_con := GetSurfSize(m_InputData.currTrans.NPVA)[0];

  // P1.Y := round(d_con);
  P1.Y := round(m_InputData.currTrans.SizesFromTP[0]);
  // P1.X := round(m_InputData.joinTrans2.SizesFromTP[2]);
  P1.X := round(CalcOutSizeTor(m_InputData.currTrans.R_POVV));

  if (flagLeft) then
    P2.X := P1.X - round(GetSurfParam(m_InputData.currTrans.NPVA).Sizes[1])
  else if (not (flagLeft)) then
    P2.X := P1.X + round(GetSurfParam(m_InputData.currTrans.NPVA).Sizes[1]);

  P2.Y := round(m_InputData.joinTrans.SizesFromTP[0]);
  // проекция длины конуса
  // P2.X := round(m_InputData.currTrans.SizesFromTP[1]);
  // P2.X := round(GetSurfSize(m_InputData.currTrans.NPVA)[1]);

  // от какого торца отсчитываем подрезку
  faceOfReference := round(GetSurfParam(m_InputData.currTrans.R_POVV).PRIV);

  MainForm.m_sketchView.Insert_OutCon(m_InputData.currTrans, flagLeft, P1, P2,
    faceOfReference);

  FillList(m_InputData.currTrans);
end;

procedure TProcessingTransition.MakeOutCon_Tor_and_Tor;
var
  i: integer;
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPov: integer;
  NPVA, PKDA, POVB, POVV: integer;
  P1, P2: TPOINT;
  faceOfReference: integer;
  d_con: single;
begin

// Вставляем торец
  begin
    nomerPov := m_InputData.currTrans.NPVA;
  // определение положение выемок
    flagLeft := PositionCut;

    podrezTorec := m_InputData.currTrans.SizesFromTP[2];
  // берем величину подрезки из перехода "точить конус"
    for i := 0 to m_InputData.countTransitions - 1 do
    begin
      if ptrTrans(m_InputData.listTrans[i]).NPVA = m_InputData.currTrans.R_POVV then
      begin
        tochitPover := ptrTrans(m_InputData.listTrans[i]).SizesFromTP[0];
        Break;
      end;
    end;

   // P1.Y :=
    P1.X := Round(podrezTorec);
    P2.Y := Round(tochitPover);
    P2.X := Round(podrezTorec);

    MainForm.m_sketchView.Insert_Tor(nomerPov, flagLeft, P1, P2);

    FillList(m_InputData.currTrans);
  end;

  // Вставляем конус
  begin
   // читаем данные перехода "точить конус"
    m_InputData.ReadCurrentTransition(m_InputData.currTrans, i_trans + 1);
   // пропускаем один переход
    skipTrans := skipTrans + 1;
    nomerPov := m_InputData.currTrans.NPVA;
   // определение положения конуса
    flagLeft := PositionCut;

    P1.Y := round(m_InputData.currTrans.SizesFromTP[0]);

   // берем величину подрезки из перехода "подрезать торец"
    for i := 0 to m_InputData.countTransitions - 1 do
    begin
      if ptrTrans(m_InputData.listTrans[i]).NPVA = m_InputData.currTrans.R_POVV then
      begin
        P1.X := Round(ptrTrans(m_InputData.listTrans[i]).SizesFromTP[2]);
        Break;
      end;
    end;

    if (flagLeft) then
      P2.X := P1.X - round(GetSurfParam(m_InputData.currTrans.NPVA).Sizes[1])
    else if (not (flagLeft)) then
      P2.X := P1.X + round(GetSurfParam(m_InputData.currTrans.NPVA).Sizes[1]);

    if (GetSurfParam(m_InputData.currTrans.NPVA).Sizes[0] > GetSurfParam(m_InputData.currTrans.NPVA).Sizes
      [4]) then
      d_con := GetSurfParam(m_InputData.currTrans.NPVA).Sizes[4]
    else
      d_con := GetSurfParam(m_InputData.currTrans.NPVA).Sizes[0];

    P2.Y := round(d_con);

   // от какого торца отсчитываем подрезку
    faceOfReference := round(GetSurfParam(m_InputData.currTrans.R_POVV).PRIV);

    MainForm.m_sketchView.Insert_OutCon(m_InputData.currTrans, flagLeft, P1, P2,
      faceOfReference);
    FillList(m_InputData.currTrans);
  end;

  // Вставляем цилиндр
  begin
   // координаты цилиндра
    P1.X := P2.X;
    P1.Y := P2.Y;  // P2.Y у цилиндра как и у конуса

    // +2 потому что конус расположен между торцем и торцем, значит следующий за торцем
    // вставляемый цилиндр имеет нумерацию Nконуса + 2
    nomerPov := m_InputData.currTrans.NPVA + 2;
   // находим P2.X
    for i := 0 to MainForm.m_sketchView.OutSurf.Count - 1 do
    begin
      if ((pSurf(MainForm.m_sketchView.OutSurf[i]).PKDA = 2132) or (pSurf(MainForm.m_sketchView.OutSurf
        [i]).PKDA = 2131)) and (pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X > P1.X) then
      begin
        P2.X := pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X;
        break;
      end;
    end;

    // Если первая координата цилидра при вырезе справа равна длине детали, то цилиндр не вставляем
    if not (P2.X = P1.X + MainForm.m_sketchView.razmLeftPodrez) then
      MainForm.m_sketchView.Insert_Cyl(nomerPov, flagLeft, P1, P2);
  end;
end;

procedure TProcessingTransition.MakeOutCon_Tor_and_Tor1;
var
  i: integer;
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPov: integer;
  NPVA, PKDA, POVB, POVV: integer;
  P1, P2: TPOINT;
  faceOfReference: integer;
  d_con: single;
begin

  // Вставляем конус
  begin

    nomerPov := m_InputData.currTrans.NPVA;
   // определение положения конуса
    flagLeft := PositionCut;

    P1.Y := round(m_InputData.currTrans.SizesFromTP[0]);

   // берем величину подрезки из перехода "подрезать торец"
    for i := i_trans to m_InputData.countTransitions - 1 do
    begin
      if ptrTrans(m_InputData.listTrans[i]).NPVA = m_InputData.currTrans.R_POVV then
      begin
        P1.X := Round(ptrTrans(m_InputData.listTrans[i]).SizesFromTP[2]);
        Break;
      end;
    end;

    if (flagLeft) then
      P2.X := P1.X - round(GetSurfParam(m_InputData.currTrans.NPVA).Sizes[1])
    else if (not (flagLeft)) then
      P2.X := P1.X + round(GetSurfParam(m_InputData.currTrans.NPVA).Sizes[1]);

    if (GetSurfParam(m_InputData.currTrans.NPVA).Sizes[0] > GetSurfParam(m_InputData.currTrans.NPVA).Sizes
      [4]) then
      d_con := GetSurfParam(m_InputData.currTrans.NPVA).Sizes[4]
    else
      d_con := GetSurfParam(m_InputData.currTrans.NPVA).Sizes[0];

    P2.Y := round(d_con);

   // от какого торца отсчитываем подрезку
    faceOfReference := round(GetSurfParam(m_InputData.currTrans.R_POVV).PRIV);

    MainForm.m_sketchView.Insert_OutCon(m_InputData.currTrans, flagLeft, P1, P2,
      faceOfReference);
    FillList(m_InputData.currTrans);
  end;

  // Вставляем цилиндр
  begin
   // координаты цилиндра
    P1.X := P2.X;
    P1.Y := P2.Y;

    if (flagLeft) then
      nomerPov := m_InputData.currTrans.NPVA - 2
    else
      nomerPov := m_InputData.currTrans.NPVA + 1;

   // находим P2.X
    for i := 0 to MainForm.m_sketchView.OutSurf.Count - 1 do
    begin
      if not (flagLeft) then
        if ((pSurf(MainForm.m_sketchView.OutSurf[i]).PKDA = 2132) or (pSurf(MainForm.m_sketchView.OutSurf
          [i]).PKDA = 2131)) and (pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X > P1.X)
          then
        begin
          P2.X := pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X;
          break;
        end;
      if (flagLeft) then
        if ((pSurf(MainForm.m_sketchView.OutSurf[i]).PKDA = 2132) or (pSurf(MainForm.m_sketchView.OutSurf
          [i]).PKDA = 2131)) and (pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X < P2.X)
          then
        begin
          P1.X := pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X;
          break;
        end;

    end;
    MainForm.m_sketchView.Insert_Cyl(nomerPov, flagLeft, P1, P2);
  end;

  // Вставляем торец
  begin
    // читаем данные перехода "точить конус"
    m_InputData.ReadCurrentTransition(m_InputData.currTrans, i_trans + 1);

    nomerPov := m_InputData.currTrans.NPVA;
  // определение положение выемок
    flagLeft := PositionCut;

    podrezTorec := m_InputData.currTrans.SizesFromTP[2];
  // берем величину подрезки из перехода "точить конус"
    for i := i_trans to m_InputData.countTransitions - 1 do
    begin
      if ptrTrans(m_InputData.listTrans[i]).NPVA = m_InputData.currTrans.R_POVV then
      begin
        tochitPover := ptrTrans(m_InputData.listTrans[i]).SizesFromTP[0];
        Break;
      end;
    end;

   // P1.Y :=
    P1.X := Round(podrezTorec);
    P2.Y := Round(tochitPover);
    P2.X := Round(podrezTorec);

    MainForm.m_sketchView.Insert_Tor(nomerPov, flagLeft, P1, P2);

    FillList(m_InputData.currTrans);

    // пропускаем один переход
    skipTrans := skipTrans + 1;
  end;

end;

procedure TProcessingTransition.MakeOutCyl;
var
  i: integer;
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPovTorec: integer;
  nomerPriv: integer;
  NPVA, PKDA, POVB, POVV: integer;
  P1, P2: TPOINT;
begin

end;

// Вставка внешней полуоткрытой выемки
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
  existCylCon: boolean;
  P1, P2: TPOINT;
  faceOfReference: integer;
begin
  existCylCon := false;

  NPVA := m_InputData.currTrans.NPVA;
  PKDA := m_InputData.currTrans.PKDA;
  POVB := m_InputData.currTrans.L_POVB;
  POVV := m_InputData.currTrans.R_POVV;

  // Условие, когда для отрисовки эскиза нужна информация о 2-м переходе
  begin
    // если переход "точить.."
    if (((PKDA = 2112) or (PKDA = 3222)) and (m_InputData.currTrans.SizesFromTP[2] = 0)
      and (m_InputData.currTrans.SizesFromTP[0] > 0)) then
    begin
      if (m_InputData.countTransitions > i_trans + 1) then
      begin
        // если цилиндр между торцами
        if (((GetSurfParam(POVB).PKDA = 2132) or ((GetSurfParam(POVB).PKDA = 2131))) and ((GetSurfParam
          (POVV).PKDA = 2132) or ((GetSurfParam(POVV).PKDA = 2131)))) then
          existCylCon := false
        else // иначе между торцем и конусом
          existCylCon := true;

        // читаем данные перехода, связанного  с текущим
        m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1)
      end;
    end;
    // если переход "подрезать.."
    if (PKDA = 2132) then
    begin
      if (m_InputData.countTransitions > i_trans + 1) then
        m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1);
    end;
  end;

  // определение положение выемок
  flagLeft := PositionCut;

  if not (existCylCon) then
  begin

    // Если  обрабатываем 1 переход
    // в переходе сразу точим цилиндр и подрезаем торец
    if (((PKDA = 2112) or (PKDA = 3212) or (PKDA = 3222)) and
      // (когда в переходе "точить..." есть размер ..TP14 )
      (m_InputData.currTrans.SizesFromTP[2] <> 0)) then
    begin

      // от какого торца отсчитываем подрезку
      faceOfReference := round(GetSurfParam(m_InputData.currTrans.R_POVV).PRIV);

      podrezTorec := CalcOutSizeTor(m_InputData.currTrans.R_POVV);
      tochitPover := m_InputData.currTrans.SizesFromTP[0];
      // номер поверхности нового торца
      if not (flagLeft) then
        nomerPovTorec := NPVA - 1
      else
        nomerPovTorec := NPVA + 1;

      MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.currTrans, flagLeft,
        nomerPovTorec, podrezTorec, tochitPover, faceOfReference);

      FillList(m_InputData.currTrans);
    end

    // Если обрабатываем 2 перехода
    else
    begin

      // Рассматриваем первый переход из пары
      if (PKDA = 2132) and ((m_InputData.joinTrans.PKDA = 2112) or (m_InputData.joinTrans.PKDA
        = 3212) or (m_InputData.joinTrans.PKDA = 3222)) then
      begin

        // от какого торца отсчитываем подрезку
        faceOfReference := round(GetSurfParam(NPVA).PRIV);

        // новая длина детали
        podrezTorec := CalcOutSizeTor(NPVA);
        // на сколько подрезаем цилиндр
        tochitPover := m_InputData.joinTrans.SizesFromTP[0];
        // номер поверхности нового торца
        nomerPovTorec := NPVA;

        // вставляем поверхности
        MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.currTrans, flagLeft,
          nomerPovTorec, podrezTorec, tochitPover, faceOfReference);

        // если делая выемку обрабатываем сразу 2 перехода, то один переход пропускаем
        skipTrans := skipTrans + 1;
      end;

      // Рассматриваем второй переход из пары
      if (m_InputData.joinTrans.PKDA = 2132) and ((PKDA = 2112) or (PKDA = 3212) or (PKDA
        = 3222)) then
      begin
        // от какого торца отсчитываем подрезку
        faceOfReference := round(GetSurfParam(m_InputData.joinTrans.NPVA).PRIV);

        podrezTorec := CalcOutSizeTor(m_InputData.joinTrans.NPVA);
        tochitPover := m_InputData.currTrans.SizesFromTP[0];
        nomerPovTorec := m_InputData.joinTrans.NPVA;

        MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.joinTrans, flagLeft,
          nomerPovTorec, podrezTorec, tochitPover, faceOfReference);

        skipTrans := skipTrans + 1;
      end;

      FillList(m_InputData.currTrans);
      FillList(m_InputData.joinTrans);
    end;

  end; // закрываем if not(existCyl)

  // если подрезаемый цилиндр между торцем и конусом
  if (existCylCon) then
  begin

    // d1_con := round(GetSurfParam(POVV).Sizes[0]);
    //d2_con := round(GetSurfParam(POVV).Sizes[4]);
    horizProjection := round(GetSurfParam(POVV).Sizes[1]);

    podrezTorec := CalcOutSizeTor(m_InputData.currTrans.L_POVB);

    if (flagLeft) then
      podrezTorec := podrezTorec + GetSurfParam(NPVA).Sizes[1]
    else if (not (flagLeft)) then
      podrezTorec := podrezTorec - GetSurfParam(NPVA).Sizes[1];

    tochitPover := m_InputData.currTrans.SizesFromTP[0];
    nomerPovTorec := NPVA;

    // координаты цилиндра
    P1.X := round(podrezTorec);
    P2.X := round(podrezTorec);


    //??? Правильно найти торец, к которому привязываемся.
    // находим P2.X
    i := MainForm.m_sketchView.OutSurf.Count - 1;
    while i >= 0 do
    begin
      if (flagLeft) then
        if ((pSurf(MainForm.m_sketchView.OutSurf[i]).PKDA = 2132) or (pSurf(MainForm.m_sketchView.OutSurf
          [i]).PKDA = 2131)) and (pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X < P1.X)
          then
        begin
          P1.X := pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X;
          break;
        end;
      if not (flagLeft) then
        if ((pSurf(MainForm.m_sketchView.OutSurf[i]).PKDA = 2132) or (pSurf(MainForm.m_sketchView.OutSurf
          [i]).PKDA = 2131)) and (pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X > P1.X)
          then
        begin
          P2.X := pSurf(MainForm.m_sketchView.OutSurf[i]).point[0].X;
          break;
        end;
      i := i - 1;
    end;

    P1.Y := round(tochitPover);
    P2.Y := round(tochitPover);
    MainForm.m_sketchView.Insert_Cyl(NPVA, flagLeft, P1, P2, true);


    // координаты конуса
    P1.Y := round(m_InputData.currTrans.SizesFromTP[0]);
    P1.X := round(podrezTorec);

    P2.Y := round(m_InputData.joinTrans.SizesFromTP[0]);
    if (flagLeft) then
      P2.X := P1.X + horizProjection
    else
      P2.X := P1.X - horizProjection;

    MainForm.m_sketchView.Insert_Con(POVV, flagLeft, P1, P2);

    skipTrans := skipTrans + 1;

    FillList(m_InputData.currTrans);
    FillList(m_InputData.joinTrans);
  end;

end;

// Вставка внешнего торца
procedure TProcessingTransition.MakeOutTor;
var
  i: integer;
  // если true, то вырез слева, иначе - справа
  flagLeft: boolean;
  tochitPover, podrezTorec: single;
  nomerPovTorec: integer;
  nomerPriv: integer;
  NPVA, PKDA, POVB, POVV: integer;
  P1, P2: TPOINT;
  faceOfReference: integer;
begin
 // определение положение выемок
  flagLeft := PositionCut;

 // от какого торца отсчитываем подрезку
  faceOfReference := round(GetSurfParam(m_InputData.currTrans.NPVA).PRIV);

  podrezTorec := m_InputData.currTrans.SizesFromTP[2];
  // берем величину подрезки из перехода "точить конус"
  for i := 0 to m_InputData.countTransitions - 1 do
  begin
    if ptrTrans(m_InputData.listTrans[i]).NPVA = m_InputData.currTrans.R_POVV then
    begin
      tochitPover := ptrTrans(m_InputData.listTrans[i]).SizesFromTP[0];
      Break;
    end;
  end;

      // номер поверхности нового торца
  if not (flagLeft) then
    nomerPovTorec := NPVA - 1
  else
    nomerPovTorec := NPVA + 1;

  MainForm.m_sketchView.Insert_OutHalfopenSurf(m_InputData.currTrans, flagLeft,
    nomerPovTorec, podrezTorec, tochitPover, faceOfReference);

  FillList(m_InputData.currTrans);
end;

// Вставка внутреннего полуоткрытого выреза
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
  if ((m_InputData.currTrans.PKDA = -2132) or ((m_InputData.currTrans.PKDA = -2112) and (m_InputData.currTrans.SizesFromTP
    [2] = 0))) then
    // читаем данные перехода, связанного  с текущим
    m_InputData.ReadCurrentTransition(m_InputData.joinTrans, i_trans + 1);

  // определение положения выреза
  flagLeft := PositionCut;

  // Если в переходе сразу точим цилиндр и подрезаем торец
  if (m_InputData.currTrans.PKDA = -3212) then
  begin
    MainForm.m_sketchView.Insert_InHalfopenSurf(m_InputData.currTrans, flagLeft);

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
    MainForm.m_sketchView.Insert_InHalfopenSurf(m_InputData.currTrans, flagLeft,
      nomerPovTorec, podrezTorec, tochitPover);

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

    MainForm.m_sketchView.Insert_InHalfopenSurf(m_InputData.currTrans, flagLeft,
      nomerPovTorec, podrezTorec, tochitPover);

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

  diametr := m_InputData.currTrans.SizesFromTP[0];
  nomerPovTorec := m_InputData.currTrans.NPVA;

  MainForm.m_sketchView.Insert_InOpenCyl(m_InputData.currTrans, nomerPovTorec, diametr);
  FillList(m_InputData.currTrans);
end;

end.

