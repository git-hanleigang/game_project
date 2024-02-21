--[[
]]
local LuckyStampLatticeData = util_require("GameModule.LuckyStamp.model.LuckyStampLatticeData")
local LuckyStampProcessData = class("LuckyStampProcessData")

function LuckyStampProcessData:ctor()
end

-- message LuckyStampProcess {
--     optional int32 process = 1; //戳索引
--     optional string stampType = 2;//戳类型NORMAL,GOLDEN
--     optional int64 prizePool = 3;//小游戏上方奖池
--     repeated LuckyStampV2Lattice latticeList = 4; //格子数据
--     optional int32 winIndex = 5; //中奖索引
--     optional bool collect = 6; //是否已领奖
--     optional bool spin = 7; //是否已抽奖
--   }
function LuckyStampProcessData:parseData(_netData)
    self.p_process = _netData.process
    self.p_stampType = _netData.stampType
    self.p_prizePool = tonumber(_netData.prizePool)
    self.p_latticeList = {}
    if _netData.latticeList and #_netData.latticeList > 0 then
        for i = 1, #_netData.latticeList do
            local lattice = LuckyStampLatticeData:create()
            lattice:parseData(_netData.latticeList[i])
            table.insert(self.p_latticeList, lattice)
        end
    end
    self.p_winIndex = _netData.winIndex
    self.p_collect = _netData.collect
    self.p_spin = _netData.spin
end

function LuckyStampProcessData:getIndex()
    return self.p_process
end

function LuckyStampProcessData:getStampType()
    return self.p_stampType
end

function LuckyStampProcessData:getTopCoins()
    return self.p_prizePool
end

function LuckyStampProcessData:getLatticeList()
    return self.p_latticeList
end

function LuckyStampProcessData:getLatticeDataByIndex(_index)
    if _index and _index > 0 then
        if self.p_latticeList and #self.p_latticeList > 0 and #self.p_latticeList >= _index then
            return self.p_latticeList[_index]
        end
    end
    return nil
end

function LuckyStampProcessData:getGoldenLatticeList()
    local goldenList = {}
    if self.p_latticeList and #self.p_latticeList > 0 then
        for i = 1, #self.p_latticeList do
            if self.p_latticeList[i]:getType() == LuckyStampCfg.StampType.Golden then
                table.insert(goldenList, i)
            end
        end
    end
    return goldenList
end

-- 服务器从0开始
function LuckyStampProcessData:getWinIndex()
    return self.p_winIndex
end

function LuckyStampProcessData:isSpin()
    return self.p_spin
end

function LuckyStampProcessData:isCollect()
    return self.p_collect
end

function LuckyStampProcessData:isHaveGame()
    if self:getWinIndex() >= 0 then
        return true
    end
    return false
end

function LuckyStampProcessData:checkReconnect()
    if self:getWinIndex() >= 0 then
        if self:isSpin() == false then
            return true
        end
        if self:isCollect() == false then
            return true
        end
    end
    return false
end

return LuckyStampProcessData
