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
@author(Andrey Zubarev <zamtmn@yandex.ru>)
}
{$MODE OBJFPC}{$H+}
unit gzundoCmdChgMethods2;
interface
uses
  zeundostack,zebaseundocommands;

type
  generic GUCmdChgMethods2<GDoData:class;GundoData> =class(TUCmdBase)
    private
      type
        TDoMethod=procedure(const data:GDoData)of object;
        TundoMethod=procedure(const data:GundoData)of object;
        TAfterUndoProc=procedure(const AUndoMethod:TMethod)of object;
      var
        DoData:GDoData;
        UndoData:GundoData;
        DoMethod,UnDoMethod:tmethod;
        AfterUndoProc:TAfterUndoProc;
        Commited:Boolean;
        procedure AfterDo;
    public
        constructor Create(const AData:GDoData;const AUndoData:GUndoData;ADoMethod,AUndoMethod:TMethod;const AAfterUndoProc:TAfterUndoProc;ACommited:Boolean=False);
        constructor CreateAndPush(const AData:GDoData;const AUndoData:GUndoData;ADoMethod,AUndoMethod:TMethod;var us:TZctnrVectorUndoCommands;const AAfterUndoProc:TAfterUndoProc;ACommited:Boolean=False);

        procedure UnDo;override;
        procedure Comit;override;
        destructor Destroy;override;
  end;

implementation

constructor GUCmdChgMethods2.CreateAndPush(const AData:GDoData;const AUndoData:GUndoData;ADoMethod,AUndoMethod:TMethod;var us:TZctnrVectorUndoCommands;const AAfterUndoProc:TAfterUndoProc;ACommited:Boolean=False);
begin
  Create(AData,AUndoData,ADoMethod,AUndoMethod,AAfterUndoProc,ACommited);
  us.PushBackData(self);
  inc(us.CurrentCommand);
end;

constructor GUCmdChgMethods2.Create(const AData:GDoData;const AUndoData:GUndoData;ADoMethod,AUndoMethod:TMethod;const AAfterUndoProc:TAfterUndoProc;ACommited:Boolean=False);
begin
  AfterUndoProc:=AAfterUndoProc;
  DoData:=AData;
  UndoData:=AUndoData;
  DoMethod:=ADoMethod;
  UndoMethod:=AUndoMethod;
  Commited:=ACommited;
end;

procedure GUCmdChgMethods2.UnDo;
begin
  {TUndoMethod(UnDoMethod)(UndoData);
  Commited:=not Commited;
  AfterDo;}
  Comit;
end;

procedure GUCmdChgMethods2.Comit;
begin
  if commited then
    TUndoMethod(UnDoMethod)(UndoData)
  else
    TDoMethod(DoMethod)(DoData);
  Commited:=not Commited;
  AfterDo;
end;

procedure GUCmdChgMethods2.AfterDo;
begin
  if assigned(AfterUndoProc) then
    AfterUndoProc(undomethod);
end;

destructor GUCmdChgMethods2.Destroy;
begin
  if not Commited then
    DoData.Destroy;
  inherited;
end;

end.
