# 3d-model-share

GitHub Pages で glb を公開する自分用ビューワー。

- モデルは models/ に置く(小文字・スペースなし)
- 共有 URL: https://<user>.github.io/<repo>/?model=<file>.glb&title=<名前>
- 一覧ページ: https://<user>.github.io/<repo>/gallery.html

## 新しいモデルを公開する(自動)

PowerShellで以下を実行するだけで、コピー・manifest更新・commit・push・URL表示まで自動化される。

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
- 実行後、共有URLと一覧ページURLがターミナルに表示される
