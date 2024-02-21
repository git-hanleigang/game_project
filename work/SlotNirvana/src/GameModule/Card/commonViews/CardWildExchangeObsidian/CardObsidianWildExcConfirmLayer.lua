--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-02-28 11:14:27
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-28 11:15:41
FilePath: /SlotNirvana/src/GameModule/Card/commonViews/CardWildExchangeObsidian/CardObsidianWildExcConfirmLayer.lua
Description: 集卡 黑耀卡 wild兑换 二次确认界面
--]]
local CardObsidianWildExcConfirmLayer = class("CardObsidianWildExcConfirmLayer", BaseLayer)

function CardObsidianWildExcConfirmLayer:initDatas(_cardData, _confirmCB)
    CardObsidianWildExcConfirmLayer.super.initDatas(self)

    self.m_cardData = _cardData
    self.m_confirmCB = _confirmCB
    self.m_seasonId = G_GetMgr(G_REF.ObsidianCard):getSeasonId()

    self:setExtendData("CardObsidianWildExcConfirmLayer")
    self:setName("CardObsidianWildExcConfirmLayer")
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName(string.format("CardRes/CardObsidian_%s/csb/wild/cash_wild_exchange_confirm.csb", self.m_seasonId))
    self:addClickSound({"btn_yes", "btn_no"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

-- 初始化UI --
function CardObsidianWildExcConfirmLayer:initView()
    CardObsidianWildExcConfirmLayer.super.initView(self)
   
    -- 卡片node
    self:createMiniCardUI()
    -- 卡片名字
    self:initChipCardNameUI()
end

-- 卡片node
function CardObsidianWildExcConfirmLayer:createMiniCardUI()
    local nodeParent =  self:findChild("node_card")

    local nodeChip = util_createView("GameModule.Card.season201903.MiniChipUnit")
    nodeChip:playIdle()
    nodeChip:reloadUI(self.m_cardData, true)
    nodeParent:addChild(nodeChip)
    nodeChip:setScale(0.5)
end

-- 卡片名字
function CardObsidianWildExcConfirmLayer:initChipCardNameUI()
    local lbCardName = self:findChild("lb_cardName")
    local name = string.gsub(self.m_cardData.name, "|", " ")
    lbCardName:setString(name)
end

function CardObsidianWildExcConfirmLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardObsidianWildExcConfirmLayer.super.playShowAction(self, "show", false)
end

function CardObsidianWildExcConfirmLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CardObsidianWildExcConfirmLayer:playHideAction()
    CardObsidianWildExcConfirmLayer.super.playHideAction(self, "over", false)
end

-- 点击事件 --
function CardObsidianWildExcConfirmLayer:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_yes" then
        self:closeUI(self.m_confirmCB)
    elseif name == "btn_no" then
        self:closeUI()
    end
end

function CardObsidianWildExcConfirmLayer:closeUI(_cb)
    if self.m_closing then
        return
    end
    self.m_closing = true

    CardObsidianWildExcConfirmLayer.super.closeUI(self, _cb)
end

return CardObsidianWildExcConfirmLayer
