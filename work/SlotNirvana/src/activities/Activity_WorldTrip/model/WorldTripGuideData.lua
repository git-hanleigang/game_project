--[[
    time:2022-09-01 11:38:43
]]
local WorldTripGuideData = {}

-- 引导主题
WorldTripGuideData.guideTheme = ACTIVITY_REF.WorldTrip

-- 引导入口配置信息
WorldTripGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterWorldTripMain"},
    {id = 2, startStep = "1101", guideName = "enterWorldTripRecallMain"}
}
-- 步骤信息
WorldTripGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterWorldTripMain",
        nextStep = "1001",
        isCoerce = true,
        archiveStep = "",
        luaName = "WorldTripMainUI",
        signIds = "s1001",
        tipIds = "t1001"
    },
    {
        stepId = "1002",
        guideName = "enterWorldTripMain",
        nextStep = "1002",
        isCoerce = true
    },
    {
        stepId = "1101",
        guideName = "enterWorldTripRecallMain",
        nextStep = "1102",
        isCoerce = true,
        archiveStep = "",
        luaName = "WorldTripRecallMainUI",
        signIds = "s1101",
        tipIds = "t1101"
    },
    {
        stepId = "1102",
        guideName = "enterWorldTripRecallMain",
        nextStep = "1102",
        isCoerce = true
    }
}

-- 标记节点信息
WorldTripGuideData.signInfos = {
    {
        signId = "s1001",
        luaName = "WorldTripMainUI",
        nodeName = "node_dice",
        size = "200|200",
        anchor = "0.5|0.5",
        offset = "0|29"
    },
    {
        signId = "s1101",
        luaName = "WorldTripRecallMainUI",
        nodeName = "node_dice",
        size = "200|200",
        anchor = "0.5|0.5",
        offset = "0|29"
    }
}

-- 提示节点信息
WorldTripGuideData.tipInfos = {
    {
        tipId = "t1001",
        luaName = "WorldTripMainUI",
        nodeName = "node_guide",
        type = "csb",
        path = "Activity/WorldTrip/csd/guide/WorldTrip_guide_1.csb"
    },
    {
        tipId = "t1101",
        luaName = "WorldTripRecallMainUI",
        nodeName = "node_guide",
        type = "csb",
        path = "Activity/WorldTrip/csd/guide/WorldTrip_guide_2.csb"
    }
}
return WorldTripGuideData
