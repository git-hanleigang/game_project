--[[
    集卡系统 卡片卡组掉落界面
]]
local BaseCardDropView = class("BaseCardDropView", BaseLayer)
BaseCardDropView.m_autoCloseStartTime = nil
BaseCardDropView.m_autoCloseTimer = nil
local CARD_SPRITE_POSY_OFFSET = 0
local drop_open_pack = 0.92

function BaseCardDropView:ctor()
    BaseCardDropView.super.ctor(self)
    self.isClose = false
    self.m_needOpenPkg = false
    self:setPauseSlotsEnabled(true)
    self:setExtendData("BaseCardDropView")
end

function BaseCardDropView:initDatas(dropData)
    -- 掉落数据 --
    self.m_DropInfo = dropData
end

-- 初始化UI --
function BaseCardDropView:initUI(dropData)
    BaseCardDropView.super.initUI(self)

    self.m_cardDropShow = self:createShowList()

    -- 是否自动关闭UI --
    self.m_sourceCfg = self:getSourceCfg()
    self.m_isAutoClose = self.m_sourceCfg.autoCloseDropUI == true

    self:resetViewShow()

    -- 根据包类型显示不同状态 --
    self:initViewByType()

    self:updateTitle()
end

function BaseCardDropView:playShowAction()
    BaseCardDropView.super.playShowAction(self, "show", false)
end

function BaseCardDropView:onShowedCallFunc()
    -- 如果是普通卡 则直接飞卡 --
    if self.m_DropInfo.type == CardSysConfigs.CardDropType.single then
        self:startDropCard()
        if self.m_isAutoClose then
            self:initAutoClose()
        end
    end
    self:runCsbAction("idle", true, nil, 60)
end

-- 子类重写
function BaseCardDropView:createShowList()
    return
end

--显示标题和彩带
function BaseCardDropView:updateTitle()
    local showTime = 1 --开始出现时间
    local overTime = 1.5 --完全出现时间
    local offWidth = 160 --彩带去除裁切区域的宽度
    local orgSize = self.m_clipLayout:getContentSize()
    local orgPiaoSize = {width = 940, height = 96} --飘带原始尺寸
    local newPiaoWidth = self.m_Text_Source:getContentSize().width * self.m_Text_Source:getScale() + 200 --飘带根据字体缩放的尺寸
    self.m_clipLayout:setVisible(false)
    self.m_piao:setContentSize(cc.size(math.max(orgPiaoSize.width, newPiaoWidth), orgPiaoSize.height))
    performWithDelay(
        self,
        function()
            self.m_clipLayout:setVisible(true)
            local size = self.m_piao:getContentSize()
            local runTime = overTime - showTime --运行时间
            local targetWidth = size.width - offWidth --目标宽度
            local clipWidth = 300 --增量
            self.m_clipLayout:setContentSize(clipWidth, orgSize.height)
            self.m_Text_Source:setPositionX(clipWidth * 0.5)
            local frameLen = targetWidth * 0.5 / runTime --秒宽度
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

-- 初始化基本UI --
function BaseCardDropView:initCsbNodes()
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
    self.m_list_card = self:findChild("list_card")
    -- 卡包 --
    self.m_cardPackageNode = self:findChild("Node_Package")
    self.m_Tex_TapToSee = self:findChild("taptosee_6")
    self.m_Tex_WildCard = self:findChild("wild_card")
    self.m_Tex_GoldenPkg = self:findChild("golden_card_9")

    -- wild卡包的不同类型显示不同wild卡图片
    self.m_sp_wilds = {}
    for i = 1, 4 do
        self.m_sp_wilds[#self.m_sp_wilds + 1] = self:findChild("card_wild_" .. i)
    end

    -- 关闭按钮 --
    self.m_closeBtn = self:findChild("Button_1")
    self.m_closeBtn:setVisible(true)

    -- 收集按钮 --
    self.m_collectBtn = self:findChild("Button_6")
    self.m_collectBtn:setVisible(false)

    -- link跳转按钮 --
    self.m_checkItBtn = self:findChild("Button_checkit")
    self.m_checkItBtn:setVisible(false)

    -- 分享按钮 --
    self.m_shareTxt = self:findChild("BitmapFontLabel_6")
    if self.m_shareTxt then
        self.m_shareTxt:setVisible(false)
    end
    self.m_shareBtn = self:findChild("Button_7")
    if self.m_shareBtn then
        self.m_shareBtn:setVisible(false)
    end

    -- 点击事件 --
    self.m_ClickNode = self:findChild("btn_ClickPkg")
    self:addClick(self.m_ClickNode)
    self.m_ClickNode:setEnabled(false)
end

function BaseCardDropView:initView()
    self:cardPackage_initSpine()
end

--[[
    根据卡包类型初始化掉落面板 
    -- normal  = "NORMAL",         -- 普通卡包
    -- link    = "LINK",           -- link卡包
    -- golden  = "GOLDEN",         -- 金卡包
    -- single  = "SINGLE",         -- 单卡
    -- wild    = "WILD"            -- wild卡
]]
function BaseCardDropView:initViewByType()
    local isWild = false
    if self.m_DropInfo.type == CardSysConfigs.CardDropType.normal then
        self:showCommonPackage()
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.link then
        self:showLinkPackage()
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.golden then
        self:showGoldenPackage()
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.single then
        self:showSingleCardDrop()
    elseif CardSysRuntimeMgr:isWildDropType(self.m_DropInfo.type) then
        isWild = true
        self:showWildCardDrop()
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_normal then
        isWild = true
        -- TODO:MAQUN:待优化 掉落扩展wild卡
        self:showWildCardDrop()
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_link then
        isWild = true
        -- TODO:MAQUN:待优化 掉落扩展wild卡
        self:showWildCardDrop()
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_golden then
        isWild = true
        -- TODO:MAQUN:待优化 掉落扩展wild卡
        self:showWildCardDrop()
    elseif CardSysRuntimeMgr:isStatueDropType(self.m_DropInfo.type) then
        self:showStatuePackage()
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.merge then
        self:showMergePackage()
    end
    --非wild自动关闭
    if not isWild and globalData.slotRunData.checkViewAutoClick then
        globalData.slotRunData:checkViewAutoClick(self, "Button_1")
    end
end

--
function BaseCardDropView:getSourceCfg()
    local sourceCfg = CardSysManager:getDropMgr():getDropSourceCfgBySource(self.m_DropInfo.source)
    return sourceCfg
end

function BaseCardDropView:initAutoClose()
    self.m_autoCloseStartTime = -1
    self.m_autoCloseTimer =
        schedule(
        self,
        function()
            if self.m_autoCloseStartTime >= 0 then
                self.m_autoCloseStartTime = self.m_autoCloseStartTime + 1
                if self.m_autoCloseStartTime >= 5 then
                    self:stopAction(self.m_autoCloseTimer)
                    self.m_autoCloseTimer = nil
                    self:closeDropView(1)
                end
            end
        end,
        1
    )
end

-- 显示背景光
function BaseCardDropView:showBgLight(isShow)
    -- 可以直接显示背景光 --
    if isShow then
        self.m_bgLigt:setVisible(true)
        local selectNode, selectAct = util_csbCreate(CardResConfig.CardDropViewBgLightRes)
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

-- 重新设置彩带背景条的长度，按照九宫格
function BaseCardDropView:resetTitleBgSize(widthSize)
    -- local oriWidth = 940
    -- local oriHeight = 96
    -- self.m_piao:setContentSize(cc.size(oriWidth*widthSize, oriHeight))
end

-- 标题
function BaseCardDropView:showTitle(title)
    self.m_Title_ohYeah:setVisible(title == "OH YEAH!")
    self.m_Title_Wow:setVisible(title == "WOW!")
    self.m_Title_Congrats:setVisible(title == "CONGRATS!")
    self.m_Title_Awesome:setVisible(title == "AWESOME!")
end

function BaseCardDropView:resetViewShow()
    self.m_Title_ohYeah:setVisible(false)
    self.m_Title_Wow:setVisible(false)
    self.m_Title_Congrats:setVisible(false)
    self.m_Title_Awesome:setVisible(false)
    self.m_Tex_TapToSee:setVisible(false)
    self.m_cardPackageNode:setVisible(false)
    self.m_Tex_GoldenPkg:setVisible(false)
    self.m_Tex_WildCard:setVisible(false)
    self.m_Text_Source:setString("HolyShit")
end

function BaseCardDropView:showCommonPackage()
    -- self:resetViewShow()
    self:showBgLight(true)
    self.m_cardPackageNode:setVisible(true)
    self.m_ClickNode:setEnabled(true)
    self:normalPackage_Idle()
    self.m_Tex_TapToSee:setVisible(true)

    local info = self.m_sourceCfg.normalPackage
    -- 标题
    self:showTitle(info.title)
    -- 描述文字
    self.m_Text_Source:setString(info.des)
    self:resetTitleBgSize(1.2)
    -- 声音
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC[info.music])
end

function BaseCardDropView:showLinkPackage()
    -- self:resetViewShow()
    self:showBgLight(true)
    self.m_cardPackageNode:setVisible(true)
    self.m_ClickNode:setEnabled(true)
    self:linkPackage_Idle()
    self.m_Tex_TapToSee:setVisible(true)

    local info = self.m_sourceCfg.linkPackage
    -- 标题
    self:showTitle(info.title)
    -- 描述文字
    self.m_Text_Source:setString(info.des)
    self:resetTitleBgSize(1.3)
    -- 声音
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC[info.music])
end
function BaseCardDropView:showGoldenPackage()
    -- self:resetViewShow()
    self:showBgLight(true)
    self.m_ClickNode:setEnabled(true)
    self.m_Tex_TapToSee:setVisible(true)
    self.m_Tex_GoldenPkg:setVisible(true)

    local info = self.m_sourceCfg.goldenPackage
    -- 标题
    self:showTitle(info.title)
    -- 描述文字
    self.m_Text_Source:setString(info.des)
    self:resetTitleBgSize(1)
    -- 声音
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC[info.music])
end

function BaseCardDropView:showSingleCardDrop()
    -- self:resetViewShow()

    local info = self.m_sourceCfg.single
    -- 标题
    self:showTitle(info.title)
    -- 描述文字
    local cardsNum = 0
    for i = 1, #self.m_DropInfo.cards do
        local cardData = self.m_DropInfo.cards[i]
        cardsNum = cardsNum + cardData.count
    end
    if cardsNum == 1 then
        if self.m_DropInfo.cards[1].type == CardSysConfigs.CardType.puzzle then
            self.m_Text_Source:setString(string.format(info.des, cardsNum .. " PUZZLE CARD"))
        else
            self.m_Text_Source:setString(string.format(info.des, cardsNum .. " FORTUNE CARD"))
        end
    elseif cardsNum > 1 then
        self.m_Text_Source:setString(string.format(info.des, cardsNum .. " FORTUNE CARDS"))
    end
    self:resetTitleBgSize(1)
    -- 声音
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC[info.music])
end

function BaseCardDropView:showWildCardDrop()
    -- self:resetViewShow()
    self:showBgLight(true)
    self.m_ClickNode:setEnabled(true)
    self.m_Tex_WildCard:setVisible(true)
    self.m_closeBtn:setVisible(false)
    local info = self.m_sourceCfg.wildCard
    -- 标题
    self:showTitle(info.title)
    -- 描述文字
    self.m_Text_Source:setString(info.des)
    self:resetTitleBgSize(1)
    -- 声音
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC[info.music])

    -- 根据wild卡的类型显示不同的wild卡图片
    local showIndex = nil
    if self.m_DropInfo.type == CardSysConfigs.CardDropType.wild then
        showIndex = 1
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_normal then
        showIndex = 2
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_golden then
        showIndex = 3
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_link then
        showIndex = 4
    end
    if showIndex ~= nil then
        for i = 1, 4 do
            self.m_sp_wilds[i]:setVisible(i == showIndex)
        end
    end
end

-- 点击开卡包操作 --
function BaseCardDropView:clickOpenPackage()
    -- 点击一次之后，不再响应click事件 --
    self.m_ClickNode:setEnabled(false)

    if self.m_DropInfo.type == CardSysConfigs.CardDropType.normal then
        -- 播放开卡包动画 执行飞卡 --
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropOpenPack)
            end,
            drop_open_pack
        )
        self:normalPackage_Open(
            function()
                self:startDropCard()
                self:showBgLight(false)
            end,
            function()
                self.m_cardPackageNode:setVisible(false)
            end
        )
        self.m_Tex_TapToSee:setVisible(false)
        self.m_needOpenPkg = true
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.link then
        -- 引导打点：Card引导-3.领取link卡
        if CardSysManager:isInGuide() then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                gLobalSendDataManager:getLogGuide():sendGuideLog(8, 3)
            end
        end
        -- 播放开卡包动画 执行飞卡 --
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropOpenPack)
            end,
            drop_open_pack
        )
        self:linkPackage_Open(
            function()
                self:startDropCard()
                self:showBgLight(false)
            end,
            function()
                self.m_cardPackageNode:setVisible(false)
            end
        )
        self.m_Tex_TapToSee:setVisible(false)
        self.m_needOpenPkg = true
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.golden then
        -- 播放开卡包动画 执行飞卡 --
        self.m_Tex_GoldenPkg:setVisible(false)
        self.m_Tex_TapToSee:setVisible(false)
        self.m_needOpenPkg = true
        self:showBgLight(false)
        self:startDropCard()
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.single then
        -- do nothing --
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild then
        -- 关闭掉落面板 跳转wild兑换 --
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropClickWild)
        self:closeDropView(3, nil, CardSysConfigs.CardType.wild)
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_normal then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropClickWild)
        self:closeDropView(3, nil, CardSysConfigs.CardType.wild_normal)
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_link then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropClickWild)
        self:closeDropView(3, nil, CardSysConfigs.CardType.wild_link)
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_golden then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropClickWild)
        self:closeDropView(3, nil, CardSysConfigs.CardType.wild_golden)
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.wild_obsidian then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropClickWild)
        self:closeDropView(3, nil, CardSysConfigs.CardType.wild_obsidian)
    elseif CardSysRuntimeMgr:isStatueDropType(self.m_DropInfo.type) then
        -- 播放开卡包动画 执行飞卡 --
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropOpenPack)
            end,
            drop_open_pack
        )
        self:statuePackage_Open(
            function()
                self:startDropCard()
                self:showBgLight(false)
            end,
            function()
                if self.m_dropStatuePackage then
                    self.m_dropStatuePackage:setVisible(false)
                end
            end
        )
        self.m_Tex_TapToSee:setVisible(false)
        self.m_needOpenPkg = true
    elseif self.m_DropInfo.type == CardSysConfigs.CardDropType.merge then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.DropOpenPack)
        self:mergePackage_Open(
            function()
                self:startDropCard()
                self:showBgLight(false)
            end,
            function()
                self.m_cardPackageNode:setVisible(false)
            end
        )
    end
end

-- 掉落卡片动画 --
function BaseCardDropView:startDropCard()
    -- -- 判断是否已经正常获取集卡系统数据信息 --
    -- local bHasLogin = CardSysRuntimeMgr:hasLoginCardSys()
    -- if bHasLogin == false then
    --     print("-------------->>  卡片系统登陆失败 请找程序")
    --     return
    -- else
    -- end
    -- 解析数据 --
    -- 普通卡存放列表 --
    local normalCardsData = {}
    -- 金卡存放列表
    local goldCardsData = {}
    -- Link卡存放列表 --
    local linkCardsData = {}
    -- 拼图卡存放列表
    local puzzleCardsData = {}

    local flyCardsNum = 0
    local nDropCardsNum = #self.m_DropInfo.cards
    for i = 1, nDropCardsNum do
        local cardData = self.m_DropInfo.cards[i]

        if cardData.type == CardSysConfigs.CardType.normal then
            flyCardsNum = flyCardsNum + cardData.count
            for i = 1, cardData.count do
                normalCardsData[#normalCardsData + 1] = cardData
            end
        elseif cardData.type == CardSysConfigs.CardType.golden then
            flyCardsNum = flyCardsNum + cardData.count
            for i = 1, cardData.count do
                goldCardsData[#goldCardsData + 1] = cardData
            end
        elseif cardData.type == CardSysConfigs.CardType.link then
            flyCardsNum = flyCardsNum + cardData.count
            for i = 1, cardData.count do
                linkCardsData[#linkCardsData + 1] = cardData
            end
        elseif cardData.type == CardSysConfigs.CardType.puzzle then
            flyCardsNum = flyCardsNum + cardData.count
            for i = 1, cardData.count do
                puzzleCardsData[#puzzleCardsData + 1] = cardData
            end
        end
    end

    -- 普通卡进行星级排序 --
    table.sort(
        normalCardsData,
        function(card1, card2)
            return card1.star < card2.star
        end
    )
    -- 普通卡进行星级排序 --
    table.sort(
        goldCardsData,
        function(card1, card2)
            return card1.star < card2.star
        end
    )
    -- link卡进行星级排序 --
    table.sort(
        linkCardsData,
        function(card1, card2)
            return card1.star < card2.star
        end
    )
    -- 拼图卡进行星级排序 --
    table.sort(
        puzzleCardsData,
        function(card1, card2)
            return card1.star < card2.star
        end
    )

    -- 最终将3个列表拼接 --
    -- 所有掉落卡存放列表
    local flyCardsData = {}
    for i = 1, #normalCardsData do
        flyCardsData[#flyCardsData + 1] = normalCardsData[i]
    end
    for i = 1, #goldCardsData do
        flyCardsData[#flyCardsData + 1] = goldCardsData[i]
    end
    for i = 1, #linkCardsData do
        flyCardsData[#flyCardsData + 1] = linkCardsData[i]
    end
    for i = 1, #puzzleCardsData do
        flyCardsData[#flyCardsData + 1] = puzzleCardsData[i]
    end

    self:cardsFly(flyCardsNum, flyCardsData)
end

-- 点击事件 --
function BaseCardDropView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then
        -- 清除后续打点
        if CardSysManager:isInGuide() then
            if gLobalSendDataManager:getLogGuide():isGuideBegan(8) then
                gLobalSendDataManager:getLogGuide():cleanParams(8)
            end
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:closeDropView(1)
    elseif name == "Button_6" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        self:closeDropView(1)
    elseif name == "Button_checkit" then
        -- gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        self:clickCheckIt()
    elseif name == "btn_ClickPkg" then
        if self.m_clickPackage then
            return
        end
        self.m_clickPackage = true
        self:clickOpenPackage()
    end
end

function BaseCardDropView:clickCheckIt()
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

--调用管理类里面的关闭方法
function BaseCardDropView:closeDropView(closeType, dropLinkClanId, wildType)
    local callback = function()
        CardSysManager:getDropMgr():closeDropView(closeType, dropLinkClanId, wildType)
    end
    self:closeUI(callback)
end
-- 关闭事件 --
function BaseCardDropView:closeUI(callFunc)
    if self.isClose then
        return
    end
    self.isClose = true
    -- self:removeFromParent()

    local callback = function()
        if callFunc then
            callFunc()
        end
        -- 收集结束，刷新一下章节选择界面上的卡牌信息
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_ALBUM_LIST_UPDATE)
    end

    BaseCardDropView.super.closeUI(self, callback)
end



function BaseCardDropView:onExit()
    BaseCardDropView.super.onExit(self)

    if self.m_autoCloseTimer then
        self:stopAction(self.m_autoCloseTimer)
        self.m_autoCloseTimer = nil
    end

    if self.m_cardDropShow then
        self.m_cardDropShow:purge()
        self.m_cardDropShow = nil
    end
end

-- 所有卡牌飞出效果 --
function BaseCardDropView:cardsFly(nCardNum, flyCardsData)
    local useClanIcon = true
    if self.m_sourceCfg.source == "Wild Exchange" then
        useClanIcon = false
    end
    local flyTime = self.m_cardDropShow:flyCards(flyCardsData, useClanIcon)

    self:setDropLink(flyCardsData)

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
end

function BaseCardDropView:setDropLink(flyCardsData)
    -- 判断是否有link卡掉落 --
    self.m_dropLinkClanId = nil
    if flyCardsData and #flyCardsData > 0 then
        for i = 1, #flyCardsData do
            if flyCardsData[i].type == CardSysConfigs.CardType.link then
                if tonumber(flyCardsData[i].albumId) == tonumber(CardSysRuntimeMgr:getCurAlbumID()) then
                    self.m_dropLinkClanId = flyCardsData[i].clanId
                end
                break
            end
        end
    else
    end
end

function BaseCardDropView:updateBottomBtn()
    -- 显示按钮 --
    if CardSysManager:hasSeasonOpening() then
        if self.m_dropLinkClanId ~= nil 
            and CardSysManager:checkShowCheckIt(self.m_sourceCfg.source)
            and CardSysManager:checkIsInNewQuest()
            and CardSysManager:checkIsInPassMission() then
            self.m_checkItBtn:setVisible(true)
            self.m_collectBtn:setVisible(false)
        else
            self.m_checkItBtn:setVisible(false)
            self.m_collectBtn:setVisible(true)
        end
    else
        self.m_checkItBtn:setVisible(false)
        self.m_collectBtn:setVisible(true)
    end
end

-- 卡包的骨骼动画
function BaseCardDropView:cardPackage_initSpine()
    local size = self.m_cardPackageNode:getContentSize()
    self.m_cardPackageSpine = util_spineCreate(CardResConfig.CardDropPackageSpineRes, false, true, 1)
    self.m_cardPackageSpine:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
    self.m_cardPackageNode:addChild(self.m_cardPackageSpine)
end

-- link卡 idle 动画 --
function BaseCardDropView:linkPackage_Idle()
    util_spinePlay(self.m_cardPackageSpine, "idleframe", true)
end

-- link卡 开卡包 动画 --
function BaseCardDropView:linkPackage_Open(cardAppear, packageDisappear)
    util_spinePlay(self.m_cardPackageSpine, "actionframe", false)
    util_spineFrameCallFunc(
        self.m_cardPackageSpine,
        "actionframe",
        "show",
        function()
            if cardAppear then
                cardAppear()
            end
        end,
        function()
            if packageDisappear then
                packageDisappear()
            end
        end
    )
end

-- 普通卡 idle 动画 --
function BaseCardDropView:normalPackage_Idle()
    util_spinePlay(self.m_cardPackageSpine, "idleframe2", true)
end

-- 普通卡 开卡包 动画 --
function BaseCardDropView:normalPackage_Open(cardAppear, packageDisappear)
    util_spinePlay(self.m_cardPackageSpine, "actionframe2", false)
    util_spineFrameCallFunc(
        self.m_cardPackageSpine,
        "actionframe2",
        "show",
        function()
            if cardAppear then
                cardAppear()
            end
        end,
        function()
            if packageDisappear then
                packageDisappear()
            end
        end
    )
end

function BaseCardDropView:statuePackage_Open(cardAppear, packageDisappear)
    if cardAppear then
        cardAppear()
    end
    if packageDisappear then
        packageDisappear()
    end
end

function BaseCardDropView:showMergePackage()
    self:showBgLight(true)
    self.m_closeBtn:setVisible(false)
    self.m_cardPackageNode:setVisible(true)

    self.m_mergeBoxes = {}
    local UIList = {}
    for dropType, num in pairs(self.m_DropInfo.mergedTypes) do
        if num > 0 then
            local box = util_createView("GameModule.Card.commonViews.CardDrop.CardDropBox")
            self.m_cardPackageNode:addChild(box)
            table.insert(self.m_mergeBoxes, box)
            table.insert(UIList, {node = box, anchor = cc.p(0.5, 0.5), size = cc.size(423, 353)})

            box:changeBox(dropType == CardSysConfigs.CardDropType.link)
            box:updateBoxNum(num)
            box:playStart(
                function()
                    self.m_ClickNode:setEnabled(true)
                    box:playBreathe()
                end
            )
        end
    end
    util_alignCenter(UIList)
end

function BaseCardDropView:mergePackage_Open(cardAppear, packageDisappear)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropBoxOpen)
    if self.m_mergeBoxes and #self.m_mergeBoxes > 0 then
        local isFirst = false
        for i = 1, #self.m_mergeBoxes do
            self.m_mergeBoxes[i]:playOpen(
                function()
                    if isFirst then
                        return
                    end
                    isFirst = true
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
    end
end

return BaseCardDropView
