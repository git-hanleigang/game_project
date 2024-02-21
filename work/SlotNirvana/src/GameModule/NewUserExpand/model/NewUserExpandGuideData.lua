--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-22 10:55:00
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-22 10:55:17
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/NewUserExpandGuideData.lua
Description: 扩圈 引导数据
--]]
local NewUserExpandGuideData = {}

-- 引导主题
NewUserExpandGuideData.guideTheme = G_REF.NewUserExpand
NewUserExpandGuideData.miniGameMainUILuaName =  G_GetMgr(G_REF.NewUserExpand):getMiniGameMainUILuaName()

-- 引导入口配置信息
NewUserExpandGuideData.stepCfg = {
    {id = 1, startStep = "1001", guideName = "EnterExpandMainFirst"},
    {id = 2, startStep = "1002", guideName = "FirstPlayExpandGame"},
    {id = 3, startStep = "1003", guideName = "EnterExpandMainPlayPass1"},
    {id = 4, startStep = "1004", guideName = "EnterExpandMainPlayPass2"},
    {id = 5, startStep = "1005", guideName = "EnterExpandMainPlayPass3"},
    {id = 6, startStep = "1006", guideName = "EnterExpandMainMissionUnlock"},
    {id = 7, startStep = "1007", guideName = "ExpandEntryClickGuide"},
    {id = 8, startStep = "1008", guideName = "EnterExpandMainPlayEntryTag"},
}
-- 步骤信息
NewUserExpandGuideData.stepInfos = {
    {
        stepId = "1001",
        guideName = "EnterExpandMainFirst",
        isCoerce = true,
        archiveStep = "",
        luaName = "NewUserExpandMainUI",
    },
    {
        stepId = "1002",
        guideName = "FirstPlayExpandGame",
        luaName = NewUserExpandGuideData.miniGameMainUILuaName,
        isCoerce = true,
        signIds = "s001",
        tipIds = "t001",
        opacity = 0
    },
    {
        stepId = "1003",
        guideName = "EnterExpandMainPlayPass1",
        luaName = "NewUserExpandMapUI",
        isCoerce = true,
        signIds = "s003",
        tipIds = "t003"
    },
    {
        stepId = "1004",
        guideName = "EnterExpandMainPlayPass2",
        luaName = "NewUserExpandMapUI",
        isCoerce = true,
        signIds = "s004",
        tipIds = "t004"
    },
    {
        stepId = "1005",
        guideName = "EnterExpandMainPlayPass3",
        luaName = "NewUserExpandMapUI",
        isCoerce = true,
        signIds = "s005",
        tipIds = "t005"
    },
    {
        stepId = "1006",
        guideName = "EnterExpandMainMissionUnlock",
        luaName = "NewUserExpandMapUI",
        isCoerce = false,
        signIds = "s006",
        tipIds = "t006"
    },
    {
        stepId = "1007",
        guideName = "ExpandEntryClickGuide",
        luaName = "NewUserExpandEntry",
        isCoerce = false,
        tipIds = "t007",
        opacity = 0
    },
    {
        stepId = "1008",
        guideName = "EnterExpandMainPlayEntryTag",
        luaName = "NewUserExpandEntry",
        isCoerce = false,
        signIds = "s008",
        tipIds = "t008"
    },
}

-- 标记节点信息
NewUserExpandGuideData.signInfos = {
    {
        signId = "s001",
        luaName = NewUserExpandGuideData.miniGameMainUILuaName,
        nodeName = "node_start",
        size = "450|310",
        anchor = "0.5|0.5",
        zOrder = 1,
        isBlock = false
    },
    {
        signId = "s003",
        luaName = "NewUserExpandMapUI",
        nodeName = "node_game_1",
        size = "140|140",
        anchor = "0.5|0.5",
        zOrder = 1,
        isBlock = false
    },
    {
        signId = "s004",
        luaName = "NewUserExpandMapUI",
        nodeName = "node_game_2",
        size = "140|140",
        anchor = "0.5|0.5",
        zOrder = 1,
        isBlock = false
    },
    {
        signId = "s005",
        luaName = "NewUserExpandMapUI",
        nodeName = "node_game_3",
        size = "140|140",
        anchor = "0.5|0.5",
        zOrder = 1,
        isBlock = false
    },
    {
        signId = "s006",
        luaName = "NewUserExpandMapUI",
        nodeName = "node_stop_1",
        size = "260|260",
        anchor = "0.5|0.5",
        zOrder = 1,
        isBlock = false
    },
    {
        signId = "s008",
        luaName = "NewUserExpandEntry",
        nodeName = "Node_Entry",
        size = "80|230",
        anchor = "0.5|0.5",
        zOrder = 1,
        isBlock = false
    },
}

-- 提示节点信息
NewUserExpandGuideData.tipInfos = {
    {
        tipId = "t001",
        luaName = NewUserExpandGuideData.miniGameMainUILuaName,
        nodeName = "node_start",
        type = "lua",
        path = "GameModule.NewUserExpand.views.NewUserExpandGuideFinger"
    },
    {
        tipId = "t003",
        luaName = "NewUserExpandMapUI",
        nodeName = "node_game_1",
        type = "lua",
        path = "GameModule.NewUserExpand.views.NewUserExpandGuideView"
    },
    {
        tipId = "t004",
        luaName = "NewUserExpandMapUI",
        nodeName = "node_game_2",
        type = "lua",
        path = "GameModule.NewUserExpand.views.NewUserExpandGuideView"
    },
    {
        tipId = "t005",
        luaName = "NewUserExpandMapUI",
        nodeName = "node_game_3",
        type = "lua",
        path = "GameModule.NewUserExpand.views.NewUserExpandGuideView"
    },
    {
        tipId = "t006",
        luaName = "NewUserExpandMapUI",
        nodeName = "node_stop_1",
        type = "lua",
        path = "GameModule.NewUserExpand.views.NewUserExpandGuideView"
    },
    {
        tipId = "t007",
        luaName = "NewUserExpandEntry",
        nodeName = "btn_puzzle",
        type = "lua",
        path = "GameModule.NewUserExpand.views.NewUserExpandGuideFinger"
    },
    {
        tipId = "t008",
        luaName = "NewUserExpandEntry",
        nodeName = "Node_Entry",
        type = "lua",
        path = "GameModule.NewUserExpand.views.NewUserExpandGuideView"
    },
}

-- "1.点击小游戏按钮 2.页签提示点击 3.点击游戏入口 4.引导查看解锁规则（完成路障引导时打） 5.了解返回Slot界面规则（点击进入到老虎机界面打）"
NewUserExpandGuideData.guide_log_info = {
    FirstPlayExpandGame = {guideId = "1002", guideType = 1, guideName = "FirstPlayExpandGame", bCoerce = true},
    ExpandEntryClickGuide = {guideId = "1007", guideType = 2, guideName = "ExpandEntryClickGuide", bCoerce = false},

    EnterExpandMainPlayPass1 = {guideId = "1003", guideType = 3, passIdx = 1, guideName = "EnterExpandMainPlayPass1", bCoerce = true},
    EnterExpandMainPlayPass2 = {guideId = "1004", guideType = 3, passIdx = 2, guideName = "EnterExpandMainPlayPass2", bCoerce = true},
    EnterExpandMainPlayPass3 = {guideId = "1005", guideType = 3, passIdx = 3, guideName = "EnterExpandMainPlayPass3", bCoerce = true},
    EnterExpandMainFirst = {guideId = "1001", guideType = 3, passIdx = 1, guideName = "EnterExpandMainFirst", bCoerce = true},

    EnterExpandMainMissionUnlock = {guideId = "1006", guideType = 4, guideName = "EnterExpandMainMissionUnlock", bCoerce = false},
    EnterExpandMainPlayEntryTag = {guideId = "1008", guideType = 5, guideName = "EnterExpandMainPlayEntryTag", bCoerce = false},
}


return NewUserExpandGuideData
