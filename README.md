[MeowlWatch]
============

[![][App Icon]][MeowlWatch]

[MeowlWatch] is an iOS app for students at Northwestern to check their dining account balance, and see what's open around them.

[MeowlWatch]: https://itunes.apple.com/us/app/meowlwatch-for-northwestern-university-dining/id1219875692?mt=8
[App Icon]: 1024.png

- [Installation]
- [Overview]

[Installation]: #installation
[Overview]: #overview

Installation
------------
1. Clone the repo.
2. Run `git submodule update --init` to fetch schedules managed by [another repo][Schedules].
3. Open `MeowlWatch.xcworkspace` in Xcode 9.3.
4. Change the "Bundle Identifier" and "Team" for all targets in the `MeowlWatch Project`.
5. If building for Release, add a file `MeowlWatch/AdMobKeys-Release.plist` in the same format as `MeowlWatch/AdMobKeys-Debug.plist`.

[Schedules]: https://github.com/NathanJang/MeowlWatch-Schedules

Overview
--------
This is a [UITableViewController]-based app. The main app links with:

- `MeowlWatch Widget`, which is the widget on the notification center
- `MeowlWatchData`, which is a common framework that deals with fetching and storing data for the app
- Additional frameworks in [Podfile] under their respective licenses

[UITableViewController]: https://developer.apple.com/documentation/uikit/uitableviewcontroller
[Podfile]: Podfile
