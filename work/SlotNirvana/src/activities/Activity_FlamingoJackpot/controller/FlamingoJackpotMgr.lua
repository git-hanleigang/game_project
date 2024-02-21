--[[
    Flamingo Jackpot
]]

-- 加载配置文件
require("activities.Activity_FlamingoJackpot.config.FlamingoJackpotCfg")
-- jackpot数值同步管理
local FlamingoJackpotPoolCtr = import(".FlamingoJackpotPoolCtr")

local FlamingoJackpotMgr = class("FlamingoJackpotMgr", BaseActivityControl)

function FlamingoJackpotMgr:ctor()
    FlamingoJackpotMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FlamingoJackpot)

    -- SPIN后数据解析
    -- 关卡spin消息回调
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            if param[1] == true then
                local spinData = param[2]
                if spinData and spinData.action == "SPIN" and globalData.slotRunData.machineData ~= nil and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                    local data = self:getRunningData()
                    if data and data:checkLevelByLevelId(globalData.slotRunData.machineData.p_id) then
                        if spinData.flamingoJackpot ~= nil then
                            self:parseSpinData(spinData.flamingoJackpot)
                        end
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    self.m_poolCtr = FlamingoJackpotPoolCtr:create()
    self.m_poolCtr:init()
end

function FlamingoJackpotMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function FlamingoJackpotMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function FlamingoJackpotMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function FlamingoJackpotMgr:getPoolCtr()
    return self.m_poolCtr
end

function FlamingoJackpotMgr:parseSpinData(_netData)
    if not _netData then
        return
    end
    local data = self:getRunningData()
    if not data then
        return
    end
    -- 没有拦截非配置关卡的数据，理论上服务器不应该发数据
    data:parseSpinData(_netData)

    -- 飞钥匙逻辑，单独拆出来处理方便连续飞
    self:startSpinFlyKey()
end

-- 没有最大值，一直涨，下次数据来了，重新计算
function FlamingoJackpotMgr:getJackpotValue(_jackpotType)
    local coins = 0
    local data = self:getRunningData()
    if not data then
        return coins
    end
    local jackpotData = data:getJackpotDataByType(_jackpotType)
    if jackpotData then
        local value = jackpotData:getValue() or 0
        local offset = jackpotData:getOffset() or 0
        local syncTime = self.m_poolCtr:getSyncTime(_jackpotType) or 0
        local addTimes = math.floor(syncTime / FlamingoJackpotCfg.JACKPOT_FRAME)
        coins = value + addTimes * offset
    end
    return coins
end

function FlamingoJackpotMgr:syncJackpotPoolData(_jackpotType)
    local data = self:getRunningData()
    if not data then
        return
    end
    data:syncJackpotPoolData(_jackpotType)
end

function FlamingoJackpotMgr:clearSpinTriggerData(_clearType)
    local data = self:getRunningData()
    if not data then
        return
    end
    data:clearSpinTriggerData(_clearType)
end

-- loading 资源
function FlamingoJackpotMgr:isDownloadLobbyRes()
    return self:isDownloadLoadingRes()
end

-- 消耗额外金币需要实现的方法
function FlamingoJackpotMgr:getBetExtraPercent()
    local betPercent = 0

    local data = self:getRunningData()
    if not data then
        return betPercent
    end
    -- 判断关卡
    if not globalData.slotRunData.machineData then
        return betPercent
    end
    if not data:checkLevelByLevelId(globalData.slotRunData.machineData.p_id) then
        return betPercent
    end   
    -- 判断开关
    local switchStatus = self:getSwitchStatusCacheData()
    if switchStatus == FlamingoJackpotCfg.SwitchStatus.OFF then
        return betPercent
    end

    betPercent = (data:getExtraBetPercent() or 0) / 100

    return betPercent
end

-- 规则
function FlamingoJackpotMgr:showRuleLayer()
    if gLobalViewManager:getViewByName("FJackpotRuleLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity_FlamingoJackpot.Code.Rule.FJackpotRuleLayer")
    view:setName("FJackpotRuleLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 奖励
function FlamingoJackpotMgr:showRewardLayer(layerType,_rewardCoins, _rewardGems, _rewardItems,_over)
    if gLobalViewManager:getViewByName("FJackpotRewardLayer") ~= nil then
        return nil
    end
    -- 打开奖励界面的时候同步一下jackpot
    self:syncJackpotPoolData()

    local layerPath = "Activity_FlamingoJackpot.Code.Reward.FJackpotRewardLayer"
    if layerType >= 2 then
        layerPath = "Activity_FlamingoJackpot.Code.Reward.FJackpotDexRewardLayer"
    end
    local view = util_createView(layerPath, _rewardCoins, _rewardGems, _rewardItems,_over,layerType)
    view:setName("FJackpotRewardLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 打开轮盘
function FlamingoJackpotMgr:showWheelLayer(_overCall)
    if not self:isCanShowLayer() then
        return nil
    end
    local activityData = self:getRunningData()
    if not activityData:isActiveWheel() then
        return nil
    end
    if gLobalViewManager:getViewByName("FJackpot_WheelLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity_FlamingoJackpot.Code.Wheel.FJackpot_WheelLayer", _overCall)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 每日首次参与弹版
function FlamingoJackpotMgr:showDayFirstLayer(_over)
    if not self:isCanShowLayer() then
        return nil
    end
    if globalData.slotRunData.machineData == nil then
        return nil
    end
    local data = self:getRunningData()
    if not data:checkLevelByLevelId(globalData.slotRunData.machineData.p_id) then
        return nil
    end
    if not self:checkDayFirstCD() then
        return nil
    end
    if gLobalViewManager:getViewByName("FJackpot_DayFirstJoinLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity_FlamingoJackpot.Code.Join.FJackpot_DayFirstJoinLayer", _over)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        self:recordDayFirstCD()
    end
    return view
end

-- 二次确认弹版
function FlamingoJackpotMgr:showConfirmLayer(_over, _betValue)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("FJackpot_DayFirstConfirmLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity_FlamingoJackpot.Code.Join.FJackpot_DayFirstConfirmLayer", _over, _betValue)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 透明的逻辑遮罩层
function FlamingoJackpotMgr:addLogicMask()
    if gLobalViewManager:getViewByName("FJackpotLogicMaskLayer") ~= nil then
        return nil
    end    
    local view = util_createView("Activity_FlamingoJackpot.Code.Mask.FJackpotLogicMaskLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function FlamingoJackpotMgr:removeLogicMask()
    local mask = gLobalViewManager:getViewByName("FJackpotLogicMaskLayer")
    if mask ~= nil then
        mask:closeUI()
        mask = nil
    end
end

function FlamingoJackpotMgr:checkGameTopNode()
    if not self:isCanShowLayer() then
        return false
    end
    local data = self:getRunningData()
    if not data then
        return false
    end
    -- 判断关卡
    if not data:checkLevelByLevelId(globalData.slotRunData.machineData.p_id) then
        return false
    end
    return true
end

-- 紧贴关卡上UI底部的节点
function FlamingoJackpotMgr:createGameTopNode()
    local topNode = util_createView("Activity_FlamingoJackpot.Code.Main.FJackpot_Main")
    topNode:setName("FJackpot_Main")
    self.m_gameTopNode = topNode
    return topNode
end

--[[
    关卡spin触发逻辑
]]
function FlamingoJackpotMgr:checkSpin()
    local data = self:getRunningData()
    if data then
        -- 判断关卡
        if data:checkLevelByLevelId(globalData.slotRunData.machineData.p_id) then
            -- local addValue = data:getAddProcess()
            local isActiveSlot = data:isActiveSlot()
            local isActiveWheel = data:isActiveWheel()
            -- if addValue and addValue > 0 then
            --     return true
            -- end
            -- 激活老虎机
            if isActiveSlot then
                return true
            end
            -- 激活轮盘
            if isActiveWheel then
                return true
            end
        end    
    end
    return false
end

function FlamingoJackpotMgr:startSpinAction(_over)
    if not tolua.isnull(self.m_gameTopNode) then
        self.m_gameTopNode:startSpinAction(_over)
    else
        if _over then
            _over()
        end
    end
end

function FlamingoJackpotMgr:startSpinFlyKey()
    local data = self:getRunningData()
    if not data then
        return
    end
    -- 获取spin后的激活数据
    local addValue = data:getAddProcess()
    local isActiveSlot = data:isActiveSlot()
    local isActiveWheel = data:isActiveWheel()    
    if addValue and addValue > 0 and not (isActiveSlot or isActiveWheel) then
        if not tolua.isnull(self.m_gameTopNode) then       
            self.m_gameTopNode:startSpinFlyKey()
        end 
    end
end

-- 更改关卡的bet
function FlamingoJackpotMgr:changeBet(_betValue)
    if globalData.slotRunData.machineData then
        local betList = globalData.slotRunData.machineData:getMachineCurBetList()
        if betList and #betList > 0 then
            local targetBetData = nil
            local minBetData = betList[1]
            local maxBetData = betList[#betList]
            if _betValue <= minBetData.p_totalBetValue then
                targetBetData = minBetData
            elseif _betValue >= maxBetData.p_totalBetValue then
                targetBetData = maxBetData
            else
                local lastBetValue = 0
                for i=1,#betList do
                    local betData = betList[i]
                    if (betData.p_totalBetValue == _betValue) or (lastBetValue < _betValue and _betValue <= betData.p_totalBetValue) then
                        targetBetData = betData
                        break
                    end
                    lastBetValue = betData.p_totalBetValue
                end
            end
            if targetBetData ~= nil then
                -- 更改
                globalData.slotRunData.iLastBetIdx = targetBetData.p_betId
                -- 更改消息
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
            end
        end
    end
end

-- 每天首次参与，控制活动开关
function FlamingoJackpotMgr:controlSwitchByDayFirst(_type)
    if not tolua.isnull(self.m_gameTopNode) then
        if _type == "open" then
            self.m_gameTopNode:openFlamingoFunc()
        elseif _type == "close" then
            self.m_gameTopNode:closeFlamingoFunc()
        end
    end
end

-- function FlamingoJackpotMgr:requestStart()
--     -- local data = self:getRunningData()
--     -- if data then
--     -- end
--     local function successFunc(_result)
--     end
--     local function failureFunc()
--         gLobalViewManager:showReConnect()
--     end
--     G_GetNetModel(NetType.FlamingoJackpot):requestStart(successFunc, failureFunc)
-- end

function FlamingoJackpotMgr:showGuideMaskLayer(_clickMask)
    if gLobalViewManager:getViewByName("FJackpotLogicMaskLayer") ~= nil then
        return nil
    end    
    local view = util_createView("Activity_FlamingoJackpot.Code.Guide.FJackpotGuideMaskLayer", _clickMask)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_GUIDE)
    return view
end

function FlamingoJackpotMgr:checkGuide()
    -- 判断是否有数据
    local data = self:getRunningData()
    if not data then
        return false
    end
    -- 判断是否有资源
    if not self:isCanShowLayer() then
        return false
    end
    -- 判断关卡
    if not data:checkLevelByLevelId(globalData.slotRunData.machineData.p_id) then
        return false
    end
    local guideId = self:getLocalCacheData("Guide", 0)
    if guideId > 0 then
        return false
    end
    if tolua.isnull(self.m_gameTopNode) then
        return false
    end
    return true
end

function FlamingoJackpotMgr:startGuide(_over)
    if tolua.isnull(self.m_gameTopNode) then
        if _over then
            _over()
        end
        return
    end
    self.m_gameTopNode:startGuide(_over)
end


-- 检查bet气泡
function FlamingoJackpotMgr:isCanShowBetBubble()
    if not FlamingoJackpotMgr.super.isCanShowBetBubble(self) then
        return false
    end
    -- 判断是否有数据
    local data = self:getRunningData()
    if not data then
        return false
    end
    -- 判断是否有资源
    if not self:isCanShowLayer() then
        return false
    end
    if not (globalData.slotRunData and globalData.slotRunData.machineData) then
        return false
    end     
    -- 判断关卡
    if not data:checkLevelByLevelId(globalData.slotRunData.machineData.p_id) then
        return false
    end    
    -- 判断开关
    if self:getSwitchStatusCacheData() == FlamingoJackpotCfg.SwitchStatus.OFF then
        return false
    end
    return true
end

function FlamingoJackpotMgr:getBetBubblePath(_refName)
    return "BetExtraBubbleCode/" .. _refName .. "BetExtraNode"
end

-- 每日首次参与弹版
function FlamingoJackpotMgr:getDayFirstCD()
    if self.m_dayFirstCDTime == nil then
        -- 当前时间戳
        local curServerTime = tonumber(globalData.userRunData.p_serverTime / 1000)        
        -- 从缓存中获取
        self.m_dayFirstCDTime = self:getLocalCacheData("DayFirstCDTime", curServerTime)
    end
    return self.m_dayFirstCDTime
end

function FlamingoJackpotMgr:recordDayFirstCD()
    -- 当前时间戳
    local curServerTime = tonumber(globalData.userRunData.p_serverTime / 1000)
    -- 当天剩余时间戳
    local todayLeftTime = util_get_today_lefttime() 
    -- 第二天0点时间戳
    local nextDay0Time = curServerTime + todayLeftTime
    self.m_dayFirstCDTime = nextDay0Time
    -- 计入缓存
    self:setLocalCacheData("DayFirstCDTime", self.m_dayFirstCDTime)
end

-- 检测是否是每日首次
function FlamingoJackpotMgr:checkDayFirstCD()
    local cdTime = self:getDayFirstCD()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if curTime >= cdTime then
        return true
    end
    return false
end

-- 每一期开始都要重新记录
function FlamingoJackpotMgr:getLocalCacheKey(_key)
    local data = self:getRunningData()
    if data then
        local expireAt = data:getExpireAt()
        return globalData.userRunData.uid .. "_FlamingoJackpot_" .. _key .. "_" .. expireAt
    end
    return nil
end

-- 记录本地缓存
function FlamingoJackpotMgr:setLocalCacheData(_key, _value)
    local cacheKey = self:getLocalCacheKey(_key)
    if cacheKey then
        gLobalDataManager:setNumberByField(cacheKey , _value)
    end
end

function FlamingoJackpotMgr:getLocalCacheData(_key, _defaultValue)
    local cacheKey = self:getLocalCacheKey(_key)
    if cacheKey then
        return gLobalDataManager:getNumberByField(cacheKey, _defaultValue == nil and 1 or _defaultValue)
    end
    return nil
end

-- 开关的缓存数据，默认是关闭
function FlamingoJackpotMgr:getSwitchStatusCacheData()
    if self.m_switchStatus == nil then
        self.m_switchStatus = self:getLocalCacheData(FlamingoJackpotCfg.SwitchKey, FlamingoJackpotCfg.SwitchStatus.OFF)
    end
    return self.m_switchStatus
end

function FlamingoJackpotMgr:setSwitchStatusCacheData(_status)
    self.m_switchStatus = _status
    self:setLocalCacheData(FlamingoJackpotCfg.SwitchKey, _status)
    -- bet气泡
    G_GetMgr(G_REF.BetBubbles):refreshBetBubble(ACTIVITY_REF.FlamingoJackpot, self.m_switchStatus == FlamingoJackpotCfg.SwitchStatus.ON)    
    -- 发消息通知GameBottomNode改变bet显示
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_BET_EXTRA_COST_SWITCH, {name = ACTIVITY_REF.FlamingoJackpot})
end

-- 箭头的缓存数据，默认是下拉
function FlamingoJackpotMgr:getArrowStatusCacheData()
    if self.m_arrowStatus == nil then
        self.m_arrowStatus = self:getLocalCacheData(FlamingoJackpotCfg.ArrowKey, FlamingoJackpotCfg.ArrowStatus.DOWN)
    end
    return self.m_arrowStatus
end

function FlamingoJackpotMgr:setArrowStatusCacheData(_status)
    self.m_arrowStatus = _status
    self:setLocalCacheData(FlamingoJackpotCfg.ArrowKey, _status)
end

return FlamingoJackpotMgr
