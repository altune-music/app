# Feature: UI Shell

## Purpose

The app's frame: responsive layout that adapts to small, large, and TV screens, sidebar navigation, shared UI elements (back button, app icon), D-pad navigation, and build configuration.

## Background

Where the app is running on a supported device

## Responsive layout

### Small screen shows app bar, song list, and mini player

Where the device has a small screen
When the app loads the main screen
The screen shall show an app bar containing a search button
And the app title shall show a logo icon followed by "altune" aligned to the left
And the main content panel shall show a list of songs
And a mini player shall be visible at the bottom of the screen

### Large screen shows sidebar and song list

Where the device has a large screen
When the app loads the main screen
A left sidebar shall be shown with navigation and player controls
And a content panel shall be shown containing a list of songs for the selected section
And the sidebar shall have Library, Search navigation (no Queue)

### TV screen shows sidebar with D-pad navigation

Where the device is a TV
When the app loads the main screen
A left sidebar shall be shown with navigation and player controls
And a content panel shall be shown containing a list of songs for the selected section
And all interactive elements shall support D-pad focus navigation
And focused elements shall show a visual highlight

### Full player screen hides sidebar on large screens

Where the device has a large screen
When the user opens the full player screen
The sidebar shall be hidden
And the full player content shall fill the available space

### Album details replace content panel on large screen

Where the user is on the search screen on a large screen
When the user taps an album result
The album details shall replace the content panel
And the sidebar shall remain visible for navigation
And a back button shall be shown in the content panel to navigate back to search
And search results shall persist when navigating back to the search screen

### Back navigation preserves search results on both form factors

Where the user has search results visible
When the user taps an album to view details
And navigates back via system back gesture or button
The previous search results and query shall be preserved

### System back button does not switch between top-level screens

Where the user is on the search screen
When the user presses the system back button
The app shall not navigate to the library screen
And the user shall stay on the search screen

Where the user is on the settings screen
When the user presses the system back button
The app shall not navigate to the library screen
And the user shall stay on the settings screen

### System back button on library screen exits app

Where the user is on the library screen
When the user presses the system back button
The app shall exit

## System bar visibility

### System bars are transparent

When the app launches
The status bar and navigation bar shall be transparent
And the status bar icons shall use light color
And the navigation bar icons shall use light color

### Small screen layout avoids system bar overlap

Where the device has a small screen
When the main screen renders
The body content shall not overlap with system bars
And the mini player shall sit above the navigation bar
And the library song list shall not be clipped by the navigation bar

### Large screen layout avoids system bar overlap

Where the device has a large screen
When the tablet layout renders
The sidebar and content shall not overlap with system bars
And both the top status bar and bottom navigation bar shall be respected

### Full player screen avoids system bar overlap

Where the full player screen is open
The album art and controls shall not overlap with system bars
And the close button and queue button shall remain accessible

## Sidebar — layout and appearance

### Sidebar shows app logo and name at the top

When the sidebar is displayed
The sidebar shall show the app logo icon at the top
And the app name "altune" shall be displayed next to the logo

### Sidebar shows navigation links

When the sidebar is displayed
The sidebar shall show navigation links for Library, Search, and Settings

### Sidebar shows player at the bottom center

While a song is playing
When the sidebar is displayed
The sidebar shall show a player centered at the bottom
And the player shall show album art, progress bar, song title, and artist
And the player shall show playback controls (play/pause, skip next, skip previous)
And the player controls shall reflect the current playback state

### Sidebar has dynamic width based on screen size

When the sidebar is displayed
The sidebar width shall adapt to the screen size
And the sidebar shall not be too narrow or too wide

### Sidebar is divided into focus regions

When the sidebar is displayed
The navigation links shall be in one focus region
And the player shall be in a separate focus region
And navigating up from the artwork shall move focus to the navigation links
And navigating down within the navigation links shall stay within that region
And navigating up or down within the player shall stay within that region

## Sidebar — behavior

### Sidebar is persistent on all screens except full player

Where the user is on the Library screen
The sidebar shall be visible

Where the user is on the Search screen
The sidebar shall be visible

When the user opens the full player screen
The sidebar shall be hidden

### Sidebar persists when navigating between screens

Where the sidebar is visible on the left side of the screen
And the user is currently viewing the Library screen
When the user taps the Search tab in the sidebar
The main content panel shall show the Search screen
And the sidebar shall remain visible
And the sidebar shall highlight the Search tab as selected
And the Library tab shall no longer be highlighted

### Sidebar navigation items respond to touch tap

Where the sidebar is displayed
When the user taps a sidebar navigation item
The main content shall change to the selected section

### Album details show content with sidebar on large screen

Where the device has a large screen
When the user navigates to album details from search
The screen shall display album details in the content panel
And a sidebar shall be shown with navigation and player controls

### Sidebar navigation works from album details

Where the device has a large screen
When the user taps the Library tab in the sidebar
The app shall navigate to the library screen

When the user taps the Search tab in the sidebar
The app shall navigate to the search screen

### Album details screen does not show mini player on large screen

Where the device has a large screen
No mini player bar shall be shown at the bottom of the screen
And playback shall be controlled from the sidebar player instead

## Back button

### Back button is reusable

Where the back button is placed in an app bar
When the button is rendered
It shall display a back icon
And it shall navigate back when pressed

### Album details screen shows back button on small screen

Where the device has a small screen
The app bar shall show a back button
And tapping the back button shall navigate to the previous screen
And the back button shall be in a floating app bar that scrolls away

### Album details screen shows back button on large screen

Where the device has a large screen
A back button shall be shown in the app bar
And tapping the back button shall navigate back to the search screen in the content panel
And the sidebar shall remain visible for navigation

### Search screen shows back button when opened from another screen

Where the user is on a small screen device
When the user opens search from the main screen
The app bar shall show a back button
And tapping the back button shall navigate to the previous screen

## App icon

### App icon uses theme colors

When the app launches
The app icon shall use the theme's colors
And the icon shall be visible on both light and dark backgrounds
And the icon shall maintain its recognizable shape and style

### App icon is color neutral

Where the user is viewing the app icon on the launcher
The icon shall not use unrelated accent colors
And the icon shall use colors that adapt to the theme
And the icon shall be recognizable in both light and dark modes

### Theme uses consistent colors

When the app theme is applied
The color scheme shall provide good contrast on dark backgrounds

### App icon background covers full space

Where the app icon is displayed
The background shall cover the entire icon space
And no transparent or empty areas shall be visible
And the background shall use the theme's surface color

## D-pad — sidebar

### Sidebar items are focusable

Where the sidebar is displayed
When the user navigates up or down
Focus shall move between sidebar items
And the focused item shall show a focus highlight

When the user presses select on a focused item
The main content shall change to that section

### Sidebar player is focusable

While a song is playing
Where the sidebar is displayed
When the user navigates to the player controls
Each control shall show a focus highlight

When the user presses select on the artwork
The full player screen shall open

When the user presses select on play/pause
Playback shall toggle

### Sidebar regions keep focus contained

Where the sidebar is displayed
When the user navigates up or down within the navigation links
Focus shall stay within the navigation links

When the user navigates up or down within the player controls
Focus shall stay within the player controls

When the user navigates up from the artwork
Focus shall move to the navigation links above

### Region navigation between sidebar and content

Where the sidebar and content panel are displayed
When the user navigates right from the sidebar
Focus shall move to the content panel

When the user navigates left from the content panel
Focus shall move back to the sidebar

## D-pad — content

### Content regions keep focus contained

Where the Search screen is displayed
When the user navigates up or down within the tabs
Focus shall stay within the tabs (Songs, Albums)

When the user navigates up or down within the search results
Focus shall stay within the results list

### Song items are focusable

Where the Library or Search screen is displayed
When the user navigates to a song item
The item shall show a focus highlight

When the user presses select
The song shall start playing

### Album items are focusable

Where the Search screen is displayed
When the user navigates to an album item
The item shall show a focus highlight

When the user presses select
The album details shall be shown

### Queue items are focusable

Where the Queue screen is displayed
When the user navigates to a queue item
The item shall show a focus highlight

When the user presses select
The song shall start playing from that position

### Playlist items are focusable

Where the Library Playlists tab is displayed
When the user navigates to a playlist item
The item shall show a focus highlight

When the user presses select
The playlist detail screen shall be shown

## D-pad — player

### Playback controls are focusable

Where the full player screen is displayed
When the user navigates between controls
Each focused control shall show a focus highlight

When the user presses select on play/pause
Playback shall toggle

### Seek slider responds to left and right

Where the full player screen is displayed
When the user navigates to the seek slider
And presses left
The song shall seek backward

When the user presses right
The song shall seek forward

## D-pad — modals

### Bottom sheet items are focusable

Where a bottom sheet is displayed
All action items shall be focusable
And no item shall have initial focus
So focus highlights shall only appear after the first D-pad interaction

### Song menu is navigable

Where a song list item is focused via D-pad
When the user navigates right to the menu button
The menu button shall show its own focus highlight

When the user presses select
The song actions bottom sheet shall open

### Sort menu is navigable

Where the Library or Playlist Detail screen is displayed
When the user navigates to the sort button
And presses select
The sort options shall be shown
And the user shall be able to navigate and select an option

### Search input is focusable

Where the Search screen is displayed
The search field shall be focusable via D-pad
And no element shall have initial focus

When the user presses down from the search field
Focus shall move to the tabs below

## D-pad — focus behavior

### Focus only shown after D-pad interaction

Where any screen is displayed
No element shall have initial focus
So no focus highlights shall be shown on touch

When the user presses a D-pad direction
Focus shall move to the nearest focusable element
And the element shall show its focus highlight

### Focus memory restores position on return

Where the user navigated from Library to Search
And focused a specific search result
When the user navigates back to Library
The previously focused position shall be restored

### Back button closes overlays and unfocuses inputs

Where a text field is focused
When the user presses the back button
The text field shall be unfocused

Where a bottom sheet or dialog is open
When the user presses the back button
The overlay shall be dismissed

### Device entry point

When the app is launched from the device home screen
The app shall open directly to the main screen
And the sidebar navigation shall have initial focus
## Library section

### Settings screen shows Library section

Where the settings screen is displayed
A Library section header shall be shown above the backup and restore controls

### Library section contains backup and restore controls

Where the Library section is displayed
A Backup tile shall be shown
When the user taps the Backup tile
The app shall open a backup confirmation dialog
And the dialog shall show the full filesystem path to the Backups folder
And the dialog shall show how many songs and playlists will be backed up
And the dialog shall offer a copy control for the backup folder path
When the user confirms the backup in the dialog
The app shall export the library to a JSON backup file

Where the Library section is displayed
A Restore tile shall be shown
When the user taps the Restore tile
The app shall open a restore confirmation dialog
And the dialog shall show the full filesystem path to the Restore folder
And the dialog shall show how many songs and playlists the backup contains
And the dialog shall offer a copy control for the restore folder path
When the user confirms the restore in the dialog
The app shall import songs and playlists from the backup

### Backup feedback is shown

Where the user triggers a backup
When the backup completes successfully
The backup dialog shall stay open and confirm success inline, showing the written backup file path with a copy control and a Done button

When the backup fails
The backup dialog shall show an error with a Retry option

The result is shown in the dialog rather than a transient SnackBar so the outcome and the file location are not missed

### Restore feedback is shown

Where the user triggers a restore
When the restore completes successfully
The restore dialog shall stay open and confirm success inline, showing how many songs and playlists were imported with a Done button

When the restore fails (a file was found but import errored)
The restore dialog shall show an error with a Retry option

When no backup JSON is found in the Restore folder
The restore dialog shall show that no backup was found and tell the user to copy a backup JSON to the Restore folder

The result is shown in the dialog rather than a transient SnackBar so the outcome is not missed

### Backup location is shown in Library section

Where the user has created a backup
The app shall show the backup folder path in the Library section
And the path shall be the full filesystem path to the Backups folder

### Backup path is read-only in Library section

Where the user views the backup location in the Library section
The backup location tile shall display the current backup folder path
And tapping it shall copy the path to the clipboard
And shall not open a folder picker or allow changing the path

## Appearance section

### Settings screen shows Appearance section

Where the settings screen is displayed
An Appearance section shall be shown above the About section
And the section shall show a Theme color tile

### Theme color can be chosen

Where the Appearance section is displayed
A Theme color tile shall be shown with the current accent color
When the user taps the tile
A list of preset theme colors shall be shown
When the user selects a color
The app theme shall change to the selected color
And the selected color shall be marked in the list
And the choice shall persist across restarts

The default theme color shall be Green

## Playback section

### Settings screen shows Playback section on Android

Where the settings screen is displayed
And the app is running on Android
A Playback section header shall be shown above the battery optimization control

Where the settings screen is displayed
And the app is not running on Android
The Playback section shall not be shown

### Battery optimization tile is shown on Android

Where the Playback section is displayed
A Disable Battery Optimization tile shall be shown
And the tile shall show whether battery optimization is currently disabled
When the user taps the tile
The app shall open the Android battery optimization settings for this app

## About section

### Settings screen shows About section

Where the settings screen is displayed
An About section shall be shown at the bottom of the settings list
And the section shall display the installed version

### Version is shown as a tile

Where the About section is displayed
A Version tile shall be shown showing the installed version
And the tile shall display the update status beside the version

### Update available is shown in the version tile

Where a newer release exists on GitHub
When the update check completes
The version tile shall show that an update is available and its version

### Up-to-date status is shown in the version tile

Where the installed version matches the latest release
When the update check completes
The version tile shall indicate the app is up to date

### Version tile tap shows update popup

Where the About section is displayed
When the user taps the Version tile
A popup dialog shall open showing the current update status
And if an update is available, the popup shall show the version and an Update button
And if the app is up to date, the popup shall show a message indicating this
And if the update check failed or has not completed, no popup shall appear

### Update popup shows update available with button

Where a newer release exists on GitHub
When the user taps the Version tile
The popup shall show "Update available" with the version
And the popup shall provide a button to open the release page
And the popup shall show a Cancel or Done button to close it

### Update popup shows up to date status

Where the installed version matches the latest release
When the user taps the Version tile
The popup shall show a message indicating the app is up to date
And the popup shall provide a Done button to close it

### Update check failure is silent

Where the network request fails
When the update check completes
The version tile shall not show an update or up-to-date status
The app shall not crash or show an error dialog

### Source Code tile opens repository

Where the About section is displayed in settings
A Source Code tile shall be shown
When the user taps the tile
The GitHub repository shall open in the system browser

### About section shows attribution

Where the About section is displayed
The copyright notice shall be shown at the bottom
And "Built with Flutter" shall be shown

## Build

### Release build works on all devices

When a release build is created
The app shall work on all supported devices
And no device-specific packages shall be generated
