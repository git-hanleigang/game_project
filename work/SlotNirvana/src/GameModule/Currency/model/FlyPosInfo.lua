--[[

    author:{author}
    time:2022-05-22 22:08:32
]]
local FlyPosInfo = class("FlyPosInfo")

function FlyPosInfo:ctor(pos, name, order, scale)
    self.m_pos = pos or nil
    self.m_name = name or ""
    self.m_order = order or 0
    self.m_scale = scale or 1
end

function FlyPosInfo:setPos(pos)
    self.m_pos = pos
end

function FlyPosInfo:getPos()
    return self.m_pos
end

function FlyPosInfo:getName()
    return self.m_name
end

function FlyPosInfo:getOrder()
    return self.m_order
end

return FlyPosInfo
