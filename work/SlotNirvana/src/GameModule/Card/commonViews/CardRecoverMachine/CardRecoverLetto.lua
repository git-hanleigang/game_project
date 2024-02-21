--[[--
    回收机 - 乐透
]]
-- local BaseView = util_require("base.BaseView")
local CardRecoverLetto = class("CardRecoverLetto", BaseLayer)
local CSB_FRAME = 30

local spineAnimList = {
    {"idleframe", "actionframe", "idleframe_over"},
    {"idleframe2", "actionframe2", "idleframe_over2"},
    {"idleframe3", "actionframe3", "idleframe_over3"}
}

function CardRecoverLetto:initDatas()
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardRecoverLettoRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    self:initData()
end

function CardRecoverLetto:initUI()
    CardRecoverLetto.super.initUI(self)
    -- local isAutoScale = true
    -- if CC_RESOLUTION_RATIO == 3 then
    --     isAutoScale = false
    -- end
    -- self:createCsbNode(string.format(CardResConfig.commonRes.CardRecoverLettoRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()), isAutoScale)

    -- self:initData()
    -- self:initView()

    -- self:runCsbAction(
    --     "show",
    --     false,
    --     function()
    --         if self.showIdle then
    --             self:showIdle()
    --         end
    --     end,
    --     CSB_FRAME
    -- )
    gLobalSoundManager:pauseBgMusic()
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardLettoEnter)
end

function CardRecoverLetto:initData()
    -- 初始化数据 --
    --根据年度等级获取轮盘数据
    local cardYearData = CardSysRuntimeMgr:getCurrentYearData()

    -- 获取在之前计算好的数据 --
    self.m_maxMuls = {50, 100, 200}
    self.m_totalMul = 0
    local tExValue = CardSysManager:getRecoverMgr():getMaxStarCardList()
    for i = 1, #tExValue do
        self.m_totalMul = self.m_totalMul + tExValue[i].cardMul
    end

    -- 服务器数据参数 --
    self.m_requestData = {} -- 请求spin数据
    self.m_requestData.level = CardSysManager:getRecoverMgr():getCardWheelSelLevel().Level - 1

    self.m_requestData.cards = {}
    self.m_yearList = CardSysManager:getRecoverMgr():getYearTabList()
    for i = 1, #self.m_yearList do
        local cards = self.m_yearList[i].cards
        if cards and #cards > 0 then
            for m = 1, #cards do
                local cardData = cards[m]
                if cardData and cardData.chooseNum and cardData.chooseNum > 0 then
                    self.m_requestData.cards[#self.m_requestData.cards + 1] = {cardData.cardId, cardData.chooseNum}
                end
            end
        end
    end
    self.m_requestData.type = 0
    if CardSysManager:getRecoverMgr():getIsUseAISelect() == true then
        self.m_requestData.type = 1
    end

    -- 获得滚动数据 --
    local level = CardSysManager:getRecoverMgr():getCardWheelSelLevel().Level
    local wheelCfg = cardYearData:getWheelConfig()
    assert(wheelCfg ~= nil, "wheelCfg is nil")
    local lettosData = wheelCfg:getLettos()
    local data = lettosData[level]
    self.m_reelDatas = data.balls --小球列表
    self.m_maxMul = self.m_maxMuls[self.m_requestData.level + 1]
    self.m_baseCoins = data.baseCoins
    self.m_curMul = 1
    self.m_rewardCoins = 0
end

function CardRecoverLetto:initView()
    self:initLogo()
    self:initSpin()
    self:initBalls()
end

function CardRecoverLetto:initLogo()
    -- logo
    local logo_lotto = self:findChild("logo_lotto")
    if logo_lotto then
        self.m_logo = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLettoLogoRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        logo_lotto:addChild(self.m_logo)
        local Node_extra = self.m_logo:findChild("Node_extra")
        if self.m_totalMul > 0 then
            local m_lb_mul = self.m_logo:findChild("m_lb_mul")
            m_lb_mul:setString("+" .. (self.m_totalMul * 100) .. "%")
            local sp_logo = self.m_logo:findChild("logo")
            if sp_logo then
                local tCards = CardSysManager:getRecoverMgr():getMaxStarCardList()
                local posX = 0
                for i = 1, #tCards do
                    local cardData = tCards[i].cardData
                    if cardData then
                        local sp_card
                        if cardData.type == CardSysConfigs.CardType.puzzle then
                            -- 拼图卡
                            sp_card = util_createView("GameModule.Card.views.PuzzleCardUnitView", cardData, "show")
                            sp_card:setScale(0.13)
                        else
                            sp_card = util_createView("GameModule.Card.season201903.MiniChipUnit")
                            sp_card:playIdle()
                            sp_card:reloadUI(cardData, nil, nil, nil, true)
                            sp_card:setScale(0.2)
                        end
                        sp_logo:addChild(sp_card)
                        sp_card:setPositionX(posX + (i - 1) * 30)
                    end
                end
            end
        else
            Node_extra:setVisible(false)
        end
    end
end

function CardRecoverLetto:initSpin()
    -- spin按钮
    local spinNode = self:findChild("node_spin")
    if spinNode then
        self.m_spinNode = util_createView("GameModule.Card.commonViews.CardRecoverMachine.CardRecoverLettoSpin", self.m_baseCoins, self.m_maxMul, handler(self, self.requestSpinLetto))
        spinNode:addChild(self.m_spinNode)
    end
    -- spin背景光
    local spinLightNode = self:findChild("node_spinLight")
    if spinLightNode then
        self.m_spinLight = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLettoSpinLightRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        spinLightNode:addChild(self.m_spinLight)
        self.m_spinLight:setVisible(false)
    end
end

function CardRecoverLetto:initBalls()
    --spine小球
    local middleNode = self:findChild("Node_middle")
    if middleNode then
        --气泡粒子
        self.m_ballLizi = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLettoLiziRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        middleNode:addChild(self.m_ballLizi)
        self.m_ballLizi:setVisible(false)

        --所有小球spine
        self.m_spineBalls = util_spineCreate(CardResConfig.commonRes.CardRecoverLettoSpineBallRes, false, true, 1)
        middleNode:addChild(self.m_spineBalls)
        --根据选择等级在三套动画里面选一套播
        util_spinePlay(self.m_spineBalls, spineAnimList[self.m_requestData.level + 1][1], true)

        --单独的小球
        self.m_csbBall = util_createAnimation(string.format(CardResConfig.commonRes.CardRecoverLettoBallRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        middleNode:addChild(self.m_csbBall)
        self.m_csbBall:setVisible(false)
    end
end
--待机
function CardRecoverLetto:showIdle()
    local juese = self:findChild("FileNode_2")
    if juese then
        local csbAct = util_actCreate(string.format(CardResConfig.commonRes.CardRecoverLettoJueseRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
        juese:runAction(csbAct)
        util_csbPlayForKey(csbAct, "idle2", true)
    end
    self:runCsbAction("animation")
    self.m_spinNode:showIdle()
    self.m_spinLight:setVisible(true)
    self.m_spinLight:runCsbAction(
        "show",
        false,
        function()
            self.m_spinLight:runCsbAction("idle", true)
        end,
        30
    )
    self.m_audioLettoBg = gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardLettoBg, true)
end
--点击spin
function CardRecoverLetto:requestSpinLetto()
    self.m_networking = true
    self:findChild("btn_back"):setVisible(false)

    -- gLobalViewManager:addLoadingAnimaDelay()
    gLobalViewManager:addLoadingAnima()
    -- 成功回调
    local spinSuccess = function(tInfo)
        local successFunc = function()
            self.m_networking = false
            gLobalViewManager:removeLoadingAnima()
            local data = CardSysRuntimeMgr:getCardWheelSpinInfo()

            if not tolua.isnull(self) and self.recvData then
                self:recvData(data.index + 1, data)
            end
        end
        local yearID = CardSysRuntimeMgr:getCurrentYear()
        local albumId = CardSysRuntimeMgr:getCurAlbumID()
        local tExtraInfo = {year = yearID, albumId = albumId}
        CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo, successFunc)

        -- 需要刷新星星的数据，和倒计时信息，服务器不给发，只能自己做一次请求了
        CardSysManager:requestCardCollectionSysInfo(
            function()
                self.m_networking = false
                gLobalViewManager:removeLoadingAnima()
                -- 特殊关闭逻辑：如果请求结束后发现，赛季不对了，说明跨赛季了，要退出集卡系统
                if CardSysRuntimeMgr:getSelAlbumID() ~= CardSysRuntimeMgr:getCurAlbumID() then
                    self.m_needExitCardSys = true
                end
            end
        )
    end
    -- 失败回调
    local spinFaild = function()
        self.m_networking = false
        if not tolua.isnull(self) and self.findChild then
            self:findChild("btn_back"):setVisible(true)
        end
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end
    -- 发送spin消息 --
    CardSysNetWorkMgr:sendCardLettoRequest(self.m_requestData, spinSuccess, spinFaild)
end

--接受服务器数据
function CardRecoverLetto:recvData(index, lettoData)
    self.m_spining = true
    self.m_resultIndex = index

    local ball = self.m_reelDatas[index]
    if ball then
        self.m_curMul = ball.multiply --这个需要计算 ball.dropCard
    end
    self.m_resultData = lettoData
    self.m_rewardCoins = tonumber(lettoData.coins) --转动结果金币
    self.m_dropReward = lettoData.cardInfo --卡片掉落信息
    if self.m_rewardCoins == 0 then
        --数据存在问题
        gLobalViewManager:showReConnect()
        return
    end
    self:showSpin()
end

--获得小球
function CardRecoverLetto:getSpriteBall()
    local key = nil
    local num = 1

    if self.m_dropReward and self.m_dropReward.cards and #self.m_dropReward.cards > 0 then
        num = 2
    end
    if self.m_curMul >= 200 then
        key = 200
    else
        key = self.m_curMul .. "_" .. num
    end
    local path = CardResConfig.otherRes.CardLettoQiu .. key .. ".png"
    return util_createSprite(path)
end

--点击spin后的动画逻辑
function CardRecoverLetto:showSpin()
    local node_base = self.m_csbBall:findChild("node_base")
    if node_base then
        local sp_ball = self:getSpriteBall()
        if sp_ball then
            node_base:addChild(sp_ball)
            sp_ball:setScale(1 / 2.1)
        end
    end
    self.m_spinNode:showOver()
    self.m_spinLight:runCsbAction(
        "over",
        false,
        function()
            self.m_spinLight:setVisible(false)
        end,
        30
    )
    self.m_ballLizi:setVisible(true)
    --小球开始下落跳动
    local spineSpin = spineAnimList[self.m_requestData.level + 1][2]
    --小球停止
    local spineOver = spineAnimList[self.m_requestData.level + 1][3]
    util_spinePlay(self.m_spineBalls, spineSpin)
    util_spineFrameCallFunc(
        self.m_spineBalls,
        spineSpin,
        "fly",
        function()
            if self.m_csbBall then
                self.m_csbBall:setVisible(true)
                self.m_csbBall:runCsbAction(
                    "FlyFromBox",
                    false,
                    function()
                        self.m_csbBall:runCsbAction(
                            "Fly2Center_scale",
                            false,
                            function()
                                local node_base = self.m_csbBall:findChild("node_base")
                                local wordPos = node_base:getParent():convertToWorldSpace(cc.p(node_base:getPosition()))
                                local localPos = self:convertToNodeSpace(wordPos)
                                util_changeNodeParent(self, node_base, 1)
                                node_base:setPosition(localPos)
                                util_setCascadeOpacityEnabledRescursion(self, true)
                                local endPos = self:convertToNodeSpace(display.center)
                                node_base:runAction(cc.MoveTo:create(25 / 30, endPos))

                                self.m_csbBall:runCsbAction("Fly2Center_front")
                            end
                        )
                    end
                )

                performWithDelay(self, handler(self, self.showReward), 4)
                gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardLettoBall)
            end
        end,
        function()
            util_spinePlay(self.m_spineBalls, spineOver)
        end
    )
end
--显示结算
function CardRecoverLetto:showReward()
    -- 结算板子
    self:runCsbAction("animation2")
    local bottomNode = self:findChild("node_reward")
    if bottomNode then
        bottomNode:setScale(self:getUIScalePro())

        local node_mask = self:findChild("node_mask")
        if node_mask then
            local newMask = util_newMaskLayer()
            node_mask:addChild(newMask)
            newMask:setScale(3)
        end
        self.m_rewardNode =
            util_createView(
            "GameModule.Card.commonViews.CardRecoverMachine.CardRecoverLettoReward",
            self.m_baseCoins,
            self.m_curMul,
            self.m_totalMul,
            self.m_rewardCoins,
            self.m_dropReward,
            handler(self, self.clickOver)
        )
        bottomNode:addChild(self.m_rewardNode)
        self.m_rewardNode:setVisible(false)
        self.m_rewardNode:showIdle()
    else
        self:clickOver()
    end
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardLettoReward)
end

function CardRecoverLetto:getCoinNodeWdPosition()
    local spCoin = self.m_rewardNode:findChild("btn_collect")
    local wdPos = spCoin:getParent():convertToWorldSpace(cc.p(spCoin:getPosition()))
    return wdPos
end

--游戏结束
function CardRecoverLetto:clickOver()
    if not self.m_resultIndex then
        return
    end
    local startPos = self:getCoinNodeWdPosition()
    local dropData = nil
    if self.m_dropReward and self.m_dropReward.cards and #self.m_dropReward.cards > 0 then
        dropData = self.m_dropReward
    end
    --飞金币
    globalData.userRunData:setCoins(globalData.userRunData.coinNum + self.m_rewardCoins)
    CardSysManager:cardflyCoins(
        self.m_rewardCoins,
        startPos,
        function()
            if dropData then
                CardSysManager:dropCardOnce(dropData)
                -- 补丁：掉落的金币需要客户端自己加上
                local cardDropCoins = 0
                if dropData.albumReward and dropData.albumReward.coins > 0 then
                    cardDropCoins = cardDropCoins + dropData.albumReward.coins
                end
                if dropData.clanReward and #dropData.clanReward > 0 then
                    for j = 1, #dropData.clanReward do
                        local clanData = dropData.clanReward[j]
                        if clanData.coins and clanData.coins > 0 then
                            cardDropCoins = cardDropCoins + clanData.coins
                        end
                    end
                end
                if cardDropCoins > 0 then
                    globalData.userRunData:setCoins(globalData.userRunData.coinNum + cardDropCoins)
                end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            CardSysManager:getRecoverMgr():closeRecoverWheelView()

            CardSysManager:getRecoverMgr():closeRecoverExchangeView()
            CardSysManager:getRecoverMgr():closeRecoverView()
            if self.m_needExitCardSys then
                CardSysManager:exitCard()
            else
                CardSysManager:showRecoverSourceUI()
            end
        end,
        true
    )
end

function CardRecoverLetto:playShowAction()
    CardRecoverLetto.super.playShowAction(self, "show", false, CSB_FRAME)
end

function CardRecoverLetto:onShowedCallFunc()
    if self.showIdle then
        self:showIdle()
    end
end

function CardRecoverLetto:onEnter()
    CardRecoverLetto.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            CardSysManager:getRecoverMgr():closeRecoverExchangeView()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

-- function CardRecoverLetto:onExit()
--     gLobalNoticManager:removeAllObservers(self)
--     CardSysManager:notifyResume()
-- end

function CardRecoverLetto:playHideAction()
    local _action = function(callback)
        local fadeTime = 0.5
        self:runAction(cc.FadeOut:create(fadeTime))
        performWithDelay(
            self,
            function()
                if callback then
                    callback()
                end
            end,
            fadeTime
        )
    end
    CardRecoverLetto.super.playHideAction(self, _action)
end

function CardRecoverLetto:closeUI()
    if self.m_closed then
        return
    end
    self.m_closed = true
    if self.m_rewardNode then
        self.m_rewardNode:showOver()
    end
    if self.m_spining then
        self:runCsbAction("animation3")
    end
    util_setCascadeOpacityEnabledRescursion(self, true)
    -- local fadeTime = 0.5
    -- self:runAction(cc.FadeOut:create(fadeTime))
    -- performWithDelay(
    --     self,
    --     function()
    --         self:removeFromParent()
    --     end,
    --     fadeTime
    -- )
    if self.m_audioLettoBg ~= nil then
        gLobalSoundManager:stopAudio(self.m_audioLettoBg)
        self.m_audioLettoBg = nil
    end
    gLobalSoundManager:resumeBgMusic()

    CardRecoverLetto.super.closeUI(self)
end

function CardRecoverLetto:canClick()
    if self.m_spining then
        return false
    end
    if self.m_networking then
        return false
    end
    return true
end

function CardRecoverLetto:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self:canClick() then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_back" then
        --返回
        CardSysManager:getRecoverMgr():closeRecoverWheelView()
        CardSysManager:getRecoverMgr():showRecoverExchangeView()
        CardSysManager:getRecoverMgr():showRecoverView()
    end
end

return CardRecoverLetto