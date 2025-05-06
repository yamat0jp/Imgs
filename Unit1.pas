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
  Data.Bind.ObjectScope, Data.Bind.GenData, FMX.ListBox;

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
    ImageList1: TImageList;
    Glyph1: TGlyph;
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Change(Sender: TObject);
    procedure FramedVertScrollBox1Paint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
  private
    { private êÈåæ }
    procedure AddDir(dir: TTreeViewItem; const depth: integer = 2);
    function Main(FileName: string; var X, Y: Single): Single;
    function Ext(str: string; args: array of string): Boolean;
  public
    { public êÈåæ }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses System.IOUtils, System.Threading;

var
  max: Single;

procedure TForm1.AddDir(dir: TTreeViewItem; const depth: integer = 2);
var
  Child: TTreeViewItem;
  option: TSearchOption;
  X, Y, tmp: Single;
begin
  if depth = 0 then
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
  X := 10;
  Y := 10;
  max := Y;
  for var item in TDirectory.GetFiles(dir.TagString, '*.*', option) do
  begin
    if not Ext(ExtractFileExt(item), ['.jpg', '.jpeg', '.bmp', '.tif', '.tiff',
      '.png', '.gif']) then
      continue;
    Child := TTreeViewItem.Create(dir);
    Child.Text := ExtractFileName(item);
    dir.AddObject(Child);
    if depth = 2 then
    begin
      tmp := Main(item, X, Y);
      if max < tmp then
        max := tmp;
    end;
  end;
end;

function TForm1.Ext(str: string; args: array of string): Boolean;
begin
  for var arg in args do
    if LowerCase(str) = arg then
      Exit(true);
  result := false;
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
  Node.Text := TPath.GetDocumentsPath;
  Node.TagString := Node.Text;
  TreeView1.AddObject(Node);
  Node := TTreeViewItem.Create(TreeView1);
  Node.Text := TPath.GetDownloadsPath;
  Node.TagString := Node.Text;
  TreeView1.AddObject(Node);
end;

procedure TForm1.FramedVertScrollBox1Paint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if Assigned(Sender) then
    TreeView1Change(Sender)
  else
    ImageList1.Draw(Canvas, ARect, ImageList1.Count - 1, 1);
end;

function TForm1.Main(FileName: string; var X, Y: Single): Single;
var
  a: Single;
  r1, r2: TRectF;
begin
  if Y > FramedVertScrollBox1.Height then
    Exit(0.0);
  result := 0.0;
  a := 100 + TrackBar1.Value * 50;
  r1 := TRectF.Create(X, Y, a + X, a + Y);
  if r1.Width + X < FramedVertScrollBox1.Width then
  begin
    r2 := TRectF.Create(X, Y, r1.Width + X, r1.Height + Y);
    X := r1.Width + X + 10;
    result := Y + r1.Height + 10;
  end
  else
  begin
    X := 10;
    Y := max;
    r2 := TRectF.Create(X, Y, r1.Width + X, r1.Height + Y);
  end;
  with ImageList1.Source.Add do
  begin
    Name := FileName;
    DisplayName := ExtractFileName(FileName);
    MultiResBitmap.Add.Bitmap.LoadThumbnailFromFile(FileName, a, a, true);
  end;
  ImageList1.Destination.Add.Layers.Add.Name := FileName;
  with FramedVertScrollBox1 do
    if Canvas.BeginScene then
      try
        FramedVertScrollBox1Paint(nil, Canvas, r2);
      finally
        Canvas.EndScene;
      end;
end;

procedure TForm1.TreeView1Change(Sender: TObject);
var
  item: TTreeViewItem;
begin
  item := TreeView1.Selected;
  if not Assigned(item) or (ExtractFileExt(item.Text) <> '') then
    Exit;
  item.BeginUpdate;
  for var i := item.Count - 1 downto 0 do
    item.Items[i].Free;
  item.EndUpdate;
  ImageList1.Source.Clear;
  ImageList1.Destination.Clear;
  AddDir(item);
  item.Expand;
end;

end.
