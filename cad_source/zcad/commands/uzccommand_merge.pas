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

unit uzccommand_merge;
{$INCLUDE zengineconfig.inc}

interface
uses
  uzcLog,
  uzbpaths,uzbtypes,

  uzeffmanager,
  uzccommand_DWGNew,
  uzccmdload,
  uzccommandsimpl,uzccommandsabstract;

function Merge_com(operands:TCommandOperands):TCommandResult;

implementation

function Merge_com(operands:TCommandOperands):TCommandResult;
begin
  result:=Load_merge(operands,TLOMerge);
end;

procedure startup;
begin
  CreateCommandFastObjectPlugin(@Merge_com,'Merge',CADWG,0);
end;
procedure finalize;
begin
end;
initialization
  programlog.LogOutFormatStr('Unit "%s" initialization',[{$INCLUDE %FILE%}],LM_Info,UnitsInitializeLMId);
  startup;
finalization
  ProgramLog.LogOutFormatStr('Unit "%s" finalization',[{$INCLUDE %FILE%}],LM_Info,UnitsFinalizeLMId);
  finalize;
end.
