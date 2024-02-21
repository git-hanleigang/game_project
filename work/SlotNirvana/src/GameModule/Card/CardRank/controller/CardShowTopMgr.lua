-- 集卡 排行榜管理器

local CardRankNet = require("GameModule.Card.CardRank.net.CardRankNet")
local CardShowTopMgr = class("CardShowTopMgr", BaseGameControl)

function CardShowTopMgr:ctor()
    CardShowTopMgr.super.ctor(self)
    self:setRefName(G_REF.CardRank)
    self.m_CardStoreNet = CardRankNet:getInstance()
end

function CardShowTopMgr:getThemeName(_albumId)
    _albumId = _albumId or CardSysRuntimeMgr:getSelAlbumID() or CardSysRuntimeMgr:getCurAlbumID()
    return "CardRank" .. _albumId
end

function CardShowTopMgr:getEntryIcon()
    local rank_data = self:getData()

    if not rank_data:hasData() then
        return
    end

    local left_time = rank_data:getLeftTime()
    if not left_time or left_time <= 0 then
        return
    end
    local rankIcon = util_createView("views.Card." .. self:getThemeName() .. ".CardRankItem")
    if not tolua.isnull(rankIcon) then
        return rankIcon
    end
end

function CardShowTopMgr:showMainLayer()
    local rank_data = self:getData()
    if not rank_data:hasData() then
        return
    end
    local rankUI = nil
    if gLobalViewManager:getViewByExtendData("CardRankUI") == nil then
        -- gLobalNoticManager:postNotification(ViewEventType.RANK_BTN_CLICKED, {name = G_REF.CardRank})
        rankUI = util_createView("views.Card." .. self:getThemeName() .. ".CardRankUI")
        if not tolua.isnull(rankUI) then
            gLobalViewManager:showUI(rankUI, ViewZorder.ZORDER_POPUI)
        end
    end
    return rankUI
end

-- 获得数据
function CardShowTopMgr:getData()
    if not self.p_rankData then
        local CardShowTopData = require("GameModule.Card.CardRank.model.CardShowTopData")
        if CardShowTopData then
            self.p_rankData = CardShowTopData:create()
        end
    end
    return self.p_rankData
end

-- 解析数据
function CardShowTopMgr:parseData(data)
    local rank_data = self:getRunningData()
    if rank_data then
        rank_data:parseData(data)
    end
end

function CardShowTopMgr:sendActionRank(info_type, callFunc)
    self.m_CardStoreNet:sendActionRank(info_type, callFunc)
end

return CardShowTopMgr
