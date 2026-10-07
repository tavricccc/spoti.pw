# iPad Redesigned 調整與驗證

適用 Spotify 9.1.78、iPadOS 26、Appearance → Redesigned。Native 外觀不使用這些版面調整。

## 設定

- Mod Settings → Player → iPad player：`Full screen in portrait`、`Full screen in landscape` 分開控制直向與橫向首次開啟播放頁時是否使用 Expanded。預設皆關閉；修改後重啟 Spotify。方向依目前視窗尺寸判斷；播放頁已開啟時轉向，請收合並重新開啟，套用新方向的初始設定。這不是關閉整個 tablet 排版的開關。
- Mod Settings → Navbar → Labels：Show、Hide、Auto。Auto 根據目前導覽列所在面板的寬度與文字大小隱藏／還原標籤，立即生效。原 Hide labels 設定會遷移到新選項。

手機與 iPad 全螢幕播放頁向下滑使用共用收合入口；目前是放開手指後收合，不是跟隨手指的互動轉場。原生 minimize 按鈕不存在時，改呼叫呈現它的 side attachment 或 UIKit modal；原生 expanded overlay 則可使用自身的 expand／condense 動作收回分割面板。畫面會保留可點的向下箭頭：橫向由新的播放器面板提供，直向原生缺少時補上。歌詞捲動保留原用途，開啟歌詞時從頂部下滑收合；VoiceOver 開啟時使用收合按鈕。

## 本次變更

- iPad 的 ⋯ 使用 popover 時也會呈現 Redesigned 選單；收合與重新開啟會清理 takeover 狀態。
- split／全螢幕切換按鈕套用玻璃底；沒有強制全螢幕時保留原生按鈕透明度與可用狀態。
- 歌詞封面遮罩、標題與進度列定位限定於目前播放面板；歌詞關閉後還原原生內容。
- iPad footer 不套用手機向畫面外延伸的位移；直向分割模式將底部控制群配置到播放面板下方，補上位移後的觸控範圍。
- iPad 首頁改為緊湊的浮動玻璃標題工具列，帳號按鈕保留原生動作。首頁內容仍由 Spotify 的音樂 shelves 提供，尚未完整重做 Apple Music 的推薦大卡與頂端分頁。
- 首頁 feed 額外保留 16pt 頂部間距，避免第一排卡片緊貼浮動工具列；旋轉、切換分割與重新進入首頁不會累加間距。
- iPad 浮動 navbar 不再繪製手機用的全寬黑色漸層，玻璃膠囊外的封面與文字保持原色。
- 減少首頁標題搜尋與封面 observer 重裝；導覽列文字寬度只在名稱／字型改變時重算。
- 已按讚歌曲使用單次繪製的藍紫漸層白色愛心封面，供既有 full-bleed hero 與背景色場讀取；它不是從一般 playlist UIImageView 載入的封面。
- 停用自動更新、贊助與證書推銷提示，以及對應推銷列；手動 Updates 頁保留。

## 橫向播放器與歌詞

Redesigned 的手機與 iPad 全螢幕橫向播放器使用相同版型：沒有開歌詞時，封面、歌名、進度、播放控制及音量置中；開歌詞時改為左側封面／控制欄、右側歌詞。矮的手機視窗會縮小封面，五個播放按鈕仍各有至少 44pt 的觸控範圍。裝置、歌詞、佇列放在畫面底部。

橫向歌詞不啟動閒置隱藏控制項的計時器。直向歌詞閒置時，只淡出操作按鈕與進度／播放／音量群，保留歌名與 48pt 小封面；歌名與作者也縮小。第一個觸控會還原控制群。

橫向欄位是 Redesigned 自己的 views，原生 units 留在原位並暫時遮罩，回直向會還原遮罩與可操作狀態。播放／跳曲／shuffle／repeat／seek 使用既有 Spotify 播放服務；更多、收藏、裝置、佇列與收合仍呼叫原生控制。只有畫面顯示且 app 前景時，每 0.5 秒更新進度，沒有增加 display link。

## Binary 依據

以使用者提供的已解密 IPA 查核，main binary UUID：`c712370b-44cd-35c8-a058-4fbed1ad0758`，cryptid 為 0。切換按鈕 identifier `expand_collapse_button` 的字串位址是 `0x10a45cbc0`，引用包括 `0x1014fb32c`、`0x105bbff38`、`0x1079f02d8`。

初始模式 flag 是 `ios-adaptivelayout-experimentationmanager.now_playing_view_initial_mode`，enum 值為 `Expanded`／`Collapsed`，預設 `Collapsed`。properties initializer `0x1055a1944` 讀取它；字串 switch table `0x10d11f218`／`0x10d11f228` 對應 Expanded=0／Collapsed=1；Swift getter `0x10636cf90` 直接讀取 properties 的 `nowPlayingViewInitialMode` byte ivar。這版依視窗方向更新這個已確認欄位（用 runtime ivar offset，限定 9.1.78），取代先前無效的自動點擊切換按鈕。兩個方向都啟用時，同時透過現有 flag registry 強制 Expanded。

尚未找到一個能可靠停用整個 tablet／side attachment 排版的 flag。沒有修改 `sideAttachment` 或偽造 `isActive`；binary 顯示 `sideAttachment` 是必要容器值，直接返回 nil 會進入 trap。

手機原 IPA 的 `UISupportedInterfaceOrientations` 只有 Portrait；現在加入兩個 landscape 方向，並在 Redesigned 下擴充 AppDelegate（`0x106ccb640`）、SPNavigationController（`0x1010921a4`）及播放頁的方向限制。旋轉仍遵守系統的直向鎖定。

## Build 與實機檢查

Windows 本機檢查 Logos 預處理、來源分層、plist 與 shell 語法；iOS 編譯交由下方 macOS Actions 完成。成功建置仍不代表完成實機互動與視覺驗證。

將 `continue` 分支推到 GitHub，再執行 Actions → **Build IPA from your own Spotify IPA**，選擇 `continue`，`ipa_url` 使用可直接下載的已解密 Spotify 9.1.78 IPA 網址，`upload_method` 選 artifacts。Actions 無法讀取電腦上的 `C:\...` 路徑；完成後下載 `spoti.ipa` artifact 並使用原本流程簽名安裝。

安裝後重啟 Spotify，在 Redesigned／iPadOS 26 檢查：

1. 橫、直向與窄多工視窗中，快速點 ⋯、關閉、再開啟；播放頁應持續可操作。
2. 全螢幕播放頁下滑應收合；兩個方向的 full screen 設定應各自生效，轉向後也可操作。
3. 直向分割播放頁的控制群應移到下方；歌詞、Connect、queue 應顯示並可點。切換歌詞與封面時不應露出原生封面／重疊 context 標題。
4. Navbar 選 Auto，調整視窗寬度，標籤應在空間不足時消失，變寬後恢復。
5. 首頁工具列不應遮住帳號按鈕；開啟已按讚歌曲應看到漸層愛心封面與帶色背景。
6. 手機關閉系統直向鎖定，開啟播放器後轉橫向；封面／控制群應置中，開歌詞後改成左右兩欄，等待超過四秒仍保留控制群。回直向後等待四秒，應保留縮小的歌名與小封面，淡出其他操作控制。
7. 在橫向版型操作播放、跳曲、seek、shuffle、repeat、音量、收藏、更多、裝置、佇列，再切回直向；確認音訊狀態與原生控制一致，沒有不可見的觸控區擋住歌詞。
