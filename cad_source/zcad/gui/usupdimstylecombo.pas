{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
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

unit usupdimstylecombo;
{$INCLUDE def.inc}

interface

uses
  usupportgui,StdCtrls,UGDBDescriptor,zcadstrconsts,Controls,Classes,ugdbdimstylearray,strproc,uzcsysvars,commandline,zcadinterface;

type
  TSupportDimStyleCombo = class
                             class procedure DropDownTStyle(Sender:Tobject);
                             class procedure CloseUpTStyle(Sender:Tobject);
                             class procedure FillLTStyle(cb:TCustomComboBox);
                             class procedure DrawItemTStyle(Control: TWinControl; Index: Integer; ARect: TRect;
                                                              State: TOwnerDrawState);
                             class procedure ChangeLType(Sender:Tobject);
  end;

implementation
uses
  mainwindow;
class procedure TSupportDimStyleCombo.DropDownTStyle(Sender:Tobject);
var
  i:integer;
  PDimStyleArray:PGDBDimStyleArray;
  PDimStyle:PGDBDimStyle;
begin
  //Correct items count
  PDimStyleArray:=@gdb.GetCurrentDWG.DimStyleTable;
  SetcomboItemsCount(tcombobox(Sender),PDimStyleArray.Count);

  //Correct items
  for i:=0 to PDimStyleArray.Count-1 do
  begin
       PDimStyle:=gdb.GetCurrentDWG.DimStyleTable.getelement(i);
       tcombobox(Sender).Items.Objects[i]:=tobject(PDimStyle);
  end;
  tcombobox(Sender).ItemIndex:=-1;
end;
class procedure TSupportDimStyleCombo.CloseUpTStyle(Sender:Tobject);
begin
     tcombobox(Sender).ItemIndex:=0;
end;
class procedure TSupportDimStyleCombo.FillLTStyle(cb:TCustomComboBox);
begin
  cb.items.AddObject('', TObject(0));
end;
class procedure TSupportDimStyleCombo.DrawItemTStyle(Control: TWinControl; Index: Integer; ARect: TRect;
                                                     State: TOwnerDrawState);
var
  pts:PGDBDimStyle;
   s:string;
begin
    if gdb.GetCurrentDWG=nil then
                                 exit;
    if gdb.GetCurrentDWG.LTypeStyleTable.Count=0 then
                                 exit;
    ComboBoxDrawItem(Control,ARect,State);

    if TComboBox(Control).DroppedDown then
                                          pts:=PGDBDimStyle(tcombobox(Control).items.Objects[Index])
                                      else
                                          pts:=IVars.CDimStyle;
    if pts<>nil then
                   begin
                        s:=Tria_AnsiToUtf8(pts^.Name);
                   end
               else
                   begin
                       s:=rsDifferent;
                   end;

    ARect.Left:=ARect.Left+2;
    TComboBox(Control).Canvas.TextRect(ARect,ARect.Left,(ARect.Top+ARect.Bottom-TComboBox(Control).Canvas.TextHeight(s)) div 2,s);
end;
class procedure TSupportDimStyleCombo.ChangeLType(Sender:Tobject);
var
   index:Integer;
   CLTSave,pts:PGDBDimStyle;
begin
     index:=tcombobox(Sender).ItemIndex;
     pts:=PGDBDimStyle(tcombobox(Sender).items.Objects[index]);
     if pts=nil then
                         exit;


     if gdb.GetCurrentDWG.wa.param.seldesc.Selectedobjcount=0
     then
     begin
          SysVar.dwg.DWG_CDimStyle^:=pts;
     end
     else
     begin
          CLTSave:=SysVar.dwg.DWG_CDimStyle^;
          SysVar.dwg.DWG_CDimStyle^:={TSIndex}pts;
          commandmanager.ExecuteCommand('SelObjChangeDimStyleToCurrent',gdb.GetCurrentDWG,gdb.GetCurrentOGLWParam);
          SysVar.dwg.DWG_CDimStyle^:=CLTSave;
     end;
     if assigned(SetVisuaProplProc) then SetVisuaProplProc;
     //setnormalfocus(nil);
end;


end.
