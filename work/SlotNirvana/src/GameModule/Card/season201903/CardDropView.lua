--[[
    集卡系统 卡片卡组掉落界面
]]
local BaseCardDropView = util_require("GameModule.Card.baseViews.BaseCardDropView")
local CardDropView = class("CardDropView", BaseCardDropView)

function CardDropView:initDatas(dropData)
    CardDropView.super.initDatas(self, dropData)
    --移动资源到包内
    self:setLandscapeCsbName("CardsBase201903/CardRes/season201903/cash_drop_layer.csb")
    self:setPortraitCsbName("CardsBase201903/CardRes/season201903/cash_drop_layer_portrait.csb")
end

function CardDropView:initUI(dropData)
    CardDropView.super.initUI(self, dropData)
end

function CardDropView:onShowedCallFunc()
    self:runCsbAction("idle", true)
    if self.isClose then
        return
    end
    -- 如果是普通卡 则直接飞卡 --
    if self.m_DropInfo.type == CardSysConfigs.CardDropType.single then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropChipAppear)
        self:initDropCard()
        self.m_listUI:playStart(
            function()
                self:startDropCard()
            end
        )

        performWithDelay(
            self,
            function()
                if self.m_isAutoClose then
                    self:initAutoClose()
                end
            end,
            0.25
        )
    end
end

-- 初始化基本UI --
function CardDropView:initCsbNodes()
    -- 背景光 --
    self.m_bgLigt = self:findChild("backLightNode")
    -- Title图片 --
    self.m_Title_ohYeah = self:findChild("oh_29")
    self.m_Title_Wow = self:findChild("wow_8")
    self.m_Title_Congrats = self:findChild("congrats_1")
    self.m_Title_Awesome = self:findChild("awesome_2")

    -- 飘带上的文字 --
    self.m_Text_Source = self:findChild("font_source")
    self.m_piao = self:findChild("piaodai_3")
    self.m_clipLayout = self:findChild("font")
    self.m_clipLayout:setVisible(false)
    -- 卡
    self.m_cardNode = self:findChild("Node_Card")
    self.m_listNode = self:findChild("Node_list")
    -- 卡包 --
    self.m_cardPackageNode = self:findChild("Node_Package")
    self.m_Tex_WildCard = self:findChild("Node_wild")
    self.m_Tex_GoldenPkg = self:findChild("Node_goldenbox")
    self.m_statuePackageNode = self:findChild("Node_statue")

    -- 关闭按钮 --
    self.m_closeBtn = self:findChild("Button_1")
    self.m_closeBtn:setVisible(true)

    -- 收集按钮 --
    self.m_collectBtn = self:findChild("Button_6")
    self.m_collectBtn:setVisible(false)

    -- link跳转按钮 --
    self.m_checkItNode = self:findChild("Node_checkit")
    self.m_checkItNode:setVisible(false)

    -- 分享按钮 --
    self.m_shareTxt = self:findChild("BitmapFontLabel_6")
    if self.m_shareTxt then
        self.m_shareTxt:setVisible(false)
    end
    self.m_shareBtn = self:findChild("Button_7")
    if self.m_shareBtn then
        self.m_shareBtn:setVisible(false)
    end

    self.m_Tex_TapToSee = self:findChild("Node_taptosee")

    -- 点击事件 --
    self.m_ClickNode = self:findChild("btn_ClickPkg")
    self:addClick(self.m_ClickNode)
    self.m_ClickNode:setEnabled(false)
end

function CardDropView:initView()
    CardDropView.super.initView(self)
    self:initList()
    self:initTapTip()

    self:initWildPackage()
    self:initStatuePackage()
end

function CardDropView:initViewByType()
    CardDropView.super.initViewByType(self)

    self:showTitleByType()
end

-- 获得nado机上的小红点初始数量
function CardDropView:getNadoGameInitNum()
    local totalNum = self.m_DropInfo.nadoGames -- 总数

    local getNum = 0
    for i = 1, #self.m_DropInfo.cards do
        local cardData = self.m_DropInfo.cards[i]
        if cardData and cardData.type == CardSysConfigs.CardType.link then
            getNum = getNum + cardData.nadoCount
        end
    end

    return math.max(0, totalNum - getNum)
end

function CardDropView:initNadoMachine()
    self.m_machineUI = util_createView("GameModule.Card.commonViews.CardDrop.CardDropMachine", self)
    self.m_checkItNode:addChild(self.m_machineUI)
    self.m_machineUI:updateNum(self:getNadoGameInitNum())
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropNadoWheelAppear)
    self.m_machineUI:playStart()
end

function CardDropView:updateBottomBtn()
    -- 显示按钮 --
    if CardSysManager:hasSeasonOpening() then
        if self.m_dropLinkClanId ~= nil
            and CardSysManager:checkShowCheckIt(self.m_sourceCfg.source) 
            and CardSysManager:checkIsInNewQuest() 
            and CardSysManager:checkIsInPassMission() then
            self.m_checkItNode:setVisible(true)
            self.m_collectBtn:setVisible(false)

            self:initNadoMachine()
            performWithDelay(
                self,
                function()
                    self:flyLinkParticle()
                end,
                0.5
            )
        else
            self.m_checkItNode:setVisible(false)
            self.m_collectBtn:setVisible(true)
        end
    else
        self.m_checkItNode:setVisible(false)
        self.m_collectBtn:setVisible(true)
    end
end

function CardDropView:flyLinkParticle()
    local flyCards = self.m_cardDropShow:getLinkCards()
    local flynum = #flyCards
    local flyTime = 0.5
    local index = 1

    local nadoMachineNum = self:getNadoGameInitNum()

    local machineBtn = self.m_machineUI:getMachineBtn()
    local flyParticle = nil
    flyParticle = function(index)
        local flyCard = flyCards[index]
        local flyObj = flyCard.spObj
        local flyCardData = flyCard.cardData

        local startPosWord = flyObj:getParent():convertToWorldSpace(cc.p(flyObj:getPosition()))
        local startPos = cc.p(self:convertToNodeSpace(startPosWord))
        local endPosWord = machineBtn:getParent():convertToWorldSpace(cc.p(machineBtn:getPosition()))
        local endPos = cc.p(self:convertToNodeSpace(endPosWord))

        local particle = self:createFlyParticle()
        particle:setPosition(startPos)
        self:addChild(particle)
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropFlyLizi)

        local moveTo = cc.MoveTo:create(flyTime, endPos)

        local playShakeSound =
            cc.CallFunc:create(
            function()
                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropNadoWheelShake)
            end
        )
        local delayFunc = cc.DelayTime:create(0.2)
        local callFunc =
            cc.CallFunc:create(
            function()
                particle:removeFromParent()
            end
        )
        local seq = cc.Sequence:create(delayFunc, callFunc)
        local spawn = cc.Spawn:create(playShakeSound, seq)

        particle:runAction(cc.Sequence:create(moveTo, spawn))

        nadoMachineNum = nadoMachineNum + flyCardData.nadoCount
        performWithDelay(
            self,
            function()
                self.m_machineUI:playFlyto()
                performWithDelay(
                    self,
                    function()
                        self.m_machineUI:updateNum(nadoMachineNum)
                    end,
                    6 / 30
                )
            end,
            flyTime
        )

        index = index + 1
        if index <= flynum then
            performWithDelay(
                self,
                function()
                    flyParticle(index)
                end,
                flyTime + 1
            )
        end
    end
    if index <= flynum then
        flyParticle(index)
    end

    local btnTime = flynum * (1.5 + flyTime)
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropNadoWheelMoveLeft)
            self.m_machineUI:playShowBtn()
        end,
        btnTime
    )
end

function CardDropView:createFlyParticle()
    local flyParticle = cc.ParticleSystemQuad:create("CardsBase201903/CardRes/season201903/lizi/CashCards_jiahao_tuowei.plist")
    return flyParticle
end

function CardDropView:initList()
    self.m_listUI = util_createView("GameModule.Card.commonViews.CardDrop.CardDropList")
    self.m_listNode:addChild(self.m_listUI)
end

function CardDropView:createShowList()
    local dropListUI = util_createView("GameModule.Card.season201903.CardDropShow", self.m_listUI:getListView())
    return dropListUI
end

function CardDropView:initTapTip()
    self.m_tapUI = util_createView("GameModule.Card.commonViews.CardDrop.CardDropPackageTip")

    local isWildPackage = false
    if CardSysRuntimeMgr:isWildDropType(self.m_DropInfo.type) then
        isWildPackage = true
    end
    self.m_tapUI:updateIcon(isWildPackage)
    self.m_Tex_TapToSee:addChild(self.m_tapUI)
end

function CardDropView:initWildPackage()
    self.m_dropWild = util_createView("GameModule.Card.commonViews.CardDrop.CardDropWild")
    self.m_Tex_WildCard:addChild(self.m_dropWild)
end

function CardDropView:initStatuePackage()
    self.m_dropStatuePackage = util_createView("GameModule.Card.commonViews.CardDrop.CardDropStatue")
    self.m_statuePackageNode:addChild(self.m_dropStatuePackage)
end

function CardDropView:showTitleByType()
    local title = ""
    local des = ""
    local scale = 1
    local info = nil
    if self.m_DropInfo.type == CardSysConfigs.CardDropType.normal then
        info = self.m_sourceCfg.normalPackage
        if not info then
            local sourceCfg = CardSysManager:getDropMgr():getDropSourceInfo(self.m_DropInfo.source)
            info = sourceCfg.normalPackage
        end
        title = info.title
        des = info.des
        scale = 1.2
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.link then
        info = self.m_sourceCfg.linkPackage
        if not info then
            local sourceCfg = CardSysManager:getDropMgr():getDropSourceInfo(self.m_DropInfo.source)
            info = sourceCfg.linkPackage
        end
        title = info.title
        des = info.des
        scale = 1.3
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.golden then
        info = self.m_sourceCfg.goldenPackage
        if not info then
            local sourceCfg = CardSysManager:getDropMgr():getDropSourceInfo(self.m_DropInfo.source)
            info = sourceCfg.goldenPackage
        end
        title = info.title
        des = info.des
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.single then
        info = self.m_sourceCfg.single
        if not info then
            local sourceCfg = CardSysManager:getDropMgr():getDropSourceInfo(self.m_DropInfo.source)
            info = sourceCfg.single
        end
        title = info.title
        -- 描述文字
        local cardsNum = 0
        for i = 1, #self.m_DropInfo.cards do
            local cardData = self.m_DropInfo.cards[i]
            cardsNum = cardsNum + cardData.count
        end
        if cardsNum == 1 then
            if self.m_DropInfo.cards[1].type == CardSysConfigs.CardType.puzzle then
                des = string.format(info.des, cardsNum .. " PUZZLE CHIP")
            else
                des = string.format(info.des, cardsNum .. " FORTUNE CHIP")
            end
        elseif cardsNum > 1 then
            des = string.format(info.des, cardsNum .. " FORTUNE CHIPS")
        end
    elseif CardSysRuntimeMgr:isWildDropType(self.m_DropInfo.type) then
        info = self.m_sourceCfg.wildCard
        if not info then
            local sourceCfg = CardSysManager:getDropMgr():getDropSourceInfo(self.m_DropInfo.source)
            info = sourceCfg.wildCard
        end
        title = info.title
        des = info.des
    elseif CardSysRuntimeMgr:isStatueDropType(self.m_DropInfo.type) then
        info = self.m_sourceCfg.statuePackage
        if not info then
            local sourceCfg = CardSysManager:getDropMgr():getDropSourceInfo(self.m_DropInfo.source)
            info = sourceCfg.statuePackage
        end
        title = info.title
        des = info.des
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.merge then
        info = self.m_sourceCfg.mergePackage
        if not info then
            local sourceCfg = CardSysManager:getDropMgr():getDropSourceInfo(self.m_DropInfo.source)
            info = sourceCfg.mergePackage
        end
        title = info.title
        des = info.des
    end

    -- 标题
    self:showTitle(title)
    -- 描述文字
    self.m_Text_Source:setString(des)
    self:resetTitleBgSize(scale)
    -- 标题声音
    if info and info.music then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC[info.music])
    end
end

--显示标题和彩带
function CardDropView:updateTitle()
    local showTime = 12 / 30 --开始出现时间
    local overTime = 25 / 30 --完全出现时间
    local offWidth = 160 --彩带去除裁切区域的宽度
    local orgSize = self.m_clipLayout:getContentSize()
    local orgPiaoSize = {width = 940, height = 96} --飘带原始尺寸
    local newPiaoWidth = self.m_Text_Source:getContentSize().width * self.m_Text_Source:getScale() + 200 --飘带根据字体缩放的尺寸
    self.m_piao:setContentSize(cc.size(math.max(orgPiaoSize.width, newPiaoWidth), orgPiaoSize.height))
    performWithDelay(
        self,
        function()
            self.m_clipLayout:setVisible(true)
            local size = self.m_piao:getContentSize()
            local runTime = overTime - showTime --运行时间
            local targetWidth = size.width - offWidth --目标宽度
            local frameLen = targetWidth / runTime --秒宽度
            local clipWidth = 0 --增量
            local function update(dt)
                runTime = runTime - dt
                clipWidth = clipWidth + frameLen * dt
                if runTime <= 0 then
                    self:unscheduleUpdate()
                    clipWidth = targetWidth
                end
                self.m_clipLayout:setContentSize(clipWidth, orgSize.height)
                self.m_Text_Source:setPositionX(clipWidth * 0.5)
            end
            self:onUpdate(update)
        end,
        showTime
    )
end

function CardDropView:resetViewShow()
    CardDropView.super.resetViewShow(self)
    self.m_statuePackageNode:setVisible(false)
end

function CardDropView:showCommonPackage()
    self:showBgLight(true)
    self.m_cardPackageNode:setVisible(true)
    self:normalPackage_Idle(
        function()
            self.m_Tex_TapToSee:setVisible(true)
            self.m_tapUI:playStart(
                function()
                    self.m_ClickNode:setEnabled(true)
                    self:normalPackage_Breathe()
                end
            )
        end
    )
end

function CardDropView:showLinkPackage()
    self:showBgLight(true)
    self.m_cardPackageNode:setVisible(true)
    self:linkPackage_Idle(
        function()
            self.m_Tex_TapToSee:setVisible(true)
            self.m_tapUI:playStart(
                function()
                    self.m_ClickNode:setEnabled(true)
                    self:linkPackage_Breathe()
                end
            )
        end
    )
end

function CardDropView:showGoldenPackage()
    self:showBgLight(true)
    self.m_Tex_TapToSee:setVisible(true)
    self.m_Tex_GoldenPkg:setVisible(true)
    self.m_tapUI:playStart(
        function()
            self.m_ClickNode:setEnabled(true)
        end
    )
end

function CardDropView:showSingleCardDrop()
end

function CardDropView:showWildCardDrop()
    self:showBgLight(true)
    self.m_Tex_WildCard:setVisible(true)
    self.m_closeBtn:setVisible(false)

    self.m_dropWild:playStart(
        function()
            self.m_Tex_TapToSee:setVisible(true)
            self.m_tapUI:playStart(
                function()
                    self.m_ClickNode:setEnabled(true)
                    self.m_dropWild:playBreathe()
                end
            )
        end
    )
    self.m_dropWild:updateUI(self.m_DropInfo.type)
end

function CardDropView:showStatuePackage()
    self:showBgLight(true)
    self.m_statuePackageNode:setVisible(true)
    self.m_closeBtn:setVisible(false)

    self.m_dropStatuePackage:playStart(
        function()
            self.m_Tex_TapToSee:setVisible(true)
            self.m_tapUI:playStart(
                function()
                    self.m_ClickNode:setEnabled(true)
                    self.m_dropStatuePackage:playBreathe()
                end
            )
        end
    )
    self.m_dropStatuePackage:updateUI(self.m_DropInfo.type)
end

function CardDropView:statuePackage_Open(cardAppear, packageDisappear)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropBoxOpen)
    self.m_dropStatuePackage:playOpen(
        function()
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropChipAppear)
            self:initDropCard()
            self.m_listUI:playStart(
                function()
                    if cardAppear then
                        cardAppear()
                    end
                end
            )
        end,
        packageDisappear
    )
end

function CardDropView:getDropLightRes()
    --移动资源到包内
    return "CardsBase201903/CardRes/season201903/cash_drop_light.csb"
    -- return string.format(CardResConfig.seasonRes.CardDropLight201903Res, "season201903")
end

-- 显示背景光
function CardDropView:showBgLight(isShow)
    -- 可以直接显示背景光 --
    if isShow then
        self.m_bgLigt:setVisible(true)
        local selectNode, selectAct = util_csbCreate(self:getDropLightRes())
        self.m_bgLigt:addChild(selectNode)
        util_csbPlayForKey(
            selectAct,
            "start",
            false,
            function()
                util_csbPlayForKey(selectAct, "idle", true)
            end,
            30
        )
    else
        local callF = function()
            self.m_bgLigt:setVisible(false)
        end
        local opa = cc.FadeOut:create(0.7)
        local callFunc = cc.CallFunc:create(callF)
        local seq = cc.Sequence:create(opa, callFunc)
        self.m_bgLigt:runAction(seq)
    end
end

-- 卡包的骨骼动画
function CardDropView:cardPackage_initSpine()
    local size = self.m_cardPackageNode:getContentSize()
    self.m_cardPackage = util_createView("GameModule.Card.commonViews.CardDrop.CardDropBox")
    self.m_cardPackage:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
    self.m_cardPackageNode:addChild(self.m_cardPackage)
end

-- link卡 idle 动画 --
function CardDropView:linkPackage_Idle(overFunc)
    self.m_cardPackage:changeBox(true)
    self.m_cardPackage:updateBoxNum(1)
    self.m_cardPackage:playStart(overFunc)
end

function CardDropView:linkPackage_Breathe()
    self.m_cardPackage:playBreathe()
end

-- link卡 开卡包 动画 --
function CardDropView:linkPackage_Open(cardAppear, packageDisappear)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropBoxOpen)
    self.m_cardPackage:playOpen(
        function()
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropChipAppear)
            self:initDropCard()
            self.m_listUI:playStart(
                function()
                    if cardAppear then
                        cardAppear()
                    end
                end
            )
        end,
        packageDisappear
    )
end

-- 普通卡 idle 动画 --
function CardDropView:normalPackage_Idle(overFunc)
    self.m_cardPackage:changeBox(false)
    self.m_cardPackage:updateBoxNum(1)
    self.m_cardPackage:playStart(overFunc)
end

function CardDropView:normalPackage_Breathe()
    self.m_cardPackage:playBreathe()
end

-- 普通卡 开卡包 动画 --
function CardDropView:normalPackage_Open(cardAppear, packageDisappear)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropBoxOpen)
    self.m_cardPackage:playOpen(
        function()
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropChipAppear)
            self:initDropCard()
            self.m_listUI:playStart(
                function()
                    if cardAppear then
                        cardAppear()
                    end
                end
            )
        end,
        packageDisappear
    )
end

-- 直接显示nado轮盘
function CardDropView:clickCheckIt()
    if CardSysManager:isDownLoadCardRes() then
        -- 引导打点：Card引导-4.进入集卡界面
        if CardSysManager:isInGuide() then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                gLobalSendDataManager:getLogGuide():setGuideParams(8, {result = 1})
                gLobalSendDataManager:getLogGuide():sendGuideLog(8, 4)
            end
        end

        self.m_checkOutFlag = true
        self:closeDropView(2, self.m_dropLinkClanId)
    else
        -- 引导打点：Card引导-4.进入集卡界面
        if CardSysManager:isInGuide() then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                gLobalSendDataManager:getLogGuide():setGuideParams(8, {result = 0})
                gLobalSendDataManager:getLogGuide():sendGuideLog(8, 4)
            end
        end
        -- 清除后续打点
        if CardSysManager:isInGuide() then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                gLobalSendDataManager:getLogGuide():cleanParams(8)
            end
        end

        self:closeDropView(1, self.m_dropLinkClanId)
    end
end

function CardDropView:initDropCardData(_cardDatas)
    if not (_cardDatas and #_cardDatas > 0) then
        return
    end
    local CardSortTable = {
        [CardSysConfigs.CardType.normal] = 1,
        [CardSysConfigs.CardType.golden] = 2,
        [CardSysConfigs.CardType.link] = 3,
        [CardSysConfigs.CardType.puzzle] = 4,
        [CardSysConfigs.CardType.statue_green] = 5,
        [CardSysConfigs.CardType.statue_blue] = 5,
        [CardSysConfigs.CardType.statue_red] = 5
    }
    local flyCardsData = {}
    local flyCardsNum = 0
    for i = 1, #_cardDatas do
        local cardData = _cardDatas[i]
        -- 计算数量
        flyCardsNum = flyCardsNum + cardData.count
        for j = 1, cardData.count do
            flyCardsData[#flyCardsData + 1] = cardData
        end
        -- 排序参数
        cardData.sortIndex = 0
        if CardSysRuntimeMgr:isCardNormalPoint(cardData) or CardSysRuntimeMgr:isCardGoldPoint(cardData) then
            cardData.sortIndex = 100
        end
        cardData.sortIndex = cardData.sortIndex + CardSortTable[cardData.type]
    end
    -- 排序
    table.sort(
        flyCardsData,
        function(card1, card2)
            if card1.sortIndex == card2.sortIndex then
                if card1.star == card2.star then
                    return tonumber(card1.cardId) < tonumber(card2.cardId)
                else
                    return card1.star < card2.star
                end
            else
                return card1.sortIndex < card2.sortIndex
            end
        end
    )
    return flyCardsNum, flyCardsData
end

function CardDropView:initDropCard()
    -- 此行代码屏蔽，如果集卡数据没有返回，会影响掉落的飞行的卡牌数据
    -- local bHasLogin = CardSysRuntimeMgr:hasLoginCardSys()
    -- if bHasLogin == false then
    --     return
    -- end
    self.m_flyNum, self.m_flyData = self:initDropCardData()
    local useClanIcon = true
    if self.m_sourceCfg.source == "Wild Exchange" then
        useClanIcon = false
    end
    if self.m_flyData and #self.m_flyData > 0 then
        self.m_cardDropShow:initCards(self.m_flyData, useClanIcon)
    end
end

-- 掉落卡片动画 --
function CardDropView:startDropCard()
    -- 判断是否已经正常获取集卡系统数据信息 --
    -- local bHasLogin = CardSysRuntimeMgr:hasLoginCardSys()
    -- if bHasLogin == false then
    --     return
    -- end

    local flyTime = self.m_cardDropShow:flyCards()

    -- 判断是是否有link卡掉落
    self:setDropLink(self.m_flyData)
    -- 计算动画时间 --
    performWithDelay(
        self,
        function()
            self:updateBottomBtn()
            if self.m_isAutoClose then
                -- 开始计算倒计时5s后自动关闭
                self.m_autoCloseStartTime = 0
            end
        end,
        flyTime
    )
    return flyTime
end
return CardDropView
