--[[
    time:2022-09-01 11:38:43
]]
local PipeConnectGuideData = {}

-- 引导主题
PipeConnectGuideData.guideTheme = "Activity_PipeConnect"

-- 引导入口配置信息
PipeConnectGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterPipeGame_1", preGuides = ""},
    {id = 2, startStep = "1101", guideName = "enterPipeGame_2", preGuides = ""},
}
-- 步骤信息
PipeConnectGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterPipeGame_1",
        nextStep = "1002",
        isCoerce = false,
        opacity = 0,
        archiveStep = "",
        luaName = "PipeConnectGameUI",
        signIds = "s002",
        tipIds = "t003|t001"
    },
    {
        stepId = "1002",
        guideName = "enterPipeGame_1",
        nextStep = "1003",
        isCoerce = true,
        opacity = 0,
        archiveStep = "",
        luaName = "PipeConnectGameUI",
        signIds = "s001",
        tipIds = "t002|t005"
    },
    {
        stepId = "1101",
        guideName = "enterPipeGame_2",
        nextStep = "1102",
        isCoerce = false,
        opacity = 0,
        archiveStep = "",
        luaName = "PipeConnectGameUI",
        signIds = "s003",
        tipIds = "t006|t004"
    }
}

-- 标记节点信息
PipeConnectGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "PipeConnectGameUI",
        nodeName = "node_guide",
        size = "290|100",
        offset = "0|3",
        anchor = "0.5|0.5",
    },
    {
        signId = "s002",
        luaName = "PipeConnectGameUI",
        nodeName = "node_guide_1",
        anchor = "0.5|0.5",
        zOrder = 1,
    },
    {
        signId = "s003",
        luaName = "PipeConnectGameUI",
        nodeName = "node_guide_1",
        anchor = "0.5|0.5"
    }
}

-- 提示节点信息
PipeConnectGuideData.tipInfos = {
    {
        tipId = "t001",
        luaName = "PipeConnectGameUI",
        nodeName = "node_guide_1",
        type = "csb",
        path = "Activity_PipeConnect/csd/PipeConnect_Guide/PipeConnect_FirstNode_1.csb"
    },
    {
        tipId = "t002",
        luaName = "PipeConnectGameUI",
        nodeName = "node_guide_1",
        zOrder = 1,
        type = "csb",
        path = "Activity_PipeConnect/csd/PipeConnect_Guide/PipeConnect_FirstNode_2.csb"
    },
    {
        tipId = "t003",
        luaName = "PipeConnectGameUI",
        nodeName = "node_guide_1",
        zOrder = 1,
        type = "csb",
        path = "Activity_PipeConnect/csd/PipeConnect_Guide/PipeConnect_FirstMaskNode_1.csb"
    },
    {
        tipId = "t004",
        luaName = "PipeConnectGameUI",
        nodeName = "node_guide_1",
        zOrder = 1,
        type = "csb",
        path = "Activity_PipeConnect/csd/PipeConnect_Guide/PipeConnect_FirstNode_3.csb"
    },
    {
        tipId = "t005",
        luaName = "PipeConnectGameUI", 
        nodeName = "node_guide_1",
        zOrder = 1,
        type = "lua",
        path = "Activity/PipeConnectGuide/PipeConnectGuideFingerNode"
    },
    {
        tipId = "t006",
        luaName = "PipeConnectGameUI",
        nodeName = "node_guide_1",
        zOrder = 1,
        type = "csb",
        path = "Activity_PipeConnect/csd/PipeConnect_Guide/PipeConnect_FirstMaskNode_2.csb"
    }
}

return PipeConnectGuideData
