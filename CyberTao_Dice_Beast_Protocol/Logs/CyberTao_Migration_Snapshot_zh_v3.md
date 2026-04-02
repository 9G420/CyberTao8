<!-- CURRENT_VERSION_NOTICE -->
> 注意：本文件主体内容当前落后于真实项目进度。
> 截至 2026-04-02，项目真实基线为 `v0.1.103`。
> 接手时请优先以 `Logs/AI_Employee_Guide_v3.md`、`Logs/Mulerun_Work_Report.md`、`Logs/changelog_v0.1.md` 为准；本文仅作为架构快照参考。
# CyberTao: Dice Beast Protocol 椤圭洰杩佺Щ蹇収锛堜腑鏂?v3锛?

**鏇存柊鏃堕棿**: 2026-04-01
**褰撳墠鐗堟湰**: v0.1.72
**GitHub 浠撳簱**: `https://github.com/9G420/CyberTao8`
**涓昏寮€鍙戝垎鏀?*: `codex/dice-beast-protocol`
**涓诲伐浣滅洰褰?*: `CyberTao_Dice_Beast_Protocol/Project/`
**寮曟搸**: Godot 4.6.1 | GDScript | renderer: gl_compatibility
**瑙嗗彛**: 1280x720 | stretch mode: canvas_items

---

## 0. 鏂版帴鎵?AI 蹇呰锛堝揩閫熶笂鎵嬫寚鍗楋級

**浣犳鍦ㄦ帴鎵嬩竴涓?Godot 璧涘崥鏈嬪厠鎴樻湳 Roguelike 椤圭洰銆?* 璇锋寜浠ヤ笅椤哄簭闃呰鏂囦欢锛?

1. **`Logs/AI_Employee_Guide_v3.md`** 鈥?AI 鍛樺伐涓婂矖鎸囦护锛堣涓鸿鑼?鎶€鏈‖瑙勫垯+鏃ュ織瑙勮寖锛?
2. **`Logs/Handoff_Package_latest.md`** 鈥?鏈€鏂颁氦鎺ュ寘锛堝瀛樺湪锛屼紭鍏堢骇楂樹簬鏈枃浠讹級
3. **鏈枃浠?*锛坄Logs/CyberTao_Migration_Snapshot_zh_v3.md`锛夆€?椤圭洰鍏ㄨ矊銆佹灦鏋勩€佹暟鎹粨鏋勩€佸綋鍓嶇姸鎬?
4. **`Logs/Mulerun_Work_Report.md`** 鈥?鏈€杩戜竴杞伐浣滄姤鍛?
5. **`Logs/changelog_v0.1.md`** 鈥?瀹屾暣鐗堟湰鍙樻洿璁板綍锛坴0.1.0 ~ v0.1.60锛?

**鍏抽敭瑙勫垯锛?*
- **鍙湪 `CyberTao_Dice_Beast_Protocol/Project/` 鐩綍涓嬪紑鍙?*锛屼笉瑕佷慨鏀规棫椤圭洰 `CyberTao8` 鏍圭洰褰?
- **鎵€鏈夋棩蹇楀繀椤诲啓涓枃**
- 姣忚疆浠诲姟瀹屾垚鍚庡繀椤绘洿鏂颁笁浠跺锛歚Mulerun_Work_Report.md` + `changelog_v0.1.md` + `AI_Employee_Guide_v3.md`
- 姣忔浠诲姟鍓嶇‘璁わ細鏈嶅姟浜庢鐩樿蛋浣嶅眰 or 鍗＄墝鎴樻枟灞傦紝涓よ€呴兘涓嶆槸鍒欎笉浼樺厛鍋?

**褰撳墠闃舵鐘舵€侊細鍙屽眰鐜╂硶缁撴瀯瀹屾暣闂幆锛屽崱鐗屾垬鏂楀眰绗竴鐗堝畬鎴愬苟鎸佺画娣卞寲锛岀編鍖?Phase 1~6 鍏ㄩ儴瀹屾垚锛岀瓑璺濊创鍥炬鐩?鐩告満璺熼殢+榧犳爣鎷栨嫿+缂╂斁+瑙掕壊褰㈣薄閲嶆瀯+閫愭牸绉诲姩鍔ㄧ敾+鍗＄墝鎷栨嫿鍑虹墝+澶村儚HUD+鐜╁绮剧伒鍔ㄧ敾宸插疄鐜般€?D 娓愯繘杩佺Щ P0 瀹屾垚锛圔oardView3D+SubViewport+F5鍒囨崲鍙岃鍥撅級锛寁0.1.72 瀹屾垚 3D 浜や簰鎵嬫劅淇锛堟嫋鎷?闀滃ご璺熼殢+杈圭晫闄愬埗+缂╂斁杞村績锛夈€備笅涓€闃舵鑱氱劍 3D 鍙嶉绯荤粺鎴栧晢搴楁牸鎵╁睍銆?*

---

## 1. 椤圭洰瀹氫綅

`CyberTao: Dice Beast Protocol锛堥鍏藉崗璁級` 鏄棫椤圭洰 `CyberTao8` 鐨勫苟琛岄噸鏋勬柟鍚戙€?

**姝ｅ紡涓荤帺娉曟柟鍚戯紙v0.1.22 璧风敓鏁堬級锛?*

### "楠板瓙璧颁綅妫嬬洏鎺ㄨ繘 + 閬亣瑙﹀彂鍗＄墝鎴樻枟"

鍙屽眰鐜╂硶缁撴瀯锛?

1. **澶栧眰锛氭鐩樿蛋浣嶅眰** 鈥?鎺烽鑾峰緱璧勬簮 鈫?鍦ㄦ鐩樹笂绉诲姩/璧颁綅/韪╂牸 鈫?璺嚎閫夋嫨/鎶㈢偣/鍗犻珮鍙?閬块櫡闃?閾鸿矾鎺ㄨ繘 鈫?瑙﹀彂閬亣
2. **鍐呭眰锛氬崱鐗屾垬鏂楀眰** 鈥?閬亣瑙﹀彂鍚庡垏鍏?鈫?鎶界墝/鍑虹墝/鑳介噺璐圭敤/鏀婚槻鍗氬紙/鏋勭瓚鎴愰暱 鈫?鎴樻枟缁撶畻 鈫?鍥炲埌妫嬬洏缁х画

鏍稿績鐞嗗康锛?
- 妫嬬洏灞傝礋璐?璧板埌鍝噷銆侀亣鍒颁粈涔堛€佸崰浠€涔堜紭鍔?
- 鍗＄墝灞傝礋璐?鐪熸鎵撹捣鏉ユ椂鎬庝箞璧?
- 涓ゅ眰浜掔浉澧炵泭锛氭鐩樿蛋浣嶅奖鍝嶆垬鏂楁潯浠讹紝鎴樻枟缁撴灉褰卞搷妫嬬洏鎺ㄨ繘

椋庢牸鏍囩锛氶瀛愰┍鍔?/ 鎬吔瀵规姉 / 鍙敜閾鸿矾 / CN meme / 璧涘崥 furry

---

## 2. 褰撳墠宸插畬鎴愬唴瀹癸紙v0.1.0 鈫?v0.1.72锛?

### 妫嬬洏璧颁綅灞傦紙澶栧眰 鈥?鍏ㄩ儴绋冲畾锛?

| 绯荤粺 | 鐗堟湰 | 鐘舵€?|
|------|------|------|
| 8x8 妫嬬洏鍙鍖栵紙璧涘崥鏈嬪厠椋庢牸锛?| v0.1.0 | 绋冲畾 |
| 鎺烽 鈫?6绉峜rest璧勬簮姹?| v0.1.1 | 绋冲畾 |
| 鍗曚綅閫変腑 + BFS绉诲姩锛堝惈鍦板舰鏉冮噸锛?| v0.1.1 | 绋冲畾 |
| 鍩虹杩戞垬鏀诲嚮锛堝惈鍦板舰閫傛€у姞鎴愶級 | v0.1.4 | 绋冲畾 |
| HP鏄剧ず + 鑳滆礋鍒ゅ畾 + 閲嶆柊寮€濮?| v0.1.6/12 | 绋冲畾 |
| 鏀诲嚮鍙嶉锛堥棯鍏?椋樺瓧锛?| v0.1.12 | 绋冲畾 |
| 鏁屾柟AI鏈€灏忓洖鍚堬紙浼樺厛鏀诲嚮/杩借釜锛?| v0.1.13 | 绋冲畾 |
| 鍙敜閾鸿矾锛圫UMMON鈫掕矾寰勬牸+鍙敜鍗曚綅锛?| v0.1.14 | 绋冲畾 |
| 鍦板舰绯荤粺锛堥珮鍙?闄烽槺锛?| v0.1.15 | 绋冲畾 |
| 鍗曚綅鍦板舰閫傛€э紙3绉嶏級 | v0.1.19 | 绋冲畾 |
| 閬撳叿鎷惧彇锛?绉嶅嵆鏃舵晥鏋滐級 | v0.1.20 | 绋冲畾 |
| 鏁屾柟鎰忓浘骞挎挱 + 鏀诲嚮棰勮 | v0.1.21 | 绋冲畾 |
| 閬亣鏆傚仠涓嶦NCOUNTER闃舵 | v0.1.23 | 绋冲畾 |
| 缁熶竴璧涘崥鏈嬪厠瑙嗚椋庢牸锛圕yberStyle锛?| v0.1.29 | 绋冲畾 |
| DEFEND/SKILL/TRICK crest 娑堣€楀叆鍙?| v0.1.33 | 绋冲畾 |
| 妫嬬洏闅忔満鐢熸垚锛圔oardGenerator锛?| v0.1.35 | 绋冲畾 |
| BuffManager 鎺ュ叆锛坱ick_turn+浼ゅ淇+閬撳叿buff锛?| v0.1.39 | 绋冲畾 |
| BattleFlowController 鐦﹁韩锛?95鈫?88琛岋紝CrestActionHandler+CellEffectHandler 鍓ョ锛?| v0.1.40 | 绋冲畾 |
| 9绉嶅彲浜や簰鏍煎瓙锛堝惈鎭㈠/浜嬩欢/鍟嗗簵/瀹濈锛?| v0.1.41 | 绋冲畾 |
| 澶氬眰鍦板浘锛?灞傛帹杩?灞傞棿濂栧姳+HP淇濈暀锛?| v0.1.42 | 绋冲畾 |
| BUG-001 淇锛堝垎杈ㄧ巼/鍏ㄥ睆/鏃犺竟妗?绐楀彛妯″紡鍒囨崲锛?| v0.1.43 | 绋冲畾 |
| 缇庡寲 Phase 1锛圔oardCellRenderer+UnitRenderer+楂樹寒鍗囩骇锛?| v0.1.45 | 绋冲畾 |
| 缇庡寲 Phase 2锛圖iceRollAnimation+BattleEffects锛?| v0.1.46 | 绋冲畾 |
| 缇庡寲 Phase 4.1锛圕yberBackground 鑳屾櫙姘涘洿鍗囩骇锛?| v0.1.48 | 绋冲畾 |
| 鎺烽婕斿嚭鍗囩骇锛堜吉3D绛夎窛楠板瓙+鍏ㄥ睆灞呬腑锛?| v0.1.49 | 绋冲畾 |
| Boss閿佸畾+鍝ㄥ叺鍓嶇疆+浼犻€侀棬鏈哄埗 | v0.1.50 | 绋冲畾 |
| Boss/閬亣鏍煎嚮璐ユ秷澶?Bug 淇锛坮esolve_encounter 涓夊垎鏀級 | v0.1.51 | 绋冲畾 |
| 鍗曚綅绮剧畝锛?涓昏+浼欎即妲界郴缁燂級+ 鑻遍泟瀛樻椿鍒惰儨璐熷垽瀹?| v0.1.52 | 绋冲畾 |
| Boss瑙ｉ攣鑷姩浼犻€?+ 瀹濆彲姊﹀紡鍗＄墝鎴樻枟杩囨浮 | v0.1.53 | 绋冲畾 |
| 鍏ㄥ睆鐙珛鍗＄墝鎴樻枟鐣岄潰+瑙掕壊绔嬬粯+鎵囧舰鎵嬬墝+妫嬬洏鍗曚綅缇庡寲 | v0.1.54 | 绋冲畾 |
| 缇庡寲 Phase 4.2锛圲ITransitions+闈㈡澘缂撳姩鍔ㄧ敾+鍙敜灞曞紑婕斿嚭锛?| v0.1.55 | 绋冲畾 |
| 缇庡寲 Phase 5锛圓udioManager+SFXGenerator+鍏ㄥ眬闊虫晥鎺ュ叆+BGM鍒囨崲锛?| v0.1.56 | 绋冲畾 |
| 灞傞棿闅惧害閫掑锛坈urrent_floor缂╂斁鏁屾柟HP/ATK锛?| v0.1.57 | 绋冲畾 |
| 缇庡寲 Phase 6锛圛soTileRenderer+绛夎窛璐村浘妫嬬洏+BoardView绛夎窛鍖栵級 | v0.1.58 | 绋冲畾 |
| 鍏ㄥ睆绛夎窛妫嬬洏+鍙犲眰UI+楂樿捣璐村浘+瑙掕壊鏀惧ぇ | v0.1.59 | 绋冲畾 |
| 鐩告満璺熼殢鐜╁瑙掕壊+鍏ㄦ柊绱犳潗+UI浼樺寲 | v0.1.60 | 绋冲畾 |
| 妫嬬洏娓叉煋鍥為€€鑷崇▼搴忓寲锛堢Щ闄I璐村浘+绋嬪簭鍖栬彵褰㈢粯鍒讹級 | v0.1.61 | 绋冲畾 |
| 榧犳爣鎷栨嫿鐩告満+骞虫粦璺熼殢+鎮仠楂樹寒+妫嬬洏鎵╁睍12x12 | v0.1.62 | 绋冲畾 |
| 澶т笘鐣岀幆澧冨～鍏?缂╂斁+鏁屾柟璺熼殢+鍏夋爣+UI绱у噾鍖?| v0.1.63 | 绋冲畾 |
| 闀滃ご璺熼殢浼樺寲+鎺烽鍔ㄧ敾澧炲己 | v0.1.64 | 绋冲畾 |
| 鏁屾柟鍥炲悎闀滃ご璺熼殢浼樺寲锛堢Щ鍔ㄨ窡韪?寤惰繜鍒囧洖+鏌斿拰杩囨浮锛?| v0.1.65 | 绋冲畾 |
| 瑙掕壊褰㈣薄閲嶆瀯锛堝挬鍜╁惎绀哄綍椋庢牸锛?闊虫晥璁剧疆闈㈡澘 | v0.1.66 | 绋冲畾 |
| 绉诲姩閫愭牸琛岃蛋鍔ㄧ敾+鏁屾柟绉诲姩鍔ㄧ敾+鎴戞柟鍥炲悎闀滃ご鍒囧洖浼樺寲 | v0.1.67 | 绋冲畾 |
| 鍗＄墝鎷栨嫿鍑虹墝+鍗虫椂浼ゅ鍙嶉 | v0.1.68 | 绋冲畾 |
| 椤堕儴鍗曚綅澶村儚 HUD | v0.1.69 | 绋冲畾 |
| 鐜╁瑙掕壊绮剧伒鍔ㄧ敾锛?鏂瑰悜 spritesheet锛?| v0.1.70 | 绋冲畾 |
| 3D 娓愯繘杩佺Щ P0锛圔oardView3D+SubViewport+F5鍒囨崲鍙岃鍥撅級 | v0.1.71 | 绋冲畾 |
| 3D 浜や簰鎵嬫劅淇锛堟嫋鎷?闀滃ご璺熼殢+杈圭晫闄愬埗+缂╂斁杞村績锛?| v0.1.72 | 绋冲畾 |

### 鍗＄墝鎴樻枟灞傦紙鍐呭眰 鈥?绗竴鐗堝畬鎴愶紝鎸佺画娣卞寲锛?

| 绯荤粺 | 鐗堟湰 | 鐘舵€?|
|------|------|------|
| 鍙屽眰闂幆棣栨璺戦€?| v0.1.25 | 绋冲畾 |
| CardBattleController鐙珛鐘舵€佹満 | v0.1.26 | 绋冲畾 |
| 鑳介噺绯荤粺锛堟瘡鍥炲悎3鐐癸紝鎴愰暱鑷充笂闄?锛?| v0.1.27/38 | 绋冲畾 |
| 鍙岀墝鍫嗙郴缁燂紙鎶界墝/寮冪墝/娲楃墝锛?| v0.1.27 | 绋冲畾 |
| 3绉嶆晫鏂硅涓烘ā寮?+ 鎰忓浘棰勫憡 | v0.1.27 | 绋冲畾 |
| 鑳滃埄濂栧姳crest | v0.1.27 | 绋冲畾 |
| 璋冭瘯蹇嵎鎸夐挳锛堜竴閿祴璇曞崱鐗屾垬鏂楋級 | v0.1.28 | 绋冲畾 |
| 鎸佷箙鐗岀粍绯荤粺锛堣法鎴樻枟淇濈暀锛?| v0.1.31 | 绋冲畾 |
| 鎴樻枟鑳滃埄閫夌墝鏈哄埗锛?閫?鍔犲叆鐗岀粍锛?| v0.1.31 | 绋冲畾 |
| CardRewardPanel 濂栧姳閫夌墝闈㈡澘 | v0.1.31 | 绋冲畾 |
| 5绉嶉伃閬囨晫鏂癸紙鍚?绉嶆柊鏁屾柟锛?| v0.1.32 | 绋冲畾 |
| 5涓伃閬囨牸锛堣鐩栨鐩樺鏉¤矾绾匡級 | v0.1.32 | 绋冲畾 |
| DeckViewPanel 鐗岀粍鏌ョ湅闈㈡澘 | v0.1.34 | 绋冲畾 |
| 鍗＄墝鍗囩骇鏈哄埗锛?4绉嶇墝鍗囩骇鏁版嵁+濂栧姳闈㈡澘鍙屾ā寮忥級 | v0.1.36 | 绋冲畾 |
| Boss 閬亣锛堥浂鍙峰崗璁?HP20/ATK3/6闃舵+鐙珛瑙嗚+澧炲己濂栧姳锛?| v0.1.37 | 绋冲畾 |
| 鑳介噺鎴愰暱鏈哄埗锛堥伃閬囪儨鍒?1/Boss+2锛屼笂闄?锛?| v0.1.38 | 绋冲畾 |
| 缇庡寲 Phase 3锛圕ardRenderer+CardBattlePanel 閲嶈璁★級 | v0.1.47 | 绋冲畾 |

### 瑙嗚婕斿嚭绯荤粺

| 绯荤粺 | 鐗堟湰 | 鐘舵€?|
|------|------|------|
| CyberStyle 缁熶竴椋庢牸绯荤粺锛坈lass_name 鍏ㄥ眬娉ㄥ唽锛?| v0.1.29 | 绋冲畾 |
| BoardCellRenderer 鏍煎瓙娓叉煋锛?绉嶆牸瀛?Boss閿佸畾+浼犻€侀棬锛?| v0.1.45/50 | 绋冲畾 |
| UnitRenderer 鍗曚綅娓叉煋锛堣糠浣犺鑹插壀褰憋級 | v0.1.54 | 绋冲畾 |
| DiceRollAnimation 浼?D绛夎窛楠板瓙婕斿嚭 | v0.1.49 | 绋冲畾 |
| BattleEffects 鎴樻枟鐗规晥 | v0.1.46 | 绋冲畾 |
| CardRenderer 鍗＄墝娓叉煋锛?绉嶇被鍨嬬嫭绔嬮厤鑹?鍗囩骇鏍囪锛?| v0.1.47 | 绋冲畾 |
| CyberBackground 鑳屾櫙姘涘洿锛堟笎鍙?缃戞牸+绮掑瓙+鎵弿绾匡級 | v0.1.48 | 绋冲畾 |
| TransitionOverlay 瀹濆彲姊﹀紡鐧惧彾绐楄繃娓?| v0.1.53 | 绋冲畾 |
| BattleCharRenderer 鎴樻枟瑙掕壊绔嬬粯锛堢帺瀹?6绉嶆晫鏂癸級 | v0.1.54 | 绋冲畾 |
| UITransitions UI杩囨浮鍔ㄧ敾宸ュ叿绫?| v0.1.55 | 绋冲畾 |
| AudioManager+SFXGenerator 绋嬪簭鍖栭煶鏁堢郴缁燂紙28绉峉FX+4绉岯GM锛?| v0.1.56 | 绋冲畾 |
| IsoTileRenderer 绛夎窛璐村浘娓叉煋鍣紙TILE_W=192锛?| v0.1.58/60 | 绋冲畾 |
| UnitPortraitHUD 椤堕儴鍗曚綅澶村儚 HUD | v0.1.69 | 绋冲畾 |
| PlayerSpriteAnimator 鐜╁绮剧伒鍔ㄧ敾锛?鏂瑰悜 spritesheet锛?| v0.1.70 | 绋冲畾 |
| GridMapper3D 鏍煎潗鏍団啍3D涓栫晫鍧愭爣杞崲 | v0.1.71 | 绋冲畾 |
| TileMeshFactory3D 9绉嶆牸瀛?BoxMesh+StandardMaterial3D 宸ュ巶 | v0.1.71 | 绋冲畾 |
| UnitMeshFactory3D 鍗曚綅 CapsuleMesh/CylinderMesh+billboard HP 鏉?| v0.1.71 | 绋冲畾 |
| BoardView3D 瀹屾暣 3D 妫嬬洏瑙嗗浘锛堜俊鍙锋帴鍙ｅ榻?BoardView锛?| v0.1.71/72 | 绋冲畾 |

### 鍙屽眰闂幆瀹屾暣娴佺▼锛坴0.1.72锛?

```
妫嬬洏璧颁綅灞?                             鍗＄墝鎴樻枟灞?
鎺烽 鈫?鑾峰緱 crest
閫変腑鍗曚綅 鈫?绉诲姩/鏀诲嚮/鍙敜
韪╅伃閬囨牸 鈫?ENCOUNTER 鏆傚仠
  鈫?鐧惧彾绐楄繃娓★紙TransitionOverlay锛夆攢鈹€鈫?CardBattleController.start_battle()
                                        鈫?
                                      鍏ㄥ睆鎴樻枟鐣岄潰锛堣鑹茬珛缁?鎵囧舰鎵嬬墝锛?
                                        鈫?
                                      鎶界墝 3 寮?鈫?鏄剧ず鎰忓浘
                                        鈫?
                                      鐜╁鍑虹墝锛堟秷鑰楄兘閲忥級鈫?鏁堟灉缁撶畻
                                        鈫?
                                      缁撴潫鍥炲悎 鈫?寮冩墜鐗?鈫?鏁屾柟琛屽姩
                                        鈫?
                                      寰幆鑷充竴鏂?HP 鈮?0
                                        鈫?
                                      鑳滃埄 鈫?濂栧姳閫夌墝锛?閫? 鏂扮墝/鍗囩骇锛?
                                        鈫?
  鈫?鐧惧彾绐楄繃娓″洖妫嬬洏 鈫愨攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ battle_ended 淇″彿
妫嬬洏鍗曚綅 HP 鍚屾 鈫愨攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ resolve_encounter(victory, hp)
  鑳滃埄 鈫?閬亣鏍兼秷澶憋紙Boss鈫掔敓鎴愪紶閫侀棬锛?
  澶辫触浣嗗瓨娲?鈫?閬亣鏍间繚鐣欙紝HP淇濆簳1锛屽彲鍐嶆垬
  澶辫触鍏ㄧ伃 鈫?DEFEAT

澶氬眰鍦板浘淇″彿閾撅紙v0.1.50+锛夛細
鍑绘潃鍝ㄥ叺 鈫?_check_battle_outcome() 鈫?_try_unlock_boss() 鈫?boss_unlocked
韪〣oss閬亣鏍?鈫?encounter_triggered 鈫?鍗＄墝鎴樻枟
Boss鑳滃埄 鈫?resolve_encounter() 鈫?_spawn_portal_near() 鈫?portal_spawned
韪╀紶閫侀棬 鈫?_check_portal() 鈫?floor_cleared / game_won
```

### 鐜╁鍗曚綅锛坴0.1.52 绮剧畝鍚庯級

| 鍗曚綅 | 瀹氫綅 | HP | ATK | DEF | 绉诲姩 | 鏀诲嚮鑼冨洿 | 閫傛€?|
|------|------|-----|-----|-----|------|----------|------|
| 鍒€鐩剧嫍锛堣嫳闆勶級 | 鍓嶆帓鍧﹀厠 | 8 | 3 | 1 | 1 | 1 | 璺緞锛圖EF+1锛?|
| 浼欎即锛堝彫鍞わ級 | 杈呭姪 | 鈥?| 鈥?| 鈥?| 鈥?| 鈥?| 姣忓眰涓婇檺2娆?鍦轰笂1鍙?|

> 鐏电嫄楠囧銆侀甫鏈烘湳澹湪 v0.1.52 绉婚櫎鍑哄満锛屼粎淇濈暀 1 涓昏 + 浼欎即妲界郴缁?

### 6 涓伃閬囨晫鏂癸紙v0.1.32/37锛?

| 閬亣ID | 鍚嶇О | HP | ATK | 琛屼负妯″紡 | 瀹氫綅 |
|--------|------|-----|-----|----------|------|
| encounter_01 | 寮傚父鍝ㄥ叺 | 8 | 2 | 鏀烩啋鏀烩啋闃插嚮鈫掗噸鍑?4鍥炲悎) | 鍧囪　鍨?|
| encounter_02 | 璧涘崥娓搁瓊 | 4 | 3 | 鏀烩啋閲嶅嚮鈫掓敾(3鍥炲悎) | 鐖嗗彂鍨?|
| encounter_03 | 鏆楃綉鐖櫕 | 12 | 1 | 闃插嚮鈫掗槻鍑烩啋閲嶅嚮鈫掓敾(4鍥炲悎) | 鍧﹀厠鍨?|
| encounter_04 | 鑴夊啿鐚庢墜 | 5 | 4 | 閲嶅嚮鈫掓敾鈫掓敾(3鍥炲悎) | 鐜荤拑鐐瀷 |
| encounter_05 | 鏁版嵁骞界伒 | 9 | 2 | 鏀烩啋闃插嚮鈫掗噸鍑烩啋閲嶅嚮鈫掓敾(5鍥炲悎) | 闀垮懆鏈熷瀷 |
| encounter_boss_01 | 闆跺彿鍗忚 | 20 | 3 | 鏀烩啋闃叉敾鈫掗噸鍑烩啋鍥炲鈫掓敾鈫掕秴杞?6鍥炲悎) | Boss |

### 14绉嶅崱鐗岀墝缁勶紙v0.1.36 鍗囩骇鏈哄埗锛?

**鍒濆鐗岀粍锛?0寮狅級**

| 鍗＄墝 | 鏁伴噺 | 璐圭敤 | 鏁堟灉 | 鍗囩骇鍚?|
|------|------|------|------|--------|
| 鏂╁嚮 | 2 | 1E | 閫犳垚3浼ゅ | 鏂╁嚮+ 鈫?4浼ゅ |
| 閲嶅嚮 | 1 | 2E | 閫犳垚5浼ゅ | 閲嶅嚮+ 鈫?7浼ゅ |
| 闃插尽 | 2 | 1E | 鍑忎激2鐐?| 闃插尽+ 鈫?鍑忎激3 |
| 淇 | 1 | 1E | 鍥炲2HP | 淇+ 鈫?鍥炲3 |
| 杩炴柀 | 2 | 1E | 閫犳垚2浼ゅ | 杩炴柀+ 鈫?3浼ゅ |
| 鐚涙敾 | 1 | 3E | 閫犳垚8浼ゅ | 鐚涙敾+ 鈫?11浼ゅ |
| 鎬ユ晳 | 1 | 2E | 鍥炲4HP | 鎬ユ晳+ 鈫?鍥炲6 |

**濂栧姳鍗℃睜锛?绉嶏紝鎴樻枟鑳滃埄鍚?閫?锛?*

| 鍗＄墝 | 璐圭敤 | 鏁堟灉 | 鍗囩骇鍚?|
|------|------|------|--------|
| 绌垮埡 | 2E | 鏃犺闃插尽閫犳垚4浼ゅ | 绌垮埡+ 鈫?6浼ゅ |
| 閾佸 | 2E | 鍑忎激4鐐?| 閾佸+ 鈫?鍑忎激6 |
| 鍚歌鏂?| 2E | 閫犳垚3浼ゅ+鍥炲1HP | 鍚歌鏂? 鈫?4浼ゅ+鍥炲2 |
| 瓒呴淇 | 3E | 鍥炲6HP | 瓒呴淇+ 鈫?鍥炲9 |
| 鐢靛姬 | 1E | 閫犳垚2浼ゅ+鏁屾柟ATK-1 | 鐢靛姬+ 鈫?3浼ゅ+ATK-1 |
| 寮哄寲鏂╁嚮 | 1E | 閫犳垚4浼ゅ | 寮哄寲鏂╁嚮+ 鈫?6浼ゅ |
| 鍙岄噸闃插尽 | 1E | 鍑忎激3鐐?| 鍙岄噸闃插尽+ 鈫?鍑忎激4 |

---

## 3. 鏋舵瀯姒傝堪

### BattleV2 妯″潡鍖栨灦鏋?

```
BattleFlowController锛堟鐩樺眰鏍稿績鎺у埗鍣級         ~693琛岋紙鍚灞傚湴鍥撅級
鈹溾攢鈹€ DiceManager          鈥?鎺烽 + crest 璧勬簮姹?
鈹溾攢鈹€ BoardManager         鈥?妫嬬洏鐘舵€侊紙9涓牸瀛愬瓧鍏?locked_encounters+portal_cells + BFS锛?
鈹溾攢鈹€ BoardGenerator       鈥?妫嬬洏绋嬪簭鍖栫敓鎴愶紙闈欐€佸伐鍏风被锛?
鈹溾攢鈹€ UnitManager          鈥?鍗曚綅鐘舵€侊紙鐢熸垚/绉诲姩/浼ゅ/鍑绘潃锛?
鈹溾攢鈹€ ActionResolver       鈥?鏀诲嚮鑼冨洿璁＄畻
鈹溾攢鈹€ BuffManager          鈥?buff绠＄悊锛堝凡鎺ュ叆锛歵ick_turn+浼ゅ淇锛?鉁?
鈹溾攢鈹€ BattleAI             鈥?鏁屾柟鍐崇瓥
鈹溾攢鈹€ AttackRuleHelper     鈥?浼ゅ鍏紡
鈹溾攢鈹€ VictoryRuleHelper    鈥?鑳滆礋鍒ゅ畾锛坔as_hero_unit 鑻遍泟瀛樻椿鍒讹級
鈹溾攢鈹€ CrestActionHandler   鈥?Crest娑堣€楁搷浣滐紙浠嶣FC鍓ョ锛?     ~66琛?
鈹斺攢鈹€ CellEffectHandler    鈥?鏍煎瓙鏁堟灉澶勭悊锛堜粠BFC鍓ョ锛?      ~205琛?

CardBattleController锛堝崱鐗屽眰鐙珛鐘舵€佹満锛?        ~540琛?
鈹斺攢鈹€ 鐘舵€侊細IDLE/PLAYER_TURN/ENEMY_TURN/VICTORY/DEFEAT/REWARD_SELECT
```

### UI 灞?

```
Main.gd锛堝満鏅粍鍚?淇″彿涓浆+闊虫晥瑙﹀彂+鐩告満璺熼殢+3D瑙嗗浘璺敱锛?      ~670琛?
鈹溾攢鈹€ BoardView            鈥?妫嬬洏娓叉煋+鐐瑰嚮浜や簰+鍙嶉鍔ㄧ敾+鐩告満璺熼殢    ~610琛岋紙v0.1.70 绮剧伒鍔ㄧ敾锛?
鈹溾攢鈹€ BoardCellRenderer    鈥?鏍煎瓙娓叉煋闈欐€佺被锛坈lass_name锛?  ~210琛岋紙Phase 6 鍚庝粎渚涘弬鑰冿級
鈹溾攢鈹€ UnitRenderer         鈥?鍗曚綅娓叉煋锛坴0.1.66 鍜╁挬鍚ず褰曢鏍硷級  ~490琛?
鈹溾攢鈹€ IsoTileRenderer      鈥?绛夎窛绋嬪簭鍖栨覆鏌撳櫒锛坈lass_name锛?  ~200琛?鉁?v0.1.61 绋嬪簭鍖栭噸鍐?
鈹溾攢鈹€ PlayerSpriteAnimator 鈥?鐜╁绮剧伒鍔ㄧ敾绠＄悊鍣紙class_name锛? ~70琛?鉁?v0.1.70 鏂板
鈹溾攢鈹€ DiceRollAnimation    鈥?鎺烽婕斿嚭鍔ㄧ敾锛坈lass_name锛?    ~252琛?鉁?v0.1.49 閲嶅啓
鈹溾攢鈹€ BattleEffects        鈥?鎴樻枟鐗规晥闈欐€佺被锛坈lass_name锛?  ~103琛?鉁?Phase 2 鏂板
鈹溾攢鈹€ DiceDebugPanel       鈥?妫嬬洏灞侶UD锛堝惈灞傛暟鏄剧ず锛?      ~540琛?
鈹溾攢鈹€ CardRenderer         鈥?鍗＄墝娓叉煋闈欐€佺被锛坈lass_name锛?    ~233琛?鉁?Phase 3 鏂板
鈹溾攢鈹€ CardBattlePanel      鈥?鍗＄墝鎴樻枟UI锛坴0.1.54 鍏ㄥ睆閲嶈璁★級  ~420琛?
鈹溾攢鈹€ CardRewardPanel      鈥?濂栧姳閫夌墝/鍗囩骇闈㈡澘             ~230琛?
鈹溾攢鈹€ DeckViewPanel        鈥?鐗岀粍鏌ョ湅闈㈡澘                 ~160琛?
鈹溾攢鈹€ CyberStyle           鈥?鍏ㄥ眬瑙嗚椋庢牸锛坈lass_name娉ㄥ唽锛墌149琛?
鈹溾攢鈹€ CyberBackground      鈥?鑳屾櫙姘涘洿绯荤粺锛坈lass_name娉ㄥ唽锛? ~155琛?鉁?Phase 4.1 鏂板
鈹溾攢鈹€ TransitionOverlay    鈥?瀹濆彲姊﹀紡鐧惧彾绐楄繃娓★紙CanvasLayer 10锛?~110琛?鉁?v0.1.53 鏂板
鈹溾攢鈹€ BattleCharRenderer   鈥?鎴樻枟瑙掕壊绔嬬粯娓叉煋锛坈lass_name娉ㄥ唽锛?  ~180琛?鉁?v0.1.54 鏂板
鈹溾攢鈹€ UITransitions        鈥?UI杩囨浮鍔ㄧ敾宸ュ叿绫伙紙class_name娉ㄥ唽锛?   ~60琛?鉁?v0.1.55 鏂板
鈹溾攢鈹€ UnitPortraitHUD      鈥?椤堕儴鍗曚綅澶村儚 HUD锛坈lass_name娉ㄥ唽锛?  ~130琛?鉁?v0.1.69 鏂板
鈹斺攢鈹€ SettingsPanel        鈥?鏄剧ず璁剧疆+闊抽噺鎺т欢

UI3D/锛坴0.1.71 鏂板 鈥?3D 娓愯繘杩佺Щ琛ㄧ幇灞傦級
鈹溾攢鈹€ GridMapper3D         鈥?鏍煎潗鏍団啍3D涓栫晫鍧愭爣杞崲锛坈lass_name锛岀函鏁板宸ュ叿锛? ~40琛?鉁?v0.1.71 鏂板
鈹溾攢鈹€ TileMeshFactory3D    鈥?9绉嶆牸瀛?BoxMesh+StandardMaterial3D 宸ュ巶锛坈lass_name锛? ~120琛?鉁?v0.1.71 鏂板
鈹溾攢鈹€ UnitMeshFactory3D    鈥?鍗曚綅 CapsuleMesh/CylinderMesh+billboard HP 鏉★紙class_name锛? ~130琛?鉁?v0.1.71 鏂板
鈹斺攢鈹€ BoardView3D          鈥?瀹屾暣 3D 妫嬬洏瑙嗗浘锛圫ubViewport 宓屽叆+淇″彿鎺ュ彛瀵归綈 BoardView锛? ~380琛?鉁?v0.1.71 鏂板 / v0.1.72 浜や簰淇

System/
鈹溾攢鈹€ AudioManager         鈥?闊虫晥绠＄悊鍣紙class_name娉ㄥ唽锛屽閫氶亾SFX+BGM锛? ~120琛?鉁?v0.1.56 鏂板
鈹斺攢鈹€ SFXGenerator         鈥?绋嬪簭鍖栭煶棰戝紩鎿庯紙28绉嶉煶鏁?4绉岯GM寰幆锛?      ~1100琛?鉁?v0.1.56 杩佸叆
```

### 淇″彿浣撶郴

```
妫嬬洏灞備俊鍙凤紙BattleFlowController锛夛細
  setup_completed / phase_changed / round_changed
  move_completed / attack_completed / enemy_attack_completed
  summon_completed / terrain_damage_triggered / item_picked_up
  enemy_action_announced / enemy_turn_ended
  encounter_triggered / encounter_resolved
  heal_cell_triggered / event_cell_triggered
  boss_unlocked / portal_spawned / hero_warped       鈫?v0.1.50/53 鏂板
  floor_cleared / game_won                           鈫?v0.1.42 鏂板

鍗＄墝灞備俊鍙凤紙CardBattleController锛夛細
  battle_started / hand_changed / card_played
  enemy_acted / enemy_intent_changed / turn_resolved
  battle_ended / victory_reward

璋冭瘯淇″彿锛圖iceDebugPanel锛夛細
  test_card_battle_requested
```

### 鍏抽敭鏁版嵁缁撴瀯

```
BoardManager:
  occupied_cells: Dictionary     # cell -> unit_id
  path_cells: Dictionary         # cell -> owner_id
  item_cells: Dictionary         # cell -> item_id
  terrain_cells: Dictionary      # cell -> "high_ground" / "trap"
  encounter_cells: Dictionary    # cell -> encounter_id
  heal_cells: Dictionary         # cell -> int (heal_amount)
  event_cells: Dictionary        # cell -> String (event_id)
  shop_cells: Dictionary         # cell -> shop_data          鈫?v0.1.41 鏂板
  chest_cells: Dictionary        # cell -> chest_data         鈫?v0.1.41 鏂板
  locked_encounters: Dictionary  # cell -> bool               鈫?v0.1.50 鏂板
  portal_cells: Dictionary       # cell -> bool               鈫?v0.1.50 鏂板

UnitManager:
  units_by_id: Dictionary     # unit_id -> {hp, max_hp, atk, def, move_range, attack_range, owner, cell, terrain_affinity, display_name, is_summoned}
  units_by_cell: Dictionary   # cell -> unit_id

DiceManager:
  crest_pool: Dictionary      # "summon"/"move"/"attack"/"defend"/"skill"/"trick" -> int

CardBattleController:
  _draw_pile: Array           # 鎶界墝鍫?
  _discard_pile: Array        # 寮冪墝鍫?
  _hand: Array                # 褰撳墠鎵嬬墝锛堟瘡寮?= {name, type, value, cost, upgraded}锛?
  energy / max_energy: int    # 褰撳墠鑳介噺 / 姣忓洖鍚堣兘閲忎笂闄愶紙3璧锋锛屼笂闄?锛?
  _enemy_pattern: Array       # 鏁屾柟琛屼负寰幆搴忓垪
  _persistent_deck: Array     # 鎸佷箙鐗岀粍锛堣法鎴樻枟淇濈暀锛?     鈫?v0.1.31 鏂板
```

### 鎴樻枟闃舵娴佺▼

```
妫嬬洏灞?
  BattlePhase: BOOT 鈫?PLAYER_ROLL 鈫?PLAYER_ACTION 鈫?[ENCOUNTER] 鈫?ENEMY_ROLL 鈫?ENEMY_ACTION 鈫?(loop)
  缁堟€? VICTORY / DEFEAT
  閬亣鍒嗘敮: PLAYER_ACTION 鈫?ENCOUNTER 鈫?[鐧惧彾绐楄繃娓 鈫?[鍏ㄥ睆鍗＄墝鎴樻枟] 鈫?resolve_encounter(涓夊垎鏀? 鈫?PLAYER_ACTION
  Boss 閾? 鍝ㄥ叺鍏ㄧ伃 鈫?Boss瑙ｉ攣 鈫?鑻遍泟鑷姩浼犻€?鈫?Boss鎴樻枟 鈫?浼犻€侀棬 鈫?涓嬩竴灞?閫氬叧

鍗＄墝灞?
  BattleState: IDLE 鈫?PLAYER_TURN 鈫?ENEMY_TURN 鈫?(loop) 鈫?VICTORY 鈫?REWARD_SELECT / DEFEAT
```

### 鍏抽敭浠ｇ爜璺緞

- **绉诲姩鍚庢鏌ラ『搴?*锛歚try_move_unit()` 鈫?`_check_terrain_trap()` 鈫?`_check_item_pickup()` 鈫?`_check_heal_cell()` 鈫?`_check_event_cell()` 鈫?`_check_encounter()` 鈫?`_check_portal()`
- **鐐瑰嚮浼樺厛绾?*锛歛ttack > move > summon
- **浼ゅ鍏紡**锛歚max(1, attacker.atk - defender.def - terrain_bonus)`
- **淇濆簳鏈哄埗**锛氭瘡娆℃幏楠颁繚搴?1 MOVE crest
- **閬亣瑙﹀彂閾?*锛歚encounter_triggered` 鈫?Main.gd 鈫?TransitionOverlay 鐧惧彾绐?鈫?`CardBattleController.start_battle()` 鈫?鍏ㄥ睆鎴樻枟鐣岄潰 鈫?`battle_ended` 鈫?鐧惧彾绐楀洖妫嬬洏 鈫?`resolve_encounter(涓夊垎鏀?`
- **resolve_encounter 涓夊垎鏀?*锛坴0.1.51锛夛細鑳滃埄鈫掓竻閬亣鏍硷紙Boss鐢熶紶閫侀棬锛夛紱澶辫触瀛樻椿鈫掗伃閬囨牸淇濈暀HP淇濆簳1锛涘け璐ュ叏鐏啋DEFEAT

---

## 4. 宸茬煡闂涓庢妧鏈€?

| 闂 | 涓ラ噸绋嬪害 | 鏄惁闃诲 | 璇存槑 |
|------|----------|----------|------|
| ~~BUG-001锛氬垎杈ㄧ巼/绐楀彛妯″紡鍒囨崲鏃犳晥~~ | ~~浣巭~ | ~~鍚~ | 鉁?v0.1.43 宸茶В鍐?|
| ~~BuffManager.tick_turn() 鏈帴鍏~ | ~~涓瓇~ | ~~鍚~ | 鉁?v0.1.39 宸茶В鍐?|
| ~~BattleFlowController 795琛寏~ | ~~涓瓇~ | ~~鍚~ | 鉁?v0.1.40 宸茬槮韬嚦588琛?|
| BattleFlowController 693琛岋紙澶氬眰鍦板浘鍚庡闀匡級 | 涓?| 鍚?| 涓嬫澶у姛鑳藉墠鑰冭檻鐦﹁韩 |
| 鐢靛姬鐗?ATK-1 鏁堟灉浠呭崟鍦虹敓鏁堬紙璁捐缂洪櫡锛?| 浣?| 鍚?| 鍗＄墝鏁版嵁缁撴瀯閲嶆瀯鏃朵慨 |
| 鍗囩骇鏁板€兼湭缁忓钩琛℃祴璇?| 浣?| 鍚?| 鏁板€艰皟浼樿疆娆?|
| 澶氬眰鍦板浘闅惧害鏆備笉閫掑锛堝悇灞傛晫鏂规暟鍊肩浉鍚岋級 | ~~浣巭~ | ~~鍚~ | 鉁?v0.1.57 宸插疄鐜板眰闂撮毦搴︾缉鏀?|
| 闃典骸鍗曚綅璺ㄥ眰涓嶅娲伙紙鍙兘瀵艰嚧鍚庣画灞傝繃闅撅級 | 浣?| 鍚?| 鏁板€艰皟浼樿疆娆?|
| CardRewardPanel 鏈娇鐢?CardRenderer 椋庢牸 | 浣?| 鍚?| UI 缁熶竴杞 |
| 鎵囧舰鎵嬬墝鏃犳嫋鎷斤紙浠呯偣鍑诲嚭鐗岋級 | ~~浣巭~ | ~~鍚~ | 鉁?v0.1.68 宸插疄鐜版嫋鎷藉嚭鐗?|
| spritesheet 鑳屾櫙閫忔槑搴﹀緟纭 | 涓?| 鍚?| 鐢ㄦ埛娴嬭瘯鍚庡鐞?|
| 3D 鍙嶉鏂规硶涓烘々鍑芥暟锛坧lay_attack_feedback 绛夛級 | 涓?| 鍚?| 3D 杩唬 P1 |
| 3D 鍗曚綅涓虹畝鍗曞嚑浣曚綋锛圕apsuleMesh/CylinderMesh锛?| 浣?| 鍚?| 3D 杩唬 P2 |
| DiceDebugPanel 缁戝畾 2D BoardView锛?D 妯″紡涓嬫棤浜や簰閫傞厤锛?| 浣?| 鍚?| 3D 瀹屽杽杞 |
| BoardView3D.rebuild_board() 鍏ㄩ噺閲嶅缓锛堝ぇ妫嬬洏鎬ц兘寮€閿€锛?| 浣?| 鍚?| 3D 浼樺寲杞 |

---

## 5. 涓嬩竴闃舵鎺ㄨ繘寤鸿

### 褰撳墠闃舵鏍稿績鏂瑰悜锛氫綋楠屾墦纾?+ 鍔熻兘鎵╁睍

v0.1.31~v0.1.72 瀹屾垚浜嗗崱鐗屾繁鍖栥€佸叏闈㈢編鍖栵紙Phase 1~6锛夈€佺瓑璺濇鐩?鐩告満绯荤粺+榧犳爣鎷栨嫿+瑙掕壊褰㈣薄閲嶆瀯+閫愭牸绉诲姩鍔ㄧ敾+鍗＄墝鎷栨嫿鍑虹墝+澶村儚HUD+鐜╁绮剧伒鍔ㄧ敾+3D 娓愯繘杩佺Щ P0+3D 浜や簰鎵嬫劅淇銆?

### 馃敶 楂樹紭鍏堢骇

1. **3D 鍙嶉绯荤粺瀹炵幇** 鈥?绮掑瓙鐗规晥/3D 椋樺瓧鏇夸唬 2D BattleEffects
2. **鍟嗗簵鏍兼墿灞?* 鈥?澶氶€夊晢鍝?+ 鐙珛 UI 闈㈡澘

### 馃煛 涓紭鍏堢骇

2. **闃典骸鍗曚綅璺ㄥ眰澶嶆椿鏈哄埗** 鈥?闃叉鍚庣画灞傛棤浼欎即鍙敤
3. **BattleFlowController 鐦﹁韩** 鈥?褰撳墠绾?710 琛?
4. **3D 鍗曚綅绮剧伒鍖?* 鈥?billboard sprite 鎴栦綆澶氳竟褰㈡ā鍨嬫浛浠ｇ畝鍗曞嚑浣曚綋

### 馃煝 涓綆浼樺厛绾?

4. ~~**鐩告満璺熼殢骞虫粦杩囨浮**~~ 鈥?鉁?v0.1.64/65 宸插畬鎴?
5. ~~**SettingsPanel 闊抽噺鎺т欢**~~ 鈥?鉁?v0.1.66 宸插畬鎴?

### 馃數 闀挎湡鏂瑰悜

5. ~~**绛夎窛瑙掕壊涓撳睘璐村浘**~~ 鈥?鉁?v0.1.70 鐜╁瑙掕壊宸蹭娇鐢ㄧ簿鐏靛姩鐢?
6. **鏁屾柟瑙掕壊绮剧伒鍖?* 鈥?鏇夸唬绋嬪簭鍖栨晫鏂瑰壀褰?
7. **Crest 钃勫姏姹?+ 楠板瓙鎿嶆帶鏈哄埗**
8. **瀛樻。绯荤粺** 鈥?鏈€灏忓瓨妗?璇绘。

---

## 6. 鏍稿績鏂囦欢绱㈠紩

### 婧愪唬鐮佹枃浠讹紙`Project/Scripts/` 涓嬶級

| 鏂囦欢璺緞 | 鑱岃矗 | 琛屾暟鍙傝€?|
|----------|------|----------|
| `BattleV2/BattleFlowController.gd` | 妫嬬洏灞傛牳蹇冩帶鍒跺櫒锛氶樁娈电鐞?澶氬眰鍦板浘/Boss閿佸畾浼犻€侀棬 | ~693 琛?|
| `BattleV2/CardBattleController.gd` | 鍗＄墝灞傜嫭绔嬫帶鍒跺櫒锛氳兘閲?鍙岀墝鍫?鎸佷箙鐗岀粍/鍗囩骇/6绉嶆晫鏂?Boss | ~540 琛?|
| `BattleV2/BoardManager.gd` | 妫嬬洏鐘舵€侊細9+2 涓牸瀛愬瓧鍏?+ BFS 绉诲姩 | ~150 琛?|
| `BattleV2/BoardGenerator.gd` | 妫嬬洏绋嬪簭鍖栫敓鎴愶紙闈欐€佸伐鍏风被锛?| ~200 琛?|
| `BattleV2/UnitManager.gd` | 鍗曚綅鐘舵€侊細鐢熸垚/绉诲姩/浼ゅ/鍑绘潃 | ~90 琛?|
| `BattleV2/ActionResolver.gd` | 鏀诲嚮鑼冨洿璁＄畻锛堝惈鍦板舰閫傛€у姞鎴愶級 | ~50 琛?|
| `BattleV2/DiceManager.gd` | 鎺烽 + crest 璧勬簮姹犵鐞?| ~60 琛?|
| `BattleV2/BattleAI.gd` | 鏁屾柟 AI锛堜紭鍏堟敾鍑?杩借釜鏈€杩戠帺瀹讹級 | ~80 琛?|
| `BattleV2/BuffManager.gd` | buff 绠＄悊锛坱ick_turn 宸叉帴鍏ワ級 | ~30 琛?|
| `BattleV2/AttackRuleHelper.gd` | 浼ゅ鍏紡 | ~15 琛?|
| `BattleV2/VictoryRuleHelper.gd` | 鑳滆礋鍒ゅ畾锛坔as_hero_unit+has_grunt_units锛?| ~30 琛?|
| `BattleV2/CrestActionHandler.gd` | Crest 娑堣€楁搷浣滐紙浠?BFC 鍓ョ锛?| ~66 琛?|
| `BattleV2/CellEffectHandler.gd` | 鏍煎瓙鏁堟灉澶勭悊锛堜粠 BFC 鍓ョ锛?| ~205 琛?|
| `UI/BoardView.gd` | 妫嬬洏娓叉煋 + 鐐瑰嚮浜や簰 + 鍙嶉鍔ㄧ敾 + 鐩告満璺熼殢 + 绮剧伒鍔ㄧ敾 | ~610 琛?|
| `UI/BoardCellRenderer.gd` | 鏍煎瓙娓叉煋闈欐€佺被锛圥hase 6 鍚庝粎渚涘弬鑰冿級 | ~210 琛?|
| `UI/UnitRenderer.gd` | 鍗曚綅娓叉煋锛坴0.1.66 鍜╁挬鍚ず褰曢鏍硷級 | ~490 琛?|
| `UI/IsoTileRenderer.gd` | 绛夎窛绋嬪簭鍖栨覆鏌撳櫒锛圱ILE_W=192+鐩告満璺熼殢锛?| ~200 琛?|
| `UI/PlayerSpriteAnimator.gd` | 鐜╁绮剧伒鍔ㄧ敾绠＄悊鍣紙4鏂瑰悜 spritesheet锛?| ~70 琛?|
| `UI/DiceRollAnimation.gd` | 鎺烽婕斿嚭锛堜吉3D绛夎窛楠板瓙锛?| ~252 琛?|
| `UI/BattleEffects.gd` | 鎴樻枟鐗规晥闈欐€佺被 | ~103 琛?|
| `UI/DiceDebugPanel.gd` | 妫嬬洏灞?HUD锛坈rest 姹?闃舵/灞傛暟/閮ㄧ讲鎻愮ず锛?| ~540 琛?|
| `UI/CardRenderer.gd` | 鍗＄墝娓叉煋闈欐€佺被锛?绉嶇被鍨嬮厤鑹诧級 | ~233 琛?|
| `UI/CardBattlePanel.gd` | 鍏ㄥ睆鍗＄墝鎴樻枟 UI锛?280x720+绔嬬粯+鎵囧舰鎵嬬墝锛?| ~420 琛?|
| `UI/CardRewardPanel.gd` | 濂栧姳閫夌墝/鍗囩骇闈㈡澘 | ~230 琛?|
| `UI/DeckViewPanel.gd` | 鐗岀粍鏌ョ湅闈㈡澘 | ~160 琛?|
| `UI/CyberStyle.gd` | 缁熶竴璧涘崥鏈嬪厠瑙嗚椋庢牸锛堝叏灞€ class_name锛?| ~149 琛?|
| `UI/CyberBackground.gd` | 鑳屾櫙姘涘洿绯荤粺锛堟笎鍙?缃戞牸+绮掑瓙+鎵弿绾匡級 | ~155 琛?|
| `UI/TransitionOverlay.gd` | 瀹濆彲姊﹀紡鐧惧彾绐楄繃娓★紙CanvasLayer 10锛?| ~110 琛?|
| `UI/BattleCharRenderer.gd` | 鎴樻枟瑙掕壊绔嬬粯娓叉煋锛堢帺瀹?6绉嶆晫鏂癸級 | ~180 琛?|
| `UI/UITransitions.gd` | UI杩囨浮鍔ㄧ敾宸ュ叿绫伙紙popup/close缂撳姩锛?| ~60 琛?|
| `UI/UnitPortraitHUD.gd` | 椤堕儴鍗曚綅澶村儚 HUD | ~130 琛?|
| `UI/SettingsPanel.gd` | 鏄剧ず璁剧疆+闊抽噺鎺т欢闈㈡澘 | ~100 琛?|
| `UI3D/GridMapper3D.gd` | 鏍煎潗鏍団啍3D涓栫晫鍧愭爣杞崲锛堢函鏁板宸ュ叿绫伙級 | ~40 琛?|
| `UI3D/TileMeshFactory3D.gd` | 9绉嶆牸瀛?BoxMesh+StandardMaterial3D 宸ュ巶 | ~120 琛?|
| `UI3D/UnitMeshFactory3D.gd` | 鍗曚綅 CapsuleMesh/CylinderMesh+billboard HP 鏉?| ~130 琛?|
| `UI3D/BoardView3D.gd` | 3D 妫嬬洏瑙嗗浘锛圫ubViewport 宓屽叆+淇″彿鎺ュ彛瀵归綈 BoardView锛?| ~380 琛?|
| `System/AudioManager.gd` | 闊虫晥绠＄悊鍣紙澶氶€氶亾SFX+BGM锛?| ~120 琛?|
| `System/SFXGenerator.gd` | 绋嬪簭鍖栭煶棰戝紩鎿庯紙28绉峉FX+4绉岯GM锛?| ~1100 琛?|
| `Main.gd` | 鍦烘櫙缁勫悎 + 淇″彿涓浆 + 闊虫晥瑙﹀彂 + 鐩告満璺熼殢 + 3D瑙嗗浘璺敱 | ~670 琛?|

### 鏃ュ織鏂囦欢锛坄Logs/` 涓嬶級

| 鏂囦欢 | 鐢ㄩ€?| 鏇存柊棰戠巼 |
|------|------|----------|
| `AI_Employee_Guide_v3.md` | AI 鍛樺伐涓婂矖鎸囦护锛堣涓鸿鑼冿級 | 姣忚疆寮哄埗鏇存柊 |
| `Handoff_Package_latest.md` | 鏈€鏂颁氦鎺ュ寘 | 浜ゆ帴鏃惰鐩?|
| `CyberTao_Migration_Snapshot_zh_v3.md` | 鏈枃浠?鈥?椤圭洰鍏ㄨ矊+鏋舵瀯 | 闃舵鎬ф洿鏂?|
| `Mulerun_Work_Report.md` | 涓婁竴杞簿纭姸鎬?| 姣忚疆瑕嗙洊 |
| `changelog_v0.1.md` | 瀹屾暣鐗堟湰鍘嗗彶 | 姣忚疆杩藉姞 |
| `Board_Card_Battle_Concept_zh.md` | 鍙屽眰鐜╂硶璁捐鏂囨。 | 璁捐鍙樻洿鏃?|
| `Demo_Roadmap_2p5D_zh.md` | 涓暱鏈熻矾绾垮浘 | 闃舵鎬ф洿鏂?|
| `Art_Beautification_Strategy_zh.md` | 缇庢湳缇庡寲鎺ㄨ繘绛栫暐锛?闃舵锛?| 缇庡寲闃舵鍙傝€?|

---

## 7. 鐗堟湰閲岀▼纰戞€昏

| 鐗堟湰 | 閲岀▼纰?|
|------|--------|
| v0.1.0~v0.1.3 | 鍩虹楠ㄦ灦锛堟鐩?鎺烽+绉诲姩+鍥炲悎锛?|
| v0.1.4~v0.1.6 | 鎴樻枟鍩虹锛堟敾鍑?HP+鑳滆礋锛?|
| v0.1.7~v0.1.12 | 浣撻獙澧炲己锛堣缃?鍙嶉+閲嶅紑锛?|
| v0.1.13~v0.1.14 | AI+鍙敜锛堟晫鏂瑰洖鍚?閾鸿矾锛?|
| v0.1.15~v0.1.21 | 妫嬬洏娣卞寲锛堝湴褰?閫傛€?閬撳叿+鎰忓浘锛?|
| v0.1.22~v0.1.24 | 鍙屽眰鍏ュ彛锛堥伃閬囨牸+鏆傚仠+鏍煎瓙浜嬩欢鍖栵級 |
| v0.1.25~v0.1.27 | 鍗＄墝鎴樻枟锛堝師鍨嬧啋涓板瘜鍖栵級 |
| v0.1.28~v0.1.30 | 璋冭瘯+UI+闃舵鏀跺彛 |
| v0.1.31~v0.1.38 | 鍗＄墝娣卞寲锛堟瀯绛?鍗囩骇/Boss/6绉嶆晫鏂?鑳介噺鎴愰暱锛?|
| v0.1.39~v0.1.43 | 绯荤粺瀹屽杽锛圔uffManager鎺ュ叆/BFC鐦﹁韩/9绉嶆牸瀛?澶氬眰鍦板浘/BUG-001淇锛?|
| v0.1.45~v0.1.49 | 缇庡寲 Phase 1~4.1锛堟牸瀛?鍗曚綅/楠板瓙/鍗＄墝/鑳屾櫙 瑙嗚鍗囩骇锛?|
| v0.1.50~v0.1.54 | Boss鏈哄埗+鍗曚綅绮剧畝+鍏ㄥ睆鍗＄墝鎴樻枟鐣岄潰+瑙掕壊绔嬬粯+鐧惧彾绐楄繃娓?|
| v0.1.55~v0.1.60 | UI杩囨浮鍔ㄧ敾+闊虫晥绯荤粺+灞傞棿闅惧害閫掑+绛夎窛璐村浘妫嬬洏+鐩告満璺熼殢+鍏ㄦ柊AI绱犳潗 |
| v0.1.61~v0.1.66 | 绋嬪簭鍖栨鐩樺洖閫€+榧犳爣鎷栨嫿鐩告満+12x12鎵╁睍+澶т笘鐣屽～鍏?闀滃ご浼樺寲+瑙掕壊閲嶆瀯+闊虫晥璁剧疆 |
| v0.1.67~v0.1.70 | 閫愭牸绉诲姩鍔ㄧ敾+鍗＄墝鎷栨嫿鍑虹墝+鍗虫椂浼ゅ鍙嶉+澶村儚HUD+鐜╁绮剧伒鍔ㄧ敾 |
| v0.1.71 | 3D 娓愯繘杩佺Щ P0锛圔oardView3D+SubViewport+F5鍒囨崲鍙岃鍥?3D鐩告満/灏勭嚎妫€娴?楂樹寒/绉诲姩鍔ㄧ敾锛?|
| v0.1.72 | 3D 浜や簰鎵嬫劅淇锛堟嫋鎷藉嵆鏃跺搷搴?闀滃ご璺熼殢閫熷害+杈圭晫闄愬埗+缂╂斁杞村績瀵归綈2D浣撻獙锛?|

---

## 8. 涓€鍙ヨ瘽鐘舵€?

**v0.1.72 鍙屽眰鐜╂硶瀹屾暣闂幆+鍗＄墝娣卞寲绗竴鐗堝畬鎴愩€傛鐩樿蛋浣嶅眰锛?绉嶆牸瀛?闅忔満鐢熸垚+3灞傛帹杩?Boss閿佸畾浼犻€侀棬+鍗曚綅绮剧畝+灞傞棿闅惧害缂╂斁+閫愭牸绉诲姩鍔ㄧ敾+澶村儚HUD锛夊拰鍗＄墝鎴樻枟灞傦紙14绉嶇墝+鍗囩骇+6绉嶆晫鏂?Boss+鑳介噺鎴愰暱+鎸佷箙鐗岀粍+濂栧姳閫夌墝+鎷栨嫿鍑虹墝+鍗虫椂浼ゅ鍙嶉锛夊叏閮ㄧǔ瀹氥€傜瓑璺濈▼搴忓寲妫嬬洏锛圛soTileRenderer锛?榧犳爣鎷栨嫿鐩告満+缂╂斁+12x12妫嬬洏+瑙掕壊褰㈣薄閲嶆瀯锛堝挬鍜╁惎绀哄綍椋庢牸锛?鐜╁绮剧伒鍔ㄧ敾锛?鏂瑰悜spritesheet锛?闊虫晥绯荤粺+鍏ㄥ睆鐙珛鍗＄墝鎴樻枟鐣岄潰+瑙掕壊绔嬬粯+瀹濆彲姊﹀紡鐧惧彾绐楄繃娓?璧涘崥鏈嬪厠鍏ㄩ潰缇庡寲锛圥hase 1~6锛夊凡瀹屾垚銆?D 娓愯繘杩佺Щ P0 瀹屾垚锛圔oardView3D+SubViewport+F5鍒囨崲+3D鐩告満/灏勭嚎妫€娴?楂樹寒/绉诲姩鍔ㄧ敾锛夛紝v0.1.72 瀹屾垚 3D 浜や簰鎵嬫劅淇锛堟嫋鎷藉嵆鏃跺搷搴?闀滃ご璺熼殢閫熷害+杈圭晫闄愬埗+缂╂斁杞村績瀵归綈2D浣撻獙锛屽弽棣堟柟娉曟殏涓烘々鍑芥暟锛夈€備笅涓€姝ワ細3D 鍙嶉绯荤粺鎴栧晢搴楁牸鎵╁睍銆?*

