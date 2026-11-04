"""Only public, non-mutating production checks; credentials are never needed."""
import os,json,urllib.request,urllib.error
BASE=os.environ.get('CINEO_TEST_API','https://njyjwcjrirqmbvsizqar.supabase.co/functions/v1/cineo')
for path in ['/health','/version','/guest']:
    with urllib.request.urlopen(BASE+path,timeout=30) as response:
        assert response.status==200
        data=json.load(response)
        if path=='/health':assert data['ok'] and data['version']=='0.7.0'
        if path=='/guest':assert all(x['status']=='approved' and not x['hidden'] for x in data['items'])
for path in ['/v7/devices','/v7/health','/v7/worker/claim']:
    try:urllib.request.urlopen(BASE+path,timeout=30)
    except urllib.error.HTTPError as e:assert e.code in (400,401,403)
    else:raise AssertionError('Private endpoint allowed anonymous request')
print('Public API and anonymous-access boundaries passed')
