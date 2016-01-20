object dxCustomObjectViewerFrame: TdxCustomObjectViewerFrame
  Left = 0
  Top = 0
  Width = 638
  Height = 329
  TabOrder = 0
  object dbGrid: TDBGrid
    Left = 0
    Top = 0
    Width = 638
    Height = 306
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
  object Panel1: TPanel
    Left = 0
    Top = 306
    Width = 638
    Height = 23
    Align = alBottom
    TabOrder = 1
    object labFileOperation: TLabel
      Left = 82
      Top = 4
      Width = 78
      Height = 13
      Caption = 'labFileOperation'
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
  object gridDataSource: TDataSource
    Left = 32
    Top = 152
  end
  object SaveDialog1: TSaveDialog
    Left = 184
    Top = 152
  end
end
