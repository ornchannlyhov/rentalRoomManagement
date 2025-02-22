# Receipts_v2

**Receipts_v2** is a simple offline Flutter application designed to help asset owners (e.g., apartment managers, rental property owners, or landlords) manage their rental assets and monthly billing efficiently. The app provides an owner-side interface and stores all data locally on the user's device.

## Features

- Manage rental assets such as apartments, rental houses, or rooms.
- Record and track monthly bills for tenants.
- Offline-first: all data is securely stored on the user's device.
- Simplified navigation between screens with proper state management.
- Learn how to implement essential Flutter development techniques.

## Key Learning Points

This project serves as a learning resource for understanding:

- **Routing and State Management:** Learn to navigate between screens using Flutter's routing mechanisms.
- **Data Passing:** Understand how to pass data between screens effectively.
- **Stateful vs. Stateless Widgets:** Identify when to use Stateful and Stateless widgets based on your app's requirements.
- **File Management:** Handle local file storage for saving and retrieving data.

## Getting Started

Follow these steps to set up and run the project:

### Prerequisites

1. **Install Flutter:** Follow the official [Flutter installation guide](https://docs.flutter.dev/get-started/install) to set up Flutter on your machine.
2. **Install a code editor:** Use [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/) with the Flutter and Dart plugins.
   - [Android Studio Plugin](https://plugins.jetbrains.com/plugin/9212-flutter)
   - [VS Code Plugin](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
3. **Set up a device:** Use a physical device or an emulator for testing. You can find instructions on setting up emulators within the official [Flutter documentation](https://docs.flutter.dev/get-started/test-drive#emulator).

### Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/ornchannlyhov/rentalRoomManagement
   cd receipts_v2
   ```

2. Get the project dependencies:

   ```bash
   flutter pub get
   ```

3. Run the application:

   ```bash
   flutter run
   ```

### Folder Structure

    lib/
    ├── main.dart         # Entry point of the application
    ├── data/             # Contain the data from the application
    ├── model/            # Data models used in the app
    ├── view/             # Contain everything relate to the user interface
    ├── diagrams/         # Widget diagram and Class UML

## Resources

For additional help with Flutter development, check out the following resources:

- **Lab: Write your first Flutter app:** [Flutter codelab](https://docs.flutter.dev/codelabs/first-flutter-app-pt1)
- **Cookbook: Useful Flutter samples:** [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- **Flutter Documentation:** [Flutter Official Website](https://flutter.dev/) - Tutorials, examples, and API references.
- **Flutter Layout Cheat Sheet:** [Flutter Layout Cheat Sheet](https://flutterlayoutcheat.sheet.zapp.run/)

## Contribution

Contributions to improve the app or expand its functionality are welcome. Please fork the repository, make your changes, and submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
