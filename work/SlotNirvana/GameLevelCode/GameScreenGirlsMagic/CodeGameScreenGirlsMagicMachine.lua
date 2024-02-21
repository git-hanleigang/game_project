---
-- island li
-- 2019年1月26日
-- CodeGameScreenGirlsMagicMachine.lua
--
-- 玩法：
--
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local BaseMachine = require "Levels.BaseMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenGirlsMagicMachine = class("CodeGameScreenGirlsMagicMachine", BaseNewReelMachine)

CodeGameScreenGirlsMagicMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenGirlsMagicMachine.SYMBOL_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 --口红信号
CodeGameScreenGirlsMagicMachine.SYMBOL_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 --口红信号
CodeGameScreenGirlsMagicMachine.SYMBOL_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3 --口红信号
CodeGameScreenGirlsMagicMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8 --bonus信号
CodeGameScreenGirlsMagicMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenGirlsMagicMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2

CodeGameScreenGirlsMagicMachine.EFFECT_WILD_COLLOCT = GameEffect.EFFECT_SELF_EFFECT + 1 -- 口红收集
CodeGameScreenGirlsMagicMachine.EFFECT_BONUS_SCORE_COLLOCT = GameEffect.EFFECT_EPICWIN + 1-- bonus分数收集
CodeGameScreenGirlsMagicMachine.EFFECT_BONUS_SHOW_LAST_CLOTHES = GameEffect.EFFECT_EPICWIN + 2-- bonus分数收集
CodeGameScreenGirlsMagicMachine.EFFECT_BONUS_TRIGGER = GameEffect.EFFECT_SELF_EFFECT + 3 -- bonus触发
CodeGameScreenGirlsMagicMachine.EFFECT_BONUS_OTHER_BIGWIN = GameEffect.EFFECT_SELF_EFFECT + 4 -- 其他玩家大赢

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

-- 构造函数
function CodeGameScreenGirlsMagicMachine:ctor()
    BaseNewReelMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    --添加头像缓存
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")
    self.m_isShowOutGame = false

    self.m_isStartCountDown = false

    self.m_spinRestMusicBG = true

    self.m_triggerBonus = false
    self.m_isStopRefresh = false
    self.m_isShowSystemView = false

    self.m_isAllWild = false    --是否所有列均为wild

    self.m_leftTriggerTime = 0

    self.m_spineManager = require("CodeGirlsMagicSrc.GirlsMagicSpineManager").new()

    self.m_collectNodeTab = {}
    --收集标记对象存储表
    self.m_betCollectData = {}
    --bet收集数据
    self.m_curCollectColTab = {}
    --本轮有收集图标的列
    self.m_curNoCollectColTab = {}
    --本轮没有收集图标的列
    self.m_bigWildNodeTab = {}
    --大wild对象存储表
    self.m_smallWildNodeTab = {}
    --假装是大wild的整列小wild对象存储表

    --切换后台的时间戳
    self.m_timeInBack = 0
    self.m_flyTime = 0
    --init
    self:initGame()
end

function CodeGameScreenGirlsMagicMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)

    self.m_configData = gLobalResManager:getCSVLevelConfigData("GirlsMagicConfig.csv", "LevelGirlsMagicConfig.lua")
    self.m_configData.m_machine = self

    -- 中奖音效
    self.m_winPrizeSounds = {}
    for i = 1, 3 do
        self.m_winPrizeSounds[#self.m_winPrizeSounds + 1] = "GirlsMagicSounds/sound_GirlsMagic_win_" .. i .. ".mp3"
    end
end

--[[
    数据刷新返回
]]
function CodeGameScreenGirlsMagicMachine:dataRefreshBack()
    
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenGirlsMagicMachine:operaEffectOver(  )

    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    -- 结束动画播放
    self.m_isRunningEffect = false

    if self.checkControlerReelType and self:checkControlerReelType( ) then
        globalMachineController.m_isEffectPlaying = false
    end
    
    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    self:playEffectNotifyChangeSpinStatus()

    if  not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,false)
        -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    --清空事件
    self.m_gameEffects = {}
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
    --     self:showFreeSpinOverAds()
    -- end
end

--进关数据初始化
function CodeGameScreenGirlsMagicMachine:initGameStatusData(gameData)
    CodeGameScreenGirlsMagicMachine.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.extra then
        --进关初始化bet收集数据
        local collectDatas = gameData.gameConfig.extra.collectData
        for betIdString, collectData in pairs(collectDatas) do
            local data = {}
            data.collects = {}
            data.wildLeftCounts = {}
            for i, num in ipairs(collectData.collects) do
                table.insert(data.collects, num)
            end
            for i, leftCount in ipairs(collectData.wildLeftCounts) do
                table.insert(data.wildLeftCounts, leftCount)
            end
            self.m_betCollectData[betIdString] = data
        end
    end
end

--更新bet收集数据
function CodeGameScreenGirlsMagicMachine:updateBetCollectData()
    if self.m_runSpinResultData.p_selfMakeData then
        local totalBetID = globalData.slotRunData:getCurTotalBet()
        local collectData = self.m_runSpinResultData.p_selfMakeData.collectData

        local data = {}
        data.collects = {}
        data.wildLeftCounts = {}
        for i, num in ipairs(collectData.collects) do
            table.insert(data.collects, num)
        end
        for i, leftCount in ipairs(collectData.wildLeftCounts) do
            table.insert(data.wildLeftCounts, leftCount)
        end
        self.m_betCollectData["" .. totalBetID] = data
    end
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGirlsMagicMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "GirlsMagic"
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenGirlsMagicMachine:getNetWorkModuleName()
    return "GirlsMagicV2"
end

function CodeGameScreenGirlsMagicMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar

    --修改背景
    self:changeBg("choose")

    --房间列表
    self.m_roomList = util_createView("CodeGirlsMagicSrc.GirlsMagicRoomListView", {machine = self})
    self:findChild("Node_Room"):addChild(self.m_roomList)
    self.m_roomData = self.m_roomList.m_roomData

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_flyNodes = {}
    self.m_flyNodes_bonus = {}

    --收集节点
    self.m_wildTimes = {}
    for index = 1, self.m_iReelColumnNum do
        local node = self:findChild("shouji_" .. index)

        local collectNode = util_createAnimation("GirlsMagic_shouji.csb")
        node:addChild(collectNode)
        table.insert(self.m_collectNodeTab, collectNode)
        --整列变为wild剩余次数GirlsMagic_shouji_number
        local wildTimes = util_createAnimation("GirlsMagic_shouji_number.csb")
        local node_reel = self:findChild("reel")
        node_reel:addChild(wildTimes, REEL_SYMBOL_ORDER.REEL_ORDER_2 - 100)
        local numPos = util_convertToNodeSpace(node, node_reel)
        wildTimes:setPosition(cc.p(numPos.x - 5, numPos.y + 20))
        self.m_wildTimes[index] = wildTimes

        wildTimes:setVisible(false)
        collectNode.lipstickTab = {}
        for iCount = 1, 3 do
            local lipstick = util_createAnimation("GirlsMagic_shouji_KouHong_" .. iCount .. ".csb")
            collectNode:addChild(lipstick)
            table.insert(collectNode.lipstickTab,#collectNode.lipstickTab + 1, lipstick)
            lipstick:setVisible(false)
        end
    end

    --收集金币节点
    self.m_node_credits = self:findChild("Node_Credits")
    self.m_credits = util_createView("CodeGirlsMagicSrc.GirlsMagicCredits", {machine = self,isShowTip = true})
    self.m_node_credits:addChild(self.m_credits)

    --添加点击回调
    self:addClick(self:findChild("Panel_1"))
    self:addClick(self:findChild("reel_kuang"))

    --过场动画
    self.m_changSceneAni = util_spineCreate("GirlsMagic_guochang", true, true)
    self.m_changSceneAni:setVisible(false)
    self:addChild(self.m_changSceneAni, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 4)
    self.m_changSceneAni:setPosition(cc.p(display.width / 2, display.height / 2))

    self.m_bonus_choose_view = util_createView("CodeGirlsMagicSrc.GirlsMagicBonusChoose", {machine = self})
    self:findChild("root"):addChild(self.m_bonus_choose_view, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 50)
    self.m_bonus_choose_view:setPosition(cc.p(-display.width / 2,-display.height / 2))
    self.m_bonus_choose_view:showView(true)
    local winSpots = self.m_roomData:getWinSpots()
    local isNeedColloct = false
    if winSpots and #winSpots > 0 then
        for key,winInfo in pairs(winSpots) do
            if winInfo.udid == globalData.userRunData.userUdid then
                isNeedColloct = true
                break
            end
        end
    end
    if not isNeedColloct then
        self.m_bonus_choose_view:showLastClothes()
    end
    
    

    --bonus玩法界面
    self.m_bonusView = util_createView("CodeGirlsMagicSrc.GirlsMagicBonusGame", {machine = self})
    self:findChild("root"):addChild(self.m_bonusView, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 60)
    self.m_bonusView:setPosition(-display.width / 2, -display.height / 2)
    self.m_bonusView:setVisible(false)
    -- self.m_bonusView:startSpin()

    --玩家选择结果界面
    self.m_chooseResultView = util_createView("CodeGirlsMagicSrc.GirlsMagicBonusSelectInfoView", {machine = self})
    self:findChild("root"):addChild(self.m_chooseResultView, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 70)
    self.m_chooseResultView:hideView()

    local Node_dress = self:findChild("Node_dress")
    self.m_bonusCredits = util_createAnimation("GirlsMagic_BonusCredits.csb")
    Node_dress:addChild(self.m_bonusCredits)

    --测试代码
    -- self:showBonusChoose()
end

--[[
    初始化随机轮盘
]]
function CodeGameScreenGirlsMagicMachine:randomSlotNodes( )
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        local randIndex = math.random(1,#reelDatas)
        for rowIndex=1,rowCount do
            local symbolType = reelDatas[randIndex]
            randIndex = randIndex + 1
            if randIndex > #reelDatas then
                randIndex = 1
            end

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = columnData.p_showGridH      
           
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex
           

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end
            
--            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * columnData.p_showGridH + halfNodeH )

           
        end
    end
    self:initGridList()
end

--按钮监听回调
function CodeGameScreenGirlsMagicMachine:clickFunc(sender)
    self.m_credits:hideTip()
end

--[[
    获取房间数据
]]
function CodeGameScreenGirlsMagicMachine:getRoomData()
    return self.m_roomList:getRoomData()
end

--[[
    修改衣服显示
]]
function CodeGameScreenGirlsMagicMachine:changeClothes(choose)
    local node = cc.Node:create()
    --创建选择的衣服
    for index = 1,#choose do
        local spine = self.m_spineManager:getChooseClothes(index,choose[index])
        node:addChild(spine)
        if index == 2 then
            spine:setLocalZOrder(10)
        else
            spine:setLocalZOrder(index)
        end
    end
    local Node_dress = self.m_bonusCredits:findChild("Node_dress")
    Node_dress:removeAllChildren(true)
    Node_dress:addChild(node)
end

--[[
    停止倒计时
]]
function CodeGameScreenGirlsMagicMachine:stopCountDown( )
    self.m_isStartCountDown = false
    self.m_bonusCredits:unscheduleUpdate()
end

--[[
    开始倒计时
]]
function CodeGameScreenGirlsMagicMachine:startConutDown()
    self.m_bonusCredits:unscheduleUpdate()
    local delay,curTime = 0,0
    local roomData = self:getRoomData()
    local perFunc = function(  )
        self.m_leftTriggerTime = self.m_leftTriggerTime - 1
        local str = util_hour_min_str(self.m_leftTriggerTime)
        self.m_bonusCredits:findChild("m_lb_countdown"):setString(str)
    end
    local endFunc = function(  )
        --刷新心跳间隔时间,主动请求一次结果
        self.m_roomList.m_refreshTime = self.m_roomList.m_heart_beat_time
    end

    if self.m_leftTriggerTime <= 0 then
        return
    end
    local str = util_hour_min_str(self.m_leftTriggerTime)
    self.m_isStartCountDown = true
    
    --刷帧
    self.m_bonusCredits:onUpdate(function(dt)
        delay = delay + dt
        if delay < 1 then
            return
        end

        delay = 0

        --每秒回调
        perFunc()
        --结束回调
        if self.m_leftTriggerTime <= 0 then
            self.m_isStartCountDown = false
            self.m_bonusCredits:unscheduleUpdate()
            endFunc()  
        end
    end)
    -- util_countDownBySecond(self.m_bonusCredits,self.m_leftTriggerTime,perFunc,endFunc)
end

--[[
    刷新倒计时时间
]]
function CodeGameScreenGirlsMagicMachine:refreshTriggerTime(time)
    self.m_leftTriggerTime = math.ceil(time / 1000) 
    if self.m_leftTriggerTime <= 0 then
        self.m_leftTriggerTime = 0
    end
    if not self.m_isStartCountDown then
        self:startConutDown()
    end
    
end

--[[
    显示轮盘
]]
function CodeGameScreenGirlsMagicMachine:showReel()
    self:findChild("reel"):setVisible(true)
    self:findChild("Node_Room"):setVisible(true)
    self:findChild("Particle_2"):setVisible(true)
    self:findChild("Particle_3"):setVisible(true)
    self:findChild("Particle_4"):setVisible(true)
    self:findChild("Particle_5"):setVisible(true)
    self:findChild("Node_dress"):setVisible(true)
    self.m_node_credits:setVisible(true)
end

--[[
    隐藏轮盘
]]
function CodeGameScreenGirlsMagicMachine:hideReel()
    self:findChild("reel"):setVisible(false)
    self:findChild("Node_Room"):setVisible(false)
    self:findChild("Particle_2"):setVisible(false)
    self:findChild("Particle_3"):setVisible(false)
    self:findChild("Particle_4"):setVisible(false)
    self:findChild("Particle_5"):setVisible(false)
    self:findChild("Node_dress"):setVisible(false)
    self.m_node_credits:setVisible(false)
end

--[[
    显示bonus开始弹版
]]
function CodeGameScreenGirlsMagicMachine:showBonusStart(func)
    local roomData = self:getRoomData()
    local triggerPlayer = roomData.result.data.triggerPlayer
    local isMe = triggerPlayer.udid == globalData.userRunData.userUdid
    local isSystem = triggerPlayer.nickName == "SYSTEM"

    if self.m_bonusView.m_isEnd then
        return
    end

    local function startShow()
        if self.m_bonusView.m_isEnd then
            return
        end
        local view = util_createAnimation("GirlsMagic/BonusStart.csb")
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_bonus_start.mp3")

        local aniName = isMe and "auto" or "auto2"
        view:findChild("Panel_1"):setVisible(isMe or isSystem)

        view:runCsbAction(aniName,false,function()
            view:removeFromParent(true)
            self.m_bonusStartView = nil
            self:clearEffectNode()
            if type(func) == "function" then
                func()
            end
        end)

        
        local node_head = view:findChild("Node_11")
        node_head:removeAllChildren(true)

        local lbl_name = view:findChild("lb_playerName")
        if isSystem then
            lbl_name:setString("Mr. Cash")
        else
            lbl_name:setString(triggerPlayer.nickName)
        end
        

        --创建头像
        local item = util_createView("CodeGirlsMagicSrc.GirlsMagicPlayerItem", true)
        node_head:addChild(item)
        --刷新头像
        item:refreshData(triggerPlayer)
        item:refreshHead()

        gLobalViewManager:showUI(view)

        self.m_bonusStartView = view
    end
    
    
    --触发玩家是自己
    if isMe or isSystem then
        startShow()
        self:clearEffectNode()
    else
        --获取其他玩家头像
        local playerItem = self.m_roomList:getUserHeadItemByUdid(triggerPlayer.udid)
        --容错判断
        if playerItem then
            --创建背景遮罩
            local mask = util_createAnimation("GirlsMagic_Player_mask.csb")
            self.m_effectNode:addChild(mask,50)
            gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_show_bonus_by_other.mp3")
            mask:runCsbAction("start",false,function(  )
                mask:runCsbAction("idle")
            end)

            --创建一个临时头像
            local tempItem = util_createView("CodeGirlsMagicSrc.GirlsMagicPlayerItem", true)
            tempItem:refreshData(playerItem:getPlayerInfo())
            tempItem:refreshHead()
            tempItem:setScale(playerItem:getParent():getScale())
            self.m_effectNode:addChild(tempItem,100)
            tempItem:setPosition(util_convertToNodeSpace(playerItem,self.m_effectNode))
            tempItem:runCsbAction("actionframe",false,function(  )
                tempItem:runCsbAction("shouji")
                local seq = cc.Sequence:create({
                    cc.MoveTo:create(util_csbGetAnimTimes(tempItem.m_csbAct,"shouji",60),cc.p(0,0)),
                    cc.CallFunc:create(function(  )
                        startShow()
                    end),
                    cc.DelayTime:create(0.5),
                    cc.RemoveSelf:create(true)
                })
                tempItem:findChild("Particle_1"):setPositionType(0)
                tempItem:runAction(seq)
            end)
        else
            startShow()
        end

        
    end
end

function CodeGameScreenGirlsMagicMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        self:playEnterGameSound( "GirlsMagicSounds/sound_GirlsMagic_enter_game.mp3" )
        local roomData = self.m_roomData:getRoomData()
        --房间状态判断
        if roomData.result then
            return true
        end
        scheduler.performWithDelayGlobal(function(  )
            self:resetMusicBg(false,"GirlsMagicSounds/music_GirlsMagic_bg_choose.mp3")
            
        end,3,self:getModuleName())
    end,0.4,self:getModuleName())
end
function CodeGameScreenGirlsMagicMachine:getBottomUINode()
    return "CodeGirlsMagicSrc.GirlsMagicBoottomUiView"
end
function CodeGameScreenGirlsMagicMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    self:updateCollectNode()

    --发送停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)

    --禁用按钮
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
end

--[[
    暂停轮盘
]]
function CodeGameScreenGirlsMagicMachine:pauseMachine()
    BaseMachine.pauseMachine(self)
    self.m_isShowSystemView = true
    --停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end

--[[
    恢复轮盘
]]
function CodeGameScreenGirlsMagicMachine:resumeMachine()
    BaseMachine.resumeMachine(self)
    self.m_isShowSystemView = false
    if self.m_isStopRefresh then
        return
    end
    --重新刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
end

--[[
    退出到大厅
]]
function CodeGameScreenGirlsMagicMachine:showOutGame( )

    if self.m_isShowOutGame then
        return
    end
    self.m_isShowOutGame = true
    local view = util_createView("CodeGirlsMagicSrc.GirlsMagicGameOut")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
end

function CodeGameScreenGirlsMagicMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    --切换到后台
    gLobalNoticManager:addObserver(self,function(self, params)
        --记录切后台的时间
        self.m_timeInBack = os.time()
        self.m_spineManager:pauseAllSpine()

    end,ViewEventType.APP_ENTER_BACKGROUND_EVENT)

    --切换到前台
    gLobalNoticManager:addObserver(self,function(self, params)
        self.m_spineManager:resumeAllSpine()
        local curTime = os.time()
        --切后台时间超过60秒直接结算
        if self.m_timeInBack > 0 and curTime > self.m_timeInBack + 60 then
            if self.m_triggerBonus then
                self:clearEffectNode()
                self:removeGameEffectType(GameEffect.EFFECT_BONUS)  --移除bonus玩法
                if self.m_bonusStartView then
                    self.m_bonusStartView:setVisible(false)
                end
                if type(self.m_bonusView.m_endFunc) ~= "function" then
                    self.m_bonusView.m_endFunc = function(  )
                        self:onBonusEnd()
                    end
                end
                
                self.m_bonusView:setGameEnd(true)
                self.m_bonusView:gameEnd()
            end
        end

        --重置时间
        self.m_timeInBack = 0
    end,ViewEventType.APP_ENTER_FOREGROUND_EVENT)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_credits:hideTip()
        end,
        ViewEventType.NOTIFY_CLOSE_PIG_TIPS
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if params[self.m_stopUpdateCoinsSoundIndex] then
                -- 此时不应该播放赢钱音效
                return
            end

            if self.m_bIsBigWin or self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
                return
            end

            local winAmonut = params[1]
            if type(winAmonut) == "number" then
                local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
                local winRatio = winAmonut / lTatolBetNum
                local soundName = nil
                local soundTime = 2
                if winRatio > 0 then
                    if winRatio <= 1 then
                        soundName = self.m_winPrizeSounds[1]
                    elseif winRatio > 1 and winRatio <= 3 then
                        soundName = self.m_winPrizeSounds[2]
                    elseif winRatio > 3 then
                        soundName = self.m_winPrizeSounds[3]
                        soundTime = 3
                    end
                end
    
                if soundName ~= nil then
                    self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
                end
            end
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
    --更改bet时触发
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params then
                local isLevelUp = params.p_isLevelUp
                self:betChangeNotify(isLevelUp) 
            end
            
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CodeGameScreenGirlsMagicMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    self.m_roomList:onExit()
    self.m_spineManager:release()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGirlsMagicMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_GirlsMagic_Bonus"
    end

    if symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_GirlsMagic_Bonus1"
    end

    if symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_GirlsMagic_Bonus2"
    end

    if symbolType == self.SYMBOL_BONUS_3 then
        return "Socre_GirlsMagic_Bonus3"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_GirlsMagic_10"
    end

    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_GirlsMagic_11"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGirlsMagicMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenGirlsMagicMachine:MachineRule_initGame()
    --检测是否直接进入Bonus
    self:checkTriggerBonus()

    --是否需要领取bonus奖励
    local winSpots = self.m_roomData:getWinSpots()
    if winSpots and #winSpots > 0 then
        local coins = 0--lastData[globalData.userRunData.userUdid] * self.m_result.userScore[globalData.userRunData.userUdid]
        for key,winInfo in pairs(winSpots) do
            if winInfo.udid == globalData.userRunData.userUdid then
                coins = coins + winInfo.coins
            end
        end

        if coins > 0 then
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            --拉上帘子
            self:closeCurtain(true,function(  )
                
            end)
            self:delayCallBack(0.47,function(  )
                --显示bonus结果
                self:showBonusWinView(coins,function(  )
                    --拉开帘子
                    self:openCurtain(true,function(  )
                        self:playGameEffect()
                    end)
                end)
            end)
        end
        
    end
end

function CodeGameScreenGirlsMagicMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        bonusNum, bRunLong = self:setBonusScatterInfo(self.SYMBOL_BONUS, col , bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenGirlsMagicMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  false,false--reelRunData:getSpeicalSybolRunInfo(symbolType)

    if symbolType == self.SYMBOL_BONUS then
        bRun, bPlayAni = true,true
    end
    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
        
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenGirlsMagicMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    -- if nodeNum < 1 or col < self.m_iReelColumnNum - 1 then
    --     return runStatus.NORUN, false
    -- else
    --     return runStatus.DUANG, true
    -- end
    --去掉快滚
    return runStatus.NORUN, false
end

--[[
    显示bonus结果
]]
function CodeGameScreenGirlsMagicMachine:showBonusWinView(coins,func)
    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    self.m_bonus_choose_view:hideLastClothes()

    --检测是否获得大奖
    self:checkFeatureOverTriggerBigWin(coins, GameEffect.EFFECT_BONUS)
    self:addLastClothesEffect()
    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_bonus_over.mp3")
    local view = self:showDialog("BonusOver_0",ownerlist,function()
        local gameName = self:getNetWorkModuleName()
        local index = -1 
        gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
            function()
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                    coins, true, true
                })
            end,
            function(errorCode, errorData)
                
            end
        )
        if type(func) == "function" then
            func()
        end
    end)

    local info={label = view:findChild("m_lb_coins"),sx = 1.33,sy = 1.33}
    self:updateLabelSize(info,568)
end

--更改bet时调用
function CodeGameScreenGirlsMagicMachine:betChangeNotify(isLevelUp)
    if isLevelUp then
    else
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        self:removeAllBigWild(false)
        self:removeAllSmallWild()
        self:removeAllCollectAction()
        self:updateCollectNode(false)
        --移除口红收集动作
        for key,flyNode in pairs(self.m_flyNodes) do
            flyNode:stopAllActions()
            flyNode:removeFromParent(true)
        end
        self.m_flyNodes = {}
    end
end

--更新收集标记 的显示
function CodeGameScreenGirlsMagicMachine:updateCollectNode(isVisibleZero)
    local totalBetID = globalData.slotRunData:getCurTotalBet()
    local data = self.m_betCollectData["" .. totalBetID]

    for i, collectNode in ipairs(self.m_collectNodeTab) do
        local collectNum = 0
        local wildLeftCount = 0
        if data ~= nil then
            collectNum = data.collects[i]
            wildLeftCount = data.wildLeftCounts[i]
            if wildLeftCount > 0 then
                collectNum = wildLeftCount
            end
        end
        for j = 1, collectNum do
            self:stopDelayFuncAct(collectNode.lipstickTab[j])
            if collectNode.lipstickTab[j]:isVisible() == false then
                collectNode.lipstickTab[j]:setVisible(true)
                if wildLeftCount > 0 then
                    collectNode.lipstickTab[j]:playAction("idle2", true)
                    collectNode.lipstickTab[j].m_curAniName = "idle2"
                else
                    collectNode.lipstickTab[j]:playAction("idle1")
                    collectNode.lipstickTab[j].m_curAniName = "idle1"
                end
            else
                if wildLeftCount > 0 then
                    collectNode.lipstickTab[j]:playAction("idle2", true)
                    collectNode.lipstickTab[j].m_curAniName = "idle2"
                else
                    collectNode.lipstickTab[j]:playAction("idle1")
                    collectNode.lipstickTab[j].m_curAniName = "idle1"
                end
            end
        end
        for i = collectNum + 1, 3 do
            self:stopDelayFuncAct(collectNode.lipstickTab[i])
            collectNode.lipstickTab[i]:setVisible(false)
        end
    end
    self:updateCollectNodeNum(nil, isVisibleZero)
end


--更新收集标记上的数字显示
function CodeGameScreenGirlsMagicMachine:updateCollectNodeNum(isBeginReel, isVisibleZero)
    local totalBetID = globalData.slotRunData:getCurTotalBet()
    local data = self.m_betCollectData["" .. totalBetID]
    for i, collectNode in ipairs(self.m_collectNodeTab) do
        local wildLeftCount = 0
        if data ~= nil then
            wildLeftCount = data.wildLeftCounts[i]
        end
        self.m_wildTimes[i]:setVisible(true)
        self.m_wildTimes[i]:findChild("m_lb_num"):setString(wildLeftCount)
        if wildLeftCount > 0 then
            collectNode:playAction("idle2", true)
        else
            local isHaveBigWild = false
            if isVisibleZero then
                if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.wildColumns then
                    local data = self.m_runSpinResultData.p_selfMakeData.wildColumns
                    for j, severCol in ipairs(data) do
                        if severCol + 1 == i then
                            isHaveBigWild = true
                            break
                        end
                    end
                end
            end
            if isHaveBigWild == false then
                self.m_wildTimes[i]:setVisible(false)
            else
                if isBeginReel == true then
                    self.m_wildTimes[i]:setVisible(false)
                else
                    self.m_wildTimes[i]:setVisible(true)
                end
            end
        end
    end
end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenGirlsMagicMachine:MachineRule_afterNetWorkLineLogicCalculate()
    self:updateBetCollectData()
end
--
--单列滚动停止回调
--
function CodeGameScreenGirlsMagicMachine:slotOneReelDown(reelCol)
    BaseNewReelMachine.slotOneReelDown(self, reelCol)

    self:changeToWildSymbol(reelCol)

    local playSound = {bonusSound = 0}

    local isBonusDown,isLipstickDown = false,false

    --快停不播落地
    if self.m_isNewReelQuickStop == nil or self.m_isNewReelQuickStop == false then
        for k = 1, self.m_iReelRowNum do
            if self:isCollectSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
                isLipstickDown = true
                if symbolNode then
                    playSound.bonusSound = 1
                    symbolNode:runAnim(
                        "buling",
                        false,
                        function()
                            if symbolNode.p_symbolType ~= nil then
                                symbolNode:runAnim("idleframe", true)
                            end
                        end
                    )
                end
            end
    
            if self.m_stcValidSymbolMatrix[k][reelCol] == self.SYMBOL_BONUS then
                isBonusDown = true
                local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
                if symbolNode then
                    symbolNode:runAnim("buling")
                end
            end
        end
    end
    
    if isLipstickDown then
        local soundPath = "GirlsMagicSounds/sound_GirlsMagic_lipstick_down.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
    if isBonusDown then
        local soundPath = "GirlsMagicSounds/sound_GirlsMagic_bonus_down.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
    -- if playSound.bonusSound == 1 then
    --     gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_bonusBuling.mp3")
    -- end
end

--[[
    变更固定wild列的信号值
]]
function CodeGameScreenGirlsMagicMachine:changeToWildSymbol(colIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end

    local wildColumns = selfData.wildColumns
    for k, iCol in pairs(wildColumns) do
        if iCol + 1 == colIndex then
            for iRow = 1, self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol + 1, iRow)
                if symbol then
                    symbol:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                end
            end
            --固定wild图标
            if self.m_bigWildNodeTab[colIndex] ~= nil then
                local bigWild = self.m_bigWildNodeTab[colIndex]
                bigWild:setVisible(true)
                bigWild:playAction("idle0")
                self:stopDelayFuncAct(bigWild)
            else
                local bigWild = util_createAnimation("Socre_GirlsMagic_Wild_2.csb")
                self.m_clipParent:addChild(bigWild, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 100 - self.m_iReelRowNum - 1 + colIndex, SYMBOL_NODE_TAG)
                bigWild:setPosition(self:getReelCenterPos(colIndex))
                self.m_bigWildNodeTab[colIndex] = bigWild
            end
            break
        end
    end
end

--[[
    获取reel位置
]]
function CodeGameScreenGirlsMagicMachine:getReelCenterPos(colIndex)
    local reelNode = self:findChild("sp_reel_" .. (colIndex - 1))
    local posX, posY = reelNode:getPosition()
    local reelSize = reelNode:getContentSize()
    posX = posX + reelSize.width * 0.5
    posY = posY + reelSize.height * 0.5
    return cc.p(posX, posY)
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenGirlsMagicMachine:showDialog(ccbName,ownerlist,func,isAuto,index,isView)
    local view=util_createView("Levels.BaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index,self.m_baseDialogViewFps)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    if isView then
        gLobalViewManager:showUI(view)
    else
        self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 4)
    end
    

    return view
end


---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenGirlsMagicMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenGirlsMagicMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenGirlsMagicMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("GirlsMagicSounds/music_GirlsMagic_custom_enter_fs.mp3")

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            )
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFreeSpinView()
        end,
        0.5
    )
end

--[[
    改变背景
]]
function CodeGameScreenGirlsMagicMachine:changeBg(bgType)
    local bg_base = self.m_gameBg:findChild("bg_base")
    local bg_bonus = self.m_gameBg:findChild("bg_bonus")
    local bg_ipad = self.m_gameBg:findChild("bg_ipad")
    if bgType == "bonus" then
        bg_base:setVisible(false)
        bg_bonus:setVisible(true)
        bg_ipad:setVisible(false)
    elseif bgType == "choose" then 
        bg_base:setVisible(false)
        bg_bonus:setVisible(false)
        bg_ipad:setVisible(true)
    else
        bg_base:setVisible(true)
        bg_bonus:setVisible(false)
        bg_ipad:setVisible(false)
    end
    
end

function CodeGameScreenGirlsMagicMachine:showFreeSpinOverView()
    -- gLobalSoundManager:playSound("GirlsMagicSounds/music_GirlsMagic_over_fs.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:triggerFreeSpinOverCallFun()
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenGirlsMagicMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()

    --隐藏提示标签
    self.m_credits:hideTip()

    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

--开始滚动
function CodeGameScreenGirlsMagicMachine:beginReel()
    self.m_curCollectColTab = {}
    self.m_curNoCollectColTab = {}
    self:removeAllCollectAction()
    BaseNewReelMachine.beginReel(self)
    --重置自动退出时间间隔
    self.m_roomList:resetLogoutTime()

    self.m_flyTime = 0

    self:clearEffectNode()

    self.m_effectNode:stopAllActions()

    
    --刷新分数
    self.m_credits:refreshScore()

    self:updateCollectNode(false)
    self:beginReelUpdateAllWildFrame()
end

--[[
    清理特效层
]]
function CodeGameScreenGirlsMagicMachine:clearEffectNode( )
    for key,flyNode in pairs(self.m_flyNodes) do
        flyNode:stopAllActions()
        flyNode:removeFromParent(true)
    end
    self.m_flyNodes = {}

    --打断收集动画
    for key,flyNode in pairs(self.m_flyNodes_bonus) do
        self:stopDelayFuncAct(flyNode)
        flyNode:removeFromParent(true)
    end
    self.m_flyNodes_bonus = {}

    self.m_effectNode:removeAllChildren(true)
end

--开始滚动时判断更新wild边框
function CodeGameScreenGirlsMagicMachine:beginReelUpdateAllWildFrame()
    local totalBetID = globalData.slotRunData:getCurTotalBet()
    local data = self.m_betCollectData["" .. totalBetID]
    local addBigWildColTab = {}
    if data then
        local leftCountsDatas = data.wildLeftCounts
        local isHaveLeftCount = false
        --判断是否所有列均为wild
        self.m_isAllWild = true
        for i, counts in ipairs(leftCountsDatas) do
            --记录固定wild的列
            if counts > 0 then
                isHaveLeftCount = true
                table.insert(addBigWildColTab, i)
            else
                self.m_isAllWild = false
            end
        end
        if isHaveLeftCount == false then
            self:removeAllBigWild(true)
            self:removeAllSmallWild()
            self:updateCollectNodeNum(true)
        else
            self:updateBigWildNode(true)
        end
    else
        self:removeAllBigWild(true)
        self:removeAllSmallWild()
    end
end

--更新大wild显示  isPlayAni是否播放动画
function CodeGameScreenGirlsMagicMachine:updateBigWildNode(isPlayAni)
    local totalBetID = globalData.slotRunData:getCurTotalBet()
    local data = self.m_betCollectData["" .. totalBetID]
    if isPlayAni == nil then
        isPlayAni = true
    end
    if isPlayAni == true then
        if data then
            local leftCountsDatas = data.wildLeftCounts
            local delay = 0
            for col, leftCounts in ipairs(leftCountsDatas) do
                if leftCounts > 0 then
                    self:firecrackerBlast(col, isPlayAni)
                end
            end
        end
    else
        if self.m_runSpinResultData.p_selfMakeData then
            local data = self.m_runSpinResultData.p_selfMakeData.wildColumns
            local delay = 0
            local isPlayAni = false
            if data then
                for i, severCol in ipairs(data) do
                    self:addWildByCol(severCol + 1, isPlayAni)
                end
            end
        end
    end
end
-- 某一列收集的口红爆炸一个 然后出现大wild
function CodeGameScreenGirlsMagicMachine:firecrackerBlast(col, isPlayAni)
    if isPlayAni == nil then
        isPlayAni = true
    end
    local lipstickTab = self.m_collectNodeTab[col].lipstickTab
    local aniTime = 0
    --爆炸动画时间

    --这里取显示的最后一个爆炸，不能取数值（数值是最终值，这里可能不是最终值）
    for i = #lipstickTab, 1, -1 do
        if lipstickTab[i]:isVisible() == true then
            --就这个爆炸了
            if isPlayAni == true then
                aniTime = util_csbGetAnimTimes(lipstickTab[i].m_csbAct, "over")
                lipstickTab[i]:playAction(
                    "over",
                    false,
                    function()
                        lipstickTab[i]:setVisible(false)
                    end
                )
                lipstickTab[i].m_curAniName = "over"
            else
                lipstickTab[i]:setVisible(false)
            end
            --显示数字减1
            local currNum = tonumber(self.m_wildTimes[col]:findChild("m_lb_num"):getString())

            self.m_wildTimes[col]:findChild("m_lb_num"):setString(currNum - 1)

            break
        end
    end

    self:addWildByCol(col, isPlayAni)
end
-- 某一列添加大wild  isPlayAni是否播放动画
function CodeGameScreenGirlsMagicMachine:addWildByCol(col, isPlayAni)
    if self.m_bigWildNodeTab[col] == nil then
        if isPlayAni == nil then
            isPlayAni = true
        end
        local bigWild = util_createAnimation("Socre_GirlsMagic_Wild_2.csb")
        self.m_clipParent:addChild(bigWild, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 100 - self.m_iReelRowNum - 1 + col, SYMBOL_NODE_TAG)
        bigWild:setPosition(self:getReelCenterPos(col))
        if isPlayAni then
            gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_show_big_wild.mp3")
            bigWild:playAction("actionframe", false)
            self:addDelayFuncAct(bigWild,"actionframe",function()
                --所有列均为wild
                if self.m_isAllWild then
                    bigWild:runCsbAction("actionframe0")
                    self:addDelayFuncAct(bigWild,"actionframe0",function()
                        bigWild:runCsbAction("idle")
                    end)
                else
                    bigWild:runCsbAction("idle0")
                end
                
            end)
        else
            --所有列均为wild
            if self.m_isAllWild then
                bigWild:runCsbAction("actionframe0")
                self:addDelayFuncAct(bigWild,"actionframe0",function()
                    bigWild:runCsbAction("idle")
                end)
            else
                bigWild:runCsbAction("idle0")
            end
        end

        self.m_bigWildNodeTab[col] = bigWild
    else
        self:stopDelayFuncAct(self.m_bigWildNodeTab[col])
        if self.m_isAllWild then
            self.m_bigWildNodeTab[col]:runCsbAction("actionframe0")
            self:addDelayFuncAct(self.m_bigWildNodeTab[col],"actionframe0",function()
                self.m_bigWildNodeTab[col]:runCsbAction("idle")
            end)
        else
            self.m_bigWildNodeTab[col]:runCsbAction("idle0")
        end
        
    end
end
--创建一列小wild
function CodeGameScreenGirlsMagicMachine:addSmallWildByCol(col)
    --添加一列wild
    if self.m_smallWildNodeTab[col] == nil then
        local smallWildNodeTab = {}
        for row = 1, self.m_iReelRowNum do
            local wild = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, row, col)
            self.m_clipParent:addChild(wild, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 120 - self.m_iReelRowNum - 1 + col, SYMBOL_NODE_TAG)
            wild:setPosition(self:getNodePosByColAndRow(row, col))
            wild:runAnim("idleframe")
            wild.p_slotNodeH = self.m_SlotNodeH

            wild.m_symbolTag = SYMBOL_FIX_NODE_TAG
            wild.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            wild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

            local linePos = {}
            linePos[#linePos + 1] = {iX = row, iY = col}
            wild:setLinePos(linePos)
            table.insert(smallWildNodeTab, wild)
        end
        self.m_smallWildNodeTab[col] = smallWildNodeTab
    end
end
--清除停止所有的收集相关动画及数据
function CodeGameScreenGirlsMagicMachine:removeAllCollectAction()
    for i, collectNode in ipairs(self.m_collectNodeTab) do
        if collectNode.m_scheduleAction then
            collectNode:stopAction(collectNode.m_scheduleAction)
            collectNode.m_scheduleAction = nil
        end

        for j, lipstick in ipairs(collectNode.lipstickTab) do
            self:stopDelayFuncAct(lipstick)
            lipstick:playAction("idle1")
            lipstick.m_curAniName = "idle1"
        end
    end
end
--删除所有的假装大wild的小wild
function CodeGameScreenGirlsMagicMachine:removeAllSmallWild()
    for col = 1, self.m_iReelColumnNum do
        --删除小wild
        if self.m_smallWildNodeTab[col] ~= nil then
            local smallWildNodeTab = self.m_smallWildNodeTab[col]
            for i, smallWildNode in ipairs(smallWildNodeTab) do
                smallWildNode:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(smallWildNode.p_symbolType, smallWildNode)
            end
            self.m_smallWildNodeTab[col] = nil
        end
    end
end
-- -删除所有大wild
function CodeGameScreenGirlsMagicMachine:removeAllBigWild(isPlayAni)
    for col = 1, self.m_iReelColumnNum do
        self:removeBigWildByCol(col, isPlayAni)
    end
end
--删除某一列大wild  isPlayAni是否播动画
function CodeGameScreenGirlsMagicMachine:removeBigWildByCol(col, isPlayAni)
    if isPlayAni == nil then
        isPlayAni = true
    end
    if self.m_bigWildNodeTab[col] ~= nil then
        if isPlayAni then
            local bigWild = self.m_bigWildNodeTab[col]
            bigWild:setVisible(true)
            bigWild:playAction("actionframe2")
            self:addDelayFuncAct(
                bigWild,
                "actionframe2",
                function()
                    self.m_bigWildNodeTab[col]:removeFromParent()
                    self.m_bigWildNodeTab[col] = nil
                end
            )
        else
            self.m_bigWildNodeTab[col]:removeFromParent()
            self.m_bigWildNodeTab[col] = nil
        end
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGirlsMagicMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end
    --有口红收集
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.EFFECT_WILD_COLLOCT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.EFFECT_WILD_COLLOCT -- 动画类型

    --bonus分数收集
    local reelData = self.m_runSpinResultData.p_reelsData
    local isColloct = false
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            if  reelData and reelData[iRow] and reelData[iRow][iCol] and reelData[iRow][iCol] == self.SYMBOL_BONUS then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.EFFECT_BONUS_SCORE_COLLOCT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_BONUS_SCORE_COLLOCT -- 动画类型
                isColloct = true
                break
            end
        end
        if isColloct then
            local winCoinTime = self:getWinCoinTime()
            break
        end
    end

    self:checkTriggerBonus()
end

--[[
    检测是否触发bonus
]]
function CodeGameScreenGirlsMagicMachine:checkTriggerBonus()

    --检测是否已经添加过bonus,防止刷新数据时导致二次添加
    for k,gameEffect in pairs(self.m_gameEffects) do
        if gameEffect.p_effectType == GameEffect.EFFECT_BONUS then
            return true
        end
    end

    --有玩家触发Bonus
    local roomData = self.m_roomData:getRoomData()
    if roomData.result then
        --发送停止刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
        self:addBonusEffect()
        return true
    end

    return false
end

--[[
    添加Bonus玩法
]]
function CodeGameScreenGirlsMagicMachine:addBonusEffect()
    self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_EPICWIN + 2
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_CHOOSE_SET_VISIBLE, {isShow = false})


    --提前设置bonus所需数据,防止切后台后直接结算数据错误
    local roomData = self:getRoomData()
    self.m_bonusView.m_roomData = roomData
    self.m_bonusView.m_result = roomData.result.data

    self.m_isStopRefresh = true

    self.m_roomList:changeStatus(false)
    self.m_roomList:sendLogOutRoom()
end

--[[
    添加其他玩家大赢
]]
function CodeGameScreenGirlsMagicMachine:addOtherBigWinEffect(eventData)
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.EFFECT_BONUS_OTHER_BIGWIN -- 动画类型
    selfEffect.eventData = eventData

    self:sortGameEffects()
end

--[[
    添加展示上次衣服
]]
function CodeGameScreenGirlsMagicMachine:addLastClothesEffect()
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.EFFECT_BONUS_SHOW_LAST_CLOTHES
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.EFFECT_BONUS_SHOW_LAST_CLOTHES -- 动画类型
end

function CodeGameScreenGirlsMagicMachine:onBonusEnd()
    self.m_bonusView:setVisible(false)
    self.m_triggerBonus = false
    self.m_isStopRefresh = false
    --等待帘子拉开再执行下一个特效
    self:delayCallBack(1,function()
        self:playGameEffect()
    end)
    self.m_roomData.m_teamData.room.result = nil
    self.m_credits:refreshScore()
    self:resetMusicBg(false,"GirlsMagicSounds/music_GirlsMagic_bg_choose.mp3")

    self.m_bonus_choose_view:showView(false)
    self.m_bonus_choose_view:hideLastClothes()
    self:addLastClothesEffect()
end

--[[
    Bonus玩法
]]
function CodeGameScreenGirlsMagicMachine:showEffect_Bonus(effectData)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    self.m_triggerBonus = true
    self.m_bonusView:setGameEnd(false)
    self.m_bonusView.m_isShowEnd = false
    local bonusEnd = function(resultData)
        effectData.p_isPlay = true
        self:onBonusEnd()
    end
    

    --选择结束
    local chooseEnd = function()
        --显示过场动画
        self:closeCurtain(true,function()
            self:stopCountDown()
            --修改背景
            self:changeBg("bonus")

            self:hideReel()

            self:delayCallBack(
                0.5,
                function()
                    self.m_bonusView:showChooseView(bonusEnd)
                end
            )
            self:openCurtain(false)
        end)
        
    end

    self:showBonusStart(function()
        if self.m_bonusView.m_isEnd then
            return
        end
        --清空赢钱
        self.m_bottomUI:updateWinCount("")
        self:removeSoundHandler()
        self:setMaxMusicBGVolume()
        self:resetMusicBg(true,"GirlsMagicSounds/music_GirlsMagic_bg_bonus.mp3")
        chooseEnd()
    end)

    --测试代码
    -- chooseEnd()
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    return true
end

--[[
    选择衣服结束
]]
function CodeGameScreenGirlsMagicMachine:onChooseEnd()
    --修改背景
    self:changeBg("base")
    --变更轮盘状态
    if globalData.slotRunData.m_isAutoSpinAction then
        self:setCurrSpinMode(AUTO_SPIN_MODE)
    else
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
    end
    self:playEffectNotifyNextSpinCall()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    --显示轮盘
    self:showReel()

    self.m_roomList:changeStatus(true)

    self.m_credits:refreshScore()

    self:resetMusicBg(false,"GirlsMagicSounds/music_GirlsMagic_bg_base.mp3")
    self:reelsDownDelaySetMusicBGVolume() 
end

--[[
    显示Bonus选择界面
]]
function CodeGameScreenGirlsMagicMachine:showBonusChoose(func)
    self.m_bonus_choose_view:showView(false,func)
end

--[[
    显示bonus界面
]]
function CodeGameScreenGirlsMagicMachine:showBonusGame(func)
    self.m_bonusView:showView()
end

--[[
    过场动画
]]
function CodeGameScreenGirlsMagicMachine:changeSceneAni(func1, func2)
    self.m_changSceneAni:setVisible(true)
    local params = {}
    params[1] = {
        --帘子拉上动画
        type = "spine", --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_changSceneAni, --执行动画节点  必传参数
        actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            if type(func1) == "function" then
                func1()
            end
        end
    }
    params[2] = {
        --帘子拉开动画
        type = "spine", --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_changSceneAni, --执行动画节点  必传参数
        actionName = "actionframe2", --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            self.m_changSceneAni:setVisible(false)
            if type(func2) == "function" then
                func2()
            end
        end
    }
    util_runAnimations(params)
end

--[[
    拉上帘子动画
]]
function CodeGameScreenGirlsMagicMachine:closeCurtain(isFull,func)
    self.m_changSceneAni:setVisible(true)
    --帘子从一半开始拉上
    local aniName = isFull and "actionframe" or "actionframe4"

    local radio = display.width / display.height    
    if radio < 1.5 and not isFull then
        aniName = "actionframe6"
    elseif radio >= 1.5 and radio < 1.6 and not isFull then
        aniName = "actionframe8"
    end
    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_close_curtain.mp3")
    local params = {}
    params[1] = {
        --帘子拉上动画
        type = "spine", --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_changSceneAni, --执行动画节点  必传参数
        actionName = aniName, --动作名称  动画必传参数,单延时动作可不传
        callBack = function()

            if type(func) == "function" then
                func()
            end
        end
    }
    util_runAnimations(params)
end

--[[
    拉开帘子动画
]]
function CodeGameScreenGirlsMagicMachine:openCurtain(isFull,func)
    self.m_changSceneAni:setVisible(true)
    --帘子是否只拉开一半
    local aniName = isFull and "actionframe2" or "actionframe3"
    local radio = display.width / display.height
    if radio < 1.5 and not isFull then
        aniName = "actionframe5"
    elseif radio >= 1.5 and radio < 1.6 and not isFull then
        aniName = "actionframe7"
    end

    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_open_curtain.mp3")
    local params = {}
    params[1] = {
        --帘子拉开动画
        type = "spine", --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_changSceneAni, --执行动画节点  必传参数
        actionName = aniName, --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            if isFull then
                self.m_changSceneAni:setVisible(false)
            end
            
            if type(func) == "function" then
                func()
            end
        end
    }
    util_runAnimations(params)
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGirlsMagicMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_WILD_COLLOCT then
        --收集口红
        self:colloctLipstick(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end

    --bonus分数收集
    if effectData.p_selfEffectType == self.EFFECT_BONUS_SCORE_COLLOCT then
        self:colloctBonusScore(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end

    --展示上次衣服
    if effectData.p_selfEffectType == self.EFFECT_BONUS_SHOW_LAST_CLOTHES then
        self.m_bonus_choose_view:showLastClothes(function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    

    return true
end

--[[
    收集分数
]]
function CodeGameScreenGirlsMagicMachine:colloctBonusScore(func)
    local roomData = self.m_roomData:getRoomData()
    local isBonusTrigger = (roomData.result ~= nil)
    local bonus_symbol = {}
    
    --遍历小
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow)
            if symbol.p_symbolType == self.SYMBOL_BONUS then
                --记录bonus图标
                table.insert(bonus_symbol,#bonus_symbol + 1,symbol)
            end
            self:bonusColloctAni(symbol)
        end
    end

    
    --先收集分数,然后播触发动画
    performWithDelay(self.m_effectNode,function(  )
        self.m_credits:refreshScore()
        if isBonusTrigger then
            --清理连线
            self:clearWinLineEffect()
            gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_bonus_trigger.mp3")
            self:clearCurMusicBg()
            --触发动画
            for k,symbol in pairs(bonus_symbol) do
                symbol:runAnim("actionframe")
            end
        end
    end,1.25)
    

    local delayTime2 = 0.5
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        delayTime2 = 1
    end
    if roomData.result then
        delayTime2 = 4
    end
    self:delayCallBack(delayTime2,function(  )
        if type(func) == "function" then
            func()
        end
    end)
    
end


--[[
    收集bonus分数动画
]]
function CodeGameScreenGirlsMagicMachine:bonusColloctAni(symbol)
    if symbol.p_symbolType == self.SYMBOL_BONUS then
        local lbl_score = symbol:getChildByTag(self.SYMBOL_BONUS + 1000)

        --分数标签放大然后飞粒子
        if lbl_score then
            lbl_score:runCsbAction("actionframe1",false,function(  )
                lbl_score:runCsbAction("idle2")
                self:flyCollectBonusAni(symbol,self.m_credits,function(  )
                    lbl_score:runCsbAction("actionframe2",false,function(  )
                        lbl_score:runCsbAction("idle1")
                    end)
                end)
            end)
        end
    end
end

--新滚动使用
function CodeGameScreenGirlsMagicMachine:updateReelGridNode(symbolNode)
    local symbolType = symbolNode.p_symbolType
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --固定wild的不收集分数
    if selfData then
        local wildColumns = selfData.wildColumns
        for k, iCol in pairs(wildColumns) do
            if iCol + 1 == symbolNode.p_cloumnIndex then
                return
            end
        end
    end

    --创建分数标签
    local lbl_score = symbolNode:getChildByTag(self.SYMBOL_BONUS + 1000)
    if not lbl_score then
        lbl_score = util_createAnimation("Socre_GirlsMagic_Bonus_number.csb")
        symbolNode:addChild(lbl_score,100,self.SYMBOL_BONUS + 1000)
        lbl_score:setAnchorPoint(0.5, 0.5)
    end
    lbl_score:setVisible(false)

    --添加分数标签
    if symbolNode.m_isLastSymbol == true and symbolType == self.SYMBOL_BONUS then
        local iCol = symbolNode.p_cloumnIndex
        local iRow = symbolNode.p_rowIndex
        local index = self:getPosReelIdx(iRow ,iCol,self.m_iReelRowNum)

        local selfData = self.m_runSpinResultData.p_selfMakeData

        local score = 0
        --bonus分数收集
        if selfData.positionScore then
            score = selfData.positionScore[tostring(index)] or 0
        end

        local m_lb_coins = lbl_score:findChild("m_lb_coins")
        m_lb_coins:setString(util_formatCoins(score, 4))
        
        local info={label = m_lb_coins,sx = 1,sy = 1}
        self:updateLabelSize(info,180)
        lbl_score:setVisible(true)
    end
end



--判断是不是收集图标
function CodeGameScreenGirlsMagicMachine:isCollectSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_3 then
        return true
    end
    return false
end

--[[
    收集口红
]]
function CodeGameScreenGirlsMagicMachine:colloctLipstick(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end
    local collects = selfData.collectData.collects
    local wildLeftCounts = selfData.collectData.wildLeftCounts
    self.m_flyTime = 0
    local waitFly = 0
    for col = 1, self.m_iReelColumnNum do
        local isHaveCollectSymbol = false
        for row = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
            if slotNode and self:isCollectSymbol(slotNode.p_symbolType) then
                slotNode:runAnim("actionframe")
                waitFly = 0.4
                performWithDelay(self.m_effectNode,function(  )
                    self:playCollectParticle(slotNode, self.m_wildTimes[col],col,row)
                end,0.2)
                isHaveCollectSymbol = true
            end
        end
        if isHaveCollectSymbol == true then
            table.insert(self.m_curCollectColTab, col)
        else
            table.insert(self.m_curNoCollectColTab, col)
        end
    end

    -- 2.5 1.5
    if #self.m_curCollectColTab > 0 then
        local time = 1

        local isHaveCollectFull = false
        local data = self.m_runSpinResultData.p_selfMakeData.collectData
        for i, wildLeft in ipairs(data.wildLeftCounts) do
            if wildLeft == 3 then
                isHaveCollectFull = true
                break
            end
        end
        --如果有收集满的列，则开始非收集列的出现
        if isHaveCollectFull == true then
            for i, v in ipairs(self.m_curNoCollectColTab) do
                if data.wildLeftCounts[v] == 3 then
                    time = 1.5
                    break
                end
            end
        end

        if self.m_flyTime < time then
            self.m_flyTime = time
        end

    end

    if type(func) == "function" then
        func()
    end
    -- self:delayCallBack(waitFly,function(  )
        
    -- end)
    
    
end
--[[
    @desc: 获得轮盘的位置
]]
function CodeGameScreenGirlsMagicMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end


--[[
    bonus分数收集粒子
]]
function CodeGameScreenGirlsMagicMachine:flyCollectBonusAni(startNode,endNode,func)
    local flyNode = util_createAnimation("Socre_GirlsMagic_Bonus_money_shouji.csb")
    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
    flyNode:setPosition(startPos)
    self.m_effectNode:addChild(flyNode,1000)

    local angle = util_getAngleByPos(startPos, endPos)
    flyNode:setRotation(-angle)

    local scaleSize = math.sqrt(math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2))
    flyNode:setScaleX(scaleSize / 455)

    table.insert( self.m_flyNodes_bonus, #self.m_flyNodes_bonus + 1, flyNode )

    self:stopDelayFuncAct(flyNode)
    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_bonus_colloct.mp3")
    flyNode:runCsbAction("actionframe1")
    self:addDelayFuncAct(flyNode,"actionframe1",function(  )
        local bombAni = util_createAnimation("Socre_GirlsMagic_Bonus_shouji_bao.csb")
        self.m_effectNode:addChild(bombAni,1000)
        bombAni:setPosition(endPos)
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_refresh_score.mp3")
        bombAni:runCsbAction("actionframe",false,function(  )
            bombAni:removeFromParent(true)
        end)
        --收集粒子飞完，开始播收集标记上的口红动画
        if type(func) == "function" then
            func()
        end
    end)
    
    return flyNode
end

--播放收集粒子
function CodeGameScreenGirlsMagicMachine:playCollectParticle(startNode,endNode,colIndex,rowIndex)
    local flyNode = util_createAnimation("Socre_GirlsMagic_Bonus_shouji.csb")
    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
    self.m_effectNode:addChild(flyNode,1000)
    flyNode:setPosition(startPos)

    --炸开特效
    local bombAni = util_createAnimation("Socre_GirlsMagic_Bonus_shouji_bao.csb")
    self.m_effectNode:addChild(bombAni,1000)
    bombAni:setPosition(endPos)
    bombAni:setVisible(false)

    local time = 0.3
    -- if rowIndex == 2  then
    --     time = 0.2
    -- elseif rowIndex == 1 then
    --     time = 0.3
    -- end

    flyNode:findChild("Particle_1"):setPositionType(0)
    flyNode:findChild("Particle_1_0"):setPositionType(0)
    local seq = cc.Sequence:create({
        cc.MoveTo:create(time,endPos),
        cc.CallFunc:create(function(  )
            bombAni:setVisible(true)
            bombAni:runCsbAction("actionframe",false,function(  )
                bombAni:removeFromParent(true)
            end)
            --收集粒子飞完，开始播收集标记上的口红动画
            self:CollectParticleEndOneCollectNodeLipstickAppear(colIndex)
        end),
        cc.Hide:create()
    })
    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_fly_particle_lipstick.mp3")
    flyNode:runAction(seq)

    table.insert(self.m_flyNodes,#self.m_flyNodes + 1,flyNode)

    return flyNode
end

--收集粒子飞完后 一个收集标记上的口红出现
function CodeGameScreenGirlsMagicMachine:CollectParticleEndOneCollectNodeLipstickAppear(col)
    local collectNode = self.m_collectNodeTab[col]

    local data = self.m_runSpinResultData.p_selfMakeData.collectData
    local collectNum = 0
    local wildLeftCount = 0
    if data ~= nil then
        collectNum = data.collects[col]
        wildLeftCount = data.wildLeftCounts[col]
    end
    --检测从第几个口红出现
    local index = 0
    for i = 1, 3 do
        if collectNode.lipstickTab[i]:isVisible() == false then
            index = i
            break
        end
    end

    if index > 0 then
        local function lipstickAppear()
            if index > 3 then
                collectNode:stopAllActions()
                collectNode.m_scheduleAction = nil
            end
            local lipstick = collectNode.lipstickTab[index]
            lipstick:setVisible(true)
            gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_lipstick_appear.mp3")
            lipstick:playAction("start")
            lipstick.m_curAniName = "start"

            index = index + 1
            if index > collectNum then
                --口红出现结束
                collectNode:stopAction(collectNode.m_scheduleAction)
                collectNode.m_scheduleAction = nil
                self:addDelayFuncAct(
                    lipstick,
                    "start",
                    function()
                        self:CollectParticleEndOneCollectNodeLipstickAppearEnd(col)
                    end
                )
            end
        end
        collectNode.m_scheduleAction = util_schedule(collectNode, lipstickAppear, 0.1)
    end
end

--收集粒子飞完后 一个收集标记上的口红出现结束
function CodeGameScreenGirlsMagicMachine:CollectParticleEndOneCollectNodeLipstickAppearEnd(col)
    local collectNode = self.m_collectNodeTab[col]
    local data = self.m_runSpinResultData.p_selfMakeData.collectData
    local collectNum = 0
    local wildLeftCount = 0
    if data ~= nil then
        collectNum = data.collects[col]
        wildLeftCount = data.wildLeftCounts[col]
    end
    --收集满了
    if wildLeftCount == 3 then
        --出数字
        self.m_wildTimes[col]:setVisible(true)
        self.m_wildTimes[col]:findChild("m_lb_num"):setString(wildLeftCount)
        self.m_wildTimes[col]:runCsbAction("actionframe")
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_resetTimes.mp3")
        collectNode:playAction(
            "start",
            false,
            function()
                collectNode:playAction("idle2", true)
                self:CollectParticleEndOneCollectNodeCollectEnd(col)
            end
        )
        -- self:addBigWildFrame(col)
        --点火
        for i = 1, 3 do
            if collectNode.lipstickTab[i].m_curAniName ~= "idle2" then
                collectNode.lipstickTab[i]:playAction("idle2", true)
                collectNode.lipstickTab[i].m_curAniName = "idle2"
            end
        end
    else
        self:CollectParticleEndOneCollectNodeCollectEnd(col)
    end
end
--一个收集图标彻底收集结束
function CodeGameScreenGirlsMagicMachine:CollectParticleEndOneCollectNodeCollectEnd(col)
    --收集结束的列清除记录
    for i, v in ipairs(self.m_curCollectColTab) do
        if v == col then
            table.remove(self.m_curCollectColTab, i)
            break
        end
    end
    --所有该收集的列都收集完
    if #self.m_curCollectColTab == 0 then
        local isHaveCollectFull = false
        local data = self.m_runSpinResultData.p_selfMakeData.collectData
        for i, wildLeft in ipairs(data.wildLeftCounts) do
            if wildLeft == 3 then
                isHaveCollectFull = true
                break
            end
        end
        --如果有收集满的列，则开始非收集列口红的出现
        if isHaveCollectFull == true then
            --判读有没有要出口红的列
            local lipstickAppearColTab = {}
            --存储要出口红的列
            for i, v in ipairs(self.m_curNoCollectColTab) do
                if data.wildLeftCounts[v] == 3 then
                    table.insert(lipstickAppearColTab, v)
                end
            end
            if #lipstickAppearColTab > 0 then
                self.m_curNoCollectColTab = lipstickAppearColTab
                for i, v in ipairs(self.m_curNoCollectColTab) do
                    self:OneNoCollectNodeLipstickAppear(v)
                end
            else
                --没有需要出口红的列，结束收集流程
                if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
                    self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT, self.EFFECT_WILD_COLLOCT})
                end
            end
        else --如果没有收集满的列，则结束收集流程
            if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
                self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT, self.EFFECT_WILD_COLLOCT})
            end
        end
    end
end

--本轮没收集的一列 收集标志上的口红出现
function CodeGameScreenGirlsMagicMachine:OneNoCollectNodeLipstickAppear(col)
    local collectNode = self.m_collectNodeTab[col]

    --检测从第几个口红出现
    local index = 0
    for i = 1, 3 do
        if collectNode.lipstickTab[i]:isVisible() == false then
            index = i
            break
        end
    end

    if index > 0 then --有没出现的口红
        local function lipstickAppear()
            local lipstick = collectNode.lipstickTab[index]
            lipstick:setVisible(true)
            lipstick:playAction("start")
            lipstick.m_curAniName = "start"

            index = index + 1
            if index > 3 then
                --口红出现结束
                collectNode:stopAction(collectNode.m_scheduleAction)
                collectNode.m_scheduleAction = nil
                self:addDelayFuncAct(
                    lipstick,
                    "start",
                    function()
                        self:OneNoCollectNodeLipstickAppearEnd(col)
                    end
                )
            end
        end
        collectNode.m_scheduleAction = util_schedule(collectNode, lipstickAppear, 0.1)
    else
        --没有没出现的口红，直接调用出现结束
        self:OneNoCollectNodeLipstickAppearEnd(col)
    end
end

--本轮没收集的列 收集标记上的口红出现结束
function CodeGameScreenGirlsMagicMachine:OneNoCollectNodeLipstickAppearEnd(col)
    local collectNode = self.m_collectNodeTab[col]
    local data = self.m_runSpinResultData.p_selfMakeData.collectData
    local collectNum = 0
    local wildLeftCount = 0
    if data ~= nil then
        collectNum = data.collects[col]
        wildLeftCount = data.wildLeftCounts[col]
    end
    self.m_wildTimes[col]:setVisible(true)
    self.m_wildTimes[col]:findChild("m_lb_num"):setString(wildLeftCount)
    if wildLeftCount >= 3 then
        self.m_wildTimes[col]:runCsbAction("actionframe")
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_resetTimes.mp3")
    end
    -- gLobalSoundManager:playSound("WickedBlazeSounds/music_WickedBlaze_collectNodeNumChange.mp3")
    collectNode:playAction(
        "start",
        false,
        function()
            collectNode:playAction("idle2", true)
            self:OneNoCollectNodeCollectEnd(col)
        end
    )
end

--本轮没收集图标的列 收集标记上的口红出现的流程彻底结束
function CodeGameScreenGirlsMagicMachine:OneNoCollectNodeCollectEnd(col)
    --动画结束的列清除记录
    for i, v in ipairs(self.m_curNoCollectColTab) do
        if v == col then
            table.remove(self.m_curNoCollectColTab, i)
            break
        end
    end

    if #self.m_curNoCollectColTab == 0 then
        --结束收集流程
        if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
            self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT, self.EFFECT_WILD_COLLOCT})
        end
    end
end

--添加动画回调(用延迟)
function CodeGameScreenGirlsMagicMachine:addDelayFuncAct(animationNode, animationName, func)
    self:stopDelayFuncAct(animationNode)
    animationNode.m_runDelayFuncAct =
        performWithDelay(
        animationNode,
        function()
            animationNode.m_runDelayFuncAct = nil
            if func then
                func()
            end
        end,
        util_csbGetAnimTimes(animationNode.m_csbAct, animationName)
    )
end
--停止动画回调
function CodeGameScreenGirlsMagicMachine:stopDelayFuncAct(animationNode)
    if animationNode and animationNode.m_runDelayFuncAct then
        animationNode:stopAction(animationNode.m_runDelayFuncAct)
        animationNode.m_runDelayFuncAct = nil
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenGirlsMagicMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenGirlsMagicMachine:playEffectNotifyNextSpinCall( )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE then

        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime() + self.m_flyTime

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

end

function CodeGameScreenGirlsMagicMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    BaseNewReelMachine.slotReelDown(self)
end
--[[
    延迟回调
]]
function CodeGameScreenGirlsMagicMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

-- 通知某种类型动画播放完毕
function CodeGameScreenGirlsMagicMachine:notifyGameEffectPlayComplete(param)
    local effectType
    if type(param) == "table" then
        effectType = param[1]
    else
        effectType = param
    end
    local effectLen = #self.m_gameEffects
    if effectType == nil or effectType == EFFECT_NONE or effectLen == 0 then
        return
    end

    if effectType == GameEffect.EFFECT_QUEST_DONE then
        return
    end

    for i = 1, effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == effectType and effectData.p_isPlay == false then
            if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT then
                if effectData.p_selfEffectType == param[2] then
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 继续播放动画
                    break
                end
            else
                effectData.p_isPlay = true
                self:playGameEffect() -- 继续播放动画
                break
            end
        end
    end
end

--获得信号块层级
function CodeGameScreenGirlsMagicMachine:getBounsScatterDataZorder(symbolType)
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_3 or symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分值越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order
end

return CodeGameScreenGirlsMagicMachine
