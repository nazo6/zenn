---
published: true
type: idea
topics:
  - qmkfirmware
  - 自作キーボード
emoji: ⌨️
title: QMKキーIDとアクションのすべて
---

<https://github.com/qmk/qmk_firmware/blob/master/quantum/keycodes.h>

にあるQMKのキーコードのアクションごとの範囲をまとめました。ほぼ全てのQMKのアクションを網羅しているはずです。

# 範囲一覧

QMKでは2バイトの値でほとんど全てのキーマップを表しており、

- 基本のキーコード: 8ビット
- Modifier(ctrlなど): 5ビット
- レイヤ: 5ビット
  のいずれかと余ったビットから成るキーマップの種類を表す固定ビットで構成されています。

これら2バイトの値によりキーコードが表現され、全てのキーコードは

@[card](https://docs.qmk.fm/keycodes)

より確認できます。

以下では各キーマップの種類とその説明、そしてアドレス範囲及びそのデータ構造を記しています。このデータ構造を元に各キーコードからデータを求める実際の計算は

@[card](https://github.com/qmk/qmk_firmware/blob/master/quantum/quantum_keycodes.h)

にあります。

## 凡例

| 項目       | 内容                                     |
| -------- | -------------------------------------- |
| 機能名      | QMKの機能名です。正式な名前が見つからなかったら適当なものをつけています。 |
| キーマップマクロ | キーマップを作成する際の該当するマクロや定数の名前です。           |
| 説明       | その機能の説明です。                             |
| URL      | 参考URLです。                               |

```
↓上位ビット
              ↓下位ビット
←     2byte    →
[ 8bit ][ 8bit ]
00000000         <--          8bit
        ^^^^^^^^ <-- Keycode  8bit
```

↑各キーコードで各ビットが何を表しているかの表示です。

## QK\_BASIC (0x0000-0x00FF)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | 特になし                                 |
| キーマップマクロ | `KC_`で始まる物                           |
| 説明       | 下のKeycodeの項目を参照                      |
| URL      | <https://docs.qmk.fm/keycodes_basic> |

```
[ 8bit ][ 8bit ]
00000000         <--          8bit
        ^^^^^^^^ <-- Keycode  8bit
```

## QK\_MODS (0x0100-0x1FFF)

| 項目       | 内容                                              |
| -------- | ----------------------------------------------- |
| 機能名      | Modifier                                        |
| キーマップマクロ | `LCTL(kc)`,`LSFT(kc)`など                         |
| 説明       | Modとキー同時押し。Modのデコード方法については下のModifierの項目を参照      |
| URL      | <https://docs.qmk.fm/feature_advanced_keycodes> |

```
[ 8bit ][ 8bit ]
000              <--          3bit
   ^^^^^         <-- Modifier 5bit
        ^^^^^^^^ <-- Keycode  8bit
```

modifierのデコード方法は下部を参照。

## QK\_MOD\_TAP (0x2000-0x3FFF)

| 項目       | 内容                            |
| -------- | ----------------------------- |
| 機能名      | Mod-Tap                       |
| キーマップマクロ | `MT(mod, kc)`                 |
| 説明       | Tapでキー,HoldでMod。              |
| URL      | <https://docs.qmk.fm/mod_tap> |

```
[ 8bit ][ 8bit ]
001              <--          3bit
   ^^^^^         <-- Modifier 5bit
        ^^^^^^^^ <-- Keycode  8bit
```

## QK\_LAYER\_TAP (0x4000-0x4FFF)

| 項目       | 内容                                                                       |
| -------- | ------------------------------------------------------------------------ |
| 機能名      | Layer-Tap                                                                |
| キーマップマクロ | `LT(layer, kc)`                                                          |
| 説明       | Tapでキー,HoldでLayer。他のレイヤ関連キーは5bitつまり32レイヤまでいけるがこれは4bitなので16レイヤまでしか指定できない。 |
| URL      | <https://docs.qmk.fm/feature_layers>                                     |

```
[ 8bit ][ 8bit ]
0100             <--          4bit
    ^^^^         <-- Layer    4bit
        ^^^^^^^^ <-- Keycode  8bit
```

## QK\_LAYER\_MOD (0x5000-0x51FF)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | Layer-Mod                            |
| キーマップマクロ | `LM(layer, mod)`                     |
| 説明       | Hold時に`MO`とmod送信を同時にやる。これも16レイヤまで。   |
| URL      | <https://docs.qmk.fm/feature_layers> |

```
[ 8bit ][ 8bit ]
0101000          <--          7bit
       ^^^^      <-- Layer    4bit
           ^^^^^ <-- Modifier 5bit
```

## QK\_TO (0x5200-0x521F)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | TO                                   |
| キーマップマクロ | `TO(n)`                              |
| 説明       | このレイヤを有効化して他のレイヤを無効にする               |
| URL      | <https://docs.qmk.fm/feature_layers> |

```
[ 8bit ][ 8bit ]
01010010000      <--       11bit
           ^^^^^ <-- Layer 5bit
```

## QK\_MOMENTARY (0x5220-0x523F)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | Momentary layer                      |
| キーマップマクロ | `MO(n)`                              |
| 説明       | 押してる間だけレイヤ有効化                        |
| URL      | <https://docs.qmk.fm/feature_layers> |

```
[ 8bit ][ 8bit ]
01010010001      <--       11bit
           ^^^^^ <-- Layer 5bit
```

## QK\_DEF\_LAYER (0x5240-0x525F)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | Default layer                        |
| キーマップマクロ | `DEF(n)`                             |
| 説明       | デフォルトレイヤ設定                           |
| URL      | <https://docs.qmk.fm/feature_layers> |

```
[ 8bit ][ 8bit ]
01010010010      <--       11bit
           ^^^^^ <-- Layer 5bit
```

## QK\_TOGGLE\_LAYER (0x5260-0x527F)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | Toggle layer                         |
| キーマップマクロ | `TG(n)`                              |
| 説明       | 押下でレイヤの有効無効切り替え                      |
| URL      | <https://docs.qmk.fm/feature_layers> |

```
[ 8bit ][ 8bit ]
01010010011      <--       11bit
           ^^^^^ <-- Layer 5bit
```

## QK\_ONE\_SHOT\_LAYER (0x5280-0x529F)

| 項目       | 内容                                  |
| -------- | ----------------------------------- |
| 機能名      | One shot layer                      |
| キーマップマクロ | `OSL(n)`                            |
| 説明       | 次のキー押下時にこのレイヤを使用                    |
| URL      | <https://docs.qmk.fm/one_shot_keys> |

```
[ 8bit ][ 8bit ]
01010010100      <--       11bit
           ^^^^^ <-- Layer 5bit
```

## QK\_ONE\_SHOT\_MOD (0x52A0-0x52BF)

| 項目       | 内容                                  |
| -------- | ----------------------------------- |
| 機能名      | One shot mod                        |
| キーマップマクロ | `OSM(n)`                            |
| 説明       | 次のキー押下時にこのModを送信                    |
| URL      | <https://docs.qmk.fm/one_shot_keys> |

```
[ 8bit ][ 8bit ]
01010010101      <--          11bit
           ^^^^^ <-- Modifier 5bit
```

## QK\_LAYER\_TAP\_TOGGLE (0x52C0-0x52DF)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | Layer tap toggle                     |
| キーマップマクロ | `TT(n)`                              |
| 説明       | 普段はMOのように働くが何回かtapしてるとTGになるらしい       |
| URL      | <https://docs.qmk.fm/feature_layers> |

```
[ 8bit ][ 8bit ]
01010010110      <--       11bit
           ^^^^^ <-- Layer 5bit
```

## QK\_SWAP\_HANDS (0x5600-0x56FF)

| 項目       | 内容                                        |
| -------- | ----------------------------------------- |
| 機能名      | Swap hands                                |
| キーマップマクロ | `SH_T(kc)`                                |
| 説明       | 分割キーボードの左右を一時的に切り替えるSwap関連のキーコード          |
| URL      | <https://docs.qmk.fm/features/swap_hands> |

```
[ 8bit ][ 8bit ]
01010110         <--          8bit
        ^^^^^^^^ <-- Keycode  8bit
```

## QK\_TAP\_DANCE (0x5700-0x57FF)

| 項目       | 内容                                       |
| -------- | ---------------------------------------- |
| 機能名      | Tap dance                                |
| キーマップマクロ |                                          |
| 説明       | キーを何回押したかで動作を変えれる                        |
| URL      | <https://docs.qmk.fm/features/tap_dance> |

```
[ 8bit ][ 8bit ]
01010111         <--                8bit
        ^^^^^^^^ <-- tap dance id?  8bit
```

## QK\_MAGIC (0x7000-0x70FF)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | Magic Key                            |
| キーマップマクロ |                                      |
| 説明       |                                      |
| URL      | <https://docs.qmk.fm/keycodes_magic> |

```
[ 8bit ][ 8bit ]
01110000         <--       8bit
        ^^^^^^^^ <-- data  8bit
```

## QK\_MIDI (0x7100-0x71FF)

| 項目       | 内容                                  |
| -------- | ----------------------------------- |
| 機能名      | MIDI                                |
| キーマップマクロ | `QK_MIDI_`                          |
| 説明       | MIDIキー。詳細は省略。                       |
| URL      | <https://docs.qmk.fm/features/midi> |

```
[ 8bit ][ 8bit ]
01110001         <--          8bit
        ^^^^^^^^ <-- Midi key 8bit
```

## QK\_SEQUENCER (0x7200-0x73FF)

| 項目       | 内容                                       |
| -------- | ---------------------------------------- |
| 機能名      | Sequencer                                |
| キーマップマクロ |                                          |
| 説明       | Midiに関係した何からしい                           |
| URL      | <https://docs.qmk.fm/features/sequencer> |

```
[ 8bit ][ 8bit ]
0111001          <--       7bit
       ^^^^^^^^^ <-- data  9bit
```

## QK\_JOYSTICK (0x7400-0x743F)

| 項目       | 内容                                      |
| -------- | --------------------------------------- |
| 機能名      | Joystick                                |
| キーマップマクロ | `QK_JOYSTICK_`                          |
| 説明       | ジョイスティック。                               |
| URL      | <https://docs.qmk.fm/features/joystick> |

```
[ 8bit ][ 8bit ]
0111010000       <--       10bit
          ^^^^^^ <-- data  6bit
```

## QK\_PROGRAMMABLE\_BUTTON (0x7440-0x747F)

| 項目       | 内容                                                 |
| -------- | -------------------------------------------------- |
| 機能名      | Programmable button                                |
| キーマップマクロ | `QK_PROGRAMMABLE_BUTTON`                           |
| 説明       | ソースコードの関数を呼び出せるみたいな感じ?                             |
| URL      | <https://docs.qmk.fm/features/programmable_button> |

```
[ 8bit ][ 8bit ]
0111010001       <--           10bit
          ^^^^^^ <-- button id 6bit
```

## QK\_AUDIO (0x7480-0x74BF)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | Audio                                |
| キーマップマクロ | `QK_AUDIO`                           |
| 説明       | 音が出る                                 |
| URL      | <https://docs.qmk.fm/features/audio> |

```
[ 8bit ][ 8bit ]
0111010010       <--       10bit
          ^^^^^^ <-- data  6bit
```

## QK\_STENO (0x74CO-0x74FF)

| 項目       | 内容                                         |
| -------- | ------------------------------------------ |
| 機能名      | Stenography                                |
| キーマップマクロ |                                            |
| 説明       | ステノタイプ。という単語を今初めて知った。速記で使われてるらしい？          |
| URL      | <https://docs.qmk.fm/features/stenography> |

```
[ 8bit ][ 8bit ]
0111010011       <--       10bit
          ^^^^^^ <-- data  6bit
```

## QK\_MACRO (0x7700-0x777F)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | Macros                               |
| キーマップマクロ |                                      |
| 説明       | マクロ。                                 |
| URL      | <https://docs.qmk.fm/feature_macros> |

```
[ 8bit ][ 8bit ]
011101001        <--            9bit
         ^^^^^^^ <-- macro id?  7bit
```

## QK\_LIGHTING (0x7800-0x78FF)

| 項目       | 内容                                                        |
| -------- | --------------------------------------------------------- |
| 機能名      | Lighting                                                  |
| キーマップマクロ |                                                           |
| 説明       | ライティング制御。RGB LightingとRGB Matrixなどライティング関係のものは全てこの中にあります。 |
| URL      | <https://docs.qmk.fm/features/backlight>                  |

```
[ 8bit ][ 8bit ]
01111000         <--       8bit
        ^^^^^^^^ <-- data  8bit
```

## QK\_QUANTUM (0x7C00-0x7DFF)

| 項目       | 内容                                     |
| -------- | -------------------------------------- |
| 機能名      | N/A                                    |
| キーマップマクロ | N/A                                    |
| 説明       | その他特殊なキーが割り当てられています。キー一覧を折り畳んで置いておきます。 |
| URL      |                                        |

:::details キー一覧

```c
QK_BOOTLOADER = 0x7C00,
QK_REBOOT = 0x7C01,
QK_DEBUG_TOGGLE = 0x7C02,
QK_CLEAR_EEPROM = 0x7C03,
QK_MAKE = 0x7C04,
QK_AUTO_SHIFT_DOWN = 0x7C10,
QK_AUTO_SHIFT_UP = 0x7C11,
QK_AUTO_SHIFT_REPORT = 0x7C12,
QK_AUTO_SHIFT_ON = 0x7C13,
QK_AUTO_SHIFT_OFF = 0x7C14,
QK_AUTO_SHIFT_TOGGLE = 0x7C15,
QK_GRAVE_ESCAPE = 0x7C16,
QK_VELOCIKEY_TOGGLE = 0x7C17,
QK_SPACE_CADET_LEFT_CTRL_PARENTHESIS_OPEN = 0x7C18,
QK_SPACE_CADET_RIGHT_CTRL_PARENTHESIS_CLOSE = 0x7C19,
QK_SPACE_CADET_LEFT_SHIFT_PARENTHESIS_OPEN = 0x7C1A,
QK_SPACE_CADET_RIGHT_SHIFT_PARENTHESIS_CLOSE = 0x7C1B,
QK_SPACE_CADET_LEFT_ALT_PARENTHESIS_OPEN = 0x7C1C,
QK_SPACE_CADET_RIGHT_ALT_PARENTHESIS_CLOSE = 0x7C1D,
QK_SPACE_CADET_RIGHT_SHIFT_ENTER = 0x7C1E,
QK_OUTPUT_AUTO = 0x7C20,
QK_OUTPUT_USB = 0x7C21,
QK_OUTPUT_BLUETOOTH = 0x7C22,
QK_UNICODE_MODE_NEXT = 0x7C30,
QK_UNICODE_MODE_PREVIOUS = 0x7C31,
QK_UNICODE_MODE_MACOS = 0x7C32,
QK_UNICODE_MODE_LINUX = 0x7C33,
QK_UNICODE_MODE_WINDOWS = 0x7C34,
QK_UNICODE_MODE_BSD = 0x7C35,
QK_UNICODE_MODE_WINCOMPOSE = 0x7C36,
QK_UNICODE_MODE_EMACS = 0x7C37,
QK_HAPTIC_ON = 0x7C40,
QK_HAPTIC_OFF = 0x7C41,
QK_HAPTIC_TOGGLE = 0x7C42,
QK_HAPTIC_RESET = 0x7C43,
QK_HAPTIC_FEEDBACK_TOGGLE = 0x7C44,
QK_HAPTIC_BUZZ_TOGGLE = 0x7C45,
QK_HAPTIC_MODE_NEXT = 0x7C46,
QK_HAPTIC_MODE_PREVIOUS = 0x7C47,
QK_HAPTIC_CONTINUOUS_TOGGLE = 0x7C48,
QK_HAPTIC_CONTINUOUS_UP = 0x7C49,
QK_HAPTIC_CONTINUOUS_DOWN = 0x7C4A,
QK_HAPTIC_DWELL_UP = 0x7C4B,
QK_HAPTIC_DWELL_DOWN = 0x7C4C,
QK_COMBO_ON = 0x7C50,
QK_COMBO_OFF = 0x7C51,
QK_COMBO_TOGGLE = 0x7C52,
QK_DYNAMIC_MACRO_RECORD_START_1 = 0x7C53,
QK_DYNAMIC_MACRO_RECORD_START_2 = 0x7C54,
QK_DYNAMIC_MACRO_RECORD_STOP = 0x7C55,
QK_DYNAMIC_MACRO_PLAY_1 = 0x7C56,
QK_DYNAMIC_MACRO_PLAY_2 = 0x7C57,
QK_LEADER = 0x7C58,
QK_LOCK = 0x7C59,
QK_ONE_SHOT_ON = 0x7C5A,
QK_ONE_SHOT_OFF = 0x7C5B,
QK_ONE_SHOT_TOGGLE = 0x7C5C,
QK_KEY_OVERRIDE_TOGGLE = 0x7C5D,
QK_KEY_OVERRIDE_ON = 0x7C5E,
QK_KEY_OVERRIDE_OFF = 0x7C5F,
QK_SECURE_LOCK = 0x7C60,
QK_SECURE_UNLOCK = 0x7C61,
QK_SECURE_TOGGLE = 0x7C62,
QK_SECURE_REQUEST = 0x7C63,
QK_DYNAMIC_TAPPING_TERM_PRINT = 0x7C70,
QK_DYNAMIC_TAPPING_TERM_UP = 0x7C71,
QK_DYNAMIC_TAPPING_TERM_DOWN = 0x7C72,
QK_CAPS_WORD_TOGGLE = 0x7C73,
QK_AUTOCORRECT_ON = 0x7C74,
QK_AUTOCORRECT_OFF = 0x7C75,
QK_AUTOCORRECT_TOGGLE = 0x7C76,
QK_TRI_LAYER_LOWER = 0x7C77,
QK_TRI_LAYER_UPPER = 0x7C78,
QK_REPEAT_KEY = 0x7C79,
QK_ALT_REPEAT_KEY = 0x7C7A,
```

:::

```
[ 8bit ][ 8bit ]
0111110          <--       7bit
       ^^^^^^^^^ <-- data  9bit
```

## QK\_KB (0x7E00-0x7E3F)

| 項目       | 内容                               |
| -------- | -------------------------------- |
| 機能名      | Keyboard keycode                 |
| キーマップマクロ | `QK_KB_`                         |
| 説明       | QMKのキーボード層でカスタムキーコードを定義するための予約領域 |
| URL      |                                  |

```
[ 8bit ][ 8bit ]
0111111000       <--       10bit
          ^^^^^^ <-- data  6bit
```

## QK\_USER (0x7E40-0x7FFF)

| 項目       | 内容                                   |
| -------- | ------------------------------------ |
| 機能名      | User keycode                         |
| キーマップマクロ | `QK_USER_`                           |
| 説明       | QMKのユーザー層でカスタムキーコードを定義するための予約領域      |
| URL      | <https://docs.qmk.fm/feature_layers> |

```
- 0x7E40-0x7E7F
[ 8bit ][ 8bit ]
0111111001       <--       10bit
          ^^^^^^ <-- data  6bit

- 0x7E80-0x7EFF
[ 8bit ][ 8bit ]
011111101        <--       9bit
         ^^^^^^^ <-- data  7bit

- 0x7F00-0x7FFF
[ 8bit ][ 8bit ]
01111111         <--       8bit
        ^^^^^^^^ <-- data  8bit
```

# Keycode

Keycodeという単語が意味するものは結構曖昧ですが、今から説明するKeycodeはQMK上で`KC_`から始まるもののことを指します。

Keycodeは`0x00`から`0xFF`までの8ビットで表され、「普通のキー」を指します。それぞれに割り当てられている番号はHIDと大体同じですが

@[card](https://docs.qmk.fm/keycodes_basic)

にあるように、HIDのキーボードレポートではサポートされていないマウスやメディアキーも入っているなどの違いがあります。
また、`0x0000`はNO、`0x0001`はTRANSPARENTを表します。

# Modifier

Modifierの5ビットは次のように表されています。

```c
/** \brief 5-bit packed modifiers
 *
 * Mod bits:    43210
 *   bit 0      ||||+- Control
 *   bit 1      |||+-- Shift
 *   bit 2      ||+--- Alt
 *   bit 3      |+---- Gui
 *   bit 4      +----- LR flag(Left:0, Right:1)
 */
enum mods_5bit {
    MOD_LCTL = 0x01,
    MOD_LSFT = 0x02,
    MOD_LALT = 0x04,
    MOD_LGUI = 0x08,
    MOD_RCTL = 0x11,
    MOD_RSFT = 0x12,
    MOD_RALT = 0x14,
    MOD_RGUI = 0x18,
};
```

([modifiers.h](https://github.com/qmk/qmk_firmware/blob/75402109e9a3d0d0ec129bb7132aae1367c8bf9d/quantum/modifiers.h#L16)より引用)

HIDとは違うデータ構造になっており、HIDでは8ビット必要だったのが5ビットに圧縮されています。


> この記事は[個人ブログ](https://nazo6.dev/blog/article/qmk-key-id-list)とクロスポストしています。