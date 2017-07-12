unit SketchForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  // для отрисовки эскиза
  SketchView, Vcl.Grids, Vcl.ValEdit,
  // для обработки переходов и формировании эскизов
  ProcessTrans, InputData, Vcl.Buttons;

type
  TEdit = class(StdCtrls.TEdit)
  private
    procedure MessagePaint(var Msg: TMessage); message WM_NCPAINT;
    procedure SetBorder(AColor: TColor);
    procedure PaintEdit(DC: HDC; ARect: TRect; EColor, BColor: TColor);
  public
    { Public declarations }
  end;

type
  TMainForm = class(TForm)
    DrawButton: TButton;
    Kod_detal: TEdit;
    PaintBox1: TPaintBox;
    Splitter1: TSplitter;
    ValueListEditor1: TValueListEditor;
    Panel1: TPanel;
    BitBtn1: TBitBtn;
    procedure DrawButtonClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure Kod_detalMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure BitBtn1Click(Sender: TObject);

  private

    ProcessTrans: TProcessingTransition;

  public
    // объект используется в классе TProcessingTransition
    m_sketchView: TSketchView;
  end;

var
  MainForm: TMainForm;
  flagRedraw: boolean;

implementation

{$R *.dfm}

procedure TMainForm.BitBtn1Click(Sender: TObject);
var
  f: System.Text;
  i: Integer;
begin
  AssignFile(f, 'file.txt');
  Rewrite(f);
   Writeln(f, ' Наружние поверхности');
  for i := 0 to m_sketchView.OutsideSurfaces.Count - 1 do
  begin
    Writeln(f, (pSurf(m_sketchView.OutsideSurfaces[i]).number.ToString()));
    Writeln(f, 'PKDA: ' + (pSurf(m_sketchView.OutsideSurfaces[i])
      .PKDA.ToString()) + '   X1: ' + pSurf(m_sketchView.OutsideSurfaces[i])
      .point[0].X.ToString() + ' Y1: ' + pSurf(m_sketchView.OutsideSurfaces[i])
      .point[0].Y.ToString() + '   X2: ' + pSurf(m_sketchView.OutsideSurfaces[i]
      ).point[1].X.ToString() + ' Y2: ' + pSurf(m_sketchView.OutsideSurfaces[i])
      .point[1].Y.ToString());
  end;

  Writeln(f, ' ');
   Writeln(f, ' Внутренние поверхности');

  for i := 0 to m_sketchView.InnerSurfaces.Count - 1 do
  begin
    Writeln(f, (pSurf(m_sketchView.InnerSurfaces[i]).number.ToString()));
    Writeln(f, 'PKDA: ' + (pSurf(m_sketchView.InnerSurfaces[i])
      .PKDA.ToString()) + '   X1: ' + pSurf(m_sketchView.InnerSurfaces[i])
      .point[0].X.ToString() + ' Y1: ' + pSurf(m_sketchView.InnerSurfaces[i])
      .point[0].Y.ToString() + '   X2: ' + pSurf(m_sketchView.InnerSurfaces[i]
      ).point[1].X.ToString() + ' Y2: ' + pSurf(m_sketchView.InnerSurfaces[i])
      .point[1].Y.ToString());
  end;

  CloseFile(f);
end;

procedure TMainForm.DrawButtonClick(Sender: TObject);
var
  i: Integer;
begin

  while ValueListEditor1.Strings.Count > 0 do
    ValueListEditor1.DeleteRow(1);

  // Считываем данные о переходах для детали
  ProcessTrans.InitSQL;

  // устанавливаем масштаб для отрисовки эскиза
  m_sketchView.m_Screen := PaintBox1.ClientRect;
  m_sketchView.SetMetric;
  // очищаем  listSurfaces и listSurfacesScale от старых поверхностей
  m_sketchView.Clear;
  // очищаем    PaintBox1 от старого эскиза
  flagRedraw := false;
  PaintBox1.Repaint;
  flagRedraw := true;
  // Создаем поверхности заготовки
  m_sketchView.CreateFirstSurface;
  // Отрисовываем
  m_sketchView.Draw(PaintBox1.Canvas);

  i := 0;
  // Проходим каждый переход
  for i := 0 to ProcessTrans.m_InputData.countTransitions - 1 do
  begin
    if (MessageDlg('Следующий переход?', mtConfirmation, mbYesNo, 1) <> mrNo)
    then
    begin
      // Обработка перехода
      ProcessTrans.ProcessingTransition(i);
    end
    else
      break;
    // Отрисовываем эскиз перехода
    if (i > (ProcessTrans.m_InputData.countTransitions - 1)) then
      flagRedraw := false
    else
    begin
      flagRedraw := true;
      PaintBox1.Repaint;
    end;
  end;

end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Инициализируем объект класса TSketchView для отрисовки
  m_sketchView := TSketchView.Create;
  ProcessTrans := TProcessingTransition.Create;

  PaintBox1.Repaint;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  m_sketchView.m_Screen := PaintBox1.ClientRect;
  // m_sketchView.SetMetric;
  PaintBox1.Repaint;
end;

procedure TMainForm.Kod_detalMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  DC: HDC;
  Rect: TRect;
  colorBg, colorBr: TColor;
begin
  colorBr := RGB(193, 220, 240);
  Kod_detal.PaintEdit(DC, Rect, clWindow, colorBr);
end;

procedure TMainForm.PaintBox1Paint(Sender: TObject);
var
  colorBg: TColor;
begin

  // Устанавливаем цвет  PaintBox1
  colorBg := RGB(248, 255, 255);
  PaintBox1.Canvas.Brush.Color := colorBg;
  PaintBox1.Canvas.FillRect(PaintBox1.Canvas.ClipRect);
  // Если флаг перерисовки true, то перерисовываем эскиз
  if (flagRedraw) then
    m_sketchView.Draw(PaintBox1.Canvas);
end;

// TEdit's metodes
procedure TEdit.SetBorder(AColor: TColor);
var
  Canvas: TCanvas;
begin
  Canvas := TCanvas.Create;
  try
    Canvas.Handle := GetWindowDC(Handle);
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Color := AColor;
    Canvas.Pen.Width := 3;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(0, 0, Width, Height);
  finally
    ReleaseDC(Handle, Canvas.Handle);
    Canvas.Free;
  end;
end;

procedure TEdit.MessagePaint(var Msg: TMessage);
var
  DC: HDC;
  Rect: TRect;
  colorBg, colorBr: TColor;
begin
  colorBr := RGB(0, 120, 215);
  DC := GetWindowDC(Handle);
  try
    Windows.GetClientRect(Handle, Rect);
    PaintEdit(DC, Rect, clWindow, colorBr);
  finally
    ReleaseDC(Handle, DC);
  end;
end;

procedure TEdit.PaintEdit(DC: HDC; ARect: TRect; EColor, BColor: TColor);
var
  WindowColor: TColor;
  BorderColor: TColor;
begin
  WindowColor := EColor; // Color of TEdit
  BorderColor := BColor; // Border Color of TEdit
  if not Enabled then
  begin
    WindowColor := clBtnFace;
    BorderColor := clBtnShadow;
  end;
  InflateRect(ARect, 4, 4);
  Brush.Color := WindowColor;
  Windows.FillRect(DC, ARect, Brush.Handle);
  SetBorder(BorderColor);
end;

end.
