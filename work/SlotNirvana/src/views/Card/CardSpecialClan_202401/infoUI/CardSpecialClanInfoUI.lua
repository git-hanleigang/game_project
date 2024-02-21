--[[
    特殊卡册 说明
]]
local CardSpecialClanInfoUI = class("CardSpecialClanInfoUI", BaseLayer)

function CardSpecialClanInfoUI:initDatas()
    -- self.m_curPageIndex = 1
    self:setLandscapeCsbName("CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/info/MagicAlbum_Rules.csb")
end

function CardSpecialClanInfoUI:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")

    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")    

    -- self.m_btnLeft = self:findChild("btn_left")
    -- self.m_btnRight = self:findChild("btn_right")

    -- self.m_nodePages = {}
    -- for i = 1, math.huge do
    --     local pageNode = self:findChild("node_rules_" .. i)
    --     if not pageNode then
    --         break
    --     end
    --     table.insert(self.m_nodePages, pageNode)
    -- end
    -- self.m_pageCount = #self.m_nodePages
end

function CardSpecialClanInfoUI:initView()
    -- self:updatePageNode()
    self:initCoins()
end

-- function CardSpecialClanInfoUI:updatePageNode()
--     -- self.m_btnLeft:setVisible(self.m_curPageIndex > 1)
--     -- self.m_btnRight:setVisible(self.m_curPageIndex < self.m_pageCount)
--     -- for i = 1, #self.m_nodePages do
--     --     self.m_nodePages[i]:setVisible(i == self.m_curPageIndex)
--     -- end
-- end

function CardSpecialClanInfoUI:initCoins()
    local coins = self:getCoins()
    self.m_lbCoin:setString(util_getFromatMoneyStr(coins))

    util_alignCenter({
        {node = self.m_spCoin, scale = 0.35},
        {node = self.m_lbCoin, scale = 0.22, alignX = 5},
    }, nil, 240)
end

function CardSpecialClanInfoUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    -- elseif name == "btn_left" then
    --     if self.m_curPageIndex == 1 then
    --         return
    --     end
    --     gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    --     self.m_curPageIndex = self.m_curPageIndex - 1
    --     self:updatePageNode()
    -- elseif name == "btn_right" then
    --     if self.m_curPageIndex == self.m_pageCount then
    --         return
    --     end
    --     gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    --     self.m_curPageIndex = self.m_curPageIndex + 1
    --     self:updatePageNode()
    end
end

function CardSpecialClanInfoUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CardSpecialClanInfoUI:getCoins()
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if data then
        return data:getMagicCoins() or 0
    end
    return 0
end

return CardSpecialClanInfoUI
