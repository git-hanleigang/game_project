---
--xhkj
--2018年6月11日
--FrogPrinceBonusStartView.lua

local FrogPrinceBonusStartView = class("FrogPrinceBonusStartView", util_require("base.BaseView"))

function FrogPrinceBonusStartView:initUI(data)
    self:createCsbNode("FrogPrince_BonusGame1.csb")
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
    end)
end

function FrogPrinceBonusStartView:onEnter()

end

function FrogPrinceBonusStartView:setParent(parent)
    self.m_parent = parent
end

function FrogPrinceBonusStartView:onExit()
end
--默认按钮监听回调
function FrogPrinceBonusStartView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction("over",false,function ()
            self.m_parent:showBonusPlayView()
            self:removeFromParent()
        end)
    end
end
return FrogPrinceBonusStartView
