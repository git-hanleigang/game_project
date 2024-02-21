-- quest 基础配置

local code_path = "QuestNewUserCode/GroupC/Quest/"
local res_path = "QuestNewUser/Activity/csd/GroupC/"
--代码路径
local ThemeConfig = {
    code = {
        QuestOpenView = "QuestNewUserCode/QuestNewUserOpenView", --quest开启界面
        QuestLoginView = "QuestNewUserCode/QuestNewUserLoginView", --quest开启界面
        QuestMainView = code_path .. "lobby/QuestNewUserMainViewC", --quest主界面
        --cell
        QuestBox = code_path .. "cell/QuestNewUserBox", --地图上宝箱
        QuestBoxReward = code_path .. "cell/QuestBoxReward", --宝箱打开得劲奖励
        QuestCell = code_path .. "cell/QuestNewUserCell", --关卡节点
        QuestGift = code_path .. "cell/QuestNewUserGift", -- 地图上的礼盒
        QuestCellTips = "QuestNewUserCode/QuestNewUserTipReward", --关卡奖励气泡
        QuestCellTipRewards = code_path .. "cell/QuestCellTipRewards", -- 奖励气泡里面的内容
        --lobby
        QuestLobbyTitle = "QuestNewUserCode/QuestNewUserLobbyTitle", -- quest彩金栏
        --map
        QuestMapControl = code_path .. "map/QuestNewUserMapControl", --地图控制
        --task
        QuestTaskDoneLayer = code_path .. "task/QuestNewUserTaskDoneView", --quest关卡任务完成
        QuestMapConfig = "QuestNewUser/Activity/QuestNewUserMap/questMapConfigC.json" --大地图配置文件json
    },
    --资源路径
    res = {
        QuestPopLayer = res_path .. "NewUser_QuestLayer_popview.csb",
        QuestPopLayer_por = res_path .. "NewUser_QuestLayer_popview_shu.csb",
        --
        QuestCellDL = res_path .. "NewUser_QuestCellDL.csb", --关卡下载进度
        QuestCellTips = res_path .. "NewUser_reward_tips.csb", -- 关卡奖励气泡
        QuestEnterCell = res_path .. "NewUser_QuestEnterCell.csb", --关卡任务展示单个描述
        QuestEnterLayer = res_path .. "NewUser_QuestEnterLayer.csb", --关卡任务展示弹版
        QuestEnterPorLayer = res_path .. "NewUser_QuestEnterLayer_Portrait.csb", --关卡任务展示弹版
        --主界面
        QuestMainLayer = res_path .. "NewUser_QuestLayer.csb", --主界面展示
        QuestLobbyLogo = res_path .. "NewUser_QuestLobbyLogo.csb", -- 主界面logo按钮
        QuestLobbyTitile = res_path .. "NewUser_QuestLayer_title.csb", --主界面标题
        -- QuestMapMask = res_path .. "QuestMapMask.csb", --地图迷雾
        QuestFinalReward = res_path .. "NewUser_QuestLayer_final_rewards.csb", -- 最终奖励
        QuestGiftReward = res_path .. "NewUser_QuestLayer_gift_rewards.csb", -- 礼盒奖励
        QuestMapBoxBig = res_path .. "NewUser_QuestMapBoxBig.csb", --地图宝箱最后一关资源
        --任务
        QuestTaskDoneLayer = res_path .. "NewUser_QuestTaskDoneLayer.csb", --任务完成界面
        QuestTaskProgress = res_path .. "NewUser_QuestTaskProgress.csb", --左侧任务条进度
        QuestTaskTipNode = res_path .. "NewUser_QuestTaskTipNode.csb", --左侧任务条提示
        QuestCell = res_path .. "NewUser_QuestCell.csb", --关卡节点
        QuestCellGift = res_path .. "NewUser_QuestCellGift.csb", --关卡礼物
        QuestCellGiftEff = res_path .. "NewUser_VipBoost.csb", --关卡礼物
        -- QuestCellGuide = res_path .. "QuestCellGuide.csb", --关卡引导小手
        QuestEntryNode = res_path .. "NewUser_QuestEntryNode.csb", --关卡内左侧条
        QuestMapArrow = res_path .. "NewUser_QuestMapArrow.csb", --地图箭头
        --bgm
        QuestBGMPath = "QuestNewUser/Activity/QuestNewUserSounds/Quest_bg.mp3",
        --other
        --地图碎片路径
        QuestMapCellPath = "QuestNewUser/Activity/QuestNewUserMap/ui_c/bg_",
        QuestMapRoadPath = "QuestNewUser/Activity/QuestNewUserMap/ui/quest_road.png", -- 地图上的路
        QuestMapDecorateNode = res_path .. "decorateNode.csb", -- 装饰层
        -- 地图参数
        QuestMapBgCount = 50,
        QuestMapBgWidth = 55,
        -- 地图配置
        BG_ROAD_LEN = 2748, -- 整个主题的长度，每个主题需要提前算好这个值
        BG_FAR_RATIO = 1, -- 远景长度比率 -- 算法 = BG_ROAD_LEN + 1660 / 背景图总长度
        BG_NEAR_RATIO = 1, -- 近景长度比率 -- 大于1 是因为需要比远景滑的快一些
        QUEST_TOP_SHOW = false -- 是否可以展示顶部条
    },
    config = {
        box_offset = 0,
        show_task_pop = true
    }
}

return ThemeConfig
