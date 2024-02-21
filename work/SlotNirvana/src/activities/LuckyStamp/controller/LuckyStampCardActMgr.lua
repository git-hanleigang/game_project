--[[
Author: cxc
Date: 2021-10-22 14:56:01
LastEditTime: 2021-10-21 16:34:07
LastEditors: your name
Description: luckyStemp送卡 活动
FilePath: /SlotNirvana/src/activities/LuckyStamp/controller/LuckyStampCardActMgr.lua
--]]
local LuckyStampCardActNet = require("activities.LuckyStamp.net.LuckyStampCardActNet")
local LuckyStampCardActMgr = class("LuckyStampCardActMgr", BaseActivityControl)

function LuckyStampCardActMgr:ctor()
    LuckyStampCardActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckyStampCard)
end

function LuckyStampCardActMgr:isActive()
    local data = self:getRunningData()
    if data then
        return data:isActive()
    end
    return false
end

function LuckyStampCardActMgr:showMainLayer(_callBack)
    if not self:isCanShowLayer() then
        return false
    end
    if gLobalViewManager:getViewByName("Activity_LuckyStampCard") ~= nil then
        return false
    end
    local view = util_createFindView("Activity/Activity_LuckyStampCard", {activityId = "LSC001", callBack = _callBack})
    view:setName("Activity_LuckyStampCard")
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function LuckyStampCardActMgr:collectCard()
    if not self:isActive() then
        return
    end

    -- local function successCallFun(resData)
    --     if resData.code == 1 then
    --         local result = util_cjsonDecode(resData.result)
    --         if result ~= nil then
    --             --self:setPlayData(result)
    --             --local data = self:getData()
    --             --if data then
    --             --    self:setRewards(result.items)
    --             --end
    --             gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PLAY_RESULT, {name = ACTIVITY_REF.LuckyStampCard, flag = true, data = result})
    --         else
    --             print("---------> LuckyStampCard活动获取卡牌消息返回异常 ")
    --             release_print(result)
    --             gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PLAY_RESULT, {name = ACTIVITY_REF.LuckyStampCard, flag = false, data = result})
    --         end
    --     else
    --         local errorMsg = "parse lucky stamp card play json error"
    --         print(errorMsg)
    --         release_print(errorMsg)
    --         gLobalViewManager:showReConnect()
    --     end
    -- end

    -- local function failedCallFun(target, errorCode, errorData)
    --     gLobalViewManager:showReConnect()
    -- end
    -- self:sendMsgBaseFunc(ActionType.LuckyStampCardReward, "luckyStampCard", nil, successCallFun, failedCallFun)

    LuckyStampCardActNet:getInstance():collectCard()
end

return LuckyStampCardActMgr
