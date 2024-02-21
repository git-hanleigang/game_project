--[[
    荣誉
]]

local SidekicksRankReward = class("SidekicksRankReward", BaseLayer)

function SidekicksRankReward:initDatas(_seasonIdx, _data)
    self.m_seasonIdx = _seasonIdx
    self.m_data = _data
    self.m_gems = 0

    self:setLandscapeCsbName(string.format("Sidekicks_%s/csd/reward/Sidekicks_Reward_RankSale.csb", _seasonIdx))
    self:setExtendData("SidekicksRankReward")
end

function SidekicksRankReward:initCsbNodes()
    self.m_sp_icon_coin = self:findChild("sp_icon_coin")
    self.m_lb_coins = self:findChild("lb_coins")
    self.m_node_item = self:findChild("node_item")
end

function SidekicksRankReward:initView()
    local coins = self.m_data:getCoins()
    local items = self.m_data:getItemList()
    
    -- 金币道具
    if coins > toLongNumber(0) then
        self.m_lb_coins:setString(util_formatCoins(coins, 12))
        local uiList = {
            {node = self.m_sp_icon_coin},
            {node = self.m_lb_coins, alignX = 3}
        }
        util_alignCenter(uiList)
    end

    -- 通用道具
    if #items > 0 then
        local uiList = {}
        for i, v in ipairs(items) do
            local itemData = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD)
            self.m_node_item:addChild(itemNode)
            
            local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
            local anchor = cc.p(0.5, 0.5)
            table.insert(uiList, {node = itemNode, size = cc.size(width,width), anchor = anchor})

            -- 钻石
            if v.p_icon == "Gem" then
                self.m_gems = self.m_gems + v.p_num
            end
        end
        util_alignCenter(uiList)
    end
end

function SidekicksRankReward:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function SidekicksRankReward:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_collect" then
        local coins = self.m_data:getCoins()
        local flyList = {}
        local btnCollect = self:findChild("btn_collect")
        local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
        if coins > toLongNumber(0) then
            table.insert(flyList, { cuyType = FlyType.Coin, addValue = coins, startPos = startPos })
        end

        if self.m_gems > 0 then
            table.insert(flyList, { cuyType = FlyType.Gem, addValue = self.m_gems, startPos = startPos })
        end

        G_GetMgr(G_REF.Currency):playFlyCurrency(flyList, function()
            if not tolua.isnull(self) then
                self:closeUI(function ()
                    gLobalViewManager:checkBuyTipList()
                end)
            else
                gLobalViewManager:checkBuyTipList()
            end
        end)
    end
end

return SidekicksRankReward