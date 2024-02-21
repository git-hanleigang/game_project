--[[
]]
local JewelManiaSlateData = class("JewelManiaSlateData")

function JewelManiaSlateData:ctor()
end

-- message JewelManiaSlate {
--     optional int32 position = 1;
--     optional bool mined = 2;//是否被开采
--   }
function JewelManiaSlateData:parseData(_netData)
    self.p_positon = _netData.position
    self.p_mined = _netData.mined
end  

function JewelManiaSlateData:getPosition()
    return self.p_positon
end

function JewelManiaSlateData:isMined()
    return self.p_mined
end


return JewelManiaSlateData