--[[
    轮盘数据
]]

local FlamingoJackpotWheelData = class("FlamingoJackpotWheelData")
local FlamingoJackpotWheelGridData = import(".FlamingoJackpotWheelGridData")

function FlamingoJackpotWheelData:ctor()
    self.p_tierData = {}
end

function FlamingoJackpotWheelData:setWheelConfig(wheelConfig)
    if wheelConfig then
        self.p_tierData = {}
        for tier_id,tierData in pairs(wheelConfig) do
            local tierVec = {}
            if tierData and #tierData > 0 then
                for i,oneData in ipairs(tierData) do
                    local gridData = FlamingoJackpotWheelGridData:create()
                    gridData:parseData(oneData)
                    gridData:setTierId(tonumber(tier_id))
                    table.insert(tierVec, gridData)
                end
            end
            self.p_tierData[tonumber(tier_id)] = tierVec
        end
    end
end

function FlamingoJackpotWheelData:getWheelTierVecByTierId(tier_id)
    return self.p_tierData[tier_id] or {}
end

function FlamingoJackpotWheelData:setHitPos(hitPos)
    self.p_hitPosVec = hitPos
end


function FlamingoJackpotWheelData:getHitResultData()
    local data = {}
    data.tier_id = self:getHitTier()
    data.hitPosIds = self:getHitPos()
    local hitPos = self.p_hitPosVec[#self.p_hitPosVec]
    local hitGridData = self.p_tierData[data.tier_id][hitPos]
    data.grid_type = hitGridData:getType()
    data.jackpotType = hitGridData:getJackpotType()
    data.hitCoin = hitGridData:getCoins()
    if data.hitCoin == 0 then
        data.hitCoin = self.p_wheelWinCoins
    end
    return data
end

function FlamingoJackpotWheelData:getHitPos()
    return self.p_hitPosVec
end

function FlamingoJackpotWheelData:getHitTier()
    return #self.p_hitPosVec
end

function FlamingoJackpotWheelData:setWheelWinCoins(wheelWinCoins)
    self.p_wheelWinCoins = wheelWinCoins or 0
end

function FlamingoJackpotWheelData:setTierId(tierId)
    self.p_tierId = tierId
end

function FlamingoJackpotWheelData:getTierId(tierId)
    return self.p_tierId
end

function FlamingoJackpotWheelData:isHaveSuper()
    return not not self.p_tierData[3]
end


return FlamingoJackpotWheelData