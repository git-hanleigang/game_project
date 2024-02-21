--接水管主数据部分
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local BaseActivityData = require "baseActivity.BaseActivityData"
local ShopItem = require "data.baseDatas.ShopItem"

local OutsideGaveStageData = util_require("activities.Activity_OutsideCave.model.OutsideGaveStageData")
local OutsideGaveRewardData = util_require("activities.Activity_OutsideCave.model.OutsideGaveRewardData")
local OutsideGaveWheelGameData = util_require("activities.Activity_OutsideCave.model.OutsideGaveWheelGameData")

local OutsideGaveWheelResultData = util_require("activities.Activity_OutsideCave.model.OutsideGaveWheelResultData")

local OutsideCaveData = class("OutsideCaveData", BaseActivityData)

-- message OutsideGave {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int32 props = 4; //道具数
--     optional int32 propSpinLimit = 5; //道具spin累积上限
--     optional int32 gemUpLimitCost = 6; //提升上限消耗第二货币值
--     optional int32 round = 7; //轮次
--     optional int32 stage = 8; //章节
--     optional int32 energy = 9; //能量
--     optional int32 energyMax = 10; //能量最大值
--     repeated OutsideGaveStage stages = 11; //章节数据
--     repeated OutsideGaveSpinGear spinGears = 12; //解锁BET档位
--     optional OutsideGaveWheelGame wheelGame = 13; //转盘数据
--     optional OutsideGaveHammerGame hammerGame = 14; //砸龙蛋小游戏
--     optional bool gemsBuyLimit = 15; //是否可以通过消耗第二货币提升上限标识
--     optional OutsideGaveReward roundReward = 16; //轮次奖励
--     optional int32 gemsBuyPropLimit = 17; //gem购买道具spin累积上限值
-- }

function OutsideCaveData:ctor()
    OutsideCaveData.super.ctor(self)
    -- 排行榜数据
    self.p_rankCfg = nil
end

function OutsideCaveData:parseData(data)
    OutsideCaveData.super.parseData(self, data)

    self.props = tonumber(data.props) --道具数
    self.propSpinLimit = tonumber(data.propSpinLimit) --道具spin累积上限
    self.gemUpLimitCost = tonumber(data.gemUpLimitCost) --提升上限消耗第二货币值
    self.round = tonumber(data.round) --轮次
    self.stage = tonumber(data.stage) --章节
    self.energy = tonumber(data.energy) --能量
    self.energyMax = tonumber(data.energyMax) --能量最大值

    self.stages = {}
    if data.stages and #data.stages > 0 then
        for i=1,#data.stages do
            local stageData = OutsideGaveStageData:create()
            stageData:parseData(data.stages[i])
            table.insert(self.stages, stageData)
        end
    end
    self.m_stageLen = #self.stages

    self.wheelGame = nil
    if data:HasField("wheelGame") then
        self.wheelGame = OutsideGaveWheelGameData:create()
        self.wheelGame:parseData(data.wheelGame)
    end

    if data:HasField("hammerGame") then
        G_GetMgr(ACTIVITY_REF.CaveEggs):parseData(data.hammerGame)
    end

    self.gemsBuyLimit = data.gemsBuyLimit

    self.roundReward = nil
    if data:HasField("roundReward") then
        self.roundReward = OutsideGaveRewardData:create()
        self.roundReward:parseData(data.roundReward)
    end

    self.gemsBuyPropLimit = tonumber(data.gemsBuyPropLimit)
    if data.spinGears and #data.spinGears > 0 then
        self:parseSpinG(data.spinGears)
    end
end

function OutsideCaveData:setSlotResult(_data)
    self.m_slotResult = clone(_data)
    local endRells = {}
    for i,v in ipairs(self.m_slotResult.reels) do
        table.insert(endRells,v)
        if i ~= 3 then
            table.insert(endRells,{100,100,100})
        end

    end
    self.m_slotResult.m_endReels = endRells

    self:recordStageReward(self.m_slotResult)
    self:recordRoundReward(self.m_slotResult)
    self:recordStepReward(self.m_slotResult)
end

function OutsideCaveData:getSlotResult()
    return self.m_slotResult
end

-- 轮盘转动结果
function OutsideCaveData:recordWheelResultData(data)
    self.m_wheelResultData = nil
    self.m_wheelResultData = OutsideGaveWheelResultData:create()
    self.m_wheelResultData:parseData(data)

    self:recordStageReward(data)
    self:recordRoundReward(data)
    self:recordStepReward(data)
end

function OutsideCaveData:getWheelResultData()
    return self.m_wheelResultData
end

function OutsideCaveData:recordStageReward(data)
    self.m_rStageReward = nil
    if data.stageReward ~= nil and next(data.stageReward) ~= nil then
        local rData = OutsideGaveRewardData:create()
        rData:parseData(data.stageReward)
        if rData:isEffective() then
            self.m_rStageReward = rData
        end
    end    
end

function OutsideCaveData:recordRoundReward(data)
    self.m_rRoundReward = nil
    if data.roundReward ~= nil and next(data.roundReward) ~= nil then
        local rData = OutsideGaveRewardData:create()
        rData:parseData(data.roundReward)
        if rData:isEffective() then
            self.m_rRoundReward = rData
        end
    end        
end

function OutsideCaveData:recordStepReward(data)
    self.m_rStepReward = nil
    if data.stepReward ~= nil and next(data.stepReward) ~= nil then
        local rData = OutsideGaveRewardData:create()
        rData:parseData(data.stepReward)
        if rData:isEffective() then
            self.m_rStepReward = rData
        end
    end
end

function OutsideCaveData:getRecordStageRewardData()
    return self.m_rStageReward
end
function OutsideCaveData:getRecordRoundRewardData()
    return self.m_rRoundReward
end
function OutsideCaveData:getRecordStepRewardData()
    return self.m_rStepReward       
end

function OutsideCaveData:getRound()
    return self.round
end

function OutsideCaveData:getStage()
    return self.stage
end

function OutsideCaveData:getStages()
    return self.stages
end

function OutsideCaveData:getStageDataByIndex(_index)
    if _index and _index > 0 and self.stages and #self.stages > 0 then
        return self.stages[_index]
    end
    return
end

function OutsideCaveData:getStageLen()
    return self.m_stageLen
end

function OutsideCaveData:getWheelGameData()
    return self.wheelGame
end

function OutsideCaveData:checkWheelGameEffective()
    if self.wheelGame then
        if self.wheelGame:hasWheel() then
            return true
        end
    end
    return false
end

function OutsideCaveData:getRoundReward()
    return self.roundReward
end

function OutsideCaveData:getProps()
    return self.props
end
function OutsideCaveData:setProps(_val)
    self.props = _val
end

function OutsideCaveData:getPropSpinLimit()
    return self.propSpinLimit
end

function OutsideCaveData:setPropSpinLimit(_val)
    self.propSpinLimit = _val
end

function OutsideCaveData:getEnergy()
    return self.energy
end

function OutsideCaveData:setEnergy(_val)
    self.energy = _val
end

function OutsideCaveData:getEnergyMax()
    return self.energyMax
end
function OutsideCaveData:setEnergyMax(_val)
    self.energyMax = _val
end

function OutsideCaveData:getGemUpLimitCost()
    return self.gemUpLimitCost 
end

function OutsideCaveData:getGemsBuyLimit()
    return self.gemsBuyLimit 
end

function OutsideCaveData:getGemsBuyPropLimit()
    return self.gemsBuyPropLimit 
end

function OutsideCaveData:isFirstStage()
    if self.stage == 1 then
        return true
    end
    return false
end

function OutsideCaveData:isFirstRound()
    if self.round == 1 then
        return true
    end
    return false
end

function OutsideCaveData:isFirstStep()
    local chapterData = self:getStageDataByIndex(1)
    if chapterData and chapterData:getCurStep() == 1 then
        return true
    end
    return false
end

function OutsideCaveData:getLobbyRedNum()
    return self:getProps() or 0
end

--老虎机数据
function OutsideCaveData:parseSpinG(_data)
    self.m_spinGears = {}
    for i,v in ipairs(_data) do
        local item = {}
        item.p_propsMin = v.propsMin
        item.p_propsMax = v.propsMax
        item.p_gears = {}
        if v.gears and #v.gears > 0 then
            local gears = {}
            for k=1,#v.gears do
                table.insert(gears,v.gears[k])
            end
            item.p_gears = gears
        end
        table.insert(self.m_spinGears,item)
    end
    --dump(self.m_spinGears)
end

function OutsideCaveData:getSpinGears()
    return self.m_spinGears
end

function OutsideCaveData:getCurBetG()
    -- local gears = nil
    -- local pros = tonumber(self.props) or 0
    -- local list = self.m_spinGears
    -- -- 小于最小
    -- gears = list[1]
    -- if pros < tonumber(gears.p_propsMin) then
    --     gears = gears
    --     return gears
    -- end
    -- -- 大于最大
    -- gears = list[#list]
    -- if pros > tonumber(gears.p_propsMax) then
    --     return gears
    -- end
    -- for i,v in ipairs(list) do
    --     if pros >= tonumber(v.p_propsMin) and pros <= tonumber(v.p_propsMax) then
    --         gears = v
    --         break
    --     end
    -- end
    -- return gears
    -- 不添加限制，只取最大的就可以
    local maxGear = self.m_spinGears[#self.m_spinGears]
    return maxGear
end

---------------------------------------------- 排行榜
-- 解析排行榜信息
function OutsideCaveData:parseRankConfig(_data)
    if not _data then
        return
    end

    if not self.p_rankCfg then
        self.p_rankCfg = BaseActivityRankCfg:create()
    end
    self.p_rankCfg:parseData(_data)

    local myRankConfigInfo = self.p_rankCfg:getMyRankConfig()
    if myRankConfigInfo and myRankConfigInfo.p_rank then
        self:setRank(myRankConfigInfo.p_rank)
    end
end

function OutsideCaveData:getRankCfg()
    return self.p_rankCfg
end

function OutsideCaveData:getMyRank()
    return self.m_rank or 0
end

function OutsideCaveData:getMyRankUp()
    return self.m_rankUp or 0
end

function OutsideCaveData:getMyRankPoint()
    return self.m_rankpoint or 0
end

--获取入口位置 1：左边，0：右边
function OutsideCaveData:getPositionBar()
    return 1
end

return OutsideCaveData
