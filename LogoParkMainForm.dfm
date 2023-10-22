object FrmLOGOMain: TFrmLOGOMain
  Left = 0
  Top = 0
  Caption = 'LogoPark'
  ClientHeight = 86
  ClientWidth = 306
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 290
    Height = 73
    Caption = 'In/Out status'
    TabOrder = 0
    object ShI1: TShape
      Left = 3
      Top = 16
      Width = 20
      Height = 20
    end
    object ShI3: TShape
      Left = 3
      Top = 39
      Width = 20
      Height = 20
    end
    object Label1: TLabel
      Left = 29
      Top = 20
      Width = 19
      Height = 13
      Caption = 'in 1'
    end
    object Label2: TLabel
      Left = 29
      Top = 42
      Width = 19
      Height = 13
      Caption = 'in 2'
    end
    object ShQ1: TShape
      Left = 155
      Top = 16
      Width = 20
      Height = 20
      Hint = #1051#1072#1084#1087#1072' '#1087#1086#1076#1089#1074#1077#1090#1082#1080' '#1082#1085#1086#1087#1082#1080' '#1042#1042#1045#1056#1061
      ParentShowHint = False
      Shape = stCircle
      ShowHint = True
      OnMouseUp = ShQ1MouseUp
    end
    object ShQ2: TShape
      Left = 155
      Top = 42
      Width = 20
      Height = 20
      Hint = #1051#1072#1084#1087#1072' '#1087#1086#1076#1089#1074#1077#1090#1082#1080' '#1082#1085#1086#1087#1082#1080' '#1042#1053#1048#1047
      ParentShowHint = False
      Shape = stCircle
      ShowHint = True
      OnMouseUp = ShQ2MouseUp
    end
    object Label9: TLabel
      Left = 197
      Top = 20
      Width = 27
      Height = 13
      Caption = 'out 1'
    end
    object Label10: TLabel
      Left = 197
      Top = 42
      Width = 27
      Height = 13
      Caption = 'out 2'
    end
  end
  object Edit1: TEdit
    Left = 8
    Top = 642
    Width = 113
    Height = 21
    TabOrder = 1
    Text = 'GETSTDG'
  end
  object Button6: TButton
    Left = 8
    Top = 669
    Width = 113
    Height = 25
    Caption = 'Request'
    TabOrder = 2
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 256
    Top = 32
  end
  object IdIcmpClient1: TIdIcmpClient
    Protocol = 1
    ProtocolIPv6 = 58
    IPVersion = Id_IPv4
    Left = 96
    Top = 32
  end
end
