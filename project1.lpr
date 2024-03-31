program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, ScannerScreen, runtimetypeinfocontrols,
  laz_synapse, codes2;

{$R *.res}

begin
  Application.Title:='Scanner Screen';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormcodes, Formcodes);
  Application.Run;
end.

