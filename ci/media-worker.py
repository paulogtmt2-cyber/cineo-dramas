"""Private media processing using short-lived GitHub identity; no Supabase secrets in CI."""
import os,json,urllib.request,urllib.parse,tempfile,subprocess,base64,pathlib,time
BASE='https://njyjwcjrirqmbvsizqar.supabase.co/functions/v1/cineo/v7/worker'
def api(path,data):
    u=os.environ['ACTIONS_ID_TOKEN_REQUEST_URL']+'&audience=cineo-media'
    req=urllib.request.Request(u,headers={'Authorization':'Bearer '+os.environ['ACTIONS_ID_TOKEN_REQUEST_TOKEN']})
    token=json.load(urllib.request.urlopen(req,timeout=30))['value']
    req=urllib.request.Request(BASE+path,data=json.dumps(data).encode(),headers={'Authorization':'Bearer '+token,'Content-Type':'application/json'},method='POST')
    try:return json.load(urllib.request.urlopen(req,timeout=240))
    except urllib.error.HTTPError as e:raise RuntimeError('Worker API HTTP '+str(e.code)) from None
def run(args):
    p=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=240)
    if p.returncode:raise RuntimeError('FFmpeg não conseguiu processar o vídeo.')
    return p.stdout
def encode(p):
    data=p.read_bytes()
    if len(data)>26214400:raise RuntimeError('Versão processada excedeu 25 MB.')
    return base64.b64encode(data).decode()
def process(job):
    with tempfile.TemporaryDirectory() as folder:
        root=pathlib.Path(folder);src=root/'source.mp4'
        with urllib.request.urlopen(job['url'],timeout=120) as response,src.open('wb') as out:
            size=0
            while chunk:=response.read(65536):
                size+=len(chunk)
                if size>26214400:raise RuntimeError('Original excede 25 MB.')
                out.write(chunk)
        info=json.loads(run(['ffprobe','-v','error','-show_format','-show_streams','-of','json',str(src)]))
        streams=info.get('streams',[]);video=next((s for s in streams if s['codec_type']=='video'),None)
        if not video:raise RuntimeError('O arquivo não tem faixa de vídeo.')
        duration=float(info['format'].get('duration',0))
        if not 0<duration<=14400:raise RuntimeError('Duração inválida ou superior a quatro horas.')
        # Decode the full source to detect damaged frames; missing audio is reported, not invented.
        run(['ffmpeg','-v','error','-xerror','-i',str(src),'-f','null','-'])
        result={'ok':True,'duration':duration,'details':{'video':video.get('codec_name'),'has_audio':any(s['codec_type']=='audio' for s in streams),'width':video['width'],'height':video['height']}}
        for name,width,rate in [('low',360,300000),('medium',720,900000)]:
            target=root/(name+'.mp4');budget=min(rate,int(22*1024*1024*8/duration)-64000)
            if budget<40000:continue
            run(['ffmpeg','-v','error','-y','-i',str(src),'-vf',f"scale='min({width},iw)':-2",'-c:v','libx264','-preset','fast','-b:v',str(budget),'-maxrate',str(budget),'-bufsize',str(budget*2),'-c:a','aac','-b:a','64k','-movflags','+faststart',str(target)])
            result[name]=encode(target)
        thumb=root/'thumb.jpg'
        run(['ffmpeg','-v','error','-y','-i',str(src),'-vf',f'fps=10/{duration},scale=160:-2,tile=10x1','-frames:v','1',str(thumb)])
        result['thumb']=encode(thumb)
        return result
if __name__=='__main__':
    api('/erasure',{})
    completed=0
    while completed<4:
        job=api('/claim',{}).get('job')
        if not job:break
        try:result=process(job)
        except Exception as e:result={'ok':False,'message':str(e)[:200]}
        result.update(id=job['id'],lease=job['lease']);api('/result',result)
        completed+=1
    print('Vídeos processados:',completed)
