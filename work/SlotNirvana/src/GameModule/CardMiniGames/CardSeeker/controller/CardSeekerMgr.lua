--[[
    集卡神庙探险小游戏
]]
require("GameModule.CardMiniGames.CardSeeker.config.CardSeekerCfg")
local CardSeekerMgr = class("CardSeekerMgr", BaseGameControl)

function CardSeekerMgr:ctor()
    CardSeekerMgr.super.ctor(self)
    self:setRefName(G_REF.CardSeeker)
    -- 配置表，每次新赛季开启都要维护
    self.m_openSeasons = {
        ["202204"] = true,
        ["202301"] = true,
        ["202302"] = true,
        ["202303"] = true,
        ["202304"] = true,
        ["202401"] = true,
        ["302301"] = true,
    }

    self.m_isInView = false
end

function CardSeekerMgr:parseData(data)
    if not data then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = require("GameModule.CardMiniGames.CardSeeker.model.CardSeekerData"):create()
        _data:parseData(data)
        self:registerData(_data)
    else
        _data:parseData(data)
    end
end

function CardSeekerMgr:isSeasonOpenMiniGame()
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    if albumId and self.m_openSeasons[tostring(albumId)] then
        return true
    end
    return false
end

function CardSeekerMgr:setExitGameCallFunc(_over)
    self.m_over = _over
end

function CardSeekerMgr:enterGame(_openSource, _over)
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    CardSeekerCfg.resPath(albumId)
    CardSeekerCfg.resetBubbleTexts(albumId)
    self.m_openSource = _openSource
    self:setExitGameCallFunc(_over)
    local data = self:getData()
    if not data then
        return false
    end

    -- 外部系统直接打开的神像界面。需要播放当前赛季的集卡的背景音效
    if self.m_openSource == "CSEntryNode" then
        CardSysManager:playBgMusic()
    end

    self:showStartLayer()

    self.m_isInView = true
    return true
end

function CardSeekerMgr:exitGame()
    -- 外部系统直接打开的神像界面，需要关闭集卡的背景音效
    if self.m_openSource == "CSEntryNode" then
        CardSysManager:stopBgMusic()
    end

    self.m_isInView = false

    if self.m_over then
        self.m_over()
    end
end

function CardSeekerMgr:isInView()
    return self.m_isInView == true
end

-- 主题名
function CardSeekerMgr:getThemeName(refName)
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    if albumId ~= nil then
        return "CardGame_Seeker" .. tostring(albumId)
    end
    return CardSeekerMgr.super.getThemeName(self, refName)
end

function CardSeekerMgr:createEntryNode()
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    CardSeekerCfg.resPath(albumId)
    return util_createView(CardSeekerCfg.luaPath .. "entryNode.CSEntryNode")
end

function CardSeekerMgr:checkEntryNode()
    if not self:isSeasonOpenMiniGame() then
        return false
    end
    if not self:isCanShowLayer() then
        return false
    end
    -- 等级，赛季开启状态
    if not CardSysManager:canEnterCardCollectionSys() then
        return false
    end
    -- 判断资源是否下载
    if not CardSysManager:isDownLoadCardRes() then
        return false
    end
    -- 时间和状态
    local data = self:getData()
    if not data then
        return false
    end
    -- if data:getLeftTime() == 0 then
    --     return false
    -- end
    if data:isFinished() then
        return false
    end
    return true
end

function CardSeekerMgr:showCGLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("CSCGLayer") ~= nil then
        return nil
    end
    local view = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSCGLayer")
    view:setName("CSCGLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI + 1)
end

function CardSeekerMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("CSMainLayer") ~= nil then
        return nil
    end
    local view = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainLayer")
    view:setName("CSMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CardSeekerMgr:showRuleLayer()
    if gLobalViewManager:getViewByName("CSInfoLayer") ~= nil then
        return nil
    end
    local view = util_createView(CardSeekerCfg.luaPath .. "ruleUI.CSInfoLayer")
    view:setName("CSInfoLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CardSeekerMgr:showStartLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("CSStartLayer") ~= nil then
        return nil
    end
    local view = util_createView(CardSeekerCfg.luaPath .. "startUI.CSStartLayer")
    view:setName("CSStartLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CardSeekerMgr:showConfirmLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("CSConfirmLayer") ~= nil then
        return nil
    end
    local view = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSConfirmLayer")
    view:setName("CSConfirmLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CardSeekerMgr:showDefeatLayer(_levelIndex, _over)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("CSDefeatLayer") ~= nil then
        return nil
    end
    local view = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSDefeatLayer", _levelIndex, _over)
    view:setName("CSDefeatLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CardSeekerMgr:showLoseLayer(_rewardDatas, _over)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("CSLoseLayer") ~= nil then
        return nil
    end
    local view = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSLoseLayer", _rewardDatas, _over)
    view:setName("CSLoseLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CardSeekerMgr:showRewardLayer(_isFinal, _over)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("CSRewardUI") ~= nil then
        return nil
    end
    local view = util_createView(CardSeekerCfg.luaPath .. "rewardUI.CSRewardUI", _isFinal, _over)
    view:setName("CSRewardUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

--[[---------------------------------------------------------------------
    接口
]]
function CardSeekerMgr:requestOpenBox(_pos, _success)
    local successFunc = function(_result)
        if _success then
            _success()
        end
        gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_REQUEST_OPENBOX, {isSuc = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
    end
    local failFunc = function()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_REQUEST_OPENBOX, {isSuc = false})
    end
    local data = self:getData()
    if not data then
        return
    end
    local chapter = data:getCurLevelIndex()
    G_GetNetModel(NetType.CardSeeker):requestOpenBox(chapter, _pos, successFunc, failFunc)
end

function CardSeekerMgr:requestCollectReward(_success)
    local successFunc = function(_result)
        if _success then
            _success()
        end
        gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_REQUEST_COLLECT, {isSuc = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        -- 重新拉取一下集卡最新数据
        local yearID = CardSysRuntimeMgr:getCurrentYear()
        local albumId = CardSysRuntimeMgr:getCurAlbumID()
        local tExtraInfo = {year = yearID, albumId = albumId}
        CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo)
    end
    local failFunc = function()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_REQUEST_COLLECT, {isSuc = false})
    end
    local data = self:getData()
    if not data then
        return
    end
    local chapter = data:getCurLevelIndex()
    G_GetNetModel(NetType.CardSeeker):requestCollectReward(chapter, successFunc, failFunc)
end

function CardSeekerMgr:requestCostGem(_success, _type)
    local successFunc = function(_result)
        if _success then
            _success()
        end
        gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_REQUEST_COSTGEM, {isSuc = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    end
    local failFunc = function()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_REQUEST_COSTGEM, {isSuc = false})
    end
    local data = self:getData()
    if not data then
        return
    end
    local chapter = data:getCurLevelIndex()
    G_GetNetModel(NetType.CardSeeker):requestCostGem(_type, chapter, successFunc, failFunc)
end

function CardSeekerMgr:requestGiveUp(_success)
    local successFunc = function(_result)
        -- local data = self:getData()
        -- if data then
        --     data:parseData(_result)
        -- end

        if _success then
            _success()
        end
        gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_REQUEST_GIVEUP, {isSuc = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
    end
    local failFunc = function()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.CARD_SEEKER_REQUEST_GIVEUP, {isSuc = false})
    end
    local data = self:getData()
    if not data then
        return
    end
    local chapter = data:getCurLevelIndex()
    G_GetNetModel(NetType.CardSeeker):requestGiveUp(chapter, successFunc, failFunc)
end


-- 花费钻石再来一次
function CardSeekerMgr:requestPickAgain(_success)    
    self:requestCostGem(_success, "AGAIN")
end


function CardSeekerMgr:requestGiveUpAgain(_success, _fail)
    local data = self:getData()
    if not data then
        return
    end
    local successFunc = function(_result)
        if _success then
            _success()
        end
    end
    local failFunc = function()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end
    G_GetNetModel(NetType.CardSeeker):requestGiveUpAgain(successFunc, failFunc)
end

return CardSeekerMgr
