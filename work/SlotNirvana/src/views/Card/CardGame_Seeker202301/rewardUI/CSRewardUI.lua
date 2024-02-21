--[[
]]
local CSRewardUI = class("CSRewardUI", BaseLayer)

function CSRewardUI:initDatas(_isFinal, _over)
    self.m_isFinal = _isFinal
    self.m_over = _over
    self.m_hasGem = false

    self:cacheWinRewardData()
    -- if _isFinal == true then
    --     self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_RewardLayer.csb")
    -- else
    --     self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_RewardLayer.csb")
    -- end
    self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_RewardLayer.csb")
end

function CSRewardUI:cacheWinRewardData()
    local GameData = G_GetMgr(G_REF.CardSeeker):getRunningData()
    if not GameData then
        return
    end
    local winRewardData = GameData:getWinRewardData()
    if not winRewardData then
        return
    end
    self.m_winRewardData = clone(winRewardData)
end

function CSRewardUI:getCardSource()
    return "Mythic Chip Game"
end

-- 检测 list 调用方法
function CSRewardUI:triggerDropFuncNext()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        if not tolua.isnull(self) then
            self:closeUI(
                function()
                    local mainUI = gLobalViewManager:getViewByName("CSMainLayer")
                    if not tolua.isnull(mainUI) then
                        mainUI:closeUI(
                            function()
                                G_GetMgr(G_REF.CardSeeker):exitGame()
                            end
                        )
                    else
                        G_GetMgr(G_REF.CardSeeker):exitGame()
                    end
                end
            )
        end
        return
    end

    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

function CSRewardUI:initCsbNodes()
    self.m_nodeRewards = self:findChild("node_rewards")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_btnClose = self:findChild("btn_close")
end

function CSRewardUI:initView()
    gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/Seeker_reward_success.mp3")
    self:initDropList()
    self:initRewards()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

-- 初始化 list
function CSRewardUI:initDropList()
    local _dropFuncList = {}
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerDropCrads)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerCatFoodView)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerDeluxeCard)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerPropsBagView)
    self.m_dropFuncList = _dropFuncList
end

function CSRewardUI:initRewards()
    if not self.m_winRewardData then
        return
    end    
    local coinNum = self.m_winRewardData:getCoins() or 0
    local gemNum = self.m_winRewardData:getGems() or 0
    local items = self.m_winRewardData:getMergeItems()

    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
    local parentNode = self.m_nodeRewards

    local itemNum = 0
    if coinNum > 0 then
        itemNum = itemNum + 1
    end
    if gemNum > 0 then
        itemNum = itemNum + 1
    end
    if items and #items > 0 then
        itemNum = itemNum + #items
    end

    local alignY1 = 0
    local alignY2 = 0
    if itemNum > 5 then
        alignY1 = width / 2
        alignY2 = -width / 2 - 10
    end
    local itemCount1 = 0

    local itemNodeList = {}
    local itemNodeList2 = {}
    if coinNum > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", coinNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD)
        if itemNode then
            parentNode:addChild(itemNode)
            if itemNum > 5 then
                itemNode:setPositionY(alignY1)
                itemNodeList[#itemNodeList + 1] = {node = itemNode, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)}
            else
                itemNodeList[#itemNodeList + 1] = {node = itemNode, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)}
            end
        end
        itemCount1 = itemCount1 + 1
    end
    if gemNum > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Gem", gemNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD)
        if itemNode then
            parentNode:addChild(itemNode)
            if itemNum > 5 then
                itemNode:setPositionY(alignY1)
                itemNodeList[#itemNodeList + 1] = {node = itemNode, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)}
            else
                itemNodeList[#itemNodeList + 1] = {node = itemNode, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)}
            end
        end
        self.m_hasGem = true
        itemCount1 = itemCount1 + 1
    end
    if items and #items > 0 then
        for i = 1, #items do
            local itemData = items[i]
            if itemData.p_type == "Buff" then
                itemData.p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}
            elseif itemData.p_type == "Package" then
                itemData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_ADD}})
            end
            local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD)
            if itemNode then
                parentNode:addChild(itemNode)
                itemCount1 = itemCount1 + 1
                if itemCount1 > 5 then
                    if itemNum > 5 then
                        itemNode:setPositionY(alignY2)
                        itemNodeList2[#itemNodeList2 + 1] = {node = itemNode, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)}
                    else
                        itemNodeList2[#itemNodeList2 + 1] = {node = itemNode, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)}
                    end
                else
                    if itemNum > 5 then
                        itemNode:setPositionY(alignY1)
                        itemNodeList[#itemNodeList + 1] = {node = itemNode, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)}
                    else
                        itemNodeList[#itemNodeList + 1] = {node = itemNode, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)}
                    end
                end
            end
        end
    end
    if #itemNodeList > 0 then
        util_alignCenter(itemNodeList, nil, 900)
    end
    if #itemNodeList2 > 0 then
        util_alignCenter(itemNodeList2, nil, 900)
    end
    util_setCascadeOpacityEnabledRescursion(self, true)
end

--飞金币
function CSRewardUI:flyCoins(_flyCoinsEndCall)
    if not self.m_winRewardData then
        return
    end       
    local coins = self.m_winRewardData:getCoins() or 0
    local gems = self.m_winRewardData:getGems() or 0
    if coins == 0 and gems == 0 then
        if _flyCoinsEndCall ~= nil then
            _flyCoinsEndCall()
        end
        return
    end
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if cuyMgr then
        local startPos = self.m_btnCollect:getParent():convertToWorldSpace(cc.p(self.m_btnCollect:getPosition()))
        local flyList = {}
        if coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = coins, startPos = startPos})
        end
        if gems > 0 then
            table.insert(flyList, {cuyType = FlyType.Gem, addValue = gems, startPos = startPos})
        end
        cuyMgr:playFlyCurrency(flyList, _flyCoinsEndCall)
    end
end

-- 检测掉卡
function CSRewardUI:triggerDropCrads()
    local cardSource = self:getCardSource()
    if CardSysManager:needDropCards(cardSource) == true then
        -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                self:triggerDropFuncNext()
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards(cardSource, nil)
    else
        self:triggerDropFuncNext()
    end
end

-- 检测掉落猫粮
function CSRewardUI:triggerCatFoodView()
    local catManager = G_GetMgr(ACTIVITY_REF.DeluxeClubCat)
    catManager:popCatFoodRewardPanel(
        self.m_catFoodList,
        function()
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end
        end
    )
end

-- 检测掉落 合成福袋
function CSRewardUI:triggerPropsBagView()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:popMergePropsBagRewardPanel(
        self.m_propsBagist,
        function()
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end
        end
    )
end

-- 检测高倍场体验卡
function CSRewardUI:triggerDeluxeCard()
    gLobalNoticManager:postNotification(
        ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM,
        function()
            if not tolua.isnull(self) then
                self:triggerDropFuncNext()
            end
        end
    )
end

function CSRewardUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CSRewardUI:canClick()
    if self.m_isFlyingIcons then
        return false
    end
    if self.m_requesting then
        return false
    end
    if self:isShowing() then
        return false
    end
    if self:isHiding() then
        return false
    end
    if self.m_closed then
        return false
    end
    if self.m_logicTriggering then
        return false
    end
    return true
end

function CSRewardUI:onClickMask()
    if not self:canClick() then
        return
    end
    self:onClickCollect()
end

function CSRewardUI:onClickCollect()
    self.m_btnCollect:setTouchEnabled(false)
    self.m_requesting = true
    G_GetMgr(G_REF.CardSeeker):requestCollectReward()
end

function CSRewardUI:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "btn_collect" then
        self:onClickCollect()
    elseif name == "btn_close" then
        -- 中途离开工程才有关闭按钮
        if self.m_closed then
            return
        end
        self.m_closed = true
        self:closeUI(
            function()
                if self.m_over then
                    self.m_over()
                end
            end
        )
    end
end

function CSRewardUI:registerListener()
    CSRewardUI.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self.m_requesting = false
            self.m_btnCollect:setTouchEnabled(true)
            if params and params.isSuc then
                -- if self.m_hasGem == true then
                --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
                -- end
                self:flyCoins(
                    function()
                        if not tolua.isnull(self) then
                            self.m_logicTriggering = true
                            self:triggerDropFuncNext()
                        end
                    end
                )
            end
        end,
        ViewEventType.CARD_SEEKER_REQUEST_COLLECT
    )
end

return CSRewardUI
