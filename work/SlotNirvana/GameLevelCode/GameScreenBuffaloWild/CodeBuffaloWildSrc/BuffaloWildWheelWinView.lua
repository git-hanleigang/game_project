---
--island
--2018年4月12日
--BuffaloWildWheelWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local BuffaloWildWheelWinView = class("BuffaloWildWheelWinView", util_require("base.BaseView"))

BuffaloWildWheelWinView.jPnum = {9,8,7,6,5}

function BuffaloWildWheelWinView:initUI(data,callback)
    self.m_click = false

    local resourceFilename = "BuffaloWild/WheelOver.csb"
    self:createCsbNode(resourceFilename)
    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_lb_coins:setString(util_getFromatMoneyStr(data))
    self:updateLabelSize({label=self.m_lb_coins,sx=0.8,sy=0.8},655)
    self.m_callFun = callback
    self:runCsbAction("start",false,function()
        if not self.m_click then
            self:runCsbAction("idle",true)
        end
    end)

    self.bgSoundId = gLobalSoundManager:playSound("BuffaloWildSounds/buffaloWild_collect_bonusOver.mp3")
end

function BuffaloWildWheelWinView:showResult(winNum)

end

function BuffaloWildWheelWinView:onEnter()
    gLobalSoundManager:pauseBgMusic()
end

function BuffaloWildWheelWinView:onExit()
    gLobalSoundManager:resumeBgMusic()
end

function BuffaloWildWheelWinView:clickFunc(sender)
    local name = sender:getName()
    if self.m_click == true then
        return
    end
    self.m_click = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    self:runCsbAction("over",false,function()
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end)
end


return BuffaloWildWheelWinView