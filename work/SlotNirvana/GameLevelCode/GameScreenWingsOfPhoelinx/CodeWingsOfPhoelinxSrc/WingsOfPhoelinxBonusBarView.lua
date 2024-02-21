---
--xcyy
--2018年5月23日
--WingsOfPhoelinxBonusBarView.lua

local WingsOfPhoelinxBonusBarView = class("WingsOfPhoelinxBonusBarView",util_require("Levels.BaseLevelDialog"))


function WingsOfPhoelinxBonusBarView:initUI()

    self:createCsbNode("WingsOfPhoelinx_bonuscishukuang.csb")
    self.lastNum = 0
    self.m_node = cc.Node:create()
    self:addChild(self.m_node)
end


function WingsOfPhoelinxBonusBarView:onEnter()

    WingsOfPhoelinxBonusBarView.super.onEnter(self)

end

function WingsOfPhoelinxBonusBarView:onExit()
    WingsOfPhoelinxBonusBarView.super.onExit(self)
end

function WingsOfPhoelinxBonusBarView:resetLastNum( )
    self.lastNum = 0
end

function WingsOfPhoelinxBonusBarView:updateTimes(curtimes,totaltimes)
    self.m_node:stopAllActions()
    if curtimes == totaltimes or self.lastNum == totaltimes then
        self:findChild("m_lb_num"):setString(totaltimes - curtimes)
        self:findChild("m_lb_num_1"):setString(totaltimes)
        return
    end

    if self.lastNum ~= totaltimes then
        self:runCsbAction("actionframe")
        gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_addNum.mp3")
        self.lastNum = totaltimes
        performWithDelay(self.m_node,function (  )
            self:findChild("m_lb_num"):setString(totaltimes - curtimes)
            self:findChild("m_lb_num_1"):setString(totaltimes)
        end,5/55)
    end
end

--用于判断本次respin结束之后刷新一下总次数（全满的情况下会少一次）
function WingsOfPhoelinxBonusBarView:updateOverTimes(totaltimes)
    if self.lastNum == totaltimes then
        self:findChild("m_lb_num_1"):setString(totaltimes)
        return
    end

    if self.lastNum ~= totaltimes then
        self:runCsbAction("actionframe")
        gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_addNum.mp3")
        self.lastNum = totaltimes
        performWithDelay(self,function (  )
            self:findChild("m_lb_num_1"):setString(totaltimes)
        end,5/55)
    end
end

return WingsOfPhoelinxBonusBarView