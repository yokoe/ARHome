# AR Home

Sota Yokoe / May. 2019

ARKit + SceneKit + SpriteKit + Nature Remo API で家電を操作するデモアプリです。

## 動作のための設定
### ビルド環境設定

CoocaPodsで必要なライブラリをインストールしてください。

```
pod install
```

### マーカーの画像

適当なマーカー画像を`Assets.xcassets`の`AR Resources`に登録してください。画像名が後述の家電リストの家電のKeyになります。物理サイズの設定もお忘れなく。

### Nature Remo設定
#### Nature Remo API Access Tokenの設定

Nature Remo APIのアクセストークンを`ViewController.swift`の`accessToken`にセットします。

```
let accessToken = ""
```

Nature Remo APIのアクセストークンの取得については[こちら](https://developer.nature.global)を参照してください。

#### 家電リストの設定
TBD

## 著作権表示
* エフェクトで使用しているテクスチャは[52 Complex Hi-Tech Sci-Fi Circle Brushes](https://www.deviantart.com/xresch/art/52-Complex-Hi-Tech-Sci-Fi-Circle-Brushes-701905546)を使って生成しています。
* UIには[Michromaフォント](https://fonts.google.com/specimen/Michroma)を使用しています。
* Nature RemoのAPI呼び出しで[Alamofire](https://github.com/Alamofire/Alamofire)を利用しています。
