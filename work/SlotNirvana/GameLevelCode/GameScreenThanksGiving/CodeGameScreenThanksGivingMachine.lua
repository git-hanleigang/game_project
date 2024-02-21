
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenThanksGivingMachine = class("CodeGameScreenThanksGivingMachine", BaseNewReelMachine)

CodeGameScreenThanksGivingMachine.SYMBOL_SCORE_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3

CodeGameScreenThanksGivingMachine.SPINDROPWILDSYMBOLCHANGEWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 17--将spin落下wild列的图标变为wild
CodeGameScreenThanksGivingMachine.NORMALSCATTERADDWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 16--normal下出scatter增加wild效果
CodeGameScreenThanksGivingMachine.NORMALBONUSRANDOM_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 15--normal下出bonus随机选择增加wild列数的随机效果
CodeGameScreenThanksGivingMachine.DROPWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 13--wild下落
CodeGameScreenThanksGivingMachine.DROPWILDSYMBOLCHANGEWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 12--轮盘停止后有下落wild的话将下落列图标变为wild
CodeGameScreenThanksGivingMachine.REMOVEDROPEDWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 11--删除下落的wild
CodeGameScreenThanksGivingMachine.COLLECTBONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10--bonus收集
CodeGameScreenThanksGivingMachine.FREESPINUPDATEWILDBARWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 9--freespin下更新wild条上的wild

-- 构造函数
function CodeGameScreenThanksGivingMachine:ctor()
    CodeGameScreenThanksGivingMachine.super.ctor(self)
    self.m_reelIsruning = false--轮盘是否转动
    self.m_wildBarFullNum = 8--wild条上最大wild数量
    self.m_randomNum = 0--bonus出现随机wild条的次数
    self.m_clipBonus = {}--存储提高层级的bonus图标
    self.m_clipScatter = {}--存储提高层级的scatter图标
    self.m_wildBarBgTab = {}--wild条下的半透明底对象数组
    self.m_wildTab = {{},{},{},{},{}}--wild条上的wild图标存储
    self.m_dropedWildTab = {{},{},{},{},{}}--掉落到盘面上的wild图标
    self.m_baseWildData = {} -- 存储的所有bet的数据
    self.m_isFeatureOverBigWinInFree = true
	--init
    self:initGame()
end

function CodeGameScreenThanksGivingMachine:initGame()
	--初始化基本数据
	self:initMachine(self.m_moduleName)
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenThanksGivingMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ThanksGiving"
end
function CodeGameScreenThanksGivingMachine:getBottomUINode()
    return "CodeThanksGivingSrc.ThanksGivingBoottomUiView"
end
function CodeGameScreenThanksGivingMachine:initUI()
    self.m_reelRunSound = "ThanksGivingSounds/music_ThanksGiving_quick_run.mp3"--快滚音效
    --背景适配
    self.m_gameBg:setPosition(cc.p(self:findChild("root"):getPosition()))
    self.m_gameBg:setScale(self.m_machineRootScale)
    self.m_gameBg:runCsbAction("day",false)
    self.m_bgCloud = util_createAnimation("GameScreenThanksGivingBg1.csb")
    self.m_gameBg:findChild("GameScreenThanksGivingBg"):addChild(self.m_bgCloud)
    self.m_bgCloud:playAction("idleframe",true)
    util_setCascadeOpacityEnabledRescursion(self.m_gameBg,true)
    self:initFreeSpinBar()
    --添加jackpot条
    self.m_jackpotBar = util_createView("CodeThanksGivingSrc.ThanksGivingJackPotBarView")
    self:findChild("jackpotNode"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)
    --添加freespinbar
    self.m_freespinBar = util_createView("CodeThanksGivingSrc.ThanksGivingFreespinBarView")
    self:findChild("freespinNode"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)
    --添加提示字
    self.m_tishiBar = util_createAnimation("ThanksGiving_tishitiao_2.csb")
    self:findChild("ThanksGiving_tishitiao"):addChild(self.m_tishiBar)
    self.m_tishiBar.currShowId = 1--当前显示的id
    self.m_tishiBar.totalId = 2--总共可显示的个数
    --添加收集进度条
    self.m_collectProgress = util_createAnimation("ThanksGiving_jishouji.csb")
    self:findChild("ThanksGiving_jishouji"):addChild(self.m_collectProgress)
    --添加进度条上的螃蟹(后来知道是火鸡，就不改了)
    self.m_collectProgressCrab = util_spineCreate("ThanksGiving_jindutiao_Juese",true,true)
    self.m_collectProgress:findChild("jiNode"):addChild(self.m_collectProgressCrab,-1)
    util_spinePlay(self.m_collectProgressCrab,"idleframe",true)
    self.m_collectProgressCrab:setPositionY(17)

    --添加倍数条
    self.m_multipleBar = util_createAnimation("ThanksGiving_anniu.csb")
    self:findChild("multipleNode"):addChild(self.m_multipleBar)
    self.m_multipleBar:setVisible(false)
    --添加轮盘上的半透明遮罩
    self.m_reelTranslucentMask = util_createAnimation("GameScreenThanksGiving_reelan.csb")
    self:findChild("ThanksGiving_reel_an"):addChild(self.m_reelTranslucentMask)
    self.m_reelTranslucentMask:setVisible(false)
    --添加wild条上的半透明底
    for i = 1,5 do
        local wildBarBg = util_createAnimation("GameScreenThanksGiving_an.csb")
        self:findChild("reel_an"..i):addChild(wildBarBg,10)
        table.insert(self.m_wildBarBgTab,wildBarBg)
        wildBarBg.isShow = false--这个背景是否显示了
    end
    --添加过场
    self.m_guochang = util_spineCreate("ThanksGiving_Jackpot_Juese",true,true)
    self:findChild("bonusLayer"):addChild(self.m_guochang)
    self.m_guochang:setVisible(false)
    self:findChild("bonusLayer"):setLocalZOrder(100001)
    --添加过场背景
    self.m_guochangBg = util_createAnimation("ThanksGiving/GameScreenThanksGivingGuochangBg.csb")
    self.m_guochang:addChild(self.m_guochangBg,-1)
    --隐藏轮盘边框扫光
    self:hideReelLight()

    --添加蝴蝶
    self.m_butterfly = util_spineCreate("GameScreenThanksGivingBg2",true,true)
    self:findChild("hudieNode"):addChild(self.m_butterfly)
    util_spinePlay(self.m_butterfly,"idleframe",true)
end
--适配
function CodeGameScreenThanksGivingMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize() --h 120
    local uiBW, uiBH = self.m_bottomUI:getUISize()  --h 180
    --看资源实际的高度
    uiH = 120
    uiBH = 180

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1

    if display.height/display.width == DESIGN_SIZE.height/DESIGN_SIZE.width then
        --设计尺寸屏

    elseif display.height/display.width > DESIGN_SIZE.height/DESIGN_SIZE.width then
        --高屏
        local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale < wScale then
            mainScale = hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end
    else
        --宽屏
        local topAoH = 40--顶部条凹下去距离 在宽屏中会被用的尺寸
        local bottomMoveH = 0--底部空间尺寸，最后要下移距离
        local hScale1 = (mainHeight + topAoH )/(mainHeight + topAoH - bottomMoveH)--有效区域尺寸改变适配
        local hScale = (mainHeight + topAoH ) / (DESIGN_SIZE.height - uiH - uiBH + topAoH )--有效区域屏幕适配
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale1 * hScale < wScale then
            mainScale = hScale1 * hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end

        local designDis = (DESIGN_SIZE.height/2 - uiBH) * mainScale--设计离下条距离
        local dis = (display.height/2 - uiBH)--实际离下条距离
        local move = designDis - dis
        --宽屏下轮盘跟底部条更接近，实际整体下移了
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + move - bottomMoveH)
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end
function CodeGameScreenThanksGivingMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_enter.mp3")
        scheduler.performWithDelayGlobal(function ()
            self.m_enterGameMusicIsComplete = true
            self:resetMusicBg()
            if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
                self:setMinMusicBGVolume()
            end
        end,2.5,self:getModuleName())
    end,0.4,self:getModuleName())
end
-- 重置当前背景音乐名称
function CodeGameScreenThanksGivingMachine:resetCurBgMusicName()
    if self.m_enterGameMusicIsComplete == false then
        return nil
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == REWAED_SPIN_MODE then
        self.m_currentMusicBgName = "ThanksGivingSounds/music_ThanksGiving_JackpotBG.mp3"
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end
function CodeGameScreenThanksGivingMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenThanksGivingMachine.super.onEnter(self)
    self:addObservers()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:freespinUpdateWildBarWild()
    else
        self:updateCollectProgree()
        self:updateTishi()
        self:normalUpdateWildBarWild()
    end
    self.m_jackpotBar:setLable(false)    
end

function CodeGameScreenThanksGivingMachine:addObservers()
    CodeGameScreenThanksGivingMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 3
        else
            soundIndex = 3
            soundTime = 3
        end

        local soundName = "ThanksGivingSounds/music_ThanksGiving_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:bonusOverTriggerFreeSpin()
    end,"CodeGameScreenThanksGivingMachine_bonusOverTriggerFreeSpin")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:resetMusicBg()
        self:notifyClearBottomWinCoin()
        self.m_bottomUI:showAverageBet()
    end,"CodeGameScreenThanksGivingMachine_eggBonusStart")
    
    gLobalNoticManager:addObserver(self,function(self,params)
        self:eggbonusOver()
    end,"CodeGameScreenThanksGivingMachine_eggbonusOver")

    gLobalNoticManager:addObserver(self,function(self,params)
        if params then
            local isLevelUp = params.p_isLevelUp
            self:betChangeNotify(isLevelUp) 
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:clearCurMusicBg()
    end,"CodeGameScreenThanksGivingMachine_clearCurMusicBg")
end
--更新收集进度
function CodeGameScreenThanksGivingMachine:updateCollectProgree(isPlayAni)
    local toPogress = 0
    if self.m_runSpinResultData.p_collectNetData and #self.m_runSpinResultData.p_collectNetData > 0 then
        local collectData = self.m_runSpinResultData.p_collectNetData[1]
        if collectData.collectLeftCount == 0 and self.m_runSpinResultData.p_bonusStatus == "CLOSED" then
            toPogress = 0
            self.m_collectProgress:findChild("m_lab_num"):setString("0".."/"..collectData.collectTotalCount)
        else
            toPogress = (collectData.collectTotalCount - collectData.collectLeftCount)/collectData.collectTotalCount * 100
            self.m_collectProgress:findChild("m_lab_num"):setString((collectData.collectTotalCount - collectData.collectLeftCount).."/"..collectData.collectTotalCount)
        end
        if isPlayAni then
            self.m_collectProgress:findChild("Particle_1_0"):setPositionType(0)
            self.m_collectProgress:findChild("Particle_1_0"):resetSystem()

            self.m_collectProgressCrab:setAnimation(0, "buling", false)
            self.m_collectProgressCrab:addAnimation(0, "idleframe4", false)
            self.m_collectProgressCrab:addAnimation(0, "idleframe", true)

            self.m_collectProgress:findChild("Particle_1"):setPositionType(0)
            self.m_collectProgress:findChild("Particle_1"):resetSystem()

            local startPro = self.m_collectProgress:findChild("jindutiao"):getPercent()
            local dt1 = 0.5--进度条动画时长
            -- 播放进度条动画
            self.m_proMoveHandlerID = scheduler.scheduleUpdateGlobal(
                function(dt)
                    if self.m_collectProgress:findChild("jindutiao"):getPercent() >= toPogress then
                        self.m_collectProgress:findChild("jindutiao"):setPercent(toPogress)
                        self.m_collectProgress:findChild("Particle_4"):setVisible(false)
                        scheduler.unscheduleGlobal(self.m_proMoveHandlerID)
                        self.m_proMoveHandlerID = nil
                        return
                    end

                    self.m_collectProgress:findChild("Particle_4"):setVisible(true)
                    local zengzhang = (toPogress - startPro)/dt1 * dt--本帧增长
                    local benzhenToPogress = self.m_collectProgress:findChild("jindutiao"):getPercent() + (toPogress - startPro)/dt1 * dt
                    self.m_collectProgress:findChild("jindutiao"):setPercent(benzhenToPogress)

                    self.m_collectProgress:findChild("Particle_4"):setPositionX(self.m_collectProgress:findChild("jindutiao"):getPositionX() + self.m_collectProgress:findChild("jindutiao"):getContentSize().width * (benzhenToPogress/100))
                end
            )
        else
            self.m_collectProgress:findChild("jindutiao"):setPercent(toPogress)
            self.m_collectProgress:findChild("Particle_4"):setVisible(false)
        end
    end
    -- if toPogress == 100 then
    --     self.m_collectProgress:findChild("Particle_2"):setVisible(true)
    --     self.m_collectProgress:findChild("Particle_2_0"):setVisible(true)
    --     self.m_collectProgress:findChild("Particle_2"):setPositionType(0)
    --     self.m_collectProgress:findChild("Particle_2"):resetSystem()
    --     self.m_collectProgress:findChild("Particle_2_0"):setPositionType(0)
    --     self.m_collectProgress:findChild("Particle_2_0"):resetSystem()
    -- else
    --     self.m_collectProgress:findChild("Particle_2"):setVisible(false)
    --     self.m_collectProgress:findChild("Particle_2_0"):setVisible(false)
    -- end

end
--更新提示信息
function CodeGameScreenThanksGivingMachine:updateTishi()
    self.m_tishiBar:playAction("start"..self.m_tishiBar.currShowId,false,function ()
        self.m_tishiBar:playAction("idle"..self.m_tishiBar.currShowId)
    end)
    performWithDelay(self.m_tishiBar,function ()
        self.m_tishiBar:playAction("over"..self.m_tishiBar.currShowId,false,function ()
            self.m_tishiBar.currShowId = self.m_tishiBar.currShowId + 1
            if self.m_tishiBar.currShowId > self.m_tishiBar.totalId then
                self.m_tishiBar.currShowId = 1
            end
            self:updateTishi()
        end)
    end,5)
end
--随机两个倍数
function CodeGameScreenThanksGivingMachine:randomMultiple()
    local multipleTab
    if self.m_runSpinResultData.p_freeSpinsTotalCount == 5 then
        multipleTab = {1,2,3,4,5,6,7}
    elseif self.m_runSpinResultData.p_freeSpinsTotalCount == 10 then
        multipleTab = {1,2,3,4,5}
    elseif self.m_runSpinResultData.p_freeSpinsTotalCount == 15 then
        multipleTab = {1,2}
    end
    return multipleTab[math.random(#multipleTab)],multipleTab[math.random(#multipleTab)]
end
--更新倍数显示
function CodeGameScreenThanksGivingMachine:updateMultiple(multiple,isPlayAni,func)
    if isPlayAni then
        gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_updateMultiple.mp3")
        self.m_multipleBar:playAction("start2",false,function ()
            local multiple1,multiple2 = self:randomMultiple()
            self.m_multipleBar:findChild("m_lb_num_0_0"):setString("X"..multiple1)
            self.m_multipleBar:findChild("m_lb_num_0_1"):setString("X"..multiple2)
            self.m_multipleBar:playAction("idle2",false,function ()
                local multiple3 = self:randomMultiple()
                self.m_multipleBar:findChild("m_lb_num_0"):setString("X"..multiple3)
                if multiple then
                    self.m_multipleBar:findChild("m_lb_num_0_0"):setString("X"..multiple)
                elseif self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.multiple then
                    self.m_multipleBar:findChild("m_lb_num_0_0"):setString("X"..self.m_runSpinResultData.p_selfMakeData.multiple)
                end
                performWithDelay(self,function ()
                    self.m_multipleBar:findChild("Particle_2"):setPositionType(0)
                    self.m_multipleBar:findChild("Particle_2"):resetSystem()
                end,5/30)
                self.m_multipleBar:playAction("over2",false,function ()
                    self.m_multipleBar:findChild("m_lb_num_0"):setString(self.m_multipleBar:findChild("m_lb_num_0_0"):getString())
                    if func then
                        func()
                    end
                end)
            end)
        end)
    else
        self.m_multipleBar:playAction("idle3")
    end
    if multiple then
        self.m_multipleBar:setVisible(true)
        self.m_multipleBar:findChild("m_lb_num"):setString("X"..multiple)
    elseif self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.multiple then
        self.m_multipleBar:setVisible(true)
        self.m_multipleBar:findChild("m_lb_num"):setString("X"..self.m_runSpinResultData.p_selfMakeData.multiple)
    else
        self.m_multipleBar:setVisible(true)
        local mul = self:randomMultiple()
        self.m_multipleBar:findChild("m_lb_num"):setString("X"..mul)
        self.m_multipleBar:findChild("m_lb_num_0_0"):setString("X"..mul)
        self.m_multipleBar:findChild("m_lb_num_0"):setString("X"..mul)
    end
end
--某一列wild加满
function CodeGameScreenThanksGivingMachine:addWildFulInWildBar(col,isPlayAni)
    local addNum = self.m_wildBarFullNum - #self.m_wildTab[col]
    return self:addWildInWildBar(col,addNum,isPlayAni)
end
--某一列增加wild
function CodeGameScreenThanksGivingMachine:addWildInWildBar(col,addNum,isPlayAni)
    local dt = 0
    for i = 1,addNum do
        local wildNode = util_spineCreate("Socre_ThanksGiving_Wild",true,true)
        wildNode:setAnimation(0,"idleframe1",true)
        self:findChild("reel_an"..col):addChild(wildNode,self.m_wildBarFullNum - #self.m_wildTab[col])
        table.insert(self.m_wildTab[col],wildNode)
        wildNode.isDroped = false--标记是否落到盘面上
        local jiange = self.m_reelColDatas[col].p_showGridH
        if isPlayAni then
            wildNode:setPositionY(350)
            local pos = cc.p(0,-280 + (#self.m_wildTab[col]-1)*jiange + jiange/2)
            local dTime = 0.1*(i - 1)
            local moveTime = 1
            local delaytime = cc.DelayTime:create(dTime)
            local moveto = cc.MoveTo:create(moveTime,pos)
            local action = cc.EaseQuinticActionIn:create(moveto)
            local cfunc = cc.CallFunc:create(function ()
                performWithDelay(self,function ()
                    gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_addWildBuling.mp3")
                    util_spinePlay(wildNode,"buling_8",false)
                    wildNode:addAnimation(0,"idleframe1",true)
                end,moveTime - 9/30)
            end)
            local seq = cc.Sequence:create({delaytime,cfunc,action})
            wildNode:runAction(seq)
            if i == addNum then
                dt = dTime + moveTime
            end
        else
            wildNode:setPositionY(-280 + (#self.m_wildTab[col]-1)*jiange + jiange/2)
            wildNode:addAnimation(0,"idleframe1",true)
        end
    end
    return dt
end
--scatter增加wild
function CodeGameScreenThanksGivingMachine:scatterAddWild(func)
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.scatterAddWilds then
        local addWildCol = {}
        for col,addWildNum in ipairs(self.m_runSpinResultData.p_selfMakeData.scatterAddWilds) do
            if addWildNum > 0 then
                table.insert(addWildCol,col)
            end
        end
        self:showReelLightAni(addWildCol,nil,function ()
            local dt = 0
            for col,addWildNum in ipairs(self.m_runSpinResultData.p_selfMakeData.scatterAddWilds) do
                local temdt = self:addWildInWildBar(col,addWildNum,true)
                if dt < temdt then
                    dt = temdt
                end
            end
            if func then
                performWithDelay(self,func,dt)
            end
        end)
    end
end
--bonus增加wild
function CodeGameScreenThanksGivingMachine:bonusAddWild(func)
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.chickenAddWilds then
        local dt = 0
        if self.m_runSpinResultData.p_selfMakeData.chickenAddWilds then
            for col,addWildNum in ipairs(self.m_runSpinResultData.p_selfMakeData.chickenAddWilds) do
                local temdt = self:addWildInWildBar(col,addWildNum,true)
                if dt < temdt then
                    dt = temdt
                end
            end
        end
        if func then
            performWithDelay(self,func,dt)
        end
    end
end
--normal下更新wild条上的wild数量(直接出现，没有过程)
function CodeGameScreenThanksGivingMachine:normalUpdateWildBarWild()
    -- 使用totalbet作为K
    local currTotalBet = globalData.slotRunData:getCurTotalBet()
    local currTotalBetWildData = self.m_baseWildData[tostring(currTotalBet)]

    if currTotalBetWildData then
        for col,wildNum in ipairs(currTotalBetWildData) do
            local currNum = #self.m_wildTab[col]
            self:addWildInWildBar(col,wildNum - currNum,false)
        end
    end
end
--freespin下更新wild条上的wild数量
function CodeGameScreenThanksGivingMachine:freespinUpdateWildBarWild(isPlayAni,func)
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.columnWilds then
        local dt = 0
        for col,wildNum in ipairs(self.m_runSpinResultData.p_selfMakeData.columnWilds) do
            local currNum = #self.m_wildTab[col]
            local temdt = self:addWildInWildBar(col,wildNum - currNum,isPlayAni)
            if dt < temdt then
                dt = temdt
            end
        end
        if func then
            if dt > 0 then
                performWithDelay(self,func,dt)
            else
                func()
            end
        end
    end
end

--某一列wild下落 isFull是不是全部落到盘面上  firstBulingFunc第一个wild播buling时的开始调用的回调函数
function CodeGameScreenThanksGivingMachine:oneColWildDrop(col,isFull,firstBulingFunc)
    local wildNodeTab = self.m_wildTab[col]
    local dt = 0
    for j,wildNode in ipairs(wildNodeTab) do
        local pos
        if isFull then
            local worldPos = self.m_clipParent:convertToWorldSpace(self:getNodePosByColAndRow(math.ceil(j/2),col))
            pos = wildNode:getParent():convertToNodeSpace(worldPos)
            wildNode.isDroped = true
            table.insert(self.m_dropedWildTab[col],wildNode)
            wildNode.row = math.ceil(j/2)--记录掉到盘面上的wild掉到了第几行
        else
            if j <= self.m_iReelRowNum then
                local worldPos = self.m_clipParent:convertToWorldSpace(self:getNodePosByColAndRow(j,col))
                pos = wildNode:getParent():convertToNodeSpace(worldPos)
                wildNode.isDroped = true
                table.insert(self.m_dropedWildTab[col],wildNode)
                wildNode.row = j--记录调到盘面上的wild掉到了第几行
            else
                pos = cc.p(0,-280 + (j - 5)*self.m_SlotNodeH + self.m_SlotNodeH/2)
            end
        end

        local dTime = 0.1*(j - 1)
        local moveTime = 1
        local delaytime1 = cc.DelayTime:create(dTime)
        local cFunc1 = cc.CallFunc:create(function ()
            util_spinePlay(wildNode,"buling_4",false)
        end)
        local delaytime2 = cc.DelayTime:create(5/30)
        local moveto = cc.MoveTo:create(moveTime,pos)
        local action = cc.EaseQuinticActionIn:create(moveto)
        
        local cFunc2 = cc.CallFunc:create(function ()
            performWithDelay(self,function ()
            end,moveTime - 9/30)
            if j == 1 then
                if firstBulingFunc then
                    firstBulingFunc()
                end
            end
            
            --如果是轮盘停止后
            if self.m_reelIsruning == false then
                -- 停止下落没有全落的
                    if j <= self.m_iReelRowNum then
                        --将盘面图标变为wild，下落的wild隐藏
                        -- wildNode:setVisible(false)
                        local isSpecialSymbol = self:oneSpecialSymbolChangeWild(col,j,isFull)
                        if isSpecialSymbol == false then
                            gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_wildBuling.mp3")
                        end
                        util_spinePlay(wildNode,"actionframe_4",false)
                    else
                        -- util_spinePlay(wildNode,"buling_4",false)
                        -- wildNode:addAnimation(0,"idleframe1_2",true)
                        gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_wildBuling.mp3")
                        util_spinePlay(wildNode,"idleframe1_2",true)
                        wildNode:setLocalZOrder(self.m_wildBarFullNum - (j - self.m_iReelRowNum - 1))
                    end
                -- end
            else
                gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_wildBuling.mp3")
                if isFull then
                    if j % 2 == 1 then
                        util_spinePlay(wildNode,"actionframeX2_1",false)
                    else
                        util_spinePlay(wildNode,"scatteractionframe_4",false)--wild消失动画
                    end
                else
                    if j <= self.m_iReelRowNum then
                        util_spinePlay(wildNode,"actionframe_4",false)
                    else
                        -- util_spinePlay(wildNode,"buling_4",false)
                        -- wildNode:addAnimation(0,"idleframe1_2",true)
                        util_spinePlay(wildNode,"idleframe1_2",true)
                        wildNode:setLocalZOrder(self.m_wildBarFullNum - (j - self.m_iReelRowNum - 1))
                    end
                end
            end
        end)
        -- local cFunc3 = cc.CallFunc:create(function ()
        --     if self.m_reelIsruning == true then
        --         if isFull then
        --             if j % 2 == 1 then
        --                 -- util_spinePlay(wildNode,"actionframeX2_1",false)
        --             else
        --                 util_spinePlay(wildNode,"scatteractionframe_4",false)--wild消失动画
        --             end
        --         end
        --     end
        -- end)
        local seq = cc.Sequence:create({delaytime1,cFunc1,delaytime2,action,cFunc2})
        wildNode:runAction(seq)
        if j == #wildNodeTab then
            dt = dTime + moveTime
        end
    end
    self:removeDropWildFromWildTab()
    return dt
end
--将一个盘面一定位置特殊图标变为wild并buling
function CodeGameScreenThanksGivingMachine:oneSpecialSymbolChangeWild(col,row,isfull)
    if isfull == nil then
        isfull = false
    end
    if self.m_stcValidSymbolMatrix[row][col] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        local slotNode = self:getFixSymbol(col,row)
        if slotNode then
            self:setSymbolToClip(slotNode)
            slotNode:runAnim("actionframe3",false)
            slotNode.m_lineAnimName = "actionframe2"
            slotNode.m_idleAnimName = "idleframe2"
            gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_scatterWildBuling.mp3")
            return true
        end
    elseif self.m_stcValidSymbolMatrix[row][col] == self.SYMBOL_SCORE_BONUS then
        for i,slotNode in ipairs(self.m_clipBonus) do
            if slotNode.p_rowIndex == row and slotNode.p_cloumnIndex == col then
                --bonus不管是不是要变都要播这个动画，就不在这里播了
                -- slotNode:runAnim("buling2",false)
                slotNode.m_idleAnimName = "idleframe11"
            end
        end
        return true
    end
end
--将一个盘面普通图标变为wild
function CodeGameScreenThanksGivingMachine:oneSymbolChangeWild(col,row,isfull)
    if isfull == nil then
        isfull = false
    end
    local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
    if slotNode then
        if slotNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER
            and slotNode.p_symbolType ~= self.SYMBOL_SCORE_BONUS then

            slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
            slotNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - row)
            if isfull == false then
                slotNode:runAnim("idleframe",false)
            else
                slotNode.m_lineAnimName = "actionframeX2"--信号块连线动画变量，为nil时播actionframe
                slotNode.m_idleAnimName = "idleframeX2"
                slotNode:runAnim("idleframeX2",false)
            end

        end
    end
end
--将已经落到盘面的wild从存储数组中清除
function CodeGameScreenThanksGivingMachine:removeDropWildFromWildTab()
    for col,wildTab in ipairs(self.m_wildTab) do
        local index = 1
        while true do
            if index <= #wildTab then
                if wildTab[index].isDroped == true then
                    table.remove(wildTab,index)
                else
                    index = index + 1
                end
            else
                break
            end
        end
    end
end
--隐藏已经下落来的wild图标
function CodeGameScreenThanksGivingMachine:hideDropedWild()
    for col,dropedWildTab in ipairs(self.m_dropedWildTab) do
        for i,dropedWild in ipairs(dropedWildTab) do
            dropedWild:setVisible(false)
        end
    end
end
--删除已经落下来的wild图标
function CodeGameScreenThanksGivingMachine:removeDropedWild()
    for col,dropedWildTab in ipairs(self.m_dropedWildTab) do
        while true do
            if #dropedWildTab > 0 then
                dropedWildTab[1]:removeFromParent()
                table.remove(dropedWildTab,1)
            else
                break
            end
        end
    end
end

--删除所有wild条上的wild
function CodeGameScreenThanksGivingMachine:removeAllWild()
    for col,wildTab in ipairs(self.m_wildTab) do
        while true do
            if #wildTab > 0 then
                wildTab[1]:removeFromParent()
                table.remove(wildTab,1)
            else
                break
            end
        end
    end
end

--bonus收集
function CodeGameScreenThanksGivingMachine:collectBonus(func)
    if #self.m_clipBonus > 0 then
        self:clearWinLineEffect()
        for i,bonusNode in ipairs(self.m_clipBonus) do
            local row = bonusNode.p_rowIndex
            if i == #self.m_clipBonus then
                if self:oneColIsDropedWildForData(3) then
                    bonusNode:runAnim("shouji"..(5-row),false,function ()
                        bonusNode:runAnim("idleframe11")
                        self:updateCollectProgree(true)
                        if func then
                            func()
                        end
                    end)
                else
                    bonusNode:runAnim("shouji"..(9-row),false,function ()
                        bonusNode:runAnim("idleframe")
                        self:updateCollectProgree(true)
                        if func then
                            func()
                        end
                    end)
                end
            else
                if self:oneColIsDropedWildForData(3) then
                    bonusNode:runAnim("shouji"..(5-row),false,function ()
                        bonusNode:runAnim("idleframe11")
                    end)
                else
                    bonusNode:runAnim("shouji"..(9-row),false,function ()
                        bonusNode:runAnim("idleframe")
                    end)
                end
                
            end
        end
    else
        if func then
            func()
        end
    end
end
--[[
    @desc: 获得轮盘的位置
]]
function CodeGameScreenThanksGivingMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end
function CodeGameScreenThanksGivingMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenThanksGivingMachine.super.onExit(self)
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    if self.m_proMoveHandlerID then
        scheduler.unscheduleGlobal(self.m_proMoveHandlerID)
        self.m_proMoveHandlerID = nil
    end
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenThanksGivingMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_ThanksGiving_Bonus"
    end
    return nil
end

----------------------------- 玩法处理 -----------------------------------
--进关数据初始化
function CodeGameScreenThanksGivingMachine:initGameStatusData(gameData)
    if gameData then
        if gameData.spin then
            if gameData.spin.selfData then
                if gameData.spin.selfData.betColumnWilds then
                    self.m_baseWildData = clone(gameData.spin.selfData.betColumnWilds)
                end
            end
        end
    end

    --将feature 跟spin合并 并删除feature
    if gameData.feature then
        table_merge(gameData.spin,gameData.feature)
        self.m_feature = gameData.feature
        gameData.feature = nil
    end

    CodeGameScreenThanksGivingMachine.super.initGameStatusData(self,gameData)
end
-- 断线重连
function CodeGameScreenThanksGivingMachine:MachineRule_initGame()

end
--所有滚轴停止调用
function CodeGameScreenThanksGivingMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
    CodeGameScreenThanksGivingMachine.super.slotReelDown(self)
    self.m_reelIsruning = false
end
--
--单列滚动停止回调
--
function CodeGameScreenThanksGivingMachine:slotOneReelDown(reelCol)    
    CodeGameScreenThanksGivingMachine.super.slotOneReelDown(self,reelCol)
    local sound = {scatter = 0,bonus = 0}
    if #self.m_dropedWildTab[reelCol] > 0 then
        for row = 1,self.m_iReelRowNum do
            if self.m_stcValidSymbolMatrix[row][reelCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local symbolNode = self:getFixSymbol(reelCol, row)
                if symbolNode then
                    sound.scatter = 1
                    self:setSymbolToClip(symbolNode)
                    symbolNode:runAnim("actionframe3",false,function ()
                    end)
                    symbolNode.m_lineAnimName = "actionframe2"
                    symbolNode.m_idleAnimName = "idleframe2"
                end
                for i,wildNode in ipairs(self.m_dropedWildTab[reelCol]) do
                    if wildNode.row == row then
                        wildNode:setVisible(false)
                    end
                end
            elseif self.m_stcValidSymbolMatrix[row][reelCol] == self.SYMBOL_SCORE_BONUS then
                local symbolNode = self:getFixSymbol(reelCol, row, SYMBOL_NODE_TAG)
                if symbolNode then
                    self:setSymbolToClip(symbolNode)
                    symbolNode.m_idleAnimName = "idleframe11"
                    sound.bonus = 1
                    symbolNode:runAnim("buling2",false,function ()
                        symbolNode:runAnim("idleframe12",false,function ()
                            -- symbolNode:runIdleAnim()
                        end)
                    end)
                end
                for i,wildNode in ipairs(self.m_dropedWildTab[reelCol]) do
                    if wildNode.row == row then
                        wildNode:setVisible(false)
                    end
                end
            end
        end
    else
        for row = 1,self.m_iReelRowNum do
            -- if self.m_stcValidSymbolMatrix[row][reelCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            --     local symbolNode = self:getFixSymbol(reelCol, row)
            --     if symbolNode then
            --         sound.scatter = 1
            --         self:setSymbolToClip(symbolNode)
            --         symbolNode:runAnim("buling")
            --     end
            -- else
            if self.m_stcValidSymbolMatrix[row][reelCol] == self.SYMBOL_SCORE_BONUS then
                local symbolNode = self:getFixSymbol(reelCol, row, SYMBOL_NODE_TAG)
                if symbolNode then
                    self:setSymbolToClip(symbolNode)
                    sound.bonus = 1
                    symbolNode:runAnim("buling",false,function ()
                        symbolNode:runAnim("idleframe1",false,function ()
                            -- symbolNode:runAnim("idleframe2",true)
                        end)
                    end)
                end
            end
        end
    end
    if sound.scatter == 1 then

        local soundPath = self.m_scatterBulingSoundArry[reelCol]
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath,TAG_SYMBOL_TYPE.SYMBOL_SCATTER )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    elseif sound.bonus == 1 then

        local soundPath = "ThanksGivingSounds/music_ThanksGiving_chickenBuling.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
end
function CodeGameScreenThanksGivingMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "ThanksGivingSounds/music_ThanksGiving_Scatter"..i..".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
function CodeGameScreenThanksGivingMachine:isPlayTipAnima(matrixPosY, matrixPosX, node)
    return true
end
--根据行列获取root层的图标
function CodeGameScreenThanksGivingMachine:getSymbolForColRow(col,row)
    for i,symbolNode in ipairs(self.m_clipScatter) do
        if symbolNode.p_rowIndex == row and symbolNode.p_cloumnIndex == col then
            return symbolNode
        end
    end
end
--将图标提到root层
function CodeGameScreenThanksGivingMachine:setSymbolToClip(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = slotNode:getPositionY()
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX,slotNode.m_preY))
    pos = self:findChild("root"):convertToNodeSpace(pos)
    -- pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
    
    self:findChild("root"):addChild(slotNode,self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex*10)
    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        self.m_clipScatter[#self.m_clipScatter + 1] = slotNode
    elseif slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
        self.m_clipBonus[#self.m_clipBonus + 1] = slotNode
    end

    local linePos = {}
    linePos[#linePos + 1] = {iX = slotNode.p_rowIndex,iY = slotNode.p_cloumnIndex}
    slotNode:setLinePos(linePos)
end
--将图标恢复到轮盘层
function CodeGameScreenThanksGivingMachine:setSymbolToReel()
    for i,bonusNode in ipairs(self.m_clipBonus) do
        local preParent = bonusNode.m_preParent
        if preParent ~= nil then
            bonusNode.p_layerTag = bonusNode.m_preLayerTag

            local nZOrder = bonusNode.m_showOrder
            nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + bonusNode.m_showOrder

            util_changeNodeParent(preParent,bonusNode,nZOrder)
            bonusNode:setPosition(bonusNode.m_preX, bonusNode.m_preY)
            bonusNode:runIdleAnim()
        end
    end
    self.m_clipBonus = {}
    self:setScatterSymbolToReel()
end
--将scatter图标还原到轮盘层
function CodeGameScreenThanksGivingMachine:setScatterSymbolToReel()
    for i,scatterNode in ipairs(self.m_clipScatter) do
        local preParent = scatterNode.m_preParent
        if preParent ~= nil then
            scatterNode.p_layerTag = scatterNode.m_preLayerTag

            local nZOrder = scatterNode.m_showOrder
            nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + scatterNode.m_showOrder

            util_changeNodeParent(preParent,scatterNode,nZOrder)
            scatterNode:setPosition(scatterNode.m_preX, scatterNode.m_preY)
            scatterNode:runIdleAnim()
        end
    end
    self.m_clipScatter = {}
end
function CodeGameScreenThanksGivingMachine:showGuochang(func)
    gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_guochang.mp3")
    self.m_guochang:setVisible(true)
    util_spinePlay(self.m_guochang,"guochang",false)
    self.m_guochangBg:playAction("guochang")
    util_spineEndCallFunc(self.m_guochang,"guochang",function ()
        self.m_guochang:setVisible(false)
    end)
    util_spineFrameCallFunc(self.m_guochang,"guochang","guochang", function()
        if func then
            func()
        end
    end)
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenThanksGivingMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self.m_gameBg:runCsbAction("day_night",false)
    self:updateMultiple(nil,false)
    self.m_tishiBar:setVisible(false)
    self.m_freespinBar:setVisible(true)
    self.m_freespinBar:runCsbAction("start",false)
    self.m_collectProgress:setVisible(false)

    self:removeAllWild()
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenThanksGivingMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self.m_gameBg:runCsbAction("night_day",false)

    self.m_multipleBar:playAction("end",false,function ()
        self.m_multipleBar:setVisible(false)
    end)
    
    self.m_freespinBar:runCsbAction("over",false,function ()
        self.m_freespinBar:setVisible(false)
        self.m_tishiBar:setVisible(true)
    end)
    
    self.m_collectProgress:setVisible(true)
    self:updateCollectProgree()

    self:removeAllWild()
    self:normalUpdateWildBarWild()
end
---------------------------------------------------------------------------
---
-- 显示free spin
function CodeGameScreenThanksGivingMachine:showEffect_FreeSpin(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 停掉背景音乐
    self:clearCurMusicBg()

    self:showFreeSpinView(effectData)
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end
function CodeGameScreenThanksGivingMachine:showFreeSpinStart(num,func)
    local ownerlist = {}
    ownerlist["m_lb_num_1"] = num
    local multipleString = {
        ["5"] = "1-7X",
        ["10"] = "1-5X",
        ["15"] = "1-2X",
    }
    ownerlist["m_lb_num_2"] = multipleString[""..num]
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func,BaseDialog.AUTO_TYPE_ONLY)
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenThanksGivingMachine:showFreeSpinView(effectData)
    local showFreeSpinView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            -- self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            --     effectData.p_isPlay = true
            --     self:playGameEffect()
            -- end,true)
        else
            self:showGuochang(function ( )
                gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_showFreeSpinView.mp3")
                local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    
                        self:triggerFreeSpinCallFun()
                    
                    -- performWithDelay(self,function ()
                        self:freespinUpdateWildBarWild(true,function ()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end)
                    -- end,97/30)
                end)
                local chicken = util_spineCreate("ThanksGiving_Jackpot_Juese",true,true)
                view:findChild("ThanksGiving_ji"):addChild(chicken)

                util_spinePlay(chicken,"jackpot3",false)
                chicken:addAnimation(0,"idleframe7",true)

                -- local chickenWings = util_spineCreate("ThanksGiving_Jackpot_Juese2",true,true)
                -- view:findChild("ThanksGiving_jichibang"):addChild(chickenWings)
                -- util_spinePlay(chickenWings,"jackpot3",false)
                -- chickenWings:addAnimation(0,"idleframe7",true)
            end)
            
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function()
        showFreeSpinView()
    end,0.5)
end

function CodeGameScreenThanksGivingMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_freespinEnd.mp3")
    performWithDelay(self,function ()
        gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_showFreeSpinView.mp3")
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
        local view = self:showFreeSpinOver( strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            -- self:showGuochang(function ()
                self:triggerFreeSpinOverCallFun()
            -- end)
        end)
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node,sx = 0.93,sy = 0.93},497)
        local chicken = util_spineCreate("ThanksGiving_Jackpot_Juese",true,true)
        view:findChild("ThanksGiving_ji"):addChild(chicken)
        util_spinePlay(chicken,"idleframe7",true)
        view:findChild("ThanksGiving_jizhua"):setVisible(false)
        view:findChild("ThanksGiving_jizhua_0"):setVisible(false)
    end,3)
end

--显示bonus小游戏界面
function CodeGameScreenThanksGivingMachine:showBonusGameView(effectData)
    -- 停掉背景音乐
    self:clearCurMusicBg()
    self:clearWinLineEffect()
    if self.m_runSpinResultData.p_selfMakeData.select then
        --加一下触发金币
        if globalData.slotRunData.lastWinCoin == nil or globalData.slotRunData.lastWinCoin ~= self.m_runSpinResultData.p_winAmount then
            globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_winAmount
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{0,false,false})
        end

        self:playScatterTipMusicEffect()
        if #self.m_clipScatter > 0 then
            for i,slotNode in ipairs(self.m_clipScatter) do
                slotNode:runAnim("actionframe",false,function ()
                    slotNode:runAnim(slotNode:getIdleAnimName())
                end)
            end
        end
        for row = 1,self.m_iReelRowNum do
            for col = 1,self.m_iReelColumnNum do
                local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    self:setSymbolToClip(slotNode)
                    slotNode:runAnim("actionframe",false,function ()
                        slotNode:runAnim(slotNode:getIdleAnimName())
                    end)
                end
            end
        end
        
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end

        --freespin选择界面
        performWithDelay(self,function ()
            gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_showChooseView.mp3")
            local freespinChooseLayer = util_createView("CodeThanksGivingSrc.ThanksGivingFreespinChoseLayer",self)
            self:findChild("bonusLayer"):addChild(freespinChooseLayer)
        end,4.5)
    else
        self:setCurrSpinMode(REWAED_SPIN_MODE)
        --播放进度条满的各种特效
        self.m_collectProgress:findChild("Particle_2"):setVisible(true)
        self.m_collectProgress:findChild("Particle_2_0"):setVisible(true)
        self.m_collectProgress:findChild("Particle_2"):setPositionType(0)
        self.m_collectProgress:findChild("Particle_2"):resetSystem()
        self.m_collectProgress:findChild("Particle_2_0"):setPositionType(0)
        self.m_collectProgress:findChild("Particle_2_0"):resetSystem()

        gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_collectBonusEnterGame.mp3")
        self.m_collectProgressCrab:setAnimation(0, "actionframe", false)
        self.m_collectProgressCrab:addAnimation(0, "idleframe4", false)
        self.m_collectProgressCrab:addAnimation(0, "idleframe", true)
        util_spineEndCallFunc(self.m_collectProgressCrab,"idleframe4",function ()
            --过场
            self:showGuochang(function ()
                --去掉进度条满的各种特效
                self.m_collectProgress:findChild("Particle_2"):setVisible(false)
                self.m_collectProgress:findChild("Particle_2_0"):setVisible(false)
                --敲鸡蛋的小游戏
                local bonusLayer = util_createView("CodeThanksGivingSrc.ThanksGivingBonuLayer",self)
                bonusLayer.m_jackpotBar:setLable(false)
                bonusLayer:setAvgBet(self.m_runSpinResultData.p_collectNetData[1].collectCoinsPool)
                bonusLayer:findChild("root"):setScale(self.m_machineRootScale)
                self:findChild("bonusLayer1"):addChild(bonusLayer)--100001
                self:removeSoundHandler()
                gLobalSoundManager:setBackgroundMusicVolume(1)

                if globalData.slotRunData.machineData.p_portraitFlag then
                    bonusLayer.getRotateBackScaleFlag = function(  ) return false end
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = bonusLayer})
            end)
        end)
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenThanksGivingMachine:MachineRule_SpinBtnCall()
    self:removeSoundHandler( )
    gLobalSoundManager:setBackgroundMusicVolume(1)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    return false -- 用作延时点击spin调用
end
--轮盘开始滚动
function CodeGameScreenThanksGivingMachine:beginReel()
    self.m_randomNum = 0
    self.m_reelIsruning = true

    self:resetReelDataAfterReel()
    self:setSymbolToReel()
    local slotsParents = self.m_slotParents
    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local reelDatas = self:checkUpdateReelDatas(parentData)

        self:checkReelIndexReason(parentData)
        self:resetParentDataReel(parentData)

        self:createSlotNextNode(parentData)
        if self.m_configData.p_reelBeginJumpTime > 0 then
            self:addJumoActionAfterReel(slotParent,slotParentBig)
        else
            self:registerReelSchedule()
        end
        self:checkChangeClipParent(parentData)
    end
    self:checkChangeBaseParent()
    self:beginNewReel()
    
    -- CodeGameScreenThanksGivingMachine.super.beginReel(self)

end

--所有effect播放完之后调用
function CodeGameScreenThanksGivingMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenThanksGivingMachine.super.playEffectNotifyNextSpinCall(self)
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenThanksGivingMachine:addSelfEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_selfMakeData and (self.m_runSpinResultData.p_selfMakeData.dropColumns or self.m_runSpinResultData.p_selfMakeData.fullColumns) then
            --将spin落下wild列的图标变为wild
            local selfEffect3 = GameEffectData.new()
            selfEffect3.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect3.p_effectOrder = self.SPINDROPWILDSYMBOLCHANGEWILD_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect3
            selfEffect3.p_selfEffectType = self.SPINDROPWILDSYMBOLCHANGEWILD_EFFECT
            --删除下落的wild
            local selfEffect4 = GameEffectData.new()
            selfEffect4.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect4.p_effectOrder = self.REMOVEDROPEDWILD_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect4
            selfEffect4.p_selfEffectType = self.REMOVEDROPEDWILD_EFFECT
        end

        -- --更新wild条上的wild
        -- if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
        --     local selfEffect1 = GameEffectData.new()
        --     selfEffect1.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        --     selfEffect1.p_effectOrder = self.FREESPINUPDATEWILDBARWILD_EFFECT
        --     self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect1
        --     selfEffect1.p_selfEffectType = self.FREESPINUPDATEWILDBARWILD_EFFECT
        -- end
    else
        --将spin落下wild列的图标变为wild
        local selfEffect3 = GameEffectData.new()
        selfEffect3.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect3.p_effectOrder = self.SPINDROPWILDSYMBOLCHANGEWILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect3
        selfEffect3.p_selfEffectType = self.SPINDROPWILDSYMBOLCHANGEWILD_EFFECT

        -- 添加scatter增加的wild
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.scatterAddWilds then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.NORMALSCATTERADDWILD_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.NORMALSCATTERADDWILD_EFFECT
        end
        -- 出bonus随机选择增加wild列数的随机效果
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.chickenAddWilds then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.NORMALBONUSRANDOM_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.NORMALBONUSRANDOM_EFFECT
        end

        --wild下落
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.dropWildColumns then
            local dropData = self.m_runSpinResultData.p_selfMakeData.dropWildColumns
            for i,v in ipairs(dropData) do
                local col = v + 1
                if self.m_runSpinResultData.p_selfMakeData.columnWilds[col] == self.m_wildBarFullNum - self.m_iReelRowNum then
                    --有某一列的wild是第一次开始下落
                    local selfEffect1 = GameEffectData.new()
                    selfEffect1.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect1.p_effectOrder = self.DROPWILD_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect1
                    selfEffect1.p_selfEffectType = self.DROPWILD_EFFECT

                    local selfEffect2 = GameEffectData.new()
                    selfEffect2.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect2.p_effectOrder = self.DROPWILDSYMBOLCHANGEWILD_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect2
                    selfEffect2.p_selfEffectType = self.DROPWILDSYMBOLCHANGEWILD_EFFECT
                    
                    break
                end
            end
        end

        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.dropWildColumns then
            --删除下落的wild
            local selfEffect4 = GameEffectData.new()
            selfEffect4.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect4.p_effectOrder = self.REMOVEDROPEDWILD_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect4
            selfEffect4.p_selfEffectType = self.REMOVEDROPEDWILD_EFFECT
        end

        if #self.m_clipBonus > 0 then
            --收集bonus
            local selfEffect5 = GameEffectData.new()
            selfEffect5.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect5.p_effectOrder = self.COLLECTBONUS_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect5
            selfEffect5.p_selfEffectType = self.COLLECTBONUS_EFFECT
        end
    end
end

---
-- 播放玩法动画gan
-- 实现自定义动画内容
function CodeGameScreenThanksGivingMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.SPINDROPWILDSYMBOLCHANGEWILD_EFFECT then--将spin落下wild列的图标变为wild
        self:spinDropWildSymbolChangeWild()
        effectData.p_isPlay = true
        self:playGameEffect()
    elseif effectData.p_selfEffectType == self.NORMALSCATTERADDWILD_EFFECT then--scatter增加wild
        self:scatterAddWild(function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.NORMALBONUSRANDOM_EFFECT then--bonus随机列的随机过程
        --稍微延迟一点时间  免得变暗太快
        performWithDelay(self,function ()
            self:randomBonusAddWildCol()
        end,0.3)
    elseif effectData.p_selfEffectType == self.DROPWILD_EFFECT then--wild下落
        self:normalReelDownWildDrop(function ()
            if #self.m_clipBonus > 0 then
                --盘面恢复亮度
                self:hideReelTranslucentMask()
                for i,wildBarBg in ipairs(self.m_wildBarBgTab) do
                    if wildBarBg.isShow == true then
                        wildBarBg:playAction("over")
                        wildBarBg.isShow = false
                    end
                end
            end

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.DROPWILDSYMBOLCHANGEWILD_EFFECT then--轮盘停止后有下落wild的话将下落列图标变为wild
        self:spinDropWildSymbolChangeWild()
        effectData.p_isPlay = true
        self:playGameEffect()
    elseif effectData.p_selfEffectType == self.REMOVEDROPEDWILD_EFFECT then--删除下落的wild
        self:removeDropedWild()
        effectData.p_isPlay = true
        self:playGameEffect()
    elseif effectData.p_selfEffectType == self.COLLECTBONUS_EFFECT then--收集bonus
        self:collectBonus(function ()
            performWithDelay(self,function ()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,0.5)
        end)
    elseif effectData.p_selfEffectType == self.FREESPINUPDATEWILDBARWILD_EFFECT then--freespin下更新wild条上的wild
        self:freespinUpdateWildBarWild(true,function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
	return true
end
-- 通知某种类型动画播放完毕
function CodeGameScreenThanksGivingMachine:notifyGameEffectPlayComplete(param)
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

    for i=1,effectLen do
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
--出bonus后随机增加wild列的随机过程
function CodeGameScreenThanksGivingMachine:randomBonusAddWildCol()
    -- 播放火鸡动画
    gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_chickenCollect.mp3")
    for i,symbolNode in ipairs(self.m_clipBonus) do
        symbolNode:runAnim("idleframe2",true)
    end
    --轮盘变暗
    for i,wildBarBg in ipairs(self.m_wildBarBgTab) do
        wildBarBg:playAction("start")
        wildBarBg.isShow = true
    end
    self:showReelTranslucentMask(function ()
        self:randomPlayWildBarBgAni()
    end)
end
--播放随机选择动画
function CodeGameScreenThanksGivingMachine:randomPlayWildBarBgAni()
    local colNumTab = {}
    for i = 1,self.m_iReelColumnNum do
        if not (#self.m_wildTab[i] == self.m_wildBarFullNum or self:oneColIsDropedWildForDropWildNode(i)) then
            table.insert(colNumTab,i)
        end
    end
    local randomColTab = randGetValueByTab(colNumTab,2)
    for i = 1,self.m_iReelColumnNum do
        local isChoosed = false
        for j,v in ipairs(randomColTab) do
            if v == i then
                if self.m_wildBarBgTab[i].isShow == false then
                    isChoosed = true
                end
                break
            end
        end
        if isChoosed == false then
            if self.m_wildBarBgTab[i].isShow == false then
                self.m_wildBarBgTab[i]:playAction("start")
                self.m_wildBarBgTab[i].isShow = true
            end
        end
    end
    local dt = 0
    for i,col in ipairs(randomColTab) do
        if self.m_wildBarBgTab[col].isShow == true then
            self.m_wildBarBgTab[col]:playAction("over")
            self.m_wildBarBgTab[col].isShow = false
            dt = 5/30
        end
    end
    if dt > 0 then
        gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_chooseBlink.mp3")
        local dt1 = 15/30 * ((self.m_wildBarFullNum - self.m_randomNum)/self.m_wildBarFullNum)
        if dt1 < 0.1 then
            dt1 = 0.1
        end
        performWithDelay(self,function ()
            self.m_randomNum = self.m_randomNum + 1
            if self.m_randomNum >= self.m_wildBarFullNum then
                self:wildBarChoosedLink()
            else
                self:randomPlayWildBarBgAni()
            end
        end,dt + dt1)
    else
        --这次不算
        self:randomPlayWildBarBgAni()
    end
end
--最后选择好后的闪烁
function CodeGameScreenThanksGivingMachine:wildBarChoosedLink()
    for i,bonusNode in ipairs(self.m_clipBonus) do
        bonusNode:runAnim("idleframe3",false,function ()
            bonusNode:runAnim("idleframe2",true)
        end)
    end
    local addWildData = self.m_runSpinResultData.p_selfMakeData.chickenAddWilds
    local resultColTab = {}
    for i,v in ipairs(addWildData) do
        if v > 0 then
            table.insert(resultColTab,i)
        end
    end
    
    for i = 1,self.m_iReelColumnNum do
        local isChoosed = false
        for j,v in ipairs(resultColTab) do
            if v == i then
                if self.m_wildBarBgTab[i].isShow == false then
                    isChoosed = true
                end
                break
            end
        end
        if isChoosed == false then
            if self.m_wildBarBgTab[i].isShow == false then
                self.m_wildBarBgTab[i]:playAction("start")
                self.m_wildBarBgTab[i].isShow = true
            end
        end
    end
    local dt = 0
    for i,col in ipairs(resultColTab) do
        if self.m_wildBarBgTab[col].isShow == true then
            self.m_wildBarBgTab[col]:playAction("over")
            self.m_wildBarBgTab[col].isShow = false
            dt = 5/30
        end
    end

    performWithDelay(self,function ()
        -- n帧之后每隔m帧播l次
        for i,col in ipairs(resultColTab) do
            self.m_wildBarBgTab[col]:playAction("blink")
            self.m_wildBarBgTab[col].isShow = false
            if i == 1 then
                local detime = cc.DelayTime:create(5/30)
                local func1 = cc.CallFunc:create(function ()
                    gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_blink.mp3")
                end)
                local detime1 = cc.DelayTime:create(10/30)
                local seq = cc.Sequence:create({detime,func1:clone(),detime1:clone(),func1:clone(),detime1,func1})
                self.m_wildBarBgTab[col]:runAction(seq)
            end
        end
        performWithDelay(self,function ()
            self:bonusAddWild(function ()
                self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.NORMALBONUSRANDOM_EFFECT})
            end)
        end,30/30)
    end,dt + 15/30)
end
--normal下轮盘停止后，wild下落
function CodeGameScreenThanksGivingMachine:normalReelDownWildDrop(func)
    --wild满了的列的遮罩消失
    for col,wildTab in ipairs(self.m_wildTab) do
        if #wildTab == self.m_wildBarFullNum then
            if self.m_wildBarBgTab[col].isShow == true then
                self.m_wildBarBgTab[col]:playAction("over")
                self.m_wildBarBgTab[col].isShow = false
            end
        end
    end

    -- local temdt = self:wildFullShowLight()
    -- if temdt > 0 then
    --     performWithDelay(self,function ()
            local dt = 0
            local isFistDropCol = true
            for col,wildTab in ipairs(self.m_wildTab) do
                if #wildTab == self.m_wildBarFullNum then
                    local ti = 0
                    if isFistDropCol then
                        ti = self:oneColWildDrop(col,false,function ()
                            --有bonus图标的话，同时播bonus动画
                            for i,bonusNode in ipairs(self.m_clipBonus) do
                                bonusNode:runAnim("buling2",false,function ()
                                    bonusNode:runAnim("idleframe12",false,function ()
                                        -- bonusNode:runIdleAnim()
                                    end)
                                end)
                            end
                        end)
                        isFistDropCol = false
                    else
                        ti = self:oneColWildDrop(col,false)
                    end
                    if dt < ti then
                        dt = ti
                    end
                end
            end

            if dt > 0 then
                performWithDelay(self,function ()
                    if func then
                        func()
                    end
                end,dt + 25/30)--加一个wild  buling的时长
            else
                if func then
                    func()
                end
            end
        -- end,temdt)
    -- else
    --     if func then
    --         func()
    --     end
    -- end
end
--将spin落下wild列的图标变为wild
function CodeGameScreenThanksGivingMachine:spinDropWildSymbolChangeWild()
    for col,dropWildT in ipairs(self.m_dropedWildTab) do
        if #dropWildT > 0 then
            local isfull = false
            if self.m_runSpinResultData.p_selfMakeData.fullColumns then
                for i,v in ipairs(self.m_runSpinResultData.p_selfMakeData.fullColumns) do
                    if v + 1 == col then
                        isfull = true
                        break
                    end
                end
            end
            for row = 1,self.m_iReelRowNum do
                self:oneSymbolChangeWild(col,row,isfull)
            end
        end
    end
    self:setScatterSymbolToReel()
    self:hideDropedWild()
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenThanksGivingMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

end

----
--- 处理spin 成功消息
--
function CodeGameScreenThanksGivingMachine:checkOperaSpinSuccess( param )
    function callfunc()
        self:hideReelTranslucentMask()
        CodeGameScreenThanksGivingMachine.super.checkOperaSpinSuccess(self,param)
        self.m_jackpotBar:setLable(true)
    end
    local resultData = param[2].result

    local function startSpinAddWild()
        local addWildCol = {}--添加wild个数在4个以上的列
        --spin时添加wild
        local function spinAddWild()
            local dt1 = 0 --开始下落延迟时间
            if resultData.selfData then
                --因spin增加的wild
                if resultData.selfData.spinAddWilds then
                    for col,addNum in ipairs(resultData.selfData.spinAddWilds) do
                        if addNum > 0 then
                            local temdt = self:addWildInWildBar(col,addNum,true)
                            if dt1 < temdt then
                                dt1 = temdt
                            end
                        end
                    end
                end
                -- --freespin下 掉落的列wild不够添加
                -- if resultData.selfData.dropColumns then
                --     for i,v in ipairs(resultData.selfData.dropColumns) do
                --         local col = v + 1
                --         local temdt = self:addWildInWildBar(col,self.m_wildBarFullNum - self.m_iReelRowNum - #self.m_wildTab[col],true)
                --         if dt1 < temdt then
                --             dt1 = temdt
                --         end
                --     end
                -- end
                -- --freespin下 满掉落的列先把wild加满
                -- if resultData.selfData.fullColumns then
                --     for i,v in ipairs(resultData.selfData.fullColumns) do
                --         local col = v + 1
                --         local temdt = self:addWildFulInWildBar(col,true)
                --         if dt1 < temdt then
                --             dt1 = temdt
                --         end
                --     end
                -- end
            end

            --延迟dt1时间开始走下落流程
            if dt1 > 0 then
                performWithDelay(self,function ()
                    self:spinDropWild(resultData,addWildCol,callfunc)
                end,dt1)
            else
                self:spinDropWild(resultData,addWildCol,callfunc)
            end
        end

        --检测是否有添加wild个数在4个以上的
        if resultData.selfData then
            --因spin增加的wild
            if resultData.selfData.spinAddWilds then
                for col,addNum in ipairs(resultData.selfData.spinAddWilds) do
                    if addNum >= 4 then
                        table.insert(addWildCol,col)
                    end
                end
            end
            -- --freespin下 掉落的列wild不够添加
            -- if resultData.selfData.dropColumns then
            --     for i,v in ipairs(resultData.selfData.dropColumns) do
            --         local col = v + 1
            --         if self.m_wildBarFullNum - self.m_iReelRowNum - #self.m_wildTab[col] >= 4 then
            --             table.insert(addWildCol,col)
            --         end
            --     end
            -- end
            -- --freespin下 满掉落的列先把wild加满
            -- if resultData.selfData.fullColumns then
            --     for i,v in ipairs(resultData.selfData.fullColumns) do
            --         local col = v + 1
            --         if self.m_wildBarFullNum - #self.m_wildTab[col] >= 4 then
            --             table.insert(addWildCol,col)
            --         end
            --     end
            -- end
        end
        --有添加4个以上wild的话 要先边框发个光
        if #addWildCol > 0 then
            self:showReelTranslucentMask()
            self:showReelLightAni({},nil,function ()
                spinAddWild()
            end)
        else
            spinAddWild()
        end
    end

    if resultData.selfData and resultData.selfData.multiple then
        self:updateMultiple(resultData.selfData.multiple,true,function ()
            startSpinAddWild()
        end)
    else
        startSpinAddWild()
    end
end
--wild满了的列wild发个光 准备下落
function CodeGameScreenThanksGivingMachine:wildFullShowLight()
    --wild满了的列先发个光
    local temdt = 0--发光时长
    for col = 1,#self.m_wildTab do
        if #self.m_wildTab[col] == self.m_wildBarFullNum then
            for i,wildNode in ipairs(self.m_wildTab[col]) do
                util_spinePlay(wildNode,"idleframe1_2",false)
            end
            temdt = 40/30--动画时长
        end
    end
    return temdt
end
--spin的时候wild下落
function CodeGameScreenThanksGivingMachine:spinDropWild(resultData,addWildMoreColTab,func)
    local dropColTab = {}--存储下落的列
    local isHaveTwoDropCol = false
    if resultData.action == "NORMAL" and resultData.selfData and resultData.selfData.dropWildColumns then
        local dropData = resultData.selfData.dropWildColumns
        local columnWildsData = resultData.selfData.columnWilds
        for i,v in ipairs(dropData) do
            local col = v + 1
            -- 最终一列没有wild且还下落的，肯定在spin时下落   现在满了的列肯定下落
            if columnWildsData[col] == 0 or #self.m_wildTab[col] == self.m_wildBarFullNum then
                table.insert(dropColTab,col)
            end
            if columnWildsData[col] == 0 then
                isHaveTwoDropCol = true
            end
        end
    elseif resultData.action == "FREESPIN" then
        local dropData = resultData.selfData.dropColumns
        local fullDropData = resultData.selfData.fullColumns
        if dropData then
            for i,v in ipairs(dropData) do
                local col = v + 1
                table.insert(dropColTab,col)
            end
        end
        if fullDropData then
            for i,v in ipairs(fullDropData) do
                local col = v + 1
                table.insert(dropColTab,col)
            end
        end
        if #dropColTab > 0 then
            table.sort(dropColTab,function (p1,p2)
                return p1 > p2
            end)
        end
    end

    --wild下落
    function spinWildDrop()
        if resultData.action == "NORMAL" then
            local dt = 0
            for i,col in ipairs(dropColTab) do
                performWithDelay(self,function ()
                    self:oneColWildDrop(col)
                end,dt)
                dt = dt + 0.1
            end
            self:showReelTranslucentMask()
            performWithDelay(self,function ()
                if func then
                    func()
                end
            end,2)
        -- freespin下wild下落
        elseif resultData.action == "FREESPIN" then
            local dt = 0
            for i,col in ipairs(dropColTab) do
                performWithDelay(self,function ()
                    if #self.m_wildTab[col] == self.m_wildBarFullNum then
                        self:oneColWildDrop(col,true)
                    else
                        self:oneColWildDrop(col)
                    end
                end,dt)
                dt = dt + 0.1
            end
            performWithDelay(self,function ()
                if func then
                    func()
                end
            end,2)
        end
    end


    --有满了的列边框先发个光
    local fullCol = {}
    for col = 1,#self.m_wildTab do
        if #self.m_wildTab[col] == self.m_wildBarFullNum then
            table.insert(fullCol,col)
        end
    end
    
    if #dropColTab > 0 then
        --如果有二次落的 则边框扫光
        if isHaveTwoDropCol then
            self:showReelLightAni({},nil,function ()
                spinWildDrop()
            end)
        elseif #addWildMoreColTab > 0 then--如果有加了4个以上的wild则不用扫光
            spinWildDrop()
        else--如果有满的则扫光
            self:showReelLightAni({},nil,function ()
                spinWildDrop()
            end)
        end
        self:showReelTranslucentMask()
    else
        if func then
            func()
        end
    end
end

-- 网络消息回来后的处理
function CodeGameScreenThanksGivingMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end

function CodeGameScreenThanksGivingMachine:SpinResultParseResultData(spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
end
--选完freespin次数触发freespin
function CodeGameScreenThanksGivingMachine:bonusOverTriggerFreeSpin()
    self:featuresOverAddFreespinEffect()
    self:notifyGameEffectPlayComplete(GameEffect.EFFECT_BONUS)
end
--bonus玩法结束后添加freespin动画效果
function CodeGameScreenThanksGivingMachine:featuresOverAddFreespinEffect()
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end
--打完鸡蛋后调用
function CodeGameScreenThanksGivingMachine:eggbonusOver()
    self:updateCollectProgree(false)
    self.m_jackpotBar:setLable(false)
    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    self:resetMusicBg()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
    globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_winAmount
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,true,true})
    self.m_bottomUI:hideAverageBet()
    local winAmonut = self.m_runSpinResultData.p_bonusWinCoins
    self:checkFeatureOverTriggerBigWin(winAmonut,GameEffect.EFFECT_BONUS)
    self:notifyGameEffectPlayComplete(GameEffect.EFFECT_BONUS)
end

--得到参与连线的固定小块
function CodeGameScreenThanksGivingMachine:getSpecialReelNode(matrixPos)
    local slotNode = CodeGameScreenThanksGivingMachine.super.getSpecialReelNode(self,matrixPos)
    if slotNode == nil then
        --如果为空则从 root获取
        local childs = self:findChild("root"):getChildren()
        for index=1, #childs do
            local slotNode = childs[index]
            if slotNode ~= nil and slotNode:getTag() > SYMBOL_FIX_NODE_TAG then
                if slotNode.p_layerTag ~= nil then
                    if slotNode:isInLinePos(matrixPos) then
                        return slotNode
                    end
                end
            end
        end
    end
    return slotNode
end
function CodeGameScreenThanksGivingMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    self:showLineFrame()
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.5)
    else
        if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
            performWithDelay(self, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, 0.5)
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    return true
end
--[[
    @desc: 计算单线
    time:2018-08-16 19:35:49
    --@lineData: 
    @return:
]]
function CodeGameScreenThanksGivingMachine:getWinLineSymboltType(winLineData,lineInfo )
    local iconsPos = winLineData.p_iconPos
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for posIndex=1,#iconsPos do
        local posData = iconsPos[posIndex]
        
        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData  -- 连线元素的 pos信息
            
        local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD and symbolType ~= self.SYMBOL_SCORE_BONUS 
            and not (symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and self:oneColIsDropedWildForData(rowColData.iY)) then
            enumSymbolType = symbolType
        end
    end
    return enumSymbolType
end
--隐藏轮盘边框扫光
function CodeGameScreenThanksGivingMachine:hideReelLight()
    performWithDelay(self,function ()
        for i = 1,6 do
            self:findChild("guang_"..i):setVisible(false)
            if i <= self.m_iReelColumnNum then
                self:findChild("reel_saoguang_"..i):setVisible(false)
                self:findChild("reel_saoguang_"..i + self.m_iReelColumnNum):setVisible(false)
            end
        end
    end,0.5)
end
--播放轮盘边框扫光 endFunc扫光结束调用 nearlyCompletedFunc扫光快结束调用
function CodeGameScreenThanksGivingMachine:showReelLightAni(colTab,endFunc,nearlyCompletedFunc)
    gLobalSoundManager:playSound("ThanksGivingSounds/music_ThanksGiving_ReelLight.mp3")
    if #colTab > 0 then
        for i,col in ipairs(colTab) do
            self:findChild("guang_"..col):setVisible(true)
            self:findChild("guangshangparticle_"..col):setPositionType(0)
            self:findChild("guangshangparticle_"..col):resetSystem()
            self:findChild("guang_"..col + 1):setVisible(true)
            self:findChild("guangshangparticle_"..col + 1):setPositionType(0)
            self:findChild("guangshangparticle_"..col + 1):resetSystem()

            self:findChild("reel_saoguang_"..col):setVisible(true)
            self:findChild("reel_saoguang_"..col + 5):setVisible(true)
        end
    else
        self:findChild("guang_1"):setVisible(true)
        self:findChild("guangshangparticle_1"):setPositionType(0)
        self:findChild("guangshangparticle_1"):resetSystem()
        self:findChild("guang_6"):setVisible(true)
        self:findChild("guangshangparticle_6"):setPositionType(0)
        self:findChild("guangshangparticle_6"):resetSystem()
    end
    
    
    if nearlyCompletedFunc then
        performWithDelay(self,function ()
            nearlyCompletedFunc()
        end,9/30)
    end
    self:runCsbAction("actionframe",false,function ()
        self:hideReelLight()
        if endFunc then
            endFunc()
        end
    end)
end
--通过服务器数据判断某一列是否落下wild（不管什么时候落下的，只管最后是否落了）
function CodeGameScreenThanksGivingMachine:oneColIsDropedWildForData(col)
    if self.m_runSpinResultData.p_selfMakeData then
        if self.m_runSpinResultData.p_selfMakeData.dropColumns then
            for i,v in ipairs(self.m_runSpinResultData.p_selfMakeData.dropColumns) do
                if col == v + 1 then
                    return true
                end
            end
        end
        if self.m_runSpinResultData.p_selfMakeData.fullColumns then
            for i,v in ipairs(self.m_runSpinResultData.p_selfMakeData.fullColumns) do
                if col == v + 1 then
                    return true
                end
            end
        end
        if self.m_runSpinResultData.p_selfMakeData.dropWildColumns then
            for i,v in ipairs(self.m_runSpinResultData.p_selfMakeData.dropWildColumns) do
                if col == v + 1 then
                    return true
                end
            end
        end
    end
    return false
end
--通过落下图标对象检测某一列是否落下wild(注意在wild落下后删除前调用)
function CodeGameScreenThanksGivingMachine:oneColIsDropedWildForDropWildNode(col)
    if #self.m_dropedWildTab[col] > 0 then
        return true
    end
    return false
end
--显示轮盘上的半透明遮罩
function CodeGameScreenThanksGivingMachine:showReelTranslucentMask(func)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if func then
            func()
        end
        return
    end
    if self.m_reelTranslucentMask:isVisible() == false then
        self.m_reelTranslucentMask:setVisible(true)
        self.m_reelTranslucentMask:playAction("show",false,function ()
            if func then
                func()
            end
        end)
    end
end
--隐藏轮盘上的半透明遮罩
function CodeGameScreenThanksGivingMachine:hideReelTranslucentMask(func)
    if self.m_reelTranslucentMask:isVisible() == true then
        self.m_reelTranslucentMask:playAction("hide",false,function ()
            self.m_reelTranslucentMask:setVisible(false)
            if func then
                func()
            end
        end)
    end
end

function CodeGameScreenThanksGivingMachine:setReelRunInfo()
    local haveFullWildCol = false
    for iCol = 1,self.m_iReelColumnNum do
        -- 整列
        if self:oneColIsDropedWildForDropWildNode(iCol) then
            haveFullWildCol = true
            break
        end
    end

    if haveFullWildCol then
        print(" 如果现在界面上有满列的wild，就不要快滚（前面有两个scatter也不要快滚）")
    else
        BaseNewReelMachine.setReelRunInfo(self)
    end
end

function CodeGameScreenThanksGivingMachine:updateNetWorkData()
    BaseNewReelMachine.updateNetWorkData(self)
    self:updateAllTopWildData()
end

function CodeGameScreenThanksGivingMachine:updateAllTopWildData()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local columnWilds = selfdata.columnWilds or {}

    local currTotalBet = globalData.slotRunData:getCurTotalBet()
    self.m_baseWildData[tostring(currTotalBet)] = columnWilds
end

function CodeGameScreenThanksGivingMachine:betChangeNotify(isLevelUp)
    
    if isLevelUp then
    else
        -- 切换bet修改顶部wild排列
        self:removeAllWild()
        self:normalUpdateWildBarWild()

        --没有数据时切bet改变jackpot显示
        if self.m_runSpinResultData.p_selfMakeData == nil then
            self.m_jackpotBar:setLable(false)
        end
    end

end

-- free选择不再播放震动
function CodeGameScreenThanksGivingMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if "bonus" == _sFeature then
        return
    end
    if CodeGameScreenThanksGivingMachine.super.levelDeviceVibrate then
        CodeGameScreenThanksGivingMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenThanksGivingMachine