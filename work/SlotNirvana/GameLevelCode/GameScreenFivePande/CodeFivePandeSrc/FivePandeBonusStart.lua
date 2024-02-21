---
--smy
--2018年4月26日
--BonusStart.lua

local BonusStart = class("BonusStart",util_require("base.BaseView"))

function BonusStart:initUI()

    self:createCsbNode("FivePande/BonusStart.csb",false)

    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self:runCsbAction("actionframe")
    -- TODO 输入自己初始化逻辑
    self.m_moveNode=self:findChild("sg_bg")
end

function BonusStart:initViewData(func)
    scheduler.performWithDelayGlobal(function()

        local x=display.width/DESIGN_SIZE.width
        local y=display.height/DESIGN_SIZE.height
        local pro=x/y
        local scale= 1 --/ pro

        local aq = cc.Sequence:create(cc.ScaleTo:create(1.5,scale),cc.CallFunc:create(function(  )
            if func then
                func() 
            end
            self:removeFromParent()
        end))
        self.m_moveNode:runAction(aq)

    end, 2.5,"FivePande_BonusStart")
    
    
end


function BonusStart:onEnter()

end

function BonusStart:onExit()
    scheduler.unschedulesByTargetName("FivePande_BonusStart")
end

return BonusStart