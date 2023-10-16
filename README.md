# Dorkus Playtest Assistant

DPA is a user-friendly wrapper for OBS, allowing non-technical folks to record playtesting sessions quickly and easily. See the [itch.io page](https://nogoblin.itch.io/dorkus-playtest-assistant) to download and learn more.

## Usage

Just run `DorkusAssist.exe` and you're 90% of the way there. Open the context menu by right-clicking Dorkus to start/stop recording, open the recording folder, or close the app (which will automatically stop and save any active recording before closing OBS as well).

### Unreal Integration
When running a project built with Unreal Engine, it's possible for Dorkus to listen for a WebSocket connection and use that to determine whether to start or stop recording. Add the `-RCWebControlEnable` parameter when running your game (if using Steam, this can be set in Properties > Launch Options) to start the WebSocket server on run.

### frame.io Config
frame.io is a service that allows you to upload videos so they can be commented and annotated via a web interface. Dorkus can automatically upload recordings to your frame.io project, eliminating the need for an external playtester to share their video manually.

Please see the instructions in [support/config_template.ini](support/config_template.ini) for more information on how to set this up.
