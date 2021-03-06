{ ***************************************** }
{ FastReport v2.3 }
{ PDF export filter }
{ By : Ricardo Cardona Ramirez }
{ ***************************************** }

unit FR_E_TNPDF;

interface

{$I FR.inc}

uses
  SysUtils, Windows, Messages, Classes, Graphics, Forms, StdCtrls, FR_BarC,
  FR_Class, PdfDoc, PdfTypes, PdfFonts, PReport, Dialogs, Controls, UITypes;

type
  TfrTNPDFExport = class(TComponent)// fake component
  end;

  TfrTNPDFExportFilter = class(TfrExportFilter)
  private
    NewPage: Boolean;
    PDF: TPReport;
    PPage: TPRPage;
    PRPanel: TPRPanel;
    DummyControl: TForm;
  public
    constructor Create(AStream: TStream); override;
    destructor Destroy; override;
    procedure OnBeginPage; override;
    procedure OnEndPage; override;
    procedure ShowBackGround(View: TfrView; x, y, h, w: integer);
    procedure Frame(View: TfrView; x, y, h, w: integer);
    procedure ShowFrame(View: TfrView; x, y, h, w: integer);
    procedure ShowBarCode(View: TfrBarCodeView; x, y, h, w: integer);
    procedure ShowPicture(View: TfrPictureView; x, y, h, w: integer);
    procedure OnText(x, y: integer; const Text: string; View: TfrView); override;
    procedure OnData(x, y: integer; View: TfrView); override;
  end;

implementation

uses
  FR_Const;

type
  TfrMemoView_ = class(TfrMemoView);
  TPRText_ = class(TPRText);

const
    // The magic number :)
  PDFEscx = 0.7915006640106241699867197875166;
  PDFEscy = 0.78544776119402985074626865671642;

constructor TfrTNPDFExportFilter.Create(AStream: TStream);
begin
  inherited;
  PDF := TPReport.Create(nil);
  PDF.CompressionMethod := cmNone;
  PDF.BeginDoc;
  DummyControl := TForm.Create(nil);
  NewPage := False;
end;

destructor TfrTNPDFExportFilter.Destroy;
begin
  PDF.GetPdfDoc.SaveToStream(Stream);
  PDF.Free;
  DummyControl.Free;
  inherited;
end;

procedure TfrTNPDFExportFilter.OnBeginPage;
begin
  { Add New Page }
  PPage := TPRPage.Create(PDF);
  PPage.Parent := DummyControl;
  PPage.MarginBottom := 0;
  PPage.MarginTop := 0;
  PPage.MarginLeft := 0;
  PPage.MarginRight := 0;
  // for Multisize pages �?
  PPage.Height := trunc(CurReport.EMFPages[0].PrnInfo.Pgh * PDFEscy);
  PPage.Width := trunc(CurReport.EMFPages[0].PrnInfo.Pgw * PDFEscx);
  PRPanel := TPRPanel.Create(PPage);
  PRPanel.Parent := PPage;
  PRPanel.Left := 0;
  PRPanel.Top := 0;
  PRPanel.Width := PPage.Width;
  PRPanel.Height := PPage.Height;
end;

procedure TfrTNPDFExportFilter.OnEndPage;
begin
  PDF.Print(PPage);
  FreeAndNil(PPage);
end;

procedure TfrTNPDFExportFilter.ShowBackGround(View: TfrView; x, y, h, w: integer);
var
  PRRect: TPRRect;
begin
  PRRect := TPRRect.Create(PRPanel);
  PRRect.Parent := PRPanel;
  PRRect.FillColor := View.FillColor;
  PRRect.LineColor := View.FillColor;
  PRRect.LineStyle := psSolid;
  PRRect.Left := x;
  PRRect.Top := y;
  PRRect.Height := h;
  PRRect.Width := w;
end;

procedure TfrTNPDFExportFilter.Frame(View: TfrView; x, y, h, w: integer);
var
  PRRect: TPRRect;
begin
  PRRect := TPRRect.Create(PRPanel);
  PRRect.Parent := PRPanel;
  PRRect.FillColor := clNone;

  PRRect.Left := x;
  PRRect.Top := y;
  PRRect.Height := h;
  PRRect.Width := w;

  PRRect.LineStyle := TPenStyle(View.FrameStyle);
  PRRect.LineWidth := View.FrameWidth - 0.5;
  PRRect.LineColor := View.FrameColor;
end;

procedure TfrTNPDFExportFilter.ShowFrame(View: TfrView; x, y, h, w: integer);
begin
  if ((View.FrameTyp and $F) = $F) and (View.FrameStyle = 0) then
  begin
    Frame(View, x, y, h, w);
  end else begin
    if (View.FrameTyp and $1) <> 0 then
      Frame(View, x + w, y, h + 1, 0);
    if (View.FrameTyp and $4) <> 0 then
      Frame(View, x, y, h + 1, 0);
    if (View.FrameTyp and $2) <> 0 then
      Frame(View, x, y + h, 0, w);
    if (View.FrameTyp and $8) <> 0 then
      Frame(View, x, y, 0, w);
  end;
end;

procedure TfrTNPDFExportFilter.ShowBarCode(View: TfrBarCodeView; x, y, h, w: integer);
var
  Bitmap: TBitmap;
  PRImage: TPRImage;
  oldX, oldY: integer;
begin
  oldX := View.x;
  oldY := View.y;
  View.x := 0;
  View.y := 0;
  Bitmap := TBitmap.Create;
  try
    PRImage := TPRImage.Create(PRPanel);
    PRImage.Parent := PRPanel;
    PRImage.Stretch := True;
    PRImage.SharedImage := False;
    PRImage.Left := x;
    PRImage.Top := y;
    PRImage.Height := h;
    PRImage.Width := w;

    Bitmap.Height := View.dy;
    Bitmap.Width := View.dx;

    TfrBarCodeView(View).Draw(Bitmap.Canvas);

    PRImage.Picture.Bitmap := Bitmap;
  finally
    FreeAndNil(Bitmap);
  end;
  View.x := oldX;
  View.y := oldY;
end;

procedure TfrTNPDFExportFilter.ShowPicture(View: TfrPictureView; x, y, h, w: integer);
var
  Bitmap: TBitmap;
  PRImage: TPRImage;
begin
  Bitmap := TBitmap.Create;
  try
    PRImage := TPRImage.Create(PRPanel);
    PRImage.Parent := PRPanel;
    PRImage.Stretch := True;
    PRImage.SharedImage := False;
    PRImage.Left := x;
    PRImage.Top := y;
    PRImage.Height := h;
    PRImage.Width := w;
    Bitmap.Height := View.Picture.Height;
    Bitmap.Width := View.Picture.Width;
    Bitmap.Canvas.Draw(0, 0, View.Picture.Graphic);
    PRImage.Picture.Bitmap := Bitmap;
  finally
    FreeAndNil(Bitmap);
  end;
end;

procedure TfrTNPDFExportFilter.OnData(x, y: integer; View: TfrView);
var
  nx, ny, ndx, ndy: integer;
begin
  nx := Round(x * PDFEscx);
  ny := Round(y * PDFEscy);
  ndx := Round(View.dx * PDFEscx) + 1;
  ndy := Round(View.dy * PDFEscy) + 1;

  if View.FillColor <> clNone then
    ShowBackGround(View, nx, ny, ndy, ndx);

  if View is TfrBarCodeView then
    ShowBarCode(TfrBarCodeView(View), nx, ny, ndy, ndx)
  else
    if View is TfrPictureView then
      ShowPicture(TfrPictureView(View), nx, ny, ndy, ndx);
        // For debugging only
        // else if not View is  TfrMemoView then
        // MessageDlg(View.ClassName, mtWarning, [mbOK], 0);
  if ((View.FrameTyp and $F) <> 0) and not (View is TfrBarCodeView) then
    ShowFrame(View, nx, ny, ndy, ndx);
end;

procedure TfrTNPDFExportFilter.OnText(x, y: integer; const Text: string; View: TfrView);
var
  PRTLabel: TPRText;
  nx, ny, ndx, ndy: integer;
begin
  nx := Round(x * PDFEscx) + 1;
  ny := Round(y * PDFEscy) + 1;
  ndx := Round(View.dx * PDFEscx);
  ndy := Round(View.dy * PDFEscy);
  PRTLabel := TPRText.Create(PRPanel);
  PRTLabel.Parent := PRPanel;
  try
    PRTLabel.Text := Text;
    PRTLabel.Left := nx;
    PRTLabel.Top := ny;
    PRTLabel.Width := ndx;
    PRTLabel.Height := ndy;
    if View is TfrMemoView then
    begin
      if Pos('Arial', TfrMemoView_(View).Font.Name) > 0 then
        PRTLabel.FontName := fnArial
      else
        if Pos('Courier', TfrMemoView_(View).Font.Name) > 0 then
          PRTLabel.FontName := fnFixedWidth
        else
          if Pos('Times', TfrMemoView_(View).Font.Name) > 0 then
            PRTLabel.FontName := fnTimesRoman;
      PRTLabel.FontSize := TfrMemoView_(View).Font.Size;
      PRTLabel.FontBold := fsBold in TfrMemoView_(View).Font.Style;
      PRTLabel.FontItalic := fsItalic in TfrMemoView_(View).Font.Style;
      PRTLabel.FontColor := TfrMemoView_(View).Font.Color;
    end;
  finally
  end;
end;

initialization

frRegisterExportFilter(TfrTNPDFExportFilter, 'Adobe Acrobat Pdf ' + ' (*.pdf)', '*.pdf');

end.
