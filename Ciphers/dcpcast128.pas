unit DCPcast128;

{$MODE Delphi}

interface
uses
  Classes, Sysutils, Crypto;

type
  TCipherCAST128= class(TCipher)
  protected
    KeyData: array[0..31] of DWord;
    Rounds: longword;
    procedure InitKey(const Key; Size: longword); override;
  public
    destructor Destroy; override;
    class function Algorithm: TCipherAlgorithm; override;
    class function MaxKeySize: integer; override;
    class function SelfTest: boolean; override;
    class function BlockSize: Integer; override;
    procedure EncryptBlock(const InData; var OutData); override;
    procedure DecryptBlock(const InData; var OutData); override;
  end;

implementation
{$R-}{$Q-}

{$I DCPcast128.inc}

function LRot32(a, n: dword): dword;
begin
  Result:= (a shl n) or (a shr (32-n));
end;

destructor TCipherCAST128.Destroy;
begin
  FillChar(KeyData,Sizeof(KeyData),$FF);
  Rounds:= 0;
  inherited Destroy;
end;

class function TCipherCAST128.MaxKeySize: integer;
begin
  Result:= 128;
end;

class function TCipherCast128.BlockSize: Integer;
begin
  Result := 64;
end;

class function TCipherCAST128.Algorithm: TCipherAlgorithm;
begin
  Result:= caCAST128;
end;

class function TCipherCAST128.SelfTest: boolean;
const
  Key: array[0..15] of byte=
    ($01,$23,$45,$67,$12,$34,$56,$78,$23,$45,$67,$89,$34,$56,$78,$9A);
  InBlock: array[0..7] of byte=
    ($01,$23,$45,$67,$89,$AB,$CD,$EF);
  Out128: array[0..7] of byte=
    ($23,$8B,$4F,$E5,$84,$7E,$44,$B2);
  Out80: array[0..7] of byte=
    ($EB,$6A,$71,$1A,$2C,$02,$27,$1B);
  Out40: array[0..7] of byte=
    ($7A,$C8,$16,$D1,$6E,$9B,$30,$2E);
var
  Block: array[0..7] of byte;
  Cipher: TCipherCAST128;
begin
  FillChar(Block, SizeOf(Block), 0);
  Cipher:= TCipherCAST128.Create(@Key,128);
  Cipher.EncryptBlock(InBlock,Block);
  Result:= boolean(CompareMem(@Block,@Out128,8));
  Cipher.DecryptBlock(Block,Block);
  Result:= Result and boolean(CompareMem(@Block,@InBlock,8));
  Cipher.Free;
  Cipher := TCipherCAST128.Create(@Key,80);
  Cipher.EncryptBlock(InBlock,Block);
  Result:= Result and boolean(CompareMem(@Block,@Out80,8));
  Cipher.DecryptBlock(Block,Block);
  Result:= Result and boolean(CompareMem(@Block,@InBlock,8));
  Cipher.Free;
  Cipher := TCipherCAST128.Create(@Key,40);
  Cipher.EncryptBlock(InBlock,Block);
  Result:= Result and boolean(CompareMem(@Block,@Out40,8));
  Cipher.DecryptBlock(Block,Block);
  Result:= Result and boolean(CompareMem(@Block,@InBlock,8));
  Cipher.Free;
end;

procedure TCipherCAST128.InitKey(const Key; Size: longword);
var
  x, t, z: array[0..3] of DWord;
  i: longword;
begin
  Size:= Size div 8;
  if Size<= 10 then
    Rounds:= 12
  else
    Rounds:= 16;
  FillChar(x, Sizeof(x), 0);
  Move(Key,x,Size);
  x[0]:= (x[0] shr 24) or ((x[0] shr 8) and $FF00) or ((x[0] shl 8) and $FF0000) or (x[0] shl 24);
  x[1]:= (x[1] shr 24) or ((x[1] shr 8) and $FF00) or ((x[1] shl 8) and $FF0000) or (x[1] shl 24);
  x[2]:= (x[2] shr 24) or ((x[2] shr 8) and $FF00) or ((x[2] shl 8) and $FF0000) or (x[2] shl 24);
  x[3]:= (x[3] shr 24) or ((x[3] shr 8) and $FF00) or ((x[3] shl 8) and $FF0000) or (x[3] shl 24);
  i:= 0;
  while i< 32 do
  begin
    case (i and 4) of
      0:
        begin
          z[0]:= x[0] xor cast_sbox5[(x[3] shr 16) and $FF] xor
           cast_sbox6[x[3] and $FF] xor cast_sbox7[x[3] shr 24] xor
           cast_sbox8[(x[3] shr 8) and $FF] xor cast_sbox7[x[2] shr 24];
          t[0]:= z[0];
          z[1]:= x[2] xor cast_sbox5[z[0] shr 24] xor
           cast_sbox6[(z[0] shr 8) and $FF] xor cast_sbox7[(z[0] shr 16) and $FF] xor
           cast_sbox8[z[0] and $FF] xor cast_sbox8[(x[2] shr 8) and $FF];
          t[1]:= z[1];
          z[2]:= x[3] xor cast_sbox5[z[1] and $FF] xor
           cast_sbox6[(z[1] shr 8) and $FF] xor cast_sbox7[(z[1] shr 16) and $FF] xor
           cast_sbox8[z[1] shr 24] xor cast_sbox5[(x[2] shr 16) and $FF];
          t[2]:= z[2];
          z[3]:= x[1] xor cast_sbox5[(z[2] shr 8) and $FF] xor
           cast_sbox6[(z[2] shr 16) and $FF] xor cast_sbox7[z[2] and $FF] xor
           cast_sbox8[z[2] shr 24] xor cast_sbox6[x[2] and $FF];
          t[3]:= z[3];
        end;
      4:
        begin
          x[0]:= z[2] xor cast_sbox5[(z[1] shr 16) and $FF] xor
           cast_sbox6[z[1] and $FF] xor cast_sbox7[z[1] shr 24] xor
           cast_sbox8[(z[1] shr 8) and $FF] xor cast_sbox7[z[0] shr 24];
          t[0]:= x[0];
          x[1]:= z[0] xor cast_sbox5[x[0] shr 24] xor
           cast_sbox6[(x[0] shr 8) and $FF] xor cast_sbox7[(x[0] shr 16) and $FF] xor
           cast_sbox8[x[0] and $FF] xor cast_sbox8[(z[0] shr 8) and $FF];
          t[1]:= x[1];
          x[2]:= z[1] xor cast_sbox5[x[1] and $FF] xor
           cast_sbox6[(x[1] shr 8) and $FF] xor cast_sbox7[(x[1] shr 16) and $FF] xor
           cast_sbox8[x[1] shr 24] xor cast_sbox5[(z[0] shr 16) and $FF];
          t[2]:= x[2];
          x[3]:= z[3] xor cast_sbox5[(x[2] shr 8) and $FF] xor
           cast_sbox6[(x[2] shr 16) and $FF] xor cast_sbox7[x[2] and $FF] xor
           cast_sbox8[x[2] shr 24] xor cast_sbox6[z[0] and $FF];
          t[3]:= x[3];
        end;
    end;
    case (i and 12) of
      0,12:
        begin
          KeyData[i+0]:= cast_sbox5[t[2] shr 24] xor cast_sbox6[(t[2] shr 16) and $FF] xor
           cast_sbox7[t[1] and $FF] xor cast_sbox8[(t[1] shr 8) and $FF];
          KeyData[i+1]:= cast_sbox5[(t[2] shr 8) and $FF] xor cast_sbox6[t[2] and $FF] xor
           cast_sbox7[(t[1] shr 16) and $FF] xor cast_sbox8[t[1] shr 24];
          KeyData[i+2]:= cast_sbox5[t[3] shr 24] xor cast_sbox6[(t[3] shr 16) and $FF] xor
           cast_sbox7[t[0] and $FF] xor cast_sbox8[(t[0] shr 8) and $FF];
          KeyData[i+3]:= cast_sbox5[(t[3] shr 8) and $FF] xor cast_sbox6[t[3] and $FF] xor
           cast_sbox7[(t[0] shr 16) and $FF] xor cast_sbox8[t[0] shr 24];
        end;
      4,8:
        begin
          KeyData[i+0]:= cast_sbox5[t[0] and $FF] xor cast_sbox6[(t[0] shr 8) and $FF] xor
           cast_sbox7[t[3] shr 24] xor cast_sbox8[(t[3] shr 16) and $FF];
          KeyData[i+1]:= cast_sbox5[(t[0] shr 16) and $FF] xor cast_sbox6[t[0] shr 24] xor
           cast_sbox7[(t[3] shr 8) and $FF] xor cast_sbox8[t[3] and $FF];
          KeyData[i+2]:= cast_sbox5[t[1] and $FF] xor cast_sbox6[(t[1] shr 8) and $FF] xor
           cast_sbox7[t[2] shr 24] xor cast_sbox8[(t[2] shr 16) and $FF];
          KeyData[i+3]:= cast_sbox5[(t[1] shr 16) and $FF] xor cast_sbox6[t[1] shr 24] xor
           cast_sbox7[(t[2] shr 8) and $FF] xor cast_sbox8[t[2] and $FF];
        end;
    end;
    case (i and 12) of
      0:
        begin
          KeyData[i+0]:= KeyData[i+0] xor cast_sbox5[(z[0] shr 8) and $FF];
          KeyData[i+1]:= KeyData[i+1] xor cast_sbox6[(z[1] shr 8) and $FF];
          KeyData[i+2]:= KeyData[i+2] xor cast_sbox7[(z[2] shr 16) and $FF];
          KeyData[i+3]:= KeyData[i+3] xor cast_sbox8[z[3] shr 24];
        end;
      4:
        begin
          KeyData[i+0]:= KeyData[i+0] xor cast_sbox5[x[2] shr 24];
          KeyData[i+1]:= KeyData[i+1] xor cast_sbox6[(x[3] shr 16) and $FF];
          KeyData[i+2]:= KeyData[i+2] xor cast_sbox7[x[0] and $FF];
          KeyData[i+3]:= KeyData[i+3] xor cast_sbox8[x[1] and $FF];
        end;
      8:
        begin
          KeyData[i+0]:= KeyData[i+0] xor cast_sbox5[(z[2] shr 16) and $FF];
          KeyData[i+1]:= KeyData[i+1] xor cast_sbox6[z[3] shr 24];
          KeyData[i+2]:= KeyData[i+2] xor cast_sbox7[(z[0] shr 8) and $FF];
          KeyData[i+3]:= KeyData[i+3] xor cast_sbox8[(z[1] shr 8) and $FF];
        end;
      12:
        begin
          KeyData[i+0]:= KeyData[i+0] xor cast_sbox5[x[0] and $FF];
          KeyData[i+1]:= KeyData[i+1] xor cast_sbox6[x[1] and $FF];
          KeyData[i+2]:= KeyData[i+2] xor cast_sbox7[x[2] shr 24];
          KeyData[i+3]:= KeyData[i+3] xor cast_sbox8[(x[3] shr 16) and $FF];
        end;
    end;
    if (i >= 16) then
    begin
      KeyData[i+0]:= KeyData[i+0] and 31;
      KeyData[i+1]:= KeyData[i+1] and 31;
      KeyData[i+2]:= KeyData[i+2] and 31;
      KeyData[i+3]:= KeyData[i+3] and 31;
    end;
    Inc(i,4);
  end;
end;

procedure TCipherCAST128.EncryptBlock(const InData; var OutData);
var
  t, l, r: DWord;
begin
  l:= Pdword(@InData)^;
  r:= Pdword(Pointer(@InData)+4)^;
  l:= (l shr 24) or ((l shr 8) and $FF00) or ((l shl 8) and $FF0000) or (l shl 24);
  r:= (r shr 24) or ((r shr 8) and $FF00) or ((r shl 8) and $FF0000) or (r shl 24);
  t:= LRot32(KeyData[0]+r, KeyData[0+16]);
  l:= l xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
    cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[1] xor l, KeyData[1+16]);
  r:= r xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
    cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[2]-r, KeyData[2+16]);
  l:= l xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
    cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[3]+l, KeyData[3+16]);
  r:= r xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
    cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[4] xor r, KeyData[4+16]);
  l:= l xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
    cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[5]-l, KeyData[5+16]);
  r:= r xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
    cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[6]+r, KeyData[6+16]);
  l:= l xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
    cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[7] xor l, KeyData[7+16]);
  r:= r xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
    cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[8]-r, KeyData[8+16]);
  l:= l xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
    cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[9]+l, KeyData[9+16]);
  r:= r xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
    cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[10] xor r, KeyData[10+16]);
  l:= l xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
    cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[11]-l, KeyData[11+16]);
  r:= r xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
    cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
  if Rounds> 12 then
  begin
    t:= LRot32(KeyData[12]+r, KeyData[12+16]);
    l:= l xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
      cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
    t:= LRot32(KeyData[13] xor l, KeyData[13+16]);
    r:= r xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
      cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
    t:= LRot32(KeyData[14]-r, KeyData[14+16]);
    l:= l xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
      cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
    t:= LRot32(KeyData[15]+l, KeyData[15+16]);
    r:= r xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
      cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  end;
  l:= (l shr 24) or ((l shr 8) and $FF00) or ((l shl 8) and $FF0000) or (l shl 24);
  r:= (r shr 24) or ((r shr 8) and $FF00) or ((r shl 8) and $FF0000) or (r shl 24);
  Pdword(@OutData)^:= r;
  Pdword(pointer(@OutData)+4)^:= l;
end;

procedure TCipherCAST128.DecryptBlock(const InData; var OutData);
var
  t, l, r: DWord;
begin
  r:= Pdword(@InData)^;
  l:= Pdword(pointer(@InData)+4)^;
  l:= (l shr 24) or ((l shr 8) and $FF00) or ((l shl 8) and $FF0000) or (l shl 24);
  r:= (r shr 24) or ((r shr 8) and $FF00) or ((r shl 8) and $FF0000) or (r shl 24);
  if Rounds> 12 then
  begin
    t:= LRot32(KeyData[15]+l, KeyData[15+16]);
    r:= r xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
      cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
    t:= LRot32(KeyData[14]-r, KeyData[14+16]);
    l:= l xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
      cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
    t:= LRot32(KeyData[13] xor l, KeyData[13+16]);
    r:= r xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
      cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
    t:= LRot32(KeyData[12]+r, KeyData[12+16]);
    l:= l xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
      cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  end;
  t:= LRot32(KeyData[11]-l, KeyData[11+16]);
  r:= r xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
    cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[10] xor r, KeyData[10+16]);
  l:= l xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
    cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[9]+l, KeyData[9+16]);
  r:= r xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
    cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[8]-r, KeyData[8+16]);
  l:= l xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
    cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[7] xor l, KeyData[7+16]);
  r:= r xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
    cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[6]+r, KeyData[6+16]);
  l:= l xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
    cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[5]-l, KeyData[5+16]);
  r:= r xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
    cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[4] xor r, KeyData[4+16]);
  l:= l xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
    cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[3]+l, KeyData[3+16]);
  r:= r xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
    cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[2]-r, KeyData[2+16]);
  l:= l xor (((cast_sbox1[t shr 24] + cast_sbox2[(t shr 16) and $FF]) xor
    cast_sbox3[(t shr 8) and $FF]) - cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[1] xor l, KeyData[1+16]);
  r:= r xor (((cast_sbox1[t shr 24] - cast_sbox2[(t shr 16) and $FF]) +
    cast_sbox3[(t shr 8) and $FF]) xor cast_sbox4[t and $FF]);
  t:= LRot32(KeyData[0]+r, KeyData[0+16]);
  l:= l xor (((cast_sbox1[t shr 24] xor cast_sbox2[(t shr 16) and $FF]) -
    cast_sbox3[(t shr 8) and $FF]) + cast_sbox4[t and $FF]);
  l:= (l shr 24) or ((l shr 8) and $FF00) or ((l shl 8) and $FF0000) or (l shl 24);
  r:= (r shr 24) or ((r shr 8) and $FF00) or ((r shl 8) and $FF0000) or (r shl 24);
  Pdword(@OutData)^:= l;
  Pdword(pointer(@OutData)+4)^:= r;
end;


end.