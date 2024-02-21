--[[
    大奖icon
]]
local CardNadoWheelBigCoinIcon = class("CardNadoWheelBigCoinIcon", BaseView)

function CardNadoWheelBigCoinIcon:initDatas(_count, _clickBigCoinIcon)
    self.m_count = _count
    self.m_clickBigCoinIcon = _clickBigCoinIcon
end

function CardNadoWheelBigCoinIcon:getCsbName()
    return string.format(CardResConfig.commonRes.CardNadoWheelBigCoinOverIconRes, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardNadoWheelBigCoinIcon:initCsbNodes()
    self.m_PanelTouch = self:findChild("Panel_touch")
    self:addClick(self.m_PanelTouch)
    self.m_lbNum = self:findChild("lb_num")
end

function CardNadoWheelBigCoinIcon:initUI()
    CardNadoWheelBigCoinIcon.super.initUI(self)
    self:initView()
end

function CardNadoWheelBigCoinIcon:initView()
    self.m_lbNum:setString("x" .. self.m_count)
end

function CardNadoWheelBigCoinIcon:initBigCoinIcon()
    local view = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelOverItem", {key = k, data = v}) -- string.format(CardResConfig.commonRes.CardNadoWheelBigCoinOverIconRes, "common" .. CardSysRuntimeMgr:getCurAlbumID())
    self.m_nodeBigCoinIcon:addChild(view)
    self.m_bigCoinIcon = view
end

function CardNadoWheelBigCoinIcon:playShow(_over)
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("breathe", true, nil, 30)
            if _over then
                _over()
            end
        end,
        30
    )
end

function CardNadoWheelBigCoinIcon:playOpen1(_over)
    self:runCsbAction("open1", false, _over, 30)
end

function CardNadoWheelBigCoinIcon:playOpen2()
    self:runCsbAction("open2", false, _over, 30)
end

function CardNadoWheelBigCoinIcon:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_touch" then
        if self.m_clickBigCoinIcon then
            self.m_clickBigCoinIcon()
        end
    end
end

return CardNadoWheelBigCoinIcon
