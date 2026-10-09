#!/usr/bin/env python3
"""Run the tested same-origin site and API; secrets stay outside the web root."""
import argparse,json,os,sys,webbrowser
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--secrets',type=Path);p.add_argument('--web-dir',type=Path,default=Path('build/web'));p.add_argument('--web-path',default='/SAQQO');p.add_argument('--host',default='127.0.0.1');p.add_argument('--port',type=int,default=8765);p.add_argument('--open',action='store_true');args=p.parse_args()
root=Path(__file__).resolve().parents[1];server=root/'server';sys.path.insert(0,str(server))
if args.secrets:
 values=json.loads(args.secrets.read_text());os.environ.update({k:v for k,v in values.items() if k.startswith('YANDEX_') and isinstance(v,str)})
os.environ['SAQGO_WEB_DIR']=str(args.web_dir.resolve());os.environ['SAQGO_WEB_PATH']=args.web_path
os.environ.setdefault('SAQGO_DATA_FILE',str(root/'data'/'saqgo.sqlite3'))
url=f'http://127.0.0.1:{args.port}{args.web_path}/';print('Open the presentation site:',url)
if args.open:webbrowser.open(url)
import uvicorn
uvicorn.run('app.main:app',host=args.host,port=args.port,access_log=False)
