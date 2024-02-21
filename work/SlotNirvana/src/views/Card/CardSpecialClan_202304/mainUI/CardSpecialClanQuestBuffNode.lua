--[[
    特殊卡册 Quest Title Buff
]]
local CardSpecialClanQuestBuffNode = class("CardSpecialClanQuestBuffNode", BaseView)

function CardSpecialClanQuestBuffNode:getCsbName()
    return "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/main/MagicQuestBuff.csb"
end

function CardSpecialClanQuestBuffNode:initCsbNodes()
    self.m_lb_number = self:findChild("lb_number")
end

function CardSpecialClanQuestBuffNode:initUI()
    CardSpecialClanQuestBuffNode.super.initUI(self)
    self:runCsbAction("idle", true)
end

function CardSpecialClanQuestBuffNode:updateBuffMultiple(_nMuti)
    if _nMuti and _nMuti > 0 then
        self.m_lb_number:setString(_nMuti .. "%")
    end
end

function CardSpecialClanQuestBuffNode:updateBuff()
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if albumID and CardSysRuntimeMgr:isPastAlbum(albumID) then
        return
    end
    local buffInfo = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
    if buffInfo then
        self:setVisible(true)
        local nMuti = tonumber(buffInfo.buffMultiple)
        self:updateBuffMultiple(nMuti)
    else
        self:setVisible(false)
    end
end

function CardSpecialClanQuestBuffNode:onEnter()
    CardSpecialClanQuestBuffNode.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateBuff()
        end,
        ViewEventType.NOTIFY_MULEXP_END
    )
    -- 新赛季开启清除buff刷新ui
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateBuff()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )    
end

return CardSpecialClanQuestBuffNode
