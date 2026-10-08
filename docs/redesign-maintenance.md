# Redesigned 維護紀錄

適用 Spotify 9.1.78、iOS／iPadOS 26、Appearance → Redesigned。

## 2026-10-08 自主改善

這輪檢查播放頁與旋轉策略、歌詞生命週期、mini player 手勢、Navbar Auto、Home 排版、搜尋分類卡，以及播放清單／專輯／藝人頁面的揭露與配色流程。以下是從原始碼確認並實作的項目；沒有把編譯成功當成實機效能或互動驗證。

| 問題 | 修正 | 可核對的範圍 |
| --- | --- | --- |
| 頁面黑幕等待封面與配色，缺少任一項可等到 1.2 秒 | 只等控制項與第一筆曲目，上限 0.35 秒；淡入縮至 0.2 秒，減少動態效果時不淡入 | 減少插件自身的等待，不代表 Spotify 網路載入時間固定 |
| Header 與 field 對同一張封面重複讀取顏色 | 串列配色 queue 共用弱 image key 的快取，區分一般／提高對比與 dissolve 版本 | 原始圖片釋放時快取也釋放；沒有新增 Liked Songs 合成封面 |
| 歌詞 display link 的 target 直接持有 view | 改用弱 ticker，view 釋放時 invalidate link | 保留 80–120 Hz 範圍與既有背景／播放頁轉場停用規則 |
| 視窗只改變高度時，歌詞焦點位置未重算 | 高度改變時重新安排目前歌詞 | 寬度變化仍走原本背景文字測量 |
| 歌詞跟隨動畫忽略減少動態效果 | 關閉跟隨 spring | 不改歌曲時間與點歌詞 seek 行為 |
| 減少透明度的「實心」玻璃仍使用 alpha 0.16／0.26 | 使用不透明深灰填色 | 只改 Redesigned 的 Kit |
| mini player 在舊滑動動畫完成時才切歌，連續操作可能留下舊回呼 | 手指放開時提交切歌，以 generation 隔離視覺回呼；收合完成重新排版 | 僅影響選用的 inline mini player |
| mini player 的播放鍵只由觸控辨認，沒有 VoiceOver 動作 | 卡片提供開啟播放器與播放／暫停、上一首、下一首動作 | 輔助使用操作仍交給原有 Spotify player commands |
| Search 每張分類卡都建立玻璃 backdrop | 移除卡片玻璃，保留原封面、標題、漸層與按壓回饋 | 減少 effect view 數量；沒有宣稱量到特定 FPS 增幅 |

玻璃只留在導覽與控制層，參考 [Apple Materials](https://developer.apple.com/design/human-interface-guidelines/materials) 與本專案 Apple HIG skill 的 `liquid-glass.md › Where the material belongs`。尺寸與動態效果處理參考 `layout.md › Adaptability`、`motion.md › Best practices`。

## 手機與 iPad 排版適配

使用實際裝置類型決定文字與工具列尺寸，使用目前內容面板的 bounds 決定可用空間。iPad 直向套用 Compact traits 仍使用 iPad 的尺寸規則；不以 size class 推斷裝置類型，也不再增加手機橫向播放器。

| 範圍 | 手機 | iPad |
| --- | --- | --- |
| Home 頂部膠囊 | 基準寬 220pt，隨原生標題及帳號內容增加 | 基準寬 260pt，依主內容面板置中 |
| Home 帳號按鈕 | 原生 row 每次排版後重算位置 | 同樣跟著原生 row 重算；膠囊限定於 row 與 header 的交集，不把按鈕移出父容器的觸控範圍 |
| Search／Library 標題 | Large Title | Title 1；即使 Compact 也保留 iPad 字級 |
| 播放清單／專輯／藝人文字 | 左右各 20pt | 左右至少 24pt，內文最大寬 640pt，置中 |
| 內容頁播放按鈕列 | 主按鈕置中，文字過長時縮至可用寬度 | 同樣按目前面板寬度計算；旁邊按鈕保留 48pt 與 16pt 間距 |
| 封面 hero 高度 | 視窗尺寸改變時清除舊高度 | 旋轉、縮放多工視窗時重新計算，不沿用舊比例 |
| 歌詞小封面／歌名 | 保留原生標題的 leading | 以目前播放面板的 safe area + 24pt 對齊，不再繼承大封面的額外內縮 |
| 播放頁 footer | 依目前 player safe area 定位 | 保留原生位置；兩者都跟著 footer row 的後續排版更新 |

Home、Search 與 footer 沿用 Kit 的公開 UIKit layout observer；沒有新增私有 selector。Navbar Auto 沿用已回報有效的版本。這些調整的實際外觀、帳號觸控與旋轉轉場仍需兩種裝置分別核對。

## 保留的策略與待驗證項目

- iPad 橫向保留原生 Split，隱藏真正的 `now-playing-toggle-button`；直向套用 Compact。旋轉同步與原生模式切換沿用 `8e8156b` 的處理，這輪沒有再加一套收合流程。旋轉後是否自動回 Split 仍須實機驗證。
- 手機保持原生直向政策，更多選單直接使用 Spotify 原生 sheet。
- Navbar Auto 的標籤判斷沿用已回報有效的版本。
- Liked Songs 合成封面保持回退；漸層／混色背景仍未確認修復。
- iPad 底部壓暗漸層、更新／贊助／證書推銷提示維持停用。
- Sidebar 的 Apple 原生化仍未實作；本輪沒有替換 Spotify 的導航容器。

## 建置檢查

Windows 檢查 `scripts/check-layers.sh`、Redesigned 全部 53 個 Logos 來源與 `git diff --check`。完整 Objective-C／iOS SDK 編譯、注入與 IPA 封裝由 Actions 的 **Build IPA from your own Spotify IPA** 執行，輸出選 artifacts。Windows 不具備 iOS SDK，未執行 simulator harness。

`harness/layout/geometry.c` 直接測試正式使用的 `SGRAdaptiveLayout.h`，包含 280–1366pt 面板、不同長度的播放文字、左右控制項的有／無組合，共 416 組。檢查主按鈕置中、按鈕列邊界與間距、文字最大寬、膠囊不超出可用寬度。Windows 的 MSVC C11 編譯與執行已通過；Actions 另外執行 `sh harness/layout/check.sh`。此測試不模擬 Spotify view tree，不能代替真機觸控與畫面檢查。

## 安裝後驗證

使用本輪 Actions 產物簽名安裝並重啟 Spotify，選 Redesigned，在 iOS／iPadOS 26 檢查：

1. 快速進出一般播放清單、Liked Songs、專輯與藝人頁，封面尚未載入時應能較早看到控制項／內容，原生返回可操作。
2. iPad 開啟歌詞，調整視窗高度但保持寬度，焦點歌詞應重新定位；再檢查直向轉橫向的 Split 與原生收合操作。
3. Mod Settings → Navbar 開啟 inline mini player，快速交替左右滑、未達門檻放手與旋轉，確認沒有延後的多次切歌或卡住的內容位移。
4. 啟用 VoiceOver，mini player 可開播放頁，動作提供播放／暫停與前後曲；啟用減少透明度與減少動態效果，控制底色應實心，歌詞不再使用跟隨 spring。
5. Search 分類卡保留色彩、封面與點擊入口，卡片不再有玻璃邊緣；搜尋欄與導覽仍保留玻璃。
6. 手機直向分別開 Home、Search、Library，確認膠囊、帳號按鈕、標題與原生控制項對齊；開啟名稱較長的播放清單，Play、shuffle 與儲存按鈕不應互相覆蓋。
7. iPad 直向、橫向 Split 與窄多工視窗分別檢查上述頁面，邊開內容頁邊轉向／縮放，封面、文字與按鈕列應重新適配。開歌詞後，小封面／歌名應對齊播放面板左側的歌詞文字；footer 三個入口應留在面板內且可點。
