import os
import sys
import json
from frameioclient import FrameioClient

client = FrameioClient(sys.argv[1])

result = client.assets.upload(sys.argv[2], sys.argv[3])

sys.stdout.write(json.dumps(result))