-- bingo比赛 排行榜

local BingoRushShowTopManager = class("BingoRushShowTopManager", BaseActivityControl)

function BingoRushShowTopManager:ctor()
    BingoRushShowTopManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BingoRushShowTop)
    self:addPreRef(ACTIVITY_REF.BingoRush)
end

return BingoRushShowTopManager
