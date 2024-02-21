---
--xcyy
--2018年5月23日
--VegasRespinStartView.lua

local VegasRespinStartView = class("VegasRespinStartView", util_require("base.BaseView"))

function VegasRespinStartView:initUI()
    self:createCsbNode("Vegas/ReSpinStart.csb")
    self.m_touchFlag = false

    self:runCsbAction(
        "start",
        false,
        function()
            self.m_touchFlag = true
            self:runCsbAction("idle", true)
        end
    )
    
end

function VegasRespinStartView:onEnter()

end



--默认按钮监听回调
function VegasRespinStartView:clickFunc(sender)
    if self.m_touchFlag == false then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local tag = sender:getTag()
    self.m_touchFlag = false
    self.m_func()
    self:runCsbAction(
        "over",
        false,
        function() 
            self:removeFromParent()
        end
    )
  
end

function VegasRespinStartView:setFunCall(_func)
    self.m_func = function()
        if _func then
            _func()
        end
    end
end

return VegasRespinStartView
