## Keycode Generator

This directory contains a keycode generator that can generate Dart code for
the `LogicalKeyboardKey` and `PhysicalKeyboardKey` classes. It draws information
from both the Chromium and Android source bases, and incorporates the
information it finds in those sources into a single key database in JSON form.

It then generates `keyboard_key.dart` (containing the `LogicalKeyboardKey` and
`PhysicalKeyboardKey` classes), and `keyboard_maps.dart`, containing
platform-specific immutable maps for translating platform keycodes and
information into the pre-defined key values in the `LogicalKeyboardKey` and
`PhysicalKeyboardKey` classes. 

The `data` subdirectory contains both some local data files, and the templates 
used to generate the source files.

 - `data/key_data.json`: contains the merged data from all the other sources.
    This file will be regenerated if "--collect" is specified for the
    gen_keycodes script.
 - `data/key_name_to_android_name.json`: contains a mapping from Flutter key
   names to Android keycode names (with the "KEY_" prefix stripped off).
 - `data/keyboard_key.tmpl`: contains the template for the `keyboard_key.dart`
   file. Markers that begin and end with "@@@" denote the locations where
   generated data will be inserted.
 - `data/keyboard_maps.tmpl`: contains the template for the `keyboard_maps.dart`
   file. Markers that begin and end with "@@@" denote the locations where
   generated data will be inserted.
 - `data/printable.json`: contains a mapping between Flutter key name and its
   printable character. This character is used as the key label.
 
 ## Running the tool
 
To run the `gen_keycodes` tool using the checked in `key_data.json` file, run
it like so:

```bash
$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart bin/gen_keycodes.dart
```

This will rengerate the `keyboard_key.dart` and `keyboard_maps.dart` files in
place.

If you wish to incorporate and parse changes from the Chromium and Android
source trees, add `--collect` to the command line. The script will download and
incorporate the changed data automatically. Note that the parsing is specific to
the format of the source code that it is reading, so if the format of those
files changes appreciably, you will need to update the parser.

There are other options for manually specifying the file to read in place of the
downloaded files, use `--help` to see what is available.

If the data in those files changes in the future to be unhelpful, then we can
switch to another data source, or abandon the parsing and maintain
`key_data.json` manually. All output files and local input files should be
checked in.

## Key Code ID Scheme

In order to provide keys with unique ID codes, Flutter uses a scheme to assign
codes which keeps us out of the business of minting new codes ourselves.

The codes are meant to be opaque to the user, and should never be unpacked for
meaning, since the code scheme could change at any time, and the meaning is
likely to be retrievable in a more reliable and correct manner from the API.

However, if you are porting Flutter to a new platform, you should follow the
following guidelines for specifying key codes.

The key code is a 37-bit integer in a namespace that we control and define. It
has values in the following ranges.

  - **0x00 0000 0000 - 0x0 0010 FFFF**: For keys that generate Unicode
    characters when pressed (this includes dead keys, but not e.g. function keys
    or shift keys), the logical key code is the Unicode code point corresponding
    to the representation of the key in the current keyboard mapping. The
    Unicode code point might not actually match the string that is generated for
    an unshifted key press of that key, for example we would use U+0034 for the
    “4 $” key in the US layout, and also the “4 ;” key in the Russian layout,
    and also, maybe less intuitively, for the “' 4 {“ in French layout (where in
    the latter case, an unshifted press gets you a ', not a 4). Similarly, the Q
    key in the US layout outputs a q in normal usage, but its code would be 0x0
    0000 0051 (U+00051 being the code for the uppercase Q).

  - **0x01 0000 0000 - 0x01 FFFF FFFF**: For keys that are defined by the USB HID
    standard, the key code consists of the 32 bit USB extended usage code. For
    example, the Enter key would have code 0x0 0007 0028. Only keys that fall
    into collections "Keyboard", "Keypad", and "Tablet PC System Controls" are
    considered for this API; for example, a mixing desk with multiple
    collections of volume controls would not be exposed via DOWN and UP events,
    nor would a mouse, joystick, or golf simulator control.

  - **0x02 0000 0000 - 0xFF FFFF FFFF**: For keys that aren't defined in USB at the
    time of implementation, but that we need to support. For example, if Flutter
    were ever ported to the Symbolics LM-2, the "thumb up" key might be given
    the code 0x14 0000 0001, where 0x14 is defined as the “Symbolics” platform
    range. Where possible, we will use specific subranges of this space to reuse
    keys from other platforms. When this is not possible, the prefix 0xFF is
    reserved for “Custom” codes. Each platform from which we take codes will get
    a unique prefix in the range 0x2-0xFE. If multiple systems define keys with
    the same usage (not the same number), then the value with the lowest prefix
    is used as the defining code.
 
    Prefixes will be:
    
    |Code|Platform|
    |----|--------|
    |0x02| Android|
    |0x03|Fuchsia |
    |0x04|iOS     |
    |0x05|macOS   |
    |0x06|Linux   |
    |0x07|Windows |
    |0x08|Web     |
    |0xFF|Custom  |

    Further ranges will be added as platforms are added. The platform prefix
    does not define the platform it is used on, it is just the platform that
    decides what the value is: the codes are mapped to the same value on all
    platforms.

  - **0x100 0000 0000 - 0x1FF FFFF FFFF**: For keys that have no definition yet in
    Flutter, but that are encountered in the field, this range is used to embed
    the platform-specific keycode in an ID that must be tested for in a platform
    specific way. For instance, if a platform generates a new USB HID code 0x07
    00E8 that a Flutter app wasn’t compiled with, then it would appear in the
    app as 0x100 0007 00E8, and the app could test against that code. Yes, this
    also means that once they recompile with a version of Flutter that supports
    this new HID code, apps looking for this code will break. This situation is
    only meant to provide a fallback ability for apps to handle esoteric codes
    that their version of Flutter doesn’t support yet. The prefix for this code
    is the platform prefix from the previous sections, plus 0x100.

**This is intended to get us out of the business of defining key codes where
possible.** We still have to have mapping tables, but at least the actual minting
of codes is deferred to other organizations to a large extent. Coming up with a
code is a mechanical process consisting of just picking the lowest number code
possible that matches the semantic meaning of the key according to the
definitions above.

Here are some examples:

For example, on a French keyboard layout, pressing CAPS LOCK then pressing
SHIFT + Y would generate the following sequence:

DOWN, code 0x00070039. (CAPS LOCK DOWN)<br>
UP, code 0x00070039. (CAPS LOCK UP)<br>
DOWN, code 0x000700E1 (SHIFT DOWN)<br>
DOWN, code 0x0007001D, string U+00059 (Y DOWN, the code is for the "Z" key, but
string is the character, "Y")<br>
UP, code 0x0007001D (Y UP)<br>
UP, code 0x000700E1 (SHIFT UP)<br>

Here's another example. On a German keyboard layout, you press ^e (the ^ key is
at the top left of the keyboard and is a dead key) to produce a “ê”:

DOWN, code 0x00070035 (GRAVE DOWN) Assuming that the keymap maps it to the same
logical key, it produces no string, because it's a dead key. The HID key is for
"Keyboard grave accent and tilde" in AT-101 keyboard typical position 1.<br>
UP, code 0x00070035 (GRAVE UP)<br>
DOWN, code 0x00070008, string U+000EA (Unicode for ê‬) (E DOWN).<br>
UP, code 0x00070008. (E UP).<br>

It is an important point that even though we’re representing many keys with USB
HID codes, these are not necessarily the same HID codes produced by the hardware
and presented to the driver, since on most platforms we have to map the platform
representation back to a HID code because we don’t have access to the original
HID code. USB HID is simply a conveniently well-defined standard that includes
many of the keys we would want.