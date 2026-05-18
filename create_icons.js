const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

function createIconPNG(size) {
  const pixels = new Uint8Array(size * size * 3);

  // Cores
  const BG  = [13, 27, 42];       // #0D1B2A fundo escuro
  const ACC = [79, 195, 247];     // #4FC3F7 azul claro
  const WH  = [255, 255, 255];    // branco
  const GR  = [39, 174, 96];      // verde para seta de alta

  function setPixel(x, y, c) {
    x = Math.round(x); y = Math.round(y);
    if (x < 0 || x >= size || y < 0 || y >= size) return;
    const i = (y * size + x) * 3;
    pixels[i] = c[0]; pixels[i+1] = c[1]; pixels[i+2] = c[2];
  }

  function fillRect(x, y, w, h, c) {
    for (let dy = 0; dy < h; dy++)
      for (let dx = 0; dx < w; dx++)
        setPixel(x+dx, y+dy, c);
  }

  function drawRoundedRect(x, y, w, h, r, c) {
    // Fill center + sides
    fillRect(x+r, y,   w-2*r, h,   c);
    fillRect(x,   y+r, r,     h-2*r, c);
    fillRect(x+w-r, y+r, r,   h-2*r, c);
    // Corners
    for (let cy = 0; cy < r; cy++) {
      for (let cx = 0; cx < r; cx++) {
        if ((cx-r)*(cx-r)+(cy-r)*(cy-r) <= r*r) {
          setPixel(x+cx,       y+cy,       c); // top-left
          setPixel(x+w-1-cx,   y+cy,       c); // top-right
          setPixel(x+cx,       y+h-1-cy,   c); // bottom-left
          setPixel(x+w-1-cx,   y+h-1-cy,   c); // bottom-right
        }
      }
    }
  }

  function drawLine(x1, y1, x2, y2, thick, c) {
    const dx = x2-x1, dy = y2-y1;
    const steps = Math.max(Math.abs(dx), Math.abs(dy), 1);
    for (let t = 0; t <= steps; t++) {
      const px = x1 + dx*t/steps;
      const py = y1 + dy*t/steps;
      for (let ty = -thick; ty <= thick; ty++)
        for (let tx = -thick; tx <= thick; tx++)
          if (tx*tx+ty*ty <= thick*thick)
            setPixel(px+tx, py+ty, c);
    }
  }

  const sc = size / 192;

  // Fundo totalmente escuro
  for (let i = 0; i < size*size; i++) {
    pixels[i*3]=BG[0]; pixels[i*3+1]=BG[1]; pixels[i*3+2]=BG[2];
  }

  // Fundo com canto arredondado (simulando ícone Android)
  const pad = Math.round(8*sc);
  const rad = Math.round(28*sc);
  drawRoundedRect(pad, pad, size-2*pad, size-2*pad, rad, BG);

  // --- 3 barras do gráfico ---
  const baseY = Math.round(155*sc);
  const barW  = Math.round(30*sc);
  const gap   = Math.round(14*sc);
  const startX = Math.round(28*sc);
  const barRadius = Math.max(2, Math.round(4*sc));

  // Alturas das barras (proporcionais)
  const bars = [
    { h: Math.round(55*sc) },  // curta
    { h: Math.round(95*sc) },  // alta
    { h: Math.round(72*sc) },  // média
    { h: Math.round(108*sc) }, // mais alta
  ];

  bars.forEach((bar, i) => {
    const bx = startX + i*(barW+gap);
    const by = baseY - bar.h;
    // Barra com topo arredondado
    fillRect(bx, by+barRadius, barW, bar.h-barRadius, ACC);
    // Topo arredondado
    for (let ry = 0; ry < barRadius; ry++) {
      for (let rx = 0; rx < barW; rx++) {
        const cx = barW/2, cy = barRadius;
        const dx = rx-cx, dy = ry-cy;
        if (dx*dx + (dy+1)*(dy+1) <= (barW/2)*(barW/2))
          setPixel(bx+rx, by+ry, ACC);
      }
    }
  });

  // --- Linha base ---
  const lineBaseH = Math.max(2, Math.round(3*sc));
  fillRect(Math.round(20*sc), baseY, Math.round(152*sc), lineBaseH, ACC);

  // --- Linha de tendência crescente em verde ---
  const thick = Math.max(1, Math.round(4*sc));
  const pts = bars.map((bar, i) => ({
    x: startX + i*(barW+gap) + barW/2,
    y: baseY - bar.h - Math.round(8*sc)
  }));

  for (let i = 0; i < pts.length-1; i++) {
    drawLine(pts[i].x, pts[i].y, pts[i+1].x, pts[i+1].y, thick, GR);
  }

  // Pontos na linha
  pts.forEach(p => {
    const r = Math.max(3, Math.round(6*sc));
    for (let dy = -r; dy <= r; dy++)
      for (let dx = -r; dx <= r; dx++)
        if (dx*dx+dy*dy <= r*r)
          setPixel(p.x+dx, p.y+dy, WH);
  });

  // --- Seta para cima no último ponto ---
  const ap = pts[pts.length-1];
  const as = Math.max(4, Math.round(10*sc));
  for (let ay = 0; ay <= as; ay++) {
    const w = ay;
    for (let ax = -w; ax <= w; ax++)
      setPixel(ap.x+ax, ap.y-as+ay-Math.round(10*sc), GR);
  }

  // --- Pequeno cifrão no canto superior esquerdo ---
  // Apenas um ponto decorativo azul claro
  const dotR = Math.max(3, Math.round(7*sc));
  for (let dy = -dotR; dy <= dotR; dy++)
    for (let dx = -dotR; dx <= dotR; dx++)
      if (dx*dx+dy*dy <= dotR*dotR)
        setPixel(Math.round(30*sc)+dx, Math.round(30*sc)+dy, ACC);

  // --- Gerar PNG ---
  const sig = Buffer.from([137,80,78,71,13,10,26,10]);
  const crcTable = (() => {
    const t = new Uint32Array(256);
    for (let i=0;i<256;i++){let c=i;for(let j=0;j<8;j++)c=(c&1)?(0xEDB88320^(c>>>1)):(c>>>1);t[i]=c;}
    return t;
  })();
  function crc32(buf){let c=0xFFFFFFFF;for(let i=0;i<buf.length;i++)c=crcTable[(c^buf[i])&0xFF]^(c>>>8);return(c^0xFFFFFFFF)|0;}
  function chunk(type,data){
    const tb=Buffer.from(type,'ascii');
    const lb=Buffer.allocUnsafe(4);lb.writeUInt32BE(data.length,0);
    const cd=Buffer.concat([tb,data]);
    const cb=Buffer.allocUnsafe(4);cb.writeInt32BE(crc32(cd),0);
    return Buffer.concat([lb,tb,data,cb]);
  }
  const ihdr=Buffer.allocUnsafe(13);
  ihdr.writeUInt32BE(size,0);ihdr.writeUInt32BE(size,4);
  ihdr[8]=8;ihdr[9]=2;ihdr[10]=0;ihdr[11]=0;ihdr[12]=0;
  const rowSize=1+size*3;
  const raw=Buffer.allocUnsafe(size*rowSize);
  for(let y=0;y<size;y++){
    raw[y*rowSize]=0;
    for(let x=0;x<size;x++){
      const src=(y*size+x)*3;
      raw[y*rowSize+1+x*3]=pixels[src];
      raw[y*rowSize+1+x*3+1]=pixels[src+1];
      raw[y*rowSize+1+x*3+2]=pixels[src+2];
    }
  }
  return Buffer.concat([sig,chunk('IHDR',ihdr),chunk('IDAT',zlib.deflateSync(raw)),chunk('IEND',Buffer.alloc(0))]);
}

const base = path.join(__dirname, 'android', 'app', 'src', 'main', 'res');
const sizes = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

for (const [folder, size] of Object.entries(sizes)) {
  const dir = path.join(base, folder);
  fs.mkdirSync(dir, { recursive: true });
  const png = createIconPNG(size);
  fs.writeFileSync(path.join(dir, 'ic_launcher.png'), png);
  fs.writeFileSync(path.join(dir, 'ic_launcher_round.png'), png);
  console.log(`OK ${folder} ${size}x${size} (${png.length} bytes)`);
}
console.log('Icones criados com sucesso!');
