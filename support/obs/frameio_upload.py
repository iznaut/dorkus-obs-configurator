# expects args = [frameio_token, frameio_root_asset_id, asset_path]

import os
import sys
import json
from frameioclient import FrameioClient


def upload_to_frameio(frameio_token, frameio_root_asset_id, asset_path):
    client = FrameioClient(frameio_token)
    result = client.assets.upload(frameio_root_asset_id, asset_path)

    sys.stdout.write(json.dumps(result))


# error if missing required args
if len(sys.argv) < 4:
    error_msg = "expected 3 arguments, got " + str(len(sys.argv) - 1)
    sys.stdout.write(error_msg)
    raise ValueError(error_msg)

# remove first arg (script filepath)
sys.argv.pop(0)

upload_to_frameio(*sys.argv)