local XmasCraze2023Net = require("activities.Activity_XmasCraze2023.net.XmasCraze2023Net")
local XmasCraze2023Mgr = class(" XmasCraze2023Mgr", BaseActivityControl)

-- 构造函数
function XmasCraze2023Mgr:ctor()
    XmasCraze2023Mgr.super.ctor(self)

    self.m_XmasCraze2023Net = XmasCraze2023Net:getInstance()
    self.payFlag = false
    self:setRefName(ACTIVITY_REF.XmasCraze2023)

    self.awardPoolAmount = toLongNumber(0)
    
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateAwardPoolAmount()
        end,
        ViewEventType.NOTIFY_XMASCRAZE2023_OPEN
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)

            self:stopSchedule()
            self:updateAwardPoolAmount()
            
        end,
        ViewEventType.NOTIFY_XMASCRAZE2023_REFRESH
    )
end

function XmasCraze2023Mgr:requestNewData()
    self.m_XmasCraze2023Net:requestNewData()
end

function XmasCraze2023Mgr:getRandom1to5()
    local random = math.random(1, 5)
    return toLongNumber(random)
end

-- 三格同步(轮播，广告，弹板 三个定时器同步数据)
function XmasCraze2023Mgr:updateAwardPoolAmount()
    local a = self:isRunning()
    local _data = self:getRunningData()
    if not _data then
        self:stopSchedule()
        return
    end
    self.keyExpireAt = self:getExpireAt()
    local Time = 0
    local setPercent = function ()
        local data = self:getRunningData()
        if not data then
            self:stopSchedule()
            return
        end
        local second = 180 -- 服务器三分钟定时任务，每隔180秒要去请求一下数据
        local keyStr = "Activity_XmasCraze2023_" .. self.keyExpireAt

        local maxCoins = toLongNumber(data:getRewardPoll()) or toLongNumber(0)
        local baseCoins = toLongNumber(data:getPreRewardPoll()) or toLongNumber(0)
        local addPercent = toLongNumber((maxCoins - baseCoins) / second) or toLongNumber(0)

        local localCoins = toLongNumber(gLobalDataManager:getStringByField(keyStr, baseCoins))
        if localCoins > baseCoins then
            baseCoins = localCoins
        end

        local random = self:getRandom1to5() --toLongNumber(gLobalDataManager:getNumberByField(keyStr .. "Random", 1))
        if random > addPercent then
            random = 0
        end

        -- if baseCoins >= maxCoins then
        if Time >= second then
            if maxCoins ~= toLongNumber("0") then
                self:requestNewData()
                gLobalDataManager:setStringByField(keyStr, "" .. 0)
                Time = 0
            else
                self:stopSchedule()
            end
        else
            baseCoins:setNum(baseCoins + addPercent - random)

            -- local temp = LongNumber.rounding( baseCoins )
            -- self.awardPoolAmount:setNum(temp)
            self.awardPoolAmount:setNum(baseCoins)

            gLobalDataManager:setStringByField(keyStr, "" .. baseCoins)
            -- local random1to5 = self:getRandom1to5()
            -- gLobalDataManager:setNumberByField(keyStr .. "Random", random1to5)
        end
        Time = Time + 1      
    end
    setPercent()
    if not self.m_autoSchedule then
        self.m_autoSchedule = scheduler.scheduleGlobal(setPercent,1)
    end
end

function XmasCraze2023Mgr:stopSchedule()
    if self.m_autoSchedule ~= nil then
        scheduler.unscheduleGlobal(self.m_autoSchedule)
        self.m_autoSchedule = nil
    end
end

function XmasCraze2023Mgr:getAwardPoolAmount()
    return self.awardPoolAmount
end

function XmasCraze2023Mgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function XmasCraze2023Mgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function XmasCraze2023Mgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function XmasCraze2023Mgr:showMainLayer(autoPop, _overcall)
    if not self:isCanShowLayer() then
        return nil
    end

    local data = self:getRunningData()
    local isPaid
    if data then
        isPaid = data:isPaid()
    end

    if autoPop and self.payFlag then
        return nil
    else
        self.payFlag = true
    end

    local refName = self:getRefName()
    local themeName = self:getThemeName(refName)
    local uiView = util_createView(themeName .. "/" .. themeName, autoPop, _overcall)
    if uiView then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

function XmasCraze2023Mgr:getExpireAt()
    local data = self:getData()
    if data then
        return data:getExpireAt()
    end
end

function XmasCraze2023Mgr:onEnter()
    -- self:updateAwardPoolAmount()
    
end

return XmasCraze2023Mgr
