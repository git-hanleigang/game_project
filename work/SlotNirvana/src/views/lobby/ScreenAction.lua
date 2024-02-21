---
--幕布动画
--
local ScreenAction = class("ScreenAction", util_require("base.BaseView"))

function ScreenAction:initUI(func)
    self:createCsbNode("Logon/ScreenAction.csb")
    performWithDelay(self,function()
        self:runCsbAction("mubu_open", false, function ()
            func()
            self:removeFromParent()
        end)
    end,0.4)
end

return ScreenAction