--[[
    poker单元数据
]]
local PokerUnitData = class("PokerUnitData")

function PokerUnitData:ctor()
end

function PokerUnitData:parseData(_netData)
    self.p_card = _netData.card or 0 -- 1-13
    self.p_color = _netData.color or 0 -- 0-3 黑桃、红桃、梅花、方片
    self.p_wild = _netData.wild -- 0, 1小王, 2大王

    self:setId()
end

-- string格式
function PokerUnitData:getId()
    return self.m_id
end

-- string格式
-- 生成唯一扑克id，方便参数传递
function PokerUnitData:setId()
    self.m_id = string.format("%d-%d-%d", self.p_card, self.p_color, self.p_wild)
end

function PokerUnitData:getCard()
    return self.p_card
end

function PokerUnitData:getColor()
    return self.p_color
end

function PokerUnitData:getWild()
    return self.p_wild
end

-- 是否是大小王
function PokerUnitData:isWild()
    if self.p_wild and self.p_wild > 0 then
        return true
    end
    return false
end

function PokerUnitData:setColor(_color)
    self.p_color = _color
    self:setId()
end

function PokerUnitData:setCard(_card)
    self.p_card = _card
    self:setId()
end

function PokerUnitData:setWild(_wild)
    self.p_wild = _wild
    self:setId()
end

return PokerUnitData
