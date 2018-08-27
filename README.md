# Accounts4Fixer: Alternative tool for Mail.app account settings panel.

## CAUTION

__THIS APPLICATION DIRECTLY MODIFIED `~/Library/Accounts/Accounts4.sqlite` DATABASE.  YOU SHOULD NOT USE THIS TOOL IF YOU ARE NOT FAMILIAR WITH IT.__

## What's this

Mail.app on macOS High Sierra(at least up to 10.13.6) has a bug that it cannot accept 'Allow insecure authentication' enabled settings.

The Mail.app tries to check whether newly entered authentication information is valid or not before saving the setting values, but if the server does not support 'SSL' connection, the app fails to this validation, and it prevents to save the information.

This application allows you to set some properties for Mail.app settings.

## Screen Shot

![ScreenShot1](https://raw.githubusercontent.com/n-miyo/Accounts4Fixer/master/ScreenShots/1.png)

## How to compile it.

You can build this source code with Xcode 8 with this instruction.  You also can download pre build binary from [here](https://github.com/n-miyo/Accounts4Fixer/releases/download/v1.0.0/Accounts4Fixer-v100.app.zip), or,

1. Install `carthage` command.  One of the easy way is to use `brew` command.
```
% brew install carthage
```

2. Build related libraries with `carthage`.
```
% carthage update --platform macos
```

3. open `Accounts4Fixer.xcodeproj` with Xcode8 and run it(command + R).


## Notice

- NO WARRANTY.
- You should quit `Mail.app` before updating your information.
- macOS Mojave will fix this bug.  If you have a plan to install the new OS and you can wait until the release date, I recommend do so.

## License

MIT.
