--[[
    time:2022-09-01 11:38:43
]]
local EgyptCoinPusherGuideData = {}

-- 引导主题
EgyptCoinPusherGuideData.guideTheme = ACTIVITY_REF.EgyptCoinPusher

-- 引导入口配置信息
EgyptCoinPusherGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterSelectLayer"},
    {id = 2, startStep = "2001", guideName = "enterMainLayer"},
}
-- 步骤信息
EgyptCoinPusherGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterSelectLayer",
        nextStep = "1002",
        archiveStep = "",
        luaName = "EgyptCoinPusherSelectUI",
        signIds = "s001",
        tipIds = "1"
    },
    {
        stepId = "2001",
        guideName = "enterMainLayer",
        nextStep = "2002",
        archiveStep = "",
        luaName = "EgyptCoinPusherMainUI",
        signIds = "s002",
        tipIds = "2"
    },
    {
        stepId = "2002",
        guideName = "enterMainLayer",
        nextStep = "2003",
        archiveStep = "",
        luaName = "EgyptCoinPusherMainUI",
        signIds = "s003",
        tipIds = "3"
    }
}

-- 标记节点信息
EgyptCoinPusherGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "EgyptCoinPusherSelectUI",
        nodeName = "node_guide",
    },
    {
        signId = "s002",
        luaName = "EgyptCoinPusherMainUI",
        nodeName = "node_mid",
        type = "clip|Activity/CoinPusher_Egypt/other/guideShape.png",
        size = "500|300",
        anchor = "0.5|0.5",
        offset = "0|350",
        isBlock = false
    },
    {
        signId = "s003",
        luaName = "EgyptCoinPusherMainUI",
        nodeName = "node_mid",
        type = "clip|Activity/CoinPusher_Egypt/other/guideShape.png",
        size = "320|260",
        anchor = "0.5|0.5",
        offset = "0|60",
        isBlock = false
    }
}

-- 提示节点信息
EgyptCoinPusherGuideData.tipInfos = {
    {
        tipId = "1",
        luaName = "EgyptCoinPusherSelectUI",
        nodeName = "nodeGuide",
        type = "lua",
        path = "Activity.EgyptCoinPusherGame.EgyptCoinPusherGuideView"
    },
    {
        tipId = "2",
        luaName = "EgyptCoinPusherMainUI",
        nodeName = "nodeGuide",
        type = "lua",
        path = "Activity.EgyptCoinPusherGame.EgyptCoinPusherGuideView"
    },
    {
        tipId = "3",
        luaName = "EgyptCoinPusherMainUI",
        nodeName = "nodeGuide",
        type = "lua",
        path = "Activity.EgyptCoinPusherGame.EgyptCoinPusherGuideView"
    }
}

return EgyptCoinPusherGuideData
