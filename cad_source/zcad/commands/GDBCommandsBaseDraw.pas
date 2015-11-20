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

unit GDBCommandsBaseDraw;
{$INCLUDE def.inc}

interface
uses
  zcadstrconsts,GL,printers,graphics,fileutil,Clipbrd,LCLType,classes,
  commandlinedef,
  gdbasetypes,commandline,GDBCommandsBase,
  plugins,
  commanddefinternal,
  gdbase,
  UGDBDescriptor,
  GDBManager,
  sysutils,
  varmandef,
  oglwindowdef,
  iodxf,
  geometry,
  memman,
  gdbobjectsconstdef,
  shared,uzclog;
implementation
uses UBaseTypeDescriptor,Varman,TypeDescriptors;
var
   c1,c2:integer;
   distlen:gdbdouble;
   oldpoint,point:gdbvertex;
function Line_com_CommandStart(operands:TCommandOperands):TCommandResult;
begin
  GDB.GetCurrentDWG.wa.SetMouseMode((MGet3DPoint) or (MMoveCamera) or (MRotateCamera));
  if operands='' then
                     historyoutstr(rscmPoint)
                 else
                     historyout(operands);
  result:=cmd_ok;
end;
function Line_com_BeforeClick(wc: GDBvertex; mc: GDBvertex2DI; button: GDBByte;osp:pos_record;mclick:GDBInteger): GDBInteger;
begin
  point:=wc;
  if (button and MZW_LBUTTON)<>0 then
  begin
       commandmanager.PushValue('','GDBVertex',@wc);
       commandmanager.executecommandend;
       result:=1;
  end
end;
function Rect_com_CommandStart(operands:TCommandOperands):TCommandResult;
begin
     c1:=commandmanager.GetValueHeap;
     c2:=-1;
     commandmanager.executecommandsilent('Get3DPoint(Первая точка:)',gdb.GetCurrentDWG,gdb.GetCurrentOGLWParam);
     result:=cmd_ok;
end;
procedure Rect_com_CommandCont;
begin
     if c2=-1 then
                  c2:=commandmanager.GetValueHeap
              else
                  begin
                       commandmanager.executecommandend;
                       exit;
                  end;
     if c1=c2 then
                  commandmanager.executecommandend
              else
                  commandmanager.executecommandsilent('Get3DPoint_DrawRect(Вторая точка:)',gdb.GetCurrentDWG,gdb.GetCurrentOGLWParam);
end;
function DrawRect(mclick:GDBInteger):GDBInteger;
var
   vd:vardesk;
   p1,p2,p4:gdbvertex;
   matrixs:tmatrixs;
begin
     vd:=commandmanager.GetValue;
     p1:=pgdbvertex(vd.data.Instance)^;

     p2:=createvertex(p1.x,point.y,p1.z);
     p4:=createvertex(point.x,p1.y,point.z);

     matrixs.pmodelMatrix:=@gdb.GetCurrentDWG.GetPcamera.modelMatrix;
     matrixs.pprojMatrix:=@gdb.GetCurrentDWG.GetPcamera.projMatrix;
     matrixs.pviewport:=@gdb.GetCurrentDWG.GetPcamera.viewport;

     gdb.GetCurrentDWG.wa.Drawer.DrawLine3DInModelSpace(p1,p2,matrixs);
     gdb.GetCurrentDWG.wa.Drawer.DrawLine3DInModelSpace(p2,point,matrixs);
     gdb.GetCurrentDWG.wa.Drawer.DrawLine3DInModelSpace(point,p4,matrixs);
     gdb.GetCurrentDWG.wa.Drawer.DrawLine3DInModelSpace(p4,p1,matrixs);
     result:=cmd_ok;
end;

function Dist_com_CommandStart(operands:TCommandOperands):TCommandResult;
begin
     c1:=commandmanager.GetValueHeap;
     c2:=-1;
     commandmanager.executecommandsilent('Get3DPoint(Первая точка:)',gdb.GetCurrentDWG,gdb.GetCurrentOGLWParam);
     distlen:=0;
     result:=cmd_ok;
end;
procedure Dist_com_CommandCont;
var
   cs:integer;
   vd:vardesk;
   len:gdbdouble;
begin
     cs:=commandmanager.GetValueHeap;
     if cs=c1 then
     begin
          commandmanager.executecommandend;
          exit;
     end;
     vd:=commandmanager.PopValue;
     point:=pgdbvertex(vd.data.Instance)^;
     //c1:=cs;
     c1:=commandmanager.GetValueHeap;
     if c2<>-1 then
                   begin
                        len:=geometry.Vertexlength(point,oldpoint);
                        distlen:=distlen+len;
                        HistoryOutStr('Длина отрезка: '+floattostr(len)+' Суммарная длина: '+floattostr(distlen))
                   end;
     c2:=cs;
     oldpoint:=point;
     commandmanager.executecommandsilent('Get3DPoint(Следующая точка:)',gdb.GetCurrentDWG,gdb.GetCurrentOGLWParam);
end;
procedure startup;
begin
  CreateCommandRTEdObjectPlugin(@Line_com_CommandStart,nil,nil,nil,@Line_com_BeforeClick,nil,nil,nil,'Get3DPoint',0,0).overlay:=true;
  CreateCommandRTEdObjectPlugin(@Line_com_CommandStart,nil,nil,nil,@Line_com_BeforeClick,nil,@DrawRect,nil,'Get3DPoint_DrawRect',0,0).overlay:=true;
  CreateCommandRTEdObjectPlugin(@Rect_com_CommandStart,nil,nil,nil,nil,nil,nil,@Rect_com_CommandCont,'GetRect',0,0).overlay:=true;

  CreateCommandRTEdObjectPlugin(@Dist_com_CommandStart,nil,nil,nil,nil,nil,nil,@Dist_com_CommandCont,'Dist',0,0){.overlay:=true};
end;
procedure Finalize;
begin
end;
initialization
     startup;
finalization
     finalize;
end.
