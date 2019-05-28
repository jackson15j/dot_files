Programming the Vortex Core
===========================

Create a layout file
--------------------

* Use: [TsFreddie/much-programming-core] ([Github:
  TsFreddie/much-programming-core]) to create a `*.cys` file.
* Start by uploading the `export.txt` JSON layout file.
* Make modifications.
* Export JSON for prosperity.
* Generate the binary `*.cys` file.

Program the board
-----------------

* Unplug the board.
* Hold `Fn + d` and then re-plug in the board.
* Copy the `*.cys` file to the newly discovered USB Mass Storage device.
* Unplug and re-plug in the board.

OS Gotcha's
-----------

* Manjaro: Default keymap for `[Shift+]AltGr+#` does not give backslash (`\`)
  or bar/pipe (`|`). Added a new `xkbmap` that can is loaded to correct this.


[TsFreddie/much-programming-core]: https://tsfreddie.github.io/much-programming-core/
[Github: TsFreddie/much-programming-core]: https://github.com/TsFreddie/much-programming-core
