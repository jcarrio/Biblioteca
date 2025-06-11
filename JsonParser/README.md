# JsonParser
Simple Json Parser for Delphi 5 and above

Sample code:
```
var
  json: TJsonParser;
  sample: TStrings;
begin
  sample.Text := '{
  "id": "0001",
  "type": "donut",
  "name": "Cake",
  "image": {
    "url": "images/0001.jpg",
    "width": 200,
    "height": 200
  },
  "thumbnail": {
    "url": "images/thumbnails/0001.jpg",
    "width": 32,
    "height": 32
  }
}';

  json := TJsonParser.Create(sample);
  ShowMessage(json.GetKey('width','image')); // 200
  ShowMessage(json.GetKey('height','thumbnail')); // 32

  ShowMessage(json.ListKeys);
end;
```

Output:
```
id: "0001" (-1)
type: "donut" (-1)
name: "Cake" (-1)
image: (-1)
url: "images/0001.jpg" (3)
width: 200 (3)
height: 200 (3)
thumbnail: (-1)
url: "images/thumbnails/0001.jpg" (7)
width: 32 (7)
height: 32 (7)
```
