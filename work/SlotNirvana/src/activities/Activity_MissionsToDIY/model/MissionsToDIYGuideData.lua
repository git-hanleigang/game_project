--[[
    
]]
local MissionsToDIYData = {}

-- 引导主题
MissionsToDIYData.guideTheme = ACTIVITY_REF.MissionsToDIY

-- 引导入口配置信息
MissionsToDIYData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterGame"},
    {id = 2, startStep = "1101", guideName = "overGuide", preGuides = "enterGame"},
}
-- 步骤信息
MissionsToDIYData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterGame",
        isCoerce = false,
        luaName = "Activity_MissionsToDIY",
        signIds = "s001",
        tipIds = "t001"
    },
    {
        stepId = "1101",
        guideName = "overGuide",
        isCoerce = false,
        archiveStep = "1201",
        luaName = "Activity_MissionsToDIY",
        signIds = "s002",
        tipIds = "t002"
    }
}

-- 标记节点信息
MissionsToDIYData.signInfos = {
    {
        signId = "s001",
        luaName = "Activity_MissionsToDIY",
        nodeName = "Node_Mission",
        size = "1370|768",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s002",
        luaName = "Activity_MissionsToDIY",
        nodeName = "Node_bottom",
        size = "1370|768",
        anchor = "0.5|0.5",
        isBlock = true
    }
}

-- 提示节点信息
MissionsToDIYData.tipInfos = {
    {
        tipId = "t001",
        luaName = "Activity_MissionsToDIY",
        nodeName = "Node_mid",
        type = "lua",
        path = "Activity_MissionsToDIY.Activity.MissionsToDIYGuide",
    },
    {
        tipId = "t002",
        luaName = "Activity_MissionsToDIY",
        nodeName = "Node_mid",
        type = "lua",
        path = "Activity_MissionsToDIY.Activity.MissionsToDIYGuide",
    }
}

return MissionsToDIYData
