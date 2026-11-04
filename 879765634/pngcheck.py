import struct,sys,zlib,hashlib
for p in sys.argv[1:]:
    b=open(p,'rb').read()
    assert b[:8]==b'\x89PNG\r\n\x1a\n','bad signature'
    i=8; idat=b''; w=h=d=c=None; types=[]
    while i<len(b):
        n,t=struct.unpack('>I4s',b[i:i+8]); data=b[i+8:i+8+n]; crc=struct.unpack('>I',b[i+8+n:i+12+n])[0]
        assert zlib.crc32(t+data)&0xffffffff==crc,'bad crc '+t.decode()
        if t==b'IHDR': w,h,d,c=struct.unpack('>IIBB',data[:10])
        if t==b'IDAT': idat+=data
        types.append(t); i+=12+n
    assert types[-1]==b'IEND','no IEND'
    ch={0:1,2:3,3:1,4:2,6:4}[c]
    raw=zlib.decompress(idat); exp=h*(1+(w*d*ch+7)//8)
    assert len(raw)==exp,'scanline bytes %d != %d'%(len(raw),exp)
    print('%s: PNG signature ok, all chunk CRCs ok, IHDR %dx%d depth %d colortype %d, %d scanline bytes decoded, %d file bytes, sha256 %s'%(p.split('/')[-1],w,h,d,c,len(raw),len(b),hashlib.sha256(b).hexdigest()[:16]))
