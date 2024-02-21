-- 卡牌商店 玩法介绍界面

local CardStoreMainHelpItem = class("CardStoreMainHelpItem", BaseView)

function CardStoreMainHelpItem:initDatas(_index)
    self.m_index = _index
end

function CardStoreMainHelpItem:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    if self.m_index == 1 then
        return p_config.InfoItem1
    elseif self.m_index == 2 then
        return p_config.InfoItem2
    end
end

function CardStoreMainHelpItem:initUI()
    CardStoreMainHelpItem.super.initUI(self)
    
    if self.m_index == 1 then
        local spMythic = self:findChild("sp_info_3_mythic")
        local spMagic = self:findChild("sp_info_3")
        if spMythic and spMagic then
            local curAlbumId = CardSysRuntimeMgr:getCurAlbumID()
            if curAlbumId ~= nil and tonumber(curAlbumId) >= 202303 then
                spMythic:setVisible(true)
                spMagic:setVisible(false)
            else
                spMythic:setVisible(false)
                spMagic:setVisible(true)
            end
        end
    end
end

return CardStoreMainHelpItem
