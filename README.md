# Evidence for callstack/agent-device#4183

Client head `12580a6aab780ee3992ce03c9ffcaf569e6caefe`. Run on Linux with this head's CLI.

- `live-transcript.txt`, `live-rpc.ndjson`, `wallet.png`: LIVE. The real simlock gateway and a real iPhone 17 Pro simulator, iOS 26.2. The gateway runs simlock main with #1225, and the daemon behind it is agent-device 0.21.36, not this head. `live-rpc.ndjson` was recorded by a local logging relay between the CLI and the gateway. The "disabled launchd labels" count in the transcript is unverified: its raw output was not kept.
- `stub-transcript.txt`: **STUB**. `gw.mjs` on 127.0.0.1 stands in for a gateway, because the real one does not report a mode yet. No device or simulator is involved.
