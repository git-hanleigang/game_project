---
--xcyy
--2018年5月23日
--ColorfulCircusTanBanBtnView.lua

local ColorfulCircusTanBanBtnView = class("ColorfulCircusTanBanBtnView",util_require("Levels.BaseLevelDialog"))


function ColorfulCircusTanBanBtnView:initUI(viewName)
    local name = "ColorfulCircus/FreeSpinOver_btn.csb"
    self:createCsbNode(name)
    self.m_click = false
    self:showBtn(viewName)
end

function ColorfulCircusTanBanBtnView:initViewData(_func)

    self.callFunc = _func
end

function ColorfulCircusTanBanBtnView:setIsClick(isClick)
    self.m_click = isClick
end

function ColorfulCircusTanBanBtnView:showBtn(viewName)
    if viewName == "respinstart" or viewName == "superstart" then
        self:changeShowBtn(true)
    else
        self:changeShowBtn(false)
    end
end

function ColorfulCircusTanBanBtnView:changeShowBtn(isShowStart)
    if isShowStart then
        self:findChild("Button_1"):setVisible(false)
        self:findChild("Button_2"):setVisible(true)
    else
        self:findChild("Button_1"):setVisible(true)
        self:findChild("Button_2"):setVisible(false)
    end
end

function ColorfulCircusTanBanBtnView:clickFunc(sender)
    if self.m_click == false then
        return 
    end

    self.m_click = false
    gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_click.mp3")
    performWithDelay(self,function(  )
        if self.callFunc then
            self.callFunc()
        end
    end,0.5)
end

return ColorfulCircusTanBanBtnView