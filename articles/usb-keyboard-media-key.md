---
published: true
type: tech
topics:
  - Keyboard
emoji: 💻
title: USB HIDキーボードでメディアキーを操作する方法
---

USB HIDでは`0x80`がVolume Up、`0x81`がVolume Downに割り当てられており、さらに`0xED`や`0xEE`でもVolume UpやDownができそうですが、実はこれらは全て動きません(Windowsでは)。

Volume UpやDownを送るためには通常のキーボード用レポートディスクリプタではなく、メディアキー専用のレポートディスクリプタを使うデバイスを作成する必要があります。

他の言語では分かりませんが、Rustでは`usbd_hid`を用いることでメディアキー用のレポートを作成することができます。

https://docs.rs/usbd-hid/latest/usbd_hid/descriptor/struct.MediaKeyboardReport.html

バリアントとして使用可能なのは以下のキーになります。

https://docs.rs/usbd-hid/latest/usbd_hid/descriptor/enum.MediaKey.html

抜粋:
```rust
pub enum MediaKey {
    Zero = 0x00,
    Play = 0xB0,
    Pause = 0xB1,
    Record = 0xB2,
    NextTrack = 0xB5,
    PrevTrack = 0xB6,
    Stop = 0xB7,
    RandomPlay = 0xB9,
    Repeat = 0xBC,
    PlayPause = 0xCD,
    Mute = 0xE2,
    VolumeIncrement = 0xE9,
    VolumeDecrement = 0xEA,
    Reserved = 0xEB,
}
```

デバイスの作成は例えば`embassy_usb`では以下のようになります。
```rust
let config = embassy_usb::class::hid::Config {
    report_descriptor: MediaKeyboardReport::desc(),
    request_handler: None,
    poll_ms: 10,
    max_packet_size: 64,
};
HidReaderWriter::<_, 1, 8>::new(&mut builder, &mut State::new(), config)
```

メディアキーでは送信できるのは一つのキーのみで、さらに「押されている状態を送信する」通常のキーとは違い「送信するたびに押されたことにする」ようになっているみたいです。

> この記事は [https://note.nazo6.dev/blog/usb-keyboard-media-key](https://note.nazo6.dev/blog/usb-keyboard-media-key) とのクロスポストです。