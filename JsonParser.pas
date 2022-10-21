unit JsonParser;
// Autor: Julio Carrió  - 21/10/2022
// Doesn't consider lists []

interface

uses Classes;

type
  TItem = record
    Key: String;
    Value: String;
    Parent: Integer;
  end;
  TJson = array of TItem;

  TJsonParser = class
  private
    json: TJson;
    formatted: TStringList;
    procedure FormatJson(pList: TStrings); 
  public
    constructor Create(pList: TStrings);
    destructor Destroy;
    function GetValue(pKey: String; pParent: String = ''): String;
    function ListKeys: String;
    function FormattedJson: String;
  end;

implementation

uses SysUtils;

constructor TJsonParser.Create(pList: TStrings);
var
  ind,parent: Integer;
begin
  formatted := TStringList.Create;
  FormatJson(pList);
  parent := -1;
  for ind := 0 to formatted.Count-1 do begin
    if trim(formatted[ind]) = '},' then
      parent := json[parent].Parent;
    if (trim(formatted[ind]) = '{')or(trim(formatted[ind]) = '}')or(trim(formatted[ind]) = '},') then
      continue;
    SetLength(json, length(json)+1);
    json[high(json)].Key := trim(stringreplace(copy(formatted[ind],1,pos(':',formatted[ind])-1),'"','',[rfReplaceAll]));
    json[high(json)].Value := trim(copy(formatted[ind],pos(':',formatted[ind])+1,length(formatted[ind])));
    json[high(json)].Parent := parent;
    if json[high(json)].Value = '{' then begin
      json[high(json)].Value := '';
      parent := high(json)
    end else if copy(json[high(json)].Value,length(json[high(json)].Value),1) = ',' then
      json[high(json)].Value := copy(json[high(json)].Value,1,length(json[high(json)].Value)-1);
  end;
end;

destructor TJsonParser.Destroy;
begin
  SetLength(json, 0);
  formatted.Free;
end;

function TJsonParser.GetValue(pKey: String; pParent: String = ''): String;
var aux, cont: Integer;
begin
  Result := '';
  aux := -1;
  if pParent <> '' then
    for cont := low(json) to high(json) do
      if json[cont].Key = pParent then begin
        aux := cont;
        break;
      end;
  //
  for cont := low(json) to high(json) do
    if (json[cont].Key = pKey)and(json[cont].Parent = aux) then begin
      Result := StringReplace(json[cont].Value,'"','',[rfReplaceAll]);;
      break;
    end;
end;

function TJsonParser.ListKeys: String;
var
  ind: Integer;
begin
  Result := '';
  for ind := low(json) to high(json) do
    Result := Result + json[ind].Key + ': '+json[ind].Value+' ('+inttostr(json[ind].Parent)+')'+chr(10);
end;

procedure TJsonParser.FormatJson(pList: TStrings);
var
  openingCB,comma,closingCB,colon: Integer;
  pLine: String;
  ind: Integer;
begin
  formatted.Clear;
  for ind := 0 to pList.Count-1 do begin
    pLine := pList[ind];
    while pLine <> '' do begin
      if (trim(pLine) = '{')or(trim(pLine) = '}')or(trim(pLine) = '},') then begin
        formatted.Add(pLine);
        pLine := '';
        continue;
      end;
      openingCB := pos('{',pLine);
      comma := pos(',',pLine);
      closingCB := pos('}',pLine);
      colon := pos(':',pLine);
      if (openingCB = 0)and(comma = 0)and(closingCB = 0) then begin
        formatted.Add(pLine);
        pLine := '';
      end else
      if (openingCB > 0)and((comma = 0)or(openingCB < comma))and((closingCB = 0)or(openingCB < closingCB)) then begin
        formatted.Add(copy(pLine,1,pos('{',pLine)));
        pLine := copy(pLine,pos('{',pLine)+1,length(pLine));
      end else
      if (comma > 0)and((closingCB = 0)or(comma < closingCB)) then begin
        formatted.Add(copy(pLine,1,pos(',',pLine)));
        pLine := copy(pLine,pos(',',pLine)+1,length(pLine));
      end else
      if (closingCB > 0)and(comma = 0)and(colon > 0) then begin
        formatted.Add(copy(pLine,1,pos('}',pLine)-1));
        pLine := copy(pLine,pos('}',pLine),length(pLine));
      end else
      if (closingCB > 0)and(comma = 0)and(colon = 0) then begin
        formatted.Add(copy(pLine,1,pos('}',pLine)));
        pLine := copy(pLine,pos('}',pLine)+1,length(pLine));
      end;
    end;
  end;
end;

function TJsonParser.FormattedJson: String;
begin
  Result := formatted.Text;
end;

end.
