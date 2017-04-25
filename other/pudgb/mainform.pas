unit mainform;

{$mode delphi}{$H+}
{$DEFINE CHECKLOOPS}

interface

uses
  LazUTF8,Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, StdCtrls, ActnList, Menus, LCLIntf,

  zcobjectinspectorui,uzctypesdecorations,uzedimensionaltypes,zcobjectinspector,Varman,uzbtypes,uzemathutils,UUnitManager,varmandef,zcobjectinspectoreditors,UEnumDescriptor,


  {$IFDEF CHECKLOOPS}uchecker,{$ENDIF}
  uoptions,uscaner,uscanresult,uwriter,yEdWriter,ulpiimporter,udpropener,uexplorer;
  {$INCLUDE revision.inc}
  type

  { TForm1 }

  TForm1 = class(TForm)
    MenuItem8: TMenuItem;
    OpenDPR: TAction;
    CodeExplorer: TAction;
    doExit: TAction;
    OpenWebGraphviz: TAction;
    SaveGML: TAction;
    GDBobjinsp1: TGDBobjinsp;
    ImportLPI: TAction;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    Scan: TAction;
    Save: TAction;
    ActionList1: TActionList;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    procedure _CodeExplorer(Sender: TObject);
    procedure _Exit(Sender: TObject);
    procedure _SaveGML(Sender: TObject);
    procedure _ImportLPI(Sender: TObject);
    procedure _OpenDPR(Sender: TObject);
    procedure _onClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure _onCreate(Sender: TObject);
    procedure _Save(Sender: TObject);
    procedure _Scan(Sender: TObject);
    procedure _OpenWebGraphviz(Sender: TObject);
    procedure _SetOptionFromUI(Sender: TObject);
    procedure _SetUIFromOption(Sender: TObject);
  private
    Options:TOptions;
    ScanResult:TScanResult;

    RunTimeUnit:ptunit;
    UnitsFormat:TzeUnitsFormat;
  public
    procedure DummyWriteToLog(msg:string);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1._SetOptionFromUI(Sender: TObject);
begin
   GDBobjinsp1.updateinsp;
end;
procedure TForm1._SetUIFromOption(Sender: TObject);
begin
   GDBobjinsp1.updateinsp;
end;
procedure TForm1._onCreate(Sender: TObject);
begin
   Options:=DefaultOptions;
   UnitsFormat:=CreateDefaultUnitsFormat;
   INTFObjInspShowOnlyHotFastEditors:=false;

   RunTimeUnit:=units.CreateUnit('',nil,'RunTimeUnit');//create empty zscript unit
   RunTimeUnit^.RegisterType(TypeInfo(TOptions));//register rtti types in zscript unit
   RunTimeUnit^.SetTypeDesk(TypeInfo(TOptions),['Paths','Parser options','Graph bulding','Log']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TPaths),['File','Paths']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TParser),['Compiler options','Target OS','Target CPU']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TGraphBulding),['Circular graph','Full graph','Interface uses edge type',
                                                     'Implementation uses edge type','Calc edges weight']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TCircularG),['Calc edges weight']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TFullG),['Include not founded units','Include interface uses',
                                              'Include implementation uses','Only looped edges',
                                              'Source unit','Dest unit']);

   RunTimeUnit^.SetTypeDesk(TypeInfo(TLogger),['Scaner messages','Parser messages','Timer','Not founded units']);
   RunTimeUnit^.SetTypeDesk(TypeInfo(TEdgeType),['Continuous','Dotted']);

   Options.Paths._File:=ExtractFileDir(ParamStr(0))+pathdelim+'passrcerrors.pas';
   Options.Paths._Paths:=ExtractFileDir(ParamStr(0));

   Options.Logger.ScanerMessages:=false;
   Options.Logger.ParserMessages:=false;
   Options.Logger.Timer:=true;
   Options.Logger.Notfounded:=false;

   {tp:='Z:\hdd\src\fpc\lazarus-ccr\applications\cactusjukebox\';//путь к тестику
  Options.Paths._File:=tp+'source\cactusjukebox.pas';                //главный файл
  Options.Paths._Paths:=tp+'source';                                 //путь к исходникам
  Options.ParserOptions._CompilerOptions:='-Sc';}                             //"опция компилятора" разрешающая си синтаксис по типу i+=j;

  {Options.Paths._File:='E:\zcad\cad_source\zcad.pas';
  Options.Paths._Paths:='E:\zcad\cad_source\zengine/containers;E:\zcad\cad_source\zengine/styles;E:\zcad\cad_source\zengine;E:\zcad\cad_source\zengine/core;E:\zcad\cad_source\zengine/core/entities;E:\zcad\cad_source\zengine/core/drawings;E:\zcad\cad_source\zengine/fonts;E:\zcad\cad_source\zengine/zgl;E:\zcad\cad_source\zengine/zgl/drawers;E:\zcad\cad_source\zengine/misc;E:\zcad\cad_source\zengine/fileformats;E:\zcad\cad_source\other;E:\zcad\cad_source\../cad;E:\zcad\cad_source\other/uniqueinstance;E:\zcad\cad_source\autogenerated;E:\zcad\cad_source\zcad/electrotech;E:\zcad\cad_source\zcad/lclmod;E:\zcad\cad_source\zcad/commands;E:\zcad\cad_source\zcad/devicebase;E:\zcad\cad_source\zcad/gui;E:\zcad\cad_source\zcad/gui/forms;E:\zcad\cad_source\zcad/entities;E:\zcad\cad_source\zcad;E:\zcad\cad_source\zcad/gui/odjectinspector;E:\zcad\cad_source\zcad/core/undostack;E:\zcad\cad_source\zcad/register;E:\zcad\cad_source\zcad/core/drawings;E:\zcad\cad_source\zengine/core/utils;E:\zcad\cad_source\zcad/core/utils;zengine/core/objects;E:\zcad\cad_source\zcad/core;E:\zcad\cad_source\zcad/misc;E:\zcad\cad_source\other/AGraph/Graphs;E:\zcad\cad_source\other/AGraph/Attrs;E:\zcad\cad_source\other/AGraph/Math;E:\zcad\cad_source\other/AGraph/Vectors;E:\zcad\cad_source\other/AGraph/Packs';
  Options.ParserOptions._CompilerOptions:='-Sd -FiE:\zcad\cad_source\components\zebase\ -FiE:\zcad\cad_source\autogenerated\';}

  _SetUIFromOption(nil);

  AddEditorToType(RunTimeUnit^.TypeName2PTD('Integer'),TBaseTypesEditors.BaseCreateEditor);//register standart editor to integer type
  AddEditorToType(RunTimeUnit^.TypeName2PTD('Double'),TBaseTypesEditors.BaseCreateEditor);//register standart editor to double type
  AddEditorToType(RunTimeUnit^.TypeName2PTD('AnsiString'),TBaseTypesEditors.BaseCreateEditor);//register standart editor to string type
  AddEditorToType(RunTimeUnit^.TypeName2PTD('String'),TBaseTypesEditors.BaseCreateEditor);//register standart editor to string type
  AddEditorToType(RunTimeUnit^.TypeName2PTD('Boolean'),TBaseTypesEditors.GDBBooleanCreateEditor);//register standart editor to string type
  AddFastEditorToType(RunTimeUnit^.TypeName2PTD('Boolean'),@OIUI_FE_BooleanGetPrefferedSize,@OIUI_FE_BooleanDraw,@OIUI_FE_BooleanInverse);
  EnumGlobalEditor:=TBaseTypesEditors.EnumDescriptorCreateEditor;//register standart editor to all enum types

  GDBobjinsp1.setptr(nil,UnitsFormat,RunTimeUnit^.TypeName2PTD('TOptions'),@Options,nil);//show data variable in inspector
  caption:='pudgb v 0.1 rev:'+RevisionStr;
end;

procedure TForm1._onClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if assigned(ScanResult)then FreeAndNil(ScanResult);//чистим прошлый результат
end;

procedure TForm1._ImportLPI(Sender: TObject);
var
  od:TOpenDialog;
begin
   od:=TOpenDialog.Create(nil);
   od.Title:='Import Lazarus project file';
   od.Filter:='Lazarus project files (*.lpi)|*.lpi|All files (*.*)|*.*';
   od.DefaultExt:='lpi';
   od.FilterIndex := 1;
   if od.Execute then
   begin
     LPIImport(Options,od.FileName,DummyWriteToLog);
   end;
   od.Free;
   _SetUIFromOption(nil);
end;

procedure TForm1._OpenDPR(Sender: TObject);
var
  od:TOpenDialog;
begin
   od:=TOpenDialog.Create(nil);
   od.Title:='Open Dlphi project file';
   od.Filter:='Dlphi project files (*.dpr)|*.dpr|All files (*.*)|*.*';
   od.DefaultExt:='dpr';
   od.FilterIndex := 1;
   if od.Execute then
   begin
     DPROpen(Options,od.FileName,DummyWriteToLog);
   end;
   od.Free;
   _SetUIFromOption(nil);
end;
procedure TForm1._SaveGML(Sender: TObject);
begin
    Memo1.Clear;
    WriteGML(Options,ScanResult,DummyWriteToLog);//пишем то что унас есть в результате
end;

procedure TForm1._Exit(Sender: TObject);
begin
 close;
end;

procedure TForm1._CodeExplorer(Sender: TObject);
begin
 ExploreCode(Options,ScanResult,DummyWriteToLog);
end;

procedure TForm1._Save(Sender: TObject);
begin
   Memo1.Clear;
   WriteGraph(Options,ScanResult,DummyWriteToLog);//пишем то что унас есть в результате
end;
procedure TForm1._Scan(Sender: TObject);
var
  cd:ansistring;
begin
   cd:=GetCurrentDir;
   SetCurrentDir(ExtractFileDir(Options.Paths._File));
   Memo1.Clear;
   if assigned(ScanResult)then FreeAndNil(ScanResult);           //чистим прошлый результат
   ScanResult:=TScanResult.Create;                               //создаем новый результат
   if FileExists(Options.Paths._File)then
    ScanModule(Options.Paths._File,Options,ScanResult,DummyWriteToLog)//пытаемся читать файл исходников
   else
    ScanDirectory(Options.Paths._File,Options,ScanResult,DummyWriteToLog);//пытаемся читать директорию с исходниками
   SetCurrentDir(cd);
   {$IFDEF CHECKLOOPS}CheckGraph(Options,ScanResult,DummyWriteToLog);{$ENDIF}//проверяем граф
end;
procedure TForm1._OpenWebGraphviz(Sender: TObject);
begin
  OpenURL('http://www.webgraphviz.com');
end;
procedure TForm1.DummyWriteToLog(msg:string);
begin
   Memo1.Append(msg);
end;
end.

