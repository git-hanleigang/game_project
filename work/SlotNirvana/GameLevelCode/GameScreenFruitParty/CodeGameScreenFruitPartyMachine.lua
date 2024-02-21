---
-- island li
-- 2019年1月26日
-- CodeGameScreenFruitPartyMachine.lua
-- 
-- 玩法：
-- 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local BaseMachine = require "Levels.BaseMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenFruitPartyMachine = class("CodeGameScreenFruitPartyMachine", BaseNewReelMachine)

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

CodeGameScreenFruitPartyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenFruitPartyMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型

CodeGameScreenFruitPartyMachine.OPEN_BONUS_SPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 开奖
CodeGameScreenFruitPartyMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 中jackpot
CodeGameScreenFruitPartyMachine.WIN_SPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 中spot
CodeGameScreenFruitPartyMachine.CHANGE_BIG_SYMBOL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 -- 自定义动画的标识


CodeGameScreenFruitPartyMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenFruitPartyMachine.SYMBOL_SCORE_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

--轮底
local HAVE_LUNDI_TAG    =       1000    --显示轮底
local SYMBOL_DI_1       =       1001
local SYMBOL_DI_2       =       1002
local SYMBOL_DI_3       =       1003

-- 构造函数
function CodeGameScreenFruitPartyMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_spinRestMusicBG = true
    self.m_isShowOutGame = false
    self.m_isShowSystemView = false
    self.m_isBonusPlaying = false
    self.m_isQuickRun = false
    --添加头像缓存
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")
    self.m_isJackpotQuickRun = {}
    for iCol = 1,5 do
        self.m_isJackpotQuickRun[iCol] = false
    end

    self.m_bEnterGame = true --首次进入关卡
    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end

function CodeGameScreenFruitPartyMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}

    self.m_configData = gLobalResManager:getCSVLevelConfigData("FruitPartyConfig.csv", "LevelFruitPartyConfig.lua")

    -- 中奖音效
    self.m_winPrizeSounds = {}
    for i = 1, 3 do
        self.m_winPrizeSounds[#self.m_winPrizeSounds + 1] = "FruitPartySounds/sound_FruitParty_win_" .. i .. ".mp3"
    end
    
end  

--[[
    退出到大厅
]]
function CodeGameScreenFruitPartyMachine:showOutGame( )

    if self.m_isShowOutGame then
        return
    end
    self.m_isShowOutGame = true
    local view = util_createView("CodeFruitPartySrc.FruitPartyGameOut")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFruitPartyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FruitParty"  
end




function CodeGameScreenFruitPartyMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("reelNode"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    

    --jackpot
    self.m_jackpotBar = util_createView("CodeFruitPartySrc.FruitPartyJackPotBarView",{machine = self})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    --jackpot快滚框
    self.m_jackpot_run = util_createAnimation("FruitParty_jp_run.csb")
    self:findChild("reelNode"):addChild(self.m_jackpot_run)
    self.m_jackpot_run:setPosition(util_convertToNodeSpace(self:findChild("reelNode"),self:findChild("reelNode")))
    self.m_jackpot_run:setVisible(false)

    --房间列表
    self.m_roomList = util_createView("CodeFruitPartySrc.FruitPartyRoomListView", {machine = self})
    self:findChild("Node_Room"):addChild(self.m_roomList)
    self.m_roomData = self.m_roomList.m_roomData

    --邮件按钮
    self.m_MailTip = util_createView("CodeFruitPartySrc.FruitPartyMailTip",{machine = self})
    self:findChild("Node_Mail"):addChild(self.m_MailTip)
    self.m_MailTip:setVisible(false)
 
    self.m_SpotOpenView = util_createView("CodeFruitPartySrc.FruitPartySpotOpenView",{machine = self})
    self:findChild("Node_SpotNum"):addChild(self.m_SpotOpenView)
    self:findChild("Node_SpotNum"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10000)
    
    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10000 - 1)
    end
    

    --bonus轮子
    self.m_machine_bonus = self:createrOneReel()
    self:findChild("Node_SpotBonusView"):addChild(self.m_machine_bonus)
    self:findChild("Node_SpotBonusView"):setScale(self:getScaleForBonusNode(1400,550))
    self.m_machine_bonus:setPosition(cc.p(-display.width / 2,-display.height / 2))
    --显示基础轮盘
    self:setBaseReelShow(true)

    --轮底特效
    self.m_effect_jackpot_bg = {}
    for iCol = 1,self.m_iReelColumnNum do
        local ani = util_createAnimation("Socre_FruitParty_jp_L.csb")
        self.m_effect_jackpot_bg[iCol] = ani
        -- ani:runCsbAction("actionframe",true)

        local sp_reel = self:findChild("sp_reel_"..(iCol - 1))
        local size = sp_reel:getContentSize()
        local pos = cc.p(sp_reel:getPosition())

        self:findChild("reelNode"):addChild(ani)
        ani:setPosition(cc.p(pos.x + size.width / 2,pos.y + size.height / 2))
        ani:setVisible(false)
    end

    --过场动画
    self.m_changSceneAni = util_createAnimation("FruitParty_guochang.csb")
    self.m_changSceneAni:setVisible(false)
    self:addChild(self.m_changSceneAni, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 4)
    self.m_changSceneAni:setPosition(cc.p(display.width / 2, display.height / 2))

    self.m_changSceneAni2 = util_spineCreate("Socre_FruitParty_Bonus", true, true)
    self.m_changSceneAni2:setVisible(false)
    self:addChild(self.m_changSceneAni2, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5)
    self.m_changSceneAni2:setPosition(cc.p(display.width / 2, display.height / 2))

    self.m_effectNode2 = cc.Node:create()
    self:addChild(self.m_effectNode2, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 4)

    --补足下方轮底
    self.m_symbol_di_bottom = {}
    self.m_symbol_di_bottom_parent = {}
    local slotsParents = self.m_slotParents
    for iCol = 1, #slotsParents do
        self.m_symbol_di_bottom[iCol] = {}
        local parentData = slotsParents[iCol]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local parentNode = slotParent:getParent()

        local size = slotParent:getContentSize()
        local pos = cc.p(slotParent:getPosition()) 
        for iRow = 1,3 do
            local symbol_di = util_createAnimation("Socre_FruitParty_jp_"..iRow..".csb") 
            slotParent:addChild(symbol_di)
            symbol_di:setPosition(cc.p(pos.x + size.width / 2,pos.y - size.height / 3 / 2))
            self.m_symbol_di_bottom[iCol][iRow] = symbol_di
            symbol_di:setVisible(false)
        end
        
    end
end

function CodeGameScreenFruitPartyMachine:getScaleForBonusNode(width,height)
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / height
    local wScale = winSize.width / width
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
    end
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
        end
    end
    return mainScale
end

function CodeGameScreenFruitPartyMachine:createrOneReel()
    local className = "CodeFruitPartySpecialReel.FruitPartyMiniMachine"

    local params = {
        index = 1,
        parent = self,
        maxReelIndex  = 1
    }
    local miniReel = util_createView(className,params)

    return miniReel
end


function CodeGameScreenFruitPartyMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function()
        if not self.m_isShowMail then
            self:playEnterGameSound( "FruitPartySounds/sound_FruitParty_enter_game.mp3" )
        end
        
        scheduler.performWithDelayGlobal(function(  )
            if self.m_isTriggerBonus then
                return
            end
            self:resetMusicBg()
            self:reelsDownDelaySetMusicBGVolume( ) 
        end,3,self:getModuleName())
    end,0.4,self:getModuleName())
end

function CodeGameScreenFruitPartyMachine:reelsDownDelaySetMusicBGVolume()
    self:removeSoundHandler()


    self.m_soundHandlerId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_soundHandlerId = nil
            local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0

            self.m_soundGlobalId =
                scheduler.scheduleGlobal(
                function()
                    --播放广告过程中暂停逻辑
                    if gLobalAdsControl ~= nil and gLobalAdsControl.getPlayAdFlag ~= nil and gLobalAdsControl:getPlayAdFlag() then
                        return
                    end

                    if volume <= 0 then
                        volume = 0
                    end

                    print("缩小音量 = " .. tostring(volume))
                    gLobalSoundManager:setBackgroundMusicVolume(volume)

                    if volume <= 0 then
                        if self.m_soundGlobalId ~= nil then
                            scheduler.unscheduleGlobal(self.m_soundGlobalId)
                            self.m_soundGlobalId = nil
                        end
                    end

                    volume = volume - 0.04
                end,
                0.1
            )
        end,
        10,
        "SoundHandlerId"
    )

    self:setReelDownSoundFlag(true)
end

function CodeGameScreenFruitPartyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_bottomUI.m_showPopUpUIStates = false

    self:showOrHideMailTip()

    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"animation0",true})
end

function CodeGameScreenFruitPartyMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local gameBg_1 = util_createView("views.gameviews.GameMachineBG")
    local bgNode =  self:findChild("bg")

    if bgNode  then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        bgNode:addChild(gameBg_1, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        self:addChild(gameBg_1, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
    end
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    gameBg_1.m_ccbClassName = "GameScreenFruitPartyBg_1"
    gameBg_1:createCsbNode("FruitParty/GameScreenFruitPartyBg_1.csb",true)
    gameBg_1:runCsbAction("animation0", true)   

    self.m_gameBg = gameBg
    self.m_gameBg1 = gameBg_1
end

function CodeGameScreenFruitPartyMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    --刷新中spot格子
    gLobalNoticManager:addObserver(self,function(self, params)
        --没有房间不刷新
        local playersInfo = self.m_roomData:getRoomRanks()
        if #playersInfo == 0 then
            return
        end
        self.m_SpotOpenView:refreshSpotItem()
    end,ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_OPEN_SPOT)

    --重置开奖信息
    gLobalNoticManager:addObserver(self,function(self, params)
        self.m_SpotOpenView:resetBonusViewData()
    end,ViewEventType.NOTIFY_LOTTO_PARTY_RESET_BONUS_SPOT)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end

        if self.m_bIsBigWin then
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


    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenFruitPartyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    self.m_roomList:onExit()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFruitPartyMachine:MachineRule_GetSelfCCBName(symbolType)

    -- print("symbolType = "..symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_FruitParty_10"
    end

    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_FruitParty_Bonus"
    end
    
    return nil
end


--[[
    显示基础轮盘
]]
function CodeGameScreenFruitPartyMachine:setBaseReelShow(isShow)
    self:findChild("reelNode"):setVisible(isShow)
    self:findChild("Node_Mail"):setVisible(isShow)
    self:findChild("Node_Room"):setVisible(isShow)
    self:findChild("Node_SpotNum"):setVisible(isShow)

    self:findChild("Node_SpotBonusView"):setVisible(not isShow)

    self.m_gameBg:setVisible(true)
    self.m_gameBg1:setVisible(false)
end

--[[
    显示结算背景
]]
function CodeGameScreenFruitPartyMachine:showBonusOverBg()
    self.m_gameBg:setVisible(false)
    self.m_gameBg1:setVisible(true)
end

--[[
    隐藏bonus轮盘
]]
function CodeGameScreenFruitPartyMachine:hideBonusReel( )
    self:findChild("Node_SpotBonusView"):setVisible(false)
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFruitPartyMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenFruitPartyMachine:MachineRule_initGame(  )

    
end

--
--单列滚动停止回调
--
function CodeGameScreenFruitPartyMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not self.m_isJackpotQuickRun[reelCol] and self.m_jackpot_run:isVisible() then
        gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
        self.m_reelRunSoundTag = -1
        self.m_jackpot_run:setVisible(false)
    end

    local parentData = self.m_slotParents[reelCol]
    parentData.beginReelIndex = parentData.beginReelIndex - 1
    if parentData.beginReelIndex < 1 then
        parentData.beginReelIndex = #parentData.reelDatas
    end

    if selfData and selfData.jackpotCols and selfData.jackpotCols >= reelCol then
        self.m_effect_jackpot_bg[reelCol]:setVisible(true)
        -- local aniName = reelCol >= 3 and "actionframe" or "idleframe"
        local aniName = "idleframe"
        for index = 1,reelCol do
            
            self.m_effect_jackpot_bg[index]:runCsbAction(aniName,true)
        end
    end

    --显示当前中的jackpot
    self:showCurHitJackpot(reelCol)

    local isBonusDown = false
    for iRow=1,self.m_iReelRowNum do
        local symbol = self:getFixSymbol(reelCol, iRow)
        if symbol then
            if self.m_effect_jackpot_bg[reelCol]:isVisible() then
                self:showSymbolLunDi(symbol,-1)
            end

            --落地动画
            if symbol.p_symbolType == self.SYMBOL_SCORE_BONUS then
                isBonusDown = true
                symbol:runAnim("buling",false,function()
                    symbol:runAnim("idleframe")
                end)
            end
        end
    end

    if isBonusDown then

        local soundPath = "FruitPartySounds/sound_FruitParty_bonus_down.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    end

    --隐藏最上层小块,节省性能
    self:delayCallBack(0.3,function()
        local symbol = self:getFixSymbol(reelCol, self.m_iReelRowNum + 1)
        if symbol then
            symbol:setVisible(false)
        end
    end)
    
end

--[[
    显示小块轮底
]]
function CodeGameScreenFruitPartyMachine:showSymbolLunDi(symbol,lunDiType)
    --获取轮底
    local symbol_di_1 = symbol:getChildByTag(SYMBOL_DI_1)
    local symbol_di_2 = symbol:getChildByTag(SYMBOL_DI_2)
    local symbol_di_3 = symbol:getChildByTag(SYMBOL_DI_3)

    symbol_di_1:setVisible(lunDiType == 1)
    symbol_di_2:setVisible(lunDiType == 2)
    symbol_di_3:setVisible(lunDiType == 3)
end

--[[
    显示当前中的jackpot
]]
function CodeGameScreenFruitPartyMachine:showCurHitJackpot(reelCol)
    if self.m_isJackpotQuickRun[reelCol] and reelCol >= 3 then
        if reelCol == 3 then
            self.m_jackpotBar:hitAni("minor")
        elseif reelCol == 4 then
            self.m_jackpotBar:hitAni("major")
        elseif reelCol == 5 then
            self.m_jackpotBar:hitAni("grand")
        end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFruitPartyMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFruitPartyMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenFruitPartyMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("FruitPartySounds/music_FruitParty_custom_enter_fs.mp3")

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

function CodeGameScreenFruitPartyMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("FruitPartySounds/music_FruitParty_over_fs.mp3")

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
function CodeGameScreenFruitPartyMachine:MachineRule_SpinBtnCall()
    -- self:setMaxMusicBGVolume( )
    self.m_bEnterGame = false

    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenFruitPartyMachine:logObj(obj)
    
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenFruitPartyMachine:showDialog(ccbName,ownerlist,func,isAuto,index,isView)
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

--判断是否有3列以上相同的信号块相邻 不包含（bonus wild 低级信号块1,2,3,4,5）
function CodeGameScreenFruitPartyMachine:isNeedChangeBigSymbol()
    local winLines = self.m_runSpinResultData.p_winLines

    if #winLines <= 0 then
        return {isChange = false}
    end

    local function isSameSymbol(_firstType, _tempType)
        --低分信号块 直接退出
        if _firstType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_3 and _firstType < TAG_SYMBOL_TYPE.SYMBOL_WILD then
            return false
        end

        if _tempType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_3 and _tempType < TAG_SYMBOL_TYPE.SYMBOL_WILD then
            return false
        end
        --两个图标不一样 但是有wild
        if _firstType ~= _tempType and (_firstType == TAG_SYMBOL_TYPE.SYMBOL_WILD or _tempType == TAG_SYMBOL_TYPE.SYMBOL_WILD) then
            return true
        end

        if _firstType == _tempType then
            return true
        end

        return false
    end
    --存储每一列是否时相同图标
    local symbolTypeData = {}
    for iCol = 1, self.m_iReelColumnNum do
        local symbolType = nil -- 合图类型
        local bSame = true
        for iRow = 1, self.m_iReelRowNum do
            local tempType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolType = tempType
            end
            if not isSameSymbol(symbolType, tempType) then
                bSame = false
                symbolType = -1
                break
            end
        end
        local symbolData = {}
        symbolData.symbolType = symbolType
        symbolData.bSame = bSame
        symbolTypeData[iCol] = symbolData
    end

    local startCol = 0
    local sameCol = 0
    local symbolType = nil
    for i = 1, #symbolTypeData do
        local data = symbolTypeData[i]
        if data.bSame then
            local tempType = data.symbolType
            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolType = tempType
            end
            if startCol == 0 then
                startCol = i
            end

            if startCol > 3 then
                symbolType = nil
                sameCol = 0
                startCol = 0
                break
            end
            
            if not isSameSymbol(symbolType, tempType) then
                if sameCol >= 3 then
                    break
                end
                symbolType = tempType
                sameCol = 0
                startCol = 0
            end
            sameCol = sameCol + 1
        else
            if i > 3 then
                break
            end
            symbolType = nil
            sameCol = 0
            startCol = 0
        end
        --前三列都是wild 直接返回 不合图
        -- if sameCol >= 3 and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        --     symbolType = nil
        --     sameCol = 0
        --     startCol = 0
        --     break
        -- end
    end

    --判断是否在赢钱线上
    if not self:isHaveWinLineByType(symbolType) then
        return {isChange = false}
    end
    --有3列及以上相同的则可以合图
    if sameCol >= 3 then
        return {isChange = true, changeType = symbolType, startCol = startCol, changeCol = sameCol}
    end
    return {isChange = false}
end

--判断是否在赢钱线上
function CodeGameScreenFruitPartyMachine:isHaveWinLineByType(_symbolType)
    local winLines = self.m_runSpinResultData.p_winLines

    if _symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return true
    end

    local isHave = false
    for i = 1, #self.m_runSpinResultData.p_winLines do
        local line = self.m_runSpinResultData.p_winLines[i]
        if line.p_type == _symbolType then
            isHave = true
            break
        end
    end

    return isHave
end

--[[
    暂停轮盘
]]
function CodeGameScreenFruitPartyMachine:pauseMachine()
    BaseMachine.pauseMachine(self)
    self.m_isShowSystemView = true
    --停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end

--[[
    恢复轮盘
]]
function CodeGameScreenFruitPartyMachine:resumeMachine()
    BaseMachine.resumeMachine(self)
    self.m_isShowSystemView = false
    if self.m_isTriggerBonus then
        return
    end
    --重新刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
end

--[[
    检测是否触发bonus
]]
function CodeGameScreenFruitPartyMachine:checkTriggerBonus()

    --检测是否已经添加过bonus,防止刷新数据时导致二次添加
    for k,gameEffect in pairs(self.m_gameEffects) do
        if gameEffect and gameEffect.p_effectType == GameEffect.EFFECT_BONUS then
            return true
        end
    end
    
    --有玩家触发Bonus
    local result = self.m_roomData:getSpotResult()

    --测试代码
    -- local fileUtil = cc.FileUtils:getInstance()
    -- local fullPath = fileUtil:fullPathForFilename("CodeFruitPartySrc/resultData.json")
    -- local jsonStr = fileUtil:getStringFromFile(fullPath) 
    -- local result = cjson.decode(jsonStr)

    if result then
        --发送停止刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
        self:addBonusEffect(result)
        return true
    end

    return false
end

--[[
    添加Bonus玩法
]]
function CodeGameScreenFruitPartyMachine:addBonusEffect(result)
    self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_CHOOSE_SET_VISIBLE, {isShow = false})

    local effect = GameEffectData.new()
    effect.p_effectType = GameEffect.EFFECT_BONUS
    effect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = effect
    effect.resultData = clone(result) 

    self.m_isTriggerBonus = true
end

--[[
    Bonus玩法
]]
function CodeGameScreenFruitPartyMachine:showEffect_Bonus(effectData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    
    local result = effectData.resultData
    if self.m_isBonusPlaying then
        return
    end
    self.m_isBonusPlaying = true

    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    self:setMaxMusicBGVolume()

    self:removeSoundHandler()
    --bonus结束回调
    local function bonusEnd()

        --变更轮盘状态
        if globalData.slotRunData.m_isAutoSpinAction then
            self:setCurrSpinMode(AUTO_SPIN_MODE)
        else
            self:setCurrSpinMode(NORMAL_SPIN_MODE)
        end

        effectData.p_isPlay = true
        self:playGameEffect()

        self.m_isBonusPlaying = false
        self.m_isTriggerBonus = false

        self:resetMusicBg(false,"FruitPartySounds/music_FruitParty_bgmusic_base.mp3")
        --显示基础轮盘
        self:setBaseReelShow(true)

        

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)

        
    end

    local keyFunc = function(  )
        --隐藏基础轮盘
        self:setBaseReelShow(false)
        self.m_machine_bonus:resetUI(result,bonusEnd)
    end

    --清理连线
    self:clearWinLineEffect()
    --清空赢钱
    self.m_bottomUI:updateWinCount("")
    
    self:changeSceneAni(keyFunc,function(  )
        self.m_machine_bonus:startBonus()

        
        self.m_roomData.m_teamData.room.result = nil
        self.m_roomList:refreshPlayInfo()

        --刷新spot
        self.m_SpotOpenView:refreshSpotItem()
        self.m_SpotOpenView:showBonusComing(false)
    end)
    
    return true
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFruitPartyMachine:addSelfEffect()

    local resultData = self.m_runSpinResultData

    --检测是否触发bonus玩法
    self:checkTriggerBonus()

    self.m_changeBigData = self:isNeedChangeBigSymbol()
    -- 自定义动画创建方式
    if self.m_changeBigData.isChange then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CHANGE_BIG_SYMBOL_EFFECT -- 动画类型
    end

    if not resultData.p_selfMakeData then
        return
    end


    local selfData = resultData.p_selfMakeData

    --中jackpot
    if selfData.jackpotCols and selfData.jackpotCols >= 3 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.QUICKHIT_JACKPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型
    end

     --中spot
     if selfData.collectData then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.WIN_SPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.WIN_SPOT_EFFECT -- 动画类型
        selfEffect.spotResult = selfData.collectData
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFruitPartyMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.OPEN_BONUS_SPOT_EFFECT then --开奖
        
    end
    --合并大图信号
    if effectData.p_selfEffectType == self.CHANGE_BIG_SYMBOL_EFFECT then    
        self:changeBigSymbolEffect(effectData)
    end

    local resultData = self.m_runSpinResultData
    if not resultData.p_selfMakeData then
        return true
    end
    local selfData = resultData.p_selfMakeData
    --中jackpot
    if effectData.p_selfEffectType == self.QUICKHIT_JACKPOT_EFFECT then

        local aniName = "actionframe"
        for index = 1,self.m_iReelColumnNum do
            self.m_effect_jackpot_bg[index]:runCsbAction(aniName,true)
        end
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_jackpot_trigger.mp3")
        
        self:delayCallBack(2.5,function(  )
            self:showJackpotWinView(selfData.jackpot,selfData.jackpotCoins,function(  )
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
        
    elseif effectData.p_selfEffectType == self.WIN_SPOT_EFFECT then 
        --中spot
        local spotResult = effectData.spotResult

        self:delayCallBack(0.5,function(  )
            self:playBonusMoveEffect(effectData)
        end)

        -- self.m_SpotOpenView:showHitSpot(spotResult,function(  )
        --     effectData.p_isPlay = true
        --     self:playGameEffect()
        -- end)
    end

	return true
end

--[[
    设置该列信号是否显示
]]
function CodeGameScreenFruitPartyMachine:setSymbolVisibleByCol(_startCol, _endCol, _bShow)
    if _startCol == 0 or _endCol == 0 then
        return
    end
    for iCol = _startCol, _endCol do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                targSp:setVisible(_bShow)
            end
        end
    end
end

--获取播放大图的中心点 起始列
function CodeGameScreenFruitPartyMachine:getBigSymbolPos(_startCol, _endCol,parentNode)
    if _endCol > 5 then
        _endCol = 5
    end

    local targSp1 = self:getFixSymbol(_startCol, 1, SYMBOL_NODE_TAG)
    local posWorld1 = targSp1:getParent():convertToWorldSpace(cc.p(targSp1:getPositionX(), targSp1:getPositionY()))
    local pos1 = self.m_clipParent:convertToNodeSpace(cc.p(posWorld1.x, posWorld1.y))
    if parentNode then
        pos1 = parentNode:convertToNodeSpace(cc.p(posWorld1.x, posWorld1.y))
    end

    local targSp2 = self:getFixSymbol(_endCol, 3, SYMBOL_NODE_TAG)
    local posWorld2 = targSp2:getParent():convertToWorldSpace(cc.p(targSp2:getPositionX(), targSp2:getPositionY()))
    local pos2 = self.m_clipParent:convertToNodeSpace(cc.p(posWorld2.x, posWorld2.y))
    if parentNode then
        pos2 = parentNode:convertToNodeSpace(cc.p(posWorld2.x, posWorld2.y))
    end
    return cc.pMidpoint(pos1, pos2)
end

function CodeGameScreenFruitPartyMachine:getChangeBigSymbolName(changeType)
    local bigName = ""
    if changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 then
        bigName = "Socre_FruitParty_4"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
        bigName = "Socre_FruitParty_5"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        bigName = "Socre_FruitParty_6"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        bigName = "Socre_FruitParty_7"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        bigName = "Socre_FruitParty_8"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        bigName = "Socre_FruitParty_9"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        bigName = "Socre_FruitParty_Wild"
    end
    return bigName
end

function CodeGameScreenFruitPartyMachine:changeBigSymbolEffect(effectData)
    local changeType = self.m_changeBigData.changeType
    local startCol = self.m_changeBigData.startCol
    local changeCol = self.m_changeBigData.changeCol

    local bigName = self:getChangeBigSymbolName(changeType)
    local endCol = startCol + changeCol - 1
    local pos = self:getBigSymbolPos(startCol, endCol)
    self:setSymbolVisibleByCol(startCol, endCol, false)
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_change_big_symbol.mp3")
    local bigSymbol = util_spineCreate(bigName, true, true)
    local actName = "actionframe" .. changeCol

    local params = {}
    params[1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = bigSymbol,   --执行动画节点  必传参数
        actionName = actName, --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            self:setSymbolVisibleByCol(startCol, endCol, true)
        end,   --回调函数 可选参数
    }
    params[2] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = bigSymbol,   --执行动画节点  必传参数
        actionName = "over"..changeCol, --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            bigSymbol:setVisible(false)
            effectData.p_isPlay = true
            self:playGameEffect()
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)

    bigSymbol:setPosition(pos)
    self.m_effectNode:addChild(bigSymbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    --黄色遮罩
    self:createChangeBigSymbolYellowEffect(changeCol, pos)
end

--变成大信号块 表现时的黄色遮罩
function CodeGameScreenFruitPartyMachine:createChangeBigSymbolYellowEffect(changeCol, pos)
    if changeCol > 5 then
        changeCol = 5
    end

    local effCsb = util_createAnimation("FruitParty_Socre_effect.csb")
    local actName = "actionframe4_" .. changeCol
    effCsb:runCsbAction(
        actName,
        false,
        function()
            effCsb:removeFromParent()
        end,
        60
    )
    effCsb:setPosition(pos)
    for i = 1, changeCol do
        local par = effCsb:findChild("Particle_" .. i)
        par:resetSystem()
        par:setPositionType(0)
    end
    self.m_effectNode:addChild(effCsb, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 10)
end

--[[
    移动bonus信号
]]
function CodeGameScreenFruitPartyMachine:playBonusMoveEffect(effectData)
    if not self:isNeedMoveBonus() then
        self:playMoveBonusReel(effectData)
    else
        self:playChangeBigBonusEffect(effectData)
    end
end

--[[
    合并大信号动作
]]
function CodeGameScreenFruitPartyMachine:playChangeBigBonusEffect(effectData)
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_change_big_symbol_bonus.mp3")
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local changeCol = #selfData.bonusColumns
    --限定列数
    if changeCol < 3 then
        changeCol = 3
    end
    local winSpotNum = 0
    local totalBetNum = 0
    local spotData = {}

    if selfData and selfData.collectData then
        totalBetNum = selfData.collectData.coins
        winSpotNum = selfData.collectData.position + 1
        spotData = selfData.collectData
    end

    local pos = self:getBigSymbolPos(1, changeCol)
    --黄色遮罩
    self:createChangeBigSymbolYellowEffect(changeCol, pos)

    self:setSymbolVisibleByCol(1, changeCol, false)
    if self.m_bonusReel then
        for i = 1, #self.m_bonusReel do
            local bonusReel = self.m_bonusReel[i]
            bonusReel:setVisible(false)
        end
    end

    self.m_spotBigSymbol = util_spineCreate("Socre_FruitParty_Bonus", true, true)
    self.m_spotWinCsb = self:createBigSpotWinNum(changeCol, winSpotNum, totalBetNum)

    self.m_effectNode:addChild(self.m_spotBigSymbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self.m_effectNode:addChild(self.m_spotWinCsb, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)

    self.m_spotBigSymbol:setPosition(pos)
    self.m_spotWinCsb:setPosition(pos)
    local idlefameName = "idleframe" .. changeCol
    util_spinePlay(self.m_spotBigSymbol, idlefameName, false)
    self:delayCallBack(0.3,function(  )
        local actName = "actionframe" .. changeCol
        gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_change_bonus_trigger.mp3")
        util_spinePlay(self.m_spotBigSymbol, actName, false)
        util_spineFrameEvent(self.m_spotBigSymbol,actName,"Show",function()
            self.m_spotWinCsb:runCsbAction("actionframe",false,function()
            end,60)
        end)
        util_spineEndCallFunc(self.m_spotBigSymbol,actName,function()
            local spotResult = effectData.spotResult
            self.m_SpotOpenView:showHitSpot(spotResult,function(  )

                local function showBigSymbolOver(  )
                    local overName = "over" .. changeCol
                    util_spinePlay(self.m_spotBigSymbol, overName)
                    self:setSymbolVisibleByCol(1, self.m_iReelColumnNum, true)

                    if self.m_spotWinCsb then
                        self.m_spotWinCsb:runCsbAction("over",false,function()    
                            self.m_spotWinCsb:removeFromParent(true)
                        end,60)
                    end
                end
                showBigSymbolOver()
                

                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            
        end)
    end)
end

--bigSpot 赢的位置信息
function CodeGameScreenFruitPartyMachine:createBigSpotWinNum(changeCol, winSpotNum, totalBetNum)
    local winCsb = util_createAnimation("FruitParty_SpotTrigger.csb")
    -- local spotNumLab = winCsb:findChild("m_lb_num")
    local totalBetLab = winCsb:findChild("m_lb_num_tb")
    -- spotNumLab:setString(tostring(winSpotNum))
    totalBetLab:setString(util_formatCoins(totalBetNum, 10))

    local info={label=totalBetLab,sx=1,sy=1}
    self:updateLabelSize(info,410)

    local Panel3 = winCsb:findChild("Panel_3")
    local Panel4 = winCsb:findChild("Panel_4")
    local Panel5 = winCsb:findChild("Panel_5")
    Panel3:setVisible(false)
    Panel4:setVisible(false)
    Panel5:setVisible(false)
    if changeCol == 3 then
        Panel3:setVisible(true)
    elseif changeCol == 4 then
        Panel4:setVisible(true)
    elseif changeCol == 5 then
        Panel5:setVisible(true)
    end
    return winCsb
end

--[[
    是否需要移动bonus
]]
function CodeGameScreenFruitPartyMachine:isNeedMoveBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --scatter所在整列
    local bonusColumns = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolType = self.m_runSpinResultData.p_reelsData[iRow][iCol]
            if symbolType == self.SYMBOL_SCORE_BONUS then
                table.insert(bonusColumns,#bonusColumns + 1,iCol - 1)
                break
            end
        end
    end

    selfData.bonusColumns = bonusColumns

    local startReel = 0
    for i, v in ipairs(bonusColumns) do
        if startReel ~= v then
            return false
        end
        startReel = startReel + 1
    end
    return true
end

--[[
    移动bonus列
]]
function CodeGameScreenFruitPartyMachine:playMoveBonusReel(effectData)
    self.m_bonusReel = {}
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local moveLeftTime = 0.25
    local moveRightTime = 0.25
    local maxTime = moveLeftTime + moveRightTime - 0.1
    --Bonus所在整列
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_change_big_symbol_move.mp3")
    if selfData and selfData.bonusColumns then
        local startReel = 1
        local needMoveColNum = 0
        for i, v in ipairs(selfData.bonusColumns) do
            local col = v + 1
            local bonusReel = self:createMoveBonusReel(col)
            if bonusReel then
                if startReel ~= col then
                    needMoveColNum = needMoveColNum + 1
                    local penEffectCol = startReel
                    local movePos = self:getMoveToPos(startReel)
                    local actList = {}
                    local endPos = movePos.x
                    if penEffectCol ~= 1 then
                        endPos = movePos.x - 20
                    end
                    actList[#actList + 1] = cc.DelayTime:create(0.2 * (needMoveColNum - 1))
                    actList[#actList + 1] = cc.MoveTo:create(moveLeftTime, cc.p(endPos, movePos.y))
                    actList[#actList + 1] =
                        cc.CallFunc:create(
                        function()
                            if penEffectCol ~= 1 then
                                self:createPenEffect(penEffectCol)
                            end

                        end
                    )
                    actList[#actList + 1] = cc.MoveTo:create(moveRightTime, cc.p(movePos.x, movePos.y))

                    local sq = cc.Sequence:create(actList)
                    bonusReel:runAction(sq)
                    maxTime = maxTime + 0.2 * (needMoveColNum - 1)
                end
                table.insert(self.m_bonusReel, bonusReel)
            end
            startReel = startReel + 1
        end
    end

    self:setAllSymbolVisible(false)

    self:delayCallBack(maxTime,function()
        for iCol = 1,self.m_iReelColumnNum do
            local penEffect = self.m_effectNode:getChildByTag(1000 + iCol)
            if penEffect then
                penEffect:setVisible(false)
            end
        end
        self:playChangeBigBonusEffect(effectData)
    end)
end

--[[
    设置所有信号是否显示
]]
function CodeGameScreenFruitPartyMachine:setAllSymbolVisible(_bShow)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local changeCol = 0
    if selfData and selfData.bonusColumns then
        changeCol = #selfData.bonusColumns
    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                if targSp.p_symbolType == self.SYMBOL_BONUS_1 then
                    targSp:runAnim("idleframe")
                end

                targSp:setVisible(_bShow)
            end
        end
    end
end

--创建移动的列
function CodeGameScreenFruitPartyMachine:createMoveBonusReel(_col)
    local targSp = self:getFixSymbol(_col, 1, SYMBOL_NODE_TAG)
    local posWorld = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))

    local bonusReel = cc.Node:create()
    bonusReel:setPosition(pos)
    self.m_clipParent:addChild(bonusReel, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 1)

    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(_col, iRow, SYMBOL_NODE_TAG)
        if targSp then
            local bonusSymbol = self:createMoveBonus()
            local posWorld = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
            local pos = bonusReel:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            local zorder = targSp:getLocalZOrder()
            bonusSymbol:setPosition(pos)
            bonusReel:addChild(bonusSymbol, zorder)
        end
    end
    return bonusReel
end

function CodeGameScreenFruitPartyMachine:createMoveBonus()
    local bonusSymbol = util_spineCreate("Socre_FruitParty_Bonus", true, true)
    util_spinePlay(bonusSymbol, "idleframe", false)
    return bonusSymbol
end

function CodeGameScreenFruitPartyMachine:getMoveToPos(_col)
    local targSp = self:getFixSymbol(_col, 1, SYMBOL_NODE_TAG)
    local posWorld = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
    return pos
end

--[[
    列合并动效
]]
function CodeGameScreenFruitPartyMachine:createPenEffect(_col)
    local penEffect = util_createAnimation("FruitParty_Socrereel_effect.csb")

    self.m_effectNode:addChild(penEffect)
    penEffect:setTag(1000 + _col)

    local sp_reel = self:findChild("sp_reel_"..(_col - 1))
    local pos = util_convertToNodeSpace(sp_reel,self.m_effectNode)
    local size = sp_reel:getContentSize()
    penEffect:setPosition(cc.p(pos.x, pos.y + size.height / 2))
    penEffect:runCsbAction(
        "actionframe",
        false,
        function()
            penEffect:removeFromParent()
        end,
        60
    )
    return penEffect
end

--[[
    显示jackpot
]]
function CodeGameScreenFruitPartyMachine:showJackpotWinView(jackpotType,coins,func)
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_show_jackpot.mp3")
    local jackPotWinView = util_createView("CodeFruitPartySrc.FruitPartyJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)

    jackPotWinView:findChild("root"):setScale(self.m_machineRootScale)
    local curCallFunc = function(  )

        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
            self.m_iOnceSpinLastWin, true, true
        })

        self:resetMusicBg()
        self:reelsDownDelaySetMusicBGVolume() 

        if func then
            func()
        end
    end
    jackPotWinView:initViewData(self,jackpotType,coins,curCallFunc)
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFruitPartyMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenFruitPartyMachine:playEffectNotifyNextSpinCall( )
    BaseNewReelMachine.playEffectNotifyNextSpinCall( self )
    self:setMaxMusicBGVolume( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenFruitPartyMachine:slotReelDown( )

    self.m_jackpot_run:setVisible(false)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = -1
    self.m_isQuickRun = false

    for iCol = 1,self.m_iReelColumnNum do
        self.m_isJackpotQuickRun[iCol] = false
    end
    self:setMaxMusicBGVolume( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    
    self.m_roomList:refreshPlayInfo()
    --其他玩家大赢事件
    local eventData = self.m_roomData:getRoomEvent()
    self.m_roomList:showBigWinAni(eventData)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    --不是自己中spot,刷新当前spotview
    if not (selfData and selfData.collectData and selfData.collectData.udid == globalData.userRunData.userUdid) then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_OPEN_SPOT)
    end
    


    BaseNewReelMachine.slotReelDown(self)
end

--[[
    准备停止
]]
function CodeGameScreenFruitPartyMachine:perpareStopReel()
    for i=1,#self.m_reels do
        local runLen = self.m_reelRunInfo[i]:getReelRunLen()

        self.m_reelRunInfo[i]:setReelRunLen(runLen)
        
        self.m_reels[i]:perpareStopReel(runLen)
        
        local parentData = self.m_slotParents[i]
        local columnData = self.m_reelColDatas[i]
        parentData.lastReelIndex = columnData.p_showGridCount -- 从最初起始开始滚动
        self.m_configData:prepareStop(parentData,runLen,self.m_LunDiAry)
    end
end

--开始滚动
function CodeGameScreenFruitPartyMachine:beginReel()
    self:setMaxMusicBGVolume( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    self.m_jackpotBar:idleAni()
    self.m_isTriggerBonus = false
    --重置自动退出时间间隔
    self.m_roomList:resetLogoutTime()
    --隐藏轮底特效
    for iCol = 1,self.m_iReelColumnNum do
        if self.m_effect_jackpot_bg[iCol]:isVisible() then
            local temp = {3,2,1}
            for iRow = 1,self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol, iRow)
                if symbol then
                    self:showSymbolLunDi(symbol,temp[iRow])
                end
            end
        end
        
        local symbol = self:getFixSymbol(iCol, self.m_iReelRowNum + 1)
        if symbol then
            symbol:setVisible(true)
        end
        self.m_effect_jackpot_bg[iCol]:setVisible(false)
    end


    self.m_ScatterShowCol = {3,4,5}
    self.m_bottomUI.m_showPopUpUIStates = true
    self.m_effectNode:removeAllChildren(true)
    self.m_effectNode2:removeAllChildren(true)

    self:resetReelDataAfterReel()
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
            self:addJumoActionAfterReel(slotParent,slotParentBig,parentData.cloumnIndex)
        else
            self:registerReelSchedule()
        end
        self:checkChangeClipParent(parentData)
    end
    self:checkChangeBaseParent()

    self:beginNewReel()
end

--[[
    @desc: 开始滚动之前添加向上跳动作
    time:2020-07-21 19:23:58
    @return:
]]
function CodeGameScreenFruitPartyMachine:addJumoActionAfterReel(slotParent,slotParentBig,colIndex)
    --添加一个回弹效果
    local action0 = cc.JumpTo:create(self.m_configData.p_reelBeginJumpTime,
        cc.p(slotParent:getPositionX(), slotParent:getPositionY()),
        self.m_configData.p_reelBeginJumpHight,1)

    local sequece =
        cc.Sequence:create(
        {
            action0,
            cc.CallFunc:create(
                function()
                    for iRow = 1,self.m_iReelRowNum do
                        self.m_symbol_di_bottom[colIndex][iRow]:setVisible(false)
                    end
                    self:registerReelSchedule()
                end
            )
        }
    )

    slotParent:runAction(sequece)
    if slotParentBig then
        slotParentBig:runAction(action0:clone())
    end

    if not self.m_LunDiAry then
        return
    end
    --计算需显示轮底
    if self.m_LunDiAry[1][colIndex] == 2 then
        self.m_symbol_di_bottom[colIndex][3]:setVisible(true)
    elseif self.m_LunDiAry[1][colIndex] == 1 then
        self.m_symbol_di_bottom[colIndex][2]:setVisible(true)
    end
end

--消息返回
function CodeGameScreenFruitPartyMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or spinData.action == "FEATURE" then
        release_print("消息返回胡来了")
        print(cjson.encode(spinData))

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)
        if spinData.action == "FEATURE" then
            self:showJackpotSymbleWin()
        end

        if spinData.action == "SPIN" then
            self:updateNetWorkData()

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
function CodeGameScreenFruitPartyMachine:lockSymbol()
    for k,parentData in pairs(self.m_slotParents) do
        parentData.lockSymbol = self:getColIsSameSymbol(parentData.cloumnIndex)
    end
end

--[[
    判断该列整列信号是否相同
]]
function CodeGameScreenFruitPartyMachine:getColIsSameSymbol(iCol)
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

--随机信号
function CodeGameScreenFruitPartyMachine:getReelSymbolType(parentData)
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end

    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
    end

    --判断小块是否已被锁定
    if not self.m_isQuickRun and parentData.lockSymbol and parentData.lockSymbol ~= -1 then
        symbolType = parentData.lockSymbol
    end

    
    return symbolType
end

--[[
    刷新小块
]]
function CodeGameScreenFruitPartyMachine:updateReelGridNode(node)
    --获取轮底
    local symbol_di_1 = node:getChildByTag(SYMBOL_DI_1)
    local symbol_di_2 = node:getChildByTag(SYMBOL_DI_2)
    local symbol_di_3 = node:getChildByTag(SYMBOL_DI_3)

    --创建轮底
    if not symbol_di_1 then
        symbol_di_1 = util_createAnimation("Socre_FruitParty_jp_1.csb") 
        node:addChild(symbol_di_1)
        symbol_di_1:setTag(SYMBOL_DI_1)
    end
    if not symbol_di_2 then
        symbol_di_2 = util_createAnimation("Socre_FruitParty_jp_2.csb") 
        node:addChild(symbol_di_2)
        symbol_di_2:setTag(SYMBOL_DI_2)
    end
    if not symbol_di_3 then
        symbol_di_3 = util_createAnimation("Socre_FruitParty_jp_3.csb") 
        node:addChild(symbol_di_3)
        symbol_di_3:setTag(SYMBOL_DI_3)
    end
    local curIndex = -1
    local parentData = node.m_parentData or {m_isLastSymbol = false}

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if parentData and not parentData.m_isLastSymbol then
        curIndex = parentData.beginReelIndex or -1
    end

    
    local lundi_type = self.m_configData:getLunDiType(node.p_cloumnIndex,curIndex)
    if parentData and parentData.m_isLastSymbol and self.m_LunDiAry then
        lundi_type = self.m_LunDiAry[parentData.rowIndex][parentData.cloumnIndex]
    end

    -- if node.p_cloumnIndex == 5 then
    --     print("col_"..node.p_cloumnIndex..",lundi_type = "..lundi_type..",curIndex = "..curIndex)
    -- end

    symbol_di_1:setVisible(lundi_type == 1)
    symbol_di_2:setVisible(lundi_type == 2)
    symbol_di_3:setVisible(lundi_type == 3)
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenFruitPartyMachine:checkUpdateReelDatas(parentData )
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
        --判断轮底类型,轮底类型不为3则需要改变开始索引
        local lundi_type = self.m_configData:getLunDiType(parentData.cloumnIndex,parentData.beginReelIndex)
        if lundi_type == 3 then
            parentData.beginReelIndex = parentData.beginReelIndex + 3
        elseif lundi_type == 2 then
            parentData.beginReelIndex = parentData.beginReelIndex + 2
        elseif lundi_type == 1 then
            parentData.beginReelIndex = parentData.beginReelIndex + 1
        end

        --判断是否越界
        if parentData.beginReelIndex > #reelDatas then
            parentData.beginReelIndex = 1
        end
    end

    parentData.lockSymbol = self:getColIsSameSymbol(parentData.cloumnIndex)

    return reelDatas

end

function CodeGameScreenFruitPartyMachine:setReelRunInfo()
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
        bonusNum, bRunLong = self:setBonusScatterInfo(self.SYMBOL_SCORE_BONUS, col , bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenFruitPartyMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)

    local selfData = self.m_runSpinResultData.p_selfMakeData

    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  false,false

    local soundType = runStatus.DUANG
    local nextReelLong = false
    local isJackpotLongRun = false

    local showCol = self.m_ScatterShowCol

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    --判断图标是否满列
    local isFullSymbol = true
    for row = 1, iRow do

        if self:getSymbolTypeForNetData(column,row,runLen) ~= symbolType then
            isFullSymbol = false
        end
    end

    --图标满列
    if isFullSymbol then
        allSpecicalSymbolNum = allSpecicalSymbolNum + 1
    end

    soundType, nextReelLong,isJackpotLongRun = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
    if nextReelLong then
        bRun, bPlayAni = true,true
    else
        if column == 3 then
            self.m_ScatterShowCol = {3}
        elseif column == 4 then
            self.m_ScatterShowCol = {3,4}
        end
    end
    -- if not nextReelLong then
    --     bRun = false
    --     bRunLong = false
    -- end

    for row = 1, iRow do
        local bPlaySymbolAnima = bPlayAni
        
        if bRun == true then

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

    self.m_isJackpotQuickRun[column] = isJackpotLongRun


    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenFruitPartyMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end

    local soundType, nextReelLong,isJackpotLongRun = runStatus.NORUN, false,false

    if nodeNum >= 2 and col >= 2 then
        soundType = runStatus.DUANG
        nextReelLong = true
    end



    local selfData = self.m_runSpinResultData.p_selfMakeData
    if col >= 2 and selfData and selfData.jackpotCols and selfData.jackpotCols >= 2 and col <= selfData.jackpotCols then
        isJackpotLongRun = true
        soundType = runStatus.DUANG
        nextReelLong = true
    end


    
    return soundType, nextReelLong,isJackpotLongRun
end

---
--添加金边
function CodeGameScreenFruitPartyMachine:creatReelRunAnimation(col)
    
    

    if self.m_isJackpotQuickRun[col - 1] then

        if self.m_reelRunSoundTag == -1 then
            self.m_reelRunSoundTag = gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_quick_run_spot.mp3")
        end

        self.m_jackpot_run:setVisible(true)
        if col == 3 then
            self.m_jackpot_run:runCsbAction("actionframe1",true)
        elseif col == 4 then
            self.m_jackpot_run:runCsbAction("actionframe2",true)
        elseif col == 5 then
            self.m_jackpot_run:runCsbAction("actionframe3",true)
        end
        return        
    end

    self.m_isQuickRun = true
    local parentData = self.m_slotParents[col]
    if parentData then
        parentData.lockSymbol = -1
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = -1
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)

    for iCol = 1,self.m_iReelColumnNum do
        if self.m_isJackpotQuickRun[iCol] then
            return
        end
    end

    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)


    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    if self.m_reelBgEffectName ~= nil then   -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        -- if self.m_bProduceSlots_InFreeSpin == true then
        -- else
        -- end

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    
end

--[[
    延迟回调
]]
function CodeGameScreenFruitPartyMachine:delayCallBack(time, func)
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
    过场动画
]]
function CodeGameScreenFruitPartyMachine:changeSceneAni(func1,endFunc)
    self.m_changSceneAni:setVisible(true)
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_change_scene.mp3")
    self.m_changSceneAni:runCsbAction("actionframe",false,function(  )
        self.m_changSceneAni:setVisible(false)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self.m_changSceneAni2:setVisible(true)
    util_spinePlay(self.m_changSceneAni2, "guochang")
    util_spineEndCallFunc(self.m_changSceneAni2,"guochang",function()
        self.m_changSceneAni2:setVisible(false)
    end)

    self:delayCallBack(100 / 60,function(  )
        if type(func1) == "function" then
            func1()
        end
    end)
end


function CodeGameScreenFruitPartyMachine:showOrHideMailTip()
    if self.m_isTriggerBonus then
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
function CodeGameScreenFruitPartyMachine:openMail()
    if self.m_MailTip then
        self.m_MailTip:setVisible(false)
        local mailTip = util_createView("CodeFruitPartySrc.FruitPartyMailTip",{machine = self})
        mailTip:setClickEnable(false)
        self:findChild("Node_Mail"):addChild(mailTip)
        local movePos = util_convertToNodeSpace(self:findChild("root"),self:findChild("Node_Mail"))--cc.p(self:findChild("MailFlyNode"):getPosition())
        local delay = cc.DelayTime:create(64 / 60)
        local moveTo = cc.MoveTo:create(22 / 60, movePos)
        mailTip:runAction(cc.Sequence:create(delay, moveTo))
        mailTip:runCsbAction(
            "actionframe",
            false,
            function()
                mailTip:removeFromParent()
            end,
            60
        )

        self:delayCallBack(110 / 60,function(  )
            self:showSpotMailWinView()
        end)
    end
end

--邮箱获得奖励弹板
function CodeGameScreenFruitPartyMachine:showSpotMailWinView()
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_show_mail.mp3")
    local winView = util_createView("CodeFruitPartySrc.FruitPartySpotMailWin",{machine = self})
    local _winCoins = self.m_roomData:getMailWinCoins()
    winView:initViewData(_winCoins)
    winView:setPosition(display.width/2,display.height/2)
    --检测大赢
    -- self:checkFeatureOverTriggerBigWin(_winCoins, GameEffect.EFFECT_BONUS)

    winView:setFunc(
        function()
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                _winCoins, true, true
            })
            self:playGameEffect()
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            --重新刷新房间消息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
            self.m_isShowMail = false
        end
    )
    gLobalViewManager:showUI(winView)

    --发送停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end


function CodeGameScreenFruitPartyMachine:checkIsAddLastWinSomeEffect( )
    
    local notAdd  = false

    if self.m_iOnceSpinLastWin == 0 then
        notAdd = true
    end

    return notAdd
end

--[[
    网络消息返回
]]
function CodeGameScreenFruitPartyMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()
    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    --计算轮底
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.colorReels then
        self:convertToLunDi(selfData.colorReels)
    end

    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()  -- end
end

--重写列停止
function CodeGameScreenFruitPartyMachine:reelSchedulerCheckColumnReelDown(parentData)
    local  slotParent = parentData.slotParent
    if parentData.isDone ~= true then
        parentData.isDone = true
        slotParent:stopAllActions()

        

        local slotParentBig = parentData.slotParentBig 
        if slotParentBig then
            slotParentBig:stopAllActions()
        end
        self:slotOneReelDown(parentData.cloumnIndex)
        local speedActionTable = nil
        local addTime = nil
        local quickStopY = -35 --快停回弹距离
        if self.m_quickStopBackDistance then
            quickStopY = -self.m_quickStopBackDistance
        end
        -- local quickStopY = -self.m_configData.p_reelResDis --不读取配置
        if self.m_isNewReelQuickStop then
            self.m_configData:prepareStop(parentData,1,self.m_LunDiAry,true)

            local symbol = self:getFixSymbol(parentData.cloumnIndex, self.m_iReelRowNum + 1)
            if symbol then
                self:updateReelGridNode(symbol)
            end
            slotParent:setPositionY(quickStopY)
            if slotParentBig then
                slotParentBig:setPositionY(quickStopY)
            end
            speedActionTable = {}
            speedActionTable[1], addTime = self:MachineRule_BackAction(slotParent, parentData)
        else
            speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
        end
        if slotParentBig then
            local seq = cc.Sequence:create(speedActionTable)
            slotParentBig:runAction(seq:clone())
        end
        local tipSlotNoes = nil
        local nodeParent = parentData.slotParent
        local nodes = nodeParent:getChildren()
        if slotParentBig then
            local nodesBig = slotParentBig:getChildren()
            for i=1,#nodesBig do
                nodes[#nodes+1]=nodesBig[i]
            end
        end

        
        --添加提示节点
        tipSlotNoes = self:addReelDownTipNode(nodes)

        if tipSlotNoes ~= nil then
            local nodeParent = parentData.slotParent
            for i = 1, #tipSlotNoes do
                --播放提示动画
                self:playReelDownTipNode(tipSlotNoes[i])
            end -- end for
        end
       
        self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)
        
        local actionFinishCallFunc = cc.CallFunc:create(
        function()
            parentData.isResActionDone = true
            if self.m_quickStopReelIndex and self.m_quickStopReelIndex == parentData.cloumnIndex then
                self:newQuickStopReel(self.m_quickStopReelIndex)
            end
            self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
        end)

        speedActionTable[#speedActionTable + 1] = actionFinishCallFunc
        slotParent:runAction(cc.Sequence:create(speedActionTable))
    end
    return 0.1
end

--[[
    转化轮底
]]
function CodeGameScreenFruitPartyMachine:convertToLunDi(colorReels)
    self.m_configData:resetLunDi()
    self.m_LunDiAry = {
        {},
        {},
        {}
    }
    for iCol = 1,self.m_iReelColumnNum do
        if colorReels[1][iCol] == HAVE_LUNDI_TAG and colorReels[2][iCol] == HAVE_LUNDI_TAG and colorReels[3][iCol] == HAVE_LUNDI_TAG then
            self.m_LunDiAry[1][iCol] = 3
            self.m_LunDiAry[2][iCol] = 2
            self.m_LunDiAry[3][iCol] = 1
        elseif colorReels[1][iCol] == HAVE_LUNDI_TAG and colorReels[2][iCol] == HAVE_LUNDI_TAG and colorReels[3][iCol] ~= HAVE_LUNDI_TAG then
            self.m_LunDiAry[1][iCol] = 2
            self.m_LunDiAry[2][iCol] = 1
            self.m_LunDiAry[3][iCol] = 0
        elseif colorReels[1][iCol] == HAVE_LUNDI_TAG and colorReels[2][iCol] ~= HAVE_LUNDI_TAG and colorReels[3][iCol] ~= HAVE_LUNDI_TAG then
            self.m_LunDiAry[1][iCol] = 1
            self.m_LunDiAry[2][iCol] = 0
            self.m_LunDiAry[3][iCol] = 0
        elseif colorReels[1][iCol] ~= HAVE_LUNDI_TAG and colorReels[2][iCol] == HAVE_LUNDI_TAG and colorReels[3][iCol] == HAVE_LUNDI_TAG then
            self.m_LunDiAry[1][iCol] = 0
            self.m_LunDiAry[2][iCol] = 3
            self.m_LunDiAry[3][iCol] = 2
        elseif colorReels[1][iCol] ~= HAVE_LUNDI_TAG and colorReels[2][iCol] ~= HAVE_LUNDI_TAG and colorReels[3][iCol] == HAVE_LUNDI_TAG then
            self.m_LunDiAry[1][iCol] = 0
            self.m_LunDiAry[2][iCol] = 0
            self.m_LunDiAry[3][iCol] = 3
        else
            self.m_LunDiAry[1][iCol] = 0
            self.m_LunDiAry[2][iCol] = 0
            self.m_LunDiAry[3][iCol] = 0
        end
    end
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenFruitPartyMachine:operaEffectOver(  )

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

    self.m_gameEffects = {}

    --主动刷新一次数据
    self.m_roomList:sendRefreshData()
end

function CodeGameScreenFruitPartyMachine:getReelHeight()
    local radio = display.width / display.height
    if radio >= (1370 / 768) then
        return 550
    end
    return self.m_reelHeight
end

return CodeGameScreenFruitPartyMachine






