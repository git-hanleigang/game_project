--[[--
    引导基类
    每一期都有引导
]]
local PokerGuideMgr = class("PokerGuideMgr", BaseSingleton)

function PokerGuideMgr:ctor()
    -- 引导配置
    self:initCfg()
end

function PokerGuideMgr:initCfg()
    self.GUIDE_CFG = {}
    assert(false, "配置表，必须重写")
end

function PokerGuideMgr:getRefName()
    assert(false, "活动引用名，必须重写")
end

function PokerGuideMgr:getClientCacheKey()
    assert(false, "活动缓存记录key，必须重写")
end

-- 活动控制类实现showGuideLayer方法
function PokerGuideMgr:createGuideLayer(_stepKey)
    assert(false, "遮罩层UI，必须重写")
end

-- 可重复引导，步骤结束条件
function PokerGuideMgr:getDynamicMax(_stepKey)
    assert(false, "步骤达到最大条件才能结束，必须重写")
end

-- 可重复引导，引导步骤计数
function PokerGuideMgr:setDynamicData(_stepKey)
    assert(false, "执行一次累计计数，不同活动引导，必须重写")
end

--------------------------------------------------------------------------------
function PokerGuideMgr:getGuideConfig(_key)
    for i = 1, #self.GUIDE_CFG do
        if _key == self.GUIDE_CFG[i].key then
            return self.GUIDE_CFG[i]
        end
    end
end

-- 每一期开始都要引导
function PokerGuideMgr:getGuideKey()
    local refName = self:getRefName()
    local data = G_GetMgr(refName):getData()
    if data then
        local id = data:getExpireAt()
        local key = self:getClientCacheKey()
        return refName .. "_" .. key .. "_" .. id
    end
end

---- 这是一条华丽丽的分割线 ---------------------------------------------------------------------------------------
function PokerGuideMgr:getGuiding()
    return self.m_isGuiding
end
function PokerGuideMgr:setGuiding(_isGuiding)
    self.m_isGuiding = _isGuiding
end
function PokerGuideMgr:getGuideStopping()
    return self.m_isGuideStopping
end
function PokerGuideMgr:setGuideStopping(_isGuideStopping)
    print("----------------- PokerGuideMgr:setGuideStopping _isGuideStopping = " .. (_isGuideStopping and "true" or "false"))
    self.m_isGuideStopping = _isGuideStopping
end
function PokerGuideMgr:getGuidingId()
    if self.m_GuideingId == nil then
        self.m_GuideingId = self:getUserDefaultStepId() or 0
    end
    return self.m_GuideingId
end
function PokerGuideMgr:setGuidingId(_GuideingId)
    self.m_GuideingId = _GuideingId
end
function PokerGuideMgr:getUserDefaultStepId()
    local cacheKey = self:getGuideKey()
    if cacheKey ~= nil then
        local stepId = gLobalDataManager:getNumberByField(cacheKey, 0)
        return stepId
    end
    return 0
end
function PokerGuideMgr:setUserDefaultStepId(_stepId)
    local cacheKey = self:getGuideKey()
    if cacheKey ~= nil then
        gLobalDataManager:setNumberByField(cacheKey, _stepId)
    end
end
-- 单步引导，开始流程结束时回调 _key = start
-- 单步引导，结束流程结束时回调 _key = stop
-- 单步引导，整个流程结束的回调 _key = all
function PokerGuideMgr:setStepOverCallFunc(_stepKey, _key, _callFunc)
    if not (_key and _stepKey and _callFunc) then
        return
    end
    if not self.m_stepOverCall then
        self.m_stepOverCall = {}
    end
    if not self.m_stepOverCall[_stepKey] then
        self.m_stepOverCall[_stepKey] = {}
    end
    if not self.m_stepOverCall[_stepKey][_key] then
        self.m_stepOverCall[_stepKey][_key] = {}
    end
    table.insert(self.m_stepOverCall[_stepKey][_key], _callFunc)
end
function PokerGuideMgr:doStepOverCallFunc(_stepKey, _key)
    if not (_stepKey and _key) then
        return
    end
    if self.m_stepOverCall then
        if self.m_stepOverCall[_stepKey] then
            if self.m_stepOverCall[_stepKey][_key] and #self.m_stepOverCall[_stepKey][_key] > 0 then
                for i = #self.m_stepOverCall[_stepKey][_key], 1, -1 do
                    self.m_stepOverCall[_stepKey][_key][i]()
                    self.m_stepOverCall[_stepKey][_key][i] = nil
                end
            end
        end
    end
end

function PokerGuideMgr:isFinishStep(_stepId, _dynamic)
    local curStepId = self:getGuidingId()
    if curStepId == 0 then
        return false
    end
    if curStepId > _stepId then
        return true
    end
    return false
end

function PokerGuideMgr:checkStartGuide(_key)
    local cfg = self:getGuideConfig(_key)
    if not cfg then
        return false
    end
    -- 判断自己是否完成
    if self:isFinishStep(cfg.id) then
        return false
    end
    -- 判断当前引导是否是前置引导
    if cfg.preId then
        local curStepId = self:getGuidingId()
        if cfg.dynamic then
            if not (curStepId == cfg.preId or curStepId == cfg.id) then
                return false
            end
        else
            if not (curStepId == cfg.preId) then
                return false
            end
        end
    end
    return true
end

function PokerGuideMgr:checkStopGuide(_key)
    local cfg = self:getGuideConfig(_key)
    if not cfg then
        return false
    end
    if self:getGuideStopping() then
        return false
    end
    if self:isFinishStep(cfg.id) then
        return false
    end
    if not self.m_stepUI then
        return false
    end
    return true
end

-- _startOverCall: 当前引导的开始流程结束时的回调方法
-- _stopOverCall: 当前引导的结束流程结束时的回调方法
-- 理论上，如果引导有回调，配置也有nextId，优先执行nextId，等nextId执行完在执行回调。配表和传参数时注意。
function PokerGuideMgr:startGuide(_key, _stopOverCall, _startOverCall)
    print(" -----------------0 startGuide _key = ", _key)

    local cfg = self:getGuideConfig(_key)
    assert(cfg ~= nil, "新手引导的配置错误，_key = " .. _key)

    if _startOverCall then
        self:setStepOverCallFunc(_key, "start", _startOverCall)
    end
    if _stopOverCall then
        self:setStepOverCallFunc(_key, "stop", _stopOverCall)
    end

    if cfg.startRecord then
        self:setUserDefaultStepId(cfg.startRecord)
    end

    local dynamicProgress = nil
    if cfg.dynamic then
        self:setDynamicData(cfg.key)
        dynamicProgress = cfg.dynamic.cur
    end

    self:setGuidingId(cfg.id)
    self:setGuiding(true)

    -- 获取引导界面
    if self.m_stepUI and self.m_stepUI.removeFromParent then
        self.m_stepUI:removeFromParent()
        self.m_stepUI = nil
    end
    self.m_stepUI = self:createGuideLayer(cfg.key) -- 开始后发送消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_GUIDE_START, {refName = self:getRefName(), stepKey = cfg.key, dynamic = dynamicProgress})
    return true
end

function PokerGuideMgr:closeGuideStartUI(_key)
    print(" -----------------0 closeGuideStartUI _key = ", _key)
    local cfg = self:getGuideConfig(_key)
    if not cfg then
        return
    end
    assert(cfg ~= nil, "closeGuideStartUI 扑克新手引导配置错误，key = " .. _key)
    print(" -----------------1 closeGuideStartUI _key = ", _key)
    self:doStepOverCallFunc(_key, "start")
end

function PokerGuideMgr:stopGuide(_key, _stopOverCall)
    print(" -----------------0 stopGuide _key = ", _key)
    local cfg = self:getGuideConfig(_key)

    if _stopOverCall then
        self:setStepOverCallFunc(_key, "stop", _stopOverCall)
    end

    if cfg.overRecord then
        self:setUserDefaultStepId(cfg.overRecord)
    end

    local dynamicProgress = nil
    if cfg.dynamic then
        dynamicProgress = cfg.dynamic.cur
    end
    self:setGuideStopping(true)
    print(" -----------------1 stopGuide _key = ", _key)
    self.m_stepUI:hideLayout(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_GUIDE_OVER, {refName = self:getRefName(), stepKey = _key, dynamic = dynamicProgress})
        end
    )
    return true
end

function PokerGuideMgr:closeGuideStopUI(_key)
    print(" ----------------- closeGuideStopUI 1 ", _key)
    local cfg = self:getGuideConfig(_key)
    if not cfg then
        return
    end
    assert(cfg ~= nil, "closeGuideStopUI 扑克新手引导配置错误，key = " .. _key)
    self.m_stepUI:closeUI(
        function()
            print(" ----------------- closeGuideStopUI 2 ", _key)
            self.m_stepUI = nil
            self:setGuiding(false)
            self:setGuideStopping(false)
            -- dynamic
            if cfg.dynamic and cfg.dynamic.cur < cfg.dynamic.max then
                -- 放在下一帧中执行，等PokerGuideUI被移除后再开始下一个引导
                util_nextFrameFunc(
                    function()
                        self:startGuide(_key)
                    end
                )
            else
                -- 执行回调方法
                self:doStepOverCallFunc(_key, "stop")
                -- 结束当前引导直接开始下一个引导
                if cfg.nextId then
                    local _cfg = self.GUIDE_CFG[cfg.nextId]
                    -- 放在下一帧中执行，等PokerGuideUI被移除后再开始下一个引导
                    util_nextFrameFunc(
                        function()
                            self:startGuide(_cfg.key)
                        end
                    )
                end
            end
        end
    )
end

return PokerGuideMgr
