-- 长度小的卡牌单元

local BaseCardUnitView = util_require("GameModule.Card.baseViews.BaseCardUnitView")
local MiniCardUnitView = class("MiniCardUnitView", BaseCardUnitView)
MiniCardUnitView.m_noMiniBtn = false

function MiniCardUnitView:ctor()
    MiniCardUnitView.super.ctor(self)
end

function MiniCardUnitView:initUI(cardData, touchLayer, actionName, noMiniBtn, useClanIcon, showNail, newFlag, linkTip, isMiddleIcon)
    if cardData then
        self:reloadUI(cardData, touchLayer, actionName, noMiniBtn, useClanIcon, showNail, newFlag, linkTip, isMiddleIcon)
    end
end

-- 重新加载 --
function MiniCardUnitView:reloadUI(cardData, touchLayer, actionName, noMiniBtn, useClanIcon, showNail, newFlag, linkTip, isMiddleIcon)
    self.m_noMiniBtn = not (not noMiniBtn)
    self.m_showNail = showNail
    self.m_newFlag = newFlag
    self.m_linkTip = linkTip
    self.m_isMiddleIcon = isMiddleIcon
    MiniCardUnitView.super.reloadUI(self, cardData, touchLayer, actionName, useClanIcon)
end

function MiniCardUnitView:createCsbInfo(actionName)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local cardData = self:getCardData()
    if cardData.type == CardSysConfigs.CardType.normal then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.mini.normal, isAutoScale)

        local btnAsk = self:findChild("Button_ask")
        btnAsk:setVisible(not self.m_noMiniBtn)

        -- 不开放暂时不能点击
        btnAsk:setTouchEnabled(false)
        btnAsk:setBright(false)
    elseif cardData.type == CardSysConfigs.CardType.link then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.mini.link, isAutoScale)
        local btnGet = self:findChild("Button_getin")
        btnGet:setVisible(not self.m_noMiniBtn)

        -- 不开放暂时不能点击
        btnGet:setTouchEnabled(false)
        btnGet:setBright(false)

        self:initLinkCardTip()
    elseif cardData.type == CardSysConfigs.CardType.golden then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.mini.golden, isAutoScale)
    elseif cardData.type == CardSysConfigs.CardType.wild then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.mini.wild, isAutoScale)
        self:addClick(self:findChild("bg"))
    elseif cardData.type == CardSysConfigs.CardType.wild_normal then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.mini.wild, isAutoScale)
        self:addClick(self:findChild("bg"))
    elseif cardData.type == CardSysConfigs.CardType.wild_golden then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.mini.wild, isAutoScale)
        self:addClick(self:findChild("bg"))
    elseif cardData.type == CardSysConfigs.CardType.wild_link then
        self:createCsbNode(CardResConfig.CardUnitCsbRes.mini.wild, isAutoScale)
        self:addClick(self:findChild("bg"))
    elseif cardData.type == CardSysConfigs.CardType.puzzle then -- 拼图卡
        self:createCsbNode(CardResConfig.CardUnitCsbRes.mini.puzzle, isAutoScale)
    else
        assert(false, " new card type ???")
    end

    local isHaveCard = self:isHaveCard()
    local cardIcon1, cardIcon2 = self:getCardIconNode()
    --拼图卡还没有资源
    if cardIcon1 and cardIcon2 then
        -- 是否强制使用居中的卡牌图标
        if self.m_isMiddleIcon == true then
            cardIcon1:setVisible(false)
            cardIcon2:setVisible(true)
        else
            cardIcon1:setVisible(not isHaveCard)
            cardIcon2:setVisible(isHaveCard)
        end
    end
    if actionName == "idle" then
        self:runCsbAction("idle")
    elseif actionName == "show" then
        self:runCsbAction(
            "show",
            nil,
            function()
                self:runCsbAction("idle")
            end
        )
    elseif actionName == "start" then
        self:runCsbAction(
            "start",
            nil,
            function()
                self:runCsbAction("idle")
            end
        )
    end
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function MiniCardUnitView:isShowLinkTip()
    local cardData = self:getCardData()
    if cardData.type == "LINK" and cardData.linkCount > 0 then
        return true
    end
    return false
end

function MiniCardUnitView:initLinkCardTip()
    -- local Node_linkTip = self:findChild("Node_linkTip")
    -- if self.m_linkTip == true and self:isShowLinkTip() then
    --     Node_linkTip:setVisible(true)
    --     local child = Node_linkTip:getChildByName("LinkTip")
    --     if not child then
    --         child = util_createView("GameModule.Card.views.LinkCardTip")
    --         child:setName("LinkTip")
    --         Node_linkTip:addChild(child)
    --     end
    --     child:updateUI()
    -- else
    --     Node_linkTip:setVisible(false)
    -- end
end

function MiniCardUnitView:updateUI()
    local cardData = self:getCardData()
    if cardData.type == CardSysConfigs.CardType.wild then
    elseif cardData.type == CardSysConfigs.CardType.wild_normal then
    elseif cardData.type == CardSysConfigs.CardType.wild_golden then
    elseif cardData.type == CardSysConfigs.CardType.wild_link then
    else
        MiniCardUnitView.super.updateUI(self)
    end
end

function MiniCardUnitView:setCardName()
    local nameLabel, nameHaveLabel, unHaveNode, haveNode = self:getNameNode()

    local isHaveCard = self:isHaveCard()
    if unHaveNode then
        unHaveNode:setVisible(not isHaveCard)
    end
    if haveNode then
        haveNode:setVisible(isHaveCard)
    end
    if isHaveCard then
        if nameHaveLabel then
            nameHaveLabel:setString(self.m_cardData.name)
        end
    else
        if nameLabel then
            nameLabel:setString(self.m_cardData.name)
        end
    end
end

function MiniCardUnitView:updateSpecialUI()
    self.nail = self:findChild("nail")
    self.nail_have = self:findChild("nail_have")

    self.bg = self:findChild("bg")
    self.line_have = self:findChild("line_have")

    -- 摁钉显示控制 --
    if self.nail then
        self.nail:setVisible(self.m_showNail)
        self.nail_have:setVisible(self.m_showNail)
    end

    local cardData = self:getCardData()
    local clanId = string.sub(cardData.clanId, 7, 8)
    -- 背景图片 --
    -- util_changeTexture(self.bg, string.format(CardResConfig., clanId) )
    -- 虚线图片 --
    util_changeTexture(self.line_have, string.format(CardResConfig.ClanCardNormalLinePath, clanId))
    -- 摁钉图片 --
    if self.m_showNail then
        util_changeTexture(self.nail_have, string.format(CardResConfig.ClanCardNailPath, clanId))
    end

    -- new图片 --
    local spNew = self:findChild("sp_new")
    if self.m_newFlag then
        spNew:setVisible(cardData.firstDrop == true)
    else
        spNew:setVisible(false)
    end

    -- 重置位置
    local newText = self:findChild("BitmapFontLabel_1")
    local newParentSize = newText:getParent():getContentSize()
    newText:setPosition(cc.p(newParentSize.width * 0.45, newParentSize.height * 0.5))
end

-- 点击事件 --
function MiniCardUnitView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_getin" then
        -- TODO: MAQUN 跳转
        print(" --------- TODO:跳转到其他界面 -----------")
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        local cardData = self:getCardData()
        local clanIdx, cardIndex = CardSysRuntimeMgr:getClanIndex(cardData)
        CardSysManager:showBigCardView(clanIdx, cardIndex)
    elseif name == "Button_ask" then
        -- TODO: MAQUN 需要对接链接
        print(" --------- TODO:需要对接链接 -----------")
    end
end

return MiniCardUnitView
