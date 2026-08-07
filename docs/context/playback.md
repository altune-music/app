# Playback

**Playing state**:
A reference to the currently playing `Song` plus playback state (playing/paused/stopped) and position. Not a copy — the UI reads from the live `Song` reference.
_Avoid_: PlayingInfo, current track, now playing

**Playback state**:
Whether audio is playing, paused, or stopped. Shared across all player UIs (mini, sidebar, full).
_Avoid_: play status
