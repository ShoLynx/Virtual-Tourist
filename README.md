# Virtual-Tourist
**Virtual Tourist** is an Udacity iOS Developer Student project.


## Installation
Clone the GitHub repositiory and use Xcode to install.


## How to Use
When you first open **Virtual Tourist**, you are presented with a full screen **map**.  Place pins at locations of interest.  Then, select that pin to view a auto-generated album of photos from the pin's city or region.

### Map Controls
- Pinch gesture: Set the zoom level of the map
- Held press: Set a pin on the map
- Tap a pin: Enter that pin's album

Once you select a pin, you'll enter that pin's **album**.  The album will contain up to 30 photos that you can scroll through.  You can remove photos by tapping them or get a new set of 30 photos by tapping the New Collection button.

### Album Controls
- Tap a photo: Removes the selected photo from the album
- Swipe collection view: Scrolls through the available photos in the album
- New Collection button: Removes all available photos and downloads a new set of photos

The state of the map pins and albums should persist.  Allowing you to revisit them even after closing the app.

## Planned updates
- A known issue about some albums showing placeholder photos or photos from other albums after New Collection is used is planned to be fixed
- A photo details view is planned to be added to allow users to get a full-screen view of photos in the albums
- A pin delete feature is planned to allow users to remove pins from the map
- A clear map feature is planned to allow users to remove all pins with a single action
