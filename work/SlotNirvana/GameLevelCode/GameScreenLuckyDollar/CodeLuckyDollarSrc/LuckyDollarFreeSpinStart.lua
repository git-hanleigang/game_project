---

local LuckyDollarFreeSpinStart = class("LuckyDollarFreeSpinStart", util_require("base.BaseView"))

function LuckyDollarFreeSpinStart:initUI(_data)
    self:createCsbNode("LuckyDollar/FreeSpinStart.csb")
    local num = _data.freespinCounts
    local numLab = self:findChild("m_lb_num")
    numLab:setString(num)
    self:runCsbAction(
        "actionframe",
        false,
        function()
            self.m_click = true
            if self.m_func then
                self.m_func()
            end
        end
    )
end

function LuckyDollarFreeSpinStart:setFunCall(_func)
    self.m_func = function()
        if _func then
            _func()
            self:removeFromParent()
        end
    end
end

function LuckyDollarFreeSpinStart:onEnter()
end

function LuckyDollarFreeSpinStart:onExit()
end

--默认按钮监听回调
function LuckyDollarFreeSpinStart:clickFunc(sender)
    local name = sender:getName()
    if name == "touchPanel" then
        if self.m_click == true then
            return
        end
        self.m_click = true
        if self.m_func then
            self.m_func()
        end
    end
end

return LuckyDollarFreeSpinStart
