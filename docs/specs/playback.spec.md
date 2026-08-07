# Feature: Playback

## Purpose

Play songs, control playback progress, manage the queue, and navigate between players. All players share the same state so playback is always consistent.

## Background

Where the app is ready for playback
Where the app is running on a supported device

## Playback backend failure

### Audio backend unavailable on Linux

Where the app runs on Linux
And the audio playback library is not installed
When the user tries to play a song
Playback shall not start
And a friendly message shall be shown
And the message shall not reference a specific Linux package manager command

## Shared player state

### Mini player shows current playing song

While a song starts playing
When the mini player appears
The mini player shall display the current song title and artist

When the song title changes
The mini player shall update automatically

### Mini player updates automatically

While the mini player is displayed on any screen
When a new song starts playing
The mini player shall update automatically

### Mini player updates on album detail screen

Where the album detail screen is displayed on mobile
And the mini player shows a previously playing song
When the user taps a song in the album to play it
The mini player shall update to show the new song
And the play/pause button shall reflect the playing state

### Mini player and sidebar player show same song info

While a song is playing
Where the app is on a large screen
When both the mini player and sidebar player are visible
The sidebar player shall show the same song title and artist as the mini player

When playback pauses
Both players shall update to show the paused state together

### Full player shows same song info as other players

While a song is playing
When the user opens the full player
The full player shall display the album art, title, and artist

When the user taps shuffle in the full player
Shuffle shall toggle
And the mini player and sidebar player shall reflect the same state

## Mini player

### Mini player appears at the bottom on small screens

Where the device has a small screen
When the main screen loads
A mini player shall be visible at the bottom of the screen
And it shall display the current song title, artist, and album art
And it shall show a play/pause button
And it shall show a skip next button

### Mini player shows last played song when idle

Where the app opens and no song is currently playing
The mini player shall show the most recently played song
And the play/pause icon shall show play state

### Mini player shows progress bar when no songs have been played

Where the app launches and no song has been played
A thin progress bar shall be shown at the bottom of the screen
And no song title, artist, or controls shall be shown
And the progress bar value shall be zero

### Mini player does not auto-play on startup

Where the app opens and a previously played song is shown in the mini player
The song info shall be displayed (title, artist, artwork)
And the play icon shall be shown (not pause)
And the song shall not start playing automatically

### Tapping mini player opens full player from bottom

Where the mini player is visible on mobile
When the user taps the mini player
The full player screen shall open with a bottom-to-top animation

When the user closes the full player
The full player shall close with a bottom-to-top animation and return to mini player

### Mini player shows for local songs

Where a saved song is in the library
When the user taps play on the saved song
The mini player shall show the song title, artist, and cover art
And the play/pause button shall show pause icon

### Mini player shows for streamed songs

While search results are displayed
When the user taps a song in search results
The mini player shall show the song title, artist, and cover art
And the play/pause button shall show pause icon

### Mini player skip next button works correctly

While a song is playing from the queue
When the user taps the skip next button in the mini player
The next song shall start playing automatically
And all players shall update to show the new current song

## Sidebar player

### Sidebar player appears in the left panel on large screens

Where the device has a large screen
When the main screen loads
A left panel shall be shown with navigation links
And the left panel shall display a player centered at the bottom
And the player shall show album art, progress bar, song title, and artist
And the player shall show playback controls
And the player controls shall reflect the current playback state

### Sidebar player controls are focusable on TV

While a song is playing
Where the sidebar is displayed on TV
When the user navigates to a playback control using D-pad
The control shall show a focus highlight

When the user presses select on the play/pause button
Playback shall toggle between play and pause

### Sidebar player shows library button next to song info

While a song is playing
When the sidebar player is displayed
The sidebar player shall show song title with a library icon button next to it, and artist below
And the title and artist shall be left-aligned
And the icon shall show filled when the song is in the library
And the icon shall show outline when the song is not in the library

When the user taps the library button
The song shall be added to or removed from the library
And the icon shall update accordingly

### Sidebar player removes song from queue and skips to next when removing from library while playing

While a song is currently playing from the queue
And the queue has at least one more song after the current one
When the user taps the library button to remove the current song from the library
The song shall be removed from the library
And the song shall be removed from the queue
And playback shall advance to the next song in the queue

### Sidebar player stops playback when removing last queued song from library while playing

While a song is the only song in the queue and is currently playing
When the user taps the library button to remove the current song from the library
The song shall be removed from the library
And playback shall stop

### Sidebar player removes song from queue without advancing when removing from library while paused

While a song is paused
When the user taps the library button to remove the current song from the library
The song shall be removed from the library
And the song shall be removed from the queue
And playback shall not advance to the next song

### Sidebar player skip next and previous buttons work correctly

While a song is playing
Where the sidebar player is displayed
When the user taps the skip previous button
The previous song in the queue shall start playing

When the user taps the skip next button
The next song in the queue shall start playing
And all players shall update to reflect the current song

## Full player

### Full player shows current song and playback state

While a song is playing
When the user opens the full player screen
The full player shall show album art, song title, artist, and playback controls

When the user pauses playback from the full player
The full player shall reflect the paused state
And both the mini player and sidebar player shall reflect the paused state

### All players show the same playing state

While a song is playing or paused
When the mini player, sidebar player, and full player are visible
Each player shall show the correct playing state

### Full player album art appears sharp

Where the full player screen is open
The album art shall appear sharp and clear

### Artwork is sharp in all players

Where a song with multiple image quality options is playing
When the song is displayed in any player
The artwork shall appear sharp

### Full player buttons are navigable with D-pad on TV

Where the full player screen is open
When the user navigates using D-pad
Every button on the full player screen shall be reachable by D-pad
And each button shall show a focus highlight when selected

### Full player header buttons have D-pad focus

Where the full player screen is open on a TV or tablet
When the user navigates to the close button with D-pad
The close icon shall show a focus highlight
And pressing select on the close button shall close the full player

When the user navigates to the queue button with D-pad
The queue icon shall show a focus highlight
And pressing select on the queue button shall open the queue screen

When the user navigates to the song actions button with D-pad
The more icon shall show a focus highlight
And pressing select on the song actions button shall open the song actions modal

### Full player control buttons are focusable via D-pad

Where the full player screen is open on a TV
When the user navigates to a control button with D-pad
The button shall show a focus highlight
And pressing select shall trigger the control action

### Remote back button closes full player

Where the full player screen is open
When the user presses the back button on the remote
The full player shall be closed
And the mini player shall be shown again

### Full player has close icon and action icons in header

Where the full player screen is open
The full player shall display a close icon in the top left
And a queue icon in the top right
And a song actions icon to the right of the queue icon in the top right

When the user taps the close icon
The full player shall be closed and the previous screen shall be shown

When the user taps the queue icon
The queue screen shall be opened

When the user taps the song actions icon
A song actions modal shall be shown with options like Add to Library and Add to Playlist

### Full player shows library icon next to song title

Where the full player screen is open
And a song is playing
A library icon button shall be shown next to the song title
And the icon shall show filled when the song is in the library
And the icon shall show outline when the song is not in the library

### Full player has playback controls in a row

Where the full player screen is open
The controls row shall show shuffle, previous, play/pause, next, and repeat buttons in that order

### Full player shows shuffle and repeat state

Where the full player screen is open
When the user toggles shuffle or cycles repeat mode
The full player shall reflect the new state

### Full player queue controls row has Manage Queue button

Where the full player screen is open
When the user views the queue controls row
A "Manage Queue" button shall be shown
And tapping the button shall open the queue screen

### Toggle shuffle from full player queue controls

Where the full player screen is open
When the user taps the shuffle button in the queue controls row
The shuffle state shall be toggled
And the button icon shall update to reflect the new state
And the queue shall be reordered if enabling shuffle

### Cycle repeat mode from full player queue controls

Where the full player screen is open
When the user taps the repeat button in the queue controls row
The repeat mode shall cycle through off, all, one
And the button icon shall update to reflect the active mode

### Full player skip next button works correctly

While a song is playing
Where the full player screen is open
When the user taps the skip next button
The next song in the queue shall start playing
And the full player shall display the new song information
And the mini player and sidebar player shall reflect the new current song

## Player navigation

### Tapping mini player opens full player

Where the mini player is visible
When the user taps the mini player
The full player screen shall be displayed
And the mini player shall be hidden while the full player is visible

### Closing full player returns to previous screen

Where the full player screen is open
When the user presses the back button or close icon
The previous screen shall be displayed
And the mini player shall be shown again

### Mini player visibility across screens

Where the mini player is visible
When the user navigates to any screen except the full player
The mini player shall be visible at the bottom

When the full player screen is opened
The mini player shall be hidden

When the full player screen is closed
The mini player shall be visible again

## Player lifecycle

### Mini player and full player share same state

While a song is playing
When both the mini player and full player are open
Both shall display the same track information
And both shall reflect the same playback state

### App navigates away from player

While a song is playing
When the user navigates away from the app
Playback shall continue
And returning to the app shall show the current song in the mini player

## Recent Songs tracking

### Played song appears in Recent Songs

While a song starts playing
When the user opens the Recent Songs playlist
The song shall be shown in the list
And streaming-only songs shall appear alongside saved songs

### Recent Song updates on each play

While a song finishes playing and another song starts
When the user views Recent Songs
Both songs shall be in the list
And the most recently played song shall appear first

### Same song played again moves to top

Where a song is already in Recent Songs
When the song is played again
The song shall move to the top of the Recent Songs list
And duplicates shall not be created

### Recent Songs shows song metadata offline

Where songs have been played
When the user views Recent Songs without an internet connection
Each song shall show its name, artist, and cover art

### Recently streamed song plays offline while still in Recent Songs

Where a streamed song has finished playing
And the song is still in the Recent Songs list
When the user is offline
And taps the song in Recent Songs
The song shall play from the device without interruption

### Recently streamed song fails offline after leaving Recent Songs

Where a streamed song was in Recent Songs
And the song has been evicted from Recent Songs
And the song is not in Library or any playlist
When the user is offline
The song shall no longer be available offline

### Pinned song plays offline from Recent Songs

Where a song is in the Library
And the song appears in Recent Songs
When the user is offline
And taps the song in Recent Songs
The song shall play from the device without interruption

## Queue respects sort order

### Library queue respects sort order

Where the library song list is sorted by name ascending
When the user taps a saved song to play
The queue order shall match the visible sorted order
And not the original save order

### Playlist queue respects sort order

Where the playlist song list is sorted by artist name
When the user taps a song from the playlist to play
The queue order shall match the visible sorted order
And all songs from the playlist shall be queued in the displayed order

## Queue screen

### Queue screen shows list of songs

While songs are playing
When the user opens the queue screen
The current song shall be highlighted with animated equalizer bars
And the equalizer bars shall animate while the song is playing
And the equalizer bars shall freeze when playback is paused
And all queued songs shall be listed in order

### Queue is empty

Where no songs are queued
When the user opens the queue screen
An empty state shall be shown

### Queue screen uses the back button

Where the queue screen is displayed
The app bar shall show the back button

### Queue screen does not show shuffle action

Where the queue screen is displayed
The app bar shall not show a shuffle action

### User removes a song from the queue

While songs are queued
When the user removes a song from the queue
The song shall be removed
And the remaining songs shall fill the gap

### Reordering queue updates the displayed queue

While songs are in the queue
When the user drags a queue song to a new position
The queue order shall be updated
And the queue screen shall immediately show the reordered queue

### Removing a queue song updates the displayed queue

While songs are in the queue
When the user removes a queue song
The song shall be removed from the queue
And the queue screen shall immediately remove the song from the list

### Playing from queue starts playback

While songs are in the queue
When the user taps a song in the queue
The selected song shall start playing
And playback shall start automatically
And the current playing song shall reflect the new song

### User plays next from song actions

While songs are queued
When the user taps Play Next on a song from search or library
The song shall be inserted after the current song

### User adds to queue end from song actions

While songs are queued
When the user taps Add to Queue on a song
The song shall be added after all currently queued songs

## Sleep timer

### User sets a sleep timer

While a song is playing
When the user taps the timer icon in the full player header (next to queue and kebab buttons)
A duration picker shall appear with options: 15, 30, 45, 60, 90 minutes

When the user selects a duration
The timer shall start counting down
And the timer icon shall change to filled state
And the remaining time shall be shown next to the timer icon in the header

### Timer button hidden when no song

Where no song is loaded
The timer icon shall not be shown in the full player header

### Sleep timer pauses playback

While a sleep timer is active
When the timer expires
Playback shall be paused
And the timer icon shall return to outline state
And the remaining time shall disappear

### User cancels sleep timer

While a sleep timer is active
When the user taps the timer icon
The timer shall be cancelled
And playback shall continue
And the timer icon shall return to outline state
And the remaining time shall disappear

## Shuffle and repeat

### User toggles shuffle

Where shuffle is off
When the user taps the shuffle button
Shuffle shall turn on
And upcoming songs shall be randomized

When the user taps shuffle again
Shuffle shall turn off

### User cycles repeat mode

Where repeat is off
When the user taps the repeat button
Repeat all shall be enabled

When the user taps repeat again
Repeat one shall be enabled

When the user taps repeat again
Repeat shall turn off

## Queue navigation

### User skips to next song

While songs are queued
When the user taps the skip next button
The next song shall start playing

### User goes back to previous song

While songs are queued
When the user taps the skip previous button
The previous song shall start playing

### Next song at end of queue with repeat off

Where the current song is the last in the queue
And repeat is off
When the current song finishes
Playback shall stop
And the play/pause button shall show the play icon
And the equalizer bars shall freeze

### Queue wraps in repeat all mode

Where the current song is the last in the queue
And repeat all is enabled
When the current song finishes
The first song shall start playing

### Same song repeats in repeat one mode

Where repeat one is enabled
When the current song finishes
The same song shall start playing again

## Queue state persistence

### Queue shuffle and repeat persist across sessions

Where the user has set shuffle and repeat preferences
When the user restarts the app
The previous shuffle and repeat settings shall be restored

### Queue persists across app restarts

Where the user has songs queued
When the user restarts the app
The queue shall be restored to the state where the user left off
And the previously playing song shall be selected
