--[[--
    付费返代币
    目前服务器限制只买商城会有返还代币，后续可能会扩展
]]
local BucksBackMgr = class("BucksBackMgr", BaseActivityControl)

function BucksBackMgr:ctor()
    BucksBackMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BucksBack)
    self:setDataModule("GameModule.BrokenSaleV2.model.BucksBackData")
end

function BucksBackMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function BucksBackMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function BucksBackMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return BucksBackMgr
