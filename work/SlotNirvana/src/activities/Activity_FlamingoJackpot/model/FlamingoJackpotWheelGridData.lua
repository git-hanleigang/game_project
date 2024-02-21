--[[
    轮盘数据
]]
local FlamingoJackpotWheelGridData = class("FlamingoJackpotWheelGridData")

function FlamingoJackpotWheelGridData:ctor()
end

function FlamingoJackpotWheelGridData:parseData(_netData)
    self.p_pos = _netData.pos
    self.p_type = _netData.type
    self.p_coins = tonumber(_netData.coins)
end

function FlamingoJackpotWheelGridData:getPos()
    return self.p_pos
end

function FlamingoJackpotWheelGridData:getType()
    return self.p_type
end

function FlamingoJackpotWheelGridData:getCoins()
    return self.p_coins
end

function FlamingoJackpotWheelGridData:setTierId(gridId)
    self.p_gridId= gridId --层ID
end

function FlamingoJackpotWheelGridData:getGridId(gridId)
    return self.p_gridId
end

function FlamingoJackpotWheelGridData:isPointer()
    return self.p_type == "POINTER"
end

function FlamingoJackpotWheelGridData:isJackpotType()
    return self.p_type ~= "POINTER" and self.p_type ~= "COIN"
end

function FlamingoJackpotWheelGridData:getJackpotType()
    if self.p_type == "MINI" then
        return 2
    elseif self.p_type == "MINOR" then
        return 3
    elseif self.p_type == "GRAND" then
        return 4
    end
    return 1
end

return FlamingoJackpotWheelGridData