unit DataModule;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Data.Win.ADODB, SQLConnection;

type
  TDataModule1 = class(TDataModule)
    ADOConnection1: TADOConnection;
    ADOSpReadTransitions: TADOStoredProc;
    ADOQuery: TADOQuery;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule1: TDataModule1;
    sqlConnect: TSqlConnection;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
 // Создаем строку подключения
  sqlConnect := TSqlConnection.Create;
end;

end.
