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

unit UGDBFontManager;
{$INCLUDE def.inc}
interface
uses zcadstrconsts,shared,zcadsysvars,strproc,ugdbfont,gdbasetypes,SysInfo,memman,sysutils,gdbase, geometry,
     UGDBNamedObjectsArray,classes;
type
{Export+}
  PGDBFontRecord=^GDBFontRecord;
  GDBFontRecord = packed record
    Name: GDBString;
    Pfont: GDBPointer;
  end;
PGDBFontManager=^GDBFontManager;
GDBFontManager={$IFNDEF DELPHI}packed{$ENDIF} object({GDBOpenArrayOfData}GDBNamedObjectsArray)(*OpenArrayOfData=GDBfont*)
                    ttffontfiles:TStringList;
                    shxfontfiles:TStringList;
                    constructor init({$IFDEF DEBUGBUILD}ErrGuid:pansichar;{$ENDIF}m:GDBInteger);

                    function addFonf(FontPathName:GDBString):PGDBfont;
                    procedure EnumerateTTFFontFile(filename:GDBString);
                    procedure EnumerateSHXFontFile(filename:GDBString);
                    //function FindFonf(FontName:GDBString):GDBPointer;
                    {procedure freeelement(p:GDBPointer);virtual;}
              end;
{Export-}
var
   FontManager:GDBFontManager;
implementation
uses ioshx,iottf,log;
procedure GDBFontManager.EnumerateTTFFontFile(filename:GDBString);
begin
     ttffontfiles.Add(filename);
end;
procedure GDBFontManager.EnumerateSHXFontFile(filename:GDBString);
begin
     shxfontfiles.Add(filename);
end;
constructor GDBFontManager.init;
begin
  inherited init({$IFDEF DEBUGBUILD}ErrGuid,{$ENDIF}m,sizeof({GDBFontRecord}GDBfont));
  if assigned(sysvar.PATH.Fonts_Path)then
  begin
    ttffontfiles:=TStringList.create;
    ttffontfiles.Duplicates := dupIgnore;
    FromDirsIterator(sysvar.PATH.Fonts_Path^,'*.ttf','',nil,EnumerateTTFFontFile);
    shxfontfiles:=TStringList.create;
    shxfontfiles.Duplicates := dupIgnore;
    FromDirsIterator(sysvar.PATH.Fonts_Path^,'*.shx','',nil,EnumerateSHXFontFile);
  end;
end;
{procedure GDBFontManager.freeelement;
begin
  PGDBFontRecord(p).Name:='';
  PGDBfont(PGDBFontRecord(p).Pfont)^.fontfile:='';
  PGDBfont(PGDBFontRecord(p).Pfont)^.name:='';
  GDBFreeMem(PGDBFontRecord(p).Pfont);
end;}
(*function GDBFontManager.addFonf(FontName:GDBString):GDBInteger;
var
  fr:GDBFontRecord;
  ft:string;
begin
  if FindFonf(Fontname)=nil then
  begin
  fr.Name:=FontName;
  ft:=uppercase(ExtractFileExt(fontname));
  //if ft='.SHP' then fr.Pfont:=createnewfontfromshp(sysparam.programpath+'fonts/'+FontName);
  if ft='.SHX' then fr.Pfont:=createnewfontfromshx(sysparam.programpath+'fonts/'+FontName);
  add(@fr);
  GDBPointer(fr.Name):=nil;
  end;
end;*)
function GDBFontManager.addFonf(FontPathName:GDBString):PGDBfont;
var
  p:PGDBfont;
  FontName,FontExt:GDBString;
  FontLoaded:GDBBoolean;
      //ir:itrec;
begin
     result:=nil;
     if FontPathName='' then exit;
     FontExt:=uppercase(ExtractFileExt(FontPathName));
     FontName:=ExtractFileName(FontPathName);
          if FontName='_mipgost.shx' then
                                    fontname:=FontName;
     case AddItem(FontName,pointer(p)) of
             IsFounded:
                       begin
                       end;
             IsCreated:
                       begin
                            shared.HistoryOutStr(sysutils.format(rsLoadingFontFile,[FontPathName]));
                            programlog.logoutstr('Loading font '+FontPathName,lp_IncPos);
                            if FontExt='.SHX' then
                                                  FontLoaded:=createnewfontfromshx(FontPathName,p)
                       else if FontExt='.TTF' then
                                                  FontLoaded:=createnewfontfromttf(FontPathName,p);
                            if FontLoaded then
                            begin
                                 programlog.logoutstr('OK',lp_OldPos)
                            end
                            else
                            begin
                                 shared.ShowError(sysutils.format('Font file "%S" unknown format',[FontPathName]));
                                 //shared.LogError(sysutils.format(fontnotfoundandreplace,[Tria_AnsiToUtf8(stylename),FontFile]));
                                 dec(self.Count);
                                 //p^.Name:='ERROR ON LOAD';
                                 p:=nil;
                            end;
                            programlog.logoutstr('done..',lp_DecPos);
                            //p^.init(FontPathName,Color,LW,oo,ll,pp);
                       end;
             IsError:
                       begin
                       end;
     end;
     result:=p;
end;
{function GDBFontManager.FindFonf;
var
  pfr:pGDBFontRecord;
  i:GDBInteger;
begin
  result:=nil;
  if count=0 then exit;
  pfr:=parray;
  for i:=0 to count-1 do
  begin
       if pfr^.Name=fontname then begin
                                       result:=pfr^.Pfont;
                                       exit;
                                  end;
       inc(pfr);
  end;
end;}

{function GDBLayerArray.CalcCopactMemSize2;
var i:GDBInteger;
    tlp:PGDBLayerProp;
begin
     result:=0;
     objcount:=count;
     if count=0 then exit;
     result:=result;
     tlp:=parray;
     for i:=0 to count-1 do
     begin
          result:=result+sizeof(GDBByte)+sizeof(GDBSmallint)+sizeof(GDBWord)+length(tlp^.name);
          inc(tlp);
     end;
end;
function GDBLayerArray.SaveToCompactMemSize2;
var i:GDBInteger;
    tlp:PGDBLayerProp;
begin
     result:=0;
     if count=0 then exit;
     tlp:=parray;
     for i:=0 to count-1 do
     begin
          PGDBByte(pmem)^:=tlp^.color;
          inc(PGDBByte(pmem));
          PGDBSmallint(pmem)^:=tlp^.lineweight;
          inc(PGDBSmallint(pmem));
          PGDBWord(pmem)^:=length(tlp^.name);
          inc(PGDBWord(pmem));
          Move(GDBPointer(tlp.name)^, pmem^,length(tlp.name));
          inc(PGDBByte(pmem),length(tlp.name));
          inc(tlp);
     end;
end;
function GDBLayerArray.LoadCompactMemSize2;
begin
     {inherited LoadCompactMemSize(pmem);
     Coord:=PGDBLineProp(pmem)^;
     inc(PGDBLineProp(pmem));
     PProjPoint:=nil;
     format;}
//end;
initialization
  {$IFDEF DEBUGINITSECTION}LogOut('UGDBFontManager.initialization');{$ENDIF}
  FontManager.init({$IFDEF DEBUGBUILD}'{9D0E081C-796F-4EB1-98A9-8B6EA9BD8640}',{$ENDIF}100);
finalization
 FontManager.FreeAndDone;
end.
