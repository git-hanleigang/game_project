-- blast活动 配置

local BlastConfig = {}

--------------------------------------    通用逻辑部分    --------------------------------------
BlastConfig.BUFF_STATE = {
    INACTIVE = "inactive", -- 未激活
    ACTIVE = "active" -- 激活
}

BlastConfig.BLAST_ITEM_STATE = {
    NO_SELECT = 0,
    SELECTED = 1
}

BlastConfig.CELL_REWARD_TYPE = {
    EMPTY = "EMPTY", --空的
    PICKS = "PICKS", --次数
    COINS = "COINS", --钱
    STAGE_COINS = "STAGE_COINS", --总钱百分比
    CARD = "CARD", --集卡
    JACKPOT = "JACKPOT", --jackpot
    CLEAR = "CLEAR", --过关道具
    GEMS = "GEMS", --第二货币
    ITEM_1 = "ITEM_1", --buff1
    ITEM_2 = "ITEM_2", --buff2
    ITEM_3 = "ITEM_3", --buff3
    REFRESH_TREASURE = "REFRESH_TREASURE", --特殊道具
    AFFAIR = "AFFAIR", --事件图标
    BOMB1 = "BOMB1",
    BOMB2 = "BOMB2",
    BOMB3 = "BOMB3",
    BOMB4 = "BOMB4"
}

-- jackpot类型 这个数字是跟服务器绑定的 不能动
BlastConfig.JACKPOT_TYPE = {
    GRAND = 4,
    MAJOR = 3,
    MINOR = 2,
    MINI = 1
}

-- 关卡中获得blast次数的弹框 复选框是否选中标记
BlastConfig.ActivityBlast_CollectDice_CanShow = "ActivityBlast_CollectDice_CanShow"

BlastConfig.BLAST_MAIN_GUIDE = "BLAST_MAIN_GUIDE33" -- 新手引导步骤key
--------------------------------------    通用逻辑部分    --------------------------------------

--------------------------------------    主题相关部分    --------------------------------------
-- 主题类型
BlastConfig.THEMES = {
    OCEAN = "Activity_Blast", -- 海洋主题
    HALLOWEEN = "Activity_BlastHalloween", -- 万圣节主题
    THANKSGIVING = "Activity_BlastThanksGiving", -- 感恩节主题
    CHRISTMAS = "Activity_BlastChristmas", -- 圣诞节主题
    EASTER = "Activity_BlastEaster", -- 复活节主题
    THREE3RD = "Activity_Blast3RD",   --三周年
    BLOSSOM = "Activity_BlastBlossom", -- 阿凡达主题
    MERMAID = "Activity_BlastMermaid" -- 人鱼主题
}

-- 主题索引路径
BlastConfig.THEME_PATH = {
    [BlastConfig.THEMES.OCEAN] = "Activity/Blast/",
    [BlastConfig.THEMES.HALLOWEEN] = "Activity/Blast_Halloween/",
    [BlastConfig.THEMES.THANKSGIVING] = "Activity/Blast_ThanksGiving/",
    [BlastConfig.THEMES.CHRISTMAS] = "Activity/Blast_Christmas/",
    [BlastConfig.THEMES.EASTER] = "Activity/Blast_Easter/",
    [BlastConfig.THEMES.THREE3RD] = "Activity/Blast_3RD/",
    [BlastConfig.THEMES.BLOSSOM] = "Activity/Blast_Blossom/",
    [BlastConfig.THEMES.MERMAID] = "Activity/Blast_Mermaid/"
}

-- 给一个默认主题 应对现在没填写多主题会报错的问题
BlastConfig.theme = nil

-- 获取主题
function BlastConfig.getThemeName()
    return BlastConfig.theme
end

-- 设置主题
function BlastConfig.setThemeName(theme_str)
    if theme_str == "Activity_Blast" then
        BlastConfig.theme = BlastConfig.THEMES.OCEAN
    elseif theme_str == "Activity_BlastHalloween" then
        BlastConfig.theme = BlastConfig.THEMES.HALLOWEEN
    elseif theme_str == "Activity_BlastThanksGiving" then
        BlastConfig.theme = BlastConfig.THEMES.THANKSGIVING
    elseif theme_str == "Activity_BlastChristmas" then
        BlastConfig.theme = BlastConfig.THEMES.CHRISTMAS
    elseif theme_str == "Activity_BlastEaster" then
        BlastConfig.theme = BlastConfig.THEMES.EASTER
    elseif theme_str == "Activity_Blast3RD" then
        BlastConfig.theme = BlastConfig.THEMES.THREE3RD
    elseif theme_str == "Activity_BlastBlossom" then
        BlastConfig.theme = BlastConfig.THEMES.BLOSSOM
    elseif theme_str == "Activity_BlastMermaid" then
        BlastConfig.theme = BlastConfig.THEMES.MERMAID
    end

    BlastConfig.reloadFile()
end

--改动比较大的主题单独处理
function BlastConfig.getThemeFile(theme_str)
    local path = "Activity/BlastGame/MainUI/BlastMainUI"
    if theme_str == "Activity_BlastBlossom" then
        path = "Activity/BlastGame/NewMainUI/Blossom/BlossomBlastMainUI"
    elseif theme_str == "Activity_BlastMermaid" then
        path = "Activity/BlastGame/MainUI/Mermaid/MermaidBlastMainUI"
    end
    return path
end

-- 重新加载
function BlastConfig.reloadFile()
    local theme_name = BlastConfig.getThemeName()
    local theme_path = BlastConfig.THEME_PATH[theme_name]
    if not theme_path or theme_path == "" then
        theme_path = "Activity/Blast_Blossom/"
    end
    -- 主界面相关资源 --
    -- 主界面资源
    BlastConfig.BlastMainmap = theme_path .. "BlastMainmap.csb"
    -- buff资源
    BlastConfig.Blast_Buff = theme_path .. "Blast_Powerup.csb"
    BlastConfig.Blast_Powerup_Stage = theme_path .. "Blast_Powerup_Stage.csb"
    -- pick按钮资源
    BlastConfig.Blast_Pick = theme_path .. "Blast_Pick.csb"
    -- title控件资源
    BlastConfig.Blast_title = theme_path .. "Blast_title.csb"
    -- 过关加成百分比显示
    BlastConfig.Blast_percent = theme_path .. "Blast_Jiacheng.csb"

    -- 玩法介绍弹板
    BlastConfig.BlastRule = theme_path .. "BlastRule.csb"
    -- grand奖励
    BlastConfig.Blast_GrandJackpot = theme_path .. "Blast_GrandJackpot.csb"
    -- major奖励
    BlastConfig.Blast_MajorJackpot = theme_path .. "Blast_MajorJackpot.csb"
    -- minor奖励
    BlastConfig.Blast_MinorJackpot = theme_path .. "Blast_MinorJackpot.csb"
    -- mini奖励
    BlastConfig.Blast_MiniJackpot = theme_path .. "Blast_MiniJackpot.csb"
    -- 奖励卡牌资源
    BlastConfig.Blast_MainMapCell = theme_path .. "Blast_MainMapCell.csb"
    -- 道具飞粒子动效
    BlastConfig.Blast_CellRewardEffect = theme_path .. "Blast_Process_shouji.csb"
    -- 特殊道具飞粒子动效
    BlastConfig.Blast_CellBonusEffect = theme_path .. "Blast_Pick_tuowei.csb"
    -- bonus 贝壳扫光
    BlastConfig.Blast_MainMapCell_beike = theme_path .. "Blast_MainMapCell_beike.csb"
    -- -- 活动进度条资源
    -- BlastConfig.Blast_Process               = theme_path .. "Blast_Process.csb"
    -- 章节进度条资源
    BlastConfig.Blast_ProcessPage = theme_path .. "Blast_ProcessPage.csb"
    -- 活动总进度资源
    BlastConfig.Blast_ProcessRound = theme_path .. "Blast_ProcessRound.csb"
    -- 活动总进度背景光资源
    BlastConfig.Blast_ProcessRoundEffect = theme_path .. "Blast_ProcessRound_0.csb"

    -- 活动进度条 关卡道具奖励提示控件
    BlastConfig.Blast_Qipao = theme_path .. "Blast_Qipao.csb"
    BlastConfig.Blast_RankItem = theme_path .. "Blast_rank/Blast_RankItem.csb"
    -- 获得排名飞的动效
    BlastConfig.Blast_RankFlyEffect = theme_path .. "Blast_rank/Blast_Rank_flyLizi.csb"

    -- jackpot类型和资源绑定
    BlastConfig.ITEM_JACKPOT_TYPE = {
        [BlastConfig.JACKPOT_TYPE.GRAND] = BlastConfig.Blast_GrandJackpot,
        [BlastConfig.JACKPOT_TYPE.MAJOR] = BlastConfig.Blast_MajorJackpot,
        [BlastConfig.JACKPOT_TYPE.MINOR] = BlastConfig.Blast_MinorJackpot,
        [BlastConfig.JACKPOT_TYPE.MINI] = BlastConfig.Blast_MiniJackpot
    }

    -- 预定义jackpot累积奖励弹板
    BlastConfig.JACKPOT_REWARD_VIEW = {
        [BlastConfig.JACKPOT_TYPE.GRAND] = "Activity/BlastGame/RewardBoards/BlastGrandJackpotReward",
        [BlastConfig.JACKPOT_TYPE.MAJOR] = "Activity/BlastGame/RewardBoards/BlastMajorJackpotreward",
        [BlastConfig.JACKPOT_TYPE.MINOR] = "Activity/BlastGame/RewardBoards/BlastMinorJackpotReward",
        [BlastConfig.JACKPOT_TYPE.MINI] = "Activity/BlastGame/RewardBoards/BlastMiniJackpotReward"
    }
    BlastConfig.JACKPOT_REWARD_CSB = {
        [BlastConfig.JACKPOT_TYPE.GRAND] = theme_path .. "BlastReward_GrandJackpot.csb",
        [BlastConfig.JACKPOT_TYPE.MAJOR] = theme_path .. "BlastReward_MajorJackpot.csb",
        [BlastConfig.JACKPOT_TYPE.MINOR] = theme_path .. "BlastReward_MinorJackpot.csb",
        [BlastConfig.JACKPOT_TYPE.MINI] = theme_path .. "BlastReward_MiniJackpot.csb"
    }

    -- 奖励弹窗 --
    -- grand收集奖励展示面板
    BlastConfig.BlastReward_GrandJackpot = theme_path .. "BlastReward_GrandJackpot.csb"
    -- major收集奖励展示面板
    BlastConfig.BlastReward_MajorJackpot = theme_path .. "BlastReward_MajorJackpot.csb"
    -- minor收集奖励展示面板
    BlastConfig.BlastReward_MinorJackpot = theme_path .. "BlastReward_MinorJackpot.csb"
    -- mini收集奖励展示面板
    BlastConfig.BlastReward_MiniJackpot = theme_path .. "BlastReward_MiniJackpot.csb"

    -- 翻牌奖励展示面板
    BlastConfig.BlastReward_Cell = theme_path .. "BlastReward_Cell.csb"
    -- 过关奖励展示面板
    BlastConfig.BlastReward_Stage = theme_path .. "BlastReward_Stage.csb"
    -- 完整通关奖励展示面板
    BlastConfig.BlastReward_Final = theme_path .. "BlastReward_Final.csb"
    -- 奖励界面 buff特效
    BlastConfig.Blast_Powerup_jiangli = theme_path .. "Blast_Powerup_jiangli.csb"
    -- 过关章节显示动画
    BlastConfig.BlastChapterChange = theme_path .. "BlastChapterChange.csb"

    -- 关卡内展示 --
    -- 收集能量条
    BlastConfig.BlastGameSceneUI = theme_path .. "GameSceneUiNode.csb"
    -- 手机能量条 弹出提示框
    BlastConfig.Blast_Tip = theme_path .. "Blast_Tip.csb"

    -- 新手引导相关 --
    BlastConfig.Blast_Guide1 = theme_path .. "BlastTip_Guide1.csb"
    BlastConfig.Blast_Guide2 = theme_path .. "BlastTip_Guide2.csb"
    BlastConfig.Blast_Guide3 = theme_path .. "BlastTip_Guide3.csb"
    BlastConfig.Blast_Jl = theme_path .. "Blast_newcell.csb"
    BlastConfig.Blast_CollectCSB = theme_path .. "BlastReward_New.csb"
    BlastConfig.Blast_BoxTip = theme_path .. "Blast_bagshowitem.csb"
    BlastConfig.Blast_Node = theme_path .. "BlastMainmap_bag.csb"

    -- 背景音乐
    BlastConfig.blast_bgm = theme_path .. "Sound/blast_bgm.mp3"
    -- 翻牌音效
    BlastConfig.blast_collect = theme_path .. "Sound/blast_collect.mp3"
    -- 特殊道具音效
    BlastConfig.blast_bonus = theme_path .. "Sound/blast_bonus.mp3"
    -- jackpot收集音效
    BlastConfig.blast_jackpot_collect = theme_path .. "Sound/blast_jackpot_collect.mp3"
    -- jackpot集齐奖励弹板音效
    BlastConfig.blast_jackpot_reward = theme_path .. "Sound/blast_jackpot_reward.mp3"
    -- 翻牌奖励音效
    BlastConfig.blast_cell_reward = theme_path .. "Sound/blast_cell_reward.mp3"
    -- 过关奖励音效
    BlastConfig.blast_stage_reward = theme_path .. "Sound/blast_stage_reward.mp3"
    -- 通关奖励音效
    BlastConfig.blast_final_reward = theme_path .. "Sound/blast_final_reward.mp3"
    -- 过关飞粒子音效
    BlastConfig.blast_fly_partical = theme_path .. "Sound/blast_fly_partical.mp3"
    -- 有buff对奖励加成的音效
    BlastConfig.blast_buff_collect = theme_path .. "Sound/blast_buff_collect.mp3"

    --------------------    差异化的东西    --------------------
    BlastConfig.loadThemeSpecial()
end

-- 加载差异化的资源
function BlastConfig.loadThemeSpecial()
    local theme_name = BlastConfig.getThemeName()
    local theme_path = BlastConfig.THEME_PATH[theme_name]

    if theme_name == BlastConfig.THEMES.OCEAN then
        -- 这里的过场是一个气泡粒子 拼在工程里了
        -- 海洋主题特有资源
        -- 水草
        BlastConfig.effect_bg_cao = theme_path .. "spine/BlastMainmap_bg_cao"
    elseif theme_name == BlastConfig.THEMES.HALLOWEEN then
        -- 万圣节主题特有资源
        ---- 过场动画
        BlastConfig.Blast_guochang = theme_path .. "Sound/blast_guoguan.mp3"
        ---- 转场音效
        --BlastConfig.blast_new_stage = theme_path .. "Sound/blast_new_stage.mp3"
        BlastConfig.Blast_fankui_music = theme_path .. "Sound/blast_fly_fankui.mp3"
        BlastConfig.blast_fly_jiacheng = theme_path .. "Sound/blast_fly_jiacheng.mp3"
    elseif theme_name == BlastConfig.THEMES.THANKSGIVING then
        -- 感恩节主题特有资源
        -- 场动画spine
        --BlastConfig.Blast_guochang_thanksGiving_spine = theme_path .. "spine/Socre_ThanksGiving_Bonus3"
        -- 转场音效
        --BlastConfig.Blast_guochang_thanksGiving_music = theme_path .. "Sound/blast_new_stage_thanksGiving.mp3"
    elseif theme_name == BlastConfig.THEMES.CHRISTMAS then
        -- 圣诞节主题特有资源
        -- 过场动画spine
        -- BlastConfig.Blast_guochang_christmas_spine = theme_path .. "spine/quest_guochang"
        BlastConfig.Blast_fankui_music = theme_path .. "Sound/blast_fly_fankui.mp3"
        -- 转场音效
        BlastConfig.Blast_guochang_christmas_music = theme_path .. "Sound/blast_new_stage_christmas.mp3"
    elseif theme_name == BlastConfig.THEMES.EASTER then
        -- 复活节主题特有资源
        -- 过场动画spine
        BlastConfig.Blast_guochang_easter_spine = theme_path .. "spine/guochangtuzi"
        -- 转场音效
        BlastConfig.Blast_guochang_easter_music = theme_path .. "Sound/blast_new_stage_easter.mp3"
    elseif theme_name == BlastConfig.THEMES.THREE3RD then
        BlastConfig.Blast_fankui_music = theme_path .. "Sound/blast_fly_fankui.mp3"
        BlastConfig.blast_new_stage = theme_path .. "Sound/blast_new_stage.mp3"
    elseif theme_name == BlastConfig.THEMES.BLOSSOM then
        -- 阿凡达专场
        BlastConfig.Blast_guochang_xiaosan = theme_path .. "Sound/blast_flxiaosan.mp3"
        BlastConfig.Blast_guochang_shengzhang = theme_path .. "Sound/blast_flsz.mp3"
        BlastConfig.Blast_fankui = theme_path .. "Sound/blast_stage_fankui.mp3"
        BlastConfig.Blast_guide = theme_path .. "Sound/blast_guide.mp3"
        BlastConfig.Blast_jssz = theme_path .. "Sound/blast_jssz.mp3"  --金色种子分裂
        BlastConfig.Blast_Bom = theme_path .. "Blast_Bomb.csb"
        BlastConfig.Blast_BomKuosan = theme_path .. "Blast_Process_kuosan.csb"
        BlastConfig.Blast_BomRule = theme_path .. "BlastBombRule.csb"
        BlastConfig.Blast_sdbomb1 = theme_path .. "Sound/blast_Bomb1.mp3"  --点击炸弹音效
        BlastConfig.Blast_sdbomb2 = theme_path .. "Sound/blast_Bomb2.mp3"  --次级炸弹音效
        BlastConfig.Blast_newFly = theme_path .. "Sound/blast_newfly.mp3"  --次级炸弹音效
        BlastConfig.Blast_newBei = theme_path .. "Sound/blast_coinbei.mp3"  --次级炸弹音效
        BlastConfig.Blast_newClear = theme_path .. "Sound/blast_newclear.mp3"  --次级炸弹音效
    elseif theme_name == BlastConfig.THEMES.MERMAID then
        -- 人鱼
         -- 道具飞粒子动效
        BlastConfig.Blast_CellRewardEffect = theme_path .. "Blast_Pick_tuowei_normal.csb"
        -- 特殊道具飞粒子动效
        BlastConfig.Blast_CellBonusEffect = theme_path .. "Blast_Pick_tuowei_gold.csb"
        BlastConfig.Blast_guochang_xiaosan = theme_path .. "Sound/blast_flxiaosan.mp3"
        BlastConfig.Blast_guochang_shengzhang = theme_path .. "Sound/BLAST_Mermaid_Trans1.mp3"
        BlastConfig.Blast_guochang_2 = theme_path .. "Sound/BLAST_Mermaid_Trans2.mp3"
        BlastConfig.Blast_music_nvwu = theme_path .. "Sound/BLAST_Mermaid_witch.mp3"
        BlastConfig.Blast_music_pangxie = theme_path .. "Sound/BLAST_Mermaid_pangxie.mp3"
        BlastConfig.Blast_fankui = theme_path .. "Sound/blast_stage_fankui.mp3"
        BlastConfig.Blast_guide = theme_path .. "Sound/blast_guide.mp3"
        BlastConfig.Blast_jssz = theme_path .. "Sound/blast_jssz.mp3"  --金色种子分裂
        BlastConfig.Blast_ThingLayer = theme_path .. "Blast_Thing/Blast_Thing_Pick.csb"
        BlastConfig.spineNvWu = theme_path .. "spine/Blast_Mermaid_nvwu"
        BlastConfig.Blast_port = theme_path .. "Blast_Thing/Blast_Thing_pickPot.csb"
        BlastConfig.spineOneN = theme_path .. "spine/Blast_Mermaid_xiaochouyu"
        BlastConfig.spineHigh = theme_path .. "spine/Blast_Mermaid_jijuxie"
        BlastConfig.minReward = theme_path .. "Blast_Thing/Blast_Thing_Reward1.csb"
        BlastConfig.middleReward = theme_path .. "Blast_Thing/Blast_Thing_Reward2.csb"
        BlastConfig.bigReward = theme_path .. "Blast_Thing/Blast_Thing_Reward3.csb"
        BlastConfig.guang = theme_path .. "Blast_Thing/Blast_Thing_Glow.csb"
        BlastConfig.spinenpc = theme_path .. "spine/Activity_BlastMermaid_npc"
        BlastConfig.jackport_c = theme_path .. "Blast_JackpotCollect.csb"
        BlastConfig.thing_ani = theme_path .. "Blast_Thing/Blast_Thing_Pickcanying.csb"
        BlastConfig.pxhuiwu = theme_path .. "Sound/blast_pxhuiwu.mp3"  --螃蟹挥舞
        BlastConfig.pxlikai = theme_path .. "Sound/BLAST_Mermaid_pxLeave.mp3"  --螃蟹离开
        BlastConfig.fishcx = theme_path .. "Sound/BLAST_Mermaid_fish.mp3"  --鱼出现
        BlastConfig.fishxs = theme_path .. "Sound/BLAST_Mermaid_fishDisappear.mp3"  --鱼消失
        BlastConfig.fishyz = theme_path .. "Sound/BLAST_Mermaid_fishLeave.mp3"  --鱼youzou
        BlastConfig.empty = theme_path .. "Sound/blast_pick_empty.mp3"  --空贝壳
        BlastConfig.jk_st = theme_path .. "Sound/blast_jk_start.mp3"  --jk开始
        BlastConfig.jk_or = theme_path .. "Sound/blast_jk_over.mp3"  --jk开始
        BlastConfig.ctjl = theme_path .. "Sound/blast_jiangli.mp3"  --jk开始
    end
end

return BlastConfig
