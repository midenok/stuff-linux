Compile terminfo from `screen`:
```
tic screen
```

You will get compiled DB in `.terminfo/s/screen`.

Run `screen`, check your current TERM:
```
$ echo $TERM
screen
```
This means that your compiled DB will be used by terminfo.

You may [disable global shortcuts](https://askubuntu.com/a/1286401/335914) in Konsole for Ctrl+Fx, Alt+Fx to work.

Run `tack`, then `n) begin testing` -> `f) test function keys`, you may see:
```
Testing ENQ/ACK, standby...
```

Press any key, you will see:

```
This program expects the ENQ sequence to be answered with the ACK character.  This will help the program reestablish
synchronization when the terminal is overrun with data.

ENQ sequence from (u9): ^E
ACK received: d
Length of ACK 1.  Expected length of ACK 0.
```

This means that your terminal (i.e. `screen`) doesn't respond to ENQ sequence. Well, nothing to worry about
(though should be fixed in future).

Go `k) test function keys`, you will see:
```
The following keys are defined:
^H      kbs     ^[[3~   kdch1   ^[OB    kcud1   ^[OP    kf1     ^[[21~  kf10    ^[OQ    kf2     ^[OR    kf3     ^[OS    kf4
^[[15~  kf5     ^[[17~  kf6     ^[[18~  kf7     ^[[19~  kf8     ^[[20~  kf9     ^[[1~   khome   ^[[2~   kich1
^[OD    kcub1   ^[[6~   knp     ^[[5~   kpp     ^[OC    kcuf1   ^[OA    kcuu1   ^[[Z    kcbt    ^[[4~   kend
^[[23~  kf11    ^[[24~  kf12    ^[[23;2~kf13    ^[[24;2~kf14    ^[[23;5~kf15    ^[[24;5~kf16    ^[[23;3~kf17
^[[24;3~kf18    ^[[24;4~kf19    ^[O2P   kf21    ^[O2Q   kf22    ^[O2R   kf23    ^[O2S   kf24    ^[[15;2~kf25
^[[17;2~kf26    ^[[18;2~kf27    ^[[19;2~kf28    ^[[20;2~kf29    ^[[21;2~kf30    ^[O5P   kf31    ^[O5Q   kf32
^[O5R   kf33    ^[O5S   kf34    ^[[15;5~kf35    ^[[17;5~kf36    ^[[18;5~kf37    ^[[19;5~kf38    ^[[20;5~kf39
^[[21;5~kf40    ^[O3P   kf41    ^[O3Q   kf42    ^[O3R   kf43    ^[O3S   kf44    ^[[15;3~kf45    ^[[17;3~kf46
^[[18;3~kf47    ^[[19;3~kf48    ^[[20;3~kf49    ^[[21;3~kf50    ^[O4P   kf51    ^[O4Q   kf52    ^[O4R   kf53
^[O4S   kf54    ^[[15;4~kf55    ^[[17;4~kf56    ^[[18;4~kf57    ^[[19;4~kf58    ^[[20;4~kf59    ^[[21;4~kf60
^[[23;4~kf61    ^[[1;2H kf62    ^[[1;3H kf63

Hit any function key.  Type 'end' to quit.  Type ? to update the display.

```

Try to press any Alt+Fx, Ctrl+Fx, Shift+Fx, Alt+Shift+Fx: you will see corresponding names (kf4x, kf3x, kf2x, kf5x).
This means that terminfo DB works!

Important: don't forget to configure your terminal application to send correct keycodes! Look at [Wiki](https://github.com/midenok/linux/wiki/GNU-Screen) for Konsole configuration tips.

Now:

1. get corresponding `screenrc` (it must contain same keycodes);
2. put it to `~/.screenrc`;
4. run `screen`;
5. Write something on command prompt, then try to switch to another screen with Alt+F2 and return back with Alt+F1.

Consider following features to implement:

* some prefix keybinding to pass keybindings to child process (to be able to test in tack assigned keybindings);
* terminfo names of keybindings instead of codes in `screenrc`;
* screen name into envvar of child shell to be able to put into PS1;
* shorter bell message timeout (i.e. press Alt+F2 two times, you will see `This IS window 1 (bash).`);
* bell message on any screen switch.

