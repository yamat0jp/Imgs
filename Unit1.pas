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
    Image1: TImage;
    Image2: TImage;
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Change(Sender: TObject);
    procedure Image1Paint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
  private
    { private êÈåæ }
    procedure AddDir(dir: TTreeViewItem; const depth: integer = 2);
    procedure Main(FileName: string; var X, Y: Single);
    function GetSize(FileName: string; var Width, Height: Word): Boolean;
    function Ext(str: string; args: array of string): Boolean;
  public
    { public êÈåæ }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses System.IOUtils, System.Threading, CCR.Exif;

const
  exts: TArray<string> = ['.jpg', '.jpeg'];

var
  bmps: TArray<TBitmap>;

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

function TForm1.GetSize(FileName: string; var Width, Height: Word): Boolean;
var
  Data: TExifData;
begin
  Data := TExifData.Create;
  try
    Data.LoadFromGraphic(FileName);
    result := Data.Empty;
    Width := Data.ExifImageWidth;
    Height := Data.ExifImageHeight;
    if Width = 0 then
      result := false;
  finally
    Data.Free;
  end;
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
    begin
      Canvas.DrawBitmap(bmp, bmp.BoundsF, TRectF.Create(X, Y, X + bmp.Width,
        Y + bmp.Height), 1, true);
      X := X + bmp.Width + 10;
    end
    else
    begin
      X := 10;
      Y := max + 10;
      Canvas.DrawBitmap(bmp, bmp.BoundsF, TRectF.Create(X, Y, X + bmp.Width,
        Y + bmp.Height), 1, true);
    end;
    if Y + bmp.Height > max then
      max := Y + bmp.Height;
  end;
  if FramedVertScrollBox1.Height < max then
    Image1.Height := max
  else
    Image1.Height := FramedVertScrollBox1.Height;
end;

procedure TForm1.Main(FileName: string; var X, Y: Single);
var
  wd, wid, hei: Word;
  bmp: TBitmap;
begin
  if GetSize(FileName, wd, hei) then
  begin
    wid := 100 + Round(TrackBar1.Value) * 50;
    hei := wid * Round(hei / wd);
    bmp := TBitmap.Create;
    bmp.LoadThumbnailFromFile(FileName, wid, hei, false);
    bmps := bmps + [bmp];
  end
  else
  begin
    bmp := TBitmap.Create;
    bmp.LoadThumbnailFromFile(FileName, 100, 100, true);
    bmps := bmps + [bmp];
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
  for var bmp in bmps do
    bmp.Free;
  Finalize(bmps);
  AddDir(item);
  item.Expand;
  Image1.Repaint;
  FramedVertScrollBox1.RecalcSize;
  FramedVertScrollBox1.ViewportPosition:=TPointF.Create(0,0);
end;

end.
