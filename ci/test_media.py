import importlib.util,pathlib,tempfile,unittest,base64
spec=importlib.util.spec_from_file_location('media',pathlib.Path(__file__).with_name('media-worker.py'));media=importlib.util.module_from_spec(spec);spec.loader.exec_module(media)
class MediaProcessingTest(unittest.TestCase):
    def test_decode_and_transcode_known_mp4(self):
        sample=pathlib.Path(__file__).resolve().parents[1]/'android/app/src/androidTest/assets/sample.mp4'
        result=media.process({'url':sample.as_uri()})
        self.assertTrue(result['ok']);self.assertGreater(result['duration'],0)
        self.assertIn('video',result['details'])
        for kind in ['low','medium','thumb']:self.assertGreater(len(base64.b64decode(result[kind])),100)
    def test_reject_corrupt_video(self):
        with tempfile.TemporaryDirectory() as folder:
            file=pathlib.Path(folder)/'broken.mp4';file.write_bytes(b'not a playable video')
            with self.assertRaises(RuntimeError):media.process({'url':file.as_uri()})
if __name__=='__main__':unittest.main()
