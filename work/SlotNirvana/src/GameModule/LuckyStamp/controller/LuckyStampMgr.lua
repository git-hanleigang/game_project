--[[
    盖戳
]]
require("GameModule.LuckyStamp.config.LuckyStampCfg")
local LuckyStampMgr = class("LuckyStampMgr", BaseGameControl)
function LuckyStampMgr:ctor()
    LuckyStampMgr.super.ctor(self)
    self:setRefName(G_REF.LuckyStamp)
    self:setResInApp(true)
end

function LuckyStampMgr:parseData(_netData, _isLogon, _isPay)
    if not _netData then
        return
    end
    local data = self:getData()
    if not data then
        data = require("GameModule.LuckyStamp.model.LuckyStampData"):create()
        data:parseData(_netData, _isLogon, _isPay)
        self:registerData(data)
    else
        data:parseData(_netData, _isLogon, _isPay)
    end
end

function LuckyStampMgr:enterGame(_over)
    print("LuckyStamp Mgr:enterGame")
    if self.m_stampQueueList == nil then
        self.m_stampQueueList = {}
    end
    local view = self:showMainLayer()
    if view then
        local LuckyStampQueue = util_require("GameModule.LuckyStamp.controller.LuckyStampQueue")
        local queue = LuckyStampQueue:create()
        queue:setOverFunc(_over)
        table.insert(self.m_stampQueueList, queue)
    else
        if _over then
            _over()
        end
    end
end

function LuckyStampMgr:exitGame()
    LuckyStampMgr.super.exitGame(self)

    if table.nums(self.m_stampQueueList) > 0 then
        local newestQueue = table.remove(self.m_stampQueueList)
        newestQueue:initPopList()
        newestQueue:doExitNextPop()
    end
end

function LuckyStampMgr:setHolidayChallenge(_isNeedCheck)
    self.m_isNeedCheckHolidayChallenge = _isNeedCheck
end

function LuckyStampMgr:getHolidayChallenge()
    return self.m_isNeedCheckHolidayChallenge
end

function LuckyStampMgr:createLuckyStampTip(_callback, _isPermanent, _isLuckySpin)
    if not self:isCanShowLayer() then
        return
    end
    return util_createView(LuckyStampCfg.luaPath .. "tipUI.LuckyStampTipViewNew", _callback, _isPermanent, _isLuckySpin)
end

function LuckyStampMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("LSGameMainUI") ~= nil then
        return
    end
    local view = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameMainUI")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function LuckyStampMgr:showRewardLayer(_over)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("LSGameRewardUI") ~= nil then
        return
    end
    self:setHolidayChallenge(true)
    local view = util_createView(LuckyStampCfg.luaPath .. "MiniGame.rewardUI.LSGameRewardUI", _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function LuckyStampMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("LSGameRuleUI") ~= nil then
        return
    end
    local view = util_createView(LuckyStampCfg.luaPath .. "MiniGame.ruleUI.LSGameRuleUI")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function LuckyStampMgr:showFlyLizi()
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("LSGameLizi") ~= nil then
        return
    end
    local particle = cc.ParticleSystemQuad:create(LuckyStampCfg.otherPath .. "gaichuo_tuowei.plist")
    particle:setName("LSFlyLizi")
    particle:setBlendFunc({src = GL_SRC_ALPHA, dst = GL_ONE})
    self:showLayer(particle, ViewZorder.ZORDER_UI, false)
    particle:setScale(1.5)
    return particle
end

function LuckyStampMgr:requestCollect(_success, _fail)
    local successFunc = function(_result)
        if _result["error"] ~= nil and _result["error"] == "expired" then
            -- 服务器返回时间过期
            local view = gLobalViewManager:getViewByName("LSGameMainUI")
            if view ~= nil then
                view:closeUI()
            end
            return
        end
        -- 玩完小游戏后要重置当前进度
        local data = self:getData()
        if data then
            data:setProcessIndex(0)
            data:setLocalCacheProcess(0)
        end
        if _result.luckyStampV2Config ~= nil then
            globalData.syncLuckyStampData(_result.luckyStampV2Config)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATA_LUCKYSTAMP)
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
    local data = self:getData()
    if not data then
        return
    end
    G_GetNetModel(NetType.LuckyStamp):requestCollect(successFunc, failFunc)
end

function LuckyStampMgr:requestRoll(_success, _fail)
    local successFunc = function(_result)
        if _result["error"] ~= nil and _result["error"] == "expired" then
            -- 服务器返回时间过期
            local view = gLobalViewManager:getViewByName("LSGameMainUI")
            if view ~= nil then
                view:closeUI()
            end
            return
        end
        if _result.luckyStampV2Config ~= nil then
            globalData.syncLuckyStampData(_result.luckyStampV2Config)
        end
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
    local data = self:getData()
    if not data then
        return
    end
    G_GetNetModel(NetType.LuckyStamp):requestRoll(successFunc, failFunc)
end

return LuckyStampMgr
