--[[
    
]]
local BlindBoxGuideData = {}

-- 引导主题
BlindBoxGuideData.guideTheme = ACTIVITY_REF.BlindBox

-- 引导入口配置信息
BlindBoxGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterGame"},
    {id = 2, startStep = "1101", guideName = "overGuide", preGuides = "enterGame"},
}
-- 步骤信息
BlindBoxGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterGame",
        nextStep = "1002",
        isCoerce = false,
        luaName = "BlindBoxMainLayer",
        signIds = "s001|s002",
        tipIds = "t001"
    },
    {
        stepId = "1002",
        guideName = "enterGame",
        nextStep = "1003",
        isCoerce = false,
        luaName = "BlindBoxMainLayer",
        signIds = "s003|s004|s005",
        tipIds = "t002"
    },
    {
        stepId = "1003",
        guideName = "enterGame",
        isCoerce = true,
        luaName = "BlindBoxMainLayer",
        signIds = "s003|s006|s007",
        tipIds = "t003"
    },
    {
        stepId = "1101",
        guideName = "overGuide",
        isCoerce = false,
        archiveStep = "1201",
        luaName = "BlindBoxMainLayer",
        signIds = "s001|s002",
        tipIds = "t004"
    }
}

-- 标记节点信息
BlindBoxGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "BlindBoxMainLayer",
        nodeName = "sp_bg",
        size = "1370|768",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s002",
        luaName = "BlindBoxMainLayer",
        nodeName = "Node_1",
        size = "1370|768",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s003",
        luaName = "BlindBoxMainLayer",
        nodeName = "Node_Box",
        size = "1145|700",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s004",
        luaName = "BlindBoxMainLayer",
        nodeName = "Node_4",
        size = "367.2|106.2",
        offset = "337.91|-296.69",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s005",
        luaName = "BlindBoxMainLayer",
        nodeName = "Node_26",
        size = "367.2|106.2",
        offset = "337.91|-296.69",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s006",
        luaName = "BlindBoxMainLayer",
        nodeName = "Node_key",
        size = "367.2|106.2",
        offset = "337.91|-296.69",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s007",
        luaName = "BlindBoxMainLayer",
        nodeName = "Node_4",
        size = "367.2|106.2",
        offset = "337.91|-296.69",
        anchor = "0.5|0.5",
        isBlock = false
    }
}

-- 提示节点信息
BlindBoxGuideData.tipInfos = {
    {
        tipId = "t001",
        luaName = "BlindBoxMainLayer",
        nodeName = "node_mid",
        type = "lua",
        path = "Activity_BlindBox.Activity.BlindBoxGuide",
    },
    {
        tipId = "t002",
        luaName = "BlindBoxMainLayer",
        nodeName = "node_mid",
        type = "lua",
        path = "Activity_BlindBox.Activity.BlindBoxGuide",
    },
    {
        tipId = "t003",
        luaName = "BlindBoxMainLayer",
        nodeName = "node_mid",
        type = "lua",
        path = "Activity_BlindBox.Activity.BlindBoxGuide",
    },
    {
        tipId = "t004",
        luaName = "BlindBoxMainLayer",
        nodeName = "node_mid",
        type = "lua",
        path = "Activity_BlindBox.Activity.BlindBoxGuide",
    }
}

return BlindBoxGuideData
