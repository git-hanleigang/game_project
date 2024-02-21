--[[
    bet变化时，bet上方进度条变化
]]
local GameBetBarControl = class("GameBetBarControl", BaseSingleton)

function GameBetBarControl:ctor()
    -- 按照最高优先级的往表头插入数据的规则配表
    self.m_betTipsConfig = {
        {
            key = "LevelGoldIcon",      --关卡切换bet优先弹关卡内的小弹板(修改显示优先级)
            init = nil,
            check = "checkLevelGoldIcon",
            lua = "base/BaseView", -- 不需要展示
            params = {portraitX = 40},
            update = "updateLevelGoldIcon",
            priority = 1
        },
        {
            key = "BetBubbles",
            init = nil,
            check = "checkBetBubbles",
            lua = "GameModule/BetBubbles/view/BetBubblesMain",
            params = {portraitX = 0},
            update = "updateBetBubbles",
            refName = G_REF.BetBubbles,
            priority = 2
        },              
        -- {
        --     key = "FrostFlameClash",
        --     init = nil,
        --     check = "checkFrostFlameClash",
        --     lua = "FrostFlameClashCode/BetBubble/FrostFlameClashBetBubble",
        --     params = {portraitX = 40},
        --     update = "updateFrostFlameClash",
        --     priority = 6
        -- },
        -- {
        --     key = "MegaWinParty",
        --     init = nil,
        --     check = "checkMegaWinParty",
        --     lua = "Activity_MegaWinPartyCode/Activity/MegaWinPartyBetNode",
        --     params = {portraitX = 40},
        --     update = "updateMegaWinParty",
        --     priority = 6
        -- },          
        -- {
        --     key = "BetExtraBubble",
        --     init = nil,
        --     check = "checkBetExtraBubble",
        --     lua = "BetExtraBubbleCode/BetExtraMain",
        --     params = {portraitX = 0},
        --     update = "updateBetExtraBubble",
        --     priority = 5
        -- },        
        -- -- {
        -- --     key = "MinzBetBubble",
        -- --     init = nil,
        -- --     check = "checkMinz",
        -- --     lua = "MinzCode/MinzBetBubble",
        -- --     params = {portraitX = 0},
        -- --     update = "updateMinz",
        -- --     priority = 5
        -- -- },
        -- {
        --     key = "RainbowBetTip",
        --     init = nil,
        --     check = "checkBalloonRush",
        --     --lua = "Activity/BalloonRush/BalloonRushBetTip",
        --     --lua = "Activity/RainbowRush/RainbowRushBetTip",
        --     refName = ACTIVITY_REF.BalloonRush,
        --     params = {portraitX = 40},
        --     update = "updateBalloonRush",
        --     priority = 5
        -- },
        -- {
        --     key = "CommonJackpotBetTip",
        --     init = nil,
        --     check = "checkCommonJackpot",
        --     lua = "Activity/CommonJackpot/LevelBet/CJBetTipNode",
        --     params = {portraitX = 40},
        --     update = "updateCommonJackpot",
        --     priority = 5
        -- },
        -- {
        --     key = "DeluexeClubTip",
        --     init = "initDeluexe",
        --     check = "checkDeluexe",
        --     lua = "Activity/DeluexeClubSrc/Activity_DeluexeClubTip",
        --     params = {portraitX = 40},
        --     update = "updateDeluexe",
        --     priority = 3
        -- },
        -- {
        --     key = "CardBetTip",
        --     init = nil,
        --     check = "checkCard",
        --     lua = "views/gameviews/CardBetChipNode",
        --     params = {portraitX = 40},
        --     update = "updateCard",
        --     priority = 2
        -- },
        -- {
        --     key = "FindBetTip",
        --     check = "checkFind",
        --     lua = "",
        --     params = {portraitX = 40},
        --     priority = 1
        -- }
    }
end

function GameBetBarControl:init(_parentNode)
    self.m_parentNode = _parentNode
end

-- 清除缓存数据和节点
function GameBetBarControl:clearBets()
    self.m_showBetCoins = 0
    self.m_showBetKey = nil
    if self.m_betTip and not tolua.isnull(self.m_betTip) then
        self.m_betTip:removeFromParent()
        self.m_betTip = nil
    end
    self.m_deluxeClubTipFlag = nil
    self:clearLevelGoldIcon()
end

-- bet变化
function GameBetBarControl:changeBet(_newBetCoins)
    if not (_newBetCoins and _newBetCoins > 0) then
        return
    end
    if not self.m_showBetCoins then
        self.m_showBetCoins = 0
    end
    if self.m_showBetCoins == _newBetCoins then
        return
    end
    self:showBetTip(_newBetCoins)
    self.m_showBetCoins = _newBetCoins
end

-- 不切换bet时刷新
function GameBetBarControl:updateShowBetTips()
    if self.m_showBetCoins == nil then
        self.m_showBetCoins = 0
    end
    self:showBetTip(self.m_showBetCoins)
end

function GameBetBarControl:showBetTip(_newBetCoins, _popDefault)
    local showConfig = nil
    for i = 1, #self.m_betTipsConfig do
        local cfg = self.m_betTipsConfig[i]
        -- 初始化
        if cfg.init then
            self[cfg.init](self)
        end
        -- 检测条件
        if cfg.check and self[cfg.check](self) then
            showConfig = cfg
            break
        end
    end
    if showConfig ~= nil then
        local isExistLuaPath = showConfig.lua ~= nil and (util_IsFileExist(showConfig.lua .. ".lua") or util_IsFileExist(showConfig.lua .. ".luac"))
        local isExistRefName = showConfig.refName ~= nil
        if isExistLuaPath or isExistRefName then
            if (not self.m_showBetKey and not self.m_betTip) or (self.m_showBetKey and self.m_showBetKey ~= showConfig.key) then
                self.m_betTip = self:createBetTipNode(showConfig.key, showConfig.lua, showConfig.refName)
            end
            if not tolua.isnull(self.m_betTip) then
                -- 可扩展参数
                if showConfig.params then
                    -- 适配竖版下的x位置
                    if showConfig.params.portraitX ~= nil and globalData.slotRunData.isPortrait == true then
                        self.m_betTip:setPositionX(showConfig.params.portraitX)
                    end
                end 

                self.m_showBetKey = showConfig.key
                -- 刷新
                if showConfig.update then
                    self[showConfig.update](self, self.m_showBetCoins or 0, _newBetCoins, _popDefault)
                end
            end
        end
    end
end

function GameBetBarControl:createBetTipNode(_key, _luaPath, _refName)
    self.m_parentNode:removeAllChildren()
    local betTip = nil
    if _luaPath ~= nil then
        betTip = util_createView(_luaPath)
    elseif _refName ~= nil then
        betTip = G_GetMgr(_refName):createBetTipNode()
    end
    if betTip then
        betTip:setName(_key)
        self.m_parentNode:addChild(betTip)
    end
    return betTip
end

--[[ --------------------------------------------------------------------------------------------------------
    最多需要配置 初始化函数， 检测函数， 刷新函数
]]
-- --[[
--     气球挑战 限时任务
-- ]]
-- function GameBetBarControl:checkBalloonRush()
--     -- 判断是否有数据
--     local act_data = G_GetMgr(ACTIVITY_REF.BalloonRush):getRunningData()
--     if not act_data then
--         return false
--     end

--     if act_data:isAllCollected() then
--         return false
--     end
--     -- 判断是否有资源
--     if not G_GetMgr(ACTIVITY_REF.BalloonRush):isCanShowLayer() then
--         return false
--     end
--     if globalData.slotRunData.machineData == nil then
--         return false
--     end
--     local betList = globalData.slotRunData.machineData:getMachineCurBetList()
--     if not betList then
--         return false
--     end
--     local curIndex = globalData.slotRunData:getCurBetIndex()
--     local bet_data = betList[curIndex]
--     if not bet_data then
--         return false
--     end
--     if not bet_data.p_balloonRushScores or table.nums(bet_data.p_balloonRushScores) <= 0 then
--         return false
--     end
--     return true
-- end

-- function GameBetBarControl:updateBalloonRush(_nowBetCoins, _newBetCoins, _popDefault)
--     if globalData.slotRunData.machineData == nil then
--         return
--     end
--     local betList = globalData.slotRunData.machineData:getMachineCurBetList()
--     local curIndex = globalData.slotRunData:getCurBetIndex()
--     local value = math.floor(curIndex / (#betList) * 100)
--     if _newBetCoins - _nowBetCoins > 0 then
--         self.m_betTip:addBet(value, true)
--     elseif _newBetCoins - _nowBetCoins < 0 then
--         self.m_betTip:delBet(value, true)
--     end
-- end

-- --[[
--     公共jackpot
-- ]]
-- function GameBetBarControl:checkCommonJackpot()
--     -- 判断是否有数据
--     local runningData = G_GetMgr(ACTIVITY_REF.CommonJackpot):getRunningData()
--     if not runningData then
--         return false
--     end
--     -- 判断是否有资源
--     if not G_GetMgr(ACTIVITY_REF.CommonJackpot):isCanShowLayer() then
--         return false
--     end
--     if globalData.slotRunData.machineData == nil then
--         return false
--     end
--     -- 判断关卡是否是公共jackpot关卡
--     if not G_GetMgr(ACTIVITY_REF.CommonJackpot):isRecmdJackpotLevel(globalData.slotRunData.machineData.p_name) then
--         return false
--     end
--     return true
-- end

-- function GameBetBarControl:updateCommonJackpot(_nowBetCoins, _newBetCoins, _popDefault)
--     if globalData.slotRunData.machineData == nil then
--         return
--     end    
--     local betList = globalData.slotRunData.machineData:getMachineCurBetList()
--     local curIndex = globalData.slotRunData:getCurBetIndex()
--     local value = math.floor(curIndex / (#betList) * 100)
--     if _newBetCoins - _nowBetCoins > 0 then
--         self.m_betTip:addBet(value, true)
--     elseif _newBetCoins - _nowBetCoins < 0 then
--         self.m_betTip:delBet(value, true)
--     end
-- end

--[[
    关卡的黄金图标
]]
-- function GameBetBarControl:initLevelGoldIcon()
-- end
function GameBetBarControl:checkLevelGoldIcon()
    if globalData.slotRunData.machineData == nil then
        return false
    end
    -- 抛出的事件包内带一个表,如果有关卡要触发黄金图标就修改一下表内的数据
    local params = {
        -- 当前关卡名称
        levelName = globalData.slotRunData.machineData.p_name,
        -- 是否触发提示面板
        bTrigger = false
    }
    self.m_checkLevelGoldIconParams = params
    gLobalNoticManager:postNotification("checkLevelGoldIcon", self.m_checkLevelGoldIconParams)

    print("[GameBetBarControl:checkLevelGoldIcon] ", params.levelName, params.bTrigger)
    return params.bTrigger
end
function GameBetBarControl:updateLevelGoldIcon(_nowBetCoins, _newBetCoins, _popDefault)
    if globalData.slotRunData.machineData == nil then
        return
    end
    local params = {
        levelName = globalData.slotRunData.machineData.p_name,
        nowBetCoins = _nowBetCoins,
        newBetCoins = _newBetCoins,
        popDefault = _popDefault
    }
    gLobalNoticManager:postNotification("UpdateLevelGoldIcon", params)
end
function GameBetBarControl:clearLevelGoldIcon()
    self.m_checkLevelGoldIconParams = nil
end

-- --[[
--     高倍场
-- ]]
-- function GameBetBarControl:initDeluexe()
--     if self.m_deluxeClubTipFlag == nil then
--         local currBetIndex = globalData.slotRunData:getCurBetIndex()
--         self.m_deluxeClubTipFlag = currBetIndex >= globalData.constantData.FREE_CLUB_POINT_SPIN_LIMIT
--     end
-- end
-- function GameBetBarControl:checkDeluexe()
--     if not util_IsFileExist("Activity/Activity_DeluexeClub_tip.csb") then
--         return false
--     end
--     if globalDynamicDLControl:checkDownloading("Activity_DeluexeClub") then
--         return false
--     end
--     if globalData.slotRunData.isDeluexeClub == true then
--         return false
--     end
--     if globalData.userRunData.levelNum < globalData.constantData.CLUB_OPEN_LEVEL then
--         return false
--     end
--     local currBetIndex = globalData.slotRunData:getCurBetIndex()
--     if self.m_deluxeClubTipFlag == (currBetIndex >= globalData.constantData.FREE_CLUB_POINT_SPIN_LIMIT) then
--         return false
--     end
--     return true
-- end
-- function GameBetBarControl:updateDeluexe(_nowBetCoins, _newBetCoins, _popDefault)
--     local currBetIndex = globalData.slotRunData:getCurBetIndex()
--     self.m_deluxeClubTipFlag = currBetIndex >= globalData.constantData.FREE_CLUB_POINT_SPIN_LIMIT
--     self.m_betTip:updateView(self.m_deluxeClubTipFlag)
-- end

-- --[[
--     集卡
-- ]]
-- function GameBetBarControl:checkCard()
--     -- 新手集卡期间不显示 普通集卡UI
--     local bCardNovice = CardSysManager:isNovice()
--     if bCardNovice then
--         return
--     end

--     if not CardSysManager:hasSeasonOpening() then
--         return false
--     end
--     if not CardSysManager:isDownLoadCardRes() then
--         return false
--     end
--     if not CardSysManager:isCardOpenLv() then
--         return false
--     end
--     return true
-- end
-- function GameBetBarControl:updateCard(_nowBetCoins, _newBetCoins, _popDefault)
--     if globalData.slotRunData.machineData == nil then
--         return
--     end    
--     if _popDefault then
--         self.m_betTip:popBetDefault(_popDefault)
--     else
--         local betList = globalData.slotRunData.machineData:getMachineCurBetList()
--         local curIndex = globalData.slotRunData:getCurBetIndex()
--         local value = math.floor(curIndex / (#betList) * 100)
--         if _newBetCoins - _nowBetCoins > 0 then
--             self.m_betTip:addBet(value, true)
--         elseif _newBetCoins - _nowBetCoins < 0 then
--             self.m_betTip:delBet(value, true)
--         end
--     end
-- end

-- --[[
--     Minz 雕像收集活动
-- ]]
-- function GameBetBarControl:checkMinz()
--     -- 判断是否有MinzMgr
--     local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
--     if not minzMgr then
--         return false
--     end
--     -- 判断是否有数据
--     local act_data = minzMgr:getRunningData()
--     if not act_data then
--         return false
--     end
--     -- 判断是否有资源
--     if not minzMgr:isCanShowLayer() then
--         return false
--     end
--     -- 判断是否会掉落minz点数关卡
--     local isMinzGame = minzMgr:getIsMinzGame()
--     if not isMinzGame then
--         return false
--     end
--     -- 判断当前是否是minz关卡
--     local isMinzLevel = minzMgr:isMinzLevel()
--     if isMinzLevel then
--         return false
--     end
--     -- 开关
--     local isMinzSwitchOn = G_GetMgr(ACTIVITY_REF.Minz):getIsMinzSwitchOn()
--     if not isMinzSwitchOn then
--         return false
--     end    
--     return true
-- end

-- function GameBetBarControl:updateMinz(_nowBetCoins, _newBetCoins, _popDefault)
--     self.m_betTip:updateBetLab()
-- end

-- minz点击按钮（气泡弹出or收起）
function GameBetBarControl:clickBtnBetBarFunc()
    if self.m_betTip and self.m_betTip.clickBtnBetBarFunc then
        self.m_betTip:clickBtnBetBarFunc()
    end
end

-- -- 额外消耗bet的活动气泡
-- function GameBetBarControl:checkBetExtraBubble()
--     local effectiveRefs = G_GetMgr(G_REF.BetExtraCosts):getEffectiveBetExtraRef()
--     if effectiveRefs and #effectiveRefs > 0 then
--         return true
--     end
--     return false
-- end

-- function GameBetBarControl:updateBetExtraBubble()
--     self.m_betTip:showBet()
-- end

-- --[[
--     1v1比赛
-- ]]
-- function GameBetBarControl:checkFrostFlameClash()
--     -- 判断是否有Mgr
--     local mgr = G_GetMgr(ACTIVITY_REF.FrostFlameClash)
--     if not mgr then
--         return false
--     end
--     return mgr:checkBetIsShow()
-- end

-- function GameBetBarControl:updateFrostFlameClash(_nowBetCoins, _newBetCoins, _popDefault)
--     self.m_betTip:updateBetLab(_nowBetCoins, _newBetCoins)
-- end

-- --[[
--     find
-- ]]
-- function GameBetBarControl:checkFind()
--     return false
-- end

-- --[[
--     大赢宝箱
-- ]]
-- function GameBetBarControl:checkMegaWinParty()
--     -- 判断是否有Mgr
--     local mgr = G_GetMgr(ACTIVITY_REF.MegaWinParty)
--     if not mgr then
--         return false
--     end
--     return false --mgr:checkBetIsShow()
-- end

-- function GameBetBarControl:updateMegaWinParty(_nowBetCoins, _newBetCoins, _popDefault)
--     self.m_betTip:updateBetLab(_nowBetCoins, _newBetCoins)
-- end

function GameBetBarControl:checkBetBubbles()
    local bubbleDatas = G_GetMgr(G_REF.BetBubbles):getShowModuleDatas()
    if bubbleDatas and #bubbleDatas > 0 then
        return true
    end
    return false    
end

function GameBetBarControl:updateBetBubbles()
    self.m_betTip:showBet()
end

return GameBetBarControl
