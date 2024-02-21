--[[
Author: cxc
Date: 2022-01-11 11:50:44
LastEditTime: 2022-01-11 14:17:39
LastEditors: your name
Description: Lottery乐透 额外奖励活动 mgr
FilePath: /SlotNirvana/src/activities/Activity_Lottery_Jackpot/controller/LotteryJackpotActMgr.lua
--]]
local LotteryJackpotActMgr = class("LotteryJackpotActMgr", BaseActivityControl)
local LotteryJackpotNet = util_require("activities.Activity_Lottery_Jackpot.net.LotteryJackpotNet")
local LotteryJackpotConfig = util_require("activities.Activity_Lottery_Jackpot.config.LotteryJackpotConfig")

function LotteryJackpotActMgr:ctor()
    LotteryJackpotActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LotteryJackpot)
end

-- 获取活动期号
function LotteryJackpotActMgr:getActPeriod()
    local mgr = G_GetMgr(G_REF.Lottery)
    if not mgr then
        return ""
    end 

    local data = G_GetMgr(G_REF.Lottery):getData()
    if not data then
        return ""
    end

    return data:getEndDataStr()
end

-- 掉落 额外奖励 卡
function LotteryJackpotActMgr:triggerDropExtraReward(_extraRewardInfo)
    if not _extraRewardInfo then
        return false
    end

    if gLobalViewManager:getViewByExtendData("Activity_Lottery_Jackpot") then
        return false
    end
   
    local view = util_createFindView("Activity/Activity_Lottery_Jackpot", {preLotteryRewardData = _extraRewardInfo})
    if not view then
        return false
    end
    view:setOverFunc(function()
        --弹窗逻辑执行下一个事件
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return true
end

function LotteryJackpotActMgr:sendCollectReq()
    local successFunc = function()
        local mgr = G_GetMgr(G_REF.Lottery)
        if mgr then
            mgr:resetDropExtraReward()
        end
        gLobalNoticManager:postNotification(LotteryJackpotConfig.EVENT_NAME.RECIEVE_COLLECT_LOTTERY_EXTRA_REWARD)
    end
    LotteryJackpotNet:getInstance():sendCollectReq(successFunc)
end

return LotteryJackpotActMgr
