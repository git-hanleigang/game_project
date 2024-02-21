--[[
    膨胀宣传 金币商店
]]
local BigBangCoinStoreMgr = class("BigBangCoinStoreMgr", BaseActivityControl)

function BigBangCoinStoreMgr:ctor()
    BigBangCoinStoreMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BigBang_CoinStore)
end

function BigBangCoinStoreMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function BigBangCoinStoreMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function BigBangCoinStoreMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return BigBangCoinStoreMgr
