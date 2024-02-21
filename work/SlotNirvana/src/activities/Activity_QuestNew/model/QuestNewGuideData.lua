--[[
    time:2022-09-01 11:38:43
]]
local QuestNewGuideData = {}

-- 引导主题
QuestNewGuideData.guideTheme = "QuestNew"

-- 引导入口配置信息
QuestNewGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterQuestMap_1", preGuides = ""},
    {id = 2, startStep = "1101", guideName = "enterQuestMap_2", preGuides = ""},
    {id = 3, startStep = "1201", guideName = "enterQuestMap_3", preGuides = "enterQuestMap_2"},
    {id = 4, startStep = "1501", guideName = "enterQuestChapterMain", preGuides = ""},
}
-- 步骤信息
QuestNewGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterQuestMap_1",
        nextStep = "1002",
        isCoerce = true,
        archiveStep = "",
        luaName = "QuestNewMapRoadLayer",
        signIds = "s001",
        tipIds = "t001"
    },
    {
        stepId = "1101",
        guideName = "enterQuestMap_2",
        nextStep = "1102",
        isCoerce = true,
        archiveStep = "",
        luaName = "QuestNewMainMapView",
        signIds = "s002",
        tipIds = "t003"
    },
    {
        stepId = "1201",
        guideName = "enterQuestMap_3",
        nextStep = "1202",
        isCoerce = false,
        archiveStep = "",
        luaName = "QuestNewMapRoadLayer",
        signIds = "s003",
        tipIds = "t004"
    },
    {
        stepId = "1202",
        guideName = "enterQuestMap_3",
        nextStep = "1203",
        isCoerce = false,
        archiveStep = "",
        luaName = "QuestNewMapRoadLayer",
        signIds = "s004",
        tipIds = "t005"
    },
    {
        stepId = "1203",
        guideName = "enterQuestMap_3",
        nextStep = "1204",
        isCoerce = true,
        archiveStep = "",
        luaName = "QuestNewMapRoadLayer",
        signIds = "s005",
        tipIds = "t002"
    }
}

-- 标记节点信息
QuestNewGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "QuestNewMapRoadLayer",
        nodeName = "Node_1",
        --type = "clip|",
        size = "160|230",
        offset = "0|33",
        anchor = "0.5|0.5",
    },
    {
        signId = "s002",
        luaName = "QuestNewMainMapView",
        nodeName = "node_starmeter_entrance",
        size = "140|140",
        anchor = "0.5|0.5",
        zOrder = 1,
    },
    {
        signId = "s003",
        luaName = "QuestNewMapRoadLayer",
        nodeName = "node_wheel",
        anchor = "0.5|0.5"
    },
    {
        signId = "s004",
        luaName = "QuestNewMapRoadLayer",
        nodeName = "node_wheel",
        anchor = "0.5|0.5"
    },
    {
        signId = "s005",
        luaName = "QuestNewMapRoadLayer",
        nodeName = "Node_2",
        --type = "clip|",
        size = "160|230",
        offset = "0|33",
        anchor = "0.5|0.5",
    },
    {
        signId = "s006",
        luaName = "QuestNewChapterStarPrizesLayer",
        nodeName = "btn_close",
        --type = "clip|",
        size = "76|76",
        offset = "0|0",
        anchor = "0.5|0.5",
    }
}

-- 提示节点信息
QuestNewGuideData.tipInfos = {
    {
        tipId = "t001",
        luaName = "QuestNewMapRoadLayer",
        nodeName = "node_guide_1",
        type = "lua",
        path = "baseQuestNewCode/guide/QuestNewGuideNode"
    },
    {
        tipId = "t002",
        luaName = "QuestNewMapRoadLayer",
        nodeName = "node_guide_2",
        zOrder = 1,
        type = "lua",
        path = "baseQuestNewCode/guide/QuestNewGuideNode"
    },
    {
        tipId = "t003",
        luaName = "QuestNewMainMapView",
        nodeName = "node_guide",
        zOrder = 1,
        type = "lua",
        path = "baseQuestNewCode/guide/QuestNewGuideNode"
    },
    {
        tipId = "t004",
        luaName = "QuestNewMapRoadLayer",
        nodeName = "node_guide_3",
        zOrder = 1,
        type = "lua",
        path = "baseQuestNewCode/guide/QuestNewGuideNode"
    },
    {
        tipId = "t005",
        luaName = "QuestNewMapRoadLayer", 
        nodeName = "node_guide_3",
        zOrder = 1,
        type = "lua",
        path = "baseQuestNewCode/guide/QuestNewGuideNode"
    }
}

return QuestNewGuideData
