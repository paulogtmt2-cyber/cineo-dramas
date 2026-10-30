"""Cineo development API. Put behind HTTPS before connecting physical devices."""
import base64, hashlib, hmac, json, os, secrets, sqlite3, time
from pathlib import Path
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(os.environ.get('CINEO_DATA', './data'))
ROOT.mkdir(parents=True, exist_ok=True)
def db():
    c = sqlite3.connect(ROOT / 'cineo.sqlite')
    c.row_factory = sqlite3.Row
    return c
def init():
    with db() as c:
        c.executescript('''
        CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY,email TEXT UNIQUE,password TEXT,role TEXT DEFAULT 'creator');
        CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY,user_id INTEGER,expires INTEGER);
        CREATE TABLE IF NOT EXISTS shows(id INTEGER PRIMARY KEY,owner INTEGER,title TEXT,synopsis TEXT,status TEXT DEFAULT 'draft',reason TEXT DEFAULT '');
        CREATE TABLE IF NOT EXISTS episodes(id INTEGER PRIMARY KEY,show_id INTEGER,title TEXT,file TEXT);
        CREATE TABLE IF NOT EXISTS audit(id INTEGER PRIMARY KEY,show_id INTEGER,admin INTEGER,decision TEXT,reason TEXT,at INTEGER);
        ''')
def password(value, salt=None):
    salt = salt or secrets.token_hex(16)
    return salt + ':' + hashlib.scrypt(value.encode(),salt=salt.encode(),n=16384,r=8,p=1).hex()
def require(ok, message, code=400):
    if not ok: raise ApiError(message, code)
class ApiError(Exception):
    def __init__(self, message, code=400): self.message,self.code=message,code
def action(method, path, data, token=''):
    with db() as c:
        user=c.execute('SELECT u.* FROM users u JOIN sessions s ON s.user_id=u.id WHERE s.token=? AND s.expires>?',(token,time.time())).fetchone()
        if path in ('/register','/login') and method=='POST':
            email=str(data.get('email','')).strip().lower(); pw=str(data.get('password',''))
            require('@' in email and 10<=len(pw)<=200,'Informe email e senha com pelo menos 10 caracteres.')
            if path=='/register':
                try: c.execute('INSERT INTO users(email,password) VALUES (?,?)',(email,password(pw)))
                except sqlite3.IntegrityError: raise ApiError('Conta já cadastrada.',409)
            u=c.execute('SELECT * FROM users WHERE email=?',(email,)).fetchone()
            require(u and hmac.compare_digest(u['password'],password(pw,u['password'].split(':')[0])),'Credenciais inválidas.',401)
            t=secrets.token_urlsafe(32)
            c.execute('INSERT INTO sessions VALUES (?,?,?)',(t,u['id'],int(time.time())+86400))
            return {'token':t,'role':u['role']}
        if path=='/catalog' and method=='GET':
            return {'items':[dict(r) for r in c.execute("SELECT id,title,synopsis,status FROM shows WHERE status='approved' ORDER BY id DESC")]}
        require(user is not None,'Entre na sua conta.',401)
        uid=user['id']; admin=user['role']=='admin'
        if path=='/logout' and method=='POST':
            c.execute('DELETE FROM sessions WHERE token=?',(token,)); return {'ok':True}
        if path=='/mine' and method=='GET':
            return {'items':[dict(r) for r in c.execute('SELECT * FROM shows WHERE owner=? ORDER BY id DESC',(uid,))]}
        if path=='/queue' and method=='GET':
            require(admin,'Acesso exclusivo do administrador.',403)
            return {'items':[dict(r) for r in c.execute("SELECT * FROM shows WHERE status='pending' ORDER BY id")]}
        if path=='/shows' and method=='POST':
            title=str(data.get('title','')).strip(); synopsis=str(data.get('synopsis','')).strip()
            require(1<=len(title)<=100 and 1<=len(synopsis)<=3000,'Preencha título e sinopse.')
            cur=c.execute('INSERT INTO shows(owner,title,synopsis) VALUES (?,?,?)',(uid,title,synopsis))
            return {'id':cur.lastrowid}
        parts=path.strip('/').split('/')
        require(len(parts)==3 and parts[0]=='shows' and parts[1].isdigit(),'Não encontrado.',404)
        sid=int(parts[1]); op=parts[2]
        show=c.execute('SELECT * FROM shows WHERE id=?',(sid,)).fetchone()
        require(show is not None,'Não encontrado.',404)
        owner=show['owner']==uid
        if op=='episodes' and method=='GET':
            require(owner or admin or show['status']=='approved','Conteúdo indisponível.',403)
            return {'items':[{'id':r['id'],'title':r['title'],'url':'/media/'+r['file']} for r in c.execute('SELECT * FROM episodes WHERE show_id=? ORDER BY id',(sid,))]}
        if op=='episodes' and method=='POST':
            require(owner and show['status'] in ('draft','rejected'),'Somente rascunhos ou reprovados podem ser editados.',403)
            title=str(data.get('title','')).strip(); require(0<len(title)<=100,'Informe o título do episódio.')
            try: blob=base64.b64decode(data.get('video',''),validate=True)
            except Exception: raise ApiError('Arquivo inválido.')
            require(12<=len(blob)<=25*1024*1024 and blob[4:8]==b'ftyp','Envie um MP4 de até 25 MB.')
            name=secrets.token_hex(24)+'.mp4'; (ROOT/name).write_bytes(blob)
            c.execute('INSERT INTO episodes(show_id,title,file) VALUES (?,?,?)',(sid,title,name))
            c.execute("UPDATE shows SET status='draft',reason='' WHERE id=?",(sid,)); return {'ok':True}
        if op=='submit' and method=='POST':
            require(owner and show['status'] in ('draft','rejected'),'Envio não permitido.',403)
            require(data.get('rights') is True,'Confirme a autorização de publicação.')
            require(c.execute('SELECT 1 FROM episodes WHERE show_id=?',(sid,)).fetchone(),'Adicione um episódio.')
            c.execute("UPDATE shows SET status='pending',reason='' WHERE id=?",(sid,)); return {'ok':True}
        if op=='review' and method=='POST':
            require(admin,'Acesso exclusivo do administrador.',403)
            require(show['status']=='pending','Esta produção já foi analisada ou não foi enviada.',409)
            decision=data.get('decision'); reason=str(data.get('reason','')).strip()
            require(decision in ('approved','rejected'),'Decisão inválida.')
            require(decision!='rejected' or 3<=len(reason)<=2000,'Informe o motivo da reprovação.')
            c.execute('UPDATE shows SET status=?,reason=? WHERE id=?',(decision,reason,sid))
            c.execute('INSERT INTO audit(show_id,admin,decision,reason,at) VALUES (?,?,?,?,?)',(sid,uid,decision,reason,int(time.time())))
            return {'ok':True}
        raise ApiError('Não encontrado.',404)

class Handler(BaseHTTPRequestHandler):
    def do_GET(self): self.handle_request()
    def do_POST(self): self.handle_request()
    def handle_request(self):
        try:
            token=self.headers.get('Authorization','').removeprefix('Bearer ')
            if self.command=='GET' and self.path.startswith('/media/'):
                name=self.path.split('/')[-1]
                with db() as c:
                    r=c.execute('SELECT s.* FROM shows s JOIN episodes e ON e.show_id=s.id WHERE e.file=?',(name,)).fetchone()
                    u=c.execute('SELECT u.* FROM users u JOIN sessions t ON u.id=t.user_id WHERE t.token=? AND t.expires>?',(token,time.time())).fetchone()
                require(r and (r['status']=='approved' or (u and (u['id']==r['owner'] or u['role']=='admin'))),'Conteúdo indisponível.',403)
                file=ROOT/name; total=file.stat().st_size; start,end=0,total-1
                ran=self.headers.get('Range','')
                if ran:
                    import re
                    m=re.fullmatch(r'bytes=(\d+)-(\d*)',ran)
                    require(m is not None,'Range inválido.',416)
                    start=int(m[1]); end=min(int(m[2]) if m[2] else end,end)
                    require(start<=end,'Range inválido.',416)
                self.send_response(206 if ran else 200)
                self.send_header('Content-Type','video/mp4'); self.send_header('Accept-Ranges','bytes')
                self.send_header('Cache-Control','private, no-store')
                if ran: self.send_header('Content-Range',f'bytes {start}-{end}/{total}')
                self.send_header('Content-Length',str(end-start+1)); self.end_headers()
                with file.open('rb') as f:
                    f.seek(start); remaining=end-start+1
                    while remaining:
                        chunk=f.read(min(65536,remaining))
                        if not chunk: break
                        self.wfile.write(chunk); remaining-=len(chunk)
                return
            length=int(self.headers.get('Content-Length','0'))
            require(0<=length<=36*1024*1024,'Arquivo excede o limite.',413)
            data=json.loads(self.rfile.read(length) or '{}'); require(isinstance(data,dict),'JSON inválido.')
            self.reply(200,action(self.command,self.path,data,token))
        except ApiError as e: self.reply(e.code,{'error':e.message})
        except (ValueError,TypeError): self.reply(400,{'error':'Dados inválidos.'})
        except (BrokenPipeError,ConnectionResetError): pass
        except Exception: self.reply(500,{'error':'Erro interno.'})
    def reply(self,code,obj):
        raw=json.dumps(obj,ensure_ascii=False).encode(); self.send_response(code)
        self.send_header('Content-Type','application/json; charset=utf-8'); self.send_header('Content-Length',str(len(raw)))
        self.end_headers(); self.wfile.write(raw)
if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser(); p.add_argument('--admin'); p.add_argument('--port',type=int,default=8080); args=p.parse_args(); init()
    if args.admin:
        with db() as c:
            cur=c.execute("UPDATE users SET role='admin' WHERE email=?",(args.admin.lower(),))
            print('Administrador definido.' if cur.rowcount else 'Cadastre essa conta primeiro.')
    else: ThreadingHTTPServer(('127.0.0.1',args.port),Handler).serve_forever()
