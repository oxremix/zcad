{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.txt, included in this distribution,                 *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Vladimir Bobrov)
}
{$mode objfpc}{$H+}

unit uzvmanemgetgem;
{$INCLUDE zengineconfig.inc}

interface
uses

   sysutils, //math,

  URecordDescriptor,TypeDescriptors,

  Forms, //uzcfblockinsert,
   //uzcfarrayinsert,

  uzeentblockinsert,      //unit describes blockinsert entity
                       //модуль описывающий примитив вставка блока
  uzeentline,             //unit describes line entity
                       //модуль описывающий примитив линия
  uzeentmtext,

  uzeentlwpolyline,             //unit describes line entity
                       //модуль описывающий примитив двухмерная ПОЛИлиния

  uzeentpolyline,             //unit describes line entity
                       //модуль описывающий примитив трехмерная ПОЛИлиния
  uzeentabstracttext,uzeenttext,
                       //модуль описывающий примитив текст

  uzeentdimaligned, //unit describes aligned dimensional entity
                       //модуль описывающий выровненный размерный примитив
  uzeentdimrotated,

  uzeentdimdiametric,

  uzeentdimradial,
  uzeentarc,
  uzeentcircle,
  uzeentity,
  uzegeometrytypes,


  gvector,//garrayutils, // Подключение Generics и модуля для работы с ним

  uzcentcable,
  uzeentdevice,
  UGDBOpenArrayOfPV,

  uzegeometry,
  //uzeentitiesmanager,

  //uzcmessagedialogs,
  uzeentityfactory,    //unit describing a "factory" to create primitives
                      //модуль описывающий "фабрику" для создания примитивов
  uzcsysvars,        //system global variables
                      //системные переменные
  //uzgldrawcontext,
  uzcinterface,
  uzbtypes, //base types
                      //описания базовых типов
  uzeconsts, //base constants
                      //описания базовых констант
  uzccommandsmanager,
  uzccommandsabstract,
  uzccommandsimpl, //Commands manager and related objects
                      //менеджер команд и объекты связанные с ним
  //uzcdrawing,
  uzedrawingsimple,
  uzcdrawings,     //Drawings manager, all open drawings are processed him
                      //"Менеджер" чертежей
  uzcutils,         //different functions simplify the creation entities, while there are very few
                      //разные функции упрощающие создание примитивов, пока их там очень мало
  varmandef,
  Varman,
  {UGDBOpenArrayOfUCommands,}//zcchangeundocommand,

  uzclog,                //log system
                      //<**система логирования
  uzcvariablesutils, // для работы с ртти

   gzctnrVectorTypes,                  //itrec

  //для работы графа
  ExtType,
  Pointerv,
  Graphs,
  AttrType,
  AttrSet,
  //*

   uzcenitiesvariablesextender,
   UUnitManager,
   uzbpaths,
   uzeroot,
   uzctranslations,
   uzgldrawcontext,
   uzeentityextender,
   uzeblockdef,

  uzvagraphsdev,
  uzvconsts;
  //uzvtmasterdev,
  //uzvtestdraw;


type
 TDummyComparer=class
 function Compare (Edge1, Edge2: Pointer): Integer;
 function CompareEdges (Edge1, Edge2: Pointer): Integer;
 end;
 TSortTreeLengthComparer=class
 function Compare (vertex1, vertex2: Pointer): Integer;
 end;


 function getListGrapghEM:TListGraphDev;
 procedure visualGraphTree(G: TGraph; var startPt:GDBVertex;height:double; var depth:double);

implementation
var
  DummyComparer:TDummyComparer;
  SortTreeLengthComparer:TSortTreeLengthComparer;




//**Получить список всех древовидно ориентированных графов из которых состоит модель
function getListGrapghEM:TListGraphDev;
type
 TListDevice=specialize TVector<pGDBObjDevice>;
 TListCable=specialize TVector<PGDBObjPolyLine>;
var

   graphDev:TGraphDev;
   vertexDev:TVertex;
   listDevice:TListDevice;
   listCable:TListCable;
   listTreeRoots:TListDevice;
   dev:pGDBObjDevice;
   pvd:pvardesk;
   depthVisual:double;
   insertCoordination:GDBVertex;

    //** Получение области выделения по полученным точкам, левая-нижняя-ближняя точка и правая-верхняя-дальняя точка
    function getTBoundingBox(VT1,VT2:GDBVertex):TBoundingBox;
    begin
      result.LBN:=VT1;
      result.RTF:=VT2;
      result.LBN.y:= VT2.y;
      result.RTF.y:= VT1.y;
    end;

    //**Получаем координаты стартовой и конечной точки электрической модели
    function getStEdEMVertex(var VTst,VTed:GDBVertex):boolean;
    var
        stVertexSum,edVertexSum:integer;
        pobj: pGDBObjEntity;   //выделеные объекты в пространстве листа
        pblock: PGDBObjBlockInsert;   //выделеные объекты в пространстве листа
        ir:itrec;  // применяется для обработки списка выделений, но что это понятия не имею :)
    begin
      result:=false;
      stVertexSum:=0;
      edVertexSum:=0;
      pobj:=drawings.GetCurrentROOT^.ObjArray.beginiterate(ir); //зона уже выбрана в перспективе застовлять пользователя ее выбирать
      if pobj<>nil then
        repeat
            // Заполняем список всех GDBSuperLineID
           if pobj^.GetObjType=GDBBlockInsertID then
             begin
               pblock:=PGDBObjBlockInsert(pobj);
               //ZCMsgCallBackInterface.TextMessage('getStEdEMVertex pblock=' + pblock^.Name,TMWOHistoryOut);
               if pblock^.Name=velec_SchemaELSTART then
                 begin
                    VTst:=pblock^.P_insert_in_WCS;
                    inc(stVertexSum);
                 end;
               if pblock^.Name=velec_SchemaELEND then
                 begin
                    VTed:=pblock^.P_insert_in_WCS;
                    inc(edVertexSum);
                 end;
             end;
          pobj:=drawings.GetCurrentROOT^.ObjArray.iterate(ir); //переход к следующем примитиву в списке выбраных примитивов
        until pobj=nil;
      //ZCMsgCallBackInterface.TextMessage('stVertexSum=' + inttostr(stVertexSum) + ' ' + 'edVertexSum=' + inttostr(edVertexSum),TMWOHistoryOut);
      if (stVertexSum = 1) and (edVertexSum = 1) then
           result:=true
        else
           ZCMsgCallBackInterface.TextMessage('ОШИБКА!!! На чертеже отсутствует электрическая модель или присутствует несколько электрических моделей',TMWOHistoryOut);
    end;

    //**Получаем список устройств и кабелей
    function getListDeviceAndCable(var lDevice:TListDevice;var lCable:TListCable):boolean;
    var
        //infoDevice:TVertexDevice; //инфо по объекта списка

        areaEMBoundingBox:TBoundingBox;        //Ограничивающий объем, обычно в графике его называют AABB - axis aligned bounding box
                                        //куб со сторонами паралелльными осям, определяется 2мя диагональными точками
                                        //левая-нижняя-ближняя и правая-верхняя-дальня
        VTst,VTed:GDBVertex;

        pobj: pGDBObjEntity;   //выделеные объекты в пространстве листа
        pvd:pvardesk; //для работы со свойствами устройств

        //i,num:integer;
        //
        //polyLWObj:pgdbobjlwpolyline;
        //pt:gdbvertex;
        //vertexLWObj:GDBvertex2D; //для двух серной полилинии
        //widthObj:GLLWWidth;      //переменная для добавления веса линии в начале и конце пути
        //
        //drawing:PTSimpleDrawing; //для работы с чертежом
        NearObjects:GDBObjOpenArrayOfPV;//список примитивов рядом с точкой
        ir:itrec;  // применяется для обработки списка выделений, но что это понятия не имею :)
    begin

       result:=false;

       VTst:=uzegeometry.CreateVertex(0,0,0);
       VTed:=uzegeometry.CreateVertex(0,0,0);
       //Получаем координаты стартовой и конечной точки электрической модели
       if not getStEdEMVertex(VTst,VTed) then
         exit;

       //** Получение области выделения по полученным точкам, левая-нижняя-ближняя точка и правая-верхняя-дальняя точка
       areaEMBoundingBox:= getTBoundingBox(VTst,VTed);

       //**Выделяем все примитывы внутри данной области
       NearObjects.init(100); //инициализируем список
       if drawings.GetCurrentROOT^.FindObjectsInVolume(areaEMBoundingBox,NearObjects)then //ищем примитивы оболочка которых пересекается с volume
       begin
         pobj:=NearObjects.beginiterate(ir);   //получаем первый примитив из списка
         if pobj<>nil then                     //если он есть то
         repeat
           if pobj^.GetObjType=GDBDeviceID then //если это устройство
               lDevice.PushBack(PGDBObjDevice(pobj));
           if pobj^.GetObjType=GDBPolyLineID then
           begin
                pvd:=FindVariableInEnt(PGDBObjPolyline(pobj),velec_SchemaIsCable);
                if pvd <> nil then
                  if (pBoolean(pvd^.data.Addr.Instance)^) then
                     lCable.PushBack(PGDBObjPolyline(pobj));
           end;
           pobj:=NearObjects.iterate(ir);//получаем следующий примитив из списка
         until pobj=nil;
        end;
        result:=true;
        //zcClearCurrentDrawingConstructRoot;
        NearObjects.Clear;
        NearObjects.Done;//убиваем список
      end;

    //*** поиск точки координаты коннектора в устройстве
    function getDevVertexConnector(pobj:pGDBObjEntity; out pConnect:GDBVertex):Boolean;
    var
       pObjDevice,currentSubObj:PGDBObjDevice;
       ir_inDevice:itrec;  // применяется для обработки списка выделений, но что это понятия не имею :)
    Begin
       result:=false;
      pObjDevice:= PGDBObjDevice(pobj); // передача объекта в девайсы
      currentSubObj:=pObjDevice^.VarObjArray.beginiterate(ir_inDevice); //иследование содержимого девайса
      if (currentSubObj<>nil) then
        repeat
          if (CurrentSubObj^.GetObjType=GDBDeviceID) then begin
             if (CurrentSubObj^.Name = 'CONNECTOR_SQUARE') or (CurrentSubObj^.Name = 'CONNECTOR_POINT') then
               begin
                 pConnect:=CurrentSubObj^.P_insert_in_WCS;
                 result:=true;
               end;
             if not result then
                result := getDevVertexConnector(CurrentSubObj,pConnect);
          end;
        currentSubObj:=pObjDevice^.VarObjArray.iterate(ir_inDevice);
        until currentSubObj=nil;
    end;

    //**Получить список источников питания
    function getListTreeRoots(lDevice:TListDevice;lCable:TListCable):TListDevice;
    var
      dev:pGDBObjDevice;
      devVertex:GDBVertex;
      cab:PGDBObjPolyLine;
      devFound:boolean;
    begin
      result:=TListDevice.Create;
      for dev in lDevice do
      begin
           devFound:=false;
           devVertex:=uzegeometry.CreateVertex(0,0,0);
           if not getDevVertexConnector(dev,devVertex) then       // Получаем координату коннектора
              ZCMsgCallBackInterface.TextMessage('ОШИБКА! устройство без коннектора',TMWOHistoryOut);
           for cab in lCable do    // перебираем все кабели в списке
               if vertexeq(devVertex,cab^.VertexArrayInWCS.getLast) then    //сравниваем координату устройства с последней точкой кабеля. на вершинах дерьвьев не заканичваются кабели. Они начинаются с вершин. Так можно найти вершены, всех деревьев
                  devFound:=true;

           if not devFound then
             result.PushBack(dev);
      end;
    end;

    //**Получить список источников питания
    procedure getGraphEM(var gDev:TGraphDev;index:integer;lDevice:TListDevice;lCable:TListCable);
    var

      dev:pGDBObjDevice;
      devVertex:GDBVertex;
      lastDevVertex:GDBVertex;
      cab:PGDBObjPolyLine;
      newVertex:TVertex;
      //devFound:boolean;
    begin
      //result:=TListDevice.Create;
      devVertex:=gDev[index].getVertexDevWCS;
      for cab in lCable do
      begin
           //ZCMsgCallBackInterface.TextMessage('3',TMWOHistoryOut);
           if vertexeq(devVertex,cab^.VertexArrayInWCS.getData(0)) then    //Ищем кабели у которые начинаются из нашего устройства
             begin
                //ZCMsgCallBackInterface.TextMessage('4',TMWOHistoryOut);
                for dev in lDevice do    // теперь из списка устройств ищем те чьи координаты находятся на конце кабеля
                begin
                   //ZCMsgCallBackInterface.TextMessage('5',TMWOHistoryOut);
                   lastDevVertex:=uzegeometry.CreateVertex(0,0,0);
                   if not getDevVertexConnector(dev,lastDevVertex) then       // Получаем координату коннектора
                      ZCMsgCallBackInterface.TextMessage('ОШИБКА! устройство без коннектора',TMWOHistoryOut);
                   if vertexeq(lastDevVertex,cab^.VertexArrayInWCS.getLast) then    //сравниваем координату устройства с последней точкой кабеля
                      begin
                         //ZCMsgCallBackInterface.TextMessage('6',TMWOHistoryOut);
                         newVertex:=gDev[index].AddChild;
                         newVertex.attachDevice(dev);
                         gDev.GetEdge(gDev[index],newVertex).attachCable(cab);
                         getGraphEM(gDev,newVertex.Index,lDevice,lCable);
                      end;
                end;
             end;

             //cab^.VertexArrayInWCS[0];
           //devFound:=false;

           //devVertex:=uzegeometry.CreateVertex(0,0,0);
           //if not getDevVertexConnector(dev,devVertex) then       // Получаем координату коннектора
           //   ZCMsgCallBackInterface.TextMessage('ОШИБКА! устройство без коннектора',TMWOHistoryOut);
           //for cab in lCable do    // перебираем все кабели в списке
           //    if vertexeq(devVertex,cab^.VertexArrayInWCS.getLast) then    //сравниваем координату устройства с последней точкой кабеля. на вершинах дерьвьев не заканичваются кабели. Они начинаются с вершин. Так можно найти вершены, всех деревьев
           //       devFound:=true;
           //
           //if not devFound then
           //  result.PushBack(dev);
      end;
    end;

begin
     ZCMsgCallBackInterface.TextMessage(' Получение списков древовидных графов электрической модели (getListGrapghEM) - НАЧАТО  ',TMWOHistoryOut);
     result:=TListGraphDev.Create;
     listDevice:=TListDevice.Create;
     listCable:=TListCable.Create;
     listTreeRoots:=TListDevice.Create;


     //Получение списков устройств и кабелей
     if getListDeviceAndCable(listDevice,listCable) then begin
        ZCMsgCallBackInterface.TextMessage('Количество устройств внутри электрической модели = ' + inttostr(listDevice.Size) + 'шт.',TMWOHistoryOut);
        ZCMsgCallBackInterface.TextMessage('Количество кабелей внутри электрической модели = ' + inttostr(listCable.Size) + 'шт.',TMWOHistoryOut);

        // Получаем вершины деревьев (источники питания)
        listTreeRoots:=getListTreeRoots(listDevice,listCable);
        ZCMsgCallBackInterface.TextMessage('Количество источников питания (вершин деревьев) = ' + inttostr(listTreeRoots.Size) + 'шт.',TMWOHistoryOut);
        ZCMsgCallBackInterface.TextMessage('Список источников питания: ',TMWOHistoryOut);
        for dev in listTreeRoots do
           begin
              pvd:=FindVariableInEnt(dev,'NMO_Name');
              if pvd<>nil then
                 ZCMsgCallBackInterface.TextMessage(' - ' + pstring(pvd^.data.Addr.Instance)^,TMWOHistoryOut);
           end;
       // Получаем деревьея (графы) рекурсия от источников питания
       ZCMsgCallBackInterface.TextMessage('Получаем графы: ',TMWOHistoryOut);
         for dev in listTreeRoots do
           begin
              graphDev:=TGraphDev.Create;
              graphDev.Features:=[Tree];
              graphDev.CreateVertexAttr(vPGDBObjDeviceVertex,AttrPointer);
              graphDev.CreateEdgeAttr(vPGDBObjDeviceEdge,AttrPointer);            // добавили ссылку сразу на саму линию

              pvd:=FindVariableInEnt(dev,'NMO_Name');
              if pvd<>nil then
                 ZCMsgCallBackInterface.TextMessage(' Источник питания - ' + pstring(pvd^.data.Addr.Instance)^,TMWOHistoryOut);
              vertexDev:=graphDev.addVertexDevFunc(dev);  // создаем вершину с присвоиным устройство
              //ZCMsgCallBackInterface.TextMessage('1',TMWOHistoryOut);
              graphDev.Root:=vertexDev;                   //Говорим графу что это вершина дерева
              //ZCMsgCallBackInterface.TextMessage('2',TMWOHistoryOut);
              getGraphEM(graphDev,vertexDev.Index,listDevice,listCable);
              ZCMsgCallBackInterface.TextMessage('Количество вершин в древовидном графе = ' + inttostr(graphDev.VertexCount) + 'шт.',TMWOHistoryOut);
              ZCMsgCallBackInterface.TextMessage('Количество ребер в древовидном графе = ' + inttostr(graphDev.EdgeCount) + 'шт.',TMWOHistoryOut);
              result.PushBack(graphDev);
           end;
         depthVisual:=15;
         insertCoordination:=uzegeometry.CreateVertex(0,0,0);
         visualGraphTree(result[0],insertCoordination,3,depthVisual);
     end
     else
        exit;


     ZCMsgCallBackInterface.TextMessage(' getListGrapghEM - ФИНИШ  ',TMWOHistoryOut);
end;


////Визуализация графа
procedure visualGraphTree(G: TGraph; var startPt:GDBVertex;height:double; var depth:double);
const
  size=5;
  indent=30;
type
   PTInfoVertex=^TInfoVertex;
   TInfoVertex=record
       num,kol,childs:Integer;
       poz:GDBVertex2D;
       vertex:TVertex;
   end;

   TListVertex=specialize TVector<TInfoVertex>;

var
  //ptext:PGDBObjText;
  //indent,size:double;
  x,y,i,tParent:integer;
  //iNum:integer;
  listVertex:TListVertex;
  infoVertex:TInfoVertex;
  pt1,pt2,pt3,ptext,ptSt,ptEd:GDBVertex;
  VertexPath: TClassList;
  pv:pGDBObjDevice;
  //ppvvarext,pvarv:TVariablesExtender;
  //pvmc,pvv:pvardesk;

  function howParent(listVertex:TListVertex;ch:integer):integer;
  var
      c:integer;
  begin
      result:=-1;

      for c:=0 to listVertex.Size-1 do
            if ch = listVertex[c].num then
               result:=c;
  end;

  procedure addBlockonDraw(dev:pGDBObjDevice;var currentcoord:GDBVertex; var root:GDBObjRoot);
  var
      datname:String;
      pv:pGDBObjDevice;
      DC:TDrawContext;
      lx,{rx,}uy,dy:Double;
        c:integer;
        pCentralVarext,pVarext:TVariablesExtender;
        pu:PTSimpleUnit;
        extensionssave:TEntityExtensions;
        pnevdev:PGDBObjDevice;
        entvarext,delvarext:TVariablesExtender;
        PBH:PGDBObjBlockdef;
        t_matrix:DMatrix4D;
        ir2:itrec;
        pobj,pcobj:PGDBObjEntity;
  begin

      //ZCMsgCallBackInterface.TextMessage('addBlockonDraw DEVICE-' + dev^.Name,TMWOHistoryOut);

      dc:=drawings.GetCurrentDWG^.CreateDrawingRC;

      //добавляем определение блока HEAD_CONNECTIONDIAGRAM в чечтеж если надо
      drawings.GetCurrentDWG^.AddBlockFromDBIfNeed(velec_SchemaELDevInfo);

      //получаеи указатель на него
      PBH:=drawings.GetCurrentDWG^.BlockDefArray.getblockdef(velec_SchemaELDevInfo);

      //такого блок в библиотеке нет, водим
      //TODO: надо добавить ругань
      if pbh=nil then
          exit;
      if not (PBH^.Formated) then
          PBH^.FormatEntity(drawings.GetCurrentDWG^,dc);

      if dev <> nil then
         pointer(pnevdev):=dev^.Clone(@{drawings.GetCurrentROOT}root);

      //выставляем клону точку вставки, ориентируем по осям, вращаем
      pnevdev^.Local.P_insert:=currentcoord;


      //форматируем клон
      //TODO: убрать, форматировать клон надо в конце
      pnevdev^.formatEntity(drawings.GetCurrentDWG^,dc);

      //добавляем в чертеж
      drawings.GetCurrentDWG^.mainObjRoot.ObjArray.AddPEntity(pnevdev^);

      //ZCMsgCallBackInterface.TextMessage('DEVICE-' + dev^.Name,TMWOHistoryOut);
  end;

  //procedure addBlockNodeonDraw(var currentcoord:GDBVertex; var root:GDBObjRoot);
  //var
  //    datname:String;
  //    pv:pGDBObjDevice;
  //    //DC:TDrawContext;
  //    //lx,{rx,}uy,dy:Double;
  //      //c:integer;
  //      //pCentralVarext,pVarext:TVariablesExtender;
  //begin
  //    //addBlockonDraw(velec_beforeNameGlobalSchemaBlock + string(TVertexTree(G.Root.AsPointer[vpTVertexTree]^).dev^.Name),pt1,drawings.GetCurrentDWG^.mainObjRoot);
  //   ZCMsgCallBackInterface.TextMessage('addBlockNodeonDraw -',TMWOHistoryOut);
  //   datname:= velec_SchemaBlockJunctionBox;
  //
  //   drawings.AddBlockFromDBIfNeed(drawings.GetCurrentDWG,datname);
  //   pointer(pv):=old_ENTF_CreateBlockInsert(drawings.GetCurrentROOT,@{drawings.GetCurrentROOT}root.ObjArray,
  //                                       drawings.GetCurrentDWG^.GetCurrentLayer,drawings.GetCurrentDWG^.GetCurrentLType,sysvar.DWG.DWG_CColor^,sysvar.DWG.DWG_CLinew^,
  //                                       currentcoord, 1, 0,@datname[1]);
  //   //dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
  //   zcSetEntPropFromCurrentDrawingProp(pv);
  //
  //end;

      //рисуем прямоугольник с цветом  зная номера вершин, координат возьмем из графа по номерам
      procedure drawConnectLineDev(pSt,p1,p2,pEd:GDBVertex;VT1,VT2:TVertex; var root:GDBObjRoot);
      var
          //pDev1,pDev2:pGDBObjDevice;
          cableLine:PGDBObjPolyLine;
          //entvarext,delvarext:TVariablesExtender;
          //psu:ptunit;
          //pvd:pvardesk;
          //datname:String;
      begin
           cableLine:=GDBObjPolyline.CreateInstance;
           zcSetEntPropFromCurrentDrawingProp(cableLine);
           cableLine^.VertexArrayInOCS.PushBackData(pSt);
           cableLine^.VertexArrayInOCS.PushBackData(p1);
           cableLine^.VertexArrayInOCS.PushBackData(uzegeometry.CreateVertex(p2.x,p1.y,0));
           cableLine^.VertexArrayInOCS.PushBackData(p2);
           cableLine^.VertexArrayInOCS.PushBackData(pEd);
           zcAddEntToCurrentDrawingWithUndo(cableLine);
      end;
begin

    x:=0;
    y:=0;

    VertexPath:=TClassList.Create;
    listVertex:=TListVertex.Create;


    infoVertex.num:=G.Root.Index;
    infoVertex.vertex:=G.Root;
    infoVertex.poz:=uzegeometry.CreateVertex2D(x,0);
    infoVertex.kol:=0;
    infoVertex.childs:=G.Root.ChildCount;
    listVertex.PushBack(infoVertex);
    ptSt:=uzegeometry.CreateVertex(startPt.x + x*indent,startPt.y + y*indent,0);

    //ZCMsgCallBackInterface.TextMessage('ptSt.x -' + floattostr(ptSt.x) + ' ptSt.Y -' + floattostr(ptSt.Y),TMWOHistoryOut);
    //*********
    //ZCMsgCallBackInterface.TextMessage('root i -'+ inttostr(G.Root.Index),TMWOHistoryOut);
    //pvarv:=TVertexTree(G.Root.AsPointer[vpTVertexTree]^).dev^.specialize GetExtension<TVariablesExtender>;
    //ZCMsgCallBackInterface.TextMessage(string(TVertexTree(G.Root.AsPointer[vpTVertexTree]^).dev^.Name) + ' - '+ inttostr(G.Root.Index),TMWOHistoryOut);
    //pvv:=pvarv.entityunit.FindVariable('Name');
    //ZCMsgCallBackInterface.TextMessage('3'+ inttostr(G.Root.Index),TMWOHistoryOut);
    //if pvv<>nil then  begin
    //    ZCMsgCallBackInterface.TextMessage(pstring(pvv^.data.Addr.Instance)^ + ' - '+ inttostr(G.Root.Index),TMWOHistoryOut);
        //addBlockonDraw(TVertexTree(G.Root.AsPointer[vpTVertexTree]^).dev^);
        addBlockonDraw(listVertex.Back.vertex.getDevice,ptSt,drawings.GetCurrentDWG^.mainObjRoot);
    //end;
    //ZCMsgCallBackInterface.TextMessage('фин'+ inttostr(G.Root.Index),TMWOHistoryOut);
    //drawVertex(pt1,3,height);
    //*********

    //drawText(pt1,inttostr(G.Root.index),4);
    //ptext:=uzegeometry.CreateVertex(pt1.x,pt1.y + indent/10,0) ;
    //pt1.y+=indent/10;
     //G.Root.
    //iNum:=0;

    //********
    //drawMText(pt1,inttostr(iNum),4,0,height);
    //********

           //PGDBObjDevice(G.Root.AsPointer[vGPGDBObjDevice])^.P_insert_in_WCS;
    //*****drawMText(PTStructDeviceLine(G.Root.AsPointer[vGPGDBObjVertex])^.centerPoint,inttostr(G.Root.AsInt32[vGGIndex]),4,0,height);

    //drawMText(GGraph.listVertex[G.Root.AsInt32[vGGIndex]].centerPoint,inttostr(G.Root.AsInt32[vGGIndex]),4,0,height);
    //drawMText(GGraph.pt1,G.Root.AsString['infoVertex'],4,0,height);

    G.TreeTraversal(G.Root, VertexPath); //получаем путь обхода графа
    for i:=1 to VertexPath.Count - 1 do begin
        //ZCMsgCallBackInterface.TextMessage('VertexPath i -'+ inttostr(TVertex(VertexPath[i]).Parent.Index),TMWOHistoryOut);
        tParent:=howParent(listVertex,TVertex(VertexPath[i]).Parent.Index);
        //ZCMsgCallBackInterface.TextMessage('1/2',TMWOHistoryOut);
        if tParent>=0 then
        begin
          inc(listVertex.Mutable[tparent]^.kol);
          if listVertex[tparent].kol = 1 then begin
             infoVertex.poz:=uzegeometry.CreateVertex2D(listVertex[tparent].poz.x,listVertex[tparent].poz.y + 1) ;
             infoVertex.vertex:=TVertex(VertexPath[i]);
          end
          else  begin
            inc(x);
            infoVertex.poz:=uzegeometry.CreateVertex2D(x,listVertex[tparent].poz.y + 1);
            infoVertex.vertex:=TVertex(VertexPath[i]);
          end;

          infoVertex.num:=TVertex(VertexPath[i]).Index;
          infoVertex.kol:=0;
          infoVertex.childs:=TVertex(VertexPath[i]).ChildCount;
          listVertex.PushBack(infoVertex);

        //ZCMsgCallBackInterface.TextMessage('1',TMWOHistoryOut);
        ptEd:=uzegeometry.CreateVertex(startPt.x + listVertex.Back.poz.x*indent,startPt.y - listVertex.Back.poz.y*indent,0) ;
        //ZCMsgCallBackInterface.TextMessage('2',TMWOHistoryOut);
        //if listVertex.Back.vertex.getDevice<>nil then
        //   ZCMsgCallBackInterface.TextMessage('VertexPath i -'+ string(listVertex.Back.vertex.getDevice^.Name),TMWOHistoryOut);
         //ZCMsgCallBackInterface.TextMessage('3',TMWOHistoryOut);
        //*********
        if listVertex.Back.vertex.getDevice<>nil then  begin
           //ZCMsgCallBackInterface.TextMessage('-dev true-',TMWOHistoryOut);
           addBlockonDraw(listVertex.Back.vertex.getDevice,ptEd,drawings.GetCurrentDWG^.mainObjRoot)
        end
        else
        begin
           ZCMsgCallBackInterface.TextMessage('-dev false-',TMWOHistoryOut);
           //addBlockNodeonDraw(ptEd,drawings.GetCurrentDWG^.mainObjRoot);
        end;
         //ZCMsgCallBackInterface.TextMessage('4',TMWOHistoryOut);

        ptSt:=uzegeometry.CreateVertex(startPt.x + listVertex[tparent].poz.x*indent,startPt.y - listVertex[tparent].poz.y*indent,0) ;

        if listVertex[tparent].kol = 1 then
        begin
          pt1:=uzegeometry.CreateVertex(startPt.x + listVertex[tparent].poz.x*indent,startPt.y - listVertex[tparent].poz.y*indent-size,0) ;
          //pt2.x:=startPt.x + listVertex[tparent].poz.x*indent;
          //pt2.y:=startPt.y - listVertex[tparent].poz.y*indent-size;
          //pt2.z:=0;
        end
        else
        begin
          pt1:=uzegeometry.CreateVertex(startPt.x + listVertex[tparent].poz.x*indent + size,startPt.y - listVertex[tparent].poz.y*indent-size+(listVertex[tparent].kol-1)*((2*size)/listVertex[tparent].childs),0) ;
          //pt2.x:=startPt.x + listVertex[tparent].poz.x*indent + size;
          //pt2.y:=startPt.y - listVertex[tparent].poz.y*indent-size+(listVertex[tparent].kol-1)*((2*size)/listVertex[tparent].childs);
          //pt2.z:=0;
        end;

        pt2:=uzegeometry.CreateVertex(startPt.x + listVertex.Back.poz.x*indent,startPt.y - listVertex.Back.poz.y*indent+size,0) ;

        //******
        //ZCMsgCallBackInterface.TextMessage('5',TMWOHistoryOut);
        drawConnectLineDev(ptSt,pt1,pt2,ptEd,listVertex[tparent].vertex,listVertex.Back.vertex,drawings.GetCurrentDWG^.mainObjRoot);
        //ZCMsgCallBackInterface.TextMessage('6',TMWOHistoryOut);

        //******
        if depth>ptEd.y then
           depth:= ptEd.y;

        end;
     end;
    startPt.x:=startPt.x + (infoVertex.poz.x+1)*indent;

end;
function TSortTreeLengthComparer.Compare (vertex1, vertex2: Pointer): Integer;
var
  e1,e2:TAttrSet;
begin
   result:=0;
   e1:=TAttrSet(vertex1);
   e2:=TAttrSet(vertex2);

       //Edge1
   ZCMsgCallBackInterface.TextMessage(floattostr(e1.AsFloat32['lengthfromend']) + ' сравниваем ' + floattostr(e2.AsFloat32['lengthfromend']),TMWOHistoryOut);
   //   ZCMsgCallBackInterface.TextMessage(floattostr(e2.AsFloat32['length']) + '   ',TMWOHistoryOut);

   //e1.GetAsFloat32
   if e1.AsFloat32['lengthfromend'] <> e2.AsFloat32['lengthfromend'] then
     if e1.AsFloat32['lengthfromend'] > e2.AsFloat32['lengthfromend'] then
        result:=1
     else
        result:=-1;

   //тут e1 и e2 надо както сравнить по какомуто критерию и вернуть -1 0 1
   //в зависимости что чего меньше-больше
end;


function TDummyComparer.Compare (Edge1, Edge2: Pointer): Integer;
var
  e1,e2:TAttrSet;
begin
   result:=0;
   e1:=TAttrSet(Edge1);
   e2:=TAttrSet(Edge2);

   ZCMsgCallBackInterface.TextMessage('sssssssssssssss'+e1.ClassName,TMWOHistoryOut);
   //ZCMsgCallBackInterface.TextMessage('xxxxxxssssss'+e1.AsString['infoEdge'],TMWOHistoryOut);
       //Edge1
   //ZCMsgCallBackInterface.TextMessage(floattostr(e1.AsFloat32['tt']) + ' сравниваем ' + floattostr(e2.AsFloat32['tt']),TMWOHistoryOut);
   //   ZCMsgCallBackInterface.TextMessage(floattostr(e2.AsFloat32['length']) + '   ',TMWOHistoryOut);

   //e1.GetAsFloat32

   //if e1.ClassName; AsFloat32['lengthfrombegin'] <> nil then
   //  if e1.AsFloat32['lengthfrombegin'] > e2.AsFloat32['lengthfrombegin'] then
   //       result:=1
   //    else
   //       result:=-1;

   {if e1.AsFloat32['tt'] <> e2.AsFloat32['tt'] then
       if e1.AsFloat32['tt'] > e2.AsFloat32['tt'] then
          result:=1
       else
          result:=-1;}

   //тут e1 и e2 надо както сравнить по какомуто критерию и вернуть -1 0 1
   //в зависимости что чего меньше-больше
end;
function TDummyComparer.CompareEdges (Edge1, Edge2: Pointer): Integer;
var
  e1,e2:TAttrSet;
begin

   ////result:=1;
   //e1:=TAttrSet(Edge1);
   //e2:=TAttrSet(Edge2);
   //
   ZCMsgCallBackInterface.TextMessage('hhhhhhhhhhhhhhhhhhhhhhhttttttttttttttttttttt,,,,hj',TMWOHistoryOut);
   //ZCMsgCallBackInterface.TextMessage('xxxxxxssssss'+e1.AsString['infoEdge'],TMWOHistoryOut);
       //Edge1
   //ZCMsgCallBackInterface.TextMessage(floattostr(e1.AsFloat32['tt']) + ' сравниваем ' + floattostr(e2.AsFloat32['tt']),TMWOHistoryOut);
   //   ZCMsgCallBackInterface.TextMessage(floattostr(e2.AsFloat32['length']) + '   ',TMWOHistoryOut);

   //e1.GetAsFloat32

   //if e1.ClassName; AsFloat32['lengthfrombegin'] <> nil then
   //  if e1.AsFloat32['lengthfrombegin'] > e2.AsFloat32['lengthfrombegin'] then
   //       result:=1
   //    else
   //       result:=-1;

   {if e1.AsFloat32['tt'] <> e2.AsFloat32['tt'] then
       if e1.AsFloat32['tt'] > e2.AsFloat32['tt'] then
          result:=1
       else
          result:=-1;}

   //тут e1 и e2 надо както сравнить по какомуто критерию и вернуть -1 0 1
   //в зависимости что чего меньше-больше
   result:=cmd_ok;
end;


initialization
  DummyComparer:=TDummyComparer.Create;
  SortTreeLengthComparer:=TSortTreeLengthComparer.Create;
finalization
  DummyComparer.free;
  SortTreeLengthComparer.free;
end.
