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

unit uzgprimitivescreator;
{$INCLUDE def.inc}
interface
uses uzctnrvectordata,uzgprimitivescreatorabstract,uzgindexsarray,uzgprimitives,
     uzbtypesbase,sysutils,uzbtypes,uzbmemman,uzgprimitivessarray,uzegeometry;
type

TLLPrimitivesCreator=class(TLLPrimitivesCreatorAbstract)
                function CreateLLLine(var pa:TLLPrimitivesArray;const P1Index:TLLVertexIndex):TArrayIndex;override;
                function CreateLLTriangle(var pa:TLLPrimitivesArray;const P1Index:TLLVertexIndex):TArrayIndex;override;
                function CreateLLFreeTriangle(var pa:TLLPrimitivesArray;const P1Index,P2Index,P3Index:TLLVertexIndex; var ia:ZGLIndexsArray):TArrayIndex;override;
                function CreateLLTriangleStrip(var pa:TLLPrimitivesArray):TArrayIndex;override;
                function CreateLLTriangleFan(var pa:TLLPrimitivesArray):TArrayIndex;override;
                function CreateLLPoint(var pa:TLLPrimitivesArray;const PIndex:TLLVertexIndex):TArrayIndex;override;
                function CreateLLSymbol(var pa:TLLPrimitivesArray):TArrayIndex;override;
                function CreateLLSymbolLine(var pa:TLLPrimitivesArray):TArrayIndex;override;
                function CreateLLSymbolEnd(var pa:TLLPrimitivesArray):TArrayIndex;override;
                function CreateLLPolyLine(var pa:TLLPrimitivesArray;const P1Index,_Count:TLLVertexIndex;_closed:GDBBoolean=false):TArrayIndex;override;
             end;
var
   DefaultLLPCreator:TLLPrimitivesCreator;
implementation
//uses log;
function TLLPrimitivesCreator.CreateLLTriangle(var pa:TLLPrimitivesArray;const P1Index:TLLVertexIndex):TArrayIndex;
var
  ptt:PTLLTriangle;
begin
  result:=pa.count;
  ptt:=pa.AllocData(sizeof(TLLTriangle));
  ptt.init;
  ptt.P1Index:=P1Index;
end;
function TLLPrimitivesCreator.CreateLLFreeTriangle(var pa:TLLPrimitivesArray;const P1Index,P2Index,P3Index:TLLVertexIndex; var ia:ZGLIndexsArray):TArrayIndex;
var
  ptt:PTLLFreeTriangle;
begin
  result:=pa.count;
  ptt:=pa.AllocData(sizeof(TLLFreeTriangle));
  ptt.init;
  ptt.P1IndexInIndexesArray:=ia.PushBackData(P1Index);
  ia.PushBackData(P2Index);
  ia.PushBackData(P3Index);
  {ptt.P1Index:=P1Index;
  ptt.P2Index:=P2Index;
  ptt.P3Index:=P3Index;}
end;
function TLLPrimitivesCreator.CreateLLTriangleStrip(var pa:TLLPrimitivesArray):TArrayIndex;
var
  pts:PTLLTriangleStrip;
begin
  result:=pa.count;
  pts:=pa.AllocData(sizeof(TLLTriangleStrip));
  pts.init;
end;

function TLLPrimitivesCreator.CreateLLTriangleFan(var pa:TLLPrimitivesArray):TArrayIndex;
var
  ptf:PTLLTriangleFan;
begin
  result:=pa.count;
  ptf:=pa.AllocData(sizeof(TLLTriangleFan));
  ptf.init;
end;

function TLLPrimitivesCreator.CreateLLLine(var pa:TLLPrimitivesArray;const P1Index:TLLVertexIndex):TArrayIndex;
var
   ptl:PTLLLine;
begin
     result:=pa.count;
     ptl:=pa.AllocData(sizeof(TLLLine));
     ptl.init;
     ptl.P1Index:=P1Index;
end;
function TLLPrimitivesCreator.CreateLLPolyLine(var pa:TLLPrimitivesArray;const P1Index,_Count:TLLVertexIndex;_closed:GDBBoolean=false):tarrayindex;
var
   ptpl:PTLLPolyLine;
begin
     result:=pa.count;
     ptpl:=pa.AllocData(sizeof(TLLPolyLine));
     ptpl.init;
     ptpl.P1Index:=P1Index;
     ptpl.Count:=_Count;
     ptpl.Closed:=_closed;
end;
function TLLPrimitivesCreator.CreateLLPoint(var pa:TLLPrimitivesArray;const PIndex:TLLVertexIndex):TArrayIndex;
var
   ptp:PTLLPoint;
begin
     result:=pa.count;
     ptp:=pa.AllocData(sizeof(TLLPoint));
     ptp.init;
     ptp.PIndex:=PIndex;
end;
function TLLPrimitivesCreator.CreateLLSymbolLine(var pa:TLLPrimitivesArray):TArrayIndex;
var
   ptsl:PTLLSymbolLine;
begin
     result:=pa.count;
     ptsl:=pa.AllocData(sizeof(TLLSymbolLine));
     ptsl.init;
end;
function TLLPrimitivesCreator.CreateLLSymbol(var pa:TLLPrimitivesArray):TArrayIndex;
var
   pts:PTLLSymbol;
begin
     result:=pa.count;
     pts:=pa.AllocData(sizeof(TLLSymbol));
     pts.init;
end;
function TLLPrimitivesCreator.CreateLLSymbolEnd(var pa:TLLPrimitivesArray):TArrayIndex;
var
   ptse:PTLLSymbolEnd;
begin
     result:=pa.count;
     ptse:=pa.AllocData(sizeof(TLLSymbolEnd));
     ptse.init;
end;
initialization
  DefaultLLPCreator:=TLLPrimitivesCreator.create;
finalization
  DefaultLLPCreator.Destroy;
end.

