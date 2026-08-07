# Feature: Browsing

## Purpose

Search for songs and albums, view album details, and discover music. Browsing covers the full flow from entering a query to exploring album content.

## Background

Where the app is running on a supported device

## Search

### Search button visible in app bar on small screen

Where the library screen is displayed on a small screen
A search icon button shall be shown in the app bar

When the user taps the search button
The app shall navigate to the search screen

### Search button not shown on large screen

Where the app is displayed on a large screen
No search button shall be shown in the app bar
And the Search tab shall be accessible from the sidebar instead

### Search field placeholder changes by active tab

Where the search screen is displayed
And the Songs tab is active
The search field shall show placeholder text "Search songs"

When the user switches to the Albums tab
The search field shall show placeholder text "Search albums"

### Search field has background fill

Where the search screen is displayed
The search field shall have a filled background matching the filter input style

### Search icon is dynamic

Where the search screen is displayed
And the search field is empty
The search icon shall be displayed

When the user types text into the search field
The clear icon shall be displayed and tapping it shall clear the text

### Search tabs show pill-style buttons

Where the search screen is displayed
The Songs and Albums tabs shall be shown as pill-style buttons below the search field
And the buttons shall be left-aligned
And the active tab shall be visually highlighted
And the tabs shall sit flush with the content below, matching the library screen layout

### User can switch between search tabs

Where the search screen is displayed
When the user taps the Songs pill button
Only songs shall be displayed in the search results

When the user taps the Albums pill button
Only albums shall be displayed in the search results

### Search is tab-aware

Where the user is on the Songs tab
When the user enters a search query
The app shall search for songs only

Where the user is on the Albums tab
When the user enters a search query
The app shall search for albums only

### Search returns song results

Where the search screen is displayed
When the user enters a search query
The app shall display matching songs with title, artist, and cover art

### Song search results show standard list items

Where the user has searched for songs and results are displayed
Each song result shall show a standard list item with artwork, title, and artist
And a kebab menu shall be available for additional actions
And the item shall expand to full width of the list

### Song search results show song metadata

Where a search has completed
Each result shall show song name, primary artists, and album name

### Song images load quickly and look sharp

Where song search results are displayed in list view
The song images shall load quickly and look sharp

### User can stream songs from search

While search results are displayed
When the user taps a search result
The song shall start playing

### Search returns album results

Where the search screen is displayed
When the user enters an album name in search
The app shall display matching albums with title, artist, and cover art

### Album search results show album metadata

Where an album search has completed
Each result shall show album title in a single line
And the subtitle shall show year first, followed by artist (e.g., "2024 • Artist Name")
And the artist name shall be shown directly when available
And the bullet separator shall only be shown between year and artist when both are present

### Album images load quickly and look sharp

Where album search results are displayed in list view
The album images shall load quickly and look sharp

### Tapping an album result navigates to album details

Where the Albums tab is active
When the user taps an album result
The app shall navigate to the album details screen

### Album detail screen handles missing song fields gracefully

Where some songs in the album have missing fields
When the user opens the album details
The album detail screen shall display with available song data
And the app shall not crash or show error when valid songs exist

### Album search results use consistent styling with song results

Where album search results are displayed
Each album result shall use the same list item styling as song results
And the item shall expand to full width of the list

### Empty search state shows placeholder before any search

Where the search screen is displayed with the Songs tab active
And the user has not searched yet
An empty state icon shall be shown with "Search songs" text

Where the Albums tab is active
And the user has not searched yet
An empty state icon shall be shown with "Search albums" text

## Song actions modal

### Search screen modal shows Play Next action

Where a song actions modal is open for a search result
When the user taps Play Next
The song shall be added to play after the current song

### Search screen modal shows Add to Queue action

Where a song actions modal is open for a search result
When the user taps Add to Queue
The song shall be added to the end of the queue

### Modal always shows Play

Where a song actions modal is open
The action shall always show "Play" with play icon
And tapping Play shall play the song even if it is already playing

### Modal shows Add to Playlist

Where a song actions modal is open for a search result
When the user taps "Add to Playlist"
A playlist picker shall be shown
And the user shall be able to select a playlist to add the song to

### Modal shows Add or Remove from Library

Where a song actions modal is open for a song that is in the library
The action shall show "Remove from Library" with remove icon

Where a song actions modal is open for a song that is not in the library
The action shall show "Add to Library" with add icon

### Modal shows bitrate

Where a song actions modal is open
The bitrate (e.g. "320kbps") shall be displayed below the artist when available

## Album details

### Album artwork is displayed larger

The album artwork shall be shown larger than in other views
And the artwork shall be centered horizontally
And the artwork shall maintain proper aspect ratio
And a placeholder icon shall be shown if artwork is unavailable

### Album name and year are centered

The album name shall be shown below the artwork, centered
And the year and artist shall be shown together in a single line below the album name
And the year shall be shown first, followed by artist (e.g., "2024 • Artist Name")
And the artist name shall be shown directly when available
And the bullet separator shall only be shown between year and artist when both are present

### Album details show explicit content indicator

Where the album contains explicit content
An explicit content badge shall be shown below the album artist line
And the badge shall indicate the content is explicit

### Album details do not show play all button

No play all button shall be shown in the app bar
And songs shall be playable individually by tapping on them

### Album details screen shows songs list

The songs list shall be shown without a header count
And each song list item shall have reduced vertical spacing for compact display

## Album playback

### Playing a song from album makes all songs available

When the user taps a song in the album details screen
The selected song shall start playing
And all songs from the album shall be available to play next

### Playing a song from middle of album

When the user taps the 3rd song in an album
The 3rd song shall start playing
And the user shall be able to navigate to any other song from the album

### Previous queue is replaced when playing from album

Where the user had other songs queued
When the user taps any song in the album
Only songs from the album shall be available to play next

### Album Play Next adds song after current

Where the album detail screen is displayed
When the user taps Play Next on a song
The song shall be added to play after the current song
