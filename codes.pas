unit Codes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  htmlview;

type

  { TFormCodes }

  TFormCodes = class(TForm)
    HTMLViewer1: THTMLViewer;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FormCodes: TFormCodes;

implementation

{$R *.lfm}

{ TFormCodes }

procedure TFormCodes.FormActivate(Sender: TObject);
begin

end;

procedure TFormCodes.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //CloseAction:= caFree;
end;

procedure TFormCodes.FormCreate(Sender: TObject);
begin
  formcodes.Height := 600;
  formcodes.Width := 800;
  HTMLViewer1.LoadFromString(memo1.Text);
end;

end.
