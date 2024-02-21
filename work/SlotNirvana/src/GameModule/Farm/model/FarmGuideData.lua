local FarmGuideData = {}

-- 引导主题
FarmGuideData.guideTheme = "Farm"

-- 引导入口配置信息
FarmGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "enterFarmMain"},
    {id = 2, startStep = "1101", guideName = "FarmLandGuide", preGuides = "enterFarmMain"},
    {id = 3, startStep = "4001", guideName = "enterFarmBarn", preGuides = "FarmLandGuide"},
    {id = 4, startStep = "2001", guideName = "enterFarmShop"},
    {id = 5, startStep = "3001", guideName = "enterFarmFriend"},
    {id = 6, startStep = "5001", guideName = "FaemStealGuide", preGuides = "enterFarmFriend"},
}
-- 步骤信息
FarmGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "enterFarmMain",
        nextStep = "1002",
        isCoerce = true,
        luaName = "Farm_MainLayer",
        signIds = "s001",
        tipIds = "1|t201"
    },
    {
        stepId = "1002",
        guideName = "enterFarmMain",
        nextStep = "1003",
        isCoerce = true,
        event = "Event_Farm_SetName",
        luaName = "Farm_InfoSetName",
        signIds = "s003",
        tipIds = "t202",
        opacity = 0
    },
    {
        stepId = "1101",
        guideName = "FarmLandGuide",
        nextStep = "1102",
        isCoerce = true,
        luaName = "Farm_MainLayer",
        event = "Event_Farm_Land_Click",
        signIds = "s005",
        tipIds = "2|t203"
    },
    {
        stepId = "1102",
        guideName = "FarmLandGuide",
        nextStep = "1103",
        isCoerce = true,
        event = "Event_Farm_Plant",
        luaName = "Farm_MainLayer",
        signIds = "s005|s006|s009",
        tipIds = "3"
    },
    {
        stepId = "1103",
        guideName = "FarmLandGuide",
        nextStep = "1104",
        isCoerce = true,
        event = "Event_Farm_Show_Tipbubble",
        luaName = "Farm_MainLayer",
        signIds = "s005|s009|s015",
        tipIds = "4|t203"
    },
    {
        stepId = "1104",
        guideName = "FarmLandGuide",
        nextStep = "1105",
        isCoerce = true,
        event = "Event_Farm_Quick_Growth",
        luaName = "Farm_MainLayer",
        signIds = "s007|s015",
        tipIds = "5|t204"
    },
    {
        stepId = "1105",
        guideName = "FarmLandGuide",
        nextStep = "1106",
        isCoerce = true,
        event = "Event_Farm_Land_Click",
        luaName = "Farm_MainLayer",
        signIds = "s005|s015",
        tipIds = "6|t203"
    },
    {
        stepId = "1106",
        guideName = "FarmLandGuide",
        nextStep = "1107",
        isCoerce = true,
        event = "Event_Farm_Harvest",
        luaName = "Farm_MainLayer",
        signIds = "s005|s008|s009",
        tipIds = "7"
    },
    {
        stepId = "1107",
        guideName = "FarmLandGuide",
        nextStep = "1108",
        isCoerce = true,
        event = "Event_Farm_Fly",
        luaName = "Farm_MainLayer",
        signIds = "s009",
        tipIds = "7"
    },
    {
        stepId = "1108",
        guideName = "FarmLandGuide",
        nextStep = "1109",
        isCoerce = true,
        luaName = "Farm_MainLayer",
        signIds = "s009|s010",
        tipIds = "8|t205"
    },
    {
        stepId = "4001",
        guideName = "enterFarmBarn",
        nextStep = "4002",
        isCoerce = true,
        luaName = "Farm_BarnLayer",
        signIds = "s011",
        tipIds = "9|t206",
    },
    {
        stepId = "4002",
        guideName = "enterFarmBarn",
        event = "Event_Farm_Sell_Crop",
        nextStep = "4003",
        isCoerce = true,
        luaName = "Farm_BarnLayer",
        signIds = "s017",
        tipIds = "10|t210",
    },
    {
        stepId = "2001",
        guideName = "enterFarmShop",
        nextStep = "2002",
        isCoerce = false,
        luaName = "Farm_ShopLayer",
        signIds = "",
        tipIds = "t101",
        opacity = 0
    },
    {
        stepId = "3001",
        guideName = "enterFarmFriend",
        nextStep = "3002",
        isCoerce = false,
        luaName = "Farm_FriendsLayer",
        signIds = "s012",
        tipIds = "11",
    },
    {
        stepId = "3002",
        guideName = "enterFarmFriend",
        nextStep = "3003",
        isCoerce = true,
        luaName = "Farm_FriendsLayer",
        signIds = "s013",
        tipIds = "t207",
    },
    {
        stepId = "5001",
        guideName = "FaemStealGuide",
        nextStep = "5002",
        isCoerce = true,
        luaName = "Farm_MainLayer",
        signIds = "s007",
        tipIds = "13|t208",
    },
    {
        stepId = "5002",
        guideName = "FaemStealGuide",
        nextStep = "5003",
        isCoerce = true,
        luaName = "Farm_MainLayer",
        signIds = "s009|s016",
        tipIds = "14|t209",
    },
}

-- 标记节点信息
FarmGuideData.signInfos = {
    {
        signId = "s001",
        luaName = "Farm_MainLayer",
        nodeName = "node_sign",
        size = "151|202",
        anchor = "0.5|0.5",
        offset = "1|44"
    },
    {
        signId = "s003",
        luaName = "Farm_InfoSetName",
        type = "clip|Activity_Farm/img/img_buy/Activity_Farm_Buy_bg2.png",
        nodeName = "sp_bg2",
        anchor = "0.5|0.5",
    },
    {
        signId = "s005",
        luaName = "Farm_MainLayer",
        size = "110|70",
        anchor = "0.5|0.5",
    },
    {
        signId = "s006",
        luaName = "Farm_MainLayer",
        nodeName = "node_bottom_tool",
        size = "80|74",
        anchor = "0.5|0.5",
        offset = "-190|35",
        zOrder = 1,
    },
    {
        signId = "s007",
        luaName = "Farm_MainLayer",
        offset = "0|115",
        size = "120|80",
        anchor = "0.5|0.5",
    },
    {
        signId = "s008",
        luaName = "Farm_MainLayer",
        nodeName = "node_bottom_tool",
        size = "180|95",
        anchor = "0.5|0.5",
        offset = "0|30",
        zOrder = 1,
    },
    {
        signId = "s009",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide",
        size = "0|0",
        anchor = "0.5|0.5",
        zOrder = 1,
    },
    {
        signId = "s010",
        luaName = "Farm_MainLayer",
        nodeName = "Node_1",
        size = "139|141",
        anchor = "0.5|0.5",
        offset = "0|90"
    },
    {
        signId = "s011",
        luaName = "Farm_BarnLayer",
        type = "clip|Activity_Farm/img/img_main/Activity_Farm_Main_friends_bg1.png",
        nodeName = "node_middle",
        anchor = "0.5|0.5",
        offset = "-305|142",
    },
    {
        signId = "s012",
        luaName = "Farm_FriendsLayer",
        nodeName = "node_middle",
        type = "clip|Default/Button_Disable.png",
        size = "1060|100",
        anchor = "0.5|0.5",
        offset = "0|175",
        isBlock = true
    },
    {
        signId = "s013",
        luaName = "Farm_FriendsLayer",
        nodeName = "node_middle",
        type = "clip|Default/Button_Disable.png",
        size = "286|411",
        anchor = "0.5|0.5",
        offset = "-372|-95",
    },
    {
        signId = "s015",
        luaName = "Farm_MainLayer",
        size = "0|0",
        anchor = "0.5|0.5",
    },
    {
        signId = "s016",
        luaName = "Farm_MainLayer",
        nodeName = "node_others_house",
        anchor = "0.5|0.5",
        size = "72|72"
    },
    {
        signId = "s017",
        luaName = "Farm_BarnLayer",
        nodeName = "node_sell",
        anchor = "0.5|0.5",
        size = "332|205",
        offset = "-305|-50"
    }
}

-- 提示节点信息
FarmGuideData.tipInfos = {
    {
        tipId = "t101",
        luaName = "Farm_ShopLayer",
        nodeName = "node_guide_10",
        type = "csb",
        path = "Activity_Farm/csd/Activity_Farm_Guide/Activity_Farm_Guide_10.csb"
    },
    {
        tipId = "1",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "2",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "3",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "4",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "5",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "6",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "7",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "8",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "9",
        luaName = "Farm_BarnLayer",
        nodeName = "node_guide_9",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "10",
        luaName = "Farm_BarnLayer",
        nodeName = "node_guide_10",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "11",
        luaName = "Farm_FriendsLayer",
        nodeName = "node_guide_11",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "12",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "13",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    }, 
    {
        tipId = "14",
        luaName = "Farm_MainLayer",
        nodeName = "node_guide_0",
        type = "lua",
        path = "Views/Farm_GuideNode"
    },
    {
        tipId = "t201",
        luaName = "Farm_MainLayer",
        nodeName = "node_sign",
        type = "lua",
        path = "Views/Farm_GuideFingerNode"
    },
    {
        tipId = "t202",
        luaName = "Farm_InfoSetName",
        nodeName = "node_btn1",
        type = "lua",
        path = "Views/Farm_GuideFingerNode"
    },
    {
        tipId = "t203",
        luaName = "Farm_MainLayer",
        type = "lua",
        path = "Views/Farm_GuideFingerNode"
    },
    {
        tipId = "t204",
        luaName = "Farm_MainLayer",
        type = "lua",
        path = "Views/Farm_GuideFingerNode"
    },
    {
        tipId = "t205",
        luaName = "Farm_MainLayer",
        nodeName = "Node_1",
        type = "lua",
        path = "Views/Farm_GuideFingerNode"
    },
    {
        tipId = "t206",
        luaName = "Farm_BarnLayer",
        nodeName = "node_middle",
        type = "lua",
        path = "Views/Farm_GuideFingerNode"
    },
    {
        tipId = "t207",
        luaName = "Farm_FriendsLayer",
        nodeName = "node_middle",
        type = "lua",
        path = "Views/Farm_GuideFingerNode"
    },
    {
        tipId = "t208",
        luaName = "Farm_MainLayer",
        type = "lua",
        path = "Views/Farm_GuideStealNode"
    },
    {
        tipId = "t209",
        luaName = "Farm_MainLayer",
        type = "lua",
        nodeName = "node_others_house",
        path = "Views/Farm_GuideFingerNode"
    }, 
    {
        tipId = "t210",
        luaName = "Farm_BarnLayer",
        nodeName = "node_sell",
        type = "lua",
        path = "Views/Farm_GuideFingerNode"
    }
}

return FarmGuideData
