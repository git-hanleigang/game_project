--[[
    集卡系统 掉落系统管理
    掉落流程记录：购买掉落卡包时 先弹luckystamp，之后再走掉落的流程是最好的处理方式
    dropData.step

--]]

local CardSysDrop = require("GameModule.Card.CardSysDrop")
local CardSysDropData = require("GameModule.Card.CardSysDropData")
local CardSysDropManager = class("CardSysDropManager")
-- ctor
function CardSysDropManager:ctor()
    self:reset()
    self:initBaseData()
end

-- do something reset --
function CardSysDropManager:reset()
end

-- init --
function CardSysDropManager:initBaseData()
    -- 收集掉落数据  --
    self.m_dropDataList = {}
    -- 结算的奖励数据
    self.m_rewardList = {}
    -- 开启轮次数据
    self.m_roundList = {}

    -- 掉落逻辑队列
    self.m_dropLogicQueue = {}

    -- 当前掉落
    self.m_curDrop = nil

    self.m_statueCompleteList = {}

    self.m_dropBubbleUIs = {}
    self.m_dropBubbleIndex = 0
end

function CardSysDropManager:clearDropBubble()
    self.m_dropBubbleUIs = {}
    self.m_dropBubbleIndex = 0    
end

function CardSysDropManager:isHasSameRewardData(_id)
    if self.m_rewardList and #self.m_rewardList > 0 then
        for i = 1, #self.m_rewardList do
            if tonumber(self.m_rewardList[i].id) == tonumber(_id) then
                return true
            end
        end
    end
    return false
end

function CardSysDropManager:isHasSameData(_data)
    if self.m_rewardList and #self.m_rewardList > 0 then
        for i = 1, #self.m_rewardList do
            if tonumber(self.m_rewardList[i].id) == tonumber(_data.id) 
            and tonumber(self.m_rewardList[i].phaseChips) == tonumber(_data.phaseChips) then
                return true
            end
        end
    end
    return false
end

function CardSysDropManager:getStatueCompleteList()
    -- 同时升级两个神像
    if self.m_statueCompleteList and #self.m_statueCompleteList > 0 then
        local tData = clone(self.m_statueCompleteList)
        return tData
    end
    return
end

function CardSysDropManager:clearStatueCompleteList()
    self.m_statueCompleteList = {}
end

-- 分析掉落数据 --
function CardSysDropManager:parseDropDatas(tDatas)
    -- 解析掉卡列表
    local cardDropData = CardSysDropData:create()
    cardDropData:parseDropData(tDatas)
    if cardDropData:isHasDropData() then
        table.insert(self.m_dropDataList, cardDropData)
    else
        cardDropData = nil
    end
end

-- 解析章节掉落奖励
function CardSysDropManager:parseCardDropReward(dropInfo)
    if not dropInfo then
        return
    end
    -- 解析集齐章节奖励
    self:parseClanRewardData(dropInfo)
    -- 解析集齐magic所有章节奖励
    self:parseMagicAlbumRewardData(dropInfo)
    -- 解析集齐卡册奖励
    self:parseAlbumRewardData(dropInfo)
end

-- 解析轮次开启
function CardSysDropManager:parseCardNextRound(_dropInfo)
    if not _dropInfo then
        return
    end
    -- 轮次开启一定要有上一轮结束的数据
    local albumReward = _dropInfo.albumReward
    if not albumReward or not next(albumReward) then
        return
    end
    if albumReward.coins == 0 and albumReward.id == "" and #albumReward.rewards == 0 then
        return
    end
    -- 检查完成的赛季，如果不是当前赛季，下一轮次不开启
    if tonumber(albumReward.id) ~= tonumber(CardSysRuntimeMgr:getCurAlbumID()) then
        return
    end
    
    local openRound = _dropInfo.nextRound
    if openRound and openRound > 0 then -- 服务器0是第一轮，大于第一轮才计数
        table.insert(self.m_roundList, openRound + 1)
    end
end

-- 解析章节集齐奖励
function CardSysDropManager:parseClanRewardData(dropInfo)
    if not dropInfo then
        return
    end
    local clanReward = dropInfo.clanReward
    if not (clanReward and #clanReward > 0) then
        return
    end
    for i = 1, #clanReward do
        local clanType = clanReward[i]:getClanType() -- CARDTODO: 掉落数据的章节数据中添加 clanType 字段
        if CardSysRuntimeMgr:isStatueClan(clanType) then
            -- 解析特殊小游戏章节集齐奖励
            self:parseSpecialGameRewardData(dropInfo)
        elseif CardSysRuntimeMgr:isMagicClan(clanType) or CardSysRuntimeMgr:isQuestMagicClan(clanType) then
            -- 解析鲨鱼小游戏章节集齐奖励
            self:parseMagicClanRewardData(dropInfo)
        elseif CardSysRuntimeMgr:isObsidianClan(clanType) then
            -- 解析黑耀章节集齐奖励
            self:parseObsidianClanRewardData(dropInfo)
        else
            -- 解析集齐普通章节奖励
            self:parseNormalClanRewardData(dropInfo)
        end
    end
end

function CardSysDropManager:parseMagicAlbumRewardData(dropInfo)
    if not dropInfo then
        return
    end
    local albumMagicReward = dropInfo.albumMagicReward
    if not albumMagicReward or not next(albumMagicReward) then
        return
    end
    if albumMagicReward.coins == 0 and albumMagicReward.clanType == "" then
        return
    end
    -- quest magic大奖中的id是赛季id
    -- if self:isHasSameRewardData(albumMagicReward.id) then 
    --     return
    -- end
    local _season = dropInfo:getDropAlbumId()
    local _rewardInfo = clone(albumMagicReward)
    _rewardInfo.rewardType = "MAGIC_ALBUM"
    _rewardInfo.season = _season

    table.insert(self.m_rewardList, _rewardInfo)
end

-- 解析普通章节集齐奖励
function CardSysDropManager:parseNormalClanRewardData(dropInfo)
    local clanReward = dropInfo.clanReward
    if not clanReward or not next(clanReward) then
        return
    end
    -- local _season = self:checkDropSeason(dropInfo.cards)
    local _season = dropInfo:getDropAlbumId()
    -- dropInfo:getDropAlbumId()
    for i = 1, #clanReward do
        local clanRewardData = clanReward[i]
        if not self:isHasSameRewardData(clanRewardData.id) then
            local _rewardInfo = clone(clanRewardData)
            _rewardInfo.rewardType = "CLAN"
            _rewardInfo.season = _season
            table.insert(self.m_rewardList, _rewardInfo)
        end
    end
end

-- 解析卡册集齐奖励
function CardSysDropManager:parseAlbumRewardData(dropInfo)
    local albumReward = dropInfo.albumReward
    if not albumReward or not next(albumReward) then
        return
    end

    if albumReward.coins == 0 and albumReward.id == "" and #albumReward.rewards == 0 then
        return
    end

    if self:isHasSameRewardData(albumReward.id) then
        return
    end

    -- local _season = self:checkDropSeason(dropInfo.cards)
    local _season = dropInfo:getDropAlbumId()
    local _rewardInfo = clone(albumReward)
    _rewardInfo.rewardType = "ALBUM"
    _rewardInfo.season = _season

    table.insert(self.m_rewardList, _rewardInfo)
end

function CardSysDropManager:parseSpecialGameRewardData(dropInfo)
    -- local _season = self:checkDropSeason(dropInfo.cards)
    local _season = dropInfo:getDropAlbumId()
    local clanReward = dropInfo.clanReward
    if clanReward then
        for i = 1, #clanReward do
            if not self:isHasSameRewardData(clanReward[i].id) then
                local _rewardInfo = clone(clanReward[i])
                _rewardInfo.rewardType = "SPECIAL"
                _rewardInfo.season = _season
                table.insert(self.m_rewardList, _rewardInfo)
            end
        end
    end
end

function CardSysDropManager:parseMagicClanRewardData(dropInfo)
    -- local _season = self:checkDropSeason(dropInfo.cards)
    local _season = dropInfo:getDropAlbumId()
    local clanReward = dropInfo.clanReward
    if clanReward then
        for i = 1, #clanReward do
            if not self:isHasSameRewardData(clanReward[i].id) then
                local _rewardInfo = clone(clanReward[i])
                _rewardInfo.rewardType = "MAGIC_CLAN"
                _rewardInfo.season = _season
                table.insert(self.m_rewardList, _rewardInfo)
            end
        end
    end
end

function CardSysDropManager:parseObsidianClanRewardData(dropInfo)
    -- local _season = self:checkDropSeason(dropInfo.cards)
    local _season = dropInfo:getDropAlbumId()
    local clanReward = dropInfo.clanReward
    if clanReward then
        for i = 1, #clanReward do
            if not self:isHasSameData(clanReward[i]) then
                local _rewardInfo = clone(clanReward[i])
                _rewardInfo.rewardType = "OBSIDIAN_CLAN"
                _rewardInfo.season = _season
                table.insert(self.m_rewardList, _rewardInfo)
            end
        end
    end
end

-- dropSource: 服务器中存储的source（比较杂乱的文字）
-- 获取本地存储数据表中的详细配置
function CardSysDropManager:getDropSourceInfo(dropSource)
    local bigSource = string.upper(dropSource)
    local info = {
        source = dropSource, -- Quest奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM " .. bigSource .. "!"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM " .. bigSource .. "!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A NADO CHIP CASE FROM " .. bigSource .. "!"
        },
        goldenPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A GOLD CHIP FROM " .. bigSource .. "!"
        },
        statuePackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM " .. bigSource .. "!"
        },
        obsidianPackage = {
            title = "CONGRATS!",
            des = "YOU'VE RECEIVED A OBSIDIAN CHIP CASE FROM " .. bigSource .. "!"
        },
        mergePackage = {
            title = "CONGRATS!",
            des = "CHIPS CASE FROM " .. bigSource .. "!"
        }
    }
    self:checkSpecailDropSource(info)
    return info
end

function CardSysDropManager:checkSpecailDropSource(info)
    -- 商城购买，神像buff额外掉落
    if info.source == "Purchase Double Buff" then
        local _des = nil
        local extraChipBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_COINSHOP_CARD_PACKAGE_BONUS)
        local starupBuff = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_COINSHOP_CARD_STAR_BONUS)
        if extraChipBuff > 0 and starupBuff > 0 then -- 额外的升星卡包
            _des = "an extra starup chip case for your statue buff!"
        elseif starupBuff > 0 then -- 升星的卡包
            _des = "a starup chip case for your statue buff!"
        elseif extraChipBuff > 0 then -- 额外的卡包
            _des = "an extra chip case for your statue buff!"
        end
        if _des then
            info.single.des = string.upper(_des)
            info.wildCard.des = string.upper(_des)
            info.normalPackage.des = string.upper(_des)
            info.linkPackage.des = string.upper(_des)
            info.goldenPackage.des = string.upper(_des)
        end
    elseif info.source == "Lucky Challenge V2" then
        local des = string.upper("Diamond Challenge")
        info.wildCard.des = des
    else
    end
end

function CardSysDropManager:getDropSourceCfgBySource(dropSource)
    local info = CardSysConfigs.CARD_DROP_SOURCE[dropSource]
    if not info then
        info = self:getDropSourceInfo(dropSource)
    end
    return info
end

-- 获取收集来源的掉卡信息
function CardSysDropManager:getCollectDropData(dropSource)
    -- if #self.m_dropDataList > 0 then
    --     return self.m_dropDataList[1]
    -- else
    --     return nil
    -- end

    local dropInfo = nil
    local index = nil

    for i = 1, #self.m_dropDataList do
        local _info = self.m_dropDataList[i]
        if _info and _info:hasDropSource(dropSource) then
            index = i
            dropInfo = _info
            break
        end
    end
    return dropInfo, index
end

-- 移除收集来源搭的掉卡信息
function CardSysDropManager:removeCollectDropInfo(dropSource, index)
    index = index or 1

    -- local datas = self:getCollectDropData(dropSource)
    -- if #datas > 0 then
    --     return table.remove(self.m_dropDataList[dropSource], index)
    -- else
    --     return nil
    -- end
    return table.remove(self.m_dropDataList, index)
end

-- 是否有掉落数据 --
function CardSysDropManager:hasDropData(dropSource)
    local isHas = false
    if self.m_curDrop and self.m_curDrop:isHasDropSource(dropSource) then
        isHas = true
    else
        for i = 1, #self.m_dropDataList do
            local _info = self.m_dropDataList[i]
            if _info and _info:hasDropSource(dropSource) then
                isHas = true
            end
        end
    end
    return isHas
end

-- 清除掉落信息
function CardSysDropManager:clearDropCards(dropSource)
    if not dropSource or dropSource == "" then
        return
    end
    self.m_dropDataList[dropSource] = {}
end

-- -- 一次掉落只能全是一个赛季的卡牌
-- function CardSysDropManager:checkDropSeason(tDropCards)
--     if tDropCards and #tDropCards > 0 then
--         return tDropCards[1].albumId
--     end
--     return nil
-- end

-- 获取所有掉落dropSource卡片 --
function CardSysDropManager:getAllDropCardInfoBySource(dropSource)
    local dropNum = #self.m_dropDataList
    local list = {}
    if dropNum > 0 then
        if dropSource then
            for i = 1, #self.m_dropDataList do
                if self.m_dropDataList[i].source and self.m_dropDataList[i].source == dropSource then
                    list[#list + 1] = self.m_dropDataList[i]
                end
            end
        end
    end
    return list
end

-- 一组一组掉落 --
-- TODO: 没有处理同时两组掉落数据
function CardSysDropManager:dropCards(dropSource, callbackFunc)
    if self.m_curDrop and self.m_curDrop:isHasDropSource(dropSource) then
        -- 当前有没结束的掉落流程，且存在该掉落来源数据
        self.m_curDrop:setDropSource(dropSource)
        self.m_curDrop:setCallFunAfterDrop(callbackFunc)

        self.m_curDrop:doLoopDropCard()
        return true
    else
        -- 当前掉落流程没有则从剩下的掉落数据组中查找
        local dropData, index = self:getCollectDropData(dropSource)

        if dropData then
            local _dropObj = CardSysDrop:create()
            _dropObj:setDropData(dropData)
            _dropObj:setDropSource(dropSource)
            _dropObj:setCallFunAfterDrop(callbackFunc)
            -- 当前有掉落过程，则挂起
            if self.m_curDrop then
                table.insert(self.m_dropLogicQueue, self.m_curDrop)
            end
            -- 新的掉落过程作为当前掉落
            self.m_curDrop = _dropObj

            self:removeCollectDropInfo(dropSource, index)
            self.m_curDrop:doLoopDropCard()
            return true
        else
            if callbackFunc then
                callbackFunc()
            end
            return false
        end
    end
end

-- 当前掉落队列挂起状态
function CardSysDropManager:setCurDropHangUp(isHangUp)
    if self.m_curDrop then
        self.m_curDrop:setHangUp(isHangUp)
    end
end

-- 关闭面板逻辑 --
function CardSysDropManager:closeDropView(closeType, dropLinkClanId, wildType)
    if self.m_curDrop then
        self.m_curDrop:closeDropView(closeType, dropLinkClanId, wildType)
    end
end

-- 处理下一次掉落或收集全弹版 --
-- TODO: 问题：如果有多次掉落 A1,A2，其中A1掉落触发了其他的掉落B1，那么现在的顺序是，A1B1A2
function CardSysDropManager:doNextDropView()
    if self.m_curDrop then
        self.m_curDrop:doNextDropView()
    end
end

-- 当前掉落步骤结束
function CardSysDropManager:doCurDropCompleted()
    -- 移除当前掉落过程
    self.m_curDrop = nil
    -- 检查又没有挂起的掉落过程
    local _drop = self:doGetNextHangUpDrop()
    if _drop then
        self.m_curDrop = _drop
        -- 这里不要直接解挂，一定要谁挂起的谁接挂
        -- -- nado机需要等到结束后再将挂起的掉落生效
        -- if _drop:isHangUp() then
        --     _drop:setHangUp(false)
        -- end
        self.m_curDrop:checkStepLoop()
        self:doNextDropView()
    else
        -- 没有挂起的队列，结束所有开卡
        self:doAllDropFinished()
    end
end

-- 是否有挂起的掉落
function CardSysDropManager:hasHangUpDrop()
    local _count = #self.m_dropLogicQueue
    if _count > 0 then
        return true
    else
        return false
    end
end

-- 获得下一个挂起的掉落过程
function CardSysDropManager:doGetNextHangUpDrop()
    local _count = #self.m_dropLogicQueue
    if _count > 0 then
        local _drop = table.remove(self.m_dropLogicQueue, _count)
        return _drop
    else
        return nil
    end
end

-- 所有掉落结束
function CardSysDropManager:doAllDropFinished()
    -- 所有都处理完成了 --
    --比赛聚合 获得金卡和Nado 卡增加分数
    G_GetMgr(ACTIVITY_REF.BattleMatch):doCheckShowActivityLayer(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CARD_SYS_OVER)
        end,
        false
    )
end

-- 是否有收集奖励
function CardSysDropManager:isHasCollectReward()
    return #(self.m_rewardList or {}) > 0
end

-- 处理收集完成奖励
function CardSysDropManager:disposeCollectCompleteReward()
    if self:isHasCollectReward() then
        local _rewardData = table.remove(self.m_rewardList, 1)
        self:showCollectCompleteReward(_rewardData)
    else
        -- 执行当前流程的下一步骤
        self:doNextDropView()
    end
end

-- 显示收集完成奖励
function CardSysDropManager:showCollectCompleteReward(rewardData)
    if not rewardData then
        return
    end

    if rewardData.rewardType == "CLAN" then
        self:showCardClanComplete(rewardData)
    elseif rewardData.rewardType == "ALBUM" then
        self:showCardAlbumComplete(rewardData)
    elseif rewardData.rewardType == "SPECIAL" then
        self:showCardSpecialGameComplete(rewardData)
    elseif rewardData.rewardType == "MAGIC_CLAN" then
        self:showCardMagicClanComplete(rewardData)
    elseif rewardData.rewardType == "MAGIC_ALBUM" then
        self:showCardMagicAlbumComplete(rewardData)
    elseif rewardData.rewardType == "OBSIDIAN_CLAN" then
        self:showCardObsidianClanComplete(rewardData)
    end
end

-- 显示收集完成奖励
function CardSysDropManager:showCollectCompleteRewardById(rewardId)
    if not rewardId then
        return
    end

    local rewardData = nil
    for i = #self.m_rewardList, 1, -1 do
        local _info = self.m_rewardList[i]
        if _info.id == rewardId then
            rewardData = table.remove(self.m_rewardList, i)
            break
        end
    end

    self:showCollectCompleteReward(rewardData)
end

-- 展示章节奖励
function CardSysDropManager:showCardClanComplete(clanReward)
    if not clanReward then
        return
    end

    local isShowSuccess = "false"
    local seasonLogic = "no problem"
    local clanRewardData = clanReward
    if clanRewardData then
        -- 判断奖励中是否有掉卡
        local _dropSource = nil
        local _cardDrop = clanRewardData.cardDrop
        if _cardDrop then
            _dropSource = _cardDrop.source
            self:parseDropDatas({_cardDrop})
        end
        -- 打开章节收集成功面板 --
        local dropSeason = clanReward.season
        local _logic = CardSysRuntimeMgr:getSeasonLogic(dropSeason)
        -- local _logic = CardSysRuntimeMgr:getCurSeasonLogic()
        if _logic then
            local function callback()
                local hasDrop = self:dropCards(_dropSource)
                if not hasDrop then
                    -- 处理收集完成奖励
                    self:disposeCollectCompleteReward()
                end
            end
            local function enterCardSys()
                if not CardSysRuntimeMgr:isInCard() and tonumber(clanRewardData.season) == tonumber(CardNoviceCfg.ALBUMID) then
                    if gLobalDataManager:getBoolByField("NewUserCard_ClanComplete_"..globalData.userRunData.uid, false) == false then
                        gLobalDataManager:setBoolByField("NewUserCard_ClanComplete_"..globalData.userRunData.uid, true)
                        CardSysManager:pushExitCallList(callback)
                        CardSysRuntimeMgr:setIgnoreWild(true)
                        CardSysManager:enterCardCollectionSys()
                        return
                    end
                end
                callback()
            end

            local _clanComplete = _logic:createCardClanComplete(clanRewardData, enterCardSys)
            if _clanComplete then
                gLobalViewManager:showUI(_clanComplete, ViewZorder.ZORDER_UI)
                CardSysManager:setClanCompleteUI(_clanComplete)
                isShowSuccess = "true"
            end
        else
            seasonLogic = "nil"
        end
    end
end

-- 展示卡册（赛季）收集成功面板 --
function CardSysDropManager:showCardAlbumComplete(albumReward)
    if (albumReward.coins and albumReward.coins ~= 0) or #albumReward.rewards ~= 0 then
        -- 判断奖励中是否有掉卡
        local _dropSource = nil
        local dropSeason = albumReward.season
        local _logic = CardSysRuntimeMgr:getSeasonLogic(dropSeason)
        -- local _logic = CardSysRuntimeMgr:getCurSeasonLogic()
        if _logic then
            local callback2 = function()
                local hasDrop = self:dropCards(_dropSource)
                if not hasDrop then
                    -- 处理收集完成奖励
                    self:disposeCollectCompleteReward()
                end
            end

            local callback1 = function()
                self:disposeRoundOpen(callback2)
            end

            -- 完成集卡  监测运营弹窗
            local checkGuidePop = function()
                -- cxc 2023年11月30日19:38:40 集卡赛季完成奖励 监测弹（评分, 绑定Fb, 绑定邮箱）
                local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Card")
                if view then
                    view:setOverFunc(callback1)
                else
                    callback1()
                end
            end
            
            local _albumComplete = _logic:createCardAlbumComplete(albumReward, checkGuidePop)
            if _albumComplete then
                gLobalViewManager:showUI(_albumComplete, ViewZorder.ZORDER_UI)
                CardSysManager:setAlbumCompleteUI(_albumComplete)
            end
        end
    end
end

-- 展示小游戏奖励 神像卡章节完成
function CardSysDropManager:showCardSpecialGameComplete(clanReward)
    if not clanReward then
        return
    end

    local clanRewardData = clanReward
    if clanRewardData then
        -- 判断奖励中是否有掉卡
        local _dropSource = nil
        local _cardDrop = clanRewardData.cardDrop
        if _cardDrop then
            _dropSource = _cardDrop.source
            self:parseDropDatas({_cardDrop})
        end
        -- 打开章节收集成功面板 --
        local dropSeason = clanReward.season
        local _logic = CardSysRuntimeMgr:getSeasonLogic(dropSeason)
        if _logic then
            local callback = function()
                local hasDrop = self:dropCards(_dropSource)
                if not hasDrop then
                    -- 处理收集完成奖励
                    self:disposeCollectCompleteReward()
                end
            end
            local _clanComplete = _logic:createCardSpecialGameComplete(clanRewardData)
            if _clanComplete then
                _clanComplete:setOverFunc(callback)
                gLobalViewManager:showUI(_clanComplete, ViewZorder.ZORDER_UI)
                CardSysManager:setClanCompleteUI(_clanComplete)
            end
        end
    end
end

function CardSysDropManager:showCardMagicClanComplete(clanReward)
    if not clanReward then
        return
    end
    -- 判断奖励中是否有掉卡
    local _dropSource = nil
    local _cardDrop = clanReward.cardDrop
    if _cardDrop then
        _dropSource = _cardDrop.source
        self:parseDropDatas({_cardDrop})
    end
    -- 打开章节收集成功面板 --
    local callback = function()
        local hasDrop = self:dropCards(_dropSource)
        if not hasDrop then
            -- 处理收集完成奖励
            self:disposeCollectCompleteReward()
        end
    end
    G_GetMgr(G_REF.CardSpecialClan):showRewardLayer(clanReward, callback)
end

function CardSysDropManager:showCardMagicAlbumComplete(clanReward)
    -- todo card magic
    if not clanReward then
        return
    end
    -- 判断奖励中是否有掉卡
    local _dropSource = nil
    local _cardDrop = clanReward.cardDrop
    if _cardDrop then
        _dropSource = _cardDrop.source
        self:parseDropDatas({_cardDrop})
    end
    -- 打开章节收集成功面板 --
    local callback = function()
        local hasDrop = self:dropCards(_dropSource)
        if not hasDrop then
            -- 处理收集完成奖励
            self:disposeCollectCompleteReward()
        end
    end
    G_GetMgr(G_REF.CardSpecialClan):showAlbumRewardLayer(clanReward, callback)
end

function CardSysDropManager:showCardObsidianClanComplete(clanReward)
    if not clanReward then
        return
    end
    -- 判断奖励中是否有掉卡
    local _dropSource = nil
    local _cardDrop = clanReward.cardDrop
    if _cardDrop then
        _dropSource = _cardDrop.source
        self:parseDropDatas({_cardDrop})
    end
    -- 打开章节收集成功面板 --
    local callback = function()
        local hasDrop = self:dropCards(_dropSource)
        if not hasDrop then
            -- 处理收集完成奖励
            self:disposeCollectCompleteReward()
        end
    end
    local view = G_GetMgr(G_REF.ObsidianCard):showRewardLayer(clanReward, callback)
    if not view then
        callback()
    end
end
--轮次-----------------------------------------------------------------------

function CardSysDropManager:hasRoundOpen()
    if self.m_roundList and table.nums(self.m_roundList) > 0 then
        return true
    end
    return false
end

function CardSysDropManager:disposeRoundOpen(_over)
    local showRound = nil
    showRound = function()
        if not self:hasRoundOpen() then
            if _over then
                _over()
            end
            return
        end
        local openRound = table.remove(self.m_roundList, 1)
        self:showCardRoundOpen(openRound, showRound)
    end
    showRound()
end

-- 下一个轮次开启
function CardSysDropManager:showCardRoundOpen(_round, callback)
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
    if _logic then
        local roundOpenUI = _logic:createCardRoundOpen(_round, callback)
        if roundOpenUI then
            gLobalViewManager:showUI(roundOpenUI, ViewZorder.ZORDER_UI)
        end
    end
end

function CardSysDropManager:getDropBubbleKey()
    self.m_dropBubbleIndex = self.m_dropBubbleIndex + 1
    return "dropBubble_" .. self.m_dropBubbleIndex
end

function CardSysDropManager:showDropBubble(_cardDatas)
    local bubbleUI = self:createDropBubbleUI(_cardDatas)
    self.m_dropBubbleUIs[bubbleUI:getKey()] = bubbleUI

    local num = table.nums(self.m_dropBubbleUIs)
    local posY = self:getBubblePosY(num, bubbleUI:getBubbleHeight())
    -- print("init: key, posY, num -- ", bubbleUI:getKey(), posY, num)
    bubbleUI:setIndex(num)
    bubbleUI:setPosition(cc.p(display.width, posY))

    bubbleUI:playStart()
    performWithDelay(
        bubbleUI,
        function()
            if tolua.isnull(bubbleUI) then
                return
            end
            bubbleUI:playOver(
                function()
                    if tolua.isnull(bubbleUI) then
                        return
                    end
                    local removeKey = bubbleUI:getKey()
                    local removeIndex = bubbleUI:getIndex()
                    -- print("remove: key, posY, index -- ", removeKey, bubbleUI:getPositionY(), removeIndex)
                    for k, v in pairs(self.m_dropBubbleUIs) do
                        if k == removeKey then
                            if not tolua.isnull(self.m_dropBubbleUIs[k]) then
                                self.m_dropBubbleUIs[k]:removeFromParent()
                                self.m_dropBubbleUIs[k] = nil
                            end
                        else
                            if not tolua.isnull(self.m_dropBubbleUIs[k]) then
                                if v.getIndex and v:getIndex() > removeIndex then
                                    v:setIndex(v:getIndex() - 1)
                                    local nowPos = cc.p(v:getPosition())
                                    local targetPosY = self:getBubblePosY(v:getIndex(), v:getBubbleHeight())
                                    -- print("move: key, posY, num -- ", k, targetPosY, v:getIndex())
                                    v:runAction(cc.MoveTo:create(0.1, cc.p(nowPos.x, targetPosY)))
                                end
                            end
                        end
                    end
                end
            )
        end,
        3
    )
end

function CardSysDropManager:createDropBubbleUI(_cardDatas)
    local bubbleUI = util_createView("GameModule.Card.commonViews.CardDrop.CardDropBubbleUI", _cardDatas)
    gLobalViewManager:getViewLayer():addChild(bubbleUI, ViewZorder.ZORDER_UI)
    local key = self:getDropBubbleKey()
    bubbleUI:setKey(key)
    return bubbleUI
end

function CardSysDropManager:getBubblePosY(_index, _bubbleHeight)
    -- print("getBubblePosY --- 0", _index, _bubbleHeight)
    local startY = display.height - globalData.gameRealViewsSize.topUIHeight -- globalData.gameLobbyHomeNodePos.y
    local offsetY = 0
    local posY = startY - (_bubbleHeight + offsetY) * (_index - 1)
    -- print("getBubblePosY --- 1", startY, posY)
    return posY
end

function CardSysDropManager:resetDropCardData(_cardDatas)
    if not (_cardDatas and #_cardDatas > 0) then
        return
    end

    local flyCardsData = {}
    local flyCardsNum = 0
    for i = 1, #_cardDatas do
        local _cardData = _cardDatas[i]
        -- 排序参数
        _cardData.sortIndex = CardSysConfigs.DropCardPriority[_cardData.type]
        -- 计算数量
        flyCardsNum = flyCardsNum + _cardData.count
        for j = 1, _cardData.count do
            local cloneData = clone(_cardData)
            cloneData.count = 1
            if cloneData.firstDrop == true then
                if j == 1 then
                    cloneData.greenPoint = 0
                    cloneData.goldPoint = 0
                else
                    cloneData.firstDrop = false
                    cloneData.greenPoint = math.floor(cloneData.greenPoint / (_cardData.count - 1))
                    cloneData.goldPoint = math.floor(cloneData.goldPoint / (_cardData.count - 1))
                    if CardSysRuntimeMgr:isCardNormalPoint(_cardData) then
                        cloneData.sortIndex = cloneData.sortIndex + 102
                    elseif CardSysRuntimeMgr:isCardGoldPoint(_cardData) then
                        cloneData.sortIndex = cloneData.sortIndex + 101
                    elseif CardSysRuntimeMgr:isCardConvertToCoin(_cardData) then
                        cloneData.sortIndex = cloneData.sortIndex + 100
                    end
                end
            else
                cloneData.greenPoint = math.floor(cloneData.greenPoint / (_cardData.count))
                cloneData.goldPoint = math.floor(cloneData.goldPoint / (_cardData.count))
                if CardSysRuntimeMgr:isCardNormalPoint(_cardData) then
                    cloneData.sortIndex = cloneData.sortIndex + 102
                elseif CardSysRuntimeMgr:isCardGoldPoint(_cardData) then
                    cloneData.sortIndex = cloneData.sortIndex + 101
                elseif CardSysRuntimeMgr:isCardConvertToCoin(_cardData) then
                    cloneData.sortIndex = cloneData.sortIndex + 100
                end
            end
            flyCardsData[#flyCardsData + 1] = cloneData
        end
    end
    -- 排序
    table.sort(
        flyCardsData,
        function(card1, card2)
            if card1.sortIndex == card2.sortIndex then
                if card1.star == card2.star then
                    return tonumber(card1.cardId) < tonumber(card2.cardId)
                else
                    return card1.star < card2.star
                end
            else
                return card1.sortIndex < card2.sortIndex
            end
        end
    )
    return flyCardsData, flyCardsNum
end

return CardSysDropManager
