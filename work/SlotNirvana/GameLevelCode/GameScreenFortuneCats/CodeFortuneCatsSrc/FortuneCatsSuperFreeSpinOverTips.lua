---
--xcyy
--2018年5月23日
--FortuneCatsSuperFreeSpinOverTips.lua

local FortuneCatsSuperFreeSpinOverTips = class("FortuneCatsSuperFreeSpinOverTips", util_require("base.BaseView"))

function FortuneCatsSuperFreeSpinOverTips:initUI(_num)
    self:createCsbNode("FortuneCats/jiesuotanban.csb")
    self.m_click = true
    _num = _num + 1
    if _num == 4 then
        _num = 0
    end
    self:findChild("red_0"):setVisible(false)
    self:findChild("green_0"):setVisible(false)
    self:findChild("blue_0"):setVisible(false)
    self:findChild("gold_0"):setVisible(false)
    if _num == 0 then
        self:findChild("red_0"):setVisible(true)
    elseif _num == 1 then
        self:findChild("green_0"):setVisible(true)
    elseif _num == 2 then
        self:findChild("blue_0"):setVisible(true)
    elseif _num == 3 then
        self:findChild("gold_0"):setVisible(true)
    end

    self:runCsbAction(
        "start",
        false,
        function()
            self.m_click = false
            self:runCsbAction("idle", true)
        end
    )
end

function FortuneCatsSuperFreeSpinOverTips:onEnter()
end

function FortuneCatsSuperFreeSpinOverTips:setCallFunc(func)
    self.m_func = function()
        if func then
            func()
        end
    end
end

function FortuneCatsSuperFreeSpinOverTips:onExit()
end

function FortuneCatsSuperFreeSpinOverTips:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_click == true then
            return
        end
        self.m_click = true
        self:runCsbAction(
            "over",
            false,
            function()
                if self.m_func then
                    self.m_func()
                end
                self:removeFromParent()
            end
        )
    end
end

return FortuneCatsSuperFreeSpinOverTips
