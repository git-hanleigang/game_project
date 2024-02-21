--[[
    time:2022-09-01 11:38:43
]]
local HolidayChallengeGuideData = {}

-- 引导入口配置信息
HolidayChallengeGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterMainLayer"},
}

-- 步骤信息
HolidayChallengeGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterMainLayer",
        nextStep = "1002",
        archiveStep = "",
        luaName = "Activity_HolidayNewChallenge",
        signIds = "s001",
        tipIds = "1"
    },
    {
        stepId = "1002",
        guideName = "enterMainLayer",
        nextStep = "1003",
        archiveStep = "",
        luaName = "Activity_HolidayNewChallenge",
        signIds = "s002",
        tipIds = "2"
    },
    {
        stepId = "1003",
        guideName = "enterMainLayer",
        nextStep = "1004",
        archiveStep = "",
        luaName = "Activity_HolidayNewChallenge",
        signIds = "s003",
        tipIds = "3"
    },
    {
        stepId = "1004",
        guideName = "enterMainLayer",
        nextStep = "1005",
        archiveStep = "",
        luaName = "Activity_HolidayNewChallenge",
        signIds = "s004",
        tipIds = "4"
    }
}

-- 标记节点信息
HolidayChallengeGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "Activity_HolidayNewChallenge",
        nodeName = "node_sign_guide",
    },
    {
        signId = "s002",
        luaName = "Activity_HolidayNewChallenge",
        nodeName = "node_game_guide",
    },
    {
        signId = "s003",
        luaName = "Activity_HolidayNewChallenge",
        nodeName = "node_progress_guide",
    },
    {
        signId = "s004",
        luaName = "Activity_HolidayNewChallenge",
        nodeName = "node_store_guide",
    }
}

-- 提示节点信息
HolidayChallengeGuideData.tipInfos = {
    {
        tipId = "1",
        luaName = "Activity_HolidayNewChallenge",
        nodeName = "node_sign_guide",
        type = "lua",
        path = "Activity_HolidayNewChallenge/HolidayNewChallengeGudieNode"
    },
    {
        tipId = "2",
        luaName = "Activity_HolidayNewChallenge",
        nodeName = "node_game_guide",
        type = "lua",
        path = "Activity_HolidayNewChallenge/HolidayNewChallengeGudieNode"
    },
    {
        tipId = "3",
        luaName = "Activity_HolidayNewChallenge",
        nodeName = "node_progress_guide",
        type = "lua",
        path = "Activity_HolidayNewChallenge/HolidayNewChallengeGudieNode"
    },
    {
        tipId = "4",
        luaName = "Activity_HolidayNewChallenge",
        nodeName = "node_store_guide",
        type = "lua",
        path = "Activity_HolidayNewChallenge/HolidayNewChallengeGudieNode"
    }
}

return HolidayChallengeGuideData
