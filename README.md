# AudioSnapshotServer

*Where do you get the audio data for your visualizer? I pull it out of my ASS.*

TCP/IP server to fetch audio buffer's snapshot from mediaserverd.

## Installation

**iOS 11.0-11.1.2 required.**

**This tweak by itself does nothing noticeable. A client tweak is neccessary for visible effects - try [MitsuhaXI](https://github.com/Ominousness/MitsuhaXI/)**

1. Make sure [Electra](https://coolstar.org/electra/) is installed.
2. Add this repository to Cydia: http://ominous.cf/repo/
3. Install AudioSnapshotServer.

## How to use it in your tweak?

If you send anything to localhost at the port 43333 it will reply with current buffer state. That's all to it.

## Bugs

Feel free to [open a new issue](https://github.com/Ominousness/AudioSnapshotServer/issues/new).
