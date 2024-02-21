---
--xcyy
--2018年5月23日
--PelicanTanBanBtnView.lua

local PelicanTanBanBtnView = class("PelicanTanBanBtnView",util_require("Levels.BaseLevelDialog"))


function PelicanTanBanBtnView:initUI(viewName)
    local name = "Pelican/FreeSpinOver_btn.csb"
    self:createCsbNode(name)
    self.m_click = false
    self:showBtn(viewName)
end

function PelicanTanBanBtnView:initViewData(_func)

    self.callFunc = _func
end

function PelicanTanBanBtnView:setIsClick(isClick)
    self.m_click = isClick
end

function PelicanTanBanBtnView:showBtn(viewName)
    if viewName == "respinstart" or viewName == "superstart" then
        self:changeShowBtn(true)
    else
        self:changeShowBtn(false)
    end
end

function PelicanTanBanBtnView:changeShowBtn(isShowStart)
    if isShowStart then
        self:findChild("Button_1"):setVisible(false)
        self:findChild("Button_2"):setVisible(true)
    else
        self:findChild("Button_1"):setVisible(true)
        self:findChild("Button_2"):setVisible(false)
    end
end

function PelicanTanBanBtnView:clickFunc(sender)
    if self.m_click == false then
        return 
    end

    self.m_click = false
    gLobalSoundManager:playSound("PelicanSounds/Pelican_click.mp3")
    performWithDelay(self,function(  )
        if self.callFunc then
            self.callFunc()
        end
    end,0.5)
end

return PelicanTanBanBtnView