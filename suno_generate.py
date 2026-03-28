#!/usr/bin/env python3
"""
suno_generate.py - CyberTao BGM/SFX 批量生成脚本
使用 sunoapi.org 第三方 API 生成 6 首 BGM + 音效
生成后的 MP3 文件保存到 Assets/Audio/ 目录

用法:
  python suno_generate.py            # 生成全部
  python suno_generate.py --bgm-only # 仅生成 BGM
  python suno_generate.py --check ID # 检查任务状态
"""

import os
import sys
import json
import time
import argparse
import requests
from pathlib import Path

# ============================================================
# 配置
# ============================================================

SUNO_API_KEY = os.environ.get("SUNO_API_KEY", "")
if not SUNO_API_KEY:
    print("ERROR: 请设置环境变量 SUNO_API_KEY，例如：")
    print("  export SUNO_API_KEY='your-api-key-here'")
    print("  python suno_generate.py")
    sys.exit(1)
BASE_URL = "https://api.sunoapi.org"
MODEL = "V4_5"  # 可选: V4, V4_5, V5, V5_5

HEADERS = {
    "Authorization": f"Bearer {SUNO_API_KEY}",
    "Content-Type": "application/json",
}

# 输出目录
OUTPUT_DIR = Path(__file__).parent / "Assets" / "Audio"
TASK_LOG = Path(__file__).parent / "suno_tasks.json"

# 轮询间隔(秒)
POLL_INTERVAL = 30
MAX_POLLS = 20  # 最多等 10 分钟

# ============================================================
# BGM 定义 (6 首)
# ============================================================

BGM_TRACKS = [
    {
        "id": "battle_bgm",
        "title": "Digital Dao - Battle",
        "style": "chiptune, 8-bit, cyberpunk, fast-paced electronic, retro game, intense, driving beat, synthwave",
        "prompt": "[Instrumental]\nAn intense 8-bit chiptune battle theme for a cyberpunk Taoist card game. "
                  "Fast arpeggios, pulsing bass, urgent melody. Blend retro NES-era sounds with dark "
                  "synthwave atmosphere. Loop-friendly structure with building intensity.",
        "instrumental": True,
    },
    {
        "id": "title_bgm",
        "title": "Digital Dao - Main Theme",
        "style": "chiptune, 8-bit, ambient, mysterious, ethereal, cyberpunk, atmospheric, slow, meditative",
        "prompt": "[Instrumental]\nA mysterious and atmospheric 8-bit title screen theme. Slow, meditative "
                  "melody blending ancient Chinese pentatonic scale with cyberpunk synth pads. "
                  "Evokes digital enlightenment and pixel worlds. Calm but with underlying tension.",
        "instrumental": True,
    },
    {
        "id": "map_bgm",
        "title": "Digital Dao - Journey",
        "style": "chiptune, 8-bit, lo-fi, ambient, exploration, retro game, calm, contemplative, pixel",
        "prompt": "[Instrumental]\nA calm 8-bit exploration theme for navigating a cyberpunk world map. "
                  "Gentle arpeggios, soft chiptune melody, contemplative mood. Inspired by classic JRPG "
                  "overworld themes. Hints of Chinese traditional instruments in 8-bit form.",
        "instrumental": True,
    },
    {
        "id": "boss_bgm",
        "title": "Digital Dao - Old Self Awakens",
        "style": "chiptune, 8-bit, boss battle, epic, dramatic, intense, dark, cyberpunk, heavy, glitch",
        "prompt": "[Instrumental]\nAn epic 8-bit boss battle theme. Dark, intense, with glitch effects. "
                  "Two phases: first half is menacing and rhythmic, second half explodes into frantic "
                  "chiptune fury. Heavy bass drops, rapid-fire arpeggios, ominous choir-like synths. "
                  "The final confrontation against your corrupted digital self.",
        "instrumental": True,
    },
    {
        "id": "opening_bgm",
        "title": "Digital Dao - Awakening",
        "style": "chiptune, 8-bit, cinematic, building, atmospheric, cyberpunk, emotional, pixel, narrative",
        "prompt": "[Instrumental]\nA cinematic 8-bit opening sequence theme. Starts quiet and mysterious, "
                  "builds gradually to a triumphant climax. Tells the story of digital awakening through "
                  "music. Blend of melancholy and hope. Perfect for a pixel art cutscene.",
        "instrumental": True,
    },
    {
        "id": "victory_bgm",
        "title": "Digital Dao - Enlightenment",
        "style": "chiptune, 8-bit, triumphant, ethereal, victory, uplifting, cyberpunk, celestial, peaceful",
        "prompt": "[Instrumental]\nA triumphant 8-bit victory fanfare that transitions into a peaceful, "
                  "ethereal melody. Celebrates digital enlightenment and the defeat of the old self. "
                  "Bright chiptune arpeggios, ascending scales, then dissolves into meditative calm. "
                  "Blend of celebration and spiritual peace.",
        "instrumental": True,
    },
]

# ============================================================
# SFX 定义 (使用 V5 音效生成，如果 API 支持)
# ============================================================

SFX_TRACKS = [
    {"id": "sfx_attack",      "prompt": "8-bit retro game sword slash attack sound effect, short, sharp"},
    {"id": "sfx_defend",      "prompt": "8-bit retro game shield block defense sound, metallic clang"},
    {"id": "sfx_heal",        "prompt": "8-bit retro game healing sparkle sound, warm ascending tones"},
    {"id": "sfx_damage",      "prompt": "8-bit retro game hit damage sound, crunchy impact"},
    {"id": "sfx_card_play",   "prompt": "8-bit retro game card play whoosh sound, quick swipe"},
    {"id": "sfx_card_draw",   "prompt": "8-bit retro game card draw sound, light page flip"},
    {"id": "sfx_summon",      "prompt": "8-bit retro game summon creature magical appearance sound"},
    {"id": "sfx_death",       "prompt": "8-bit retro game enemy death explosion, dissolve into pixels"},
    {"id": "sfx_corruption",  "prompt": "8-bit retro game poison corruption bubbling dark sound"},
    {"id": "sfx_burn",        "prompt": "8-bit retro game fire burn crackling sound, short burst"},
    {"id": "sfx_bell",        "prompt": "8-bit retro game temple bell ring, resonant, mystical"},
    {"id": "sfx_glitch",      "prompt": "8-bit retro game digital glitch distortion error sound"},
    {"id": "sfx_levelup",     "prompt": "8-bit retro game level up fanfare, triumphant short jingle"},
    {"id": "sfx_coin",        "prompt": "8-bit retro game coin collect pickup sound, bright bling"},
    {"id": "sfx_button",      "prompt": "8-bit retro game menu button click select sound"},
    {"id": "sfx_transition",  "prompt": "8-bit retro game scene transition whoosh sweep sound"},
    {"id": "sfx_boss_appear", "prompt": "8-bit retro game boss appearance dramatic rumble warning"},
    {"id": "sfx_yinyang",     "prompt": "8-bit retro game yin yang balance harmony chime, mystical"},
]


# ============================================================
# API 函数
# ============================================================

def generate_music(track: dict) -> str:
    """提交音乐生成任务，返回 taskId"""
    payload = {
        "customMode": True,
        "instrumental": track.get("instrumental", True),
        "model": MODEL,
        "title": track["title"],
        "style": track["style"],
        "prompt": track["prompt"],
        "callBackUrl": "https://localhost/callback",  # 占位，用轮询
    }

    resp = requests.post(f"{BASE_URL}/api/v1/generate", headers=HEADERS, json=payload)

    if resp.status_code != 200:
        print(f"  [ERROR] HTTP {resp.status_code}: {resp.text}")
        return ""

    data = resp.json()
    if data.get("code") != 200:
        print(f"  [ERROR] API: {data.get('msg', 'unknown error')}")
        return ""

    task_id = data["data"]["taskId"]
    print(f"  [OK] taskId = {task_id}")
    return task_id


def check_status(task_id: str) -> dict:
    """检查生成状态"""
    resp = requests.get(
        f"{BASE_URL}/api/v1/generate/record-info",
        headers=HEADERS,
        params={"taskId": task_id},
    )
    if resp.status_code != 200:
        return {"status": "ERROR", "error": f"HTTP {resp.status_code}"}

    data = resp.json()
    if data.get("code") != 200:
        return {"status": "ERROR", "error": data.get("msg", "unknown")}

    return data["data"]


def wait_and_download(task_id: str, output_name: str) -> bool:
    """轮询等待完成并下载"""
    for attempt in range(MAX_POLLS):
        info = check_status(task_id)
        status = info.get("status", "UNKNOWN")
        print(f"  [{output_name}] 状态: {status} ({attempt + 1}/{MAX_POLLS})")

        if status in ("SUCCESS", "FIRST_SUCCESS"):
            suno_data = info.get("response", {}).get("sunoData", [])
            if not suno_data:
                print(f"  [WARN] 无音频数据")
                return False

            # 取第一首
            track = suno_data[0]
            audio_url = track.get("audioUrl", "")
            if not audio_url:
                audio_url = track.get("streamAudioUrl", "")
            if not audio_url:
                print(f"  [WARN] 无下载链接")
                return False

            # 下载
            output_path = OUTPUT_DIR / f"{output_name}.mp3"
            print(f"  下载中: {audio_url[:80]}...")
            audio_resp = requests.get(audio_url)
            if audio_resp.status_code == 200:
                output_path.write_bytes(audio_resp.content)
                duration = track.get("duration", "?")
                print(f"  [OK] 已保存: {output_path} ({duration}s)")
                return True
            else:
                print(f"  [ERROR] 下载失败: HTTP {audio_resp.status_code}")
                return False

        elif status in ("CREATE_TASK_FAILED", "GENERATE_AUDIO_FAILED",
                        "CALLBACK_EXCEPTION", "SENSITIVE_WORD_ERROR"):
            err = info.get("errorMessage", "未知错误")
            print(f"  [ERROR] 生成失败: {err}")
            return False

        time.sleep(POLL_INTERVAL)

    print(f"  [TIMEOUT] 超时，任务可能仍在进行: {task_id}")
    return False


# ============================================================
# 主流程
# ============================================================

def save_task_log(tasks: dict):
    """保存任务 ID 记录（用于断点续传）"""
    TASK_LOG.write_text(json.dumps(tasks, indent=2, ensure_ascii=False))


def load_task_log() -> dict:
    """加载已有任务记录"""
    if TASK_LOG.exists():
        return json.loads(TASK_LOG.read_text())
    return {}


def main():
    parser = argparse.ArgumentParser(description="CyberTao SUNO BGM/SFX 生成器")
    parser.add_argument("--bgm-only", action="store_true", help="仅生成 BGM")
    parser.add_argument("--sfx-only", action="store_true", help="仅生成 SFX")
    parser.add_argument("--check", type=str, help="检查指定 taskId 状态")
    parser.add_argument("--download-only", action="store_true",
                        help="仅下载已有任务的结果（从 suno_tasks.json 读取）")
    args = parser.parse_args()

    # 确保输出目录存在
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 检查单个任务
    if args.check:
        info = check_status(args.check)
        print(json.dumps(info, indent=2, ensure_ascii=False))
        return

    # 仅下载模式
    if args.download_only:
        tasks = load_task_log()
        if not tasks:
            print("无已保存的任务记录 (suno_tasks.json)")
            return
        for name, task_id in tasks.items():
            if task_id:
                print(f"\n下载 {name}...")
                wait_and_download(task_id, name)
        return

    # 确定要生成的列表
    tracks_to_generate = []
    if not args.sfx_only:
        tracks_to_generate.extend(BGM_TRACKS)
    if not args.bgm_only:
        # SFX 用非 custom 模式（简短 prompt）
        for sfx in SFX_TRACKS:
            tracks_to_generate.append({
                "id": sfx["id"],
                "title": sfx["id"].replace("sfx_", "CyberTao SFX - "),
                "style": "8-bit, retro game, sound effect, chiptune",
                "prompt": sfx["prompt"],
                "instrumental": True,
            })

    print(f"=" * 60)
    print(f"CyberTao SUNO 音频生成器")
    print(f"API Key: {SUNO_API_KEY[:8]}...{SUNO_API_KEY[-4:]}")
    print(f"模型: {MODEL}")
    print(f"输出目录: {OUTPUT_DIR}")
    print(f"待生成: {len(tracks_to_generate)} 首")
    print(f"=" * 60)

    # 加载已有记录
    task_log = load_task_log()

    # 提交所有任务
    print("\n[阶段 1/2] 提交生成任务...")
    for track in tracks_to_generate:
        tid = track["id"]
        if tid in task_log and task_log[tid]:
            print(f"\n{tid}: 已有任务 {task_log[tid]}，跳过提交")
            continue

        print(f"\n提交: {tid} ({track['title']})")
        task_id = generate_music(track)
        task_log[tid] = task_id
        save_task_log(task_log)

        # 限速: 每 1 秒提交一个
        time.sleep(1)

    # 等待并下载所有结果
    print(f"\n\n[阶段 2/2] 等待生成完成并下载...")
    results = {}
    for track in tracks_to_generate:
        tid = track["id"]
        task_id = task_log.get(tid, "")
        if not task_id:
            results[tid] = "SKIPPED"
            continue

        # 检查是否已下载
        output_path = OUTPUT_DIR / f"{tid}.mp3"
        if output_path.exists():
            print(f"\n{tid}: 文件已存在，跳过")
            results[tid] = "EXISTS"
            continue

        print(f"\n等待: {tid}...")
        success = wait_and_download(task_id, tid)
        results[tid] = "OK" if success else "FAILED"

    # 汇总
    print(f"\n\n{'=' * 60}")
    print("生成汇总:")
    print(f"{'=' * 60}")
    for name, status in results.items():
        icon = "✅" if status in ("OK", "EXISTS") else "❌" if status == "FAILED" else "⏭️"
        print(f"  {icon} {name}: {status}")

    ok_count = sum(1 for s in results.values() if s in ("OK", "EXISTS"))
    print(f"\n成功: {ok_count}/{len(results)}")

    if ok_count > 0:
        print(f"\n下一步:")
        print(f"  1. 在 Godot 中导入 Assets/Audio/*.mp3")
        print(f"  2. 修改 AudioManager.gd 加载 MP3 文件替代程序化生成")
        print(f"  3. 详见 AudioManager 集成代码")


if __name__ == "__main__":
    main()
