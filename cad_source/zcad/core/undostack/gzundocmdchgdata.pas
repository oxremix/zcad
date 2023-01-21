{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.txt, included in this distribution,                 *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>)
}
{$MODE OBJFPC}{$H+}
unit gzundoCmdChgData;
{$INCLUDE zengineconfig.inc}
interface
uses uzepalette,zeundostack,zebaseundocommands,uzbtypes,
     uzegeometrytypes,uzeentity,uzestyleslayers,uzeentabstracttext;

type
generic GUCmdChgData<_T> =class(TCustomChangeCommand2)
                                      public
                                      OldData,NewData:_T;
                                      PEntity:PGDBObjEntity;
                                      constructor Create(var data:_T);

                                      procedure UnDo;override;
                                      procedure Comit;override;
                                      procedure ComitFromObj;virtual;
                                      function GetDataTypeSize:PtrInt;virtual;
                                end;
{$MACRO ON}

{$DEFINE INTERFACE}
{$DEFINE TCommand  := TGDBVertexChangeCommand}
{$DEFINE TData     := GDBVertex}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TDoubleChangeCommand}
{$DEFINE TData     := Double}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBCameraBasePropChangeCommand}
{$DEFINE TData     := GDBCameraBaseProp}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TStringChangeCommand}
{$DEFINE TData     := String}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBPoinerChangeCommand}
{$DEFINE TData     := Pointer}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TBooleanChangeCommand}
{$DEFINE TData     := Boolean}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBByteChangeCommand}
{$DEFINE TData     := Byte}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBTGDBLineWeightChangeCommand}
{$DEFINE TData     := TGDBLineWeight}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBTGDBPaletteColorChangeCommand}
{$DEFINE TData     := TGDBPaletteColor}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBTTextJustifyChangeCommand}
{$DEFINE TData     := TTextJustify}
  {$I TGChangeCommandIMPL.inc}
{$UNDEF INTERFACE}

{$DEFINE CLASSDECLARATION}
{$DEFINE TCommand  := TGDBVertexChangeCommand}
{$DEFINE TData     := GDBVertex}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TDoubleChangeCommand}
{$DEFINE TData     := Double}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBCameraBasePropChangeCommand}
{$DEFINE TData     := GDBCameraBaseProp}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TStringChangeCommand}
{$DEFINE TData     := String}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBPoinerChangeCommand}
{$DEFINE TData     := Pointer}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TBooleanChangeCommand}
{$DEFINE TData     := Boolean}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBByteChangeCommand}
{$DEFINE TData     := Byte}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBTGDBLineWeightChangeCommand}
{$DEFINE TData     := TGDBLineWeight}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBTGDBPaletteColorChangeCommand}
{$DEFINE TData     := TGDBPaletteColor}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBTTextJustifyChangeCommand}
{$DEFINE TData     := TTextJustify}
  {$I TGChangeCommandIMPL.inc}
{$UNDEF CLASSDECLARATION}
implementation
uses uzcdrawings,uzcinterface;
constructor GUCmdChgData.Create(var data:_T);
begin
     Addr:=@data;
     olddata:=data;
     newdata:=data;
     PEntity:=nil;
end;
procedure GUCmdChgData.UnDo;
begin
     _T(addr^):=OldData;
     if assigned(PEntity)then
                             PEntity^.YouChanged(drawings.GetCurrentDWG^);
     ZCMsgCallBackInterface.Do_GUIaction(nil,ZMsgID_GUIActionRebuild);
     //if assigned(SetVisuaProplProc)then
     //                                  SetVisuaProplProc;
end;
procedure GUCmdChgData.Comit;
begin
     _T(addr^):=NewData;
     if assigned(PEntity)then
                             PEntity^.YouChanged(drawings.GetCurrentDWG^);
     ZCMsgCallBackInterface.Do_GUIaction(nil,ZMsgID_GUIActionRebuild);
     //if assigned(SetVisuaProplProc)then
     //                                  SetVisuaProplProc;

end;
procedure GUCmdChgData.ComitFromObj;
begin
     NewData:=_T(addr^);
end;
function GUCmdChgData.GetDataTypeSize:PtrInt;
begin
     result:=sizeof(_T);
end;

{$DEFINE IMPLEMENTATION}
{$DEFINE TCommand  := TGDBVertexChangeCommand}
{$DEFINE PTCommand := PTGDBVertexChangeCommand}
{$DEFINE TData     := GDBVertex}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TDoubleChangeCommand}
{$DEFINE PTCommand := PTDoubleChangeCommand}
{$DEFINE TData     := Double}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBCameraBasePropChangeCommand}
{$DEFINE PTCommand := PTGDBCameraBasePropChangeCommand}
{$DEFINE TData     := GDBCameraBaseProp}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TStringChangeCommand}
{$DEFINE PTCommand := PTStringChangeCommand}
{$DEFINE TData     := String}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBPoinerChangeCommand}
{$DEFINE PTCommand := PTGDBPoinerChangeCommand}
{$DEFINE TData     := Pointer}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TBooleanChangeCommand}
{$DEFINE PTCommand := PTBooleanChangeCommand}
{$DEFINE TData     := Boolean}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBByteChangeCommand}
{$DEFINE PTCommand := PTGDBByteChangeCommand}
{$DEFINE TData     := Byte}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBTGDBLineWeightChangeCommand}
{$DEFINE PTCommand := PTGDBTGDBLineWeightChangeCommand}
{$DEFINE TData     := TGDBLineWeight}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBTGDBPaletteColorChangeCommand}
{$DEFINE PTCommand := PTGDBTGDBPaletteColorChangeCommand}
{$DEFINE TData     := TGDBPaletteColor}
  {$I TGChangeCommandIMPL.inc}

{$DEFINE TCommand  := TGDBTTextJustifyChangeCommand}
{$DEFINE PTCommand := PTGDBTTextJustifyChangeCommand}
{$DEFINE TData     := TTextJustify}
  {$I TGChangeCommandIMPL.inc}
{$UNDEF IMPLEMENTATION}

{$MACRO OFF}
end.
