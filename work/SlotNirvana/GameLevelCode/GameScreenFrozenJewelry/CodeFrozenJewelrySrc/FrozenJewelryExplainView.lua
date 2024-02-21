---
--xcyy
--2018年5月23日
--FrozenJewelryExplainView.lua

local FrozenJewelryExplainView = class("FrozenJewelryExplainView",util_require("Levels.BaseLevelDialog"))


function FrozenJewelryExplainView:initUI(params)
    self.m_callBack = params.func
    self:createCsbNode("FrozenJewelry/Explain.csb")

    self:addClick(self:findChild("Panel_9"))

    self.m_isWaitting = false
    
    self:runCsbAction("idle",true)
    performWithDelay(self,function()
        self:clickFunc()
    end,4)
end

--默认按钮监听回调
function FrozenJewelryExplainView:clickFunc(sender)
    self:stopAllActions()
    if self.m_isWaitting then
        return
    end
    self.m_isWaitting = true
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_close_explain_view.mp3")
    self:runCsbAction("over",false,function ()
        if type(self.m_callBack) == "function" then
            self.m_callBack()
        end
        self:removeFromParent()
    end)
end




return FrozenJewelryExplainView