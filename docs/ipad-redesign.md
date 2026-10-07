# iPad Redesigned 調整與驗證

適用 Spotify 9.1.78、iPadOS 26、Appearance → Redesigned。Native 外觀不使用這些版面調整。

## 設定

- Mod Settings → Player → iPad player：`Full screen in portrait`、`Full screen in landscape` 分開控制直向與橫向是否自動展開播放頁。預設皆關閉；修改後重啟 Spotify。方向依目前視窗尺寸判斷，因此也適用 iPad 多工視窗。
- Mod Settings → Navbar → Labels：Show、Hide、Auto。Auto 根據目前導覽列所在面板的寬度與文字大小隱藏／還原標籤，立即生效。原 Hide labels 設定會遷移到新選項。

全螢幕播放頁向下滑會觸發 Spotify 原生收合按鈕；目前是放開手指後收合，不是跟隨手指的互動轉場。歌詞捲動保留原用途，開啟歌詞時從頂部下滑收合；VoiceOver 開啟時使用收合按鈕。

## 本次變更

- iPad 的 ⋯ 使用 popover 時也會呈現 Redesigned 選單；收合與重新開啟會清理 takeover 狀態。
- split／全螢幕切換按鈕套用玻璃底；沒有強制全螢幕時保留原生按鈕透明度與可用狀態。
- 歌詞封面遮罩、標題與進度列定位限定於目前播放面板；歌詞關閉後還原原生內容。
- iPad footer 不套用手機向畫面外延伸的位移；直向分割模式將底部控制群配置到播放面板下方，補上位移後的觸控範圍。
- iPad 首頁改為緊湊的浮動玻璃標題工具列，帳號按鈕保留原生動作。首頁內容仍由 Spotify 的音樂 shelves 提供，尚未完整重做 Apple Music 的推薦大卡與頂端分頁。
- 減少首頁標題搜尋與封面 observer 重裝；導覽列文字寬度只在名稱／字型改變時重算。
- 已按讚歌曲使用單次繪製的藍紫漸層白色愛心封面，供既有 full-bleed hero 與背景色場讀取；它不是從一般 playlist UIImageView 載入的封面。
- 停用自動更新、贊助與證書推銷提示，以及對應推銷列；手動 Updates 頁保留。

## Binary 依據

以使用者提供的已解密 IPA 查核，main binary UUID：`c712370b-44cd-35c8-a058-4fbed1ad0758`，cryptid 為 0。切換按鈕 identifier `expand_collapse_button` 的字串位址是 `0x10a45cbc0`，引用包括 `0x1014fb32c`、`0x105bbff38`、`0x1079f02d8`。

全螢幕設定呼叫已存在按鈕的原生動作；沒有修改 `sideAttachment` 或偽造 `isActive`。binary 顯示 `sideAttachment` 為必要容器值，直接返回 nil 會進入 trap。

## Build 與實機檢查

Windows 本機已檢查 Logos 預處理、來源分層與 shell 語法；沒有 Apple SDK，尚未完成 iOS 編譯或實機驗證。

將 `continue` 分支推到 GitHub，再執行 Actions → **Build IPA from your own Spotify IPA**，選擇 `continue`，`ipa_url` 使用可直接下載的已解密 Spotify 9.1.78 IPA 網址，`upload_method` 選 artifacts。Actions 無法讀取電腦上的 `C:\...` 路徑；完成後下載 `spoti.ipa` artifact 並使用原本流程簽名安裝。

安裝後重啟 Spotify，在 Redesigned／iPadOS 26 檢查：

1. 橫、直向與窄多工視窗中，快速點 ⋯、關閉、再開啟；播放頁應持續可操作。
2. 全螢幕播放頁下滑應收合；兩個方向的 full screen 設定應各自生效，轉向後也可操作。
3. 直向分割播放頁的控制群應移到下方；歌詞、Connect、queue 應顯示並可點。切換歌詞與封面時不應露出原生封面／重疊 context 標題。
4. Navbar 選 Auto，調整視窗寬度，標籤應在空間不足時消失，變寬後恢復。
5. 首頁工具列不應遮住帳號按鈕；開啟已按讚歌曲應看到漸層愛心封面與帶色背景。
