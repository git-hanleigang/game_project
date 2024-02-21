--[[
    
]]

local EmailNotifyRewardNode = class("NotifyRewardUI", BaseView)

function EmailNotifyRewardNode:getCsbName()
    return "NotifyReward/EmailPopup/Csb/Node_reward.csb"
end

function EmailNotifyRewardNode:initCsbNodes()
    self.m_rewardNode = self:findChild("reward")
    self.m_lb_number  = self:findChild("Lb_number")
end

function EmailNotifyRewardNode:initDatas(_data)
    self.m_rewardData = _data
end

function EmailNotifyRewardNode:initUI()
    EmailNotifyRewardNode.super.initUI(self)

    local itemNode
    if type(self.m_rewardData) == "number" then 
        local info = gLobalItemManager:createLocalItemData("Coins", self.m_rewardData)
        itemNode = gLobalItemManager:createRewardNode(info, ITEM_SIZE_TYPE.REWARD)
    else
        local tempData = self.m_rewardData
        local info = gLobalItemManager:createLocalItemData(tempData.p_icon, tempData.p_num, tempData)
        itemNode = gLobalItemManager:createRewardNode(info, ITEM_SIZE_TYPE.REWARD)
    end
    if itemNode then
        self.m_rewardNode:addChild(itemNode)
    end
end

return EmailNotifyRewardNode
