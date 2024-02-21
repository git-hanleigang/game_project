--[[
    author:{author}
    time:2019-07-16 14:35:39
]]
local BaseView = util_require("base.BaseView")
local BigCardLayer = class("BigCardLayer", BaseView)
BigCardLayer.m_showNum = 10

function BigCardLayer:getCsbName()
    return string.format(CardResConfig.seasonRes.BigCardLayerRes, "season201903")
end

function BigCardLayer:getMiniChipLua()
    return "GameModule.Card.season201903.MiniChipUnit"
end

function BigCardLayer:getBigCardTextLua()
    return "GameModule.Card.season201903.BigCardTxt"
end

function BigCardLayer:getRequestButtonRes()
    return "GameModule.Card.season201903.CardTagRequest_big"
end

function BigCardLayer:initUI(cardData)
    self:setExtendData("BigCardLayer")
    local maskUI = util_newMaskLayer()
    self:addChild(maskUI, -1)
    maskUI:setOpacity(192)

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode(self:getCsbName(), isAutoScale)

    self.m_cardData = cardData

    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle")
        end
    )

    self.m_btnSend = self:findChild("btn_send")
    -- self.m_btnSend:setVisible(false)

    self:updateUI()
end

function BigCardLayer:updateUI()
    -- 卡牌信息
    local Node_chouma = self:findChild("Node_chouma")
    local view = util_createView(self:getMiniChipLua())
    view:playIdle()
    view:reloadUI(self.m_cardData)
    view:updateTagNew(self.m_isNewCard == true)
    view:updateTagNum(self.m_cardData.count)

    Node_chouma:addChild(view)
    -- 卡牌描述
    if self.m_cardData.count > 0 then
        self:findChild("title"):setVisible(false)
    else
        self:findChild("title"):setVisible(true)
    end

    if self.m_cardData.type == CardSysConfigs.CardType.obsidian then
        local closeBtn = self:findChild("Button_x")
        if closeBtn then
            local normalPath = string.format("CardRes/CardObsidian_%s/ui/other/Album_close1.png", self.m_cardData.season)
            local selectedPath = string.format("CardRes/CardObsidian_%s/ui/other/Album_close2.png", self.m_cardData.season)
            closeBtn:setScale9Enabled(false)
            closeBtn:loadTextures(normalPath, selectedPath, selectedPath, ccui.TextureResType.localType)
        end

        if self.m_cardData.isHistory then
            self:findChild("title"):setVisible(false)
        end
    end

    -- -- 详细描述TODO:
    -- -- CardSysConfigs.DropFromDes201903
    -- local sources = string.split(self.m_cardData.source, ";")
    -- for i=1,4 do
    --     local desLb = self:findChild("Node_"..i):getChildByName("BitmapFontLabel_1")
    --     if i <= #sources then
    --         desLb:setVisible(true)
    --         local sourceId = tonumber(sources[i])
    --         local desStr = CardSysConfigs.DropFromDes201903[sourceId]
    --         desLb:setString(desStr)
    --     else
    --         desLb:setVisible(false)
    --     end
    -- end

    local sources = {}
    if self.m_cardData.count > 0 then
        local sourceList = string.split(self.m_cardData.description, ";")
        sources = sourceList
    else
        local sourceList = string.split(self.m_cardData.source, ";")
        for i = 1, #sourceList do
            local sourceId = tonumber(sourceList[i])
            local desStr = CardSysConfigs.DropFromDes201903[sourceId]
            if desStr then
                sources[#sources + 1] = desStr
            end
        end
    end
    self:initSources(sources)

    -- 显示send按钮
    if CardSysManager:hasSeasonOpening() and self.m_cardData.gift == true and not CardSysRuntimeMgr:isPastAlbum(self.m_cardData.albumId) and not CardSysManager:isNovice() then
        if self.m_cardData.count > 1 then
            -- 送卡
            self.m_btnSend:setVisible(true)
            if self.m_btnRequest then
                self.m_btnRequest:setVisible(false)
            end
        elseif self.m_cardData.count == 1 or self.m_cardData.albumId ~= CardSysRuntimeMgr:getCurAlbumID() then
            -- 一张卡不可以送也不也可以要
            self.m_btnSend:setVisible(false)
            if self.m_btnRequest then
                self.m_btnRequest:setVisible(false)
            end
        else
            -- 要卡
            self.m_btnSend:setVisible(false)
            if not self.m_btnRequest and globalData.constantData.CLAN_OPEN_SIGN then
                local view = util_createView(self:getRequestButtonRes())
                if view then
                    view:setCardData(self.m_cardData)
                    local posy = self.m_btnSend:getPositionY()
                    local parent = self.m_btnSend:getParent()
                    parent:addChild(view)
                    -- x轴随父节点走 y轴跟send按钮一致
                    view:setPositionY(posy)
                    view:setVisible(true)
                    self.m_btnRequest = view
                end
            end
            if self.m_btnRequest then
                self.m_btnRequest:updateCountdown()
            end
        end
    else
        self.m_btnSend:setVisible(false)
    end
end

function BigCardLayer:initSources(sourceList)
    -- sourceList = {
    --     "aaaaaaaaaaaaaaaaaaaa",
    --     "bbbbbbbbbbbbbbbbbbbbbbbbb",
    --     -- "cccccccccc",
    --     -- "dddddddddddddddddd",
    --     -- "ffffffffffffffffffffffffffffffff",
    -- }
    local certerY = 0
    local offsetY = 50
    local startY = 0
    startY = certerY + (#sourceList - 1) * offsetY / 2

    local desNode = self:findChild("Node_des")
    self.m_sourceNodes = {}
    for i = 1, #sourceList do
        local view = util_createView(self:getBigCardTextLua())
        desNode:addChild(view)
        view:setPosition(cc.p(0, startY - (i - 1) * offsetY))

        view:updateStr(sourceList, i)
        self.m_sourceNodes[i] = view
    end

    local delayTime = 0.2
    local index = 1
    local function playStart()
        if self.m_sourceNodes[index] then
            self.m_sourceNodes[index]:playStart()
        end
        index = index + 1
        if index <= #self.m_sourceNodes then
            performWithDelay(
                self,
                function()
                    playStart(index)
                end,
                delayTime
            )
        end
    end
    playStart(index)
end

function BigCardLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_x" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeBigCardView()
    elseif name == "btn_send" then
        -- 打开邮箱
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeBigCardView()

        CardSysManager:exitCard()

        G_GetMgr(G_REF.Inbox):showInboxLayer(
            {
                selIndex = 2,
                chooseState = "ChooseFriend",
                chooseType = "CARD"
            }
        )
    end
end

function BigCardLayer:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    self:removeFromParent()
end

return BigCardLayer
