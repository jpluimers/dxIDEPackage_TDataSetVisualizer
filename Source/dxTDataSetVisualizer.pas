(*
  The inspected dataset will be exported to a temporary file to be
  loaded into a new dataset here and then the temp file will be deleted.

  Obviously not recommended for large datasets, nor datasets with sensitive information.

  As of January 2016, the latest version is maintained on GitHub:
  https://github.com/darianmiller/dxIDEPackage_TDataSetVisualizer
*)
unit dxTDataSetVisualizer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolsAPI, Vcl.StdCtrls, Data.DB, Vcl.DBCtrls,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.DBGrids;

type
  TAvailableState = (asAvailable, asProcRunning, asOutOfScope, asNotAvailable);

  TdxCustomObjectViewerFrame = class(TFrame, IOTADebuggerVisualizerExternalViewerUpdater,
    IOTAThreadNotifier, IOTAThreadNotifier160)
    dbGrid: TDBGrid;
    gridDataSource: TDataSource;
    Panel1: TPanel;
    labFileSize: TLabel;
    SaveDialog1: TSaveDialog;
    butExport: TButton;
    procedure butExportClick(Sender: TObject);
  private
    fDataSet:TDataSet;
    FOwningForm: TCustomForm;
    FClosedProc: TOTAVisualizerClosedProcedure;
    FExpression: string;
    fTypeName:String;
    FNotifierIndex: Integer;
    FCompleted: Boolean;
    FDeferredResult: string;
    FDeferredError: Boolean;
    FAvailableState: TAvailableState;
    function Evaluate(Expression: string): string;
  protected
    procedure SetParent(AParent: TWinControl); override;
  public
    procedure CloseVisualizer;
    procedure MarkUnavailable(Reason: TOTAVisualizerUnavailableReason);
    procedure RefreshVisualizer(const Expression, TypeName, EvalResult: string);
    procedure SetClosedCallback(ClosedProc: TOTAVisualizerClosedProcedure);
    procedure SetForm(AForm: TCustomForm);

    procedure CustomDisplay(const Expression, TypeName, EvalResult: string);

    { IOTAThreadNotifier }
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    procedure ThreadNotify(Reason: TOTANotifyReason);
    procedure EvaluteComplete(const ExprStr, ResultStr: string; CanModify: Boolean;
      ResultAddress, ResultSize: LongWord; ReturnCode: Integer);
    procedure ModifyComplete(const ExprStr, ResultStr: string; ReturnCode: Integer);
    { IOTAThreadNotifier160 }
    procedure EvaluateComplete(const ExprStr, ResultStr: string; CanModify: Boolean;
      ResultAddress: TOTAAddress; ResultSize: LongWord; ReturnCode: Integer);
  end;

procedure Register;

implementation

uses
  DesignIntf, Actnlist, ImgList, Menus, IniFiles,
  {$IFDEF SUPPORT_ADO_DATASETS}
  Data.Win.ADODB,
  {$ENDIF}
  {$IFDEF SUPPORT_FIREDAC_DATASETS}
  FireDAC.Comp.Client,
  {$ENDIF}
  {$IFDEF SUPPORT_DATASNAP_DATASETS}
  Datasnap.DBClient,
  {$ENDIF}
  System.IOUtils;

{$R *.dfm}

resourcestring
  sVisualizerId = 'dxTDataSetVisualizer';
  sClassname = 'TDataSet';
  sVisualizerName = 'dxIDEPackage: TDataSet Visualizer for Delphi';
  sVisualizerDescription = 'Debugger visualizer which displays a TDataSet within a DBGrid';
  sMenuText = 'Show TDataSet';
  sFormCaption = 'TDataSet Visualizer for expression: %s (%s)';
  sProcessNotAccessible = 'process not accessible';
  sValueNotAccessible = 'value not accessible';
  sOutOfScope = 'out of scope';

type

  IFrameFormHelper = interface
    ['{0FD4A98F-CE6B-422A-BF13-14E59707D3B2}']
    function GetForm: TCustomForm;
    function GetFrame: TCustomFrame;
    procedure SetForm(Form: TCustomForm);
    procedure SetFrame(Form: TCustomFrame);
  end;

  TdxCustomObjectVisualizerForm = class(TInterfacedObject, INTACustomDockableForm, IFrameFormHelper)
  private
    FMyFrame: TdxCustomObjectViewerFrame;
    FMyForm: TCustomForm;
    FExpression: string;
    FTypeName:String;
  public
    constructor Create(const Expression, TypeName: string);
    { INTACustomDockableForm }
    function GetCaption: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    function GetIdentifier: string;
    function GetMenuActionList: TCustomActionList;
    function GetMenuImageList: TCustomImageList;
    procedure CustomizePopupMenu(PopupMenu: TPopupMenu);
    function GetToolbarActionList: TCustomActionList;
    function GetToolbarImageList: TCustomImageList;
    procedure CustomizeToolBar(ToolBar: TToolBar);
    procedure LoadWindowState(Desktop: TCustomIniFile; const Section: string);
    procedure SaveWindowState(Desktop: TCustomIniFile; const Section: string; IsProject: Boolean);
    function GetEditState: TEditState;
    function EditAction(Action: TEditAction): Boolean;
    { IFrameFormHelper }
    function GetForm: TCustomForm;
    function GetFrame: TCustomFrame;
    procedure SetForm(Form: TCustomForm);
    procedure SetFrame(Frame: TCustomFrame);
  end;

  TdxCustomObjectDebuggerVisualizer = class(TInterfacedObject, IOTADebuggerVisualizer,
    IOTADebuggerVisualizerExternalViewer)
  public
    function GetSupportedTypeCount: Integer;
    procedure GetSupportedType(Index: Integer; var TypeName: string;
      var AllDescendants: Boolean);
    function GetVisualizerIdentifier: string;
    function GetVisualizerName: string;
    function GetVisualizerDescription: string;
    function GetMenuText: string;
    function Show(const Expression, TypeName, EvalResult: string; Suggestedleft, SuggestedTop: Integer): IOTADebuggerVisualizerExternalViewerUpdater;
  end;

{ TDebuggerDateTimeVisualizer }

function TdxCustomObjectDebuggerVisualizer.GetMenuText: string;
begin
  Result := sMenuText;
end;

procedure TdxCustomObjectDebuggerVisualizer.GetSupportedType(Index: Integer;
  var TypeName: string; var AllDescendants: Boolean);
begin
  TypeName := sClassname;
  AllDescendants := True;
end;

function TdxCustomObjectDebuggerVisualizer.GetSupportedTypeCount: Integer;
begin
  Result := 1;
end;

function TdxCustomObjectDebuggerVisualizer.GetVisualizerDescription: string;
begin
  Result := sVisualizerDescription;
end;

function TdxCustomObjectDebuggerVisualizer.GetVisualizerIdentifier: string;
begin
  Result := ClassName;
end;

function TdxCustomObjectDebuggerVisualizer.GetVisualizerName: string;
begin
  Result := sVisualizerName;
end;

function TdxCustomObjectDebuggerVisualizer.Show(const Expression, TypeName, EvalResult: string; SuggestedLeft, SuggestedTop: Integer): IOTADebuggerVisualizerExternalViewerUpdater;
var
  AForm: TCustomForm;
  AFrame: TdxCustomObjectViewerFrame;
  VisDockForm: INTACustomDockableForm;
begin
  VisDockForm := TdxCustomObjectVisualizerForm.Create(Expression, TypeName) as INTACustomDockableForm;
  AForm := (BorlandIDEServices as INTAServices).CreateDockableForm(VisDockForm);
  AForm.Left := SuggestedLeft;
  AForm.Top := SuggestedTop;
  (VisDockForm as IFrameFormHelper).SetForm(AForm);
  AFrame := (VisDockForm as IFrameFormHelper).GetFrame as TdxCustomObjectViewerFrame;
  AFrame.CustomDisplay(Expression, TypeName, EvalResult);
  Result := AFrame as IOTADebuggerVisualizerExternalViewerUpdater;
end;


function GetFileSize(const S:string):Int64;
var
 h:THandle;
 fd:TWin32FindData;
begin
  h := FindFirstFile(PChar(S), fd);
  if h = INVALID_HANDLE_VALUE then
  begin
    Result := 0
  end
  else
  begin
     try
       Result := fd.nFileSizeHigh;
       Result := Result shl 32;
       Result := Result + fd.nFileSizeLow;
     finally
       CloseHandle(h);
     end;
  end;
end;

procedure TdxCustomObjectViewerFrame.CustomDisplay(const Expression, TypeName, EvalResult: string);
const
  IS_TRUE = '''-1''';  //QuotedStr('1') as it comes back from the debugger via Evaluate()
var
  vTempFileName:String;
  vFileSize:Int64;
begin
  FAvailableState := asAvailable;
  FExpression := Expression;
  fTypeName := TypeName;

  FreeAndNil(fDataSet);
  gridDataSource.DataSet := nil;
  vFileSize := 0;

  vTempFileName := TPath.GetTempFileName();
  try

    {$IFDEF SUPPORT_ADO_DATASETS}
    if Evaluate(Format('BoolToStr(%s is TCustomADODataSet)', [FExpression])) = IS_TRUE then
    begin
      {TADODataSet, TADOQuery, TADOStoredProc...}
      fDataSet := TADODataSet.Create(fOwningForm);
    end;
    {$ENDIF}

    {$IFDEF SUPPORT_FIREDAC_DATASETS}
    if Evaluate(Format('BoolToStr(%s is TFDDataSet)', [FExpression])) = IS_TRUE then
    begin
      {TFDMemTable, TFDQuery, TFDStoredProc, TFDTable...}
      if Evaluate(Format('BoolToStr(%s.State<>dsInactive)', [FExpression])) = IS_TRUE then
      begin
        fDataSet := TFDMemTable.Create(fOwningForm);
      end;
    end;
    {$ENDIF}

    {$IFDEF SUPPORT_DATASNAP_DATASETS}
    if Evaluate(Format('BoolToStr(%s is TClientDataSet)', [FExpression])) = IS_TRUE then
    begin
      if Evaluate(Format('BoolToStr(%s.State<>dsInactive)', [FExpression])) = IS_TRUE then
      begin
        fDataSet := TClientDataSet.Create(fOwningForm);
      end;
    end;
    {$ENDIF}


    if Assigned(fDataSet) then
    begin
      //ADO, FireDac and TClientDataSet support .SaveToFile
      Evaluate(Format('%s.SaveToFile(%s)', [FExpression, QuotedStr(vTempFileName)]));

      vFileSize := GetFileSize(vTempFileName);
      if (vFileSize > 0) then
      begin
        //TDataSet doesn't support LoadFromFile...do a specific LoadFromFile based on custom Type created

        {$IFDEF SUPPORT_ADO_DATASETS}
        if fDataSet is TCustomADODataSet then
        begin
          TCustomADODataSet(fDataSet).LoadFromFile(vTempFileName);
        end;
        {$ENDIF}
        {$IFDEF SUPPORT_FIREDAC_DATASETS}
        if fDataSet is TFDMemTable then
        begin
          TFDMemTable(fDataSet).LoadFromFile(vTempFileName);
        end;
        {$ENDIF}
        {$IFDEF SUPPORT_DATASNAP_DATASETS}
        if fDataSet is TClientDataSet then
        begin
          TClientDataSet(fDataSet).LoadFromFile(vTempFileName);
        end;
        {$ENDIF}

        gridDataSource.DataSet := fDataSet;
      end;
    end;
  finally
    TFile.Delete(vTempFileName);
  end;

  butExport.Enabled := (vFileSize > 0);
  labFileSize.Caption := FormatFloat('#,##0', vFileSize) + ' bytes';
  dbGrid.Invalidate;
end;

procedure TdxCustomObjectViewerFrame.AfterSave;
begin

end;

procedure TdxCustomObjectViewerFrame.BeforeSave;
begin

end;

procedure TdxCustomObjectViewerFrame.butExportClick(Sender: TObject);
begin
  if not Assigned(fDataSet) then
  begin
    Exit;
  end;

  if not SaveDialog1.Execute(self.Handle) then
  begin
    Exit;
  end;

  //TDataSet doesn't support SaveToFile...do a specific SaveToFile based on custom Type created

  {$IFDEF SUPPORT_ADO_DATASETS}
  if fDataSet is TCustomADODataSet then
  begin
    TCustomADODataSet(fDataSet).SaveToFile(SaveDialog1.FileName);
    Exit;
  end;
  {$ENDIF}

  {$IFDEF SUPPORT_FIREDAC_DATASETS}
  if fDataSet is TFDMemTable then
  begin
    TFDMemTable(fDataSet).SaveToFile(SaveDialog1.FileName);
    Exit;
  end;
  {$ENDIF}

  {$IFDEF SUPPORT_DATASNAP_DATASETS}
  if fDataSet is TClientDataSet then
  begin
    TClientDataSet(fDataSet).SaveToFile(SaveDialog1.FileName);
    Exit;
  end;
  {$ENDIF}

end;

procedure TdxCustomObjectViewerFrame.CloseVisualizer;
begin
  if FOwningForm <> nil then
    FOwningForm.Close;
end;

procedure TdxCustomObjectViewerFrame.Destroyed;
begin

end;

function TdxCustomObjectViewerFrame.Evaluate(Expression: string): string;
var
  CurProcess: IOTAProcess;
  CurThread: IOTAThread;
  ResultStr: array[0..4095] of Char;
  CanModify: Boolean;
  Done: Boolean;
  ResultAddr, ResultSize, ResultVal: LongWord;
  EvalRes: TOTAEvaluateResult;
  DebugSvcs: IOTADebuggerServices;
begin
  begin
    Result := '';
    if Supports(BorlandIDEServices, IOTADebuggerServices, DebugSvcs) then
      CurProcess := DebugSvcs.CurrentProcess;
    if CurProcess <> nil then
    begin
      CurThread := CurProcess.CurrentThread;
      if CurThread <> nil then
      begin
        repeat
        begin
          Done := True;
          EvalRes := CurThread.Evaluate(Expression, @ResultStr, Length(ResultStr),
            CanModify, eseAll, '', ResultAddr, ResultSize, ResultVal, '', 0);
          case EvalRes of
            erOK: Result := ResultStr;
            erDeferred:
              begin
                FCompleted := False;
                FDeferredResult := '';
                FDeferredError := False;
                FNotifierIndex := CurThread.AddNotifier(Self);
                while not FCompleted do
                  DebugSvcs.ProcessDebugEvents;
                CurThread.RemoveNotifier(FNotifierIndex);
                FNotifierIndex := -1;
                if not FDeferredError then
                begin
                  if FDeferredResult <> '' then
                    Result := FDeferredResult
                  else
                    Result := ResultStr;
                end;
              end;
            erBusy:
              begin
                DebugSvcs.ProcessDebugEvents;
                Done := False;
              end;
          end;
        end
        until Done = True;
      end;
    end;
  end;
end;

procedure TdxCustomObjectViewerFrame.EvaluteComplete(const ExprStr,
  ResultStr: string; CanModify: Boolean; ResultAddress, ResultSize: LongWord;
  ReturnCode: Integer);
begin
  EvaluateComplete(ExprStr, ResultStr, CanModify, TOTAAddress(ResultAddress), ResultSize, ReturnCode);
end;

procedure TdxCustomObjectViewerFrame.EvaluateComplete(const ExprStr,
  ResultStr: string; CanModify: Boolean; ResultAddress: TOTAAddress; ResultSize: LongWord;
  ReturnCode: Integer);
begin
  FCompleted := True;
  FDeferredResult := ResultStr;
  FDeferredError := ReturnCode <> 0;
end;

procedure TdxCustomObjectViewerFrame.MarkUnavailable(
  Reason: TOTAVisualizerUnavailableReason);
begin
  if Reason = ovurProcessRunning then
  begin
    FAvailableState := asProcRunning;
  end else if Reason = ovurOutOfScope then
    FAvailableState := asOutOfScope;

  gridDataSource.DataSet := nil;
  FreeAndNil(fDataSet);
  dbGrid.Invalidate;
end;

procedure TdxCustomObjectViewerFrame.Modified;
begin

end;

procedure TdxCustomObjectViewerFrame.ModifyComplete(const ExprStr,
  ResultStr: string; ReturnCode: Integer);
begin

end;

procedure TdxCustomObjectViewerFrame.RefreshVisualizer(const Expression, TypeName,
  EvalResult: string);
begin
  FAvailableState := asAvailable;
  CustomDisplay(Expression, TypeName, EvalResult);
end;

procedure TdxCustomObjectViewerFrame.SetClosedCallback(
  ClosedProc: TOTAVisualizerClosedProcedure);
begin
  FClosedProc := ClosedProc;
end;

procedure TdxCustomObjectViewerFrame.SetForm(AForm: TCustomForm);
begin
  FOwningForm := AForm;
end;

procedure TdxCustomObjectViewerFrame.SetParent(AParent: TWinControl);
begin
  if AParent = nil then
  begin
    if Assigned(FClosedProc) then
      FClosedProc;
  end;
  inherited;
end;

procedure TdxCustomObjectViewerFrame.ThreadNotify(Reason: TOTANotifyReason);
begin

end;

constructor TdxCustomObjectVisualizerForm.Create(const Expression, TypeName: string);
begin
  inherited Create;
  FExpression := Expression;
  fTypeName := TypeName;
end;

procedure TdxCustomObjectVisualizerForm.CustomizePopupMenu(PopupMenu: TPopupMenu);
begin
  // no toolbar
end;

procedure TdxCustomObjectVisualizerForm.CustomizeToolBar(ToolBar: TToolBar);
begin
 // no toolbar
end;

function TdxCustomObjectVisualizerForm.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

procedure TdxCustomObjectVisualizerForm.FrameCreated(AFrame: TCustomFrame);
begin
  FMyFrame :=  TdxCustomObjectViewerFrame(AFrame);
end;

function TdxCustomObjectVisualizerForm.GetCaption: string;
begin
  Result := Format(sFormCaption, [FExpression, fTypeName]);
end;

function TdxCustomObjectVisualizerForm.GetEditState: TEditState;
begin
  Result := [];
end;

function TdxCustomObjectVisualizerForm.GetForm: TCustomForm;
begin
  Result := FMyForm;
end;

function TdxCustomObjectVisualizerForm.GetFrame: TCustomFrame;
begin
  Result := FMyFrame;
end;

function TdxCustomObjectVisualizerForm.GetFrameClass: TCustomFrameClass;
begin
  Result := TdxCustomObjectViewerFrame;
end;

function TdxCustomObjectVisualizerForm.GetIdentifier: string;
begin
  Result := sVisualizerId;
end;

function TdxCustomObjectVisualizerForm.GetMenuActionList: TCustomActionList;
begin
  Result := nil;
end;

function TdxCustomObjectVisualizerForm.GetMenuImageList: TCustomImageList;
begin
  Result := nil;
end;

function TdxCustomObjectVisualizerForm.GetToolbarActionList: TCustomActionList;
begin
  Result := nil;
end;

function TdxCustomObjectVisualizerForm.GetToolbarImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TdxCustomObjectVisualizerForm.LoadWindowState(Desktop: TCustomIniFile;
  const Section: string);
begin
  //no desktop saving
end;

procedure TdxCustomObjectVisualizerForm.SaveWindowState(Desktop: TCustomIniFile;
  const Section: string; IsProject: Boolean);
begin
  //no desktop saving
end;

procedure TdxCustomObjectVisualizerForm.SetForm(Form: TCustomForm);
begin
  FMyForm := Form;
  if Assigned(FMyFrame) then
    FMyFrame.SetForm(FMyForm);
end;

procedure TdxCustomObjectVisualizerForm.SetFrame(Frame: TCustomFrame);
begin
   FMyFrame := TdxCustomObjectViewerFrame(Frame);
end;

var
  vMyVisualizer: IOTADebuggerVisualizer;

procedure Register;
begin
  vMyVisualizer := TdxCustomObjectDebuggerVisualizer.Create;
  (BorlandIDEServices as IOTADebuggerServices).RegisterDebugVisualizer(vMyVisualizer);
end;

procedure RemoveVisualizer;
var
  DebuggerServices: IOTADebuggerServices;
begin
  if Supports(BorlandIDEServices, IOTADebuggerServices, DebuggerServices) then
  begin
    DebuggerServices.UnregisterDebugVisualizer(vMyVisualizer);
    vMyVisualizer := nil;
  end;
end;

initialization
finalization
  RemoveVisualizer;
end.

