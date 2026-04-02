# CyberTao: Dice Beast Protocol Changelog

## v0.1.105 - 2026-04-02

### 修复
- 重写 `AI_Employee_Guide_v3.md`，清理残留乱码并同步当前接手流程
- 重写 `Art_Beautification_Strategy_zh.md`，替换过时的旧阶段策略正文
- 重写 `CyberTao_Migration_Snapshot_zh_v3.md`，同步当前版本、结构、模块和风险说明
- 修复最近几版 changelog 顶部条目的可读性，避免接手时直接撞上乱码

### 修改
- `Handoff_Package_latest.md`：更新到 v0.1.105，并记录当前已消除的交接风险
- `Mulerun_Work_Report.md`：覆盖为本轮工作报告

### 备注
- 本轮没有改动游戏逻辑、数值或界面行为
- 当前已清理的是“接手主路径”文档；更早历史归档如需精修，应另开轮次处理

## v0.1.104 - 2026-04-02

### 修复
- 对 `AI_Employee_Guide_v3.md`、`Art_Beautification_Strategy_zh.md`、`Mulerun_Work_Report.md` 进行了保守编码修复，恢复核心中文内容可读性

### 修改
- `AI_Employee_Guide_v3.md`：重写文档顶部说明，明确当前执行应以 Handoff / Work Report / Changelog 为准
- `Handoff_Package_latest.md`：同步当前版本到 v0.1.104，并记录日志编码修复状态
- `CyberTao_Migration_Snapshot_zh_v3.md`：同步顶部提示中的真实项目基线版本

### 备注
- 本轮没有改动游戏逻辑或界面行为
- 日志正文仍残留少量历史损坏字符，后续建议单独开轮次精修

## v0.1.103 - 2026-04-02

### 修改
- `IsoTileRenderer.gd`：新增固定外场边框台座与四角结构件，强化“棋盘舞台”层次

### 调整
- 取消 2D / 3D 拖拽结束后的自动回正行为，避免手感被强行拉回
  - `BoardView.gd`：移除选中状态下 `_drag_offset` 的自动 lerp 回零
  - `BoardView3D.gd`：移除 `_drag_offset_accumulated` 的空闲自动回正

## v0.1.102 - 2026-04-02

### 修改
- `IsoTileRenderer.gd`：为棋盘外背景补充可视化装饰，不再保持纯空白
  - 四角赛博面板
  - 左右能量节点
  - 远景条带装饰
- 保持棋盘主体可读性，外场只负责低强度氛围和区域区分

## v0.1.101 - 2026-04-02

### 修复
- `BoardView.gd`：选中单位时持续跟随并居中，避免角色跑到边角导致构图异常
- `BoardView.gd`：选中单位状态下逐步回收拖拽偏移，保持棋盘与角色留在视口中心
- `IsoTileRenderer.gd`：提亮外场底色并加入轻量警示斜线，强化棋盘内外区分

### 说明
- 2D 视图继续以方正、稳定和可读为优先，不再启用会导致歪斜的伪透视旋转

## v0.1.100 - 2026-04-02

### 修复
- `BoardView.gd`：移除 2D 伪视角输入路径（中键 / Alt + 右键 orbit），恢复稳定构图
- `BoardView.gd`：启动时强制重置 `_view_pitch_offset` / `_view_yaw_offset = 0`
- `BoardView.gd`：拖拽逻辑回归“仅右键平移”，避免 orbit 状态干扰导致棋盘倾斜与偏移

### 根因
- 2D 伪视角 offset 与自动回正、镜头跟随叠加后，会让棋盘出现“歪斜 + 松手回怪位置”的问题

## v0.1.99 - 2026-04-02

### 淇锛?D瑙嗚鎺у埗鍏煎 + 妫嬬洏涓績婕傜Щ + 澶栧満浠嶅亸榛戯級
- `BoardView.gd`锛氱┖闂叉椂瀵?`_drag_offset` 鍋氱紦鎱㈣“鍑忥紝闄嶄綆闀挎椂闂存父鐜╁悗妫嬬洏鍋忕涓績闂
- `BoardView3D.gd`锛氱┖闂叉椂瀵?`_drag_offset_accumulated` 鍋氱紦鎱㈠洖姝ｏ紝鍑忓皯 3D 婕傜Щ
- `IsoTileRenderer.gd`锛氬鍦哄钩鍙板簳鑹蹭笌杈圭紭楂樺厜浜害鎻愰珮锛屽寮衡€滄鐩樺鑳屾櫙鍖哄垎鈥濆彲瑙佹€?

### 璇存槑
- 2D 涓敭浜嬩欢鍦ㄩ儴鍒嗛紶鏍囦笂浠嶅彲鑳戒笉绋冲畾锛屽凡淇濈暀 `Alt/Shift + 鍙抽敭` 瑙嗚鎺у埗澶囩敤璺緞

## v0.1.98 - 2026-04-02

### 淇锛?D涓敭鏃犲弽搴?+ 妫嬬洏澶栦粛鏄鹃粦杈癸級
- `BoardView.gd`锛?D 瑙嗚杈撳叆澧炲姞鍏煎璺緞
  - 涓敭鎷栨嫿浠嶅彲璋冭瑙?
  - 鏂板 `Alt/Shift + 鍙抽敭鎷栨嫿` 浣滀负澶囩敤瑙嗚鎺у埗锛堥儴鍒嗛紶鏍囦腑閿簨浠朵涪澶卞満鏅級
- `BoardView.gd`锛氭鐩樺眰鍏堥摵搴曡壊锛岄伩鍏嶅閮ㄥ尯鍩熷嚭鐜扮函榛?
- `BoardView.gd`锛氶檷浣庤竟缂樻殫瑙掑己搴︼紝鍑忓皯鈥滈粦杈瑰寘瑁规劅鈥?

### 澶囨敞
- 2D 鎿嶄綔鐜板湪涓猴細
  - 鍙抽敭鎷栨嫿锛氬钩绉?
  - 涓敭鎷栨嫿锛氳瑙掑亸绉?
  - Alt/Shift+鍙抽敭鎷栨嫿锛氳瑙掑亸绉伙紙鍏煎锛?

## v0.1.97 - 2026-04-02

### 淇敼锛?D涓敭瑙嗚鐢熸晥 + 妫嬬洏澶栬儗鏅尯鍒嗭級
- `BoardView.gd`锛氫腑閿嫋鎷芥敼涓烘槑纭€?D瑙嗚鎺у埗鈥?
  - 宸﹀彸鎷栵細`_view_yaw_offset`
  - 涓婁笅鎷栵細`_view_pitch_offset`
  - 涓庡彸閿钩绉诲垎绂?
- `IsoTileRenderer.gd`锛氱Щ闄ゆ鐩樺缁х画閾鸿鐜鏍煎瓙鐨勫仛娉?
- `IsoTileRenderer.gd`锛氭柊澧?`_draw_board_platform_bg()`锛屾鐩樺鏀逛负鐙珛鑸炲彴鑳屾櫙鍖猴紙绫讳技鎴樺満澶栧満鍦帮級

### 淇
- **闂1**锛?D 涓敭鎷栨嫿浣撴劅涓嶆槑鏄撅紝涓嶅儚 3D 璋冭瑙?
- **闂2**锛氭鐩樺浠嶅儚寤跺睍骞抽潰锛屼笉绗﹀悎鈥滃閮ㄨ儗鏅尯鍒嗏€濋鏈?

## v0.1.96 - 2026-04-02

### 淇锛?D 澶栫幆鍦板彴杩愯鏃跺穿婧冿級
- `BoardView3D.gd`锛氱Щ闄ゅ `MeshInstance3D.modulate` 鐨勯潪娉曡祴鍊硷紙Godot 4 涓灞炴€т笉鍙敤锛?
- 鏀逛负閫氳繃澶嶅埗 `StandardMaterial3D` 骞朵笅璋?`albedo_color/emission_energy_multiplier` 瀹炵幇澶栫幆鏆楀寲

### 鏍瑰洜
- 澶栫幆 ambient tile 鏆楀寲浣跨敤浜?`tile_node.modulate = Color(...)`锛岃Е鍙戯細
  `Invalid assignment of property or key 'modulate' on a base object of type 'MeshInstance3D'`

## v0.1.95 - 2026-04-02

### 淇敼锛?D涓敭瑙嗚 + 3D娌夋蹈澶栧満 + 杩滆窛鍙鎬у姞寮猴級
- `BoardView.gd`锛氭柊澧?2D 涓敭鎸変綇鎷栨嫿瑙嗚鎺у埗
  - 涓婁笅鎷栵細淇话鍋忕Щ锛堥€氳繃瑙嗗彛涓績 Y 鍋忕Щ妯℃嫙锛?
  - 宸﹀彸鎷栵細缂╂斁寰皟
- `BoardView3D.gd`锛氭鐩橀噸寤烘椂鏂板澶栫幆鐜鍦板彴锛坅mbient pad锛夛紝娑堥櫎妫嬬洏澶栭粦杈瑰壊瑁傛劅
- `BoardView3D.gd`锛氳繙璺濆崟浣嶅姩鎬佺缉鏀句笂闄愮户缁彁楂橈紝鏈€杩滆瑙掓洿瀹规槗鐪嬫竻鍗曚綅
- `TileMeshFactory3D.gd`锛氫笂涓€鐗堝姛鑳芥牸 3D 鏍囪瘑缁х画娌跨敤锛屽鐜湴鍙颁笌涓绘鐩樺舰鎴愬眰娆″姣?

### 淇
- **闂1**锛?D 鏈€杩滆窛绂诲崟浣嶄粛涓嶆槑鏄?
- **闂2**锛?D 妯″紡缂哄皯涓敭瑙嗚璋冭妭
- **闂3**锛氭鐩樺榛戣壊鑳屾櫙娌夋蹈鎰熷樊

## v0.1.94 - 2026-04-02

### 淇敼锛?D 杩滆窛鍙鎬?+ 涓敭瑙嗚鎺у埗 + 鍔熻兘鏍肩珛浣撳寲锛?
- `BoardView3D.gd`锛氭柊澧炰腑閿寜浣忔嫋鎷借瑙掑姛鑳斤紙Pitch + Yaw锛?
- `BoardView3D.gd`锛氬彸閿繚鐣欏钩绉伙紱涓敭鐙珛瑙嗚鏃嬭浆锛屼簰涓嶅啿绐?
- `BoardView3D.gd`锛氳繙璺濆崟浣嶅姩鎬佺缉鏀惧寮猴紙鏈€澶у€嶇巼鎻愬崌锛夛紝鏀瑰杽鏈€杩滆窛绂讳笉鍙
- `UnitMeshFactory3D.gd`锛氱簿鐏靛熀鍑嗗昂瀵稿井璋冿紝閰嶅悎鍔ㄦ€佺缉鏀鹃伩鍏嶈繎鏅垎灞?
- `TileMeshFactory3D.gd`锛氬姛鑳芥牸鏂板 3D 鏍囪瘑鐗╋紙绠变綋/妫辨煴/鍦嗘煴锛夛紝涓嶅啀鍙槸骞抽潰鑹插潡

### 淇
- **闂1**锛?D 鎷夊埌鏈€杩滃崟浣嶄粛涓嶅彲瑙?
- **闂2**锛氱己灏戜腑閿瑙掕皟鏁?
- **闂3**锛氭鐩樺姛鑳芥牸缂轰箯 3D 浣撳潡杈ㄨ瘑

## v0.1.93 - 2026-04-02

### 淇锛?D鍗曚綅杩戞櫙婧㈠嚭灞忓箷锛?
- `UnitMeshFactory3D.gd`锛氬叧闂?`Sprite3D.fixed_size`锛坱rue鈫抐alse锛夛紝閬垮厤杩戞櫙鍥哄畾灞忓箷灏哄瀵艰嚧瑙掕壊宸ㄥぇ鍖?
- `UnitMeshFactory3D.gd`锛歚SPRITE_PIXEL_SIZE` 浠?0.013 鍥炶皟鍒?0.0105
- `BoardView3D.gd`锛氭柊澧?`_update_unit_readability_scale()`锛屾寜鐩告満璺濈鍔ㄦ€佺缉鏀惧崟浣嶏紙杩滃鏇村ぇ銆佽繎澶勬甯革級

### 鏍瑰洜
- v0.1.92 浣跨敤 `fixed_size=true` 铏芥彁鍗囪繙璺濆彲璇绘€э紝浣嗕細鍦ㄨ繎鏅€犳垚灞忓箷绾ф斁澶э紝鍑虹幇瑙掕壊婧㈠嚭

## v0.1.92 - 2026-04-02

### 淇敼锛?D 杩滆窛绂诲崟浣嶅彲璇绘€т慨澶嶏級
- `UnitMeshFactory3D.gd`锛歚Sprite3D.fixed_size = true`锛屽崟浣嶅湪鎷夎繙鏃朵繚鎸佸彲璇诲睆骞曞昂瀵?
- `UnitMeshFactory3D.gd`锛歚SPRITE_PIXEL_SIZE` 鐢?`0.009/0.013` 浣撶郴涓婅皟鍒?`0.013`锛屾彁鍗囦腑杩滆窛绂昏鲸璇?

### 淇
- **闂**锛?D 妯″紡鎷夎繙鍚庡崟浣嶅彂榛?杩囧皬锛岀湅涓嶆竻锛涢渶瑕佹媺寰堣繎鎵嶇湅鍒板舰璞?
- **澶勭悊**锛氭敼涓哄浐瀹氬睆骞曞昂瀵?billboard + 閫傚害鏀惧ぇ鍩哄噯鍍忕礌灏哄锛屾媺杩滄椂涓嶅啀鈥滅缉鎴愰粦鐐光€?

## v0.1.91 - 2026-04-02

### 淇敼锛?D 鍗曚綅缇庢湳鍚屾鍍忕礌閲嶇粯锛?
- `UnitRenderer.gd`锛?D 绛夎窛鍗曚綅缁樺埗鏀逛负浼樺厛澶嶇敤 `UnitMeshFactory3D` 鐨勫儚绱犵汗鐞嗭紙鐜╁/鍙敜/鏁屾柟 encounter 鏄犲皠锛?
- `draw_full_unit_iso`锛氫笉鍐嶉粯璁よ蛋鏃?Q 鐗堢煝閲忚鑹诧紝鏀逛负鍍忕礌璐村浘缁樺埗 + 鑴氬簳寰厜
- 淇濈暀鏃х煝閲忚矾寰勪綔涓虹汗鐞嗗紓甯告椂 fallback

### 淇
- **闂**锛氱敤鎴峰弽棣?2D 瑙嗗浘鍗曚綅浠嶆槸鏃ч鏍尖€滃緢涓戔€?鈥斺€?鏍瑰洜鏄箣鍓嶄粎鏀逛簡 3D 涓庡崱鐗屾垬鏂楃珛缁橈紝2D 浠嶈蛋鏃?`UnitRenderer` 鐭㈤噺缁樺埗

## v0.1.90 - 2026-04-02

### 淇锛堝崱鐗屾垬鏂楃珛缁樻湭鍚屾鏂板儚绱犳晫鏂癸級
- `BattleCharRenderer.gd`锛氬崱鐗屾垬鏂楄鑹茬粯鍒舵敼涓轰紭鍏堝鐢?`UnitMeshFactory3D` 鐨勫儚绱犵汗鐞嗙紦瀛?
- 鐜╁绔嬬粯鏀逛负浣跨敤 `_gen_player_hero()` 鍍忕礌绾圭悊
- 鏁屾柟绔嬬粯鏀逛负鎸?`encounter_id` 浣跨敤 `_gen_enemy_by_id()` 鍍忕礌绾圭悊

### 鏍瑰洜
- v0.1.89 浠呴噸缁樹簡 3D 妫嬬洏鍗曚綅绾圭悊鐢熸垚鍣紙UnitMeshFactory3D锛?
- 浣犳埅鍥炬墍鍦ㄧ殑鍗＄墝鎴樻枟鐣岄潰浣跨敤鐨勬槸 `BattleCharRenderer` 鐙珛鐭㈤噺绔嬬粯璺緞锛屽洜姝よ瑙夌湅璧锋潵鈥滄病鍙樺寲鈥?

## v0.1.89 - 2026-04-02

### 淇敼锛堝儚绱犵編鏈噸璁捐 P0 - 鏁屾柟绗竴鎵癸級
- `UnitMeshFactory3D.gd`锛氶噸缁樻晫鏂?encounter_01~04 绋嬪簭鍖栧儚绱犲舰璞★紙GBA椋庝綋鍧楁瘮渚嬨€侀厤鑹插眰绾с€佽疆寤撻珮鍏夛級
- 绗竴鎵瑰畬鎴愶細
  - `encounter_01` 寮傚父鍝ㄥ叺 鈫?澶уご鏈虹敳鍏甸鏍?
  - `encounter_02` 璧涘崥娓搁瓊 鈫?鏂楃骞界伒椋庢牸
  - `encounter_03` 鏆楃綉鐖櫕 鈫?鐢插３铔涢鏍?
  - `encounter_04` 鑴夊啿鐚庢墜 鈫?杩呮嵎鍒╃埅鍏介鏍?

### 澶囨敞
- 鏈疆鍙敼绗竴鎵规晫鏂癸紙01~04锛夛紝浣滀负鏁村缇庢湳椋庢牸鍩虹嚎
- 涓嬩竴杞皢鎸夊悓椋庢牸缁х画閲嶇粯 05~07 + Boss锛屽苟鍚屾 UI/鍗＄墝瑙嗚璇█

## v0.1.88 - 2026-04-02

### 淇敼锛?D 鍙鎬т笌绔嬩綋鎰?+ 2D/3D 鍒囨崲鐗规晥锛?
- `UnitMeshFactory3D.gd`锛氭彁楂樼簿鐏靛彲瑙佹€хǔ瀹氭€э紙`alpha_scissor_threshold` 0.4鈫?.25锛屽己鍒剁櫧鑹?modulate锛岀汗鐞嗙┖鍊煎厹搴曚负榛樿鏁屾柟绾圭悊锛?
- `TileMeshFactory3D.gd`锛氭柊澧?`_get_tile_lift()`锛屽姛鑳芥牸娣诲姞棰濆鎶崌锛坋ncounter/portal 鏇撮珮锛宻hop/chest/item/event/heal/trap 涓瓑鎶崌锛夛紝澧炲己绔嬩綋杈ㄨ瘑
- `Main.gd`锛氭柊澧?2D/3D 瑙嗗浘鍒囨崲闇撹櫣杩峰够闂儊鐗规晥灞傦紙ColorRect + Tween锛?

### 淇
- **BUG**锛?D 妯″紡涓嬪崟浣嶅嚭鐜伴粦鑹蹭笉鍙/闅句互璇嗗埆 鈥斺€?澧炲姞绾圭悊绌哄€煎厹搴曚笌閫忔槑闃堝€兼斁瀹藉悗鏀瑰杽
- **浣撻獙闂**锛?D/3D 鍒囨崲缂哄皯杩囨浮鍙嶉 鈥斺€?鏂板鐐厜鍒囨崲鐗规晥

### 澶囨敞
- 鏈疆浼樺厛鍋氬揩閫熷彲鎰熺煡浼樺寲锛屽悗缁彲缁х画鍗囩骇涓哄睆骞曟壄鏇?鑹叉暎 shader 绾у埆鍒囨崲鐗规晥

## v0.1.87 - 2026-04-02

### 鏂板
- 寮曞叆鐢ㄦ埛鎻愪緵澶栭儴 BGM 鏂囦欢锛歚Project/Audio/bgm_tension_fast.mp3`

### 淇敼
- `AudioManager.gd`锛欱GM 鍔犺浇绛栫暐鏀逛负鈥滀紭鍏堝閮ㄩ煶杞紝澶辫触鍥為€€绋嬪簭鍖栫敓鎴愨€?
- `AudioManager.gd`锛歚bgm_battle / bgm_map / bgm_boss / bgm_title` 鏆傜粺涓€鏄犲皠鍒板閮ㄩ煶杞?`res://Audio/bgm_tension_fast.mp3`

### 澶囨敞
- 褰撳墠涓哄揩閫熸琛€鏂规锛堝厛鐢ㄧ敤鎴锋彁渚?BGM 瑕嗙洊鍒鸿€崇▼搴忓寲鏇茬洰锛?
- 鍚庣画鍙寜鍦烘櫙鎷嗗垎涓嶅悓澶栭儴闊宠建锛岀▼搴忓寲缁х画浣滀负 fallback

## v0.1.86 - 2026-04-02

### 淇敼锛圔GM/SFX 鍚劅鏌斿寲锛岄檷浣庡埡鑰冲害锛?
- `AudioManager.gd`锛氶粯璁ら煶閲忎笅璋冿紙BGM -12dB 鈫?-18dB锛孲FX -6dB 鈫?-12dB锛?
- `SettingsPanel.gd`锛氶煶閲忔粦鍧楅粯璁ゅ€间笅璋冿紙BGM 25% 鈫?18%锛孲FX 50% 鈫?35%锛夛紝閲嶇疆榛樿鍚屾涓嬭皟
- `AudioManager.gd`锛氭浛鎹㈤珮鍒鸿€崇紦瀛樻槧灏勶細
  - `dice_roll` 浠?`generate_cyber_glitch_sfx()` 鏀逛负鏇存煍鍜岀殑 `generate_draw_sfx()`
  - `boss_attack` 浠?`generate_boss_attack_sfx()` 鏀逛负 `generate_attack_sfx()`
  - `player_hurt` 鏀圭敤杈冩俯鍜岀殑 `generate_enemy_hurt_sfx()`
- `SFXGenerator.gd`锛? 鏉′富 BGM 鍥炶矾锛坆attle/title/map/boss锛夐檷纭害澶勭悊锛?
  - 涓绘棆寰嬩粠鏂规尝/绐勮剦鍐叉敼涓轰笁瑙掓尝锛堥檷浣庨娇闊筹級
  - 榧撶粍鍣０锛坰nare/hat锛夐煶閲忎笅璋?
  - 鎬昏緭鍑哄鐩婁笅璋冿紙battle/title/map/boss锛?

### 淇
- **浣撻獙闂**锛氱▼搴忓寲 BGM/SFX 楂橀鎴愬垎鍜屾暣浣撳搷搴﹁繃楂橈紝闀挎湡鍚劅鍒鸿€崇柌鍔筹紱鏈疆閫氳繃娉㈠舰/鍣０/澧炵泭涓夊眰闄嶅櫔澶勭悊缂撹В鈥滅偢鑰斥€濋棶棰?

### 澶囨敞
- 鏈疆鏈紩鍏ュ閮ㄩ煶棰戠礌鏉愶紝浠嶄繚鎸佲€滅函绋嬪簭鍖栫敓鎴愨€濇灦鏋?
- 濡傞渶杩涗竴姝ユ帴杩戝晢鐢ㄥ惉鎰燂紝涓嬩竴姝ュ缓璁敮鎸佸彲閫夊閮?BGM 璧勬簮鍖咃紙淇濈暀绋嬪簭鍖?fallback锛?

## v0.1.85 - 2026-04-02

### 淇敼锛?D 妯″紡妫嬬洏鎷栨嫿鑷敱搴︿慨姝ｏ級
- `BoardView3D.gd`锛氭斁瀹?`_clamp_drag_offset()` 鐨勬嫋鎷借竟鐣岀瓥鐣ワ紝淇 3D 瑙嗗浘鎷栨嫿鍒版煇浣嶇疆鍚庘€滃崱浣?鎷変笉鍔ㄢ€濈殑鎵嬫劅闂
- 鎷栨嫿鏈€澶у亸绉讳粠鏃х増鍥哄畾 `half_board * 0.5`锛?2x12 涓嬩粎 卤6锛夋敼涓哄姩鎬佽竟鐣岋細`half_board * 2.0 + zoom_extra * 0.8`

### 淇
- **BUG**锛?D 妯″紡妫嬬洏鎷栨嫿鑼冨洿杩囧皬锛屾棤娉曞儚 2D 涓€鏍疯嚜鐢卞钩绉?鈥斺€?鏍瑰洜鏄?v0.1.72 鐨勮竟鐣屽す绱х郴鏁拌繃浜庝繚瀹?

### 澶囨敞
- 鏈疆浠呰皟鏁?3D 鐩告満鎷栨嫿杈圭晫锛屼笉鏀瑰姩 2D BoardView 鎷栨嫿閫昏緫
- 浠嶄繚鐣欒竟鐣屼繚鎶わ紝閬垮厤鐩告満鏃犻檺婕傜Щ鍒拌繙绂绘鐩樺尯鍩?

## v0.1.84 - 2026-04-02

### 淇敼锛堝崱鐗屾垬鏂楁墜鎰熷洖璋冿細鎷栨嫿鍧愭爣绯讳笌鎮仠绋冲畾鎬э級
- `CardBattlePanel.gd`锛氭嫋鎷藉潗鏍囦粠 `global_position` 鏀逛负 `_card_container` 鏈湴鍧愭爣锛岄伩鍏嶇獥鍙ｄ綅缃?杈撳叆鍧愭爣绯诲樊寮傚鑷村崱鐗岀灛绉诲埌椤堕儴
- `CardBattlePanel.gd`锛氬嚭鐗屽垽瀹氬尯鍩熸敼鐢ㄦ湰鍦伴紶鏍?Y 鍊煎垽鏂紙`local_mouse.y < PLAY_ZONE_Y`锛夛紝涓?UI 瑙嗚鍖哄煙涓€鑷?
- `CardBattlePanel.gd`锛氭偓鍋滃姩鐢绘敼涓哄熀浜庡浐瀹?`base_pos` 鍏冩暟鎹紝涓嶅啀渚濊禆涓存椂 `saved_y`锛岄伩鍏嶆偓鍋滄姈鍔ㄤ笌绱婕傜Щ
- `CardBattlePanel.gd`锛氬彇娑堟嫋鎷芥敼涓?0.12s tween 鍥炲脊锛堜綅缃?鏃嬭浆/缂╂斁鍚屾锛夛紝鎻愬崌鈥滀笣婊戞劅鈥?

### 淇
- **BUG**锛氶儴鍒嗗満鏅笅鎷栨嫿鎵嬬墝浼氣€滆嚜鍔ㄩ鍒伴《閮?鍋忕Щ寮傚父鈥?鈥斺€?鏍瑰洜鏄叏灞€鍧愭爣涓庢湰鍦板潗鏍囨贩鐢紙`event.global_position` vs card container 鏈湴鍧愭爣锛?
- **鎵嬫劅闂**锛氭偓鍋?鍙栨秷鎷栨嫿瀛樺湪鐢熺‖璺冲彉锛屽凡鏀逛负鍩轰簬鍩哄噯浣嶇疆鐨勭ǔ瀹氬姩鐢?

### 澶囨敞
- 鏈疆浠呰皟鏁?`CardBattlePanel` 琛ㄧ幇灞備氦浜掞紝涓嶆敼鍔?`CardBattleController` 鍗＄墝缁撶畻閫昏緫
- 鐩爣涓哄厛瀵归綈鏃ч」鐩€滃彲鎺с€佺ǔ瀹氥€侀『婊戔€濈殑鎷栨嫿鎵嬫劅

## v0.1.83 - 2026-04-02

### 鏂板
- **鍟嗗簵鏁版嵁娓呮礂鎵嬪姩閫夌墝 UI**锛氳喘涔?`remove_card` 鏃朵笉鍐嶈嚜鍔ㄧЩ闄ゆ渶寮辩墝锛屾敼涓哄脊鍑哄崱鐗屽垪琛紝鐢辩帺瀹舵墜鍔ㄩ€夋嫨瑕佺Щ闄ょ殑鍗＄墝
- ShopPanel 鏂板绉荤墝閫夋嫨寮圭獥锛堥伄缃╁眰 + 婊氬姩鍒楄〃 + 鍗曞崱绉婚櫎鎸夐挳 + 鍙栨秷鎸夐挳锛?

### 淇敼
- `ShopPanel.gd`锛歚remove_card` 鍟嗗搧鎻忚堪鏇存柊涓衡€滄墜鍔ㄩ€夋嫨绉婚櫎鐗岀粍涓殑1寮犵墝鈥?
- `ShopPanel.gd`锛氳喘涔版墽琛屾帴鍙?`_execute_purchase(item, remove_deck_index=-1)` 澧炲姞鍙€?deck index 鍙傛暟锛岀敤浜庢墜鍔ㄩ€夌墝缁撶畻
- `ShopPanel.gd`锛氳喘涔板弽棣堢粺涓€璧?`_apply_purchase_result()`锛屾垚鍔?澶辫触鎻愮ず涓庨鑹插弽棣堜繚鎸佷竴鑷?
- `ShopPanel.gd`锛歚_refresh_display()` 涓嶅啀娓呯┖鐘舵€佹枃鏈紝閬垮厤鍒氳喘涔板畬鎻愮ず琚珛鍗宠鐩?

### 淇
- **浜や簰缂洪櫡**锛歚remove_card` 鍘熷疄鐜版寜 value/cost 鑷姩鍒犫€滄渶寮辩墝鈥濓紝鍓ュず鐜╁鏋勭瓚鍐崇瓥锛涚幇鏀逛负鐜╁鏄惧紡閫夋嫨锛岀鍚堝晢搴楃瓥鐣ヨ璁＄洰鏍?

### 澶囨敞
- 鎵ｈ垂鏃舵満淇濇寔涓衡€滅‘璁ょЩ闄ゅ悗鍐嶆墸璐光€濓紝鍙栨秷閫夋嫨涓嶄細娑堣€?crest
- 淇濈暀鍘熼檺鍒讹細鐗岀粍 <=3 寮犳椂锛宍remove_card` 涓嶅彲璐拱

## v0.1.82 - 2026-04-01

### 淇敼锛?D 娓叉煋璺緞 spritesheet 绉婚櫎 鈥?淇榛樿妯″紡浠嶆樉绀烘棫鎻掑浘 BUG锛?
- **BoardView.gd**锛氱Щ闄?PlayerSpriteAnimator 渚濊禆锛坃sprite_animator 鍙橀噺/鍒濆鍖?tick/鏂瑰悜璁剧疆/鍋滄/draw 鍒嗘敮锛夛紝鐜╁鍗曚綅鏀逛负涓庢晫鏂圭浉鍚岀殑 UnitRenderer 绋嬪簭鍖栨覆鏌撹矾寰?
- 绉婚櫎 `_draw_player_sprite()` 鏂规硶锛坰pritesheet 绾圭悊鍖哄煙娓叉煋+HP鏉?閫変腑鍏夌幆锛?
- `play_move_step()` / `_on_move_step_finished()` 绮剧畝锛氫笉鍐嶈缃?鍋滄绮剧伒鍔ㄧ敾
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.82

### 淇
- **BUG**: 榛樿 2D 妯″紡涓嬬帺瀹惰鑹蹭粛鏄剧ず spritesheet 鎻掑浘鑰岄潪绋嬪簭鍖栧儚绱犻鏍?鈥?v0.1.81 浠呬慨鏀逛簡 3D 娓叉煋璺緞锛圲nitMeshFactory3D锛夛紝閬楁紡浜?2D 娓叉煋璺緞锛圔oardView+PlayerSpriteAnimator锛?

### 澶囨敞
- PlayerSpriteAnimator.gd 鏂囦欢浠嶅瓨鍦ㄤ絾宸叉棤浠讳綍寮曠敤鏂癸紙鍙湪鍚庣画娓呯悊杞瀹夊叏鍒犻櫎锛?
- 2D 妯″紡鐜颁娇鐢?UnitRenderer 绋嬪簭鍖栨覆鏌擄紙鍜╁挬鍚ず褰?Q 鐗堥鏍硷級锛?D 妯″紡浣跨敤 UnitMeshFactory3D 绋嬪簭鍖栨覆鏌擄紙BGA 瀹濆彲姊﹀儚绱犻鏍硷級
- 涓ょ妯″紡鍧囨棤澶栭儴缇庢湳璧勬簮渚濊禆

## v0.1.81 - 2026-04-01

### 淇敼锛堝叏鍗曚綅绋嬪簭鍖?BGA 瀹濆彲姊﹀儚绱犻鏍奸噸鏋勶級
- **UnitMeshFactory3D 瀹屽叏閲嶅啓**锛氱Щ闄ゆ墍鏈?spritesheet 澶栭儴 PNG 璧勬簮渚濊禆锛屾敼涓哄叏鍗曚綅绋嬪簭鍖栧儚绱犻鏍肩敓鎴?
- 鏂板 12 涓嫭绔嬬▼搴忓寲鍍忕礌鐢熺墿鐢熸垚鍣紙BGA 瀹濆彲姊﹂鏍硷細澶уご姣斾緥+绮椾綋杞粨+璧涘崥鏈嬪厠鍙戝厜锛夛細
  - 鍒€鐩剧嫍锛堢帺瀹惰嫳闆勶級锛氳摑鑹茶禌鍗氱姮鎴樺＋锛屾寔鍒€+鐩?
  - 璧涘崥灏忕簿鐏碉紙鍙敜浼欎即锛夛細闈掕壊椋炶灏忎紮浼?
  - 寮傚父鍝ㄥ叺銆佽禌鍗氭父榄傘€佹殫缃戠埇铏€佽剦鍐茬寧鎵嬨€佹暟鎹菇鐏点€侀噺瀛愬垎瑁備綋銆佽禌鍗氬帆鍖伙紙7绉嶉伃閬囨晫鏂癸級
  - 闆跺彿鍗忚锛圔oss锛夛細澶у瀷鏆楃孩閾犵敳瀹炰綋
  - 榛樿鍥為€€鏁屾柟
- 缁樺浘绯荤粺锛?2脳32 閫昏緫鍍忕礌缃戞牸锛?28px 绾圭悊锛?脳4 瀹為檯鍍忕礌/閫昏緫鍍忕礌锛夛紝鍚嚜鍔ㄥ彂鍏夎疆寤?
- **BoardView3D 绮剧伒鍔ㄧ敾绉婚櫎**锛氬垹闄?_update_sprite_animation() 鍙婄浉鍏冲彉閲忥紙_sprite_anim_accum/frame_idx/move_dir锛夛紝绮剧畝 play_move_step/finish 閫昏緫
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.81

### 鍒犻櫎
- UnitMeshFactory3D锛歴pritesheet 鍔犺浇锛?鏂瑰悜 PNG 璺緞锛夈€佸抚鍔ㄧ敾鎺ュ彛锛坕s_spritesheet_unit/set_sprite_direction/set_sprite_frame/reset_sprite_idle锛夈€佹棫鐗堢畝鍗曞嚑浣曞浘鏍囩敓鎴愬櫒锛坃generate_icon锛?
- BoardView3D锛氱簿鐏靛抚鍔ㄧ敾绯荤粺锛堜笉鍐嶉渶瑕?PlayerSpriteAnimator 鐨勬柟鍚戞娴嬶級

### 澶囨敞
- 鏈疆婧愪簬鐢ㄦ埛鎸囩ず锛?鏁屾柟缇庢湳璧勬簮鍏堝彇娑堬紝涓昏鑹?spritesheet 绱犳潗涔熶笉鐢ㄤ簡锛屾敼涓虹▼搴忓寲璁捐锛屽弬鑰?BGA 瀹濆彲姊﹀儚绱犺鑹叉€墿璁捐"
- 鎵€鏈夊崟浣嶇幇涓洪潤鎬佺汗鐞嗭紙鏃犲抚鍔ㄧ敾锛夛紝濡傞渶琛岃蛋琛ㄧ幇鍙悗缁坊鍔犲脊璺?tween
- PlayerSpriteAnimator.gd 鏂囦欢浠嶅瓨鍦ㄤ絾宸叉棤寮曠敤锛堝彲鍦ㄥ悗缁竻鐞嗭級
- 鏁屾柟绾圭悊鎸?encounter_id 寤惰繜鐢熸垚骞剁紦瀛橈紝棣栨閬囧埌鏃剁敓鎴?

## v0.1.80 - 2026-04-01

### 淇敼锛堟暟鍊煎钩琛¤皟浼橈級
- **鑳介噺铏瑰惛**锛歝ost 0鈫?锛?璐规娊2寮犺繃浜庡己鍔匡紝1璐逛粛涓轰紭璐ㄦ娊鐗屽崱锛?
- **姣掔礌娉ㄥ叆**锛氭寔缁洖鍚?3鈫?锛堟€讳激瀹?6鈫?锛岄檷浣庡欢杩熶激瀹崇殑鎬т环姣旓紝鍗囩骇鍚?4鈫? 鍥炲悎锛?
- **鍙嶅嚮**锛氶槻寰″€?2鈫?锛屽弽鍑讳激瀹?3鈫?锛堝師鏁板€间弗鏍间紭浜庨槻寰＄墝锛屽崌绾у悗 3鈫? def / 4鈫? counter锛?
- **璧涘崥褰╃エ锛堝晢搴楋級**锛氳垂鐢?姝1鈫掓x2锛堝師璐圭敤涓嬪嚑涔庡繀涔帮紝鎻愰珮鍐崇瓥鎴愭湰锛?
- **鑴夊啿鐚庢墜锛坋ncounter_04锛?*锛氳涓烘ā寮?閲嶅嚮鈫掓敾鈫掓敾 鏀逛负 鏀烩啋閲嶅嚮鈫掓敾锛堥鍥炲悎 8 浼ゅ=鐜╁婊¤涓€鍑绘瘷鍛斤紝涓嶅悎鐞嗭級
- **璧涘崥宸尰锛坋ncounter_07锛?*锛欻P 11鈫?锛堥珮HP+娌荤枟+buff涓夊彔鍔狅紝11HP杩囦簬鎸佷箙锛?
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.80

### 澶囨敞
- 鏈疆涓虹函鏁板€艰皟鏁达紝鏃犳柊澧炲姛鑳?鎺ュ彛/淇″彿
- 骞宠　鎬濊矾锛?
  - 鍗＄墝DPE锛堟瘡鑳介噺浼ゅ锛夊熀绾夸负 3.0锛堟柀鍑?3/1锛夛紝瓒呰繃 4.0 鐨勯渶鏈夐檮鍔犻檺鍒?
  - 鑳介噺铏瑰惛浠?鏃犳潯浠舵渶寮哄崱"闄嶇骇涓?浼樿川宸ュ叿鍗?锛?璐规娊2鍦⊿TS鍙傝€冧笅浠嶅己浜庡钩鍧囷級
  - 鍙嶅嚮瀹氫綅涓?闃插尽+鏉′欢浼ゅ"锛屼笉搴旀棤鏉′欢浼樹簬绾槻寰＄墝
  - 鑴夊啿鐚庢墜浠嶄繚鎸侀珮ATK(4)鐜荤拑鐐畾浣嶏紝浣嗙粰鐜╁涓€涓洖鍚堝噯澶囬槻寰?
  - 璧涘崥宸尰浠?鍑犱箮鏃犳硶鍑绘潃"闄嶄负"闇€瑕佺瓥鐣ヤ絾鍙鐞?

## v0.1.79 - 2026-04-01

### 鏂板
- **4 绉嶆柊鍗＄墝鏁堟灉**锛?
  - 姣掔礌娉ㄥ叆锛坧oison锛夛細cost 1锛屾柦鍔犳寔缁瘨绱犱激瀹筹紙2浼?鍥炲悎锛屾寔缁?鍥炲悎锛屽彲鍙犲姞鍥炲悎鏁帮級
  - 鑳介噺铏瑰惛锛坉raw锛夛細cost 0锛岄澶栨娊 2 寮犵墝锛堝崌绾у悗鎶?3 寮狅級
  - 鍙嶅嚮锛坈ounter锛夛細cost 1锛岃幏寰楅槻寰?2 骞惰搫鍔涘弽鍑?3 浼ゅ锛堟晫鏂规敾鍑绘椂瑙﹀彂锛?
  - 瑁傜┖鏂╋紙combo锛夛細cost 2锛? 杩炲嚮鍚?2 浼ゅ锛堟瘡鍑荤嫭绔嬭绠楅槻寰″噺鍏嶏級
- **2 绉嶆柊鏁屾柟琛屼负妯″紡**锛?
  - buff锛氭晫鏂规案涔?ATK+1锛堥暱鎴樻枟涓▉鑳侀€掑锛?
  - multi_attack锛氭晫鏂硅繛缁敾鍑?2 娆★紙姣忔 60% ATK锛?
- **2 涓柊閬亣鏁屾柟**锛?
  - encounter_06 閲忓瓙鍒嗚浣擄細HP 7 / ATK 2锛屽惈 buff + multi_attack 琛屼负
  - encounter_07 璧涘崥宸尰锛欻P 11 / ATK 2锛屽惈 buff + heal 琛屼负
- **CardRenderer 鏂板 4 绉嶅崱鐗岀被鍨?*锛歱oison/draw/counter/combo 閰嶈壊+鍥炬爣+鏍囩+鏁板€兼牸寮?
- **BattleCharRenderer 鏂板 2 涓晫鏂圭珛缁?*锛氶噺瀛愬垎瑁備綋锛堢传鑹茶彵褰㈡櫠浣擄級銆佽禌鍗氬帆鍖伙紙缁胯壊鍏滃附娌荤枟鑰咃級

### 淇敼
- CardBattleController.gd: 鏂板 _poison_turns/_poison_dmg/_counter_dmg 鐘舵€佸彉閲忥紱_resolve_card 鏂板 4 绉嶅崱鐗岀被鍨嬶紱_enemy_act 鏂板 buff/multi_attack + 鍙嶅嚮瑙﹀彂锛沞nd_turn 鏂板姣掔礌缁撶畻锛沖update_enemy_intent 鏂板 buff/multi_attack 鎰忓浘锛涙柊澧?2 涓伃閬囨暟鎹紱濂栧姳鍗℃睜 13鈫?7 寮狅紱鍗囩骇鏁版嵁鏂板 4 寮?
- CardRenderer.gd: TYPE_COLORS/TYPE_ICONS/TYPE_LABELS 鍚勬柊澧?4 椤癸紱_format_value 鏂板 4 绉嶆牸寮?
- BoardGenerator.gd: ENCOUNTER_IDS 5鈫? 涓?
- Main.gd: 閬亣鏄剧ず鍚嶆槧灏勬柊澧?2 鏉?
- BattleCharRenderer.gd: draw_enemy 鏂板 2 涓垎鏀紱鏂板 _draw_quantum_splitter/_draw_cyber_shaman
- CardBattlePanel.gd: _on_enemy_intent_changed 鏂板"杩炵画"/"寮哄寲"鎰忓浘鍥炬爣
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.79

### 澶囨敞
- 姣掔礌鍦?end_turn 涓粨绠楋紙鏁屾柟鍥炲悎寮€濮嬪墠锛夛紝鍙湪鏁屾柟琛屽姩鍓嶅嚮鏉€
- 鍙嶅嚮浼ゅ閫氳繃 _resolve_counter() 缁熶竴澶勭悊锛屾墍鏈夋晫鏂规敾鍑荤被琛屼负锛坅ttack/heavy/defend_attack/mega/multi锛夐兘浼氳Е鍙?
- combo 杩炲嚮姣忓嚮鐙珛妫€鏌ユ晫鏂归槻寰★紝瀵归珮闃叉晫鏂规晥鏋滄樉钁楀噺寮憋紙璁捐鎰忓浘锛?
- buff 琛屼负浣挎晫鏂?ATK 姘镐箙閫掑锛岄噺瀛愬垎瑁備綋 5 鍥炲悎寰幆鍚?1 娆?buff锛岄暱鎴樻枟涓?ATK 浼氭寔缁闀?
- multi_attack 姣忓嚮 60% ATK锛? 鍑诲叡 120% ATK 浣嗗垎鍒彈闃插尽鍑忓厤锛堟瘮 heavy_attack 寮变絾瀵逛綆闃叉湁鏁堬級
- 鏂伴伃閬囧潎鍙楀眰闂撮毦搴︾缉鏀惧奖鍝嶏紙HP+30%/灞? ATK+1/灞傦級

## v0.1.78 - 2026-04-01

### 鏂板
- **鍟嗗搧姹犳墿灞?*锛氬晢搴椾粠 5 绉嶅晢鍝佹墿灞曡嚦 9 绉嶏紝鏂板 4 绫荤瓥鐣ユ€у晢鍝?
  - 鏁版嵁鑺墖锛坅dd_card锛夛細鑺辫垂 绛杧1锛屼粠濂栧姳鍗℃睜闅忔満鑾峰緱 1 寮犲崱鐗屽姞鍏ユ寔涔呯墝缁?
  - 鏁版嵁娓呮礂锛坮emove_card锛夛細鑺辫垂 鏈痻1锛岀Щ闄ょ墝缁勪腑鏁堣垂姣旀渶浣庣殑 1 寮犵墝锛堢墝缁勨墹3寮犳椂涓嶅彲鐢級
  - 璧涘崥褰╃エ锛坮andom_crest锛夛細鑺辫垂 姝1锛岄殢鏈鸿幏寰?2 涓?crest 璧勬簮
  - 鐢熶綋寮哄寲锛坢ax_hp_up锛夛細鑺辫垂 鐩緓2锛屾渶澶P+2 骞跺悓鏃跺洖澶?2HP

### 淇敼
- ShopPanel.gd: SHOP_ITEM_POOL 5鈫? 绉嶏紱`_pick_random_items()` 鏂板鐗岀粍杩囧皬杩囨护锛沗_can_purchase()` 鏂板 add_card/remove_card 鍓嶇疆妫€鏌ワ紱`_execute_purchase()` 鏂板 4 绉嶆晥鏋滅粨绠?
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.78

### 澶囨敞
- add_card 浠?`CardBattleController._build_reward_pool()` 鍙栧崱锛屽鐢ㄧ幇鏈?13 寮犲鍔卞崱姹?
- remove_card 鎸?value/cost 姣斿€奸€夋嫨鏈€寮辩墝锛岀‘淇濈墝缁勨墹3寮犳椂鑷姩绂佺敤
- random_crest 浠?6 绉?crest 涓殢鏈洪€夊彇锛岀洿鎺ヤ慨鏀?`crest_pool` 瀛楀吀
- max_hp_up 鍚屾椂鎻愬崌 max_hp 鍜屽綋鍓?hp锛岄伩鍏嶈喘涔板悗 HP 鏉＄湅璧锋潵鍙嶈€屾洿浣?
- 鍟嗗簵浠嶇劧姣忔闅忔満灞曠ず 3 浠跺晢鍝侊紙浠?9 绉嶄腑閫夛級锛屼赴瀵岀瓥鐣ラ€夋嫨

## v0.1.77 - 2026-04-01

### 鏂板
- **3D 鍗曚綅绮剧伒鍖?*锛歜illboard Sprite3D 鏇夸唬 CapsuleMesh/CylinderMesh
  - 鐜╁鑻遍泟锛氫娇鐢ㄧ幇鏈?4 鏂瑰悜 spritesheet锛堝垁鐩惧悜X璧?png锛夛紝鏀寔琛岃蛋甯у姩鐢伙紙10fps锛?5甯у惊鐜級
  - 鏁屾柟鍗曚綅锛氱▼搴忓寲鐢熸垚 128px 绾㈣壊鑿卞舰鍥炬爣锛堝彂鍏夎竟缂?涓績楂樹寒锛?
  - 鍙敜浼欎即锛氱▼搴忓寲鐢熸垚 128px 闈掕壊鍦嗗舰鍥炬爣
- **UnitMeshFactory3D 绮剧伒鍔ㄧ敾鎺ュ彛**锛歚is_spritesheet_unit()` / `set_sprite_direction()` / `set_sprite_frame()` / `reset_sprite_idle()`
- **BoardView3D 绮剧伒鍔ㄧ敾**锛氱Щ鍔ㄦ椂鑷姩妫€娴嬫柟鍚戙€佸垏鎹?spritesheet銆佹帹杩涘抚鍔ㄧ敾

### 淇敼
- UnitMeshFactory3D.gd: 瀹屾暣閲嶅啓锛?33鈫?50 琛岋級锛屼粠鍑犱綍浣撳伐鍘傚彉涓虹簿鐏靛伐鍘?
- BoardView3D.gd: 鏂板绮剧伒鍔ㄧ敾閫昏緫锛?01鈫?36 琛岋級
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.77

### 淇
- UnitMeshFactory3D: is_summoned 妫€娴嬫敼涓烘鏌?tags 鏁扮粍锛堝師瀹炵幇妫€鏌ヤ笉瀛樺湪鐨?"is_summoned" 瀛楁锛?
- **BUG-002锛歷0.1.76 鍥炲綊 鈥?DiceDebugPanel/Main.gd 鐩存帴璁块棶宸茬Щ闄ょ殑 `current_floor` 灞炴€?*锛歷0.1.76 灏?`current_floor` 浠?BFC 绉昏嚦 FloorManager锛屼絾 DiceDebugPanel锛?澶勶級鍜?Main.gd锛?澶勶級浠嶇洿鎺ヨ闂?`battle_flow.current_floor`锛屽鑷磋繍琛屾椂宕╂簝銆備慨澶嶏細鍏ㄩ儴鏀逛负 `get_current_floor()` 鏂规硶璋冪敤

### 澶囨敞
- 浣跨敤 `ALPHA_CUT_DISCARD`锛坓l_compatibility 鍏煎锛夛紝闃堝€?0.4
- 绋嬪簭鍖栧浘鏍囩紦瀛樹负闈欐€佸彉閲忥紝浠呴娆＄敓鎴?
- 澶栭儴淇″彿鎺ュ彛闆跺彉鏇达紝Main.gd 鏃犻渶淇敼
- 鏁屾柟/鍙敜鍥炬爣涓轰复鏃剁▼搴忓寲鏂规锛屽悗缁彲鏇挎崲涓虹編鏈祫婧?

## v0.1.76 - 2026-04-01

### 鏂板
- **FloorManager 鐙珛绫?*锛坄Scripts/BattleV2/FloorManager.gd`锛寏162 琛岋級锛氫粠 BattleFlowController 鍓ョ澶氬眰鍦板浘閫昏緫
  - `advance_floor()` 鈥?灞傞棿鎺ㄨ繘锛圚P 蹇収 鈫?娓呯悊 鈫?閫掑 鈫?閲嶇敓 鈫?鐢熸垚鏂版鐩橈級
  - `snapshot_player_hp()` / `_spawn_player_units_with_hp()` 鈥?HP 蹇収/澶嶆椿/鍥炲
  - `try_unlock_boss()` / `warp_hero_to_boss()` 鈥?Boss 瑙ｉ攣/鑻遍泟浼犻€?
  - `spawn_portal_near()` / `check_portal()` 鈥?浼犻€侀棬鐢熸垚/妫€娴?
  - `get_current_floor()` / `get_max_floor()` / `reset_floor()` 鈥?灞傛暟绠＄悊

### 淇敼
- BattleFlowController.gd: 绉婚櫎 `MAX_FLOOR`/`REVIVE_HP_RATIO`/`FLOOR_HEAL_RATIO` 甯搁噺鍜?`current_floor` 鍙橀噺锛堢Щ鑷?FloorManager锛?
- BattleFlowController.gd: 绉婚櫎 `_snapshot_player_hp()`/`_spawn_player_units_with_hp()` 鏂规硶锛堢Щ鑷?FloorManager锛?
- BattleFlowController.gd: `_try_unlock_boss()`/`_warp_hero_to_boss()`/`_spawn_portal_near()`/`_check_portal()`/`advance_to_next_floor()` 鏀逛负濮旀墭 FloorManager
- BattleFlowController.gd: `restart_battle()` 鏀圭敤 `floor_manager.reset_floor()`
- BattleFlowController.gd: 琛屾暟浠?881 琛屽噺鑷?791 琛岋紙-90 琛岋級
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.76

### 澶囨敞
- 澶栭儴淇″彿鎺ュ彛闆跺彉鏇达紝Main.gd 鏃犻渶淇敼
- FloorManager 杩斿洖鏁版嵁锛堝瓧鍏?鏁扮粍锛夛紝BFC 淇濈暀淇″彿鍙戝皠鏉?
- 甯搁噺鍜屽娲?鍥炲閫昏緫琛屼负瀹屽叏涓嶅彉锛屼粎浠ｇ爜浣嶇疆鍙樻洿

## v0.1.75 - 2026-04-01

### 鏂板
- **闃典骸鍗曚綅璺ㄥ眰澶嶆椿鏈哄埗**锛氭案涔呯帺瀹跺崟浣嶏紙闈炲彫鍞わ級鍦ㄨ繘鍏ヤ笅涓€灞傛椂鑷姩澶嶆椿锛孒P = 50% max_hp锛堝悜涓婂彇鏁达紝鑷冲皯 1锛?
- **瀛樻椿鍗曚綅璺ㄥ眰鍥炲**锛氬瓨娲诲崟浣嶅湪杩涘叆涓嬩竴灞傛椂棰濆鍥炲 30% max_hp锛堜笉瓒呰繃 max_hp锛夛紝闃叉浣?HP 姝讳骸铻烘棆
- **甯搁噺 `REVIVE_HP_RATIO`**锛氶樀浜″娲?HP 姣斾緥锛岄粯璁?0.5锛?0%锛?
- **甯搁噺 `FLOOR_HEAL_RATIO`**锛氬瓨娲昏法灞傚洖澶嶆瘮渚嬶紝榛樿 0.3锛?0%锛?

### 淇敼
- BattleFlowController.gd: `_spawn_player_units_with_hp()` 浠?璺宠繃闃典骸鍗曚綅"鏀逛负"闃典骸鍗曚綅澶嶆椿 + 瀛樻椿鍗曚綅鍥炲"
- BattleFlowController.gd: `_snapshot_player_hp()` 鏂板 `alive` 瀛楁锛堝悜鍓嶅吋瀹癸紝涓嶅奖鍝嶇幇鏈夐€昏緫锛?
- BattleFlowController.gd: `advance_to_next_floor()` 娉ㄩ噴鏇存柊
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.75

### 澶囨敞
- 浠呬慨鏀?BattleFlowController.gd 鍜?DiceDebugPanel.gd锛孶I 灞傞浂鏀瑰姩
- 鍙敜浼欎即锛坱agged "summoned"锛変粛涓哄眰鍐呬复鏃跺崟浣嶏紝璺ㄥ眰鏃舵秷澶憋紙璁捐鎰忓浘锛?
- 澶嶆椿/鍥炲姣斾緥锛?0%/30%锛変负鍒濆鏁板€硷紝鏈粡骞宠　娴嬭瘯锛屽悗缁彲璋冩暣甯搁噺
- 褰撳墠鍙湁 1 涓案涔呭崟浣嶏紙blade_shield_dog锛夛紝鏈哄埗宸蹭负澶氭案涔呭崟浣嶆墿灞曢鐣?
- `restart_battle()` 涓嶅彈褰卞搷锛堝畬鍏ㄩ噸缃紝涓嶈皟鐢?`_spawn_player_units_with_hp`锛?

## v0.1.74 - 2026-04-01

### 鏂板
- **3D 鍙嶉绯荤粺瀹屾暣瀹炵幇**锛? 涓々鍑芥暟鍏ㄩ儴鏇挎崲涓虹湡瀹?3D 鐗规晥
- **Label3D billboard 婕傛诞鏂囧瓧**锛歚_spawn_float_text_3d()` 鈥?甯﹂粦鑹叉弿杈圭殑 billboard 鏂囧瓧锛屼笂鍗?+ 娓愰殣 + 鑷姩閲婃斁锛岀敤浜庝激瀹虫暟瀛?鎷惧彇/娌荤枟/浜嬩欢/鍟嗗簵/瀹濈/閬亣鍙嶉
- **PlaneMesh 鏍煎瓙闂厜**锛歚_spawn_cell_flash_3d()` 鈥?鍗婇€忔槑鍙戝厜骞抽潰鍙犳斁鍦ㄧ洰鏍囨牸瀛愪笂鏂癸紝鑷彂鍏?+ 娓愰殣鍚庨噴鏀撅紝鐢ㄤ簬鏀诲嚮闂厜鍜屾晫鏂归璀?
- **CPUParticles3D 鍛戒腑绮掑瓙**锛歚_spawn_hit_particles_3d()` 鈥?鐞冨舰绮掑瓙鍚戜笂鐖嗘暎锛坓l_compatibility 鍏煎锛夛紝棰滆壊娓愬彉閫忔槑锛屽嚮鏉€鏃舵暟閲?閫熷害/鑼冨洿澧炲ぇ
- **3D 鐩告満闇囧姩**锛歚_shake_camera_3d()` 鈥?閫氳繃 `_shake_offset` 鍙橀噺椹卞姩锛? 姝ヨ“鍑忔姈鍔紝鍦?`_process()` 涓彔鍔犲埌鐩告満浣嶇疆
- **`_feedback_root` 瀹瑰櫒鑺傜偣**锛氭墍鏈変复鏃跺弽棣堢壒鏁堬紙Label3D/MeshInstance3D/CPUParticles3D锛夌粺涓€鎸傝浇锛屼笌鏍煎瓙/鍗曚綅/楂樹寒灞傚垎绂?

### 淇敼
- BoardView3D.gd: v0.1.72 鈫?v0.1.74锛? 涓々鍑芥暟鏇挎崲涓哄畬鏁村疄鐜帮紙~130 琛屾柊澧烇級锛屾柊澧?4 涓緟鍔╂柟娉?+ `_feedback_root` + `_shake_offset`
- BoardView3D.gd: `_process()` 鐩告満鏇存柊鍙犲姞 `_shake_offset`
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.74

### 澶囨敞
- 浠呬慨鏀?BoardView3D.gd 鍜?DiceDebugPanel.gd锛屾牳蹇冮€昏緫鏂囦欢闆舵敼鍔?
- 2D 妯″紡涓嶆秹鍙婃湰娆′慨鏀癸紝闆跺奖鍝?
- CPUParticles3D 浣跨敤 SphereMesh 浣滀负绮掑瓙鍙褰㈢姸锛実l_compatibility 娓叉煋鍣ㄥ畬鍏ㄥ吋瀹?
- Label3D 浣跨敤 `no_depth_test = true` 纭繚鏂囧瓧涓嶈妫嬬洏鏍煎瓙閬尅
- 鏀诲嚮鍙嶉鍖呭惈 5 灞傛晥鏋滐紙闂厜+闇囧姩+绮掑瓙+浼ゅ椋樺瓧+鍑绘潃鏂囧瓧锛夛紝涓?2D 鐗堝榻?
- 鏁屾柟棰勮浣跨敤鍙屾寤惰繜闂儊锛?.25s + 0.3s 寤惰繜鍚?0.2s锛夛紝妯℃嫙 2D 鐗堣剦鍐叉晥鏋?

## v0.1.73 - 2026-04-01

### 鏂板
- **ShopPanel.gd**锛氭柊鏂囦欢锛垀240琛岋級锛宍class_name ShopPanel`锛岀嫭绔嬪晢搴?UI 闈㈡澘
- **5 绉嶅晢鍝佹睜**锛氫慨澶嶈嵂鍓傦紙姝1鈫扝P+3锛夈€侀珮绾т慨澶嶏紙姝2鈫扝P+6锛夈€佹敾鍑昏姱鐗囷紙鏀粁1鈫扐TK+1锛夈€侀槻寰¤姱鐗囷紙鐩緓1鈫扗EF+1锛夈€佽兘閲忔牳蹇冿紙鏈痻2鈫掕兘閲忎笂闄?1锛?
- **闅忔満 3 閫?*锛氭瘡娆¤俯鍟嗗簵鏍间粠姹犱腑闅忔満灞曠ず 3 浠跺晢鍝侊紝鍙娆¤喘涔?
- **CyberStyle 椋庢牸鍖栭潰鏉?*锛氳禌鍗氶潚鑹茶竟妗嗭紝鏄剧ず鎸佹湁 crest 璧勬簮锛岃喘涔板弽棣堟枃瀛楋紝鐏版帀涓嶅彲璐拱椤?
- **淇″彿 `shop_panel_requested`**锛氭浛浠ｆ棫鐨?`shop_cell_triggered`锛孊FC 浠呭彂淇″彿涓嶈嚜鍔ㄨ喘涔?
- **`CellEffectHandler.has_valid_shop_cell()`**锛氫粎妫€鏌ュ晢搴楁牸瀛樺湪鎬?鐜╁韬唤锛屼笉鎵ц璐拱閫昏緫

### 淇敼
- CellEffectHandler.gd: 鍒犻櫎 `check_shop_cell()`锛堣嚜鍔ㄨ喘涔帮級锛屾浛鎹负 `has_valid_shop_cell()`锛堢函鏍￠獙锛?
- BattleFlowController.gd: `_check_shop_cell` 鏀逛负浠呭彂 `shop_panel_requested` 淇″彿
- Main.gd: 鏂板 ShopPanel 瀵煎叆/瀹炰緥鍖?淇″彿杩炴帴 + `_on_shop_panel_requested`/`_on_shop_closed` 鍥炶皟
- DiceDebugPanel.gd: 淇″彿缁戝畾 `shop_cell_triggered` 鈫?`shop_panel_requested`锛岀増鏈爣璁?鈫?v0.1.73

### 澶囨敞
- ATK/DEF 鎻愬崌鐩存帴淇敼 unit dict锛堟湰灞傛案涔咃紝璺ㄥ眰鏃?unit 閲嶅缓鑷姩閲嶇疆锛夛紝鏈蛋 BuffManager
- 鑳介噺鏍稿績淇敼 CardBattleController.max_energy锛堣法鎴樻枟鎸佷箙锛夛紝涓婇檺鍗?5
- 鍟嗗搧姹犱负 const Array锛屽悗缁墿灞曟柟渚匡紙鍔犳柊鐗?绉婚櫎璇呭拻/闅忔満 crest 绛夛級
- 鏃т俊鍙?shop_cell_triggered 宸插叏閲忔竻闄わ紙grep 纭闆跺紩鐢級

## v0.1.72 - 2026-03-31

### 淇
- **3D 鎷栨嫿鎵嬫劅**锛氭敼鐢ㄨ捣濮嬩綅缃?缁濆宸€兼槧灏勶紙鏇夸唬閫愬抚澧為噺绱Н锛夛紝娑堥櫎鎷栨嫿婕傜Щ鍜岀簿搴︿涪澶?
- **3D 鎷栨嫿瀹炴椂鍝嶅簲**锛氭嫋鎷芥湡闂寸浉鏈轰互 20.0 楂橀€?lerp 杩借釜锛堝師鍏堟嫋鎷芥椂 lerp 瀹屽叏鍏抽棴锛屾澗鎵嬫墠鐢熸晥锛?
- **3D 闀滃ご璺熼殢閫熷害**锛欳AMERA_LERP_SPEED 4.5 鈫?8.0锛屼慨澶?60fps 涓?lerp 鍥犲瓙杩囧皬锛?.072鈫?.128/甯э級瀵艰嚧鐨勯暅澶磋繜婊?
- **3D 缂╂斁杞村績**锛氭柊澧?_apply_zoom()锛屼互榧犳爣浣嶇疆涓鸿酱蹇冪缉鏀撅紙灏勭嚎浜ゅ弶璁＄畻缂╂斁鍓嶅悗鍦伴潰鐐瑰亸绉伙級锛屼笌 2D 琛屼负瀵归綈
- **3D 杈圭晫闄愬埗**锛氭柊澧?_clamp_drag_offset()锛屽皢鎷栨嫿鍋忕Щ澶圭揣鍒版鐩樹笘鐣岃寖鍥寸殑 卤50%锛岄槻姝㈢浉鏈烘棤闄愭紓绉?

### 淇敼
- BoardView3D.gd: 閲嶅啓 handle_input() 鎷栨嫿閫昏緫锛坃drag_start_offset 蹇収 + 缁濆鍋忕Щ璁＄畻锛?
- BoardView3D.gd: 閲嶅啓 _process() 鐩告満鏇存柊锛堟嫋鎷戒腑/闈炴嫋鎷藉弻璺緞 lerp锛?
- BoardView3D.gd: 鏂板 _clamp_drag_offset() / _apply_zoom() / _screen_to_ground() 涓変釜鍐呴儴鏂规硶
- BoardView3D.gd: 鏂板 _drag_start_offset 鍙橀噺銆乑OOM_STEP 甯搁噺
- DiceDebugPanel.gd: 鐗堟湰鏍囪 鈫?v0.1.72

### 澶囨敞
- 浠呬慨鏀?BoardView3D.gd 鍜?DiceDebugPanel.gd锛屾牳蹇冮€昏緫鏂囦欢闆舵敼鍔?
- 2D 妯″紡涓嶆秹鍙婃湰娆′慨鏀癸紝闆跺奖鍝?
- _screen_to_ground() 浣跨敤 camera.project_ray_origin/normal 鎶曞皠锛屽綋鐩告満浣嶇疆鍥?lerp 鏈畬鍏ㄥ埌浣嶆椂瀛樺湪寰皬鍋忓樊锛堝彲鎺ュ彈锛?

## v0.1.71.1 - 2026-03-31 (hotfix)

### 淇
- **BoardView3D.gd**锛歚Environment.TONE_MAP_ACES` 鈫?`Environment.TONE_MAPPER_ACES`锛圙odot 4.x 姝ｇ‘鏋氫妇甯搁噺锛夛紝淇 3D 瑙嗗浘瑙ｆ瀽閿欒瀵艰嚧鏃犳硶杩愯

## v0.1.71 - 2026-03-31

### 鏂板
- **3D 娓愯繘杩佺Щ P0**锛氭柊澧炲畬鏁?3D 琛ㄧ幇灞傦紝涓?2D 瑙嗗浘鍙垏鎹㈠叡瀛?
- **GridMapper3D.gd**锛氭柊鏂囦欢锛宍class_name GridMapper3D`锛屾鐩樻牸鍧愭爣(Vector2i) 鈫?3D涓栫晫鍧愭爣(Vector3) 鍙屽悜杞崲
- **TileMeshFactory3D.gd**锛氭柊鏂囦欢锛宍class_name TileMeshFactory3D`锛屼负 9 绉嶆牸瀛愮被鍨嬪垱寤虹▼搴忓寲 BoxMesh + StandardMaterial3D锛堥厤鑹叉部鐢?CyberStyle锛?
- **UnitMeshFactory3D.gd**锛氭柊鏂囦欢锛宍class_name UnitMeshFactory3D`锛屼负鐜╁锛圕apsuleMesh锛?鏁屾柟锛圕ylinderMesh锛夊垱寤?3D 鍗曚綅 + billboard HP 鏉?
- **BoardView3D.gd**锛氭柊鏂囦欢锛宍class_name BoardView3D`锛宔xtends Node3D锛屽畬鏁?3D 妫嬬洏瑙嗗浘锛屼俊鍙锋帴鍙ｄ笌 BoardView(2D) 瀵归綈
- **SubViewport 宓屽叆**锛氶€氳繃 SubViewportContainer + SubViewport 灏?3D 鍦烘櫙宓屽叆 2D UI 鏍?
- **F5 鍒囨崲 2D/3D**锛氳繍琛屾椂鎸?F5 閿垏鎹㈣鍥炬ā寮?
- **3D 鐩告満绯荤粺**锛氶€忚鐩告満锛?5掳 淇锛夛紝骞虫粦璺熼殢 + 榧犳爣鎷栨嫿骞崇Щ + 婊氳疆缂╂斁
- **3D 灏勭嚎妫€娴?*锛氬湴闈㈠钩闈㈠皠绾夸氦鍙夊疄鐜伴紶鏍団啋鏍煎瓙鏄犲皠
- **3D 楂樹寒绯荤粺**锛氬崐閫忔槑钖勭墖鍙犲眰鏄剧ず绉诲姩/鏀诲嚮/鍙敜楂樹寒
- **3D 閫愭牸绉诲姩鍔ㄧ敾**锛歍ween 椹卞姩 Vector3 鎻掑€?
- **璧涘崥鏈嬪厠 3D 鍏夌収**锛欴irectionalLight3D锛堝喎璋冨厜锛? WorldEnvironment锛堟殫鑹茶儗鏅?杈夊厜+ACES 鑹茶皟鏄犲皠锛?

### 淇敼
- Main.gd: 鏂板 `_use_3d` 鏍囧織 + `_active_view()` duck typing 璺敱 + `_reset_drag_offset()` 鍏煎鏂规硶
- Main.gd: 鏂板 `_setup_3d_view()` 鍒濆鍖?SubViewport + BoardView3D + 淇″彿缁戝畾
- Main.gd: 鏂板 `toggle_3d_view()` + `_input()` F5 蹇嵎閿?
- Main.gd: 鎵€鏈?~40 澶?`_board_view.` 璋冪敤鏇挎崲涓?`_active_view().` 璺敱
- Main.gd: 鍙敜婕斿嚭銆佹嫋鎷藉亸绉荤瓑 2D-specific 浠ｇ爜鐢?`_use_3d` 瀹堝崼
- DiceDebugPanel: 鐗堟湰鏍囪 鈫?v0.1.71

### 鏋舵瀯璇存槑
- **涓嶄慨鏀规牳蹇冮€昏緫鏂囦欢**锛欱attleFlowController銆丆ardBattleController銆丅oardManager銆乁nitManager 闆舵敼鍔?
- **duck typing 璺敱**锛欱oardView(2D) 鍜?BoardView3D(3D) 鍏变韩淇″彿鍚嶅拰鏂规硶鍚嶏紝Main.gd 閫氳繃 `_active_view()` 鏃犵被鍨嬭繑鍥炲疄鐜扮粺涓€璺敱
- **2D 濮嬬粓鍙敤**锛歚_use_3d` 榛樿 false锛?D 涓虹敓浜фā寮忥紝3D 涓哄疄楠岄瑙?
- **3D 鍙嶉鏂规硶鏆備负妗?*锛歱lay_attack_feedback 绛?3D 鐗堟殏杩斿洖绌猴紝鍚庣画杩唬琛ュ厖绮掑瓙/椋樺瓧

### 澶囨敞
- 4 涓柊鏂囦欢鍧囧湪 `Scripts/UI3D/` 鐩綍涓?
- BoardView3D 鍐呭祵浜?SubViewport锛?280x720锛夛紝鐢?SubViewportContainer 鏄剧ず
- 3D 鏍煎瓙浣跨敤 BoxMesh锛圕ELL_SIZE=2.0锛夛紝楂樺彴鏍奸澶栨姮楂?0.4
- 3D 鍗曚綅浣跨敤 CapsuleMesh锛堢帺瀹惰摑锛? CylinderMesh锛堟晫鏂圭孩锛夛紝鍙戝厜鑹插尮閰?CyberStyle
- 3D 妯″紡涓嬮紶鏍囦簨浠堕€氳繃 Main._input() 杞彂缁?BoardView3D.handle_input()

## v0.1.70 - 2026-03-31

### 鏂板
- **鐜╁瑙掕壊绮剧伒鍔ㄧ敾**锛氭浛浠ｇ▼搴忓寲缁樺埗锛屼娇鐢?spritesheet 娓叉煋鐜╁鍗曚綅
- **PlayerSpriteAnimator.gd**锛氭柊鏂囦欢锛宍class_name PlayerSpriteAnimator`锛岀鐞?4 鏂瑰悜琛岃蛋 spritesheet 甯у垏鎹?
- **4鏂瑰悜琛岃蛋鍔ㄧ敾**锛氫笂/涓?宸?鍙冲悇涓€寮?4x4 缃戞牸 spritesheet锛?5甯э級锛岀Щ鍔ㄦ椂鑷姩鎾斁瀵瑰簲鏂瑰悜
- **鏂瑰悜鑷姩妫€娴?*锛氭牴鎹Щ鍔ㄨ捣缁堟牸璁＄畻鏈濆悜锛坉x/dy 姣旇緝锛?
- **闈欐鏃舵樉绀虹涓€甯?*锛氭湭绉诲姩鏃舵樉绀哄綋鍓嶆湞鍚戠殑绗竴甯э紙榛樿鍚戜笅锛?

### 淇敼
- BoardView.gd: 鏂板 `_sprite_animator` + `_draw_player_sprite()` 鏂规硶锛岀Щ鍔ㄦ椂鍚姩/鍋滄鍔ㄧ敾
- BoardView.gd: `_on_anim_tick()` 涓帹杩涚簿鐏靛抚锛宍play_move_step()` 涓缃柟鍚?
- DiceDebugPanel: 鐗堟湰鏍囪 鈫?v0.1.70

### 澶囨敞
- 4 寮?spritesheet 灏哄涓嶅悓锛堝悜涓?3032x2596锛屽悜涓?3532x2888锛屽悜宸?鍙?3840x3840锛夛紝娓叉煋鏃剁粺涓€缂╂斁鑷?80px 楂?
- 鏁屾柟鍗曚綅浠嶄娇鐢ㄧ▼搴忓寲缁樺埗锛圲nitRenderer锛?
- HUD 澶村儚浠嶄娇鐢ㄧ▼搴忓寲缁樺埗锛圲nitRenderer._draw_player_char锛?
- 濡傛灉 spritesheet 鑳屾櫙涓嶉€忔槑锛堥潪 RGBA alpha锛夛紝闇€瑕佺敤鎴烽澶勭悊鍘荤櫧搴?
- 甯х巼锛?0fps锛堟瘡 100ms 鍒囧抚锛夛紝15 甯т竴涓畬鏁村惊鐜?

## v0.1.69 - 2026-03-31

### 鏂板
- **椤堕儴鍗曚綅澶村儚 HUD**锛氬睆骞曢《閮ㄦí鎺掓樉绀哄悇鏂瑰崟浣嶅ご鍍?+ HP 鏉?+ 鍚嶇О
- **UnitPortraitHUD.gd**锛氭柊鏂囦欢锛宍class_name UnitPortraitHUD`锛宍_draw` 娓叉煋鎵€鏈夊崟浣嶈倴鍍?
- **鐜╁鍗曚綅宸︽帓銆佹晫鏂瑰彸鎺?*锛氳嚜鍔ㄦ寜闃佃惀鍒嗙粍甯冨眬
- **鐐瑰嚮澶村儚鍒囨崲闀滃ご**锛氱偣鍑荤帺瀹跺ご鍍?鈫?閫変腑鍗曚綅 + 闀滃ご璺熼殢锛涚偣鍑绘晫鏂瑰ご鍍?鈫?浠呴暅澶磋窡闅?
- **閫変腑楂樹寒 + 鎮仠鍙嶉**锛氬綋鍓嶉€変腑鍗曚綅杈规楂樹寒锛屾偓鍋滄椂鑳屾櫙鍙樹寒
- **鍗＄墝鎴樻枟鏃惰嚜鍔ㄩ殣钘?*锛氳繘鍏ラ伃閬囨椂闅愯棌 HUD锛岃繑鍥炴鐩樻椂鏄剧ず
- **涓?BoardView 閫変腑鍚屾**锛欱oardView 鐨?unit_selected/unit_deselected 淇″彿鑱斿姩 HUD 楂樹寒

### 淇敼
- Main.gd: 鏂板 `_portrait_hud` 瀹炰緥鍖?+ 淇″彿杩炴帴 + `_on_portrait_clicked` 鍥炶皟
- Main.gd: 鍗＄墝鎴樻枟杩涘嚭鏃跺垏鎹?`_portrait_hud.visible`
- DiceDebugPanel: 鐗堟湰鏍囪 鈫?v0.1.69

### 澶囨敞
- UnitRenderer._draw_player_char / _draw_enemy_char 浠?0.45 缂╂斁缁樺埗杩蜂綘澶村儚
- HUD 閫氳繃 units_changed 淇″彿鑷姩閲嶅缓锛屽崟浣嶉樀浜?鏂板鏃惰嚜鍔ㄦ洿鏂?
- 璧峰 X=90px 閬垮紑宸︿笂瑙掕缃寜閽?

## v0.1.68 - 2026-03-31

### 鏂板
- **鍗＄墝鎷栨嫿鍑虹墝绯荤粺**锛氭浛浠ｅ師鏈夌偣鍑诲嚭鐗岋紝mousedown 寮€濮嬫嫋鎷?鈫?mousemove 璺熼殢鎵嬫寚 鈫?mouseup 鍦ㄤ笂鍗婂尯锛坹<380锛夐噴鏀惧嵆鎵撳嚭
- **鍑虹墝鍖鸿瑙夋彁绀?*锛氭嫋鎷芥椂椤堕儴鍑虹幇鍗婇€忔槑钃濊壊鍖哄煙 + "鎷栧埌姝ゅ鍑虹墝" 鏂囧瓧锛屽崱鐗岃繘鍏ュ尯鍩熸椂楂樹寒鍔犳繁
- **鍗虫椂浼ゅ鍙嶉**锛氭瘡娆″嚭鐗屽悗绔嬪嵆鍒锋柊 HP 鏉★紙涓嶅啀绛夊埌缁撴潫鍥炲悎锛夛紝鍚屾椂鏄剧ず浼ゅ/娌荤枟椋樺瓧
- **浼ゅ椋樺瓧绯荤粺**锛歚_spawn_effect_popup()` 鏂规硶锛岀孩鑹蹭笂娴?"-X" 浼ゅ / 缁胯壊 "+X" 娌荤枟锛?.7s Tween 鍔ㄧ敾鍚庤嚜鍔ㄦ秷澶?
- **鏁屾柟琛屽姩鍗虫椂鍙嶉**锛氭晫鏂硅鍔ㄥ悗涔熺珛鍗冲埛鏂?HP 鏉?+ 浼ゅ椋樺瓧

### 淇敼
- CardBattlePanel._create_battle_card: 绉婚櫎 callback 鍙傛暟锛実ui_input 浠庣洿鎺ヨ皟鐢?play_card 鏀逛负鍚姩鎷栨嫿
- CardBattlePanel._on_card_played: 鏂板 `_refresh_status()` 璋冪敤 + HP 宸€兼瘮瀵?+ 椋樺瓧鐢熸垚
- CardBattlePanel._on_hand_changed: 鏂板 `_cancel_drag()` 闃叉鎵嬬墝閲嶅缓鏃舵嫋鎷芥畫鐣?
- CardBattlePanel._on_enemy_acted: 鏂板鍗虫椂 HP 鍒锋柊 + 椋樺瓧
- CardBattlePanel._on_battle_started: 鍒濆鍖?HP 杩借釜鍙橀噺
- CardBattlePanel hover 鍥炶皟: 鎷栨嫿杩涜鏃舵姂鍒?hover 缂╂斁鍔ㄧ敾
- DiceDebugPanel: 鐗堟湰鏍囪 鈫?v0.1.68

### 澶囨敞
- 鎷栨嫿浣跨敤 `_input()` override 鑰岄潪 `_gui_input`锛岀‘淇濋紶鏍囩寮€鍗＄墝鍖哄煙鍚庝粛鑳借窡韪?
- HP 杩借釜鍙橀噺 `_hp_before_enemy/_hp_before_player` 鍦ㄥ嚭鐗屽墠蹇収銆佸嚭鐗屽悗姣斿锛岀敤浜庤绠楅瀛楁暟鍊?
- 鏁屾柟琛屽姩鍚庝篃鏇存柊杩借釜鍙橀噺锛岄槻姝㈣繛缁鍔ㄦ椂椋樺瓧鏁板€肩疮绉敊璇?

## v0.1.67 - 2026-03-31

### 鏂板
- **绉诲姩閫愭牸琛岃蛋鍔ㄧ敾**锛氱帺瀹?鏁屾柟鍗曚綅绉诲姩鏃堕€愭牸 Tween 鎻掑€硷紙0.15s/鏍硷級锛屽憡鍒灛绉?
- **BFS 璺緞閲嶅缓锛圔oardManager锛?*锛歚get_path_to_cell()` 鏂规硶锛屽熀浜?came_from 鍥炴函瀹屾暣璺緞
- **绉诲姩鍔ㄧ敾淇″彿閾?*锛欱FC.move_step_visual 鈫?Main 鈫?BoardView.play_move_step 鈫?move_anim_done 鈫?BFC.move_step_done
- **validate_move 绾獙璇佹柟娉?*锛氫笉娑堣€楄祫婧愮殑鍚屾绉诲姩鏍￠獙锛屼緵 Main 棰勬
- **鎴戞柟鍥炲悎闀滃ご鍒囧洖浼樺寲**锛氭晫鏂瑰洖鍚堢粨鏉熷悗闀滃ご浼樺厛鍒囧洖涓婁竴杞搷浣滅殑鎴戞柟鍗曚綅锛堥潪鍥哄畾鍒囦富瑙掞級
- **_last_operated_unit_id 杩借釜**锛氱Щ鍔?鏀诲嚮/鍙敜鎿嶄綔鏃惰褰曪紝鐢ㄤ簬闀滃ご鍒囧洖

### 淇敼
- BattleFlowController.try_move_unit: 浠庡悓姝ヨ繑鍥?bool 鏀逛负 async void锛岄€愭牸绉诲姩+await 鍔ㄧ敾
- BattleFlowController._execute_enemy_actions: 鏁屾柟绉诲姩鎺ュ叆 move_step_visual 鍔ㄧ敾淇″彿閾?
- 鏁屾柟绉诲姩鍚庣瓑寰呬粠 0.9s 闄嶈嚦 0.5s锛堝姩鐢诲凡鎻愪緵瑙嗚鍙嶉锛?
- BoardView._draw_layer_units: 鍔ㄧ敾涓殑鍗曚綅缁樺埗鍦?from鈫抰o 鎻掑€间綅缃?
- Main._on_move_requested: 鏀圭敤 validate_move 鍚屾鏍￠獙 + fire-and-forget 寮傛鎵ц
- Main._on_enemy_turn_ended: 浼樺厛鍒囧洖 _last_operated_unit_id
- DiceDebugPanel: 鐗堟湰鏍囪 鈫?v0.1.67

### 澶囨敞
- 涓€旂粡杩囩殑鏍煎瓙涓嶈Е鍙戞晥鏋滐紙闄烽槺/閬亣绛変粎鍦ㄦ渶缁堢洰鐨勫湴妫€鏌ワ級锛岃繖鏄璁″喅瀹?
- try_move_unit 杩斿洖绫诲瀷鍙樻洿锛坆ool鈫抳oid锛変负鏋舵瀯绾ф敼鍔紝闇€纭鏃犲叾浠栬皟鐢ㄦ柟渚濊禆杩斿洖鍊?

## v0.1.66 - 2026-03-31

### 鏂板
- **瑙掕壊褰㈣薄鍏ㄩ潰閲嶆瀯锛堝挬鍜╁惎绀哄綍椋庢牸锛?*锛氱帺瀹惰嫳闆?鍏ㄩ儴鏁屾柟鍗曚綅锛堝摠鍏?娓搁瓊/鐖櫕/鐚庢墜/骞界伒/Boss锛夐噸鏂拌璁′负 Cult of the Lamb 椋庢牸鈥斺€斿ぇ鍦嗗ご銆佸ぇ鐪肩潧銆佽悓绯?Q 鐗堣韩鏉?
- **妫嬬洏杩蜂綘瑙掕壊閲嶆瀯锛圲nitRenderer锛?*锛氬悓姝ラ噸鏋勶紝鎵€鏈夋鐩樹笂鐨勮糠浣犺鑹蹭笌鎴樻枟绔嬬粯椋庢牸缁熶竴
- **闊虫晥璁剧疆闈㈡澘**锛歋ettingsPanel 鏂板 BGM/SFX 闊抽噺婊戝潡锛?-100锛夊拰寮€鍏虫寜閽紝瀹炴椂璋冭妭
- **AudioManager 闊抽噺鎺у埗 API**锛氭柊澧?set_bgm_volume/set_sfx_volume/get_bgm_volume/get_sfx_volume/is_sfx_enabled/is_bgm_enabled 鏂规硶

### 淇敼
- SettingsPanel: 鏍囬鏀逛负"璁剧疆"锛岄潰鏉挎墿澶ц嚦 440x520锛屾柊澧為煶鏁堣缃尯鍩?
- Main.gd: 鏂板 bind_audio_manager 璋冪敤锛岃皟鏁?SettingsPanel 浣嶇疆
- DiceDebugPanel: 鐗堟湰鏍囪 鈫?v0.1.66

### 澶囨敞
- 瑙掕壊璁捐鐏垫劅鏉ユ簮锛氬挬鍜╁惎绀哄綍锛圕ult of the Lamb锛夆€斺€斿ぇ澶磋悓绯?Q 鐗?璧涘崥鏈嬪厠閰嶈壊
- 闊虫晥璁剧疆涓哄疄鏃剁敓鏁堬紝鏃犻渶鐐瑰嚮"搴旂敤"鎸夐挳锛堟粦鍧楀拰寮€鍏冲嵆鏃跺搷搴旓級

## v0.1.65 - 2026-03-31

### 淇敼
- **鏁屾柟绉诲姩鍚庣浉鏈鸿窡闅?*锛歘execute_enemy_actions 涓晫鏂?move_unit 鍚庡彂灏?move_completed 淇″彿锛岀浉鏈鸿嚜鍔ㄨ窡韪晫鏂圭Щ鍔ㄧ洰鏍囦綅缃?
- **鏁屾柟鍥炲悎缁撴潫寤惰繜鍒囧洖**锛歁ain._on_enemy_turn_ended 澧炲姞 0.8 绉掑欢杩熷啀鍒囧洖鐜╁锛岄伩鍏嶇敓纭烦杞?
- **BFC 鏁屾柟鍥炲悎缁撴潫寤堕暱绛夊緟**锛氭晫鏂瑰叏閮ㄨ鍔ㄥ畬姣曞悗鍏堢瓑 0.6 绉掑啀 emit enemy_turn_ended锛屽啀绛?1.2 绉掓墠鎺ㄨ繘鐜╁鍥炲悎
- **鐩告満 Lerp 閫熷害闄嶄綆**锛欳AMERA_LERP_SPEED 浠?8.0 闄嶈嚦 4.5锛岃繃娓℃洿鏌斿拰骞虫粦
- **鏁屾柟绉诲姩鍚庣瓑寰呭欢闀?*锛氭晫鏂圭Щ鍔ㄥ悗绛夊緟浠?0.6 绉掑鑷?0.9 绉掞紝渚夸簬瑙傚療
- **鏁屾柟鎺烽绛夊緟鍔ㄧ敾瀹屾垚**锛氭柊澧?dice_animation_done 淇″彿锛孊FC 鍦ㄦ晫鏂规幏楠板悗 await 璇ヤ俊鍙风洿鍒板姩鐢荤湡姝ｇ粨鏉燂紝鑰岄潪鍥哄畾 0.8 绉掞紙鍔ㄧ敾瀹為檯绾?4 绉掞級
- DiceDebugPanel: 鐗堟湰鏍囪 鈫?v0.1.65

### 澶囨敞
- 鏈増鏈笓娉ㄤ簬鏁屾柟鍥炲悎闀滃ご浣撻獙浼樺寲锛岃В鍐?v0.1.64 鍙嶉涓暅澶磋繃蹇繃纭殑闂

## v0.1.64 - 2026-03-31

### 鏂板
- **閫変腑鍗曚綅鍗冲眳涓浉鏈?*锛氱偣鍑诲彲鎺у埗鍗曚綅鏃剁浉鏈虹珛鍗崇Щ鍒拌鍗曚綅浣嶇疆
- **鏁屾柟鍥炲悎棰勫憡闀滃ご**锛氭晫鏂规幏楠板墠鍏堝皢鐩告満绉诲埌鍗冲皢琛屽姩鐨勬晫鏂瑰崟浣?
- **鎺烽鍔ㄧ敾澧炲己**锛氶瀛愭斁澶?5%锛?4鈫?6锛夛紝鎬诲姩鐢绘椂闀跨害4绉掞紝鏂板钀藉湴闃村奖銆佷腑蹇冨厜鏅曘€佸噺閫熺炕婊氭晥鏋?
- **enemy_turn_starting 淇″彿**锛氭晫鏂瑰洖鍚堝紑濮嬪墠閫氱煡 UI 灞?

### 淇敼
- BoardView._select_unit: 閫変腑鏃惰皟鐢?set_camera_target + 閲嶇疆 _drag_offset
- BattleFlowController._start_enemy_turn: 鎺烽鍓?emit enemy_turn_starting锛岀瓑寰?0.5 绉?
- Main.gd: 鎵€鏈夎嚜鍔ㄧ浉鏈鸿窡闅忓洖璋冮噸缃?_drag_offset锛屾柊澧?_on_enemy_turn_starting
- DiceRollAnimation: 鍏ㄩ潰閲嶅啓鈥斺€旀洿澶ч瀛愩€佹洿闀垮姩鐢汇€佸灞傝緣鍏夈€侀槾褰便€佸噺閫熺炕婊氥€佹棆杞晥鏋?
- DiceDebugPanel: 鐗堟湰鏍囪 鈫?v0.1.64

## v0.1.63 - 2026-03-31

### 鏂板
- **澶т笘鐣岀幆澧冨～鍏?*锛氭鐩樺缁樺埗鏆楄壊鐜鑿卞舰鏍煎瓙锛屾秷闄ら粦鑹茬┖鐧藉尯鍩?
- **榧犳爣婊氳疆缂╂斁**锛氭粴杞斁澶?缂╁皬妫嬬洏瑙嗚锛?.4x~1.6x锛夛紝浠ラ紶鏍囦綅缃负涓績缂╂斁
- **鏁屾柟鍥炲悎鐩告満璺熼殢**锛氭晫鏂硅鍔ㄦ椂鐩告満璺熼殢鏁屼汉锛岀帺瀹跺洖鍚堣嚜鍔ㄥ垏鍥?
- **璧涘崥椋庢牸榧犳爣鍏夋爣**锛氱▼搴忓寲鍗佸瓧鍑嗘槦鍏夋爣
- **UI绱у噾鍖?*锛欴iceDebugPanel 浠?220x680 鍙冲叏鏍忔敼涓?260x200 搴曢儴鍙充晶绱у噾 HUD

### 淇敼
- IsoTileRenderer: 鍏ㄩ儴缁樺埗鏂规硶鏀寔 zoom 鍙傛暟
- BoardView: 鏂板缂╂斁绯荤粺锛坃zoom/ZOOM_MIN/ZOOM_MAX锛?
- Main.gd: 鏁屾柟璺熼殢+鑷畾涔夊厜鏍?
- DiceDebugPanel: 鍏ㄩ潰绱у噾鍖栭噸璁捐

## v0.1.62 - 2026-03-31

### 鏂板
- **榧犳爣鎷栨嫿骞崇Щ鐩告満**锛氬彸閿?涓敭鎷栨嫿鍙嚜鐢卞钩绉绘鐩樿瑙?
- **骞虫粦鐩告満璺熼殢**锛歴et_camera_target 鏀逛负 Lerp 鎻掑€艰繃娓★紙CAMERA_LERP_SPEED=8.0锛?
- **鎮仠楂樹寒**锛氶紶鏍囨偓鍋滄牸瀛愭樉绀虹櫧鑹茶彵褰㈤珮浜弽棣?
- **妫嬬洏鎵╁睍鑷?12x12**锛欸RID_SIZE 浠?8 鎵╁睍鍒?12锛屽唴瀹规洿涓板瘜

### 淇敼
- IsoTileRenderer: GRID_SIZE 鈫?DEFAULT_GRID_SIZE=12锛宒raw_board 鍔ㄦ€佷粠 board_mgr 璇诲彇灏哄
- BoardView: 绉婚櫎 GRID_W/GRID_H 甯搁噺锛屾敼鐢?board_manager.is_in_bounds() 鍔ㄦ€佸垽瀹?
- BoardView: 鏂板 _drag_active/_drag_offset/_iso_origin_target 鎷栨嫿鍜屽钩婊戠浉鏈虹姸鎬?
- BattleFlowController: 鏂板 BOARD_SIZE 甯搁噺锛屾墍鏈?Vector2i(8,8) 鏇挎崲涓?BOARD_SIZE
- BattleFlowController: 纭紪鐮?bounds check (adj >= 8) 鏀逛负 board_manager.board_size 鍔ㄦ€佸垽瀹?
- BoardGenerator: 鎵€鏈夌敓鎴愬弬鏁版寜 12x12 妫嬬洏姣斾緥涓婅皟锛堥伃閬?-6/楂樺彴3-5/闄烽槺3-5/閬撳叿3/鍥炲3/浜嬩欢3-5/鍟嗗簵2/瀹濈2-3/鏁屼汉3锛?
- BoardGenerator: 鐜╁鍑虹敓鍖鸿皟鏁磋嚦 row 9-11锛屾柊澧炲摠鍏典笝鏁屾柟妯℃澘
- CyberBackground: board_size 鏇存柊鑷?864x864

## v0.1.61 - 2026-03-31

### 淇敼
- **妫嬬洏娓叉煋鍥為€€鑷崇▼搴忓寲**锛欼soTileRenderer 浠?AI 璐村浘娓叉煋鏀逛负绋嬪簭鍖栬彵褰㈢粯鍒?
  - 绉婚櫎鎵€鏈夎创鍥惧姞杞戒唬鐮侊紙TILE_PATHS / _textures / _loaded / _ensure_loaded锛?
  - 绉婚櫎 TILE_FULL_H / TILE_ELEVATED_H / ELEVATION_OFFSET 甯搁噺锛堜笉鍐嶆湁楂樿€告柟鍧楋級
  - 鏂板 `_draw_tile_procedural()` 绋嬪簭鍖栫粯鍒讹細鑿卞舰濉厖+鍐呴儴娓愬彉+缃戞牸杈规+绫诲瀷瑁呴グ
  - 9绉嶆牸瀛愮被鍨嬶紙楂樺彴/闄烽槺/閬亣/鍥炲/鍟嗗簵/瀹濈/閬撳叿/浜嬩欢/浼犻€侀棬锛夊悇鏈夌嫭绔嬮厤鑹插拰绗﹀彿
  - draw_board() 鏂板 pulse 鍙傛暟锛屾牸瀛愯楗版敮鎸佽剦鍐插懠鍚告晥鏋?
- BoardView._draw_layer_grid() 浼犲叆 pulse 鍙傛暟
- 鍒犻櫎 Assets/Tiles/ 涓嬪叏閮?11 寮?AI 鐢熸垚 PNG 璐村浘

### 澶囨敞
- 绛夎窛鍧愭爣绯伙紙TILE_W=192 / grid_to_screen / screen_to_grid锛夊畬鍏ㄤ繚鐣?
- 鐩告満璺熼殢绯荤粺锛坈alc_origin_for_cell / camera_cell / set_camera_target锛夊畬鍏ㄤ繚鐣?
- 鏍瑰洜锛欰I 璐村浘涓洪珮鑰?3D 鏂瑰潡鍥撅紝娓叉煋鍚庢鐩樺绉湪澧欙紝瑙嗚涓ラ噸寮傚父
- 鍚庣画濡傛湁鍚堥€傜殑鎵佸钩绛夎窛璐村浘璧勬簮锛屽彲鍦?_draw_tile_procedural 涓浛鎹㈠洖璐村浘璺緞

## v0.1.60 - 2026-03-31

### 鏂板
- **鐩告満璺熼殢鐜╁瑙掕壊 + 鍏ㄦ柊绱犳潗 + UI浼樺寲**
- IsoTileRenderer.calc_origin_for_cell()锛氬弽鎺?iso_origin 浣挎寚瀹氭牸瀛愭槧灏勫埌灞忓箷涓績
- BoardView.camera_cell + set_camera_target()锛氱浉鏈鸿窡闅忕郴缁?
- BoardView._draw_edge_vignette()锛氬洓杈?80px 娓愭殫甯︽煍鍖栨鐩樿竟鐣?
- Main._update_camera_to_player() / _on_move_completed_camera()锛氱Щ鍔?閲嶅紑/浼犻€?灞傚垏鎹㈡椂鏇存柊鐩告満
- 11 寮犲叏鏂?AI 鐢熸垚璧涘崥鏈嬪厠绛夎窛鏂瑰潡璐村浘锛圢ano Banana Pro锛岀粺涓€鑻辨枃鍛藉悕锛?

### 淇敼
- IsoTileRenderer 绛夎窛鍙傛暟鍐嶆鏀惧ぇ锛歍ILE_W 144鈫?92, TILE_H_HALF 36鈫?8, TILE_FULL_H 144鈫?92, TILE_ELEVATED_H 192鈫?56, ELEVATION_OFFSET 48鈫?4
- BoardView iso_origin 浠庡浐瀹?(640,72) 鏀逛负鍔ㄦ€佽绠楋紙鐩告満璺熼殢锛?
- BoardView 鍚敤 clip_contents=true 瑁佸壀婧㈠嚭瑙嗗彛鐨勬鐩?
- UnitRenderer 绛夎窛瑙掕壊鏀惧ぇ锛歴cale 0.9鈫?.1锛孒P鏉″ 60鈫?2锛岄€変腑鐜崐寰?24鈫?0锛孻鍋忕Щ -16鈫?20
- DiceDebugPanel 闈㈡澘瀹藉害 232鈫?20锛屽渾瑙?6鈫?锛宎lpha 0.75鈫?.80锛岀増鏈?v0.1.59鈫抳0.1.60
- DiceDebugPanel 浣嶇疆 (1040,8)鈫?1052,8)
- CyberBackground 绉婚櫎妫嬬洏鍙戝厜杈规鍜岃鏍囩粯鍒讹紙鐩告満璺熼殢涓嬫鐩樿秴鍑鸿鍙ｏ級
- 鍒犻櫎鎵€鏈夋棫 PNG 绱犳潗鏂囦欢锛堝惈涓枃鍛藉悕鍜?v0.1.59 elevated 鐗堟湰锛?

### 澶囨敞
- 鐩告満璺熼殢鏆備负鐬棿璺宠浆锛屽悗缁彲鍔?Tween 骞虫粦杩囨浮
- TILE_W=192 浣?8 鏍兼鐩樺搴?1536px锛屾孩鍑?1280px 瑙嗗彛绾?128px/渚?

## v0.1.59 - 2026-03-31

### 鏂板
- **鍏ㄥ睆绛夎窛妫嬬洏 + 鍙犲眰 UI + 楂樿捣璐村浘 + 瑙掕壊鏀惧ぇ**
- 8寮?AI 鐢熸垚楂樿捣璐村浘锛圢ano Banana Pro锛夛細楂樺彴/閬亣/鍥炲/鍟嗗簵/瀹濈/閬撳叿/浜嬩欢/浼犻€侀棬
- IsoTileRenderer 楂樿捣娓叉煋锛歍ILE_ELEVATED_H=192 + ELEVATION_OFFSET=48锛岀壒娈婃牸鑷姩鍫嗗彔绐佽捣
- IsoTileRenderer 鏂板璐村浘璺緞锛歟vent_tile.png / portal_tile.png锛堜簨浠舵牸鍜屼紶閫侀棬涓撳睘璐村浘锛?
- IsoTileRenderer._get_tile_key 鏂板 portal/event 浼樺厛绾у垎鏀?

### 淇敼
- IsoTileRenderer 绛夎窛鍙傛暟鏀惧ぇ 2x锛歍ILE_W 72鈫?44, TILE_H_HALF 18鈫?6, TILE_FULL_H 72鈫?44
- BoardView 鍏ㄥ睆鍖栵細size 576脳350 鈫?1280脳720, iso_origin (288,30)鈫?640,72)
- BoardView 鍙犲眰绠€鍖栵細浜嬩欢鏍?浼犻€侀棬宸叉湁涓撳睘璐村浘锛岀Щ闄ょ▼搴忓寲鑿卞舰鍙犲眰
- BoardView 鍙嶉椋樺瓧瀛楀彿鏀惧ぇ锛?8鈫?2/24锛夛紝鍋忕Щ閫傞厤澶ф牸瀛?
- UnitRenderer 绛夎窛瑙掕壊鏀惧ぇ锛歴cale 0.55鈫?.9锛孒P鏉″ 40鈫?0锛岄€変腑鐜崐寰?16鈫?4
- Main.gd 甯冨眬閲嶆瀯锛氭鐩?(0,0) 鍏ㄥ睆锛孌iceDebugPanel 鍙充晶鍗婇€忔槑鍙犲姞 (1040,8)
- Main.gd 绉婚櫎鏍囬/鍓爣棰?鎻愮ず鏉★紙鍏ㄥ睆妫嬬洏鏃犻渶鍗犱綅鏍囬鏍忥級
- DiceDebugPanel 鍗婇€忔槑鍙犲姞妯″紡锛氬搴?280鈫?32锛孲tyleBoxFlat bg_color alpha=0.75
- DiceDebugPanel 鐗堟湰鏍囪鏇存柊 v0.1.50鈫抳0.1.59
- CyberBackground 瑕嗙洊鍏ㄥ睆 (0,0)鈫?1280,720)
- 鎺烽婕斿嚭涓績 (328,382)鈫?640,360)

### 澶囨敞
- 鏃у钩闈㈣创鍥炬枃浠朵繚鐣欏湪 Assets/Tiles/ 浣嗕笉鍐嶈寮曠敤锛坱rap 闄ゅ锛?
- BoardCellRenderer 涓嶅啀琚?BoardView 寮曠敤
- DiceDebugPanel 浣跨敤鐙珛 StyleBoxFlat 浠ｆ浛 CyberStyle.make_panel_bg 浠ュ疄鐜板崐閫忔槑

## v0.1.58 - 2026-03-31

### 鏂板
- **缇庡寲 Phase 6锛氱瓑璺濇鐩樿创鍥炬浛鎹?*
- **IsoTileRenderer.gd**锛垀145琛岋級锛氱瓑璺濇鐩樿创鍥炬覆鏌撳櫒锛坈lass_name 鍏ㄥ眬娉ㄥ唽锛?
  - 9寮犵瓑璺濇柟鍧楄创鍥炬寜鏍煎瓙绫诲瀷鍔犺浇缂撳瓨锛堟櫘閫氭祬/娣便€侀珮鍙般€侀櫡闃便€侀伃閬囥€佹仮澶嶃€侀亾鍏枫€佸晢搴椼€佸疂绠憋級
  - grid_to_screen / screen_to_grid 鏍煎潗鏍団啍灞忓箷鍧愭爣鍙屽悜杞崲
  - painter's algorithm 鎸?depth=gx+gy 姝ｇ‘閬尅缁樺埗
  - diamond_points / draw_diamond_highlight / draw_diamond_corners 鑿卞舰杈呭姪缁樺埗
- `UnitRenderer.draw_full_unit_iso()`锛氱瓑璺濇鐩樹笓鐢ㄥ崟浣嶇粯鍒讹紙0.55缂╂斁+鑿卞舰涓績瀹氫綅锛?
- `UnitRenderer.draw_affinity_star_iso()`锛氱瓑璺濇鐩橀€傛€ф槦鏍?

### 淇敼
- `BoardView.gd`锛氬叏闈㈢瓑璺濆寲閲嶅啓
  - 鎺т欢灏哄 576脳576 鈫?576脳350锛涙柊澧?iso_origin = (288, 30)
  - _pixel_to_cell 浠庢鏂瑰舰缃戞牸闄ゆ硶鏀逛负 IsoTileRenderer.screen_to_grid
  - _draw_layer_grid 浠?BoardCellRenderer.draw_base_cell 寰幆鏀逛负 IsoTileRenderer.draw_board
  - _draw_layer_overlays 浠?Rect2 瑕嗙洊灞傛敼涓鸿彵褰腑蹇冨眳涓枃瀛?绗﹀彿
  - _draw_layer_highlights 浠庢鏂瑰舰 L 瑙掓爣/鍑嗘槦鏀逛负鑿卞舰 diamond_corners/diamond_highlight
  - _draw_layer_units 浠?cell脳CELL_SIZE 鏀逛负 IsoTileRenderer.grid_to_screen + depth 鎺掑簭
  - _draw_attack_flash 浠庢鏂瑰舰鐧介棯鏀逛负鑿卞舰鐧介棯
  - 7涓弽棣堟柟娉曞叏閮ㄤ娇鐢ㄧ瓑璺濆潗鏍囧畾浣?
- `Main.gd`锛欳yberBackground 576脳350 + summon_completed 绛夎窛鍧愭爣

### 澶囨敞
- BoardCellRenderer.gd 涓嶅啀鐢ㄤ簬鍩虹鏍肩粯鍒讹紝鏂囦欢淇濈暀渚涘弬鑰?
- 鍘熸湁 UnitRenderer.draw_full_unit / draw_affinity_star 淇濈暀锛屾棫璺緞鍏煎
- 浜嬩欢鏍?璺緞鏍?浼犻€侀棬鏍兼棤涓撳睘璐村浘锛屼娇鐢ㄧ▼搴忓寲鑿卞舰鍙犲眰
- 閫昏緫灞傦紙BattleFlowController / UnitManager / BoardManager锛夐浂淇敼
- 鍗＄墝闈㈡澘锛圕ardBattlePanel锛夐浂淇敼

## v0.1.57 - 2026-03-31

### 鏂板
- **灞傞棿闅惧害閫掑**锛氭牴鎹?current_floor 鍔ㄦ€佺缉鏀炬晫鏂?HP/ATK
- `BoardGenerator._floor_scaling()` 缂╂斁鍑芥暟锛氱1灞傚熀鍑嗭紝绗?灞?HP脳1.3/ATK+1锛岀3灞?HP脳1.6/ATK+2
- 妫嬬洏灞傚摠鍏靛崟浣嶆寜灞傜缉鏀撅紙绗?灞?HP5/ATK2 鈫?绗?灞?HP8/ATK4锛?
- 鍗＄墝灞傞伃閬囨晫鏂规寜灞傜缉鏀撅紙鍚?Boss锛氱1灞?HP20/ATK3 鈫?绗?灞?HP32/ATK5锛?

### 淇敼
- `BoardGenerator.gd`锛歡enerate_board / _spawn_enemies 鏂板 current_floor 鍙傛暟锛岀缉鏀惧摠鍏?HP/ATK
- `CardBattleController.gd`锛歡et_encounter_enemy_data / start_battle 鏂板 current_floor 鍙傛暟锛岀缉鏀鹃伃閬囨晫鏂?HP/ATK
- `BattleFlowController.gd`锛?澶?generate_board 璋冪敤浼犲叆 current_floor
- `Main.gd`锛?澶?start_battle 璋冪敤浼犲叆 _battle_flow.current_floor

### 澶囨敞
- 鎵€鏈夋柊澧炲弬鏁板潎鏈夐粯璁ゅ€?= 1锛屼笉鐮村潖鐜版湁鏃犲弬璋冪敤璺緞
- HP 缂╂斁浣跨敤 ceil 鍚戜笂鍙栨暣锛岀‘淇濊嚦灏戝鍔?1 鐐?
- 缂╂斁鍏紡绾挎€х畝鍗曪紝鍚庣画鍙牴鎹帺娴嬪弽棣堣皟鏁寸郴鏁?
- UI 闈㈡澘 / BoardView / AudioManager 闆朵慨鏀?

## v0.1.56 - 2026-03-31

### 鏂板
- **缇庡寲 Phase 5锛氶煶鏁堢郴缁?*
- **SFXGenerator.gd**锛垀1100琛岋級锛氫粠鏃ч」鐩縼鍏ュ畬鏁寸▼搴忓寲闊抽寮曟搸锛?8绉嶉煶鏁?4绉岯GM寰幆锛?
  - 8bit 鑺墖闊抽鏍?+ 璧涘崥鏈嬪厠鍚堟垚鍣ㄩ煶鑹?+ EVA 鏆楄壊鐜闊?
  - 鎵€鏈夐煶棰戣繍琛屾椂鐢熸垚锛屾棤澶栭儴闊抽鏂囦欢渚濊禆
- **AudioManager.gd**锛垀120琛岋級锛氶煶鏁堢鐞嗗櫒锛坈lass_name 鍏ㄥ眬娉ㄥ唽锛?
  - 6閫氶亾 SFX 澶氳矾澶嶇敤鎾斁 + 1閫氶亾 BGM 寰幆鎾斁
  - 鍚姩鏃堕缂撳瓨 18 绉嶅父鐢ㄩ煶鏁堬紙attack_hit/defense/card_draw/card_play/victory/defeat 绛夛級
  - BGM 鎸夐渶鐢熸垚骞剁紦瀛橈紙bgm_map/bgm_battle/bgm_boss/bgm_title锛?
  - `play_sfx(name)` / `play_bgm(name)` / `stop_bgm()` / `set_sfx_enabled()` / `set_bgm_enabled()` API

### 淇敼
- `Main.gd`锛氭柊澧?`_audio: AudioManager` 鎴愬憳锛宊ready 涓垱寤哄苟鍚姩妫嬬洏 BGM
  - 妫嬬洏灞傛帴鍏ワ細绉诲姩(click)/鏀诲嚮(attack_hit)/鍙敜(summon)/鎺烽(dice_roll)/鍦板舰浼ゅ(player_hurt)/閬撳叿鎷惧彇(pickup)/鍥炲(heal)/闃插尽(defense)/鍟嗗簵(shop)/瀹濈(chest)/閬亣(encounter)/Boss瑙ｉ攣(encounter)
  - 鍗＄墝灞傛帴鍏ワ細鍑虹墝(card_play)/鏁屾柟琛屽姩(enemy_hurt)/鎶界墝(card_draw)
  - 鑳滆礋鍙嶉锛氳儨鍒?victory)/澶辫触(defeat)
  - BGM 鍒囨崲锛氭鐩樷啋閬亣(bgm_battle)/Boss(bgm_boss)鈫掕繑鍥炴鐩?bgm_map)
  - 璁剧疆鎸夐挳鐐瑰嚮(click)

### 澶囨敞
- SFXGenerator 浣跨敤 class_name 鍏ㄥ眬娉ㄥ唽锛孉udioManager 鍚屾牱 class_name 娉ㄥ唽
- AudioManager 鍦?_ready 鏃堕鐢熸垚骞剁紦瀛樺父鐢ㄩ煶鏁堬紝閬垮厤棣栨鎾斁寤惰繜
- BGM 鍦ㄥ満鏅垏鎹㈡椂鑷姩鍒囨崲锛堟鐩樷啍鎴樻枟鈫擝oss锛夛紝鐩稿悓 BGM 涓嶉噸澶嶅惎鍔?
- 鎵€鏈夐煶鏁堣Е鍙戦泦涓湪 Main.gd 淇″彿鍥炶皟涓紝涓嶄镜鍏ュ瓙妯″潡浠ｇ爜
- BattleFlowController / CardBattleController / BoardView / UI闈㈡澘鍧囬浂淇敼

## v0.1.55 - 2026-03-31

### 鏂板
- **缇庡寲 Phase 4.2锛歎I 杩囨浮鍔ㄧ敾**
- **UITransitions.gd**锛垀60琛岋級锛歎I 杩囨浮鍔ㄧ敾宸ュ叿绫伙紙class_name 鍏ㄥ眬娉ㄥ唽锛?
  - `popup()` 闈㈡澘寮瑰嚭鍔ㄧ敾锛歴cale 0.9鈫?.0锛圗ASE_OUT+TRANS_BACK 寮硅烦锛? alpha 0鈫?锛?.2绉?
  - `close()` 闈㈡澘鍏抽棴鍔ㄧ敾锛歴cale 1.0鈫?.95 + alpha 1鈫?锛?.15绉掞紝鑷姩闅愯棌+澶嶄綅
  - `close_await()` 寮傛鍏抽棴鐗堟湰锛屽彲 await 绛夊緟瀹屾垚
  - `summon_unit_spawn()` 鍙敜鍑哄満闂厜锛氶潚鑹?ColorRect scale 寮硅烦 0.3鈫?.3鈫?.0 + 娣″嚭
- **鍙敜灞曞紑婕斿嚭**锛氳矾寰勬牸閫愭牸閾哄睍锛堟瘡鏍?0.1s 寤惰繜閲嶇粯锛? 鍗曚綅鍑哄満闂厜寮硅烦

### 淇敼
- `CardRewardPanel.gd`锛氬鍔遍潰鏉垮脊鍑?鍏抽棴/璺宠繃/鍗囩骇瀹屾垚鍧囨帴鍏?UITransitions 缂撳姩鍔ㄧ敾
- `DeckViewPanel.gd`锛歰pen/close 鎺ュ叆 UITransitions 缂撳姩鍔ㄧ敾
- `SettingsPanel.gd`锛歰pen/close 鎺ュ叆 UITransitions 缂撳姩鍔ㄧ敾
- `Main.gd`锛歘on_summon_completed 閲嶅啓涓鸿矾寰勯€愭牸閾哄睍 + 鍙敜鍗曚綅鍑哄満闂厜
- 涓変釜闈㈡澘鍧囨柊澧?pivot_offset 璁句负闈㈡澘涓績锛岀‘淇濈缉鏀惧姩鐢讳粠涓績寮€濮?

### 澶囨敞
- UITransitions 浣跨敤 class_name 鍏ㄥ眬娉ㄥ唽锛屾棤闇€ preload
- close() 瀹屾垚鍚庤嚜鍔ㄥ浣?scale=Vector2.ONE 鍜?modulate=Color.WHITE锛岄槻姝㈡畫鐣欑姸鎬?
- 鍙敜灞曞紑婕斿嚭涓?async锛堜娇鐢?await timer锛夛紝涓嶉樆濉炴鐩樻搷浣滀絾鏈夎瑙夊欢杩?
- BattleFlowController / CardBattleController / BoardView 闆朵慨鏀?
- Phase 4.2 瀹屾垚鏍囧噯锛氶潰鏉垮脊鍑?鍏抽棴鏈夌紦鍔ㄨ繃娓℃劅锛涘彫鍞ゆ湁灞曞紑婕斿嚭鑰岄潪鐩存帴鍑虹幇

## docs: Snapshot 鍏ㄩ潰鍚屾 - 2026-03-31

### 淇敼
- **CyberTao_Migration_Snapshot_zh_v3.md 鍏ㄩ潰閲嶅啓**锛氫粠 v0.1.30 鍚屾鑷?v0.1.54 鐘舵€?
  - 搂2 宸插畬鎴愬唴瀹癸細妫嬬洏灞傛柊澧?18 椤广€佸崱鐗屽眰鏂板 9 椤广€佽瑙夋紨鍑虹郴缁熺嫭绔嬪垎绫?9 妯″潡
  - 搂3 鏋舵瀯姒傝堪锛欱attleV2 鏂板 3 妯″潡銆乁I 灞傛柊澧?10 妯″潡銆佷俊鍙?鏁版嵁缁撴瀯鍏ㄩ潰鏇存柊
  - 搂4 鎶€鏈€猴細鏍囪 3 椤瑰凡瑙ｅ喅銆佹柊澧炲綋鍓?7 椤?
  - 搂5~搂8 鎺ㄨ繘寤鸿/鏂囦欢绱㈠紩/閲岀▼纰?鐘舵€佹弿杩板叏閮ㄦ洿鏂?
- Mulerun_Work_Report.md 鏇存柊涓烘湰杞枃妗ｅ悓姝ヤ换鍔?

### 澶囨敞
- 绾枃妗ｄ换鍔★紝鏃犱唬鐮佷慨鏀?
- AI_Employee_Guide_v3.md 宸插湪 v0.1.54 鏃跺悓姝ヨ嚦鏈€鏂帮紝鏈疆纭鏃犻渶淇敼

## v0.1.54 - 2026-03-30

### 鏂板
- **鍏ㄥ睆鐙珛鍗＄墝鎴樻枟鐣岄潰**锛欳ardBattlePanel 浠?500x470 娴獥閲嶈璁′负 1280x720 鍏ㄥ睆鐙珛鐣岄潰
  - 鐙珛鎴樻枟鑳屾櫙锛氳禌鍗氭湅鍏嬮€忚缃戞牸鍦伴潰 + VS 鏍囪 + 鍏夊姬瑁呴グ
  - 涓嶅啀渚濊禆鏆楀箷锛坄_battle_dark_bg` 宸茬Щ闄わ級锛岄潰鏉胯嚜甯︽繁鑹叉垬鏂楀満鏅儗鏅?
- **瑙掕壊绔嬬粯绯荤粺**锛氭柊澧?`BattleCharRenderer.gd`锛垀180琛岋級锛岀▼搴忓寲缁樺埗鎴樻枟瑙掕壊
  - 鐜╁鑻遍泟锛堝垁鐩剧姮锛夛細璧涘崥鎴樺＋鍓奖锛堢浘鐗?鍏夊垉+V鍨嬫姢鐩暅+瑁呯敳韬共锛?
  - 6 绉嶆晫鏂硅鑹茬珛缁橈細寮傚父鍝ㄥ叺锛堟壂鎻忕溂锛夈€佽禌鍗氭父榄傦紙椋樻负灏剧劙锛夈€佹殫缃戠埇铏紙澶氳冻铚樿洓锛夈€佽剦鍐茬寧鎵嬶紙涓夎灏勬墜锛夈€佹暟鎹菇鐏碉紙鑿卞舰鏁版嵁浣擄級銆侀浂鍙峰崗璁紙宸ㄥ瀷涓夌溂鍐犲啎Boss锛?
  - 瑙掕壊闅忚剦鍐插弬鏁板疄鏃跺姩鐢伙紙鍛煎惛鍏夋晥 + 鍙戝厜鍙樺寲锛?
- **鎵囧舰鎵嬬墝甯冨眬**锛氬崱鐗屼互寮у舰鎺掑垪鍦ㄧ敾闈㈠簳閮?
  - FAN_RADIUS=700 / FAN_CARD_ANGLE=6掳 / FAN_MAX_ANGLE=22掳
  - 鍗＄墝灏哄浠?90x108 鏀惧ぇ鍒?105x130锛堝叏灞忛€傞厤锛?
  - 鎮仠鏀惧ぇ 1.12x + 涓婃诞 20px + z-index 鎻愬崌
- **妫嬬洏鍗曚綅缇庡寲**锛歎nitRenderer 閲嶅啓涓鸿糠浣犺鑹插壀褰?
  - 鐜╁瑙掕壊锛氳糠浣犺禌鍗氭垬澹紙韬共+鍥涜偄+鐩?鍒?鎶ょ洰闀滐級
  - 鏁屾柟 6 绉嶇嫭鐗归€犲瀷鍖归厤鍏ㄥ睆鎴樻枟绔嬬粯
  - 鏇夸唬鏃х増鍑犱綍鏂规/涓夎褰?鑿卞舰

### 淇敼
- `CardBattlePanel.gd` 瀹屽叏閲嶅啓锛?00x470 鈫?1280x720 鍏ㄥ睆锛?
- `UnitRenderer.gd` 瀹屽叏閲嶅啓锛堝嚑浣曞舰鐘?鈫?杩蜂綘瑙掕壊鍓奖锛?
- `Main.gd`锛欳ardBattlePanel 浣嶇疆浠?(390,125) 鏀逛负 (0,0)锛涚Щ闄?`_battle_dark_bg` 鏆楀箷
- 鍏ㄥ睆甯冨眬锛氭晫鏂逛俊鎭彸涓?/ 鐜╁淇℃伅宸︿笅 / 鎴樻枟鏃ュ織涓ぎ / 鎵嬬墝搴曢儴 / 鎿嶄綔鎸夐挳鍙充笅

### 澶囨敞
- BattleCharRenderer 浣跨敤 class_name 鍏ㄥ眬娉ㄥ唽锛屾棤闇€ preload
- 瑙掕壊缁樺埗閫氳繃 Control._draw 鍥炶皟瀹炵幇锛屾瘡甯ф洿鏂拌剦鍐插姩鐢?
- CardBattlePanel 鐨?encounter_id 浠?controller 鑾峰彇锛岀敤浜庨€夋嫨姝ｇ‘鐨勬晫鏂圭珛缁?
- Boss 绔嬬粯浣跨敤 2.8x 缂╂斁锛屾櫘閫氭晫鏂逛娇鐢?2.2x 缂╂斁

## v0.1.53 - 2026-03-30

### 鏂板
- **Boss 瑙ｉ攣鑷姩浼犻€?*锛氬摠鍏靛叏鐏悗鑻遍泟鑷姩浼犻€佸埌 Boss 鏍兼梺杈癸紝娑堥櫎鏃犳剰涔夌殑璧拌矾鍥炲悎
  - `BattleFlowController._warp_hero_to_boss()` 鏌ユ壘鑻遍泟鍗曚綅骞朵紶閫佸埌 Boss 鏃佺┖鏍?
  - 鏂板 `hero_warped` 淇″彿锛孧ain.gd 杩炴帴鍚庨瀛?浼犻€佽嚦 Boss锛?
- **瀹濆彲姊﹀紡鍗＄墝鎴樻枟杩囨浮**锛氶伃閬囪Е鍙戞椂鎾斁鍏ㄥ睆鐧惧彾绐楄繃娓″姩鐢?
  - 鏂板 `TransitionOverlay.gd`锛圕anvasLayer 10锛夛細8 鏉℃按骞崇櫨鍙剁獥鍚堟嫝/灞曞紑
  - 杩涘叆鎴樻枟锛氱櫨鍙剁獥鍚堟嫝(0.35s) 鈫?闂儊鏁屾柟鍚嶇О(0.45s) 鈫?灞曠ず鎴樻枟鐣岄潰 鈫?鐧惧彾绐楀睍寮€(0.3s)
  - 閫€鍑烘垬鏂楋細绛夊緟缁撴灉(0.8s) 鈫?鐧惧彾绐楀悎鎷?鈫?闅愯棌闈㈡澘 鈫?灞曞紑鍥炴鐩?
  - Boss 閬亣浣跨敤鏆楃孩鑹茬櫨鍙剁獥
- **鍏ㄥ睆鏆楀箷**锛氬崱鐗屾垬鏂楁椂榛戣壊閬僵瑕嗙洊妫嬬洏锛岃惀閫犵嫭绔嬪満鏅劅
- **閬亣鍚嶇О闂瓧**锛氳繃娓℃椂鍦ㄧ櫨鍙剁獥鍚堟嫝鍚庨棯鐑佹晫鏂逛腑鏂囧悕绉?

### 淇敼
- `CardBattlePanel._on_battle_started()` / `_on_battle_ended()` 涓嶅啀鑷姩鎺у埗 visible锛岀敱 Main.gd 閫氳繃杩囨浮缁熶竴绠＄悊
- `Main._on_encounter_triggered()` 閲嶅啓涓哄紓姝ヨ繃娓℃祦绋?
- `Main._on_card_battle_ended()` 閲嶅啓涓哄紓姝ヨ繃娓℃祦绋?
- 璋冭瘯鎸夐挳"娴嬭瘯鎴樻枟"涔熻蛋杩囨浮娴佺▼

### 澶囨敞
- CardBattlePanel 鍐呴儴甯冨眬淇濇寔 500x470 涓嶅彉锛岄€氳繃鏆楀箷+灞呬腑瀹炵幇鍦烘櫙闅旂鎰?
- TransitionOverlay 涓嶅奖鍝嶄换浣曠幇鏈?UI 灞傜骇锛圕anvasLayer 10 鐙珛锛?
- v0.1.51 resolve_encounter 涓夊垎鏀€乿0.1.52 鍗曚綅绮剧畝鍧囦笉鍙楀奖鍝?

## v0.1.52 - 2026-03-30

### 鏀硅繘
- **鍗曚綅绮剧畝**锛氱帺瀹跺嚭鍦哄崟浣嶄粠 3 涓噺涓?1 涓富瑙掞紙blade_shield_dog锛?
- **浼欎即妲界郴缁?*锛氬彫鍞ゆ敼涓轰紮浼撮儴缃诧紝姣忓眰涓婇檺 2 娆￠儴缃层€佸満涓婁笂闄?1 鍙紮浼?
  - `BattleFlowController` 鏂板 `SUMMON_FLOOR_LIMIT=2`銆乣SUMMON_FIELD_LIMIT=1`銆乣_summon_this_floor` 璁℃暟
  - `get_summon_cells_for()` / `try_summon()` 澧炲姞灞?鍦洪檺鍒舵鏌?
  - `restart_battle()` / `advance_to_next_floor()` 閲嶇疆 `_summon_this_floor`
- **鑻遍泟瀛樻椿鍒惰儨璐熷垽瀹?*锛歚VictoryRuleHelper.get_battle_outcome()` 鏀圭敤 `has_hero_unit()`锛屼粎闈?summoned 鐨勭帺瀹跺崟浣嶈涓鸿嫳闆?
  - 鏂板 `VictoryRuleHelper.has_hero_unit()` 闈欐€佹柟娉?
- **HUD 閮ㄧ讲鎻愮ず**锛欴iceDebugPanel 鍦?Crest 姹犱笅鏂规樉绀烘湰灞傞儴缃插墿浣欐鏁?

### 绮剧畝
- `_spawn_player_units()` 浠呯敓鎴?blade_shield_dog锛堢Щ闄?fire_fox銆乤qua_turtle锛?
- `_spawn_player_units_with_hp()` spawn_data 浠呬繚鐣?blade_shield_dog 涓€鏉?

### 澶囨敞
- v0.1.51 涓夊垎鏀?resolve_encounter 涓嶅彈褰卞搷
- v0.1.50 浼犻€侀棬/Boss 閿佸畾鏈哄埗涓嶅彈褰卞搷
- CardBattleController / CardBattlePanel / BoardManager 闆朵慨鏀?

## v0.1.51 - 2026-03-30

### 淇
- **Boss/閬亣鏍煎嚮璐ユ秷澶?Bug**锛堥樆濉炴€э級
  - 鏍瑰洜锛歚resolve_encounter()` 鏃犺鑳滆触閮借皟鐢?`board_manager.clear_encounter_cell()`
  - 淇锛氶噸鍐欎负涓夊垎鏀垽鏂?
    - 鑳滃埄 鈫?娓呴櫎閬亣鏍?+ Boss 鐢熸垚浼犻€侀棬 + encounter_resolved 淇″彿
    - 澶辫触浣嗗瓨娲?鈫?閬亣鏍间繚鐣欙紙涓嶆竻闄わ級锛孒P 淇濆簳 1锛屽洖鍒?PLAYER_ACTION锛屽彲鍐嶆鎸戞垬
    - 澶辫触涓斿叏鐏?鈫?瑙﹀彂 DEFEAT
  - 褰卞搷鏂囦欢锛欱attleFlowController.gd銆丮ain.gd
- Main.gd `_on_card_battle_ended()` 鏂板澶辫触鍙嶉椋樺瓧锛?鎴樻枟澶辫触..."锛?

### 澶囨敞
- 鍑芥暟绛惧悕涓嶅彉锛屼俊鍙风鍚嶄笉鍙橈紝涓嬫父锛圕ardBattleController/CardBattlePanel锛夐浂淇敼
- 澶辫触鏃朵笉鍙戝皠 encounter_resolved 淇″彿锛堥伃閬囨湭鐪熸缁撴潫锛孌iceDebugPanel 鐨?encounter_panel 閫氳繃 phase_changed 姝ｇ‘闅愯棌锛?
- v0.1.50 鐨?Boss 浼犻€侀棬鏈哄埗瀹屾暣淇濈暀锛坕s_boss + _spawn_portal_near 鍦ㄨ儨鍒╁垎鏀腑锛?

## v0.1.50 - 2026-03-30

### 鏂板
- Boss 閿佸畾鏈哄埗锛氬摠鍏碉紙grunt锛夊叏鐏墠 Boss 閬亣鏍兼樉绀轰负閿佸畾鐘舵€侊紙鐏版殫+閿侀摼绗﹀彿锛夛紝涓嶅彲瑙﹀彂
- 鍝ㄥ叺鍏ㄧ伃鑷姩瑙ｉ攣锛氭墍鏈?grunt 鍗曚綅琚嚮鏉€鍚庯紝BFC 鑷姩瑙ｉ攣 Boss 閬亣鏍硷紝椋樺瓧鎻愮ず"BOSS 瑙ｉ攣锛?
- 浼犻€侀棬绯荤粺锛氬嚮璐?Boss 閬亣鍚庡湪 Boss 鏍奸檮杩戯紙浼樺厛涓嬫柟锛夌敓鎴愪紶閫侀棬
- 浼犻€侀棬鏍艰瑙夛細闈掕摑鑹叉棆娑″悓蹇冨渾鐜?+ 鑴夊啿杈夊厜锛圔oardCellRenderer._draw_portal锛?
- Boss 閿佸畾鏍艰瑙夛細鐏版殫绾?+ X 閿侀摼绗﹀彿 + LOCKED 鏂囧瓧锛圔oardCellRenderer._draw_boss_locked锛?
- VictoryRuleHelper.has_grunt_units()锛氭鏌ユ槸鍚﹁繕鏈夊瓨娲诲摠鍏靛崟浣?
- BoardManager锛歭ocked_encounters/portal_cells 瀛楀吀 + lock/unlock/portal 鏂规硶
- BFC 鏂颁俊鍙凤細boss_unlocked(cell)銆乸ortal_spawned(cell)

### 淇敼
- BattleFlowController._check_battle_outcome()锛氫笉鍐嶇畝鍗曞垽"鍏ㄦ晫鏂规=鑳滃埄"
  - 鍝ㄥ叺鍏ㄧ伃 鈫?瑙ｉ攣 Boss
  - 閬亣鏍间粛瀛樺湪鏃朵笉鍒よ儨锛堢瓑鐜╁韪?Boss 鏍艰Е鍙戝崱鐗屾垬鏂楋級
  - 浼犻€侀棬瀛樺湪鏃朵笉鍒よ儨锛堢瓑鐜╁韪╀紶閫侀棬瑙﹀彂閫氬叧锛?
- BattleFlowController._check_encounter()锛氶攣瀹氶伃閬囨牸涓嶅彲瑙﹀彂
- BattleFlowController.resolve_encounter()锛欱oss 閬亣鑳滃埄 鈫?鐢熸垚浼犻€侀棬
- BattleFlowController.try_move_unit()锛氭柊澧?_check_portal() 璋冪敤
- BoardGenerator锛欱oss 閬亣鏍肩敓鎴愬悗鑷姩璋冪敤 lock_encounter()
- BoardView锛歟ncounter_cells 娓叉煋鍖哄垎 boss/boss_locked/encounter 涓夌绫诲瀷
- BoardView锛氭柊澧?portal_cells 娓叉煋寰幆
- Main.gd锛氳繛鎺?boss_unlocked/portal_spawned 淇″彿锛屽弽棣堥瀛?

### 澶囨敞
- 鑳滃埄鏉′欢閾撅細鍑绘潃鍝ㄥ叺鈫払oss瑙ｉ攣鈫掕俯Boss鏍尖啋鍗＄墝鎴樻枟鈫掕儨鍒┾啋浼犻€侀棬鈫掕俯浼犻€侀棬鈫掗€氬叧/涓嬩竴灞?
- BoardManager locked_encounters/portal_cells 鍦?build_test_board/clear_board 涓纭竻鐞?
- advance_to_next_floor() 鏃犻渶棰濆淇敼锛坈lear_board 宸叉竻鐞嗘柊瀛楀吀锛?

## v0.1.49 - 2026-03-30

### 鏂板
- 鎺烽婕斿嚭鍗囩骇锛氫吉 3D 绛夎窛楠板瓙 + 鍏ㄥ睆灞呬腑婕斿嚭
- DiceRollAnimation.gd 瀹屽叏閲嶅啓锛垀252琛岋級锛?
  - 鍏ㄥ睆閬僵 PRESET_FULL_RECT锛孧OUSE_FILTER_STOP 闃绘绌块€?
  - 3 鏋氱瓑璺濈珛鏂逛綋锛堝叚杈瑰舰杞粨+涓夐潰鐫€鑹?楠伴潰绗﹀彿+鍚嶇О鏍囩锛?
  - 缈绘粴鈫掗€愪釜瀹氭牸鈫掓寔鏄锯啋娣″嚭 鍥涢樁娈靛姩鐢?
  - set_board_center() 鎺ュ彛锛屽眳涓簬妫嬬洏涓ぎ鑰岄潪鍙充晶闈㈡澘
- Main.gd 鍒涘缓 DiceRollAnimation 瀹炰緥骞朵紶鍏?DiceDebugPanel

### 淇敼
- DiceDebugPanel.gd锛氱Щ闄ゆ棫鍐呭祵楠板瓙鍒涘缓浠ｇ爜锛屾敼鐢?Main 浼犲叆澶栭儴寮曠敤
  - 鏂板 set_dice_animation(anim) 鏂规硶

### 澶囨敞
- 楠板瓙鍔ㄧ敾涓嶅啀涓?HUD 闈㈡澘閲嶅彔锛屽眳涓簬妫嬬洏鍖哄煙锛?28, 382锛?
- Tween 鍔ㄧ敾閾撅細閬僵娣″叆鈫掔炕婊氣啋閫愰瀹氭牸锛堝脊璺崇缉鏀?杈夊厜锛夆啋娣″嚭
- DiceRollAnimation 浣滀负 Main 鏈€鍚庝竴涓?add_child锛寊-order 鍦ㄦ渶涓婂眰

## v0.1.48 - 2026-03-30

### 鏂板
- 缇庡寲 Phase 4.1 瀹屾暣瀹炵幇锛氳儗鏅皼鍥村崌绾?
- CyberBackground.gd锛垀155琛岋級锛氳儗鏅皼鍥存覆鏌撶郴缁?
  - 涓夋娓愬彉鑳屾櫙锛?2绾ц壊闃讹紝娣辨殫钃濃啋鏆楄摑鐏扳啋寰寒钃濈伆锛?
  - 閫忚缃戞牸绾匡紙妫嬬洏涓嬫柟锛屾按骞崇嚎甯︽紓绉诲姩鐢?鍨傜洿绾夸腑蹇冩笎寮猴級
  - 娴姩绮掑瓙锛圕PUParticles2D锛?5涓摑鍏夊井绮掞紝Gradient 娣″叆娣″嚭锛?
  - 妫嬬洏鍙戝厜杈规锛?灞傚杈夊厜+鍐呭眰浜嚎+sin鑴夊啿鍛煎惛锛?
  - 鍥涜 L 褰㈣楗版爣璁帮紙闈掕壊鐭嚎锛?
  - 鍏ㄥ睆缂撴參鎵弿绾匡紙6px 鍗婇€忔槑闈掕壊鏉″惊鐜級

### 淇敼
- Main.gd锛氱函鑹?ColorRect 鑳屾櫙 鈫?CyberBackground 鍔ㄦ€佽儗鏅?
  - 鏂板 CyberBackground preload
  - set_board_rect() 浼犲叆妫嬬洏浣嶇疆(40,94)鍜屽昂瀵?576,576)

### 澶囨敞
- CyberBackground 绾瑙夊眰锛宮ouse_filter = IGNORE锛屼笉褰卞搷浠讳綍浜や簰
- CPUParticles2D gl_compatibility 瀹夊叏锛屼笉渚濊禆 GPU 绮掑瓙
- 棰滆壊甯搁噺瀹氫箟鍦ㄦ枃浠跺唴閮紙鑳屾櫙涓撶敤锛屼笉姹℃煋 CyberStyle锛?
- 鎵€鏈夊姩鐢荤敤 Time.get_ticks_msec() + sin() 椹卞姩锛屼笉鍒涘缓 Tween
- BattleFlowController/CardBattleController/BoardView 闆朵慨鏀?
- Phase 4.1 瀹屾垚鏍囧噯锛氱敾闈㈡湁璧涘崥鏈嬪厠姘涘洿鎰燂紝鑳屾櫙鏈夊姩鎬佸眰娆¤€岄潪绾壊

## v0.1.47 - 2026-03-30

### 鏂板
- 缇庡寲 Phase 3 瀹屾暣瀹炵幇锛氬崱鐗屾垬鏂楅潰鏉块噸璁捐
- CardRenderer.gd锛垀233琛岋級锛氬崱鐗屾覆鏌撳伐鍏风被
  - create_card()锛?0x108 鍗＄墝鎺т欢锛岀被鍨嬪浘鏍?閰嶈壊+璐圭敤+鏁板€?鎮诞鏁堟灉
  - 6绉嶅崱鐗岀被鍨嬬嫭绔嬮厤鑹诧細鏀诲嚮姗?绌块€忛噾/鍚歌鍝佺孩/鐢靛嚮绱?闃插尽钃?娌荤枟缁?
  - 鍗囩骇鍗＄墝锛氶潚鑹茶竟妗?鍙戝厜闃村奖锛屼笉鍙敤鍗＄墝锛氭殫鐏?鐏拌壊鏂囧瓧
  - create_hp_bar()锛氬渾瑙掑彲瑙嗗寲琛€鏉★紙濉厖+楂樺厜+鏁板€兼枃瀛楋紝<30%鍙樿壊锛?
  - create_energy_dots()锛氬渾瑙掑彂鍏夎兘閲忓渾鐐癸紙娲昏穬钃濆厜/娑堣€楁殫鐏帮級

### 淇敼
- CardBattlePanel.gd 閲嶅啓锛垀329琛岋級锛?
  - 鎵嬬墝锛?05x48 鏂囧瓧鎸夐挳 鈫?90x108 CardRenderer 鍗＄墝鎺т欢
  - HP 鏄剧ず锛氱函鏂囧瓧 鈫?鍙鍖栬鏉★紙鏁屾柟绾?鎴戞柟缁匡級
  - 鑳介噺鏄剧ず锛氭枃瀛?鈫?鍙戝厜鍦嗙偣锛堟渶澶?涓級
  - 鏁屾柟鎰忓浘锛氬鍔犲浘鏍囧墠缂€锛堚殧/鈿斺殧/鈻犫殧/鉁?鈿狅級+ 鐙珛閰嶈壊
  - 闈㈡澘灏哄锛?80x460 鈫?500x470
- Main.gd CardBattlePanel 浣嶇疆灞呬腑锛?280,140) 鈫?(390,125)

### 澶囨敞
- CardRenderer 绾潤鎬佽璁★紝涓?CyberStyle/BoardCellRenderer/UnitRenderer/BattleEffects 涓€鑷?
- HP 鏉?鑳介噺鐐归噰鐢?container 娓呯┖+閲嶅缓妯″紡锛岀畝鍗曞彲闈?
- CardBattleController 闆朵慨鏀癸紝鎵€鏈変俊鍙风鍚嶄笉鍙?
- CardRewardPanel 鏆傛湭鍚屾鍗囩骇锛堢嫭绔嬮潰鏉匡紝鍚庣画缁熶竴澶勭悊锛?
- gl_compatibility 瀹夊叏锛歅anel + StyleBoxFlat 鍦嗚锛屾棤 GPU 渚濊禆
- Phase 3 瀹屾垚鏍囧噯锛氬崱鐗屾垬鏂楅潰鏉跨湅璧锋潵鍍?鍗＄墝娓告垙"鑰岄潪"璋冭瘯鎸夐挳鍒楄〃"

## v0.1.0 - 2026-03-29

### Added

- created the parallel rebuild workspace `CyberTao_Dice_Beast_Protocol/`
- added top-level project documentation and technical blueprint
- created a standalone Godot subproject scaffold under `Project/`
- added a minimal entry scene and startup script
- added the first pass of the `BattleV2` architecture scaffold
- added resource script stubs for units, skills, items, cores, and dice faces
- added a dedicated `Logs/` folder for migration and version tracking
- added a reusable Mulerun handoff template for account-to-account continuity
- added the first debug board view and dice debug panel
- added a first prototype unit resource: blade shield dog

### Improved

- wired the main scene to the new BattleV2 managers
- added manager signals for board, units, phase, and dice roll updates
- spawned debug units and demo path support for the visual prototype
- expanded the skill data model for cooldown, targeting, and trait gating
- added the first skill resource definitions for blade shield dog
- added a reusable skill effect library stub for combat effect execution
- added a first explicit combat rules document for the prototype phase
- added the first pickup item resource set
- added the first dice face resource set
- added a second prototype faction unit: hacker fox
- added a content roadmap document for prototype batching
- added an item effect library stub
- added a third prototype unit: crow caster
- added first prototype core resource
- added a unit keyword reference document
- added first attack helper and target query support
- added prototype attack rule documentation
- added early attack-oriented skill resources for dog and fox units
- added first victory-rule helper for post-attack battle-end checks
- added explicit HP and victory rule documentation for prototype combat

### Notes

- legacy `CyberTao8` remains preserved as reference
- new development should prioritize the new `Project/` folder
- future updates should append to this changelog and keep migration snapshot in sync

## v0.1.1 - 2026-03-29

### Added

- unit selection: click a player unit on the board to select it (gold ring indicator)
- movable cell highlighting: BFS-based reachable cell calculation respecting move_range and occupied cells
- cyan highlight overlay on all valid move targets when a unit is selected
- click-to-move: click a highlighted cell to move the selected unit there
- MOVE crest cost: each move consumes 1 MOVE resource from the dice crest pool
- "Selected: ..." display in the debug panel showing current selection state
- debug panel auto-refreshes crest pool display after each move
- `BoardManager.get_reachable_cells()`: BFS within move_range, skipping occupied cells
- `UnitManager.board_manager` sync: spawn/move/despawn now keep `BoardManager.occupied_cells` in sync
- `UnitManager.unit_moved` signal for move event tracking
- `UnitManager.get_player_units()` helper
- `BattleFlowController.try_move_unit()`: validates reachability, pays MOVE crest, executes move
- `BattleFlowController.get_reachable_cells_for()`: delegates to BoardManager BFS
- `BattleFlowController.move_completed` signal
- `BoardView` signals: `unit_selected`, `unit_deselected`, `move_requested`
- `DiceDebugPanel.bind_board_view()` for selection event subscription
- `move_range` field now stored in unit state and passed from UnitData on spawn

### Changed

- `BoardView.mouse_filter` changed from `MOUSE_FILTER_IGNORE` to `MOUSE_FILTER_STOP` to enable click input
- debug panel height increased from 380 to 440 to accommodate new selected unit label
- `Main._wire_debug_views()` now connects board view signals and binds board view to debug panel

### Notes

- only player units can be selected and moved
- only orthogonal movement (up/down/left/right) is supported
- no attack system implemented yet
- no pathfinding beyond BFS range check
- no movement animation; position updates are instant

## v0.1.2 - 2026-03-29

### Fixed

- dice roll now limited to once per turn: `start_player_roll()` only executes during PLAYER_ROLL phase, then auto-transitions to PLAYER_ACTION
- Roll Dice button in debug panel is disabled after rolling (re-enabled only in PLAYER_ROLL phase)
- movable cell highlights now respect MOVE crest availability: `get_reachable_cells_for()` returns empty when MOVE <= 0
- highlights refresh immediately after every move attempt (success or failure), clearing when MOVE is exhausted

### Notes

- no "End Turn" button yet; to roll again after spending resources, a phase-reset mechanism is still needed
- the roll-once restriction is per phase transition, not a stored flag 鈥?future turn flow will manage this naturally

## v0.1.3 - 2026-03-29

### Added

- End Turn button in debug panel: ends player action phase and advances to next round
- `BattleFlowController.end_player_turn()`: clears crest pool, increments round_index, resets to PLAYER_ROLL
- `BattleFlowController.round_changed` signal emitted on round advance
- `DiceManager.reset_for_turn()`: clears crest pool and last roll results at turn boundary
- round number display ("Round: N") in debug panel
- End Turn button enabled only during PLAYER_ACTION, disabled otherwise
- BoardView deselects unit and clears highlights on any phase transition

### Changed

- debug panel height increased from 440 to 500 to accommodate End Turn button and round label
- debug panel layout reorganized: round label, phase label, selected label, Roll Dice, End Turn, Spawn Demo Path, roll results, crest pool
- `_on_phase_changed` now also refreshes crest pool display (shows zeroed pool after turn reset)

### Notes

- the minimum turn cycle now works: Roll Dice 鈫?move unit 鈫?End Turn 鈫?Roll Dice again
- crest pool is fully cleared at turn start (simple reset, no carry-over)
- no enemy turn yet; End Turn skips directly back to PLAYER_ROLL
- no attack system implemented

## v0.1.4 - 2026-03-29

### Added

- attack highlighting: red overlay on adjacent enemy cells when a player unit is selected and ATTACK crest > 0
- click-to-attack: clicking a red-highlighted enemy cell triggers a basic attack
- `BattleFlowController.try_attack_unit()`: validates adjacency, pays 1 ATTACK crest, applies damage via `AttackRuleHelper.calc_basic_damage()`
- `BattleFlowController.get_attackable_cells_for()`: delegates to `ActionResolver.get_attackable_cells()`, gated on ATTACK crest availability
- `BattleFlowController.attack_completed` signal (attacker_id, defender_id, damage, killed)
- `BoardView.attack_requested` signal for attack click events
- `BoardView.attack_highlight_cells` array for red attack target rendering
- `BoardView._draw_attack_highlights()`: red filled + red border rectangles on attackable cells
- `DiceDebugPanel._on_attack_completed()`: refreshes crest pool display after each attack
- `Main._on_attack_requested()`: wires attack signal, refreshes both move and attack highlights after attack
- if target HP <= 0, unit is despawned from board via existing `UnitManager.apply_damage()` 鈫?`despawn_unit()`

### Changed

- `_handle_cell_click()` now checks attack targets before move targets (attack takes priority on enemy-occupied cells)
- `_select_unit()` and `_on_state_changed()` now compute both move and attack highlights
- `_deselect()` now clears both highlight arrays
- `_on_move_requested()` now refreshes attack highlights alongside move highlights

### Notes

- minimum combat loop now works: Roll 鈫?Move 鈫?Attack 鈫?End Turn
- attack is melee-only (orthogonal adjacent, range 1)
- damage formula: max(1, attacker.atk - defender.def)
- no attack animation; damage is applied instantly
- no HP display on units yet
- no enemy turn or enemy AI
- no victory/defeat check on kill

## v0.1.5 - 2026-03-29

### Fixed

- `UnitManager.spawn_unit()` now stores `attack_range` in unit state (was missing, causing `ActionResolver.get_attackable_cells()` to always fall back to default)
- `BattleFlowController._spawn_debug_units()` now passes `attack_range` from `UnitData` resource for player unit and from hardcoded payload for enemy unit

### Notes

- this is a data-link fix only; no new features or behavior changes
- all units already defaulted to `attack_range = 1` via fallback, so visible behavior is unchanged for the current prototype
- the fix ensures future units with non-default attack_range will work correctly

## v0.1.6 - 2026-03-29

### Added

- HP display on all units: white `hp/max_hp` text drawn on each unit rectangle
- victory/defeat check after every attack using `VictoryRuleHelper.get_battle_outcome()`
- `BattleFlowController._check_battle_outcome()`: calls `mark_victory()` when all enemies dead, `mark_defeat()` when all player units dead
- `BattleFlowController.is_battle_over()`: returns true if phase is VICTORY or DEFEAT
- result banner label in Main scene: large "VICTORY" (green) or "DEFEAT" (red) text appears at top center
- debug panel phase label turns green on VICTORY, red on DEFEAT
- all buttons disabled on terminal phase (VICTORY/DEFEAT)
- board click input blocked when battle is over

### Changed

- `try_move_unit()`, `try_attack_unit()`, `start_player_roll()`, `end_player_turn()` all guard on `is_battle_over()`
- `_on_phase_changed` in DiceDebugPanel now handles terminal phases with colored text and full button disable
- `Main._wire_debug_views()` now connects `phase_changed` for result banner display

### Notes

- minimum combat prototype is now complete: Roll 鈫?Move 鈫?Attack 鈫?End Turn 鈫?Victory/Defeat
- HP is displayed as text overlay; no HP bar yet
- no restart mechanism after victory/defeat
- no enemy AI turn; enemy never fights back

## v0.1.7 - 2026-03-29

### Added

- display settings system: `DisplaySettings` node handles resolution, window mode, and persistence via `ConfigFile`
- settings panel UI (`SettingsPanel`): resolution dropdown (1280x720, 1600x900, 1920x1080), window mode dropdown (windowed, fullscreen, borderless), apply/reset/close buttons
- "璁剧疆" button in top-right corner of main scene opens settings panel
- settings saved to `user://display_settings.cfg` and loaded on startup
- `DisplayServer` API used for window mode switching, resize, and centering

### Changed

- default viewport changed from 1920x1080 to 1280x720 in `project.godot`
- `Main.gd` layout repositioned for 1280x720: board at (40,160), dice panel at (660,160), labels resized to 1280 width
- `Main.gd` now preloads and instantiates `DisplaySettings` and `SettingsPanel`

### Notes

- settings panel appears centered over the board when opened
- resolution change takes effect immediately on "搴旂敤" (apply)
- "鎭㈠榛樿" resets to 1280x720 windowed
- battle prototype functionality unchanged

## v0.1.8 - 2026-03-29

### Fixed

- `DiceDebugPanel.bind_battle_flow()` round label initialization used English "Round: " instead of Chinese "鍥炲悎锛? 鈥?now consistent with all other Chinese UI text

### Notes

- all three UI scripts (Main.gd, DiceDebugPanel.gd, SettingsPanel.gd) verified as valid UTF-8 with correct Chinese encoding
- no logic changes, text-only fix

## v0.1.9 - 2026-03-29

### Fixed

- rewrote all three UI scripts (Main.gd, DiceDebugPanel.gd, SettingsPanel.gd) from scratch via Python with Unicode escape sequences to guarantee clean UTF-8 Chinese encoding
- all Chinese text strings verified byte-by-byte after rewrite

### Notes

- no logic or layout changes; identical behavior to v0.1.8
- rewrite approach used to eliminate any possible encoding layer corruption

## v0.1.10 - 2026-03-29

### Fixed

- board click interaction restored: `bg` ColorRect, title/subtitle/hint labels, and `_result_label` now set `mouse_filter = MOUSE_FILTER_IGNORE` so they never intercept clicks meant for the board
- `SettingsPanel` now starts with `mouse_filter = MOUSE_FILTER_IGNORE` (was `MOUSE_FILTER_STOP`); toggles to `STOP` only when opened, back to `IGNORE` on close 鈥?prevents invisible panel from blocking board clicks in its overlapping region
- `BoardView._gui_input()` now calls `accept_event()` after handling a click to properly consume the input event

### Notes

- root cause: Controls in Godot 4 default to `MOUSE_FILTER_STOP`, which can intercept mouse events even for purely decorative nodes; the full-screen `bg` ColorRect and full-width labels were potential input blockers
- `SettingsPanel` at position (440,200) size 400x320 overlapped the board at (40,160) size 576x576 鈥?with `MOUSE_FILTER_STOP` while invisible, it could block clicks in the overlap zone [440,200]-[616,520]
- no logic, layout, or feature changes 鈥?interaction-only fix

## v0.1.11 - 2026-03-29

### Changed

- guaranteed minimum 1 MOVE crest per dice roll: if random roll produces 0 MOVE, pool is set to 1 MOVE after rolling
- enemy debug unit spawn position moved from (7,1) to (3,4) 鈥?manhattan distance to player reduced from 12 to 5

### Notes

- prototype playability fix: with 3 dice and 6 faces, probability of 0 MOVE per roll was 57.9% 鈥?most turns were unplayable
- guaranteed MOVE ensures every turn has at least 1 movement action available
- new enemy position (3,4) means player at (0,6) can reach and attack within 2-3 rounds
- no new features, no enemy AI, no visual changes

## v0.1.12 - 2026-03-29

### Added

- attack feedback: white flash on hit cell (tween fade 0.35s) + red floating damage number (-N) that rises and fades out (0.6s)
- `BoardView.play_attack_feedback()`: creates flash overlay via `_draw_attack_flash()` and spawns a temporary Label for damage number with position+alpha tween
- "閲嶆柊寮€濮? (restart) button appears on VICTORY or DEFEAT phase, positioned at top center
- `BattleFlowController.restart_battle()`: resets dice, clears all units, rebuilds board, re-spawns debug units, returns to round 1 PLAYER_ROLL
- `UnitManager.clear_all_units()`: clears all unit state and occupied cells
- `BoardManager.clear_board()`: clears occupied, path, and item cells
- `Main._on_attack_completed()`: captures damage for feedback display
- `Main._on_restart_pressed()`: clears board selection and triggers battle restart

### Changed

- `Main._on_phase_changed()` now shows/hides restart button alongside result label
- `Main._on_attack_requested()` triggers `play_attack_feedback()` on successful attack

### Notes

- attack feedback is visual only 鈥?no sound effects
- restart fully resets to initial state (same as fresh load)
- no enemy AI; enemy still does not act

## v0.1.13 - 2026-03-29

### 鏂板

- 鏁屾柟 AI 鏈€灏忓洖鍚堬細鐜╁鐐瑰嚮"缁撴潫鍥炲悎"鍚庯紝杩涘叆 ENEMY_ROLL 鈫?ENEMY_ACTION 鈫?鑷姩鍥炲埌 PLAYER_ROLL
- `BattleAI` 閲嶅啓锛氭坊鍔?`get_enemy_units()`銆乣find_nearest_player_cell()`銆乣get_adjacent_player_cells()`銆乣pick_move_toward()` 鍥涗釜鏍稿績鏂规硶
- `BattleFlowController` 娣诲姞 `_start_enemy_turn()`銆乣_execute_enemy_actions()`銆乣_advance_to_next_player_round()` 涓変釜鏁屾柟鍥炲悎鏂规硶
- `BattleFlowController` 娣诲姞 `enemy_attack_completed` 淇″彿锛堝寘鍚?target_cell 鍙傛暟锛?
- 鏁屾柟鏀诲嚮鏃跺湪鐩爣鏍兼樉绀虹櫧鑹查棯鍏?+ 绾㈣壊椋樺瓧锛堜笌鐜╁鏀诲嚮鍙嶉涓€鑷达級
- `DiceDebugPanel` 杩炴帴 `enemy_attack_completed` 淇″彿锛屾晫鏂规敾鍑诲悗鍒锋柊 crest 姹犳樉绀?

### 淇敼

- `end_player_turn()` 涓嶅啀鐩存帴璺冲洖 PLAYER_ROLL锛屾敼涓鸿Е鍙戞晫鏂瑰洖鍚堟祦绋?
- 鏁屾柟鍥炲悎鏈熼棿锛屾幏楠版寜閽拰缁撴潫鍥炲悎鎸夐挳鑷姩绂佺敤
- 璋冭瘯闈㈡澘闃舵鏍囩姝ｇ‘鏄剧ず"鏁屾柟鎺烽"/"鏁屾柟琛屽姩"

### 鏁屾柟 AI 琛屼负

- 閬嶅巻鎵€鏈夊瓨娲绘晫鏂瑰崟浣?
- 浼樺厛鏀诲嚮锛氬鏋滅浉閭绘湁鐜╁鍗曚綅涓旀湁 ATTACK crest 鈫?鏀诲嚮锛堟秷鑰?1 ATTACK锛?
- 鍚﹀垯绉诲姩锛氭湞鏈€杩戠帺瀹跺崟浣嶆柟鍚戠Щ鍔?1 鏍硷紙娑堣€?1 MOVE锛?
- 绉诲姩鍚庡啀鏀诲嚮锛氱Щ鍔ㄥ悗濡傛灉鐩搁偦鏈夌帺瀹跺崟浣嶄笖鏈?ATTACK crest 鈫?鍐嶆鏀诲嚮
- 浣跨敤 await timer 鍦ㄨ鍔ㄤ箣闂存坊鍔犵煭寤惰繜锛?.3s-0.5s锛夛紝璁╃帺瀹跺彲浠ヨ瀵熸晫鏂硅涓?

### 澶囨敞

- 鏁屾柟 AI 涓烘渶灏忓彲鐢ㄥ疄鐜帮紝涓嶅寘鍚珮绾х瓥鐣ユ垨琛屼负鏍?
- 鏁屾柟鎺烽浣跨敤涓庣帺瀹剁浉鍚岀殑 DiceManager锛堜繚搴?1 MOVE锛?
- 绉诲姩浠嶄负鐬棿浣嶇Щ锛屾棤鍔ㄧ敾
- 褰撳墠鍙湁 1 涓皟璇曟晫鏂瑰崟浣?

## v0.1.14 - 2026-03-29

### 鏂板

- 鍙敜绯荤粺鍘熷瀷锛坰ummon + path-building 绗竴鐗堬級
- `BattleFlowController` 娣诲姞 `summon_completed` 淇″彿銆乣get_summon_cells_for()`銆乣try_summon()` 鏂规硶
- `BoardManager` 娣诲姞 `get_free_neighbors()` 杈呭姪鏂规硶
- `BoardView` 娣诲姞 `summon_requested` 淇″彿鍜?`summon_highlight_cells` 绱壊楂樹寒娓叉煋
- 妫嬬洏鐐瑰嚮鍙敜锛氶€変腑鐜╁鍗曚綅涓旀湁 SUMMON crest 鏃讹紝鐩搁偦绌烘牸鏄剧ず绱壊楂樹寒锛岀偣鍑诲嵆瑙﹀彂鍙敜
- 璋冭瘯闈㈡澘"娴嬭瘯鍙敜"鎸夐挳锛氶渶閫変腑鍗曚綅 + 鏈夋樉鍖?crest锛屼竴閿湪绗竴涓彲鐢ㄦ牸鍙敜
- 鍙敜鏃惰嚜鍔ㄩ摵璁?2 鏍艰矾寰勶紙鐩爣鏍?+ 鍚戝寤朵几 1 鏍硷級锛屽綊灞?player
- 鍙敜鍦ㄧ洰鏍囨牸鐢熸垚 summoned_fox 娴嬭瘯鍗曚綅锛圚P 4 / ATK 2 / DEF 0 / 绉诲姩 2 / 鏀诲嚮 1锛?
- 姣忔鍙敜鐢熸垚鍞竴 ID锛坰ummoned_fox_1, summoned_fox_2, ...锛?
- 璺緞鏍煎彲瑙嗗寲鏀硅繘锛氱帺瀹惰矾寰勪负闈掕壊鍙戝厜銆佸叾浠栬矾寰勪负姗欒壊

### 淇敼

- `BoardView._draw_paths()` 閲嶅啓锛氬尯鍒?player/other 璺緞棰滆壊锛屾坊鍔犺竟妗嗘覆鏌?
- 璋冭瘯闈㈡澘"鐢熸垚娴嬭瘯璺緞"鎸夐挳鏇挎崲涓?娴嬭瘯鍙敜锛堥渶閫変腑鍗曚綅+鏄惧寲锛?
- `Main.gd` 鎻愮ず鏂囧瓧鏇存柊涓?闈掕壊=绉诲姩 绾㈣壊=鏀诲嚮 绱壊=鍙敜閾鸿矾"
- 绉诲姩銆佹敾鍑诲悗鍚屾椂鍒锋柊鍙敜楂樹寒
- 閲嶅紑鎴樻枟鏃舵竻绌?summon_highlight_cells 鍜?_summon_counter

### 澶囨敞

- 鏈疆涓烘渶灏忓師鍨嬶紝楠岃瘉"鍙敜鍗抽摵璺?姒傚康
- 鍙敜鍗曚綅涓?hardcoded 鏁版嵁锛屾湭鎺ュ叆 UnitData 璧勬簮
- 璺緞鏍肩洰鍓嶄笉褰卞搷绉诲姩瑙勫垯锛堜粎瑙嗚鏍囪锛?
- 鏃犲彫鍞ゅ姩鐢汇€佹棤鍙敜鏁伴噺闄愬埗
- 璺緞褰㈢姸鍥哄畾涓?2 鏍肩洿绾垮欢浼?

## v0.1.15 - 2026-03-29

### 鏂板

- 鍦板舰绯荤粺鍘熷瀷锛堥珮鍙版牸 + 闄烽槺鏍?绗竴鐗堬級
- `BoardManager` 娣诲姞 `terrain_cells` 瀛楀吀銆乣add_terrain_cell()`銆乣get_terrain_type()`銆乣get_move_cost()` 鏂规硶
- 楂樺彴鏍艰鍒欙細杩涘叆楂樺彴鏍兼秷鑰?2 绉诲姩鐐癸紙鏅€氭牸 1 鐐癸級锛涚珯鍦ㄩ珮鍙颁笂鏀诲嚮鑼冨洿 +1
- 闄烽槺鏍艰鍒欙細鍗曚綅杩涘叆闄烽槺鏍兼椂绔嬪嵆鍙楀埌 1 鐐逛激瀹筹紝鍙嚧姝诲苟瑙﹀彂鑳滆礋鍒ゅ畾
- `BattleFlowController` 娣诲姞 `terrain_damage_triggered` 淇″彿鍜?`_check_terrain_trap()` 鏂规硶
- `BattleFlowController._spawn_debug_terrain()`锛氶缃?2 涓珮鍙版牸 (2,4)(2,5) 鍜?2 涓櫡闃辨牸 (1,5)(3,6)
- `ActionResolver.get_attackable_cells()` 楂樺彴鍔犳垚锛氭娴嬪崟浣嶆槸鍚︾珯鍦ㄩ珮鍙颁笂锛屾槸鍒?attack_range += 1
- `BoardView._draw_terrain()`锛氶珮鍙版牸閲戣壊濉厖+杈规+"HIGH"鏍囪鏂囧瓧锛岄櫡闃辨牸鏆楃孩濉厖+杈规+"TRAP"鏍囪鏂囧瓧
- 鍦板舰涓庤矾寰勬牸鍙叡瀛橈紙terrain_cells 鍜?path_cells 鐙珛瀛樺偍锛?
- 闄烽槺浼ゅ瑙﹀彂鏀诲嚮鍙嶉锛堢櫧鑹查棯鍏?+ 绾㈣壊椋樺瓧锛?
- 鎻愮ず鏂囧瓧鏇存柊锛?閲戣壊=楂樺彴 鏆楃孩=闄烽槺"

### 淇敼

- `BoardManager.get_reachable_cells()` BFS 閲嶅啓锛氫粠鍥哄畾 cost=1 鏀逛负浣跨敤 `get_move_cost()` 璁＄畻姣忔牸绉诲姩娑堣€?
- `BoardManager.build_test_board()` 鍜?`clear_board()` 鐜板湪娓呯┖ `terrain_cells`
- `BattleFlowController.try_move_unit()` 绉诲姩鍚庢鏌ラ櫡闃卞湴褰?
- `BattleFlowController._execute_enemy_actions()` 鏁屾柟绉诲姩鍚庢鏌ラ櫡闃卞湴褰?
- `BattleFlowController.restart_battle()` 閲嶅紑鏃堕噸鏂版斁缃皟璇曞湴褰?
- `DiceDebugPanel` 杩炴帴 `terrain_damage_triggered` 淇″彿锛屽湴褰激瀹冲悗鍒锋柊 crest 姹犳樉绀?

### 澶囨敞

- 鍦板舰鏍间负绾暟鎹爣璁帮紝涓嶉樆鎸＄Щ鍔紙楂樺彴鍙槸娑堣€楁洿澶氾紝涓嶆槸涓嶅彲杩涘叆锛?
- 闄烽槺鏍煎彲閲嶅瑙﹀彂锛堟瘡娆¤繘鍏ラ兘鍙椾激锛?
- 褰撳墠鍙湁 hardcoded 璋冭瘯甯冨眬锛屾棤鍦板舰缂栬緫鍣?
- 楂樺彴鏀诲嚮鍔犳垚瀵圭帺瀹跺拰鏁屾柟鍧囩敓鏁堬紙ActionResolver 涓嶅尯鍒嗛樀钀ワ級
- 鏃犲湴褰㈢浉鍏冲姩鐢绘垨闊虫晥

## v0.1.16 - 2026-03-29

### 淇

- 淇鏁屾柟鍗曚綅韪╅櫡闃辨浜″悗浠嶅皾璇曟敾鍑荤殑 bug锛歚_execute_enemy_actions()` 鍦ㄩ櫡闃辨鏌ュ悗澧炲姞鍗曚綅瀛樻椿鍒ゅ畾锛屾浜″垯璺宠繃鍚庣画鏀诲嚮
- 淇閫変腑鍗曚綅琚嚮鏉€鍚庢畫鐣欏菇鐏甸€変腑鐘舵€佺殑 bug锛歚BoardView._on_state_changed()` 妫€娴嬮€変腑鍗曚綅鏄惁浠嶅瓨娲伙紝涓嶅瓨鍦ㄥ垯鑷姩鍙栨秷閫変腑

### 澶囨敞

- 鏈疆涓?summon / path-building 绗竴鐗堟敹鍙ｏ紝鍙慨绋冲畾鎬ч棶棰橈紝涓嶅鍔犳柊鍔熻兘
- 瀹℃煡浜嗗彫鍞ゆ祦绋嬨€佽矾寰勬牸鐢熸垚銆佸彫鍞ゅ崟浣嶈惤浣嶃€佸彫鍞ゅ悗瀵瑰師鏈夐棴鐜殑褰卞搷
- 瀹℃煡纭浠ヤ笅娴佺▼鍦ㄥ彫鍞ゅ悗鍧囨甯革細閫変腑鍗曚綅銆丮OVE 绉诲姩銆丄TTACK 鏀诲嚮銆佹晫鏂瑰洖鍚堛€乂ictory/Defeat銆侀噸鏂板紑濮?
- 鍙敜璧勬簮娑堣€楋紙SUMMON crest锛夈€佽矾寰勬牸瑙嗚鍖哄垎銆佽矾寰勬牸涓庡崟浣嶅叡瀛橀€昏緫鍧囩ǔ瀹?

## v0.1.17 - 2026-03-29

### 淇

- 淇妫嬬洏搴曢儴琚鍒囩殑甯冨眬闂锛氭爣棰樺尯浠?160px 鍘嬬缉鍒?94px锛屾鐩樺簳閮ㄤ粠 736 闄嶈嚦 670锛屽畬鍏ㄥ湪 720 瑙嗗彛鍐?
- 淇鍒嗚鲸鐜囪缃棤瑙嗚鏁堟灉鐨勯棶棰橈細`DisplaySettings.apply_settings()` 鐜板湪鍚屾鏇存柊 `root.content_scale_size`锛屼娇涓嶅悓鍒嗚鲸鐜囨湁鐪熷疄瑙嗚鍙樺寲

### 淇敼

- `Main.gd` 甯冨眬閲嶆帓锛氭爣棰?y=4锛堝師 42锛夈€佸壇鏍囬 y=44锛堝師 96锛夈€佹彁绀?y=68锛堝師 126锛夈€佹鐩?璋冭瘯闈㈡澘 y=94锛堝師 160锛?
- 鏍囬瀛楀彿 30锛堝師 34锛夈€佸壇鏍囬瀛楀彿 16锛堝師 18锛夈€佹彁绀哄瓧鍙?13锛堝師 15锛?
- 鑳滆礋鏍囩鍜岄噸寮€鎸夐挳浣嶇疆鍚屾璋冩暣
- `DisplaySettings.apply_settings()` 鏂板 `root.content_scale_size` 鏇存柊

### 澶囨敞

- 妫嬬洏搴曡竟 94+576=670锛岃窛瑙嗗彛搴曢儴 720 鏈?50px 浣欓噺
- 鍒嗚鲸鐜囧垏鎹㈡晥鏋滐細1280x720 涓烘爣鍑嗗竷灞€锛?600x900/1920x1080 绐楀彛鍜岃櫄鎷熻鍙ｅ悓姝ユ斁澶?
- 鏃犲姛鑳介€昏緫鍙樺寲锛岀函甯冨眬鍜屾樉绀轰慨澶?

## v0.1.18 - 2026-03-29

### 淇

- 淇鐐瑰嚮绉诲姩鏃惰瑙﹀彫鍞ょ殑涓ラ噸 bug锛氱浉閭荤┖鏍煎悓鏃舵弧瓒崇Щ鍔ㄥ拰鍙敜鏉′欢鏃讹紝鍘熶唬鐮佷紭鍏堟墽琛屽彫鍞よ€岄潪绉诲姩锛屽鑷存剰澶栫敓鎴?4/4 "鍒嗚韩"鍗曚綅
- 鐐瑰嚮浼樺厛绾т粠 attack > summon > move 鏀逛负 attack > move > summon
- 鍙敜绱壊楂樹寒鐜板湪鎺掗櫎宸插湪绉诲姩楂樹寒涓殑鏍煎瓙锛屼粎鍦?涓嶅彲绉诲姩浣嗗彲鍙敜"鐨勬牸瀛愭樉绀虹传鑹?
- `BoardView._filter_summon_cells()`锛氭柊澧炶緟鍔╂柟娉曪紝浠庡彫鍞ゅ€欓€夋牸涓Щ闄ょЩ鍔ㄥ€欓€夋牸
- `Main.gd` 鎵€鏈夐珮浜埛鏂扮偣锛堢Щ鍔ㄥ悗銆佹敾鍑诲悗銆佸彫鍞ゅ悗锛夊潎浣跨敤杩囨护鍚庣殑鍙敜楂樹寒

### 澶囨敞

- 鏍瑰洜锛歛djacent free cells 鍚屾椂瀛樺湪浜?BFS 鍙揪闆嗗拰鍙敜鍊欓€夐泦锛屽師 summon 浼樺厛瀵艰嚧璇Е
- 淇鍚庤涓猴細鏈?MOVE crest 鏃剁偣鍑荤浉閭绘牸 = 绉诲姩锛涙棤 MOVE 浣嗘湁 SUMMON 鏃?= 鍙敜
- 璋冭瘯闈㈡澘"娴嬭瘯鍙敜"鎸夐挳涓嶅彈褰卞搷锛屽缁堝彲鐢?

## v0.1.19 - 2026-03-29

### 鏂板

- 鍗曚綅鍦板舰閫傛€х郴缁熺涓€鐗堬細姣忕鍗曚綅鎷ユ湁涓嶅悓鐨勫湴褰㈤€傛€ф爣绛撅紝褰卞搷鎴樻枟琛ㄧ幇
- `UnitData.gd` 鏂板 `terrain_affinity` 瀛楁锛?high_ground" / "path" / "trap"锛?
- 鍒€鐩剧嫍锛坆lade_shield_dog锛夛細璺緞閫傛€?鈥?绔欏湪璺緞鏍间笂 DEF +1
- 鐏电嫄楠囧锛坔acker_fox锛夛細闄烽槺閫傛€?鈥?鍏嶇柅闄烽槺浼ゅ
- 楦︽満鏈＋锛坈row_caster锛夛細楂樺彴閫傛€?鈥?楂樺彴鏀诲嚮鑼冨洿鍔犳垚 +2锛堥潪閫氱敤鐨?+1锛?
- 涓変釜 .tres 鍗曚綅鏂囦欢鍧囨坊鍔?`terrain_affinity` 灞炴€?
- `BattleFlowController._calc_damage_with_terrain()`锛氬惈鍦板舰閫傛€у姞鎴愮殑浼ゅ璁＄畻锛堣矾寰勬牸 DEF +1锛?
- `BattleFlowController._check_terrain_trap()` 澧炲姞闄烽槺閫傛€у厤鐤鏌?
- `ActionResolver.get_attackable_cells()` 楂樺彴閫傛€у崟浣嶅湪楂樺彴涓婃敾鍑昏寖鍥?+2
- `UnitManager.spawn_unit()` 鏂板 `terrain_affinity` 鍜?`display_name` 瀛楁浼犻€?
- `BoardView._draw_unit_names()`锛氬崟浣嶅悕绉扮缉鍐欐樉绀猴紙鍖哄垎涓嶅悓鍗曚綅锛?
- `BoardView._draw_terrain_affinity_indicator()`锛氬崟浣嶇珯鍦ㄥ尮閰嶅湴褰笂鏃舵樉绀?* 鎸囩ず鍣?
- 璋冭瘯甯冨眬鍗囩骇涓?3 涓帺瀹跺崟浣?+ 2 涓晫鏂瑰崟浣?
- 鎻愮ず鏍忔柊澧?"*=閫傛€ф縺娲? 璇存槑

### 淇敼

- `_spawn_debug_units()` 閲嶅啓锛氱敓鎴愬垁鐩剧嫍(0,6)銆佺伒鐙愰獓瀹?1,7)銆侀甫鏈烘湳澹?0,5) 涓変釜鐜╁鍗曚綅
- 鏁屾柟浠?1 涓鍔犲埌 2 涓細鍝ㄥ叺鐢?3,4) HP5/ATK2 + 鍝ㄥ叺涔?5,3) HP4/ATK3
- 鎵€鏈変激瀹宠绠楋紙鐜╁鏀诲嚮銆佹晫鏂规敾鍑伙級缁熶竴浣跨敤 `_calc_damage_with_terrain()`

### 澶囨敞

- 涓夌閫傛€ф晥鏋滅畝娲佷笖浜掍笉閲嶅彔锛氭敾鍑诲寮猴紙楂樺彴锛夈€侀槻寰″寮猴紙璺緞锛夈€佺敓瀛樺寮猴紙闄烽槺锛?
- 閫傛€ф縺娲婚渶瑕?绔欏湪鍖归厤鍦板舰涓?锛岄紦鍔卞湴褰㈢瓥鐣?
- 鏁屾柟鍗曚綅鏆傛棤鍦板舰閫傛€э紙鍙湪 AI 澧炲己鐗堟湰涓坊鍔狅級
- 鍙敜鍗曚綅鏆傛棤鍦板舰閫傛€?

## v0.1.20 - 2026-03-29

### 鏂板

- 閬撳叿鎷惧彇绯荤粺绗竴鐗堬細妫嬬洏涓婃斁缃彲鎷惧彇閬撳叿鏍硷紝鍗曚綅绉诲姩缁忚繃鏃惰嚜鍔ㄦ嬀鍙?
- `BattleFlowController._spawn_debug_items()`锛氶缃?2 涓亾鍏锋牸锛堣ˉ涓佸噳鑼?+ 瓒呴楠ㄥご锛?
- `BattleFlowController._check_item_pickup()`锛氬崟浣嶇Щ鍔ㄥ悗妫€鏌ョ洰鏍囨牸鏄惁鏈夐亾鍏?
- `BattleFlowController._apply_item_effect()`锛氭墽琛岄亾鍏锋晥鏋滃苟杩斿洖鏁堟灉鎻忚堪
- `BattleFlowController.item_picked_up` 淇″彿锛坲nit_id, item_id, effect_text, cell锛?
- 鎺ュ叆 `ItemEffectLibrary`锛? 绉嶉亾鍏锋晥鏋滀粠 stub 鍙樹负瀹為檯鐢熸晥
  - 琛ヤ竵鍑夎尪锛坧atch_tea_cache锛夛細鍥炲 2 HP
  - 瓒呴楠ㄥご锛坥verclock_bone锛夛細+1 MOVE crest
  - 鏁呴殰闆堕鐩掞紙glitch_snack_box锛夛細闅忔満 +1 ATTACK/DEFEND/SKILL crest
- `BoardView._draw_items()`锛氱豢鑹插～鍏?杈规+閬撳叿鍚嶇О缂╁啓娓叉煋
- `BoardView.play_pickup_feedback()`锛氭嬀鍙栨椂缁胯壊椋樺瓧鏄剧ず鏁堟灉锛圚P+2 / MOVE+1 绛夛級
- `DiceDebugPanel` 杩炴帴 `item_picked_up` 淇″彿锛屾嬀鍙栧悗鍒锋柊 crest 姹犳樉绀?
- `Main.gd` 杩炴帴 `item_picked_up` 淇″彿锛岃Е鍙戞嬀鍙栧弽棣?
- 鎻愮ず鏍忔柊澧?"缁胯壊=閬撳叿" 璇存槑

### 淇敼

- `try_move_unit()` 绉诲姩鍚庡鍔犻亾鍏锋嬀鍙栨鏌ワ紙闄烽槺妫€鏌ヤ箣鍚庯紝纭繚瀛樻椿鎵嶆嬀鍙栵級
- `restart_battle()` 閲嶅紑鏃堕噸鏂版斁缃皟璇曢亾鍏?
- `BoardManager.item_cells` 瀛楀吀浠庢閾惧彉涓哄疄闄呬娇鐢?

### 澶囨敞

- 閬撳叿鏍艰鎷惧彇鍚庝粠妫嬬洏娑堝け锛堜笉鍙噸澶嶆嬀鍙栵級
- 褰撳墠涓哄浐瀹氭斁缃紝涓嶆敮鎸侀殢鏈虹敓鎴?
- 浠呯帺瀹跺崟浣嶈Е鍙戞嬀鍙栵紝鏁屾柟绉诲姩涓嶈Е鍙?
- 閬撳叿鏁堟灉涓哄嵆鏃剁敓鏁堬紝鏃犳寔缁?buff锛圔uffManager.tick_turn 浠嶆湭鎺ュ叆锛?
- 琛ヤ竵鍑夎尪鍥炲涓嶈秴杩?max_hp

## v0.1.21 - 2026-03-29

### 鏂板

- 鏁屾柟 AI 鍙鎬у寮虹涓€鐗堬細鎰忓浘骞挎挱 + 鍔犻暱鍋滈】 + 鏀诲嚮棰勮
- `BattleFlowController` 鏂板 `enemy_action_announced` 淇″彿锛氭瘡涓晫鏂硅鍔ㄥ墠骞挎挱鎰忓浘锛?鍝ㄥ叺鐢?鈫?鏀诲嚮 鍒€鐩剧嫍"锛?
- `BattleFlowController` 鏂板 `enemy_turn_ended` 淇″彿锛氭墍鏈夋晫鏂硅鍔ㄥ畬鎴愬悗骞挎挱
- `BattleFlowController._get_unit_display_name()`锛氱粺涓€鑾峰彇鍗曚綅鏄剧ず鍚嶇О
- `BoardView.play_enemy_warning()`锛氭敾鍑绘剰鍥惧箍鎾椂鐩爣鏍兼鑹查璀﹂棯鐑侊紙0.6s锛?
- `BoardView.play_enemy_move_indicator()`锛氱Щ鍔ㄦ剰鍥炬寚绀猴紙姗欒壊鍗曚綅鍚嶇О娓愰殣锛?
- `DiceDebugPanel` 鏂板 `enemy_intent_label`锛氭鑹叉爣绛惧疄鏃舵樉绀烘晫鏂硅鍔ㄥ唴瀹?
- 鏁屾柟鍥炲悎缁撴潫鏃堕潰鏉挎樉绀?"鏁屾柟鍥炲悎缁撴潫"
- 鐜╁闃舵寮€濮嬫椂鑷姩娓呯┖鎰忓浘鏂囧瓧

### 淇敼

- `_execute_enemy_actions()` 閲嶅啓锛氭瘡姝ヨ鍔ㄥ墠骞挎挱鎰忓浘銆佺瓑寰呴璇绘椂闂村悗鍐嶆墽琛?
- 鏁屾柟琛屽姩鍋滈】鏃堕棿鍏ㄩ潰鍔犻暱锛氭幏楠?0.5鈫?.8s锛屾敾鍑诲悗 0.4鈫?.7s锛岀Щ鍔ㄥ悗 0.3鈫?.6s
- 姣忔琛屽姩鍓嶆柊澧炴剰鍥鹃璇荤瓑寰咃細鏀诲嚮 0.6s锛岀Щ鍔?0.5s
- 鏁屾柟鍥炲悎缁撴潫鍚庢柊澧?0.5s 杩囨浮绛夊緟鍐嶅洖鍒扮帺瀹跺洖鍚?
- `DiceDebugPanel.crest_label` 楂樺害浠?180 缂╁噺涓?140锛屼负鎰忓浘鏍囩鑵惧嚭绌洪棿

### 澶囨敞

- AI 鍐崇瓥閫昏緫鏈彉锛堜粛涓虹畝鍗曠殑浼樺厛鏀诲嚮/鏈濇渶杩戠帺瀹剁Щ鍔級
- 鏈疆浠呮敼鍠勫彲璇绘€э紝涓嶅鍔?AI 绛栫暐澶嶆潅搴?
- 闈㈡澘鍙樉绀烘渶鍚庝竴鏉℃剰鍥撅紝涓嶄繚鐣欐晫鏂硅鍔ㄥ巻鍙叉棩蹇?
- 棰勮闂儊浣跨敤涓庢敾鍑诲弽棣堢浉鍚岀殑 `_flash_cell` 鏈哄埗锛屼笉浼氬悓鏃跺鏍奸棯鐑?

## v0.1.22 - 2026-03-29

### 鏂板

- 閬亣鏍煎師鍨嬪叆鍙ｏ紙Day 6锛氭鐩樿蛋浣嶅眰鎵╁睍锛?
- `BoardManager` 鏂板 `encounter_cells` 瀛楀吀锛坈ell 鈫?encounter_id锛?
- `BoardManager.add_encounter_cell()`锛氭坊鍔犻伃閬囨牸锛屽惈杈圭晫妫€鏌?
- `BoardManager.clear_encounter_cell()`锛氭竻闄ゆ寚瀹氶伃閬囨牸
- `BattleFlowController` 鏂板 `encounter_triggered` 淇″彿锛坲nit_id, encounter_id, cell锛?
- `BattleFlowController._spawn_debug_encounters()`锛氶缃?2 涓伃閬囨牸 (4,4) encounter_01銆?6,5) encounter_02
- `BattleFlowController._check_encounter()`锛氱帺瀹跺崟浣嶇Щ鍔ㄥ埌閬亣鏍兼椂瑙﹀彂閬亣淇″彿
- `BoardView._draw_encounters()`锛氶伃閬囨牸娓叉煋涓烘绾㈣壊濉厖 + 杈规 + "閬亣" 鏂囧瓧鏍囪
- `BoardView.play_encounter_feedback()`锛氶伃閬囪Е鍙戞椂姗欑孩鑹查瀛楀弽棣堬紙"閬亣锛?涓婃诞娓愰殣 0.9s锛?
- `DiceDebugPanel` 杩炴帴 `encounter_triggered` 淇″彿锛岃Е鍙戞椂鏄剧ず "閬亣锛佸噯澶囪繘鍏ユ垬鏂?.. [encounter_id]"
- `Main.gd` 杩炴帴 `encounter_triggered` 淇″彿锛岃Е鍙戞绾㈤瀛楀弽棣?
- 鎻愮ず鏍忔柊澧?"姗欑孩=閬亣" 璇存槑

### 淇敼

- `BoardManager.build_test_board()` 鍜?`clear_board()` 鐜板湪娓呯┖ `encounter_cells`
- `BattleFlowController.try_move_unit()` 绉诲姩鍚庡鍔犻伃閬囨牸妫€鏌ワ紙閬撳叿鎷惧彇涔嬪悗锛?
- `BattleFlowController._bootstrap()` 鍜?`restart_battle()` 璋冪敤 `_spawn_debug_encounters()`

### 澶囨敞

- 鏈疆涓洪伃閬囧叆鍙ｆ渶灏忛獙璇侊紝涓嶅垏鍦烘櫙銆佷笉瀹炵幇鍗＄墝鎴樻枟
- 褰撳墠韪╅伃閬囨牸鍙Е鍙戜俊鍙峰拰鍗犱綅鎻愮ず锛屼笉鏆傚仠妫嬬洏娴佺▼
- 閬亣鏍艰俯鍚庝笉娑堝け锛圖ay 7 閬亣鏆傚仠娴佺▼涓鐞嗘竻闄ら€昏緫锛?
- 閬亣鏍间綅缃細(4,4) 鍦ㄧ帺瀹跺墠杩涜矾绾夸腑娈碉紝(6,5) 鍦ㄤ晶缈煎彲閫夌粫琛?
- 涓?Day 7锛堥伃閬囨殏鍋滐級鍜?Day 9锛堝崱鐗屾垬鏂楋級棰勭暀浜嗕俊鍙锋帴鍙?

## v0.1.23 - 2026-03-29

### 鏂板

- 閬亣鏆傚仠涓庢垬鏂楀崰浣嶆祦绋嬶紙Day 7锛氭鐩樿蛋浣嶅眰 鈫?鍙屽眰鍏ュ彛锛?
- `BattlePhase.ENCOUNTER` 鏂伴樁娈垫灇涓撅細閬亣瑙﹀彂鍚庢鐩樿繘鍏ユ殏鍋滅姸鎬?
- `BattleFlowController.encounter_resolved` 淇″彿锛坋ncounter_id, cell锛?
- `BattleFlowController.resolve_encounter()`锛氶伃閬囩粨绠楁柟娉曪紝娓呴櫎閬亣鏍煎苟鍥炲埌 PLAYER_ACTION
- `BattleFlowController` 鏂板閬亣涓婁笅鏂囧彉閲忥細`_encounter_unit_id`銆乣_encounter_id`銆乣_encounter_cell`
- `DiceDebugPanel` 鏂板閬亣鎴樻枟鍗犱綅闈㈡澘锛坄encounter_panel`锛夛細姗欑孩鑹茶儗鏅?+ "鎴樻枟寮€濮?[encounter_id]" 鏍囬 + "鎴樻枟鑳滃埄锛堝崰浣嶏級"鎸夐挳
- 閬亣娓呴櫎鍙嶉锛氳В闄ら伃閬囧悗鍦ㄩ伃閬囨牸浣嶇疆鏄剧ず缁胯壊"閬亣娓呴櫎"椋樺瓧
- `_phase_label_text()` 鏂板 "ENCOUNTER" 鈫?"閬亣鎴樻枟" 鏄犲皠

### 淇敼

- `_check_encounter()` 閲嶅啓锛氫粠浠呭彂淇″彿鏀逛负杩涘叆 ENCOUNTER 鏆傚仠鐘舵€?+ 淇濆瓨閬亣涓婁笅鏂?
- `BoardView._handle_cell_click()` 鏂板 ENCOUNTER 闃舵鐐瑰嚮灞忚斀锛堜笌 VICTORY/DEFEAT 涓€鑷达級
- `DiceDebugPanel._on_phase_changed()` 鏂板 ENCOUNTER 澶勭悊锛氱鐢ㄦ幏楠?缁撴潫鍥炲悎鎸夐挳锛岄樁娈垫爣绛惧彉姗欒壊
- `DiceDebugPanel._on_encounter_triggered()` 鏇存柊锛氶櫎鏄剧ず鏂囧瓧鎻愮ず澶栵紝鍚屾椂寮瑰嚭鎴樻枟鍗犱綅闈㈡澘
- `Main.gd` 杩炴帴 `encounter_resolved` 淇″彿锛岃Е鍙戠豢鑹查瀛楀弽棣?
- `restart_battle()` 娓呯┖閬亣涓婁笅鏂囧彉閲?

### 瀹屾暣娴佺▼

韪╅伃閬囨牸 鈫?妫嬬洏杩涘叆 ENCOUNTER 鏆傚仠 鈫?绂佹鎵€鏈夋搷浣?鈫?寮瑰嚭鎴樻枟鍗犱綅闈㈡澘 鈫?鐐瑰嚮"鎴樻枟鑳滃埄锛堝崰浣嶏級" 鈫?閬亣鏍兼秷澶?鈫?鍥炲埌 PLAYER_ACTION 缁х画

### 澶囨敞

- 鍗犱綅闈㈡澘涓?Day 9 鏈€灏忓崱鐗屾垬鏂楀師鍨嬬殑鏇挎崲鍏ュ彛
- `resolve_encounter()` 棰勭暀浜嗘垬鏂楃粨鏋滃弬鏁版墿灞曠┖闂?
- 閬亣鏍艰娓呴櫎鍚庝笉鍐嶈Е鍙戯紙鍗曟閬亣锛?
- ENCOUNTER 闃舵鏈熼棿锛屾幏楠?绉诲姩/鏀诲嚮/鍙敜/缁撴潫鍥炲悎鍧囪绂佹

## v0.1.30 - 2026-03-29

### 鏂板

- 闃舵鏀跺彛涓庢棩蹇楁暣鐞嗭紙Day 12锛?
- `CyberTao_Migration_Snapshot_zh_v3.md` 鍏ㄩ潰閲嶅啓锛氫粠 v0.1.24 鏇存柊鍒?v0.1.30
  - 鏂板鍗＄墝鎴樻枟灞傚畬鎴愮姸鎬佽〃锛?2 椤癸級
  - 鏂板鍙屽眰闂幆瀹屾暣娴佺▼鍥?
  - 鏂板閬亣鏁屾柟鏁版嵁琛ㄥ拰 10 寮犲崱鐗岀墝缁勮〃
  - 鏂板 CardBattleController / CardBattlePanel / CyberStyle 鍒版枃浠剁储寮?
  - 鏂板鍗＄墝灞備俊鍙蜂綋绯诲拰鏁版嵁缁撴瀯
  - 鏂板鎶€鏈€烘竻鍗曪紙6 椤癸級
  - 鏂板涓嬩竴闃舵鎺ㄨ繘寤鸿锛? 涓柟鍚?15+ 鍏蜂綋寤鸿锛?
  - 鏂板鐗堟湰閲岀▼纰戞€昏琛紙v0.1.0 鈫?v0.1.30锛?
- `Weekly_Mulerun_Plan_zh_v2.md` 鏀跺彛锛欴ay 11/12 鏍囪宸插畬鎴愶紝鎬荤粨鏇存柊

### 澶囨敞

- 绾棩蹇楁暣鐞嗭紝鏃犱唬鐮佸彉鏇?
- 绗竴闃舵锛圖ay 1~12锛夊叏閮ㄥ畬鎴?
- 30 涓増鏈紙v0.1.0 鈫?v0.1.30锛変粠闆跺畬鎴愬弻灞傜帺娉曢棴鐜?
- 鎵€鏈夊凡鐭ラ棶棰樺拰鎶€鏈€哄凡璁板綍鍦?Snapshot 绗?4 鑺?

---

## v0.1.29 - 2026-03-29

### 鏂板

- 缁熶竴璧涘崥鏈嬪厠瑙嗚椋庢牸绯荤粺锛圖ay 11锛歎I 鍘昏皟璇曞寲绗竴鐗堬級
- `Scripts/UI/CyberStyle.gd`锛堝叏鏂版枃浠讹級锛氬叏灞€瑙嗚甯搁噺鍜屾牱寮忓伐鍘?
  - 30+ 鍛藉悕棰滆壊甯搁噺锛氳儗鏅?涓昏壊璋?杈规/鏂囧瓧/HP/鎸夐挳
  - 涓夊ぇ涓昏壊璋冿細闈掕壊锛堜俊鎭級/ 姗欒壊锛堟垬鏂楋級/ 鍝佺孩锛堟妧鑳斤級
  - 闈㈡澘鑳屾櫙宸ュ巶 `make_panel_bg()`锛氭殫搴?闇撹櫣杈规+闃村奖
  - 鎸夐挳鍥涙€佸伐鍘傦細normal/hover/pressed/disabled 鍚勬湁鐙珛 StyleBoxFlat
  - `style_button(btn, accent)` 涓€閿鏍煎寲锛堟敮鎸?cyan/orange 涓婚锛?
  - `make_encounter_panel_bg()` 閬亣闈㈡澘涓撶敤鑳屾櫙

### 淇敼

- **DiceDebugPanel** 瑙嗚鍏ㄩ潰鍗囩骇
  - 闈㈡澘浠庣伆鑹茶皟璇曢鏍煎彉涓烘繁钃濋粦搴?闈掕壊闇撹櫣杈规
  - 鎵€鏈夋寜閽娇鐢?`CyberStyle.style_button()` 缁熶竴椋庢牸鍖?
  - 鎺烽=姗欒壊涓婚銆佸叾浠?闈掕壊涓婚
  - 鏂板 3 鏉￠潚鑹插垎闅旂嚎鍒掑垎鍔熻兘鍖哄煙
  - Crest 璧勬簮姹犱娇鐢?BBCode 褰╄壊鏂囧瓧锛堟樉鍖?姝ヨ繘=闈掋€佹潃浼?鎶ゆ寔=姗欍€佹湳寮?鏈哄阀=鍝佺孩锛?
  - 鏂板鐗堟湰鍙锋爣璁?
- **CardBattlePanel** 椋庢牸缁熶竴
  - 姗欒壊杈规涓婚锛堟垬鏂楅潰鏉胯瘑鍒壊锛?
  - 鎵嬬墝/閫冭窇鎸夐挳=orange 涓婚銆佺粨鏉熷洖鍚?cyan 涓婚
  - 鏂板 2 鏉℃鑹插垎闅旂嚎
- **SettingsPanel** 椋庢牸缁熶竴
  - 闈掕壊杈规涓婚
  - 搴旂敤=orange銆佸叾浠?cyan
- **Main.gd** 鏍囬鏍忛鏍肩粺涓€
  - 鑳屾櫙鍔犳繁鑷宠繎绾粦
  - 鍓爣棰樻洿鏂颁负瀹屾暣鍔熻兘鍒楄〃
  - 鎵€鏈夋寜閽粺涓€椋庢牸鍖?
  - 鑳滆礋鏍囩浣跨敤缁熶竴棰滆壊甯搁噺

### 澶囨敞

- 绾瑙夊崌绾э紝鎵€鏈夌幇鏈夊姛鑳藉拰淇″彿瀹屽叏淇濈暀
- 鎸夐挳 hover 甯﹀彂鍏夐槾褰辨晥鏋滐紝澧炲己璧涘崥鏈嬪厠浜や簰鎰?
- CyberStyle 浣跨敤 class_name 鍏ㄥ眬娉ㄥ唽锛屾墍鏈?UI 鏂囦欢鏃犻渶 preload

---

## v0.1.28 - 2026-03-29

### 鏂板

- "娴嬭瘯鍗＄墝鎴樻枟"璋冭瘯蹇嵎鎸夐挳锛欴iceDebugPanel 鏂板涓€閿繘鍏ュ崱鐗屾垬鏂楃殑鎸夐挳锛屾棤闇€璧板埌閬亣鏍煎嵆鍙祴璇?
- `DiceDebugPanel.test_card_battle_requested` 淇″彿
- `DiceDebugPanel._on_test_card_battle_pressed()` 澶勭悊鏂规硶
- `Main._on_test_card_battle_requested()`锛氳幏鍙栫涓€涓帺瀹跺崟浣?HP锛岀洿鎺ュ惎鍔?CardBattleController锛坋ncounter_01 寮傚父鍝ㄥ叺锛?

### 淇敼

- DiceDebugPanel 闈㈡澘楂樺害浠?500 鎵╁ぇ鑷?540锛屽悇鏍囩浣嶇疆璋冩暣閬垮厤閲嶅彔
  - roll_label y: 256鈫?94
  - crest_label y: 306鈫?42
  - enemy_intent_label y: 450鈫?88

### 澶囨敞

- 瑙ｅ喅鐢ㄦ埛鍙嶉"鍙兘鎶曢瀛愪簰娈淬€佹棤娉曡Е鍙戝崱鐗屾垬鏂?鐨勯棶棰?
- 鏍瑰洜锛氶伃閬囨牸 (4,4)/(6,5) 璺濈鐜╁璧风偣 (0,6)/(1,7)/(0,5) 澶繙锛岄渶澶氫釜鍥炲悎鎵嶈兘璧板埌
- 璋冭瘯鎸夐挳鍏佽浠绘剰鏃跺埢涓€閿祴璇曞崱鐗屾垬鏂楁祦绋?

---

## v0.1.27 - 2026-03-29

### 鏂板

- 鍗＄墝鎴樻枟涓板瘜鍖栵紙Day 10锛氬崱鐗屾垬鏂楀眰锛?
- **鑳介噺绯荤粺**锛氭瘡鍥炲悎 3 鐐硅兘閲忥紝鍑虹墝娑堣€?1~3 鑳介噺锛屼笉瓒虫椂鎸夐挳绂佺敤
- **鍙岀墝鍫嗙郴缁?*锛?0 寮犵墝缁勶紙draw pile + discard pile锛夛紝姣忓洖鍚堟娊 3 寮狅紙涓婇檺 6锛夛紝鍥炲悎缁撴潫寮冨叏閮ㄦ墜鐗岋紝鐗屽爢绌烘椂鑷姩 reshuffle
- **鐗岀粍鍐呭**锛氭柀鍑粁2(1E/3浼? / 閲嶅嚮x1(2E/5浼? / 闃插尽x2(1E/鍑忎激2) / 淇x1(1E/鍥炲2) / 杩炴柀x2(1E/2浼? / 鐚涙敾x1(3E/8浼? / 鎬ユ晳x1(2E/鍥炲4)
- **3 绉嶆晫鏂硅涓烘ā寮?*锛歛ttack锛堟櫘鏀伙級/ heavy_attack锛圓TK脳2 閲嶅嚮锛? defend_attack锛堥槻寰?鏀诲嚮锛屾晫鏂硅幏 2 鍑忎激锛?
- **鏁屾柟琛屼负寰幆**锛氬紓甯稿摠鍏?= attack鈫抋ttack鈫抎efend_attack鈫抙eavy_attack / 璧涘崥娓搁瓊 = attack鈫抙eavy_attack鈫抋ttack
- **鏁屾柟鎰忓浘棰勫憡**锛氭瘡鍥炲悎寮€濮嬫樉绀烘晫鏂逛笅涓€姝ヨ鍔ㄧ被鍨嬪拰棰勬湡浼ゅ
- **鏁屾柟闃插尽鍑忎激**锛歞efend_attack 缁欐晫鏂?+2 鍑忎激锛屽奖鍝嶇帺瀹朵笅娆℃敾鍑伙紙鏈€浣庣┛閫?1锛?
- **鑳滃埄濂栧姳**锛氳儨鍒╁悗闅忔満 +1 crest 鍐欏叆妫嬬洏灞?dice_manager
- **缁撴潫鍥炲悎鎸夐挳**锛氱帺瀹跺彲闅忔椂缁撴潫鍥炲悎
- `CardBattleController.hand_changed` / `enemy_intent_changed` / `victory_reward` 淇″彿
- `CardBattleController.end_turn()` / `get_draw_count()` / `get_discard_count()` 鏂规硶

### 淇敼

- `CardBattleController.gd` 鍏ㄩ潰閲嶅啓锛氫粠鍥哄畾 5 寮犳墜鐗屽崌绾т负鑳介噺+鎶界墝+琛屼负妯″紡绯荤粺
- `CardBattlePanel.gd` 鍏ㄩ潰閲嶅啓锛氬浐瀹氭寜閽敼涓哄姩鎬佹墜鐗屾寜閽尯锛屽鍔犺兘閲?鐗屽爢/鎰忓浘鏄剧ず锛岄潰鏉挎墿澶ц嚦 480x460
- `Main.gd` 杩炴帴 `victory_reward` 淇″彿锛岃儨鍒╁悗灏?crest 鍐欏叆 dice_manager.crest_pool
- 閬亣鏁屾柟鏁版嵁澧炲姞 pattern 瀛楁鍜?HP 璋冩暣锛堝紓甯稿摠鍏?HP 6鈫?锛?

### 澶囨敞

- 鑳介噺涓嶄繚鐣欒法鍥炲悎锛堝師鍨嬬畝鍖栵級
- 鏁屾柟闃插尽鍑忎激鍙奖鍝嶇帺瀹朵笅涓€娆℃敾鍑荤墝锛堟秷璐瑰悗褰掗浂锛?
- 闃插尽鍙彔鍔狅紙鍚屽洖鍚堝寮犻槻寰＄墝鏁堟灉绱姞锛?
- 鐗岀粍鍥哄畾 10 寮狅紙鍚庣画鍙弬鑰冩棫 CardData.gd 寮曞叆绋€鏈夊害鍜屽崌绾э級
- 鍑虹墝閫夋嫨鏈変簡鐪熸鐨勭瓥鐣ョ淮搴︼細鑳介噺鍒嗛厤 + 鎵嬬墝鍙栬垗 + 搴斿鏁屾柟鎰忓浘

---

## v0.1.26 - 2026-03-29

### 鏂板

- `Scripts/BattleV2/CardBattleController.gd`锛堝叏鏂版枃浠讹級锛氱嫭绔嬪崱鐗屾垬鏂楃姸鎬佹満
  - BattleState 鏋氫妇锛欼DLE / PLAYER_TURN / ENEMY_TURN / VICTORY / DEFEAT
  - 5 寮犲浐瀹氭墜鐗岋紙鏂╁嚮/閲嶅嚮/闃插尽/淇/杩炴柀锛?
  - 閬亣鏁屾柟鏁版嵁鏄犲皠锛坰tatic 鏂规硶锛?
  - 瀹屾暣淇″彿閾撅細battle_started / card_played / enemy_acted / turn_resolved / battle_ended
- `BattleFlowController.get_encounter_unit_id()` 鏌ヨ鏂规硶

### 淇敼

- `CardBattlePanel.gd` 閲嶅啓涓虹函 UI 灞傦細绉婚櫎鎵€鏈夋垬鏂楃姸鎬侊紝閫氳繃 `bind_controller()` 缁戝畾 CardBattleController 淇″彿
- `BattleFlowController.gd` 鐦﹁韩锛氱Щ闄?`card_battle_started`/`card_battle_ended` 淇″彿銆乣get_encounter_enemy_data()` 鏂规硶锛沗_check_encounter()` 绠€鍖栦负鍙彂灏?`encounter_triggered`锛沗resolve_encounter()` 绉婚櫎 `card_battle_ended` 鍙戝皠
- `DiceDebugPanel.gd` 绉婚櫎 `card_battle_ended` 淇″彿杩炴帴鍜屽洖璋?
- `Main.gd` 閲嶆瀯淇″彿杩炴帴锛欳ardBattleController 鐙珛瀹炰緥鍖栵紝encounter_triggered 鐩存帴鍚姩 controller锛宐attle_ended 椹卞姩 resolve_encounter

### 澶囨敞

- 鏈増鏈槸 v0.1.25 鐨勬灦鏋勪慨姝ｏ紝鍔熻兘涓嶅彉锛屼絾浠ｇ爜缁撴瀯绗﹀悎涓婂矖鎸囦护瑕佹眰
- 鍗＄墝鎴樻枟閫昏緫瀹屽叏鑴辩 BattleFlowController锛岄€氳繃 Main.gd 涓浆淇″彿
- 鏃ч」鐩洏鐐圭粨璁猴細BattleManager.gd 涓嶅鐢紙杩囦簬澶嶆潅锛夛紝Deck.gd 鍜?CardData.gd Day 10 鍙弬鑰?
- 闇€瑕?Codex 澶嶅锛欳ardBattleController 鐨勭嫭绔嬫寕杞戒綅缃€乺esolve_encounter 鐨勫弬鏁颁紶閫掓柟寮?

---

## v0.1.25 - 2026-03-29

### 鏂板

- 鏈€灏忓崱鐗屾垬鏂楀師鍨嬶紙Day 9锛氬崱鐗屾垬鏂楀眰锛夆€?鍙屽眰鐜╂硶缁撴瀯棣栨瀹屾暣璺戦€?
- `Scripts/UI/CardBattlePanel.gd`锛堝叏鏂版枃浠讹級锛氱嫭绔嬪崱鐗屾垬鏂楅潰鏉?
  - 5 寮犲浐瀹氭墜鐗岋細鏂╁嚮(3浼ゅ) / 閲嶅嚮(5浼ゅ) / 闃插尽(鍑忎激2) / 淇(鍥炲2HP) / 杩炴柀(2浼ゅ)
  - 鏁屾柟姣忓洖鍚堝浐瀹氭敾鍑伙紙绌块€忛槻寰℃渶浣?1 鐐癸級
  - 鎴樻枟鏃ュ織瀹炴椂鏄剧ず姣忓洖鍚堜簨浠?
  - 閫冭窇鏈哄埗锛?1 HP 鎯╃綒鍚庤涓哄け璐ラ€€鍑猴級
  - HP 浣庝簬 30% 绾㈣壊璀﹀憡
  - 鎴樻枟缁撴潫 1.2s 寤惰繜鍚庤嚜鍔ㄥ叧闂潰鏉?
  - 璧涘崥鏈嬪厠椋庢牸 UI锛堟殫绱簳+姗欒壊杈规锛?
- `BattleFlowController.card_battle_started` 淇″彿锛坋ncounter_id, enemy_name, enemy_hp, enemy_atk, unit_id, player_hp, player_max_hp锛?
- `BattleFlowController.card_battle_ended` 淇″彿锛坋ncounter_id, cell, victory, player_hp_remaining锛?
- `BattleFlowController.get_encounter_enemy_data()`锛氶伃閬囨晫鏂规暟鎹槧灏?
  - encounter_01 鈫?寮傚父鍝ㄥ叺锛圚P 6, ATK 2锛?
  - encounter_02 鈫?璧涘崥娓搁瓊锛圚P 4, ATK 3锛?

### 淇敼

- `BattleFlowController._check_encounter()` 閲嶅啓锛氳Е鍙戦伃閬囧悗鍚屾椂鍙戝皠 `card_battle_started` 淇″彿锛屼紶閫掗伃閬囨晫鏂规暟鎹拰褰撳墠鍗曚綅 HP
- `BattleFlowController.resolve_encounter()` 閲嶅啓锛氭帴鍙?`victory` 鍜?`player_hp_remaining` 鍙傛暟
  - 鑳滃埄锛氬崱鐗屾垬鏂楀墿浣?HP 鍚屾鍥炴鐩樺崟浣?
  - 璐ュ寳/閫冭窇锛氬墿浣?HP 鍚屾锛堜繚搴?1 HP锛屽師鍨嬮樁娈典笉鍥犲崱鐗屾垬鏂楃洿鎺ュ叏鐏級
  - 鏃犺鑳滆触鍧囨竻闄ら伃閬囨牸
- `DiceDebugPanel` 閬亣闈㈡澘鎸夐挳鏀逛负绂佺敤鐨?鍗＄墝鎴樻枟杩涜涓?.."锛涜繛鎺?`card_battle_ended` 淇″彿锛涙垬鏂楃粨鏉熷悗鏇存柊鎸夐挳鏄剧ず鑳滆触鏂囧瓧
- `Main.gd` 鏂板 `CardBattlePanel` 瀹炰緥鍖栧拰淇″彿杩炵嚎锛涙柊澧?`_on_card_battle_started()` / `_on_card_battle_panel_ended()` / `_on_card_battle_ended()` 澶勭悊鏂规硶

### 瀹屾暣鍙屽眰闂幆

```
妫嬬洏璧颁綅灞?                         鍗＄墝鎴樻枟灞?
韪╅伃閬囨牸 鈫?ENCOUNTER 鏆傚仠 鈹€鈹€鈹€鈹€鈹€鈹€鈫?CardBattlePanel 鍚姩
                                    鈫?
                                  鐜╁閫夌墝 鈫?鏁堟灉缁撶畻
                                    鈫?
                                  鏁屾柟鏀诲嚮 鈫?HP 妫€鏌?
                                    鈫?
                                  寰幆鑷充竴鏂?HP 鈮?0
                                    鈫?
PLAYER_ACTION 鎭㈠ 鈫愨攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ battle_ended 淇″彿
妫嬬洏鍗曚綅 HP 鍚屾 鈫愨攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ resolve_encounter(victory, hp)
```

### 澶囨敞

- 鎵嬬墝鍥哄畾涓嶆秷鑰楋紙Day 10 鍔犲叆璐圭敤绯荤粺鍜屾娊鐗岋級
- 鏁屾柟琛屼负鍗曚竴锛圖ay 10 鍔犲叆澶氱琛屼负妯″紡锛?
- 鍗＄墝鎴樻枟涓殑 HP 鍙樺寲浼氬悓姝ュ洖妫嬬洏鍗曚綅锛屼娇涓ゅ眰鐘舵€佷繚鎸佷竴鑷?
- 杩欐槸鍙屽眰鐜╂硶缁撴瀯鐨勫叧閿噷绋嬬锛氫粠"鍗犱綅鎸夐挳"杩涘寲涓?鐪熸鐨勫崱鐗屾垬鏂楀瓙娴佺▼"

---

## v0.1.24 - 2026-03-29

### 鏂板

- 妫嬬洏鏍煎瓙浜嬩欢鍖栵紙Day 8锛氭鐩樿蛋浣嶅眰锛?
- `BoardManager` 鏂板 `heal_cells` 瀛楀吀锛坈ell 鈫?heal_amount锛夊拰 `event_cells` 瀛楀吀锛坈ell 鈫?event_id锛?
- `BoardManager.add_heal_cell()`锛氭坊鍔犳仮澶嶆牸锛堟寔涔呭湴褰級
- `BoardManager.add_event_cell()` / `clear_event_cell()`锛氭坊鍔?娓呴櫎浜嬩欢鏍硷紙涓€娆℃€цЕ鍙戯級
- `BattleFlowController.heal_cell_triggered` 淇″彿锛坲nit_id, cell, heal_amount, actual_heal锛?
- `BattleFlowController.event_cell_triggered` 淇″彿锛坲nit_id, cell, event_id, effect_text锛?
- `BattleFlowController._check_heal_cell()`锛氬崟浣嶈俯鎭㈠鏍兼椂鍥炲 HP锛堜笉瓒?max_hp锛屾弧琛€涓嶈Е鍙戯級
- `BattleFlowController._check_event_cell()`锛氬崟浣嶈俯浜嬩欢鏍兼椂闅忔満涓夐€変竴锛圚P+1 / 闅忔満 crest+1 / HP-1锛?
- `BattleFlowController._spawn_debug_heal_cells()`锛氶缃?2 涓仮澶嶆牸 (5,6) HP+2銆?1,3) HP+3
- `BattleFlowController._spawn_debug_event_cells()`锛氶缃?3 涓簨浠舵牸 (3,5)銆?6,3)銆?4,6)
- `BoardView._draw_heal_cells()`锛氳摑鐧借壊濉厖+杈规+"鍥炲"+鍥炲閲忔覆鏌?
- `BoardView._draw_event_cells()`锛氶粍绱壊濉厖+杈规+"?"鏍囪娓叉煋
- `BoardView.play_heal_feedback()`锛氳摑鑹查瀛楁樉绀哄洖澶嶉噺
- `BoardView.play_event_feedback()`锛氭闈㈤粍鑹?璐熼潰绾㈣壊椋樺瓧鏄剧ず鏁堟灉
- 鎻愮ず鏍忔柊澧?"钃濈櫧=鍥炲 榛勭传=浜嬩欢" 璇存槑

### 淇敼

- `BoardManager.build_test_board()` 鍜?`clear_board()` 鐜板湪娓呯┖ `heal_cells` 鍜?`event_cells`
- `BattleFlowController.try_move_unit()` 绉诲姩鍚庡鍔犳仮澶嶆牸鍜屼簨浠舵牸妫€鏌ワ紙閬撳叿鎷惧彇涔嬪悗銆侀伃閬囨牸涔嬪墠锛?
- `BattleFlowController._bootstrap()` 鍜?`restart_battle()` 璋冪敤 `_spawn_debug_heal_cells()` 鍜?`_spawn_debug_event_cells()`
- `DiceDebugPanel` 杩炴帴 `heal_cell_triggered` 鍜?`event_cell_triggered` 淇″彿
- `Main.gd` 杩炴帴鏂颁俊鍙凤紝瑙﹀彂瀵瑰簲椋樺瓧鍙嶉

### 妫嬬洏鏍煎瓙绉嶇被锛? 绉嶅彲浜や簰锛?

| 鏍煎瓙绫诲瀷 | 棰滆壊 | 琛屼负 | 鎸佷箙鎬?|
|----------|------|------|--------|
| 璺緞鏍?| 闈掕壊 | 璺緞閫傛€?DEF+1 | 鎸佷箙 |
| 楂樺彴鏍?| 閲戣壊 | 绉诲姩娑堣€?2锛屾敾鍑昏寖鍥?1/+2 | 鎸佷箙 |
| 闄烽槺鏍?| 鏆楃孩 | 杩涘叆鍙?1 浼ゅ锛堥櫡闃遍€傛€у厤鐤級 | 鎸佷箙 |
| 閬撳叿鏍?| 缁胯壊 | 鎷惧彇閬撳叿鑾峰緱鏁堟灉 | 涓€娆℃€?|
| 閬亣鏍?| 姗欑孩 | 瑙﹀彂閬亣鏆傚仠鈫掓垬鏂?| 涓€娆℃€?|
| 鎭㈠鏍?| 钃濈櫧 | 韪╀笂鍥炲 HP | 鎸佷箙 |
| 浜嬩欢鏍?| 榛勭传 | 韪╀笂闅忔満姝?璐熸晥鏋?| 涓€娆℃€?|

### 澶囨敞

- 鎭㈠鏍间负鎸佷箙鍦板舰锛堝彲閲嶅韪╋級锛屾弧琛€鏃朵笉瑙﹀彂
- 浜嬩欢鏍间负涓€娆℃€цЕ鍙戯紙韪╁悗娑堝け锛夛紝鏁堟灉绛夋鐜囦笁閫変竴
- 浜嬩欢鏍艰礋闈㈡晥鏋滐紙HP-1锛夊彲鑷存锛屼細瑙﹀彂鑳滆礋鍒ゅ畾
- 璧颁綅璺嚎寮€濮嬫湁澶氭潯閫夋嫨锛氬畨鍏ㄨ矾绾匡紙鍥為伩闄烽槺/浜嬩欢锛塿s 鍐掗櫓璺嚎锛堥珮鏀剁泭浣嗘湁椋庨櫓锛?
- 浠呯帺瀹跺崟浣嶈Е鍙戞仮澶嶆牸鍜屼簨浠舵牸锛屾晫鏂逛笉瑙﹀彂

## v0.1.31 - 2026-03-29

### 鏂板
- 鎸佷箙鐗岀粍绯荤粺锛氱墝缁勮法鎴樻枟淇濈暀锛屾垬鏂楄儨鍒╁悗鍙幏寰楁柊鍗＄墝
- 鎴樻枟鑳滃埄閫夌墝鏈哄埗锛氬嚮璐ユ晫浜哄悗浠?3 寮犻殢鏈哄€欓€変腑閫?1 寮犲姞鍏ョ墝缁勶紙鎴栬烦杩囷級
- CardRewardPanel 濂栧姳閫夌墝闈㈡澘锛氬搧绾㈣壊杈规璧涘崥鏈嬪厠椋庢牸锛屾樉绀哄€欓€夊崱鐗岃鎯?
- 5 绉嶆柊鍗＄墝绫诲瀷鍔犲叆濂栧姳鍗℃睜锛氱┛鍒猴紙鏃犺闃插尽 4 浼ゅ锛夈€佸惛琛€鏂╋紙3 浼ゅ+鍥炲 1锛夈€佺數寮э紙2 浼ゅ+鏁屾柟 ATK-1锛夈€佸己鍖栨柀鍑伙紙4 浼ゅ锛夈€佸弻閲嶉槻寰★紙闃插尽 3锛?
- BattleState.REWARD_SELECT 鏂扮姸鎬侊細濂栧姳閫夌墝闃舵
- 鏂颁俊鍙凤細reward_cards_offered / reward_card_selected
- 鏂版柟娉曪細select_reward_card() / skip_reward() / get_deck_size() / reset_persistent_deck()

### 淇敼
- CardBattleController._win() 涓嶅啀鐩存帴鍙戝嚭 battle_ended锛屾敼涓鸿繘鍏?REWARD_SELECT 闃舵
- CardBattleController.start_battle() 浣跨敤鎸佷箙鐗岀粍澶嶅埗鑰岄潪姣忔閲嶅缓
- CardBattlePanel._on_battle_ended() 鑳滃埄鏃跺欢杩熺缉鐭负 0.5s
- Main.gd 閲嶆柊寮€濮嬫椂閲嶇疆鎸佷箙鐗岀粍

### 澶囨敞
- 濂栧姳鍗℃睜鍏?13 寮狅紙5 绉嶆柊鐗?+ 8 绉嶅熀纭€鐗岋級锛屾瘡娆￠殢鏈?3 閫?1
- 鐗岀粍鍦ㄩ噸鏂板紑濮嬫父鎴忔椂閲嶇疆涓哄垵濮?10 寮?
- 鐢靛姬鏁堟灉铏界劧鍐欎负 enemy_atk -= 1锛屼絾鍥?start_battle 閲嶈鏁屾柟鏁版嵁锛屽疄闄呬粎鍗曞満鐢熸晥
- 绗簩闃舵棣栦釜鍔熻兘浠诲姟锛屾牳蹇冪洰鏍囨槸璁╂瘡娆￠伃閬囨湁"鏀惰幏鎰?

## v0.1.32 - 2026-03-30

### 鏂板
- 3 绉嶆柊閬亣鏁屾柟锛氭殫缃戠埇铏紙HP12/ATK1 鍧﹀厠鍨?4鍥炲悎寰幆锛夈€佽剦鍐茬寧鎵嬶紙HP5/ATK4 鐜荤拑澶х偖 3鍥炲悎寰幆锛夈€佹暟鎹菇鐏碉紙HP9/ATK2 闀垮懆鏈熷瀷 5鍥炲悎寰幆锛?
- 3 涓柊閬亣鏍硷細(2,2) 鏆楃綉鐖櫕銆?7,4) 鑴夊啿鐚庢墜銆?5,1) 鏁版嵁骞界伒
- 閬亣鏁屾柟鎬绘暟浠?2 绉嶆彁鍗囪嚦 5 绉嶏紝妫嬬洏閬亣鏍间粠 2 涓鑷?5 涓?

### 澶囨敞
- 鏆楃綉鐖櫕棰戠箒闃插尽+鏀诲嚮锛岄紦鍔辩帺瀹舵瀯绛戠┛鍒?楂樹激鐗?
- 鑴夊啿鐚庢墜棣栧洖鍚堥噸鍑?8 浼ゅ锛圓TK4脳2锛夛紝閫艰揩浼樺厛闃插尽鎴栭€熸潃
- 鏁版嵁骞界伒 5 鍥炲悎闀垮懆鏈熷惈杩炵画閲嶅嚮娈碉紝鑰冮獙璧勬簮鍒嗛厤
- 鏂伴伃閬囨牸浣嶇疆宸叉帓鏌ヤ笉涓庣幇鏈夋牸瀛愬啿绐?

## v0.1.33 - 2026-03-30

### 鏂板
- 鎶ゆ寔(DEFEND) crest 娑堣€楀叆鍙ｏ細閫変腑鍗曚綅鏈洖鍚?DEF+1锛堝彲绱姞锛屽洖鍚堢粨鏉熸竻闆讹級
- 鏈紡(SKILL) crest 娑堣€楀叆鍙ｏ細閫変腑鍗曚綅鍗虫椂鍥炲 2 HP锛堟弧琛€涓嶅彲鐢級
- 鏈哄阀(TRICK) crest 娑堣€楀叆鍙ｏ細娑堣€?1 鏈哄阀杞寲涓?+1 闅忔満瀹炵敤 crest锛堟杩?鏉€浼?鏄惧寲锛?
- DiceDebugPanel 鏂板 3 涓?crest 鎿嶄綔鎸夐挳锛堟姢鎸?鏈紡/鏈哄阀锛?
- 鏂颁俊鍙凤細defend_crest_used / skill_crest_used / trick_crest_used
- 鏂版柟娉曪細try_use_defend_crest() / try_use_skill_crest() / try_use_trick_crest()
- 鍗曚綅涓存椂闃插尽瀛楁 temp_def锛堝弬涓庝激瀹宠绠楋紝鍥炲悎缁撴潫娓呴浂锛?

### 淇敼
- 浼ゅ鍏紡鍗囩骇锛歮ax(1, ATK - DEF - 鍦板舰鍔犳垚 - 涓存椂闃插尽)
- end_player_turn() 鏂板 _clear_temp_def() 娓呴櫎鎵€鏈夌帺瀹跺崟浣嶄复鏃堕槻寰?
- DiceDebugPanel 闈㈡澘楂樺害浠?540 璋冩暣涓?574锛岀増鏈彿鏇存柊

### 澶囨敞
- 鎵€鏈?6 绉嶉闈㈢幇鍦ㄩ兘鏈夊疄闄呮秷鑰楀叆鍙ｏ紝娑堥櫎浜?搴熼"闂
- 鎶ゆ寔/鏈紡闇€瑕佸厛閫変腑鐜╁鍗曚綅锛屾満宸т笉闇€瑕?
- 鏁屾柟 AI 鏆備笉浣跨敤 defend/skill/trick crest

## v0.1.34 - 2026-03-30

### 鏂板
- 鐗岀粍鏌ョ湅闈㈡澘锛圖eckViewPanel锛夛細妫嬬洏闃舵鍙煡鐪嬪綋鍓嶆寔涔呯墝缁勬墍鏈夊崱鐗?
- 鍗＄墝鎸夊悕绉版帓搴忋€佸悓鍚嶅悎骞惰鏁般€佺被鍨嬪僵鑹插尯鍒嗭紙鏀诲嚮姗?闃插尽闈?鍥炲缁?绌块€忓搧绾級
- DiceDebugPanel 鏂板"鏌ョ湅鐗岀粍"鎸夐挳鍜?deck_view_requested 淇″彿
- Toggle 浜や簰锛氱偣鍑绘墦寮€/鍐嶇偣鍏抽棴锛屾瘡娆℃墦寮€瀹炴椂鍒锋柊鏁版嵁

### 淇敼
- DiceDebugPanel "娴嬭瘯鍗＄墝鎴樻枟"鎸夐挳鎷嗗垎涓?娴嬭瘯鎴樻枟"+"鏌ョ湅鐗岀粍"骞舵帓甯冨眬
- Main.gd 鏂板 DeckViewPanel 瀹炰緥鍖栥€佹帶鍒跺櫒缁戝畾銆佷俊鍙疯繛鎺?

### 澶囨敞
- 绾?UI 鏌ョ湅鍔熻兘锛屾棤閫昏緫鍙樻洿锛屼笉褰卞搷妫嬬洏灞傚拰鍗＄墝灞傞棴鐜?
- 闈㈡澘浣嶇疆 (160,120)锛岃鐩栨鐩樹腑蹇冨尯鍩燂紝浣跨敤鏃堕渶鎵嬪姩鍏抽棴
- 鏀寔 RichTextLabel 婊氬姩锛岀墝缁勫彉澶у悗鍙粴鍔ㄦ祻瑙?

## v0.1.41 - 2026-03-30

### 鏂板
- 鍟嗗簵鏍硷紙Shop Cell锛夛細鎸佷箙鏍煎瓙锛屾秷鑰?1 姝ヨ繘 crest 鍥炲 3 HP锛屾瘡灞€ 1 涓?
- 瀹濈鏍硷紙Chest Cell锛夛細涓€娆℃€ф牸瀛愶紝闅忔満濂栧姳锛圚P+3 / 闅忔満crest+2 / 鍏╟rest+1锛夛紝姣忓眬 1-2 涓?
- BoardManager 鏂板 shop_cells/chest_cells 瀛楀吀锛宎dd_shop_cell/add_chest_cell/clear_chest_cell 鏂规硶
- CellEffectHandler 鏂板 check_shop_cell()/check_chest_cell() 鏁堟灉璁＄畻
- BFC 鏂板 shop_cell_triggered/chest_cell_triggered 淇″彿锛宊check_shop_cell/_check_chest_cell 钖勪唬鐞?
- BoardGenerator 鏂板 SHOP_COUNT/CHEST_COUNT 甯搁噺鍜岀敓鎴愰€昏緫
- BoardView 鏂板鍟嗗簵鏍硷紙闈掔豢鑹诧級鍜屽疂绠辨牸锛堥噾鐞ョ弨鑹诧級缁樺埗鏂规硶鍜岄瀛楀弽棣?

### 淇敼
- try_move_unit 鏍煎瓙妫€鏌ラ摼鎵╁睍锛歵rap鈫抜tem鈫抙eal鈫抏vent鈫抯hop鈫抍hest鈫抏ncounter
- Main.gd 鎻愮ず鏂囧瓧鏂板鍟嗗簵鏍煎拰瀹濈鏍奸鑹茶鏄?
- DiceDebugPanel 杩炴帴鏂颁俊鍙凤紝鐗堟湰鍙锋洿鏂颁负 v0.1.41

### 澶囨敞
- 鍟嗗簵鏍煎綋鍓嶄负鑷姩瑙﹀彂妯″紡锛堟棤閫夋嫨闈㈡澘锛夛紝鏈潵鍙墿灞?
- 瀹濈鏍?3 绉嶅鍔辩瓑姒傜巼锛屾暟鍊煎钩琛℃湭缁忓疄鎴樻祴璇?
- 妫嬬洏灞傛牸瀛愮被鍨嬩粠 7 绉嶅鑷?9 绉?

## v0.1.40 - 2026-03-30

### 鏂板
- CrestActionHandler.gd锛?6琛岋級锛氫粠 BFC 鍓ョ鐨?DEFEND/SKILL/TRICK crest 浣跨敤閫昏緫
- CellEffectHandler.gd锛?39琛岋級锛氫粠 BFC 鍓ョ鐨勯櫡闃?閬撳叿/鎭㈠/浜嬩欢鏍兼晥鏋滃鐞?
- _spawn_unit_from_data() 杈呭姪鍑芥暟锛氬帇缂╃帺瀹跺崟浣嶇敓鎴愪唬鐮?

### 淇敼
- BattleFlowController 浠?795 琛岀槮韬嚦 588 琛岋紙闄嶅箙 26%锛?
- Crest 浣跨敤鍑芥暟鏇挎崲涓鸿杽浠ｇ悊妯″紡锛堝鎵?Handler + 淇″彿鍙戝皠锛?
- 鏍煎瓙鏁堟灉鍑芥暟鏇挎崲涓鸿杽浠ｇ悊妯″紡锛堝鎵?Handler + 淇″彿鍙戝皠锛?
- _spawn_player_units 鍘嬬缉涓?3 琛岃緟鍔╁嚱鏁拌皟鐢?
- ItemEffectLibrary 寮曠敤浠?BFC 杞叆 CellEffectHandler

### 澶囨敞
- 鎵€鏈?BFC 淇″彿绛惧悕鍜屽叕鍏辨柟娉曠鍚嶅畬鍏ㄤ笉鍙橈紝娑堣垂鏂归浂淇敼
- 鎬讳唬鐮侀噺鏈噺灏戯紙鎷嗗垎鍓?795 琛岋紝鎷嗗垎鍚?588+66+139=793 琛岋級锛屼絾鑱岃矗鍒嗙
- _execute_enemy_actions锛?2琛岋級浠嶅湪 BFC锛屽洜 async/await 鑰﹀悎鏆備笉鎻愬彇

## v0.1.39 - 2026-03-30

### 鏂板
- BuffManager 姝ｅ紡鎺ュ叆鍥炲悎娴佺▼锛歵ick_turn() 姣忓洖鍚堣嚜鍔ㄨ“鍑?buff 鎸佺画鏃堕棿
- BuffManager 鏂板 apply_buff()銆乬et_stat_modifier()銆乬et_buff_summary() 绛夊畬鏁?API
- 鏂颁俊鍙凤細buff_applied(unit_id, type, value, duration) / buff_expired(unit_id, type)
- 妫嬬洏浼ゅ璁＄畻闆嗘垚 buff 淇锛欰TK/DEF 鍙?buff 绯荤粺褰卞搷
- overclock_bone 閬撳叿鎷惧彇鏂板 ATK+1 buff 鎸佺画 3 鍥炲悎
- DiceDebugPanel 鏄剧ず buff 鑾峰緱/娑堝け鎻愮ず + 閫変腑鍗曚綅 buff 鎽樿

### 淇敼
- _calc_damage_with_terrain() 娉ㄩ噴鍜岄€昏緫鏇存柊锛屽鍔?buff 淇璁＄畻
- overclock_bone 鏁堟灉鏂囨湰浠?"MOVE+1" 鏀逛负 "MOVE+1 ATK+1(3鍥炲悎)"
- BattleFlowController 浠?786 琛屽闀垮埌 795 琛岋紙+9琛屾帴鍏ヤ唬鐮侊級

### 淇
- BuffManager tick_turn() 浠庢湭琚皟鐢ㄧ殑鍘嗗彶閬楃暀闂锛堟妧鏈€?BuffManager.tick_turn() 鏈帴鍏ュ凡瑙ｅ喅锛?

### 澶囨敞
- buff 绯荤粺浠呭奖鍝嶆鐩樺眰浼ゅ璁＄畻锛屼笉褰卞搷鍗＄墝鎴樻枟灞傦紙璁捐濡傛锛?
- 鐩墠鍙湁 overclock_bone 涓€涓?buff 鏉ユ簮锛屽悗缁彲鎵╁睍
- BFC 795 琛屾帴杩戜笂闄愶紝涓嬩竴闃舵搴旇€冭檻鐦﹁韩

## v0.1.38 - 2026-03-30

### 鏂板
- 鑳介噺鎴愰暱鏈哄埗锛氭瘡娆￠伃閬囪儨鍒╁悗鑳介噺涓婇檺+1锛孊oss 鑳滃埄+2锛堝垵濮?3锛屼笂闄?5锛?
- 鏂颁俊鍙凤細energy_grown(old_max, new_max) 閫氱煡 UI 鑳介噺鎻愬崌
- 鏂板父閲忥細INITIAL_MAX_ENERGY(3)銆丮AX_ENERGY_CAP(5)
- 鎴樻枟鏃ュ織鏄剧ず"鑳介噺涓婇檺鎻愬崌锛乆 鈫?Y"
- 濂栧姳闈㈡澘鍜岀墝缁勬煡鐪嬮潰鏉挎樉绀哄綋鍓嶈兘閲忎笂闄?

### 淇敼
- max_energy 鏀逛负璺ㄦ垬鏂楁寔涔呯姸鎬侊紙涓?persistent_deck 鍚岀骇鍒級
- reset_persistent_deck() 鍚屾椂閲嶇疆 max_energy 涓哄垵濮嬪€?3

### 澶囨敞
- 鑳介噺涓婇檺 5 鏃朵竴鍥炲悎鍙嚭 3E+2E 鎴?5 寮?1E 鐗?
- Boss 鑳滃埄+2 鍙粠 3 鐩存帴璺冲埌 5锛屾彁渚涙樉钁楃殑鎴樿儨濂栧姳鎰?
- 閫冭窇/鎴樿触涓嶈Е鍙戣兘閲忔垚闀?
- 閲嶆柊寮€濮嬫父鎴忔椂鑳介噺涓婇檺閲嶇疆涓?3

## v0.1.37 - 2026-03-30

### 鏂板
- Boss 閬亣绯荤粺锛氱壒娈婇珮闅惧害閬亣鏍硷紝娣辩孩鑹茶瑙夋爣璇?+ "BOSS" 鏂囧瓧
- Boss 鏁屾柟"闆跺彿鍗忚"锛欻P 20 / ATK 3 / 6 闃舵琛屼负寰幆锛堟敾鈫掗槻鏀烩啋閲嶅嚮鈫掑洖澶嶁啋鏀烩啋瓒呰浇閲嶅嚮锛?
- 涓ょ鏂版晫鏂硅涓猴細heal锛堝洖澶?3 HP锛夈€乵ega_attack锛圓TK脳3 浼ゅ锛?
- Boss 閬亣鎰忓浘棰勫憡锛歨eal 鏄剧ず"淇锛堝洖澶?HP锛?锛宮ega_attack 鏄剧ず"瓒呰浇閲嶅嚮锛圶 浼ゅ锛夆殸"
- Boss 鎴樿儨鍒╂彁渚?4 寮犲鍔辩墝锛堟櫘閫氶伃閬?3 寮狅級
- Boss 鎴樹笉鍙€冭窇锛岄€冭窇鎸夐挳绂佺敤鏄剧ず"鏃犳硶閫冭窇"
- 妫嬬洏姣忓眬鏀剧疆 1 涓?Boss 閬亣鏍硷紙浼樺厛鍙充笂璞￠檺锛岃繙绂荤帺瀹跺嚭鐢熷尯锛?
- CardBattlePanel 鏍囬 Boss 鎴樻樉绀?[BOSS] 鏍囪
- 鏂版柟娉曪細CardBattleController.is_boss_encounter()
- 鏂板父閲忥細BoardGenerator.BOSS_ENCOUNTER_IDS

### 淇敼
- _draw_encounters() 閲嶆瀯涓哄尯鍒?Boss锛堟繁绾?绮楄竟妗嗭級鍜屾櫘閫氶伃閬囷紙姗欑孩锛?
- _generate_reward_options() 鏍规嵁 is_boss 鍔ㄦ€佽皟鏁村鍔辩墝鏁伴噺
- Main.gd 妫嬬洏鍥句緥鎻愮ず鏂板"娣辩孩=BOSS"

### 澶囨敞
- Boss 琛屼负 heal 鍜?mega_attack 鏄€氱敤鏁屾柟琛屼负绫诲瀷锛屾湭鏉ユ櫘閫氭晫鏂逛篃鍙娇鐢?
- Boss 鏁板€兼湭缁忓钩琛℃祴璇曪紝闆跺彿鍗忚 6 鍥炲悎绱杈撳嚭绾?26 鐐逛激瀹筹紙涓嶅惈鍑忓厤鍜?heal 鍥炲锛?
- 鎵╁睍鏇村 Boss 鍙渶鍦?BOSS_ENCOUNTER_IDS 鍜?get_encounter_enemy_data() 涓坊鍔犳潯鐩?

## v0.1.36 - 2026-03-30

### 鏂板
- 鍗＄墝鍗囩骇鏈哄埗锛氬熀纭€鐗屽彲鍗囩骇涓哄己鍖栫増鏈紙鍚嶇О+"+"鍚庣紑锛屾暟鍊兼彁鍗?30%~50%锛岃垂鐢ㄤ笉鍙橈級
- 14 绉嶇墝鐨勫畬鏁村崌绾ф暟鎹槧灏勶紙鏂╁嚮鈫掓柀鍑?銆侀噸鍑烩啋閲嶅嚮+銆侀槻寰♀啋闃插尽+ 绛夛級
- 濂栧姳闈㈡澘鍙屾ā寮忥細鑳滃埄鍚庡彲閫?鑾峰彇鏂扮墝"鎴?鍗囩骇宸叉湁鐗?锛堜簩閫変竴锛?
- 鍗囩骇妯″紡鏄剧ず鎵€鏈夋湭鍗囩骇鐗岋紝鍚屽悕鍚堝苟锛屽睍绀哄崌绾у墠鍚庢暟鍊煎姣?
- 鎵嬬墝涓崌绾х墝浣跨敤闈掕壊鎸夐挳鏍峰紡锛堝尯鍒嗕簬鏅€氱墝姗欒壊锛?
- 鐗岀粍鏌ョ湅闈㈡澘鍗囩骇鐗屽悕绉伴潚鑹查珮浜?
- 鏂颁俊鍙凤細card_upgrade_completed(old_card, new_card)
- 鏂版柟娉曪細get_card_upgrade() / get_upgradeable_indices() / upgrade_deck_card()

### 淇敼
- 鎵€鏈夊崱鐗屽瓧鍏告柊澧?upgraded: bool 瀛楁
- 鍚歌鏂╂柊澧?heal_value 瀛楁锛屽崌绾у悗鍥炲閲忎粠 1 鎻愬崌涓?2
- CardRewardPanel 閲嶅啓涓哄弻妯″紡闈㈡澘锛堝鍔?鍗囩骇锛夛紝闈㈡澘楂樺害 320鈫?40

### 澶囨敞
- 姣忓紶鍗＄墝鍙兘鍗囩骇涓€娆★紙涓?STS 涓€鑷达級
- 姣忔鑳滃埄鍙兘閫?鍔犳柊鐗?鎴?鍗囩骇涓€寮?涔嬩竴
- 鍗囩骇鍦?REWARD_SELECT 鐘舵€佹墽琛岋紝涓嶅奖鍝嶆鐩樺眰鍜屾垬鏂楁祦绋?
- 閲嶆柊寮€濮嬫父鎴忔椂鐗岀粍閲嶇疆锛屾墍鏈夊崌绾х姸鎬佹竻闆?

## v0.1.35 - 2026-03-30

### 鏂板
- 妫嬬洏闅忔満鐢熸垚绯荤粺锛圔oardGenerator.gd锛夛細姣忓眬/姣忔閲嶅紑甯冨眬闅忔満鍖?
- 楂樺彴 2~3 涓€侀櫡闃?2~3 涓€侀亾鍏?2 涓€侀伃閬?3~4 涓€佹仮澶?2 涓€佷簨浠?2~3 涓殢鏈烘斁缃?
- 鏁屾柟鍗曚綅 2 涓殢鏈虹敓鎴愬湪妫嬬洏涓婂崐鍖哄煙
- 鐜╁鍑虹敓鍖轰繚鎶わ紙宸︿笅 col0~1 row5~7 涓嶆斁鍗遍櫓鏍煎瓙锛?
- 闃查噸鍙犳満鍒讹細used_cells 杩借釜 + Fisher-Yates 娲楃墝閫夊彇

### 淇敼
- BattleFlowController 鍒犻櫎 5 涓?_spawn_debug_* 鏂规硶锛屾敼鐢?BoardGenerator.generate_board()
- _spawn_debug_units 鏀瑰悕涓?_spawn_player_units锛堜粎淇濈暀鐜╁鍗曚綅锛?
- _bootstrap() 鍜?restart_battle() 缁熶竴璋冪敤 BoardGenerator

### 澶囨敞
- 姣忓眬閬亣鏍间粠 5 绉嶄腑闅忔満閫?3~4 绉嶏紝浣嶇疆姣忓眬涓嶅悓
- 閲嶆柊寮€濮嬪悗鑷姩鐢熸垚鏂板竷灞€锛岄噸鐜╂€уぇ骞呮彁鍗?
- BFC 琛屾暟缁存寔 785 琛岋紙鍒犻櫎 50 琛?debug spawn锛屾柊澧炲皯閲忚皟鐢級
- 妫嬬洏灞傚拰鍗＄墝灞傚畬鏁撮棴鐜笉鍙楀奖鍝?

## v0.1.42 - 2026-03-30

### 鏂板
- 澶氬眰鍦板浘绯荤粺锛?灞傛鐩樻帹杩涳紝鍑绘潃鎵€鏈夋鐩樻晫鏂瑰崟浣嶉€氬叧褰撳墠灞?
- FLOOR_CLEAR 闃舵锛氬眰閫氬叧鍚庢殏鍋滄鐩橈紝绛夊緟灞傞棿濂栧姳瀹屾垚
- floor_cleared/game_won 淇″彿锛氬尯鍒嗗眰閫氬叧鍜屾渶缁堥€氬叧
- advance_to_next_floor()锛氫繚鐣欏瓨娲诲崟浣?HP锛岄噸鏂扮敓鎴愭鐩橈紝杩涘叆涓嬩竴灞?
- _snapshot_player_hp()锛氬瓨娲荤帺瀹跺崟浣?HP 蹇収锛堣法灞備繚鐣欙級
- _spawn_player_units_with_hp()锛氬甫 HP 蹇収鐢熸垚鐜╁鍗曚綅锛堥樀浜″崟浣嶄笉澶嶆椿锛?
- CardBattleController.offer_floor_reward()锛氬眰闂村鍔辩洿鎺ヨ繘鍏ラ€夌墝/鍗囩骇闃舵
- DiceDebugPanel 鏂板"灞傛暟锛歑/3"鏍囩锛堝搧绾㈣壊锛?
- MAX_FLOOR 甯搁噺锛堥粯璁?3锛夛紝current_floor 鍙橀噺

### 淇敼
- _check_battle_outcome() 鍖哄垎灞傞€氬叧锛團LOOR_CLEAR锛夊拰鏈€缁堣儨鍒╋紙VICTORY锛?
- is_battle_over() 鍖呭惈 FLOOR_CLEAR 闃舵锛岄樆姝㈠眰閫氬叧鏈熼棿鎿嶄綔
- restart_battle() 閲嶇疆 current_floor = 1
- Main._on_phase_changed() 澶勭悊 FLOOR_CLEAR锛?绗?X 灞傞€氬叧锛?锛夊拰鏈€缁?VICTORY锛?閫氬叧鑳滃埄锛?锛?
- Main._on_card_battle_ended() 閫氳繃 _floor_clear_pending 鍖哄垎灞傞棿濂栧姳鍜岄伃閬囨垬鏂楃粨绠?
- DiceDebugPanel 鐗堟湰鍙锋洿鏂颁负 v0.1.42

### 澶囨敞
- 灞傞棿淇濈暀锛氱墝缁?鑳介噺涓婇檺/鍗＄墝鍗囩骇锛涘眰闂撮噸缃細妫嬬洏/crest/buff/鍥炲悎
- 闅惧害鏆備笉閫掑锛堝悇灞傛晫鏂规暟鍊肩浉鍚岋級锛屽悗缁彲鏍规嵁 floor 璋冩暣
- 闃典骸鍗曚綅涓嶅娲伙紝鍙兘瀵艰嚧鍚庣画灞傚洶闅撅紝闇€骞宠　娴嬭瘯
- BFC 浠?605 琛屽闀胯嚦绾?693 琛岋紙+88琛岋級

## v0.1.43 - 2026-03-30

### 淇
- BUG-001锛氬垎杈ㄧ巼鍒囨崲鏃犳晥 鈥?apply_settings() 鍦?_ready() 涓悓姝ヨ皟鐢紝绐楀彛绯荤粺灏氭湭鍒濆鍖栵紝鏀逛负 call_deferred 寤惰繜涓€甯?
- BUG-001锛氬叏灞?鏃犺竟妗嗙獥鍙ｅ垏鎹㈡棤鏁?鈥?浠庡叏灞忓垏鍥炵獥鍙?鏃犺竟妗嗘椂 DisplayServer 蹇界暐鍚庣画鎿嶄綔锛屼慨澶嶄负鍏堝己鍒跺洖閫€ WINDOW_MODE_WINDOWED 鍐嶈缃洰鏍囨ā寮?
- BUG-001锛氭棤杈规绐楀彛鍒囨崲鏃犳晥 鈥?鏃т唬鐮佸厛璁?WINDOW_MODE_WINDOWED 鍐嶈 BORDERLESS 鏍囧織锛屼絾 borderless 鏍囧織鍙兘琚ā寮忓垏鎹㈣鐩栵紱淇涓哄厛娓呴櫎 borderless 鏍囧織锛屽啀鎸夌洰鏍囨ā寮忔纭缃?

### 淇敼
- DiceDebugPanel 鐗堟湰鍙锋洿鏂颁负 v0.1.43

### 澶囨敞
- DisplaySettings.gd 鏍稿績淇锛歝all_deferred 寤惰繜鍒濆鍖?+ 鍏堝洖閫€绐楀彛妯″紡鍐嶅簲鐢ㄧ洰鏍囨ā寮?
- 淇瑕嗙洊涓夌鍦烘櫙锛氬垎杈ㄧ巼鍒囨崲銆佸叏灞忊啍绐楀彛鍒囨崲銆佹棤杈规绐楀彛鍒囨崲
- 妫嬬洏灞傚拰鍗＄墝灞傚畬鏁撮棴鐜笉鍙楀奖鍝?

## v0.1.44 - 2026-03-30

### 淇
- BUG-001 琛ュ厖淇锛氬垎杈ㄧ巼鍒囨崲鍚庣敾闈笉鑷€傚簲 鈥?content_scale_size 琚涓虹洰鏍囧垎杈ㄧ巼锛堝1920x1080锛夛紝瀵艰嚧铏氭嫙鐢诲竷鍙樺ぇ浣?UI 浠嶆寜 1280x720 甯冨眬锛屽彸涓嬫柟鍑虹幇澶х墖绌虹櫧锛涗慨澶嶄负濮嬬粓淇濇寔 content_scale_size = 璁捐鍒嗚鲸鐜囷紙1280x720锛夛紝鐢?canvas_items 鎷変几妯″紡鑷姩缂╂斁鍐呭鑷冲疄闄呯獥鍙ｅぇ灏?

### 淇敼
- DiceDebugPanel 鐗堟湰鍙锋洿鏂颁负 v0.1.44

### 澶囨敞
- 鏍瑰洜锛歝anvas_items 鎷変几妯″紡鐨勬纭敤娉曟槸 content_scale_size 鍥哄畾涓鸿璁″垎杈ㄧ巼锛岀獥鍙ｅぇ灏忛殢鐢ㄦ埛閫夋嫨鍙樺寲锛屽紩鎿庤嚜鍔ㄥ鐞嗙缉鏀?
- 绐楀彛妯″紡鍒囨崲锛坴0.1.43 淇锛変笉鍙楀奖鍝?

## v0.1.44-docs - 2026-03-30

### 鏂板
- 缇庢湳缇庡寲鎺ㄨ繘绛栫暐鏂囨。锛圓rt_Beautification_Strategy_zh.md锛夛細6 闃舵鍒嗘缇庡寲璁″垝
  - Phase 1锛氭鐩樻牸+鍗曚綅瑙嗚鍗囩骇锛圔oardCellRenderer + UnitRenderer锛?
  - Phase 2锛氭幏楠版紨鍑?鏀诲嚮婕斿嚭澧炲己锛圖iceRollAnimation + BattleEffects锛?
  - Phase 3锛氬崱鐗屾垬鏂楅潰鏉块噸璁捐锛圕ardRenderer锛?
  - Phase 4锛氳儗鏅皼鍥?UI杩囨浮鍔ㄧ敾+鍙敜婕斿嚭
  - Phase 5锛氶煶鏁堢郴缁燂紙AudioManager锛?
  - Phase 6锛?.5D 妫嬬洏锛堥暱鏈熺洰鏍囷級

### 淇敼
- 浠诲姟浼樺厛绾ц皟鏁达細灞傞棿闅惧害閫掑鎺掑悗锛岀編鏈編鍖?Phase 1 鎻愬墠涓哄綋鍓嶆渶楂樹紭鍏?

### 澶囨敞
- 鏈潯鐩负绾枃妗ｅ彉鏇达紝鏃犱唬鐮佷慨鏀?
- 鍏ㄩ儴 UI/娓叉煋浠ｇ爜宸插畬鎴愬璁★紝绛栫暐鏂囨。鍩轰簬瀹為檯浠ｇ爜鐘舵€佸埗瀹?

## v0.1.45 - 2026-03-30

### 鏂板
- 缇庡寲 Phase 1 瀹屾暣瀹炵幇锛氭鐩樻牸+鍗曚綅+楂樹寒瑙嗚鍗囩骇
- BoardCellRenderer.gd锛垀210琛岋級锛氭牸瀛愭覆鏌撻潤鎬佺被
  - 鍩虹鏍兼繁鑹叉笎鍙樺簳鑹?+ 鍙戝厜缃戞牸绾?
  - 9绉嶆牸瀛愮被鍨嬬嫭鐗瑰浘鏍囩鍙?+ 闇撹櫣鍙戝厜鏁堟灉锛堥珮鍙扳柌/闄烽槺鉁?閬亣鈿?Boss/鍥炲鉁?浜嬩欢?/鍟嗗簵鈼?瀹濈鍏竟褰?閬撳叿鑿卞舰锛?
  - 绉诲姩楂樹寒鍗囩骇涓哄洓瑙扡褰㈢嚎鏉★紝鏀诲嚮楂樹寒鍗囩骇涓哄崄瀛楀噯鏄?鑴夊啿锛屽彫鍞ら珮浜崌绾т负鍦嗗姬鏍囪
- UnitRenderer.gd锛垀159琛岋級锛氬崟浣嶆覆鏌撻潤鎬佺被
  - 鐜╁鍗曚綅鐙壒褰㈢姸锛堝垁鐩剧姮鈫掔浘褰€侀粦瀹㈢嫄鈫掕彵褰€侀甫鏈＋鈫掑€掍笁瑙掞級+ 鍙戝厜杞粨
  - 鏁屾柟鍗曚綅鏆楃孩鍙戝厜 + 鍥涜灏栬瑁呴グ锛堥敮榻垮▉鑳佹劅锛?
  - HP鏉★細搴曡壊+濉厖鍙屽眰锛岀豢鈫掗噾鈫掔孩娓愬彉
  - 閫変腑鑴夊啿閲戣壊杈规 + idle寰姩鐢?
  - 鍦板舰閫傛€ч噾鑹叉槦鏍?
- CyberStyle.gd 鏂板 10 涓鐩樼編鍖栭鑹插父閲忥紙BOARD_CELL_DARK/LIGHT銆丅OARD_GRID_LINE/INNER_GLOW銆丯EON_GOLD/RED/TEAL/PURPLE/BLUE/GREEN锛?

### 淇敼
- BoardView.gd 瀹屽叏閲嶅啓锛?48琛屸啋423琛岋紙闄嶅箙35%锛?
  - 15+涓棫 _draw_* 鏂规硶鏇挎崲涓?5灞傚垎灞傜粯鍒讹紙Grid鈫扥verlays鈫扝ighlights鈫扷nits鈫扐ttackFlash锛?
  - 鍏ㄩ儴娓叉煋濮旀墭缁?BoardCellRenderer/UnitRenderer 闈欐€佹柟娉?
  - 鏂板 Timer 椹卞姩 20fps 鍔ㄧ敾鍒锋柊锛?0ms 闂撮殧 queue_redraw锛?
  - 鎵€鏈夌偣鍑讳氦浜掗€昏緫鍜屽弽棣堝姩鐢诲畬鏁翠繚鐣欙紝闆朵慨鏀?
- DiceDebugPanel 鐗堟湰鍙锋洿鏂颁负 v0.1.45

### 澶囨敞
- 100% 绋嬪簭鍖栫粯鍒讹紝闆跺閮ㄥ浘鐗囪祫婧愪緷璧?
- 100% CyberStyle 棰滆壊甯搁噺锛屾棤纭紪鐮侀鑹?
- gl_compatibility 瀹夊叏锛氬叏閮ㄤ娇鐢?draw_rect/draw_line/draw_arc/draw_colored_polygon/draw_string
- BoardView 鎵€鏈夊叕鍏变俊鍙峰拰鏂规硶绛惧悕涓嶅彉锛屾秷璐规柟锛圡ain.gd/DiceDebugPanel锛夐浂淇敼
- Phase 1 瀹屾垚鏍囧噯锛氭鐩樻埅鍥剧湅璧锋潵鍍?娓告垙"鑰岄潪"璋冭瘯宸ュ叿"锛涘崟浣嶅彲鍖哄垎绫诲瀷锛涙牸瀛愮被鍨嬩竴鐩簡鐒?

## v0.1.46 - 2026-03-30

### 鏂板
- 缇庡寲 Phase 2 瀹屾暣瀹炵幇锛氭幏楠版紨鍑?+ 鏀诲嚮婕斿嚭澧炲己
- DiceRollAnimation.gd锛垀158琛岋級锛氭幏楠版紨鍑哄姩鐢绘帶浠?
  - 3鏋氶瀛愮炕婊氾紙55ms闅忔満鍒囨崲crest绗﹀彿锛夆啋 閫愪釜瀹氭牸锛坰cale寮硅烦+闇撹櫣鍙戝厜锛?
  - 6绉峜rest鐙壒绗﹀彿绋嬪簭鍖栫粯鍒讹紙鈽呯澶粹湒鐩锯棊猬★級+ 6绉嶇嫭鐗归鑹?
  - 鎬绘紨鍑烘椂闀跨害 1.1s锛屽姩鐢绘湡闂翠笉闃诲鎿嶄綔
- BattleEffects.gd锛垀103琛岋級锛氭垬鏂楃壒鏁堥潤鎬佺被
  - 灞忓箷寰渿锛?姝ヨ“鍑忛殢鏈哄亸绉伙紝meta瀛樺偍闈欐浣嶇疆闃叉紓绉?
  - 鍛戒腑绮掑瓙锛欳PUParticles2D 涓€娆℃€х垎鍙戯紙鏅€?绮?鍑绘潃12绮掞級+ 鑷姩閲婃斁
  - 澧炲己浼ゅ椋樺瓧锛歴cale寮硅烦锛?.0鈫?.4鈫?.0锛? 涓婃诞娓愰殣
  - 鍑绘潃鏂囧瓧锛氶噾鑹?"KILL!" 寮瑰嚭

### 淇敼
- BoardView.play_attack_feedback() 澧炲己锛氶泦鎴?BattleEffects锛堝井闇?绮掑瓙+寮硅烦椋樺瓧锛夛紝鏂板 is_kill 鍙傛暟锛堥粯璁?false 鍚戝悗鍏煎锛?
- BoardView 绉婚櫎鏃?_damage_label 瀹炰緥鍙橀噺锛岃 BattleEffects.enhanced_damage_popup 鏇夸唬
- DiceDebugPanel 闆嗘垚 DiceRollAnimation锛氭幏楠板悗鎾斁鍔ㄧ敾锛宑rest姹犵珛鍗虫洿鏂?
- Main.gd 鏂板 _last_attack_killed 鍙橀噺锛屼紶閫掑嚮鏉€鐘舵€佸埌 play_attack_feedback
- DiceDebugPanel 鐗堟湰鍙锋洿鏂颁负 v0.1.46

### 澶囨敞
- 鎺烽鍔ㄧ敾涓嶉樆濉炴搷浣滐細crest姹犲湪鍔ㄧ敾寮€濮嬫椂鍗虫洿鏂帮紝鐜╁鍙珛鍗宠鍔?
- CPUParticles2D锛坓l_compatibility 鍏煎锛夛紝one_shot + 鑷姩閲婃斁锛屾棤鑺傜偣娉勬紡
- 鍑绘潃鏃舵晥鏋滃叏闈㈠寮猴細闂厜鏇翠寒銆侀渿鍔ㄦ洿寮恒€佺矑瀛愭洿澶氥€侀噾鑹查瀛?+ KILL!鏂囧瓧
- BattleFlowController / DiceManager 闆朵慨鏀?
- Phase 2 瀹屾垚鏍囧噯锛氭幏楠版湁鏈熷緟鎰燂紙>1绉掓紨鍑猴級锛涙敾鍑诲懡涓湁鍐插嚮鎰燂紙灞忓箷寰渿+绮掑瓙锛?


