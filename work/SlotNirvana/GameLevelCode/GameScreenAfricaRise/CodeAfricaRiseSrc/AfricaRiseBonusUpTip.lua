---
--xcyy
--2018年5月23日
--AfricaRiseBonusUpTip.lua

local AfricaRiseBonusUpTip = class("AfricaRiseBonusUpTip",util_require("base.BaseView"))


function AfricaRiseBonusUpTip:initUI()
    self:createCsbNode("AfricaRise_ji_kuang.csb")
    self.m_eff = nil
end

function AfricaRiseBonusUpTip:onEnter()

end

function AfricaRiseBonusUpTip:playChooseEffect(_type)
    if _type == 120 then
        return 
    end
    local num = 1
    if _type == 0 then
        num = 1
    elseif  _type == 1 then
        num = 2
    elseif  _type == 2 then
        num = 3
    elseif  _type == 3 then
        num = 4
    elseif  _type == 4 then
        num = 5
    elseif  _type == 101 then
        num = 6
    elseif  _type == 102 then
        num = 7
    elseif  _type == 103 then
        num = 8
    end
    self.m_eff = util_createView("CodeAfricaRiseSrc.AfricaRiseBonusWinFrame",1)
    self:findChild("Node_" .. num):addChild(self.m_eff)
    self.m_eff:setPositionY(-25)
    self.m_eff:runCsbAction("animation0",true)
end

function AfricaRiseBonusUpTip:removeChooseEff()
    if self.m_eff then
        self.m_eff:removeFromParent()
        self.m_eff = nil
    end
end

function AfricaRiseBonusUpTip:playEff()
    if self.m_eff then
        self.m_eff:runCsbAction("animation0",true)
    end
end

function AfricaRiseBonusUpTip:setEffectVisible(bShow)
    if self.m_eff then
        self.m_eff:setVisible(bShow)
    end
end

function AfricaRiseBonusUpTip:onExit()
end

return AfricaRiseBonusUpTip