--[[
    Flamingo jackpot网络数据解析
]]

local FlamingoJackpotWheelData = import(".FlamingoJackpotWheelData")
local FlamingoJackpotPoolData = import(".FlamingoJackpotPoolData")
local BaseActivityData = require "baseActivity.BaseActivityData"
local FlamingoJackpotData = class("FlamingoJackpotData", BaseActivityData)

function FlamingoJackpotData:ctor()
    FlamingoJackpotData.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FlamingoJackpot)
end

-- message FlamingoJackpot {
--     optional string activityId = 1;
--     optional int32 expire = 2;
--     optional int64 expireAt = 3;
--     optional int64 miniJackpot = 4;
--     optional int64 minorJackpot = 5;
--     optional int64 grandJackpot = 6;
--     optional int64 superJackpot = 7;
--     optional int64 miniJackpotOffset = 8;
--     optional int64 minorJackpotOffset = 9;
--     optional int64 grandJackpotOffset = 10;
--     optional int64 superJackpotOffset = 11;
--     optional string extraBetPercent = 12; // 关卡额外消耗bet百分比
--     repeated string gameIds = 13; //生效关卡
--     optional int32 currentProcess = 14; //进度条
--     optional int32 totalProcess = 15; //总进度条
--     optional bool doubleBuff = 16;//  最后一天buff
--     optional int64 minValidBet = 17; // spin生效的最小bet
--     optional int64 superValidBet = 18; // 中super的最小bet    
--   }
function FlamingoJackpotData:parseData(_netData)
    FlamingoJackpotData.super.parseData(self, _netData) 

    self.p_extraBetPercent = tonumber(_netData.extraBetPercent)
    
    self.p_gameIds = {}
    if _netData.gameIds and #_netData.gameIds > 0 then
        for i=1,#_netData.gameIds do
            table.insert(self.p_gameIds, tonumber(_netData.gameIds[i]))
        end
    end
    
    self.p_currentProcess = _netData.currentProcess
    self.p_totalProcess = _netData.totalProcess
    self.p_doubleBuff = _netData.doubleBuff

    self.p_minValidBet = tonumber(_netData.minValidBet)
    self.p_superValidBet = tonumber(_netData.superValidBet)

    -- 解析jackpot
    self:parseJackpotData(_netData)   
end

-- "spin":{
--     "miniJackpot":100000,
--     "minorJackpot":100000,
--     "grandJackpot":100000,
--     "superJackpot":100000,
--     "miniJackpotOffset":1000,
--     "minorJackpotOffset":1000,
--     "grandJackpotOffset":1000,
--     "superJackpotOffset":1000,
--     "addProcess":77777,
--     "activeSlot":true, //是否激活老虎机
--     "reelResult":[1,1,0],
--     "winAmount":121212, //老虎机赢钱
--     "activeWheel":true,
--     "wheelPos":[1,2,3],
--     "jackpotWinCoins":213123,
--     "wheelConfig":[[{"pos":0, "type":"Mini", "coins":123123123}], [], [], [], ...],
--     "doubleBuff":true
-- }

function FlamingoJackpotData:parseSpinData(_netData)

    self.p_doubleBuff = _netData.doubleBuff == true

    -- 以下是只有spin时才发送的数据，触发了哪个字段，服务器下发哪个字段
    -- 客户端自己处理清空，每次spin激活是在玩法结束后清空激活的参数
    self.p_addProcess = tonumber(_netData.addProcess or 0)

    -- 客户端同步当前进度
    if _netData.currentProcess ~= nil then
        self.p_currentProcess = _netData.currentProcess
    end
    -- if self.p_addProcess > 0 then
    --     self:addCurrentProcess(self.p_addProcess)
    -- end

    self.p_activeSlot = _netData.activeSlot == true

    self.p_reelResult = {}
    if _netData.reelResult and #_netData.reelResult > 0 then
        for i=1,#_netData.reelResult do
            table.insert(self.p_reelResult, tonumber(_netData.reelResult[i] or 0))
        end
    end

    self.p_winAmount = tonumber(_netData.winAmount or 0)
    self.p_activeWheel = _netData.activeWheel == true

    --轮盘相关
    if not self.p_wheelData then
        self.p_wheelData = FlamingoJackpotWheelData:create()
    end
    if _netData.wheelPos and #_netData.wheelPos > 0 then
        self.p_wheelData:setHitPos(_netData.wheelPos)
    end
    self.p_wheelData:setWheelWinCoins(tonumber(_netData.jackpotWinCoins or 0))
    if _netData.wheelConfig then
        self.p_wheelData:setWheelConfig(_netData.wheelConfig)
    end

    -- 解析jackpot
    self:parseJackpotData(_netData, self.p_activeWheel)
end

-- -- 每次spin触发玩法后都要清理掉触发的几个参数
-- function FlamingoJackpotData:clearSpinActiveData()
--     self.p_addProcess = 0
--     self.p_activeSlot = false
--     self.p_winAmount = 0
--     self.p_activeWheel = falseh
-- end
--[[--
    每完成一步，清理一步的数据
    _clearType: 
        process:清理增加的进度条
        slot:清理激活的老虎机
        wheel:清理激活的轮盘
        如果不传参数，全清
]]
function FlamingoJackpotData:clearSpinTriggerData(_clearType)
    if _clearType == "process" then
        self.p_addProcess = 0
    elseif _clearType == "slot" then
        self.p_activeSlot = false
        self.p_winAmount = 0
    elseif _clearType == "wheel" then
        self.p_activeWheel = false
    else
        self.p_addProcess = 0
        self.p_activeSlot = false
        self.p_winAmount = 0
        self.p_activeWheel = false
    end
end

-- 解析jackpot
-- 延迟同步的需求
function FlamingoJackpotData:parseJackpotData(_netData, _isDelaySync)

    -- local intervalFrameTime = FlamingoJackpotCfg.JACKPOT_FRAME -- 客户端的每次变化时间间隔

    -- self.p_miniJackpot = tonumber(_netData.miniJackpot or 0)
    -- self.p_minorJackpot = tonumber(_netData.minorJackpot or 0)
    -- self.p_grandJackpot = tonumber(_netData.grandJackpot or 0)
    -- self.p_superJackpot = tonumber(_netData.superJackpot or 0)

    -- local miniSecOffset = tonumber(_netData.miniJackpotOffset or 0) -- 每秒增加值【服务器是按秒计算的】
    -- self.p_miniJackpotOffset = math.floor(miniSecOffset * intervalFrameTime) -- 转换

    -- local minorSecOffset = tonumber(_netData.minorJackpotOffset or 0)
    -- self.p_minorJackpotOffset = math.floor(minorSecOffset * intervalFrameTime)

    -- local grandSecOffset = tonumber(_netData.grandJackpotOffset or 0)
    -- self.p_grandJackpotOffset = math.floor(grandSecOffset * intervalFrameTime)
    
    -- local superSecOffset = tonumber(_netData.superJackpotOffset or 0)
    -- self.p_superJackpotOffset = math.floor(superSecOffset * intervalFrameTime)


    self.p_miniJackpotData = self:createJackpotPoolData(FlamingoJackpotCfg.JackpotType.Mini, _netData.miniJackpot, _netData.miniJackpotOffset)
    self.p_minorJackpotData = self:createJackpotPoolData(FlamingoJackpotCfg.JackpotType.Minor, _netData.minorJackpot, _netData.minorJackpotOffset)
    self.p_grandJackpotData = self:createJackpotPoolData(FlamingoJackpotCfg.JackpotType.Grand, _netData.grandJackpot, _netData.grandJackpotOffset)
    self.p_superJackpotData = self:createJackpotPoolData(FlamingoJackpotCfg.JackpotType.Super, _netData.superJackpot, _netData.superJackpotOffset)
end

function FlamingoJackpotData:getJackpotDataByType(_type)
    if _type == FlamingoJackpotCfg.JackpotType.Mini then
        return self.p_miniJackpotData
    elseif _type == FlamingoJackpotCfg.JackpotType.Minor then
        return self.p_minorJackpotData
    elseif _type == FlamingoJackpotCfg.JackpotType.Grand then
        return self.p_grandJackpotData
    elseif _type == FlamingoJackpotCfg.JackpotType.Super then
        return self.p_superJackpotData
    end
    return nil
end

function FlamingoJackpotData:createJackpotPoolData(_jackpotType, _value, _offset)
    local netData = 
    {
        type = _jackpotType,
        value = _value,
        offset = _offset
    }
    local poolData = FlamingoJackpotPoolData:create()
    poolData:parseData(netData)
    return poolData
end

function FlamingoJackpotData:syncJackpotPoolData(_jackpotType)
    if _jackpotType ~= nil then
        local jackpotData = self:getJackpotDataByType(_jackpotType)
        if jackpotData then
            jackpotData:syncPoolData()
        end
    else
        self.p_miniJackpotData:syncPoolData()
        self.p_minorJackpotData:syncPoolData()
        self.p_grandJackpotData:syncPoolData()
        self.p_superJackpotData:syncPoolData()
    end
end

function FlamingoJackpotData:getExtraBetPercent()
    return self.p_extraBetPercent or 0
end

function FlamingoJackpotData:getGameIds()
    return self.p_gameIds
end

function FlamingoJackpotData:getCurrentProcess()
    return self.p_currentProcess or 0
end

-- function FlamingoJackpotData:addCurrentProcess(_addValue)
--     self.p_currentProcess = math.min((self.p_currentProcess or 0) + _addValue, self.p_totalProcess)
-- end

function FlamingoJackpotData:getTotalProcess()
    return self.p_totalProcess or 0
end

function FlamingoJackpotData:isDoubleBuff()
    return self.p_doubleBuff
end

function FlamingoJackpotData:getMinBet()
    return self.p_minValidBet
end

function FlamingoJackpotData:getSuperBet()
    return self.p_superValidBet
end

---------------------------------------------------
------------------以下数据是spin后同步来的------------
function FlamingoJackpotData:getAddProcess()
    return self.p_addProcess
end

function FlamingoJackpotData:isActiveSlot()
    return self.p_activeSlot
end

function FlamingoJackpotData:getReelResult()
    return self.p_reelResult
end

function FlamingoJackpotData:getWinAmount()
    return self.p_winAmount or 0
end

function FlamingoJackpotData:isActiveWheel()
    return self.p_activeWheel
end

function FlamingoJackpotData:getWheelData()
    return self.p_wheelData 
end

------------------------------------------------------
--------------------- 扩展方法 ------------------------

-- 判断关卡
function FlamingoJackpotData:checkLevelByLevelId(_levelId)
    if self.p_gameIds and #self.p_gameIds > 0 and _levelId then
        for i=1,#self.p_gameIds do
            if tonumber(_levelId) == self.p_gameIds[i] then
                return true
            end
        end
    end
    return false
end

function FlamingoJackpotData:isSlotPlayWinEffect()
    if self.p_reelResult and #self.p_reelResult > 0 then
        if self.p_reelResult[1] == FlamingoJackpotCfg.SlotSymbolType.Key then
            if self.p_reelResult[1] == self.p_reelResult[2] and self.p_reelResult[1] == self.p_reelResult[3] then
                return true
            end
        end
    end
    return false
end

return FlamingoJackpotData
