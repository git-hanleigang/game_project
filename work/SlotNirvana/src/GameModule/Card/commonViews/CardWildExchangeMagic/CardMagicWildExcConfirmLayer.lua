--[[
    集卡 Magic卡 wild兑换 二次确认界面
--]]
local CardMagicWildExcConfirmLayer = class("CardMagicWildExcConfirmLayer", BaseLayer)

function CardMagicWildExcConfirmLayer:initDatas(_cardData, _confirmCB)
    CardMagicWildExcConfirmLayer.super.initDatas(self)

    self.m_cardData = _cardData
    self.m_confirmCB = _confirmCB

    self:setExtendData("CardMagicWildExcConfirmLayer")
    self:setName("CardMagicWildExcConfirmLayer")
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/wild/cash_wild_exchange_confirm.csb")
    self:addClickSound({"btn_yes", "btn_no"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

-- 初始化UI --
function CardMagicWildExcConfirmLayer:initView()
    CardMagicWildExcConfirmLayer.super.initView(self)
   
    -- 卡片node
    self:createMiniCardUI()
    -- 卡片名字
    self:initChipCardNameUI()
    -- btn文本
    self:initButtonLabel()
end

function CardMagicWildExcConfirmLayer:initButtonLabel()
    self:setButtonLabelContent("btn_yes", "YES")
end

-- 卡片node
function CardMagicWildExcConfirmLayer:createMiniCardUI()
    local nodeParent =  self:findChild("node_card")

    local nodeChip = util_createView("GameModule.Card.season201903.MiniChipUnit")
    nodeChip:playIdle()
    nodeChip:reloadUI(self.m_cardData, true)
    nodeParent:addChild(nodeChip)
    nodeChip:setScale(0.5)
end

-- 卡片名字
function CardMagicWildExcConfirmLayer:initChipCardNameUI()
    local lbCardName = self:findChild("lb_cardName")
    local name = string.gsub(self.m_cardData.name, "|", " ")
    lbCardName:setString(name)
end

-- function CardMagicWildExcConfirmLayer:playShowAction()
--     gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
--     CardMagicWildExcConfirmLayer.super.playShowAction(self, "show", false)
-- end

function CardMagicWildExcConfirmLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

-- function CardMagicWildExcConfirmLayer:playHideAction()
--     CardMagicWildExcConfirmLayer.super.playHideAction(self, "over", false)
-- end

-- 点击事件 --
function CardMagicWildExcConfirmLayer:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_yes" then
        self:closeUI(self.m_confirmCB)
    elseif name == "btn_no" then
        self:closeUI()
    end
end

function CardMagicWildExcConfirmLayer:closeUI(_cb)
    if self.m_closing then
        return
    end
    self.m_closing = true

    CardMagicWildExcConfirmLayer.super.closeUI(self, _cb)
end

return CardMagicWildExcConfirmLayer
