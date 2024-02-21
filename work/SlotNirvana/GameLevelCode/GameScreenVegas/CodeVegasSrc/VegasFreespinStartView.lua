---
--xcyy
--2018年5月23日
--VegasFreespinStartView.lua

local VegasFreespinStartView = class("VegasFreespinStartView", util_require("base.BaseView"))

function VegasFreespinStartView:initUI(data)


    self:createCsbNode(data.csbname)
    self.m_touchFlag = false
    local num = data.num
    
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_touchFlag = true
            self:runCsbAction("idle", true)
        end
    )
  

    local freeSpinNumLab = self:findChild("m_lb_num")
    freeSpinNumLab:setString(num)
end

function VegasFreespinStartView:onEnter()
end

--默认按钮监听回调
function VegasFreespinStartView:clickFunc(sender)
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

function VegasFreespinStartView:setFunCall(_func)
    self.m_func = function()
        if _func then
            _func()
        end
    end
end

return VegasFreespinStartView
