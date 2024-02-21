---

local LuckyDollarBonusStart = class("LuckyDollarBonusStart", util_require("base.BaseView"))

function LuckyDollarBonusStart:initUI()
    self:createCsbNode("LuckyDollar/Feature.csb")
    self.m_click = true
end

function LuckyDollarBonusStart:playStart(isReconnect)
    if isReconnect then
        self:runCsbAction("idle", true)
    else
        self:runCsbAction(
            "start",
            false,
            function()
                self.m_click = false
                if self.m_func then
                    self.m_func()
                end
                self:runCsbAction("idle", true)
            end
        )
    end
end

function LuckyDollarBonusStart:setFunCall(_func)
    self.m_func = function()
        if _func then
            _func()
        end
    end
end

function LuckyDollarBonusStart:onEnter()
end

function LuckyDollarBonusStart:onExit()
end

--默认按钮监听回调
function LuckyDollarBonusStart:clickFunc(sender)
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

return LuckyDollarBonusStart
