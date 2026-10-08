"""Validate the actual first-stage exports, not application behavior."""
import json
from pathlib import Path
from xml.etree import ElementTree as ET
from PIL import Image, ImageFont
from generate import COPY, PATHS, ROOT

checks=[]
def check(name,ok):
 checks.append({'check':name,'passed':bool(ok)})

check('RU/KK translation key parity',COPY['ru'].keys()==COPY['kk'].keys())
check('Distinct icon geometries',len(set(PATHS.values()))==len(PATHS))
index=json.loads((ROOT/'design/index.json').read_text())
check('60 independent references',len(index)==60 and len({x['source'] for x in index})==60)
fontpath='/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf'
overflow=[]
for item in index:
 path=ROOT/'design'/item['source'];tree=ET.parse(path);w=int(tree.getroot().attrib['width']);h=int(tree.getroot().attrib['height'])
 expected=(390,844) if item['platform']=='ios' else (412,915)
 check(path.stem+' frame size',(w,h)==expected)
 with Image.open(ROOT/'design'/item['image']) as im:check(path.stem+' PNG size',im.size==(w*2,h*2))
 text=' '.join(el.text or '' for el in tree.iter() if el.tag.endswith('text'))
 check(path.stem+' demo disclosure',COPY[item['locale']]['demo'] in text or COPY[item['locale']]['synthetic'] in text or item['screen'] in ['S01','S02','S13','S14','S15'])
 for el in tree.iter():
  if not el.tag.endswith('text') or not el.text:continue
  # Map labels are inside translated groups; test all app text outside those groups.
  if el.text in ['A','B']:continue
  font=ImageFont.truetype(fontpath,int(float(el.attrib['font-size'])*10))
  width=font.getlength(el.text)/10
  x=float(el.attrib['x']);y=float(el.attrib['y']);anchor=el.attrib['text-anchor']
  left=x-width if anchor=='end' else x-width/2 if anchor=='middle' else x
  if left<0 or left+width>w or y>h or y<0:overflow.append({'file':path.name,'text':el.text,'left':round(left,1),'right':round(left+width,1)})
check('Text within frame (Noto Sans measurement)',not overflow)
for name in PATHS:
 check(name+' separate SVG',(ROOT/f'assets/icons/{name}.svg').is_file())
 for density in [1,2,3]:
  with Image.open(ROOT/f'assets/icons/{name}@{density}x.png') as im:check(name+f' PNG {density}x transparency',im.mode=='RGBA' and im.size==(24*density,24*density) and im.getextrema()[3][0]==0)
report={'scope':'Design artifacts only; no Android/iOS runtime validation','checks':checks,'overflow':overflow,'passed':sum(c['passed'] for c in checks),'failed':sum(not c['passed'] for c in checks)}
(ROOT/'design/validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps({k:report[k] for k in ['passed','failed','overflow']},ensure_ascii=False,indent=2))
raise SystemExit(1 if report['failed'] else 0)
