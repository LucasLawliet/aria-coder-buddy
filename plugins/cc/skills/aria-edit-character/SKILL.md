---
name: aria-edit-character
description: Use when the user wants to open Aria's character editor UI to fine-tune the current avatar — they say things like "打开编辑器" / "改发型" / "改头发" / "换衣服" / "改外观" / "调一下样子" / "细调一下" / "打开捏人界面" / "open editor" / "edit avatar" / "change hairstyle". Different from aria-pick-character: this opens the editor UI for sliders/textures/clothing tweaks on the CURRENT avatar; that one swaps to a different preset character. Run bin/model.sh — Flutter will push /character-editor route and the user can adjust everything in UI.
---

# Aria — 打开编辑器微调当前角色

用户在 chat 里想 **微调当前 avatar**(发型/服装/sliders/颜色)时,
跑 `bin/model.sh` 让 Aria 桌面 app 跳转到 character editor UI.

## 触发词

中文:
- "打开编辑器" / "开一下编辑器" / "调出编辑器"
- "改发型" / "换发型" / "改头发"
- "换衣服" / "改衣服"
- "改外观" / "调外观" / "调一下样子"
- "细调一下" / "微调一下"
- "打开捏人界面" (注意: 跟"捏人/换角色"区分,见下)

英文:
- "open editor" / "open character editor"
- "edit avatar" / "edit appearance"
- "change hairstyle" / "change clothes"
- "tweak the model" / "fine-tune"

## 跟 aria-pick-character 的区分

| Skill | 触发词 | 行为 |
|---|---|---|
| **aria-edit-character** (这条) | 改发型/换衣服/调外观 | 打开 editor UI 让用户在面板里调 |
| **aria-pick-character** | 捏人/换角色/换形象 | 列 11 预设让用户选,直接 set-preset.sh 切换 |

如果用户说"捏人" / "换个人" → 优先走 aria-pick-character (列预设).
如果用户说"调当前这个" / "改一下她的发型" → 走 aria-edit-character (开 editor).

## 工作流

直接调脚本(它会保证 Aria.app 在跑,然后 broadcast 给 Flutter shell push 路由):

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/model.sh"
```

成功返回 `✓ 捏人界面已打开`,简短确认即可.
失败(Aria.app 没启动 / agent 没响应)告诉用户检查 app 是否在跑.

## 注意事项

- editor 内的修改 **实时生效** 到 avatar, 用户在 UI 里点 ✓ 保存 / × 放弃
- 这条 skill 只管打开 UI, 不替用户做具体调整 (那是 UI 里手动操作)
- 如果用户想"切到 maomao" 这种换预设,**不要**走这条,走 aria-pick-character
