program SketchApp;

uses
  Vcl.Forms,
  DataModule in 'DataModule.pas' {DataModule1: TDataModule},
  InputData in 'InputData.pas',
  SketchForm in 'SketchForm.pas' {MainForm},
  SketchView in 'SketchView.pas',
  SQLConnection in 'SQLConnection.pas',
  ProcessTrans in 'ProcessTrans.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDataModule1, DataModule1);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;

end.
