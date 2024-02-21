--[[
    time:2022-09-01 11:38:43
]]
local DragonChallengeGuideData = {}

-- 引导主题
DragonChallengeGuideData.guideTheme = ACTIVITY_REF.DragonChallenge

-- 引导入口配置信息
DragonChallengeGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterGame"},
    {id = 2, startStep = "2001", guideName = "triggerVulBuff"},
    {id = 3, startStep = "3001", guideName = "triggerInjuryBuff"},
}
-- 步骤信息
DragonChallengeGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterGame",
        nextStep = "1002",
        isCoerce = true,
        luaName = "DragonChallengeMainLayer",
        signIds = "s002|s003|s010|s007|s008|s009",
        event = "Event_Guide_Dragon_Select_Area",
        tipIds = "t001|t004"
    },
    {
        stepId = "1002",
        guideName = "enterGame",
        nextStep = "1004",
        isCoerce = false,
        luaName = "DragonChallengeMainLayer",
        signIds = "s006",
        tipIds = "t002"
    },
    {
        stepId = "1004",
        guideName = "enterGame",
        isCoerce = false,
        nextStep = "1005",
        luaName = "DragonChallengeMainLayer",
        signIds = "s001",
        tipIds = "t003"
    },
    {
        stepId = "2001",
        guideName = "triggerVulBuff",
        isCoerce = false,
        nextStep = "2002",
        luaName = "DragonChallengeMainLayer",
        signIds = "s011",
        tipIds = "t005"
    },
    {
        stepId = "3001",
        guideName = "triggerInjuryBuff",
        isCoerce = false,
        nextStep = "3002",
        luaName = "DragonChallengeMainLayer",
        signIds = "s011",
        tipIds = "t006"
    }
}

-- 标记节点信息
DragonChallengeGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_Wheel",
        size = "503|504",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s002",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_dragon",
        size = "600|600",
        offset = "0|0",
        anchor = "0.5|0.5",
        isBlock = true,
    },
    {
        signId = "s003",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_Progress",
        size = "723|120",
        anchor = "0.5|0.5",
        isBlock = true,
    },
    {
        signId = "s006",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_Jackpot",
        size = "677|174",
        anchor = "0.5|0.5",
        isBlock = true
    },
    {
        signId = "s007",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_area_1",
        size = "110|110",
        anchor = "0.5|0.5",
    },
    {
        signId = "s008",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_area_2",
        size = "110|110",
        anchor = "0.5|0.5",
    },
    {
        signId = "s009",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_area_3",
        size = "110|110",
        anchor = "0.5|0.5",
    },
    {
        signId = "s010",
        luaName = "DragonChallengeMainLayer",
        nodeName = "panel_area",
        size = "840|768",
        anchor = "0.5|0.5",
    },
    {
        signId = "s011",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_buff",
        size = "200|100",
        anchor = "0.5|0.5",
    }
}

-- 提示节点信息
DragonChallengeGuideData.tipInfos = {
    {
        tipId = "t001",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_guide1",
        type = "lua",
        path = "Activity_DragonChallenge.Activity.DragonChallengeGuide",
    },
    {
        tipId = "t002",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_guide2",
        type = "lua",
        path = "Activity_DragonChallenge.Activity.DragonChallengeGuide",
    },
    {
        tipId = "t003",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_guide3",
        type = "lua",
        path = "Activity_DragonChallenge.Activity.DragonChallengeGuide",
    },
    {
        tipId = "t004",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_area_1",
        type = "lua",
        path = "Activity_DragonChallenge.Activity.DragonChallengeGuideFingerNode"
    },
    {
        tipId = "t005",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_guide4",
        type = "lua",
        path = "Activity_DragonChallenge.Activity.DragonChallengeGuide",
    },
    {
        tipId = "t006",
        luaName = "DragonChallengeMainLayer",
        nodeName = "node_guide4",
        type = "lua",
        path = "Activity_DragonChallenge.Activity.DragonChallengeGuide",
    }
}

return DragonChallengeGuideData
