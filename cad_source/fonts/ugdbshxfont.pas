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

unit ugdbshxfont;
{$INCLUDE def.inc}
interface
uses ugdbbasefont,memman,UGDBOpenArrayOfByte,gdbasetypes,sysutils,gdbase,
     geometry;
type
{EXPORT+}
PSHXFont=^SHXFont;
SHXFont={$IFNDEF DELPHI}packed{$ENDIF} object(BASEFont)
              //compiledsize:GDBInteger;
              h,u:GDBByte;
              //SHXdata:GDBOpenArrayOfByte;
              constructor init;
              destructor done;virtual;
        end;
{EXPORT-}
implementation
uses log;
constructor SHXFont.init;
begin
     inherited;
     u:=1;
     h:=1;
     //SHXdata.init({$IFDEF DEBUGBUILD}'{700B6312-B792-4FFE-B514-2F2CD4B47CC2}',{$ENDIF}1024);
end;
destructor SHXFont.done;
begin
     inherited;
     //SHXdata.done;
end;
initialization
  {$IFDEF DEBUGINITSECTION}LogOut('UGDBSHXFont.initialization');{$ENDIF}
finalization
end.
