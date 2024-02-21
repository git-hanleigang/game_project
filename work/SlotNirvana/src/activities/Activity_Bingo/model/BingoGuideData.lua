--[[
    time:2022-09-01 11:38:43
]]
local BingoGuideData = {}

-- 引导主题
BingoGuideData.guideTheme = "Bingo"

-- 引导入口配置信息
BingoGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterBingoMain"},
    {id = 2, startStep = "1101", guideName = "enterBingoPick"}
}
-- 步骤信息
BingoGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterBingoMain",
        nextStep = "1002",
        isCoerce = true,
        archiveStep = "",
        luaName = "BingoGameUI",
        signIds = "s001|s002",
        tipIds = "t001"
    },
    {
        stepId = "1002",
        guideName = "enterBingoMain",
        nextStep = "1002",
        isCoerce = true
    },
    {
        stepId = "1101",
        guideName = "enterBingoPick",
        nextStep = "1102",
        isCoerce = true,
        archiveStep = "",
        luaName = "BingoZeusMainLayer",
        signIds = "s003|s004",
        tipIds = "t002"
    },
    {
        stepId = "1102",
        guideName = "enterBingoPick",
        nextStep = "1102",
        isCoerce = true
    }
}

-- 标记节点信息
BingoGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "BingoGameUI",
        nodeName = "node_zeus",
        -- type = "clip",
        size = "180|70",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s002",
        luaName = "BingoGameUI",
        nodeName = "node_shakepool",
        size = "240|100",
        offset = "2|-225",
        anchor = "0.5|0.0"
    },
    {
        signId = "s003",
        luaName = "BingoZeusMainLayer",
        nodeName = "node_npc",
        size = "300|450",
        anchor = "0.5|0.1",
        zOrder = 1,
        isBlock = true
    },
    {
        signId = "s004",
        luaName = "BingoZeusMainLayer",
        nodeName = "node_board",
        size = "800|500",
        anchor = "0.5|0.5"
    }
}

-- 提示节点信息
BingoGuideData.tipInfos = {
    {
        tipId = "t001",
        luaName = "BingoGameUI",
        nodeName = "node_guide_1",
        type = "csb",
        path = "Activity/csd/Bingo_Guide/BingoFirstNode_1.csb"
    },
    {
        tipId = "t002",
        luaName = "BingoZeusMainLayer",
        nodeName = "node_guide_2",
        zOrder = 1,
        type = "csb",
        path = "Activity/csd/Bingo_Guide/BingoFirstNode_2.csb"
    }
}

return BingoGuideData
