unit frexBMP;

interface

{$I FR.inc}

uses
  Windows, SysUtils, Classes, Graphics, Math, UITypes,
  FR_BarC, FR_Class, FR_Shape;

type
  TFrameSet = set of (Left, Top, Bottom, Right);

  TfrBMPExport = class(TComponent)// fake component
  end;

  TfrBMPExportFilter = class(TfrExportFilter)
  private
    LastY, CurrPage: Integer;
    Image: TBitmap;
    Canvas: TCanvas;
    function CalcRect(const x, y: Integer; const View: TfrView): TRect;
    function CalcFrameSet(const View: TfrView): TFrameSet;
    procedure DrawBackGround(const View: TfrView; const R: TRect);
    procedure DrawFrame(const View: TfrView; const R: TRect; const FrameSet: TFrameSet);
    procedure DrawBarCode(const View: TfrBarCodeView; const R: TRect);
    procedure DrawPicture(const View: TfrPictureView; const R: TRect);
    procedure DrawEndLine;
    procedure DrawShape(const View: TfrShapeObject; const R: TRect);
  public
    constructor Create(AStream: TStream); override;
    destructor Destroy; override;
    procedure OnBeginPage; override;
    procedure OnEndPage; override;
    procedure OnText(x, y: Integer; const Text: string; View: TfrView); override;
    procedure OnData(x, y: Integer; View: TfrView); override;
  end;

implementation

type
  TfrMemoView_ = class(TfrMemoView);

procedure TfrBMPExportFilter.DrawEndLine;
begin
  Canvas.Pen.Color := RGB(220, 220, 220);
  Canvas.Pen.Style := psDash;
  Canvas.Pen.Width := 1;
  Canvas.MoveTo(0, Pred(Image.Height));
  Canvas.LineTo(Image.Width, Pred(Image.Height));
end;

procedure TfrBMPExportFilter.DrawBackGround(const View: TfrView; const R: TRect);
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Style := psClear;
  Canvas.Brush.Color := View.FillColor;
  Canvas.Rectangle(R);
end;

function TfrBMPExportFilter.CalcFrameSet(const View: TfrView): TFrameSet;
begin
  Result := [];
  if ((View.FrameTyp and $F) = $F) and (View.FrameStyle = 0) then
  begin
    Result := [Left, Top, Bottom, Right];
  end else begin
    if (View.FrameTyp and $1) <> 0 then
      Include(Result, Right);
    if (View.FrameTyp and $4) <> 0 then
      Include(Result, Left);
    if (View.FrameTyp and $2) <> 0 then
      Include(Result, Bottom);
    if (View.FrameTyp and $8) <> 0 then
      Include(Result, Top);
  end;
end;

procedure TfrBMPExportFilter.DrawFrame(const View: TfrView; const R: TRect; const FrameSet: TFrameSet);
begin
  if FrameSet = [] then
    Exit;
  Canvas.Pen.Style := TPenStyle(View.FrameStyle);
  Canvas.Pen.Color := View.FrameColor;
  Canvas.Pen.Width := Round(View.FrameWidth - 0.5);
  if Top in FrameSet then
  begin
    Canvas.MoveTo(R.Left, R.Top);
    Canvas.LineTo(R.Right, R.Top);
  end;
  if Bottom in FrameSet then
  begin
    Canvas.MoveTo(R.Left, R.Bottom);
    Canvas.LineTo(R.Right, R.Bottom);
  end;
  if Left in FrameSet then
  begin
    Canvas.MoveTo(R.Left, R.Top);
    Canvas.LineTo(R.Left, R.Bottom);
  end;
  if Right in FrameSet then
  begin
    Canvas.MoveTo(Pred(R.Right), R.Top);
    Canvas.LineTo(Pred(R.Right), R.Bottom);
  end;
end;

procedure TfrBMPExportFilter.DrawBarCode(const View: TfrBarCodeView; const R: TRect);
var
  TempDraw: TBitmap;
  oldX, oldY: Integer;
begin
  oldX := View.x;
  oldY := View.y;
  View.x := 0;
  View.y := 0;
  TempDraw := TBitmap.Create;
  try
    TempDraw.Height := View.dy;
    TempDraw.Width := View.dx;
    TfrBarCodeView(View).Draw(TempDraw.Canvas);
    Canvas.Draw(R.Left, R.Top, TempDraw);
  finally
    FreeAndNil(TempDraw);
  end;
  View.x := oldX;
  View.y := oldY;
end;

procedure TfrBMPExportFilter.DrawPicture(const View: TfrPictureView; const R: TRect);
begin
  Canvas.Draw(R.Left, R.Top, View.Picture.Graphic);
end;

procedure TfrBMPExportFilter.DrawShape(const View: TfrShapeObject; const R: TRect);
begin
             seguir
end;

function TfrBMPExportFilter.CalcRect(const x, y: Integer; const View: TfrView): TRect;
begin
  Result.Left := x;
  Result.Top := y + LastY;
  Result.Right := Result.Left + Round(View.dx);
  Result.Bottom := Result.Top + Round(View.dy);
end;

procedure TfrBMPExportFilter.OnText(x, y: Integer; const Text: string; View: TfrView);
var
  R: TRect;
  TextTemp: String;
begin
  if View is TfrMemoView then
  begin
    R := CalcRect(x, y, View);
    Canvas.Font.Assign(TfrMemoView_(View).Font);
    TextTemp := Text;
    Canvas.TextRect(R, TextTemp, [tfVerticalCenter]);
  end;
end;

procedure TfrBMPExportFilter.OnData(x, y: Integer; View: TfrView);
var
  R: TRect;
begin
  R := CalcRect(x, y, View);
  if View.FillColor <> clNone then
    DrawBackGround(View, R)
  else
    Canvas.Brush.Style := bsClear;
  if View is TfrBarCodeView then
    DrawBarCode(TfrBarCodeView(View), R)
  else
    if View is TfrPictureView then
      DrawPicture(TfrPictureView(View), R)
    else
      if View is TfrShapeObject then
        DrawShape(TfrShapeObject(View), R);
  DrawFrame(View, R, CalcFrameSet(View));
end;

procedure TfrBMPExportFilter.OnBeginPage;
var
  PrnInfo: TfrPrnInfo;
begin
  PrnInfo := CurReport.EMFPages[CurrPage].PrnInfo;
  Image.Height := Image.Height + trunc(PrnInfo.Pgh);
  Image.Width := Max(Image.Width, trunc(PrnInfo.Pgw));
end;

procedure TfrBMPExportFilter.OnEndPage;
begin
  DrawEndLine;
  LastY := Image.Height;
  Inc(CurrPage);
end;

constructor TfrBMPExportFilter.Create(AStream: TStream);
begin
  inherited;
  Image := TBitmap.Create;
  Canvas := Image.Canvas;
  LastY := 0;
  CurrPage := 0;
end;

destructor TfrBMPExportFilter.Destroy;
begin
  Image.SaveToStream(Stream);
  Image.Free;
  inherited;
end;

initialization

frRegisterExportFilter(TfrBMPExportFilter, 'Bitmap image (*.bmp)', '*.bmp');

end.
