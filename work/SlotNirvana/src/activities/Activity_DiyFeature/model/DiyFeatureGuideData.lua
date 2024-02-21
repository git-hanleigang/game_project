--[[
    time:2022-09-01 11:38:43
]]
local DiyFeatureGuideData = {}

-- 引导主题
DiyFeatureGuideData.guideTheme = "Activity_DiyFeatureConnect"

-- 引导入口配置信息
DiyFeatureGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterDiyFeatureGame_1", preGuides = ""},
    {id = 2, startStep = "2001", guideName = "enterDiyFeatureGame_2", preGuides = ""},
    {id = 3, startStep = "3001", guideName = "enterDiyFeatureGame_3", preGuides = ""},
    {id = 4, startStep = "4001", guideName = "enterDiyFeatureGame_4", preGuides = ""},
}
-- 步骤信息
DiyFeatureGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterDiyFeatureGame_1",
        nextStep = "1002",
        isCoerce = false,
        opacity = 0,
        archiveStep = "",
        luaName = "DiyFeatureMainLayer",
        signIds = "s001",
        tipIds = "t001|t002"
    },
    {
        stepId = "2001",
        guideName = "enterDiyFeatureGame_2",
        nextStep = "2002",
        isCoerce = false,
        opacity = 0,
        archiveStep = "",
        luaName = "DiyFeatureMainLayer",
        signIds = "s001",
        tipIds = "t003|t004"
    },
    {
        stepId = "3001",
        guideName = "enterDiyFeatureGame_3",
        nextStep = "3002",
        isCoerce = false,
        opacity = 0,
        archiveStep = "",
        luaName = "DiyFeatureMainLayer",
        signIds = "s001",
        tipIds = "t005|t006"
    },
    {
        stepId = "4001",
        guideName = "enterDiyFeatureGame_4",
        nextStep = "4002",
        isCoerce = false,
        opacity = 0,
        archiveStep = "",
        luaName = "DiyFeatureMainLayer",
        signIds = "s001",
        tipIds = "t007|t008"
    }
}

-- 标记节点信息
DiyFeatureGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "DiyFeatureMainLayer",
        nodeName = "node_guide",
        anchor = "0.5|0.5",
    }
}

-- 提示节点信息
DiyFeatureGuideData.tipInfos = {
    {
        tipId = "t001",
        luaName = "DiyFeatureMainLayer",
        nodeName = "node_guide",
        type = "csb",
        path = "Activity_DiyFeature/csd/guide/DiyFeature_Guide1.csb"
    },
    {
        tipId = "t002",
        luaName = "DiyFeatureMainLayer",
        nodeName = "node_guide",
        zOrder = 1,
        type = "lua",
        path = "Activity_DiyFeatureCode.Guide.DiyFeatureGuideFingerNode"
    },
    {
        tipId = "t003",
        luaName = "DiyFeatureMainLayer",
        nodeName = "node_guide",
        zOrder = 1,
        type = "csb",
        path = "Activity_DiyFeature/csd/guide/DiyFeature_Guide4.csb"
    },
    {
        tipId = "t004",
        luaName = "DiyFeatureMainLayer",
        nodeName = "node_guide",
        zOrder = 1,
        type = "csb",
        path = "Activity_DiyFeature/csd/guide/DiyFeature_GuideNpc4.csb"
    },
    {
        tipId = "t005",
        luaName = "DiyFeatureMainLayer", 
        nodeName = "node_guide",
        zOrder = 1,
        type = "csb",
        path = "Activity_DiyFeature/csd/guide/DiyFeature_Guide2.csb"
    },
    {
        tipId = "t006",
        luaName = "DiyFeatureMainLayer",
        nodeName = "node_guide",
        zOrder = 1,
        type = "csb",
        path = "Activity_DiyFeature/csd/guide/DiyFeature_GuideNpc2.csb"
    },
    {
        tipId = "t007",
        luaName = "DiyFeatureMainLayer", 
        nodeName = "node_guide",
        zOrder = 1,
        type = "csb",
        path = "Activity_DiyFeature/csd/guide/DiyFeature_Guide3.csb"
    },
    {
        tipId = "t008",
        luaName = "DiyFeatureMainLayer",
        nodeName = "node_guide",
        zOrder = 1,
        type = "csb",
        path = "Activity_DiyFeature/csd/guide/DiyFeature_GuideNpc3.csb"
    }
}

return DiyFeatureGuideData
