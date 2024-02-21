--[[
    主界面

    需要有宝箱是否已经打开的数据
    断线重连的点
        开宝箱后
            有鲨鱼
            无鲨鱼
        中途带走奖励但是没有领奖需要断线吗？？？
        最后一轮结算但是没有领奖需要断线重连吗？？？
]]
local CSMainTouchControl = import(".CSMainTouchControl")
local CSMainLogic = import(".CSMainLogic")
local CSMainLayer = class("CSMainLayer", CSMainLogic)

function CSMainLayer:getBgMusicPath()
    return CardSeekerCfg.otherPath .. "music/magic_bg.mp3"
end

function CSMainLayer:getRefName()
    return G_REF.CardSeeker
end

function CSMainLayer:initDatas()
    self.m_btnClickStatus = nil
    -- self.m_isCGShowing = true
    self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_MainLayer.csb")
    self:setKeyBackEnabled(false)
    self:setPauseSlotsEnabled(true)
    --self:setBgm(CardSeekerCfg.otherPath .. "music/magic_bg.mp3")
end

-- function CSMainLayer:playShowAction()
--     gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
--     CSMainLayer.super.playShowAction(self, "start")
-- end

function CSMainLayer:initCsbNodes()
    self.m_nodeGuoChang = self:findChild("node_guochang")
    -- self.m_nodeCG = self:findChild("node_CG")
    self.m_btnInfo = self:findChild("btn_i")
    self.m_btnGo = self:findChild("btn_go")
    self.m_nodeNpc = self:findChild("Node_spine_Npc")
    self.m_nodeShuiBG = self:findChild("node_spine")            -- 2024.01 新增背景Spine挂点（水）
    self.m_nodeBG = self:findChild("Node_spine_bj")           -- 2024.01 新增背景Spine挂点（bj）
    self.m_nodeNpcBubble = self:findChild("Node_NPC_Bubble")
    self.m_nodeProgress = self:findChild("Node_Progress")
    self.m_nodeReward = self:findChild("Node_Reward")

    self.m_nodeBoxWaters = {}
    for i = 1, CardSeekerCfg.BoxTotalCount do
        local water = self:findChild("Node_water_" .. i)
        table.insert(self.m_nodeBoxWaters, water)
    end

    self.m_nodeBoxRewards = {}
    -- for i = 1, CardSeekerCfg.BoxTotalCount do
    --     local prize = self:findChild("Node_prize_" .. i)
    --     table.insert(self.m_nodeBoxRewards, prize)
    -- end

    self.m_nodeBoxes = self:findChild("Node_Boxes")
    self.m_nodeBoxList = {}
    for i = 1, CardSeekerCfg.BoxTotalCount do
        local nodeBox = self:findChild("Node_Box_" .. i)
        table.insert(self.m_nodeBoxList, nodeBox)
    end

    self.m_nodeGems = self:findChild("node_gem")
    self.m_nodePickAgain = self:findChild("node_pick")
end

function CSMainLayer:initView()
    self:initGems()
    self:initReward()
    self:initBg()           -- 2024.01 新增背景Spine挂点
    self:initNpc()
    self:initBubble()
    --self:initBoxWater()
    -- self:initBoxReward()
    self:initBoxes()
    self:initProgress()
    self:initBtnGo()
    -- 晃动宝箱计时初始化
    CSMainTouchControl:getInstance():init(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CSMainLayer:initGems()
    self.m_gem = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainGem")
    self.m_nodeGems:addChild(self.m_gem)
end

function CSMainLayer:initReward()
    self.m_reward = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainReward")
    self.m_nodeReward:addChild(self.m_reward)
end

-- 2024.01 新增背景Spine挂点  v2 双层BG
function CSMainLayer:initBg()
    self.m_bg = util_spineCreate(CardSeekerCfg.otherPath .. "spine/Seeker202401_bj", true, true, 1)
    if self.m_nodeBG and self.m_bg then
        self.m_nodeBG:addChild(self.m_bg)
    end
    self.m_bgShui = util_spineCreate(CardSeekerCfg.otherPath .. "spine/shui", true, true, 1)
    if self.m_nodeShuiBG and self.m_bgShui then
        self.m_nodeShuiBG:addChild(self.m_bgShui)
    end
    self:playBgIdle()
end

-- 2024.01 新增背景Spine挂点 v2 双层BG
function CSMainLayer:playBgIdle()
    if self.m_bg then
        util_spinePlay(self.m_bg, "idle", true)
    end
    if self.m_bgShui then
        util_spinePlay(self.m_bgShui, "idle", true)
    end
end

function CSMainLayer:initNpc()
    self.m_npc = util_spineCreate(CardSeekerCfg.otherPath .. "spine/Seeker202401_npc", true, true, 1)
    self.m_nodeNpc:addChild(self.m_npc)
    self:playNpcIdle()
end

function CSMainLayer:playNpcIdle()
    if self.m_npc then
        util_spinePlay(self.m_npc, "idle", true)
    end
end

-- npc 挥棒
function CSMainLayer:playNpcStart(_over)
    -- if self.m_npc then
    --     util_spinePlay(self.m_npc, "start", false)
    --     util_spineEndCallFunc(self.m_npc, "start", function()
    --         if not tolua.isnull(self) then
    --             self:playNpcIdle()
    --         end
    --     end)
    --     util_performWithDelay(self, function()
    --         if not tolua.isnull(self) then
    --             if _over then
    --                 _over()
    --             end            
    --         end
    --     end, 0.3)
    -- else        
    --     if _over then
    --         _over()
    --     end
    -- end
    if _over then
        _over()
    end
end

function CSMainLayer:initBubble()
    self.m_bubble = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainBubble")
    self.m_nodeNpcBubble:addChild(self.m_bubble)
    -- 初始化后隐藏，播放动作前显示，播放完后再隐藏
    self.m_bubble:setVisible(false)
end

function CSMainLayer:initBoxWater()
    self.m_boxWaters = {}
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local curLevelData = GameData:getCurLevelData()
    for i = 1, CardSeekerCfg.BoxTotalCount do
        local isOpened = curLevelData:isBoxOpened(i)
        local water = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainBoxWater", not isOpened)
        self.m_nodeBoxWaters[i]:addChild(water)
        table.insert(self.m_boxWaters, water)
    end
end

function CSMainLayer:createBoxReward(_boxIndex, _boxData, _isGrey)
    local rewardNode = nil
    -- if _boxData:isMonsterBox() then
    --     rewardNode = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainBoxMonster", _isGrey)
    -- else
        rewardNode = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainBoxReward", _boxData, _isGrey)
    -- end
    local box = self.m_boxList[_boxIndex]
    if rewardNode and box then
        local box_spine = box:getSpine()
        rewardNode:setName("BoxReward")
        util_spinePushBindNode(box_spine,"node_reward",rewardNode)
        self.m_nodeBoxRewards[_boxIndex] = rewardNode
        --parent:addChild(rewardNode)
        util_setCascadeOpacityEnabledRescursion(box_spine, true)
        util_setCascadeColorEnabledRescursion(box_spine, true)
    end
    
    return rewardNode
end

function CSMainLayer:createGuoChane(_over)
    -- self:runCsbAction("over",false,function()
    --     if tolua.isnull(self) then
    --         return
    --     end
    --     self:runCsbAction("idle",true)
    --     if _over then
    --         _over()
    --     end
    --     gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/Seeker_screen_over.mp3")
    -- end)
    -- gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/Seeker_screen_start.mp3")

    -- 202401 只保留音效
    -- if not self.m_guochang then
    --     self.m_guochang = util_spineCreate(CardSeekerCfg.otherPath .. "spine/Seeker_lianzi", true, true, 1)
    --     local bg = self:findChild("root")
    --     local s = 1 / bg:getScale()
    --     self.m_guochang:setScale(s+0.01)
    --     if s == 1 then
    --         self.m_guochang:setScaleX(1.1)
    --     end
    --     self.m_nodeGuoChang:addChild(self.m_guochang)
    -- end
    gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/Seeker_screen_start.mp3")

    -- 判断 _over 以前没有这段代码 202401 加
    if _over then
        _over()
    end

    -- util_spinePlay(self.m_guochang, "start", false)
    -- util_spineEndCallFunc(self.m_guochang, "start", function()
    --     gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/Seeker_screen_over.mp3")
    --    util_spinePlay(self.m_guochang, "over", false)
    --    util_spineEndCallFunc(self.m_guochang, "over", _over)
    -- end)     
end

function CSMainLayer:getBoxRewardByIndex(_boxIndex)
    local parent = self.m_nodeBoxRewards[_boxIndex]
    if not parent then
        return
    end
    return parent
end

function CSMainLayer:clearBoxRewardByIndex(_boxIndex)
    local parent = self.m_nodeBoxRewards[_boxIndex]
    local box = self.m_boxList[_boxIndex]
    if not parent or not box then
        return
    end
    local box_spine = box:getSpine()
    util_spineRemoveBindNode(box_spine,parent)
    self.m_nodeBoxRewards[_boxIndex] = nil
end

-- function CSMainLayer:initBoxReward()
--     self.m_boxRewards = {}
--     local GameData = self:getTSGameData()
--     if not GameData then
--         return
--     end
--     for i = 1, CardSeekerCfg.BoxTotalCount do
--         local prize = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainBoxReward")
--         self.m_nodeBoxRewards[i]:addChild(prize)
--         table.insert(self.m_boxRewards, prize)
--     end
-- end

function CSMainLayer:initBoxes()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local curLevelData = GameData:getCurLevelData()
    local curLevelConfig = GameData:getCurLevelConfig()
    if not (curLevelData and curLevelConfig) then
        return
    end
    local special = curLevelConfig:getSpecial()
    local boxRewardData = curLevelData:getBoxRewards()
    self.m_boxList = {}
    for i = 1, CardSeekerCfg.BoxTotalCount do
        -- 初始化时，断线重连后要考虑之前开出鲨鱼的情况
        local isOpened = curLevelData:isBoxOpened(i)
        local box = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainBox", i, special, isOpened, boxRewardData[i], handler(self, self.clickBox))
        self.m_nodeBoxList[i]:addChild(box)
        table.insert(self.m_boxList, box)
    end
end

function CSMainLayer:initProgress()
    self.m_progress = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainProgress")
    self.m_nodeProgress:addChild(self.m_progress)
end

function CSMainLayer:initBtnGo()
    -- 断线重连 处理按钮状态
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local winData = GameData:getWinRewardData()
    if winData and winData:hasRewards() then
        self:setBtnGoClickStatus(true)
    else
        self:setBtnGoClickStatus(false)
    end
end

function CSMainLayer:shakeBox(_over)
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local curLevelData = GameData:getCurLevelData()
    if not curLevelData then
        return
    end
    if not self.m_lastShakeIndex then
        self.m_lastShakeIndex = -1
    end
    local shakeIndexList = {}
    for i = 1, CardSeekerCfg.BoxTotalCount do
        -- 初始化时，断线重连后要考虑之前开出鲨鱼的情况
        local isOpened = curLevelData:isBoxOpened(i)
        if not isOpened and i ~= self.m_lastShakeIndex then
            shakeIndexList[#shakeIndexList + 1] = i
        end
    end
    if #shakeIndexList == 0 then
        return
    end
    local index = math.random(1, #shakeIndexList)
    local shakeIndex = shakeIndexList[index]
    self.m_lastShakeIndex = shakeIndex
    local box = self.m_boxList[shakeIndex]
    box:playShake(_over)
end

function CSMainLayer:showWidget(_isShow)
    -- self.m_reward:setVisible(_isShow)
    -- self.m_npc:setVisible(_isShow)
    -- self.m_nodeBoxes:setVisible(_isShow)
    -- self.m_progress:setVisible(_isShow)
    -- self.m_btnInfo:setVisible(_isShow)
    -- self.m_btnGo:setVisible(_isShow)
end

-- function CSMainLayer:openCG(_over)
--     gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/CG.mp3")
--     if not self.m_GCNode then
--         self.m_GCNode = util_createAnimation(CardSeekerCfg.csbPath .. "Seeker_MainLayer_guochang.csb")
--         self.m_nodeGuoChang:addChild(self.m_GCNode)
--     end
--     self.m_GCNode:playAction(
--         "guochang",
--         false,
--         function()
--             if not tolua.isnull(self.m_GCNode) then
--                 self.m_GCNode:removeFromParent()
--                 self.m_GCNode = nil
--             end
--             if _over then
--                 _over()
--             end
--         end,
--         60
--     )
--     -- if not self.m_CGSpine then
--     --     self.m_CGSpine = util_spineCreate(CardSeekerCfg.otherPath .. "spine/guochang", true, true)
--     --     self.m_nodeCG:addChild(self.m_CGSpine)
--     -- end
--     -- util_spinePlay(self.m_CGSpine, "guochang", false)
--     -- util_spineEndCallFunc(
--     --     self.m_CGSpine,
--     --     "guochang",
--     --     function()
--     --         util_nextFrameFunc(
--     --             function()
--     --                 if not tolua.isnull(self) and not tolua.isnull(self.m_CGSpine) then
--     --                     if self.m_CGSpine then
--     --                         self.m_CGSpine:removeFromParent()
--     --                         self.m_CGSpine = nil
--     --                     end
--     --                 end
--     --             end
--     --         )
--     --         if _over then
--     --             _over()
--     --         end
--     --     end
--     -- )
-- end

-- function CSMainLayer:closeCG(_over)
--     if not self.m_CGSpine then
--         self.m_CGSpine = util_spineCreate(CardSeekerCfg.otherPath .. "spine/guochang", true, true)
--         self.m_nodeCG:addChild(self.m_CGSpine)
--     end
--     util_spinePlay(self.m_CGSpine, "close", false)
--     util_spineEndCallFunc(
--         self.m_CGSpine,
--         "close",
--         function()
--             if _over then
--                 _over()
--             end
--             self.m_CGSpine:removeFromParent()
--             self.m_CGSpine = nil
--         end
--     )
-- end

function CSMainLayer:setBtnGoClickStatus(_btnStatus)
    if _btnStatus == self.m_btnClickStatus then
        return
    end
    if _btnStatus == true and not self:hasWinRewards() then
        return
    end
    self.m_btnClickStatus = _btnStatus
    self.m_btnGo:setTouchEnabled(_btnStatus)
    self.m_btnGo:setBright(_btnStatus)
end

function CSMainLayer:hasWinRewards()
    local GameData = self:getTSGameData()
    if GameData then
        local winData = GameData:getWinRewardData()
        if winData then
            return winData:hasRewards() 
        end
    end
    return false
end

function CSMainLayer:canClick()
    -- -- 刚进入界面时播放CG期间不能点击
    -- if self.m_isCGShowing then
    --     return false
    -- end
    -- 请求时不能点击
    if self.m_clickedBox then
        return false
    end
    -- 逻辑开始后不能点击
    if self:getStatusByKey("start_monster") then
        return false
    end
    if self:getStatusByKey("seek_monster") then
        return false
    end
    if self:getStatusByKey("seek_prize") then
        return false
    end
    if self:getStatusByKey("start_click") then
        return false
    end
    -- 主界面点击关闭后或者打开的过程中不能点击
    if self:isShowing() or self:isHiding() then
        return false
    end
    return true
end

-- 点击一个宝箱
function CSMainLayer:clickBox(_index)
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local curLevelData = GameData:getCurLevelData()
    if not curLevelData then
        local curLevelIndex = GameData:getCurLevelIndex() or "NULL"
        local msg = "function clickBox curLevelData is NULL, curLevelIndex=" .. curLevelIndex .. ", _index=" .. _index
        util_sendToSplunkMsg("CardSeeker", msg)
        return
    end
    local isOpened = curLevelData:isBoxOpened(_index)
    if isOpened then
        return
    end
    if not self:canClick() then
        return
    end
    print("--- CSMainLayer:clickBox ---", _index)
    self.m_clickedBox = true
    self.m_boxList[_index]:setOpenStatus(true)
    -- 晃动宝箱计时清除
    CSMainTouchControl:getInstance():clearTiming()
    -- 每次点击重置必要数据
    self.m_cacheLevelIndex = GameData:getCurLevelIndex()
    self.m_selectBoxIndex = _index
    G_GetMgr(G_REF.CardSeeker):requestOpenBox(_index)
end

-- 中途带走所有的礼品并且结束本次小游戏
function CSMainLayer:takeAllRewards()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    G_GetMgr(G_REF.CardSeeker):showConfirmLayer()
end

function CSMainLayer:onShowedCallFunc()
    -- self:runCsbAction("idle", true, nil, 60)

    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local curLevelData = GameData:getCurLevelData()
    local openedIndexs = curLevelData:getOpenedClientPos()
    local willOpenBoxData = curLevelData:getWillOpenBoxRewardData()
    local cur = GameData:getCurLevelIndex()
    local max = GameData:getLevelCount()

    if openedIndexs and #openedIndexs > 0 then -- 当前层已经打开
        -- 断线重连后直接开始逻辑，需要初始化一些必要数据
        self.m_cacheLevelIndex = GameData:getCurLevelIndex()
        self.m_selectBoxIndex = openedIndexs[#openedIndexs]
        -- 上一次打开的是鲨鱼且没有操作，断线重连
        if willOpenBoxData:isMonsterBox() then
            self:doStartMonsterLogic()

        -- 上一次打开的不是maigc卡且没有操作，断线重连
        elseif GameData:isCheckPickAgain(self.m_cacheLevelIndex) and curLevelData:checkPickAgain() then
            self:doSeekPrizeLogic(true, true)
        else
            -- 最后一层，玩完了得强制弹结算弹板去领奖
            if cur == max then
                if curLevelData:isFinish() then
                    self:seekPrize_showRoundReward()
                end
            end
        end
    else
        -- 晃动宝箱计时开始
        CSMainTouchControl:getInstance():startTiming()
        -- 气泡
        util_performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    self:seekPrize_playNpcBubble()
                end
            end,
            1
        )
    end
end

-- 点击事件
function CSMainLayer:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "btn_i" then
        G_GetMgr(G_REF.CardSeeker):showRuleLayer()
    elseif name == "btn_go" then
        self:takeAllRewards()
    end
end

-- 关闭时移除之上节点或者layer
function CSMainLayer:closeOtherUI()
    local closeList = {}
    for i = 1, #closeList do
        local name = closeList[i]
        local view = gLobalViewManager:getViewByName(name)
        if not tolua.isnull(view) then
            if view.closeUI then
                view:closeUI()
            else
                view:removeFromParent()
            end
        end
    end
end

function CSMainLayer:closeUI(_over)
    self:closeOtherUI()
    CSMainLayer.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
        end
    )
end

function CSMainLayer:registerListener()
    CSMainLayer.super.registerListener(self)

    -- 开宝箱后续操作
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self.m_clickedBox = false
            if params and params.isSuc then
                local GameData = self:getTSGameData()
                if not GameData then
                    return
                end
                local levelData = GameData:getLevelDataByIndex(self.m_cacheLevelIndex)
                if levelData:isWillOpenMonster() then
                    -- gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/openMonster.mp3")
                    self:doSeekMonsterLogic()
                else
                    gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/openPrize.mp3")
                    local isPickAgain = false
                    if GameData:isCheckPickAgain(self.m_cacheLevelIndex) and levelData:checkPickAgain() then
                        isPickAgain = true
                    end
                    self:doSeekPrizeLogic(isPickAgain, false)
                end
            end
        end,
        ViewEventType.CARD_SEEKER_REQUEST_OPENBOX
    )
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --     end,
    --     ViewEventType.CARD_SEEKER_REQUEST_GIVEUP
    -- )
    -- 晃动宝箱
    gLobalNoticManager:addObserver(
        self,
        function()
            --self:shakeBox()
        end,
        ViewEventType.CARD_SEEKER_SHAKE_BOX
    )
    -- -- 刚进入界面，播放CG动画过程时，不能点击宝箱
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function()
    --         self.m_isCGShowing = false
    --     end,
    --     ViewEventType.CARD_SEEKER_CG_CLOSED
    -- )
end

function CSMainLayer:showPickAgainBtn(_isInit, _pickAgainGoNext, _pickAgainCostGem)
    if not self.m_pickAgain then
        self.m_pickAgain = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainPickAgain")
        self.m_nodePickAgain:addChild(self.m_pickAgain)
    end
    local GameData = self:getTSGameData()
    if GameData then
        local levelCfg = GameData:getLevelConfigByIndex(self.m_cacheLevelIndex)
        if levelCfg then
            local needGems = levelCfg:getNeedGems()
            self.m_pickAgain:updatePick(
                needGems,
                function()
                    if not tolua.isnull(self) then
                        if _pickAgainGoNext then
                            _pickAgainGoNext()
                        end
                    end
                end,
                function()
                    if not tolua.isnull(self) then
                        if _pickAgainCostGem then
                            _pickAgainCostGem()
                        end
                    end                    
                end
            )
            if _isInit then
                self.m_pickAgain:playIdle()
            else
                self.m_pickAgain:playShow()
            end
        end
    end
end

function CSMainLayer:getTSGameData()
    return G_GetMgr(G_REF.CardSeeker):getData()
end

return CSMainLayer
