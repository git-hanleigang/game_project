--[[
    奖励界面的buff
]]
local CardSpecialClanRewardBuff = class("CardSpecialClanRewardBuff", BaseView)

function CardSpecialClanRewardBuff:initDatas(_mul, _csbPath)
    self.m_mul = _mul
    self.m_csbPath = _csbPath
end

function CardSpecialClanRewardBuff:getCsbName()
    return self.m_csbPath
end

function CardSpecialClanRewardBuff:initCsbNodes()
    self.m_lbNum = self:findChild("lb_buff_num")
end

function CardSpecialClanRewardBuff:initUI()
    CardSpecialClanRewardBuff.super.initUI(self)
    self:initNum()
end

function CardSpecialClanRewardBuff:initNum()
    self.m_lbNum:setString("+"..self.m_mul.."%")
end

function CardSpecialClanRewardBuff:playStart(_over)
    self:runCsbAction("start", false, _over, 60)
end

function CardSpecialClanRewardBuff:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

return CardSpecialClanRewardBuff