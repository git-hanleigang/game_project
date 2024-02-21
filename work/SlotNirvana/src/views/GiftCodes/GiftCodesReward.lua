--[[
    小游戏通用奖励弹板
]]

local ShopItem = util_require("data.baseDatas.ShopItem")
local GiftCodesReward = class("GiftCodesReward", BaseLayer)

function GiftCodesReward:ctor()
    GiftCodesReward.super.ctor(self)

    self:setLandscapeCsbName("Activity_GiftCodes/Activity/csb/Activity_GiftCodesRewards.csb")
    self:setExtendData("GiftCodesReward")
end

function GiftCodesReward:initDatas(_rewardInfo,_callback)
    self.m_rewardInfo = _rewardInfo
    self.m_coins = _rewardInfo.coins
    self.m_items = _rewardInfo.items
    self.m_callback = _callback
end

function GiftCodesReward:initCsbNodes()
    self.m_node_item = self:findChild("node_icon")
end

function GiftCodesReward:initView()
    local sp_coin = self:findChild("sp_coin")
    local lb_coin = self:findChild("lb_coins")
    if sp_coin and lb_coin then
        lb_coin:setString(util_formatCoins(self.m_coins, 9))
        local uiList = {
            {node = sp_coin},
            {node = lb_coin, alignX = 3}
        }
        util_alignCenter(uiList)
    end
    self:initReward()
    self:initAutoClose()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function GiftCodesReward:initAutoClose()
    local callback = function()
        if self.m_isC then
            return
        end
        self.m_isC = true
        self:collectF()
    end

    self:setAutoCloseUI(4, nil, callback)
end

function GiftCodesReward:initReward()
    local coins = self.m_rewardInfo.coins
    local items = self.m_rewardInfo.items
    local itemDataList = {}
    -- 通用道具
    if items and #items then 
        for k, v in ipairs(items) do
            local shopItem = ShopItem:create()
            shopItem:parseData(v, true)
            local tempData = gLobalItemManager:createLocalItemData(shopItem.p_icon, shopItem.p_num, shopItem)
            table.insert(itemDataList, tempData)
        end
    end
    if #itemDataList > 0 then
        local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD, 0.8)
        self.m_node_item:addChild(itemNode)
    end
end

function GiftCodesReward:clickFunc(sender)

    local senderName = sender:getName()
    if senderName == "btn_collect" then
        if self.m_isC then
            return
        end
        self.m_isC = true
        self:collectF()
    end
end

function GiftCodesReward:collectF()
    if self.m_coins and self.m_coins > 0 then
        local flyList = {}
        local btnCollect = self:findChild("btn_collect")
        local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
        local coins = self.m_coins
        if coins and coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = coins, startPos = startPos})
        end
        if G_GetMgr(G_REF.Currency) then 
            G_GetMgr(G_REF.Currency):playFlyCurrency(flyList, function()
                if not tolua.isnull(self) then 
                    self:dropCard()
                end
            end)
        end
    else
        self:dropCard()
    end
end

function GiftCodesReward:dropCard()
    if CardSysManager:needDropCards("Exchange Code") == true then
        CardSysManager:doDropCards("Exchange Code", function()
            if not tolua.isnull(self) then 
                self:closeUI()
            end
        end)
    else
        self:closeUI()
    end
end

function GiftCodesReward:closeUI()
    local callFunc = function()
        if self.m_callback then
            self.m_callback()
        end
    end
    GiftCodesReward.super.closeUI(self,callFunc)
end

function GiftCodesReward:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

return GiftCodesReward
