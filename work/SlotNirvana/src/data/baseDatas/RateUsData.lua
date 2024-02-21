--引导评价
local RateUsData = class("RateUsData")
RateUsData.p_openLevel = nil --开启等级
RateUsData.p_spinCount = nil --spin次数限制
RateUsData.p_spanTime = nil --间隔时间
RateUsData.p_maxCount = nil --最大次数
RateUsData.p_closeTime = nil --关闭延时

RateUsData.m_version = nil
RateUsData.m_isRateUs = nil --是否评价过
RateUsData.m_currentSpinNum = nil --本次游戏spin次数
RateUsData.m_lastRateUsTime = nil --上次评价时间
RateUsData.m_rateUsCount = nil --当前评价过的次数
RateUsData.m_isgetReward = nil --是否领取过奖励
RateUsData.m_isFirstOpen = nil --是不是第一次打开

RateUsData.IOS_APPURL = "itms-apps://itunes.apple.com/app/id1480805172?action=write-review"

function RateUsData:ctor()
    --设置默认值
    self.m_currentSpinNum = 0
    self.m_bankruptcyNoPayNum = 0
    self.p_openLevel = 20
    self.p_spinCount = 200
    self.p_spanTime = 86400
    self.p_maxCount = 3
    self.p_closeTime = 0.5
    self.m_isRateUs = false
    self.m_isgetReward = false
    self.m_isFirstOpen = true
    self.m_version = nil
end

-- csc 2021-12-20 新的解析方式
function RateUsData:parseData(_data)
    if not _data then
        return
    end
    self.p_openLevel = tonumber(_data.openLevel) or self.p_openLevel
    self.p_spinCount = tonumber(_data.spinCount) or self.p_spinCount
    self.p_spanTime = tonumber(_data.spanTime) or self.p_spanTime
    self.p_maxCount = tonumber(_data.maxCount) or self.p_maxCount

    -- 常量配置的 开启等级
    if globalData.constantData.RATE_US_LAYER_OPEN_LEVEL then
        self.p_openLevel = globalData.constantData.RATE_US_LAYER_OPEN_LEVEL or self.p_openLevel
    end

    -- 11.30号 临时上线常量更改 等级，次数, cd 2023年11月28日16:44:21
    self._bUseCdControl = false -- 是否使用CD调控
    if globalData.constantData.RATE_US_LAYER_CD_CONFIG_OPEN and string.find(globalData.constantData.RATE_US_LAYER_SPAN_TIME or "", "-") then
        self._spanTimeCDList = {}
        self._spinLimitCountList = {}
        self._rateusCountList = {}

        -- 分ab test了 数值配novice常量表了
        if string.find(globalData.constantData.RATE_US_LAYER_SPAN_TIME or "", "-") then
            -- rateus弹板 间隔cd时间 list
            self._spanTimeCDList = string.split(globalData.constantData.RATE_US_LAYER_SPAN_TIME, "-")
        end
        if string.find(globalData.constantData.RATE_US_LAYER_MAX_COUNT or "", "-") then
            -- rateus弹板 最大弹出次数
            self._rateusCountList = string.split(globalData.constantData.RATE_US_LAYER_MAX_COUNT, "-")
        end
        if string.find(globalData.constantData.RATE_US_LAYER_SPIN_COUNT or "", "-") then
            -- rateus弹板 spin次数区间
            self._spinLimitCountList = string.split(globalData.constantData.RATE_US_LAYER_SPIN_COUNT, "-")
        end

        if #self._spanTimeCDList == 0 or #self._spanTimeCDList ~= #self._spinLimitCountList or #self._spinLimitCountList ~= #self._rateusCountList then
            self._spanTimeCDList = {}
            self._spinLimitCountList = {}
            self._rateusCountList = {}
        else
            self._bUseCdControl = true
        end

    else
        -- 分ab test了 数值配novice常量表了
        if globalData.constantData.RATE_US_LAYER_SPAN_TIME then
            -- rateus弹板 间隔cd时间
            self.p_spanTime = tonumber(globalData.constantData.RATE_US_LAYER_SPAN_TIME) or self.p_spanTime
        end
        if globalData.constantData.RATE_US_LAYER_MAX_COUNT then
            -- rateus弹板 最大弹出次数
            self.p_maxCount = tonumber(globalData.constantData.RATE_US_LAYER_MAX_COUNT) or self.p_maxCount
        end
        if globalData.constantData.RATE_US_LAYER_SPIN_COUNT then
            -- rateus弹板 spin次数区间
            self.p_spinCount = tonumber(globalData.constantData.RATE_US_LAYER_SPIN_COUNT) or self.p_spinCount
        end
    end
end

--上次评价时间
function RateUsData:setLastTime(time)
    self.m_lastRateUsTime = time
end
--当前弹出评价的次数
function RateUsData:setRateUsCount(count)
    self.m_rateUsCount = count
end
function RateUsData:getRateUsCount(count)
    return self.m_rateUsCount or 0
end

--是否评价过
function RateUsData:setRateUs(flag)
    self.m_isRateUs = flag
end
function RateUsData:checkIsRateUs()
    return self.m_isRateUs or false
end
--是否评价过
function RateUsData:setRateUsVersion(version)
    self.m_version = version
end
--增加spin次数统计
function RateUsData:addSpinCount()
    self.m_currentSpinNum = self.m_currentSpinNum + 1
end
function RateUsData:getSpinCount()
    return self.m_currentSpinNum or 0
end
function RateUsData:resetSpinCount()
    self.m_currentSpinNum = 0
end
--增加破产未付费次数统计（登录从头来，付过费重置掉）
function RateUsData:addBankruptcyNoPayCount()
    self.m_bankruptcyNoPayNum = self.m_bankruptcyNoPayNum + 1
end
function RateUsData:getBankruptcyNoPayCount()
    return self.m_bankruptcyNoPayNum or 0
end
function RateUsData:resetBankruptcyNoPayCount()
    self.m_bankruptcyNoPayNum = 0
end

--是否评价过
function RateUsData:setRateUsGetReward(reward)
    self.m_isgetReward = reward
end

function RateUsData:checkOpenRateUs()
    -- if globalData.constantData.RATEUS_SWITCH ~= nil and globalData.constantData.RATEUS_SWITCH == 0 and device.platform == "ios" then
    -- cxc 2021-10-15 17:13:14 Android上线审核屏蔽
    if globalData.constantData.RATEUS_SWITCH then
        -- 0： 都不打开
        -- 1： ios打开
        -- 2： 安卓打开
        -- 3： 都打开
        if globalData.constantData.RATEUS_SWITCH == 0 then
            return false
        elseif globalData.constantData.RATEUS_SWITCH == 1 and device.platform ~= "ios" then
            return false
        elseif globalData.constantData.RATEUS_SWITCH == 2 and device.platform ~= "android" then
            return false
        end
    end

    if self.m_isRateUs then
        --已经评价过
        return false
    end

    local levelNum = globalData.userRunData.levelNum or 1
    if levelNum < self.p_openLevel then
        --未到开启等级
        return false
    end
    local count = self.m_rateUsCount or 0
    if self._bUseCdControl then
        -- cd调控
        -- 第1次：30级以上，Spin50次以上，BigWin1次，CD48小时
        -- 第2-4次：Spin100次以上，BigWin1次，CD48小时
        -- 第5-999次：Spin150次以上，MegaWin2次，CD168小时
        local idx = 1
        for i=1, #self._rateusCountList do --{1, 4, 99999}
            local limitCount = self._rateusCountList[i] - 1
            if count <= limitCount then
                idx = i
                break
            end
        end
        self.p_spinCount = tonumber(self._spinLimitCountList[idx]) or self.p_spinCount
        self.p_spanTime = tonumber(self._spanTimeCDList[idx]) or self.p_spanTime
    else
        if count >= self.p_maxCount then
            --次数上限
            return false
        end
    end
    local time = os.time()
    if self.m_lastRateUsTime and time - self.m_lastRateUsTime < self.p_spanTime then
        --弹版冷却中
        return false
    end
    if self.m_currentSpinNum < self.p_spinCount then
        --spin次数不足
        return false
    end

    return true
end

function RateUsData:openRateUsView(func, site, bNotShowRate, startRootPos)
    if bNotShowRate then
        if device.platform == "ios" then 
            self:iOSOpenRateUsViewV2(site)
        elseif device.platform == "android" then 
            xcyy.GameBridgeLua:rateUsForSetting()
        end
    else
        if site ~= "RateUs" then
            -- 设置处 rateUs玩家主动打开 不计数 cxc2023年11月28日16:43:53
            self.m_lastRateUsTime = os.time()
            if not self.m_rateUsCount then
                self.m_rateUsCount = 0
            end
            self.m_rateUsCount = self.m_rateUsCount + 1
            self.m_currentSpinNum = 0 -- 弹rateUs弹板 清除记录的 spin次数
            self:sendNetWork()
        end

        local view = util_createView("views.rateUs.RateusLayer", site, false)
        if startRootPos then
            view:setActionType("Curve", startRootPos)
        end
        view:setOverFunc(func)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

--尝试发送评价过的消息
function RateUsData:checkNetWork()
    -- if self.m_isRateUs then
    --     return
    -- end
    -- self.m_isRateUs = true
    self:sendNetWork()
end
--发送服务器
function RateUsData:sendNetWork()
    --发送日志
    local data = {}
    data[1] = self.m_lastRateUsTime
    data[2] = self.m_rateUsCount
    data[3] = self.m_isRateUs
    data[4] = self.m_version
    data[5] = self.m_isgetReward
    data[6] = self.m_isFirstOpen
    gLobalSendDataManager:getNetWorkFeature():sendRateUsData(data)
end

--[[
    初始化rateus数据  并兼容老数据
]]
function RateUsData:initRateUsData(rateUsData)
    local lastTime = 0
    local rateUsCount = 0
    local isRateUs = false
    local isGetReward = false
    local isFirstOpen = true
    local version = util_getAppVersionCode()
    local isSyn = true
    if rateUsData and #rateUsData == 6 then
        -- if version == rateUsData[4] then
        lastTime = rateUsData[1]
        rateUsCount = rateUsData[2]
        isRateUs = rateUsData[3]
        isGetReward = rateUsData[5]
        isFirstOpen = rateUsData[6]
        isSyn = false
    -- end
    end
    --上次评价时间
    self:setLastTime(lastTime)
    --当前评价过的次数
    self:setRateUsCount(rateUsCount)
    --是否评价过
    self:setRateUs(isRateUs)
    --上次评价的版本
    self:setRateUsVersion(version)

    self:setRateUsGetReward(isGetReward)

    self.m_isFirstOpen = isFirstOpen
    if isSyn then
        --同步到服务器
        self:sendNetWork()
    end
end

--[[
    @desc: 新版的ios 打开评论页逻辑
    author:{author}
    time:2022-02-21 17:53:53
    @return:
]]
function RateUsData:iOSOpenRateUsViewV2(_site)
    if _site == "RateUs" then
        -- 设置 点位主动触发 跳转商城 不浪费 应用内评分次数
        cc.Application:getInstance():openURL(self.IOS_APPURL)
        return
    end

    local lastTime = gLobalDataManager:getNumberByField("iOSRateUsLastTime", 0)
    local subTime = os.time() - lastTime
    if subTime < 30 * 24* 3600 then -- iOS也加一个 30天CD 检测
        cc.Application:getInstance():openURL(self.IOS_APPURL)
        return
    end
    
    -- ios应用内评分弹板 一年三次机会
    local key = string.format("iOSRateUsCount_%s", os.date("%Y")) 
    local iosRateUsCount = gLobalDataManager:getNumberByField(key, 0)
    if iosRateUsCount == 0 then
        local bHadPop = gLobalDataManager:getBoolByField("checkOpenRequestViewIos", false)
        if bHadPop then
            iosRateUsCount = iosRateUsCount + 1
        end
    end
    if iosRateUsCount < 3 then
        -- https://developer.apple.com/documentation/storekit/requesting_app_store_reviews?language=objc
        -- Be aware that the system displays the review prompt to a user a maximum of three times within a 365-day period
        gLobalDataManager:setNumberByField(key, iosRateUsCount+1)

        if gLobalSendDataManager.getLogScore then
            gLobalSendDataManager:getLogScore():sendScoreLog("ViewOpen", _site, "iOSRateUs", 0)
        end
        globalPlatformManager:openRateUSDialog()
        gLobalDataManager:setNumberByField("iOSRateUsLastTime", os.time())
    else
        cc.Application:getInstance():openURL(self.IOS_APPURL)
    end
end

-- 应用内 评价 android
function RateUsData:androidOpenRateUsViewV2(_site)
    -- if true then
    --     -- cxc 2023年12月11日18:22:07 安卓先不开放应用内评分功能
    --     xcyy.GameBridgeLua:rateUsForSetting()
    --     return
    -- end
    if _site == "RateUs" then
        -- 设置 点位主动触发 跳转商城 不浪费 应用内评分 限额
        xcyy.GameBridgeLua:rateUsForSetting()
        return
    end

    if MARKETSEL == AMAZON_MARKET or (not util_isSupportVersion("1.9.5", "android")) then
        -- 亚马逊平台 或者 google就不支持应用内评价 直接跳 商店
        xcyy.GameBridgeLua:rateUsForSetting()
        return
    end

    local lastTime = gLobalDataManager:getNumberByField("androidRateUsLastTime", 0)
    local subTime = os.time() - lastTime
    if subTime < 30 * 24* 3600 then
        -- https://developer.android.com/guide/playcore/in-app-review?hl=zh-cn
        -- 为了提供优质用户体验，Google Play 会强制执行一个限时配额，用于规定系统向用户显示评价对话框的频率。由于存在此配额，在短时间内（例如，不到一个月内）多次调用 launchReviewFlow 方法时可能不会始终显示对话框
        -- android 应用内评价至少要 1个月cd  cd不足跳商店
        xcyy.GameBridgeLua:rateUsForSetting()
        return
    end

    gLobalDataManager:setNumberByField("androidRateUsLastTime", os.time())
    if gLobalSendDataManager.getLogScore then
        gLobalSendDataManager:getLogScore():sendScoreLog("ViewOpen", _site, "AndroidRateUs", 0)
    end
    globalPlatformManager:openRateUSDialog()
end

return RateUsData
