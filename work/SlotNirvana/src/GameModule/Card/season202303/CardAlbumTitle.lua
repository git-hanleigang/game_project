--[[--
    章节选择界面的标题
]]
local UIStatus = {
    Normal = 1,
    Complete = 2
}
local CardAlbumTitle = class("CardAlbumTitle", BaseView)

function CardAlbumTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardAlbumTitleRes, "season202303")
end

function CardAlbumTitle:getTimeLua()
    return "GameModule.Card.season202303.CardSeasonTime"
end

function CardAlbumTitle:getRoundTipLua()
    return "GameModule.Card.season202303.CardAlbumRoundTip"
end

function CardAlbumTitle:getRoundRewardListLua()
    return "GameModule.Card.season202303.CardAlbumRoundRewardList"
end

function CardAlbumTitle:initDatas(_albumClass)
    self.m_albumClass = _albumClass
    self.m_isFirstTime = true
    self.m_iCollectCoin = 0
end

function CardAlbumTitle:initCsbNodes()
    self.m_nodeRoot = self:findChild("root")
    self.m_node_coins = self:findChild("Node_coins")
    self.m_lb_coins = self:findChild("coins")
    self.m_lb_pro = self:findChild("process")
    self.m_timeNode = self:findChild("Node_time")

    self.m_spCoin = self:findChild("jinbi")
    self.m_nodeRound = self:findChild("node_round_tip")
    self.m_nodeList = self:findChild("Node_list")
    self.m_nodeBanzi = self:findChild("node_banzi")

    self.m_btnOpen = self:findChild("btn_open")
    self.m_spOpen = self:findChild("sp_open")

    self.m_nodeBuff = self:findChild("node_mythic_reward")

    self.m_Node_AlbumMoreAward = self:findChild("Node_AlbumMoreAward")
end

function CardAlbumTitle:initUI()
    CardAlbumTitle.super.initUI(self)
    self:initView()
end

function CardAlbumTitle:initView()
    self:initTime()
    self:initRoundTip()
    self:initBuffTag()
    self:initAlbumMoreAward()

    -- 以往赛季隐藏轮次列表
    if tonumber(CardSysRuntimeMgr:getSelAlbumID()) == tonumber(CardSysRuntimeMgr:getCurAlbumID()) then
        self:initRoundRewards()
        self.m_btnOpen:setVisible(true)
        self.m_spOpen:setVisible(true)
    else
        self.m_btnOpen:setVisible(false)
        self.m_spOpen:setVisible(false)
    end
    
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CardAlbumTitle:initAlbumMoreAward()
    if not self.m_moreAward and self.m_Node_AlbumMoreAward then
        local node = G_GetMgr(ACTIVITY_REF.AlbumMoreAward):getTimeNode()
        if node then
            self.m_Node_AlbumMoreAward:addChild(node)
            self.m_moreAward = node
        end
    end
end

function CardAlbumTitle:initBuffTag()
    local multi = self:getBuffMulti()
    if multi and multi > 0 then
        self.m_nodeBuff:setVisible(true)
        if not self.m_buffNode then
            self.m_buffNode = self:createBuffNode()
        end
        if self.m_buffNode then
            self.m_buffNode:updateBuffMultiple(multi)
        end
    else
        self.m_nodeBuff:setVisible(false)
    end
end

function CardAlbumTitle:createBuffNode()
    local buff = G_GetMgr(G_REF.CardSpecialClan):createSpecialClanBuffNode()
    if buff then
        self.m_nodeBuff:addChild(buff) 
    end
    return buff
end

function CardAlbumTitle:initTime()
    -- 赛季结束时间戳
    local ui = util_createView(self:getTimeLua())
    self.m_timeNode:addChild(ui)
end

function CardAlbumTitle:initRoundTip()
    local view = util_createView(self:getRoundTipLua())
    self.m_nodeRound:addChild(view)
end

--[[-- 赛季新增多轮奖励展示 ]]
function CardAlbumTitle:initRoundRewards()
    self.m_rewards = util_createView(self:getRoundRewardListLua())
    if self.m_rewards then
        self.m_nodeList:addChild(self.m_rewards)
    end
end

function CardAlbumTitle:createHideLayout()
    local tLayout = ccui.Layout:create()
    tLayout:setName("round_hide_touch")
    tLayout:setTouchEnabled(true)
    tLayout:setSwallowTouches(false)
    tLayout:setAnchorPoint(cc.p(0.5, 0.5))
    tLayout:setContentSize(cc.size(display.width, display.height))
    tLayout:setClippingEnabled(false)
    tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
    tLayout:setBackGroundColorOpacity(0)

    self:addChild(tLayout)
    self:addClick(tLayout)

    local scale = self:getUIScalePro()
    if scale < 1 then
        scale = 1 / scale
    end
    tLayout:setScale(scale)

    return tLayout
end

function CardAlbumTitle:playStart(_over)
    self:runCsbAction("show2", false, _over, 30)
end

function CardAlbumTitle:playIdle()
    self:runCsbAction("idle2", true, nil, 30)
end

function CardAlbumTitle:playOver(_over)
    self:runCsbAction("over2", false, _over, 30)
end

function CardAlbumTitle:playCompleteStart(_over)
    self:runCsbAction("show1", false, _over, 30)
end

function CardAlbumTitle:playCompleteIdle()
    self:runCsbAction("idle1", true, nil, 30)
end

function CardAlbumTitle:playCompleteOver(_over)
    self:runCsbAction("over1", false, _over, 30)
end

function CardAlbumTitle:showRoundReward()
    if self:isRoundGuiding() then
        return
    end
    if self.m_rounding then
        return
    end
    self.m_rounding = true
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")

    if not self.m_touchLayer then
        self.m_touchLayer = self:createHideLayout()
        self.m_touchLayer:setGlobalZOrder(1)
        self.m_touchLayer:setVisible(false)
        local lPos = self.m_touchLayer:getParent():convertToNodeSpace(cc.p(display.cx, display.cy))
        self.m_touchLayer:setPosition(lPos)
    end

    local function showCall()
        if not tolua.isnull(self) then
            self.m_rounding = false
            self.m_touchLayer:setVisible(true)
        end
    end
    self.m_nodeBanzi:runAction(cc.FadeOut:create(0.5))
    if self.m_rewards then
        self.m_rewards:playStart(showCall)
    else
        showCall()
    end
end

function CardAlbumTitle:hideRoundReward()
    if self:isRoundGuiding() then
        return
    end
    if self.m_rounding then
        return
    end
    self.m_rounding = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local function hideCall()
        if not tolua.isnull(self) then
            self.m_rounding = false
            if self.m_touchLayer then
                self.m_touchLayer:setVisible(false)
            end
            if self.m_UIStatus == UIStatus.Complete then
                self:playCompleteIdle()
            else
                self:playIdle()
            end
        end
    end
    util_performWithDelay(
        self,
        function()
            self.m_nodeBanzi:runAction(cc.FadeIn:create(0.5))
        end,
        0.5
    )
    if self.m_rewards then
        self.m_rewards:playOver(hideCall)
    else
        hideCall()
    end
end

function CardAlbumTitle:updateUIStatus(isPlayStart)
    self.m_UIStatus = self:getUIStatus()
    if self.m_UIStatus == UIStatus.Complete then
        if isPlayStart then
            self.m_starting = true
            self:playCompleteStart(
                function()
                    self.m_starting = false
                    self:playCompleteIdle()
                end
            )
        else
            self:playCompleteIdle()
        end
    else
        if isPlayStart then
            self.m_starting = true
            self:playStart(
                function()
                    self.m_starting = false
                    self:playIdle()
                end
            )
        else
            self:playIdle()
        end
    end
end

function CardAlbumTitle:updatePro()
    local cur, max = self:getPro()
    self.m_lb_pro:setString(cur .. "/" .. max)
end

function CardAlbumTitle:updateCoin(_isPlayStart)
    local coins = tonumber(self:getAlbumCoins() or 0)
    local showCoins = coins
    local extraMulti = self:getCoinTotalMulti(_isPlayStart)
    if extraMulti > 0 then
        showCoins = extraMulti * showCoins
    end
    self.m_iCollectCoin = showCoins
    self.m_lb_coins:setString(util_formatCoins(showCoins, 33))

    if not self.m_isFirstTime then
        return
    end
    self.m_isFirstTime = true
    self.m_factor = 1
    local timeLimitExpansion = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion)
    if timeLimitExpansion then
        self.m_factor = self.m_factor + timeLimitExpansion:getExpansionRatio()
    end

    self.m_curCoins = math.floor((showCoins / self.m_factor) + 0.00001)
    self.m_lb_coins:setString(util_formatCoins(self.m_curCoins, 33))

    if self.m_factor > 1 then
        gLobalNoticManager:addObserver(
            self,
            function()
                self:carnivalCoinsAction()
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_TIMELIMITEXPANSION_LOGOLAYER_CLOSE)
            end,
            ViewEventType.NOTIFY_TIMELIMITEXPANSION_LOGOLAYER_CLOSE
        )
    end
    self:alignCoins()
end

function CardAlbumTitle:alignCoins()
    local UIList = {}
    util_formatStringScale(self.m_lb_coins, 530, 0.75)
    table.insert(UIList, {node = self.m_spCoin, anchor = cc.p(0.5, 0.5)})
    table.insert(UIList, {node = self.m_lb_coins, alignX = 5, alignY = self.m_lb_coins:getPositionY(), scale = self.m_lb_coins:getScale(), anchor = cc.p(0.5, 0.5)})
    util_alignCenter(UIList)
end

function CardAlbumTitle:carnivalCoinsAction()
    if self.m_factor > 1 then
        local baseCoins = self.m_iCollectCoin
        local interval = 1 / 30
        local rolls = 33
        local curStep = math.floor((baseCoins - self.m_curCoins) / rolls)

        self.m_scheduleId =
            schedule(
            self,
            function()
                self.m_curCoins = math.min(self.m_curCoins + curStep, baseCoins)
                self.m_lb_coins:setString(util_formatCoins(self.m_curCoins, 33))
                self:alignCoins()
                if self.m_curCoins >= baseCoins then
                    if self.m_scheduleId then
                        self:stopAction(self.m_scheduleId)
                        self.m_scheduleId = nil
                    end
                end
            end,
            interval
        )

        local _ts = (rolls + 2) * interval
        local _action = {}
        _action[1] = cc.EaseBackInOut:create(cc.ScaleTo:create(_ts, 1.2))
        _action[2] = cc.ScaleTo:create(0.1, 1)
        _action[3] =
            cc.CallFunc:create(
            function()
                self:playBaoZaAction()
            end
        )
        self.m_node_coins:runAction(cc.Sequence:create(_action))
    end
end

function CardAlbumTitle:playBaoZaAction()
    local sp = util_createAnimation(SHOP_RES_PATH.CoinLizi)
    if sp then
        self.m_node_coins:addChild(sp, 10)
        sp:playAction(
            "start",
            false,
            function()
                sp:removeFromParent()
            end,
            60
        )
    end
end

function CardAlbumTitle:updateUI(isPlayStart)
    self:updateUIStatus(isPlayStart)
    self:updatePro()
    self:updateCoin(isPlayStart)
end

-- 赛季新增多轮次弹框
function CardAlbumTitle:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_open" then
        self:showRoundReward()
    elseif name == "round_hide_touch" then
        self:hideRoundReward()
    end
end

function CardAlbumTitle:onEnter()
    CardAlbumTitle.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initBuffTag()
            self:updateCoin()
        end,
        ViewEventType.NOTIFY_MULEXP_END
    )
    -- 新赛季开启清除buff刷新ui
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initBuffTag()
            self:updateCoin()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )

    -- 限时集卡多倍奖励
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initAlbumMoreAward()
            self:updateCoin()
        end,
        ViewEventType.NOTIFY_ALBUM_MORE_AWARD_UPDATE_DATA
    )

    -- 限时集卡多倍奖励 金币滚动
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:albumMoreAwardRoll()
        end,
        ViewEventType.NOTIFY_ALBUM_MORE_AWARD_LOGO_HIDE
    )

    -- 限时集卡多倍奖励 时间到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateCoin()
        end,
        ViewEventType.NOTIFY_ALBUM_MORE_AWARD_TIME_END
    )
end

function CardAlbumTitle:isRoundGuiding()
    if self.m_albumClass:isGuiding() then
        return true
    end
    return false
end

function CardAlbumTitle:getAlbumCoins()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    if albumData then
        return albumData.coins or 0
    end
    return 0
end

function CardAlbumTitle:getPro()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    if albumData then
        return albumData.current or 0, albumData.total or 22
    end
    return 0, 22
end

function CardAlbumTitle:getUIStatus()
    local cur, max = self:getPro()
    if cur >= max then
        return UIStatus.Complete
    end
    return UIStatus.Normal
end

function CardAlbumTitle:getCardEndSpecialMul()
    local mul = 1
    if G_GetMgr(ACTIVITY_REF.CardEndSpecial):getRunningData() then
        mul = globalData.constantData.CARD_SPECIAL_REWAR or 2
    end    
    return mul
end

function CardAlbumTitle:getBuffMulti()
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if albumID and CardSysRuntimeMgr:isPastAlbum(albumID) then
        return 0
    end
    local buffInfo = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
    if buffInfo then
        local nMuti = tonumber(buffInfo.buffMultiple)
        if nMuti and nMuti > 0 then
            return nMuti
        end
    end
    return 0
end

function CardAlbumTitle:getAlbumMoreAwardMul(_isPlayStart)
    local multiply = G_GetMgr(ACTIVITY_REF.AlbumMoreAward):getMultiply()
    if _isPlayStart then
        multiply = 0
    end
    return multiply
end

-- 每次加buff都要询问计算公式是什么
function CardAlbumTitle:getCoinTotalMulti(_isPlayStart)
    local extraMulti = 0
    local endMul = self:getCardEndSpecialMul()
    if endMul and endMul > 0 then
        extraMulti = extraMulti + endMul
    end

    local multi = self:getBuffMulti()
    if multi and multi > 0 then
        extraMulti = extraMulti + multi/100
    end

    local moreAwardMul = self:getAlbumMoreAwardMul(_isPlayStart)
    if moreAwardMul and moreAwardMul > 0 then
        extraMulti = extraMulti + moreAwardMul
    end

    return extraMulti
end

function CardAlbumTitle:albumMoreAwardRoll()
    local multiply = self:getAlbumMoreAwardMul()
    if multiply > 0 and self.m_Node_AlbumMoreAward then
        local count = 0
        local coins = tonumber(self:getAlbumCoins() or 0)
        local showCoins = self.m_iCollectCoin
        local addCoins = multiply * coins / 20
        local setCoins = function ()
            count = count + 1
            if count > 20 then 
                self.m_iCollectCoin = self.m_iCollectCoin + multiply * coins
                self.m_lb_coins:setString(util_formatCoins(self.m_iCollectCoin, 33))
                
                local UIList = {}
                util_formatStringScale(self.m_lb_coins, 530, 0.75)
                table.insert(UIList, {node = self.m_spCoin, anchor = cc.p(0.5, 0.5)})
                table.insert(UIList, {node = self.m_lb_coins, alignX = 5, alignY = self.m_lb_coins:getPositionY(), scale = self.m_lb_coins:getScale(), anchor = cc.p(0.5, 0.5)})
                util_alignCenter(UIList)
                self.m_Node_AlbumMoreAward:stopAllActions()
                return
            else
                showCoins = math.floor(showCoins + addCoins)
                self.m_lb_coins:setString(util_formatCoins(showCoins, 33))
            end
        end
        setCoins()
        schedule(self.m_Node_AlbumMoreAward, setCoins, 0.02)
    end
end

return CardAlbumTitle
