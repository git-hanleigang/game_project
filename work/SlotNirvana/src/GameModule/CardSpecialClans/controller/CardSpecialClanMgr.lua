--[[
    集卡特殊章节
]]
local CardSpecialClanDatas = require("GameModule.CardSpecialClans.model.CardSpecialClanDatas")
require("GameModule.CardSpecialClans.config.CardSpecialClanCfg")
local CardSpecialClanMgr = class("CardSpecialClanMgr", BaseGameControl)

function CardSpecialClanMgr:ctor()
    CardSpecialClanMgr.super.ctor(self)
    self:setRefName(G_REF.CardSpecialClan)
end

function CardSpecialClanMgr:getThemeName(_albumId)
    _albumId = _albumId or CardSysRuntimeMgr:getSelAlbumID() or CardSysRuntimeMgr:getCurAlbumID()
    return "CardSpecialClan_" .. _albumId
end

function CardSpecialClanMgr:parseData(_clanata, _magicCoins)
    if not _clanata then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = CardSpecialClanDatas:create()
        _data:parseData(_clanata, _magicCoins)
        self:registerData(_data)
    else
        _data:parseData(_clanata, _magicCoins)
    end
end

function CardSpecialClanMgr:addExitCallFunc(_over)
    if not self.m_exitOver then
        self.m_exitOver = {}
    end
    table.insert(self.m_exitOver, _over)
end

function CardSpecialClanMgr:exitSpecialClan()
    if self.m_exitOver and #self.m_exitOver > 0 then
        for i = #self.m_exitOver, 1, -1 do
            if self.m_exitOver[i] then
                self.m_exitOver[i]()
                self.m_exitOver[i] = nil
            end
        end
    end
end

function CardSpecialClanMgr:showMainLayer(_isOpenCardLobby, _over)
    local function callFunc()
        if _over then
            _over()
        end
    end
    if not self:isCanShowLayer() then
        callFunc()
        return
    end
    if gLobalViewManager:getViewByName("CardSpecialAlbumUI") ~= nil then
        callFunc()
        return
    end

    self:addExitCallFunc(_over)

    local themeName = self:getThemeName()
    local view = util_createView("views.Card." .. themeName .. ".mainUI.CardSpecialAlbumUI", _isOpenCardLobby)
    view:setName("CardSpecialAlbumUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CardSpecialClanMgr:showClanLayer(_index)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("CardSpecialClanUI") ~= nil then
        return
    end
    local view = util_createView("views.Card." .. self:getThemeName() .. ".mainUI.CardSpecialClanUI", _index)
    view:setName("CardSpecialClanUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CardSpecialClanMgr:showInfoLayer()
    if gLobalViewManager:getViewByName("CardSpecialClanInfoUI") ~= nil then
        return
    end
    local view = util_createView("views.Card." .. self:getThemeName() .. ".infoUI.CardSpecialClanInfoUI")
    view:setName("CardSpecialClanInfoUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CardSpecialClanMgr:showRewardLayer(_rewardData, _callBack)
    if not self:isCanShowLayer() then
        if _callBack then
            _callBack()
        end
        return
    end
    if gLobalViewManager:getViewByName("CardSpecialClanRewardUI") ~= nil then
        if _callBack then
            _callBack()
        end
        return
    end
    local view = util_createView("views.Card." .. self:getThemeName() .. ".rewardUI.CardSpecialClanRewardUI", _rewardData, _callBack)
    view:setName("CardSpecialClanRewardUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CardSpecialClanMgr:showAlbumRewardLayer(_rewardData, _callBack)
    if not self:isCanShowLayer() then
        if _callBack then
            _callBack()
        end
        return
    end
    if gLobalViewManager:getViewByName("CardSpecialAlbumRewardUI") ~= nil then
        if _callBack then
            _callBack()
        end
        return
    end
    local view = util_createView("views.Card." .. self:getThemeName() .. ".rewardUI.CardSpecialAlbumRewardUI", _rewardData, _callBack)
    view:setName("CardSpecialAlbumRewardUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- ========================================== Magic卡 wild ========================================== --
-- 显示 Magic wild 卡兑换界面
function CardSpecialClanMgr:showWildExchangeMainUI(_cb, _sourceType, _cancelCB, _wildType)
    _cancelCB = _cancelCB or function() end

    local view = util_createView("GameModule.Card.commonViews.CardWildExchangeMagic.CardMagicWildExcView", _wildType, _sourceType, _cb, _cancelCB)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- Magic wild卡兑换二次确认弹板
function CardSpecialClanMgr:showWildExchangeConfirmUI(_cardData, _confirmCB)
    local view = util_createView("GameModule.Card.commonViews.CardWildExchangeMagic.CardMagicWildExcConfirmLayer", _cardData, _confirmCB)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function CardSpecialClanMgr:checkCloseExcConfirmUI()
    local view = gLobalViewManager:getViewByName("CardMagicWildExcConfirmLayer")
    if not view then
        return
    end
    
    view:closeUI()
end

-- Magic wild卡 关闭 二次确认弹板
function CardSpecialClanMgr:showWildExcCloseConfirmUI(_expire, _confirmCB)
    local view = util_createView("GameModule.Card.commonViews.CardWildExchangeMagic.CardMagicWildExcCloseLayer", _expire, _confirmCB)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- Magic wild 掉落逻辑
function CardSpecialClanMgr:doDropWildLogic(_wildType, _cb, _sourceType, _cancelCB)
    _cancelCB = _cancelCB or function() end
    if not self:isDownloadRes() then
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
        if wildExgMgr:canExchangeWildCard() then
            view = self:showWildExchangeMainUI(_cb, _sourceType, _cancelCB, _wildType)
        end
        if not view then
            _cancelCB()
        end
    end
    local failedCB = function()
        gLobalViewManager:removeLoadingAnima()
        _cancelCB()        
    end
    wildExgMgr:sendExchangeRequest(_wildType, successCB, failedCB)
end 

-- 检查 Magic卡当前赛季是否开启中
function CardSpecialClanMgr:checkCurSeasonOpen()
    local albumId = CardSysRuntimeMgr:getSelAlbumID() or CardSysRuntimeMgr:getCurAlbumID()
    if tonumber(albumId) < CardSpecialClanCfg.minSeasonId then
        return false
    end

    local expireAt = CardSysManager:getSeasonExpireAt()
    if expireAt <= 0 then
        return false
    end

    local curTimeSec = util_getCurrnetTime() 
    return expireAt > curTimeSec
end

-- quest大厅 特殊卡册入口
function CardSpecialClanMgr:createSpecialClanEntry()
    if not self:isDownloadRes() then
        return
    end
    local isCurSeasonOpen = self:checkCurSeasonOpen()
    if not isCurSeasonOpen then
        return
    end
    local entryPath = "views.Card." .. self:getThemeName() .. ".mainUI.CardSpecialClanQuestEntry"
    return util_createView(entryPath)
end

-- quest大厅 特殊卡册buff节点
function CardSpecialClanMgr:createSpecialClanBuffNode()
    if not self:isDownloadRes() then
        return
    end
    local isCurSeasonOpen = self:checkCurSeasonOpen()
    if not isCurSeasonOpen then
        return
    end
    local entryPath = "views.Card." .. self:getThemeName() .. ".mainUI.CardSpecialClanQuestBuffNode"
    return util_createView(entryPath)
end

return CardSpecialClanMgr
