unit TextFileReader;

interface

uses
  Classes, SysUtils;

type
  TTextEncoding = (teUnknown, teAnsi, teUTF8, teUTF16LE, teUTF16BE);

  TTextFileReader = class
  private
    FStream: TFileStream;
    FEncoding: TTextEncoding;
    FBufferSize: Integer;
    FBuffer: PChar;
    FBufferPos: Integer;
    FBufferLength: Integer;
    FEOFReached: Boolean;
    FFileName: string;
    
    function DetectEncoding: TTextEncoding;
    function ReadBuffer: Boolean;
    function ReadCharUTF8: WideChar;
    function ReadCharUTF16LE: WideChar;
    function ReadCharUTF16BE: WideChar;
    function ReadCharAnsi: WideChar;
    function ReadNextChar: WideChar;
    function PeekNextChar: WideChar;
  public
    constructor Create(const FileName: string; BufferSize: Integer = 8192);
    destructor Destroy; override;
    
    function ReadLine: string;
    function EOF: Boolean;
    procedure Reset;
    function FileSize: Int64;
    function FileAge: Integer;
    
    property Encoding: TTextEncoding read FEncoding;
    property FileName: string read FFileName;
  end;

implementation

{ TTextFileReader }

constructor TTextFileReader.Create(const FileName: string; BufferSize: Integer);
begin
  inherited Create;
  FFileName := FileName;
  FBufferSize := BufferSize;
  FStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  GetMem(FBuffer, FBufferSize);
  FBufferPos := 0;
  FBufferLength := 0;
  FEOFReached := False;
  
  // Detecta automaticamente o encoding
  FEncoding := DetectEncoding;
  
  // Reposiciona após detecção do BOM
  case FEncoding of
    teUTF8: FStream.Position := 3;      // Skip UTF-8 BOM
    teUTF16LE, teUTF16BE: FStream.Position := 2; // Skip UTF-16 BOM
    else FStream.Position := 0;         // ANSI, sem BOM
  end;
  
  // Carrega primeiro buffer
  ReadBuffer;
end;

destructor TTextFileReader.Destroy;
begin
  if Assigned(FBuffer) then
    FreeMem(FBuffer);
  FStream.Free;
  inherited Destroy;
end;

function TTextFileReader.DetectEncoding: TTextEncoding;
var
  BOM: array[0..3] of Byte;
  BytesRead: Integer;
begin
  Result := teAnsi; // Default
  
  if FStream.Size < 2 then
    Exit;
    
  FStream.Position := 0;
  BytesRead := FStream.Read(BOM, 4);
  
  if BytesRead >= 3 then
  begin
    // UTF-8 BOM: EF BB BF
    if (BOM[0] = $EF) and (BOM[1] = $BB) and (BOM[2] = $BF) then
    begin
      Result := teUTF8;
      Exit;
    end;
  end;
  
  if BytesRead >= 2 then
  begin
    // UTF-16 LE BOM: FF FE
    if (BOM[0] = $FF) and (BOM[1] = $FE) then
    begin
      Result := teUTF16LE;
      Exit;
    end;
    
    // UTF-16 BE BOM: FE FF
    if (BOM[0] = $FE) and (BOM[1] = $FF) then
    begin
      Result := teUTF16BE;
      Exit;
    end;
  end;
  
  // Se não tem BOM, tenta detectar UTF-8 por padrão de bytes
  FStream.Position := 0;
  // Implementação simplificada - assume ANSI se não detectou BOM
  Result := teAnsi;
end;

function TTextFileReader.ReadBuffer: Boolean;
begin
  if FEOFReached then
  begin
    Result := False;
    Exit;
  end;
  
  FBufferLength := FStream.Read(FBuffer^, FBufferSize);
  FBufferPos := 0;
  FEOFReached := FBufferLength = 0;
  Result := FBufferLength > 0;
end;

function TTextFileReader.ReadCharUTF8: WideChar;
var
  B1, B2, B3: Byte;
  CodePoint: Cardinal;
begin
  Result := #0;
  
  if FBufferPos >= FBufferLength then
    if not ReadBuffer then Exit;
    
  B1 := Byte(FBuffer[FBufferPos]);
  Inc(FBufferPos);
  
  // ASCII (0-127)
  if B1 < $80 then
  begin
    Result := WideChar(B1);
    Exit;
  end;
  
  // UTF-8 multibyte
  if (B1 and $E0) = $C0 then // 2 bytes
  begin
    if FBufferPos >= FBufferLength then
      if not ReadBuffer then Exit;
    B2 := Byte(FBuffer[FBufferPos]);
    Inc(FBufferPos);
    CodePoint := ((B1 and $1F) shl 6) or (B2 and $3F);
    Result := WideChar(CodePoint);
  end
  else if (B1 and $F0) = $E0 then // 3 bytes
  begin
    if FBufferPos >= FBufferLength then
      if not ReadBuffer then Exit;
    B2 := Byte(FBuffer[FBufferPos]);
    Inc(FBufferPos);
    if FBufferPos >= FBufferLength then
      if not ReadBuffer then Exit;
    B3 := Byte(FBuffer[FBufferPos]);
    Inc(FBufferPos);
    CodePoint := ((B1 and $0F) shl 12) or ((B2 and $3F) shl 6) or (B3 and $3F);
    Result := WideChar(CodePoint);
  end
  else
    Result := '?'; // Char inválido
end;

function TTextFileReader.ReadCharUTF16LE: WideChar;
var
  LowByte, HighByte: Byte;
begin
  Result := #0;
  
  if FBufferPos + 1 >= FBufferLength then
    if not ReadBuffer then Exit;
    
  LowByte := Byte(FBuffer[FBufferPos]);
  HighByte := Byte(FBuffer[FBufferPos + 1]);
  Inc(FBufferPos, 2);
  
  Result := WideChar(Word(LowByte) or (Word(HighByte) shl 8));
end;

function TTextFileReader.ReadCharUTF16BE: WideChar;
var
  LowByte, HighByte: Byte;
begin
  Result := #0;
  
  if FBufferPos + 1 >= FBufferLength then
    if not ReadBuffer then Exit;
    
  HighByte := Byte(FBuffer[FBufferPos]);
  LowByte := Byte(FBuffer[FBufferPos + 1]);
  Inc(FBufferPos, 2);
  
  Result := WideChar(Word(LowByte) or (Word(HighByte) shl 8));
end;

function TTextFileReader.ReadCharAnsi: WideChar;
begin
  Result := #0;
  
  if FBufferPos >= FBufferLength then
    if not ReadBuffer then Exit;
    
  Result := WideChar(Byte(FBuffer[FBufferPos]));
  Inc(FBufferPos);
end;

function TTextFileReader.ReadNextChar: WideChar;
begin
  case FEncoding of
    teUTF8: Result := ReadCharUTF8;
    teUTF16LE: Result := ReadCharUTF16LE;
    teUTF16BE: Result := ReadCharUTF16BE;
    else Result := ReadCharAnsi;
  end;
end;

function TTextFileReader.PeekNextChar: WideChar;
var
  SavePos: Integer;
  SaveLength: Integer;
begin
  SavePos := FBufferPos;
  SaveLength := FBufferLength;
  
  Result := ReadNextChar;
  
  FBufferPos := SavePos;
  FBufferLength := SaveLength;
end;

function TTextFileReader.ReadLine: string;
var
  Line: WideString;
  Ch: WideChar;
begin
  Result := '';
  Line := '';
  
  while not EOF do
  begin
    Ch := ReadNextChar;
    
    if Ch = #0 then
      Break;
      
    if Ch = #13 then // CR
    begin
      // Verifica se próximo é LF
      if PeekNextChar = #10 then
        ReadNextChar; // Consome o LF
      Break;
    end
    else if Ch = #10 then // LF
      Break
    else
      Line := Line + Ch;
  end;
  
  Result := Line;
end;

function TTextFileReader.EOF: Boolean;
begin
  Result := FEOFReached and (FBufferPos >= FBufferLength);
end;

procedure TTextFileReader.Reset;
begin
  case FEncoding of
    teUTF8: FStream.Position := 3;      // Skip UTF-8 BOM
    teUTF16LE, teUTF16BE: FStream.Position := 2; // Skip UTF-16 BOM
    else FStream.Position := 0;         // ANSI, sem BOM
  end;
  
  FBufferPos := 0;
  FBufferLength := 0;
  FEOFReached := False;
  ReadBuffer;
end;

function TTextFileReader.FileSize: Int64;
begin
  if Assigned(FStream) then
    Result := FStream.Size
  else
    Result := -1;
end;

function TTextFileReader.FileAge: Integer;
begin
  Result := SysUtils.FileAge(FFileName);
end;

end.

