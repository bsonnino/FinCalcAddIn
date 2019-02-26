unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,System.Win.WinRt, WinApi.WinRt, WinApi.Foundation,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Math,
  Vcl.ExtCtrls, Vcl.WindowsStore, WinApi.WindowsStore, WinApi.CommonTypes,
  Vcl.Grids, Winapi.Storage, WinApi.ServicesRt.Store, WinApi.WinRt.Utils;

type
  TForm1 = class(TForm)
    Label20: TLabel;
    WindowsStore1: TWindowsStore;
    PageControl1: TPageControl;
    TabSheet3: TTabSheet;
    Label11: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    FvPresentValue: TEdit;
    IrPresentValue: TEdit;
    PvPresentValue: TEdit;
    NpPresentValue: TEdit;
    TabSheet4: TTabSheet;
    Label9: TLabel;
    Label16: TLabel;
    Label12: TLabel;
    Label10: TLabel;
    PvFutureValue: TEdit;
    IrFutureValue: TEdit;
    FvFutureValue: TEdit;
    NpFutureValue: TEdit;
    Panel1: TPanel;
    Label17: TLabel;
    Button1: TButton;
    TabSheet1: TTabSheet;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    PvPayment: TEdit;
    IRPayment: TEdit;
    NpPayment: TEdit;
    PmtPayment: TEdit;
    Panel2: TPanel;
    Label18: TLabel;
    Button2: TButton;
    TabSheet2: TTabSheet;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    PvIRR: TEdit;
    PmtIRR: TEdit;
    NpIRR: TEdit;
    IRIRR: TEdit;
    Panel3: TPanel;
    Label19: TLabel;
    Button3: TButton;
    TabSheet6: TTabSheet;
    Memo1: TMemo;
    procedure PaymentChange(Sender: TObject);
    procedure IRRChange(Sender: TObject);
    procedure PresentValueChange(Sender: TObject);
    procedure PvFutureValueChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
    procedure RecalcPayment();
    procedure CalculateIRR();
    procedure CalculatePV();
    procedure CalculateFV();
    procedure CheckIfTrial();
    procedure EnableFullVersion();
    procedure CheckBoughtCalculators();
    function PurchaseItem(Item : string) : String;
    procedure UpdateProducts();
    procedure BuyProduct(Product: IStoreProduct);
    procedure LogMessage(Msg : String);
    function BuyProductById(IdProduct: String) : String;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
function Purchase(StoreId : PAnsiChar) : PAnsiChar; stdcall; external 'IAPWrapper.dll';

procedure TForm1.CheckBoughtCalculators;
begin
  LogMessage('FutureCalc: ' + WindowsStore1.UserHasBought('FutureCalc').ToString(TUseBoolStrs.True));
  LogMessage('PaymentCalc: ' + WindowsStore1.UserHasBought('PaymentCalc').ToString(TUseBoolStrs.True));
  LogMessage('RateCalc: ' + WindowsStore1.UserHasBought('RateCalc').ToString(TUseBoolStrs.True));
  Panel1.Visible := not WindowsStore1.UserHasBought('FutureCalc');
  Panel2.Visible := not WindowsStore1.UserHasBought('PaymentCalc');
  Panel3.Visible := not WindowsStore1.UserHasBought('RateCalc');
end;

procedure TForm1.CheckIfTrial;
begin
  LogMessage('IsActive: ' + WindowsStore1.AppLicense.IsActive.ToString(TUseBoolStrs.True));
  LogMessage('IsIsTrial: ' + WindowsStore1.AppLicense.IsTrial.ToString(TUseBoolStrs.True));
  if WindowsStore1.AppLicense.IsActive then begin
    if WindowsStore1.AppLicense.IsTrial then begin
      var RemainingDays := WindowsStore1.AppLicense.TrialTimeRemaining.Days;
      LogMessage('Remaining days: ' + WindowsStore1.AppLicense.TrialTimeRemaining.Days.ToString());
      EnableFullVersion;
    end
    else
      CheckBoughtCalculators;
  end;
end;

procedure TForm1.EnableFullVersion;
begin
  Panel1.Visible := False;
  Panel2.Visible := False;
  Panel3.Visible := False;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  CheckIfTrial();
  UpdateProducts();
end;

procedure TForm1.CalculatePV;
begin
  try
    var FutureValue := StrToFloat(FvPresentValue.Text);
    var InterestRate := StrToFloat(IrPresentValue.Text) / 100.0;
    var NumPeriods := StrToInt(NpPresentValue.Text);
    var PresentValue := FutureValue / Power((1 + InterestRate), NumPeriods);
    PvPresentValue.Text := FormatFloat('0.00', PresentValue);
  except
    On EConvertError do
      PvPresentValue.Text := '';
  end;
end;

procedure TForm1.PvFutureValueChange(Sender: TObject);
begin
  CalculateFV();
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  PurchaseItem('FutureCalc');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  PurchaseItem('PaymentCalc');
end;


procedure TForm1.Button3Click(Sender: TObject);
begin
  PurchaseItem('RateCalc');
end;

procedure TForm1.CalculateFV;
begin
  try
    var PresentValue := StrToFloat(PvFutureValue.Text);
    var InterestRate := StrToFloat(IrFutureValue.Text) / 100.0;
    var NumPeriods := StrToInt(NpFutureValue.Text);
    var FutureValue := PresentValue * Power((1 + InterestRate), NumPeriods);
    FvFutureValue.Text := FormatFloat('0.00', FutureValue);
  except
    On EConvertError do
      FvFutureValue.Text := '';
  end;
end;

procedure TForm1.CalculateIRR;
begin
  try
    var NumPayments := StrToInt(NpIRR.Text);
    var PresentValue := StrToFloat(PvIRR.Text);
    var Payment := StrToFloat(PmtIRR.Text);
    var FoundRate := False;
    var MinRate := 0.0;
    var MaxRate := 1.0;
    if Payment * NumPayments < PresentValue then begin
      IRIRR.Text := 'Rate Less than 0';
      exit;
    end;
    if Payment * NumPayments = PresentValue then begin
      IRIRR.Text := '0.00';
      exit;
    end;
    if Payment > PresentValue then begin
      IRIRR.Text := 'Payment greater than Present Value';
      exit;
    end;
    while not FoundRate do begin
      var Rate := (MaxRate + MinRate) / 2.0;
      var SumPayments := 0.0;
      for var I := 1 to NumPayments do
        SumPayments := SumPayments + Payment / Power((1 + Rate), I);
      if Abs(SumPayments - PresentValue) > 0.01 then begin
        if PresentValue < SumPayments then begin
          MinRate := Rate;
        end
        else begin
          MaxRate := Rate;
        end;
      end
      else begin
        FoundRate := True;
        IRIRR.Text := FormatFloat('0.00', Rate * 100.0);
      end;
    end;
  except
    On EConvertError do
      IRIRR.Text := '';
  end;
end;

procedure TForm1.PaymentChange(Sender: TObject);
begin
  RecalcPayment();
end;

procedure TForm1.PresentValueChange(Sender: TObject);
begin
  CalculatePV();
end;

function TForm1.PurchaseItem(Item: string) : string;
begin
  LogMessage('Will purchase item: ' +Item);
  for var i := 0 to WindowsStore1.AppProducts.Count - 1 do
    if TWindowsString.HStringToString(WindowsStore1.AppProducts[i].InAppOfferToken) = Item then begin
      BuyProduct(WindowsStore1.AppProducts[i]);
      exit;
    end;
  LogMessage('Item not found: ' +Item);
end;

function TForm1.BuyProductById(IdProduct: String) : String;
begin
  Result := '';
  try
    Result := Purchase(PAnsiChar(AnsiString(IdProduct)));
  except
    On e : Exception do
      LogMessage('Exception while buying item.'+Chr(13)+
        E.ClassName+', with message : '+E.Message);
  end;
end;

procedure TForm1.BuyProduct(Product: IStoreProduct);
begin
  try
    //var status := WindowsStore1.PurchaseProduct(Product);
    //LogMessage('Got status: '+Integer(status).ToString);
    //if status = StorePurchaseStatus.Succeeded then begin
    var status := Purchase(PAnsiChar(AnsiString(TWindowsString.HStringToString(Product.StoreId))));
    LogMessage('Got status: '+status);
    if status = 'Succeeded' then begin
      LogMessage('Item ' +TWindowsString.HStringToString(Product.Title)+' bought');
      CheckBoughtCalculators();
    end
    else begin
      ShowMessage('Item could not be purchased. Error: '+Integer(status).ToString);
    end;
  except
    On e : Exception do
      LogMessage('Exception while buying item.'+Chr(13)+
        E.ClassName+', with message : '+E.Message);
  end;
end;

procedure TForm1.IRRChange(Sender: TObject);
begin
  CalculateIRR();
end;

procedure TForm1.LogMessage(Msg: String);
begin
  Memo1.Lines.Add(Msg);
  OutputDebugString(PWideChar(Msg));
end;

procedure TForm1.RecalcPayment;
begin
  try
    var PresentValue := StrToFloat(PvPayment.Text);
    var InterestRate := StrToFloat(IRPayment.Text) / 100.0;
    var NumPayments := StrToInt(NpPayment.Text);
    var Payment := (PresentValue * InterestRate) * Power((1 + InterestRate),
      NumPayments) / (Power((1 + InterestRate), NumPayments) - 1);
    PmtPayment.Text := FormatFloat('0.00', Payment);
  except
    On EConvertError do
      PmtPayment.Text := '';
  end;
end;

procedure TForm1.UpdateProducts;
var
  LProdsCount: Integer;
  I: Integer;
begin
  LProdsCount := WindowsStore1.AppProducts.Count;
  LogMessage('Total products:'+LProdsCount.ToString());
  for I := 0 to LProdsCount - 1 do begin
    LogMessage(WindowsStore1.AppProducts[I].InAppOfferToken.ToString+Chr(9)+
      WindowsStore1.AppProducts[I].StoreId.ToString+Chr(9)+
      WindowsStore1.AppProducts[I].Title.ToString+Chr(9)+
      WindowsStore1.AppProducts[I].Price.FormattedBasePrice.ToString+Chr(9)+
      WindowsStore1.AppProducts[I].ProductKind.ToString+Chr(9)+
      WindowsStore1.AppProducts[I].Price.IsOnSale.ToString(TUseBoolStrs.True)+Chr(9)+
      WindowsStore1.AppProducts[I].IsInUserCollection.ToString(TUseBoolStrs.True));
  end;
  LogMessage('----------------')
end;

end.
