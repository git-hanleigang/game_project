--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-20 10:28:24
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-20 10:40:34
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/views/NoviceSevenSignFlyEfUI.lua
Description: 新手期 7日签到V2 飞行倍数粒子
--]]
local NoviceSevenSignFlyEfUI = class("NoviceSevenSignFlyEfUI", BaseView)

function NoviceSevenSignFlyEfUI:getCsbName()
    return "DailyBonusNoviceResV2/csd/node_flylizi.csb"
end

function NoviceSevenSignFlyEfUI:initUI()
    NoviceSevenSignFlyEfUI.super.initUI(self)
    
    -- 粒子
    local particle = self:findChild("Particle_1")
    particle:setPositionType(0) 
    particle:setTotalParticles(300)
end

-- 飞粒子 签到天  飞到 第7天
function NoviceSevenSignFlyEfUI:playFlyAct(_startPosW, _endPosW, _cb)
    local startPos = self:convertToNodeSpace(_startPosW)
    local endPos = self:convertToNodeSpace(_endPosW)

    self:setPosition(startPos)

    local bezier = {}
    bezier[1] = startPos
    bezier[2] = cc.pAdd(startPos, cc.p((endPos.x - startPos.x) * 0.5, 300))
    bezier[3] = endPos
    local time = 1
    local moveAct =  cc.EaseSineIn:create( cc.BezierTo:create(time, bezier) )
    local actList = {
        moveAct,
        cc.CallFunc:create(_cb),
        cc.RemoveSelf:create()
    }
    self:runAction(cc.Sequence:create(actList))
end

return NoviceSevenSignFlyEfUI