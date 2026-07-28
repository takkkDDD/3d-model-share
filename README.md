# 3d-model-share

GitHub Pages で glb を公開する自分用ビューワー。

- モデルは models/ に置く(小文字・スペースなし)
- 共有 URL: https://<user>.github.io/<repo>/?model=<file>.glb&title=<名前>
- 一覧ページ: https://<user>.github.io/<repo>/gallery.html

## 新しいモデルを公開する(かんたん版: publish.bat)

`publish.bat` をダブルクリックすると対話形式で公開できる。

- ダブルクリックで起動 → glbファイルのフルパスを聞かれるので入力 → 表示名を入力(空欄可)
- または `publish.bat` のショートカットや本体アイコンに **glbファイルをドラッグ&ドロップ** すると、パス入力が省略され表示名だけ聞かれる
- 完了すると共有URL・一覧ページURLがウィンドウに表示される(Enterで閉じる)

## 新しいモデルを公開する(PowerShellから直接)

```powershell
cd J:\3d-model-share
.\publish.ps1 -GlbPath "C:\path\to\model.glb" -Title "表示名"
```

ファイル名を指定したい場合:

```powershell
.\publish.ps1 -GlbPath "C:\path\to\model.glb" -Title "表示名" -FileName "custom_name.glb"
```

- 100MB超はエラーで停止(圧縮が必要、仕様書 8章参照)
- 50MB超は警告のみ(圧縮を検討)
- ファイル名は自動で小文字化・スペースをアンダースコアに変換
- 実行後、共有URLと一覧ページURLが表示される

## モデルを削除する(かんたん版: unpublish.bat)

`unpublish.bat` をダブルクリックすると、公開中のモデル一覧が番号付きで表示される。削除したい番号(またはファイル名)を入力 → 確認で `y` と入力すると、models/からの削除・manifest.json更新・commit・pushまで自動で行われる。

## モデルを削除する(PowerShellから直接)

```powershell
cd J:\3d-model-share
.\unpublish.ps1                             # 一覧から選んで削除
.\unpublish.ps1 -FileName "labelforum26study_vera.glb"   # 直接指定
```

- gallery.html/manifest.jsonからも自動的に除外される
- 反映まで1〜2分かかる
