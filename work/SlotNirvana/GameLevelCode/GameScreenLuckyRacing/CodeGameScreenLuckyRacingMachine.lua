---
-- island li
-- 2019年1月26日
-- CodeGameScreenLuckyRacingMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseMachine = require "Levels.BaseMachine"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CollectData = require "data.slotsdata.CollectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local CodeGameScreenLuckyRacingMachine = class("CodeGameScreenLuckyRacingMachine", BaseNewReelMachine)

CodeGameScreenLuckyRacingMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenLuckyRacingMachine.Socre_LuckyRacing_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenLuckyRacingMachine.Socre_LuckyRacing_MYSTERY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
-- CodeGameScreenLuckyRacingMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
CodeGameScreenLuckyRacingMachine.TEAMMISSION_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 多人玩法事件
CodeGameScreenLuckyRacingMachine.BONUS_TRIGGER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 多人玩法事件
CodeGameScreenLuckyRacingMachine.COLLECT_HOURSE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 收集事件
CodeGameScreenLuckyRacingMachine.COLLECT_SOCRE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 -- 收集事件
CodeGameScreenLuckyRacingMachine.CHOOSE_HOURSE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 -- 收集事件

local BTN_TAG_IDCARD    =   1001        --ID卡按钮

local SPINE_HOURSE_SKIN = {
    "huang",
    "zi",
    "lan",
    "lv",
    "hei",
}

--过场动画
local SPINE_CHANGE_SCENE = { 
    "WinnerTakeAll_0_yellow",
    "WinnerTakeAll_0_purple",
    "WinnerTakeAll_0_blue",
    "WinnerTakeAll_0_green"
}

local SPINE_WINNER_ANI = {
    "GuoChangKuang_yellow",
    "GuoChangKuang_purple",
    "GuoChangKuang_blue",
    "GuoChangKuang_green",
}
-- 构造函数
function CodeGameScreenLuckyRacingMachine:ctor()
    CodeGameScreenLuckyRacingMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_isShowOutGame = false
    self.m_isShowSystemView = false

    self.m_bEnterGame = true --首次进入关卡
    self.m_isHaveSelfCollect = false

    self.m_nodes_scatter = {}

 
    --添加头像缓存
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")

    --init
    self:initGame()
end

function CodeGameScreenLuckyRacingMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("LuckyRacingConfig.csv", "LevelLuckyRacingConfig.lua")
    self.m_configData.m_machine = self
    --初始化基本数据
    self:initMachine(self.m_moduleName)

    -- 中奖音效
    self.m_winPrizeSounds = {}
    for i = 1, 3 do
        self.m_winPrizeSounds[#self.m_winPrizeSounds + 1] = "LuckyRacingSounds/sound_LuckyRacing_win_" .. i .. ".mp3"
    end

    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenLuckyRacingMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LuckyRacing"  
end

--[[
    初始化房间列表
]]
function CodeGameScreenLuckyRacingMachine:initRoomList()
    --房间列表
    self.m_roomList = util_createView("CodeLuckyRacingSrc.LuckyRacingRoomListView", {machine = self})
    self:findChild("ChangeRoom"):addChild(self.m_roomList)
    self.m_roomData = self.m_roomList.m_roomData
end


function CodeGameScreenLuckyRacingMachine:initUI()

    --初始化房间列表
    self:initRoomList()

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_hourses = {}
    self.m_changeSceneAni = {}
    for index = 1,4 do
        local hourse = util_createAnimation("LuckyRacing_horse.csb")
        self:findChild("horse_"..(index - 1)):addChild(hourse)
        self.m_hourses[index] = hourse
        for iColor=1,4 do
            local node = hourse:findChild("xiaoma_"..(iColor - 1))
            if index == iColor then
                node:setVisible(true)
                local spine = util_spineCreate("Socre_LuckyRacing_benpao",true,true)
                node:addChild(spine,100)
                hourse.m_spine = spine
                util_spinePlay(spine,"idleframe",true)
                spine:setSkin(SPINE_HOURSE_SKIN[index])
            else
                node:setVisible(false)
            end
        end
    end

    self.m_bonusGameView = util_createView("CodeLuckyRacingSrc.LuckyRacingBonusGame",{machine = self})
    self.m_bonusGameView:setVisible(false)
    self:findChild("root"):addChild(self.m_bonusGameView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
    self.m_bonusGameView:setPosition(cc.p(-display.width / 2,-display.height / 2))
    -- self.m_bonusGameView:findChild("root"):setScale(self.m_machineRootScale)

    self.m_freeGameView = util_createView("CodeLuckyRacingSrc.LuckyRacingFreeGameView",{machine = self})
    self:findChild("root"):addChild(self.m_freeGameView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 90)
    self.m_freeGameView:setPosition(cc.p(-display.width / 2,-display.height / 2))
    self.m_freeGameView:findChild("root"):setScale(self.m_freeScale)
    self.m_freeGameView:setVisible(false)

    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 6)
    self.m_effectNode:setScale(self.m_machineRootScale)

    --过场动画
    self.m_changeSceneAni = util_spineCreate("LuckyRacing_guochang",true,true)
    self:findChild("root"):addChild(self.m_changeSceneAni,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 50)
    self.m_changeSceneAni:setVisible(false)

    --收集分数
    self.m_collectScore = util_createAnimation("LuckyRacing_JiangBei.csb")
    if self.m_isChangeScoreNode then
        self:findChild("jiangbei_0"):addChild(self.m_collectScore)
    else
        self:findChild("jiangbei"):addChild(self.m_collectScore)
    end
    
    self.m_collectScore:runCsbAction("idleframe",true)
    self.m_collectScore:findChild("Particle_1"):setVisible(false)
    self.m_collectScore.score = 0

    self.m_IDCard = util_createAnimation("LuckyRacing_IDcard.csb")
    self:findChild("IDcard"):addChild(self.m_IDCard)
    self.m_IDCard:runCsbAction("idleframe",true)

    self.m_hourse_small = util_createAnimation("LuckyRacing_touxiang_0.csb")
    self:findChild("touxiang"):addChild(self.m_hourse_small)

    --邮件按钮
    self.m_MailTip = util_createView("CodeLuckyRacingSrc.LuckyRacingMailTip",{machine = self})
    self:findChild("Mail"):addChild(self.m_MailTip)
    self.m_MailTip:setVisible(false)

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:findChild("IDcard"):addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    local size = self.m_IDCard:findChild("LuckyRacing_anniudi_9"):getContentSize()
    layout:setContentSize(CCSizeMake(size.width,size.height))
    layout:setTouchEnabled(true)
    layout:setTag(BTN_TAG_IDCARD)
    self:addClick(layout)

    --成就界面
    self.m_achievementView = util_createView("CodeLuckyRacingSrc.LuckyRacingAchievementView",{machine = self})
    self.m_achievementView:setVisible(false)
    self:findChild("root"):addChild(self.m_achievementView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 90)
    self.m_achievementView:setPosition(cc.p(-display.width / 2,-display.height / 2))
    -- self:setBaseVisible(false)

    --修改背景
    self:changBg("base")

    self:initLayerBlack()

    self:runCsbAction("idle",true)
end

--[[
    初始化黑色遮罩层
]]
function CodeGameScreenLuckyRacingMachine:initLayerBlack()

    local colorLayers = util_createReelMaskColorLayers( self ,REEL_SYMBOL_ORDER.REEL_ORDER_2 ,cc.c3b(0, 0, 0),130)
    self.m_layer_colors = colorLayers
    for key,layer in pairs(self.m_layer_colors) do
        layer:setVisible(false)
        util_setCascadeOpacityEnabledRescursion(layer, true)
    end
end

--[[
    显示黑色遮罩层
]]
function CodeGameScreenLuckyRacingMachine:showLayerBlack(isShow)
    if isShow then
        for key,layer in pairs(self.m_layer_colors) do
            layer:setOpacity(0)
            layer:runAction(cc.Sequence:create({
                cc.Show:create(),
                cc.FadeIn:create(0.2)
            }))
        end
    else
        for key,layer in pairs(self.m_layer_colors) do
            layer:runAction(cc.Sequence:create({
                cc.FadeOut:create(0.2),
                cc.Hide:create()
            }))
        end
    end
    
end

--默认按钮监听回调
function CodeGameScreenLuckyRacingMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:getGameSpinStage( ) > IDLE or self:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_isRunningEffect then
        return
    end

    if tag == BTN_TAG_IDCARD then
        self.m_achievementView:showView()
    end
end

--第一次进入本关卡初始化本关收集数据 如果数据格式不同子类重写这个方法
function CodeGameScreenLuckyRacingMachine:BaseMania_initCollectDataList()
    --收集数组
    self.m_collectDataList={}
    for i=1,4 do
        self.m_collectDataList[i]=CollectData.new()
        self.m_collectDataList[i].p_collectTotalCount=100
        self.m_collectDataList[i].p_collectLeftCount=100
        self.m_collectDataList[i].p_collectCoinsPool=0
        self.m_collectDataList[i].p_collectChangeCount=0
    end

end


function CodeGameScreenLuckyRacingMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound("LuckyRacingSounds/sound_LuckyRacing_enter_level.mp3")
        self:delayCallBack(3,function()
            if not self.m_curSelect or self.m_curSelect == -1 then
                return
            end
            local wins = self.m_roomData:getWinSpots()
            if wins and #wins > 0 then
                return
            end

            if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not self.m_bonusGameView:isVisible() then
                self:resetMusicBg()
                self:reelsDownDelaySetMusicBGVolume( ) 
            end
        end)

    end,0.4,self:getModuleName())
end

function CodeGameScreenLuckyRacingMachine:initGameStatusData(gameData)
    CodeGameScreenLuckyRacingMachine.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.extra then
        self.m_curSelect = gameData.gameConfig.extra.select
    end
end

function CodeGameScreenLuckyRacingMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    
    if self.m_initFeatureData and self.m_initFeatureData.p_data and self.m_initFeatureData.p_data.action == "BONUS" and 
    (not self.m_initFeatureData.p_data.status or self.m_initFeatureData.p_data.status ~= "CLOSED") then
        self:addBonusEffect()
    end
    self.m_isOnEnter = true
    CodeGameScreenLuckyRacingMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:updateSocre()

    --是否已经选过马
    if self.m_curSelect and self.m_curSelect ~= -1 then
        self:refreshIDCardBtn()

        self:resetCollectPercent()
        
        self:showOrHideMailTip()
        --重新刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
    elseif not self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
        --显示选马界面
        self:showChooseHourseView(function()
            self:resetMusicBg()
            self:reelsDownDelaySetMusicBGVolume( ) 
        end)

        --重置收集列表
        self:BaseMania_initCollectDataList()
        --刷新收集进度
        self:resetCollectPercent()
    end
    
    
end

--[[
    刷新成就按钮
]]
function CodeGameScreenLuckyRacingMachine:refreshIDCardBtn()
    for index = 1,4 do
        self.m_IDCard:findChild("sp_choose_"..index):setVisible(self.m_curSelect + 1 == index)
    end
end

--[[
    刷新当前选的马
]]
function CodeGameScreenLuckyRacingMachine:refreshCurHourse()
    if not self.m_curSelect or self.m_curSelect == -1 then
        return
    end
    for index = 1,4 do
        self.m_hourse_small:findChild("sp_hourse_"..index):setVisible(self.m_curSelect + 1 == index)
    end
end

function CodeGameScreenLuckyRacingMachine:addObservers()
    CodeGameScreenLuckyRacingMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self, params)
        self.m_achievementView:hideView()
    end,ViewEventType.NOTIFY_CLOSE_PIG_TIPS)

    --切换到后台
    gLobalNoticManager:addObserver(self,function(self, params)
        --记录切后台的时间
        self.m_timeInBack = os.time()
        self.m_bonusGameView:stopScrapeSound()
        if not self.m_bonusGameView.m_isAutoScrape and not tolua.isnull(self.m_bonusGameView.m_coin) then
            self.m_bonusGameView.m_coin:removeFromParent()
        end

    end,ViewEventType.APP_ENTER_BACKGROUND_EVENT)

    --切换到前台
    gLobalNoticManager:addObserver(self,function(self, params)

        --重置时间
        self.m_timeInBack = 0
    end,ViewEventType.APP_ENTER_FOREGROUND_EVENT)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

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
                self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 1, 1)
            end
        end
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenLuckyRacingMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenLuckyRacingMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    --需手动调用房间列表的退出方法,否则未加载完成退出游戏不会主动调用
    self.m_roomList:onExit()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenLuckyRacingMachine:showChooseHourseView(func)
    if self.m_chooseHourseView then
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    local view = util_createView("CodeLuckyRacingSrc.LuckyRacingChooseHouseView",{machine = self,callBack = function()
        self:resetCollectPercent()
        self.m_roomList:refreshPlayInfo()
        self:refreshIDCardBtn()
        self:updateSocre()
        self.m_chooseHourseView = nil
        if type(func) == "function" then
            func()
        end
    end})

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(view)

    self.m_chooseHourseView = view

    return view
end

--[[
    退出到大厅
]]
function CodeGameScreenLuckyRacingMachine:showOutGame( )

    if self.m_isShowOutGame then
        return
    end
    self.m_isShowOutGame = true
    local view = util_createView("CodeLuckyRacingSrc.LuckyRacingGameOut")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
end

--[[
    暂停轮盘
]]
function CodeGameScreenLuckyRacingMachine:pauseMachine()
    BaseMachine.pauseMachine(self)
    self.m_isShowSystemView = true
    --停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end

--[[
    恢复轮盘
]]
function CodeGameScreenLuckyRacingMachine:resumeMachine()
    BaseMachine.resumeMachine(self)
    self.m_isShowSystemView = false
    if self.m_isTriggerTeamMission then
        return
    end
    --重新刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
end

function CodeGameScreenLuckyRacingMachine:showOrHideMailTip()
    if self.m_isTriggerTeamMission then
        return
    end
    local wins = self.m_roomData:getWinSpots()
    if wins and #wins > 0 then
        if self.m_bEnterGame == true then
            self.m_MailTip:setClickEnable(false)
            self:openMail()
            self.m_isShowMail = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        else
            self.m_MailTip:setVisible(true)
            self.m_MailTip:setClickEnable(true)
            self.m_MailTip:runCsbAction("idle", true, nil, 60)
        end
    else
        self.m_MailTip:setVisible(false)
        self.m_MailTip:setClickEnable(false)
    end
end

--打开邮件
function CodeGameScreenLuckyRacingMachine:openMail()
    if self.m_MailTip then
        self.m_MailTip:setVisible(false)
        local mailTip = util_createView("CodeLuckyRacingSrc.LuckyRacingMailTip",{machine = self})
        mailTip:setClickEnable(false)
        self:findChild("Mail"):addChild(mailTip)
        local movePos = util_convertToNodeSpace(self:findChild("root"),self:findChild("Mail"))--cc.p(self:findChild("MailFlyNode"):getPosition())
        local delay = cc.DelayTime:create(64 / 60)
        local moveTo = cc.MoveTo:create(22 / 60, movePos)
        mailTip:runAction(cc.Sequence:create(delay, moveTo))
        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fly_mail.mp3")
        mailTip:runCsbAction(
            "actionframe",
            false,
            function()
                mailTip:removeFromParent()
            end,
            60
        )

        self:delayCallBack(110 / 60,function(  )
            self:showMailWinView()
        end)
    end
end

--[[
    获取邮件奖励
]]
function CodeGameScreenLuckyRacingMachine:showMailWinView()
    local winView = util_createView("CodeLuckyRacingSrc.LuckyRacingMailWin",{machine = self})
    local _winCoins = self.m_roomData:getMailWinCoins()
    winView:initViewData(_winCoins)
    -- winView:setPosition(display.width / 2,display.height / 2)
    --检测大赢
    -- self:checkFeatureOverTriggerBigWin(_winCoins, GameEffect.EFFECT_BONUS)

    winView:setFunc(
        function()
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                _winCoins, true, true
            })
            --为了播放大赢动画
            self:playGameEffect()

            self:resetMusicBg()
            self:reelsDownDelaySetMusicBGVolume( ) 
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            --重新刷新房间消息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
        end
    )
    gLobalViewManager:showUI(winView)

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_show_mail_win.mp3")

    --发送停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenLuckyRacingMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.Socre_LuckyRacing_MYSTERY then
        symbolType = self:getMysteryType(symbolType)
    end


    if symbolType == self.Socre_LuckyRacing_10 then
        return "Socre_LuckyRacing_10"
    end

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_LuckyRacing_Bonus"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenLuckyRacingMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenLuckyRacingMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenLuckyRacingMachine:MachineRule_initGame(  )

    
end

--[[
    重置收集进度
]]
function CodeGameScreenLuckyRacingMachine:resetCollectPercent()
    self:refreshCurHourse()
    --重置在上层信号列表
    self.m_configData.p_specialSymbolList = {self.m_curSelect,TAG_SYMBOL_TYPE.SYMBOL_SCATTER}
    local resultData = self.m_runSpinResultData
    
    local collectData = resultData.p_collectNetData

    for index = 1,4 do
        if collectData[index] then
            self.m_collectDataList[index]:parseCollectData(collectData[index])
        end
        local data = self.m_collectDataList[index]


        local percent = 1 - data.p_collectLeftCount / data.p_collectTotalCount
        if percent >= 1 then
            percent = 1
        end
        local startNode = self:findChild("horse_"..(index - 1))
        local endNode = self:findChild("qi_"..(index - 1))
        local startPos = cc.p(startNode:getPosition()) 
        local endPos = cc.p(endNode:getPosition())
        local distance = (endPos.x - startPos.x - 30) * percent
        self.m_hourses[index]:setPositionX(distance)

        self.m_hourses[index].m_spine:setSkin(SPINE_HOURSE_SKIN[5])
        endNode:getChildByName("qi_4"):setVisible(true)
        for iColor=1,4 do
            local node = self.m_hourses[index]:findChild("jiantou_"..(iColor - 1))
            if index == iColor and self.m_curSelect and iColor == self.m_curSelect + 1 then
                node:setVisible(true)
                self.m_hourses[index].m_spine:setSkin(SPINE_HOURSE_SKIN[index])
                endNode:getChildByName("qi_4"):setVisible(false)
            else
                node:setVisible(false)
            end
        end
    end
end

--[[
    图标执行收集动画
]]
function CodeGameScreenLuckyRacingMachine:runCollectAniBySymbol(symbolType,func)
    if symbolType ~= self.m_curSelect then
        return
    end
    local delayTime = 0
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == symbolType then
                delayTime = 20 / 60
                self.m_isHaveSelfCollect = true
                symbolNode:runAnim("shouji",false,function(  )
                    -- symbolNode:runAnim("idleframe",true)
                end)

                self:flyParticleAni2(symbolNode,self.m_hourses[symbolType + 1])

                --添加光效
                local light_ani = util_createAnimation("Socre_LuckyRacing_shouji.csb")
                symbolNode:addChild(light_ani,100)
                light_ani:runCsbAction("shouji",false,function()
                    light_ani:removeFromParent()
                end)
                for index = 1,4 do
                    light_ani:findChild("ef_shoujikuang_h"..index):setVisible(index == symbolType + 1)
                end
                
            end
        end
    end

    if delayTime > 0 then
        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_hourse_collect_fly.mp3")
        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_base_hourse_run.mp3") 
    end
    

    self:delayCallBack(delayTime,func)
end

--[[
    刷新收集进度
]]
function CodeGameScreenLuckyRacingMachine:refreshCollectPercent(index,func)
    if index > 4 then
        if self.m_isCollectOver then
            self:delayCallBack(2,func)
            
        else
            if self.m_isHaveSelfCollect then
                self:delayCallBack(0.5,func)
            else
                if type(func) == "function" then
                    func()
                end
            end
            
        end
        return
    end

    local resultData = self.m_runSpinResultData

    local collectData = resultData.p_collectNetData


    --是否有收集变化
    local isChanged = false
    if collectData[index] and collectData[index].collectChangeCount > 0 then
        isChanged = true
    end
    if collectData[index] then
        self.m_collectDataList[index]:parseCollectData(collectData[index])
    end

    if not isChanged then
        self:refreshCollectPercent(index + 1,func)
        return
    end

    local data = self.m_collectDataList[index]


    local percent = 1 - data.p_collectLeftCount / data.p_collectTotalCount
    if percent >= 1 then
        percent = 1
        self.m_isCollectOver = true
    end
    local startNode = self:findChild("horse_"..(index - 1))
    local endNode = self:findChild("qi_"..(index - 1))
    local startPos = cc.p(startNode:getPosition()) 
    local endPos = cc.p(endNode:getPosition())
    local distance = (endPos.x - startPos.x - 30) * percent

    local delayTime = 0.5

    if index == self.m_curSelect + 1 then
        self.m_hourses[index]:runCsbAction("shouji",false,function()
        
        end)
    end
    

    local spine = self.m_hourses[index].m_spine
    util_spinePlay(spine,"actionframe",true)
    local seq = cc.Sequence:create({
        cc.MoveTo:create(delayTime,cc.p(distance,0)),
        cc.CallFunc:create(function()
            util_spinePlay(spine,"idleframe",true)
            --到达终点
            if percent >= 1 then
                local ani = util_createAnimation("LuckyRacing_horse_zhongdian.csb")
                local node = self.m_hourses[index]:findChild("node_bao")
                node:addChild(ani)
                ani:runCsbAction("actionframe",false,function()
                    ani:removeFromParent()
                end)
                local selfData = self.m_runSpinResultData.p_selfMakeData
                if selfData.bonusType == "SIMPLE" then
                    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_collect_over_other.mp3")
                else
                    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_collect_over_me.mp3")
                end
            end

            
        end)
    })
    self.m_hourses[index]:runAction(seq)

    self:refreshCollectPercent(index + 1,func)

    
end

--
--单列滚动停止回调
--
function CodeGameScreenLuckyRacingMachine:slotOneReelDown(reelCol)    
    CodeGameScreenLuckyRacingMachine.super.slotOneReelDown(self,reelCol) 
    if reelCol == 1 then
        self:showLayerBlack(false)
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenLuckyRacingMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenLuckyRacingMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end

function CodeGameScreenLuckyRacingMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local bgNode =  self:findChild("bg")
    if bgNode  then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
    self.m_gameBgAnis = {}

    local Node_di = self.m_gameBg:findChild("Node_di")
    local Node_shu = self.m_gameBg:findChild("Node_shu")
    local Node_wu = self.m_gameBg:findChild("Node_wu")

    local ani1 = util_createAnimation("LuckyRacing/GameScreenLuckyRacingBg_di.csb")
    local ani2 = util_createAnimation("LuckyRacing/GameScreenLuckyRacingBg_shu.csb")
    local ani3 = util_createAnimation("LuckyRacing/GameScreenLuckyRacingBg_wu.csb")

    self.m_gameBgAnis[1] = gameBg
    self.m_gameBgAnis[2] = ani1
    self.m_gameBgAnis[3] = ani2
    self.m_gameBgAnis[4] = ani3

    for index = 1,4 do
        self.m_gameBgAnis[index]:runCsbAction("normal",true)
    end

    Node_di:addChild(ani1)
    Node_shu:addChild(ani2)
    Node_wu:addChild(ani3)


    self.m_gameBg_fs = util_createAnimation("LuckyRacing/GameScreenLuckyRacingBg_0.csb")
    if bgNode  then
        bgNode:addChild(self.m_gameBg_fs, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end

    self.m_gameBgAnis_fs = {}

    Node_di = self.m_gameBg_fs:findChild("Node_di")
    Node_shu = self.m_gameBg_fs:findChild("Node_shu")
    Node_wu = self.m_gameBg_fs:findChild("Node_wu")

    local ani4 = util_createAnimation("LuckyRacing/GameScreenLuckyRacingBg_di_0.csb")
    local ani5 = util_createAnimation("LuckyRacing/GameScreenLuckyRacingBg_shu_0.csb")
    local ani6 = util_createAnimation("LuckyRacing/GameScreenLuckyRacingBg_wu_0.csb")

    self.m_gameBgAnis_fs[1] = self.m_gameBg_fs
    self.m_gameBgAnis_fs[2] = ani4
    self.m_gameBgAnis_fs[3] = ani5
    self.m_gameBgAnis_fs[4] = ani6
    for index = 1,4 do
        self.m_gameBgAnis_fs[index]:runCsbAction("normal",true)
        
    end
    self.m_gameBg_fs:setVisible(false)

    Node_di:addChild(ani4)
    Node_shu:addChild(ani5)
    Node_wu:addChild(ani6)
end

--[[
    修改背景显示
]]
function CodeGameScreenLuckyRacingMachine:changBg(bgType)
    if bgType == "free" then
        self.m_gameBg:setVisible(false)
        self.m_gameBg_fs:setVisible(true)
    else
        self.m_gameBg:setVisible(true)
        self.m_gameBg_fs:setVisible(false)
    end
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenLuckyRacingMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("LuckyRacingSounds/music_LuckyRacing_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            showFreeSpinView()    
    end,0.5)

    

end

function CodeGameScreenLuckyRacingMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("LuckyRacingSounds/music_LuckyRacing_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenLuckyRacingMachine:MachineRule_SpinBtnCall()
    
    self.m_SSColSoundId = nil
    -- self:setMaxMusicBGVolume( )
    self.m_isTriggerTeamMission = false
    self.m_isCollectOver = false

    self.m_isOnEnter = false

    self.m_bEnterGame = false
    self.m_isHaveSelfCollect = false

    self.m_achievementView:hideView()

    self:showLayerBlack(true)

    self:setMaxMusicBGVolume( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    --将所有小块放回原来的节点
    self.m_effectNode:stopAllActions()
    local slotsParents = self.m_slotParents
    for key,symbol in pairs(self.m_nodes_scatter) do
        if symbol then
            local parentData = slotsParents[symbol.p_cloumnIndex]
            local slotParentBig = parentData.slotParentBig
            local pos = util_getOneGameReelsTarSpPos(self,tonumber(key))
            util_changeNodeParent(slotParentBig,symbol,self:getBounsScatterDataZorder(symbol.p_symbolType))
            symbol:setPosition(pos)
            self.m_nodes_scatter[key] = nil
        end
        
    end

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenLuckyRacingMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData

    local feature = self.m_runSpinResultData.p_features

    --检测是否触发bonus玩法
    self:checkTriggerBonus()
   

    --有玩家触发Bonus
    local result = self.m_roomData:getSpotResult()

    if result then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_EPICWIN + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUS_TRIGGER_EFFECT -- 动画类型
    end



    local reelData = self.m_runSpinResultData.p_reelsData
    if reelData then
        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
                if reelData[iRow][iCol] <= TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = self.COLLECT_HOURSE_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.COLLECT_HOURSE_EFFECT -- 动画类型
                    return
                end
            end
        end
    end

    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenLuckyRacingMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_HOURSE_EFFECT then

        
        self:runCollectAniBySymbol(self.m_curSelect,function()
            self:refreshCollectPercent(1,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
        
    elseif effectData.p_selfEffectType == self.COLLECT_SOCRE_EFFECT then
        local storedIcons = self.m_runSpinResultData.p_selfMakeData.positionScore

        local isPlay = false
        for id,score in pairs(storedIcons) do
            local pos = self:getRowAndColByPos(id)
            local iCol,iRow = pos.iY,pos.iX
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            
            if node and node.m_csbNode then
                -- node.m_csbNode:runCsbAction("shouji2",false,function ()
                --     node.m_csbNode:runCsbAction("idleframe")
                    
                -- end)

                local temp = util_createAnimation("Socre_LuckyRacing_Bonus_1.csb")
                node:addChild(temp)
                temp:runCsbAction("shouji2",false,function()
                    temp:removeFromParent()
                end)

                self:flyParticleAni(node.m_csbNode,self.m_collectScore,score,function()
                    
                    self.m_collectScore:runCsbAction("actionframe",false,function()
                        self.m_collectScore:runCsbAction("idleframe",true)
                    end)
                end)

                
                node:runAnim("shouji")
                isPlay = true
            end
            
        end

        if isPlay then
            gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_scatter_collect.mp3")
            self:delayCallBack(20 / 60,function()
                gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_scatter_collect_down.mp3")
            end)
        end
        

        self:delayCallBack(65 / 60,function()
            self:updateSocre()
        end)
        
        -- self:delayCallBack(0.7,function()
        --     effectData.p_isPlay = true
        --     self:playGameEffect()
        -- end)
        effectData.p_isPlay = true
        self:playGameEffect()
    elseif effectData.p_selfEffectType == self.BONUS_TRIGGER_EFFECT then    --触发动画
        self:delayCallBack(100 / 60,function()
            self:bonusTriggerAni(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
        
    elseif effectData.p_selfEffectType == self.TEAMMISSION_EFFECT then  --触发多人玩法
        self:playTeamMissionEffect(effectData,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.CHOOSE_HOURSE_EFFECT then --选马

        --显示选马界面
        self:showChooseHourseView(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    return true
end

--[[
    触发动画
]]
function CodeGameScreenLuckyRacingMachine:bonusTriggerAni(func)
    self:clearCurMusicBg()
    local result = self.m_roomData:getSpotResult()
    local triggerPlayer = result.data.triggerPlayer

    if triggerPlayer.udid ~= globalData.userRunData.userUdid then
        if type(func) == "function" then
            func()
        end
        return
    end

    local nodes = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolNode.preParent = symbolNode:getParent()
                local pos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
                util_changeNodeParent(self.m_effectNode,symbolNode)
                symbolNode:setPosition(pos)
                symbolNode:runAnim("actionframe",false,function()
                    
                end)
                nodes[#nodes + 1] = symbolNode
            end
        end
    end

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_scatter_trigger.mp3")

    
    self:delayCallBack(60 / 30,function()
        for k,symbolNode in pairs(nodes) do
            local pos = util_convertToNodeSpace(symbolNode,symbolNode.preParent)
            util_changeNodeParent(symbolNode.preParent,symbolNode,self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER))
            symbolNode:setPosition(pos)
        end
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    多人玩法
]]
function CodeGameScreenLuckyRacingMachine:playTeamMissionEffect(effectData,func)
    --结束回调
    local function endFunc()
        --变更轮盘状态
        if globalData.slotRunData.m_isAutoSpinAction then
            self:setCurrSpinMode(AUTO_SPIN_MODE)
        else
            self:setCurrSpinMode(NORMAL_SPIN_MODE)
        end

        --修改背景
        self:changBg("base")

        self.m_roomData.m_teamData.room.result = nil
        self:updateSocre()
        if self.m_isChangeScoreNode then
            util_changeNodeParent(self:findChild("jiangbei_0"),self.m_collectScore)
        else
            util_changeNodeParent(self:findChild("jiangbei"),self.m_collectScore)
        end
        
        self:setBaseVisible(true)


        --重置bonus触发状态
        self.m_isTriggerTeamMission = false

        --重新刷新房间数据
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)

        if type(func) == "function" then
            func()
        end
    end

    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    local triggerPlayer = effectData.resultData.data.triggerPlayer
    self.m_roomList:playTriggerAni(triggerPlayer.udid,function()
        self:delayCallBack(1.5,function()
            self:setBaseVisible(false)
            if self.m_isChangeScoreNode then
                util_changeNodeParent(self.m_freeGameView:findChild("jiangbei_0"),self.m_collectScore)
            else
                util_changeNodeParent(self.m_freeGameView:findChild("jiangbei"),self.m_collectScore)
            end
            
            self.m_freeGameView:setVisible(true)
            --修改背景
            self:changBg("free")
        end)
        self.m_bottomUI:updateWinCount("")
        self.m_freeGameView:initViewInfo(effectData.resultData)
        self:teamMissionChangeSceneAni(function()
            self:teamMissionStart(function()
                
                self:changeSceneAni(function()
                    self:resetMusicBg(true,"LuckyRacingSounds/music_LuckyRacing_free.mp3")
                    self.m_freeGameView:startGame(endFunc)
                end)
            end)
        end)
    end)
end

--[[
    多人玩法过场动画
]]
function CodeGameScreenLuckyRacingMachine:teamMissionChangeSceneAni(func)
    self.m_changeSceneAni:setVisible(true)
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_change_scene.mp3")
    util_spinePlay(self.m_changeSceneAni,"actionframe")
    util_spineEndCallFunc(self.m_changeSceneAni,"actionframe",handler(nil,function(  )
        if type(func) == "function" then
            func()
        end
        self.m_changeSceneAni:setVisible(false)
    end))
end

--[[
    多人玩法开始弹版
]]
function CodeGameScreenLuckyRacingMachine:teamMissionStart(func)
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_teammission_start.mp3")
    local view = self:showDialog("XuanRen")
    view:findChild("root"):setScale(self.m_machineRootScale)

    local playersInfo = clone(self.m_roomData:getRoomPlayersInfo())

    --当前选的马
    local curChoose = self.m_curSelect
    if not curChoose or curChoose == -1 then
        curChoose = 0
    end

    --将自己放在对应颜色的座位上
    for index = 1,4 do
        local info = playersInfo[index]
        if info and info.udid == globalData.userRunData.userUdid and index ~= curChoose + 1 then
            local temp = playersInfo[index]
            playersInfo[index] = playersInfo[curChoose + 1]
            playersInfo[curChoose + 1] = temp
            break
        end
    end

    for index = 1,4 do
        local node = view:findChild("Node_piaodai_"..(index - 1))
        local node_head = node:getChildByName("touxiang")

        if curChoose + 1 == index then
            local jiantou = util_createAnimation("LuckyRacing_xuanzekuang.csb")
            node_head:addChild(jiantou)
            node_head:setScale(0.9)
            view:findChild("sp_light_"..index):setVisible(true)

            local node_piaodai = view:findChild("Node_piaodai_"..(index - 1))
            node_piaodai:setScale(1.1)
        else
            view:findChild("sp_light_"..index):setVisible(false)
            node_head:setScale(0.75)

            local node_piaodai = view:findChild("Node_piaodai_"..(index - 1))
            node_piaodai:setScale(1)
        end

        local item = util_createView("CodeLuckyRacingSrc.LuckyRacingPlayerHead",{index = index})
        node_head:addChild(item)
        --刷新头像
        item:refreshData(playersInfo[index])
        item:refreshHead(true)
    end

    self:delayCallBack(2,function()
        view:runCsbAction("over",false,function()
            view:removeFromParent()
            if type(func) == "function" then
                func()
            end
        end)
    end)
end

--[[
    刷新分数
]]
function CodeGameScreenLuckyRacingMachine:updateSocre(addScore)
    local score = 0
    if not addScore then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        score = self.m_roomData.m_teamData.room.extra.score or 0
        local result = self.m_roomData:getSpotResult()
        if result then
            score = result.data.userScore[globalData.userRunData.userUdid]
        end
    else
        score = self.m_collectScore.score + addScore
    end

    local lbl_score = self.m_collectScore:findChild("BitmapFontLabel_1")
    lbl_score:setString(util_formatCoins(score, 4))
    self.m_collectScore.score = score
    local info={label = lbl_score,sx = 0.32,sy = 0.32}
    self:updateLabelSize(info,302)
    
end

--[[
    刷新小块
]]
function CodeGameScreenLuckyRacingMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType    --信号类型
    local reelNode = node
    if symbolType and symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then    --Bouns信号
        if not node.m_csbNode then
            local csbNode = util_createAnimation("Socre_LuckyRacing_Bonus_1.csb")
            node.m_csbNode = csbNode
            node:addChild(csbNode,100)
        end
        node.m_csbNode:setVisible(true)
        self:setSpecialNodeScore(node)
    else
        if node.m_csbNode then
            node.m_csbNode:setVisible(false)
        end
    end
end

--[[
    设置特殊小块分数
]]
function CodeGameScreenLuckyRacingMachine:setSpecialNodeScore(node)
    local symbolNode = node
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score = 1
    --判断是否为真实数据
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        local selfData = self.m_runSpinResultData.p_selfMakeData
        --获取真实分数
        local storedIcons = selfData.positionScore
        if storedIcons and next(storedIcons) then
            score = self:getSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) or 1
            
        end
        
    else
        --设置假滚Bonus,随机分数
        score = 0.002--self:randomDownSymbolScore(symbolNode.p_symbolType)
        if score == nil then
            score = 1
        end
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
    end

    if score == 1 then
        score = score * globalData.slotRunData:getCurTotalBet()
    end

    if score and type(score) ~= "string" then
        -- --格式化字符串
        score = util_formatCoins(score, 3)
        if symbolNode then
            local lbl_score = symbolNode.m_csbNode:findChild("font")
            if lbl_score then
                lbl_score:setString(score)
                self:updateLabelSize({label=lbl_score,sx=1,sy=1},186)
            end
        end
    end
end

--[[
    获取小块真实分数
]]
function CodeGameScreenLuckyRacingMachine:getSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.positionScore

    return storedIcons[tostring(id)]
end

--[[
    随机bonus分数
]]
function CodeGameScreenLuckyRacingMachine:randomDownSymbolScore(symbolType)
    local score = nil
    
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        score = self.m_configData:getBnBasePro(1)
    end

    return score
end


--[[
    检测是否触发bonus
]]
function CodeGameScreenLuckyRacingMachine:checkTriggerBonus()

    --检测是否已经添加过bonus,防止刷新数据时导致二次添加
    for k,gameEffect in pairs(self.m_gameEffects) do
        if gameEffect and gameEffect.p_effectType == GameEffect.EFFECT_SELF_EFFECT
        and gameEffect.p_selfEffectType == self.TEAMMISSION_EFFECT then
            return true
        end
    end
    
    --有玩家触发Bonus
    local result = self.m_roomData:getSpotResult()

    --测试代码
    -- local fileUtil = cc.FileUtils:getInstance()
    -- local fullPath = fileUtil:fullPathForFilename("CodeLuckyRacingSrc/resultData.json")
    -- local jsonStr = fileUtil:getStringFromFile(fullPath) 
    -- local result = cjson.decode(jsonStr)

    if result then
        --发送停止刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
        self:addTeamMissionEffect(result)
        return true
    end

    return false
end

--[[
    添加Bonus玩法
]]
function CodeGameScreenLuckyRacingMachine:addTeamMissionEffect(result)
    self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = GameEffect.EFFECT_EPICWIN + 2
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.TEAMMISSION_EFFECT -- 动画类型
    selfEffect.resultData = clone(result)

    self.m_isTriggerTeamMission = true
end

--[[
    添加Bonus玩法
]]
function CodeGameScreenLuckyRacingMachine:addBonusEffect()

    self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_CHOOSE_SET_VISIBLE, {isShow = false})

    local effect = GameEffectData.new()
    effect.p_effectType = GameEffect.EFFECT_BONUS
    effect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = effect
end


--[[
    Bonus玩法
]]
function CodeGameScreenLuckyRacingMachine:showEffect_Bonus(effectData)
    

    local function endFunc()
        
        --重置收集列表
        self:BaseMania_initCollectDataList()
        self.m_runSpinResultData.p_collectNetData = {}

        self.m_bottomUI:hideAverageBet()

        --刷新收集进度
        self:resetCollectPercent()

        self:setCurrSpinMode(NORMAL_SPIN_MODE)

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_EPICWIN + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CHOOSE_HOURSE_EFFECT -- 动画类型

        effectData.p_isPlay = true
        self:playGameEffect()
    end

    local winner = 1
    for index = 1,4 do
        local data = self.m_collectDataList[index]


        local percent = 1 - data.p_collectLeftCount / data.p_collectTotalCount
        if percent >= 1 then
            winner = index
            break
        end
    end
    
    self:clearCurMusicBg()
    self.m_curSelect = nil
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_bonusGameView:setEndCallFunc(endFunc)
    self.m_bottomUI:showAverageBet()
    if selfData.bonusType == "SIMPLE" then
        self.m_bonusGameView.m_isCanRecMsg = true
        self.m_bonusGameView.m_isWalkAway = true
        self.m_bonusGameView:sendData()
        self.m_bottomUI:updateWinCount("")
    else
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        self:showWinnerView(winner,function()
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
            self.m_bottomUI:updateWinCount("")
            self.m_bonusGameView:showView()
            self:setBaseVisible(false)
            self:resetMusicBg(true,"LuckyRacingSounds/music_LuckyRacing_bonus.mp3")
        end)
        
    end
    
    

    --停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
    --触发bonus需要退出房间
    self.m_roomList:sendLogOutRoom()
    
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenLuckyRacingMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenLuckyRacingMachine:slotReelDown( )


    self:setMaxMusicBGVolume( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.m_roomList:refreshPlayInfo()
    --其他玩家大赢事件
    local eventData = self.m_roomData:getRoomEvent()
    self.m_roomList:showBigWinAni(eventData)


    CodeGameScreenLuckyRacingMachine.super.slotReelDown(self)
end

--[[
    延迟回调
]]
function CodeGameScreenLuckyRacingMachine:delayCallBack(time, func)
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

--[[
    显示玩法赢钱弹版 freegame用
]] 
function CodeGameScreenLuckyRacingMachine:showWinCoinsView(avgbet,mutiples,coins,func)
    local view = self:showDialog("Congratulations_2",nil,func)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view.m_allowClick = false
    view:stopAllActions()
    self:delayCallBack(1,function()
        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_multiply.mp3")
        view:runCsbAction("actionframe",false,function()
            view.m_allowClick = true
            view:showidle()
        end)
    end)

    view:findChild("font_0_0"):setString(mutiples)
    view:findChild("font_0_1"):setString(util_formatCoins(avgbet,3))
    view:findChild("BitmapFontLabel_3"):setString(util_formatCoins(coins,50))
    view:updateLabelSize({label=view:findChild("BitmapFontLabel_3"),sx=1,sy=1},665)
    view:updateLabelSize({label=view:findChild("font_0_1"),sx=1,sy=1},226)

    return view
end

--[[
    显示玩法赢钱弹版 bonus玩法用
]]
function CodeGameScreenLuckyRacingMachine:showWinCoinsViewForBonus(avgbet,mutiples,coins,func)
    local view=util_createView("Levels.BaseDialog")
    view:initViewData(self,"Congratulations_1",func)
    

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    self:findChild("root"):addChild(view,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 101)
    view:setPosition(cc.p(-display.width / 2,-display.height / 2))

    view.m_allowClick = false
    view:stopAllActions()
    self:delayCallBack(1,function()
        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_multiply.mp3")
        view:runCsbAction("actionframe",false,function()
            view.m_allowClick = true
            view:showidle()
        end)
    end)

    view:findChild("font_0_0"):setString(mutiples)
    view:findChild("font_0_1"):setString(util_formatCoins(avgbet,3))
    view:findChild("BitmapFontLabel_3"):setString(util_formatCoins(coins,50))
    view:updateLabelSize({label=view:findChild("BitmapFontLabel_3"),sx=1,sy=1},665)
    view:updateLabelSize({label=view:findChild("font_0_1"),sx=1,sy=1},226)

    return view
end

--[[
    显示玩法赢钱弹版
]]
function CodeGameScreenLuckyRacingMachine:showWinCoinsViewWithOutMultiples(coins,func)
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_show_win_coins_view_without_multiples.mp3")
    local view = self:showDialog("Congratulations_0",nil,func)
    view:findChild("root"):setScale(self.m_machineRootScale)

    view:findChild("BitmapFontLabel_3"):setString(util_formatCoins(coins,50))
    view:updateLabelSize({label=view:findChild("BitmapFontLabel_3"),sx=1,sy=1},665)

    local light = util_createAnimation("LuckyRacing/WinnerTakeAll_guang.csb")
    light:runCsbAction("idle")
    view:findChild("Node_guang"):addChild(light)

    return view
end


--[[
    显示基础轮盘
]]
function CodeGameScreenLuckyRacingMachine:setBaseVisible(isShow)
    self:findChild("qipanBg"):setVisible(isShow)
    self:findChild("Node_reel"):setVisible(isShow)
    self:findChild("qi_0"):setVisible(isShow)
    self:findChild("qi_1"):setVisible(isShow)
    self:findChild("qi_2"):setVisible(isShow)
    self:findChild("qi_3"):setVisible(isShow)
    self:findChild("IDcard"):setVisible(isShow)
    self:findChild("ChangeRoom"):setVisible(isShow)
    self:findChild("horse_3"):setVisible(isShow)
    self:findChild("horse_2"):setVisible(isShow)
    self:findChild("horse_1"):setVisible(isShow)
    self:findChild("horse_0"):setVisible(isShow)
    self:findChild("jiangbei"):setVisible(isShow)
    self:findChild("jiangbei_0"):setVisible(isShow)
end


----
--- 处理spin 成功消息
--
function CodeGameScreenLuckyRacingMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]
    if spinData.action == "SPIN" then
        release_print("消息返回胡来了")
        print(cjson.encode(spinData)) 

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        
        self:updateNetWorkData()

        if spinData.action == "SPIN" then

            performWithDelay(self,function(  )
                self:lockSymbol()
            end,0.5)

        end
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

--[[
    锁定滚动小块
]]
function CodeGameScreenLuckyRacingMachine:lockSymbol()
    for k,parentData in pairs(self.m_slotParents) do
        parentData.lockSymbol = self:getColIsSameSymbol(parentData.cloumnIndex)
    end
end

--随机信号
function CodeGameScreenLuckyRacingMachine:getReelSymbolType(parentData)
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end

    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
    end

    --判断小块是否已被锁定
    if parentData.lockSymbol and parentData.lockSymbol ~= -1 then
        symbolType = parentData.lockSymbol
    end

    
    return symbolType
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenLuckyRacingMachine:checkUpdateReelDatas(parentData )
    
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    parentData.lockSymbol = self:getColIsSameSymbol(parentData.cloumnIndex)

    return reelDatas

end

--[[
    判断该列整列信号是否相同
]]
function CodeGameScreenLuckyRacingMachine:getColIsSameSymbol(iCol)
    local reelsData = self.m_runSpinResultData.p_reels
    local symbolType = -1
    if reelsData and next(reelsData) then
        for iRow = 1,self.m_iReelRowNum do
            if symbolType ~= -1 and symbolType ~= reelsData[iRow][iCol] then
                return -1
            end

            symbolType = reelsData[iRow][iCol]
        end
    end

    return symbolType
end


--增加提示节点
function CodeGameScreenLuckyRacingMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then

            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)
            
            if self:checkSymbolTypePlayTipAnima( slotNode.p_symbolType )then
                
                tipSlotNoes[#tipSlotNoes + 1] = slotNode
            end
        end
    end
    return tipSlotNoes
end

--播放提示动画
function CodeGameScreenLuckyRacingMachine:playReelDownTipNode(slotNode)

    if slotNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return
    end

    self:playScatterBonusSound(slotNode)

    --播落地动画需要提升层级

    --转化坐标
    local index = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
    local pos = util_getOneGameReelsTarSpPos(self,index) 
    local worldPos = self.m_clipParent:convertToWorldSpace(pos)
    local nodePos = self.m_effectNode:convertToNodeSpace(worldPos)
    util_changeNodeParent(self.m_effectNode,slotNode)
    slotNode:setPosition(nodePos)

    self.m_nodes_scatter[tostring(index)] = slotNode

    slotNode:runAnim("buling",false,function()
        self:runCollectScoreAniBySingle(slotNode,function()
            
        end)
        
        
    end)
    if slotNode.m_csbNode then
        slotNode.m_csbNode:runCsbAction("buling")
    end
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end

--[[
    播放收集动画(单个收集)
]]
function CodeGameScreenLuckyRacingMachine:runCollectScoreAniBySingle(symbolNode,func)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.positionScore

    if not storedIcons then
        if type(func) == "function" then
            func()
        end
        return
    end

    local index = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
    local score = storedIcons[tostring(index)]

    if symbolNode and symbolNode.m_csbNode then
        self:flyParticleAni(symbolNode.m_csbNode,self.m_collectScore,score,function()
            if self.m_SSColSoundId then
                gLobalSoundManager:stopAudio(self.m_SSColSoundId)
            end
            self.m_SSColSoundId = gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_scatter_collect_down.mp3")
            self.m_collectScore:findChild("Particle_1"):setVisible(true)
            self.m_collectScore:findChild("Particle_1"):resetSystem()
            self.m_collectScore:runCsbAction("actionframe",false,function()
                self.m_collectScore:runCsbAction("idleframe",true)
            end)
        end)

        -- gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_scatter_collect.mp3")
        local slotsParents = self.m_slotParents
        local parentData = slotsParents[symbolNode.p_cloumnIndex]
        local slotParentBig = parentData.slotParentBig
        local index = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        local pos = util_convertToNodeSpace(symbolNode,slotParentBig)
        util_changeNodeParent(slotParentBig,symbolNode,self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER))
        symbolNode:setPosition(pos)
        self.m_nodes_scatter[tostring(index)] = nil

        if type(func) == "function" then
            func()
        end
    end

    self:delayCallBack(30 / 60,function()
        self:updateSocre(score)
    end)
end

--[[
    飞粒子动画
]]
function CodeGameScreenLuckyRacingMachine:flyParticleAni2(startNode,endNode,func)
    local ani = util_createAnimation("LuckyRacing_shouji_tuowei.csb")
    for index = 1,6 do
        ani:findChild("Particle_"..index):setPositionType(0)
        ani:findChild("Particle_"..index):setDuration(-1)
    end
    self.m_effectNode:addChild(ani)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    ani:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.BezierTo:create(20 / 60,{startPos, cc.p(endPos.x, startPos.y), endPos}),
        cc.CallFunc:create(function(  )
            for index = 1,6 do
                ani:findChild("Particle_"..index):stopSystem()
            end
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })
    
    ani:runAction(seq)
    
end

--[[
    飞粒子动画
]]
function CodeGameScreenLuckyRacingMachine:flyParticleAni(startNode,endNode,score,func)
    local ani = util_createAnimation("Socre_LuckyRacing_Bonus_1.csb")
    local lizi = ani:findChild("ef_lizi")
    if lizi then
        lizi:setPositionType(0)
        lizi:setDuration(-1)
    end
    

    ani:findChild("font"):setString(util_formatCoins(score, 3))
    ani:setScale(startNode:getScale())
    self.m_effectNode:addChild(ani)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    ani:setPosition(startPos)

    

    ani:runCsbAction("shouji")

    local seq = cc.Sequence:create({
        cc.DelayTime:create(9 / 60),
        cc.BezierTo:create(21 / 60,{startPos, cc.p(startPos.x, endPos.y), endPos}),
        cc.CallFunc:create(function(  )
            local lizi = ani:findChild("ef_lizi")
            if lizi then
                lizi:stopSystem()
            end
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_scatter_collect_fly.mp3")
    ani:runAction(seq)
    
end

--[[
    过场动画
]]
function CodeGameScreenLuckyRacingMachine:changeSceneAni(func)
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_winner_take_all.mp3")
    local view = self:showDialog("WinnerTakeAll_0")
    view:setScale(self.m_machineRootScale)
    local spine = util_spineCreate(SPINE_CHANGE_SCENE[self.m_curSelect + 1],true,true)
    view:addChild(spine)
    spine:setPosition(cc.p(display.width / 2,display.height / 2))
    util_spinePlay(spine,"actionframe",false)
    util_spineFrameCallFunc(spine,"actionframe","Show",function(  )
        view:runCsbAction("over",false,function()
            self:delayCallBack(0.5,function()
                view:removeFromParent()
            end)
        end)
    end)

    self:delayCallBack(80 / 30,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示赢家弹版动画
]]
function CodeGameScreenLuckyRacingMachine:showWinnerView(winner,func)
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_show_winner_hourse_view.mp3")
    local spine = util_spineCreate(SPINE_WINNER_ANI[winner],true,true)

    local view = util_createAnimation("LuckyRacing/GuoChangKuang.csb")
    view:findChild("node_spine"):setScale(self.m_machineRootScale)

    view:findChild("node_spine"):addChild(spine)
    
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(view)

    view:runCsbAction("actionframe",false,function()
        view:runCsbAction("idle")
    end)
    util_spinePlay(spine,"actionframe",false)
    util_spineEndCallFunc(spine,"actionframe",handler(nil,function(  )
        if type(func) == "function" then
            func()
        end
        
        self:delayCallBack(0.5,function()
            view:removeFromParent()
            view = nil
        end)
    end))

    self:delayCallBack(75 / 30,function()
        if view then
            view:runCsbAction("over",false,function()
                view:setVisible(false)
            end)
        end
    end)

    -- 框
    local kuangSpine = util_spineCreateDifferentPath("GuoChangKuang_kuang", "GuoChangKuang_bg", true, true)
    view:findChild("node_spine"):addChild(kuangSpine,1)
    util_spinePlay(kuangSpine,"actionframe",false)

    -- bg
    local kuangBgSpine = util_spineCreateDifferentPath("GuoChangKuang_bg", "GuoChangKuang_bg", true, true)
    view:findChild("node_spine"):addChild(kuangBgSpine,-1)
    util_spinePlay(kuangBgSpine,"actionframe",false)

end

---
-- 进入关卡
--
function CodeGameScreenLuckyRacingMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect,isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end
    
    if isPlayGameEffect or (#self.m_gameEffects > 0 and not self.m_isRunningEffect) then
        self:sortGameEffects( )
        self:playGameEffect()
    end
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenLuckyRacingMachine:operaEffectOver(  )

    CodeGameScreenLuckyRacingMachine.super.operaEffectOver(self)
end

function CodeGameScreenLuckyRacingMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1
    self.m_freeScale = 1
    self.m_isChangeScoreNode = false

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        local offsetY = 10
        local ratio = display.height / display.width
        if ratio >= 768 / 1024 then
            -- mainScale = 0.8
            self.m_freeScale = 0.95
            self.m_isChangeScoreNode = true
        elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
            -- mainScale = 0.9
            self.m_freeScale = 0.95
            self.m_isChangeScoreNode = true
        elseif ratio < 640 / 960 and ratio >= 768 / 1228 then
            -- mainScale = 0.94
            self.m_freeScale = 0.95
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + offsetY)
    end

end


function CodeGameScreenLuckyRacingMachine:getReelWidth()
    --宽高比小于16:10的类方屏尺寸,轮盘要放大
    if display.height < DESIGN_SIZE.width then
        return 1260
    end

end

---
-- 从参考的假数据中获取数据
--
function CodeGameScreenLuckyRacingMachine:getRandomReelType(colIndex, reelDatas)
    if reelDatas == nil or #reelDatas == 0 then
        return self:getNormalSymbol(colIndex)
    end
    local reelLen = #reelDatas

    if self.m_randomSymbolSwitch then
        -- 根据滚轮真实假滚数据初始化轮子信号小块
        if self.m_randomSymbolIndex == nil then
            self.m_randomSymbolIndex = util_random(1, reelLen)
        end
        self.m_randomSymbolIndex = self.m_randomSymbolIndex + 1
        if self.m_randomSymbolIndex > reelLen then
            self.m_randomSymbolIndex = 1
        end

        local symbolType = reelDatas[self.m_randomSymbolIndex]
        symbolType = self:getMysteryType(symbolType)
        return symbolType
    else
        while true do
            local symbolType = reelDatas[util_random(1, reelLen)]
            symbolType = self:getMysteryType(symbolType)
            return symbolType
        end
    end

    return nil
end

function CodeGameScreenLuckyRacingMachine:getMysteryType(symbolType)
    if symbolType == self.Socre_LuckyRacing_MYSTERY then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.mysterySignal then
            symbolType = selfData.mysterySignal
        else
            symbolType = 0
        end
    end
    return symbolType
end

function CodeGameScreenLuckyRacingMachine:getAnimNodeFromPool(symbolType, ccbName)
    if not symbolType then
        release_print(debug.traceback())
        release_print("sever传回的数据：  " .. (globalData.slotRunData.severGameJsonData or "isnil"))
        release_print(
            "error_userInfo_ udid=" ..
                (globalData.userRunData.userUdid or "isnil") .. " machineName=" .. (globalData.slotRunData.gameModuleName or "isLobby") .. " gameSeqID = " .. (globalData.seqId or "")
        )
        release_print("AnimNodeFromPool error not symbolType!!!    ccbName:" .. ccbName)
        return nil
    end

    symbolType = self:getMysteryType(symbolType)

    if ccbName == nil then
        ccbName = self:getSymbolCCBNameByType(self, symbolType)
    end

    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}
        self.m_reelAnimNodePool[symbolType] = reelPool
    end

    if #reelPool == 0 then
        -- 扩展支持 spine 的元素
        local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
        local node = nil
        if spineSymbolData ~= nil then
            node = SlotsSpineAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:initSpineInfo(spineSymbolData[1], spineSymbolData[2])
            node:runDefaultAnim()
        else
            node = SlotsAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:runDefaultAnim()
        end

        return node
    else
        local node = reelPool[1] -- 存内存池取出来
        table.remove(reelPool, 1)
        node:runDefaultAnim()

        -- print("从尺子里面拿 SlotsAnimNode")

        return node
    end
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenLuckyRacingMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = "LuckyRacingSounds/sound_LuckyRacing_scatter_tip.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenLuckyRacingMachine:playEffectNotifyNextSpinCall()
    CodeGameScreenLuckyRacingMachine.super.playEffectNotifyNextSpinCall(self)

    if self.m_isOnEnter then
        self.m_isOnEnter = false
        return
    end

    self:resetMusicBg()
    self:setMaxMusicBGVolume( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    
end


return CodeGameScreenLuckyRacingMachine






