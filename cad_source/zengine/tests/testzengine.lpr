program testzengine;

{$mode objfpc}{$H+}

uses
  //MemCheck,
  Classes, consoletestrunner,
  Logtest,BoundaryPathSimpletest;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.
