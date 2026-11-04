# Evidence for callstack/agent-device#4184

Head `19a14237a98a88a6c671fd87c892c2755aad1233`, iPhone 17 Pro simulator, iOS 26.2, slim, macOS 15.7.4, Xcode 26.3. `transcript.txt` holds the commands, output and exit codes, and the session cleanup.

`android-transcript.txt`: same head, Pixel 9 emulator, API 35 `google_apis`, driven from macOS 15.7.4.

`provider-refusal.txt`: head `9feb2693639796426a67ae0780bf393639edf2f1`, admission boundary only, not a live provider run. The two transcripts above are from `19a14237a`.

`58d7bd8ec/`: LIVE runs at that head on a farm simulator and emulator: the Android refusal, and a local iOS Maestro comparison. `runner-screenshots.txt` is from the session `runner.log`. No provider run: that awaits credentials.

`879765634/`: LIVE run at that head: an explicit runner capture through the copy-back reworked by #4213, verified by `pngcheck.py`.
