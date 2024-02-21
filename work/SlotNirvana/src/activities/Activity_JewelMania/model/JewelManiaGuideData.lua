--[[
]]
local JewelManiaGuideData = {}

-- 引导主题
-- JewelManiaGuideData.guideTheme = "JewelMania"

-- 引导入口配置信息
JewelManiaGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterJewelMain"},
    {id = 2, startStep = "2001", guideName = "clickJewelChapter", preGuides = "enterJewelMain"},
    {id = 3, startStep = "3001", guideName = "enterJewelChapter"},
    {id = 4, startStep = "4001", guideName = "JewelChapterFigure", preGuides = "enterJewelChapter"},
}
-- 步骤信息
JewelManiaGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterJewelMain",
        nextStep = "1002",
        isCoerce = false,
        -- archiveStep = "1002",
        luaName = "JMMainLayer",
        tipIds = "t001",
        -- event = ViewEventType.NOTIFY_GUIDE_OVER
    },
    {
        stepId = "1002",
        guideName = "enterJewelMain",
        -- nextStep = "",
        isCoerce = false,
        archiveStep = "1003",
        luaName = "JMMainLayer",
        signIds = "s001",
        tipIds = "t002",
        -- event = ViewEventType.NOTIFY_JEWELMANIA_GUIDE_OVER
    },
    {
        stepId = "2001",
        guideName = "clickJewelChapter",
        -- nextStep = "",
        isCoerce = true,
        -- archiveStep = "2001",
        luaName = "JMMainLayer",
        signIds = "s002",
        tipIds = "t003",
        -- event = ViewEventType.NOTIFY_GUIDE_OVER
    }, 
    {
        stepId = "3001",
        guideName = "enterJewelChapter",
        -- nextStep = "3002",
        isCoerce = true,
        -- archiveStep = "3001",
        luaName = "JMCMainLayer",
        signIds = "s0031|s0032|s0033|s0034|s0035",
        tipIds = "t004",
        -- event = ViewEventType.NOTIFY_GUIDE_OVER
    },
    {
        stepId = "4001",
        guideName = "JewelChapterFigure",
        nextStep = "4002",
        isCoerce = false,
        -- archiveStep = "3002",
        luaName = "JMCMainLayer",
        signIds = "s004",
        tipIds = "t005",
        -- event = ViewEventType.NOTIFY_GUIDE_OVER
    },
    {
        stepId = "4002",
        guideName = "JewelChapterFigure",
        nextStep = "4003",
        isCoerce = false,
        -- archiveStep = "3003",
        luaName = "JMCMainLayer",
        signIds = "s005",
        tipIds = "t006",
        -- event = ViewEventType.NOTIFY_GUIDE_OVER
    }
}

-- 标记节点信息
JewelManiaGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "JMMainLayer",
        nodeName = "node_pay",
        offset = "0|0",
        size = "410|120",
        anchor = "0.5|0.5"
    },
    {
        signId = "s002",
        luaName = "JMMainLayer",
        nodeName = "",
        size = "400|350",
        offset = "0|48",
        anchor = "0.5|0.5",
        -- isBlock = true
    },
    {
        signId = "s0031",
        luaName = "JMCMainLayer",
        nodeName = "",
        size = "0|0",
        anchor = "0.5|0.5",
        -- type = "clip|Default/Button_Disable.png",
        -- isBlock = true
    },    
    {
        signId = "s0032",
        luaName = "JMCMainLayer",
        nodeName = "",
        size = "85|85",
        anchor = "0.5|0.5",
        -- type = "clip|Default/Button_Disable.png",
        -- isBlock = true
    },
    {
        signId = "s0033",
        luaName = "JMCMainLayer",
        nodeName = "",
        size = "85|85",
        anchor = "0.5|0.5",
        -- type = "clip|Default/Button_Disable.png",
        -- isBlock = true
    },
    {
        signId = "s0034",
        luaName = "JMCMainLayer",
        nodeName = "",
        size = "85|85",
        anchor = "0.5|0.5",
        -- type = "clip|Default/Button_Disable.png",
        -- isBlock = true
    },
    {
        signId = "s0035",
        luaName = "JMCMainLayer",
        nodeName = "",
        size = "0|0",
        anchor = "0.5|0.5",
        -- type = "clip|Default/Button_Disable.png",
        -- isBlock = true
    },         
    {
        signId = "s004",
        luaName = "JMCMainLayer",
        nodeName = "node_figure",
        size = "660|480",
        anchor = "0.5|0.5"
    },
    {
        signId = "s005",
        luaName = "JMCMainLayer",
        nodeName = "",
        size = "210|70",
        anchor = "0.5|0.5"
    }
}

-- 提示节点信息
JewelManiaGuideData.tipInfos = {
    {
        tipId = "t001",
        luaName = "JMMainLayer",
        nodeName = "", -- todo
        type = "lua",
        pos = "685|384",
        path = "Activity_JewelMania.Code.guide.JMGuideTipNode1"
    },
    {
        tipId = "t002",
        luaName = "JMMainLayer",
        nodeName = "", -- todo
        type = "lua",
        pos = "685|384",
        path = "Activity_JewelMania.Code.guide.JMGuideTipNode2"
    },
    {
        tipId = "t003",
        luaName = "JMMainLayer",
        nodeName = "", -- todo
        type = "lua",
        pos = "685|384",
        path = "Activity_JewelMania.Code.guide.JMGuideTipNode3"
    },
    {
        tipId = "t004",
        luaName = "JMCMainLayer",
        nodeName = "", -- todo
        type = "lua",
        pos = "685|384",
        path = "Activity_JewelMania.Code.guide.JMGuideTipNode4"
    },
    {
        tipId = "t005",
        luaName = "JMCMainLayer",
        nodeName = "", -- todo
        type = "lua",
        pos = "685|384",
        path = "Activity_JewelMania.Code.guide.JMGuideTipNode5"
    },
    {
        tipId = "t006",
        luaName = "JMCMainLayer",
        nodeName = "", -- todo
        type = "lua",
        pos = "685|384",
        path = "Activity_JewelMania.Code.guide.JMGuideTipNode6"
    }
}

return JewelManiaGuideData
