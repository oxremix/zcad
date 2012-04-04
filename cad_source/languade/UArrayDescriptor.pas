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

unit UArrayDescriptor;
{$INCLUDE def.inc}
interface
uses log,TypeDescriptors,gdbasetypes,varmandef,gdbase,UGDBOpenArrayOfData{,UGDBStringArray},memman;
type
PArrayIndexDescriptor=^ArrayIndexDescriptor;
ArrayIndexDescriptor=record
                           IndexMin,IndexCount:GDBInteger;
                     end;
PArrayDescriptor=^ArrayDescriptor;
ArrayDescriptor=object(TUserTypeDescriptor)
                     NumOfIndex:GDBInteger;
                     typeof:PUserTypeDescriptor;
                     Indexs:GDBOpenArrayOfData;
                     constructor init(var t:PUserTypeDescriptor;tname:string;pu:pointer);
                     procedure AddIndex(var Index:ArrayIndexDescriptor);
                     function CreateProperties(mode:PDMode;PPDA:PTPropertyDeskriptorArray;Name:GDBString;PCollapsed:GDBPointer;ownerattrib:GDBWord;var bmode:GDBInteger;var addr:GDBPointer;ValKey,ValType:GDBString):PTPropertyDeskriptorArray;virtual;
                     destructor Done;virtual;
                     function GetValueAsString(pinstance:GDBPointer):GDBString;virtual;
               end;
implementation
uses {ZBasicVisible,}varman;
function ArrayDescriptor.GetValueAsString(pinstance:GDBPointer):GDBString;
var
   PAID:PArrayIndexDescriptor;
   ir:itrec;
   i:integer;
begin
     result:='(';
     PAID:=Indexs.beginiterate(ir);
     if paid<>nil then
                     repeat
                           for i:=paid^.IndexMin to paid^.IndexMin+paid^.IndexCount do
                           begin
                                if i<>paid^.IndexMin then result:=result+',';
                                result:=result+typeof^.GetValueAsString(pinstance);
                                typeof^.IncAddr(pinstance);
                           end;
                           PAID:=Indexs.iterate(ir);
                     until paid=nil;
     result:=result+')';
end;

constructor ArrayDescriptor.init;
begin
     inherited init(0,tname,pu);
     NumOfIndex:=0;
     typeof:=t;
     Indexs.init({$IFDEF DEBUGBUILD}'{1A33FBB9-F27B-4CF2-8C08-852A22572791}',{$ENDIF}20,sizeof(ArrayIndexDescriptor));
end;
destructor ArrayDescriptor.done;
begin
     inherited;
     Indexs.Done;
end;
procedure ArrayDescriptor.AddIndex;
begin
     indexs.add(@Index);
     inc(NumOfIndex);
     SizeInGDBBytes:=SizeInGDBBytes+typeof^.SizeInGDBBytes*Index.IndexCount
end;
function ArrayDescriptor.CreateProperties;
var ppd:PPropertyDeskriptor;
begin
     {$IFDEF TOTALYLOG}programlog.LogOutStr('ArrayDescriptor.CreateProperties('+name+')',lp_OldPos);{$ENDIF}
     ppd:=GetPPD(ppda,bmode);
     ppd^.Name:=name;
     ppd^.PTypeManager:=@self;
     ppd^.Attr:=ownerattrib;
     ppd^.Collapsed:=PCollapsed;
     ppd^.valueAddres:=addr;
     ppd^.value:=GetValueAsString(addr);//'not ready';

           if ppd<>nil then
                           begin
                                //IncAddr(addr);
                                //inc(pGDBByte(addr),SizeInGDBBytes);
                                //if bmode=property_build then PPDA^.add(@ppd);
                           end;
     IncAddr(addr);
end;
begin
  {$IFDEF DEBUGINITSECTION}LogOut('UArrayDescriptor.initialization');{$ENDIF}
end.
