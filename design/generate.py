"""Reproducible, editable first-stage SAQGO designs. No real telemetry/geodata."""
from pathlib import Path
from html import escape
import csv
import json
import cairosvg
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design' / 'exports'
ICONS = ROOT / 'assets' / 'icons'
BRANDING = ROOT / 'assets' / 'branding'
OUT.mkdir(parents=True, exist_ok=True)
ICONS.mkdir(parents=True, exist_ok=True)
BRANDING.mkdir(parents=True, exist_ok=True)
NAVY, PANEL, LINE, WHITE, MUTED, BLUE, CYAN = '#0B1220', '#152033', '#29394E', '#F4F7FC', '#A7B5CA', '#4C8DFF', '#70D5DA'
PATHS = {
 'map':'<path d="m3 5 6-2 6 2 6-2v16l-6 2-6-2-6 2Z M9 3v16 M15 5v16"/>',
 'route':'<circle cx="5" cy="5" r="2"/><circle cx="19" cy="19" r="2"/><path d="M7 5h8a4 4 0 0 1 0 8H9a4 4 0 0 0 0 6h8"/>',
 'sensors':'<path d="M2 12h4l3-7 5 14 3-7h5"/>',
 'road_risk':'<path d="m7 3-4 18 M17 3l4 18 M12 3v4m0 3v3m0 4v4 M5 15l4-2 3 2 3-2 4 2"/>',
 'hazards':'<path d="m12 3 10 18H2Z M12 9v5"/><circle cx="12" cy="17" r=".6"/>',
 'layers':'<path d="m12 3 10 5-10 5L2 8Z M2 12l10 5 10-5 M2 16l10 5 10-5"/>',
 'lifelog':'<path d="M5 4h14v17H5Z M8 2v4 M16 2v4 M8 10h8 M8 14h5"/>',
 'pulse':'<path d="M3 8h4v13H3Z M10 3h4v18h-4Z M17 11h4v10h-4Z"/>',
 'sos':'<path d="M8 3h8v5h5v8h-5v5H8v-5H3V8h5Z"/>',
 'profile':'<circle cx="12" cy="7" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2"/>',
 'search':'<circle cx="10" cy="10" r="6"/><path d="m15 15 6 6"/>',
 'filter':'<path d="M3 5h18l-7 8v7l-4-2v-5Z"/>',
 'locate':'<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/><path d="M12 1v4 M12 19v4 M1 12h4 M19 12h4"/>',
 'back':'<path d="m14 4-8 8 8 8 M6 12h15"/>',
 'close':'<path d="m5 5 14 14 M19 5 5 19"/>',
 'pause':'<path d="M7 4v16 M17 4v16"/>',
 'play':'<path d="m7 3 14 9-14 9Z"/>',
 'stop':'<rect x="5" y="5" width="14" height="14" rx="2"/>',
 'calendar':'<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18 M7 2v6 M17 2v6 M7 14h3 M14 14h3"/>',
 'alert':'<path d="M5 17h14l-2-4V9a5 5 0 0 0-10 0v4Z M10 21h4 M12 1v3"/>',
 'settings':'<path d="M3 6h18 M3 12h18 M3 18h18"/><circle cx="8" cy="6" r="2"/><circle cx="16" cy="12" r="2"/><circle cx="9" cy="18" r="2"/>',
 'no_internet':'<path d="M2 6a17 17 0 0 1 20 0 M5 10a12 12 0 0 1 14 0 M9 14a5 5 0 0 1 6 0 M3 3l18 18"/><circle cx="12" cy="18" r="1"/>',
 'empty_data':'<path d="M3 8h18v13H3Z M3 8l4-5h10l4 5 M8 13h8 M12 13v4"/>',
 'no_gps':'<path d="M12 22s8-8 8-14A8 8 0 0 0 4 8c0 6 8 14 8 14Z M3 3l18 18"/>',
 'gps_weak':'<path d="M12 22s8-8 8-14A8 8 0 0 0 4 8c0 6 8 14 8 14Z M12 5v5"/><circle cx="12" cy="13" r=".6"/>',
 'permission_denied':'<path d="m12 2 9 4v6c0 5-9 10-9 10S3 17 3 12V6Z M8 12h8"/>',
 'demo_mode':'<rect x="2" y="4" width="20" height="16" rx="3"/><path d="m10 8 6 4-6 4Z"/>',
 'phone':'<path d="M5 3h4l2 5-3 2a16 16 0 0 0 6 6l2-3 5 2v4c0 5-9 1-14-4S0 3 5 3Z"/>',
 'delete':'<path d="M3 6h18 M9 6V3h6v3 M5 6l1 15h12l1-15 M10 10v7 M14 10v7"/>',
 'privacy':'<path d="m12 2 9 4v6c0 5-9 10-9 10S3 17 3 12V6Z"/><path d="m7 12 3 3 7-7"/>',
 'logo':'<path d="m12 2 9 5v10l-9 5-9-5V7Z M7 15l5-8 5 8 M9 12h6"/>',
}

COPY = {
 'ru':{
 'city':'Аркалык', 'map':'Карта', 'route':'Маршруты', 'history':'История', 'settings':'Настройки',
 'demo':'Демо-данные', 'synthetic':'Демо-карта · не геоданные', 'map_note':'Картографический источник не подключён',
 'search':'Найти место', 'overview':'Город в одном взгляде', 'no_risk':'Нет проверенных данных о рисках',
 'layers':'Слои карты', 'bumps':'Неровности дороги', 'ice':'Возможный гололёд', 'hazards':'Возможные риски', 'pulse':'Активность города',
 'scan':'Сканировать', 'scan_title':'Анализ датчиков', 'scan_sub':'Только с вашего согласия',
 'from':'Откуда', 'to':'Куда', 'point_a':'Тестовая точка А', 'point_b':'Тестовая точка Б',
 'fast':'Более быстрый', 'less':'Меньше известных рисков', 'fast_val':'12 мин', 'less_val':'16 мин',
 'distance_a':'1,2 км · пешком', 'distance_b':'1,5 км · пешком', 'risk_unknown':'Риски: недостаточно данных',
 'route_warning':'Маршрут не гарантирует безопасность', 'route_cta':'Посмотреть демо-маршрут',
 'gps':'GPS не подключён', 'sensor_fixture':'Синтетический сигнал · не запись датчиков',
 'duration':'Длительность', 'candidates':'Кандидаты', 'start':'Начать запись', 'pause':'Пауза', 'stop':'Стоп',
 'session_note':'Запись ещё не начата. Данные не собираются.', 'no_ice':'Датчики не определяют лёд или открытые люки.',
 'lifelog':'Моя история', 'local':'Данные хранятся на устройстве', 'month':'Октябрь 2026',
 'days':['П','В','С','Ч','П','С','В'], 'selected':'9 октября · демонстрация',
 'trip':'Демо-прогулка', 'trip_meta':'12 мин · 1,2 км · синтетический трек', 'timeline':'Детали дня',
 'delete':'Удалить историю', 'delete_note':'Тестовый пример, не ваша личная история',
 'sos':'Экстренная помощь', 'sos_sub':'Когда помощь нужна сейчас', 'call':'Позвонить 112',
 'dialer':'Открывает системный набор номера', 'connection':'Для звонка нужна доступная мобильная сеть',
 'auto':'Автоматическая отправка помощи не выполняется', 'steps_title':'Во время звонка',
 'steps':['Назовите место и что произошло.', 'Следуйте указаниям диспетчера.', 'Оставайтесь на связи, если это возможно.'],
 'ble':'Bluetooth: исследовательский режим', 'ble_note':'Не отправляет сигнал спасателям',
 },
 'kk':{
 'city':'Арқалық', 'map':'Карта', 'route':'Бағыттар', 'history':'Тарих', 'settings':'Баптаулар',
 'demo':'Демо-деректер', 'synthetic':'Демо-карта · геодеректер емес', 'map_note':'Карта дереккөзі қосылмаған',
 'search':'Орынды табу', 'overview':'Қалаға бір көзқарас', 'no_risk':'Қауіптер туралы расталған дерек жоқ',
 'layers':'Карта қабаттары', 'bumps':'Жолдың кедір-бұдыр жерлері', 'ice':'Көктайғақ болуы мүмкін', 'hazards':'Ықтимал қауіптер', 'pulse':'Қала белсенділігі',
 'scan':'Талдау', 'scan_title':'Датчик деректерін талдау', 'scan_sub':'Тек сіздің келісіміңізбен',
 'from':'Қайдан', 'to':'Қайда', 'point_a':'Сынақ нүктесі А', 'point_b':'Сынақ нүктесі Б',
 'fast':'Жылдамырақ', 'less':'Белгілі қауіптері азырақ', 'fast_val':'12 мин', 'less_val':'16 мин',
 'distance_a':'1,2 км · жаяу', 'distance_b':'1,5 км · жаяу', 'risk_unknown':'Қауіптер: дерек жеткіліксіз',
 'route_warning':'Бағыт қауіпсіздікке кепілдік бермейді', 'route_cta':'Демо-бағытты көру',
 'gps':'GPS қосылмаған', 'sensor_fixture':'Синтетикалық сигнал · датчик жазбасы емес',
 'duration':'Ұзақтығы', 'candidates':'Үміткерлер', 'start':'Жазуды бастау', 'pause':'Үзіліс', 'stop':'Тоқтату',
 'session_note':'Жазу басталған жоқ. Деректер жиналмайды.', 'no_ice':'Датчиктер мұзды не ашық люктерді анықтамайды.',
 'lifelog':'Менің тарихым', 'local':'Деректер құрылғыда сақталады', 'month':'Қазан 2026',
 'days':['Д','С','С','Б','Ж','С','Ж'], 'selected':'9 қазан · демонстрация',
 'trip':'Демо-серуен', 'trip_meta':'12 мин · 1,2 км · синтетикалық жол', 'timeline':'Күн мәліметтері',
 'delete':'Тарихты жою', 'delete_note':'Сынақ мысалы, сіздің жеке тарихыңыз емес',
 'sos':'Шұғыл көмек', 'sos_sub':'Көмек дәл қазір қажет болса', 'call':'112 нөміріне қоңырау шалу',
 'dialer':'Жүйелік нөмір теруді ашады', 'connection':'Қоңырау үшін қолжетімді мобильді желі қажет',
 'auto':'Көмек сұрауы автоматты түрде жіберілмейді', 'steps_title':'Қоңырау кезінде',
 'steps':['Орныңызды және болған жағдайды айтыңыз.', 'Диспетчер нұсқауларын орындаңыз.', 'Мүмкін болса, байланыста болыңыз.'],
 'ble':'Bluetooth: зерттеу режимі', 'ble_note':'Құтқарушыларға сигнал жібермейді',
 },
}

class Canvas:
 def __init__(self,w,h):
  self.w,self.h=w,h
  self.parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',f'<rect width="{w}" height="{h}" fill="{NAVY}"/>']
 def add(self,s): self.parts.append(s)
 def rect(self,x,y,w,h,fill=PANEL,r=16,stroke=None):
  self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"'+(f' stroke="{stroke}"' if stroke else '')+'/>')
 def text(self,x,y,t,size=14,color=WHITE,weight=400,anchor='start'):
  self.add(f'<text x="{x}" y="{y}" font-family="Noto Sans, DejaVu Sans, sans-serif" font-size="{size}" font-weight="{weight}" fill="{color}" text-anchor="{anchor}">{escape(str(t))}</text>')
 def icon(self,name,x,y,size=24,color=MUTED):
  self.add(f'<g transform="translate({x} {y}) scale({size/24})" fill="none" stroke="{color}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">{PATHS[name]}</g>')
 def lines(self,x,y,items,size=13,color=MUTED,gap=23):
  for i,t in enumerate(items): self.text(x,y+i*gap,t,size,color)
 def button(self,y,t,icon=None,color=BLUE):
  self.rect(24,y,self.w-48,52,color,16)
  self.text(self.w/2+(12 if icon else 0),y+33,t,14,NAVY,600,'middle')
  if icon:self.icon(icon,40,y+14,24,NAVY)
 def badge(self,x,y,t):
  self.rect(x,y,len(t)*6.4+22,26,'#203A50',13)
  self.text(x+11,y+18,t,10,CYAN,600)
 def save(self,path):
  raw=''.join(self.parts)+'</svg>'
  path.write_text(raw)
  cairosvg.svg2png(bytestring=raw.encode(),write_to=str(path.with_suffix('.png')),scale=2)

def demo_map(c,x,y,w,h,route=False):
 """Schematic drawing deliberately has no geographic claims or fake street names."""
 c.rect(x,y,w,h,'#0F1C2A',20)
 c.add(f'<g transform="translate({x} {y})"><defs><clipPath id="mapclip"><rect width="{w}" height="{h}" rx="20"/></clipPath></defs><g clip-path="url(#mapclip)">')
 for j in range(6):
  for i in range(5):
   bx,by=i*90-35+(j%2)*20,j*77-10
   c.rect(bx,by,65,52,'#182839',5)
 c.add(f'<path d="M-30 {h*.7} Q120 {h*.35} {w+30} {h*.42}" stroke="#244347" stroke-width="40" fill="none"/>')
 for dx in [-80,30,140,250,360]:
  c.add(f'<path d="M{dx} -30 {dx+160} {h+50}" stroke="#39485B" stroke-width="9" fill="none"/>')
 for dy in [90,205,330,440]:
  c.add(f'<path d="M-20 {dy} {w+30} {dy-60}" stroke="#39485B" stroke-width="8" fill="none"/>')
 if route:
  c.add(f'<path d="M{w*.22} {h*.75} L{w*.44} {h*.64} L{w*.36} {h*.34} L{w*.77} {h*.24}" stroke="{BLUE}" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
  for px,py,label in [(w*.22,h*.75,'A'),(w*.77,h*.24,'B')]:
   c.add(f'<circle cx="{px}" cy="{py}" r="12" fill="{WHITE}"/>')
   c.text(px,py+4,label,11,NAVY,600,'middle')
 else:
  c.add(f'<circle cx="{w*.5}" cy="{h*.48}" r="26" fill="{BLUE}" opacity=".12"/><circle cx="{w*.5}" cy="{h*.48}" r="6" fill="{BLUE}" stroke="{WHITE}" stroke-width="2"/>')
 c.add('</g></g>')

def system(c,platform):
 c.text(24,30,'9:41',13,WHITE,600)
 if platform=='ios':c.rect(c.w/2-48,10,96,27,'#030810',14)
 else:c.add(f'<circle cx="{c.w/2}" cy="19" r="5" fill="#030810"/>')
 c.add(f'<path d="M{c.w-69} 28v-4m5 4v-7m5 7v-10" stroke="{WHITE}" stroke-width="2"/>')
 c.rect(c.w-42,19,20,10,NAVY,3,WHITE)
 c.rect(c.w-40,21,14,6,WHITE,1)
 c.rect(c.w/2-60,c.h-13,120,4,WHITE,2)

def nav(c,t,active):
 y=c.h-92
 c.rect(0,y,c.w,68,NAVY,0)
 c.add(f'<path d="M0 {y}H{c.w}" stroke="{LINE}"/>')
 for i,(ic,key) in enumerate([('map','map'),('route','route'),('lifelog','history'),('settings','settings')]):
  x=c.w*(i+.5)/4
  col=BLUE if key==active else MUTED
  c.icon(ic,x-11,y+12,22,col)
  c.text(x,y+51,t[key],10,col,500,'middle')

def header(c,title,subtitle):
 c.icon('back',24,62,22)
 c.text(58,79,title,21,WHITE,600)
 c.text(24,111,subtitle,12,MUTED)

def screen(sid,locale,platform):
 t=COPY[locale];w,h=(390,844) if platform=='ios' else (412,915)
 c=Canvas(w,h);system(c,platform)
 if sid=='S03':
  demo_map(c,0,48,w,h-140)
  c.rect(16,58,w-32,90,NAVY,18,LINE)
  c.text(32,85,'SAQGO',19,WHITE,700);c.text(w-32,85,t['city'],15,MUTED,500,'end')
  c.badge(32,98,t['synthetic']);c.text(32,134,t['map_note'],10,MUTED)
  c.rect(w-64,170,48,48,NAVY,14,LINE);c.icon('layers',w-52,182)
  c.rect(w-64,228,48,48,NAVY,14,LINE);c.icon('locate',w-52,240)
  c.rect(16,170,64,44,'#432832',14);c.text(48,198,'SOS',14,'#FFB0B8',600,'middle')
  y=h-430;c.rect(16,y,w-32,324,PANEL,24,LINE);c.rect(w/2-18,y+11,36,3,'#536176',2)
  c.text(32,y+47,t['overview'],19,WHITE,600)
  c.text(32,y+70,t['no_risk'],11,MUTED)
  c.rect(32,y+88,w-64,44,'#0C1726',12);c.icon('search',44,y+100,20);c.text(74,y+116,t['search'],13,MUTED)
  for i,(ic,key) in enumerate([('road_risk','bumps'),('hazards','hazards'),('gps_weak','ice'),('pulse','pulse')]):
   xx=32+(i%2)*((w-64)/2);yy=y+153+(i//2)*40
   c.icon(ic,xx,yy,18);c.text(xx+26,yy+14,t[key],10,MUTED)
  c.rect(32,y+246,w-64,52,BLUE,14);c.icon('route',48,y+260,24,NAVY);c.text(w/2+9,y+279,t['route'],15,NAVY,600,'middle')
  nav(c,t,'map')
 elif sid=='S08':
  header(c,t['route'],t['demo']);
  c.rect(24,135,w-48,120,PANEL,18,LINE)
  for i,(label,val,ic) in enumerate([(t['from'],t['point_a'],'locate'),(t['to'],t['point_b'],'map')]):
   yy=158+i*54;c.icon(ic,40,yy,20,BLUE);c.text(72,yy+1,label,10,MUTED);c.text(72,yy+24,val,15,WHITE,500)
  c.add(f'<path d="M72 195H{w-40}" stroke="{LINE}"/>')
  demo_map(c,24,271,w-48,178,True);c.badge(36,283,t['synthetic'])
  for i,(label,val,dist) in enumerate([(t['fast'],t['fast_val'],t['distance_a']),(t['less'],t['less_val'],t['distance_b'])]):
   yy=465+i*92;c.rect(24,yy,w-48,80,PANEL,16,BLUE if i==0 else LINE)
   c.text(40,yy+26,label,13,WHITE,600);c.text(w-40,yy+29,val,21,WHITE,600,'end')
   c.text(40,yy+48,dist,11,MUTED);c.text(40,yy+67,t['risk_unknown'],10,CYAN)
  c.text(24,670,t['route_warning'],11,MUTED)
  c.button(h-160,t['route_cta']);nav(c,t,'route')
 elif sid=='S06':
  header(c,t['scan_title'],t['scan_sub']);c.badge(24,135,t['demo'])
  c.rect(24,177,w-48,215,PANEL,20,LINE)
  c.text(40,207,t['duration'],12,MUTED);c.text(40,257,'00:00',42,WHITE,500)
  c.text(w-40,207,t['candidates'],12,MUTED,400,'end');c.text(w-40,257,'0',42,WHITE,500,'end')
  for yy in [287,315,343]:c.add(f'<path d="M40 {yy}H{w-40}" stroke="{LINE}"/>')
  points=' '.join(f'{40+i*(w-80)/50},{316+([0,2,-2,1,0,-4,3,0,1,-1][i%10])}' for i in range(51))
  c.add(f'<polyline points="{points}" fill="none" stroke="{CYAN}" stroke-width="2"/>')
  c.text(40,375,t['sensor_fixture'],9,MUTED)
  c.rect(24,408,w-48,58,'#152B38',16);c.icon('no_gps',40,425,24,CYAN);c.text(78,442,t['gps'],13,CYAN)
  c.text(24,497,t['session_note'],11,MUTED)
  c.button(522,t['start'],'play')
  for i,(ic,key) in enumerate([('pause','pause'),('stop','stop')]):
   xx=24+i*(w-40)/2;c.rect(xx,588,(w-56)/2,52,PANEL,16,LINE);c.icon(ic,xx+16,603,22);c.text(xx+50,620,t[key],13,MUTED)
  c.text(24,677,t['no_ice'],10,MUTED);c.text(24,700,t['demo'],10,CYAN)
  nav(c,t,'map')
 elif sid=='S11':
  header(c,t['lifelog'],t['local']);c.badge(24,133,t['demo'])
  c.rect(24,174,w-48,264,PANEL,20,LINE);c.text(40,205,t['month'],17,WHITE,600);c.icon('calendar',w-64,185)
  cw=(w-80)/7
  for i,day in enumerate(t['days']):c.text(40+cw*(i+.5),239,day,11,MUTED,500,'middle')
  for n in range(1,32):
   slot=n+2;xx=40+cw*(slot%7+.5);yy=267+(slot//7)*32
   if n==9:c.rect(xx-15,yy-21,30,30,BLUE,10)
   c.text(xx,yy,n,12,NAVY if n==9 else WHITE,500,'middle')
  c.text(24,468,t['selected'],15,WHITE,600)
  c.rect(24,486,w-48,97,PANEL,16,LINE);c.icon('route',40,507,24,BLUE);c.text(78,517,t['trip'],14,WHITE,500);c.text(78,540,t['trip_meta'],9,MUTED);c.text(78,563,t['timeline'],11,BLUE)
  demo_map(c,24,599,w-48,80,True);c.badge(34,607,t['synthetic'])
  c.text(24,701,t['delete_note'],10,MUTED)
  c.icon('delete',24,h-127,18,'#FFB0B8');c.text(52,h-112,t['delete'],12,'#FFB0B8')
  nav(c,t,'history')
 elif sid=='S13':
  header(c,t['sos'],t['sos_sub'])
  c.rect(w/2-38,143,76,76,'#432832',24);c.icon('sos',w/2-18,161,36,'#FFB0B8')
  c.text(w/2,257,'112',52,WHITE,600,'middle')
  c.button(287,t['call'],'phone',color='#FFB0B8');c.text(w/2,361,t['dialer'],11,MUTED,400,'middle')
  c.rect(24,384,w-48,79,PANEL,16,LINE);c.icon('no_internet',40,406,22,MUTED)
  if locale=='ru':lines=['Для звонка нужна доступная', 'мобильная сеть.']
  else:lines=['Қоңырау үшін қолжетімді', 'мобильді желі қажет.']
  c.lines(76,410,lines,12,MUTED,23)
  c.text(24,500,t['steps_title'],16,WHITE,600)
  for i,step in enumerate(t['steps']):
   c.rect(24,519+i*39,24,24,'#203A50',8);c.text(36,536+i*39,i+1,11,CYAN,600,'middle');c.text(60,536+i*39,step,10,WHITE)
  c.rect(24,654,w-48,66,PANEL,16,LINE);c.text(40,680,t['ble'],11,WHITE,500);c.text(40,703,t['ble_note'],10,MUTED)
  c.text(24,740,t['auto'],10,MUTED);nav(c,t,'')
 else:
  # Remaining S01–S15 screens use the same real component system, not a shared image.
  titles={'S01':t['language'] if 'language' in t else 'Тіл / Язык','S02':'SAQGO','S04':t['layers'],'S05':t['hazards'],'S07':t['timeline'],'S09':t['route'],'S10':t['pulse'],'S12':t['timeline'],'S14':t['settings'],'S15':'Admin'}
  icons={'S01':'logo','S02':'privacy','S04':'layers','S05':'hazards','S07':'route','S09':'route','S10':'pulse','S12':'lifelog','S14':'settings','S15':'profile'}
  header(c,titles[sid],t['demo'] if sid not in ['S01','S02','S14'] else t['local'])
  c.rect(24,142,w-48,114,PANEL,20,LINE);c.icon(icons[sid],40,166,32,BLUE);c.text(84,180,titles[sid],18,WHITE,600);c.text(84,207,t['synthetic'] if sid not in ['S01','S02','S14'] else t['local'],11,MUTED)
  if sid in ['S05','S07','S09','S12']:
   demo_map(c,24,278,w-48,210,True);c.badge(36,291,t['synthetic'])
  elif sid=='S10':
   for yy in range(0,3):
    for xx in range(0,4):c.rect(30+xx*((w-76)/4),285+yy*70,(w-100)/4,52,'#203A50' if (xx+yy)%3==0 else PANEL,12)
   c.text(24,515,t['pulse'],17,WHITE,600);c.text(24,541,t['synthetic'],11,MUTED)
  elif sid=='S01':
   c.text(w/2,330,'SAQGO',34,WHITE,700,'middle');c.rect(24,390,w-48,52,PANEL,16,LINE);c.text(w/2,423,'Қазақша',15,WHITE,600,'middle');c.rect(24,454,w-48,52,PANEL,16,LINE);c.text(w/2,487,'Русский',15,WHITE,600,'middle')
  elif sid=='S02':
   for i,(ic,label) in enumerate([('hazards',t['hazards']),('privacy',t['local']),('no_gps',t['gps'])]):
    yy=285+i*74;c.rect(24,yy,w-48,62,PANEL,16,LINE);c.icon(ic,40,yy+19,24,BLUE);c.text(78,yy+36,label,13,WHITE,500)
  else:
   for i,(ic,label) in enumerate([('privacy',t['local']),('no_gps',t['gps']),('alert',t['demo'])]):
    yy=285+i*74;c.rect(24,yy,w-48,62,PANEL,16,LINE);c.icon(ic,40,yy+19,24,BLUE);c.text(78,yy+36,label,13,WHITE,500)
  c.button(h-180,t['continue'] if 'continue' in t else t['start'],'play')
  nav(c,t,'settings' if sid in ['S14','S15'] else 'map')
 return c

def generate():
 for name,path in PATHS.items():
  raw=f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="{WHITE}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">{path}</g></svg>'
  (ICONS/f'{name}.svg').write_text(raw)
  for density in [1,2,3]:cairosvg.svg2png(bytestring=raw.encode(),write_to=str(ICONS/f'{name}@{density}x.png'),scale=density)
 with (ROOT/'assets/assets_manifest.csv').open('w') as f:
  writer=csv.writer(f, lineterminator='\n');writer.writerow(['name','source','format','size','rights','purpose'])
  for name in PATHS:writer.writerow([name,'Original SAQGO vector geometry','SVG + PNG 1x/2x/3x','24dp','MIT (see LICENSE)',name])
  brand_svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><rect width="1024" height="1024" rx="224" fill="#0B1220"/><path d="M512 170 854 360v380L512 930 170 740V360Z M322 670l190-318 190 318 M398 550h228" fill="none" stroke="#70D5DA" stroke-width="58" stroke-linecap="round" stroke-linejoin="round"/></svg>'''
  (BRANDING/'saqgo_app_icon.svg').write_text(brand_svg)
  cairosvg.svg2png(bytestring=brand_svg.encode(),write_to=str(BRANDING/'saqgo_app_icon_1024.png'),output_width=1024,output_height=1024)
  splash_svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><rect width="1024" height="1024" fill="#0B1220"/><path d="M512 290 734 413v246L512 782 290 659V413Z M389 615l123-206 123 206 M438 537h148" fill="none" stroke="#70D5DA" stroke-width="42" stroke-linecap="round" stroke-linejoin="round"/></svg>'''
  (BRANDING/'saqgo_splash_symbol.svg').write_text(splash_svg)
  cairosvg.svg2png(bytestring=splash_svg.encode(),write_to=str(BRANDING/'saqgo_splash_symbol_1024.png'),output_width=1024,output_height=1024)
  with (ROOT/'assets/assets_manifest.csv').open('a') as f:
   writer=csv.writer(f, lineterminator='\n')
   writer.writerow(['saqgo_app_icon','Original SAQGO vector geometry','SVG + PNG','1024px','MIT (see LICENSE)','app icon'])
   writer.writerow(['saqgo_splash_symbol','Original SAQGO vector geometry','SVG + PNG','1024px','MIT (see LICENSE)','splash symbol'])
 index=[]
 for sid in ['S01','S02','S03','S04','S05','S06','S07','S08','S09','S10','S11','S12','S13','S14','S15']:
  for lang in COPY:
   for platform in ['ios','android']:
    name=f'{sid}_{lang}_{platform}';screen(sid,lang,platform).save(OUT/f'{name}.svg')
    index.append({'screen':sid,'locale':lang,'platform':platform,'image':f'exports/{name}.png','source':f'exports/{name}.svg'})
 (ROOT/'design/index.json').write_text(json.dumps(index,ensure_ascii=False,indent=2))
 # Contact sheet is a presentation artifact; separate SVGs remain the editable sources.
 font='/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf'
 board=Image.new('RGB',(2220,1140),NAVY);draw=ImageDraw.Draw(board)
 draw.text((52,35),'SAQGO / 01',font=ImageFont.truetype(font,26),fill=CYAN)
 draw.text((52,83),'Город рядом. Решения — осознанно.',font=ImageFont.truetype(font,38),fill=WHITE)
 draw.text((52,146),'Первые пять экранов · RU / iOS · демо-карта и синтетические данные',font=ImageFont.truetype(font,20),fill=MUTED)
 for i,sid in enumerate(['S03','S08','S06','S11','S13']):
  im=Image.open(OUT/f'{sid}_ru_ios.png').convert('RGB');im.thumbnail((390,844))
  board.paste(im,(52+i*433,211));draw.text((52+i*433,1080),sid,font=ImageFont.truetype(font,18),fill=MUTED)
 board.save(ROOT/'design/overview.png')
 # Moodboard uses original abstract material, no claimed city photography.
 m=Canvas(1160,760)
 m.text(48,67,'SAQGO / VISUAL DIRECTION',17,CYAN,600)
 m.text(48,131,'Ясность. Контроль. Город.',40,WHITE,600)
 m.text(48,172,'Минимализм для городской мобильности · концепция 01',18,MUTED)
 for i,(color,label) in enumerate([(NAVY,'Night Navy'),(PANEL,'Surface'),(BLUE,'Electric Blue'),(CYAN,'Cyan'),('#FFB0B8','SOS')]):
  m.rect(48+i*218,214,194,90,color,20,LINE);m.text(48+i*218,336,label,14,WHITE,500);m.text(48+i*218,362,color,12,MUTED)
 m.rect(48,402,476,254,PANEL,24,LINE);m.text(72,442,'Noto Sans',27,WHITE,600)
 m.text(72,487,'Арқалық / Аркалык',25,WHITE);m.text(72,529,'Ә Ғ Қ Ң Ө Ұ Ү Һ І',25,CYAN)
 m.text(72,568,'8 pt · 16 / 24 radius · 48+ targets',15,MUTED)
 for i,ic in enumerate(['map','route','sensors','lifelog','sos','privacy']):m.icon(ic,72+i*67,604,28,WHITE)
 demo_map(m,556,402,556,254,True);m.badge(578,422,'Демо-карта · не геоданные')
 m.text(48,710,'Оригинальные векторы / без фотографий, неона и утверждений о безопасности',16,MUTED)
 m.save(ROOT/'design/moodboard.svg')
 print(f'Exported {len(index)} independent screen pairs (SVG + PNG), {len(PATHS)} icons, overview and moodboard.')

if __name__=='__main__':generate()
