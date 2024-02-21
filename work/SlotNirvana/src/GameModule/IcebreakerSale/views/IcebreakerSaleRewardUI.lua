--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-27 17:43:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-27 17:43:26
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/views/IcebreakerSaleRewardUI.lua
Description: 新版 破冰促销 奖励UI
--]]
local IcebreakerSaleRewardUI = class("IcebreakerSaleRewardUI", BaseView)

function IcebreakerSaleRewardUI:initDatas(_rewardData)
    IcebreakerSaleRewardUI.super.initDatas(self)

    self.m_rewardData = _rewardData
end

function IcebreakerSaleRewardUI:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "Activity/csd/IcebreakerSale_Reward_Portrait.csb"
    end
    return "Activity/csd/IcebreakerSale_Reward.csb"
end

function IcebreakerSaleRewardUI:initUI()
    IcebreakerSaleRewardUI.super.initUI(self)
    
    if globalData.slotRunData.isPortrait then
        -- 金币
        self:initCoinsLbUI()
    end
    -- 道具
    self:initItemListUI()
end

-- 金币
function IcebreakerSaleRewardUI:initCoinsLbUI()
    local lbCoins = self:findChild("lb_coins")
    local coins = self.m_rewardData:getCoins()
    lbCoins:setString(util_formatCoins(coins, 6).. "+")

    local uiList = {
        {node = self:findChild("sp_coins")},
        {node = lbCoins, alignX = 5}
    }
    util_alignCenter(uiList)
end

-- 道具
function IcebreakerSaleRewardUI:initItemListUI()
    local bNoCoins = globalData.slotRunData.isPortrait
    local itemList = self.m_rewardData:getItemList()
    if bNoCoins then
        itemList = self.m_rewardData:getItemNoCoinsList()
    end

    -- 道具列表
    local nodeReward = self:findChild("node_item") -- cur奖励
    nodeReward:removeAllChildren()
    local uiList = {}
    for i=1, #itemList do
        local itemData = itemList[i]
        local shopItemUI = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.TOP)
        local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP) or 70
        table.insert(uiList, {node = shopItemUI, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)})
        nodeReward:addChild(shopItemUI)
        if i ~= #itemList then
            local nodeAdd = self:createAddUI()
            table.insert(uiList, {node = nodeAdd, size = cc.size(25, 50), anchor = cc.p(0.5, 0.5)})
            nodeReward:addChild(nodeAdd)
        end
    end
    util_alignCenter(uiList)
end

function IcebreakerSaleRewardUI:createAddUI()
    local view = util_createAnimation("Activity/csd/IcebreakerSale_Reward_Add.csb")
    return view
end

return IcebreakerSaleRewardUI