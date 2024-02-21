
local ActivityTaskEntry_coinPusher = class("ActivityTaskEntry_coinPusher", util_require("views.Activity_MissionNew.ActivityTaskEntryBase"))

function ActivityTaskEntry_coinPusher:initUI()
    ActivityTaskEntry_coinPusher.super.initUI(self)
end

function ActivityTaskEntry_coinPusher:getCsbName()
    return "Activity/Activity_MissionNew/csd/COIN_COINPUSHER_MissionEntryNode.csb"
end

function ActivityTaskEntry_coinPusher:getActivityName()
    return ACTIVITY_REF.CoinPusherTaskNew
end

function ActivityTaskEntry_coinPusher:openTaskView()
    G_GetMgr(ACTIVITY_REF.CoinPusherTaskNew):showMainLayer()
end

return ActivityTaskEntry_coinPusher
