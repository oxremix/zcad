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

unit uzcoimultipropertiesutil;
{$INCLUDE def.inc}

interface
uses
  uzctnrvectorgdbpointer,uzbstrproc, uzctnrvectorgdbstring,{uzcoimultiobjects,}uzepalette,uzbmemman,sysutils,uzeentityfactory,
  uzbgeomtypes,uzbtypes,
  uzcdrawings,
  varmandef,
  uzeentity,
  uzbtypesbase,
  Varman,UGDBPoint3DArray,
  uzedimensionaltypes,
  gzctnrvectortypes,uzeentcircle,uzeentarc,uzeentline,uzeentblockinsert,
  uzeenttext,uzeentmtext,uzeentpolyline,uzegeometry,uzcoimultiproperties,LazLogger,
  uzcstrconsts,
  gzctnrstl,usimplegenerics;
type
  PTOneVarData=^TOneVarData;
  TOneVarData=record
                    StrValue:GDBString;
                    //PVarDesc:pvardesk;
                    VDAddr:TInVectorAddr
              end;
  TStringCounter=TMyMapCounter<string>;
  PTStringCounterData=^TStringCounterData;
  TStringCounterData=record
                    counter:TStringCounter;
                    totalcount:integer;
                    //PVarDesc:pvardesk;
                    VDAddr:TInVectorAddr;
              end;
  TPointerCounter=TMyMapCounter<pointer>;
  PTPointerCounterData=^TPointerCounterData;
  TPointerCounterData=record
                    counter:TPointerCounter;
                    totalcount:integer;
                    //PVarDesc:pvardesk;
                    VDAddr:TInVectorAddr;
              end;
  PTVertex3DControlVarData=^TVertex3DControlVarData;
  TVertex3DControlVarData=record
                            StrValueX,StrValueY,StrValueZ:GDBString;
                            {PArrayIndexVarDesc,
                            PXVarDesc,
                            PYVarDesc,
                            PZVarDesc:pvardesk;}
                            ArrayIndexVarDescAddr,
                            XVarDescAddr,
                            YVarDescAddr,
                            ZVarDescAddr:TInVectorAddr;
                            PGDBDTypeDesc:PUserTypeDescriptor;
                          end;




function GetOneVarData(mp:TMultiProperty;pu:PTObjectUnit):GDBPointer;
function GetStringCounterData(mp:TMultiProperty;pu:PTObjectUnit):GDBPointer;
function GetPointerCounterData(mp:TMultiProperty;pu:PTObjectUnit):GDBPointer;
function GetVertex3DControlData(mp:TMultiProperty;pu:PTObjectUnit):GDBPointer;
procedure FreeOneVarData(piteratedata:GDBPointer;mp:TMultiProperty);
procedure FreeStringCounterData(piteratedata:GDBPointer;mp:TMultiProperty);
procedure FreePNamedObjectCounterData(piteratedata:GDBPointer;mp:TMultiProperty);
procedure FreePNamedObjectCounterDataUTF8(piteratedata:GDBPointer;mp:TMultiProperty);
procedure FreeVertex3DControlData(piteratedata:GDBPointer;mp:TMultiProperty);
procedure GeneralEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
procedure EntityNameEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
procedure PolylineVertex3DControlEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
procedure PolylineVertex3DControlFromVarEntChangeProc(pu:PTObjectUnit;pdata:PVarDesk;ChangedData:TChangedData;mp:TMultiProperty);
procedure GDBDouble2SumEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
procedure TArrayIndex2SumEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
procedure Blockname2BlockNameCounterIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
procedure PStyle2PStyleCounterIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
procedure PolylineVertex3DControlBeforeEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData);
function CreateChangedData(pentity:pointer;GSData:TGetSetData):TChangedData;
procedure GeneralFromVarEntChangeProc(pu:PTObjectUnit;pdata:PVarDesk;ChangedData:TChangedData;mp:TMultiProperty);
const
  OneVarDataMIPD:TMainIterateProcsData=(BeforeIterateProc:GetOneVarData;
                                        AfterIterateProc:FreeOneVarData);
  OneVarDataEIPD:TEntIterateProcsData=(ebip:nil;
                                       eip:GeneralEntIterateProc;
                                       ECP:GeneralFromVarEntChangeProc;
                                       CV:nil);
  OneVarRODataEIPD:TEntIterateProcsData=(ebip:nil;
                                       eip:GeneralEntIterateProc;
                                       ECP:nil;
                                       CV:nil);

implementation
var
   Vertex3DControl:TArrayIndex=0;

procedure GeneralFromVarEntChangeProc(pu:PTObjectUnit;pdata:PVarDesk;ChangedData:TChangedData;mp:TMultiProperty);
begin
     mp.MPType^.CopyInstanceTo(pvardesk(pdata)^.data.Addr.Instance,ChangedData.PSetDataInEtity);
     ProcessVariableAttributes(pvardesk(pdata)^.attrib,0,vda_approximately or vda_different);
end;

function FindOrCreateVar(pu:PTObjectUnit;varname,username,typename:GDBString;out IVA:TInVectorAddr):GDBBoolean;
var
   vd:vardesk;
begin
  IVA:=pu^.FindVarDesc(varname);
  if IVA.IsNil then begin
    pu^.setvardesc(vd, varname,username,typename);
    IVA:=pu^.InterfaceVariables.createvariable2(varname,vd);
    result:=true;
  end else
    result:=false;
end;
function GetOneVarData(mp:TMultiProperty;pu:PTObjectUnit):GDBPointer;
{
создает структуру с описанием одной переменной необходимой для mp в pu
mp - описание мультипроперти
pu - модуль в котором будет создана переменная для мультипроперти
возвращает указатель на созданную структуру
}
{var
   vd:vardesk;}
//var
  //PVD:pvardesk;
begin
    GDBGetMem({$IFDEF DEBUGBUILD}'{831CDE55-8FC6-4ACD-8A4C-FEB861D44294}',{$ENDIF}result,sizeof(TOneVarData));
    pointer(PTOneVarData(result)^.StrValue):=nil;
    FindOrCreateVar(pu,mp.MPName,mp.MPUserName,mp.MPType^.TypeName,PTOneVarData(result).VDAddr);
    //PTOneVarData(result).VDAddr:=PVD^.data.Addr;
end;

function GetStringCounterData(mp:TMultiProperty;pu:PTObjectUnit):GDBPointer;
{
создает структуру с описанием переменной осуществляющей подсчет стрингов
mp - описание мультипроперти
pu - модуль в котором будет создана переменная для мультипроперти
возвращает указатель на созданную структуру
}
var
  PVD:pvardesk;
begin
    GDBGetMem({$IFDEF DEBUGBUILD}'{831CDE55-8FC6-4ACD-8A4C-FEB861D44294}',{$ENDIF}result,sizeof(TStringCounterData));
    PTStringCounterData(result)^.counter:=TStringCounter.Create;
    if FindOrCreateVar(pu,mp.MPName,mp.MPUserName,mp.MPType^.TypeName,PTStringCounterData(result).VDAddr) then begin
      PVD:=PTStringCounterData(result).VDAddr.Instance;
      PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Enums.init(10);
      PTStringCounterData(result)^.totalcount:=0;
      PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Selected:=0;
      GDBGetMem({$IFDEF DEBUGBUILD}'{831CDE55-8FC6-4ACD-8A4C-FEB861D44294}',{$ENDIF}PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData,sizeof(TZctnrVectorGDBString));
      PTZctnrVectorGDBString(PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData)^.init(10);
    end;
    //PTStringCounterData(result).VDAddr:=PVD^.data.Addr;
end;

function GetPointerCounterData(mp:TMultiProperty;pu:PTObjectUnit):GDBPointer;
{
создает структуру с описанием переменной осуществляющей подсчет указателей
mp - описание мультипроперти
pu - модуль в котором будет создана переменная для мультипроперти
возвращает указатель на созданную структуру
}
var
  PVD:pvardesk;
  t:PTEnumDataWithOtherData;
begin
    GDBGetMem({$IFDEF DEBUGBUILD}'{831CDE55-8FC6-4ACD-8A4C-FEB861D44294}',{$ENDIF}result,sizeof(TPointerCounterData));
    PTPointerCounterData(result)^.counter:=TPointerCounter.Create;
    if FindOrCreateVar(pu,mp.MPName,mp.MPUserName,mp.MPType^.TypeName,PTPointerCounterData(result).VDAddr) then begin
      PVD:=PTPointerCounterData(result).VDAddr.Instance;
      t:=PVD^.data.Addr.Instance;
      PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Enums.init(10);
      PTPointerCounterData(result)^.totalcount:=0;
      PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Selected:=0;
      GDBGetMem({$IFDEF DEBUGBUILD}'{831CDE55-8FC6-4ACD-8A4C-FEB861D44294}',{$ENDIF}PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData,sizeof(TZctnrVectorGDBPointer));
      PTZctnrVectorGDBPointer(PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData)^.init(10);
    end;
    //PTPointerCounterData(result).VDAddr:=PVD^.data.Addr;
end;


function GetVertex3DControlData(mp:TMultiProperty;pu:PTObjectUnit):GDBPointer;
{
создает структуру с описанием контроля 3Д вершин
mp - описание мультипроперти
pu - модуль в котором будет создана переменная для мультипроперти
возвращает указатель на созданную структуру
}
{var
   vd:vardesk;}
begin
    GDBGetMem({$IFDEF DEBUGBUILD}'{15C8D138-5A5B-44F1-B725-FFFF20869CD9}',{$ENDIF}result,sizeof(TVertex3DControlVarData));
    pointer(PTVertex3DControlVarData(result)^.StrValueX):=nil;
    pointer(PTVertex3DControlVarData(result)^.StrValueY):=nil;
    pointer(PTVertex3DControlVarData(result)^.StrValueZ):=nil;
    if FindOrCreateVar(pu,mp.MPName,mp.MPUserName,mp.MPType^.TypeName,PTVertex3DControlVarData(result).ArrayIndexVarDescAddr) then
       mp.MPType.CopyInstanceTo(@Vertex3DControl,pvardesk(PTVertex3DControlVarData(result).ArrayIndexVarDescAddr.Instance)^.data.Addr.Instance);
    FindOrCreateVar(pu,mp.MPName+'x','x','GDBDouble',PTVertex3DControlVarData(result).XVarDescAddr);
    FindOrCreateVar(pu,mp.MPName+'y','y','GDBDouble',PTVertex3DControlVarData(result).YVarDescAddr);
    FindOrCreateVar(pu,mp.MPName+'z','z','GDBDouble',PTVertex3DControlVarData(result).ZVarDescAddr);
    PTVertex3DControlVarData(result).PGDBDTypeDesc:=SysUnit.TypeName2PTD('GDBDouble');
end;

procedure FreeOneVarData(piteratedata:GDBPointer;mp:TMultiProperty);
{уничтожает созданную GetOneVarData структуру}
begin
    PTOneVarData(piteratedata)^.StrValue:='';
    GDBFreeMem(piteratedata);
end;
procedure FreeStringCounterData(piteratedata:GDBPointer;mp:TMultiProperty);
var
  pair:TStringCounter.TDictionaryPair;
  //iterator:TStringCounter.TIterator;
  s:string;
  c:integer;
  PVD:pvardesk;
{уничтожает созданную GetStringCounterData структуру}
begin
    //PTStringCounterData(piteratedata)^.StrValue:='';
  PVD:=PTStringCounterData(piteratedata)^.VDAddr.Instance;
  PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Enums.PushBackData(format('Total (%d)',[PTStringCounterData(piteratedata)^.totalcount]));
  PTZctnrVectorGDBString(PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData)^.PushBackData('*');
  for pair in PTStringCounterData(piteratedata)^.counter do begin
  //iterator:=PTStringCounterData(piteratedata)^.counter.Min;
  //if assigned(iterator) then
  //repeat
        s:=pair.Key;
        c:=pair.Value;
        PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Enums.PushBackData(format('%s (%d)',[Tria_AnsiToUtf8(s),c]));
        PTZctnrVectorGDBString(PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData)^.PushBackData(s);
  //until not iterator.Next;
  end;
  PTStringCounterData(piteratedata)^.counter.Free;
  GDBFreeMem(piteratedata);
end;
procedure FreePNamedObjectCounterData(piteratedata:GDBPointer;mp:TMultiProperty);
var
  pair:TPointerCounter.TDictionaryPair;
  //iterator:TPointerCounter.TIterator;
   s:PGDBNamedObject;
   c:integer;
   name:string;
   PVD:pvardesk;
   t:PTEnumDataWithOtherData;
{уничтожает созданную GetPointerCounterData структуру}
begin
  PVD:=PTPointerCounterData(piteratedata)^.VDAddr.Instance;
  t:=PVD^.data.Addr.Instance;
  PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Enums.PushBackData(format('Total (%d)',[PTPointerCounterData(piteratedata)^.totalcount]));
  PTZctnrVectorGDBPointer(PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData)^.PushBackData(nil);
  for pair in PTPointerCounterData(piteratedata)^.counter do begin
  //iterator:=PTPointerCounterData(piteratedata)^.counter.Min;
  //if assigned(iterator) then
  //repeat
        s:=pair.Key;
        c:=pair.Value;
        if assigned(s) then
          name:=Tria_AnsiToUtf8(s.GetFullName)
        else
          name:='nil';
        PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Enums.PushBackData(format('%s (%d)',[name,c]));
        PTZctnrVectorGDBPointer(PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData)^.PushBackData(s);
  //until not iterator.Next;
  end;
  PTPointerCounterData(piteratedata)^.counter.Free;
  GDBFreeMem(piteratedata);
end;
procedure FreePNamedObjectCounterDataUTF8(piteratedata:GDBPointer;mp:TMultiProperty);
var
  pair:TPointerCounter.TDictionaryPair;
  //iterator:TPointerCounter.TIterator;
   s:PGDBNamedObject;
   c:integer;
   PVD:pvardesk;
{уничтожает созданную GetPointerCounterData структуру}
begin
  PVD:=PTPointerCounterData(piteratedata)^.VDAddr.Instance;
  PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Enums.PushBackData(format('Total (%d)',[PTPointerCounterData(piteratedata)^.totalcount]));
  PTZctnrVectorGDBPointer(PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData)^.PushBackData(nil);
  for pair in PTPointerCounterData(piteratedata)^.counter do begin
  //iterator:=PTPointerCounterData(piteratedata)^.counter.Min;
  //if assigned(iterator) then
  //repeat
        s:=pair.Key;
        c:=pair.Value;
        PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.Enums.PushBackData(format('%s (%d)',[(s.GetFullName),c]));
        PTZctnrVectorGDBPointer(PTEnumDataWithOtherData(PVD^.data.Addr.Instance)^.PData)^.PushBackData(s);
  //until not iterator.Next;
  end;
  PTPointerCounterData(piteratedata)^.counter.Free;
  GDBFreeMem(piteratedata);
end;

procedure FreeVertex3DControlData(piteratedata:GDBPointer;mp:TMultiProperty);
{уничтожает созданную GetVertex3DControlData структуру}
begin
    PTVertex3DControlVarData(piteratedata)^.StrValueX:='';
    PTVertex3DControlVarData(piteratedata)^.StrValueY:='';
    PTVertex3DControlVarData(piteratedata)^.StrValueZ:='';
    GDBFreeMem(piteratedata);
end;
procedure PolylineVertex3DControlBeforeEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData);
var
   cc:TArrayIndex;
begin
     cc:=PGDBPoint3dArray(ChangedData.PGetDataInEtity).Count-1;
     if cc<PTArrayIndex(pvardesk(PTVertex3DControlVarData(pdata).ArrayIndexVarDescAddr.Instance)^.data.Addr.Instance)^ then
                                                                                               PTArrayIndex(pvardesk(PTVertex3DControlVarData(pdata).ArrayIndexVarDescAddr.Instance)^.data.Addr.Instance)^:=cc;
     if PTArrayIndex(pvardesk(PTVertex3DControlVarData(pdata).ArrayIndexVarDescAddr.Instance)^.data.Addr.Instance)^<0 then
                                                                                              PTArrayIndex(pvardesk(PTVertex3DControlVarData(pdata).ArrayIndexVarDescAddr.Instance)^.data.Addr.Instance)^:=0;
end;
procedure PolylineVertex3DControlEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
var
   tv:PGDBVertex;
   cc:TArrayIndex;
begin
     if fistrun then
                    fistrun:=fistrun;
     if @ecp=nil then
                     begin
                          ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).XVarDescAddr.Instance).attrib,vda_RO,0);
                          ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).YVarDescAddr.Instance).attrib,vda_RO,0);
                          ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).ZVarDescAddr.Instance).attrib,vda_RO,0);
                     end;
     cc:=PGDBPoint3dArray(ChangedData.PGetDataInEtity).Count-1;
     if cc<PTArrayIndex(pvardesk(PTVertex3DControlVarData(pdata).ArrayIndexVarDescAddr.Instance).data.Addr.Instance)^ then
                                                                                               PTArrayIndex(pvardesk(PTVertex3DControlVarData(pdata).ArrayIndexVarDescAddr.Instance).data.Addr.Instance)^:=cc;
     tv:=PGDBPoint3dArray(ChangedData.PGetDataInEtity).getDataMutable(PTArrayIndex(pvardesk(PTVertex3DControlVarData(pdata).ArrayIndexVarDescAddr.Instance)^.data.Addr.Instance)^);
     if fistrun then
                    begin
                         ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).XVarDescAddr.Instance)^.attrib,0,vda_different);
                         ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).YVarDescAddr.Instance)^.attrib,0,vda_different);
                         ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).ZVarDescAddr.Instance)^.attrib,0,vda_different);

                         PTVertex3DControlVarData(pdata).PGDBDTypeDesc.CopyInstanceTo(@tv^.x,pvardesk(PTVertex3DControlVarData(pdata).XVarDescAddr.Instance)^.data.Addr.Instance);
                         PTVertex3DControlVarData(pdata).StrValueX:=PTVertex3DControlVarData(pdata).PGDBDTypeDesc.GetDecoratedValueAsString(@tv^.x,f);
                         PTVertex3DControlVarData(pdata).PGDBDTypeDesc.CopyInstanceTo(@tv^.y,pvardesk(PTVertex3DControlVarData(pdata).YVarDescAddr.Instance)^.data.Addr.Instance);
                         PTVertex3DControlVarData(pdata).StrValueY:=PTVertex3DControlVarData(pdata).PGDBDTypeDesc.GetDecoratedValueAsString(@tv^.y,f);
                         PTVertex3DControlVarData(pdata).PGDBDTypeDesc.CopyInstanceTo(@tv^.z,pvardesk(PTVertex3DControlVarData(pdata).ZVarDescAddr.Instance)^.data.Addr.Instance);
                         PTVertex3DControlVarData(pdata).StrValueZ:=PTVertex3DControlVarData(pdata).PGDBDTypeDesc.GetDecoratedValueAsString(@tv^.z,f);
                    end
                else
                    begin
                         if PTVertex3DControlVarData(pdata).PGDBDTypeDesc.Compare(@tv^.x,pvardesk(PTVertex3DControlVarData(pdata).XVarDescAddr.Instance).data.Addr.Instance)<>CREqual then
                            ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).XVarDescAddr.Instance).attrib,vda_approximately,0);
                         if PTVertex3DControlVarData(pdata).StrValueX<>PTVertex3DControlVarData(pdata).PGDBDTypeDesc.GetDecoratedValueAsString(@tv^.x,f) then
                            ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).XVarDescAddr.Instance)^.attrib,vda_different,vda_approximately);

                         if PTVertex3DControlVarData(pdata).PGDBDTypeDesc.Compare(@tv^.y,pvardesk(PTVertex3DControlVarData(pdata).YVarDescAddr.Instance)^.data.Addr.Instance)<>CREqual then
                            ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).YVarDescAddr.Instance).attrib,vda_approximately,0);
                         if PTVertex3DControlVarData(pdata).StrValueY<>PTVertex3DControlVarData(pdata).PGDBDTypeDesc.GetDecoratedValueAsString(@tv^.y,f) then
                            ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).YVarDescAddr.Instance).attrib,vda_different,vda_approximately);

                         if PTVertex3DControlVarData(pdata).PGDBDTypeDesc.Compare(@tv^.z,pvardesk(PTVertex3DControlVarData(pdata).ZVarDescAddr.Instance)^.data.Addr.Instance)<>CREqual then
                            ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).ZVarDescAddr.Instance)^.attrib,vda_approximately,0);
                         if PTVertex3DControlVarData(pdata).StrValueZ<>PTVertex3DControlVarData(pdata).PGDBDTypeDesc.GetDecoratedValueAsString(@tv^.z,f) then
                            ProcessVariableAttributes(pvardesk(PTVertex3DControlVarData(pdata).ZVarDescAddr.Instance)^.attrib,vda_different,vda_approximately);
                    end;
end;
procedure PolylineVertex3DControlFromVarEntChangeProc(pu:PTObjectUnit;pdata:PVarDesk;ChangedData:TChangedData;mp:TMultiProperty);
var
   tv:PGDBVertex;
   v:GDBVertex;
   pindex:pTArrayIndex;
   PGDBDTypeDesc:PUserTypeDescriptor;
begin
     if pvardesk(pdata).name=mp.MPName then
                                           mp.MPType.CopyInstanceTo(pvardesk(pdata).data.Addr.Instance,@Vertex3DControl)
     else begin
       PGDBDTypeDesc:=SysUnit.TypeName2PTD('GDBDouble');
       pindex:=pu^.FindValue(mp.MPName).data.Addr.Instance;
       tv:=PGDBObjPolyline(ChangedData.pentity).VertexArrayInWCS.getDataMutable(pindex^);
       v:=tv^;
       if pvardesk(pdata).name=mp.MPName+'x' then
                                                 PGDBDTypeDesc.CopyInstanceTo(pvardesk(pdata).data.Addr.Instance,@v.x);
       if pvardesk(pdata).name=mp.MPName+'y' then
                                                 PGDBDTypeDesc.CopyInstanceTo(pvardesk(pdata).data.Addr.Instance,@v.y);
       if pvardesk(pdata).name=mp.MPName+'z' then
                                                 PGDBDTypeDesc.CopyInstanceTo(pvardesk(pdata).data.Addr.Instance,@v.z);
       tv:=PGDBPoint3dArray(ChangedData.PSetDataInEtity).getDataMutable(pindex^);
       tv^:=v;
     end;
end;

procedure EntityNameEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
var
 ts:GDBAnsiString;
 entinfo:TEntInfoData;
 PVD:pvardesk;
{
общая процедура копирования имени примитива в мультипроперти
pdata - указатель на структуру созданную GetOneVarData
pentity - указатель на примитив
mp - описание мультипроперти
fistrun - флаг установлен при первой итерации (только копировать, не сравнивать)
ecp - указатель на процедуру копирования значения из мультипроперти в примитив, если nil то делаем readonly
}
begin
  PVD:=PTOneVarData(pdata).VDAddr.Instance;
     if @ecp=nil then ProcessVariableAttributes(PVD.attrib,vda_RO,0);
     if fistrun then
                    begin
                      ProcessVariableAttributes(PVD.attrib,0,vda_different);

                      if ObjID2EntInfoData.MyGetValue(PGDBObjEntity(ChangedData.PEntity)^.GetObjType,entinfo) then
                        ts:=entinfo.UserName
                      else
                        ts:=rsNotRegistred;

                      mp.MPType.CopyInstanceTo(@ts,PVD.data.Addr.Instance);
                      PTOneVarData(pdata).StrValue:=mp.MPType.GetDecoratedValueAsString(@ts,f);
                    end
                else
                    begin
                      if (PVD.attrib and vda_different)=0 then begin

                        if ObjID2EntInfoData.MyGetValue(PGDBObjEntity(ChangedData.PEntity)^.GetObjType,entinfo) then
                          ts:=entinfo.UserName
                        else
                          ts:=rsNotRegistred;

                        if PTOneVarData(pdata).StrValue<>ts then
                          ProcessVariableAttributes(PVD.attrib,vda_different,vda_approximately);
                      end;
                    end;
end;
procedure GeneralEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
{
общая процедура копирования значения в мультипроперти
pdata - указатель на структуру созданную GetOneVarData или аналогичной прцедурой
pentity - указатель на примитив или на копируемое поле, если смещение поля было задано при регистрации
mp - описание мультипроперти
fistrun - флаг установлен при первой итерации (только копировать, не сравнивать)
ecp - указатель на процедуру копирования значения из мультипроперти в примитив, если nil то делаем readonly
}
var
  PVD:pvardesk;
begin
  PVD:=PTOneVarData(pdata).VDAddr.Instance;
     if @ecp=nil then ProcessVariableAttributes(PVD.attrib,vda_RO,0);
     if fistrun then
                    begin
                      ProcessVariableAttributes(PVD.attrib,0,vda_different);
                      mp.MPType.CopyInstanceTo(ChangedData.PGetDataInEtity,PVD.data.Addr.Instance);
                      PTOneVarData(pdata).StrValue:=mp.MPType.GetDecoratedValueAsString(ChangedData.PGetDataInEtity,f);
                    end
                else
                    begin
                         if mp.MPType.Compare(ChangedData.PGetDataInEtity,PVD.data.Addr.Instance)<>CREqual then
                            ProcessVariableAttributes(PVD.attrib,vda_approximately,0);
                         if PTOneVarData(pdata).StrValue<>mp.MPType.GetDecoratedValueAsString(ChangedData.PGetDataInEtity,f) then
                            ProcessVariableAttributes(PVD.attrib,vda_different,vda_approximately);
                    end;
end;

procedure GDBDouble2SumEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
{
процедура суммирования GDBDouble значения в мультипроперти
pdata - указатель на структуру созданную GetOneVarData или аналогичной прцедурой
pentity - указатель на примитив или на копируемое поле, если смещение поля было задано при регистрации
mp - описание мультипроперти
fistrun - флаг установлен при первой итерации (только копировать, не суммировать)
ecp - указатель на процедуру копирования значения из мультипроперти в примитив, если nil то делаем readonly
}
var
  PVD:pvardesk;
begin
  PVD:=PTOneVarData(pdata).VDAddr.Instance;
     if @ecp=nil then ProcessVariableAttributes(PVD.attrib,vda_RO,0);
     if fistrun then
                    mp.MPType.CopyInstanceTo(ChangedData.PGetDataInEtity,PVD.data.Addr.Instance)
                else
                    PGDBDouble(PVD.data.Addr.Instance)^:=PGDBDouble(PVD.data.Addr.Instance)^+PGDBDouble(ChangedData.PGetDataInEtity)^;
end;
procedure TArrayIndex2SumEntIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
{
процедура суммирования TArrayIndex значения в мультипроперти
pdata - указатель на структуру созданную GetOneVarData или аналогичной прцедурой
pentity - указатель на примитив или на копируемое поле, если смещение поля было задано при регистрации
mp - описание мультипроперти
fistrun - флаг установлен при первой итерации (только копировать, не суммировать)
ecp - указатель на процедуру копирования значения из мультипроперти в примитив, если nil то делаем readonly
}
var
  PVD:pvardesk;
begin
  PVD:=PTOneVarData(pdata).VDAddr.Instance;
     if @ecp=nil then ProcessVariableAttributes(PVD.attrib,vda_RO,0);
     if fistrun then
                    mp.MPType.CopyInstanceTo(ChangedData.PGetDataInEtity,PVD.data.Addr.Instance)
                else
                    PTArrayIndex(PVD.data.Addr.Instance)^:=PTArrayIndex(PVD.data.Addr.Instance)^+PTArrayIndex(ChangedData.PGetDataInEtity)^;
end;
procedure Blockname2BlockNameCounterIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
var
  ps:pansistring;
  s:string;
begin
  s:=pansistring(ChangedData.PGetDataInEtity)^;
  ps:=pansistring(ChangedData.PGetDataInEtity);
     PTStringCounterData(pdata)^.counter.CountKey(pansistring(ChangedData.PGetDataInEtity)^,1);
     inc(PTStringCounterData(pdata)^.totalcount);
end;
procedure PStyle2PStyleCounterIterateProc(pdata:GDBPointer;ChangedData:TChangedData;mp:TMultiProperty;fistrun:boolean;ecp:TEntChangeProc; const f:TzeUnitsFormat);
var
  p:pointer;
begin
  p:=pointer(ppointer(ChangedData.PGetDataInEtity)^);
     PTPointerCounterData(pdata)^.counter.CountKey(pointer(ppointer(ChangedData.PGetDataInEtity)^),1);
     inc(PTPointerCounterData(pdata)^.totalcount);
end;
function CreateChangedData(pentity:pointer;GSData:TGetSetData):TChangedData;
begin
  result.pentity:=pentity;
  case GSData.Mode of
    GSMRel:begin
             result.PGetDataInEtity:=Pointer(PtrUInt(pentity)+GSData.Value.GetValueOffset);
             result.PSetDataInEtity:=Pointer(PtrUInt(pentity)+GSData.Value.SetValueOffset);
           end;
    GSMAbs:begin
             result.PGetDataInEtity:=Pointer(GSData.Value.GetValueOffset);
             result.PSetDataInEtity:=Pointer(GSData.Value.SetValueOffset);
           end;
  end;
end;


initialization
finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
end.

