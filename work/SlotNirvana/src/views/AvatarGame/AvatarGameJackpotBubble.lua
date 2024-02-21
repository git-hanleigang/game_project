--[[
    
]]

local AvatarGameJackpotBubble = class("AvatarGameJackpotBubble", BaseView)

function AvatarGameJackpotBubble:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_jackpot_qipao.csb"
end

function AvatarGameJackpotBubble:initCsbNodes()
    self.m_node_reward = self:findChild("node_reward")
    self.m_sp_bg = self:findChild("img_qiPao1")
end

function AvatarGameJackpotBubble:updateUI()
    local gameData = globalData.avatarFrameData:getMiniGameData()
    local cellList = gameData:getCellList()
    for i,v in ipairs(cellList) do
        if v:isBigReward() then 
            self:updateItem(v:getCoins(), v:getRewardList())
            break
        end
    end
end

function AvatarGameJackpotBubble:updateItem(_coin, _items)
    self.m_node_reward:removeAllChildren()
    local rewardInfo = {}
    if _coin and _coin > 0 then 
        local data = gLobalItemManager:createLocalItemData("Coins", _coin)
        data:setTempData({p_limit = 3})
        table.insert(rewardInfo, data)
    end

    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local data = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            table.insert(rewardInfo, data)
        end
    end
    
    if #rewardInfo > 0 then 
        local size = self.m_sp_bg:getContentSize()
        self.m_sp_bg:setContentSize(cc.size(70 * #rewardInfo + 20, size.height))
        local itemNode = gLobalItemManager:addPropNodeList(rewardInfo, ITEM_SIZE_TYPE.TOP)
        self.m_node_reward:addChild(itemNode)
    end
    
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function AvatarGameJackpotBubble:playStart(_callback)
    self:runCsbAction("start", false, function ()
        if _callback then 
            _callback()
        end        
    end, 60)
end

function AvatarGameJackpotBubble:playOver(_callback)
    self:runCsbAction("over", false, function ()
        if _callback then 
            _callback()
        end
    end, 60)
end

return AvatarGameJackpotBubble