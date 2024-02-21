--[[
    time:2022-09-01 11:38:43
]]
local MinzGuideData = {}

-- 引导主题
MinzGuideData.guideTheme = "Minz"

-- 引导入口配置信息
MinzGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterMinzMainLayer"},
}
-- 步骤信息
MinzGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterMinzMainLayer",
        nextStep = "1002",
        archiveStep = "",
        luaName = "MinzMainLayer",
        signIds = "s001|s002",
        tipIds = "1"
    },
    {
        stepId = "1002",
        guideName = "enterMinzMainLayer",
        nextStep = "1003",
        archiveStep = "",
        luaName = "MinzMainLayer",
        signIds = "s003",
        tipIds = "2"
    },
    {
        stepId = "1003",
        guideName = "enterMinzMainLayer",
        nextStep = "1004",
        archiveStep = "",
        luaName = "MinzMainLayer",
        signIds = "s004",
        tipIds = "3"
    }
}

-- 标记节点信息
MinzGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "MinzMainLayer",
        nodeName = "node_guide",
    },
    {
        signId = "s002",
        luaName = "MinzMainLayer",
        nodeName = "node_guide",
    },
    {
        signId = "s003",
        luaName = "MinzMainLayer",
        nodeName = "node_guide",
    },
    {
        signId = "s004",
        luaName = "MinzMainLayer",
        nodeName = "node_Shop",
        size = "135|126",
        anchor = "0.5|0.5",
        isBlock = true
    }
}

-- 提示节点信息
MinzGuideData.tipInfos = {
    {
        tipId = "1",
        luaName = "MinzMainLayer",
        nodeName = "node_guide_1",
        type = "lua",
        path = "MinzCode/MinzGudieNode"
    },
    {
        tipId = "2",
        luaName = "MinzMainLayer",
        nodeName = "node_guide_2",
        type = "lua",
        path = "MinzCode/MinzGudieNode"
    },
    {
        tipId = "3",
        luaName = "MinzMainLayer",
        nodeName = "node_guide_3",
        type = "lua",
        path = "MinzCode/MinzGudieNode"
    }
}

return MinzGuideData
