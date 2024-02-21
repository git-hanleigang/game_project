--[[
Author: cxc
Date: 2021-10-21 17:25:28
LastEditTime: 2021-10-21 17:25:28
LastEditors: Please set LastEditors
Description: LuckyStampCard 活动net
FilePath: SlotNirvana/src/activities/LuckyStamp/net/LuckyStampCardActNet.lua
--]]
local LuckyStampCardActNet = class("LuckyStampCardActNet", util_require("baseActivity.BaseActivityManager"))

function LuckyStampCardActNet:getInstance()
    if self.m_instance == nil then
        self.m_instance = LuckyStampCardActNet.new()
	end
	return self.m_instance
end

function LuckyStampCardActNet:collectCard()
    local function successCallFun(resData)
        if resData.code == 1 then
            local result = util_cjsonDecode(resData.result)
            if result ~= nil then
                --self:setPlayData(result)
                --local data = self:getData()
                --if data then
                --    self:setRewards(result.items)
                --end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PLAY_RESULT, {name = ACTIVITY_REF.LuckyStampCard, flag = true, data = result})
            else
                print("---------> LuckyStampCard活动获取卡牌消息返回异常 ")
                release_print(result)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_PLAY_RESULT, {name = ACTIVITY_REF.LuckyStampCard, flag = false, data = result})
            end
        else
            local errorMsg = "parse lucky stamp card play json error"
            print(errorMsg)
            release_print(errorMsg)
            gLobalViewManager:showReConnect()
        end
    end

    local function failedCallFun(target, errorCode, errorData)
        gLobalViewManager:showReConnect()
    end
    self:sendMsgBaseFunc(ActionType.LuckyStampCardReward, "luckyStampCard", nil, successCallFun, failedCallFun)
end

return LuckyStampCardActNet 