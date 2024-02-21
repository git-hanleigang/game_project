--[[
]]
local ShopBuckGuideData = {}

-- 引导入口配置信息
ShopBuckGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "Buck_CoinStore"},
    {id = 2, startStep = "2001", guideName = "Buck_BuckStore"},
}
-- 步骤信息
ShopBuckGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "Buck_CoinStore",
        nextStep = "1002",
        isCoerce = false,
        luaName = "ShopMainLayer",
        tipIds = "t001",
    },
    {
        stepId = "1002",
        guideName = "Buck_CoinStore",
        nextStep = "1003",
        isCoerce = false,
        archiveStep = "1003",
        luaName = "ShopMainLayer",
        signIds = "s002",
        tipIds = "t002",
    },
    {
        stepId = "1003",
        guideName = "Buck_CoinStore",
        nextStep = "1004",
        isCoerce = false,
        archiveStep = "1004",
        luaName = "ShopMainLayer",
        signIds = "s003",
        tipIds = "t003",
    },
    {
        stepId = "1004",
        guideName = "Buck_CoinStore",
        -- nextStep = "",
        isCoerce = true,
        archiveStep = "1005",
        luaName = "ShopMainLayer",
        signIds = "s004",
        tipIds = "t004",
    }, 
    {
        stepId = "2001",
        guideName = "Buck_BuckStore",
        nextStep = "2002",
        isCoerce = false,
        archiveStep = "2002",
        luaName = "ShopBuckMainLayer",
        signIds = "s2001",
        tipIds = "t2001",
    }, 
    {
        stepId = "2002",
        guideName = "Buck_BuckStore",
        -- nextStep = "",
        isCoerce = false,
        archiveStep = "2003",
        luaName = "ShopBuckMainLayer",
        signIds = "s2002",
        tipIds = "t2002",
    },             
}

-- 标记节点信息
ShopBuckGuideData.signInfos = {
    {
        signId = "s002",
        luaName = "ShopMainLayer",
        nodeName = "",
        offset = "0|0",
        size = "0|0",
        anchor = "0.5|0.5"
    },
    {
        signId = "s003",
        luaName = "ShopMainLayer",
        nodeName = "",
        size = "0|0",
        offset = "0|0",
        anchor = "0.5|0.5",
    },
    {
        signId = "s004",
        luaName = "ShopMainLayer",
        nodeName = "node_buck",
        size = "195|40",
        offset = "0|3",
        anchor = "0|0.5",
    },
    {
        signId = "s2001",
        luaName = "ShopBuckMainLayer",
        nodeName = "",
        size = "0|0",
        offset = "0|0",
        anchor = "0|0",
    },
    {
        signId = "s2002",
        luaName = "ShopBuckMainLayer",
        nodeName = "",
        size = "0|0",
        offset = "0|0",
        anchor = "0|0",
    },        
}

-- 提示节点信息
ShopBuckGuideData.tipInfos = {
    {
        tipId = "t001",
        luaName = "ShopMainLayer",
        nodeName = "node_middleGuide",
        type = "lua",
        pos = "0|0",
        path = "GameModule.ShopBuck.views.guide.BuckGuideTipNode1"
    },
    {
        tipId = "t002",
        luaName = "ShopMainLayer",
        nodeName = "",
        type = "lua",
        pos = "0|0",
        path = "GameModule.ShopBuck.views.guide.BuckGuideTipNode2"
    },
    {
        tipId = "t003",
        luaName = "ShopMainLayer",
        nodeName = "",
        type = "lua",
        pos = "0|0",
        path = "GameModule.ShopBuck.views.guide.BuckGuideTipNode3"
    },
    {
        tipId = "t004",
        luaName = "ShopMainLayer",
        nodeName = "node_buck",
        type = "lua",
        pos = "0|0",
        path = "GameModule.ShopBuck.views.guide.BuckGuideTipNode4"
    },
    {
        tipId = "t2001",
        luaName = "ShopBuckMainLayer",
        nodeName = "",
        type = "lua",
        pos = "685|384",
        path = "GameModule.ShopBuck.views.guide.BuckGuideTipNode5"
    },
    {
        tipId = "t2002",
        luaName = "ShopBuckMainLayer",
        nodeName = "",
        type = "lua",
        pos = "685|384",
        path = "GameModule.ShopBuck.views.guide.BuckGuideTipNode6"
    },        
}

return ShopBuckGuideData
