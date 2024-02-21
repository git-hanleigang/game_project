--[[
    集卡特殊章节
]]
local ObsidianCardData = require("GameModule.CardObsidian.model.ObsidianCardData")
local ObsidianCardYearsData = require("GameModule.CardObsidian.model.ObsidianCardYearsData")

require("GameModule.CardObsidian.config.ObsidianCardCfg")
local ObsidianCardMgr = class("ObsidianCardMgr", BaseGameControl)

function ObsidianCardMgr:ctor()
    ObsidianCardMgr.super.ctor(self)
    self:setRefName(G_REF.ObsidianCard)
end

function ObsidianCardMgr:checkDownloadObsidianCardIcon()
    -- 黑曜卡册
    globalCardsDLControl:startDownload("2091", "07")
end

function ObsidianCardMgr:getThemeName(_seasonId)
    -- if not self:getSeasonId() then
    --     return
    -- end

    local seasonId = _seasonId or self:getSeasonId()
    if not seasonId then
        return
    end
    local themeName = string.format("CardObsidian_%s", seasonId)
    return themeName
end

-- 资源是否下载完成
function ObsidianCardMgr:isDownloadRes(_seasonId)
    local themeName = self:getThemeName(_seasonId)

    if not self:checkRes(themeName) then
        return false
    end

    local isDownloaded = self:checkDownloaded(themeName)
    if not isDownloaded then
        return false
    end
    return true
end

function ObsidianCardMgr:setCurAlbumID(_albumId)
    self.m_currentAlbumId = _albumId
end

function ObsidianCardMgr:getCurAlbumID()
    return self.m_currentAlbumId
end

function ObsidianCardMgr:setSeasonId(_seasonId)
    self.m_seasonId = _seasonId
end

function ObsidianCardMgr:getSeasonId()
    return self.m_seasonId
end

function ObsidianCardMgr:parseData(_specialClanata)
    if not _specialClanata then
        return
    end
    self:setCardAlbumInfo(_specialClanata)
    self:setSeasonId(_specialClanata.season)
end

function ObsidianCardMgr:parseShortCardYears(_newdata)
    if not _newdata then
        return
    end
    if not self.m_shortYearsData then
        self.m_shortYearsData = ObsidianCardYearsData:create()
    end
    self.m_shortYearsData:parseData(_newdata)
end

function ObsidianCardMgr:getShortCardYears()
    return self.m_shortYearsData
end

function ObsidianCardMgr:setCardAlbumInfo(_newdata, _isHistory)
    if not _newdata then
        return
    end
    if not self.m_CardAlbumInfo then
        self.m_CardAlbumInfo = {}
    end
    if not self.m_CardAlbumInfo[tostring(_newdata.season)] then
        local _data = ObsidianCardData:create()
        self.m_CardAlbumInfo[tostring(_newdata.season)] = _data
    end
    self.m_CardAlbumInfo[tostring(_newdata.season)]:parseData(_newdata, _isHistory)
    -- return self.m_CardAlbumInfo[tostring(_newdata.season)]
end

function ObsidianCardMgr:getCardAlbumInfo(seasonId)
    if seasonId and seasonId ~= "" then
        return self.m_CardAlbumInfo[tostring(seasonId)]
    end
end

function ObsidianCardMgr:getSeasonData(_seasonId)
    local seasonId = _seasonId or self:getSeasonId()
    -- local seasonData = data:getCardAlbumInfo(seasonId)
    return self:getCardAlbumInfo(seasonId)
end

function ObsidianCardMgr:showMainLayer(_seasonId, _over)
    local callfunc = function()
        if _over then
            _over()
        end
    end
    local seasonId = _seasonId or self:getSeasonId()
    if not seasonId then
        callfunc()
        return
    end

    -- 判断资源是否下载
    if not self:isDownloadRes(seasonId) then
        callfunc()
        return false
    end

    if gLobalViewManager:getViewByName("ObsidianCardUI") ~= nil then
        callfunc()
        return
    end

    local path = string.format("views/Card/CardObsidian_%s/mainUI/ObsidianCardUI", seasonId)
    local view = util_createView(path, seasonId, callfunc)
    if view then
        view:setName("ObsidianCardUI")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function ObsidianCardMgr:showInfoLayer(_seasonId)
    local seasonId = _seasonId or self:getSeasonId()
    if not seasonId then
        return
    end
    if gLobalViewManager:getViewByName("ObsidianCardInfoUI") ~= nil then
        return
    end
    local path = string.format("views/Card/CardObsidian_%s/infoUI/ObsidianCardInfoUI", seasonId)
    local view = util_createFindView(path, seasonId)
    if view then
        view:setName("ObsidianCardInfoUI")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function ObsidianCardMgr:showRewardLayer(_rewardData, _callBack, _seasonId)
    local seasonId = _seasonId or self:getSeasonId()
    if not seasonId then
        return
    end
    -- 判断资源是否下载
    if not self:isDownloadRes(_seasonId) then
        return
    end
    if gLobalViewManager:getViewByName("ObsidianCardRewardUI") ~= nil then
        return
    end
    local path = string.format("views/Card/CardObsidian_%s/rewardUI/ObsidianCardRewardUI", seasonId)
    local view = util_createView(path, _rewardData, _callBack, seasonId)
    if view then
        view:setName("ObsidianCardRewardUI")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function ObsidianCardMgr:showJackpotRewardLayer(_coins, _percent, _callBack, _seasonId)
    _seasonId = _seasonId or self:getSeasonId()
    if not _seasonId then
        return
    end
    -- 判断资源是否下载
    if not self:isDownloadRes(_seasonId) then
        return
    end
    if gLobalViewManager:getViewByName("ObsidianCardJackpotRewardUI") ~= nil then
        return
    end
    local path = string.format("views/Card/CardObsidian_%s/rewardUI/ObsidianCardJackpotRewardUI", _seasonId)
    local view = util_createFindView(path, _coins, _percent, _callBack, _seasonId)
    if view then
        view:setName("ObsidianCardJackpotRewardUI")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- function ObsidianCardMgr:createObsidianEntryNode(_seasonId)
--     -- 判断资源是否下载
--     if not self:isDownloadRes() then
--         return
--     end
--     local seasonId = _seasonId or self:getSeasonId()
--     if not seasonId then
--         return
--     end
--     local luaPath = string.format("views/Card/CardObsidian_%s/entryNode/CardSeasonBottomEntryNode", seasonId)
--     local entryNode = util_createView(luaPath)
--     return entryNode
-- end

-- 注册需要隐藏的界面
function ObsidianCardMgr:registerNeedHideLayer(key, view)
    self.m_cardAlbumViews = self.m_cardAlbumViews or {}

    if not self.m_cardAlbumViews[tostring(key)] then
        self.m_cardAlbumViews[tostring(key)] = view
    end
end

-- 释放需要隐藏的界面
function ObsidianCardMgr:releaseNeedHideLayer(key)
    if not self.m_cardAlbumViews then
        return
    end

    if self.m_cardAlbumViews[tostring(key)] then
        self.m_cardAlbumViews[tostring(key)] = nil
    end
end

-- 显示需要隐藏的界面 --
function ObsidianCardMgr:showNeedHideLayer(key)
    if not self.m_cardAlbumViews then
        return
    end
    if self.m_cardAlbumViews[tostring(key)] then
        self.m_cardAlbumViews[tostring(key)]:setVisible(true)
    end
end

function ObsidianCardMgr:hideNeedHideLayer(key)
    if not self.m_cardAlbumViews then
        return
    end
    if self.m_cardAlbumViews[tostring(key)] then
        self.m_cardAlbumViews[tostring(key)]:setVisible(false)
    end
end

-- 显示 黑耀wild 卡兑换界面
function ObsidianCardMgr:showWildExchangeMainUI(_cb, _sourceType, _cancelCB)
    _cancelCB = _cancelCB or function() end
    local seasonId = self:getSeasonId()
    if not seasonId then
        _cancelCB()
        return
    end

    local view = util_createView("GameModule.Card.commonViews.CardWildExchangeObsidian.CardObsidianWildExcView", seasonId, _sourceType, _cb, _cancelCB)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 黑耀 wild卡兑换二次确认弹板
function ObsidianCardMgr:showWildExchangeConfirmUI(_cardData, _confirmCB)
    local view = util_createView("GameModule.Card.commonViews.CardWildExchangeObsidian.CardObsidianWildExcConfirmLayer", _cardData, _confirmCB)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end
function ObsidianCardMgr:checkCloseExcConfirmUI()
    local view = gLobalViewManager:getViewByName("CardObsidianWildExcConfirmLayer")
    if not view then
        return
    end
    
    view:closeUI()
end

-- 黑耀 wild卡 关闭 二次确认弹板
function ObsidianCardMgr:showWildExcCloseConfirmUI(_expire, _confirmCB)
    local view = util_createView("GameModule.Card.commonViews.CardWildExchangeObsidian.CardObsidianWildExcCloseLayer", _expire, _confirmCB)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 黑耀卡 wild 掉落逻辑
function ObsidianCardMgr:doDropWildLogic(_cb, _sourceType, _cancelCB)
    _cancelCB = _cancelCB or function() end
    local seasonId = self:getSeasonId()
    if not seasonId then
        _cancelCB()
        return
    end

    if not self:isDownloadRes(seasonId) then
        _cancelCB()
        return
    end

    if not self:checkCurSeasonOpen() then
        _cancelCB()
        return
    end

    local wildExgMgr = CardSysManager:getWildExcMgr()
    gLobalViewManager:addLoadingAnima()
    local successCB = function()
        gLobalViewManager:removeLoadingAnima()
        local view
        if wildExgMgr:canExchangeObsidianWildCard() then
            view = self:showWildExchangeMainUI(_cb, _sourceType, _cancelCB)
        end
        if not view then
            _cancelCB()
        end
    end
    local failedCB = function()
        gLobalViewManager:removeLoadingAnima()
        _cancelCB()        
    end
    wildExgMgr:sendExchangeRequest(CardSysConfigs.CardType.wild_obsidian, successCB, failedCB)
end 

-- 检查 黑耀卡当前赛季是否开启中
function ObsidianCardMgr:checkCurSeasonOpen()
    local obsidianYearsData = self:getShortCardYears()
    if not obsidianYearsData then
        return false
    end
    local albumId = self:getCurAlbumID()
    local expireSec = obsidianYearsData:getExpireAt(albumId)
    if expireSec <= 0 then
        return false
    end

    local curTimeSec = util_getCurrnetTime() 
    return expireSec > curTimeSec
end

-- 检查 是否有可兑换的 黑耀wild 卡
function ObsidianCardMgr:hadWildCardData()
    local seasonId = self:getSeasonId()
    if not seasonId then
        return false
    end
    if not self:isDownloadRes(seasonId) then
        return false
    end

    if not self:checkCurSeasonOpen() then
        return false
    end

    local obsidainCardYearData = self:getShortCardYears()
    if not obsidainCardYearData then
        return false
    end

    local yearDataList = obsidainCardYearData:getYearsData()
    if not yearDataList or #yearDataList <= 0 then
        return false
    end

    for i, yearData in ipairs(yearDataList) do
        
        local bHadCanUse, wildType = yearData:checkHadCanUseWildCardData()
        if bHadCanUse then
            return bHadCanUse, wildType
        end

    end
    
    return false
end

return ObsidianCardMgr
