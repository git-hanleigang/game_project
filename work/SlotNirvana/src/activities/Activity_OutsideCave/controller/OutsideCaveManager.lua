-- 大富翁 控制类
require("activities.Activity_OutsideCave.config.OutsideCaveConfig")
local OutsideCaveNet = require("activities.Activity_OutsideCave.net.OutsideCaveNet")
local OutsideCaveManager = class("OutsideCaveManager", BaseActivityControl)

function OutsideCaveManager:ctor()
    OutsideCaveManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.OutsideCave)

    self.m_Net = OutsideCaveNet:getInstance()
end

-- 是否播放从头追到第一个章节的动作
function OutsideCaveManager:getFirstChapterLockKey()
    local data = self:getRunningData()
    if data then
        return "OutsideCaveFirstChapterLock_" .. data:getExpireAt()
    end
    return 
end

function OutsideCaveManager:isFirstChapterLock()
    local key = self:getFirstChapterLockKey()
    if key == nil then
        return false
    end
    local last = gLobalDataManager:getNumberByField(key, 0)
    if last == 1 then
        return false
    end
    local data = self:getRunningData()
    if not data then
        return false
    end
    if not data:isFirstRound() then
        return false
    end
    if not data:isFirstStage() then
        return false
    end
    if not data:isFirstStep() then
        return false
    end
    return true
end

function OutsideCaveManager:recordFirstChapterLock()
    local key = self:getFirstChapterLockKey()
    if key == nil then
        return
    end
    gLobalDataManager:setNumberByField(key , 1)
end

function OutsideCaveManager:getEnterCGKey()
    local data = self:getRunningData()
    if data then
        return "OutsideCaveEnterCG_" .. data:getExpireAt()
    end
    return 
end

-- 是否显示CG
function OutsideCaveManager:isShowEnterCG()
    local key = self:getEnterCGKey()
    if key == nil then
        return false
    end
    local newSecs = util_getCurrnetTime()
    local lastTime = gLobalDataManager:getNumberByField(key, 0)
    if lastTime == 0 then
        gLobalDataManager:setNumberByField(key , newSecs)
        return true
    end
    -- 是否跨天
    local oldSecs = lastTime
    -- 服务器时间戳转本地时间
    local oldTM = util_UTC2TZ(oldSecs, -8)
    local newTM = util_UTC2TZ(newSecs, -8)
    if oldTM.day ~= newTM.day then
        gLobalDataManager:setNumberByField(key , newSecs)
        return true
    end
    return false
end

function OutsideCaveManager:showEnterCGLayer(_enterCall, _over)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCMainCGEnterLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Main.OCMainCGEnterLayer",_enterCall, _over)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view    
end

function OutsideCaveManager:showChapterCGLayer(_enterCall, _over)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCMainCGChapterLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Main.OCMainCGChapterLayer", _enterCall, _over)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view    
end

function OutsideCaveManager:showRoundCGLayer(_enterCall, _over)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCMainCGRoundLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Main.OCMainCGRoundLayer", _enterCall, _over)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view    
end

function OutsideCaveManager:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCMainLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    if not util_IsFileExist(themeName .. "/Main/OCMainLayer.lua") and not util_IsFileExist(themeName .. "/Main/OCMainLayer.luac") then
       return 
    end
    local view = util_createView(themeName .. ".Main.OCMainLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function OutsideCaveManager:showChapterMainLayer(_chapterIndex)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCChapterMainLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Chapter.OCChapterMainLayer", _chapterIndex)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function OutsideCaveManager:showWheelMainLayer(_resumeSlot)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCWheelMainLayer") ~= nil then
        return
    end
    -- 检查数据完整性
    local data = self:getRunningData()
    if not (data and data:checkWheelGameEffective()) then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Wheel.OCWheelMainLayer", _resumeSlot)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function OutsideCaveManager:showWheelRewardLayer(_over, _rewardCoins, _rewardGems, _rewardItems, _rewardForward)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCWheelRewardLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Wheel.OCWheelRewardLayer", _over, _rewardCoins, _rewardGems, _rewardItems, _rewardForward)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function OutsideCaveManager:showChapterRewardLayer(_over, _rewardCoins, _rewardGems, _rewardItems, _rewardForward)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCChapterRewardLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Chapter.OCChapterRewardLayer", _over, _rewardCoins, _rewardGems, _rewardItems, _rewardForward)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function OutsideCaveManager:showSlotRewardLayer(_over, _rewardCoins, _rewardGems, _rewardItems, _rewardForward)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OutCSlotRewardLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".SlotGame.OutCSlotRewardLayer", _over, _rewardCoins, _rewardGems, _rewardItems, _rewardForward)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function OutsideCaveManager:showRoundRewardLayer(_over, _rewardCoins, _rewardGems, _rewardItems, _rewardForward)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCRoundRewardLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Main.OCRoundRewardLayer", _over, _rewardCoins, _rewardGems, _rewardItems, _rewardForward)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function OutsideCaveManager:showMainInfoLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OCInfoLayer") ~= nil then
        return
    end
    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Info.OCInfoLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

------------------------------------------------------排行榜
-- 请求排行榜数据
function OutsideCaveManager:sendActionRank(_flag)
    self.m_Net:sendActionRank(_flag)
end

-- 显示排行榜主界面
function OutsideCaveManager:showRankLayer(param)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OutsideCaveRankUI") ~= nil then
        return
    end
    local OutsideCaveRankUI = nil
    self:sendActionRank(true)
    local themeName = self:getThemeName()
    local OutsideCaveRankUI = util_createView(themeName .. ".Rank.OutsideCaveRankUI", param)
    if OutsideCaveRankUI ~= nil then
        self:showLayer(OutsideCaveRankUI, ViewZorder.ZORDER_UI + 1)
    end
    return OutsideCaveRankUI
end

-- 显示排行榜主界面
function OutsideCaveManager:showRankInfoLayer(param)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("OutsideCaveRankInfo") ~= nil then
        return
    end

    local themeName = self:getThemeName()
    local OutsideCaveRankUI = util_createView(themeName .. ".Rank.OutsideCaveRankInfo", param)
    if OutsideCaveRankUI ~= nil then
        self:showLayer(OutsideCaveRankUI, ViewZorder.ZORDER_UI + 1)
    end
    return OutsideCaveRankUI
end

--------------------------------------------------------spine得道具
-- 修改关卡内可获得道具上限
function OutsideCaveManager:sendGemsUpLimit()
    local success = function (_result)
        gLobalViewManager:removeLoadingAnima()
        -- 更新
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OUTSIDECAVE_GEMSUPLIMIT)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OCSLOT_UPDATE_REDPOINT)
    end
    local failed = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end
    self.m_Net:sendGemsUpLimit(success,failed)
end

-- 转盘spin
function OutsideCaveManager:sendWheelSpin()
    local successFunc = function(_netData)
        local data = self:getRunningData()
        if not data then
            return
        end
        data:recordWheelResultData(_netData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OUTSIDECAVE_WHEEL_SPIN, {success = true, position = _netData.position})
    end
    local fileFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OUTSIDECAVE_WHEEL_SPIN, {success = false})
    end
    self.m_Net:sendWheelSpin(successFunc,fileFunc)
end

-- 老虎机spin
function OutsideCaveManager:sendSlotSpin(_bet)
    local successFunc = function(_netData)
        local data = self:getRunningData()
        if not data then
            return
        end
        --dump(_netData)
        data:setSlotResult(_netData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OCSLOT_SPINRESULT, {success = true})
    end
    local fileFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OCSLOT_SPINRESULT, {success = false})
    end
    self.m_Net:sendSlotSpin(successFunc,fileFunc,_bet)
end

function OutsideCaveManager:getEntryPath(entryName)
    local themeName = self:getThemeName()
    return themeName .. "/EntryNode/" .. themeName .. "EntryNode" 
end

function OutsideCaveManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "_loading".."/Icons/" .. themeName .. "HallNode"
end

function OutsideCaveManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "_loading".."/Icons/" .. themeName .. "SlideNode"
end

function OutsideCaveManager:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "_loading/" .. themeName 
end

function OutsideCaveManager:getBottomPath(lobbyName)
    return OutsideCaveManager.super.getBottomPath(self,lobbyName)
end

function OutsideCaveManager:getBetIndex()
    local key = self:getCacheKey("Bet")
    if not key then
        return
    end
    local betIndex = gLobalDataManager:getNumberByField(key, 1)
    return betIndex
end

function OutsideCaveManager:setBetIndex(_betIndex)
    local key = self:getCacheKey("Bet")
    if not key then
        return
    end
    if not (_betIndex and _betIndex > 0) then
        return
    end
    gLobalDataManager:setNumberByField(key, _betIndex)
end

function OutsideCaveManager:getCBet()
    local data = self:getRunningData()
    if data then
        local gears = data:getCurBetG()
        if gears and gears.p_gears and #(gears.p_gears) > 0 then
            local betIndex = self:getBetIndex() or 1
            return gears.p_gears[betIndex] or 1
        end
    end
    return 1
end

function OutsideCaveManager:getCacheKey(_type1, _type2)
    local data = self:getRunningData()
    if data then
        local key = "OutsideCave"
        if _type1 then
            key = key .. "_" .. _type1
        end
        if _type2 then
            key = key .. "_" .. _type2
        end
        key = key .. "_" .. data:getExpireAt()
        return key
    end
    return 
end

function OutsideCaveManager:recordGuide(_type)
    local key = self:getCacheKey("Guide", _type)
    if not key then
        return
    end
    gLobalDataManager:setNumberByField(key, 1)
end

-- function OutsideCaveManager:isHasWheelGuide()
--     local key = self:getCacheKey("Guide", "Wheel")
--     if not key then
--         return false
--     end
--     local guide = gLobalDataManager:getNumberByField(key, 0)
--     if guide == 1 then
--         return false
--     end
--     return true
-- end

function OutsideCaveManager:isHasSlotGuide()
    local key = self:getCacheKey("Guide", "Slot")
    if not key then
        return false
    end
    local guide = gLobalDataManager:getNumberByField(key, 0)
    if guide == 1 then
        return false
    end
    local data = self:getRunningData()
    if not data then
        return false
    end
    if not data:isFirstRound() then
        return false
    end
    if not data:isFirstStage() then
        return false
    end
    if not data:isFirstStep() then
        return false
    end
    return true
end

function OutsideCaveManager:isHasForwardGuide()
    local key = self:getCacheKey("Guide", "Forward")
    if not key then
        return false
    end
    local guide = gLobalDataManager:getNumberByField(key, 0)
    if guide == 1 then
        return false
    end
    local data = self:getRunningData()
    if not data then
        return false
    end
    if not data:isFirstRound() then
        return false
    end
    if not data:isFirstStage() then
        return false
    end
    return true
end
------促销
function OutsideCaveManager:getWildBuff()
    local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_OUTSIDECAVE_WILD)
    return leftTimes and leftTimes > 0
end
-- function OutsideCaveManager:getInCoinBuff()
--     local leftTimes = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPE_OUTSIDECAVE_DOUBLE_COIN)
--     return leftTimes and leftTimes > 0
-- end
function OutsideCaveManager:getCoinBuff()
    local multi = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPE_OUTSIDECAVE_DOUBLE_COIN)
    return multi
end
function OutsideCaveManager:getForwardBuff()
    local multi = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPE_OUTSIDECAVE_DOUBLE_FORWARD)
    return multi
end

function OutsideCaveManager:setInSpin(_isIn)
    self.m_isInSpin = _isIn
end

function OutsideCaveManager:isInSpin()
    return self.m_isInSpin == true
end

function OutsideCaveManager:exitGame()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OCSLOT_UPDATE_REDPOINT)
    OutsideCaveManager.super.exitGame(self)
end

--[[--
    _spinType: auto alone
]]
function OutsideCaveManager:getSpinLog(_spinType)
    local key = self:getCacheKey("SpinLog", _spinType)
    if not key then
        return
    end
    local num = gLobalDataManager:getNumberByField(key, 0)
    return num
end

function OutsideCaveManager:setSpinLog(_spinType, _num)
    local key = self:getCacheKey("SpinLog", _spinType)
    if not key then
        return
    end
    if _num == nil then
        return
    end
    gLobalDataManager:setNumberByField(key, _num)
end

function OutsideCaveManager:clearSpinLog()
    self:setSpinLog("auto", 0)
    self:setSpinLog("alone", 0)
end

return OutsideCaveManager
