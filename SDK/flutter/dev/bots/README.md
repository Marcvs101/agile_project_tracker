# Flutter's Build Infrastructure

This directory exists to support building Flutter on our build infrastructure.

The results of such builds are viewable at:
* https://cirrus-ci.com/github/flutter/flutter/master
  - Testing done on PRs and submitted changes on GitHub.
* https://ci.chromium.org/p/flutter/
  - Additional testing and processing done after changes are submitted.

The LUCI infra requires permissions to retrigger or schedule builds. Contact
@kf6gpe or another Google member of the Flutter team if you need to do that.

The [Cirrus](https://cirrus-ci.org)-based bots run the [`test.dart`](test.dart)
script for each PR and submission. This does testing for the tools, for the
framework, and (for submitted changes only) rebuilds and updates the master
branch API docs [staging site](https://master-docs.flutter.dev/).
For tagged dev and beta builds, it also builds and deploys the gallery app to
the app stores. It is configured by the [.cirrus.yml](/.cirrus.yml).

We also have post-commit testing with actual devices, in what we call our
[devicelab](../devicelab/README.md).

## LUCI (Layered Universal Continuous Intergration)

A [set of recipes](https://chromium.googlesource.com/chromium/tools/build.git/+/master/scripts/slave/recipes/flutter)
are run on Windows, Linux, and Mac machines. The configuration for how many
machines and what kind are managed internally by Google. Contact @kf6gpe or
another Google member of the Flutter team if you suspect changes are needed
there. Both of these technologies are highly specific to the [LUCI](https://github.com/luci)
project, which is the successor to Chromium's infra. We're just borrowing some
of their infrastructure.

### Prerequisites

To work on this infrastructure you will need:

- [depot_tools](https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up)
- Python package installer: `sudo apt-get install python-pip`
- Python coverage package (only needed for `training_simulation`): `sudo pip install coverage`

To run prepare_package.dart locally:

- Make sure the depot_tools is in your PATH. If you're on Windows, you also need
  an environment variable called DEPOT_TOOLS with the path to depot_tools as value.
- Run `gsutil.py config` (or `python %DEPOT_TOOLS%\gsutil.py` on Windows) to
  authenticate with your auth token.
- Create a local temp directory. `cd` into it.
- Run `dart [path to your normal Flutter repo]/dev/bots/prepare_package.dart
  --temp_dir=. --revision=[revision to package] --branch=[branch to deploy to]
  --publish`.
- If you're running into gsutil permission issues, check with @Hixie to make sure
  you have the right push permissions.

### Getting the code

The following will get way more than just recipe code, but it _will_ get the
recipe code:

```bash
mkdir chrome_infra
cd chrome_infra
fetch infra
```

More detailed instructions can be found [here](https://chromium.googlesource.com/infra/infra/+/master/doc/source.md).

Most of the functionality for recipes comes from `recipe_modules`, which are
unfortunately spread to many separate repositories.  After checking out the code
search for files named `api.py` or `example.py` under `infra/build`.

### Editing a recipe

Flutter has one recipe per repository. Currently
[flutter/flutter](https://chromium.googlesource.com/chromium/tools/build.git/+/master/scripts/slave/recipes/flutter/flutter.py)
and
[flutter/engine](https://chromium.googlesource.com/chromium/tools/build.git/+/master/scripts/slave/recipes/flutter/engine.py):

- build/scripts/slave/recipes/flutter/flutter.py
- build/scripts/slave/recipes/flutter/engine.py

Recipes are just Python with some limitations on what can be imported. They are
[documented](https://github.com/luci/recipes-py/blob/master/doc/user_guide.md)
by the [luci/recipes-py github project](https://github.com/luci/recipes-py).

The typical cycle for editing a recipe is:

1. Make your edits (probably to files in
   `//chrome_infra/build/scripts/slave/recipes/flutter`).
2. Update the tests. Run `build/scripts/slave/recipes.py test train` to update
   existing expected output to match the new output. Verify completely new test
   cases by altering the `GenTests` method of the recipe. The recipe is required
   to have 100% test coverage.
3. Run `led get-builder 'luci.flutter.prod:BUILDER_NAME' | led edit -p 'revision="GIT_HASH"' | led edit-recipe-bundle | led launch`, where `BUILDER_NAME` is the builder name (e.g. `Linux Engine`), and 
   `GIT_HASH` is the hash to build (which is important for the engine but not 
   for the framework).
4. To submit a CL, you need a local branch first (`git checkout -b [some branch name]`).
5. Upload the patch (`git commit`, `git cl upload`) and send it to someone in
   the `recipes/flutter/OWNERS` file for review.

### The infra config repository

The [flutter/infra](https://github.com/flutter/infra) repository contains
configuration files for the dashboard, builder groups, scheduling, and
individual builders. Edits to this may require changes other internal Google
repositories - e.g., to change the operating system or number of machines. If
you want to do that, reach out to @kf6gpe or another member of the Google team.

Each configuration file in that repository has a link in the top comments to a
schema that describes available properties.

### Future Directions

We would like to host our own recipes instead of storing them in
[build](https://chromium.googlesource.com/chromium/tools/build.git/+/master/scripts/slave/recipes/flutter).
Support for [cross-repository
recipes](https://github.com/luci/recipes-py/blob/master/doc/cross_repo.md) is
in-progress.  If you view the git log of this directory, you'll see we initially
tried, but it's not quite ready.


### Android Tools

The Android SDK and NDK used by Flutter's Chrome infra bots are stored in Google
Cloud. During the build a bot runs the `download_android_tools.py` script that
downloads the required version of the Android SDK into `dev/bots/android_tools`.

To check which components are currently installed, download the current SDK
stored in Google Cloud using the `download_android_tools.py` script, then
`dev/bots/android_tools/sdk/tools/bin/sdkmanager --list`. If you find that some
components need to be updated or installed, follow the steps below:

#### How to update Android SDK on Google Cloud Storage

1. Run Android SDK Manager and update packages
   `$ dev/bots/android_tools/sdk/tools/android update sdk`
   Use `android.bat` on Windows.

2. Use the UI to choose the packages you want to install and/or update.

3. Run `dev/bots/android_tools/sdk/tools/bin/sdkmanager --update`. On Windows,
   run `sdkmanager.bat` instead. If the process fails with an error saying that
   it is unable to move files (Windows makes files and directories read-only
   when another process is holding them open), make a copy of the
   `dev/bots/android_tools/sdk/tools` directory, run the `sdkmanager.bat` from
   the copy, and use the `--sdk_root` option pointing at
   `dev/bots/android_tools/sdk`.

4. Run `dev/bots/android_tools/sdk/tools/bin/sdkmanager --licenses` and accept
   the licenses for the newly installed components. It also helps to run this
   command a second time and make sure that it prints "All SDK package licenses
   accepted".

5. Run upload_android_tools.py -t sdk
   `$ dev/bots/upload_android_tools.py -t sdk`

#### How to update Android NDK on Google Cloud Storage

1. Download a new NDK binary (e.g. android-ndk-r10e-linux-x86_64.bin)
2. cd dev/bots/android_tools
   `$ cd dev/bots/android_tools`

3. Remove the old ndk directory
   `$ rm -rf ndk`

4. Run the new NDK binary file
   `$ ./android-ndk-r10e-linux-x86_64.bin`

5. Rename the extracted directory to ndk
   `$ mv android-ndk-r10e ndk`

6. Run upload_android_tools.py -t ndk
   `$ cd ../..`
   `$ dev/bots/upload_android_tools.py -t ndk`


## Flutter codelabs build test

The Flutter codelabs exercise Material Components in the form of a
demo application. The code for the codelabs is similar to, but
distinct from, the code for the Shrine demo app in Flutter Gallery.

The Flutter codelabs build test ensures that the final version of the
[Material Components for Flutter
Codelabs](https://github.com/material-components/material-components-flutter-codelabs)
can be built. This test serves as a smoke test for the Flutter
framework and should not fail. If it does, please address any issues
in your PR and rerun the test. If you feel that the test failing is
not a direct result of changes made in your PR or that breaking this
test is absolutely necessary, escalate this issue by [submitting an
issue](https://github.com/material-components/material-components-flutter-codelabs/issues/new?title=%5BURGENT%5D%20Flutter%20Framework%20breaking%20PR)
to the MDC-Flutter Team.
