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

`Appliances.plist`の中に家電の設定を記述できます。

```
<array>
	<dict>
		<key>BoundingBox</key>
		<dict>
			<key>Position</key>
			<dict>
				<key>x</key>
				<integer>0</integer>
				<key>y</key>
				<real>-0.4</real>
				<key>z</key>
				<real>0.25</real>
			</dict>
			<key>Scale</key>
			<dict>
				<key>x</key>
				<real>0.8</real>
				<key>y</key>
				<real>0.54</real>
				<key>z</key>
				<real>0.1</real>
			</dict>
		</dict>
		<key>Key</key>
		<string>Ceiling light</string>
		<key>MenuItems</key>
		<array>
			<dict>
				<key>Action</key>
				<dict>
					<key>Type</key>
					<string>Signal</string>
					<key>SignalID</key>
					<string>00000000-0000-0000-0000-000000000000</string>
				</dict>
				<key>Caption</key>
				<string>OFF</string>
			</dict>
		</array>
	</dict>
</array>
```

* `Key`はマーカー画像のNameを指定してください。
* `MenuItems`にその家電のマーカーをタップした時に表示されるメニューの設定を記述します。
* `Signal`タイプのメニュー項目の場合、`SignalID`にNature Remoに送信するSignalのIDを設定してください。
* `BoundingBox`には、物体の上にオーバーレイするボックスの位置(マーカーの中央からの相対位置 / 単位m)と大きさを指定できますが、動作に支障はないので面倒であれば設定しなくてOKです。

## 著作権表示
* エフェクトで使用しているテクスチャは[52 Complex Hi-Tech Sci-Fi Circle Brushes](https://www.deviantart.com/xresch/art/52-Complex-Hi-Tech-Sci-Fi-Circle-Brushes-701905546)を使って生成しています。
* UIには[Michromaフォント](https://fonts.google.com/specimen/Michroma)を使用しています。
* Nature RemoのAPI呼び出しで[Alamofire](https://github.com/Alamofire/Alamofire)を利用しています。
