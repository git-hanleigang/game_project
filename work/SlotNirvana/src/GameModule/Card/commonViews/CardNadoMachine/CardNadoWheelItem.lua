local ITEM_TYPE = {
    ITEM = "ITEM",
    BIG_COINS = "BIG_COINS",
    COINS = "COINS",
    PACKAGE = "PACKAGE",
    GOLD_PACKAGE = "GOLD_PACKAGE",
    VIP_POINTS = "VIP_POINTS",
    HIGH_LIMIT_POINTS = "HIGH_LIMIT_POINTS"
}
local CardNadoWheelItem = class("CardNadoWheelItem", BaseView)
function CardNadoWheelItem:initUI(index)
    self.m_index = index
    CardNadoWheelItem.super.initUI(self)

    self:runCsbAction("idle", true, nil, 30)
    self:initView()
end

function CardNadoWheelItem:getCsbName()
    return string.format(CardResConfig.commonRes.CardNadoWheelItemRes, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardNadoWheelItem:initCsbNodes()
    self.m_particle = self:findChild("Particle_1")
    self.m_itemNode = self:findChild("Node_item")
    self.m_spSuper = self:findChild("sp_super")
    self.m_spGoldenChip = self:findChild("sp_golden_chip")
    self.m_spFortuneChip = self:findChild("sp_fortune_chip")
    self.m_spCatFoot1 = self:findChild("sp_catfood1")
    self.m_spCatFoot2 = self:findChild("sp_catfood2")
    self.m_spCatFoot3 = self:findChild("sp_catfood3")
    self.m_lb_num = self:findChild("lb_num")

    self.m_coinsNode = self:findChild("Node_coins")
    self.m_spDexule = self:findChild("sp_dexule")
    self.m_spCoins = self:findChild("sp_coins")
    self.m_spVip = self:findChild("sp_vip")
    self.m_lb_coins = self:findChild("lb_coins")
    self.m_nodeStatueBuff = self:findChild("diaosu_buff")
end

function CardNadoWheelItem:hideParticle()
    self.m_particle:setVisible(false)
end

function CardNadoWheelItem:playScaleAction(overFunc)
    local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    local cellData = linkGameData.cells[self.m_index]
    if cellData.type == ITEM_TYPE.BIG_COINS then
        self:runCsbAction(
            "scale",
            false,
            function()
                self:runCsbAction("idle", true, nil, 30)
                if overFunc then
                    overFunc()
                end
            end,
            30
        )
    else
        util_performWithDelay(
            self,
            function()
                if overFunc then
                    overFunc()
                end
            end,
            20 / 30
        )
    end
end

function CardNadoWheelItem:initView()
    self.m_itemNode:setVisible(false)
    self.m_coinsNode:setVisible(false)

    self.m_spSuper:setVisible(false)
    self.m_spGoldenChip:setVisible(false)
    self.m_spFortuneChip:setVisible(false)

    if self.m_spCatFoot1 then
        self.m_spCatFoot1:setVisible(false)
    end
    if self.m_spCatFoot2 then
        self.m_spCatFoot2:setVisible(false)
    end
    if self.m_spCatFoot3 then
        self.m_spCatFoot3:setVisible(false)
    end
    if self.m_lb_num then
        self.m_lb_num:setVisible(false)
    end

    self.m_spDexule:setVisible(false)
    self.m_spCoins:setVisible(false)
    self.m_spVip:setVisible(false)
    self.m_lb_coins:setVisible(false)

    local customItemNode = self.m_itemNode:getChildByName("customItem")
    if customItemNode then
        customItemNode:removeFromParent()
        customItemNode = nil
    end

    local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    local cellData = linkGameData.cells[self.m_index]
    if cellData.type == ITEM_TYPE.BIG_COINS then
        self.m_itemNode:setVisible(true)
        self.m_spSuper:setVisible(true)
    elseif cellData.type == ITEM_TYPE.COINS then
        self.m_coinsNode:setVisible(true)
        self.m_spCoins:setVisible(true)
        self.m_lb_coins:setVisible(true)
        local value = tonumber(cellData.value)
        self.m_lb_coins:setString(util_formatCoins(value, 4))
        -- 神像buff
        self:initStatueBuffNode()
    elseif cellData.type == ITEM_TYPE.PACKAGE then
        self.m_itemNode:setVisible(true)
        self.m_spFortuneChip:setVisible(true)
    elseif cellData.type == ITEM_TYPE.GOLD_PACKAGE then
        self.m_itemNode:setVisible(true)
        self.m_spGoldenChip:setVisible(true)
    elseif cellData.type == ITEM_TYPE.VIP_POINTS then
        self.m_coinsNode:setVisible(true)
        self.m_spVip:setVisible(true)
        self.m_lb_coins:setVisible(true)
        local value = tonumber(cellData.value)
        self.m_lb_coins:setString(util_formatCoins(value, 4))
        -- 神像buff
        self:initStatueBuffNode()
    elseif cellData.type == ITEM_TYPE.HIGH_LIMIT_POINTS then
        self.m_coinsNode:setVisible(true)
        self.m_spDexule:setVisible(true)
        self.m_lb_coins:setVisible(true)
        local value = tonumber(cellData.value)
        self.m_lb_coins:setString(util_formatCoins(value, 4))
        -- 神像buff
        self:initStatueBuffNode()
    elseif cellData.type == ITEM_TYPE.ITEM then
        if cellData.reward then
            self.m_itemNode:setVisible(true)
            if cellData.reward.p_icon == "CatFood_1" then
                if self.m_spCatFoot1 then
                    self.m_spCatFoot1:setVisible(true)
                    self.m_lb_num:setVisible(true)
                    self.m_lb_num:setString(util_formatCoins(tonumber(cellData.reward.p_num), 4))
                end
            elseif cellData.reward.p_icon == "CatFood_2" then
                if self.m_spCatFoot2 then
                    self.m_spCatFoot2:setVisible(true)
                    self.m_lb_num:setVisible(true)
                    self.m_lb_num:setString(util_formatCoins(tonumber(cellData.reward.p_num), 4))
                end
            elseif cellData.reward.p_icon == "CatFood_3" then
                if self.m_spCatFoot3 then
                    self.m_spCatFoot3:setVisible(true)
                    self.m_lb_num:setVisible(true)
                    self.m_lb_num:setString(util_formatCoins(tonumber(cellData.reward.p_num), 4))
                end
            else
                -- 通用道具
                local customItemNode = gLobalItemManager:createRewardNode(cellData.reward, ITEM_SIZE_TYPE.REWARD)
                self.m_itemNode:addChild(customItemNode)
                customItemNode:setName("customItem")
                customItemNode:setIconTouchEnabled(false)
            end
        end
    end
end

function CardNadoWheelItem:setItemTouchEnabled(_enabled)
    local customItemNode = self.m_itemNode:getChildByName("customItem")
    if customItemNode then
        customItemNode:setIconTouchEnabled(_enabled)
    end
end

--[[-- 神像buff标签 -----------------]]
function CardNadoWheelItem:initStatueBuffNode()
    -- local buffMultiple = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_NADO_REWARD_BONUS)
    -- if buffMultiple and buffMultiple > 0 then
    --     if not self.m_statueBuffUI then
    --         local albumId = CardSysRuntimeMgr:getSelAlbumID() or CardSysRuntimeMgr:getCurAlbumID()
    --         local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
    --         if _logic then
    --             self.m_statueBuffUI = _logic:createCardSpecialGameBuffNode(buffMultiple)
    --             self.m_nodeStatueBuff:addChild(self.m_statueBuffUI)
    --         end
    --     end
    -- end
end

return CardNadoWheelItem
