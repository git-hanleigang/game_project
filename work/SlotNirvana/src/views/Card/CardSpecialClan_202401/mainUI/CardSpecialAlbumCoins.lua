--[[
    特殊卡册标题
]]
local CardSpecialAlbumCoins = class("CardSpecialAlbumCoins", BaseView)

function CardSpecialAlbumCoins:initDatas()
end

function CardSpecialAlbumCoins:getCsbName()
    return "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/main/MagicAlbumCoins.csb"
end

function CardSpecialAlbumCoins:initCsbNodes()
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")

    self.m_lbPro = self:findChild("lb_pro")

    self.m_spTitle = self:findChild("sp_title")
    self.m_spTitleComplete = self:findChild("sp_title_set")
end

function CardSpecialAlbumCoins:initUI()
    CardSpecialAlbumCoins.super.initUI(self)
    self:initTitle()
    self:initCoins()
    self:initPro()
    self:playIdle()
end

function CardSpecialAlbumCoins:initTitle()
    local isCompleted = self:isAlbumCompleted()
    self.m_spTitle:setVisible(isCompleted == false)
    self.m_spTitleComplete:setVisible(isCompleted == true)
end

function CardSpecialAlbumCoins:initCoins()
    local coins = self:getCoins()
    self.m_lbCoin:setString(util_getFromatMoneyStr(coins))

    util_alignCenter(
        {
            {node = self.m_spCoin, scale = 0.62},
            {node = self.m_lbCoin, scale = 0.4}
        },
        nil,
        580
    )
end

function CardSpecialAlbumCoins:initPro()
    local cur, max = self:getPro()
    self.m_lbPro:setString(cur .. "/" .. max)
end

function CardSpecialAlbumCoins:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function CardSpecialAlbumCoins:getPro()
    local cur, max = 0, 0
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if data then
        cur = data:getTotalHaveCardNum() or 0
        max = data:getTotalCardNum() or 1
    end
    return cur, max
end

function CardSpecialAlbumCoins:getCoins()
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if data then
        return data:getMagicCoins() or 0
    end
    return 0
end

function CardSpecialAlbumCoins:isAlbumCompleted()
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if data then
        return data:isAlbumCompleted()
    end
    return false
end

return CardSpecialAlbumCoins
