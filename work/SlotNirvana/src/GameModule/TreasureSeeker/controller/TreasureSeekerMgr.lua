--[[
]]
require("GameModule.TreasureSeeker.config.TreasureSeekerCfg")
local TreasureSeekerMgr = class("TreasureSeekerMgr", BaseGameControl)
local TEST_MODE = false
function TreasureSeekerMgr:ctor()
    TreasureSeekerMgr.super.ctor(self)
    self:setRefName(G_REF.TreasureSeeker)

    if TEST_MODE then
        self:parseData(TreasureSeekerCfg.TEST_DATA)
    end
end

-- 换皮时需主动更改这个名字，暂时无法通过配置来换皮
function TreasureSeekerMgr:getThemeName()
    return "TreasureSeekerAllCard"
end

function TreasureSeekerMgr:parseData(data)
    if not data then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = require("GameModule.TreasureSeeker.model.TreasureSeekerData"):create()
        _data:parseData(data)
        self:registerData(_data)
    else
        _data:parseData(data)
    end
end

function TreasureSeekerMgr:setExitGameCallFunc(_over)
    self.m_over = _over
end

function TreasureSeekerMgr:enterGame(_GameId, _over)
    self:setExitGameCallFunc(_over)
    self:setCurGameId(_GameId)
    return self:showStartLayer()
end

function TreasureSeekerMgr:exitGame()
    if self.m_over then
        self.m_over()
    end
end

function TreasureSeekerMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("TSMainLayer") ~= nil then
        return nil
    end
    local view = util_createView(TreasureSeekerCfg.luaPath .. "mainUI.TSMainLayer")
    view:setName("TSMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function TreasureSeekerMgr:showRuleLayer()
    if gLobalViewManager:getViewByName("TSInfoLayer") ~= nil then
        return nil
    end
    local view = util_createView(TreasureSeekerCfg.luaPath .. "ruleUI.TSInfoLayer")
    view:setName("TSInfoLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function TreasureSeekerMgr:showStartLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("TSStartLayer") ~= nil then
        return nil
    end
    local view = util_createView(TreasureSeekerCfg.luaPath .. "startUI.TSStartLayer")
    view:setName("TSStartLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function TreasureSeekerMgr:showDefeatLayer(_levelIndex, _over)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("TSDefeatLayer") ~= nil then
        return nil
    end
    local view = util_createView(TreasureSeekerCfg.luaPath .. "mainUI.TSDefeatLayer", _levelIndex, _over)
    view:setName("TSDefeatLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function TreasureSeekerMgr:showLoseLayer(_rewardDatas, _over)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("TSLoseLayer") ~= nil then
        return nil
    end
    local view = util_createView(TreasureSeekerCfg.luaPath .. "mainUI.TSLoseLayer", _rewardDatas, _over)
    view:setName("TSLoseLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function TreasureSeekerMgr:showRewardLayer(_isFinal, _over)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("TSRewardUI") ~= nil then
        return nil
    end
    local view = util_createView(TreasureSeekerCfg.luaPath .. "rewardUI.TSRewardUI", _isFinal, _over)
    view:setName("TSRewardUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function TreasureSeekerMgr:showCGLayer()
    -- local timeNode = cc.Node:create()
    -- gLobalViewManager:getViewLayer():addChild(timeNode)
    -- -- 延时
    -- util_performWithDelay(
    --     timeNode,
    --     function()
    --         -- 移除节点
    --         if not tolua.isnull(timeNode) then
    --             timeNode:removeFromParent()
    --             timeNode = nil
    --         end
    --     end,
    --     10 / 60
    -- )
    -- 创建
    gLobalSoundManager:playSound(TreasureSeekerCfg.otherPath .. "music/CG.mp3")
    local CGSpine = util_spineCreate(TreasureSeekerCfg.otherPath .. "spine/guochang", true, true, 1)
    gLobalViewManager:getViewLayer():addChild(CGSpine, ViewZorder.ZORDER_POPUI + 1)
    CGSpine:setPosition(cc.p(display.cx, display.cy))
    util_spinePlay(CGSpine, "guochang", false)
    util_spineEndCallFunc(
        CGSpine,
        "guochang",
        function()
            gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_CG_CLOSED)
            util_nextFrameFunc(
                function()
                    if not tolua.isnull(CGSpine) then
                        CGSpine:removeFromParent()
                        CGSpine = nil
                    end
                end
            )
        end
    )
end

--[[---------------------------------------------------------------------
    接口
]]
function TreasureSeekerMgr:requestOpenBox(_pos, _success)
    if TEST_MODE then
        self.m_testIndex = (self.m_testIndex or 0) + 1
        if self.m_testIndex == 1 then
            TreasureSeekerCfg.TEST_DATA_OPENBOX_1()
            self:parseData(TreasureSeekerCfg.TEST_DATA)
        elseif self.m_testIndex == 2 then
            TreasureSeekerCfg.TEST_DATA_OPENBOX_2()
            self:parseData(TreasureSeekerCfg.TEST_DATA)
        elseif self.m_testIndex == 3 then
            TreasureSeekerCfg.TEST_DATA_OPENBOX_3()
            self:parseData(TreasureSeekerCfg.TEST_DATA)
        elseif self.m_testIndex == 4 then
            TreasureSeekerCfg.TEST_DATA_OPENBOX_4()
            self:parseData(TreasureSeekerCfg.TEST_DATA)
        elseif self.m_testIndex == 5 then
            self.m_testIndex = 0
            TreasureSeekerCfg.TEST_DATA_OPENBOX_5()
            self:parseData(TreasureSeekerCfg.TEST_DATA)
        end
        gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_OPENBOX, {isSuc = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
    else
        local successFunc = function(_result)
            if _success then
                _success()
            end
            gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_OPENBOX, {isSuc = true})
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        end
        local failFunc = function()
            gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_OPENBOX, {isSuc = false})
        end
        local data = self:getData()
        if not data then
            return
        end
        local gameId = self:getCurGameId()
        assert(gameId ~= nil, "TreasureSeekerMgr:requestGiveUp 没有小游戏id，逻辑错误")
        local gameData = data:getGameDataById(gameId)
        assert(gameData ~= nil, "TreasureSeekerMgr:requestGiveUp 没有小游戏gameData，逻辑错误")
        local chapter = gameData:getCurLevelIndex()
        G_GetNetModel(NetType.TreasureSeeker):requestOpenBox(gameId, chapter, _pos, successFunc, failFunc)
    end
end

function TreasureSeekerMgr:requestCollectReward(_success)
    if TEST_MODE then
        gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_COLLECT, {isSuc = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
    else
        local successFunc = function(_result)
            if _success then
                _success()
            end
            gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_COLLECT, {isSuc = true})
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        end
        local failFunc = function()
            gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_COLLECT, {isSuc = false})
        end
        local data = self:getData()
        if not data then
            return
        end
        local gameId = self:getCurGameId()
        assert(gameId ~= nil, "TreasureSeekerMgr:requestGiveUp 没有小游戏id，逻辑错误")
        local gameData = data:getGameDataById(gameId)
        assert(gameData ~= nil, "TreasureSeekerMgr:requestGiveUp 没有小游戏gameData，逻辑错误")
        local chapter = gameData:getCurLevelIndex()
        G_GetNetModel(NetType.TreasureSeeker):requestCollectReward(gameId, chapter, successFunc, failFunc)
    end
end

function TreasureSeekerMgr:requestCostGem(_success)
    if TEST_MODE then
        TreasureSeekerCfg.TEST_DATA_COST()
        self:parseData(TreasureSeekerCfg.TEST_DATA)
        gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_COSTGEM, {isSuc = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    else
        local successFunc = function(_result)
            if _success then
                _success()
            end
            gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_COSTGEM, {isSuc = true})
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        end
        local failFunc = function()
            gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_COSTGEM, {isSuc = false})
        end
        local data = self:getData()
        if not data then
            return
        end
        local gameId = self:getCurGameId()
        assert(gameId ~= nil, "TreasureSeekerMgr:requestGiveUp 没有小游戏id，逻辑错误")
        local gameData = data:getGameDataById(gameId)
        assert(gameData ~= nil, "TreasureSeekerMgr:requestGiveUp 没有小游戏gameData，逻辑错误")
        local chapter = gameData:getCurLevelIndex()
        G_GetNetModel(NetType.TreasureSeeker):requestCostGem(gameId, chapter, successFunc, failFunc)
    end
end

function TreasureSeekerMgr:requestGiveUp(_success)
    if TEST_MODE then
        gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_GIVEUP, {isSuc = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
    else
        local successFunc = function(_result)
            if _success then
                _success()
            end
            gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_GIVEUP, {isSuc = true})
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        end
        local failFunc = function()
            gLobalNoticManager:postNotification(ViewEventType.TREASURE_SEEKER_REQUEST_GIVEUP, {isSuc = false})
        end
        local data = self:getData()
        if not data then
            return
        end
        local gameId = self:getCurGameId()
        assert(gameId ~= nil, "TreasureSeekerMgr:requestGiveUp 没有小游戏id，逻辑错误")
        local gameData = data:getGameDataById(gameId)
        assert(gameData ~= nil, "TreasureSeekerMgr:requestGiveUp 没有小游戏gameData，逻辑错误")
        local chapter = gameData:getCurLevelIndex()
        G_GetNetModel(NetType.TreasureSeeker):requestGiveUp(gameId, chapter, successFunc, failFunc)
    end
end

function TreasureSeekerMgr:setCurGameId(_id)
    if not _id then
        local data = self:getData()
        if data then
            local lastGameData = data:getLastGameData()
            if lastGameData then
                self.m_CurGameId = lastGameData:getId()
            end
        end
    else
        self.m_CurGameId = _id
    end
end

function TreasureSeekerMgr:getCurGameId()
    return self.m_CurGameId
end

return TreasureSeekerMgr
