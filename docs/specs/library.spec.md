# Feature: Library

## Purpose

Manage the user's saved music: the Library (system playlist), user-created playlists, system playlists, and offline availability. Songs added to Library or any playlist become savable automatically.

## Background

Where the app is running on a supported device
While the Songs tab shows the Library (a system playlist)
While the Playlists tab shows user-created playlists and Recent Songs

## Library — Songs tab

### Library shows empty state when no songs are in Library

Where no songs are in the Library playlist
When the library screen is displayed
The screen shall show an empty state icon
And shall display the text "Your library is empty"

### Library shows list of songs from the Library playlist

Where songs are in the Library playlist
When the library screen is displayed on the Songs tab
The screen shall list the songs in a scrollable view
And each song shall show title, artist, and cover art
And songs shall be sorted alphabetically by name by default

### Tapping a song plays it

Where songs are in the library
When the user taps a song in the library
The song shall start playing
And the mini player shall update to show the current song

### Current playing song is highlighted

While a song from the library is currently playing
When the library screen is displayed
The currently playing song shall be visually highlighted in the list

### Kebab menu shows song actions

Where songs are in the library
When the user taps the kebab menu on a song
A song actions modal shall open

### Modal shows Play or Pause based on playback state

While the song actions modal is open for a song that is currently playing
The action shall show "Pause" with pause icon

While the song actions modal is open for a song that is not playing
The action shall show "Play" with play icon

### Modal shows Play Next action

While the song actions modal is open for a song
When the user taps "Play Next"
The song shall be added to the queue after the current song

### Modal shows Add to Queue action

While the song actions modal is open for a song
When the user taps "Add to Queue"
The song shall be added to the end of the queue

### Modal shows Add to Playlist action

While the song actions modal is open for a song
When the user taps "Add to Playlist"
A playlist picker shall be shown
And the user shall be able to select a playlist to add the song to

### Modal shows Remove from Library action

While the song actions modal is open for a song in the Library
When the user taps "Remove from Library"
The song shall be removed from the Library
And the library list shall update to remove the song
And the song's audio and artwork files shall be deleted from storage only if the song is not in any other playlist

### Library updates when songs are added

While the library screen is displayed on the Songs tab
When a new song is added to the Library
The library list shall update to show the new song

### Library updates when songs are removed

While the library screen is displayed on the Songs tab
When a song is removed from the Library
The library list shall update to remove the song

### Library persists across app restarts

Where songs are in the Library
When the app is restarted
The Library playlist shall load its contents from storage
And the songs shall be available for offline playback

### Recently added songs persist across app restarts

Where the user has added a song to the Library
When the app is closed and reopened
The newly added song shall remain in the Library
And the song shall retain its data and offline availability

### Playing state is restored on restart

Where the user was playing from a queue
When the app is closed and reopened
The queue shall be restored to the state where the user left off
And the previously playing song shall be shown

### Recent Songs persist across app restarts

Where the user has played songs
When the app is closed and reopened
The Recent Songs playlist shall retain its previously played songs

### Recent Songs are not part of the library backup

Where the user plays a song that is not saved to the Library
When the library backup is generated
The played song shall not appear in the backed-up library
And only Library and user-playlist songs shall appear in the backup

## Library — Backup

### Backup generates a JSON object with songs and playlists

Where songs are in the Library or in user playlists
When the user backs up the library
The app shall write a JSON object containing a songs array and a playlists array
And each song entry shall include id, name, primaryArtists, and album
And the file shall not include imageUrl, filePath, localArtworkPath, bitrate, dateAdded, or url
And the file shall not include audio files or artwork files

### Backup uses unique timestamped filenames

When the user triggers a backup
The app shall create a new backup file instead of overwriting an existing one
And the filename shall include a timestamp

### Backup location is shown in Settings

Where the user has created a backup
The app shall show the backup folder path in Settings
And the path shall be the full filesystem path to the Backups folder

### Backup path is read-only in Settings

Where the user views the backup location in Settings
The backup location tile shall display the current backup folder path
And shall not open a folder picker or allow changing the path

### Backup excludes Recent Songs

Where a song has been played but is not in the Library or any user playlist
When the library backup is generated
The played song shall not appear in the backed-up library
And only Library and user-playlist songs shall appear in the backup

### Backup excludes system playlists other than Library

Where the app has system playlists besides Library
When the library backup is generated
Only Library and user-created playlist songs shall appear in the backup



### Backup preserves playlist definitions

Where the user has created playlists
When the library backup is generated
The backed-up playlists array shall contain each user playlist
And each playlist entry shall include id, name, and songIds

### Backup preserves song identifiers for later import

Where the backup file is generated
The backed-up song entries shall contain the song id
And the id shall be usable to re-download or import the song later

### Backup feedback is shown

Where the user triggers a backup
When the backup completes successfully
The app shall indicate success

When the backup fails
The app shall indicate failure

### Backup control is available in Settings

Where the user is on the Settings screen
A backup option shall be visible
And tapping it shall open a confirmation dialog before backing up
And the dialog shall show the full filesystem path to the Backups folder
And the dialog shall show how many songs and playlists will be backed up
And the dialog shall let the user copy the backup folder path
And confirming in the dialog shall export the library to the Backups folder

### Restore control is available in Settings

Where the user is on the Settings screen
A restore option shall be visible
And tapping it shall open a confirmation dialog before restoring
And the dialog shall show the full filesystem path to the Restore folder
And the dialog shall show how many songs and playlists the backup contains
And the dialog shall let the user copy the restore folder path
And confirming in the dialog shall import the backup from the Restore folder

### Restore dialog shows the detected file

Where a backup JSON is present in the Restore folder
The restore dialog shall show the path of the file that will be restored
So the user can confirm the app picked the right file

### Restore dialog reports a missing restore folder

Where no backup JSON is present in the Restore folder
The restore dialog shall show that no backup was found in the Restore folder
And shall tell the user to copy a backup JSON to the Restore folder

### Restore imports the detected file

Where the user confirms restore and a backup JSON is present
The app shall add any songs not already present in the Library
And shall add any playlists not already present
And shall preserve existing songs and playlists with the same identifiers
And shall report how many songs and playlists were imported and which file was used

### Restore feedback is shown

Where the user triggers a restore
When the restore completes successfully
The app shall indicate how many songs and playlists were imported

When the restore fails
The app shall indicate the failure reason

## Library — Sort

### Sort button uses sort icon

Where the library screen is displayed with songs
A sort button with a sort icon shall be shown in the header area
And tapping it shall open a menu with options: Name (A-Z), Name (Z-A), Date Added
And the selected option shall be highlighted

### Sort preference persists across app restarts

Where "Date Added" is selected as the sort mode
When the app is restarted
The sort mode shall remain "Date Added"

### Songs can be sorted by name A-Z

While the library screen is displayed
When the user selects "Name (A-Z)" from the sort menu
Songs shall be ordered alphabetically by name (case-insensitive)
And songs starting with "A" shall appear before songs starting with "B"

### Songs can be sorted by name Z-A

While the library screen is displayed
When the user selects "Name (Z-A)" from the sort menu
Songs shall be ordered reverse alphabetically by name (case-insensitive)
And songs starting with "Z" shall appear before songs starting with "A"

### Songs can be sorted by date added

While the library screen is displayed
When the user selects "Sort by Date Added" from the sort menu
Songs shall be ordered by when they were added to the library
And the most recently added songs shall appear first

### Sort mode applies immediately and stays consistent

While the library screen is displayed
When the user changes the sort mode
Songs shall re-sort immediately
And the selected sort option shall remain highlighted
And reopening the library later shall show the same sort mode

## Library — Filter

### Filter toggle button is shown in header to the right of sort

Where the library screen is displayed
A filter list icon button shall be shown in the header row to the right of the sort button
And the icon shall be highlighted when filter is active (field visible or text entered)
And the icon shall be dimmed when no filter is active

### Tapping filter toggle shows filter text field

While the library screen is displayed
When the user taps the filter list icon button
A filter text field shall be shown below the tab buttons
And the text field shall be ready to type immediately
And the field shall have a search icon when empty
And the field shall have a clear icon when text is entered

### Tapping filter toggle hides filter field and clears query

While the filter text field is visible with text entered
When the user taps the filter list icon button again
The filter text field shall be hidden
And the filter query shall be cleared
And all songs shall be shown again

### Filter placeholder changes by tab

While the library screen is displayed on the Songs tab
When the user shows the filter field
The placeholder shall read "Filter songs..."

While the library screen is displayed on the Playlists tab
When the user shows the filter field
The placeholder shall read "Filter playlists..."

### Filter filters songs by name

Where the library screen is displayed on the Songs tab
Where songs named "Song A", "Song B", and "Other Song" are saved
When the user types "Song" in the filter field
Only songs containing "Song" in their name shall be shown
And "Song A" and "Song B" shall be visible
And songs not containing "Song" in their name shall be hidden

### Filter filters songs by artist name

Where the library screen is displayed on the Songs tab
Where songs with artists "Artist One" and "Artist Two" are saved
When the user types "Artist" in the filter field
Songs with matching artist names shall be shown
And songs whose artist does not contain "Artist" shall be hidden

### Filter filters songs by album name

Where the library screen is displayed on the Songs tab
Where songs from albums "Album X" and "Album Y" are saved
When the user types "Album" in the filter field
Songs from matching album names shall be shown
And songs whose album does not contain "Album" shall be hidden

### Filter is case-insensitive

Where the library screen is displayed on the Songs tab
Where a song named "Hello World" is saved
When the user types "hello" in the filter field
The song "Hello World" shall be shown

When the user types "HELLO" in the filter field
The song "Hello World" shall be shown

### Filter shows empty state when no songs match

Where the library screen is displayed on the Songs tab
Where songs are saved in the library
When the user types a filter query that matches no songs
An empty state shall be shown indicating no matching songs

### Filter applies to playlists tab

Where the library screen is displayed on the Playlists tab
Where playlists named "Favorites", "Workout Mix", and "Chill Vibes" exist
When the user types "Fav" in the filter field
Only the "Favorites" playlist shall be shown

When the user clears the filter
All playlists shall be shown again

## Library — Playlists tab

### Library shows Songs and Playlists tabs

Where the user is on the library screen
Pill-style buttons for "Songs" and "Playlists" shall be shown at the top
And the Songs tab shall be selected by default

### Switching to Playlists tab

Where the user is on the library screen
When the user taps the "Playlists" pill button
The playlists list shall be displayed
And the Playlists tab shall be highlighted

### No playlists shows empty state

Where no playlists exist
When the user is on the Playlists tab
An empty state message shall be shown prompting to create a playlist

### Create playlist button is only visible on Playlists tab

While the library screen is displayed
While the Songs tab is selected
No create playlist button shall be shown

While the Playlists tab is selected
A plus icon button shall be shown in the header area
And tapping it shall open a dialog to create a new playlist

### Creating a new playlist

Where the user is on the Playlists tab
When the user taps the plus icon button in the header area
And enters a playlist name and confirms
The playlist shall be saved
And the playlist shall appear in the playlists list

### Playlist persists across app restarts

Where playlists have been created
When the app is restarted
The previously created playlists shall be loaded from saved data
And each playlist shall retain its name and songs

### Playlists can be sorted by name

While the library screen is displayed on the Playlists tab
When the user selects a sort option from the sort button
The playlists list shall be sorted accordingly by name

## Playlist detail

### Tapping a playlist opens its songs in a new page

Where the user is on the Playlists tab
When the user taps a playlist
A new page shall open showing the playlist's songs
And a back button shall be shown in the app bar to return to the playlists list

### Back button on large screen returns to playlists

Where the app is displayed on a large screen
And the user is viewing a playlist's songs
When the user taps the back button in the app bar
The app shall return to the playlists list

### Playlist songs can be sorted by name A-Z

Where the user is viewing a playlist with songs
A sort button with a sort icon shall be shown in the app bar
And the selected sort option shall be highlighted

When the user selects "Name (A-Z)"
Songs shall be ordered alphabetically by name (case-insensitive)

### Playlist songs can be sorted by name Z-A

Where the user is viewing a playlist with songs
When the user selects "Name (Z-A)"
Songs shall be ordered reverse alphabetically by name (case-insensitive)

### Playlist songs can be sorted by date added

Where the user is viewing a playlist with songs
When the user selects "Sort by Date Added"
Songs shall be ordered by when they were added to the library
And the most recently added songs shall appear first

### Playlist sort preference persists across restarts

Where a sort mode has been selected in a playlist
When the app is restarted and the playlist is opened
The previously selected sort mode shall be applied

### Playlist sort mode applies immediately and stays consistent

While the user is viewing a playlist with songs
When the user changes the sort mode
Songs shall re-sort immediately
And the selected sort option shall remain highlighted
And reopening the playlist later shall show the same sort mode

### Playlist with no songs shows empty state

Where a playlist exists with no songs
When the user opens the playlist
An empty state message shall be shown indicating no songs are in the playlist

### Clicking a song in a playlist plays the full playlist

Where a playlist contains songs
When the user taps any song in the playlist
All songs in the playlist shall be added to the queue
And the tapped song shall start playing

## Playlist management

### Renaming a playlist

Where the user is on the Playlists tab
When the user taps the kebab menu on a playlist and selects rename
And enters a new name and confirms
The playlist's name shall be updated
And the updated name shall appear in the playlists list

### Renaming a playlist with the same name does nothing

Where a playlist exists with a name
When the user renames the playlist to the same name
The playlist shall remain unchanged

### Adding a song to a playlist

Where a playlist exists
When the user adds a saved song to the playlist
The song shall be added to the playlist's song list
And the playlist shall be saved

### Cannot add duplicate songs to a playlist

Where a playlist contains a specific song
When the user tries to add the same song again
The song shall not be added a second time
And the playlist shall remain unchanged

### Removing a song from a playlist

Where a playlist contains songs
When the user removes a song from the playlist
The song shall be removed from the playlist's song list
And the playlist shall be saved

### Removing a song from a playlist via the kebab menu

Where a playlist contains songs
When the user opens the playlist
And taps the kebab menu on a song
And selects "Remove from Playlist"
The song shall be removed from the playlist's song list
And the playlist shall be saved
And the song list shall update to reflect the removal

### User stays on playlist screen after removing a song

Where the user is viewing a playlist with songs
When the user removes a song from the playlist
The song shall be removed from the list
And the user shall remain on the playlist screen to view the remaining songs
And the "Remove from Playlist" action shall be triggered from a modal that closes after the action

### Removing multiple songs sequentially keeps data consistent

Where a playlist contains songs A, B, and C
When the user removes song A
The playlist shall contain songs B and C

When the user removes song B
The playlist shall contain only song C
And song A shall not be resurrected in the playlist
And the playlists screen shall show count of 1 for this playlist

### Removing a song that is not in the playlist does nothing

Where a playlist contains songs A and B
When the user tries to remove song C which is not in the playlist
The playlist shall still contain songs A and B
And the song count shall remain unchanged

### Playlist song count updates correctly on playlists tab after removal

Where a playlist contains 3 songs
When the user removes one song from inside the playlist
And navigates back to the playlists tab
The playlists list shall show a count of 2 songs for that playlist

### Deleting a playlist

Where the user is on the Playlists tab
When the user taps the kebab menu on a playlist and selects delete
The playlist shall be removed from the playlists list
And the songs in the playlist shall remain in the library

## System playlists

### Recent Songs is a system playlist

Where the user opens the Playlists tab
A Recent Songs playlist shall be shown with a distinguishing icon
And the Recent Songs playlist shall not be deletable or renamable
And the Recent Songs playlist shall not appear in the Add to Playlist picker

### User cannot manually add songs to Recent Songs

While the song actions modal is open for a song
When the user taps Add to Playlist
Recent Songs shall not be shown in the playlist picker
And the song shall be added only if the user selects a visible playlist

### User cannot remove songs from Recent Songs

Where the user opens the Recent Songs playlist
The kebab menu on each song shall not show Remove from Playlist
And songs shall only be removed automatically when evicted by the cap

### System playlist cannot be deleted

Where the user is viewing a system playlist
When the user opens the playlist options
No Delete option shall be shown
And the playlist shall remain in the list

### System playlist cannot be renamed

Where the user is viewing a system playlist
When the user opens the playlist options
No Rename option shall be shown
And the playlist name shall remain unchanged

### Adding a song to a system playlist follows same auto-save behavior

Where a song is not available offline
When the user adds the song to the Library
The song shall be automatically saved for offline playback
And the song shall appear in the playlist

### Recent Songs has a cap

While the Recent Songs playlist has reached its maximum number of entries
When a new song is played
The oldest entry shall be removed
And the new song shall appear at the top of the list

## Searching playlist songs

### Search returns matching songs by name

Where a playlist contains songs with names "Summer Vibes", "Winter Chill", and "Spring Breeze"
When the user searches for "Summer" in the playlist
The song "Summer Vibes" shall be returned
And songs without "Summer" in the name shall not be returned

### Search returns matching songs by artist

Where a playlist contains songs with artists "Artist One" and "Artist Two"
When the user searches for "Artist" in the playlist
Songs with matching artist names shall be returned
And songs whose artist does not contain the query shall not be returned

### Search returns matching songs by album

Where a playlist contains songs from albums "Album X" and "Album Y"
When the user searches for "Album" in the playlist
Songs from matching album names shall be returned
And songs whose album does not contain the query shall not be returned

### Search is case-insensitive

Where a playlist contains a song named "Hello World"
When the user searches for "hello" in the playlist
The song "Hello World" shall be returned

When the user searches for "HELLO" in the playlist
The song "Hello World" shall be returned

### Search returns empty list when no match

Where a playlist contains songs
When the user searches for a query that matches no songs
An empty list shall be returned

### Search only returns songs that belong to the playlist

Where songs "Song A" and "Song B" are saved
And the playlist contains only "Song A"
When the user searches for "Song" in the playlist
Only "Song A" shall be returned
And "Song B" shall not be returned even though it matches the query

## Offline — making songs available

### Song becomes available offline when added to Library

While search results are displayed
When the user taps Add to Library on a song
The song shall be saved to the device
And the song shall appear in the Library
And the song shall play without interruption when offline

### Song becomes available offline when added to a playlist

While search results are displayed
When the user taps Add to Playlist and selects a playlist
The song shall be saved to the device
And the song shall be added to the selected playlist
And the song shall play without interruption when offline
And the song shall not appear in the Library unless it was already there

### Already available song shows offline state

Where a song is already saved offline
When the song is displayed anywhere in the app
Add to Library shall show as Remove from Library
And the song shall play from the device without re-saving

### User can remove offline song from Library

Where the user has a song in the Library
And the song is not in any other playlist
When the user taps Remove from Library
The song shall be removed from the device
And the artwork shall be removed if it exists
And the song shall be removed from the Library

### Remove from Library keeps file when song is in another playlist

Where the user has a song in the Library
And the song is also in a user-created playlist
When the user taps Remove from Library
The song shall be removed from the Library only
And the song shall remain on the device for the other playlist
And the song shall still be available offline when played from the other playlist

## Offline — playback

### Songs available offline play without internet

Where the user is offline
When the user taps a song that has been added to Library or a playlist
The song shall start playing
And playback shall continue without interruption

### Queue works offline with saved songs

Where the user is offline
When the user queues saved songs
All songs shall play without interruption
And skip forward and previous shall work normally

### Repeat and shuffle work offline

Where the user is offline
And saved songs are playing
When the user enables repeat or shuffle
The features shall work correctly

### Streaming songs fail offline

Where the user is offline
When the user taps a song that is not saved
The song shall not play
And an error or empty state shall be shown

## Offline — artwork

### Saved songs retain artwork offline

Where the user has a saved song
When the app is offline
The artwork shall still be displayed in all players and the library

### Artwork is deleted with the song when not in other playlists

Where the user has a song in the Library with local artwork
And the song is not in any other playlist
When the user removes the song from the Library
The song shall be deleted from the device
And the associated artwork shall also be deleted
And no leftover artwork shall remain on the device

### All players show artwork for saved songs

Where a saved song has local artwork
When the song is displayed in the library
The artwork shall be shown

When the same song is shown in the mini player
The artwork shall be shown

When the same song is shown in the sidebar player
The artwork shall be shown

When the same song is opened in the full player
The artwork shall be shown

### Streaming songs show remote artwork

Where a song is being streamed and not saved
When the song is displayed
The artwork shall load from the network
And artwork shall be available when there is an internet connection

## Offline — Library

### Library is available offline

Where the user is offline
When the library screen is displayed on the Songs tab
All Library songs shall be shown
And sorting shall work normally
And filtering shall work normally (searches songs by name, artist, or album)

### Library persists across app restarts while offline

Where songs are in the Library
When the app is restarted offline
The Library shall load its contents from storage
And the songs shall be available for playback
