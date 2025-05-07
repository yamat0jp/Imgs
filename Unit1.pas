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
    Image1: TImage;
    Glyph1: TGlyph;
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Change(Sender: TObject);
    procedure Image1Paint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
  private
    { private êÈåæ }
    procedure AddDir(dir: TTreeViewItem; const depth: integer = 2);
    procedure Main(FileName: string; var X, Y: Single);
    function Ext(str: string; args: array of string): Boolean;
  public
    { public êÈåæ }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses System.IOUtils, System.Threading;

const
  exts: TArray<string> = ['.jpg', '.jpeg', '.bmp', '.tif', '.tiff',
    '.png', '.gif'];

var
  max: Single;

procedure TForm1.AddDir(dir: TTreeViewItem; const depth: integer = 2);
var
  Child: TTreeViewItem;
  option: TSearchOption;
  X, Y: Single;
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
  for var s in TDirectory.GetFiles(dir.TagString, '*.*', option) do
  begin
    if not Ext(ExtractFileExt(s), exts) then
      continue;
    Child := TTreeViewItem.Create(dir);
    Child.Text := ExtractFileName(s);
    dir.AddObject(Child);
    if depth = 2 then
      Main(s, X, Y);
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

procedure TForm1.Image1Paint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
var
  X, Y, max: Single;
  r: TRectF;
  rects: TArray<TRectF>;
begin
  X := 10;
  Y := 10;
  max := 0.0;
  rects := [];
  for var i := 0 to ImageList1.Destination.Count - 1 do
  begin
    r := TRectF.Create(X, Y, X + Glyph1.Width, Y + Glyph1.Height);
    if r.Bottom > max then
      max := r.Bottom;
    if r.Right < FramedVertScrollBox1.Width then
      X := r.Right + 10
    else
    begin
      r := TRectF.Create(10, max + 10, 10 + Glyph1.Width,
        max + 10 + Glyph1.Height);
      X := r.Right + 10;
      Y := max + 10;
    end;
    rects := rects + [r];
  end;
  if FramedVertScrollBox1.Height < max then
    Image1.Height := max;
  for var i := 0 to High(rects) do
    ImageList1.Draw(Canvas, rects[i], i, 1);
  Finalize(rects);
end;

procedure TForm1.Main(FileName: string; var X, Y: Single);
var
  a: Single;
  r: TRectF;
begin
  a := 100 + TrackBar1.Value * 50;
  with ImageList1.Source.Add do
  begin
    Name := FileName;
    DisplayName := ExtractFileName(FileName);
    MultiResBitmap.Add.Bitmap.LoadThumbnailFromFile(FileName, Glyph1.Width,
      Glyph1.Height, false);
  end;
  ImageList1.Destination.Add.Layers.Add.Name := FileName;
  if Image1.BoundsRect.Contains(TPointF.Create(X, Y)) then
  begin
    r := TRectF.Create(X, Y, X + Glyph1.Width, Y + Glyph1.Height);
    Image1.Canvas.BeginScene;
    ImageList1.Draw(Image1.Canvas, r, ImageList1.Destination.Count - 1);
    Image1.Canvas.EndScene;
    if r.Right > Image1.Width then
    begin
      X := 10;
      Y := max + 10;
    end
    else
    begin
      X := r.Right + 10;
      if max < r.Bottom then
        max := r.Bottom;
    end;
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
  Image1.Height := FramedVertScrollBox1.Height;
  Image1.Repaint;
end;

end.
