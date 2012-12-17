﻿{
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

unit UEnumDescriptor;
{$INCLUDE def.inc}
interface
uses sysutils,UGDBOpenArrayOfTObjLinkRecord,UGDBOpenArrayOfByte,TypeDescriptors,gdbasetypes,varmandef,gdbase,
  UGDBOpenArrayOfData,UGDBStringArray,memman,
  StdCtrls;
type
PEnumDescriptor=^EnumDescriptor;
EnumDescriptor=object(TUserTypeDescriptor)
                     SourceValue:GDBGDBStringArray;
                     UserValue:GDBGDBStringArray;
                     Value:GDBOpenArrayOfData;
                     constructor init(size:GDBInteger;tname:string;pu:pointer);
                     procedure EditorChange(Sender:TObject;NewValue:GDBInteger);
                     function CreateProperties(mode:PDMode;PPDA:PTPropertyDeskriptorArray;Name:GDBString;PCollapsed:GDBPointer;ownerattrib:GDBWord;var bmode:GDBInteger;var addr:GDBPointer;ValKey,ValType:GDBString):PTPropertyDeskriptorArray;virtual;
                     function CreateEditor(TheOwner:TPropEditorOwner;x,y,w,h:GDBInteger;pinstance:pointer;psa:PGDBGDBStringArray;FreeOnLostFocus:boolean):TPropEditor;virtual;
                     function GetNumberInArrays(addr:GDBPointer;out number:GDBLongword):GDBBoolean;virtual;
                     function Serialize(PInstance:GDBPointer;SaveFlag:GDBWord;var membuf:PGDBOpenArrayOfByte;var  linkbuf:PGDBOpenArrayOfTObjLinkRecord;var sub:integer):integer;virtual;
                     function DeSerialize(PInstance:GDBPointer;SaveFlag:GDBWord;var membuf:GDBOpenArrayOfByte;linkbuf:PGDBOpenArrayOfTObjLinkRecord):integer;virtual;
                     function GetValueAsString(pinstance:GDBPointer):GDBString;virtual;
                     function GetUserValueAsString(pinstance:GDBPointer):GDBString;virtual;
                     destructor Done;virtual;
                     function GetTypeAttributes:TTypeAttr;virtual;
                     procedure SetValueFromString(PInstance:GDBPointer;_Value:GDBstring);virtual;
               end;
implementation
uses log;
function EnumDescriptor.GetTypeAttributes:TTypeAttr;
begin
     result:=ta_enum;
end;
function EnumDescriptor.Serialize;
//var l:gdbword;
begin
     if membuf=nil then
                       begin
                            gdbgetmem({$IFDEF DEBUGBUILD}'{EB2A30ED-C143-4D72-9D2F-FB9B0FEA334D}',{$ENDIF}pointer(membuf),sizeof(GDBOpenArrayOfByte));
                            membuf.init({$IFDEF DEBUGBUILD}'{9A6388D0-F417-4E04-BA50-2CB224DD4F66}',{$ENDIF}1000000);
                       end;
     membuf^.AddData(PInstance,SizeInGDBBytes)
end;
function EnumDescriptor.DeSerialize;
//var l:gdbword;
begin
     membuf.ReadData(PInstance,SizeInGDBBytes)
end;
destructor EnumDescriptor.done;
begin
     inherited;
     SourceValue.FreeAndDone;
     UserValue.FreeAndDone;
     value.Done;
end;
constructor EnumDescriptor.init;
begin
     //gdbgetmem({$IFDEF DEBUGBUILD}'{B8CB2886-0E46-4426-B99B-EA4A0948FAE7}',{$ENDIF}GDBPointer(PSourceValue),sizeof(PSourceValue^));
     //gdbgetmem({$IFDEF DEBUGBUILD}'{28FC622D-1EAD-4CCA-801B-ECF3B7E3C9D5}',{$ENDIF}GDBPointer(PSourceValue),sizeof(PUserValue^));
     inherited init(size,tname,pu);
     SourceValue.init(20);
     UserValue.init(20);
     case size of
                 1:Value.init({$IFDEF DEBUGBUILD}'{EA29780F-2455-4BBF-9CB6-054B6A4D48C5}',{$ENDIF}20,1);
                 2:Value.init({$IFDEF DEBUGBUILD}'{E17DB617-1782-4815-BA8B-12F53B06DAD8}',{$ENDIF}20,2);
                 4:Value.init({$IFDEF DEBUGBUILD}'{21381F6A-26DC-43C3-B4F8-0BBB24722B75}',{$ENDIF}20,4);
     end;
end;
function EnumDescriptor.CreateProperties;
var currval:GDBLongword;
//    p:GDBPointer;
//    found:GDBBoolean;
//    i:GDBInteger;
    ppd:PPropertyDeskriptor;
begin
     ppd:=GetPPD(ppda,bmode);
     ppd^.Name:=name;
     ppd^.PTypeManager:=@self;
     ppd^.Attr:=ownerattrib;
     ppd^.Collapsed:=PCollapsed;
     ppd^.valueAddres:=addr;
     ppd^.ValKey:=valkey;
     ppd^.ValType:=valtype;
     
     if (ppd^.Attr and FA_DIFFERENT)=0 then
                                           begin
                                                 if GetNumberInArrays(GDBPointer(ppd^.valueAddres),currval)then ppd^.value:=UserValue.getGDBString(currval)
                                                                                                           else ppd^.value:='NotFound';
                                           end
                                       else
                                           ppd^.value:='*Разный*';    
     IncAddr(addr);
end;
function EnumDescriptor.GetNumberInArrays;
var currval:GDBLongword;
    p:GDBPointer;
    //found:GDBBoolean;
//    i:GDBInteger;
        ir:itrec;
begin
     result:=false;
     case SizeInGDBBytes of
                      1:begin
                             currval:=pGDBByte(addr)^;
                             p:=Value.beginiterate(ir);
                             if p<>nil then
                             repeat
                                   if pGDBByte(p)^=currval then
                                                            begin
                                                                 //found:=true;
                                                                 number:=ir.itc;
                                                                 result:=true;
                                                                 system.Break;
                                                            end;
                                   p:=Value.iterate(ir);
                             until p=nil;
                        end;
     end;
end;
procedure EnumDescriptor.SetValueFromString(PInstance:GDBPointer;_Value:GDBstring);
var //currval:GDBLongword;
    p,p2,pp:GDBPointer;
//    found:GDBBoolean;
//    i:GDBInteger;
        ir,ir2,irr:itrec;
begin
     _value:=uppercase(_value);
     case SizeInGDBBytes of
                      1:begin
                             p:=SourceValue.beginiterate(ir);
                             p2:=UserValue.beginiterate(ir2);
                             pp:=Value.beginiterate(irr);
                             if p<>nil then
                             repeat
                             if (_value=uppercase(pstring(p)^))
                             or (_value=uppercase(pstring(p2)^))then
                             begin
                                  pGDBByte(pinstance)^:=pbyte(pp)^;
                                  exit;
                             end;
                                   p:=SourceValue.iterate(ir);
                                   p2:=UserValue.iterate(ir2);
                                   pp:=Value.iterate(irr);
                             until p=nil;
                      end;
     end;
end;
function EnumDescriptor.GetValueAsString;
var //currval:GDBLongword;
//    p:GDBPointer;
//    found:GDBBoolean;
//    i:GDBInteger;
    num:cardinal;
begin
     result:='ENUMERROR';
     GetNumberInArrays(pinstance,num);
     result:={UserValue}SourceValue.getGDBString(num)
end;
function EnumDescriptor.GetUserValueAsString;
var //currval:GDBLongword;
//    p:GDBPointer;
//    found:GDBBoolean;
//    i:GDBInteger;
    num:cardinal;
begin
     result:='ENUMERROR';
     GetNumberInArrays(pinstance,num);
     result:=UserValue.getGDBString(num)
end;
procedure EnumDescriptor.EditorChange(Sender:Tobject;NewValue:GDBInteger);
begin
    (* case SizeInGDBBytes of
                      1:begin
                             pGDBByte(Sender^.LincedData)^:=pGDBByte(Value.getelement(NewValue))^;
                        end;
     end;
     *)
end;
function EnumDescriptor.CreateEditor;
var
    cbedit:TComboBox;
    propeditor:TPropEditor;
    ir:itrec;
    number:longword;
    p:pgdbstring;
begin
     propeditor:=TPropEditor.Create(theowner,PInstance,@self,FreeOnLostFocus);
     cbedit:=TComboBox.Create(propeditor);
     cbedit.SetBounds(x,y,w,h);
     cbedit.Text:=GetValueAsString(pinstance);
     //cbedit.OnEditingDone:=propeditor.EditingDone;
     //cbedit.OnKeyPress:=propeditor.keyPress;
     cbedit.OnChange:=propeditor.EditingProcess;
     {$IFNDEF DELPHI}
     cbedit.ReadOnly:=true;
     {$ENDIF}

                             p:=UserValue.beginiterate(ir);
                             if p<>nil then
                             repeat
                                   cbedit.Items.Add(p^);
                                   p:=UserValue.iterate(ir);
                             until p=nil;

     GetNumberInArrays(PInstance,number);
     cbedit.ItemIndex:=number;

     cbedit.Parent:=theowner;
     cbedit.DroppedDown:=true;
     result:=propeditor;
     (*
     gdbgetmem({$IFDEF DEBUGBUILD}'{926E1599-2B34-43FF-B9D5-885F4E37F2B3}',{$ENDIF}result,sizeof(ZComboBoxWithProc));
     PZComboBoxWithProc(result).initxywh('',owner,x,y,w,h+100,true);
     PZComboBoxWithProc(result).LincedData:=pinstance;
     //PZComboBoxWithProc(result)^.assigntoprocofobject(onc(self.EditorChange));
     PZComboBoxWithProc(result)^.onChangeObj:=EditorChange;
     //PZComboBoxWithProc(result)^.onChangeObj(nil,1);

     //tmethod(self.EditorChange);
     selectobject(PZComboBoxWithProc(result)^.DC, GetStockObject(ANSI_VAR_FONT));
     self.UserValue.copyto(@PZComboBoxWithProc(result)^.GDBStrings);
     PZComboBoxWithProc(result).sync;
     num:=0;
     GetNumberInArrays(pinstance,num);
     PZComboBoxWithProc(result)^.setitem(num);
     *)
end;
begin
  {$IFDEF DEBUGINITSECTION}LogOut('UEnumDescriptor.initialization');{$ENDIF}
end.
