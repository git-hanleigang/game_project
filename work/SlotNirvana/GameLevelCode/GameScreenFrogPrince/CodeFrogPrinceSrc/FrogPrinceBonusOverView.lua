---
--xhkj
--2018年6月11日
--FrogPrinceBonusOverView.lua

local FrogPrinceBonusOverView = class("FrogPrinceBonusOverView", util_require("base.BaseView"))

function FrogPrinceBonusOverView:initUI(data)
    self:createCsbNode("FrogPrince_BonusGame7.csb")
    self.m_clickFlag = false
    self:runCsbAction("start",false,function(  )
        self.m_clickFlag = true
    end)
end

function FrogPrinceBonusOverView:onEnter()

end

function FrogPrinceBonusOverView:showCollectWinLab(_multiple,_base,_win)
    local lab1 = self:findChild("m_lb_coins")
    lab1:setString(util_formatCoins(_win, 20))
    self:updateLabelSize({label=lab1,sx=0.8,sy=0.8},627)
    local lab2 = self:findChild("BitmapFontLabel_1")
    local winNum = _multiple*_base
    local win = util_formatCoins(_win, 5)
    lab2:setString(_multiple .. " X " .. _base .. " = " .. win)
end

function FrogPrinceBonusOverView:onExit()

end

function FrogPrinceBonusOverView:setParent(parent)
    self.m_parent = parent
end

--默认按钮监听回调
function FrogPrinceBonusOverView:clickFunc(sender)
    if  self.m_clickFlag == false then
        return 
    end
    self.m_clickFlag = false
    local name = sender:getName()
    if name == "Button_1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction("over",false,function ()
            self.m_parent:ClickBonusGameOver()
        end)
    end
end

return FrogPrinceBonusOverView
