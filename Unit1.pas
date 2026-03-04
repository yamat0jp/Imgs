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
  FMX.ActnList, FMX.StdActns;

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
    Image1: TImage;
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
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Change(Sender: TObject);
    procedure Image1Paint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
    procedure FormDestroy(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
    procedure Action2Execute(Sender: TObject);
    procedure TreeView1DblClick(Sender: TObject);
    procedure TrackBar1Tracking(Sender: TObject);
  private
    { private 宣言 }
    flist: TStringList;
    procedure AddDir(dir: TTreeViewItem; const depth: integer = 2);
    procedure Main(FileName: string);
    procedure LoadFLISTdata;
    function IsGraphic(const Text: string): Boolean;
  public
    { public 宣言 }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses System.IOUtils, System.Threading, FMX.Platform;

var
  bmps: TArray<TBitmap>;
  [weak]
  task: ITask;

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

procedure TForm1.AddDir(dir: TTreeViewItem; const depth: integer = 2);
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
      flist.Add(s);
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
  flist := TStringList.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  for var bmp in bmps do
    bmp.Free;
  flist.Free;
end;

procedure TForm1.Image1Paint(Sender: TObject; Canvas: TCanvas;
const ARect: TRectF);
var
  X, Y, max: Single;
begin
  X := 10;
  Y := 10;
  max := 0.0;
  for var bmp in bmps do
  begin
    if X + bmp.Width < FramedVertScrollBox1.Width then
      Canvas.DrawBitmap(bmp, bmp.BoundsF, TRectF.Create(X, Y, X + bmp.Width,
        Y + bmp.Height), 1, true)
    else
    begin
      X := 10;
      Y := max + 10;
      Canvas.DrawBitmap(bmp, bmp.BoundsF, TRectF.Create(X, Y, X + bmp.Width,
        Y + bmp.Height), 1, true);
    end;
    X := X + bmp.Width + 10;
    if Y + bmp.Height > max then
      max := Y + bmp.Height;
  end;
  if FramedVertScrollBox1.Height < max then
    Image1.Height := max
  else
    Image1.Height := FramedVertScrollBox1.Height;
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

procedure TForm1.LoadFLISTdata;
begin
  for var i := 0 to flist.Count - 1 do
  begin
    Main(flist[i]);
    if i mod 5 = 0 then
    begin
      Image1.Repaint;
      ProgressBar1.Value := i + 1;
    end;
  end;
  Image1.Repaint;
  ProgressBar1.Value := 0;
end;

procedure TForm1.Main(FileName: string);
var
  wid, hei: Word;
  bmp: TBitmap;
begin
  wid := 100 + Round(TrackBar1.Value) * 50;
  hei := wid;
  bmp := TBitmap.Create(wid, hei);
  bmp.LoadThumbnailFromFile(FileName, wid, hei, false);
  bmps := bmps + [bmp];
end;

procedure TForm1.TrackBar1Tracking(Sender: TObject);
begin
  for var bmp in bmps do
    bmp.Free;
  bmps := [];
  LoadFLISTdata;
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
  for var bmp in bmps do
    bmp.Free;
  bmps := [];
  if Assigned(task) then
    task.Cancel;
  flist.Clear;
  AddDir(item);
  item.Expand;
  Label1.Text := ' ' + flist.Count.ToString + ' files';
  ProgressBar1.Value := 0;
  ProgressBar1.max := flist.Count;
  task := TTask.Run(LoadFLISTdata);
  FramedVertScrollBox1.RecalcSize;
  FramedVertScrollBox1.ViewportPosition := TPointF.Create(0, 0);
end;

procedure TForm1.TreeView1DblClick(Sender: TObject);
begin
  if IsGraphic(TreeView1.Selected.Text) then
    TreeView1.Selected := TreeView1.Selected.ParentItem;
end;

end.
