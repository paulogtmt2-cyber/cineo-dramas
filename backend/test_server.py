import os,tempfile,unittest,base64
os.environ['CINEO_DATA']=tempfile.mkdtemp()
import server as s
s.init()
class Workflow(unittest.TestCase):
 def setUp(self):
  with s.db() as c:
   for t in ['audit','episodes','shows','sessions','users']:c.execute('DELETE FROM '+t)
  self.a=s.action('POST','/register',{'email':'a@example.com','password':'abcdefghijk'})['token']
  self.b=s.action('POST','/register',{'email':'b@example.com','password':'abcdefghijk'})['token']
  self.admin=s.action('POST','/register',{'email':'admin@example.com','password':'abcdefghijk'})['token']
  with s.db() as c:c.execute("UPDATE users SET role='admin' WHERE email='admin@example.com'")
  self.id=s.action('POST','/shows',{'title':'Teste','synopsis':'Sinopse'},self.a)['id']
  self.path=f'/shows/{self.id}'
 def upload(self):s.action('POST',self.path+'/episodes',{'title':'Um','video':base64.b64encode(b'\x00\x00\x00\x14ftypisom00000000').decode()},self.a)
 def pending(self):self.upload();s.action('POST',self.path+'/submit',{'rights':True},self.a)
 def test_approval(self):
  self.pending();self.assertEqual(s.action('GET','/catalog',{})['items'],[])
  s.action('POST',self.path+'/review',{'decision':'approved'},self.admin)
  self.assertEqual(len(s.action('GET','/catalog',{})['items']),1)
 def test_creator_cannot_approve(self):
  self.pending()
  with self.assertRaises(s.ApiError):s.action('POST',self.path+'/review',{'decision':'approved'},self.a)
 def test_private_episodes(self):
  self.pending()
  with self.assertRaises(s.ApiError):s.action('GET',self.path+'/episodes',{},self.b)
 def test_cannot_edit_pending(self):
  self.pending()
  with self.assertRaises(s.ApiError):self.upload()
 def test_reject_reason_and_resubmit(self):
  self.pending()
  with self.assertRaises(s.ApiError):s.action('POST',self.path+'/review',{'decision':'rejected'},self.admin)
  s.action('POST',self.path+'/review',{'decision':'rejected','reason':'Corrigir vídeo'},self.admin)
  self.assertEqual(s.action('GET','/mine',{},self.a)['items'][0]['reason'],'Corrigir vídeo')
  self.upload();s.action('POST',self.path+'/submit',{'rights':True},self.a)
  self.assertEqual(len(s.action('GET','/queue',{},self.admin)['items']),1)
 def test_empty_submission(self):
  with self.assertRaises(s.ApiError):s.action('POST',self.path+'/submit',{'rights':True},self.a)
 def test_role_cannot_be_chosen(self):
  r=s.action('POST','/register',{'email':'hack@example.com','password':'abcdefghijk','role':'admin'})
  self.assertEqual(r['role'],'creator')
 def test_logout(self):
  s.action('POST','/logout',{},self.a)
  with self.assertRaises(s.ApiError):s.action('GET','/mine',{},self.a)
 def test_duplicate_review(self):
  self.pending();s.action('POST',self.path+'/review',{'decision':'approved'},self.admin)
  with self.assertRaises(s.ApiError):s.action('POST',self.path+'/review',{'decision':'rejected','reason':'teste'},self.admin)
if __name__=='__main__':unittest.main()
