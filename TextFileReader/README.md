# TextFileReader
Text File Reader for Delphi 7 and above.
Support for ANSI, UTF-8, UTF-16LE and UTF-16BE files.

Sample code:
```
uses TextFileReader;

var
  Reader: TTextFileReader;
  fName, fText: String;
  fDate: TDateTime;
  fSize: Integer;

begin
  fName := 'utf16file.txt';
  Reader := TTextFileReader.Create(fName);
  try
    // File date and size
    fDate := FileDateToDateTime(Reader.FileAge);
    fSize := Reader.FileSize;

    while not Reader.EOF do begin
      fText := Reader.ReadLine;
      // Your code here
    end;
  finally
    Reader.Free;
  end;
end;
```
