---
published: true
type: idea
topics:
  - qmkfirmware
  - 自作キーボード
emoji: 🖮
title: QMKキーIDとアクション一覧
---


Viaのプロトコルを触る際に必要だったので[ここ](https://github.com/qmk/qmk_firmware/blob/master/quantum/keycodes.h)にあるQMKの全てのキー範囲をまとめました。
# 範囲一覧

QMKでは2バイトの値でほとんど全てのキーマップを表しています。基本となる0x00-0xFFのキー(`KC`で始まる)とどのようなキーマップかを表す上位4ビットの値で成り立っています。

以下では各キーマップの種類とそのアドレス範囲及びそのデータ構造を記しています。

## QK_BASIC (0000-000F)
基本のキーコード(`KC_`で始まるもの)。
```
[ 8bit ][ 8bit ]
00000000         <--          8bit
        ^^^^^^^^ <-- Keycode  8bit
```



## QK_MODS (0100-1FFF)
Modとキー同時押し
```
[ 8bit ][ 8bit ]
000              <--          3bit
   ^^^^^         <-- Modifier 5bit
        ^^^^^^^^ <-- Keycode  8bit
```
modifierのデコード方法は下部を参照。

## QK_MOD_TAP (0x2000-0x3FFF)

https://docs.qmk.fm/mod_tap

Tapでキー,HoldでMod
```
[ 8bit ][ 8bit ]
001              <--          3bit
   ^^^^^         <-- Modifier 5bit
        ^^^^^^^^ <-- Keycode  8bit
```

## QK_LAYER_TAP (0x4000-0x4FFF)

https://docs.qmk.fm/feature_layers

Tapでキー,HoldでLayer
```
[ 8bit ][ 8bit ]
0100             <--          4bit
    ^^^^         <-- Layer    4bit
        ^^^^^^^^ <-- Keycode  8bit
```

## QK_LAYER_MOD (0x5000-0x51FF)

https://docs.qmk.fm/feature_layers

`LM(layer, mod)`: Hold時に`MO`とmod送信を同時にやる
```
[ 8bit ][ 8bit ]
0101000          <--    
       ^^^^^^^^^ <-- 未調査
```

## QK_TO (0x5200-0x521F)
`TO(n)`: このレイヤを有効化して他のレイヤを無効にする
```
[ 8bit ][ 8bit ]
01010010000      <--          
           ^^^^^ <-- 未調査
```

## QK_MOMENTARY (0x5220-0x523F)
`MO(n)`: 押してる間だけレイヤ有効化
```
[ 8bit ][ 8bit ]
01010010001      <--          
           ^^^^^ <-- 未調査
```

## QK_DEF_LAYER (0x5240-0x525F)
`DEF(n)`: デフォルトレイヤ設定
```
[ 8bit ][ 8bit ]
01010010010      <--          
           ^^^^^ <-- 未調査
```

## QK_TOGGLE_LAYER (0x5260-0x527F)
`TG(n)`: 押下でレイヤの有効無効切り替え
```
[ 8bit ][ 8bit ]
01010010011      <--          
           ^^^^^ <-- 未調査
```

## QK_ONE_SHOT_LAYER (0x5280-0x529F)
`OSL(n)`: 次のキー押下時にこのレイヤを使用
```
[ 8bit ][ 8bit ]
01010010100      <--          
           ^^^^^ <-- 未調査
```

## QK_ONE_SHOT_MOD (0x52A0-0x52BF)

https://docs.qmk.fm/one_shot_keys

`OSM(mod)`: 次のキー押下時にこのmodifierを送信
```
[ 8bit ][ 8bit ]
01010010101      <--          
           ^^^^^ <-- MOD
```

## QK_LAYER_TAP_TOGGLE (0x52C0-0x52DF)
`TT(layer)`: 普段はMOのように働くが何回かtapしてるとTGになるらしい
```
[ 8bit ][ 8bit ]
01010010110      <--          
           ^^^^^ <-- 未調査
```

## QK_SWAP_HANDS (0x5600-0x56FF)

https://docs.qmk.fm/features/swap_hands

`SH_T(kc)` ?

```
[ 8bit ][ 8bit ]
01010110         <--          8bit
        ^^^^^^^^ <-- Keycode  8bit
```

## QK_TAP_DANCE (0x5700-0x57FF)

https://docs.qmk.fm/features/tap_dance#

```
[ 8bit ][ 8bit ]
01010111         <--                8bit
        ^^^^^^^^ <-- tap dance id?  8bit
```

## QK_MAGIC (0x7000-0x70FF)
未調査
```
[ 8bit ][ 8bit ]
01110000         <--       8bit
        ^^^^^^^^ <-- data  8bit
```

## QK_MIDI (0x7100-0x70FF)
未調査
```
[ 8bit ][ 8bit ]
01110001         <--       8bit
        ^^^^^^^^ <-- data  8bit
```

## QK_SEQUENCER (0x7200-0x73FF)
未調査
```
[ 8bit ][ 8bit ]
0111001          <--       7bit
       ^^^^^^^^^ <-- data  9bit
```

## QK_JOYSTICK (0x7400-0x743F)
未調査
```
[ 8bit ][ 8bit ]
0111010000       <--       10bit
          ^^^^^^ <-- data  6bit
```

## QK_PROGRAMMABLE_BUTTON  (0x7440-0x747F)
未調査
```
[ 8bit ][ 8bit ]
0111010001       <--       10bit
          ^^^^^^ <-- data  6bit
```

## QK_AUDIO (0x7480-0x74BF)
未調査
```
[ 8bit ][ 8bit ]
0111010010       <--       10bit
          ^^^^^^ <-- data  6bit
```

## QK_STENO (0x74CO-0x74FF)
未調査
```
[ 8bit ][ 8bit ]
0111010011       <--       10bit
          ^^^^^^ <-- data  6bit
```

## QK_MACRO (0x7700-0x777F)
```
[ 8bit ][ 8bit ]
011101001        <--            9bit
         ^^^^^^^ <-- macro id?  7bit
```

## QK_LIGHTING (0x7800-0x78FF)
未調査
```
[ 8bit ][ 8bit ]
01111000         <--       8bit
        ^^^^^^^^ <-- data  8bit
```

## QK_QUANTUM (0x7C00-0x7DFF)
未調査
```
[ 8bit ][ 8bit ]
0111110          <--       7bit
       ^^^^^^^^^ <-- data  9bit
```

## QK_KB (0x7E00-0x7E3F)
未調査
```
[ 8bit ][ 8bit ]
0111111000       <--       10bit
          ^^^^^^ <-- data  6bit
```

## QK_USER (0x7E40-0x7FFF)
ユーザーカスタム定義
```
なんだこれだけ妙な範囲だ

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
0x0000はNone,
0x0001はTransparent。
基本的にUSB HIDのキーコードと同じだが、マウスやメディアキーなどそのままでは使えないものあある。

# Modifier
[modifiers.h](https://github.com/qmk/qmk_firmware/blob/75402109e9a3d0d0ec129bb7132aae1367c8bf9d/quantum/modifiers.h#L16)より引用
```c
/** \brief 5-bit packed modifiers
 *
 * Mod bits:    43210
 *   bit 0      ||||+- Control
 *   bit 1      |||+-- Shift
 *   bit 2      ||+
 Alt
 *   bit 3      |+
- Gui
 *   bit 4      +
-- LR flag(Left:0, Right:1)
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
HIDとは違いpackedされている。これにより5ビットでModifierを表現できる。


> この記事は [https://note.nazo6.dev/blog/qmk-key-id](https://note.nazo6.dev/blog/qmk-key-id) とのクロスポストです。