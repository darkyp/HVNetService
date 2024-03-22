object frmMain: TfrmMain
  Left = 389
  Top = 247
  Width = 854
  Height = 492
  Caption = 'Hyper-V network service'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 328
    Width = 838
    Height = 8
    Cursor = crVSplit
    Align = alBottom
    Beveled = True
  end
  object Panel1: TPanel
    Left = 0
    Top = 336
    Width = 838
    Height = 121
    Align = alBottom
    BevelOuter = bvNone
    BorderWidth = 3
    Caption = 'Panel1'
    TabOrder = 0
    object Label2: TLabel
      Left = 3
      Top = 3
      Width = 832
      Height = 13
      Align = alTop
      Caption = 'Log'
    end
    object mmoLog: TRichEdit
      Left = 3
      Top = 16
      Width = 832
      Height = 102
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
    end
  end
  object Panel3: TPanel
    Left = 269
    Top = 0
    Width = 569
    Height = 328
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 3
    Caption = 'Panel3'
    TabOrder = 1
    object Label1: TLabel
      Left = 3
      Top = 3
      Width = 563
      Height = 13
      Align = alTop
      Caption = 'NPcap adapters'
    end
    object lv: TListView
      Left = 3
      Top = 16
      Width = 563
      Height = 309
      Align = alClient
      Columns = <
        item
          Caption = 'Name'
          Width = 100
        end
        item
          Caption = 'Adapter'
          Width = 200
        end
        item
          Caption = 'Path'
          Width = 150
        end>
      HideSelection = False
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
    end
    object btnNetRefresh: TButton
      Left = 8
      Top = 295
      Width = 31
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = 'R'
      TabOrder = 1
      OnClick = btnNetRefreshClick
    end
  end
  object Panel4: TPanel
    Left = 0
    Top = 0
    Width = 269
    Height = 328
    Align = alLeft
    BevelOuter = bvNone
    BorderWidth = 3
    Caption = 'Panel4'
    TabOrder = 2
    object Label3: TLabel
      Left = 3
      Top = 3
      Width = 263
      Height = 13
      Align = alTop
      Caption = 'VMs'
    end
    object lvVM: TListView
      Left = 3
      Top = 16
      Width = 263
      Height = 309
      Align = alClient
      Columns = <
        item
          Caption = 'Name'
          Width = 150
        end
        item
          Caption = 'Owner'
          Width = 80
        end>
      HideSelection = False
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
      OnDblClick = lvVMDblClick
    end
    object btnVMRefresh: TButton
      Left = 8
      Top = 295
      Width = 31
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = 'R'
      TabOrder = 1
      OnClick = btnVMRefreshClick
    end
  end
  object Timer1: TTimer
    Left = 516
    Top = 48
  end
end
