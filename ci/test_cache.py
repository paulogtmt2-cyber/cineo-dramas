"""Exercise the production cache implementation on a JVM without an Android emulator."""
import pathlib,tempfile,urllib.request,hashlib,subprocess,sys,shutil,os
root=pathlib.Path(__file__).resolve().parents[1]
expected="3cf6cd6892e32e2b4c1c39e0f52f5248a2f5b37646fdfbb79a66b46b618414ed"
with tempfile.TemporaryDirectory() as folder:
 work=pathlib.Path(folder);package=work/'br/com/cineo';package.mkdir(parents=True)
 if len(sys.argv)>1:raw=pathlib.Path(sys.argv[1]).read_bytes()
 else:
  with urllib.request.urlopen('https://repo.maven.apache.org/maven2/org/json/json/20240303/json-20240303.jar',timeout=45) as response:raw=response.read()
 assert hashlib.sha256(raw).hexdigest()==expected
 jar=work/'json.jar';jar.write_bytes(raw)
 for name in ['MainActivity.java','CacheCheck.java']:shutil.copyfile(root/'ci/cache-fixture'/name,package/name)
 shutil.copyfile(root/'android/app/src/main/java/br/com/cineo/FastCache.java',package/'FastCache.java')
 jdk=pathlib.Path(os.environ['JAVA_HOME'])/'bin' if os.environ.get('JAVA_HOME') else None
 java=lambda name:str(jdk/name) if jdk else name
 subprocess.run([java('javac'),'-cp',str(jar)]+[str(p) for p in package.glob('*.java')],check=True)
 subprocess.run([java('java'),'-cp',str(jar)+os.pathsep+str(work),'br.com.cineo.CacheCheck'],check=True)
