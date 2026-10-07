# iPad Redesigned 調整與驗證

適用 Spotify 9.1.78、iPadOS 26、Appearance → Redesigned。Native 外觀不使用這些版面調整。

## 播放頁策略

- iPad 寬視窗保留 Spotify 原生分割播放頁，停用並淡出 `expand_collapse_button`；原生向下箭頭仍可操作。初始模式固定為 `Collapsed`。
- iPad 高視窗在 UIWindow 套用 Compact horizontal size class，讓 Spotify 使用既有窄視窗排版與轉場。視窗變寬時移除 override，恢復系統環境；沒有偽造 UIDevice 型號。
- 移除直／橫向初始全螢幕設定、自製橫向播放器、額外收合箭頭／手勢、直向 split 控制群位移。旧設定不再讀取。
- Mod Settings → Navbar → Labels：Show、Hide、Auto。Auto 根據實際玻璃 bar 寬高與文字大小隱藏／還原標籤；上下排圖示與文字時，額外保留 8pt 間距及上下留白。窄視窗擠壓時自動隱藏，不再只量 Spotify 外層面板寬度。

播放頁的呈現、控制與收合由 Spotify 負責。這次不再維護一套額外的播放器控制服務或猜測收合控制器。

## 本次變更

- 手機與 iPad 的 ⋯ 直接使用 Spotify 原生選單；移除 Redesigned 接管及對應 harness，保留 Shared 的 Speed and pitch 列。
- 橫向 split 的放大入口停用，保留原生 minimize 按鈕的玻璃底與動作。
- 歌詞封面遮罩、標題與進度列定位限定於目前播放面板；歌詞關閉後還原原生內容。
- iPad footer 保留原生面板內的位置。
- 手機與 iPad 首頁共用緊湊的浮動玻璃標題工具列，帳號按鈕保留原生動作。首頁內容仍由 Spotify 的音樂 shelves 提供，尚未完整重做 Apple Music 的推薦大卡與頂端分頁。
- 首頁 feed 額外保留 16pt 頂部間距，避免第一排卡片緊貼浮動工具列；旋轉、切換分割與重新進入首頁不會累加間距。
- iPad 浮動 navbar 不建立插件的全寬黑色漸層，並將 Spotify 的 `TabBarGradientView` 保持 alpha 0；依實際 iPad 裝置判斷，不受 Compact 排版影響。
- 減少首頁標題搜尋與封面 observer 重裝；導覽列文字寬度只在名稱／字型改變時重算。
- 已按讚歌曲使用單次繪製的藍紫漸層白色愛心封面，供既有 full-bleed hero 與背景色場讀取；它不是從一般 playlist UIImageView 載入的封面。
- 停用自動更新、贊助與證書推銷提示，以及對應推銷列；手動 Updates 頁保留。

## 歌詞

保留既有內嵌歌詞與 48pt 小封面。閒置時淡出操作群，保留歌名與小封面；第一個觸控會還原控制群。沒有額外橫向控制面板或進度更新計時器。

## Binary 依據

以使用者提供的已解密 IPA 查核，main binary UUID：`c712370b-44cd-35c8-a058-4fbed1ad0758`，cryptid 為 0。切換按鈕 identifier `expand_collapse_button` 的字串位址是 `0x10a45cbc0`，引用包括 `0x1014fb32c`、`0x105bbff38`、`0x1079f02d8`。

初始模式 flag 是 `ios-adaptivelayout-experimentationmanager.now_playing_view_initial_mode`，enum 值為 `Expanded`／`Collapsed`，預設 `Collapsed`。properties initializer `0x1055a1944` 讀取它；字串 switch table `0x10d11f218`／`0x10d11f228` 對應 Expanded=0／Collapsed=1。現在僅由 flag registry 強制 Collapsed，不再修改 Swift byte ivar。

`SPTBarOverlayPresentationTransition` 在 `0x109814d64`、`0x1098153c4` 讀取 `horizontalSizeClass`，Regular 與 Compact 走不同幾何／轉場分支。`NowPlayingOverlayContainer.expand` 的 ObjC 入口 `0x1012ebce8` 是 `v16@0:8`；橫向 iPad 阻止此入口，並關閉原生放大按鈕的觸控與輔助使用入口。Compact traits 是否同時覆蓋 Spotify 目前所有 adaptive layout 路徑，仍需實機確認。

尚未找到一個能可靠停用整個 tablet／side attachment 排版的 flag。沒有修改 `sideAttachment` 或偽造 `isActive`；binary 顯示 `sideAttachment` 是必要容器值，直接返回 nil 會進入 trap。

手機原 IPA 的 `UISupportedInterfaceOrientations` 只有 Portrait；目前已回退新增的 landscape 宣告與 AppDelegate／navigation／player 的方向 hooks。iPad 保留原有方向支援。

## Build 與實機檢查

Windows 本機檢查 Logos 預處理、來源分層、plist 與 shell 語法；iOS 編譯交由下方 macOS Actions 完成。成功建置仍不代表完成實機互動與視覺驗證。

將 `continue` 分支推到 GitHub，再執行 Actions → **Build IPA from your own Spotify IPA**，選擇 `continue`，`ipa_url` 使用可直接下載的已解密 Spotify 9.1.78 IPA 網址，`upload_method` 選 artifacts。Actions 無法讀取電腦上的 `C:\...` 路徑；完成後下載 `spoti.ipa` artifact 並使用原本流程簽名安裝。

安裝後重啟 Spotify，在 Redesigned／iPadOS 26 檢查：

1. 橫、直向與窄多工視窗中，快速點 ⋯、關閉、再開啟；播放頁應持續可操作。
2. 寬視窗開播放頁應保持 Split，沒有放大入口，原生向下箭頭應收起播放頁。
3. 高視窗應改為窄版／手機式播放頁，檢查原生箭頭與下滑收合；播放頁開啟時反覆轉向與調整視窗，也檢查收合後再開啟。歌詞、Connect、queue 應顯示並可點。
4. Navbar 選 Auto，調整視窗寬度，標籤應在空間不足時消失，變寬後恢復。
5. 首頁工具列不應遮住帳號按鈕；開啟已按讚歌曲應看到漸層愛心封面與帶色背景。
6. 手機首頁頂部應是玻璃膠囊，帳號按鈕可點；第一排內容保留工具列下方間距。
7. 手機更多選單只應顯示原生 sheet，不再出現額外的上方 popover；快速關閉並重開，確認播放頁仍可操作。手機轉橫向應維持 Spotify 原本的直向政策。
