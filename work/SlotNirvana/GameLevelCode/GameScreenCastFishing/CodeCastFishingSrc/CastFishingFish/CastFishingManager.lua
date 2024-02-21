-- 处理数据和消息
local CastFishingManager = class("CastFishingManager")
local CastFishingSceneConfig = require "CodeCastFishingSrc.CastFishingFish.CastFishingSceneConfig"
local SendDataManager = require "network.SendDataManager"

CastFishingManager._instance = nil

CastFishingManager.StrMode = {
    Base = "base",
    Free = "free",
    Bonus = "bonus",
}
CastFishingManager.StrAttrKey = {
    Count     = "count",
    IntervalX = "intervalX",
    Speed     = "speed",
    Shape     = "shape",
}

function CastFishingManager:getInstance()
    if not self._instance then
		self._instance = CastFishingManager.new()
	end
	return self._instance
end
function CastFishingManager:removeInstance()
    gLobalNoticManager:removeAllObservers(self)
    CastFishingManager._instance = nil
end

function CastFishingManager:ctor()
    self:initData()
end

function CastFishingManager:initMachine(_machine)
    self.m_machine = _machine
end

function CastFishingManager:initData()
    --base、free、bonus 的鱼池
    self.m_baseFishData = {}
    self.m_freeFishData = {}
    self.m_bonusFishData = {}

    -- 所有场景下子弹的属性
    self.m_bulletAttr = {}
    -- 不同场景下鱼的属性
    self.m_sceneFishAttr = {}
    -- 是否显示形状
    self.m_bShowShape = false
    --请求状态
    self.m_isWaitData = false
end

function CastFishingManager:addObservers()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:castFishingResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

--[[
    更新数据
]]
function CastFishingManager:setFishSceneData(_extraData)
    local fnGetPoolData = function(_sPoolData)
        local poolData = {
            -- 总和,池子
            maxNumber = 0,
            pool      = {},
        }
        local poolList = string.split(_sPoolData, ";")
        for i,_sData in ipairs(poolList) do
            local splitList = string.split(_sData, "-")
            -- 倍数,概率
            local iMultip  = tonumber(splitList[1])
            local iProbability = tonumber(splitList[2])

            poolData.maxNumber = poolData.maxNumber + iProbability
            table.insert(poolData.pool, {iMultip, iProbability})
        end
        return poolData
    end
    self.m_baseFishData = fnGetPoolData(_extraData.baseFishCredit)
    self.m_freeFishData = fnGetPoolData(_extraData.freeFishCredit)
    self.m_bonusFishData = {}
    for i=1,99 do
        local sKey = string.format("row%d", i)
        if nil == _extraData.bonusFishCredit[sKey] then
            break
        end
        self.m_bonusFishData[i] = fnGetPoolData(_extraData.bonusFishCredit[sKey])
    end
end
function CastFishingManager:setBulletAttr(_extraData)
    self.m_bulletAttr = {}
    local bullet = _extraData.bullet or {}
    for _sId,_attrData in pairs(bullet) do
        local id = tonumber(_sId)
        self.m_bulletAttr[id] = _attrData
    end
end
function CastFishingManager:setSceneFishAttr(_extraData)
    self.m_sceneFishAttr = {}
    
    local freeScene = _extraData.freeScene or {}
    local freeData  = {}
    for _sId,_attrData in pairs(freeScene) do
        local id = tonumber(_sId)
        freeData[id] = _attrData
    end
    self.m_sceneFishAttr[self.StrMode.Free] = freeData

    local bonusScene = _extraData.bonusScene or {}
    local bonusData  = {}
    for _sId,_attrData in pairs(bonusScene) do
        local id = tonumber(_sId)
        bonusData[id] = _attrData
    end
    self.m_sceneFishAttr[self.StrMode.Bonus] = bonusData
end



--[[
    使用服务器数据
]]
function CastFishingManager:getFishPoolData(_params)
    local poolData = {}

    local sMode = _params.sMode
    if sMode == self.StrMode.Base then
        poolData = self.m_baseFishData
    elseif sMode == self.StrMode.Free then
        poolData = self.m_freeFishData
    elseif sMode == self.StrMode.Bonus then
        local index = _params.lineIndex
        poolData = self.m_bonusFishData[index]
    end

    return poolData
end
-- 优先使用服务器的子弹和鱼的数据
function CastFishingManager:getBulletAttr(_bulletId, _sKey, _default)
    local attrData = self.m_bulletAttr[_bulletId]
    local result   = nil ~= attrData[_sKey] and attrData[_sKey] or _default
    return result
end
function CastFishingManager:getSceneFishAttr(_sMode, _fishId, _sKey, _default)
    local sceneData = self.m_sceneFishAttr[_sMode] or {}
    local attrData = sceneData[_fishId] or {}
    local result   = nil ~= attrData[_sKey] and attrData[_sKey] or _default
    return result
end

function CastFishingManager:randomFishData(_params)
    --[[
        _params = {
            sMode     = ""   --模式 self.StrMode.XXX
            lineIndex = 1,   --行数
        }
    ]]
    local poolData = self:getFishPoolData(_params)
    local randomNumber = math.random(1, poolData.maxNumber)
    local number = 0
    for i,_data in ipairs(poolData.pool) do
        number = number + _data[2]
        if randomNumber <= number then
            return _data
        end
    end
end
function CastFishingManager:getFishIdByMultip(_multip)
    -- 数值提供倍数对应模型表
    local multipList = {
        {1, 1},    -- 紫鱼
        {2, 2},    -- 蓝鱼
        {3, 3},    -- 红鱼
        {4, 4},    -- 乌龟
        {5, 9999}, -- 章鱼
    }

    local fishId = 1
    for i,_data in ipairs(multipList) do
       if _multip <=  _data[2] then
            fishId =  _data[1]
            break
       end
    end

    return fishId
end
--[[
    配置相关
]]
function CastFishingManager:getFishConfig(_fishId)
    for i,_config in ipairs(CastFishingSceneConfig.Fish) do
        if _fishId == _config.id then
            return _config
        end
    end

    return nil
end
function CastFishingManager:getBulletConfig(_bulletId)
    for i,_config in ipairs(CastFishingSceneConfig.Bullet) do
        if _bulletId == _config.id then
            return _config
        end
    end

    return nil
end


--[[
    和服务器交互请求的接口
]]
-- 发送base捕鱼的结果
function CastFishingManager:sendBaseFishingResult(_fishObjList)
    if self.m_isWaitData then
        return
    end

    self.m_isWaitData = true

    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {
        msg = MessageDataType.MSG_BONUS_SELECT,
        data = self:getBaseFishingResultData(_fishObjList)
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

    local sMsg = "[CastFishingManager:sendBaseFishingResult] 发送base捕鱼结果"
    sMsg = string.format("%s kind=(%s) credit=(%d)", sMsg, messageData.data.baseFishResult.kind, messageData.data.baseFishResult.credit)
    print(sMsg)
    release_print(sMsg)
end
function CastFishingManager:getBaseFishingResultData(_fishObjList)
    local data = {
        baseFishResult = {
            kind = "",
            credit = 0,
        }
    }
    -- 只拿一条鱼的数据
    local fishObj = _fishObjList[1]
    if not fishObj then
        return data
    end

    local fishData   = fishObj.m_data
    local fishConfig = fishObj.m_config
    
    data.baseFishResult.kind = fishConfig.kind
    if fishConfig.level == CastFishingSceneConfig.FishLevelType.Coins then
        local curBet = globalData.slotRunData:getCurTotalBet()
        local multip = fishData.multip
        data.baseFishResult.credit = curBet * multip
    end

    return data
end

-- 发送free捕鱼的结果
function CastFishingManager:sendFreeFishingResult(_fishObjList)
    if self.m_isWaitData then
        return
    end

    self.m_isWaitData = true
    
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {}
    messageData.msg = MessageDataType.MSG_BONUS_SELECT
    messageData.data = self:getFreeFishingResultData(_fishObjList)
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

    local sMsg = "[CastFishingManager:sendFreeFishingResult] 发送free捕鱼结果"
    sMsg = string.format("%s kind=(%s) credit=(%d)", sMsg, messageData.data.freeFishResult.kind, messageData.data.freeFishResult.credit)
    print(sMsg)
    release_print(sMsg)
end
function CastFishingManager:getFreeFishingResultData(_fishObjList)
    local data = {
        freeFishResult = {
            kind = "",
            credit = 0,
        }
    }
    -- 只拿一条鱼的数据
    local fishObj = _fishObjList[1]
    if not fishObj then
        return data
    end

    local fishData   = fishObj.m_data
    local fishConfig = fishObj.m_config
    
    data.freeFishResult.kind = fishConfig.kind
    if fishConfig.level == CastFishingSceneConfig.FishLevelType.Coins then
        local curBet = globalData.slotRunData:getCurTotalBet()
        local multip = fishData.multip
        data.freeFishResult.credit = curBet * multip
    end

    return data
end

-- 发bonus捕鱼结果
function CastFishingManager:sendBonusFishingResult(_fishObjList)
    if self.m_isWaitData then
        return
    end

    self.m_isWaitData = true

    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {}
    messageData.msg = MessageDataType.MSG_BONUS_SELECT
    messageData.data = self:getBonusFishingResultData(_fishObjList)
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

    print("[CastFishingManager:sendBonusFishingResult]")
    release_print("[CastFishingManager:sendBonusFishingResult]")
    for i,_rewardData in ipairs(messageData.data.bonusFishResult) do
        local sMsg = "[CastFishingManager:sendBonusFishingResult] 发送bonus捕鱼结果"
        sMsg = string.format("%s kind=(%s) credit=(%d)", sMsg, _rewardData.kind, _rewardData.credit)
        print(sMsg)
        release_print(sMsg)
    end
end
function CastFishingManager:getBonusFishingResultData(_fishObjList)
    local data = {
        bonusFishResult = {
        }
    }

    for i,_fishObj in ipairs(_fishObjList) do
        local fishData   = _fishObj.m_data
        local fishConfig = _fishObj.m_config
        local rewardData = {}
        rewardData.kind   = fishConfig.kind
        rewardData.credit = 0
        if fishConfig.level == CastFishingSceneConfig.FishLevelType.Coins then
            local curBet = self.m_machine:getCastFishingCurBet()
            local multip = fishData.multip
            rewardData.credit = curBet * multip
        end

        table.insert(data.bonusFishResult, rewardData)
    end

    return data
end


function CastFishingManager:castFishingResultCallFun(_param)
    if  _param[1] ~= true then
        return
    end
    local result   = _param[2].result
    local selfData = result.selfData
    local isBaseFishing = selfData.isBaseFishing
    local isFreeFishing = selfData.isFreeFishing
    local isBonusFishing = selfData.isBonusFishing
    if  not isBaseFishing and 
        not isFreeFishing and 
        not isBonusFishing  then
        return
    end
    
    self.m_isWaitData = false
    
    local data = {}
    data.isBaseFishing  = isBaseFishing
    data.isFreeFishing  = isFreeFishing
    data.isBonusFishing = isBonusFishing

    data.winAmount = result.winAmount
    data.lines     = result.lines
    data.selfData  = result.selfData
    data.bonus     = result.bonus
    if isFreeFishing then
        data.fsWinCoins = result.freespin.fsWinCoins
    end

    local sMsg = "[CastFishingManager:castFishingResultCallFun] 捕鱼结果返回 isBaseFishing|isFreeFishing|isBonusFishing"
    sMsg = string.format("%s %s|", sMsg, isBaseFishing and "true" or "false")
    sMsg = string.format("%s|%s", sMsg, isFreeFishing and "true" or "false")
    sMsg = string.format("%s|%s", sMsg, isBonusFishing and "true" or "false")
    print(sMsg)
    release_print(sMsg)

    gLobalNoticManager:postNotification("CastFishingMachine_resultCallFun", data)
end

return CastFishingManager