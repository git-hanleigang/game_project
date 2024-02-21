--[[
    卡片收集规则界面  一些玩法说明 --
]]
local CardNadoWheelOver = class("CardNadoWheelOver", BaseLayer)

function CardNadoWheelOver:initDatas(node, hideLater, closeMainUI)
    self.m_closeMainUI = closeMainUI
    self.m_nadoWheelMainUI = node
    self.m_hideLater = hideLater
    local albumId = tostring(CardSysRuntimeMgr:getCurAlbumID())
    self:setLandscapeCsbName(string.format("CardRes/common%s/cash_nado_wheel_over.csb", albumId))
    self:setPortraitCsbName(string.format("CardRes/common%s/cash_nado_wheel_over_shu.csb", albumId))
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:initDropList()

    local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    self.m_rewardItems = CardSysRuntimeMgr:getNadoGameReward(linkGameData.reward)
    if self.m_rewardItems and #self.m_rewardItems > 0 then
        for i, tempData in ipairs(self.m_rewardItems) do
            local tempData = ShopItem:create()
            -- 高倍场小游戏猫粮会有单独 弹板并且弹板顺序有逻辑
            if string.find(tempData.p_icon, "CatFood") then
                table.insert(self.m_catFoodList, tempData)
            end
            if string.find(tempData.p_icon, "Pouch") then
                table.insert(self.m_propsBagist, tempData)
            end
        end
    end
end

-- 初始化 list
function CardNadoWheelOver:initDropList()
    local _dropFuncList = {}
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerFlyCoins)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerPlayOverAction)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerDropCards)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerCatFoodView)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerDeluxeCard)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerPropsBagView)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerVipLevelUp)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerBigCoins)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerOperateGuidePopup)
    self.m_dropFuncList = _dropFuncList
end

function CardNadoWheelOver:initCsbNodes()
    self.m_iconNode = self:findChild("node_rewards")
    self.m_btnCollect1 = self:findChild("Button_collect1")
    self.m_btnCollect2 = self:findChild("Button_collect2")
    self.m_btnCollect1:setTouchEnabled(false)
    self.m_btnCollect2:setTouchEnabled(false)
end

-- 初始化UI --
function CardNadoWheelOver:initUI()
    CardNadoWheelOver.super.initUI(self)
end

function CardNadoWheelOver:initView()
    local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    if linkGameData.nadoGames == 0 or self.m_hideLater then
        self.m_btnCollect1:setVisible(true)
        self.m_btnCollect2:setVisible(false)
    else
        self.m_btnCollect1:setVisible(false)
        self.m_btnCollect2:setVisible(true)
    end
    self:initRewardIcon()
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
    self.m_isStartShowing = true
    self:runCsbAction(
        "show1",
        false,
        function()
            if not tolua.isnull(self) then
                local isNext = false
                for i = 1, #self.m_overItems do
                    self.m_overItems[i]:playItemAction(
                        function()
                            if isNext then
                                return
                            end
                            isNext = true
                            if not tolua.isnull(self) then
                                self:runCsbAction(
                                    "show2",
                                    false,
                                    function()
                                        if not tolua.isnull(self) then
                                            self:runCsbAction("idle", true)
                                            self.m_isStartShowing = false
                                            self.m_btnCollect1:setTouchEnabled(true)
                                            self.m_btnCollect2:setTouchEnabled(true)
                                        end
                                    end
                                )
                            end
                        end
                    )
                end
            end
        end
    )
end

function CardNadoWheelOver:initRewardIcon()
    local showNum = 0
    for k, v in pairs(self.m_rewardItems) do
        if k ~= "bigCoinsCount" then
            if type(v) == "number" then
                showNum = showNum + 1
            elseif type(v) == "table" then
                showNum = showNum + #v
            end
        end
    end

    local intervalDis = 160
    local divideNum = 0
    if showNum > 4 then
        divideNum = math.floor(showNum / 2 + 0.5)
    end

    local function setUIList(_UIList1, _UIList2, _index, _view, _divideNum)
        if _divideNum > 0 then
            if _index <= _divideNum then
                _view:setPositionY(intervalDis / 2)
                _UIList1[#_UIList1 + 1] = {node = _view, size = cc.size(intervalDis, intervalDis), anchor = cc.p(0.5, 0.5)}
            else
                _view:setPositionY(-intervalDis / 2)
                _UIList2[#_UIList2 + 1] = {node = _view, size = cc.size(intervalDis, intervalDis), anchor = cc.p(0.5, 0.5)}
            end
        else
            _UIList1[#_UIList1 + 1] = {node = _view, size = cc.size(intervalDis, intervalDis), anchor = cc.p(0.5, 0.5)}
        end
    end

    local UIList1 = {}
    local UIList2 = {}

    self.m_overItems = {}
    local index = 0
    for k, v in pairs(self.m_rewardItems) do
        if k ~= "bigCoinsCount" then
            if type(v) == "number" then
                index = index + 1
                if k == "bigCoins" then
                    v = self.m_rewardItems and self.m_rewardItems.bigCoinsCount and self.m_rewardItems.bigCoinsCount
                end
                local view = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelOverItem", {key = k, data = v})
                self.m_iconNode:addChild(view)
                table.insert(self.m_overItems, view)
                setUIList(UIList1, UIList2, index, view, divideNum)
            elseif type(v) == "table" then
                for i = 1, #v do
                    index = index + 1
                    local view = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelOverItem", {key = k, data = v[i]})
                    self.m_iconNode:addChild(view)
                    table.insert(self.m_overItems, view)
                    setUIList(UIList1, UIList2, index, view, divideNum)
                end
            end
        end
    end

    if #UIList1 > 0 then
        util_alignCenter(UIList1)
    end
    if #UIList2 > 0 then
        util_alignCenter(UIList2)
    end
end

function CardNadoWheelOver:playOver(_over)
    self:runCsbAction("over", false, _over, 30)
end

function CardNadoWheelOver:collectReward()
    -- 成功回调
    local function spinSuccess(tInfo)
        if tolua.isnull(self) then
            return
        end
        -- 重新拿一下服务器下发的数据
        local linkGameData = CardSysRuntimeMgr:getLinkGameData()
        if linkGameData.reward and linkGameData.reward.cardDrops and #linkGameData.reward.cardDrops > 0 then
            -- self.m_hasDrops = true
            CardSysManager:doDropCardsData(linkGameData.reward.cardDrops)
        end
        self.m_clickCollect = false
        self.m_nextTriggering = true

        -- 同步数据
        self:syncOtherSysData()
        self:triggerDropFuncNext()
    end

    -- 失败回调
    local spinFaild = function()
        gLobalViewManager:showReConnect()
    end

    local updateMainUI = function()
        if not tolua.isnull(self) then
            if self.m_nadoWheelMainUI and self.m_nadoWheelMainUI.initLeftCount then
                self.m_nadoWheelMainUI:initLeftCount()
            end
        end
    end

    -- 发送spin消息 --
    CardSysNetWorkMgr:sendCardLinkPlayRequest({status = 1}, spinSuccess, spinFaild, updateMainUI)
end

function CardNadoWheelOver:syncOtherSysData()
    if self.m_rewardItems.highLimitPoints and self.m_rewardItems.highLimitPoints > 0 then
        local addHighLimitPoints = tonumber(self.m_rewardItems.highLimitPoints)
        -- local buffMultiple = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_NADO_REWARD_BONUS)
        -- if buffMultiple and buffMultiple > 0 then
        --     addHighLimitPoints = addHighLimitPoints * buffMultiple
        -- end
        globalData.deluexeClubData.p_currPoint = globalData.deluexeClubData.p_currPoint + addHighLimitPoints
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE)
    end

    if self.m_rewardItems.rewards then
        -- 刷新猫粮数据和界面
        for i = 1, #self.m_rewardItems.rewards do
            local rewards = self.m_rewardItems.rewards[i]
            if rewards then
                local icon = rewards.p_icon
                if icon then
                    if string.find(icon, "CatFood") then
                        local idx = string.sub(icon, -1)
                        local count = rewards.p_num
                        local catManager = G_GetMgr(ACTIVITY_REF.DeluxeClubCat)
                        catManager:changeCatFoodNum(idx, tonumber(count))
                    end
                    if string.find(icon, "Pouch") then
                        local count = rewards.p_num
                        local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                        mergeManager:refreshBagsNum(icon, count)
                    end
                else
                    release_print("---- rewards.p_icon is nil ----")
                end
            end
        end
    end
end

-- function CardNadoWheelOver:flyCoins(_rewardCoins, _over)
--     local startPos = self.m_flyCoinsNode:getParent():convertToWorldSpace(cc.p(self.m_flyCoinsNode:getPosition()))
--     CardSysManager:cardflyCoins(
--         _rewardCoins,
--         startPos,
--         function()
--             if _over then
--                 _over()
--             end
--         end,
--         nil,
--         true
--     )
-- end

function CardNadoWheelOver:flyCoins(_coinNum, _flyOver)
    if _coinNum > 0 then
        globalData.userRunData:setCoins(globalData.userRunData.coinNum + _coinNum)
    end
    -- 屏蔽点击
    if not (self.m_flyCoinsNode and _coinNum > 0) then
        if _flyOver then
            _flyOver()
        end
        return
    end
    self.m_isFlyingCoins = true

    local baseCoins = globalData.topUICoinCount
    local startPos = self.m_flyCoinsNode:getParent():convertToWorldSpace(cc.p(self.m_flyCoinsNode:getPosition()))
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local flyList = {}
        table.insert(flyList, {cuyType = FlyType.Coin, addValue = _coinNum, startPos = startPos})
        curMgr:playFlyCurrency(
            flyList,
            function()
                if not tolua.isnull(self) then
                    self.m_isFlyingCoins = false
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {coins = baseCoins + _coinNum, isPlayEffect = false})
                    if _flyOver then
                        _flyOver()
                    end
                end
            end
        )
    end
end

function CardNadoWheelOver:closeUI(overFunc)
    if self.m_closed then
        return
    end
    self.m_closed = true

    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_NADO_WHEEL_REWARD_CLOSE)

    local callFunc = function()
        if self.m_closeMainUI then
            -- if self.m_hasDrops then
            --     CardSysManager:getLinkMgr():setHasDrops(true)
            --     self.m_hasDrops = nil
            -- end
            CardSysManager:closeNadoMachine()
        else
            -- 收集奖励后判断是否没有次数了，如果没有次数，直接关闭主界面
            if self.m_nadoWheelMainUI and self.m_nadoWheelMainUI.getLeftCount then
                if self.m_nadoWheelMainUI:getLeftCount() == 0 then
                    -- if self.m_hasDrops then
                    --     CardSysManager:getLinkMgr():setHasDrops(true)
                    --     self.m_hasDrops = nil
                    -- end
                    CardSysManager:closeNadoMachine()
                end
            end
        end

        if overFunc then
            overFunc()
        end
    end

    CardNadoWheelOver.super.closeUI(self, callFunc)
end

function CardNadoWheelOver:canClick()
    if self.m_isStartShowing then
        return false
    end
    if self.m_closed then
        return false
    end
    if self.m_clickCollect then
        return false
    end
    if self.m_nextTriggering then
        return false
    end
    return true
end

function CardNadoWheelOver:onClickMask()
    if self.m_btnCollect1:isVisibleEx() then
        self:onClickCollect(self.m_btnCollect1)
    elseif self.m_btnCollect2:isVisibleEx() then
        self:onClickCollect(self.m_btnCollect2)
    end
end

function CardNadoWheelOver:onClickCollect(btnCollect)
    if not self:canClick() then
        return
    end

    self.m_clickCollect = true
    self.m_flyCoinsNode = btnCollect
    self:collectReward()
end

function CardNadoWheelOver:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "Button_collect1" then
        self:onClickCollect(sender)
    elseif name == "Button_collect2" then
        self:onClickCollect(sender)
    end
end

function CardNadoWheelOver:onEnter()
    CardNadoWheelOver.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            self:closeUI()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

function CardNadoWheelOver:getTotalCoins()
    local total = 0
    if self.m_rewardItems and self.m_rewardItems.coins and self.m_rewardItems.coins > 0 then
        total = total + self.m_rewardItems.coins
    end
    -- local buffMultiple = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_NADO_REWARD_BONUS)
    -- if buffMultiple and buffMultiple > 0 then
    --     total = total * buffMultiple
    -- end
    return total
end

-- 检测 list 调用方法
function CardNadoWheelOver:triggerDropFuncNext()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        if not tolua.isnull(self) then
            self:closeUI()
        end
        return
    end

    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

function CardNadoWheelOver:triggerFlyCoins()
    local totalCoins = self:getTotalCoins()
    if totalCoins > 0 then
        self:flyCoins(
            totalCoins,
            function()
                if not tolua.isnull(self) then
                    performWithDelay(
                        self,
                        function()
                            if not tolua.isnull(self) then
                                self:triggerDropFuncNext()
                            end
                        end,
                        0.3
                    )
                end
            end
        )
    else
        self:triggerDropFuncNext()
    end
end

function CardNadoWheelOver:triggerPlayOverAction()
    self:playOver(
        function()
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end
        end
    )
end

-- 检测掉卡
function CardNadoWheelOver:triggerDropCards()
    if CardSysManager:needDropCards("Nado Machine") == true then
        -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响
        -- gLobalNoticManager:addObserver(
        --     self,
        --     function(sender, func)
        --         gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
        --         if not tolua.isnull(self) then
        --             self:triggerDropFuncNext()
        --         end
        --     end,
        --     ViewEventType.NOTIFY_CARD_SYS_OVER
        -- )
        CardSysManager:doDropCards("Nado Machine", function()
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end
        end, true)
    else
        self:triggerDropFuncNext()
    end
end

-- 检测掉落猫粮
function CardNadoWheelOver:triggerCatFoodView()
    G_GetMgr(ACTIVITY_REF.DeluxeClubCat):popCatFoodRewardPanel(
        self.m_catFoodList,
        function()
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end
        end
    )
end

-- 检测高倍场体验卡
function CardNadoWheelOver:triggerDeluxeCard()
    gLobalNoticManager:postNotification(
        ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM,
        function()
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end
        end
    )
end

-- 检测掉落 合成福袋
function CardNadoWheelOver:triggerPropsBagView()
    G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):popMergePropsBagRewardPanel(
        self.m_propsBagist,
        function()
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end
        end
    )
end

-- 判断 vip升级弹窗
function CardNadoWheelOver:triggerVipLevelUp()
    local bVipLevelUp = gLobalSaleManager:checkVipLevelUp()
    if bVipLevelUp then
        G_GetMgr(G_REF.Vip):showLevelUpLayer(
            function()
                if not tolua.isnull(self) then
                    self:triggerDropFuncNext()
                end
            end
        )
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_VIPLEVEL_UP)
    else
        self:triggerDropFuncNext()
    end
end

function CardNadoWheelOver:triggerBigCoins()
    local bigCoins = self.m_rewardItems and self.m_rewardItems.bigCoins and self.m_rewardItems.bigCoins
    local bigCoinsCount = self.m_rewardItems and self.m_rewardItems.bigCoinsCount and self.m_rewardItems.bigCoinsCount

    if not ((bigCoinsCount and bigCoinsCount > 0) and (bigCoinsCount and bigCoinsCount > 0)) then
        self:triggerDropFuncNext()
        return
    end
    if gLobalViewManager:getViewByName("CardNadoWheelBigCoinOver") ~= nil then
        self:triggerDropFuncNext()
        return
    end
    local view =
        util_createView(
        "GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelBigCoinOver",
        bigCoinsCount,
        bigCoins,
        function()
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end
        end
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CardNadoWheelOver:triggerOperateGuidePopup()
    local bigCoins = self.m_rewardItems and self.m_rewardItems.bigCoins and self.m_rewardItems.bigCoins
    local bigCoinsCount = self.m_rewardItems and self.m_rewardItems.bigCoinsCount and self.m_rewardItems.bigCoinsCount

    if not ((bigCoinsCount and bigCoinsCount > 0) and (bigCoinsCount and bigCoinsCount > 0)) then
        self:triggerDropFuncNext()
        return
    end

    local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("NadoMachineWin")
    if view then
        view:setOverFunc(function()
            -- 弹板关闭回调
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end            
        end)
    else
        self:triggerDropFuncNext()
    end
end

return CardNadoWheelOver
