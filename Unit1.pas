unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Menus, FMX.Layouts, FMX.TreeView,
  FMX.Objects;

type
  TForm1 = class(TForm)
    TreeView1: TTreeView;
    PopupMenu1: TPopupMenu;
    MenuBar1: TMenuBar;
    StatusBar1: TStatusBar;
    Image1: TImage;
    VertScrollBox1: TVertScrollBox;
    Panel1: TPanel;
    TrackBar1: TTrackBar;
    Image2: TImage;
    Panel2: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Change(Sender: TObject);
    procedure VertScrollBox1Resize(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
  private
    { private éŒ¾ }
    procedure AddDir(dir: TTreeViewItem; const depth: integer = 2);
    procedure Main(FileName: string; var X, Y: Single);
  public
    { public éŒ¾ }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses System.IOUtils;

procedure TForm1.AddDir(dir: TTreeViewItem; const depth: integer = 2);
var
  Child: TTreeViewItem;
  option: TSearchOption;
  X, Y: Single;
begin
  if (depth = 0) or (Pos('.', dir.Text) > 0) then
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
  X := 0.0;
  Y := 0.0;
  for var item in TDirectory.GetFiles(dir.TagString, '*.jpg', option) do
  begin
    Child := TTreeViewItem.Create(dir);
    Child.Text := ExtractFileName(item);
    dir.AddObject(Child);
    if dir = TreeView1.Selected then
      Main(item, X, Y);
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
  Node.Text := TPath.GetDocumentsPath;
  Node.TagString := Node.Text;
  TreeView1.AddObject(Node);
  Node := TTreeViewItem.Create(TreeView1);
  Node.Text := TPath.GetDownloadsPath;
  Node.TagString := Node.Text;
  TreeView1.AddObject(Node);
end;

procedure TForm1.Main(FileName: string; var X, Y: Single);
var
  r1, r2, wid, hei: TRectF;
  a: Single;
begin
  a := 100 + TrackBar1.Value * 50;
  Image1.Bitmap.LoadThumbnailFromFile(FileName, a, a, false);
  r1 := Image1.Bitmap.BoundsF;
  if X + r1.Width < Width then
    X := X + r1.Width + 10
  else
  begin
    X := 0.0;
    Y := Y + r1.Height + 10;
  end;
  r2 := RectF(r1.Left + X, r1.Top + Y, r1.Right + X, r1.Bottom + Y);
  if Image2.Height < r2.Bottom then
    Image2.Height := r2.Bottom;
  Image2.Canvas.BeginScene;
  try
    Image2.Canvas.DrawBitmap(Image1.Bitmap, r1, r2, 1.0);
  finally
    Image2.Canvas.EndScene;
  end;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  TreeView1Change(Self);
end;

procedure TForm1.TreeView1Change(Sender: TObject);
var
  item: TTreeViewItem;
  s: string;
begin
  item := TreeView1.Selected;
  s := '.jpg';
  if Assigned(item) then
    s := ExtractFileExt(item.Text);
  if LowerCase(s) = '.jpg' then
    Exit;
  Image2.Canvas.BeginScene;
  try
    Image2.Canvas.Clear(TAlphaColors.Black);
  finally
    Image2.Canvas.EndScene;
  end;
  item.BeginUpdate;
  for var i := item.Count - 1 downto 0 do
    item.Items[i].Free;
  item.EndUpdate;
  AddDir(item);
  item.Expand;
end;

procedure TForm1.VertScrollBox1Resize(Sender: TObject);
begin
  Image2.Position.X := 50;
  Image2.Position.Y := 50;
  Image2.Width := VertScrollBox1.Width;
  if Image2.Height < VertScrollBox1.Height then
    Image1.Height := VertScrollBox1.Height;
  // TreeView1Change(Self);
end;

end.
