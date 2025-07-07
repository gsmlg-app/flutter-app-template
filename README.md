# Flutter App Template

## Getting Started

This project is a template for creating flutter app.


## App Scaffold (mason bricks)

Init mason cli

```shell
dart pub global activate mason_cli
mason get
```

### Create API brick

Create `api` generator code, run `mason` command.

```shell
mason make api_gen -o api_gen/blog --package_name=blog_api
# then add  app_api/blog_api to `workspace` in `pubspec.yaml`
```

### Create Bloc brick

Create a simple `bloc` package in this app.

```shell
mason make simple_bloc -o app_bloc/hex --name=hex
```

