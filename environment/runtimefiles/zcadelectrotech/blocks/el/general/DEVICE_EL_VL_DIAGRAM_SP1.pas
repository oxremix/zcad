unit DEVICE_EL_VL_DIAGRAM_SP1;

interface

uses system,devices;
usescopy blocktype;
usescopy objname;

var

T1:GDBString;(*'Этаж'*)

implementation

begin

BTY_TreeCoord:='PLAN_EM_Таблица';
Device_Type:=TDT_SilaPotr;
Device_Class:=TDC_Shell;

NMO_Name:='S0';
NMO_BaseName:='S1.';
NMO_Suffix:='??';

T1:='??';

end.