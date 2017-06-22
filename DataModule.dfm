object DataModule1: TDataModule1
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 150
  Width = 215
  object ADOConnection1: TADOConnection
    Left = 40
    Top = 32
  end
  object ADOSpReadTransitions: TADOStoredProc
    Parameters = <>
    Left = 128
    Top = 64
  end
  object ADOQuery: TADOQuery
    Parameters = <>
    Left = 120
    Top = 16
  end
end
