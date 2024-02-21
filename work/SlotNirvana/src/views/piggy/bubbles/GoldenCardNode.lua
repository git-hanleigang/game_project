--[[
    送金卡
]]
local GoldenCardNode = class("GoldenCardNode", BaseView)

function GoldenCardNode:getCsbName()
    return "PigBank2022/csb/bubbles/node_RandomCards.csb"
end

function GoldenCardNode:initCsbNodes()
    self.m_cardNode = self:findChild("node_cards")
end

function GoldenCardNode:initUI()
    GoldenCardNode.super.initUI(self)
    self:initCards()
end

function GoldenCardNode:initCards()
    local pigGold = G_GetMgr(ACTIVITY_REF.PigGoldCard):getRunningData()
    if not (pigGold and pigGold:isRunning()) then
        return
    end
    -- 在这里处理显示卡或者道具
    local itemList = pigGold:getItems()
    if itemList and #itemList > 0 then
        -- 加载奖励
        local rewardUIList = {}
        for i = 1, #itemList do
            local data = itemList[i]
            data:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
            rewardUIList[#rewardUIList + 1] = data
        end
        local itemNode = gLobalItemManager:addPropNodeList(rewardUIList, ITEM_SIZE_TYPE.REWARD, 0.5)
        if itemNode then
            self.m_cardNode:addChild(itemNode)
        end
    end
end

return GoldenCardNode
