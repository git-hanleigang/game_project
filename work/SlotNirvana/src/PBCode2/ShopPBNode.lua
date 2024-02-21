--道具
local ShopPBNode = class("ShopPBNode", util_require("base.BaseView"))

function ShopPBNode:initUI(data)
    if not data then
        data = {}
    end
    local type = data.p_icon
    if not type then
        type = "Vip"
    end

    self.m_type = type

    local csbName = "PBRes/ItemUI/item_shop/Shop_" .. data.p_icon .. ".csb"
    self:createCsbNode(csbName)
    local msg1, msg2, isDouble
    if type == "Bingo" then
        local num = data.p_num
        msg1 = num
    elseif type == "BingoWild" then
        local num = data.p_num
        msg1 = num
    elseif type == "Card" then
        msg1 = "MIN " .. data.p_maxStarCards .. " OF"
        msg2 = data.p_cards
        for i = 1, 5 do
            local sp_star = self:findChild("sp_star" .. i)
            if sp_star then
                if i <= data.p_maxStar then
                    sp_star:setVisible(true)
                else
                    sp_star:setVisible(false)
                end
            end
        end
    elseif type == "CashBack" then
        --使用buff数据
        local buffData = data.p_buffInfo
        if buffData then
            msg1 = buffData.buffMultiple .. "%"
            msg2 = buffData.buffDuration .. " MINS"
        end
    elseif type == "DeluxeClub" then
        msg1 = "+" .. util_getFromatMoneyStr(data.p_num or 0)
    elseif type == "Help" then
        msg1 = data.p_num
    elseif type == "LuckyStamp" then
        -- msg1 = "+"..util_getFromatMoneyStr(data.p_num or 0)
    elseif type == "Vip" then
        msg1 = "+" .. util_getFromatMoneyStr(data.p_num or 0)
        self:updateVipSp()
    elseif type == "CardGem" then
        msg1 = data.p_num
    elseif type == "RichMan_Dice" then
        msg1 = data.p_num
    elseif type == "RichMan_DoubleDice" then
        msg1 = data.p_num
    elseif type == "RichMan_Rush" then
        msg1 = data.p_num
    elseif type == "Blast_GoldenPicks" or type == "Blast_Picks" then
        msg1 = data.p_num
    elseif type == "Word_Hit" or type == "Word_Picks" then
        msg1 = data.p_num
    elseif type == "Blast_PrizeBooster" or type == "Blast_CarnivalBooster" then
        local buffData = data.p_buffInfo
        msg1 = buffData.buffDuration .. " MINS"
    elseif type == "DinnerLand" then
        msg1 = data.p_num
    elseif type == "Coupon1" or type == "Coupon2" or type == "Coupon3" then
        msg1 = data.p_num .. "%"
    elseif type == "LuckChipsDraw" then
        msg1 = "X" .. data.p_num
    elseif string.find(type, "CatFood") then
        msg1 = data.p_num
    elseif type == "CoinPusher" then
        msg1 = data.p_num
    else
        --其他使用csb原始描述
    end
    self:updateUI(msg1, msg2, isDouble)
end

function ShopPBNode:updateVipSp()
    --显示现阶段Vip图标展示
    local vipLevel = globalData.userRunData.vipLevel
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if vipBoost and vipBoost:isOpenBoost() then
        local extraLevel = vipBoost:getBoostVipLevelIcon()
        if extraLevel > 0 then
            vipLevel = vipLevel + extraLevel
        end
    end

    local spVip = self:findChild("vip1_10")
    local path = VipConfig.logo_small .. vipLevel .. ".png"
    if path ~= "" and util_IsFileExist(path) then
        util_changeTexture(spVip, path)
    end
    -- spVip:setScale(0.23)
end

function ShopPBNode:updateUI(msg1, msg2, isDouble)
    if msg1 then
        local m_lb_msg1 = self:findChild("m_lb_msg1")
        if m_lb_msg1 then
            m_lb_msg1:setString(msg1)
        end
    end
    if msg2 then
        local m_lb_msg2 = self:findChild("m_lb_msg2")
        if m_lb_msg2 then
            m_lb_msg2:setString(msg2)
        end
    end

    --是否展示双倍
    local jiacheng = self:findChild("jiacheng")
    if jiacheng then
        if isDouble then
            jiacheng:setVisible(true)
        else
            jiacheng:setVisible(false)
        end
    end
end

function ShopPBNode:getPBType()
    return self.m_type
end

function ShopPBNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not tolua.isnull(self) then
                if self.m_type == "Vip" then
                    self:updateVipSp()
                end
            end
        end,
        ViewEventType.NOTIFY_UPDATE_VIP
    )
end

function ShopPBNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return ShopPBNode
