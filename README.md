# wekiosc

wekiosc sends motion, XY pad, or camera samples over OSC to
[Wekinator](http://www.wekinator.org/). It also controls recording, training,
running, and deleting examples from the phone.

## Build

Open `Modern/wekioscModern.xcodeproj` in Xcode 26 or newer and select the
`wekiosc` scheme. The bundle identifier is `uk.ishimura.wekiosc`, matching the
existing App Store Connect record. Version 1.1 targets iOS 16 and newer.

`Modern/project.yml` is the XcodeGen source for the project. Regenerate with
`xcodegen generate` from `Modern/`. The new app has no CocoaPods dependencies.
The original iOS 11 app and vendored Pods remain in Git history.

## Use

Enter the host and port of Wekinator, tap **Connect**, select a source, and
turn on **Send inputs**. The default port is 6448. Motion fields are optional;
only enabled fields are sent. The pad sends normalized X and Y values. Camera
mode sends 20 normalized brightness values from a 4 × 5 grid, and asks for
camera permission only when selected.

## Release checks

- Test all three input modes with Wekinator on a real iPhone, especially motion,
  heading, camera permissions, and network reconnection.
- Archive with the Apple distribution team, upload version 1.1 to the existing
  App Store record, and capture current iPhone and iPhone Duo screenshots.
- Set the United Kingdom base price to £0.99 and review Apple's converted
  prices for all other storefronts before submitting for review.
