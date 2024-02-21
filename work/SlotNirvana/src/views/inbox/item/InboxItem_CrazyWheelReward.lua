--[[
    抽奖转盘
    没消耗掉的券 +  没领取的奖励
]]
local InboxItem_baseReward = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_CrazyWheelReward = class("InboxItem_CrazyWheelReward", InboxItem_baseReward)

function InboxItem_CrazyWheelReward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 如果有掉卡，在这里设置来源
function InboxItem_CrazyWheelReward:getCardSource()
    return {"Crazy Wheel"}
end

-- 描述说明
function InboxItem_CrazyWheelReward:getDescStr()
    return self.m_mailData.title or "Crazy Wheel reward"
end

function InboxItem_CrazyWheelReward:mergeSpecialItem(tempData)
    -- 以下三种情况，默认num=1
    -- 居中统一居中显示x角标
    -- cashback、促销优惠券、高倍场体验卡
    if string.find(tempData.p_icon, "CashBack") or string.find(tempData.p_icon, "club_pass_") or string.find(tempData.p_icon, "Coupon") then
        tempData.p_num = 1
        tempData:setTempData({p_mark = {ITEM_MARK_TYPE.MIDDLE_X}})                
    end   
end

return InboxItem_CrazyWheelReward
