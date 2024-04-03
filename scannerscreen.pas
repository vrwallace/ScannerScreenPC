unit ScannerScreen;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RTTICtrls, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Menus, ColorBox, synaser, ComObj,
  INIFiles, lclintf, Grids, codes2, shlobj, Windows;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Buttonconnecttoscanner: TButton;
    Buttondisconnectfromscanner: TButton;
    CheckBoxwindowflash: TCheckBox;
    CheckBoxlogdata: TCheckBox;
    CheckBoxtexttospeech: TCheckBox;
    CheckBoxstayontop: TCheckBox;
    ColorBoxwindow: TColorBox;
    ColorBoxfont: TColorBox;
    ComboBoxScanner: TComboBox;
    ComboBoxcomport: TComboBox;
    Editlogdir: TEdit;
    GroupBoxSettings: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Labelfontheight: TLabel;
    LabelRate: TLabel;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MilitaryTimemenu: TMenuItem;
    MenuItemclearlog: TMenuItem;
    MenuItemSettingsPanel: TMenuItem;
    MenuItemcodes: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItemRealTimeGrid: TMenuItem;
    MenuItemAbout: TMenuItem;
    MenuItemDonate: TMenuItem;
    MenuItemSaveSettings: TMenuItem;
    PopupMenu1: TPopupMenu;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    statictexttime: TStaticText;
    StaticTextsystemname: TStaticText;
    StaticTextdepartmentname: TStaticText;
    StaticTextchannelname: TStaticText;
    StaticTextFreq: TStaticText;
    StringGridRealTimeGrid: TStringGrid;
    Timerprobescanner: TTimer;
    TimerClock: TTimer;
    TrackBarfontheight: TTrackBar;
    TrackBarRate: TTrackBar;

    procedure Button1Click(Sender: TObject);
    procedure ButtonconnecttoscannerClick(Sender: TObject);
    procedure ButtondisconnectfromscannerClick(Sender: TObject);
    procedure CheckBoxlogdataChange(Sender: TObject);
    procedure CheckBoxstayontopChange(Sender: TObject);
    procedure ColorBoxwindowChange(Sender: TObject);
    procedure ColorBoxfontChange(Sender: TObject);
    procedure ComboBoxcomportDropDown(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItemAboutClick(Sender: TObject);
    procedure MenuItemclearlogClick(Sender: TObject);
    procedure MenuItemcodesClick(Sender: TObject);
    procedure MenuItemDonateClick(Sender: TObject);
    procedure MenuItemRealTimeGridClick(Sender: TObject);
    procedure MenuItemSaveSettingsClick(Sender: TObject);
    procedure MenuItemSettingsPanelClick(Sender: TObject);
    procedure MenuItemShowSettingsClick(Sender: TObject);
    procedure MenuItemHideSettingsClick(Sender: TObject);

    procedure TimerprobescannerTimer(Sender: TObject);
    procedure DumpExceptionCallStack(E: Exception);
    procedure TimerClockTimer(Sender: TObject);
    procedure TrackBarfontheightChange(Sender: TObject);
    procedure TrackBarRateChange(Sender: TObject);
    function checksum(s: string): integer;
    function RemoveLeadingZeros(const Frequency: string): string;
    function GetTimeFormat: string;
  private
    { private declarations }
    StartTime: TDateTime;
    EndTime: TDateTime;
  public
    { public declarations }
    ser: TBlockSerial;

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }



procedure TForm1.TimerprobescannerTimer(Sender: TObject);
var
  Duration: TDateTime;
  rawmessage, modulation, systemname, departmentname, channelname, freq: string;
  glgs: TStringList;
  SpVoice: variant;
  readtext: string;

  SavedCW: word;
  FileLogfile: Textfile;
  PersonalPath: array[0..MaxPathLen] of char; //Allocate memory
  logfilepath: string;
  RTGstring: string;
  cmd: string;
  TimeFormat: string;
begin
  if comboboxscanner.Text = 'HP-1' then
  begin
    cmd := 'RMT' + #9 + 'STATUS' + #9;
    cmd := cmd + IntToStr(checksum(cmd)) + #13#10;
  end
  else
    cmd := 'GLG' + #13#10;

  try
    try

      //ser := TBlockSerial.Create;

      //ser.ConvertLineEnd := True;

      //ser.Connect(trim(comboboxcomport.Text));

      ////ser.Connect('/dev/tty.usbmodem1421');

      //ser.config(115200, 8, 'N', 0, False, False);
      ser.CanWrite(4000);
      ser.sendstring(cmd);
      if (ser.LastError <> 0) then
      begin

        memo1.Clear;
        memo1.Lines.Add('I/O Error');
        StaticTextFreq.Caption := ser.LastErrorDesc;
        StaticTextsystemname.Caption :=
          'Disconnect cable, restart scanner and try again.';

        StaticTextdepartmentname.Caption := ' ';
        StaticTextchannelname.Caption := ' ';
        Timerprobescanner.Enabled := False;
        ser.CloseSocket;
        Buttondisconnectfromscanner.Enabled := False;
        Buttonconnecttoscanner.Enabled := True;
        comboboxcomport.Enabled := True;
        comboboxscanner.Enabled := True;
        Exit;

      end;
      if ser.canread(4000) then
      begin
        rawmessage := ser.Recvstring(4000);
      end
      else
      begin
        memo1.Clear;
        memo1.Lines.Add('Cannot read device');
        StaticTextFreq.Caption := 'Cannot read device';
        StaticTextsystemname.Caption := ' ';
        StaticTextdepartmentname.Caption := ' ';
        StaticTextchannelname.Caption := ' ';
        Timerprobescanner.Enabled := False;
        ser.CloseSocket;
        Buttondisconnectfromscanner.Enabled := False;
        Buttonconnecttoscanner.Enabled := True;
        comboboxcomport.Enabled := True;
        comboboxscanner.Enabled := True;

        exit;
      end;
    finally
      // ser.Free;

    end;

    if ((pos('GLG,,,,,', rawmessage) > 0) or
      (pos('RMT' + #9 + 'STATUS' + #9 + #9 + #9, rawmessage) > 0)) then
    begin
      memo1.Clear;
      memo1.Lines.Add('Scanning or idle');
      StaticTextFreq.Caption := 'Scanning or idle';
      StaticTextsystemname.Caption := ' ';
      StaticTextdepartmentname.Caption := ' ';
      StaticTextchannelname.Caption := ' ';
      exit;
    end;

    if (((pos('GLG', rawmessage) > 0) and (pos(',', rawmessage) > 0)) or
      (pos('RMT' + #9 + 'STATUS' + #9, rawmessage) > 0)) then
    begin
      memo1.Clear;
      memo1.Lines.Add(rawmessage);
      try
        GLGS := TStringList.Create;
        if comboboxscanner.Text = 'HP-1' then
          glgs.Delimiter := #9
        else
          glgs.Delimiter := ',';

        glgs.StrictDelimiter := True;
        glgs.DelimitedText := rawmessage;

        if glgs.Count > 7 then
        begin
          if CheckBoxwindowflash.Checked = True then
            flashwindow(form1.Handle, True);

          if comboboxscanner.Text = 'HP-1' then
          begin
            freq := trim(glgs.ValueFromIndex[2]);
            modulation := trim(glgs.ValueFromIndex[3]);
            systemname := trim(glgs.ValueFromIndex[8]);
            departmentname := trim(glgs.ValueFromIndex[9]);
            Channelname := trim(glgs.ValueFromIndex[10]);

          end
          else
          begin
            freq := trim(glgs.ValueFromIndex[1]);
            modulation := trim(glgs.ValueFromIndex[2]);
            systemname := trim(glgs.ValueFromIndex[5]);
            departmentname := trim(glgs.ValueFromIndex[6]);
            Channelname := trim(glgs.ValueFromIndex[7]);
          end;



          if ((StaticTextchannelname.Caption <> channelname) or
            (StaticTextdepartmentname.Caption <> departmentname) or
            (StaticTextsystemname.Caption <> systemname) or
            (StaticTextFreq.Caption <> freq + ' (' + modulation + ')')) then
          begin
            StartTime := Now;
            StaticTextFreq.Caption := freq + ' (' + modulation + ')';
            StaticTextsystemname.Caption := systemname;
            StaticTextdepartmentname.Caption := departmentname;
            StaticTextchannelname.Caption := channelname;
            //realtimegrid start
            try
              if StringGridRealTimeGrid.Visible then
              begin
                if StringGridRealTimeGrid.RowCount > 9999 then
                begin
                  StringGridRealTimeGrid.DeleteRow
                  (StringGridRealTimeGrid.RowCount - 1);
                end;
                TimeFormat := GetTimeFormat;
                rtgstring := FormatDateTime(TimeFormat, now) + ' ' +
                  FormatDateTime('dd mmm yyyy', now) + #13#10 + freq +
                  #13#10 + modulation + #13#10 + systemname + #13#10 +
                  departmentname + #13#10 + channelname;


                StringGridRealTimeGrid.InsertColRow(False, 1);
                StringGridRealTimeGrid.RowS[1].Text := rtgstring;

              end;
            except
              on E: Exception do
              begin
                DumpExceptionCallStack(E);
              end;
            end;
            //realtimegrid end
            //write data start
            if checkboxlogdata.Checked then
            begin
              logfilepath := editlogdir.text;
              if trim(logfilepath)='' then begin
                checkboxlogdata.checked:=false;
                exit;
              end;


              try

                if not directoryexists(logfilepath) then
                  forcedirectories(logfilepath);
                logfilepath :=
                  logfilepath + '\SS' + trim(FormatDateTime('YYYYMMDD', NOW)) + '.TXT';



                if not fileexists(logfilepath) then
                begin

                  TimeFormat := GetTimeFormat;
                  AssignFile(FileLogfile, logfilepath);
                  rewrite(FileLogfile);
                  writeln(FileLogfile, FormatDateTime(TimeFormat, now) +
                    ' ' + FormatDateTime('dd mmm yyyy', now) + #9 +
                    freq + #9 + modulation + #9 + systemname + #9 +
                    departmentname + #9 + channelname);
                  CloseFile(FileLogfile);

                end
                else
                begin

                  TimeFormat := GetTimeFormat;
                  AssignFile(FileLogfile, logfilepath);
                  append(FileLogfile);
                  writeln(FileLogfile, FormatDateTime(TimeFormat, now) +
                    ' ' + FormatDateTime('dd mmm yyyy', now) + #9 +
                    freq + #9 + modulation + #9 + systemname + #9 +
                    departmentname + #9 + channelname);
                  CloseFile(FileLogfile);
                end;
              except
                on E: EInOutError do
                begin
                  checkboxlogdata.Checked := False;
                  ShowMessage('File handling error occurred, logging will be disabled. Details: '
                    + E.ClassName + '/' + E.Message + ' (' + logfilepath + ')');

                end;
              end;
            end;

            //write data end

            //mac speech strart
            if CheckBoxtexttospeech.Checked = True then
            begin
              try
                SpVoice := CreateOleObject('SAPI.SpVoice');
                // Change FPU interrupt mask to avoid SIGFPE exceptions
                SavedCW := Get8087CW;


                if channelname + DEPARTMENTNAME <> '' then
                begin
                  if pos(departmentname, channelname) > 0 then
                  begin
                    READTEXT := WideString(channelname);
                  end
                  else
                    READTEXT := WideString(DEPARTMENTNAME + ' ' + channelname);
                end
                else
                  READTEXT := WideString(RemoveLeadingZeros(freq) +
                    ' ' + modulation + ' ' + systemname);



                try
                  Set8087CW(SavedCW or $1 or $2 or $4 or $8 or $16 or $32);
                  form1.Refresh;
                  spvoice.Rate := TrackBarRate.position;
                  SpVoice.Speak(READTEXT, 1);

                  repeat
                    application.ProcessMessages;
                  until SpVoice.WaitUntilDone(10);

                finally
                  // Restore FPU mask
                  Set8087CW(SavedCW);
                end;
              finally
                spvoice := nil;
              end;
            end;
            //mac speech end

          end;
          EndTime := Now;
          Duration := EndTime - StartTime;
        end
        else
        begin
          memo1.Clear;
          memo1.Lines.Add('Return data too small');
          StaticTextFreq.Caption := 'Return data too small';
          StaticTextsystemname.Caption := ' ';
          StaticTextdepartmentname.Caption := ' ';
          StaticTextchannelname.Caption := ' ';
          exit;
        end;
      finally
        glgs.Free;
      end;

    end
    else
    begin
      memo1.Clear;
      memo1.Lines.Add('Data Error');
      StaticTextFreq.Caption := 'Data Error';
      StaticTextsystemname.Caption := ' ';
      StaticTextdepartmentname.Caption := ' ';
      StaticTextchannelname.Caption := ' ';
      exit;
    end;


  except
    on E: Exception do
    begin
      Timerprobescanner.Enabled := False;
      Buttondisconnectfromscanner.Enabled := False;
      Buttonconnecttoscanner.Enabled := True;
      comboboxcomport.Enabled := True;
      comboboxscanner.Enabled := True;
      memo1.Clear;
      memo1.Lines.Add('Program exception occured');
      StaticTextFreq.Caption := 'Program exception occured';
      StaticTextsystemname.Caption :=
        'Restart program';
      StaticTextdepartmentname.Caption := ' ';
      StaticTextchannelname.Caption := ' ';

      DumpExceptionCallStack(E);
    end;
  end;

end;

procedure TForm1.ButtondisconnectfromscannerClick(Sender: TObject);
begin
  Timerprobescanner.Enabled := False;
  Buttondisconnectfromscanner.Enabled := False;
  Buttonconnecttoscanner.Enabled := True;
  comboboxcomport.Enabled := True;
  comboboxscanner.Enabled := True;
  memo1.Clear;

  StaticTextFreq.Caption := ' ';
  StaticTextsystemname.Caption := ' ';
  StaticTextdepartmentname.Caption := ' ';
  StaticTextchannelname.Caption := ' ';
  ser.closesocket;
end;

procedure TForm1.CheckBoxlogdataChange(Sender: TObject);
begin
  if (checkboxlogdata.checked) then begin
  if not directoryexists(editlogdir.text) then begin
    showmessage('Select Log Directory');
    checkboxlogdata.checked:=false;
    end;
  end;

end;

procedure TForm1.CheckBoxstayontopChange(Sender: TObject);
begin
  if checkboxstayontop.Checked = True then
    form1.FormStyle := fsSystemStayOnTop
  else
    form1.FormStyle := fsnormal;
end;

procedure TForm1.ColorBoxwindowChange(Sender: TObject);
begin
  form1.color := ColorBoxwindow.Selected;
  StringGridRealTimeGrid.color := ColorBoxwindow.Selected;
  form1.refresh;
end;

procedure TForm1.ColorBoxfontChange(Sender: TObject);
begin
  statictexttime.Font.color := ColorBoxfont.selected;
  statictextfreq.Font.color := ColorBoxfont.selected;
  statictextsystemname.font.color := ColorBoxfont.selected;
  statictextdepartmentname.Font.color := ColorBoxfont.selected;
  statictextchannelname.Font.color := ColorBoxfont.selected;
  StringGridRealTimeGrid.Font.Color := ColorBoxfont.selected;
  form1.refresh;
end;




procedure TForm1.ComboBoxcomportDropDown(Sender: TObject);
begin
  comboboxcomport.Clear;

  comboboxcomport.Items.CommaText := GetSerialPortNames();
end;



procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := True;
  try
    timerprobescanner.Enabled := False;
    timerclock.Enabled := False;
    if Assigned(ser) then
    begin
      ser.Free;
      ser := nil;
    end;
  except
    on E: Exception do
    begin
      CanClose := False;
      MessageDlg('An error occurred while closing the application. Please try again.',
        mtError, [mbOK], 0);
      // Log the exception details to a file or a centralized logging system
      // Example: LogException(E);
    end;
  end;
end;




procedure TForm1.FormCreate(Sender: TObject);
var
  c: TGRIDColumn;
begin

  // add a custom column a grid

  c := StringGridRealTimeGrid.Columns.Add;
  c.title.Caption := 'TIME DATE';       // Set columns caption
  c.Index := 0;

  c := StringGridRealTimeGrid.Columns.Add;
  c.title.Caption := 'FREQ/TGID';       // Set columns caption
  c.Index := 1;

  c := StringGridRealTimeGrid.Columns.Add;
  c.title.Caption := 'MODULATION';       // Set columns caption
  c.Index := 2;

  c := StringGridRealTimeGrid.Columns.Add;
  c.title.Caption := 'SYSTEM';       // Set columns caption
  c.Index := 3;

  c := StringGridRealTimeGrid.Columns.Add;
  c.title.Caption := 'DEPARTMENT';       // Set columns caption
  c.Index := 4;

  c := StringGridRealTimeGrid.Columns.Add;
  c.title.Caption := 'CHANNEL';       // Set columns caption
  c.Index := 5;



  statictexttime.Font.size := trackbarfontheight.position;
  statictextfreq.Font.size := trackbarfontheight.position;
  statictextsystemname.font.size := trackbarfontheight.position;
  statictextdepartmentname.Font.size := trackbarfontheight.position;
  statictextchannelname.Font.size := trackbarfontheight.position;
  labelfontheight.Caption := '(' + IntToStr(trackbarfontheight.position) + ')';
  labelrate.Caption := '(' + IntToStr(trackbarrate.position) + ')';

  ser := TBlockSerial.Create;

end;

procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  OpenURL('https://vonwallace.com');
end;




procedure TForm1.MenuItemAboutClick(Sender: TObject);
begin
  ShowMessage('Program by: Von Wallace' + #13#10 + 'Email: vonwallace@yahoo.com' +
    #13#10 + #13#10 + 'Thank you radioreference.com forum users, for your input.' +
    #13#10 + #13#10 + 'Please Donate');

end;

procedure TForm1.MenuItemclearlogClick(Sender: TObject);
begin
  StringGridRealTimeGrid.RowCount := 1;
end;

procedure TForm1.MenuItemcodesClick(Sender: TObject);
begin
  FORMCODES.SHOWONTOP;
end;



procedure TForm1.MenuItemDonateClick(Sender: TObject);
begin

  try
    OpenURL('https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=H8RE5W4PCPZBW');

  except
    on E: Exception do
      DumpExceptionCallStack(E);
  end;

end;

procedure TForm1.MenuItemRealTimeGridClick(Sender: TObject);
begin
  if MenuItemRealTimeGrid.Checked then
    StringGridRealTimeGrid.Visible := True
  else
  begin
    StringGridRealTimeGrid.Visible := False;
    StringGridRealTimeGrid.RowCount := 1;
  end;
end;




procedure TForm1.MenuItemSaveSettingsClick(Sender: TObject);
var
  INI: TINIFile;
  converteddevicename: string;
begin

  try
    if ComboBoxcomport.ItemIndex = -1 then
    begin
      ShowMessage('Select Device!');
      exit;
    end;

    if ComboBoxscanner.ItemIndex = -1 then
    begin
      ShowMessage('Select correct Scanner!');
      exit;
    end;


    try

      converteddevicename := stringreplace(comboboxcomport.Text, '/',
        '_', [rfReplaceAll]);


      if not directoryexists(getappconfigdir(False)) then
        forcedirectories(getappconfigdir(False));

      INI := TINIFile.Create(getappconfigdir(False) + converteddevicename +
        stringreplace(comboboxscanner.Text, '/', '_', [rfReplaceAll]) + '.ini');
      ini.WriteString('config', 'comport', comboboxcomport.Text);
      ini.WriteString('config', 'Scanner', comboboxscanner.Text);
      ini.WriteString('config', 'logdir', editlogdir.text);


      ini.Writebool('config', 'TTSEnable', CheckBoxtexttospeech.Checked);
      ini.writeinteger('config', 'TTSRate', TrackBarRate.Position);
      ini.Writeinteger('config', 'FontHeight', TrackBarfontheight.Position);
      ini.Writebool('config', 'WindowOnTop', CheckBoxstayontop.Checked);
      ini.Writebool('config', 'WindowFlash', CheckBoxwindowflash.Checked);


      ini.WriteString('config', 'WindowColor', ColorBoxwindow.Text);
      ini.WriteString('config', 'FontColor', ColorBoxfont.Text);
      ini.writeinteger('config', 'WindowHeight', form1.Height);
      ini.writeinteger('config', 'WindowWidth', form1.Width);
      ini.Writebool('config', 'SettingsShow', GroupBoxSettings.Visible);
      ini.Writebool('config', 'RealTimeGridShow', StringGridRealTimeGrid.Visible);
      ini.Writebool('config', 'MilitaryTimeShow', MilitaryTimemenu.Checked);



      ini.Writeinteger('config', 'RealTimeGridcol_0',
        StringGridRealTimeGrid.ColWidths[0]);
      ini.Writeinteger('config', 'RealTimeGridcol_1',
        StringGridRealTimeGrid.ColWidths[1]);
      ini.Writeinteger('config', 'RealTimeGridcol_2',
        StringGridRealTimeGrid.ColWidths[2]);
      ini.Writeinteger('config', 'RealTimeGridcol_3',
        StringGridRealTimeGrid.ColWidths[3]);
      ini.Writeinteger('config', 'RealTimeGridcol_4',
        StringGridRealTimeGrid.ColWidths[4]);
      ini.Writeinteger('config', 'RealTimeGridcol_5',
        StringGridRealTimeGrid.ColWidths[5]);




      ini.Writebool('config', 'LogData', CheckBoxlogdata.Checked);

      ShowMessage(
        'Settings saved, next time you start program and select same device and connect to scanner settings will be loaded if requested.');
    finally
      Ini.Free;
    end;
  except
    on E: Exception do
    begin
      DumpExceptionCallStack(E);
    end;
  end;
end;

procedure TForm1.MenuItemSettingsPanelClick(Sender: TObject);
begin
  if MenuItemsettingspanel.Checked then
    groupboxsettings.Visible := True
  else
    groupboxsettings.Visible := False;
end;



procedure TForm1.MenuItemShowSettingsClick(Sender: TObject);
begin
  groupboxsettings.Visible := True;
end;

procedure TForm1.MenuItemHideSettingsClick(Sender: TObject);
begin
  groupboxsettings.Visible := False;
end;



procedure TForm1.ButtonconnecttoscannerClick(Sender: TObject);
var
  INI: TINIFile;
  converteddevicename: string;
  PersonalPath: array[0..MaxPathLen] of char;
begin
  try
    if ComboBoxcomport.ItemIndex = -1 then
    begin
      ShowMessage('Select Device!');
      exit;
    end;

    if ComboBoxscanner.ItemIndex = -1 then
    begin
      ShowMessage('Select correct Scanner!');
      exit;
    end;


    ser.ConvertLineEnd := True;

    ser.Connect(trim(comboboxcomport.Text));

    ser.config(115200, 8, 'N', 0, False, False);

    if not directoryexists(getappconfigdir(False)) then
      forcedirectories(getappconfigdir(False));

    converteddevicename := stringreplace(comboboxcomport.Text, '/', '_', [rfReplaceAll]);

    if fileexists(getappconfigdir(False) + converteddevicename +
      stringreplace(comboboxscanner.Text, '/', '_', [rfReplaceAll]) + '.ini') then
    begin

      if MessageDlg('', 'Load saved settings?', mtConfirmation, [mbYes, mbNo], 0) =
        mrYes then
        { Execute rest of Program }
      begin
        try

          INI := TINIFile.Create(getappconfigdir(False) + converteddevicename +
            stringreplace(comboboxscanner.Text, '/', '_', [rfReplaceAll]) + '.ini');

          if groupbox3.Visible then
            CheckBoxtexttospeech.Checked :=
              ini.readbool('config', 'TTSEnable', CheckBoxtexttospeech.Checked);
          TrackBarRate.Position :=
            ini.ReadInteger('config', 'TTSRate', TrackBarRate.Position);
          TrackBarfontheight.Position :=
            ini.ReadInteger('config', 'FontHeight', TrackBarfontheight.Position);
          CheckBoxstayontop.Checked :=
            ini.readbool('config', 'WindowOnTop', CheckBoxstayontop.Checked);


          CheckBoxwindowflash.Checked :=
            ini.Readbool('config', 'WindowFlash', CheckBoxwindowflash.Checked);


          // CheckBoxstayontop.Checked :=
          //ini.readbool('config', 'WindowOnTop', CheckBoxstayontop.Checked);

          ColorBoxwindow.Text :=
            ini.ReadString('config', 'WindowColor', ColorBoxwindow.Text);
          form1.color := ColorBoxwindow.Selected;

           PersonalPath := '';
             SHGetSpecialFolderPath(0, PersonalPath, CSIDL_PERSONAL, False);
          editlogdir.text :=ini.ReadString('config', 'logdir', personalpath+'\scannerscreenlog');

          StringGridRealTimeGrid.color := ColorBoxwindow.Selected;

          ColorBoxfont.Text :=
            ini.ReadString('config', 'FontColor', ColorBoxfont.Text);
          StringGridRealTimeGrid.font.color := ColorBoxfont.selected;
          statictexttime.Font.color := ColorBoxfont.selected;
          statictextfreq.Font.color := ColorBoxfont.selected;
          statictextsystemname.font.color := ColorBoxfont.selected;
          statictextdepartmentname.Font.color := ColorBoxfont.selected;
          statictextchannelname.Font.color := ColorBoxfont.selected;

          form1.Height := ini.readinteger('config', 'WindowHeight', form1.Height);
          form1.Width := ini.readinteger('config', 'WindowWidth', form1.Width);




          GroupBoxSettings.Visible :=
            ini.readbool('config', 'SettingsShow', GroupBoxSettings.Visible);
          MenuItemSettingsPanel.Checked :=
            ini.readbool('config', 'SettingsShow', GroupBoxSettings.Visible);

          StringGridRealTimeGrid.Visible :=
            ini.readbool('config', 'RealTimeGridShow', StringGridRealTimeGrid.Visible);
          MenuItemRealTimeGrid.Checked :=
            ini.readbool('config', 'RealTimeGridShow', StringGridRealTimeGrid.Visible);
          MilitaryTimemenu.Checked :=
            ini.readbool('config', 'MilitaryTimeshow', MilitaryTimemenu.Checked);


          StringGridRealTimeGrid.ColWidths[0] :=
            ini.readinteger('config', 'RealTimeGridcol_0',
            StringGridRealTimeGrid.ColWidths[0]);
          StringGridRealTimeGrid.ColWidths[1] :=
            ini.readinteger('config', 'RealTimeGridcol_1',
            StringGridRealTimeGrid.ColWidths[1]);
          StringGridRealTimeGrid.ColWidths[2] :=
            ini.readinteger('config', 'RealTimeGridcol_2',
            StringGridRealTimeGrid.ColWidths[2]);
          StringGridRealTimeGrid.ColWidths[3] :=
            ini.readinteger('config', 'RealTimeGridcol_3',
            StringGridRealTimeGrid.ColWidths[3]);
          StringGridRealTimeGrid.ColWidths[4] :=
            ini.readinteger('config', 'RealTimeGridcol_4',
            StringGridRealTimeGrid.ColWidths[4]);
          StringGridRealTimeGrid.ColWidths[5] :=
            ini.readinteger('config', 'RealTimeGridcol_5',
            StringGridRealTimeGrid.ColWidths[5]);



          CheckBoxlogdata.Checked :=
            ini.readbool('config', 'LogData', CheckBoxlogdata.Checked);

        finally
          ini.Free;
        end;
      end;
    end;


    Timerprobescanner.Enabled := True;
    Buttondisconnectfromscanner.Enabled := True;
    Buttonconnecttoscanner.Enabled := False;
    comboboxcomport.Enabled := False;
    comboboxscanner.Enabled := False;



  except
    on E: Exception do
    begin
      DumpExceptionCallStack(E);

    end;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);



var
  SelectDirectoryDialog: TSelectDirectoryDialog;
  SelectedDir: string;

begin
  SelectDirectoryDialog := TSelectDirectoryDialog.Create(nil);
  try
    SelectDirectoryDialog.Title := 'Select a directory';
    SelectDirectoryDialog.Options := [ofEnableSizing, ofViewDetail];

    if SelectDirectoryDialog.Execute then
    begin
      SelectedDir := SelectDirectoryDialog.FileName;
      editlogdir.text:=SelectedDir;
      //WriteLn('Selected directory: ', SelectedDir);
    end
    else
    begin
      //WriteLn('No directory selected.');
    end;
  finally
    SelectDirectoryDialog.Free;
  end;

  //ReadLn; // Wait for user input before closing the console
end;



procedure TForm1.DumpExceptionCallStack(E: Exception);
var
  I: integer;
  Frames: PPointer;
  Report: string;
begin

  Report := 'Program exception! ' + LineEnding + 'Stacktrace:' +
    LineEnding + LineEnding;
  if E <> nil then
  begin
    Report := Report + 'Exception class: ' + E.ClassName + LineEnding +
      'Message: ' + E.Message + LineEnding;
  end;
  Report := Report + BackTraceStrFunc(ExceptAddr);
  Frames := ExceptFrames;
  for I := 0 to ExceptFrameCount - 1 do
    Report := Report + LineEnding + BackTraceStrFunc(Frames[I]);
  ShowMessage(Report);
  //Halt; // End of program execution
end;

procedure TForm1.TimerClockTimer(Sender: TObject);
var
  ThisMoment: TDateTime;
  TimeFormat: string;
begin
  ThisMoment := Now;
  TimeFormat := GetTimeFormat;
  statictexttime.Caption := FormatDateTime(TimeFormat, ThisMoment) +
    ' ' + FormatDateTime('dd mmm yyyy', ThisMoment);
end;

procedure TForm1.TrackBarfontheightChange(Sender: TObject);
begin
  statictexttime.Font.size := trackbarfontheight.position;

  statictextfreq.Font.size := trackbarfontheight.position;
  statictextsystemname.font.size := trackbarfontheight.position;
  statictextdepartmentname.Font.size := trackbarfontheight.position;
  statictextchannelname.Font.size := trackbarfontheight.position;
  labelfontheight.Caption := '(' + IntToStr(trackbarfontheight.position) + ')';
end;

procedure TForm1.TrackBarRateChange(Sender: TObject);
begin
  labelrate.Caption := '(' + IntToStr(trackbarrate.position) + ')';
end;

function tform1.checksum(s: string): integer;
var
  i: integer;
  sum: integer;
begin
  sum := 0;
  for i := 1 to length(s) do

  begin
    sum := sum + Ord(s[i]);
  end;

  checksum := sum;

end;

function TForm1.RemoveLeadingZeros(const Frequency: string): string;
var
  i: integer;
begin
  i := 1;
  while (i <= Length(Frequency)) and (Frequency[i] = '0') do
    Inc(i);
  Result := Copy(Frequency, i, Length(Frequency) - i + 1);
  if Result = '' then
    Result := '0';
end;

function TForm1.GetTimeFormat: string;
begin
  if MilitaryTimemenu.Checked then
    Result := 'HH:nn:ss'
  else
    Result := 'h:nn:ss AM/PM';
end;


end.
