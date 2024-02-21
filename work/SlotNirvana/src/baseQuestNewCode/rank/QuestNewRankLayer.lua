-- 感恩节quest排行榜主界面

local BaseRankUI = require("baseActivity.ActivityRank.BaseRankUI")
local QuestNewRankLayer = class("QuestNewRankLayer", BaseRankUI)

function QuestNewRankLayer:initUI()
    QuestNewRankLayer.super.initUI(self)
end

function QuestNewRankLayer:sendRankRequestAction()
    G_GetMgr(ACTIVITY_REF.QuestNew):requestQuestRank()
end

function QuestNewRankLayer:getRefName()
    return ACTIVITY_REF.QuestNew
end

function QuestNewRankLayer:getCsbName()
    return "QuestFantasyRes/rank/QuestRankLayer.csb"
end

function QuestNewRankLayer:getRankHelpPath()
    return "QuestFantasyRes/rank/QuestRuleView.csb"
end

function QuestNewRankLayer:getRankTitlePath()
    return "QuestFantasyRes/rank/QuestRankTitle.csb"
end

function QuestNewRankLayer:getRankTimerPath()
    return "QuestFantasyRes/rank/QuestRankTime.csb"
end

function QuestNewRankLayer:getUserCellPath()
    return "QuestFantasyRes/rank/QuestRankCell1.csb"
end

function QuestNewRankLayer:getRewardCellPath()
    return "QuestFantasyRes/rank/QuestRankCell2.csb"
end

function QuestNewRankLayer:getCoinMaxLen()
    return 8
end

return QuestNewRankLayer
