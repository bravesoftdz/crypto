unit DCPidea;

{$MODE Delphi}

interface
uses
  Classes, Sysutils, Crypto;

type
  TCipherIDEA= class(TCipher)
    protected
      EK, DK: array[0..51] of word;
      procedure InitKey(const Key; Size: longword); override;
    public
      destructor Destroy; override;
      class function Algorithm: TCipherAlgorithm; override;
      class function BlockSize: Integer; override;
      class function MaxKeySize: Integer; override;
      class function SelfTest: Boolean; override;
      procedure EncryptBlock(const InData; var OutData); override;
      procedure DecryptBlock(const InData; var OutData); override;
  end;

implementation
{$R-}{$Q-}

destructor TCipherIDEA.Destroy;
begin
  FillChar(EK,Sizeof(EK),0);
  FillChar(DK,Sizeof(DK),0);
  inherited Destroy;
end;

class function TCipherIDEA.Algorithm: TCipherAlgorithm;
begin
  Result:= caIDEA;
end;

class function TCipherIDEA.BlockSize: Integer;
begin
  Result := 64;
end;

class function TCipherIDEA.MaxKeySize: integer;
begin
  Result:= 128;
end;

class function TCipherIDEA.SelfTest: boolean;
const
  Key1: array[0..15] of byte=
    ($3A,$98,$4E,$20,$00,$19,$5D,$B3,$2E,$E5,$01,$C8,$C4,$7C,$EA,$60);
  InData1: array[0..7] of byte=
    ($01,$02,$03,$04,$05,$06,$07,$08);
  OutData1: array[0..7] of byte=
    ($97,$BC,$D8,$20,$07,$80,$DA,$86);
  Key2: array[0..15] of byte=
    ($00,$64,$00,$C8,$01,$2C,$01,$90,$01,$F4,$02,$58,$02,$BC,$03,$20);
  InData2: array[0..7] of byte=
    ($05,$32,$0A,$64,$14,$C8,$19,$FA);
  OutData2: array[0..7] of byte=
    ($65,$BE,$87,$E7,$A2,$53,$8A,$ED);
var
  Cipher: TCipherIDEA;
  Data: array[0..7] of byte;
begin
  FillChar(Data, SizeOf(Data), 0);
  Cipher:= TCipherIDEA.Create(@Key1,SizeOf(Key1) * 8);
  Cipher.EncryptBlock(InData1,Data);
  Result:= boolean(CompareMem(@Data,@OutData1,Sizeof(Data)));
  Cipher.DecryptBlock(Data,Data);
  Result:= Result and boolean(CompareMem(@Data,@InData1,Sizeof(Data)));
  Cipher.Free;
  Cipher := TCipherIDEA.Create(@Key2,Sizeof(Key2)*8);
  Cipher.EncryptBlock(InData2,Data);
  Result:= Result and boolean(CompareMem(@Data,@OutData2,Sizeof(Data)));
  Cipher.DecryptBlock(Data,Data);
  Result:= Result and boolean(CompareMem(@Data,@InData2,Sizeof(Data)));
  Cipher.Free;
end;

function MulInv(x: word): word;
var
  t0, t1, q, y: word;
begin
  if x<= 1 then
  begin
    Result:= x;
    Exit;
  end;
  t1:= DWord($10001) div x;
  y:= DWord($10001) mod x;
  if y= 1 then
  begin
    Result:= (1 - t1) and $FFFF;
    Exit;
  end;
  t0:= 1;
  repeat
    q:= x div y;
    x:= x mod y;
    t0:= t0 + (q*t1);
    if x= 1 then
    begin
      Result:= t0;
      Exit;
    end;
    q:= y div x;
    y:= y mod x;
    t1:= t1 + (q*t0);
  until y= 1;
  Result:= (1-t1) and $FFFF;
end;

procedure TCipherIDEA.InitKey(const Key; Size: longword);
var
  i: integer;
begin
  Size:= Size div 8;

  FillChar(EK,Sizeof(EK),0);
  Move(Key,EK,Size);
  for i:= 0 to 7 do
    EK[i]:= (EK[i] shl 8) or (EK[i] shr 8);
  for i:= 1 to 5 do
  begin
    EK[(i*8)+0]:= (EK[((i-1)*8)+1] shl 9) or (EK[((i-1)*8)+2] shr 7);
    EK[(i*8)+1]:= (EK[((i-1)*8)+2] shl 9) or (EK[((i-1)*8)+3] shr 7);
    EK[(i*8)+2]:= (EK[((i-1)*8)+3] shl 9) or (EK[((i-1)*8)+4] shr 7);
    EK[(i*8)+3]:= (EK[((i-1)*8)+4] shl 9) or (EK[((i-1)*8)+5] shr 7);
    EK[(i*8)+4]:= (EK[((i-1)*8)+5] shl 9) or (EK[((i-1)*8)+6] shr 7);
    EK[(i*8)+5]:= (EK[((i-1)*8)+6] shl 9) or (EK[((i-1)*8)+7] shr 7);
    EK[(i*8)+6]:= (EK[((i-1)*8)+7] shl 9) or (EK[((i-1)*8)+0] shr 7);
    EK[(i*8)+7]:= (EK[((i-1)*8)+0] shl 9) or (EK[((i-1)*8)+1] shr 7);
  end;
  EK[48]:= (EK[41] shl 9) or (EK[42] shr 7);
  EK[49]:= (EK[42] shl 9) or (EK[43] shr 7);
  EK[50]:= (EK[43] shl 9) or (EK[44] shr 7);
  EK[51]:= (EK[44] shl 9) or (EK[45] shr 7);

  DK[51]:= MulInv(EK[3]);
  DK[50]:= -EK[2];
  DK[49]:= -EK[1];
  DK[48]:= MulInv(EK[0]);
  for i:= 0 to 6 do
  begin
    DK[47-i*6]:= EK[i*6+5];
    DK[46-i*6]:= EK[i*6+4];
    DK[45-i*6]:= MulInv(EK[i*6+9]);
    DK[44-i*6]:= -EK[i*6+7];
    DK[43-i*6]:= -EK[i*6+8];
    DK[42-i*6]:= MulInv(EK[i*6+6]);
  end;
  DK[5]:= EK[47];
  DK[4]:= EK[46];
  DK[3]:= MulInv(EK[51]);
  DK[2]:= -EK[50];
  DK[1]:= -EK[49];
  DK[0]:= MulInv(EK[48]);
end;

procedure Mul(var x: word; const y: word);
var
  p: DWord;
  t16: word;
begin
  p:= DWord(x)*y;
  if p= 0 then
    x:= 1 - x - y
  else
  begin
    x:= p shr 16;
    t16:= p and $FFFF;
    x:= t16 - x;
    if (t16 < x) then
      Inc(x);
  end;
end;

procedure TCipherIDEA.EncryptBlock(const InData; var OutData);
var
  x: array[1..4] of word;
  s3, s2: word;
  i: longword;
begin
  PDword(@X[1])^:= PDword(@InData)^;
  PDword(@X[3])^:= PDword(pointer(@InData)+4)^;
  for i:= 1 to 4 do
    x[i]:= (x[i] shl 8) or (x[i] shr 8);
  for i:= 0 to 7 do
  begin
    Mul(x[1],EK[(i*6)+0]);
    Inc(x[2],EK[(i*6)+1]);
    Inc(x[3],EK[(i*6)+2]);
    Mul(x[4],EK[(i*6)+3]);
    s3:= x[3];
    x[3]:= x[3] xor x[1];
    Mul(x[3],EK[(i*6)+4]);
    s2:= x[2];
    x[2]:= x[2] xor x[4];
    Inc(x[2],x[3]);
    Mul(x[2],EK[(i*6)+5]);
    Inc(x[3],x[2]);
    x[1]:= x[1] xor x[2];
    x[4]:= x[4] xor x[3];
    x[2]:= x[2] xor s3;
    x[3]:= x[3] xor s2;
  end;
  Mul(x[1],EK[48]);
  Inc(x[3],EK[49]);
  Inc(x[2],EK[50]);
  Mul(x[4],EK[51]);
  x[1]:= (x[1] shl 8) or (x[1] shr 8);
  s2:= (x[3] shl 8) or (x[3] shr 8);
  x[3]:= (x[2] shl 8) or (x[2] shr 8);
  x[4]:= (x[4] shl 8) or (x[4] shr 8);
  x[2]:= s2;
  PDword(@OutData)^:= PDword(@x[1])^;
  PDword(pointer(@OutData)+4)^:= PDword(@x[3])^;
end;

procedure TCipherIDEA.DecryptBlock(const InData; var OutData);
var
  x: array[1..4] of word;
  s3, s2: word;
  i: longword;
begin
  PDword(@X[1])^:= PDword(@InData)^;
  PDword(@X[3])^:= PDword(pointer(@InData)+4)^;
  for i:= 1 to 4 do
    x[i]:= (x[i] shl 8) or (x[i] shr 8);
  for i:= 0 to 7 do
  begin
    Mul(x[1],DK[(i*6)+0]);
    Inc(x[2],DK[(i*6)+1]);
    Inc(x[3],DK[(i*6)+2]);
    Mul(x[4],DK[(i*6)+3]);
    s3:= x[3];
    x[3]:= x[3] xor x[1];
    Mul(x[3],DK[(i*6)+4]);
    s2:= x[2];
    x[2]:= x[2] xor x[4];
    Inc(x[2],x[3]);
    Mul(x[2],DK[(i*6)+5]);
    Inc(x[3],x[2]);
    x[1]:= x[1] xor x[2];
    x[4]:= x[4] xor x[3];
    x[2]:= x[2] xor s3;
    x[3]:= x[3] xor s2;
  end;
  Mul(x[1],DK[48]);
  Inc(x[3],DK[49]);
  Inc(x[2],DK[50]);
  Mul(x[4],DK[51]);
  x[1]:= (x[1] shl 8) or (x[1] shr 8);
  s2:= (x[3] shl 8) or (x[3] shr 8);
  x[3]:= (x[2] shl 8) or (x[2] shr 8);
  x[4]:= (x[4] shl 8) or (x[4] shr 8);
  x[2]:= s2;
  PDword(@OutData)^:= PDword(@x[1])^;
  PDword(pointer(@OutData)+4)^:= PDword(@x[3])^;
end;

end.