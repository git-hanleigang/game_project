---
--xcyy
--2018年5月23日
--FortuneGodTanBanBtnView.lua

local FortuneGodTanBanBtnView = class("FortuneGodTanBanBtnView",util_require("Levels.BaseLevelDialog"))


function FortuneGodTanBanBtnView:initUI(viewName)
    local name = "FortuneGod/FortuneGod_Button.csb"
    self:createCsbNode(name)
    self.m_click = false
    self:showBtn(viewName)
end

function FortuneGodTanBanBtnView:initViewData(_func)

    self.callFunc = _func
end

function FortuneGodTanBanBtnView:setIsClick(isClick)
    self.m_click = isClick
end

function FortuneGodTanBanBtnView:showBtn(viewName)
    if viewName == "respinstart" then
        self:changeShowBtn(true)
        self:runCsbAction("idle1",true)
    else
        self:changeShowBtn(false)
        self:runCsbAction("idle2",true)
    end
    
end

function FortuneGodTanBanBtnView:changeShowBtn(isShowStart)
    if isShowStart then
        self:findChild("Button_1"):setVisible(true)
        self:findChild("Button_2"):setVisible(false)
        self:findChild("Sprite_START"):setVisible(true)
        self:findChild("Sprite_COLLECT"):setVisible(false)
    else
        self:findChild("Button_1"):setVisible(false)
        self:findChild("Button_2"):setVisible(true)
        self:findChild("Sprite_START"):setVisible(false)
        self:findChild("Sprite_COLLECT"):setVisible(true)
    end
end

function FortuneGodTanBanBtnView:clickFunc(sender)
    if self.m_click == false then
        return 
    end

    self.m_click = false
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_tongyongBtnClick.mp3")
    performWithDelay(self,function(  )
        if self.callFunc then
            self.callFunc()
        end
    end,0.5)
end

return FortuneGodTanBanBtnView