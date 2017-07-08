# Submarine
From The Depthsにおける潜水艦用スクリプト

## できること
- 指定高度（深度）を維持する。
- エアポンプとハイドロフォイルで高度制御する。
- 進行方向の地形を先読みしてピッチを調整する。
- [ぐるぐるレーダーブイ](https://github.com/tvagames/AroundRadarBuoy)機能搭載（オプション）

## できないこと
- ヘリブレードによる高度制御。
- ロール制御。
- ヨー制御。
- 推力制御。

## 必要なもの
- LUA Box
- AI Mainframe
- Naval AI 
- Air Pump
- Hydrofoil
- Air Pump 稼働で浮上し、Air Pump 停止で沈む程度に浮力と重量のつり合いが取れた船体が望ましい

## 使い方
船体を用意する。
![設置](https://github.com/tvagames/Submarine/blob/image/20170708210212_1.jpg?raw=true "設置")

必要なものを設置する。
![設置](https://github.com/tvagames/Submarine/blob/image/20170708210202_1.jpg?raw=true "設置")


LUA Box をQキーで開いて、[ソースコード（Submarine.lua）](https://github.com/tvagames/Submarine/blob/master/Submarine.lua)で上書きし、F8キーで適用する。
![貼り付け](https://github.com/tvagames/Submarine/blob/image/20170708211640_1.jpg?raw=true "貼り付け")

以上で完了。

![完成](https://github.com/tvagames/Submarine/blob/image/20170708211227_1.jpg?raw=true "完成")


## 注意
横幅が広い船体は地形によっては端をこするかもしれない。

以上
