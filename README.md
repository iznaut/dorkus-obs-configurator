# Dorkus Playtest Assistant

DPA is an app created with Godot Engine that acts as a user-friendly wrapper for DorkusOBS (a bespoke build of the OBS Studio optimized for recording playtest and QA sessions).

## Dorkus Assistant Features

### 👺 Dorkus Is Watching!
A cute little guy appears in the bottom right corner of your screen to give you piece of mind that you _definitely_ didn't forget to hit record.

### 🔗 Dorkus Is Connected!
Start and stop recording automatically when your Unreal-based project opens and closes. Auto-upload saved recordings to [frame.io](https://frame.io) for future review.

## DorkusOBS Features

### 📵 No Streaming Allowed!  
The "Start Streaming" button is disabled in DorkusOBS and the RTMP plugin has been removed, so there's no danger of accidentally leaking your top secret project on your personal Twitch channel.

### 🎮 Input Overlays  
Semi-transparent overlays for Xbox gamepads and mouse/keyboard are included to capture the player's in-game inputs while recording.

### 👷‍♀️ Preconfigured OBS Settings  
Encoding settings are optimized for small file sizes (easy to drop in Slack or upload to frame.io). Replay buffer is enabled by default to capture the last 60 seconds of play, even if a full recording hasn't been started.

## Development

DorkusOBS is a dependency. Be sure to download the latest DorkusOBS build before previewing or exporting the project locally:

https://github.com/nogoblin/dorkus-obs/releases/latest/download/dorkus-obs.zip

It should be extracted to `/build/win/dorkus-obs`.