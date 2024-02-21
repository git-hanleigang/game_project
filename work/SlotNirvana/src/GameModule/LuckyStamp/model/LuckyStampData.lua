--[[
    网络数据解析
]]
local LuckyStampProcessData = util_require("GameModule.LuckyStamp.model.LuckyStampProcessData")
local BaseGameModel = require("GameBase.BaseGameModel")
local LuckyStampData = class("LuckyStampData", BaseGameModel)

function LuckyStampData:ctor()
    LuckyStampData.super.ctor(self)
    self:setRefName(G_REF.LuckyStamp)
    self.m_showExpireAt = nil
end

-- message LuckyStampV2 {
--     optional int32 total = 1; //戳总数
--     optional int64 expireAt = 2; //截止时间，时间戳
--     optional int64 expire = 3; //剩余时间，毫秒
--     optional string goldenPrice = 4; //金戳起始价格
--     repeated LuckyStampProcess processList = 5; //戳进度
--     optional int32 goldenIndex = 6; //金宝箱初始位置
--     optional LuckyStampProcess afterWinProcess = 7; //中奖后process
--   }
function LuckyStampData:parseData(_netData, _isLogon, _isPay)
    self.p_total = _netData.total
    self.p_expireAt = tonumber(_netData.expireAt)
    self.p_expire = tonumber(_netData.expire)
    self.p_goldenPrice = _netData.goldenPrice
    self.p_processList = {}
    if _netData.processList and #_netData.processList > 0 then
        for i = 1, #_netData.processList do
            local stampData = LuckyStampProcessData:create()
            stampData:parseData(_netData.processList[i])
            table.insert(self.p_processList, stampData)
        end
    end
    self.p_goldenIndex = _netData.goldenIndex

    self.p_afterWinProcess = nil
    if _netData.afterWinProcess then
        local stampData = LuckyStampProcessData:create()
        stampData:parseData(_netData.afterWinProcess)
        self.p_afterWinProcess = stampData
    end

    if _isLogon == true then
        self:initCacheProcessIndex()
    end
    self:startTimer()
end

function LuckyStampData:initCacheProcessIndex()
    local stampLen = #self.p_processList
    if stampLen == 0 then
        -- 过期后服务器清空了列表
        -- 或者刚上线初始化
        -- 或者上次付费正好盖满4个戳一个不多
        self:setProcessIndex(0)
        local cacheIndex = self:getLocalCacheProcess()
        if cacheIndex ~= 0 then
            self:setLocalCacheProcess(0)
        end
    else
        local cacheIndex = self:getLocalCacheProcess()
        if cacheIndex == -1 then -- 本地缓存数据被清除了
            if stampLen < self.p_total then
                self:setProcessIndex(stampLen)
                self:setLocalCacheProcess(stampLen)
            else
                -- 小游戏一定是没完成，没抽奖或者没领奖【领奖后，服务器删除1234戳数据】
                self:setProcessIndex(self.p_total)
                self:setLocalCacheProcess(self.p_total)
            end
        elseif cacheIndex >= 0 then
            if cacheIndex == stampLen then -- 什么不需要做、
                self:setProcessIndex(cacheIndex)
            elseif cacheIndex < stampLen then -- 断线重连
                self:setProcessIndex(cacheIndex)
            elseif cacheIndex > stampLen then -- 本地缓存的数据比服务器给的数据长度还大，缓存数据出错了，强制
                self:setProcessIndex(stampLen)
                self:setLocalCacheProcess(stampLen)
            end
        end
    end
end

function LuckyStampData:setProcessIndex(_index)
    self.m_processIndex = _index
end

function LuckyStampData:getProcessIndex()
    return self.m_processIndex
end

-- 到期清空数据
function LuckyStampData:resetData()
    self:setProcessIndex(0)
    self:setLocalCacheProcess(0)
    self.p_expireAt = -1
    self.p_expire = -1
    self.p_processList = {}
    self.p_winIndex = -1
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATA_LUCKYSTAMP)
end

function LuckyStampData:onRegister()
end

function LuckyStampData:getTotal()
    return self.p_total
end

function LuckyStampData:getExpireAt()
    return self.p_expireAt or 0
end

function LuckyStampData:getExpire()
    return self.p_expire or 0
end

function LuckyStampData:getGoldenPrice()
    return self.p_goldenPrice
end

function LuckyStampData:getProcessList()
    return self.p_processList
end

-- 从0开始
function LuckyStampData:getGoldenIndex()
    return self.p_goldenIndex + 1
end

-- 只有盖第一个戳时会用到这个数据
function LuckyStampData:getAfterWinProcess()
    return self.p_afterWinProcess
end

--[[------------美丽的分割线--------------------------------------------------------------------
    以下都是扩展方法
]]
-- 0-4
function LuckyStampData:getLocalCacheProcess()
    local index = gLobalDataManager:getNumberByField("LuckyStamp_Process_" .. globalData.userRunData.uid, -1)
    return index
end

-- _cacheProcess: 0-4
function LuckyStampData:setLocalCacheProcess(_cacheProcess)
    if _cacheProcess ~= nil then
        gLobalDataManager:setNumberByField("LuckyStamp_Process_" .. globalData.userRunData.uid, _cacheProcess)
    end
end

function LuckyStampData:getProcessList()
    return self.p_processList
end

function LuckyStampData:getProcessDataByPos(_pos)
    if DEBUG == 2 then
        assert(_pos <= self.p_total, "getProcessDataByPos _pos is error!!!" .. _pos)
    end
    if self.p_processList and #self.p_processList > 0 then
        for i = 1, #self.p_processList do
            local processData = self.p_processList[i]
            if processData:getIndex() == _pos then
                return processData
            end
        end
    end
    return nil
end

function LuckyStampData:getProcessDataByIndex(_index)
    if _index and _index > 0 and #self.p_processList >= _index then
        return self.p_processList[_index]
    end
    return nil
end

function LuckyStampData:getCurProcessData(_isInit)
    local processIdx = self:getProcessIndex()
    if _isInit and processIdx == 0 then
        return self.p_afterWinProcess
    end
    return self:getProcessDataByIndex(processIdx)
end

-- 获取本次盖金戳时新增的金格子位置
-- 此时，processIdx已经加1了，当前process就是processIdx，如果processIdx==1，pre 就取 p_afterWinProcess
function LuckyStampData:getNewGoldenLatticeIndex()
    local curProcessData = nil
    local preProcessData = nil
    local processIdx = self:getProcessIndex() or 0
    if processIdx == 1 then
        preProcessData = self:getAfterWinProcess()
        curProcessData = self:getProcessDataByIndex(processIdx)
    else
        preProcessData = self:getProcessDataByIndex(processIdx - 1)
        curProcessData = self:getProcessDataByIndex(processIdx)
    end
    -- 当前次是金戳
    if curProcessData:getStampType() == LuckyStampCfg.StampType.Normal then
        return nil
    end
    -- 获取进度的格子数据
    local preLatticeList = preProcessData and preProcessData:getGoldenLatticeList() or {}
    local curLatticeList = curProcessData:getGoldenLatticeList()
    print("getNewGoldenLatticeIndex preLatticeList = ", table.concat(preLatticeList, "-"))
    print("getNewGoldenLatticeIndex curLatticeList = ", table.concat(curLatticeList, "-"))
    -- 比较
    if #curLatticeList > #preLatticeList then
        local defaultGoldenIndex = self:getGoldenIndex()
        for i = 1, #curLatticeList do
            if curLatticeList[i] ~= defaultGoldenIndex then
                local isSame = false
                for j = 1, #preLatticeList do
                    if curLatticeList[i] == preLatticeList[j] then
                        isSame = true
                        break
                    end
                end
                if isSame == false then
                    return curLatticeList[i]
                end
            end
        end
    end
    return nil
end

--[[--------------------------------------------------------------]]
function LuckyStampData:getAllNeedStamp()
    local normalStamp = 0
    local goldenStamp = 0
    local processLen = #self.p_processList
    if processLen > 0 then
        local processIdx = self:getProcessIndex() or 0
        if processIdx < processLen then
            for i = 1, processLen do
                if i > processIdx then
                    local stampType = self.p_processList[i]:getStampType()
                    if stampType == LuckyStampCfg.StampType.Golden then
                        goldenStamp = goldenStamp + 1
                    else
                        normalStamp = normalStamp + 1
                    end
                end
            end
        end
    end
    return normalStamp, goldenStamp
end

function LuckyStampData:getNeedStampNum()
    local processLen = #self.p_processList
    local processIdx = self:getProcessIndex()
    if processIdx == nil then
        return processLen
    elseif processIdx >= 0 then
        if processIdx == processLen then
            return 0
        elseif processIdx < processLen then
            if processIdx == self.p_total then
                return 0
            else
                return processLen - processIdx
            end
        else
            if DEBUG == 2 then
                assert(false, "数据错误了，请程序检查逻辑")
            end
            return 0
        end
    end
    return 0
end

-- 所有即将盖的戳是否有小游戏
function LuckyStampData:isHaveGameComing()
    local processIdx = self:getProcessIndex() or 0
    if self.p_processList and #self.p_processList > 0 then
        for i = 1, #self.p_processList do
            if i >= processIdx then
                local processData = self.p_processList[i]
                if processData:isHaveGame() then
                    return true
                end
            end
        end
    end
    return false
end

--[[--------------------------------------------------------------]]
function LuckyStampData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() / 1000 - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

-- 如果激活了小游戏，并且没有抽奖，断线重连
-- 如果激活了小游戏，抽奖了，但是没有领奖，断线重连
function LuckyStampData:checkReconnect()
    local processIdx = self:getProcessIndex()
    if processIdx < #self.p_processList then
        return true
    end
    local curProcessData = self:getCurProcessData()
    if curProcessData then
        return curProcessData:checkReconnect()
    end
    return false
end

function LuckyStampData:startTimer()
    if self.p_expireAt == nil or self.p_expireAt == -1 then
        self:stopTimer()
        return
    end
    if not self.m_showExpireAt then
        self.m_showExpireAt = self.p_expireAt
    else
        if self.m_showExpireAt == self.p_expireAt then
            return
        end
    end
    self:stopTimer()
    self.m_sche =
        scheduler.scheduleGlobal(
        function()
            local leftTime = self:getLeftTime()
            local curProcessData = self:getCurProcessData()
            -- if leftTime ~= nil and leftTime <= 0 and not (curProcessData and curProcessData:isHaveGame()) then
            if leftTime ~= nil and leftTime <= 0 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFI_LUCKYSTAMP_TIMEOUT)
                self:resetData()
                self:stopTimer()
                return
            end
        end,
        1
    )
end

function LuckyStampData:stopTimer()
    if self.m_sche ~= nil then
        scheduler.unscheduleGlobal(self.m_sche)
        self.m_sche = nil
    end
end

function LuckyStampData:isGoldenStamp(_price)
    if _price ~= nil and tonumber(_price) ~= nil then
        local goldenPrice = self:getGoldenPrice()
        if goldenPrice ~= nil and tonumber(goldenPrice) ~= nil then
            if tonumber(_price) >= tonumber(goldenPrice) then
                return true
            end
        end
    end
    return false
end

return LuckyStampData
