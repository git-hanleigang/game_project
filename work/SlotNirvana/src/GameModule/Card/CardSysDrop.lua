--[[
    集卡系统 卡牌掉落
    掉落流程记录：购买掉落卡包时 先弹luckystamp，之后再走掉落的流程是最好的处理方式
    dropData.step
--]]
local CardSysDrop = class("CardSysDrop")
-- ctor
function CardSysDrop:ctor()
    self:reset()
    self:initData()
end

-- do something reset --
function CardSysDrop:reset()
    -- 掉落数据  --
    self.m_dropData = nil
    -- 当前展示的掉落来源
    self.m_curDropSource = nil
    -- 当前单个掉落卡包信息
    self.m_curSingleDropInfo = nil
    -- 掉落步骤
    self.m_DropStepIndex = 0
    -- 回调函数
    self.m_CallFunAfterDrop = nil
    -- 是否挂起流程
    self.m_isHangUp = false

    -- 使用气泡的source
    self.m_useBubbleSouces = {
        ["Random Spin"] = true,
        -- ["Level Up"] = true,
        -- ["New Player"] = true,
        -- ["New Season"] = true,
        ["Tornado Featured Game"] = true, -- "Link Featured Game"
        ["Power Jar"] = true
    }

    -- 开关
    self.m_isDropViewV2On = true
    -- 使用带章节的掉落界面的掉落类型
    self.m_useDropViewV2 = {
        [CardSysConfigs.CardDropType.normal] = true,
        [CardSysConfigs.CardDropType.link] = true,
        [CardSysConfigs.CardDropType.golden] = true,
        [CardSysConfigs.CardDropType.merge] = true,
    }
end

-- init --
function CardSysDrop:initData(dropData)
    -- 掉落数据  --
    self:setDropData(dropData)
end

-- 设置挂起
function CardSysDrop:setHangUp(isEnabled)
    self.m_isHangUp = isEnabled
end

function CardSysDrop:isHangUp()
    return self.m_isHangUp
end

function CardSysDrop:isUseBubble(_source)
    return self.m_useBubbleSouces[_source]
end

-- 卡片掉落集合信息
function CardSysDrop:setDropData(data)
    self.m_dropData = data
end

-- 设置当前展示的掉落来源
function CardSysDrop:setDropSource(dropSource)
    self.m_curDropSource = dropSource
end

-- 是否有掉落来源
function CardSysDrop:isHasDropSource(dropSource)
    if self.m_dropData then
        return self.m_dropData:hasDropSource(dropSource)
    else
        return false
    end
end

-- 当前单个卡包掉落信息
function CardSysDrop:setCurSingleDropInfo(dropInfo)
    self.m_curSingleDropInfo = dropInfo

    --
    self.m_DropStepIndex = 0
    self.m_isHasNadoCard = false
    self.m_isHasWildCard = false
    self.m_isHasStatueCard = false
    self.m_isOpenNewRound = false
end

-- 一组一组掉落 --
function CardSysDrop:setCallFunAfterDrop(callFun)
    self.m_CallFunAfterDrop = callFun
end

function CardSysDrop:getCallFunAfterDrop()
    return self.m_CallFunAfterDrop
end

function CardSysDrop:clearCallfunc()
    self.m_CallFunAfterDrop = nil
end

function CardSysDrop:doDropCallback()
    if self.m_CallFunAfterDrop ~= nil then
        local callback = self.m_CallFunAfterDrop
        -- self.m_CallFunAfterDrop()
        self:clearCallfunc()
        callback()
    end
end

-- 掉落流程是否需要重新走一遍
function CardSysDrop:isStepNeedLoop()
    if self.m_DropStepIndex == 4 then -- 当执行到第4步时挂起，再被解挂时要重新从该步走流程，因为第4步可能有多个奖励同时触发
        return true
    end
    return false
end

function CardSysDrop:checkStepLoop()
    if self:isStepNeedLoop() then
        self.m_DropStepIndex = self.m_DropStepIndex - 1
    end
end

-- 每组掉落流程 --
-- Step1 打开掉落面板 开卡包 展示卡等
-- Step2 打开link卡收集进度
-- ... 有未展示的掉卡，跳转执行Step1
-- Step3 打开章节收集成功面板
-- ... Step3 奖励有开卡，跳转执行Step1
-- Step4 打开赛季收集成功面板
-- ... Step4 奖励有开卡，跳转执行Step1

-- Step1
function CardSysDrop:createDropCardView(tDropInfo)
    print("CardSysDrop:createDropCardView start")
    -- Step1 打开掉落面板 开卡包 展示卡等--
    local cardStoreData = G_GetMgr(G_REF.CardStore):getRunningData()
    -- 缓存记录一下掉落界面使用的章节进度数据
    CardSysRuntimeMgr:cacheClanCollects()
    -- 如果掉落列表中， 有wild或者link，需要向服务器重新申请下数据 --
    if #tDropInfo.cards > 0 then
        local isNeedNet = false
        local wildType = nil
        local isSendNoviceOver = false
        local addNadoGames = 0
        for i = 1, #tDropInfo.cards do
            local cardData = tDropInfo.cards[i]
            local cardType = cardData.type
            if cardType == CardSysConfigs.CardType.link then
                self.m_isHasNadoCard = true

                -- card nadoloop todo 掉落时次数需要验证，因为有合并掉落
                addNadoGames = addNadoGames + (cardData.nadoCount * cardData.count) 

                local nadoGame = CardSysRuntimeMgr:getLinkGameData()
                if nadoGame then
                    nadoGame.nadoGames = tDropInfo.nadoGames
                end
                isNeedNet = true
            end

            -- 改变客户端缓存数据
            if cardData.firstDrop == true then
                local clanCollect = CardSysRuntimeMgr:getClanCollectByClanId(cardData.clanId)
                if clanCollect then
                    local cur = clanCollect.cur
                    CardSysRuntimeMgr:setClanCollects(cardData.clanId, cur + 1)
                    if not tDropInfo.clanCollects then
                        tDropInfo.clanCollects = {}
                    end
                    tDropInfo.clanCollects[cardData.clanId] = (tDropInfo.clanCollects[cardData.clanId] or 0) + 1
                    print("CardSysDrop clanCollects ", cardData.clanId, cur, tDropInfo.clanCollects[cardData.clanId])
                end
            end

            -- 多余卡转换成集卡商城积分
            if cardStoreData then
                if CardSysRuntimeMgr:isCardNormalPoint(cardData) then
                    local normalPoint = cardStoreData:getNormalChipPoints()
                    if normalPoint ~= nil then
                        cardStoreData:setNormalChipPoints(normalPoint + cardData.greenPoint)
                    end
                end
                if CardSysRuntimeMgr:isCardGoldPoint(cardData) then
                    local goldenPoint = cardStoreData:getGoldenChipPoints()
                    if goldenPoint ~= nil then
                        cardStoreData:setGoldenChipPoints(goldenPoint + cardData.goldPoint)
                    end
                end
            end

            if cardType == CardSysConfigs.CardType.wild then
                self.m_isHasWildCard = true
                isNeedNet = true
                if tDropInfo.type == CardSysConfigs.CardDropType.wild then
                    wildType = CardSysConfigs.CardType.wild
                elseif tDropInfo.type == CardSysConfigs.CardDropType.wild_normal then
                    wildType = CardSysConfigs.CardType.wild_normal
                elseif tDropInfo.type == CardSysConfigs.CardDropType.wild_link then
                    wildType = CardSysConfigs.CardType.wild_link
                elseif tDropInfo.type == CardSysConfigs.CardDropType.wild_golden then
                    wildType = CardSysConfigs.CardType.wild_golden
                elseif tDropInfo.type == CardSysConfigs.CardDropType.wild_obsidian then
                    wildType = CardSysConfigs.CardType.wild_obsidian
                elseif tDropInfo.type == CardSysConfigs.CardType.wild_magic then
                    wildType = CardSysConfigs.CardType.wild_magic
                elseif tDropInfo.type == CardSysConfigs.CardType.wild_magic_red then
                    wildType = CardSysConfigs.CardType.wild_magic_red
                elseif tDropInfo.type == CardSysConfigs.CardType.wild_magic_purple then
                    wildType = CardSysConfigs.CardType.wild_magic_purple
                end
            end
            if CardSysRuntimeMgr:isStatueCard(cardType) then
                self.m_isHasStatueCard = true
                isNeedNet = true
            end
            if CardSysRuntimeMgr:isMagicCard(cardType) then
                isNeedNet = true
            end
            if CardSysRuntimeMgr:isQuestMagicCard(cardType) then
                isNeedNet = true
            end            
            if CardSysRuntimeMgr:isObsidianCard(cardType) then
                isNeedNet = true
            end
        end

        -- 新手期集卡开启 活动
        if G_GetMgr(ACTIVITY_REF.CardOpenNewUser):isCanShowLobbyLayer() then
            isNeedNet = true
        end

        -- 改变客户端缓存临时数据
        if addNadoGames > 0 then
            local left = CardSysRuntimeMgr:getNadoGameLeftCount()
            if left == nil then
                local initLefts = tDropInfo and tDropInfo.nadoGames or 0
                CardSysRuntimeMgr:setNadoGameLeftCount(initLefts)
            else
                CardSysRuntimeMgr:setNadoGameLeftCount(left + addNadoGames)
            end
        end

        if tDropInfo and tDropInfo.albumReward ~= nil and tDropInfo.albumReward.id ~= nil and tDropInfo.albumReward.id ~= "" then
            -- 只有当前赛季完成才发消息
            if tonumber(tDropInfo.albumReward.id) == tonumber(CardSysRuntimeMgr:getCurAlbumID()) then
                
                -- 下一轮次开启，更改本地缓存数据
                if tDropInfo.nextRound ~= nil and tDropInfo.nextRound > 0 then
                    self.m_isOpenNewRound = true
                    isNeedNet = true
                    CardSysRuntimeMgr:setCurAlbumRound(tDropInfo.nextRound)
                end
                
                -- 补丁：最后一轮完成，轮次没有更改，但是领了轮次奖励，得刷新标题弹框成完成状态
                local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
                if albumData and albumData:isGetAllCards() then
                    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_ALBUM_ROUND_CHANGE, {isMaxRound = true})
                end

                -- cardnewuser todo 新手期集卡全部集齐， 新手期结束
                if tonumber(tDropInfo.albumReward.id) == tonumber(CardNoviceCfg.ALBUMID) then
                    isSendNoviceOver = true
                end
            end
        end

        -- 是否使用展示章节的掉落界面（V2版本
        if self.m_isDropViewV2On and self.m_useDropViewV2[tDropInfo.type] then
            tDropInfo.isDropShowClan = true
            -- 使用新版界面，界面关闭时同步缓存数据
        else
            if self.m_isOpenNewRound then                   -- 将整个if后挪，如果跨轮次了，就将当前卡册的10 置为 0，2024.01赛季修改显示bug
                CardSysRuntimeMgr:clearClanCollectsCur()
            end
            -- 如果使用的是旧版界面，直接同步缓存数据
            CardSysRuntimeMgr:cacheClanCollects()
        end

        if self:isUseBubble(tDropInfo.source) then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHIPPIGGY_TOPNODE_EFFECT)
            CardSysManager:getDropMgr():showDropBubble(tDropInfo.cards)
            -- 弹气泡，同时弹出后续奖励弹框 --
            if self.m_isHasNadoCard then
                -- 需要进入Nado机
                CardSysManager:getLinkMgr():setNeedEnterNado(false)
                self:doNextDropView()
            elseif self.m_isHasWildCard then
                local callback = function()
                    CardSysManager:getDropMgr():doNextDropView()
                end

                if CardSysManager:isDownLoadCardRes() then
                    -- 掉落界面，wild卡掉落时关闭
                    if wildType == CardSysConfigs.CardType.wild_obsidian then
                        -- 黑耀卡 走 黑耀卡wild兑换逻辑
                        G_GetMgr(G_REF.ObsidianCard):doDropWildLogic(callback)
                    elseif wildType == CardSysConfigs.CardType.wild_magic or wildType == CardSysConfigs.CardType.wild_magic_red
                    or wildType == CardSysConfigs.CardType.wild_magic_purple then
                         -- Magic卡 走 Magic卡wild兑换逻辑
                         G_GetMgr(G_REF.CardSpecialClan):doDropWildLogic(wildType, callback)
                    else
                        -- 普通卡 
                        CardSysManager:showWildExchangeView(wildType, callback)
                    end
                end
                
            else
                -- 点关闭按钮或者点击collect按钮
                self:doNextDropView()
            end
        else
            -- 弹框 --
            self:showDropUI(tDropInfo)
        end

        if isSendNoviceOver then
            -- 新手期赛季结束逻辑，必须要拿到cardinfo数据后再发送请求
            CardSysManager:requestCardCollectionSysInfo(function()
                gLobalNoticManager:postNotification(ViewEventType.CARD_ONLINE_ALBUM_OVER)
            end)            
        else
            -- 掉落特殊卡，或者在集卡系统内部， 重新拉一下最新数据
            if isNeedNet or CardSysRuntimeMgr:isInCard() then
                -- 请求一些基本数据
                CardSysManager:requestCardCollectionSysInfo()
                self:sendCardsAlbumRequest()
            end
        end
    end
end

function CardSysDrop:sendCardsAlbumRequest()
    -- 请求小游戏产生的卡牌数据，更新章节数据
    local yearID = CardSysRuntimeMgr:getCurrentYear()
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    if yearID == nil then
        util_sendToSplunkMsg("sendCardsAlbumRequest", "!!! Error! can not get yearId")
        return 
    end
    if albumId == nil then
        util_sendToSplunkMsg("sendCardsAlbumRequest", "!!! Error! can not get albumId")
        return
    end
    local tExtraInfo = {["year"] = yearID, ["albumId"] = albumId}
    CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo)
end

-- 进入LINK玩法
function CardSysDrop:enterToLink()
    local tDropInfo = self.m_curSingleDropInfo
    if not tDropInfo then
        return false
    end

    -- 查找是否有LINK卡
    -- if tDropInfo.type == "LINK" then
    if self.m_isHasNadoCard then
        if tDropInfo.collectNado and tDropInfo.collectNado.currentCards ~= nil and tDropInfo.collectNado.currentCards > 0 then

            local dropAlbumId = tDropInfo:getDropAlbumId()
            local dropRound = tDropInfo:getRound()
            
            local newNadoCardCount = 0
            for i = 1, #tDropInfo.cards do
                local cardData = tDropInfo.cards[i]
                if cardData.type == CardSysConfigs.CardType.link and cardData.firstDrop == true then
                    newNadoCardCount = newNadoCardCount + 1
                end
            end

            -- 客户端计算缓存的nado挑战进度
            local curNadoNum = 0
            if not CardSysManager:hasLoginCardSys() then
                curNadoNum = tDropInfo.collectNado.currentCards - newNadoCardCount
            else
                curNadoNum = CardSysRuntimeMgr:getNadoCollectCount(dropAlbumId, dropRound)
            end
            local tarNadoNum = curNadoNum + newNadoCardCount
            CardSysRuntimeMgr:setNadoCollectCount(tarNadoNum, dropAlbumId, dropRound)

            -- 客户端计算缓存数据，增加nado挑战赠送的nado次数
            if newNadoCardCount > 0 then
                local totalNado = CardSysRuntimeMgr:getNadoCollectCount(dropAlbumId, dropRound)
                local newIndexs = tDropInfo.collectNado:getCardsIndexBetweenNum(totalNado - newNadoCardCount, totalNado)
                if newIndexs and #newIndexs > 0 then
                    local addNadoGames = 0
                    for i=1,#newIndexs do
                        addNadoGames = addNadoGames + tDropInfo.collectNado:getGamesByIndex(newIndexs[i])
                    end
                    if addNadoGames > 0 then
                        local left = CardSysRuntimeMgr:getNadoGameLeftCount()                      
                        CardSysRuntimeMgr:setNadoGameLeftCount(left + addNadoGames)
                    end
                end
            end

            local _params = {
                data = tDropInfo.collectNado,
                isDrop = true,
                srcNum = curNadoNum,
                tarNum = tarNadoNum
            }
            -- dump(tDropInfo.collectNado, "--- tDropInfo.collectNado ---", 5)
            -- local dropSeason = CardSysManager:getDropMgr():checkDropSeason(tDropInfo.cards)
            local logic = CardSysRuntimeMgr:getSeasonLogic(dropAlbumId)
            CardSysManager:getLinkMgr():showCardLinkProgressComplete(_params, logic)
            return true
        else
            if CardSysManager:getLinkMgr():isNeedEnterNado() and (tDropInfo.nadoGames or 0) > 0 then
                -- 防止嵌套打开界面卡死
                if not CardSysManager:getLinkMgr():hasNadoMachineUI() then
                    -- 要进入Nado机，展示Nado机
                    CardSysManager:showNadoMachine("drop")
                    CardSysManager:setNadoMachineOverCall(
                        function()
                            CardSysManager:getDropMgr():doNextDropView()
                        end
                    )
                    CardSysManager:getLinkMgr():setNeedEnterNado(false)
                    return true
                end
            end
        end
    end
    return false
end

-- 打开面板逻辑 --
function CardSysDrop:showDropUI(tDropInfo)
    -- local dropSeason = CardSysManager:getDropMgr():checkDropSeason(tDropInfo.cards)
    self.m_dropView = nil
    local dropAlbumId = tDropInfo:getDropAlbumId()
    local _logic = CardSysRuntimeMgr:getSeasonLogic(dropAlbumId)
    if _logic then
        if tDropInfo.isDropShowClan then
            self.m_dropView = _logic:createDropCardViewV2(tDropInfo)
        else
            self.m_dropView = _logic:createDropCardView(tDropInfo)
        end
    else
        -- wild卡没有albumid都属于新赛季
        -- self.m_dropView = util_createView("GameModule.Card.season201903.CardDropViewNew", tDropInfo)
        self.m_dropView = util_createView("GameModule.Card.commonViews.CardDrop.CardDropViewNew", tDropInfo)
    end
    if self.m_dropView then
        gLobalViewManager:showUI(self.m_dropView, ViewZorder.ZORDER_UI)
    end
end

-- 关闭面板逻辑 --
function CardSysDrop:closeDropView(closeType, dropLinkClanId, wildType)
    -- 处理接下来面板 --
    if closeType == 1 then
        -- 点关闭按钮或者点击collect按钮
        self:doNextDropView()
    elseif closeType == 2 then
        -- 需要进入Nado机
        CardSysManager:getLinkMgr():setNeedEnterNado(true)
        self:doNextDropView()
    elseif closeType == 3 then
        -- 掉落界面，wild卡掉落时关闭
        -- 第二个参数：wild兑换界面直接关闭时，需要调用下一个wild掉落
        local callback = function()
            CardSysManager:getDropMgr():doNextDropView()
        end

        if CardSysManager:isDownLoadCardRes() then
            -- 掉落界面，wild卡掉落时关闭
            if wildType == CardSysConfigs.CardType.wild_obsidian then
                -- 黑耀卡 走 黑耀卡wild兑换逻辑
                G_GetMgr(G_REF.ObsidianCard):doDropWildLogic(callback)
            elseif wildType == CardSysConfigs.CardType.wild_magic or wildType == CardSysConfigs.CardType.wild_magic_red
            or wildType == CardSysConfigs.CardType.wild_magic_purple then
                 -- Magic卡 走 Magic卡wild兑换逻辑
                 G_GetMgr(G_REF.CardSpecialClan):doDropWildLogic(wildType, callback)
            else
                -- 普通卡 
                CardSysManager:showWildExchangeView(wildType, callback)
            end
        else
            self:doDropFinish()
        end
        
    end
end

-- 处理多个章节一次掉落同时完成的情况
-- function CardSysDrop:doNextClanComplete()
--     local tDropInfo = self.m_dropData
--     self:showCardClanComplete(tDropInfo)
-- end

-- 掉落步骤是否完成
-- function CardSysDrop:isDropStepComplete()
--     return self.m_DropStepIndex > 5
-- end

-- 处理下一次掉落或收集全弹版 --
-- TODO: 问题：如果有多次掉落 A1,A2，其中A1掉落触发了其他的掉落B1，那么现在的顺序是，A1B1A2
function CardSysDrop:doNextDropView()
    if self:isHangUp() then
        -- 挂起则返回
        return
    end

    self.m_DropStepIndex = self.m_DropStepIndex + 1

    local tDropInfo = self.m_curSingleDropInfo

    --没有资源跳过除了掉卡之外的步骤
    if self.m_DropStepIndex > 1 then
        if not CardSysManager:isDownLoadCardRes() then
            self:doDropFinish()
            return
        end
    end

    if self.m_DropStepIndex == 1 then
        -- 显示掉落面板
        self:createDropCardView(tDropInfo)
    elseif self.m_DropStepIndex == 2 then
        -- 进入link玩法
        if not self:enterToLink() then
            self:doNextDropView()
        end
    elseif self.m_DropStepIndex == 3 then
        -- 掉落展示结束
        self:curDropShowOver()
    elseif self.m_DropStepIndex == 4 then
        -- 检查是否显示收集奖励
        self:checkCollectReward()
    else
        self:doLoopDropCard()
    end
end

-- 当前掉落展示结束
function CardSysDrop:curDropShowOver()
    if self.m_isHasStatueCard then
        local cardInfo = self.m_curSingleDropInfo.cards[1]
        -- 判断小游戏界面是否显示
        local view = gLobalViewManager:getViewByName("StatueMainLayer")
        if view then
            self:setHangUp(true)
            -- 添加小游戏卡
            view:addCard(
                cardInfo,
                function()
                    -- 检查是否显示章节完成
                    -- self:checkShowClanReward()
                    -- 不升级回调
                    self:setHangUp(false)
                    self:doNextDropView()
                end
            )
            return
        end
    end
    self:doNextDropView()
end

-- 展示收集奖励
function CardSysDrop:checkCollectReward()
    local isTrue = CardSysManager:getDropMgr():hasHangUpDrop()

    -- local clanReward = self.m_curSingleDropInfo.clanReward
    -- if (not isTrue) and ((clanReward and #clanReward > 0) or (CardSysManager:getDropMgr():isHasCollectReward())) then
    if (not isTrue) and CardSysManager:getDropMgr():isHasCollectReward() then
        -- 没有挂起的掉落，立即展示奖励
        CardSysManager:getDropMgr():disposeCollectCompleteReward()
    else
        self:doNextDropView()
    end
end

-- 循环展示卡包
function CardSysDrop:doLoopDropCard()
    if not self.m_dropData then
        return false
    end

    -- local _dropInfo = self.m_dropData:getNextDropInfo()
    local _dropInfo = self.m_dropData:getDropInfoBySource(self.m_curDropSource)

    if _dropInfo then
        -- 解析掉落中是否有奖励
        CardSysManager:getDropMgr():parseCardDropReward(_dropInfo)
        -- 解析掉落中是否开启下一轮次
        CardSysManager:getDropMgr():parseCardNextRound(_dropInfo)

        self:setCurSingleDropInfo(_dropInfo)

        self:doNextDropView()
        return true
    else
        self:doDropFinish()
        -- 这种情况在上边已经return了
        return false
    end
end

-- 掉卡流程完成
function CardSysDrop:doDropFinish()
    if self.m_dropData:isEmpty() then
        -- 没有卡了，当前掉落流程完成了
        CardSysManager:getDropMgr():doCurDropCompleted()
    else
        --比赛聚合 获得金卡和Nado 卡增加分数
        G_GetMgr(ACTIVITY_REF.BattleMatch):doCheckShowActivityLayer(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CARD_SYS_OVER)
            end,
            false
        )
    end

    -- 如果有回调
    self:doDropCallback()
end

return CardSysDrop
