unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Menus, FMX.Layouts, FMX.TreeView,
  FMX.Objects, FMX.ExtCtrls, System.ImageList, FMX.ImgList, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FMX.Bind.GenData, System.Rtti, System.Bindings.Outputs, FMX.Bind.Editors,
  Data.Bind.EngExt, FMX.Bind.DBEngExt, Data.Bind.Components,
  Data.Bind.ObjectScope, Data.Bind.GenData, FMX.ListBox, System.Actions,
  FMX.ActnList, FMX.StdActns, Thumbnails;

type
  TForm1 = class(TForm)
    TreeView1: TTreeView;
    PopupMenu1: TPopupMenu;
    StatusBar1: TStatusBar;
    Panel1: TPanel;
    TrackBar1: TTrackBar;
    Panel2: TPanel;
    FramedVertScrollBox1: TFramedVertScrollBox;
    StyleBook1: TStyleBook;
    Image2: TImage;
    Label1: TLabel;
    ProgressBar1: TProgressBar;
    MenuItem2: TMenuItem;
    MenuItem1: TMenuItem;
    MainMenu1: TMainMenu;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    ActionList1: TActionList;
    Action1: TAction;
    FileHideAppOthers1: TFileHideAppOthers;
    FileExit1: TFileExit;
    MenuItem7: TMenuItem;
    Action2: TAction;
    MenuItem6: TMenuItem;
    Label2: TLabel;
    Action3: TAction;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    Thumbnails1: TThumbnails;
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Change(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
    procedure Action2Execute(Sender: TObject);
    procedure TreeView1DblClick(Sender: TObject);
    procedure TrackBar1Tracking(Sender: TObject);
    procedure Action3Execute(Sender: TObject);
    procedure Thumbnails1LoadFile(Sender: TObject; cnt: Integer);
  private
    { private 宣言 }
    procedure AddDir(dir: TTreeViewItem; const depth: Integer = 2);
    function IsGraphic(const Text: string): Boolean;
  public
    { public 宣言 }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses System.IOUtils, System.Threading, FMX.Platform, WinAPI.ShellAPI,
  System.Math;

procedure TForm1.Action1Execute(Sender: TObject);
begin
  for var i := 0 to TreeView1.Count - 1 do
    TreeView1.Items[i].CollapseAll;
  TreeView1.Selected := nil;
end;

procedure TForm1.Action2Execute(Sender: TObject);
var
  fname: string;
  bmp: TBitmap;
  brd: IFMXClipboardService;
begin
  fname := TreeView1.Selected.TagString;
  if not IsGraphic(fname) then
    Exit;
  if not TPlatformServices.Current.SupportsPlatformService
    (IFMXClipboardService, brd) then
  begin
    Showmessage('OSが未サポートです');
    PopupMenu1.Items[1].Enabled := false;
    Exit;
  end;
  bmp := TBitmap.Create;
  try
    bmp.LoadFromFile(fname);
    brd.SetClipboard(bmp);
    TTask.Run(
      procedure
      begin
        Label2.Visible := true;
        Sleep(3000);
        Label2.Visible := false;
      end);
  finally
    bmp.Free;
  end;
end;

procedure TForm1.Action3Execute(Sender: TObject);
var
  s: string;
begin
  if not Assigned(TreeView1.Selected) then
    Exit;
  s := TreeView1.Selected.TagString;
  if FileExists(s) then
    ShellExecute(0, 'open', PChar(s), nil, nil, 1);
end;

procedure TForm1.AddDir(dir: TTreeViewItem; const depth: Integer = 2);
const
  mes = '(no Image files)';
var
  Child: TTreeViewItem;
  option: TSearchOption;
begin
  if (depth = 0) or (dir.Text = mes) then
    Exit;
  option := TSearchOption.soTopDirectoryOnly;
  for var item in TDirectory.GetDirectories(dir.TagString, '*', option) do
  begin
    Child := TTreeViewItem.Create(dir);
    Child.Text := ExtractFileName(item);
    Child.TagString := item;
    dir.AddObject(Child);
    AddDir(Child, depth - 1);
  end;
  for var s in TDirectory.GetFiles(dir.TagString, '*.*', option) do
  begin
    if not IsGraphic(s) then
      continue;
    Child := TTreeViewItem.Create(dir);
    Child.Text := ExtractFileName(s);
    Child.TagString := s;
    dir.AddObject(Child);
    if depth = 2 then
      Thumbnails1.Files.Add(s);
  end;
  if dir.Count = 0 then
  begin
    Child := TTreeViewItem.Create(dir);
    Child.Text := mes;
    dir.AddObject(Child);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Node: TTreeViewItem;
begin
  Node := TTreeViewItem.Create(TreeView1);
  Node.Text := TPath.GetPicturesPath;
  Node.TagString := Node.Text;
  TreeView1.AddObject(Node);
  Node := TTreeViewItem.Create(TreeView1);
  Node.Text := TPath.GetDesktopPath;
  Node.TagString := Node.Text;
  TreeView1.AddObject(Node);
  Node := TTreeViewItem.Create(TreeView1);
  Node.Text := TPath.GetDocumentsPath;
  Node.TagString := Node.Text;
  TreeView1.AddObject(Node);
  Node := TTreeViewItem.Create(TreeView1);
  Node.Text := TPath.GetDownloadsPath;
  Node.TagString := Node.Text;
  TreeView1.AddObject(Node);
  Thumbnails1.MinHeight := FramedVertScrollBox1.Height;
end;

function TForm1.IsGraphic(const Text: string): Boolean;
const
  args: TArray<string> = ['.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff'];
begin
  for var arg in args do
    if ExtractFileExt(Text).ToLower = arg then
      Exit(true);
  result := false;
end;

procedure TForm1.Thumbnails1LoadFile(Sender: TObject; cnt: Integer);
begin
  if cnt = ProgressBar1.Max then
    ProgressBar1.Value := 0
  else
    ProgressBar1.Value := cnt;
end;

procedure TForm1.TrackBar1Tracking(Sender: TObject);
begin
  Thumbnails1.ThumbnailSize := 100 + 50 * Ceil(TrackBar1.Value);
end;

procedure TForm1.TreeView1Change(Sender: TObject);
var
  item: TTreeViewItem;
  bool: Boolean;
begin
  item := TreeView1.Selected;
  if not Assigned(item) then
    Exit;
  bool := IsGraphic(item.Text);
  MenuItem6.Enabled := bool;
  PopupMenu1.Items[1].Enabled := bool;
  if not DirectoryExists(item.TagString) then
    Exit;
  for var i := item.Count - 1 downto 0 do
    item.Items[i].Free;
  Thumbnails1.Files.Clear;
  AddDir(item);
  Thumbnails1.Execute;
  item.Expand;
  Label1.Text := ' ' + Thumbnails1.Files.Count.ToString + ' files';
  ProgressBar1.Value := 0;
  ProgressBar1.max := Thumbnails1.Files.Count;
  FramedVertScrollBox1.RecalcSize;
  FramedVertScrollBox1.ViewportPosition := TPointF.Create(0, 0);
end;

procedure TForm1.TreeView1DblClick(Sender: TObject);
begin
  if IsGraphic(TreeView1.Selected.Text) then
    TreeView1.Selected := TreeView1.Selected.ParentItem;
end;

end.
