--[[--
    201903赛季
    筹码
]]
local MiniChipUnit = class("MiniChipUnit", BaseView)

function MiniChipUnit:getCommonCardIconRes()
    return "Common/CardClanLoading_201903.png"
end

function MiniChipUnit:setTouchCallBack(_clickBack)
    self.m_clickBack = _clickBack
end

function MiniChipUnit:initUI()
    self.m_isGrey = false
    MiniChipUnit.super.initUI(self)
end

function MiniChipUnit:getCsbName()
    --移动资源到包内
    return "CardsBase201903/CardRes/season201903/cash_card_chip_new.csb"
    -- return string.format(CardResConfig.seasonRes.CardMiniChipRes, "season201903")
end

function MiniChipUnit:initCsbNodes()
    self.m_nodeRoot = self:findChild("Node_root")
    self.m_spBg = self:findChild("sp_card_bg")
    self.m_spCardIcon = self:findChild("sp_cardIcon")
    self.m_spClanIcon = self:findChild("sp_clanIcon")
    self.m_fntName1 = self:findChild("lb_name_1")
    self.m_fntName2 = self:findChild("lb_name_2")
    self.m_fntName3 = self:findChild("lb_name_3")
    self.m_nodeStar = self:findChild("star")

    self.m_newNode = self:findChild("Node_new")
    self.m_numNode = self:findChild("Node_num")
    self.m_requestNode = self:findChild("Node_request")
    self.m_touchLayer = self:findChild("touch")
    self:addClick(self.m_touchLayer)
    self.m_touchLayer:setVisible(false)

    util_setCascadeColorEnabledRescursion(self.m_nodeRoot, true)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function MiniChipUnit:playAnimByIndex(index, nodeCard, playAnimFlag, callBack, totalCardNum)
    -- 默认一列有5个卡
    local colNum = 5
    if totalCardNum and totalCardNum > 0 then
        colNum = totalCardNum/2
    end
    if playAnimFlag then
        local secondsLine = (index - 1) / colNum
        performWithDelay(
            self,
            function()
                nodeCard:setVisible(true)
                self:runCsbAction(
                    "animation0",
                    false,
                    function()
                        self:runCsbAction("idle", true)
                        if callBack ~= nil then
                            callBack(index)
                        end
                    end
                )
            end,
            ((index - 1) % colNum) * 0.08 + (secondsLine > 0 and 0.04 or 0)
        )
    else
        nodeCard:setVisible(true)
        self:runCsbAction("idle", true)
        if callBack ~= nil then
            callBack(index)
        end
    end
end

function MiniChipUnit:playIdle()
    self:runCsbAction("idle", true)
end

function MiniChipUnit:changeIconsGrey(_node, isGrey, _color)
    if not _node then
        return
    end
    _color = _color or cc.c3b(127, 115, 150)
    local changeIconGrey = nil
    changeIconGrey = function(__parentNode)
        local __type = tolua.type(__parentNode)
        -- if __type == "cc.Sprite" or __type == "ccui.TextBMFont" then

        if isGrey == true then
            -- util_setSpriteGray(__parentNode)
            self.m_nodeRoot:setColor(_color)
        else
            -- util_clearSpriteGray(__parentNode)
            self.m_nodeRoot:setColor(cc.c3b(255, 255, 255))
        end
        local __children = __parentNode:getChildren()
        if __children then
            for i = 1, #__children do
                changeIconGrey(__children[i])
            end
        end
    end
    changeIconGrey(_node)
end

-- forceCardIcon 强制用卡牌的icon
-- forceStarLight 强制用高亮的星星
-- forceNoStar 强制不显示星星
-- forceNoName 强制不显示名字
-- enableGreyMask 启用灰色遮罩
function MiniChipUnit:reloadUI(cardData, forceCardIcon, forceStarLight, forceNoStar, forceNoName, enableGreyMask)
    self.m_cardData = cardData
    self.m_forceCardIcon = forceCardIcon
    self.m_forceStarLight = forceStarLight
    self.m_forceNoStar = forceNoStar
    self.m_forceNoName = forceNoName
    self.m_enableGreyMask = enableGreyMask

    -- 判断是否要置灰
    local _isGrey = false
    if self.m_enableGreyMask then
        -- 启用灰色遮罩时，如果未获得卡，并且不强制显示卡牌icon
        if self.m_cardData.count == 0 then
            _isGrey = true
        end
    end

    if _isGrey ~= self.m_isGrey then
        self:changeIconsGrey(self.m_nodeRoot, _isGrey)
        self.m_isGrey = _isGrey
    end

    self:updateCardBg()
    self:updateCardIcon(self.m_cardData.count > 0 or self.m_forceCardIcon)
    self:updateName(not self.m_forceNoName)
    self:updateObsidianTag(0.77)

    if not self.m_forceNoStar then
        self:updateStar()
    end

    -- util_setCascadeColorEnabledRescursion(self.m_nodeRoot, true)
    -- util_setCascadeOpacityEnabledRescursion(self, true)
end

function MiniChipUnit:updateCardBg()
    local cardBgRes = CardResConfig.getCardBgRes(self.m_cardData.type, self.m_cardData.count > 0 or self.m_forceCardIcon)
    if cardBgRes ~= nil then
        util_changeTexture(self.m_spBg, cardBgRes)
    end
end

function MiniChipUnit:updateCardIcon(haveCard)
    self.m_spCardIcon:setPositionY(0)
    self.m_spClanIcon:setVisible(false)
    if haveCard then
        local cardIconRes = CardResConfig.getCardIcon(self.m_cardData.cardId, nil, tonumber(self.m_cardData.albumId) == tonumber(CardNoviceCfg.ALBUMID))
        util_changeTexture(self.m_spCardIcon, cardIconRes)
    else
        if self.m_cardData.type == CardSysConfigs.CardType.normal then
            self.m_spCardIcon:setPositionY(27)
            local cardIconRes = CardResConfig.getCardClanIcon(self.m_cardData.clanId)
            util_changeTexture(self.m_spCardIcon, cardIconRes)
            self.m_spClanIcon:setVisible(true)
            util_changeTexture(self.m_spClanIcon, cardIconRes)
        elseif self.m_cardData.type == CardSysConfigs.CardType.golden then
            util_changeTexture(self.m_spCardIcon, "CardsBase201903/CardRes/Other/unHaveChip_Gold.png")
        elseif self.m_cardData.type == CardSysConfigs.CardType.link then
            util_changeTexture(self.m_spCardIcon, "CardsBase201903/CardRes/Other/unHaveChip_Nado.png")
        elseif self.m_cardData.type == CardSysConfigs.CardType.statue_green or self.m_cardData.type == CardSysConfigs.CardType.statue_blue or self.m_cardData.type == CardSysConfigs.CardType.statue_red then
            local cardIconRes = CardResConfig.getCardIcon(self.m_cardData.cardId, nil, tonumber(self.m_cardData.albumId) == tonumber(CardNoviceCfg.ALBUMID))
            util_changeTexture(self.m_spCardIcon, cardIconRes)
        elseif self.m_cardData.type == CardSysConfigs.CardType.quest_new then
            util_changeTexture(self.m_spCardIcon, "CardsBase201903/CardRes/Other/unHaveChip_Magic.png")
        elseif self.m_cardData.type == CardSysConfigs.CardType.quest_magic_red then
            util_changeTexture(self.m_spCardIcon, "CardsBase201903/CardRes/Other/unHaveChip_Mythic_Red.png")            
        elseif self.m_cardData.type == CardSysConfigs.CardType.quest_magic_purple then
            util_changeTexture(self.m_spCardIcon, "CardsBase201903/CardRes/Other/unHaveChip_Mythic_Purple.png")
        elseif self.m_cardData.type == CardSysConfigs.CardType.obsidian then
            util_changeTexture(self.m_spCardIcon, "CardsBase201903/CardRes/Other/unHaveChip_Obsidian.png")
        end
    end
end

function MiniChipUnit:updateName(isShowName)
    self.m_fntName1:setVisible(false)
    self.m_fntName2:setVisible(false)
    self.m_fntName3:setVisible(false)
    if isShowName then
        local nameStrs = string.split(self.m_cardData.name, "|")
        if #nameStrs == 1 then
            self.m_fntName3:setVisible(true)
            self.m_fntName3:setString(nameStrs[1])
        else
            self.m_fntName1:setVisible(true)
            self.m_fntName2:setVisible(true)
            self.m_fntName1:setString(nameStrs[1])
            self.m_fntName2:setString(nameStrs[2])
        end
        self:changeNameFntFile()
    end
end

function MiniChipUnit:changeNameFntFile()
    local fntRes = nil
    if self.m_cardData.type == CardSysConfigs.CardType.normal then
        fntRes = "CardsBase201903/CardRes/Other/chipFnt_normal.fnt"
    elseif self.m_cardData.type == CardSysConfigs.CardType.golden then
        fntRes = "CardsBase201903/CardRes/Other/chipFnt_golden.fnt"
    elseif self.m_cardData.type == CardSysConfigs.CardType.link then
        fntRes = "CardsBase201903/CardRes/Other/chipFnt_nado.fnt"
    end
    if fntRes ~= nil then
        self.m_fntName1:setFntFile(fntRes)
        self.m_fntName2:setFntFile(fntRes)
        self.m_fntName3:setFntFile(fntRes)
    end
end

function MiniChipUnit:updateStar()
    -- if util_IsFileExist("CardCode/season201903/CardTagStar.lua") or util_IsFileExist("CardCode/season201903/CardTagStar.luac") then
    local child = self.m_nodeStar:getChildByName("star")
    if not child then
        child = util_createView("GameModule.Card.season201903.CardTagStar")
        child:setName("star")
        self.m_nodeStar:addChild(child)
        util_setCascadeColorEnabledRescursion(self.m_nodeStar, true)
        util_setCascadeOpacityEnabledRescursion(self.m_nodeStar, true)
    end
    child:updateUI(self.m_cardData, self.m_forceStarLight)
    -- 这里接收一下star用来处理外面star的遮罩显示
    self.m_starChild = child
    -- end
end

--[[外部调用函数 ]]
function MiniChipUnit:updateTagNew(isShow)
    self.m_newNode:setVisible(isShow)
    if isShow then
        if not self.m_tagNewUI then
            self.m_tagNewUI = util_createView("GameModule.Card.season201903.CardTagNew")
            self.m_tagNewUI:playIdle()
            self.m_newNode:addChild(self.m_tagNewUI)
            self:changeIconsGrey(self.m_newNode, self.m_isGrey)
            util_setCascadeColorEnabledRescursion(self.m_newNode, true)
            util_setCascadeOpacityEnabledRescursion(self.m_newNode, true)
        end
    end
end

--[[外部调用函数 ]]
function MiniChipUnit:updateTagNum(num)
    if num and num > 1 then
        self.m_numNode:setVisible(true)
        if not self.m_tagNumUI then
            self.m_tagNumUI = util_createView("GameModule.Card.season201903.CardTagNum")
            self.m_numNode:addChild(self.m_tagNumUI)
            self:changeIconsGrey(self.m_numNode, self.m_isGrey)
            util_setCascadeColorEnabledRescursion(self.m_numNode, true)
            util_setCascadeOpacityEnabledRescursion(self.m_numNode, true)
        end
        self.m_tagNumUI:updateNum(num)
    else
        self.m_numNode:setVisible(false)
    end
end

--[[外部调用函数 ]]
function MiniChipUnit:updateTouchBtn(isVisible, isEnabled, isSwallow)
    self.m_touchLayer:setVisible(isVisible)
    self.m_touchLayer:setTouchEnabled(isEnabled)
    self.m_touchLayer:setSwallowTouches(isSwallow)
end

function MiniChipUnit:isShowRequest()
    if self.m_cardData.count > 0 then
        return false
    end
    if not self.m_cardData.gift then
        return false
    end
    if self.m_cardData.albumId ~= CardSysRuntimeMgr:getCurAlbumID() then
        return false
    end
    if not globalData.constantData.CLAN_OPEN_SIGN then
        return false
    end
    if CardSysManager:isNovice() then
        return false
    end
    return true
end

--[[外部调用函数 ]]
function MiniChipUnit:updateTagRequest()
    -- 判断显示条件
    if self:isShowRequest() then
        self.m_requestNode:setVisible(true)
        local tagReq = self.m_requestNode:getChildByName("REQUEST")
        if not tagReq then
            tagReq = util_createView("GameModule.Card.season201903.CardTagRequest")
            tagReq:setName("REQUEST")
            tagReq:setCardData(self.m_cardData)
            self.m_requestNode:addChild(tagReq)
            util_setCascadeColorEnabledRescursion(self.m_requestNode, true)
            util_setCascadeOpacityEnabledRescursion(self.m_requestNode, true)
        end
    else
        self.m_requestNode:setVisible(false)
        self.m_requestNode:removeAllChildren()
    end
end

--[[外部调用函数 ]]
function MiniChipUnit:setCardGrey(_isGrey, _color)
    self:changeIconsGrey(self.m_nodeRoot, _isGrey, _color)
    self:changeIconsGrey(self.m_newNode, _isGrey, _color)
    self:changeIconsGrey(self.m_numNode, _isGrey, _color)
end

function MiniChipUnit:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        CardSysManager:showBigCardView(self.m_cardData)
        if self.m_clickBack then
            self.m_clickBack()
        end
    end
end

-- 为了解决小猪送缺卡遮罩显示问题提供方法处理节点或者sprite的颜色透明度
--[[外部调用函数 ]]
function MiniChipUnit:updateStarOpacity(_color, _opacity)
    if self.m_starChild then
        self.m_starChild:setStarOpciaty(_color, _opacity)
    end
end

--[[外部调用函数 ]]
function MiniChipUnit:updateBgOpacity(_color, _opacity)
    if self.m_spBg then
        self.m_spBg:setColor(util_changeHexToColor(_color))
        self.m_spBg:setOpacity(_opacity)
    end
end

--[[外部调用函数 ]]
function MiniChipUnit:updateIconOpacity(_color, _opacity)
    local node_Parent = self:findChild("Node_card")
    if node_Parent then
        node_Parent:setColor(util_changeHexToColor(_color))
        node_Parent:setOpacity(_opacity)
    end
end

function MiniChipUnit:getCardSize()
    return cc.size(380, 380)
end

function MiniChipUnit:getCardData()
    return self.m_cardData
end

function MiniChipUnit:getAppearTime()
    local time = self.m_csbAct ~= nil and util_csbGetAnimTimes(self.m_csbAct, "animation0", 30)
    return time or 20 / 30
end

--[[(黑曜卡通过标签区分赛季)]]
function MiniChipUnit:updateObsidianTag(_scale)
    if self.m_cardData.type ~= CardSysConfigs.CardType.obsidian then
        return
    end
    local node_Parent = self:findChild("Node_card")
    if node_Parent then 
        local scale = _scale or 1
        local isHave = self.m_cardData.count == 1
        local tagIconRes = CardResConfig.getObsidianCardTagIcon(self.m_cardData.cardId, isHave)
        local tag = util_createSprite("" .. tagIconRes)
        tag:setPosition(-147, -60)
        tag:setScale(scale)
        node_Parent:addChild(tag)
    end
end

return MiniChipUnit
