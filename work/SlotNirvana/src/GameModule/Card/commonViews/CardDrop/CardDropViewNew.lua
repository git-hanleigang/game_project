--[[--
    掉落界面重构
]]
local CardDropViewNew = class("CardDropViewNew", BaseLayer)

function CardDropViewNew:initDatas(dropData)
    self.m_DropInfo = dropData
    assert(self.m_DropInfo.source ~= nil, "CARD DropData dont have source!!!")

    self.m_cfgDropType = CardSysConfigs.DropViewType[self.m_DropInfo.type]
    assert(self.m_cfgDropType ~= nil, "CardSysConfigs.DropViewType dont have droptype " .. self.m_DropInfo.type)

    self.m_dropLinkClanId = self:getDropLink()
    -- self.m_storeNormalPoints, self.m_storeGoldPoints = self:getStorePoints()

    self:setLandscapeCsbName("CardsBase201903/CardRes/season201903/cash_drop_layer_new.csb")
    self:setPortraitCsbName("CardsBase201903/CardRes/season201903/cash_drop_layer_new_shu.csb")

    -- self:setShowActionEnabled(false)

    self:setPauseSlotsEnabled(true)
    self:setExtendData("CardDropViewNew")
end

-- 初始化基本UI --
function CardDropViewNew:initCsbNodes()
    self.m_nodeScale = self:findChild("node_scale")
    self.m_nodeStoreTickets = self:findChild("Node_storeTickets")
    -- 背景光 --
    -- self.m_bgLigt = self:findChild("backLightNode")
    -- Title图片 --
    self.m_spTitle = self:findChild("sp_title")

    -- 飘带上的文字 --
    self.m_Text_Source = self:findChild("font_source")
    self.m_piao = self:findChild("img_piaodai")
    self.m_clipLayout = self:findChild("font")
    self.m_clipLayout:setVisible(false)
    -- 卡
    self.m_nodeCards = self:findChild("Node_list")
    -- 卡包 --
    self.m_nodePackage = self:findChild("Node_Package")

    -- 关闭按钮 --
    self.m_closeBtn = self:findChild("Button_1")

    -- 收集按钮 --
    self.m_collectBtn = self:findChild("Button_6")
    self.m_collectBtn:setVisible(false)

    -- link跳转按钮 --
    self.m_checkItNode = self:findChild("Node_checkit")
    self.m_checkItNode:setVisible(false)

    self.m_Tex_TapToSee = self:findChild("Node_taptosee")

    -- 集卡小猪
    self.m_nodeChipPiggy = self:findChild("Node_chipPiggy")

    -- 点击事件 --
    self.m_ClickNode = self:findChild("btn_ClickPkg")
    self:addClick(self.m_ClickNode)
    self.m_ClickNode:setEnabled(false)
end

function CardDropViewNew:initView()
    -- 根据包类型显示不同状态 --
    self:initCards()
    -- self:initBgLight()
    self:initCloseBtn()
    self:initTapTip()
    self:initTitle()
    self:updateTitleBg()
    self:initChipPiggy()

    -- self.m_initing = true
    -- util_performWithDelay(
    --     self,
    --     function()
    --         if not tolua.isnull(self) then
    --             self.m_initing = false
    --         end
    --     end,
    --     0.5
    -- )
    -- gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    -- self:runCsbAction(
    --     "show",
    --     false,
    --     function()
    --         if not tolua.isnull(self) then
    --             self:runCsbAction("idle", true)
    --         end
    --     end
    -- )

    util_setCascadeColorEnabledRescursion(self, true)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

-- function CardDropViewNew:initBgLight()
--     if self.m_cfgDropType and self.m_cfgDropType.bgLight then
--         self:showBgLight(true)
--     end
-- end

function CardDropViewNew:initCloseBtn()
    if self.m_cfgDropType and self.m_cfgDropType.showClose then
        self.m_closeBtn:setVisible(true)
    end
end

function CardDropViewNew:initTapTip()
    if self.m_cfgDropType and self.m_cfgDropType.isTap then
        local view = util_createView("GameModule.Card.commonViews.CardDrop.CardDropPackageTip")
        self.m_Tex_TapToSee:addChild(view)
        view:updateIcon(CardSysRuntimeMgr:isWildDropType(self.m_DropInfo.type))
        view:setVisible(false)
        self.m_tapUI = view
    end
end

function CardDropViewNew:initTitle()
    local info = self:getSourceInfo(self.m_cfgDropType.sourceKey)
    -- 标题
    if info and info.title ~= nil then
        local resPath = "CardsBase201903/CardRes/season201903/Other/" .. CardSysConfigs.DropViewTitle[info.title] .. ".png"
        if util_IsFileExist(resPath) then
            util_changeTexture(self.m_spTitle, resPath)
        end
    end
    -- 标题声音
    if info and info.music then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC[info.music])
    end
    -- 描述文字
    if info and info.des ~= nil then
        self.m_Text_Source:setString(info.des)
    end
end

-- 初始化集卡小猪
function CardDropViewNew:initChipPiggy()
    if not self.m_nodeChipPiggy then
        return
    end
    local isCanShow = CardSysManager:checkIsCanShowChipPiggy(self.m_DropInfo.source)
    if not isCanShow then
        return
    end
    local chipPiggyNode = G_GetMgr(ACTIVITY_REF.ChipPiggy):createCollectChipPiggyNode()
    if not chipPiggyNode then
        return
    end
    self.m_nodeChipPiggy:addChild(chipPiggyNode)
    self.m_chipPiggyNode = chipPiggyNode
end

--显示标题和彩
function CardDropViewNew:updateTitleBg()
    local showTime = 1 --开始出现时间
    local overTime = 1.5 --完全出现时间
    local offWidth = 60 --彩带去除裁切区域的宽度
    local orgSize = self.m_clipLayout:getContentSize()
    local oPSize = self.m_piao:getContentSize()
    local orgPiaoSize = {width = oPSize.width, height = oPSize.height} --飘带原始尺寸
    local newPiaoWidth = self.m_Text_Source:getContentSize().width * self.m_Text_Source:getScale() + 200 --飘带根据字体缩放的尺寸
    self.m_clipLayout:setVisible(false)

    newPiaoWidth = math.min(math.max(orgPiaoSize.width, newPiaoWidth), display.width)

    self.m_piao:setContentSize(cc.size(newPiaoWidth, orgPiaoSize.height))
    performWithDelay(
        self,
        function()
            if tolua.isnull(self) then
                return
            end
            self.m_clipLayout:setVisible(true)
            local size = self.m_piao:getContentSize()
            local runTime = overTime - showTime --运行时间
            local targetWidth = size.width - offWidth --目标宽度
            local clipWidth = 300 --增量
            self.m_clipLayout:setContentSize(clipWidth, orgSize.height)
            self.m_Text_Source:setPositionX(clipWidth * 0.5)
            local frameLen = targetWidth * 0.5 / runTime --秒宽度
            local function update(dt)
                if tolua.isnull(self) then
                    return
                end
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

function CardDropViewNew:initCards()
    local cfg = self.m_cfgDropType
    self.m_nodePackage:setVisible(cfg.packageType and true or false)
    self.m_cardPackages = {}
    if cfg.packageType then
        local packageLuaNames = {
            "CardDropBox",
            "CardDropBox",
            "CardDropWild",
            "CardDropStatue"
        }
        if cfg.packageType == 5 then
            local UIList = {}
            for dropType, num in pairs(self.m_DropInfo.mergedTypes) do
                local _cfg = CardSysConfigs.DropViewType[dropType]
                local cardPackage = util_createView("GameModule.Card.commonViews.CardDrop." .. packageLuaNames[_cfg.packageType])
                self.m_nodePackage:addChild(cardPackage)
                table.insert(self.m_cardPackages, cardPackage)
                table.insert(UIList, {node = cardPackage, anchor = cc.p(0.5, 0.5), size = cardPackage:getBoxSize()})

                cardPackage:updateUI(dropType, num)
                cardPackage:playStart(
                    function()
                        if not tolua.isnull(self) and not tolua.isnull(cardPackage) then
                            if not self.m_ClickNode:isEnabled() then
                                self.m_ClickNode:setEnabled(true)
                            end
                            cardPackage:playBreathe()
                        end
                    end
                )
            end
            util_alignCenter(UIList)
        else
            local cardPackage = util_createView("GameModule.Card.commonViews.CardDrop." .. packageLuaNames[cfg.packageType])
            self.m_nodePackage:addChild(cardPackage)
            table.insert(self.m_cardPackages, cardPackage)

            cardPackage:updateUI(self.m_DropInfo.type)
            cardPackage:playStart(
                function()
                    if not tolua.isnull(self) and self.m_tapUI then
                        self.m_tapUI:setVisible(true)
                        self.m_tapUI:playStart(
                            function()
                                if not tolua.isnull(self) and not tolua.isnull(cardPackage) then
                                    if not self.m_ClickNode:isEnabled() then
                                        self.m_ClickNode:setEnabled(true)
                                    end
                                    cardPackage:playBreathe()
                                end
                            end
                        )
                    end
                end
            )
        end
    else
        performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    self:initListView()
                end
            end,
            0.2
        )
        performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    self:updateBottomBtn()
                end
            end,
            0.5
        )
    end

    -- 非wild自动关闭
    if not cfg.isWild and globalData.slotRunData.checkViewAutoClick then
        globalData.slotRunData:checkViewAutoClick(self, "Button_1")
    end
end

function CardDropViewNew:initListView()
    self.m_listUI = util_createView("GameModule.Card.commonViews.CardDrop.CardDropList", self.m_DropInfo.cards)
    self.m_nodeCards:addChild(self.m_listUI)
    if self.m_chipPiggyNode then
        self.m_chipPiggyNode:playAnimation()
    end
end

function CardDropViewNew:showNadoMachineBtn()
    self.m_machineUI = util_createView("GameModule.Card.commonViews.CardDrop.CardDropMachine", self)
    self.m_checkItNode:addChild(self.m_machineUI)
    self.m_machineUI:updateNum(self:getNadoGameInitNum())
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropNadoWheelAppear)
    self.m_machineUI:playStart(
        function()
            if not tolua.isnull(self) then
                self:flyLinkParticle()
            end
        end
    )
end

function CardDropViewNew:flyLinkParticle()
    local flyCards = self.m_listUI:getNadoChips()
    local flynum = #flyCards
    local flyTime = 0.5
    local index = 1

    local nadoMachineNum = self:getNadoGameInitNum()

    local machineBtn = self.m_machineUI:getMachineBtn()
    local flyParticle = nil
    flyParticle = function(index)
        if tolua.isnull(self) then
            return
        end
        local flyObj = flyCards[index]
        local flyCardData = flyObj:getCardData()

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
                if not tolua.isnull(particle) then
                    particle:removeFromParent()
                end
            end
        )
        local seq = cc.Sequence:create(delayFunc, callFunc)
        local spawn = cc.Spawn:create(playShakeSound, seq)

        particle:runAction(cc.Sequence:create(moveTo, spawn))

        nadoMachineNum = nadoMachineNum + flyCardData.nadoCount
        performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    self.m_machineUI:playFlyto()
                end
            end,
            flyTime
        )
        performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    self.m_machineUI:updateNum(nadoMachineNum)
                end
            end,
            flyTime + 6 / 30
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
            if not tolua.isnull(self) then
                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropNadoWheelMoveLeft)
                self.m_machineUI:playShowBtn()
            end
        end,
        btnTime
    )
end

function CardDropViewNew:createFlyParticle()
    local flyParticle = cc.ParticleSystemQuad:create("CardsBase201903/CardRes/season201903/lizi/CashCards_jiahao_tuowei.plist")
    return flyParticle
end

-- function CardDropViewNew:createStoreTicket(_storeType)
--     local view = util_createView("GameModule.Card.commonViews.CardDrop.CardDropStoreTicket", _storeType)
--     self.m_nodeStoreTickets:addChild(view)
--     return view
-- end

-- function CardDropViewNew:showStoreTickets(_over)
--     local isOverCall = false
--     local function callFunc()
--         if isOverCall then
--             return
--         end
--         isOverCall = true
--         if _over then
--             _over()
--         end
--     end
--     if self.m_storeNormalPoints == 0 and self.m_storeGoldPoints == 0 then
--         callFunc()
--         return
--     end
--     local UIList = {}
--     self.m_storeTickets = {}
--     if self.m_storeNormalPoints > 0 then
--         local view = self:createStoreTicket("normal")
--         table.insert(UIList, {node = view, anchor = cc.p(0.5, 0.5), scale = 1, size = view:getTicketSize()})
--         table.insert(self.m_storeTickets, view)
--         view:startScroll(callFunc, self.m_storeNormalPoints)
--     end
--     if self.m_storeGoldPoints > 0 then
--         local view = self:createStoreTicket("gold")
--         table.insert(UIList, {node = view, anchor = cc.p(0.5, 0.5), scale = 1, size = view:getTicketSize()})
--         table.insert(self.m_storeTickets, view)
--         view:startScroll(callFunc, self.m_storeGoldPoints)
--     end
--     util_alignCenter(UIList)
-- end

-- function CardDropViewNew:showStorePoints(_over)
--     self.m_listUI:setListTouchEnabled(false)
--     performWithDelay(
--         self.m_listUI,
--         function()
--             self.m_listUI:scrollToStoreChip(
--                 function()
--                     self.m_listUI:setListTouchEnabled(true)
--                     self:showStoreTickets(_over)
--                 end
--             )
--         end,
--         1
--     )
-- end

function CardDropViewNew:updateBottomBtn()
    -- 显示按钮 --
    if self.m_dropLinkClanId ~= nil and CardSysManager:checkShowCheckIt(self.m_DropInfo.source) and CardSysManager:checkIsInNewQuest() and CardSysManager:checkIsInPassMission() then
        self:showNadoMachineBtn()

        if CardSysManager:hasSeasonOpening() then
            self.m_checkItNode:setVisible(true)
            self.m_collectBtn:setVisible(false)
        else
            self.m_checkItNode:setVisible(false)
            self.m_collectBtn:setVisible(true)
        end
    else
        -- if self.m_storeNormalPoints > 0 or self.m_storeGoldPoints > 0 then
        --     self:showStorePoints(
        --         function()
        --             self.m_checkItNode:setVisible(false)
        --             self.m_collectBtn:setVisible(true)
        --         end
        --     )
        -- else
        --     self.m_checkItNode:setVisible(false)
        --     self.m_collectBtn:setVisible(true)
        -- end
        self.m_checkItNode:setVisible(false)
        self.m_collectBtn:setVisible(true)
    end
end

-- 点击开卡包操作 --
function CardDropViewNew:clickOpenPackage()
    if self.m_tapUI and self.m_tapUI:isVisibleEx() then
        self.m_tapUI:setVisible(false)
    end
    if self.m_cfgDropType.isWild then
        local _tbWild = {
            [CardSysConfigs.CardDropType.wild] = CardSysConfigs.CardType.wild,
            [CardSysConfigs.CardDropType.wild_normal] = CardSysConfigs.CardType.wild_normal,
            [CardSysConfigs.CardDropType.wild_link] = CardSysConfigs.CardType.wild_link,
            [CardSysConfigs.CardDropType.wild_golden] = CardSysConfigs.CardType.wild_golden,
            [CardSysConfigs.CardDropType.wild_obsidian] = CardSysConfigs.CardType.wild_obsidian,
            [CardSysConfigs.CardDropType.quest_wild_red] = CardSysConfigs.CardType.wild_magic_red,
            [CardSysConfigs.CardDropType.quest_wild_purple] = CardSysConfigs.CardType.wild_magic_purple,
        }
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropClickWild)
        self:closeDropView(3, nil, _tbWild[self.m_DropInfo.type])
    else
        if self.m_DropInfo.type == CardSysConfigs.CardDropType.link then
            -- 引导打点：Card引导-3.领取link卡
            if CardSysManager:isInGuide() then
                if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                    gLobalSendDataManager:getLogGuide():sendGuideLog(8, 3)
                end
            end
        end
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropOpenPack)
            end,
            0.92
        )
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropBoxOpen)
        if self.m_cardPackages and #self.m_cardPackages > 0 then
            -- self:showBgLight(false)
            for i = 1, #self.m_cardPackages do
                self.m_cardPackages[i]:playOpen(
                    function()
                        if not tolua.isnull(self) then
                            if i == #self.m_cardPackages then
                                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropChipAppear)
                                performWithDelay(
                                    self,
                                    function()
                                        if not tolua.isnull(self) then
                                            self:initListView()
                                        end
                                    end,
                                    0.2
                                )
                                performWithDelay(
                                    self,
                                    function()
                                        if not tolua.isnull(self) then
                                            self:updateBottomBtn()
                                        end
                                    end,
                                    0.5
                                )
                            end
                        end
                    end,
                    function()
                        if not tolua.isnull(self) then
                            if i == #self.m_cardPackages then
                                self.m_nodePackage:setVisible(false)
                            end
                        end
                    end
                )
            end
        end
    end
end

-- 直接显示nado轮盘
function CardDropViewNew:clickCheckIt()
    if CardSysManager:isDownLoadCardRes() then
        -- 引导打点：Card引导-4.进入集卡界面
        if CardSysManager:isInGuide() then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                gLobalSendDataManager:getLogGuide():setGuideParams(8, {result = 1})
                gLobalSendDataManager:getLogGuide():sendGuideLog(8, 4)
            end
        end
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

--调用管理类里面的关闭方法
function CardDropViewNew:closeDropView(closeType, dropLinkClanId, wildType)

    local function closeFunc()
        if not tolua.isnull(self) then
            self:closeUI(
                function()
                    CardSysManager:getDropMgr():closeDropView(closeType, dropLinkClanId, wildType)
                    -- 收集结束，刷新一下章节选择界面上的卡牌信息
                    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_ALBUM_LIST_UPDATE)
                end
            )
        end
    end

    -- 增加飞金币逻辑（新手期多余的卡直接转变为金币）
    local exchangeCoins = self:getConvertCoins()
    if exchangeCoins > 0 then
        local flyNode = nil
        if self.m_checkItNode:isVisibleEx() then
            flyNode = self.m_machineUI:getMachineBtn()
        elseif self.m_collectBtn:isVisibleEx() then
            flyNode = self.m_collectBtn
        else
            flyNode = self.m_nodePackage
        end
        if flyNode then
            local startPos = flyNode:getParent():convertToWorldSpace(cc.p(flyNode:getPosition()))
            G_GetMgr(G_REF.Currency):playFlyCurrency({cuyType = FlyType.Coin, addValue = exchangeCoins, startPos = startPos}, closeFunc)
        else
            closeFunc()
        end
    else
        closeFunc()
    end

end

function CardDropViewNew:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardDropViewNew.super.playShowAction(self, "show", false)
end

function CardDropViewNew:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

-- function CardDropViewNew:canClick()
--     if self.m_initing then
--         return false
--     end
--     return true
-- end

function CardDropViewNew:clickFunc(sender)
    -- if not self:canClick() then
    --     return
    -- end
    local name = sender:getName()
    if name == "Button_1" then
        -- 清除后续打点
        if CardSysManager:isInGuide() then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                gLobalSendDataManager:getLogGuide():cleanParams(8)
            end
        end
        self:closeDropView(1)
    elseif name == "Button_6" then
        self:closeDropView(1)
    elseif name == "Button_checkit" then
        self:clickCheckIt()
    elseif name == "btn_ClickPkg" then
        if self.m_clickPackage then
            return
        end
        self.m_clickPackage = true
        self.m_ClickNode:setEnabled(false)
        self:clickOpenPackage()
    end
end

function CardDropViewNew:onEnter()
    CardDropViewNew.super.onEnter(self)
end

function CardDropViewNew:getSourceInfo(_sourceKey)
    local sourceCfg = CardSysManager:getDropMgr():getDropSourceCfgBySource(self.m_DropInfo.source)
    local info = sourceCfg[_sourceKey]
    if not info then
        local cfg = CardSysManager:getDropMgr():getDropSourceInfo(self.m_DropInfo.source)
        info = cfg[_sourceKey]
    end
    if self.m_DropInfo.type == CardSysConfigs.CardDropType.single then
        local cardsNum = 0
        for i = 1, #self.m_DropInfo.cards do
            local cardData = self.m_DropInfo.cards[i]
            cardsNum = cardsNum + cardData.count
        end
        if cardsNum == 1 then
            if self.m_DropInfo.cards[1].type == CardSysConfigs.CardType.puzzle then
                info.des = string.format(info.des, cardsNum .. " PUZZLE CHIP")
            elseif CardSysRuntimeMgr:isQuestMagicCard(self.m_DropInfo.cards[1].type) then
                info.des = string.format(info.des, cardsNum .. " MYTHIC CHIP")
            else
                info.des = string.format(info.des, cardsNum .. " FORTUNE CHIP")
            end
        elseif cardsNum > 1 then
            info.des = string.format(info.des, cardsNum .. " FORTUNE CHIPS")
        end
    end
    return info
end

-- 获得nado机上的小红点初始数量
function CardDropViewNew:getNadoGameInitNum()
    local totalNum = CardSysRuntimeMgr:getNadoGameLeftCount() or 0 -- self.m_DropInfo.nadoGames -- 总数
    local getNum = 0
    for i = 1, #self.m_DropInfo.cards do
        local cardData = self.m_DropInfo.cards[i]
        if cardData and cardData.type == CardSysConfigs.CardType.link then
            getNum = getNum + cardData.nadoCount
        end
    end
    return math.max(0, totalNum - getNum)
end

function CardDropViewNew:getDropLink()
    -- 判断是否有link卡掉落 --
    if self.m_DropInfo and self.m_DropInfo.cards and #self.m_DropInfo.cards > 0 then
        for i = 1, #self.m_DropInfo.cards do
            local cardData = self.m_DropInfo.cards[i]
            if cardData.type == CardSysConfigs.CardType.link then
                if tonumber(cardData.albumId) == tonumber(CardSysRuntimeMgr:getCurAlbumID()) then
                    return cardData.clanId
                end
            end
        end
    end
    return nil
end

-- function CardDropViewNew:getStorePoints()
--     local normalPoints, goldPoints = 0, 0
--     if self.m_DropInfo and self.m_DropInfo.cards and #self.m_DropInfo.cards > 0 then
--         for i = 1, #self.m_DropInfo.cards do
--             local cardData = self.m_DropInfo.cards[i]
--             normalPoints = normalPoints + (cardData.greenPoint or 0) * (cardData.count or 1)
--             goldPoints = goldPoints + (cardData.goldPoint or 0) * (cardData.count or 1)
--         end
--     end
--     return normalPoints, goldPoints
-- end

-- 新手期多余的卡转换成金币，直接加到玩家身上
function CardDropViewNew:getConvertCoins()
    local exchangeCoins = 0
    if self.m_DropInfo and self.m_DropInfo.cards and #self.m_DropInfo.cards > 0 then
        for i = 1, #self.m_DropInfo.cards do
            local cardData = self.m_DropInfo.cards[i]
            exchangeCoins = exchangeCoins + (cardData.exchangeCoins or 0) * (cardData.count or 1)
        end
    end
    return exchangeCoins
end

return CardDropViewNew
