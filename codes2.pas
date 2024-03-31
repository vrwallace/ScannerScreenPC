unit codes2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  htmlview;

type

  { TFormcodes }

  TFormcodes = class(TForm)
    HTMLViewer1: THTMLViewer;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Formcodes: TFormcodes;

implementation

{$R *.lfm}

{ TFormcodes }

procedure TFormcodes.FormCreate(Sender: TObject);
begin
  formcodes.Height := 600;
  formcodes.Width := 800;
  HTMLViewer1.LoadFromString(memo1.Text);
end;

end.

