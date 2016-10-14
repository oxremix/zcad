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

unit uzegeomentitiestree;
{$INCLUDE def.inc}
interface
uses
    graphics,gzctnrvectorsimple,uzgeomentity,
    uzbgeomtypes,gzctnrtree,uzgldrawcontext,uzegeometry,uzbtypesbase,uzbtypes,uzbmemman;
type
TZEntsManipulator=class;
TFirstStageData=record
                  midlepoint:gdbvertex;
                  d:double;
                  counter:integer;
                end;
{EXPORT+}
TGeomTreeNodeData=record
                  end;
TEntityArray={GZVectorPObects}GZVectorSimple<PTGeomEntity>;
         PTEntTreeNode=^TGeomEntTreeNode;
         TGeomEntTreeNode={$IFNDEF DELPHI}packed{$ENDIF}object(GZBInarySeparatedGeometry{-}<TBoundingBox,DVector4D,TGeomTreeNodeData,TZEntsManipulator,TGeomEntity,PTGeomEntity,TEntityArray>{//})
                      end;
{EXPORT-}
TZEntsManipulator=class
                   class procedure StoreTreeAdressInOnject(var Entity:TGeomEntity;var Node:GZBInarySeparatedGeometry<TBoundingBox,DVector4D,TGeomTreeNodeData,TZEntsManipulator,TGeomEntity,PTGeomEntity,TEntityArray>;const index:GDBInteger);
                   class procedure CorrectNodeBoundingBox(var NodeBB:TBoundingBox;var Entity:TGeomEntity);
                   class function GetEntityBoundingBox(var Entity:TGeomEntity):TBoundingBox;
                   class function GetBBPosition(const sep:DVector4D;const BB:TBoundingBox):TElemPosition;
                   class function isUnneedSeparate(const count,depth:integer):boolean;
                   class function GetTestNodesCount:integer;
                   class procedure FirstStageCalcSeparatirs(var NodeBB:TBoundingBox;var Entity:TGeomEntity;var PFirstStageData:pointer;TSM:TStageMode);
                   class procedure CreateSeparator(var NodeBB:TBoundingBox;var TestNode:TGeomEntTreeNode.TTestNode;var PFirstStageData:pointer;const NodeNum:integer);
                   class function IterateResult2PEntity(const IterateResult:pointer):PTGeomEntity;
                  end;
var
   SysVarRDSpatialNodeCount:integer=2;
   SysVarRDSpatialNodesDepth:integer=16;
   FirstStageData:TFirstStageData;
function GetInNodeCount(_InNodeCount:GDBInteger):GDBInteger;
implementation
class function TZEntsManipulator.isUnneedSeparate(const count,depth:integer):boolean;
begin
     if (Count<=GetInNodeCount(SysVarRDSpatialNodeCount))or(depth>=SysVarRDSpatialNodesDepth) then
       result:=true
     else
       result:=false;
end;
class function TZEntsManipulator.GetTestNodesCount:integer;
begin
   result:=1;
end;
class procedure TZEntsManipulator.FirstStageCalcSeparatirs(var NodeBB:TBoundingBox;var Entity:TGeomEntity;var PFirstStageData:pointer;TSM:TStageMode);
begin
   case TSM of
       TSMStart:begin
                   FirstStageData.midlepoint:=NulVertex;
                   FirstStageData.counter:=0;
                   PFirstStageData:={@FirstStageData}nil;
                end;
TSMAccumulation:begin
                   //FirstStageData.midlepoint:=vertexadd(Entity.GetBB.LBN,FirstStageData.midlepoint);
                   //FirstStageData.midlepoint:=vertexadd(Entity.GetBB.RTF,FirstStageData.midlepoint);
                   //inc(FirstStageData.counter,2);
                end;
        TSMCalc:begin
                   //FirstStageData.midlepoint:=VertexMulOnSc(FirstStageData.midlepoint,1/FirstStageData.counter);
                   //FirstStageData.d:=sqrt(sqr(FirstStageData.midlepoint.x) + sqr(FirstStageData.midlepoint.y) + sqr(FirstStageData.midlepoint.z));
                end;
         TSMEnd:begin
                   PFirstStageData:=nil;
                end;
   end;
end;
class procedure TZEntsManipulator.CreateSeparator(var NodeBB:TBoundingBox;var TestNode:TGeomEntTreeNode.TTestNode;var PFirstStageData:pointer;const NodeNum:integer);
var
   v:gdbvertex;
   axis:integer;
begin
   v:=VertexSub(NodeBB.RTF,NodeBB.LBN);
   if x>y then
              begin
                   if x>z then
                              axis:=0
                          else
                              axis:=2
              end
          else
              begin
                   if y>z then
                              axis:=1
                          else
                              axis:=2
              end;
   FirstStageData.midlepoint:=VertexMulOnSc(VertexAdd(NodeBB.RTF,NodeBB.LBN),0.5);
   FirstStageData.d:=sqrt(sqr(FirstStageData.midlepoint.x) + sqr(FirstStageData.midlepoint.y) + sqr(FirstStageData.midlepoint.z));
case axis of
      0:TestNode.plane:=uzegeometry.PlaneFrom3Pont(FirstStageData.midlepoint,
                                          vertexadd(FirstStageData.midlepoint,VertexMulOnSc(x_Y_zVertex,FirstStageData.d)),
                                          vertexadd(FirstStageData.midlepoint,VertexMulOnSc(xy_Z_Vertex,FirstStageData.d))
                                          );
      1:TestNode.plane:=uzegeometry.PlaneFrom3Pont(FirstStageData.midlepoint,
                                          vertexadd(FirstStageData.midlepoint,VertexMulOnSc(_X_yzVertex,FirstStageData.d)),
                                          vertexadd(FirstStageData.midlepoint,VertexMulOnSc(xy_Z_Vertex,FirstStageData.d))
                                          );
      2:TestNode.plane:=uzegeometry.PlaneFrom3Pont(FirstStageData.midlepoint,
                                          vertexadd(FirstStageData.midlepoint,VertexMulOnSc(_X_yzVertex,FirstStageData.d)),
                                          vertexadd(FirstStageData.midlepoint,VertexMulOnSc(x_Y_ZVertex,FirstStageData.d))
                                          );
end;
end;
class procedure TZEntsManipulator.StoreTreeAdressInOnject(var Entity:TGeomEntity;var Node:GZBInarySeparatedGeometry{-}<TBoundingBox,DVector4D,TgeomTreeNodeData,TZEntsManipulator,TGeomEntity,PTGeomEntity,TEntityArray>;const index:GDBInteger);
begin
  {Entity.bp.TreePos.Owner:=@Node;
  Entity.bp.TreePos.SelfIndex:=index;}
end;
class procedure TZEntsManipulator.CorrectNodeBoundingBox(var NodeBB:TBoundingBox;var Entity:TGeomEntity);
begin
     ConcatBB(NodeBB,GetEntityBoundingBox(Entity));
end;
class function TZEntsManipulator.GetEntityBoundingBox(var Entity:TGeomEntity):TBoundingBox;
begin
     result:=Entity.GetBB;
end;

class function TZEntsManipulator.GetBBPosition(const sep:DVector4D;const BB:TBoundingBox):TElemPosition;
var
    d,d1,d2:double;
begin
     d1:=sep[0] * BB.RTF.x + sep[1] * BB.RTF.y + sep[2] * BB.RTF.z + sep[3];
     d2:=sep[0] * BB.LBN.x + sep[1] * BB.LBN.y + sep[2] * BB.LBN.z + sep[3];
     if abs(d1)<eps then
                        d1:=0;
     if abs(d2)<eps then
                        d2:=0;
     d:=d1*d2;

     if d=0 then
                begin
                     if (d1=0)and(d2=0) then
                                            exit(TEP_nul)
                                            //ta[i].nul.PushBackData(pobj)
                else if (d1>0)or(d2>0)  then
                                            exit(TEP_Plus)
                                            //ta[i].plus.PushBackData(pobj)
                                        else
                                            exit(TEP_Minus)
                                            //ta[i].minus.PushBackData(pobj);
                end
else if d<0 then
                exit(TEP_nul)
                //ta[i].nul.PushBackData(pobj)
else if (d1>0)or(d2>0)  then
                            exit(TEP_Plus)
                            //ta[i].plus.PushBackData(pobj)
                        else
                            exit(TEP_Minus)
                            //ta[i].minus.PushBackData(pobj);
     //result:=TEP_nul;
end;
class function TZEntsManipulator.IterateResult2PEntity(const IterateResult:pointer):PTGeomEntity;
begin
  if IterateResult<>nil then
    result:=ppointer(IterateResult)^
  else
    result:=nil;
end;

function GetInNodeCount(_InNodeCount:GDBInteger):GDBInteger;
begin
     if _InNodeCount>0 then
                           result:=_InNodeCount
                       else
                           result:=500;
end;
begin
end.
