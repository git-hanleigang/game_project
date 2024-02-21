--[[--
    掉落界面重构 V2
]]

-- 卡片飞行间隔
local FLY_INTERVAL = 0.08

-- 飞到卡牌列表中的卡片飞行时间
local OPEN_FLY_TIME = 0.3

-- 上移时间
local MOVE_UP_TIME = 0.3

-- 飞到章节列表和商城的卡片的飞行时间
local REWARD_FLY_TIME_1 = 0.2 -- 放大时间
local REWARD_FLY_TIME_2 = 0.2 -- 缩小时间

-- 等待时间
local FLY_DELAY = 0.3

-- 飞到章节列表的卡片多余10个时，用飞粒子的方式
local REWARD_FLY_FIRST_DROP_NUM = 10
 
local CardDropViewNew = class("CardDropViewNew", BaseLayer)

function CardDropViewNew:initDatas(dropData)
    self.m_DropInfo = dropData
    assert(self.m_DropInfo.source ~= nil, "CARD DropData dont have source!!!")

    self.m_cfgDropType = CardSysConfigs.DropViewType[self.m_DropInfo.type]
    assert(self.m_cfgDropType ~= nil, "CardSysConfigs.DropViewType dont have droptype " .. self.m_DropInfo.type)

    self.m_dropLinkClanId = self:getDropLink()

    -- self.m_isMergePackage = false
    -- if self.m_DropInfo.type == CardSysConfigs.CardDropType.merge then
    --     self.m_isMergePackage = true
    -- end

    self:setLandscapeCsbName("CardsBase201903/CardRes/season201903/DropNew2/cash_drop_layer.csb")
    self:setPortraitCsbName("CardsBase201903/CardRes/season201903/DropNew2/cash_drop_layer_shu.csb")

    self:setPauseSlotsEnabled(true)
    self:setExtendData("CardDropViewNew")

    self.m_skipEffective = false
end

-- 初始化基本UI --
function CardDropViewNew:initCsbNodes()
    self.m_nodeScale = self:findChild("node_scale")
    self.m_nodeStore = self:findChild("Node_store")
    self.m_nodeNadoMachine = self:findChild("Node_nadoMachine")

    self.m_nodeBgLight = self:findChild("node_backLight")
    -- Title图片 --
    self.m_layerTitle = self:findChild("layer_title")
    self.m_spTitle = self:findChild("sp_title")

    -- 飘带上的文字 --
    self.m_Text_Source = self:findChild("font_source")
    self.m_piao = self:findChild("img_piaodai")
    self.m_clipLayout = self:findChild("font")
    self.m_clipLayout:setVisible(false)
    -- 卡
    self.m_nodeCards = self:findChild("Node_list")
    self.m_nodeClans = self:findChild("Node_list_album")
    self.m_nodeCardsPosX = self.m_nodeCards:getPositionX()
    
    -- 卡包 --
    self.m_nodePackage = self:findChild("Node_Package")
    -- 新增卡包打开后的叠加卡牌
    self.m_nodeBoxChips = self:findChild("Node_boxChips")

    -- 关闭按钮 --
    self.m_closeBtn = self:findChild("Button_1")

    -- 收集按钮 --
    self.m_collectBtn = self:findChild("Button_collect")
    if self:isHaveNodoMachine() then
        self:setButtonLabelContent("Button_collect", "PLAY NOW")
    else
        self:setButtonLabelContent("Button_collect", "COLLECT")
    end 
    self.m_collectBtn:setVisible(false)

    -- -- link跳转按钮 --
    -- self.m_checkItNode = self:findChild("Node_checkit")
    -- self.m_checkItNode:setVisible(false)

    -- 跳过按钮 --
    self.m_skipBtn = self:findChild("Button_skip")
    self:setButtonLabelContent("Button_skip", "SKIP")
    self.m_skipBtn:setVisible(false)

    self.m_Tex_TapToSee = self:findChild("Node_taptosee")

    -- 集卡小猪
    self.m_nodeChipPiggy = self:findChild("Node_chipPiggy")

    -- 点击事件 --
    self.m_ClickNode = self:findChild("btn_ClickPkg")
    self:addClick(self.m_ClickNode)
    self.m_ClickNode:setEnabled(false)

    -- 飞行层级节点， 保证最高
    self.m_flyNode = self:findChild("node_fly")
end

function CardDropViewNew:initView()
    -- 根据包类型显示不同状态 --
    self:initCardPackages()
    self:initCloseBtn()
    self:initTapTip()
    self:initTitle()
    self:updateTitleBg()
    
    util_setCascadeColorEnabledRescursion(self, true)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CardDropViewNew:initCloseBtn()
    self.m_closeBtn:setVisible(self.m_cfgDropType.showClose == true)
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

function CardDropViewNew:showTap(_over)
    self.m_tapUI:setVisible(true)
    self.m_tapUI:playStart(_over)
end

function CardDropViewNew:hideTap()
    if self.m_tapUI and self.m_tapUI:isVisibleEx() then
        self.m_tapUI:setVisible(false)
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

function CardDropViewNew:initCardPackages()
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
                local cardPackage = util_createView("GameModule.Card.commonViews.CardDropV2." .. packageLuaNames[_cfg.packageType], self.m_DropInfo)
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
            local cardPackage = util_createView("GameModule.Card.commonViews.CardDropV2." .. packageLuaNames[cfg.packageType])
            self.m_nodePackage:addChild(cardPackage)
            table.insert(self.m_cardPackages, cardPackage)

            cardPackage:updateUI(self.m_DropInfo.type)
            cardPackage:playStart(
                function()
                    if not tolua.isnull(self) and self.m_tapUI then
                        self:showTap(function()
                            if not tolua.isnull(self) and not tolua.isnull(cardPackage) then
                                if not self.m_ClickNode:isEnabled() then
                                    self.m_ClickNode:setEnabled(true)
                                end
                                cardPackage:playBreathe()
                            end                            
                        end)
                    end
                end
            )
        end
    -- else -- 暂时不支持这里打开单卡，以为单卡的位置是正中间
    --     performWithDelay(
    --         self,
    --         function()
    --             if not tolua.isnull(self) then
    --                 self:initListView()
    --             end
    --         end,
    --         0.2
    --     )
    --     performWithDelay(
    --         self,
    --         function()
    --             if not tolua.isnull(self) then
    --                 self:updateBottomBtn()
    --             end
    --         end,
    --         0.5
    --     )
    end

    -- 非wild自动关闭
    if not cfg.isWild and globalData.slotRunData.checkViewAutoClick then
        globalData.slotRunData:checkViewAutoClick(self, "Button_1")
    end
end

function CardDropViewNew:delayFunc(_over, _time)
    print("delayFunc")
    if self.m_skipEffective then
        if _over then
            _over()
        end
    else
        util_performWithDelay(self, _over, _time)
    end
end

function CardDropViewNew:doNextFunc()
    print("doNextFunc")
    if table.nums(self.m_funcList) == 0 then
        return
    end
    local function callBack()
        if not tolua.isnull(self) then
            self:doNextFunc()
        end
    end
    local funcList = table.remove(self.m_funcList, 1)
    if funcList and table.nums(funcList) > 0 then
        local func = funcList[1]
        func(callBack, funcList[2], funcList[3], funcList[4])
    end
end

function CardDropViewNew:initViewAfterOpen()
    self:initChipPiggy()
    self:initPackageChips()
    self:initChipList()
    self:initClanList()
    self:initStore()
    self:initNadoMachine()
    
    util_setCascadeColorEnabledRescursion(self, true)
    util_setCascadeOpacityEnabledRescursion(self, true)
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

function CardDropViewNew:playChipPiggyAction(_over)
    if self.m_chipPiggyNode then
        self.m_chipPiggyNode:playAnimation()
    end
    if _over then
        _over()
    end
end

function CardDropViewNew:initPackageChips()
    local boxChips = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropBoxChips", self.m_DropInfo.cards)
    self.m_nodeBoxChips:addChild(boxChips)
    self.m_boxChips = boxChips
end

function CardDropViewNew:initChipList()
    self.m_chipList = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropChipList", self.m_DropInfo.cards)
    self.m_nodeCards:addChild(self.m_chipList)

    -- 如果全是旧卡，卡牌列表放在正中间
    local num = self:getFirstDropCardNum()
    if num == 0 then
        self.m_nodeCards:setPositionX(0)
    end
end

function CardDropViewNew:hasClanList()
    local clanCollects = self.m_DropInfo.clanCollects
    if clanCollects and table_length(clanCollects) > 0 then
        return true
    end
    return false
end

function CardDropViewNew:initClanList()
    if not self:hasClanList() then
        return
    end
    self.m_clanList = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropClanList", self.m_DropInfo.cards, self.m_DropInfo.clanCollects)
    self.m_nodeClans:addChild(self.m_clanList)
    self:setClanListVisible(false)
end

function CardDropViewNew:setClanListVisible(_isShow)
    if self.m_clanList then
        self.m_clanList:setVisible(_isShow == true)
    end
end

function CardDropViewNew:initStore()
    local normalPoint, goldenPoint = self:getStorePoints()

    self.m_store = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropStore", normalPoint, goldenPoint)
    self.m_nodeStore:addChild(self.m_store)
    self:setStoreVisible(false)
end

function CardDropViewNew:setStoreVisible(_isShow)
    if self.m_store then
        self.m_store:setVisible(_isShow == true)
    end
end

function CardDropViewNew:isHaveNodoMachine()
    if self.m_dropLinkClanId == nil then
        return false
    end
    if not CardSysManager:checkShowCheckIt(self.m_DropInfo.source) then
        return false
    end
    if not CardSysManager:checkIsInNewQuest() then
        return false
    end
    if not CardSysManager:checkIsInPassMission() then
        return false
    end
    return true
end

function CardDropViewNew:initNadoMachine()
    if not self:isHaveNodoMachine() then
        return
    end
    local machine = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropMachine")
    self.m_nodeNadoMachine:addChild(machine)
    self.m_machineUI = machine

    self.m_machineUI:updateNum(self:getNadoGameInitNum())

    self:setNodoMachineVisible(false)
end

function CardDropViewNew:setNodoMachineVisible(_isShow)
    if self.m_machineUI then
        self.m_machineUI:setVisible(_isShow == true)
    end
end

function CardDropViewNew:doOpenPackageLogic()
    self.m_funcList = {}
    -- 开卡包动画
    table.insert(self.m_funcList, { handler(self, self.openPackage) })
    -- 显示skip按钮
    table.insert(self.m_funcList, { handler(self, self.openPackageHideBtn) })
    table.insert(self.m_funcList, { handler(self, self.delayFunc), FLY_DELAY})
    -- 集卡小猪
    table.insert(self.m_funcList, { handler(self, self.playChipPiggyAction) })
    -- 飞到卡牌列表中
    table.insert(self.m_funcList, { handler(self, self.flyChipToChipList) })
    -- Nado机结算
    table.insert(self.m_funcList, { handler(self, self.flyLinkParticle) })
    
    -- 单卡包卡片结算
    -- 飞到章节列表中
    table.insert(self.m_funcList, { handler(self, self.delayFunc), FLY_DELAY})
    
    if self:getFirstDropCardNum() > REWARD_FLY_FIRST_DROP_NUM  then
        -- 飞入章节卡消失，出现金粒子，飞入章节     
        table.insert(self.m_funcList, { handler(self, self.playMergeParticleShow)})
        table.insert(self.m_funcList, { handler(self, self.flyChipParticleToClanList)})
        table.insert(self.m_funcList, { handler(self, self.playMergeParticleOver)})
    else
        table.insert(self.m_funcList, { handler(self, self.flyChipToClanList) })
    end    
    -- 上移卡牌列表
    table.insert(self.m_funcList, { handler(self, self.delayFunc), FLY_DELAY})
    table.insert(self.m_funcList, { handler(self, self.moveUpChipList) })
    -- 多余卡转换成商城积分/多余卡转换成金币
    table.insert(self.m_funcList, { handler(self, self.playChipSwitch) })
    -- 展示飞行的积分商券
    table.insert(self.m_funcList, { handler(self, self.showFlyStoreTickets) })
    -- 飞到商店
    table.insert(self.m_funcList, { handler(self, self.flyToStore) })    

    -- 隐藏跳过按钮、显示领取按钮
    table.insert(self.m_funcList, { handler(self, self.openPackageOver) })

    self:doNextFunc()
end

function CardDropViewNew:openPackage(_over)
    print("CardDropViewNew:openPackage")
    if not (self.m_cardPackages and #self.m_cardPackages > 0) then
        return
    end
    performWithDelay(self, function()
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropOpenPack)
    end,0.92)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropBoxOpen)
    for i = 1, #self.m_cardPackages do
        self.m_cardPackages[i]:playOpen(function()
            if not tolua.isnull(self) then
                self.m_boxChips:playStart()
            end
        end)
    end
    local open1Time = 21/30
    local open2Time = 20/30
    performWithDelay(self, _over, open1Time + open2Time)
end

function CardDropViewNew:openPackageHideBtn(_over)
    self.m_skipBtn:setVisible(true)
    if _over then
        _over()
    end
end

function CardDropViewNew:openPackageOver(_over)
    if not self.m_skipEffective then
        self.m_skipBtn:setVisible(false)
        self.m_collectBtn:setVisible(true)
    end
    self.m_closeBtn:setVisible(true)
    if _over then
        _over()
    end
end

function CardDropViewNew:flyChipToChipList(_over)
    print("CardDropViewNew:flyChipToChipList")
    local cardNodes = self.m_boxChips:getCardNodes()
    if not (cardNodes and #cardNodes > 0) then
        return
    end

    local parentNode = self.m_chipList:getChipParentLayer()
    local chipPosList = self.m_chipList:getChipPosList()
    local bottomPos = self.m_chipList:getChipBottomPos()
    for i=1,#cardNodes do
        local flyNode = cardNodes[i]
        local pos = chipPosList[i]
        if i > REWARD_FLY_FIRST_DROP_NUM or self.m_skipEffective then
            util_changeNodeParent(parentNode, flyNode)
            flyNode:setPosition(cc.p(pos.x, pos.y))
            self.m_chipList:addChips(flyNode)
        else
            local x = pos.x
            local y = pos.y
            if pos.y < bottomPos.y then
                x = bottomPos.x
                y = bottomPos.y
            end
            local wPos = parentNode:convertToWorldSpace(cc.p(x, y))
            flyNode:resetChipParticle()
            self:flyTo(i, flyNode, #cardNodes-(i-1), wPos, function()
                if not tolua.isnull(flyNode) and not tolua.isnull(self) then
                    flyNode:stopChipParticle()
                    util_changeNodeParent(parentNode, flyNode)
                    flyNode:setPosition(cc.p(pos.x, pos.y))
                    self.m_chipList:addChips(flyNode)
                end
            end)
        end
    end
    -- 飞完后做下一步
    local flyNum = math.min(#cardNodes, REWARD_FLY_FIRST_DROP_NUM)
    local deleyTime = self.m_skipEffective and 0 or FLY_INTERVAL*(flyNum) + OPEN_FLY_TIME
    util_performWithDelay(self, _over, deleyTime)
end

function CardDropViewNew:playMergeParticleShow(_over)
    if self.m_skipEffective then
        if _over then
            _over()
        end
        return        
    end
    -- 卡消失
    self.m_chipList:playChipListAction({"firstDrop"}, "over")
    -- 粒子出现
    self.m_chipList:createMergeParticle()
    self.m_chipList:playMergeParticleStart(_over)
end

function CardDropViewNew:flyChipParticleToClanList(_over)
    if self.m_skipEffective then
        self:setClanListVisible(true)
        if _over then
            _over()
        end
        return        
    end
    -- 飞的粒子
    self.m_chipList:playMergeParticleFly(_over)
    -- 飞入章节
    local flyNode = self.m_chipList:getMergeParticleFlyNode()
    self:setClanListVisible(true)
    local clanListCenterWPos = self.m_clanList:getPanelCenterWorldPos()
    -- 0.3秒飞行时间
    self:flyTo(1, flyNode, nil, clanListCenterWPos, function()
        -- if not tolua.isnull(self) then
        --     -- flyNode:setVisible(false)
        --     -- self.m_clanList:playClansFlyIn()
        -- end
    end, 0.6) -- 18/30
end

function CardDropViewNew:playMergeParticleOver(_over)
    self.m_chipList:playMergeParticleOver(_over, self.m_skipEffective )
    self.m_clanList:playClansFlyIn(self.m_skipEffective )
end

function CardDropViewNew:flyChipToClanList(_over)
    print("CardDropViewNew:flyChipToClanList")
    -- 没有新增章节进度
    if not self:hasClanList() then
        if _over then
            _over()
        end
        return
    end
    local flyNodes = self.m_chipList:getFirstDropChips()
    if not (flyNodes and #flyNodes > 0) then
        return
    end
    self:setClanListVisible(true)

    local delayTime = 0 
    if self.m_skipEffective then
        for i=1,#flyNodes do
            local flyNode = flyNodes[i]
            local cardData = flyNode:getCardData()
            if cardData then
                local clanCell = self.m_clanList:getClanCellByClanId(cardData.clanId)
                if clanCell then
                    if not tolua.isnull(self) then
                        flyNode:setVisible(false)
                        clanCell:playFlyIn(true)
                    end                    
                end
            end
        end
    else
        delayTime = FLY_INTERVAL*(#flyNodes-1) + REWARD_FLY_TIME_1 + REWARD_FLY_TIME_2
        local clanListBottomWPos = self.m_clanList:getPanelBottomWorldPos()
        for i=1,#flyNodes do
            local flyNode = flyNodes[i]
            local cardData = flyNode:getCardData()
            if cardData then
                local clanCell = self.m_clanList:getClanCellByClanId(cardData.clanId)
                if clanCell then
                    local wPos = self.m_clanList:getClanCellWorldPos(cardData.clanId)
                    flyNode:resetChipParticle()
                    self:flyTo2(i, flyNode, #flyNodes-(i-1), wPos, function()
                        if not tolua.isnull(self) and not tolua.isnull(flyNode) and not tolua.isnull(clanCell) then
                            flyNode:setVisible(false)
                            clanCell:playFlyIn()
                        end
                    end)
                else
                    -- tableview为创建，全部移动到clanlist的底部
                    print("-------- dont find clanCell", cardData.clanId)
                    local wPos = clanListBottomWPos
                    flyNode:resetChipParticle()
                    self:flyTo2(i, flyNode, #flyNodes-(i-1), wPos, function()
                        if not tolua.isnull(self) and not tolua.isnull(flyNode) then
                            flyNode:setVisible(false)
                        end
                    end) 
                end
            else
                print("------- dont have cardData")
            end
        end
    end
    -- 飞完后做下一步
    util_performWithDelay(self, _over, delayTime)
end

-- 多余卡转换成商城积分/多余卡转换成金币
function CardDropViewNew:playChipSwitch(_over)
    print("CardDropViewNew:playChipSwitch")
    local isPlaySwitch = self.m_chipList:playChipListAction({"store", "coin"}, "switch")
    local deleyTime = 1
    if self.m_skipEffective or not isPlaySwitch then
        deleyTime = 0
    end
    util_performWithDelay(self, _over, deleyTime)
end

-- 上移卡牌列表
function CardDropViewNew:moveUpChipList(_over)
    print("CardDropViewNew:moveUpChipList")
    self.m_chipList:moveUpChipList(MOVE_UP_TIME, _over, self.m_skipEffective)
end

function CardDropViewNew:showFlyStoreTickets(_over)
    print("CardDropViewNew:showFlyStoreTickets")
    local storeOverTime = 35/30
    if self.m_skipEffective then
        -- self.m_chipList:getChipParentLayer():setVisible(false)
        -- self.m_chipList:hideChips()
        if _over then
            _over()
        end        
    else
        self.m_chipList:playChipListAction({"store"}, "over")
        local showTime = 15/30
        local delayShowTime = 25/30
        util_performWithDelay(self, function()
            if not tolua.isnull(self) then
                local normalPoint, goldenPoint = self:getStorePoints()
                self.m_chipList:showFlyStoreTickets(normalPoint, goldenPoint)
            end
        end, delayShowTime)
        self:delayFunc(_over, showTime + delayShowTime + 1)
    end
end

function CardDropViewNew:flyToStore(_over)
    print("CardDropViewNew:flyToStore")
    local ticketTime = 0
    local delayTime = 0
    if self.m_skipEffective then
        local normalPoint, goldenPoint = self:getStorePoints()
        if normalPoint > 0 or goldenPoint > 0 then
            self:setStoreVisible(true)
            self.m_store:playShowTickets()
        end
        if _over then
            _over()
        end  
        return
    end 
    local flyNodes = self.m_chipList:getStoreTickets()
    if flyNodes and #flyNodes > 0 then
        self:setStoreVisible(true)
        for i=1,#flyNodes do
            local flyNode = flyNodes[i]
            local wPos = self.m_store:getParent():convertToWorldSpace(cc.p(self.m_store:getPosition()))
            -- flyNode:resetStoreParticle()
            self:flyTo2(i, flyNode, nil, wPos, function()
                if not tolua.isnull(self) and not tolua.isnull(flyNode) then
                    flyNode:setVisible(false)
                    self.m_store:playFlyto()
                end
            end)
        end
        local flyTime = FLY_INTERVAL*(#flyNodes-1) + REWARD_FLY_TIME_1 + REWARD_FLY_TIME_2
        local storeFlyInTime = 45/60
        ticketTime = flyTime + storeFlyInTime + 0.2
        delayTime = delayTime + ticketTime 
        -- 展示商店获得的券
        local showTicketTime = 30/60
        delayTime = delayTime + showTicketTime 
        util_performWithDelay(self, function()
            if not tolua.isnull(self) then
                self.m_store:playShowTickets(_over)
            end
        end, ticketTime)
    end
    -- 飞完后做下一步
    util_performWithDelay(self, _over, delayTime)
end

function CardDropViewNew:flyTo(_index, _flyNode, _ZOrder, _targetWPos, _over, _flyTime)
    _flyNode.flyOverFunc = function()
        if _over then
            _over()
        end
    end

    -- 先把flyNode提高到最高层级
    local wPos = _flyNode:getParent():convertToWorldSpace(cc.p(_flyNode:getPosition()))
    local lPos = self.m_flyNode:convertToNodeSpace(wPos)
    util_changeNodeParent(self.m_flyNode, _flyNode, _ZOrder)
    -- 当前位置
    _flyNode:setPosition(cc.p(lPos.x, lPos.y))
    -- 目标位置
    local targetPos = self.m_flyNode:convertToNodeSpace(_targetWPos)

    _flyTime = _flyTime or OPEN_FLY_TIME
    -- 动作
    local actionList = {}
    actionList[#actionList+1] = cc.DelayTime:create(FLY_INTERVAL*(_index-1))
    actionList[#actionList+1] = cc.EaseSineInOut:create(cc.MoveTo:create(_flyTime, targetPos))
    actionList[#actionList+1] = cc.CallFunc:create(function()
        if _over then
            _over()
        end
    end)
    _flyNode.flyAction = _flyNode:runAction(cc.Sequence:create(actionList))
end

function CardDropViewNew:flyTo2(_index, _flyNode, _ZOrder, _targetWPos, _over)
    _flyNode.flyOverFunc = function()
        if _over then
            _over()
        end
    end    
    -- 先把flyNode提高到最高层级
    local wPos = _flyNode:getParent():convertToWorldSpace(cc.p(_flyNode:getPosition()))
    local lPos = self.m_flyNode:convertToNodeSpace(wPos)
    util_changeNodeParent(self.m_flyNode, _flyNode, _ZOrder)
    -- 当前位置
    _flyNode:setPosition(cc.p(lPos.x, lPos.y))
    -- 目标位置
    local targetPos = self.m_flyNode:convertToNodeSpace(_targetWPos)
    -- 动作
    local actionList = {}
    actionList[#actionList+1] = cc.DelayTime:create(FLY_INTERVAL*(_index-1))
    local move = cc.EaseQuarticActionIn:create(cc.MoveTo:create(REWARD_FLY_TIME_1+REWARD_FLY_TIME_2, targetPos))
    local scale1 = cc.EaseQuarticActionOut:create(cc.ScaleTo:create(REWARD_FLY_TIME_1, 1.5))
    local scale2 = cc.EaseQuarticActionIn:create(cc.ScaleTo:create(REWARD_FLY_TIME_2, 0.01))
    local scale = cc.Sequence:create(scale1, scale2)
    Spawn = cc.Spawn:create(move, scale)
    actionList[#actionList+1] = Spawn

    actionList[#actionList+1] = cc.CallFunc:create(function()
        if _over then
            _over()
        end
    end)
    _flyNode.flyAction = _flyNode:runAction(cc.Sequence:create(actionList))
end

-- 收集nado次数
function CardDropViewNew:flyLinkParticle(_over)
    print("CardDropViewNew:flyLinkParticle")
    if not self:isHaveNodoMachine() then
        if _over then
            _over()
        end        
        return
    end

    if self.m_machineUI == nil then
        if _over then
            _over()
        end        
        return 
    end

    self:setNodoMachineVisible(true)

    local nadoMachineNum = self:getNadoGameInitNum()

    local flyCards = self.m_chipList:getNadoChips()
    local flynum = #flyCards
    local flyTime = 0.5
    local index = 1

    local machineBtn = self.m_machineUI:getMachineBtn()
    local flyParticle = nil
    flyParticle = function(index)
        if tolua.isnull(self) then
            return
        end

        local flyObj = flyCards[index]
        if not flyObj then
            return
        end
        local flyCardData = flyObj:getCardData()
        nadoMachineNum = nadoMachineNum + flyCardData.nadoCount
        index = index + 1
        if self.m_skipEffective then
            self.m_machineUI:updateNum(nadoMachineNum)
            if index <= flynum then
                flyParticle(index)
            end
        else
            local startPosWord = flyObj:getParent():convertToWorldSpace(cc.p(flyObj:getPosition()))
            local startPos = cc.p(self:convertToNodeSpace(startPosWord))
            local endPosWord = machineBtn:getParent():convertToWorldSpace(cc.p(machineBtn:getPosition()))
            local endPos = cc.p(self:convertToNodeSpace(endPosWord))
    
            local particle = cc.ParticleSystemQuad:create("CardsBase201903/CardRes/season201903/lizi/CashCards_jiahao_tuowei.plist")
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
            local delay = cc.DelayTime:create(0.2)
            local callFunc =
                cc.CallFunc:create(
                function()
                    if not tolua.isnull(particle) then
                        particle:removeFromParent()
                    end
                end
            )
            local seq = cc.Sequence:create(delay, callFunc)
            local spawn = cc.Spawn:create(playShakeSound, seq)
            particle:runAction(cc.Sequence:create(moveTo, spawn))
    
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
    end

    local nadoMachineAdd = self:getNadoGameAddNum()
    if nadoMachineAdd > 0 then
        if flynum > 0 then
            if index <= flynum then
                flyParticle(index)
            end
        else
            self.m_machineUI:updateNum(nadoMachineNum + nadoMachineAdd)
        end
    end

    if self.m_skipEffective then
        if _over then
            _over()
        end
    else
        local btnTime = flynum * (1.5 + flyTime)
        performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropNadoWheelMoveLeft)
                    -- self.m_machineUI:playShowBtn()
                    if _over then
                        _over()
                    end
                end
            end,
            btnTime
        )
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

    -- 同步缓存数据
    CardSysRuntimeMgr:cacheClanCollects()

    -- 增加飞金币逻辑（新手期多余的卡直接转变为金币）
    local exchangeCoins = self:getConvertCoins()
    if exchangeCoins > 0 then
        local flyNode = nil
        if self.m_clickPackage == true then
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
    elseif name == "Button_collect" then
        if self:isHaveNodoMachine() then
            self:clickCheckIt()
        else
            self:closeDropView(1)
        end
    
    elseif name == "Button_skip" then
        if self.m_skipEffective == true then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_skipEffective = true
        self.m_boxChips:setVisible(false)

        self.m_flyNode:setVisible(false)

        local children = self.m_flyNode:getChildren()
        for i=1,#children do
            local child = children[i]
            if not tolua.isnull(child) then
                if child.flyAction then
                    child:stopAction(child.flyAction)
                    child.flyAction = nil
                end
                if child.flyOverFunc then
                    child.flyOverFunc()
                end
            end
        end

        self.m_chipList:hideChips()

        local flyTickets = self.m_chipList:getStoreTickets()
        if flyTickets and #flyTickets > 0 then
            for i=1,#flyTickets do
                flyTickets[i]:setVisible(false)
            end
        end

        self:closeDropView(1)

        -- self:doNextFunc()
    elseif name == "btn_ClickPkg" then
        if self.m_clickPackage then
            return
        end
        self.m_clickPackage = true
        self.m_ClickNode:setEnabled(false)
        self:clickOpenPackage()
    end
end

-- 点击开卡包操作 --
function CardDropViewNew:clickOpenPackage()
    if self.m_DropInfo.type == CardSysConfigs.CardDropType.link then
        -- 引导打点：Card引导-3.领取link卡
        if CardSysManager:isInGuide() then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                gLobalSendDataManager:getLogGuide():sendGuideLog(8, 3)
            end
        end
    end
    self.m_nodeBgLight:setVisible(false)
    self.m_layerTitle:setVisible(false)
    self.m_closeBtn:setVisible(false)
    self:hideTap()
    self:initViewAfterOpen()
    self:doOpenPackageLogic()
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
            else
                info.des = string.format(info.des, cardsNum .. " FORTUNE CHIP")
            end
        elseif cardsNum > 1 then
            info.des = string.format(info.des, cardsNum .. " FORTUNE CHIPS")
        end
    end
    return info
end

function CardDropViewNew:getNadoGameAddNum()
    local getNum = 0
    for i = 1, #self.m_DropInfo.cards do
        local cardData = self.m_DropInfo.cards[i]
        if cardData and cardData.type == CardSysConfigs.CardType.link then
            getNum = getNum + cardData.nadoCount
        end
    end
    return getNum
end

-- 获得nado机上的小红点初始数量
function CardDropViewNew:getNadoGameInitNum()
    local totalNum = CardSysRuntimeMgr:getNadoGameLeftCount() or 0 -- self.m_DropInfo.nadoGames -- 总数
    local getNum = self:getNadoGameAddNum()
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

function CardDropViewNew:getStorePoints()
    local normalPoints, goldPoints = 0, 0
    if self.m_DropInfo and self.m_DropInfo.cards and #self.m_DropInfo.cards > 0 then
        for i = 1, #self.m_DropInfo.cards do
            local cardData = self.m_DropInfo.cards[i]
            normalPoints = normalPoints + (cardData.greenPoint or 0) * (cardData.count or 1)
            goldPoints = goldPoints + (cardData.goldPoint or 0) * (cardData.count or 1)
        end
    end
    return normalPoints, goldPoints
end

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

-- 计算新卡个数
function CardDropViewNew:getFirstDropCardNum()
    local firstDropNum = 0
    if self.m_DropInfo and self.m_DropInfo.cards and #self.m_DropInfo.cards > 0 then
        for i = 1, #self.m_DropInfo.cards do
            local cardData = self.m_DropInfo.cards[i]
            if cardData.firstDrop then
                firstDropNum = firstDropNum + 1
            end
        end
    end
    return firstDropNum
end

return CardDropViewNew
