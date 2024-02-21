--[[
    nado机，一键spin按钮的确认弹框
]]
local BaseView = util_require("base.BaseView")
local CardNadoWheelOneSpinPopUI = class("CardNadoWheelOneSpinPopUI", BaseView)
function CardNadoWheelOneSpinPopUI:initUI(confirmCall)
    self.m_confirmCall = confirmCall

    -- local maskUI = util_newMaskLayer()
    -- self:addChild(maskUI,-1)
    -- maskUI:setOpacity(192)

    self:setShowActionEnabled(true)
    self:setHideActionEnabled(true)

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode(string.format(CardResConfig.commonRes.CardNadoWheelOneSpinPopRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()), isAutoScale)
    self.m_root = self:findChild("root")

    self:addClickSound({"btn_yes", "btn_no"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function CardNadoWheelOneSpinPopUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_yes" then
        self:closeUI(self.m_confirmCall)
    elseif name == "btn_no" then
        self:closeUI()
    end
end

function CardNadoWheelOneSpinPopUI:closeUI(closeCall)
    self:commonHide(
        self.m_root,
        function()
            if closeCall then
                closeCall()
            end
            self:removeFromParent()
        end
    )
end

function CardNadoWheelOneSpinPopUI:onEnter()
    CardNadoWheelOneSpinPopUI.super.onEnter(self)
    self:commonShow(self.m_root)
end

return CardNadoWheelOneSpinPopUI
