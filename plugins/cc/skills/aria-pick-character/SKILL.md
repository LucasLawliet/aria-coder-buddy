---
name: aria-pick-character
description: Use when the user wants to swap Aria's avatar to a different anime character preset — they say things like "捏个人" / "换个角色" / "换个人" / "换样子" / "换形象" / "选个角色" / "挑个人" / "swap character" / "change avatar" / "switch model". List the 11 anime presets with a short intro (who they are, which show), then wait for the user to name one and run bin/set-preset.sh to switch the running aria.app instance.
---

# Aria — 切换捏人预设

用户在 chat 里说想换 avatar 时,先列出当前 11 个预设让用户选,确认选项后调
`set-preset.sh <preset_name>` 触发 aria.app 切换。

## 11 个预设(`preset_name` 是切换时要传的参数)

| preset_name | 角色 | 出处 |
|---|---|---|
| `maomao` | Maomao 猫猫 | 《药屋少女的呢喃》宫廷药师,聪明好奇但社恐 |
| `linglaitao` | Momo 绫濑桃 | 《胆大党》会用咒术战斗的高中女生 |
| `fulilian` | Frieren 芙莉莲 | 《葬送的芙莉莲》活了上千年的精灵魔法使 |
| `xiduochuan` | Marin 喜多川海梦 | 《更衣人偶坠入爱河》开朗活泼的 cos 少女 |
| `fujie` | Yor 约尔 | 《SPY×FAMILY》白天上班晚上当杀手的妈妈 |
| `aniya` | Anya 阿尼亚 | 《SPY×FAMILY》能读心的小女孩 |
| `helixunzi` | Kaoruko 和栗薰子 | 《薰香花朵凛然绽放》成熟温柔的女主 |
| `leisai` | Reze 蕾塞 | 《电锯人》咖啡厅女孩 / 苏联间谍 |
| `lingboli` | Rei 凌波丽 | 《新世纪福音战士》第一适格者,内敛沉默 |
| `mingrixiang` | Asuka 明日香 | 《新世纪福音战士》第二适格者,傲娇 |
| `leimu` | Rem 雷姆 | 《Re:从零开始》忠诚的蓝发鬼族女仆 |

(还有一个 `DefaultCharacter` 默认少女,通常不算在选择项里;用户明确要默认时可推荐)

## 工作流

### 第 1 步:用户说想换 → 列预设让他选

用户话术变体很多:
- "捏个人" / "捏个新的" / "捏个其他的"
- "换个角色" / "换个人" / "换个样子" / "换形象"
- "选个角色" / "挑个人"
- "swap character" / "change avatar" / "switch model"

直接回复(中文/英文按用户语言),给一个**简短**的预设单(每行一句,不要长篇大论):

> 我们现在有这 11 个预设:
>
> - **Maomao** 猫猫(药屋少女)— 聪明的宫廷药师
> - **Momo** 绫濑桃(胆大党)— 用咒术战斗
> - **Frieren** 芙莉莲(葬送的芙莉莲)— 活上千年的精灵
> - **Marin** 喜多川海梦(更衣人偶)— 开朗 cos 少女
> - **Yor** 约尔(SPY×FAMILY)— 杀手妈妈
> - **Anya** 阿尼亚(SPY×FAMILY)— 读心小女孩
> - **Kaoruko** 和栗薰子(薰香花朵)— 温柔女主
> - **Reze** 蕾塞(电锯人)— 间谍咖啡店女孩
> - **Rei** 凌波丽(EVA)— 沉默第一适格者
> - **Asuka** 明日香(EVA)— 傲娇第二适格者
> - **Rem** 雷姆(Re:从零)— 鬼族女仆
>
> 你想换哪个?

### 第 2 步:用户说出名字 → 调脚本切换

用户回复"要 maomao" / "换 Frieren" / "我要 Anya" 等,把回复**模糊匹配**到上面 11 个 preset_name 的任一种命名(中文名 / 英文名 / displayName / preset_name 本身),然后调:

```bash
"${CLAUDE_PLUGIN_ROOT}/bin/set-preset.sh" maomao
```

(把 `maomao` 替换成对应的 preset_name)

成功后简短确认,如:"好,切到 Maomao 啦"。
脚本失败(非 204 HTTP)就告诉用户"aria.app 没起来或 agent 没响应,看一下窗口"。

### 模糊匹配规则
- 用户提日文/英文名 → 找 displayName
- 用户提中文角色名 → 找出处描述里的中文(芙莉莲/阿尼亚/猫猫 等)
- 用户提作品名 → 让用户在该作品的预设里再选(SPY×FAMILY 有 Yor 和 Anya,EVA 有 Rei 和 Asuka)
- 完全匹配不上 → 复述列表让用户重选,不要瞎猜

## 注意事项

- 切换是**立即生效**的,不要让用户在 character_editor 里手动选(那是 `/aria-model` slash 的职责)
- 预设清单可能变化,如果用户问"还有别的吗",回复"目前只有这 11 个,要新角色等 Lucas 再加"
- 这条 skill 只管 builtin preset 切换;custom 存档需要用户在 character_editor 里手动选
