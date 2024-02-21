---
--xcyy
--2018年5月23日
--FiveDragonTip.lua

local FiveDragonTips = class("FiveDragonTips", util_require("base.BaseView"))

function FiveDragonTips:initUI()
    self:createCsbNode("FiveDragon_tips_2.csb")
    self.m_isShow = false
end

function FiveDragonTips:showTip(_fun)

    self:setVisible(true)
    self:runCsbAction("show",false,function (  )
        if _fun then
            _fun()
        end
        self.m_isShow = true
    end)
end

function FiveDragonTips:HideTip(_fun)

    self:runCsbAction("hide",false,function()
        self:setVisible(false)
        self.m_isShow = false
        if _fun then
            _fun()
        end
    end)
end

function FiveDragonTips:getIsShow()
    return self.m_isShow 
end

function FiveDragonTips:onEnter()
end

function FiveDragonTips:onExit()
end

return FiveDragonTips
