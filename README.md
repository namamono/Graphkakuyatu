# Godot Graph Editor

Godot 4.x で動作する、DOT言語ライクなグラフ構造のビジュアルエディタです。
ノードの作成、移動、接続、および双方向エッジの可視化をサポートしています。

## 動作環境
*   Godot Engine 4.x

## インストール方法
1.  このリポジトリをクローンまたはダウンロードします。
2.  Godot Engine を起動し、`Import` から `project.godot` ファイルを選択してプロジェクトを読み込みます。
3.  エディタ上で `Run` (F5) を押して実行します。

---

# Graph Editor 操作マニュアル

このツールは、ノードとエッジを用いてグラフ構造を視覚的に作成・編集するためのエディタです。

## 基本操作

### ノード（丸）の操作
*   **作成**: 画面上の何もない場所を **左ダブルクリック** すると、新しいノードが作成されます。
*   **移動**: ノードを **左ドラッグ** すると移動できます。
*   **選択**: ノードを **左クリック** すると選択状態（色が変化）になります。

### エッジ（矢印）の操作
*   **接続（線を引く）**:
    1.  始点となるノードの上で **右クリック** したままドラッグを開始します。
    2.  終点となるノードの上で **右クリックを離す** と線が引かれます。
*   **削除**: 既に線が引かれているノード間でもう一度同じ操作（線を引く）を行うと、その線が削除されます。
*   **相互接続（双方向）**:
    *   AからBへ線を引いた後、BからAへも線を引くと、自動的に**一本の双方向矢印**として統合表示されます。
    *   この際、ラベルは「A→Bのラベル / B→Aのラベル」のように併記されます。
*   **選択**: 線を **左クリック** すると選択状態になります（線が太くなり色が変化します）。

### 画面操作
*   **視点移動（パン）**: 画面を **マウス中ボタン（ホイール押し込み）** でドラッグすると視点を移動できます。
*   **拡大・縮小（ズーム）**: **マウスホイール** を回転させるとズームイン・アウトが可能です。

## パネル機能（画面右側）

*   **ラベル編集**:
    1.  ノードまたはエッジを選択状態にします。
    2.  右側のパネルにあるテキストボックスに文字を入力します。
    3.  **Enterキー** を押すか、ボックスからフォーカスを外すとラベルが確定・反映されます。
*   **Layout（自動整列）**:
    *   ボタンを押すと、グラフの形状が見やすくなるようにノードが自動的に配置されます。
*   **Undo / Redo（元に戻す / やり直し）**:
    *   操作を間違えた場合でも、履歴をたどって状態を戻すことができます。
*   **Export**:
    *   現在のグラフ情報を `.dot` 形式などのファイルとして保存します（実装状況に依存）。
 
*   ## Licenses & Credits

This software uses the following open-source libraries and fonts:

### Godot Engine
This game uses Godot Engine, available under the following license:

Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

### Noto Sans JP
This software uses the Noto Sans JP font, licensed under the SIL Open Font License, Version 1.1.

Copyright 2014-2021 Adobe (http://www.adobe.com/), with Reserved Font Name 'Source'.
Copyright 2014-2021 Google Inc. All Rights Reserved.

(The full text of the license can be found in the OFL.txt file included with this distribution.)
