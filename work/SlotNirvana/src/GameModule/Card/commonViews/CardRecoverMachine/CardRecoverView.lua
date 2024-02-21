--[[
    CardRecoverView
    集卡系统 卡片回收主面板
--]]
local CardRecoverView = class("CardRecoverView", BaseLayer)

function CardRecoverView:initDatas()
    self.isClose = false
    self.m_canClickX = false
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardRecoverViewRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
end

-- 初始化UI --
function CardRecoverView:initUI()
    CardRecoverView.super.initUI(self)
    -- local isAutoScale = true
    -- if CC_RESOLUTION_RATIO == 3 then
    --     isAutoScale = false
    -- end
    -- self:createCsbNode(string.format(CardResConfig.commonRes.CardRecoverViewRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()), isAutoScale)
    self:initData()

    self:initBubble()

    -- self.m_canClickX = false

    -- local root = self:findChild("root")
    -- if root then
    --     self:runCsbAction("idle",true, nil, 60)
    --     self:commonShow(root,function()
    --         if self.isClose then
    --             return
    --         end
    --         self.m_canClickX = true
    --         self:runCsbAction("idle",true, nil, 60)
    --     end)
    -- else
    -- self:runCsbAction(
    --     "show",
    --     false,
    --     function()
    --         if self.isClose then
    --             return
    --         end
    --         self.m_canClickX = true
    --         self:runCsbAction("idle", true, nil, 60)
    --     end,
    --     60
    -- )
    -- end
end

function CardRecoverView:playShowAction()
    CardRecoverView.super.playShowAction(self, "show", false)
end

function CardRecoverView:onShowedCallFunc()
    if self.isClose then
        return
    end
    self.m_canClickX = true
    self:runCsbAction("idle", true, nil, 60)
end

--适配方案 --
-- function CardRecoverView:getUIScalePro()
--     local x = display.width / DESIGN_SIZE.width
--     local y = display.height / DESIGN_SIZE.height
--     local pro = x / y
--     if globalData.slotRunData.isPortrait == true then
--         pro = 0.8
--     end
--     return pro
-- end

-- 初始化数据 --
function CardRecoverView:initData()
    -- self.isClose = false

    local yearData = CardSysRuntimeMgr:getCurrentYearData()
    local wheelCfg = yearData:getWheelConfig()
    assert(wheelCfg ~= nil, "wheelCfg is nil")
    local lettos = wheelCfg:getLettos()

    self.m_MaxStarNode = self:findChild("BitmapFontLabel_2")
    self.m_MaxStarNode:setString(wheelCfg:getStarNum())

    self.m_root = self:findChild("root")

    self.m_Change1Num = lettos[1].needStars
    self.m_Change2Num = lettos[2].needStars
    self.m_Change3Num = lettos[3].needStars

    self.m_MaxCoinsNum1 = lettos[1].maxReward.coins
    self.m_MaxCoinsNum2 = lettos[2].maxReward.coins
    self.m_MaxCoinsNum3 = lettos[3].maxReward.coins

    -- 星星数量显示 --
    local LanguageKey = "CardRecoverView:Button_Exc"
    local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "Exchange %d Stars"

    self.m_Change1Text = self:findChild("Exchange5Stars")
    if self.m_Change1Text then
        self.m_Change1Text:setString("Exchange " .. self.m_Change1Num .. " Stars")
    else
        local str1 = string.format(refStr, self.m_Change1Num)
        self:setButtonLabelContent("Button_Exc1", str1)
    end
    self.m_Change2Text = self:findChild("Exchange10Stars")
    if self.m_Change2Text then
        self.m_Change2Text:setString("Exchange " .. self.m_Change2Num .. " Stars")
    else
        local str2 = string.format(refStr, self.m_Change2Num)
        self:setButtonLabelContent("Button_Exc2", str2)
    end
    self.m_Change3Text = self:findChild("Exchange20Stars")
    if self.m_Change3Text then
        self.m_Change3Text:setString("Exchange " .. self.m_Change3Num .. " Stars")
    else
        local str3 = string.format(refStr, self.m_Change3Num)
        self:setButtonLabelContent("Button_Exc3", str3)
    end

    -- 最大赢钱显示 --
    self.m_Fnt1_MaxCoins = self:findChild("m_lb_coins1")
    self.m_Fnt2_MaxCoins = self:findChild("m_lb_coins2")
    self.m_Fnt3_MaxCoins = self:findChild("m_lb_coins3")
    self.m_Fnt1_MaxCoins:setString(util_formatCoins(tonumber(self.m_MaxCoinsNum1), 30))
    self.m_Fnt2_MaxCoins:setString(util_formatCoins(tonumber(self.m_MaxCoinsNum2), 30))
    self.m_Fnt3_MaxCoins:setString(util_formatCoins(tonumber(self.m_MaxCoinsNum3), 30))
    local coins_unit1 = self:findChild("coins_unit1")
    local coins_unit2 = self:findChild("coins_unit2")
    local coins_unit3 = self:findChild("coins_unit3")

    --适配移动节点
    local offX = (self.m_Fnt1_MaxCoins:getContentSize().width - 100) * 0.5
    local function moveNode(node)
        node:setPositionX(node:getPositionX() + offX)
    end
    moveNode(self.m_Fnt1_MaxCoins)
    moveNode(self.m_Fnt2_MaxCoins)
    moveNode(self.m_Fnt3_MaxCoins)
    moveNode(coins_unit1)
    moveNode(coins_unit2)
    moveNode(coins_unit3)
    --
    -- 按钮设置 --
    self.Change1Btn = self:findChild("Button_Exc1")
    self.Change2Btn = self:findChild("Button_Exc2")
    self.Change3Btn = self:findChild("Button_Exc3")
    self.Disabled1Btn = self:findChild("Button_Exc1_0")
    self.Disabled2Btn = self:findChild("Button_Exc2_0")
    self.Disabled3Btn = self:findChild("Button_Exc3_0")
    self.suo_1 = self:findChild("suo_1")
    self.suo_2 = self:findChild("suo_2")
    self.suo_3 = self:findChild("suo_3")

    local stars = wheelCfg:getStarNum()
    local canRecover1 = stars >= self.m_Change1Num
    local canRecover2 = stars >= self.m_Change2Num
    local canRecover3 = stars >= self.m_Change3Num

    -- self.Change1Btn:setVisible(canRecover1)
    -- self.Change2Btn:setVisible(canRecover2)
    -- self.Change3Btn:setVisible(canRecover3)
    self:setButtonLabelDisEnabled("Button_Exc1", canRecover1)
    self:setButtonLabelDisEnabled("Button_Exc2", canRecover2)
    self:setButtonLabelDisEnabled("Button_Exc3", canRecover3)

    if canRecover1 then
    --     local sweep = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLightRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    --     -- sweep:runCsbAction("sweep", true, nil, 60)
    --     sweep:runCsbLoopAction("sweep", 5, 60)

    --     self.Change1Btn:removeAllChildren()
    --     self.Change1Btn:addChild(sweep)
    --     local size = self.Change1Btn:getContentSize()
    --     sweep:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
        self:startButtonAnimation("Button_Exc1", "sweep", true)
    end

    if canRecover2 then
    --     local sweep = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLightRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    --     -- sweep:runCsbAction("sweep", true, nil, 60)
    --     sweep:runCsbLoopAction("sweep", 5, 60)

    --     self.Change2Btn:removeAllChildren()
    --     self.Change2Btn:addChild(sweep)
    --     local size = self.Change2Btn:getContentSize()
    --     sweep:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
        self:startButtonAnimation("Button_Exc2", "sweep", true)
    end

    if canRecover3 then
    --     local sweep = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLightRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    --     -- sweep:runCsbAction("sweep", true, nil, 60)
    --     sweep:runCsbLoopAction("sweep", 5, 60)

    --     self.Change3Btn:removeAllChildren()
    --     self.Change3Btn:addChild(sweep)
    --     local size = self.Change3Btn:getContentSize()
    --     sweep:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
        self:startButtonAnimation("Button_Exc3", "sweep", true)
    end

    self.Disabled1Btn:setVisible(not canRecover1)
    self.Disabled2Btn:setVisible(not canRecover2)
    self.Disabled3Btn:setVisible(not canRecover3)

    self.suo_1:removeAllChildren()
    self.suo_2:removeAllChildren()
    self.suo_3:removeAllChildren()

    if not canRecover1 then
        local suoNode = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLockRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        self.suo_1:addChild(suoNode)
        -- suoNode:runCsbAction("lock", true, nil, 60)
        suoNode:runCsbLoopAction("lock", 5, 60)
    end
    if not canRecover2 then
        local suoNode = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLockRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        self.suo_2:addChild(suoNode)
        -- suoNode:runCsbAction("lock", true, nil, 60)
        suoNode:runCsbLoopAction("lock", 5, 60)
    end
    if not canRecover3 then
        local suoNode = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLockRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        self.suo_3:addChild(suoNode)
        -- suoNode:runCsbAction("lock", true, nil, 60)
        suoNode:runCsbLoopAction("lock", 5, 60)
    end

    -- wheel_node --
    local wheel = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverWheelRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    -- wheel:runCsbAction("idle", true, nil, 60)
    wheel:runCsbLoopAction("idle", 5, 60)
    self.m_wheelNode = self:findChild("wheel_node")
    self.m_wheelNode:addChild(wheel)
end

function CardRecoverView:initBubble()
    -- 播放气泡 --
    local tipNode = self:findChild("tips1")
    local tipUI = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverTip")
    tipNode:addChild(tipUI)
end

function CardRecoverView:addTip(index)
    local tipNode = util_createAnimation(string.format(CardResConfig.commonRes.CardRecovertTipRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))

    local tip = self:findChild("tip" .. index)
    tip:removeAllChildren()
    tip:addChild(tipNode)

    local name = "recover_tip_" .. index
    local ishave = self.m_root:getChildByName(name)
    if not ishave then
        local touch = CardSysManager:createFullScreenTouchLayer(name, true)
        self.m_root:addChild(touch)
        self:addClick(touch)
    end
end

function CardRecoverView:deleteTip(index)
    local name = "recover_tip_" .. index
    self.m_root:removeChildByName(name)

    local tip = self:findChild("tip" .. index)
    tip:removeAllChildren()
end

-- 点击事件 --
function CardRecoverView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self.m_canClickX then
        return
    end

    if name == "Button_Exc1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        CardSysManager:getRecoverMgr():setCardWheelSelLevel(1, self.m_Change1Num, self.m_MaxCoinsNum1)
        -- 显示兑换面板 --
        CardSysManager:getRecoverMgr():setYearTabList()
        CardSysManager:getRecoverMgr():showRecoverExchangeView()
    elseif name == "Button_Exc2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        CardSysManager:getRecoverMgr():setCardWheelSelLevel(2, self.m_Change2Num, self.m_MaxCoinsNum2)
        -- 显示兑换面板 --
        CardSysManager:getRecoverMgr():setYearTabList()
        CardSysManager:getRecoverMgr():showRecoverExchangeView()
    elseif name == "Button_Exc3" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        CardSysManager:getRecoverMgr():setCardWheelSelLevel(3, self.m_Change3Num, self.m_MaxCoinsNum3)
        -- 显示兑换面板 --
        CardSysManager:getRecoverMgr():setYearTabList()
        CardSysManager:getRecoverMgr():showRecoverExchangeView()
    elseif name == "Button_Exc1_0" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:addTip(1)
    elseif name == "Button_Exc2_0" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:addTip(2)
    elseif name == "Button_Exc3_0" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:addTip(3)
    elseif name == "recover_tip_1" then
        self:deleteTip(1)
    elseif name == "recover_tip_2" then
        self:deleteTip(2)
    elseif name == "recover_tip_3" then
        self:deleteTip(3)
    elseif name == "Button_5" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:getRecoverMgr():closeRecoverView()
        CardSysManager:showRecoverSourceUI()
    elseif name == "Button_i" then
        -- 规则
        CardSysManager:showCardRecoverRule()
    end
end

function CardRecoverView:playHideAction()
    CardRecoverView.super.playHideAction(self, "over", false)
end

-- 关闭事件 --
function CardRecoverView:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true

    -- local root = self:findChild("root")
    -- if root then
    --     self:commonHide(root,function()
    --         self:removeFromParent()
    --     end)
    -- else
    -- self:runCsbAction(
    --     "over",
    --     false,
    --     function()
    --         self:removeFromParent()
    --     end,
    --     60
    -- )
    -- end
    CardRecoverView.super.closeUI(self)
end

function CardRecoverView:onEnter()
    CardRecoverView.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            CardSysManager:getRecoverMgr():closeRecoverView()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

-- function CardRecoverView:onExit()
--     gLobalNoticManager:removeAllObservers(self)
--     CardSysManager:notifyResume()
-- end

return CardRecoverView
