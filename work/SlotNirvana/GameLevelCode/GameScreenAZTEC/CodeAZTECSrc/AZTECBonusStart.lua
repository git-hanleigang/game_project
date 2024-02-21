---
--smy
--2018年4月26日
--AZTECBonusStart.lua

local AZTECBonusStart = class("AZTECBonusStart",util_require("base.BaseView"))

function AZTECBonusStart:initUI()

    self:createCsbNode("AZTEC/AZTECBonusStart.csb",true)

    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self:runCsbAction("actionframe")
    -- TODO 输入自己初始化逻辑
    self.m_moveNode=self:findChild("sg_bg")
end

function AZTECBonusStart:initViewData(func)
    scheduler.performWithDelayGlobal(function()
        self:moveFrame()
    end, 2.8,"AZTEC_AZTECBonusStart")
    scheduler.performWithDelayGlobal(function()
        if func then
            func() 
        end
        self:removeFromParent()
    end, 4,"AZTEC_AZTECBonusStart")
end

function AZTECBonusStart:moveFrame()
    local scale=1
    local winSize = cc.Director:getInstance():getWinSize()
    local scale=math.min(display.width/1366,display.height/768)

    self.m_moveNode:stopAllActions()
    self.m_moveNode:pause()
    self.m_moveNode:runAction(cc.ScaleTo:create(1.2,1/scale))
end

function AZTECBonusStart:onEnter()

end

function AZTECBonusStart:onExit()
    scheduler.unschedulesByTargetName("AZTEC_AZTECBonusStart")
end

return AZTECBonusStart