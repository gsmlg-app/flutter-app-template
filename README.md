# Flutter App Template

A feature-rich Flutter application template.

## Getting Started

### Prerequisites

- Flutter SDK
- Melos

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/flutter-app-template.git
    cd flutter-app-template
    ```

2.  **Install Melos:**

    ```bash
    dart pub global activate melos
    ```

3.  **Bootstrap the project:**

    This will install all the dependencies for the root project and all the packages in the workspace.

    ```bash
    melos bootstrap
    ```

## Project Structure

This project is a monorepo managed by [Melos](https://melos.invertase.dev/). The project is divided into several packages, each with a specific purpose.

-   `lib/`: Main application source code.
-   `app_api/`: Contains the generated API client.
-   `app_bloc/`: BLoC (Business Logic Component) packages for state management.
-   `app_lib/`: Shared libraries for theme, localization, and providers.
-   `app_widget/`: Reusable widgets.
-   `bricks/`: Mason bricks for code generation.
-   `third_party/`: Third-party packages that are not available on pub.dev or are modified.

## Development

### Available Melos Scripts

This project uses Melos to manage the monorepo. Here are some of the available scripts:

-   `melos run lint:all`: Run all static analysis checks.
-   `melos run analyze`: Run `flutter analyze` for all packages.
-   `melos run fix`: Run `dart fix` for all packages.
-   `melos run format`: Run `dart format` for all packages.
-   `melos run upgrade`: Upgrade dependencies in all packages.
-   `melos run outdated`: Check for outdated dependencies in all packages.
-   `melos run validate-dependencies`: Validate dependencies usage.

## App Scaffold (mason bricks)
 
Init mason cli
 
```shell
dart pub global activate mason_cli
mason get
```
 
### Create API brick

Create `api` generator code, run `mason` command.
 
```shell
mason make api_client -o app_api/app_api --package_name=app_api
# then add openapi spect to `app_api/app_api/openapi.yaml`
```

### Create Bloc brick

Create a simple `bloc` package in this app.

```shell
mason make simple_bloc -o app_bloc/hex --name=hex
```

### Running the App

```bash
flutter run
```

### Running Tests

```bash
flutter test
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.