unit UnitClienteREST.Model;

interface

uses REST.Client,
     REST.Types,
     System.Json,
     IpPeerClient,
     System.Generics.Collections,
     UnitClienteREST.Model.Interfaces,
     UnitObserver.Model.Interfaces, System.Classes;

type
  TClienteREST = class(TInterfacedObject, iClienteREST, iSujeito)
  private
    FRestClient: TRESTClient;
    FRestRequest: TRESTRequest;
    FRestResponse: TRESTResponse;
    FListaObservers: TList<iObservador>;
    FListaHeaders: TDictionary<string,string>;
  public
    constructor Create(URL: string);
    destructor Destroy; override;
    class function New(URL: string): iClienteREST;
    function Put(Value: string = ''): string;
    function Get(Value: string = ''): string;
    function Post(Value: string = ''): string;overload;
    function Post(Value: string; Body: TJSONObject): string;overload;
    function Post(Value: string; Body: string): string;overload;
    function Delete(Value: string = ''): iClienteREST;
    function AddObservador(Value: iObservador): iSujeito;
    function RemoveObservador(Value: iObservador): iSujeito;
    function Notificar(Value: TNotificacao): iSujeito;
    function InscreverObservador(Value: iObservador): iClienteREST;
    function AddHeader(Par, Valor: string): iClienteREST;
    function AddBody(Value: string): iClienteREST;overload;
    function AddBody(Value: TJSONObject): iClienteREST;overload;
    function AddBody(Value: TStream): iClienteREST;overload;
  end;

implementation

uses
  System.SysUtils;

{ TClienteREST }

function TClienteREST.AddObservador(Value: iObservador): iSujeito;
begin
  Result := Self;
  FListaObservers.Add(Value);
end;

function TClienteREST.AddBody(Value: string): iClienteREST;
begin
  Result := Self;
  FRestRequest.ClearBody;
  FRestRequest.AddBody(Value);
end;

function TClienteREST.AddBody(Value: TJSONObject): iClienteREST;
begin
  Result := Self;
  FRestRequest.ClearBody;
  FRestRequest.AddBody(Value);
end;

function TClienteREST.AddBody(Value: TStream): iClienteREST;
begin
  Result := Self;
  FRestRequest.ClearBody;
  FRestRequest.AddBody(Value, ctAPPLICATION_OCTET_STREAM);
end;

function TClienteREST.AddHeader(Par, Valor: string): iClienteREST;
begin
  Result := Self;
  if not Assigned(FListaHeaders) then
    FListaHeaders := TDictionary<string,string>.Create;
  FListaHeaders.Add(Par, Valor);
end;

constructor TClienteREST.Create(URL: string);
begin
  FListaObservers       := TList<iObservador>.Create;
  FListaHeaders         := TDictionary<string,string>.Create;
  FRestClient           := TRESTClient.Create(URL);
  FRestRequest          := TRESTRequest.Create(nil);
  FRestResponse         := TRESTResponse.Create(nil);
  FRestRequest.Client   := FRestClient;
  FRestRequest.Response := FRestResponse;
end;

function TClienteREST.Delete(Value: string = ''): iClienteREST;
var
  Jo: TJSONObject;
begin
  Result              := Self;
  FRestRequest.Method := rmDELETE;
  FRestRequest.Execute;
end;

destructor TClienteREST.Destroy;
begin
  FreeAndNil(FRestClient);
  FreeAndNil(FRestRequest);
  FreeAndNil(FRestResponse);
  FreeAndNil(FListaObservers);
  if Assigned(FListaHeaders) then
    FreeAndNil(FListaHeaders);
  inherited;
end;

function TClienteREST.Get(Value: string = ''): string;
begin
  if Value <> '' then
    FRestClient.BaseURL := Value;
  FRestRequest.Method   := rmGET;
  FRestRequest.Execute;
  Result := FRestResponse.Content;
end;

function TClienteREST.InscreverObservador(Value: iObservador): iClienteREST;
begin
  Result := Self;
  AddObservador(Value);
end;

class function TClienteREST.New(URL: string): iClienteREST;
begin
  Result := Self.Create(URL);
end;

function TClienteREST.Notificar(Value: TNotificacao): iSujeito;
var
  i: Integer;
begin
  for i := 0 to Pred(FListaObservers.Count) do
    FListaObservers[i].Atualizar(Value);
end;

function TClienteREST.Post(Value: string = ''): string;
var
  Jo: TJSONObject;
  Chave: string;
  Valor: string;
begin
  Result := '';
  try
    if Value <> '' then
      FRestClient.BaseURL := Value;
    FRestRequest.Method := rmPOST;
    for chave in FListaHeaders.Keys do
    begin
      FListaHeaders.TryGetValue(Chave, Valor);
      FRestRequest.Params.AddHeader(Chave, Valor);
      FRestRequest.Params.ParameterByName(Chave).Options := [poDoNotEncode];
    end;
    FRestRequest.Execute;
    FListaHeaders.Clear;
    if FRestResponse.ContentLength > 0 then
    begin
      Result := FRestResponse.Content;
    end;
  except on E: Exception do
    raise Exception.Create('Erro ao enviar dados pelo m?todo POST');
  end;
end;

function TClienteREST.Post(Value: string; Body: TJSONObject): string;
var
  Jo: TJSONObject;
  Chave: string;
  Valor: string;
begin
  Result := '';
  try
    if Assigned(Body) then
      AddBody(Body);
    if Value <> '' then
      FRestClient.BaseURL := Value;
    FRestRequest.Method := rmPOST;
    for chave in FListaHeaders.Keys do
    begin
      FListaHeaders.TryGetValue(Chave, Valor);
      FRestRequest.Params.AddHeader(Chave, Valor);
      FRestRequest.Params.ParameterByName(Chave).Options := [poDoNotEncode];
    end;
    FRestRequest.Execute;
    FListaHeaders.Clear;
    if FRestResponse.ContentLength > 0 then
    begin
      Result := FRestResponse.Content;
    end;
  except on E: Exception do
    raise Exception.Create('Erro ao enviar dados pelo m?todo POST');
  end;
end;

function TClienteREST.RemoveObservador(Value: iObservador): iSujeito;
begin
  Result := Self;
  FListaObservers.Remove(Value);
end;

function TClienteREST.Post(Value, Body: string): string;
var
  Jo: TJSONObject;
  Chave: string;
  Valor: string;
begin
  Result := '';
  try
    if Body <> '' then
      AddBody(Body);
    if Value <> '' then
      FRestClient.BaseURL := Value;
    FRestRequest.Method := rmPOST;
    for chave in FListaHeaders.Keys do
    begin
      FListaHeaders.TryGetValue(Chave, Valor);
      FRestRequest.Params.AddHeader(Chave, Valor);
      FRestRequest.Params.ParameterByName(Chave).Options := [poDoNotEncode];
    end;
    FRestRequest.Execute;
    FListaHeaders.Clear;
    if FRestResponse.ContentLength > 0 then
    begin
      Result := FRestResponse.Content;
    end;
  except on E: Exception do
    raise Exception.Create('Erro ao enviar dados pelo m?todo POST');
  end;
end;


function TClienteREST.Put(Value: string = ''): string;
var
  chave: string;
  Valor: string;
begin
  Result := '';
  if Value <> '' then
    FRestClient.BaseURL := Value;
  FRestRequest.Method := rmPUT;
  for chave in FListaHeaders.Keys do
  begin
    FListaHeaders.TryGetValue(Chave, Valor);
    FRestRequest.Params.AddHeader(Chave, Valor);
    FRestRequest.Params.ParameterByName(Chave).Options := [poDoNotEncode];
  end;
  FRestRequest.Execute;
  FListaHeaders.Clear;
  if FRestResponse.ContentLength > 0 then
  begin
    Result := FRestResponse.Content;
  end;
end;

end.
