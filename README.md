![DinoBanner](./assets/DinoBanner.png)

# <p align="center">DinoShare</p>

<p align="center"><a href="https://github.com/karticme/dinoshare">GitHub</a></p>

DinoShare is a free, open-source, cross-platform application that enables secure file and text sharing between nearby devices over a local network with no internet connection or central server required.

- [About](#about)
- [Glimpse](#glimpses)
- [Download](#download)
- [Workings](#workings)
- [Getting Started](#getting-started)
- [Contributing](#contributing)

## About

DinoShare is a cross-platform local file sharing app built with Flutter. It lets nearby devices send files, folders, and plain text directly over the same network without needing a central server or internet connection. The app is designed for quick transfers with automatic device discovery, encrypted sessions, and a simple flow for sharing or receiving.

It also includes practical extras for everyday use: drag and drop on desktop, clipboard text sharing, transfer history, favourite devices, and settings for device name, receive folder, theme, and data units. In short, it aims to make local peer-to-peer sharing feel fast, simple, and reliable across Android, iOS, macOS, Windows, and Linux.

## Glimpses

![Transfer screenshot placeholder](./assets/screenshots/transfer-placeholder.png)

## Download

> Releasing soon

<!-- Download apps from below as per your Operating System. Currently it's manual downloads, on app stores, it will released soon. -->

<!-- | Platform | Link |
| --- | --- |
| Android | Build an APK or App Bundle with Flutter. |
| macOS | Build a native macOS app with Flutter. |
| Windows | Build a Windows desktop app with Flutter. | -->

<!-- - **iOS** and **Linux** will be release soon.
- If the app for OS you are looking for is not here then request [here](). -->

### Compatibility

| Platform | OS Version Requirement | Permissions |
| --- | --- | --- |
| Android | 5.0+ | Storage and notification permissions during onboarding. |
| iOS | 14.0+ | Local Network permission may be requested for device discovery. |
| macOS | 11.0+ | Local Network permission may be requested for device discovery. |
| Windows | 10+ | No extra system permissions required. |
<!-- | Linux | Any supported desktop version | No extra system permissions required. | -->

> [!NOTE]
> Make sure VPN is off before start sharing/receiving, otherwise it can break connections or block for device discovery.

## Workings

DinoShare discovers nearby peers on the local network and opens an encrypted transfer session between devices. Transfers happen directly device to device, which keeps the flow local and avoids third-party servers.

## Getting Started

To run DinoShare from source:

1. Install Flutter for your platform [directly](https://flutter.dev) or using [fvm](https://fvm.app). 
2. Clone `dinoshare` repository.
3. Run `flutter pub get` in the project root.
4. Run `flutter run` to launch the app.

On Android, the app may request storage and notification permissions during onboarding so it can receive files and show transfer updates properly.

## Contributing

Contributions are welcome. 

<!-- ### Bug Fixes and Improvements

- If you find a bug, open an issue or submit a pull request with a clear explanation of the problem and the fix.
- If you have an improvement in mind, open an issue first so the change can be discussed before implementation.
- Keep changes focused and consistent with the existing Flutter code style.

### UI, Platform, and Feature Work

- Desktop UX work is especially useful because DinoShare supports drag and drop, transfer dialogs, and platform-specific window behavior.
- Platform-specific fixes for discovery, permissions, and file handling are also valuable.

## Troubleshooting

### Device does not appear

- Confirm both devices are on the same local network.
- Disable AP isolation or guest-network isolation on the router.
- Check that firewalls are not blocking local traffic.
- On Apple platforms, verify that local network access is allowed.

### Incoming transfer never starts

- Make sure the sender has actually started a transfer after selecting a device.
- Check whether the receiver is paused or backgrounded.
- If you enabled always-receive mode, reopen the app and confirm receiver permissions are still granted.

### Received files are hard to find

- Open Settings and review the receive folder.
- Change the destination folder if you prefer a different location for downloaded files.

## Building

Use the standard Flutter build commands from the project root.

### Mobile

- Android APK: `flutter build apk`
- Android App Bundle: `flutter build appbundle`
- iOS: `flutter build ios`

### Desktop

- macOS: `flutter build macos`
- Windows: `flutter build windows`
- Linux: `flutter build linux`

For release distribution, use the platform-specific signing and packaging tools after the Flutter build step.

## Additional Notes

- The onboarding flow exists so the app can request the permissions it needs before discovery and receiving start.
- Desktop drag and drop is handled directly in the app window, which makes quick sharing faster.
- Favourite devices are accepted automatically when you choose to trust them. -->