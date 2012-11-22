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

unit GDBLWPolyLine;
{$INCLUDE def.inc}

interface
uses GDBCamera,UGDBOpenArrayOfPObjects,oglwindowdef,GDBCurve,UGDBVectorSnapArray,geometry,UGDBLayerArray,GDBEntity,memman,gdbasetypes,UGDBPoint3DArray,UGDBOpenArray,UGDBPolyLine2DArray,UGDBOpenArrayOfByte,varman,varmandef,
gl,ugdbltypearray,
GDBase,GDBWithLocalCS,gdbobjectsconstdef,math,dxflow,sysutils,UGDBLineWidthArray,OGLSpecFunc;
type
//----------------snaparray:GDBVectorSnapArray;(*hidden_in_objinsp*)
{Export+}
PGDBObjLWPolyline=^GDBObjLWpolyline;
GDBObjLWPolyline=object(GDBObjWithLocalCS)
                 Closed:GDBBoolean;(*saved_to_shd*)
                 Vertex2D_in_OCS_Array:GDBpolyline2DArray;(*saved_to_shd*)
                 Vertex3D_in_WCS_Array:GDBPoint3dArray;
                 Width2D_in_OCS_Array:GDBLineWidthArray;(*saved_to_shd*)
                 Width3D_in_WCS_Array:GDBOpenArray;
                 PProjPoint:PGDBpolyline2DArray;(*hidden_in_objinsp*)
                 Square:GDBdouble;(*'Oriented area'*)
                 constructor init(own:GDBPointer;layeraddres:PGDBLayerProp;LW:GDBSmallint;c:GDBBoolean);
                 constructor initnul;
                 procedure LoadFromDXF(var f: GDBOpenArrayOfByte;ptu:PTUnit;var LayerArray:GDBLayerArray;var LTArray:GDBLtypeArray);virtual;

                 procedure SaveToDXF(var handle:TDWGHandle;var outhandle:{GDBInteger}GDBOpenArrayOfByte);virtual;
                 procedure DrawGeometry(lw:GDBInteger;var DC:TDrawContext{infrustumactualy:TActulity;subrender:GDBInteger});virtual;
                 procedure Format;virtual;
                 function CalcSquare:GDBDouble;virtual;
                 function isPointInside(point:GDBVertex):GDBBoolean;virtual;
                 procedure createpoint;virtual;
                 procedure CalcWidthSegment;virtual;
                 destructor done;virtual;
                 function GetObjTypeName:GDBString;virtual;
                 function Clone(own:GDBPointer):PGDBObjEntity;virtual;
                 procedure RenderFeedback(pcount:TActulity;var camera:GDBObjCamera; ProjectProc:GDBProjectProc);virtual;
                 procedure addcontrolpoints(tdesc:GDBPointer);virtual;
                 procedure remaponecontrolpoint(pdesc:pcontrolpointdesc);virtual;
                 procedure rtmodifyonepoint(const rtmod:TRTModifyData);virtual;
                 procedure rtsave(refp:GDBPointer);virtual;
                 procedure getoutbound;virtual;
                 function CalcTrueInFrustum(frustum:ClipArray;visibleactualy:TActulity):TInRect;virtual;
                 //function InRect:TInRect;virtual;
                 function onmouse(var popa:GDBOpenArrayOfPObjects;const MF:ClipArray):GDBBoolean;virtual;
                 function onpoint(var objects:GDBOpenArrayOfPObjects;const point:GDBVertex):GDBBoolean;virtual;
                 function getsnap(var osp:os_record; var pdata:GDBPointer; const param:OGLWndtype; ProjectProc:GDBProjectProc):GDBBoolean;virtual;
                 procedure startsnap(out osp:os_record; out pdata:GDBPointer);virtual;
                 procedure endsnap(out osp:os_record; var pdata:GDBPointer);virtual;
                 procedure AddOnTrackAxis(var posr:os_record;const processaxis:taddotrac);virtual;
                 procedure transform(const t_matrix:DMatrix4D);virtual;
                 procedure TransformAt(p:PGDBObjEntity;t_matrix:PDMatrix4D);virtual;
                 function GetTangentInPoint(point:GDBVertex):GDBVertex;virtual;


           end;
{Export-}
implementation
uses UGDBSelectedObjArray,log;
function GDBObjLWpolyline.GetTangentInPoint(point:GDBVertex):GDBVertex;
var //tv:gdbvertex;
    ptv,ppredtv:pgdbvertex;
    ir:itrec;
    found:integer;

begin
     if not closed then
                   begin
                        ppredtv:=Vertex3D_in_WCS_Array.beginiterate(ir);
                        ptv:=Vertex3D_in_WCS_Array.iterate(ir);
                   end
                else
                    begin
                           if Vertex3D_in_WCS_Array.Count<3 then
                                                        exit;
                           ptv:=Vertex3D_in_WCS_Array.beginiterate(ir);
                           ppredtv:=Vertex3D_in_WCS_Array.getelement(Vertex3D_in_WCS_Array.Count-1);
                    end;
  found:=0;
  if (ptv<>nil)and(ppredtv<>nil) then
  repeat
        if (abs(ptv^.x-point.x)<eps)
       and (abs(ptv^.y-point.y)<eps)
       and (abs(ptv^.z-point.z)<eps)
                                             then
                                                 begin
                                                      found:=2;
                                                 end
   else if (found=0)and({distance2piece}SQRdist_Point_to_Segment(point,ppredtv^,ptv^)<bigeps) then begin
                                                          found:=1;
                                                     end;

        if found>0 then
                       begin
                            result:=vertexsub(ptv^,ppredtv^);
                            result:=geometry.NormalizeVertex(result);
                            exit;
                            //processaxis(posr,result);
                            //result:=geometry.CrossVertex(tv,zwcs);
                            //processaxis(posr,result);
                            dec(found);
                       end;

        ppredtv:=ptv;
        ptv:=Vertex3D_in_WCS_Array.iterate(ir);
  until ptv=nil;
end;

{function GDBObjLWpolyline.InRect;
var i:GDBInteger;
    ptpv:PGDBPolyVertex2D;
begin
     if pprojoutbound<>nil then if self.pprojoutbound^.inrect=IRFully then
     begin
          result:=IRFully;
          exit;
     end;
     //if POGLWnd^.seldesc.MouseFrameInverse then
     if PProjPoint.inrect=IRPartially then
     begin
          result:=IRPartially;
          exit;
     end;
     result:=IREmpty;
end;}
procedure GDBObjLWpolyline.TransformAt;
begin
    inherited;
    Vertex2D_in_OCS_Array.clear;
    pGDBObjLWpolyline(p)^.Vertex2D_in_OCS_Array.copyto(@Vertex2D_in_OCS_Array);
    Vertex2D_in_OCS_Array.transform(t_matrix^);
end;

procedure GDBObjLWpolyline.transform;
var tv,tv2:GDBVertex4D;
begin
 inherited;
 Vertex2D_in_OCS_Array.transform(t_matrix);
end;
procedure GDBObjLWpolyline.AddOnTrackAxis(var posr:os_record;const processaxis:taddotrac);
begin
  GDBPoint3dArrayAddOnTrackAxis(Vertex3D_in_WCS_Array,posr,processaxis,closed);
end;
procedure GDBObjLWpolyline.startsnap(out osp:os_record; out pdata:GDBPointer);
begin
     inherited;
     gdbgetmem({$IFDEF DEBUGBUILD}'{C37BA022-4629-4E16-BEB6-E8AAB9AC6986}',{$ENDIF}pdata,sizeof(GDBVectorSnapArray));
     PGDBVectorSnapArray(pdata).init({$IFDEF DEBUGBUILD}'{C37BA022-4629-4E16-BEB6-E8AAB9AC6986}',{$ENDIF}Vertex3D_in_WCS_Array.Max);
     BuildSnapArray(Vertex3D_in_WCS_Array,PGDBVectorSnapArray(pdata)^,closed);
end;

procedure GDBObjLWpolyline.endsnap(out osp:os_record; var pdata:GDBPointer);
begin
     if pdata<>nil then
                       begin
                            PGDBVectorSnapArray(pdata)^.{FreeAnd}Done;
                            gdbfreemem(pdata);
                       end;
     inherited;
end;

function GDBObjLWpolyline.getsnap;
begin
     result:=GDBPoint3dArraygetsnap(Vertex3D_in_WCS_Array,PProjPoint,{snaparray}PGDBVectorSnapArray(pdata)^,osp,closed,param,ProjectProc);
end;
function GDBObjLWpolyline.onpoint(var objects:GDBOpenArrayOfPObjects;const point:GDBVertex):GDBBoolean;
begin
     if Vertex3D_in_WCS_Array.onpoint(point,closed) then
                                                begin
                                                     result:=true;
                                                     objects.AddRef(self);
                                                end
                                            else
                                                result:=false;
end;

function GDBObjLWpolyline.onmouse;
var
   ie,i:gdbinteger;
   q3d:PGDBQuad3d;
   p3d,p3dold:PGDBVertex;
   subresult:TINRect;
begin

    result:=false;
  if closed then
                ie:=Width3D_in_WCS_Array.count
            else
                ie:=Width3D_in_WCS_Array.count - 1;


  q3d:=Width3D_in_WCS_Array.parray;
  p3d:=Vertex3D_in_WCS_Array.PArray;
  p3dold:=p3d;
  inc(p3d);
  for i := 1 to ie do
  begin
    begin
            if i=Vertex3D_in_WCS_Array.count then
                                           p3d:=Vertex3D_in_WCS_Array.PArray;

      subresult:=CalcOutBound4VInFrustum(q3d^,mf);
          if subresult=IRFully then
                                  begin
                                       result:=true;
                                       exit;
                                    end
     else if subresult=IRPartially then
                                        begin
                                             if geometry.CalcTrueInFrustum (q3d^[0],q3d^[1],mf)<>irempty then
                                                                                          begin
                                                                                               result:=true;
                                                                                               exit;
                                                                                          end;
                                             if geometry.CalcTrueInFrustum (q3d^[1],q3d^[2],mf)<>irempty then
                                                                                          begin
                                                                                               result:=true;
                                                                                               exit;
                                                                                          end;
                                             if geometry.CalcTrueInFrustum (q3d^[2],q3d^[3],mf)<>irempty then
                                                                                          begin
                                                                                               result:=true;
                                                                                               exit;
                                                                                          end;
                                             if geometry.CalcTrueInFrustum (q3d^[3],q3d^[0],mf)<>irempty then
                                                                                          begin
                                                                                               result:=true;
                                                                                               exit;
                                                                                          end;
                                        end;
          if geometry.CalcTrueInFrustum (p3d^,p3dold^,mf)<>irempty then
                                                       begin
                                                            result:=true;
                                                            exit;
                                                       end;

      inc(q3d);
      inc(p3dold);
      inc(p3d);
    end;
 end;
    {subresult:=CalcOutBound4VInFrustum(PInWCS,mf);
    if subresult<>IRPartially then
                               if subresult=irempty then
                                                        exit
                                                    else
                                                        begin
                                                             result:=true;
                                                             exit;
                                                        end;
    result:=true;

  if VertexArrayInWCS.count<2 then
                                  begin
                                       result:=false;
                                       exit;
                                  end;
   result:=VertexArrayInWCS.onmouse(mf);}
end;
function GDBObjLWpolyline.CalcTrueInFrustum;
var
pv1,pv2:pgdbvertex;
begin
      result:=Vertex3D_in_WCS_Array.CalcTrueInFrustum(frustum);
      if (result=IREmpty)and(Vertex3D_in_WCS_Array.count>3) then
                                          begin
                                               pv1:=Vertex3D_in_WCS_Array.getelement(0);
                                               pv2:=Vertex3D_in_WCS_Array.getelement(Vertex3D_in_WCS_Array.Count-1);
                                               result:=geometry.CalcTrueInFrustum(pv1^,pv2^,frustum);
                                          end;
end;
procedure GDBObjLWpolyline.getoutbound;
var //tv,tv2:GDBVertex4D;
    t,b,l,r,n,f:GDBDouble;
    ptv:pgdbvertex;
    ir:itrec;
begin
  l:=Infinity;
  b:=Infinity;
  n:=Infinity;
  r:=NegInfinity;
  t:=NegInfinity;
  f:=NegInfinity;
  ptv:=Vertex3D_in_WCS_Array.beginiterate(ir);
  if ptv<>nil then
  begin
  repeat
        if ptv.x<l then
                 l:=ptv.x;
        if ptv.x>r then
                 r:=ptv.x;
        if ptv.y<b then
                 b:=ptv.y;
        if ptv.y>t then
                 t:=ptv.y;
        if ptv.z<n then
                 n:=ptv.z;
        if ptv.z>f then
                 f:=ptv.z;
        ptv:=Vertex3D_in_WCS_Array.iterate(ir);
  until ptv=nil;
  vp.BoundingBox.LBN:=CreateVertex(l,B,n);
  vp.BoundingBox.RTF:=CreateVertex(r,T,f);

  end
              else
  begin
  vp.BoundingBox.LBN:=CreateVertex(-1,-1,-1);
  vp.BoundingBox.RTF:=CreateVertex(1,1,1);
  end;
end;
procedure GDBObjLWpolyline.rtsave;
var p,pold:pgdbvertex2d;
    i:GDBInteger;
begin
  inherited;
  p:=Vertex2D_in_OCS_Array.PArray;
  pold:=PGDBObjLWPolyline(refp)^.Vertex2D_in_OCS_Array.PArray;
  for i:=0 to Vertex2D_in_OCS_Array.Count-1 do
  begin
      pold^:=p^;
      inc(pold);
      inc(p);
  end;
  //PGDBObjLWPolyline(refp)^.format;
end;
procedure GDBObjLWpolyline.rtmodifyonepoint(const rtmod:TRTModifyData);
var vertexnumber:GDBInteger;
    tv,wwc:gdbvertex;

    M: DMatrix4D;
begin
  vertexnumber:=abs(rtmod.point.pointtype-os_polymin);

  m:=self.ObjMatrix;

  {m[3][0]:=0;
  m[3][1]:=0;
  m[3][2]:=0;}

  geometry.MatrixInvert(m);


  tv:=rtmod.dist;
  wwc:=rtmod.point.worldcoord;

  wwc:=VertexAdd(wwc,tv);

  //tv:=geometry.VectorTransform3D(tv,m);
  wwc:=geometry.VectorTransform3D(wwc,m);


  PGDBArrayVertex2D(Vertex2D_in_OCS_Array.parray)^[vertexnumber].x:=wwc.x{VertexAdd(wwc,tv)};
  PGDBArrayVertex2D(Vertex2D_in_OCS_Array.parray)^[vertexnumber].y:=wwc.y;
  //PInOCS[vertexnumber].z:=0;
     {vertexnumber:=abs(rtmod.point.pointtype-os_polymin);
     tv:=VertexAdd(rtmod.point.worldcoord, rtmod.dist);
     geometry.VectorTransform3D(tv,self.ObjMatrix);
     PGDBArrayVertex2D(Vertex2D_in_OCS_Array.parray)^[vertexnumber].x:=tv.x;
     PGDBArrayVertex2D(Vertex2D_in_OCS_Array.parray)^[vertexnumber].y:=tv.y;}
end;
procedure GDBObjLWpolyline.remaponecontrolpoint(pdesc:pcontrolpointdesc);
var vertexnumber:GDBInteger;
begin
     vertexnumber:=abs(pdesc^.pointtype-os_polymin);
     pdesc.worldcoord:=PGDBArrayVertex(Vertex3D_in_WCS_Array.parray)^[vertexnumber];
     pdesc.dispcoord.x:=round(PGDBArrayVertex2D(PProjPoint.parray)^[vertexnumber].x);
     pdesc.dispcoord.y:=round(PGDBArrayVertex2D(PProjPoint.parray)^[vertexnumber].y);
end;
procedure GDBObjLWpolyline.AddControlpoints;
var pdesc:controlpointdesc;
    i:GDBInteger;
    pv2d:pGDBvertex2d;
    pv:pGDBvertex;
begin
          //renderfeedback(gdb.GetCurrentDWG.pcamera^.POSCOUNT,gdb.GetCurrentDWG.pcamera^,nil);
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.init({$IFDEF DEBUGBUILD}'{48F91543-AAA8-4CF7-A038-D3DDC248BE3E}',{$ENDIF}{pprojpoint}Vertex3D_in_WCS_Array.count);
          //pv2d:=pprojpoint^.parray;
          pv:=Vertex3D_in_WCS_Array.parray;
          pdesc.selected:=false;
          pdesc.pobject:=nil;

          for i:=0 to {pprojpoint}Vertex3D_in_WCS_Array.count-1 do
          begin
               pdesc.pointtype:=os_polymin-i;
               pdesc.worldcoord:=pv^;
               {pdesc.dispcoord.x:=round(pv2d^.x);
               pdesc.dispcoord.y:=round(pv2d.y);}
               PSelectedObjDesc(tdesc)^.pcontrolpoint^.add(@pdesc);
               inc(pv);
               inc(pv2d);
          end;
end;
function GDBObjLWpolyline.Clone;
var tpo: PGDBObjLWPolyline;
    p:PGDBVertex2D;
    pw:PGLLWWidth;
    i:GDBInteger;
begin
  GDBGetMem({$IFDEF DEBUGBUILD}'{8F88CAFB-14F3-4F33-96B5-F493DB8B28B7}',{$ENDIF}GDBPointer(tpo), sizeof(GDBObjLWPolyline));
  tpo^.init({bp.owner}own,vp.Layer, vp.LineWeight,closed);
  CopyVPto(tpo^);
  tpo^.Local:=local;
  //tpo^.vertexarray.init({$IFDEF DEBUGBUILD}'{90423E18-2ABF-48A8-8E0E-5D08A9E54255}',{$ENDIF}1000);
  p:=Vertex2D_in_OCS_Array.PArray;
  pw:=Width2D_in_OCS_Array.parray;
  for i:=0 to Vertex2D_in_OCS_Array.Count-1 do
  begin
      tpo^.Vertex2D_in_OCS_Array.add(p);
      tpo^.Width2D_in_OCS_Array.add(pw);
      inc(p);
      inc(pw);
  end;

  result := tpo;
end;
function GDBObjLWpolyline.GetObjTypeName;
begin
     result:=ObjN_GDBObjLWPolyLine;
end;
destructor GDBObjLWpolyline.done;
begin
     if pprojpoint<>nil then
                            begin
                            pprojpoint^.done;
                            gdbfreemem(pointer(pprojpoint));
                            end;
     Vertex2D_in_OCS_Array.done;
     Width2D_in_OCS_Array.done;
     Vertex3D_in_WCS_Array.done;
     Width3D_in_WCS_Array.done;
     //----------------snaparray.done;
     inherited done;//  error
end;
constructor GDBObjLWpolyline.init;
begin
  inherited init(own,layeraddres, lw);
  vp.id:=GDBLWPolylineID;
  closed := c;
  Vertex2D_in_OCS_Array.init({$IFDEF DEBUGBUILD}'{B8E62148-AC02-4BDF-9F48-B9D3307013A1}',{$ENDIF}1000,c);
  Width2D_in_OCS_Array.init({$IFDEF DEBUGBUILD}'{EFDA3BB3-E3AD-4D5C-97D2-FECD92A7276E}',{$ENDIF}1000);
  Vertex3D_in_WCS_Array.init({$IFDEF DEBUGBUILD}'{C5FE7AEE-3EF6-4AF8-ADCE-4D30495CE3F1}',{$ENDIF}1000);
  Width3D_in_WCS_Array.init({$IFDEF DEBUGBUILD}'{C9BB8E1B-18AA-464D-8726-68F2F609FEE0}',{$ENDIF}1000, sizeof(GDBQuad3d));
  //----------------snaparray.init({$IFDEF DEBUGBUILD}'{C37BA022-4629-4E16-BEB6-E8AAB9AC6986}',{$ENDIF}1000);
  PProjPoint:=nil;
end;
constructor GDBObjLWpolyline.initnul;
begin
  inherited initnul(nil);
  vp.id:=GDBLWPolylineID;
  {убрать в афтердесериализе}
  Vertex2D_in_OCS_Array.init({$IFDEF DEBUGBUILD}'{B8E62148-AC02-4BDF-9F48-B9D3307013A1}',{$ENDIF}1000,false);
  Width2D_in_OCS_Array.init({$IFDEF DEBUGBUILD}'{EFDA3BB3-E3AD-4D5C-97D2-FECD92A7276E}',{$ENDIF}1000);
  Vertex3D_in_WCS_Array.init({$IFDEF DEBUGBUILD}'{C5FE7AEE-3EF6-4AF8-ADCE-4D30495CE3F1}',{$ENDIF}1000);
  Width3D_in_WCS_Array.init({$IFDEF DEBUGBUILD}'{C9BB8E1B-18AA-464D-8726-68F2F609FEE0}',{$ENDIF}1000, sizeof(GDBQuad3d));
  //----------------snaparray.init({$IFDEF DEBUGBUILD}'{556C3123-58FC-41AA-BA5C-C453F025ACF6}',{$ENDIF}1000);
  PProjPoint:=nil;
end;
procedure GDBObjLWpolyline.DrawGeometry;
var i,ie: GDBInteger;
    q3d:PGDBQuad3d;
    plw:PGLlwwidth;
    v:gdbvertex;
begin
  {glPolygonMode(GL_FRONT_AND_BACK, GL_fill);
  if closed then
    for i := 0 to vertexarray.count - 1 do
    begin
      begin
                                      //oglsm.myglEnable(GL_LIGHTING);
        myglbegin(GL_QUADS);
        glVertex2dv(@PGDBArrayGLlwwidth(widtharray.PArray)^[i].quad[0]);
        glVertex2dv(@PGDBArrayGLlwwidth(widtharray.PArray)^[i].quad[1]);
        glVertex2dv(@PGDBArrayGLlwwidth(widtharray.PArray)^[i].quad[2]);
        glVertex2dv(@PGDBArrayGLlwwidth(widtharray.PArray)^[i].quad[3]);
        myglend();
                                      //oglsm.myglDisable(GL_LIGHTING);
      end;
      begin
        myglbegin(GL_LINEs);
        glVertex2dv(@PGDBArrayVertex2D(vertexarray.parray)^[i]);
        if i <> vertexarray.count - 1 then
          glVertex2dv(@PGDBArrayVertex2D(vertexarray.parray)^[i + 1])
        else
          glVertex2dv(@PGDBArrayVertex2D(vertexarray.parray)^[0]);
        myglend();
      end;
    end
  else
    for i := 0 to vertexarray.count - 2 do
    begin
                                  //if PGDBlwpolyline(temp)^.pwidtharray^.widtharray[i2].hw then
      begin
                                      //oglsm.myglEnable(GL_LIGHTING);
        myglbegin(GL_QUADS);
        glVertex2dv(@PGDBArrayGLlwwidth(widtharray.PArray)^[i].quad[0]);
        glVertex2dv(@PGDBArrayGLlwwidth(widtharray.PArray)^[i].quad[1]);
        glVertex2dv(@PGDBArrayGLlwwidth(widtharray.PArray)^[i].quad[2]);
        glVertex2dv(@PGDBArrayGLlwwidth(widtharray.PArray)^[i].quad[3]);
        myglend();
                                      //oglsm.myglDisable(GL_LIGHTING);
      end;
                                  //else
      begin
        myglbegin(GL_LINE_STRIP);
        glVertex2dv(@PGDBArrayVertex2D(vertexarray.parray)^[i]);
        glVertex2dv(@PGDBArrayVertex2D(vertexarray.parray)^[i + 1]);
        myglend();
      end;
    end;}
    {if closed then myglbegin(GL_LINE_LOOP)
              else myglbegin(GL_LINE_STRIP);
    Vertex3D_in_WCS_Array.iterategl(@myglVertex3dv);
    myglend();}
    v:=geometry.VertexSub(vp.BoundingBox.RTF,vp.BoundingBox.LBN);

    if not CanSimplyDrawInWCS(DC,geometry.oneVertexlength(v),5) then
           begin
                q3d:=Width3D_in_WCS_Array.parray;
                oglsm.myglbegin(GL_Lines);
                oglsm.myglVertex3dv(@q3d^[0]);
                oglsm.myglVertex3dv(@q3d^[1]);
                oglsm.myglend();
                exit;
           end;

    if closed then ie:=Width3D_in_WCS_Array.count - 1
              else ie:=Width3D_in_WCS_Array.count - 2;


    q3d:=Width3D_in_WCS_Array.parray;
    plw:=Width2D_in_OCS_Array.parray;
    for i := 0 to ie do
    begin
      begin
        if plw^.hw then
        begin
        oglsm.myglbegin(GL_QUADS);
        oglsm.myglVertex3dv(@q3d^[0]);
        oglsm.myglVertex3dv(@q3d^[1]);
        oglsm.myglVertex3dv(@q3d^[2]);
        oglsm.myglVertex3dv(@q3d^[3]);
        oglsm.myglend();
        end;
        inc(plw);
        inc(q3d);
      end;
   end;

    oglsm.myglbegin(GL_Lines);
    q3d:=Width3D_in_WCS_Array.parray;
    plw:=Width2D_in_OCS_Array.parray;
    for i := 0 to ie do
    begin
      begin
        oglsm.myglVertex3dv(@q3d^[0]);
        oglsm.myglVertex3dv(@q3d^[1]);
        if plw^.hw then
        begin
        oglsm.myglVertex3dv(@q3d^[1]);
        oglsm.myglVertex3dv(@q3d^[2]);
        oglsm.myglVertex3dv(@q3d^[2]);
        oglsm.myglVertex3dv(@q3d^[3]);
        oglsm.myglVertex3dv(@q3d^[3]);
        oglsm.myglVertex3dv(@q3d^[0]);
        end;
        inc(plw);
        inc(q3d);
      end;
   end;
   oglsm.myglend();




    {myglbegin(GL_LINE_STRIP);
    vertexarray.iterate(@glVertex2dv);
    myglend();}
end;

procedure GDBObjLWpolyline.LoadFromDXF;
var p: gdbvertex2d;
  s: GDBString;
  byt, code, i: GDBInteger;
  hlGDBWord: GDBLongword;
  tGDBDouble: GDBDouble;
  numv: GDBInteger;
begin
  //inherited init(nil,0, -1);
  hlGDBWord:=0;
  numv:=0;
  vp.id:=GDBLWPolylineID;
  local.p_insert:={w0^}PGDBVertex(@bp.ListPos.owner^.GetMatrix^[3])^;
  closed := false;
  Width2D_in_OCS_Array.createarray;
  (*Vertex2D_in_OCS_Array.init({$IFDEF DEBUGBUILD}'{270E17CA-8FFF-43B8-A6FB-E553C47023F1}',{$ENDIF}1000,closed);
  Width2D_in_OCS_Array.init({$IFDEF DEBUGBUILD}'{AFDB5BB1-6580-48A3-A57B-4B19E109D728}',{$ENDIF}1000);
  Vertex3D_in_WCS_Array.init({$IFDEF DEBUGBUILD}'{56952B93-D6AD-4377-872C-493129DE61C1}',{$ENDIF}1000);
  Width3D_in_WCS_Array.init({$IFDEF DEBUGBUILD}'{36C3CE89-2CA9-4E3A-BCE2-E9FE8B0A40CB}',{$ENDIF}1000, sizeof(GDBQuad3d));
  *)
  s := f.readGDBstring;
  val(s, byt, code);
  while byt <> 0 do
  begin
    case byt of
      8:
        begin
          s := f.readGDBString;
          vp.Layer := LayerArray.getAddres(s);
        end;
      62:begin
              vp.color:=readmystrtoint(f);
         end;
      90:
        begin
          s := f.readGDBstring;
          hlGDBWord := strtoint(s);
          //vertexarray.init(hlGDBWord,closed);
          //vertexarray.init(hlGDBWord, sizeof(gdbvertex2d));
          //normalarray.init(hlGDBWord, sizeof(gdbvertex));
          //widtharray.init(hlGDBWord, sizeof(GLLWWidth));
          numv := hlGDBWord;
          hlGDBWord := 0;
        end;
      10:
        begin
          s := f.readGDBstring;
          val(s, p.x, code);
        end;
      20:
        begin
          s := f.readgdbstring;
          val(s, p.y, code);
          Vertex2D_in_OCS_Array.add(@p);
          inc(hlGDBWord);
        end;
      38:
        begin
          s := f.readgdbstring;
          val(s, local.p_insert.z, code);
          //local.p_insert.z:=-local.p_insert.z;
        end;
      40:
        begin
          s := f.readgdbstring;
          //val(s, PGLLWWidth(Width2D_in_OCS_Array.getelement(hlGDBWord-1)).startw, code);
          Width2D_in_OCS_Array.SetCount(hlGDBWord);
          val(s, PGLLWWidth(Width2D_in_OCS_Array.getelement(hlGDBWord-1)).startw, code);
        end;
      41:
        begin
          s := f.readgdbstring;
          Width2D_in_OCS_Array.SetCount(hlGDBWord);
          val(s, PGLLWWidth(Width2D_in_OCS_Array.getelement(hlGDBWord- 1)).endw, code);
          //Width2D_in_OCS_Array.SetCount(hlGDBWord);
        end;
      43:
        begin
          s := f.readgdbstring;
          val(s, tGDBDouble, code);
          if Width2D_in_OCS_Array.Max<numv then
                                               Width2D_in_OCS_Array.setsize(numv);
          Width2D_in_OCS_Array.Count := numv;
          for i := 0 to numv - 1 do
          begin
            PGLLWWidth(Width2D_in_OCS_Array.getelement(i)).endw := tGDBDouble;
            PGLLWWidth(Width2D_in_OCS_Array.getelement(i)).startw := tGDBDouble;
          end;
          Width2D_in_OCS_Array.Count := numv;
        end;
      70:
        begin
          s := f.readgdbstring;
          if (strtoint(s) and 1) = 1 then closed := true;
        end;
      210:
        begin
          s := f.readgdbstring;
          val(s, Local.basis.oz.x, code);
        end;
      220:
        begin
          s := f.readgdbstring;
          val(s, Local.basis.oz.y, code);
        end;
      230:
        begin
          s := f.readgdbstring;
          val(s, Local.basis.oz.z, code);
        end;
      370:
        begin
          s := f.readgdbstring;
          vp.lineweight := strtoint(s);
        end;
    else
      s := f.readgdbstring;
    end;
    s := f.readgdbstring;
    val(s, byt, code);
  end;
  Vertex2D_in_OCS_Array.Shrink;
  Width2D_in_OCS_Array.Shrink;
  //Vertex3D_in_WCS_Array.Shrink;
  //Width3D_in_WCS_Array.Shrink;
  //format;
end;

procedure GDBObjLWpolyline.SaveToDXF;
var j: GDBInteger;
    tv:gdbvertex;
    m:DMatrix4D;
begin
  SaveToDXFObjPrefix(handle,outhandle,'LWPOLYLINE','AcDbPolyline');
  dxfGDBStringout(outhandle,90,inttostr(Vertex2D_in_OCS_Array.Count));
  //WriteString_EOL(outhandle, '90');
  //WriteString_EOL(outhandle, inttostr(Vertex2D_in_OCS_Array.Count));


  //WriteString_EOL(outhandle, '70');
  if closed then //WriteString_EOL(outhandle, '1')
                 dxfGDBStringout(outhandle,70,'1')
            else //WriteString_EOL(outhandle, '0');
                 dxfGDBStringout(outhandle,70,'0');


  dxfGDBDoubleout(outhandle,38,local.p_insert.z);
  //WriteString_EOL(outhandle, '38');
  //WriteString_EOL(outhandle, floattostr(local.p_insert.z));

  m:=CalcObjMatrixWithoutOwner;
  //MatrixTranspose(m);

  for j := 0 to (Vertex2D_in_OCS_Array.Count - 1) do
  begin
       tv.x:=PGDBArrayVertex2D(Vertex2D_in_OCS_Array.PArray)^[j].x;
       tv.y:=PGDBArrayVertex2D(Vertex2D_in_OCS_Array.PArray)^[j].y;
       tv.z:=0;
       tv:=geometry.VectorTransform3D(tv,m);
    dxfvertex2dout(outhandle,10,PGDBVertex2D(@tv)^);
    //dxfvertex2dout(outhandle,10,PGDBArrayVertex2D(Vertex2D_in_OCS_Array.PArray)^[j]);
    dxfGDBDoubleout(outhandle,40,PGLLWWidth(Width2D_in_OCS_Array.getelement(j)).startw);
    dxfGDBDoubleout(outhandle,41,PGLLWWidth(Width2D_in_OCS_Array.getelement(j)).endw);
  end;
  SaveToDXFObjPostfix(outhandle);
end;
function GDBObjLWpolyline.isPointInside(point:GDBVertex):GDBBoolean;
var m: DMatrix4D;
    p:GDBVertex2D;
begin
     m:=self.getmatrix^;
     geometry.MatrixInvert(m);
     point:=VectorTransform3D(point,m);
     p.x:=point.x;
     p.y:=point.y;
     result:=Vertex2D_in_OCS_Array.ispointinside(p);
end;

function GDBObjLWpolyline.CalcSquare:GDBDouble;
var
    pv,pvnext:PGDBVertex2D;
    i:integer;

begin
    result:=0;
    if Vertex2D_in_OCS_Array.count<2 then exit;

    pv:=Vertex2D_in_OCS_Array.parray;
    pvnext:=pv;
    inc(pvnext);
    for i:=1 to Vertex2D_in_OCS_Array.count do
    begin
       if i=Vertex2D_in_OCS_Array.count then
                                            pvnext:=Vertex2D_in_OCS_Array.parray;
       result:=result+(pv.x+pvnext.x)*(pv.y-pvnext.y);
       inc(pv);
       inc(pvnext);
    end;
    result:=result/2;
end;

procedure GDBObjLWpolyline.format;
begin
     Vertex2D_in_OCS_Array.Shrink;
     Width2D_in_OCS_Array.Shrink;
     inherited Format;
     createpoint;
     CalcWidthSegment;
     Square:=CalcSquare;
     calcbb;
end;
procedure GDBObjLWpolyline.createpoint;
var
  i: GDBInteger;
  v:GDBvertex4D;
  v3d:GDBVertex;
  pv:PGDBVertex2D;
begin
  Vertex3D_in_WCS_Array.clear;
  pv:=Vertex2D_in_OCS_Array.parray;
  for i:=0 to Vertex2D_in_OCS_Array.count-1 do
  begin
       v.x:=pv.x;
       v.y:=pv.y;
       v.z:=0;
       v.w:=1;
       v:=VectorTransform(v,objMatrix);
       v3d:=PGDBvertex(@v)^;
       Vertex3D_in_WCS_Array.add(@v3d);
       inc(pv);
  end;
  Vertex3D_in_WCS_Array.Shrink;
  //----------------BuildSnapArray(Vertex3D_in_WCS_Array,snaparray,closed);
end;
procedure GDBObjLWpolyline.Renderfeedback;
var tv:GDBvertex;
    tpv:GDBVertex2D;
    ptpv:PGDBVertex;
    i:GDBInteger;
begin
  if pprojpoint=nil then
  begin
       GDBGetMem({$IFDEF DEBUGBUILD}'{59A49074-4B98-46F2-AE7E-27F1C520CEE2}',{$ENDIF}GDBPointer(pprojpoint),sizeof(GDBpolyline2DArray));
       pprojpoint^.init({$IFDEF DEBUGBUILD}'{C2BA8485-D361-4FB7-9EA1-74CEE160AE8F}',{$ENDIF}Vertex3D_in_WCS_Array.count,closed);
  end;
  pprojpoint^.clear;
                    ptpv:=Vertex3D_in_WCS_Array.parray;
                    for i:=0 to Vertex3D_in_WCS_Array.count-1 do
                    begin
                         ProjectProc(ptpv^,tv);
                         tpv.x:=tv.x;
                         tpv.y:=tv.y;
                         PprojPoint^.add(@tpv);
                         inc(ptpv);
                    end;

end;
procedure GDBObjLWpolyline.CalcWidthSegment;
var
  i, j, k: GDBInteger;
  dx, dy, nx, ny, l: GDBDouble;
  v2di,v2dj:PGDBVertex2D;
  plw,plw2:PGLlwwidth;
  //q2d:GDBQuad2d;
  q3d:GDBQuad3d;
  pq3d,pq3dnext:pGDBQuad3d;
  v:GDBvertex4D;
  v2:PGDBvertex;
  ip,ip2:Intercept3DProp;
begin
  //Width2D_in_OCS_Array.clear;
  Width3D_in_WCS_Array.clear;
  for i := 0 to Vertex2D_in_OCS_Array.count - 1 do
  begin
    if i <> Vertex2D_in_OCS_Array.count - 1 then j := i + 1
                                            else j := 0;
    v2dj:=Vertex2D_in_OCS_Array.getelement(j);
    v2di:=Vertex2D_in_OCS_Array.getelement(i);
    dx := v2dj^.x - v2di^.x;
    dy := v2dj^.y - v2di^.y;
    nx := -dy;
    ny := dx;
    l := sqrt(nx * nx + ny * ny);
    if abs(l)>eps then
                      begin
                            nx := nx / l;
                            ny := ny / l;
                      end
                  else
                      begin
                            nx :=0;
                            ny :=0;
                      end;

    plw:=PGLlwwidth(Width2D_in_OCS_Array.getelement(i));

    if (plw^.startw = 0) and (plw^.endw = 0) then plw^.hw := false
                                             else plw^.hw := true;
      plw^.quad[0].x := v2di^.x + nx * plw^.startw / 2;
      plw^.quad[0].y := v2di^.y + ny * plw^.startw / 2;

      plw^.quad[1].x := v2dj^.x + nx * plw^.endw / 2;
      plw^.quad[1].y := v2dj^.y + ny * plw^.endw / 2;

      plw^.quad[2].x := v2dj^.x - nx * plw^.endw / 2;
      plw^.quad[2].y := v2dj^.y - ny * plw^.endw / 2;

      plw^.quad[3].x := v2di^.x - nx * plw^.startw / 2;
      plw^.quad[3].y := v2di^.y - ny * plw^.startw / 2;

      for k:=0 to 3 do
      begin
           v.x:=plw^.quad[k].x;
           v.y:=plw^.quad[k].y;
           v.z:=0;
           v.w:=1;
           v:=VectorTransform(v,objMatrix);
           q3d[k]:=PGDBvertex(@v)^;
      end;
      Width3D_in_WCS_Array.add(@q3d);
  end;
  Width2D_in_OCS_Array.Shrink;
  Width3D_in_WCS_Array.Shrink;

  if closed then k:=Width3D_in_WCS_Array.count - 1
            else k:=Width3D_in_WCS_Array.count - 2;
  for i := 0 to k do
  if (i<>k)or closed then
  begin
    if i <> Width3D_in_WCS_Array.count - 1 then j := i + 1
                                           else j := 0;
    plw:=PGLlwwidth(Width2D_in_OCS_Array.getelement(i));
    plw2:=PGLlwwidth(Width2D_in_OCS_Array.getelement(j));
    if plw.hw and plw2.hw then
    begin
    if plw.endw>plw2.startw then l:=plw.endw
                            else l:=plw2.startw;
    l:=4*l*l;
    pq3d:=Width3D_in_WCS_Array.getelement(i);
    pq3dnext:=Width3D_in_WCS_Array.getelement(j);
    ip:=intercept3dmy2(pq3d^[0] ,pq3d^[1],pq3dnext^[1] ,pq3dnext^[0]);
    ip2:=intercept3dmy2(pq3d^[3] ,pq3d^[2],pq3dnext^[2] ,pq3dnext^[3]);

    if ip.isintercept and ip2.isintercept then
    if (ip.t1>0) and (ip.t2>0) then
    if (ip2.t1>0) and (ip2.t2>0) then
    {if (ip.t1<2) and (ip.t2<2) then
    if (ip2.t1<2) and (ip2.t2<2) then}
    begin
         v2:=Pgdbvertex(Vertex3D_in_WCS_Array.getelement(j));
         if SqrVertexlength(v2^,ip.interceptcoord)<l then
         if SqrVertexlength(v2^,ip2.interceptcoord)<l then
         begin
         pq3d^[1]:=ip.interceptcoord;
         pq3d^[2]:=ip2.interceptcoord;
         pq3dnext^[0]:=ip.interceptcoord;
         pq3dnext^[3]:=ip2.interceptcoord;
         end;
    end;
    end;

  end;
end;
begin
  {$IFDEF DEBUGINITSECTION}LogOut('GDBLWPolyline.initialization');{$ENDIF}
end.
