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

unit log;
{$INCLUDE def.inc}
interface
uses gdbasetypes,sysinfo,zcadinterface;
const {$IFDEF DELPHI}filelog='log/zcad_delphi.log';{$ENDIF}
      {$IFDEF FPC}
                  {$IFDEF LINUX}filelog='log/zcad_linux.log';{$ENDIF}
                  {$IFDEF WINDOWS}filelog='log/zcad_windows.log';{$ENDIF}
      {$ENDIF}
      lp_IncPos=1;
      lp_DecPos=-lp_IncPos;
      lp_OldPos=0;

      tsc2ms=2000;
type
PTMyTimeStamp=^TMyTimeStamp;
TMyTimeStamp=record
                   time:TDateTime;
                   rdtsc:int64;
end;

//PTDateTime=^TDateTime;
{EXPORT+}
ptlog=^tlog;
tlog=object
           LogFileName:GDBString;
           FileHandle:cardinal;
           Indent:GDBInteger;
           constructor init(fn:GDBString);
           destructor done;
           procedure ProcessStr(str:GDBString;IncIndent:GDBInteger;todisk:boolean);virtual;
           procedure LogOutStr(str:GDBString;IncIndent:GDBInteger);virtual;
           procedure LogOutStrFast(str:GDBString;IncIndent:GDBInteger);virtual;
           procedure WriteToLog(s:GDBString;todisk:boolean;t,dt:TDateTime;tick,dtick:int64;IncIndent:GDBInteger);virtual;
           procedure OpenLog;
           procedure CloseLog;
           procedure CreateLog;
    end;
{EXPORT-}
function getprogramlog:GDBPointer;export;
//procedure startup(s:GDBString);
procedure LogOut(s:GDBString);
var programlog:tlog;
implementation
uses
    UGDBOpenArrayOfByte,UGDBOpenArrayOfData,strutils,sysutils{$IFNDEF DELPHI},fileutil{$ENDIF};
var
    PerfomaneBuf:GDBOpenArrayOfByte;
    TimeBuf:GDBOpenArrayOfData;
procedure LogOut(s:GDBString);
var
   FileHandle:cardinal;
   logname:string;
begin
     if assigned(SplashTextOut) then
                                   SplashTextOut(s,true);
     logname:={$IFNDEF DELPHI}SysToUTF8{$ENDIF}(ExtractFilePath(paramstr(0)))+filelog+'hard';
     FileHandle:=0;
     if not fileexists({$IFNDEF DELPHI}UTF8ToSys{$ENDIF}(logname)) then
                                   FileHandle:=FileCreate({$IFNDEF DELPHI}UTF8ToSys{$ENDIF}(logname))
                                else
                                    FileHandle := FileOpen({$IFNDEF DELPHI}UTF8ToSys{$ENDIF}(logname), fmOpenWrite);
     FileSeek(FileHandle, 0, 2);

        s:=s+#13#10;
        FileWrite(FileHandle,s[1],length(s));

     fileclose(FileHandle);
     FileHandle:=0;
end;
function getprogramlog:GDBPointer;
begin
     result:=@programlog;
end;
function MyTimeToStr(MyTime:TDateTime):string;
var
    Hour,Minute,Second,MilliSecond:word;
begin
     decodetime(MyTime,Hour,Minute,Second,MilliSecond);
     if hour<>0 then
                    result:=Format('%.2d:', [hour]);
                            // inttostr(hour)+':';
     if Minute<>0 then
                    result:=result+Format('%.2d:', [minute]);
                                   //inttostr(minute,2)+':';
     if Second<>0 then
                    result:=result+Format('%.2d.', [Second]);
                                  //inttostr(Second,2)+'.';
     //if MilliSecond<>0 then
                    result:=result+Format('%.3d', [MilliSecond]);
                                   //inttostr(MilliSecond,3);

end;

procedure tlog.WriteToLog;
var ts:gdbstring;
begin
  ts:=TimeToStr(Time)+{'|'+}DupeString(' ',Indent*2);
  if todisk then ts :='!!!! '+ts +s
            else ts :=IntToHex(PerfomaneBuf.Count,4)+' '+ts +s;
  ts:=ts+DupeString('-',80-length(ts));
  //decodetime(t,Hour,Minute,Second,MilliSecond);
  ts := ts +' t:=' + {inttostr(round(t*10e7))}MyTimeToStr(t) + ', dt:=' + {inttostr(round(dt*10e7))}MyTimeToStr(dt) {+#13+#10};
  ts := ts +' tick:=' + inttostr(tick div tsc2ms) + ', dtick:=' + inttostr(dtick div tsc2ms)+#13+#10;
  if (Indent=1)and(IncIndent<0) then ts:=ts+#13+#10;
  PerfomaneBuf.TXTAddGDBString(ts);
  //FileWrite(FileHandle,ts[1],length(ts));
  if todisk then
  begin
        OpenLog;
        FileWrite(FileHandle,PerfomaneBuf.parray^,PerfomaneBuf.count);
        PerfomaneBuf.Clear;
        CloseLog;
  end;
end;
procedure tlog.OpenLog;
begin
  FileHandle := FileOpen({$IFNDEF DELPHI}UTF8ToSys{$ENDIF}(logfilename), fmOpenWrite);
  FileSeek(FileHandle, 0, 2);
end;

procedure tlog.CloseLog;
begin
  fileclose(FileHandle);
  FileHandle:=0;
end;
procedure tlog.CreateLog;
begin
  FileHandle:=FileCreate({$IFNDEF DELPHI}UTF8ToSys{$ENDIF}(logfilename){,fmOpenWrite});
  CloseLog;
end;
{procedure tlog.logout;
begin
     logoutstr(str,IncIndent);
end;}
(*function RDTSC: comp;
var
  TimeStamp: record
    case byte of
      1: (Whole: comp);
      2: (Lo, Hi: Longint);
  end;
begin
  asm
    db $0F; db $31;
  {$ifdef Cpu386}
    mov [TimeStamp.Lo], eax
    mov [TimeStamp.Hi], edx
  {$else}
    db D32
    mov word ptr TimeStamp.Lo, AX   dfg
    db D32
    mov word ptr TimeStamp.Hi, DX
  {$endif}
  end;
  Result := TimeStamp.Whole;
end;*)
function mynow:TMyTimeStamp;
var a:int64;
begin
     result.time:=now();
     asm
        rdtsc
        mov dword ptr [a],eax
        mov dword ptr [a+4],edx
     end;
     result.rdtsc:=a;
end;

procedure tlog.processstr;
var
   CurrentTime:TMyTimeStamp;
   DeltaTime,FromStartTime:TDateTime;
   tick,dtick:int64;

begin
     CurrentTime:=mynow();

     if timebuf.Count>0 then
                            begin
                                 FromStartTime:=CurrentTime.time-PTMyTimeStamp(TimeBuf.getelement(0))^.time;
                                 DeltaTime:=CurrentTime.time-PTMyTimeStamp(TimeBuf.getelement(timebuf.Count-1))^.time;
                                 tick:=CurrentTime.rdtsc-PTMyTimeStamp(TimeBuf.getelement(0))^.rdtsc;
                                 dtick:=CurrentTime.rdtsc-PTMyTimeStamp(TimeBuf.getelement(timebuf.Count-1))^.rdtsc;
                            end
                        else
                            begin
                                  FromStartTime:=0;
                                  DeltaTime:=0;
                                  tick:=0;
                                  dtick:=0;
                            end;
     if IncIndent=0 then
                      begin
                           WriteToLog(str,todisk,FromStartTime,DeltaTime,tick,dtick,IncIndent);
                      end
else if IncIndent>0 then
                      begin
                           WriteToLog(str,todisk,FromStartTime,DeltaTime,tick,dtick,IncIndent);
                           inc(Indent,IncIndent);

                           timebuf.Add(@CurrentTime);
                      end
                  else
                      begin
                           inc(Indent,IncIndent);
                           WriteToLog(str,todisk,FromStartTime,DeltaTime,tick,dtick,IncIndent);

                           dec(timebuf.Count);
                      end;
end;
procedure tlog.logoutstr;
begin
     if (Indent=0) then
                    if assigned(SplashTextOut) then
                                                  SplashTextOut(str,false);
     processstr(str,IncIndent,true);
end;
procedure tlog.LogOutStrFast;
begin
     //if (str='TOGLWnd.Pre_MouseMove----{end}')and(Indent=3) then
     //               indent:=3;
     if PerfomaneBuf.Count<1024 then
                                    processstr(str,IncIndent,false)
                                else
                                    processstr(str,IncIndent,true);
end;
constructor tlog.init;
var
   CurrentTime:TMyTimeStamp;
begin
     CurrentTime:=mynow();
     logfilename:=fn;
     PerfomaneBuf.init({$IFDEF DEBUGBUILD}'{39063C66-9D18-4707-8AD3-97DFBCB23185}',{$ENDIF}5*1024);
     TimeBuf.init({$IFDEF DEBUGBUILD}'{6EE1BC6B-1177-40B0-B4A5-793D66BF8BC8}',{$ENDIF}50,sizeof({TDateTime}TMyTimeStamp));
     Indent:=1;
     CreateLog;
     WriteToLog('------------------------Log started------------------------',false,CurrentTime.time,0,CurrentTime.rdtsc,0,0);
     timebuf.Add(@CurrentTime);
end;
destructor tlog.done;
var
   CurrentTime:TMyTimeStamp;
begin
     CurrentTime:=mynow();
     WriteToLog('-------------------------Log ended-------------------------',true,CurrentTime.time,0,CurrentTime.rdtsc,0,0);
     PerfomaneBuf.done;
     TimeBuf.done;
end;
initialization
begin
    getsysinfo;
    {$IFDEF DEBUGINITSECTION}LogOut('log.initialization');{$ENDIF}
    programlog.init(sysparam.programpath+filelog);
end;
end.

