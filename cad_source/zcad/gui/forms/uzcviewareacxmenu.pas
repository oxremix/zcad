unit uzcviewareacxmenu;

{$mode objfpc}{$H+}

interface

uses
  sysutils,
  uzglviewareaabstract,uzmenusmanager,uzmacros,TransferMacros,MacroDefIntf,Forms,ActnList;

type
  PTViewAreaContext=^TViewAreaContext;
  TViewAreaContext=record
    VA:TAbstractViewArea;
  end;

  TViewAreaContextMenuManager=specialize TGMenusManager<TViewAreaContext>;
  TViewAreaMacros=class(specialize TZMacros<TViewAreaContext>)
    function SubstituteMacrosWithCurrentContext(var s: string): boolean;override;
    procedure AddMacro(NewMacro:TTransferMacro);override;
  end;

var
  ViewAreaContextMenuManager:TViewAreaContextMenuManager=nil;
  ViewAreaMacros:TViewAreaMacros=nil;
 ViewAreaMacroList:TTransferMacroList = nil;

procedure InitializeViewAreaCXMenu(mainform:TForm;actlist:TActionList);
procedure FinalizeViewAreaCXMenu;
function CreateViewAreaContext(VA:TAbstractViewArea):TViewAreaContext;
implementation
function TViewAreaMacros.SubstituteMacrosWithCurrentContext(var s: string): boolean;
begin
  setMarkUnhandled(false);
  Result:=inherited SubstituteMacros(s);
  setMarkUnhandled(true);
  {Result:=Result or }ViewAreaMacroList.SubstituteStr(s,PtrInt(@CurrentContext));
end;

procedure TViewAreaMacros.AddMacro(NewMacro:TTransferMacro);
begin
  if not assigned(ViewAreaMacroList) then
    ViewAreaMacroList:=TTransferMacroList.Create;
  ViewAreaMacroList.Add(NewMacro);
end;

function CreateViewAreaContext(VA:TAbstractViewArea):TViewAreaContext;
begin
  result.VA:=VA;
end;
function EntsSelectedCCF(const vac:TViewAreaContext):boolean;
begin
  result:=vac.VA.param.SelDesc.Selectedobjcount>0;
end;

procedure InitializeViewAreaCXMenu(mainform:TForm;actlist:TActionList);
begin
  if not assigned(ViewAreaContextMenuManager) then
    ViewAreaContextMenuManager:=TViewAreaContextMenuManager.Create(mainform,actlist);
  if not assigned(ViewAreaMacros) then
    ViewAreaMacros:=TViewAreaMacros.Create;
  ViewAreaContextMenuManager.RegisterContextCheckFunc('EntsSelected',@EntsSelectedCCF);
end;

procedure FinalizeViewAreaCXMenu;
begin
  if assigned(ViewAreaContextMenuManager) then
    FreeAndNil(ViewAreaContextMenuManager);
  if assigned(ViewAreaMacros) then
    FreeAndNil(ViewAreaMacros);
  if assigned(ViewAreaMacroList) then
    FreeAndNil(ViewAreaMacroList);
end;

finalization
  FinalizeViewAreaCXMenu;
end.

