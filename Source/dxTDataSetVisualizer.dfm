object dxCustomObjectViewerFrame: TdxCustomObjectViewerFrame
  Left = 0
  Top = 0
  Width = 638
  Height = 329
  TabOrder = 0
  object Panel1: TPanel
    Left = 0
    Top = 306
    Width = 638
    Height = 23
    Align = alBottom
    TabOrder = 0
    object labFileSize: TLabel
      Left = 82
      Top = 4
      Width = 49
      Height = 13
      Caption = 'labFileSize'
    end
    object butExport: TButton
      Left = 8
      Top = 3
      Width = 68
      Height = 15
      Caption = 'Export'
      TabOrder = 0
      OnClick = butExportClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 638
    Height = 306
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 1
      Top = 252
      Width = 636
      Height = 11
      Cursor = crVSplit
      Align = alBottom
      Beveled = True
      MinSize = 10
      Visible = False
      ExplicitTop = 251
    end
    object dbGrid: TDBGrid
      Left = 1
      Top = 1
      Width = 636
      Height = 251
      Align = alClient
      DataSource = gridDataSource
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
    object memSQL: TMemo
      Left = 1
      Top = 263
      Width = 636
      Height = 42
      Align = alBottom
      Lines.Strings = (
        'memSQL')
      ScrollBars = ssVertical
      TabOrder = 1
      Visible = False
    end
  end
  object gridDataSource: TDataSource
    Left = 32
    Top = 152
  end
  object SaveDialog1: TSaveDialog
    Left = 184
    Top = 152
  end
end
