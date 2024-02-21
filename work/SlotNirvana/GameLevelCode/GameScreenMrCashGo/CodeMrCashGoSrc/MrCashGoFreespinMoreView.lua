--MrCashGoFreespinMoreView.lua

local MrCashGoFreespinMoreView = class("MrCashGoFreespinMoreView",util_require("Levels.BaseLevelDialog"))

MrCashGoFreespinMoreView.m_freespinCurrtTimes = 0


function MrCashGoFreespinMoreView:initUI()
    self:createCsbNode("MrCashGo/FreeSpinMore.csb")

    local particle = self:findChild("Particle_1")
    particle:stopSystem()
    util_setCascadeOpacityEnabledRescursion(particle, true)
end

function MrCashGoFreespinMoreView:playFlyAnim(_startWorldPos,_endWorldPos,_fun)
    local startPos = self:getParent():convertToNodeSpace(_startWorldPos)
    local endPos   = self:getParent():convertToNodeSpace(_endWorldPos)

    self:setPosition(startPos)

    local particle = self:findChild("Particle_1")
    particle:setPositionType(0) 
    particle:setDuration(-1)
    particle:resetSystem()

    self:findChild("Node_other"):setVisible(true)
    particle:setOpacity(255)
    self:setVisible(true)

    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_freeMore.mp3")
    self:runCsbAction("chuxian", false, function()
        self:runCsbAction("weiyi", false)

        local actList = {}
        local distance = math.sqrt((endPos.x - startPos.x) * (endPos.x - startPos.x) + (endPos.y - startPos.y) * (endPos.y - startPos.y))
        local radius = distance/2
        local flyAngle = util_getAngleByPos(startPos, endPos)
        local offsetAngle = endPos.x > startPos.x and -90 or 90
        local pos1 = cc.p( util_getCirclePointPos(startPos.x, startPos.y, radius, flyAngle + offsetAngle) )
        local pos2 = cc.p( util_getCirclePointPos(endPos.x, endPos.y, radius/2, flyAngle + offsetAngle) )
        local flyTime = 15/60
        table.insert(actList, cc.BezierTo:create(flyTime, {pos1, pos2, endPos}))

        table.insert(actList, cc.CallFunc:create(function()
            self:playParticleFadeOut()
            _fun()
        end))
        self:runAction(cc.Sequence:create(actList))
    end)
end

function MrCashGoFreespinMoreView:playParticleFadeOut()
    self:findChild("Node_other"):setVisible(false)
    local particle = self:findChild("Particle_1")
    particle:stopSystem()

    local actList = {}
    table.insert(actList, cc.FadeOut:create(0.5))
    table.insert(actList, cc.CallFunc:create(function()
        self:setVisible(false)
    end))

    particle:runAction(cc.Sequence:create(actList)) 
end

return MrCashGoFreespinMoreView