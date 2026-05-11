# TenShot

スクリーンショットを最大10枚までストックできる macOS メニューバーアプリ。

## 特徴

- メニューバーから即起動するパレット型 UI
- 範囲選択スクリーンショット（ScreenCaptureKit）
- 最大10枚まで保管（11枚目で最古を自動削除する FIFO）
- ワンクリックでクリップボードへコピー
- 他アプリへのドラッグ＆ドロップ対応
- 透過スライダーでパレット不透明度を調整
- ダーク基調のグラスモーフィズム UI

## 動作環境

- macOS 14（Sonoma）以降
- Xcode 15 以降（ビルドする場合）

## App Store

App Store で無料配布中。インストールだけしたい人はこちら：
👉 (App Store リンク準備中)

## 自分でビルド・改造したい人へ

このリポジトリはオープンソースです。Fork して自由にチューニングしてください。
PR や Issue は歓迎しますが、対応をお約束するものではありません。

### ビルド手順

1. このリポジトリを Fork（または clone）

   ```sh
   git clone https://github.com/<あなたのアカウント>/TenShot.git
   cd TenShot
   ```

2. Xcode で `TenShot.xcodeproj` を開く

3. **自分の Apple Developer Team ID を設定する**（必須）

   `TenShot.xcodeproj/project.pbxproj` 内の以下2箇所（Debug / Release）を編集：

   ```
   DEVELOPMENT_TEAM = "";
   ```

   ↓

   ```
   DEVELOPMENT_TEAM = "あなたの10桁のTeam ID";
   ```

   または Xcode の「Signing & Capabilities」タブから自分のチームを選択。

4. Bundle Identifier を変更（推奨）

   `PRODUCT_BUNDLE_IDENTIFIER` の `com.suzukimasayasu.TenShot` を自分のものに変更してください。

5. ビルド・実行

   Xcode で ⌘R。初回起動時に macOS の「画面収録」権限ダイアログが出るので許可してください。

## ライセンス

[MIT](./LICENSE)

## 開発者

鈴木元康（Masayasu Suzuki）

設計思想・ケーススタディはこちら：
👉 https://github.com/masayasusuzuki/engineering-notes/tree/main/case-studies/tenshot
