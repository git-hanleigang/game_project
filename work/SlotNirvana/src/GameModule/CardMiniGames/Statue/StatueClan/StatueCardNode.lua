local StatueCardNode = class("StatueCardNode", BaseView)
function StatueCardNode:initUI(_statueType)
    self.m_statueType = _statueType
    StatueCardNode.super.initUI(self)

    self:initData()
    self:initView()
end

function StatueCardNode:getCsbName()
    return "CardRes/season202102/Statue/Statue_chips.csb"
end

function StatueCardNode:initCsbNodes()
    self.m_nodeChips = {}
    for i = 1, 5 do
        local nodeChip = self:findChild("node_chip" .. i)
        table.insert(self.m_nodeChips, nodeChip)
    end
end

-- 筹码特效
function StatueCardNode:getChipEffectLuaName()
    return "GameModule.CardMiniGames.Statue.StatueClan.StatueCardEffectNode"
end

function StatueCardNode:initData()
    self.m_chipList = {}
    self.m_chipSGList = {}
    _, clanData = CardSysManager:getStatueMgr():getRunData():getCurrentStatueClan(self.m_statueType)
    self.m_cacheClanDataList = clone(clanData)

    self.m_isNewCard = false
end

function StatueCardNode:initView()
    if self.m_cacheClanDataList and self.m_cacheClanDataList.cards then
        for i = 1, #self.m_nodeChips do
            local cardData = self.m_cacheClanDataList.cards[i]
            local chipUI = self:createStatueChip(cardData)
            self.m_nodeChips[i]:addChild(chipUI)
            self.m_chipList[i] = chipUI

            local chipSG = util_createView(self:getChipEffectLuaName())
            chipSG:setVisible(cardData and cardData.count > 0 or false)
            self.m_nodeChips[i]:addChild(chipSG)
            chipSG:playIdle()
            self.m_chipSGList[i] = chipSG
        end
    end
end

function StatueCardNode:updateChips()
    local _, clanData = CardSysManager:getStatueMgr():getRunData():getCurrentStatueClan(self.m_statueType)
    if clanData and clanData.cards then
        local newCards = {}
        for i = 1, 5 do
            local newCardData = clanData.cards[i]
            local cacheCardData = self.m_cacheClanDataList.cards[i]
            if newCardData and cacheCardData then
                self.m_chipList[i]:reloadUI(newCardData, nil, nil, true, true, true)
                if newCardData.count > 0 then
                    self.m_chipSGList[i]:setVisible(true)
                    -- 播放点亮动画
                    -- 升级后卡牌id会变化
                    if tonumber(newCardData.cardId) == tonumber(cacheCardData.cardId) then
                        if cacheCardData.count == 0 then
                            newCards[#newCards + 1] = i
                        end
                    else
                        newCards[#newCards + 1] = i
                    end
                else
                    self.m_chipSGList[i]:setVisible(false)
                end
            end
        end
        if #newCards > 0 then
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueNewCard)
            for i = 1, #newCards do
                local index = newCards[i]
                self.m_chipSGList[index]:playLight(
                    function()
                        self.m_chipSGList[index]:playIdle()
                    end,
                    i,
                    i
                )
            end
        end
    end
    self.m_cacheClanDataList = clone(clanData)
end

-- 初始化新等级的卡
function StatueCardNode:initNewLeveCards()
    local _, clanData = CardSysManager:getStatueMgr():getRunData():getCurrentStatueClan(self.m_statueType)
    if clanData and clanData.cards then
        self.m_cacheClanDataList = clone(clanData)
        for i = 1, #self.m_cacheClanDataList.cards do
            local cacheCardData = self.m_cacheClanDataList.cards[i]
            if cacheCardData.type == CardSysConfigs.CardType.statue_red and clanData.getReward == true then
                -- 神像卡章节的最大等级，有坑，小心策划更改神像卡章节的等级数量，目前最大等级是红色
                self.m_chipList[i]:reloadUI(cacheCardData, nil, nil, true, true, false)
            else                
                cacheCardData.count = 0
                self.m_chipList[i]:reloadUI(cacheCardData, nil, nil, true, true, true)
                self.m_chipSGList[i]:setVisible(false)
            end
        end
    end
end

-- 添加小游戏卡
function StatueCardNode:addCard(cardInfo, callback)
    local callFunc = function()
        if callback then
            callback()
        end
    end

    if not cardInfo then
        callFunc()
        return
    end
    
    -- 更新数值
    local newCards = {}
    for i = 1, 5 do
        local cacheCardData = self.m_cacheClanDataList.cards[i]
        -- 播放点亮动画
        -- 升级后卡牌id会变化
        if tonumber(cardInfo.cardId) == tonumber(cacheCardData.cardId) then
            if cacheCardData.count == 0 then
                newCards[#newCards + 1] = i
                cacheCardData.count = 1
            else
                cacheCardData.count = cacheCardData.count + cardInfo.count
            end
            -- 刷新神像卡状态
            self.m_chipList[i]:reloadUI(cacheCardData, nil, nil, true, true, true)
        end
    end
    -- 播放升级动画
    local _count = #newCards
    if _count > 0 then
        self.m_isNewCard = true
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueNewCard)
        local complete = 0
        for i = 1, _count do
            local index = newCards[i]
            -- 播放特效
            self.m_chipSGList[index]:setVisible(true)
            self.m_chipSGList[index]:playLight(
                function()
                    self.m_chipSGList[index]:playIdle()

                    complete = complete + 1
                    if complete == _count then
                        -- 高亮显示小游戏卡完成
                        callFunc()
                    end
                end,
                i,
                i
            )
        end
    else
        callFunc()
    end
end

function StatueCardNode:createStatueChip(_cardData)
    local spcialChip = util_createView("GameModule.Card.season201903.MiniChipUnit")
    spcialChip:playIdle()
    spcialChip:reloadUI(_cardData, nil, nil, true, true, true)
    spcialChip:setScale(0.3)
    spcialChip:updateTouchBtn(true, true, true)
    return spcialChip
end

-- 处理获取神像卡逻辑
-- 当小游戏中集满5张卡时,回到雕塑界面
-- 升级流程：
-- 对应筹码册播放集满触发动效,筹码放出光芒
-- 播放雕塑升级动效,同时播放对应buff解锁动效
-- 弹出集齐弹板(复用普通卡册集齐弹板或新作)
function StatueCardNode:statueLevelUpStart(callback)
    self.m_isNewCard = false
    CardSysManager:getStatueMgr():setLevelUping(true)

    local _count = #self.m_chipSGList

    local levelupPeopleStart = function()
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_STATUE_LEVELUP_ANIMA_PEOPLE, {statueType = self.m_statueType})
    end

    -- 升级发光特效结束
    local levelupEffectOver = function()
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_STATUE_LEVELUP_LIZI_FLY2PEOPLE, {statueType = self.m_statueType})
        local delayFrame = 5 / 30
        local intervalFrame = 5 / 30
        for i = 1, _count do
            performWithDelay(
                self.m_chipSGList[i],
                function()
                    if i == 1 then
                        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueFly2People)
                    end
                    self.m_chipSGList[i]:playLevelUpOver(levelupPeopleStart, i, _count)
                end,
                delayFrame + intervalFrame * (i - 1)
            )
        end
    end

    -- 点亮特效结束
    local lightEffectOver = function()
        -- 升级发光特效
        for i = 1, _count do
            self.m_chipSGList[i]:playLevelUp(levelupEffectOver, i, _count)
        end
    end

    -- local changeIcons = {}
    -- for i = 1, 5 do
    --     if self.m_cacheClanDataList and self.m_cacheClanDataList.cards then
    --         if self.m_cacheClanDataList.cards[i].count == 0 then
    --             changeIcons[#changeIcons + 1] = i
    --             self.m_chipList[i]:reloadUI(self.m_cacheClanDataList.cards[i], true, nil, true, true, true)
    --         end
    --     end
    -- end

    -- 点亮特效
    -- if #changeIcons > 0 then
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatueNewCard)
    for i = 1, _count do
        self.m_chipSGList[i]:setVisible(true)
        self.m_chipSGList[i]:playLight(lightEffectOver, i, _count)
    end
    -- end
end

function StatueCardNode:statueLevelUpOver()
    -- self:updateChips()
    self:initNewLeveCards()
    -- for i = 1, #self.m_chipSGList do
    --     self.m_chipSGList[i]:playIdle()
    -- end
    -- 清数据
    CardSysManager:getDropMgr():clearStatueCompleteList()
    CardSysManager:getStatueMgr():setLevelUping(false)

    CardSysManager:getDropMgr():setCurDropHangUp(false)
    CardSysManager:getDropMgr():doNextDropView()
end

function StatueCardNode:onEnter()
    StatueCardNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.statueType == self.m_statueType then
                self:statueLevelUpOver()
            end
        end,
        CardSysConfigs.ViewEventType.CARD_STATUE_LEVELUP_ANIMA_OVER
    )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         -- if self.m_statueType == 1 then
    --         --     self:checkLevelUpAction(CardSysConfigs.CardClanType.statue_left)
    --         -- elseif self.m_statueType == 2 then
    --         --     self:checkLevelUpAction(CardSysConfigs.CardClanType.statue_right)
    --         -- end
    --         self:updateChips()
    --     end,
    --     ViewEventType.CARD_STATUE_DROP_CARD
    -- )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         if self.m_statueType == 1 then
    --             self:checkLevelUpAction(CardSysConfigs.CardClanType.statue_left)
    --         elseif self.m_statueType == 2 then
    --             self:checkLevelUpAction(CardSysConfigs.CardClanType.statue_right)
    --         end
    --     end,
    --     ViewEventType.CARD_STATUE_LEVELUP
    -- )
end

function StatueCardNode:checkLevelUpAction()
    -- local dropClanReward = CardSysManager:getDropMgr():getStatueCompleteList()
    -- if dropClanReward and #dropClanReward > 0 then
    --     local isLevelUp = false
    --     for i = 1, #dropClanReward do
    --         local clanRewardData = dropClanReward[i]
    --         if clanRewardData and clanRewardData.id then
    --             local clanData = CardSysRuntimeMgr:getClanDataByClanId(clanRewardData.id)
    --             if clanData and clanData.type == _clanType then
    --                 isLevelUp = true
    --                 self:statueLevelUpStart()
    --                 break
    --             end
    --         end
    --     end
    --     if isLevelUp == false then
    --         self:updateChips()
    --     end
    -- else
    --     self:updateChips()
    -- end

    local isLevelUp = false
    if self.m_isNewCard == true then
        local isGainedAll = true
        for i = 1, 5 do
            local cacheCardData = self.m_cacheClanDataList.cards[i]
            if cacheCardData.count == 0 then
                isGainedAll = false
                break
            end
        end
        if isGainedAll == true then
            isLevelUp = true
        end
    end
    return isLevelUp
end

-- function StatueCardNode:onExit()
--     StatueCardNode.super.onExit(self)
-- end

return StatueCardNode
