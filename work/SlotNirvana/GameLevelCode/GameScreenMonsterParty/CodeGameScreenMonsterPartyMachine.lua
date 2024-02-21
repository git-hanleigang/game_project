---
-- island li
-- 2019年1月26日
-- CodeGameScreenMonsterPartyMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"


local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local MonsterPartySlotFastNode = require "CodeMonsterPartySrc.MonsterPartySlotFastNode"

local CodeGameScreenMonsterPartyMachine = class("CodeGameScreenMonsterPartyMachine", BaseFastMachine)

CodeGameScreenMonsterPartyMachine.m_isMachineBGPlayLoop = true -- 是否循环播放主背景动画

CodeGameScreenMonsterPartyMachine.SYMBOL_JACKPOT_MEGA = 101   
CodeGameScreenMonsterPartyMachine.SYMBOL_JACKPOT_GRAND = 102   
CodeGameScreenMonsterPartyMachine.SYMBOL_JACKPOT_MAJOR = 103   
CodeGameScreenMonsterPartyMachine.SYMBOL_JACKPOT_MINOR = 104 
CodeGameScreenMonsterPartyMachine.SYMBOL_JACKPOT_MINI = 105   
CodeGameScreenMonsterPartyMachine.SYMBOL_JACKPOT_MSP = 93  
CodeGameScreenMonsterPartyMachine.SYMBOL_MONSTERPARTAY_MYSTER = 95 

CodeGameScreenMonsterPartyMachine.SYMBOL_WHEEL_BATMAN_SYMBOL = 201
CodeGameScreenMonsterPartyMachine.SYMBOL_WHEEL_WOLFMAN_SYMBOL = 202
CodeGameScreenMonsterPartyMachine.SYMBOL_WHEEL_GHOSTMAN_SYMBOL = 203
CodeGameScreenMonsterPartyMachine.SYMBOL_WHEEL_GREENMAN_SYMBOL = 204
CodeGameScreenMonsterPartyMachine.SYMBOL_WHEEL_TIMES_5_SYMBOL = 205
CodeGameScreenMonsterPartyMachine.SYMBOL_WHEEL_TIMES_8_SYMBOL = 206
CodeGameScreenMonsterPartyMachine.SYMBOL_WHEEL_TIMES_10_SYMBOL = 207
CodeGameScreenMonsterPartyMachine.SYMBOL_WHEEL_TIMES_12_SYMBOL = 208


CodeGameScreenMonsterPartyMachine.FS_LockWild_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenMonsterPartyMachine.FS_Collect_Wild_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识

CodeGameScreenMonsterPartyMachine.MONSTERPARTY_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 12 -- 自定义动画的标识



CodeGameScreenMonsterPartyMachine.FS_GAME_TYPE_m_batMan = 0
CodeGameScreenMonsterPartyMachine.FS_GAME_TYPE_ghostGirl = 1
CodeGameScreenMonsterPartyMachine.FS_GAME_TYPE_wolfMan = 2
CodeGameScreenMonsterPartyMachine.FS_GAME_TYPE_greenMan = 3

-- free logoMan
CodeGameScreenMonsterPartyMachine.m_batMan =  nil
CodeGameScreenMonsterPartyMachine.m_wolfMan =  nil
CodeGameScreenMonsterPartyMachine.m_wolfManZhua =  nil
CodeGameScreenMonsterPartyMachine.m_ghostGirl =  nil
CodeGameScreenMonsterPartyMachine.m_greenMan =  nil


-- free Reels
CodeGameScreenMonsterPartyMachine.m_Reels_batMan =  nil
CodeGameScreenMonsterPartyMachine.m_Reels_wolfMan =  nil
CodeGameScreenMonsterPartyMachine.m_Reels_ghostGirl =  nil
CodeGameScreenMonsterPartyMachine.m_Reels_greenMan =  nil

CodeGameScreenMonsterPartyMachine.m_FSLittleReelsDownIndex = 0 -- FS停止计数
CodeGameScreenMonsterPartyMachine.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数

CodeGameScreenMonsterPartyMachine.m_GhostGirlIndex = 0 -- 鬼魂新娘netCall计数

CodeGameScreenMonsterPartyMachine.m_paoAct = nil
CodeGameScreenMonsterPartyMachine.m_mainUiChangePos = 0

local FIT_HEIGHT_MAX = 1281
local FIT_HEIGHT_MIN = 1136

-- 构造函数
function CodeGameScreenMonsterPartyMachine:ctor()
    BaseFastMachine.ctor(self)

    self.SYMBOL_MYSTER_Normal_GEAR = {20,55,55,60,60,150,150,150,150,150}  -- base 假滚 mystery1 权重
    self.SYMBOL_MYSTER_ThreeReels_GEAR = {5,10,15,20,25,160,170,180,200,215}	  -- 三个轮子 假滚 mystery2 权重
    self.SYMBOL_MYSTER_NAME =   { 92,0,1,2,3,4,5,6,7,8,9}
    self.m_bProduceSlots_RunSymbol =  self.SYMBOL_MYSTER_NAME[math.random( 1, #self.SYMBOL_MYSTER_NAME)]

    self.m_Reels_batMan =  nil
    self.m_Reels_wolfMan =  nil
    self.m_Reels_ghostGirl = {}
    self.m_Reels_greenMan =  nil
    self.m_paoAct = {}

    self.m_FSLittleReelsDownIndex = 0 -- FS停止计数
    self.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数
    self.m_GhostGirlIndex = 0 
    self.m_mainUiChangePos = 0
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenMonsterPartyMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i == 1 then
            soundPath = "MonsterPartySounds/MonsterParty_scatter_down1.mp3"
        elseif i == 2 then
            soundPath = "MonsterPartySounds/MonsterParty_scatter_down2.mp3"
        else
            soundPath = "MonsterPartySounds/MonsterParty_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenMonsterPartyMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("MonsterPartyConfig.csv", "LevelMonsterPartyConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMonsterPartyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MonsterParty"  
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenMonsterPartyMachine:getNetWorkModuleName()
    return "Monsters" 
end


function CodeGameScreenMonsterPartyMachine:initFsMan( )


    self:findChild("node_man"):setPositionY(self:findChild("node_man"):getPositionY() - 50)
    self:findChild("node_man_0"):setPositionY(self:findChild("node_man_0"):getPositionY() - 50)

    self.m_batMan =  util_spineCreate("MonsterParty_juese_xixuegui",true,true)
    self:findChild("node_man"):addChild(self.m_batMan)
    self.m_batMan:setVisible(false)

    self.m_wolfMan =  util_spineCreateDifferentPath("MonsterParty_juese_langren","MonsterParty_juese_langren", true, true) 
    self:findChild("node_man"):addChild(self.m_wolfMan)
    self.m_wolfMan:setPositionY(76)
    self.m_wolfMan:setVisible(false)

    self.m_wolfManZhua =  util_spineCreateDifferentPath("MonsterParty_juese_langren_shang","MonsterParty_juese_langren", true, true) 
    self:findChild("node_man_0"):addChild(self.m_wolfManZhua)
    self.m_wolfManZhua:setPositionY(76)
    self.m_wolfManZhua:setVisible(false)

    self.m_ghostGirl =  util_spineCreate("MonsterParty_juese_jiangshi",true,true)
    self:findChild("node_man"):addChild(self.m_ghostGirl)
    self.m_ghostGirl:setVisible(false)

    self.m_greenMan =  util_spineCreate("MonsterParty_juese_lvjuren",true,true)
    self:findChild("node_man"):addChild(self.m_greenMan)
    self.m_greenMan:setPositionY(-90)
    self.m_greenMan:setVisible(false)
    
end

function CodeGameScreenMonsterPartyMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar


    -- 创建view节点方式
    -- self.m_MonsterPartyView = util_createView("CodeMonsterPartySrc.MonsterPartyView")
    -- self:findChild("xxxx"):addChild(self.m_MonsterPartyView)

    self.m_JackPotView = util_createView("CodeMonsterPartySrc.MonsterPartyJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_JackPotView)
    self.m_JackPotView:initMachine(self)
    self.m_JackPotView:runCsbAction("small",true)
    
    self.m_freespinSpinbar = util_createView("CodeMonsterPartySrc.MonsterPartyFreespinBarView")
    self:findChild("SpinRemaining"):addChild(self.m_freespinSpinbar)
    self.m_freespinSpinbar:setVisible(false)
    self.m_baseFreeSpinBar = self.m_freespinSpinbar


    local scaleX = 768 / display.width / self.m_machineRootScale
    self:findChild("GuoChang"):setScaleX(scaleX)
    self:findChild("GuoChang"):setScaleX(scaleX)
    self.m_GuoChangAct = util_createAnimation("Socre_MonsterParty_Guochang.csb")
    self:findChild("GuoChang"):addChild(self.m_GuoChangAct)
    self.m_GuoChangAct:setVisible(false)


    self.m_logo = util_createAnimation("MonsterParty_logo.csb")
    self:findChild("logo"):addChild(self.m_logo)

    self:initFsMan()


    self:findChild("batflynode"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)

    self:initFreespinReels( )

    self.m_jackPotRunEffect = util_createAnimation("WinFrameMonsterParty_run2.csb")
    self:findChild("BaseReel"):addChild(self.m_jackPotRunEffect,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 500) 
    self.m_jackPotRunEffect:setPosition(cc.p(self:findChild("sp_reel_4"):getPosition()))
    self.m_jackPotRunEffect:setVisible(false)
    
    
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
            soundTime = 2
        elseif winRate > 6 then
            soundIndex = 3
            soundTime = 2
        end

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE and freeSpinType and  freeSpinType ~= self.FS_GAME_TYPE_wolfMan then
            print("freespin最后一次 无论是否大赢都播放赢钱音效")
        else
            if winRate >= self.m_HugeWinLimitRate then
                return
            elseif winRate >= self.m_MegaWinLimitRate then
                return
            elseif winRate >= self.m_BigWinLimitRate then
                return
            end
        end
        if self.m_winSoundsId == nil then
            local soundName = "MonsterPartySounds/music_MonsterParty_last_win_".. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
            performWithDelay(self,function (  )
                self.m_winSoundsId = nil 
            end,soundTime)
        end

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenMonsterPartyMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        if not self.isInBonus then

            gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_enter.mp3")
            scheduler.performWithDelayGlobal(function (  )
                
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end,2.5,self:getModuleName())
        end
        

    end,0.4,self:getModuleName())
end

function CodeGameScreenMonsterPartyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:changeFreeReelVisible( )

end

function CodeGameScreenMonsterPartyMachine:addObservers()
    BaseFastMachine.addObservers(self)

end

function CodeGameScreenMonsterPartyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMonsterPartyMachine:MachineRule_GetSelfCCBName(symbolType)


    if symbolType == self.SYMBOL_JACKPOT_MEGA  then
        return "Socre_MonsterParty_Mega"
    elseif symbolType == self.SYMBOL_JACKPOT_GRAND then   
        return "Socre_MonsterParty_Grand"
    elseif symbolType == self.SYMBOL_JACKPOT_MAJOR then   
        return "Socre_MonsterParty_Major"
    elseif symbolType == self.SYMBOL_JACKPOT_MINOR then   
        return "Socre_MonsterParty_Minor"
    elseif symbolType == self.SYMBOL_JACKPOT_MINI then   
        return "Socre_MonsterParty_Mini"
    elseif symbolType == self.SYMBOL_JACKPOT_MSP then   
        return "Socre_MonsterParty_MSP"

    elseif symbolType == self.SYMBOL_MONSTERPARTAY_MYSTER then   
        return "Socre_MonsterParty_9"
       
    elseif symbolType == self.SYMBOL_WHEEL_BATMAN_SYMBOL then   
        return "MonsterParty_Choose_juese_0"
    elseif symbolType == self.SYMBOL_WHEEL_WOLFMAN_SYMBOL then   
        return "MonsterParty_Choose_juese_1"
    elseif symbolType == self.SYMBOL_WHEEL_GHOSTMAN_SYMBOL then   
        return "MonsterParty_Choose_juese_2"
    elseif symbolType == self.SYMBOL_WHEEL_GREENMAN_SYMBOL then   
        return "MonsterParty_Choose_juese_3"
    elseif symbolType == self.SYMBOL_WHEEL_TIMES_5_SYMBOL then   
        return "MonsterParty_Choose_shu_5"
    elseif symbolType == self.SYMBOL_WHEEL_TIMES_8_SYMBOL then   
        return "MonsterParty_Choose_shu_8"
    elseif symbolType == self.SYMBOL_WHEEL_TIMES_10_SYMBOL then   
        return "MonsterParty_Choose_shu_10"
    elseif symbolType == self.SYMBOL_WHEEL_TIMES_12_SYMBOL then   
        return "MonsterParty_Choose_shu_12"
        
    end



    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMonsterPartyMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JACKPOT_MEGA,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JACKPOT_GRAND,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JACKPOT_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JACKPOT_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JACKPOT_MINI,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_JACKPOT_MSP,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MONSTERPARTAY_MYSTER,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenMonsterPartyMachine:MachineRule_initGame(  )

    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        if freeSpinType == self.FS_GAME_TYPE_m_batMan then

            self:initFSReelsLockWildFromNetNetData()

        elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then
            self:initFSReelsCollectWildFromNetNetData()
        elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then

        elseif freeSpinType == self.FS_GAME_TYPE_greenMan then
            
        end

        self:changeGameMachineBG( true)

    end
            
            
    
end

function CodeGameScreenMonsterPartyMachine:isJackpotSymbol(symbolType )

    if symbolType == self.SYMBOL_JACKPOT_MEGA
            or symbolType == self.SYMBOL_JACKPOT_GRAND
                or symbolType == self.SYMBOL_JACKPOT_MAJOR
                    or symbolType == self.SYMBOL_JACKPOT_MINOR
                        or symbolType == self.SYMBOL_JACKPOT_MINI
                            or symbolType == self.SYMBOL_JACKPOT_MSP then


        return true

    end


    return false
end

--
--单列滚动停止回调
--
function CodeGameScreenMonsterPartyMachine:slotOneReelDown(reelCol)   
    
    self:hidePaoAct(reelCol )
    
    BaseFastMachine.slotOneReelDown(self,reelCol) 
   

    local isplay= true
    local isHaveFixSymbol = false
    for iRow = 1, self.m_iReelRowNum do

        local parentNode = self:getReelParent(reelCol)
        if not tolua.isnull(parentNode) then
            local node = parentNode:getChildByTag(self:getNodeTag(reelCol, iRow, SYMBOL_NODE_TAG))

            if node and node.p_symbolType then
                if self:isJackpotSymbol(node.p_symbolType) then
                    isHaveFixSymbol = true

                    if reelCol == 5 then
                        
                        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                        local jackpotType =  selfData.jackpotType 
                        if jackpotType then
                            node:runAnim("actionframe")
                        end

                    else
                        node:runAnim("actionframe")
                    end
                end 
            end
        else
            assert(false, "CodeGameScreenMonsterPartyMachine:slotOneReelDown|row:" .. iRow .. "|"  .. debug.traceback())
        end
        
    end
    if isHaveFixSymbol == true and isplay then
        isplay = false

        if reelCol == 1 then
            self.m_jackPotRunEffect:setVisible(true)
            self.m_jackPotRunEffect:runCsbAction("run",true)
            gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_JackPot_MSp_Down.mp3") 
        elseif reelCol == 5 then

            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local jackpotType =  selfData.jackpotType 
            if jackpotType then
                gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_JackPot_Jp_Down.mp3") 
            end
            
        end


    end

    if reelCol == 5 then
        if self.m_jackPotRunEffect:isVisible() then
            self.m_jackPotRunEffect:setVisible(false)
            self.m_jackPotRunEffect:runCsbAction("idleframe")
        end
    end

    


end


---
-- 老虎机滚动结束调用
function CodeGameScreenMonsterPartyMachine:slotReelDown()

    

    BaseFastMachine.slotReelDown(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMonsterPartyMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMonsterPartyMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

---
-- 显示free spin
function CodeGameScreenMonsterPartyMachine:showEffect_FreeSpin(effectData)

    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.isInBonus = true

    return BaseFastMachine.showEffect_FreeSpin(self,effectData)
end

---------------------------------弹版----------------------------------
function CodeGameScreenMonsterPartyMachine:showFreeSpinStart(num,func)

    if func then
        func()
        return
    end


    local ownerlist={}
    ownerlist["m_lb_num"]=num
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenMonsterPartyMachine:showFreeSpinView(effectData)

    

    -- gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else

            self:showWheelView( function(  )

                self:changeGameMachineBG( true)

                self:triggerFreespinFromType( function(  )
                    self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                        self.m_baseFreeSpinBar:setVisible(true)
                        self.m_baseFreeSpinBar:changeFreeSpinByCount()

                        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Open_Door.mp3")

                        self.m_WheelMainView:runCsbAction("open",false,function(  )
                            self.m_WheelMainView:setVisible(false)

                            if self.m_WheelMainView then
                                self.m_WheelMainView:removeFromParent()
                                self.m_WheelMainView = nil
                            end
                            
                        end)
                        
                        performWithDelay(self,function(  )
                            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                            local freeSpinType = selfData.freeSpinType
                            
                            
                            if freeSpinType == self.FS_GAME_TYPE_m_batMan then
                                gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_BatMan_Enter.mp3")
                                performWithDelay(self,function(  )
                                    self:triggerFreeSpinCallFun()
                                    effectData.p_isPlay = true
                                    self:playGameEffect()  
                                end,1)
                                 

                            elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then

                                gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_WolfMan_Enter.mp3")



                                self.m_wolfManZhua:setVisible(true)
                                util_spinePlay(self.m_wolfManZhua,"chuxian_1")
                                self.m_wolfMan:setVisible(true)
                                util_spinePlay(self.m_wolfMan,"chuxian_1")

                                performWithDelay(self,function(  )

                                    
                                    util_spinePlay(self.m_wolfManZhua,"idleframe",true)
                                    util_spinePlay(self.m_wolfMan,"idleframe",true)

                                    self:triggerFreeSpinCallFun()
                                    effectData.p_isPlay = true
                                    self:playGameEffect() 
                                end,80/30)

                            elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then

                                self:triggerFreeSpinCallFun()
                                effectData.p_isPlay = true
                                self:playGameEffect()   

                            elseif freeSpinType == self.FS_GAME_TYPE_greenMan then
                                
                                performWithDelay(self,function(  )
                                    
                                    gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_greenMan_ChuChang.mp3")

                                    performWithDelay(self,function(  )
                                        self:shakeBGNode( )
                                        self.m_Reels_greenMan:shakeMachineNode( )
                                    end,14/30)

                                    self.m_greenMan:setVisible(true)
                                    util_spinePlay(self.m_greenMan,"buling")

                                    local greeManLightAnimBg = util_createAnimation("Socre_MonsterParty_fulanke_1.csb")  
                                    self:findChild("GuoChang"):addChild(greeManLightAnimBg)
                                    greeManLightAnimBg:runCsbAction("buling",false,function(  )
                                        greeManLightAnimBg:removeFromParent()
                                    end)

                                    local greeManLightAnim = util_createAnimation("Socre_MonsterParty_fulanke_0.csb")  
                                    self:findChild("F_buling"):addChild(greeManLightAnim)
                                    greeManLightAnim:runCsbAction("buling",false,function(  )
                                        greeManLightAnim:removeFromParent()
                                    end)

                                    performWithDelay(self,function(  )

                                        util_spinePlay(self.m_greenMan,"idleframe",true)

                                        self:triggerFreeSpinCallFun()
                                        effectData.p_isPlay = true
                                        self:playGameEffect() 
                                    end,50/30)

                                end,0.3)
                                
                            end
                        end,13/30)

                        
                    end)
                end )

                
            end )

                
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end



---
-- 显示free spin over 动画
function CodeGameScreenMonsterPartyMachine:showEffect_FreeSpinOver()

    globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")

    local lines = self:getFreeSpinReelsLines()


    if #lines == 0 then
        self.m_freeSpinOverCurrentTime = 1
    end

    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
        self.m_fsOverHandlerID =scheduler.scheduleGlobal(function()
            if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
                self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
            else
                self:showEffect_newFreeSpinOver()
            end
        end,0.1)
    else
        self:showEffect_newFreeSpinOver()
    end
    return true
end

function CodeGameScreenMonsterPartyMachine:RemoveAndCreateRuningFsReelSlotsNode( )

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeSpinType

    util_printLog("**********MonsterParty RemoveAndCreateRuningFsReelSlotsNode 1",true)
    if freeSpinType == self.FS_GAME_TYPE_m_batMan then
        util_printLog("**********MonsterParty RemoveAndCreateRuningFsReelSlotsNode 2",true)
        self.m_Reels_batMan:removeAllReelsNode()

    elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then
        util_printLog("**********MonsterParty RemoveAndCreateRuningFsReelSlotsNode 3",true)
        self.m_Reels_wolfMan:removeAllReelsNode()

    elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then
        util_printLog("**********MonsterParty RemoveAndCreateRuningFsReelSlotsNode 4",true)
        for i=1,#self.m_Reels_ghostGirl do
            local ghostGirlReel = self.m_Reels_ghostGirl[i]
            ghostGirlReel:removeAllReelsNode()
        end
        
    elseif freeSpinType == self.FS_GAME_TYPE_greenMan then
        util_printLog("**********MonsterParty RemoveAndCreateRuningFsReelSlotsNode 5",true)
        self.m_Reels_greenMan:removeAllReelsNode()
    end
    util_printLog("**********MonsterParty RemoveAndCreateRuningFsReelSlotsNode 6",true)
end

function CodeGameScreenMonsterPartyMachine:showFreeSpinOverView()

   

   local FreeSpinOverFunc = function(  )

        gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_over_fs.mp3")

        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()

                util_printLog("**********MonsterParty showFreeSpinOverView 1",true)
                self:triggerFreeSpinOverCallFun()

                util_printLog("**********MonsterParty showFreeSpinOverView 2",true)
                self:changeFreeReelVisible(  )
                util_printLog("**********MonsterParty showFreeSpinOverView 3",true)
                self:RemoveAndCreateRuningFsReelSlotsNode( )
                util_printLog("**********MonsterParty showFreeSpinOverView 4",true)
                self:changeGameMachineBG(  )

                gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Open_Door.mp3")
                self.m_GuoChangAct:setVisible(true) 
                self.m_GuoChangAct:runCsbAction("open",false,function(  )
                    self.m_GuoChangAct:setVisible(false)
                    
                end)
            

        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.35,sy=1.35},458)

        view.m_btnTouchSound = "MonsterPartySounds/MonsterParty_BatMan_FsOverView_Click.mp3"
   end


    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeSpinType

    if freeSpinType == self.FS_GAME_TYPE_m_batMan then

        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_BatMan_end.mp3")

        performWithDelay(self,function(  )

            gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Close_Door.mp3")

            self.m_GuoChangAct:setVisible(true) 
            self.m_GuoChangAct:runCsbAction("close2",false,function(  )
                FreeSpinOverFunc()
            end)

            


            
        end,2.5)

    elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then
        
        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_WolfMan_end.mp3")
        performWithDelay(self,function(  )

            gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Close_Door.mp3")

            self.m_GuoChangAct:setVisible(true) 
            self.m_GuoChangAct:runCsbAction("close2",false,function(  )
                FreeSpinOverFunc()
            end)

            
            


        end,1.5)


    elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then

        performWithDelay(self,function(  )

            gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Close_Door.mp3")

            self.m_GuoChangAct:setVisible(true) 
            self.m_GuoChangAct:runCsbAction("close2",false,function(  )
                FreeSpinOverFunc()
            end)


            
            

        end,0.5)
        

    elseif freeSpinType == self.FS_GAME_TYPE_greenMan then

        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_greenMan_end.mp3")
        performWithDelay(self,function(  )

            gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Close_Door.mp3")

            self.m_GuoChangAct:setVisible(true) 
            self.m_GuoChangAct:runCsbAction("close2",false,function(  )
                FreeSpinOverFunc()
            end)


            
            

        end,1)

    end


    

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMonsterPartyMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    self.isInBonus = false
    
    
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_FSLittleReelsDownIndex = 0 -- FS停止计数
    self.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数
    self.m_GhostGirlIndex = 0 
   
    self:randomMyster( )


    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenMonsterPartyMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenMonsterPartyMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMonsterPartyMachine:addSelfEffect()

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local jackpotType =  selfData.jackpotType 
        if jackpotType then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.MONSTERPARTY_JACKPOT_EFFECT -- 动画类型
        end

        
        if self:getCurrSpinMode() == FREE_SPIN_MODE then


            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local freeSpinType = selfData.freeSpinType

            if freeSpinType == self.FS_GAME_TYPE_m_batMan then

                if self:checkIsAddFsWildLock( ) then
                    -- 自定义动画创建方式
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.FS_LockWild_EFFECT -- 动画类型
                end

            elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then

                


                local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                local wildCollect = selfdata.wildCollect
                local freeSpinLeftTimes = self.m_runSpinResultData.p_freeSpinsLeftCount or 0

                if freeSpinLeftTimes > 0  then
                    
                    util_spinePlay(self.m_wolfManZhua,"idleframe_2")
                    util_spinePlay(self.m_wolfMan,"idleframe_2")

                    util_spineEndCallFunc(self.m_wolfMan, "idleframe_2", function(  )
                        
                        util_spinePlay(self.m_wolfManZhua,"idleframe",true)
                        util_spinePlay(self.m_wolfMan,"idleframe",true)
                    end)
                end

                if self.m_Reels_wolfMan:checkIsShowCollectKuang( wildCollect ) and freeSpinLeftTimes > 0 then
                    
                    -- 自定义动画创建方式
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.FS_Collect_Wild_EFFECT -- 动画类型

                end

            elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then

            elseif freeSpinType == self.FS_GAME_TYPE_greenMan then
                
            end

            
        end

        
        
        

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMonsterPartyMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.MONSTERPARTY_JACKPOT_EFFECT then

        performWithDelay(self,function(  )

            gLobalSoundManager:setBackgroundMusicVolume(0.1)
            
           
            performWithDelay(self,function(  )
                self:showGameEffect_Jackpot( effectData )
            end,0.5)

        end,25/30)
        

    elseif effectData.p_selfEffectType == self.FS_LockWild_EFFECT then



            performWithDelay(self,function( )

                self.m_Reels_batMan:restSelfGameEffects( self.FS_LockWild_EFFECT )

                effectData.p_isPlay = true
                self:playGameEffect()
            end,0.5)

    elseif effectData.p_selfEffectType == self.FS_Collect_Wild_EFFECT then 


        gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_WolfMan_WIldToKuang.mp3")

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local wildCollect = selfdata.wildCollect
        self.m_Reels_wolfMan:updateCollectKuang( wildCollect )

        
        
        local time = 1.5
        performWithDelay(self,function()
            
            self.m_Reels_wolfMan:restSelfGameEffects( self.FS_Collect_Wild_EFFECT  )

            effectData.p_isPlay = true
            self:playGameEffect()

        end,time)
        

    end

    
	return true
end

function CodeGameScreenMonsterPartyMachine:getJackPotWinCoins( linetype )
    local winlines = self.m_runSpinResultData.p_winLines

    if winlines and #winlines > 0 then
        for i=1,#winlines do
            local line = winlines[i]
            if line and line.p_type and line.p_type == linetype then

                if line.p_amount then
                    return line.p_amount
                end
                
                
            end
        end
    end


    return 0
end

function CodeGameScreenMonsterPartyMachine:showGameEffect_Jackpot( effectData )


    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotType =  selfData.jackpotType 

    local wincoins = self:getJackPotWinCoins( tonumber(jackpotType) )
    
    local index = 1

    if jackpotType == self.SYMBOL_JACKPOT_MEGA then
        index = 1
    elseif jackpotType == self.SYMBOL_JACKPOT_GRAND then
        index = 2
    elseif jackpotType == self.SYMBOL_JACKPOT_MAJOR then
        index = 3
    elseif jackpotType == self.SYMBOL_JACKPOT_MINOR then
        index = 4
    elseif jackpotType == self.SYMBOL_JACKPOT_MINI then
        index = 5
        
    end
  
    gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_JackPot_Jp_trigger.mp3")
    local isplay= true
    local isHaveFixSymbol = false
    for iCol =1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do

            local parentNode = self:getReelParent(iCol)
            if not tolua.isnull(parentNode) then
                local node = parentNode:getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
        
                if node and node.p_symbolType then
                    if self:isJackpotSymbol(node.p_symbolType) then

        
                        node:runAnim("animation0",false,function(  )
                            -- node:runAnim("animation0",false,function(  )
                            
                            -- end)
                        end)
                    end 
                end
            else
                assert(false, "CodeGameScreenMonsterPartyMachine:showGameEffect_Jackpot|col:" .. iCol .. "|row:" .. iRow .. "|" .. debug.traceback())
            end
            
        end
    end
    performWithDelay(self,function(  )
        
        self:showJackpotWinView(index,wincoins,function(  )

            gLobalSoundManager:setBackgroundMusicVolume(1)

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end,3)

    


    


end

---
-- 根据类型获取对应节点
--
function CodeGameScreenMonsterPartyMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
        
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    reelNode:setMachine(self )
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

--小块
function CodeGameScreenMonsterPartyMachine:getBaseReelGridNode()
    return "CodeMonsterPartySrc.MonsterPartySlotFastNode"
end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMonsterPartyMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


-- ---- Myster 处理
function CodeGameScreenMonsterPartyMachine:randomMyster( )

    local index =  self:getProMysterIndex(self.SYMBOL_MYSTER_Normal_GEAR)
    if self.m_bProduceSlots_InFreeSpin == true then
        index =  self:getProMysterIndex(self.SYMBOL_MYSTER_ThreeReels_GEAR)
    end

    self.m_bProduceSlots_RunSymbol = self.SYMBOL_MYSTER_NAME[index]

    self.m_configData:setMysterSymbol( self.m_bProduceSlots_RunSymbol )

    self.m_Reels_batMan.m_configData:setMysterSymbol( self.m_bProduceSlots_RunSymbol )
    self.m_Reels_wolfMan.m_configData:setMysterSymbol( self.m_bProduceSlots_RunSymbol )
    self.m_Reels_greenMan.m_configData:setMysterSymbol( self.m_bProduceSlots_RunSymbol )

    for i=1,#self.m_Reels_ghostGirl do
        self.m_Reels_ghostGirl[i].m_configData:setMysterSymbol( self.m_bProduceSlots_RunSymbol )
    end
    


end

function CodeGameScreenMonsterPartyMachine:getProMysterIndex( array )

    local index = 1
    local Gear = 0
    local tableGear = {}
    for k,v in pairs(array) do
        Gear = Gear + v
        table.insert( tableGear, Gear )
    end

    local randomNum = math.random( 1,Gear )

    for kk,vv in pairs(tableGear) do
        if randomNum <= vv then
            return kk
        end

    end

    return index

end

function CodeGameScreenMonsterPartyMachine:showJackpotWinView(index,coins,func)
    
    
    local jackPotWinView = util_createView("CodeMonsterPartySrc.MonsterPartyJackPotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)

    local curCallFunc = function(  )

        if func then
            func()
        end
    end

    jackPotWinView:initViewData(index,coins,curCallFunc)

end

function CodeGameScreenMonsterPartyMachine:changeGameMachineBG( isfree )
    
    if isfree then
        self.m_gameBg:findChild("Fs"):setVisible(true)
        self.m_gameBg:findChild("normal"):setVisible(false)
        self.m_FsGameLightBg:setVisible(true)
        self.m_FsGameLightBg:runCsbAction("idle",true)
    else
        self.m_gameBg:findChild("Fs"):setVisible(false)
        self.m_gameBg:findChild("normal"):setVisible(true)
        self.m_FsGameLightBg:setVisible(false)
        self.m_FsGameLightBg:runCsbAction("stop")
    end

    
    
end

function CodeGameScreenMonsterPartyMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg


    self.m_FsGameLightBg = util_createAnimation("MonsterParty/GameScreenMonsterParty_FS_Bg_act.csb") 
    self.m_gameBg:findChild("Node_1"):addChild(self.m_FsGameLightBg)
    self.m_FsGameLightBg:setVisible(false)
    
end

function CodeGameScreenMonsterPartyMachine:updateNetWorkData()

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

    -- 网络消息已经赋值成功开始进行飞蝙蝠变信号 , 等动画的判断逻辑

    if self:getCurrSpinMode() == FREE_SPIN_MODE then


        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        if freeSpinType == self.FS_GAME_TYPE_m_batMan then

        elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then

        elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then

        elseif freeSpinType == self.FS_GAME_TYPE_greenMan then
            
        end

    else

        self:baseNetBackCheckAddAction( ) 

    end

    
    
end

function CodeGameScreenMonsterPartyMachine:batManNetBackCheckAddAction( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local wildLock = selfdata.wildLock
    local newLock = selfdata.newLock

    if wildLock and self.m_Reels_batMan:checkIsShowLockWild( wildLock )then

        
        -- self.m_FsGameLightBg:runCsbAction("langren",false,function(  )
        --     self.m_FsGameLightBg:runCsbAction("idle",true)
        -- end)

        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_batMan_TurnToBat.mp3")

        util_spinePlay(self.m_batMan,"chufa_1" , false)

        util_spineEndCallFunc(self.m_batMan, "chufa_1", function(  )

            self:CreateBatflyAct( self:findChild("batflynode_Fs"),function(  )

            end )

            performWithDelay(self,function(  )
  
                if self.m_Reels_batMan  then
                    self.m_Reels_batMan:createWildBat(wildLock,function(  )
                        self.m_Reels_batMan:initShowlockWild(wildLock)

                        performWithDelay(self,function(  )
                            
                            gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_batMan_batTurnToBatMan.mp3")

                            util_spinePlay(self.m_batMan,"chuxian_1")

                            util_spineEndCallFunc(self.m_batMan, "chuxian_1", function(  )
                                util_spinePlay(self.m_batMan,"idleframe_1" , true)
                            end)

                        
                            self:netBackReelsStop( )
                            self.m_Reels_batMan:netBackReelsStop( )
                        end,0.5)
                    end)
                end

            end,35/30)

            

        end)
            
    else  

        self:netBackReelsStop( )
        self.m_Reels_batMan:netBackReelsStop( )
    end


end

function CodeGameScreenMonsterPartyMachine:wolfManNetBackCheckAddAction( )
    

    

    self.m_Reels_wolfMan:changeKuangToWild( function(  )

            self:netBackReelsStop( )
            self.m_Reels_wolfMan:netBackReelsStop( )

    end)
    


end

function CodeGameScreenMonsterPartyMachine:ghostGirlNetBackCheckAddAction( maxCount )
    

    self.m_GhostGirlIndex = self.m_GhostGirlIndex + 1

    if self.m_GhostGirlIndex == maxCount then

        
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local mysteryColumns =  selfData.mysteryColumns or {}
        local mysterySignal =  selfData.mysterySignal or 6

        if mysteryColumns and #mysteryColumns > 0  then


            self:findChild("node_man"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)

            self.m_ghostGirl:setVisible(true)
            util_spinePlay(self.m_ghostGirl,"chuxian_1",false)

            self:findChild("node_man"):setPositionX((display.width + 100 )  / 2 / self.m_machineRootScale )

            local actList = {}
            actList[#actList + 1] = cc.MoveTo:create(70/30,cc.p(0,0))
            local sq = cc.Sequence:create(actList)
            self:findChild("node_man"):runAction(sq)

            performWithDelay(self,function(  )
                

                local paoBigActNode = util_createAnimation("Socre_MonsterParty_jiangshixinniang_2.csb")
                self:findChild("paopaoActNode"):addChild(paoBigActNode)
                paoBigActNode:runCsbAction("animation0")
                
                for i=1,#self.m_Reels_ghostGirl do
                    local reel = self.m_Reels_ghostGirl[i]
                    reel:CreatePaoActFromNetData( mysteryColumns )
                end

                performWithDelay(self,function(  )
                    gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_GhostGirl_xiao.mp3")
                end,2)
                

                util_spinePlay(self.m_ghostGirl,"chufa_1",false)
                util_spineEndCallFunc(self.m_ghostGirl, "chufa_1", function(  )

                    util_spinePlay(self.m_ghostGirl,"chuxian_1",false)

                    local actList = {}
                    actList[#actList + 1] = cc.MoveTo:create(70/30,cc.p(- (display.width + 300 )  / 2 / self.m_machineRootScale,0))
                    actList[#actList + 1] = cc.CallFunc:create(function(  )
                        self.m_ghostGirl:setVisible(false)
                        self:findChild("node_man"):setPosition(cc.p(0,-50))
                    end)
                    local sq = cc.Sequence:create(actList)
                    self:findChild("node_man"):runAction(sq)

                    performWithDelay(self,function(  )
                        self:findChild("node_man"):setLocalZOrder(-1)

                        self:netBackReelsStop( )
                        for i=1,#self.m_Reels_ghostGirl do
                            local reel = self.m_Reels_ghostGirl[i]
                            reel:netBackReelsStop( )
                        end
                    end,70/30)

                end)


            end,70/30)


        else

            self:netBackReelsStop( )
            for i=1,#self.m_Reels_ghostGirl do
                local reel = self.m_Reels_ghostGirl[i]
                reel:netBackReelsStop( )
            end
        end

        self.m_GhostGirlIndex = 0
    end



end

function CodeGameScreenMonsterPartyMachine:greenManNetBackCheckAddAction( )
    


    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local wildShape = selfdata.wildShape or {}
    if #wildShape > 0 then 

        self.m_FsGameLightBg:runCsbAction("langren",false,function(  )
            self.m_FsGameLightBg:runCsbAction("idle",true)
        end)

        performWithDelay(self,function(  )
            self:shakeBGNode( )
            self.m_Reels_greenMan:shakeMachineNode( )
        end,37/30)
        

        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_greenMan_ChuFa.mp3")

        self.m_greenMan:setVisible(true)
        util_spinePlay(self.m_greenMan,"chufa")

        local greeManLightAnim = util_createAnimation("Socre_MonsterParty_fulanke_2.csb")  
        self:findChild("F_chufa"):addChild(greeManLightAnim)
        greeManLightAnim:runCsbAction("buling",false,function(  )
            greeManLightAnim:removeFromParent()
        end)

        performWithDelay(self,function(  )

            

            gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_GreenMan_chuanxianWIld.mp3")
            
            self.m_Reels_greenMan:CreateDownWild( wildShape )

            self.m_Reels_greenMan:beiginAllWildDown( function(  )


                performWithDelay(self,function(  )
                    if self.m_Reels_greenMan.m_iReelRowNum > self.m_Reels_greenMan.m_iReelMinRow then
                        self.m_Reels_greenMan:changeReelLength(self.m_Reels_greenMan.m_iReelRowNum - self.m_Reels_greenMan.m_iReelMinRow,function(  )
                            self:netBackReelsStop( )
                            self.m_Reels_greenMan:netBackReelsStop( )
                        end)
                    else 
                        self:netBackReelsStop( )
                        self.m_Reels_greenMan:netBackReelsStop( )
                    end
                end,0.5)
                
        
                util_spinePlay(self.m_greenMan,"idleframe",true)
                
            end )


            


        end,37/30)
    else

        if self.m_Reels_greenMan.m_iReelRowNum > self.m_Reels_greenMan.m_iReelMinRow then
            self.m_Reels_greenMan:changeReelLength(self.m_Reels_greenMan.m_iReelRowNum - self.m_Reels_greenMan.m_iReelMinRow,function(  )
                self:netBackReelsStop( )
                self.m_Reels_greenMan:netBackReelsStop( )
            end)
        else 
            self:netBackReelsStop( )
            self.m_Reels_greenMan:netBackReelsStop( )
        end
    end

    

    


    

    

    

end


function CodeGameScreenMonsterPartyMachine:baseNetBackCheckAddAction( )
    

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mysteryColumns =  selfData.mysteryColumns or {}
    local mysterySignal =  selfData.mysterySignal or 6

    if mysteryColumns and #mysteryColumns > 0  then

        
        -- gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_BaseGame_bat_JUji.mp3")

        -- self.m_gameBg:runCsbAction("animation0",false,function(  )
        --     self.m_gameBg:runCsbAction("normal",true)

        self:shakeSelfNode( function(  )
            self:CreateBatflyAct( self:findChild("batflynode"),function(  )

                
    
            end )

            performWithDelay(self,function(  )
                self:netBackReelsStop( )
            end,40/30)
    
            self.m_paoAct = {}
            performWithDelay(self,function(  )
                print("创建 某列遮罩")
    
                local index = 0 
                for k,v in pairs(mysteryColumns) do
                    local iCol = v + 1
    
                    for iRow = self.m_iReelRowNum, 1, -1 do
                        index = index + 1
                        local func = nil
                        if index == 1 then
                            func = function(  )
                                
                            end
                        end
                        
    
                        local paoAct = self:CreatePaoAct( iRow, iCol )
                        paoAct.m_iCol = iCol
                        table.insert(self.m_paoAct,paoAct)
                    end
    
                end
            end,35/30)
        end )
        

        -- end)       
        
        

        
    
    else

        self:netBackReelsStop( )

    end


    
end

function CodeGameScreenMonsterPartyMachine:netBackReelsStop( )

    

    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end


function CodeGameScreenMonsterPartyMachine:showWheelView( func )

    
    self.m_WheelMainView = util_createView("CodeMonsterPartySrc.MonsterPartyWheelMainView",self)
    self:findChild("ChooseView"):addChild(self.m_WheelMainView)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_WheelMainView.getRotateBackScaleFlag = function(  ) return false end
    end


    self.m_WheelMainView:setRunEndCallBackFun( function(  )
        

        self.m_WheelMainView:setVisible(true) 
        
        
        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Close_Door.mp3")

        self.m_WheelMainView:runCsbAction("close",false,function(  )

            self.m_WheelMainView:findChild("root"):setVisible(false)
            self.m_WheelMainView:findChild("MonsterParty_up"):setVisible(false)
            self.m_WheelMainView:findChild("MonsterParty_down"):setVisible(false)
            self.m_WheelMainView:findChild("MonsterParty_jiantou"):setVisible(false)

            -- performWithDelay(self,function(  )
                if func then
                    func()
                end
            -- end,0.5)
            

            
         
        end)

        

    end )

 


end


function CodeGameScreenMonsterPartyMachine:showGuoChang( func1,func2 )
    

    gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_GuoChang.mp3")

    performWithDelay(self,function(  )
        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Open_Door.mp3")
    end,1)

    self.m_GuoChangAct:setVisible(true) 
    self.m_GuoChangAct:runCsbAction("actionframe",false,function(  )
        self.m_GuoChangAct:setVisible(false)
        if func2 then
            func2()
        end
    end)
    

    performWithDelay(self,function(  )
        if func1 then
            func1()
        end
    end,50/30)
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData: 
    @return:
]]
function CodeGameScreenMonsterPartyMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType

end

---
--设置bonus scatter 层级
function CodeGameScreenMonsterPartyMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1


    if symbolType == self.SYMBOL_MONSTERPARTAY_MYSTER then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    end
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS
        or symbolType == self.SYMBOL_JACKPOT_MEGA
            or symbolType == self.SYMBOL_JACKPOT_GRAND
                or symbolType == self.SYMBOL_JACKPOT_MAJOR
                    or symbolType == self.SYMBOL_JACKPOT_MINOR
                        or symbolType == self.SYMBOL_JACKPOT_MINI
                            or symbolType == self.SYMBOL_JACKPOT_MSP then

        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

function CodeGameScreenMonsterPartyMachine:triggerFreespinFromType( func )
    

    self:changeFreeReelVisible( true  )

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeSpinType

    if freeSpinType == self.FS_GAME_TYPE_m_batMan then

    elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then
        
        self.m_wolfManZhua:setVisible(false)
        self.m_wolfMan:setVisible(false)

    elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then

    elseif freeSpinType == self.FS_GAME_TYPE_greenMan then
        self.m_greenMan:setVisible(false)
    end

    if func then
        func()
    end


end

function CodeGameScreenMonsterPartyMachine:changeFreeReelVisible( isTriggerFs )
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE or isTriggerFs  then
        self:findChild("BaseReel"):setVisible(false)
        
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType
        if freeSpinType then
            self:showFreeReelsFromReelType( freeSpinType )
        end
        

    else

        self.m_Reels_batMan:setVisible(false)
        self.m_Reels_batMan:setVisible(false)
        self.m_Reels_wolfMan:setVisible(false)
        for i=1,#self.m_Reels_ghostGirl do
            local ghostGirlReel = self.m_Reels_ghostGirl[i]
            ghostGirlReel:setVisible(false)
        end
        self.m_Reels_greenMan:setVisible(false)

        self:findChild("BaseReel"):setVisible(true)

        self.m_batMan:setVisible(false) 
        self.m_wolfManZhua:setVisible(false)
        self.m_wolfMan:setVisible(false)
        self.m_ghostGirl:setVisible(false)
        self.m_greenMan:setVisible(false)

    end

end


function CodeGameScreenMonsterPartyMachine:initFreespinReels( )

    self.m_Reels_batMan =  self:createrOneReel( self.FS_GAME_TYPE_m_batMan ,1,"xixueguieel",1 )
    self.m_Reels_batMan:setVisible(false)
    self.m_Reels_wolfMan =  self:createrOneReel( self.FS_GAME_TYPE_wolfMan ,1,"langrenReel",1 )
    self.m_Reels_wolfMan:setVisible(false)

    self.m_Reels_ghostGirl = {}
    for i=1,3 do
        local ghostGirlReel = self:createrOneReel( self.FS_GAME_TYPE_ghostGirl ,i,"jiangshiReel_"..i,3 )
        table.insert(self.m_Reels_ghostGirl,ghostGirlReel)
        ghostGirlReel:setVisible(false)
        if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
            self.m_bottomUI.m_spinBtn:addTouchLayerClick(ghostGirlReel.m_touchSpinLayer)
        end
    end
     
    self.m_Reels_greenMan =  self:createrOneReel( self.FS_GAME_TYPE_greenMan ,1,"lvjurenReel",1 )
    self.m_Reels_greenMan:setVisible(false)

    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_Reels_batMan.m_touchSpinLayer)
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_Reels_wolfMan.m_touchSpinLayer)
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_Reels_greenMan.m_touchSpinLayer)
    end
end

function CodeGameScreenMonsterPartyMachine:createrOneReel( reelType,reelId,addNodeName ,maxReelIndex )
    
    local className = "CodeMonsterPartySrc.BatManMiniMachine.MonsterPartyBatManMiniMachine"

    if reelType == self.FS_GAME_TYPE_m_batMan then
        className = "CodeMonsterPartySrc.BatManMiniMachine.MonsterPartyBatManMiniMachine"
    elseif reelType == self.FS_GAME_TYPE_wolfMan then
        className = "CodeMonsterPartySrc.WolfManMiniMachine.MonsterPartyWolfManMiniMachine"
    elseif reelType == self.FS_GAME_TYPE_ghostGirl then
        className = "CodeMonsterPartySrc.GhostGirlMiniMachine.MonsterPartyGhostGirlMiniMachine"
        
    elseif reelType == self.FS_GAME_TYPE_greenMan then
        className = "CodeMonsterPartySrc.GreenManMiniMachine.MonsterPartyGreenManMiniMachine"
    end

    local reelData= {}
    reelData.reelType = reelType
    reelData.index = reelId
    reelData.maxReelIndex = maxReelIndex
    reelData.parent = self
    local miniReel = util_createView(className,reelData)
    self:findChild(addNodeName):addChild(miniReel) 

    return miniReel
end



function CodeGameScreenMonsterPartyMachine:showFsReelActMan( reelType  )


    if reelType == self.FS_GAME_TYPE_m_batMan then

        self.m_batMan:setVisible(true)
        util_spinePlay(self.m_batMan,"idleframe_1" , true)

    elseif reelType == self.FS_GAME_TYPE_wolfMan then

        
        self.m_wolfManZhua:setVisible(true)
        util_spinePlay(self.m_wolfManZhua,"idleframe" , true)
        self.m_wolfMan:setVisible(true)
        util_spinePlay(self.m_wolfMan,"idleframe" , true)

    elseif reelType == self.FS_GAME_TYPE_ghostGirl then
        -- self.m_ghostGirl:setVisible(true)
        
        
    elseif reelType == self.FS_GAME_TYPE_greenMan then
        self.m_greenMan:setVisible(true)
        util_spinePlay(self.m_greenMan,"idleframe" , true)
    end



end

function CodeGameScreenMonsterPartyMachine:showFreeReelsFromReelType( reelType )


    if reelType == self.FS_GAME_TYPE_m_batMan then

        self.m_Reels_batMan:setVisible(true)

        self:showFsReelActMan( reelType  )

    elseif reelType == self.FS_GAME_TYPE_wolfMan then

        self.m_Reels_wolfMan:setVisible(true)

        self:showFsReelActMan( reelType  )

    elseif reelType == self.FS_GAME_TYPE_ghostGirl then

        for i=1,#self.m_Reels_ghostGirl do
            local ghostGirlReel = self.m_Reels_ghostGirl[i]
            ghostGirlReel:setVisible(true)
        end

        
    elseif reelType == self.FS_GAME_TYPE_greenMan then
        self.m_Reels_greenMan:setVisible(true)
        self:showFsReelActMan( reelType  )
    end

    


end

---
-- 处理spin 返回结果
function CodeGameScreenMonsterPartyMachine:spinResultCallFun(param)


    BaseFastMachine.spinResultCallFun(self,param)

    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then


        if param[1] == true then
            local spinData = param[2]
            if spinData.result then
                if spinData.result.selfData then
                    if spinData.result.selfData.spinResults and #spinData.result.selfData.spinResults > 0 then
                     
                        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                        local freeSpinType = selfData.freeSpinType
                
                        if freeSpinType == self.FS_GAME_TYPE_m_batMan then

                            if self.m_Reels_batMan then
                                local miniReelsData = spinData.result.selfData.spinResults[1]
                                miniReelsData.bet = 0
                                miniReelsData.payLineCount = 0
                                self.m_Reels_batMan:netWorkCallFun(miniReelsData)
                            end
                
                        elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then
                            
                            if self.m_Reels_wolfMan then
                                local miniReelsData = spinData.result.selfData.spinResults[1]
                                miniReelsData.bet = 0
                                miniReelsData.payLineCount = 0
                                self.m_Reels_wolfMan:netWorkCallFun(miniReelsData)
                            end
                        elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then
                
                            for i=1,#self.m_Reels_ghostGirl do
                                local reels = self.m_Reels_ghostGirl[i]
                                if reels then
                                    local miniReelsData = spinData.result.selfData.spinResults[i]
                                    miniReelsData.bet = 0
                                    miniReelsData.payLineCount = 0
                                    reels:netWorkCallFun(miniReelsData)
                                end
                            end
                            
                        elseif freeSpinType == self.FS_GAME_TYPE_greenMan then

                            if self.m_Reels_greenMan then
                                local miniReelsData = spinData.result.selfData.spinResults[1]
                                miniReelsData.bet = 0
                                miniReelsData.payLineCount = 0
                                self.m_Reels_greenMan:netWorkCallFun(miniReelsData)
                            end

                        end

                    end
                    
                end
            end
        end
    end
    
 
end


function CodeGameScreenMonsterPartyMachine:beginReel()
    if  self:getCurrSpinMode() == FREE_SPIN_MODE then

        self:resetReelDataAfterReel()
        
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        if freeSpinType == self.FS_GAME_TYPE_m_batMan then


            self.m_Reels_batMan:beginMiniReel()

        elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then
            self.m_Reels_wolfMan:beginMiniReel()
        elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then

            for i=1,#self.m_Reels_ghostGirl do
                local reels = self.m_Reels_ghostGirl[i]
                reels:beginMiniReel() 
            end
            
        elseif freeSpinType == self.FS_GAME_TYPE_greenMan then
            self.m_Reels_greenMan:beginMiniReel()
        end


        self:setGameSpinStage(GAME_MODE_ONE_RUN)
    else

        BaseFastMachine.beginReel(self)
        
    end
end


--freespin下主轮调用父类停止函数
function CodeGameScreenMonsterPartyMachine:slotReelDownInLittleBaseReels( )
    self:setGameSpinStage( STOP_RUN )
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]
            
            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end



    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()
    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect( )
end

function CodeGameScreenMonsterPartyMachine:FSReelDownNotify( maxCount )
    
    self.m_FSLittleReelsDownIndex = self.m_FSLittleReelsDownIndex + 1

    if self.m_FSLittleReelsDownIndex == maxCount then

        self.m_FSLittleReelsDownIndex = 0


        self:slotReelDownInLittleBaseReels( )


        -- 只有鬼魂新娘这么更新钱
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        if freeSpinType == self.FS_GAME_TYPE_ghostGirl then

            local winLines = {}

            for i=1,#self.m_Reels_ghostGirl do
                local reel = self.m_Reels_ghostGirl[i]
                
                if reel.m_reelResultLines and #reel.m_reelResultLines > 0 then
                    winLines = reel.m_reelResultLines
                end
            end
    
            
    
            if #winLines > 0  then
                self:checkNotifyManagerUpdateWinCoin( )
            end

        end

    end

end

function CodeGameScreenMonsterPartyMachine:checkNotifyManagerUpdateWinCoin( )


    -- 这里作为连线时通知钱数更新的 唯一接口
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end 

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,isNotifyUpdateTop})

end

function CodeGameScreenMonsterPartyMachine:FSReelShowSpinNotify(maxCount )
    self.m_FSLittleReelsShowSpinIndex = self.m_FSLittleReelsShowSpinIndex + 1

    if self.m_FSLittleReelsShowSpinIndex == maxCount then

        
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
            end 
            
        end
        

        self.m_FSLittleReelsShowSpinIndex = 0
    end
end



function CodeGameScreenMonsterPartyMachine:quicklyStopReel(colIndex)
    
    

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        BaseFastMachine.quicklyStopReel(self, colIndex) 
    end
    
end


function CodeGameScreenMonsterPartyMachine:getFreeSpinReelsLines( )

    local lines = {}

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeSpinType

    if freeSpinType == self.FS_GAME_TYPE_m_batMan then

        if self.m_Reels_batMan then

            local miniReelslines = self.m_Reels_batMan:getResultLines()
            if miniReelslines then
                for i=1,#miniReelslines do
                    table.insert( lines,miniReelslines[i] )
                end
            end
        end

    elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then
        if self.m_Reels_wolfMan then

            local miniReelslines = self.m_Reels_wolfMan:getResultLines()
            if miniReelslines then
                for i=1,#miniReelslines do
                    table.insert( lines,miniReelslines[i] )
                end
            end
        end
    elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then
        if self.m_Reels_ghostGirl then

            for i=1,#self.m_Reels_ghostGirl do
                local miniReelslines = self.m_Reels_ghostGirl[i]:getResultLines()
                if miniReelslines then
                    for i=1,#miniReelslines do
                        table.insert( lines,miniReelslines[i] )
                    end
                end
            end
            
        end
    elseif freeSpinType == self.FS_GAME_TYPE_greenMan then
        if self.m_Reels_greenMan then

            local miniReelslines = self.m_Reels_greenMan:getResultLines()
            if miniReelslines then
                for i=1,#miniReelslines do
                    table.insert( lines,miniReelslines[i] )
                end
            end
        end
    end


    return lines
end


function CodeGameScreenMonsterPartyMachine:playEffectNotifyNextSpinCall( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


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
        
        delayTime = delayTime + self:getWinCoinTime()

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            
            local lines = self:getFreeSpinReelsLines( )
            

            if lines ~= nil and #lines > 0 then
                

                delayTime = delayTime + self:getWinCoinTime()

                
            end

            if self.m_runSpinResultData.p_features 
                and #self.m_runSpinResultData.p_features == 2 
                    and  self.m_runSpinResultData.p_features[2] == 1 then
                
                    delayTime = 0.5
                
            end

        end

        


        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

end

function CodeGameScreenMonsterPartyMachine:normalSpinBtnCall()


    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeSpinType

    if freeSpinType == self.FS_GAME_TYPE_greenMan then
        if self.m_Reels_greenMan.m_iReelRowNum > self.m_Reels_greenMan.m_iReelMinRow then
        
            self.m_Reels_greenMan:restAllDownWildLayerTag( )

            local direction = self.m_Reels_greenMan.m_iReelMinRow - self.m_Reels_greenMan.m_iReelRowNum
            self.m_Reels_greenMan.m_iReelRowNum = self.m_Reels_greenMan.m_iReelMinRow
            self.m_Reels_greenMan:changeReelLength(direction,function(  )
                
            end)

            BaseFastMachine.normalSpinBtnCall(self)

        else
    
            BaseFastMachine.normalSpinBtnCall(self)
        end

    else

        BaseFastMachine.normalSpinBtnCall(self)

    end
    

    


end

local curWinType = 0
---
-- 增加赢钱后的 效果
function CodeGameScreenMonsterPartyMachine:addLastWinSomeEffect() -- add big win or mega win

    
    local lines = {}
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local lines = self:getFreeSpinReelsLines( )
        if #lines == 0 then
            return
        end

    else
        if #self.m_vecGetLineInfo == 0 then
            return
        end
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值


    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢

        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)

    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or
            self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or
            self.m_fLastWinBetNumRatio < 1
    then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

end


-- 蝙蝠 锁定wild
function CodeGameScreenMonsterPartyMachine:initFSReelsLockWildFromNetNetData( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local wildLock = selfdata.wildLock

    if wildLock then

        if self.m_Reels_batMan  then
            self.m_Reels_batMan:initFsLockWild(wildLock)
        end

    end
end

-- 狼人收集wild框
function CodeGameScreenMonsterPartyMachine:initFSReelsCollectWildFromNetNetData( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local wildCollect = selfdata.wildCollect

    if wildCollect then

        if self.m_Reels_wolfMan  then
            self.m_Reels_wolfMan:updateCollectKuang( wildCollect )
        end

    end
end


function CodeGameScreenMonsterPartyMachine:checkIsAddFsWildLock( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local wildLock = selfdata.wildLock

    local isAddEffect = false

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        if self.m_Reels_batMan then
            self.m_Reels_batMan:setWildList( wildLock )
            if self.m_Reels_batMan.m_lockWildList and #self.m_Reels_batMan.m_lockWildList > 0 then
                isAddEffect = true
            end
        end

    end

    return isAddEffect
    
end

function CodeGameScreenMonsterPartyMachine:checkIsAddFsKuangLock( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local wildCollect = selfdata.wildCollect

    local isAddEffect = false

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        if self.m_Reels_wolfMan then
            
           
            isAddEffect = self.m_Reels_wolfMan:checkIsShowCollectKuang( wildCollect )
            
        end

    end

    return isAddEffect
    
end


function CodeGameScreenMonsterPartyMachine:CreateBatflyAct( parent,func )
    
    gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_batFly.mp3")

    local batflyAct = util_createAnimation("Socre_MonsterParty_xixuegui.csb")
    parent:addChild(batflyAct)
    batflyAct:runCsbAction("animation0",false,function(  )
        
        

        if func then
            func()
        end

        batflyAct:removeFromParent()
        

    end)

end

function CodeGameScreenMonsterPartyMachine:hidePaoAct( iCol )
    
    if self.m_paoAct == nil then
        
        return 
    end

    if #self.m_paoAct > 0 then
        gLobalSoundManager:playSound("MonsterPartySounds/music_MonsterParty_batman_Symbol_BATToWild.mp3")
    end
    for i=#self.m_paoAct,1,-1 do
        local paoAct = self.m_paoAct[i]
        if paoAct   then
            if paoAct.m_iCol == iCol then
                paoAct:runCsbAction("animation0",false,function(  )
                    paoAct:removeFromParent()
                end)

                table.remove( self.m_paoAct, i )
            end
            
        end
        
    end

    
    -- self.m_paoAct = {}
end

function CodeGameScreenMonsterPartyMachine:CreatePaoAct( iRow, iCol , func)
    local reelIdx = self:getPosReelIdx(iRow, iCol)
    local createPos = util_getOneGameReelsTarSpPos(self,reelIdx )
    local paoAct = util_createAnimation("Socre_MonsterParty_xixuegui_smoke.csb") 
    self:findChild("BaseReel"):addChild(paoAct,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + iRow)
    paoAct:setPosition(createPos)
    paoAct:runCsbAction("animation1",false,function(  )
        paoAct:runCsbAction("animation1",true)
        if func then
            func()
        end

        -- paoAct:removeFromParent()
        
    end)

    return paoAct
end

function CodeGameScreenMonsterPartyMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                if child.p_slotNodeH == nil then -- 打个补丁
                    child.p_slotNodeH = self.m_SlotNodeH
                end
                topY = childY + child.p_slotNodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end

---
-- 获取关卡下对应的free spin bg
--BigMegaView
function CodeGameScreenMonsterPartyMachine:getFreeSpinMusicBG()

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfData.freeSpinType

    if freeSpinType == self.FS_GAME_TYPE_m_batMan then

        return "MonsterPartySounds/music_MonsterParty_Bat_Bg.mp3"

    elseif freeSpinType == self.FS_GAME_TYPE_wolfMan then
        return "MonsterPartySounds/music_MonsterParty_WolfMan_Bg.mp3"
    elseif freeSpinType == self.FS_GAME_TYPE_ghostGirl then
        return "MonsterPartySounds/music_MonsterParty_GlostGirl_Bg.mp3"
    elseif freeSpinType == self.FS_GAME_TYPE_greenMan then
        return "MonsterPartySounds/music_MonsterParty_GreenMan_Bg.mp3"
    end

    
end


function CodeGameScreenMonsterPartyMachine:changeLocalViewNodePos( )
   

    if display.height >= FIT_HEIGHT_MAX then
    
        if (display.height / display.width) >= 2 then
            local jackpot =  self:findChild("jackpot")
            if jackpot then
                jackpot:setPositionY(jackpot:getPositionY() + 50)
            end
            
        else
            local jackpot =  self:findChild("jackpot")
            if jackpot then
                jackpot:setPositionY(jackpot:getPositionY() + 50 )
            end

        end
        
    elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
       
        local jackpot =  self:findChild("jackpot")
        if jackpot then
            jackpot:setPositionY(jackpot:getPositionY() - self.m_mainUiChangePos  )
        end

    else

        local jackpot =  self:findChild("jackpot")
        if jackpot then
            jackpot:setPositionY(jackpot:getPositionY() - self.m_mainUiChangePos  )
        end

        
    end


    local fsbar =  self:findChild("SpinRemaining")
    if fsbar then
        local posY = util_getConvertNodePos(self.m_topUI:findChild("TopUI_down"),fsbar).y
        local FS_Bar_H = 65
        fsbar:setPositionY(posY-FS_Bar_H)
    end

    

end

function CodeGameScreenMonsterPartyMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    if globalData.slotRunData.isPortrait == true then
        if display.height >= DESIGN_SIZE.height then
            mainScale = (FIT_HEIGHT_MAX  + 80 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
           
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale

        elseif display.height >= FIT_HEIGHT_MAX and display.height < DESIGN_SIZE.height then
            
            mainScale = (FIT_HEIGHT_MAX  + 10 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        elseif display.height < FIT_HEIGHT_MAX and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height + 80 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_mainUiChangePos = 40
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + self.m_mainUiChangePos  )
            
        else
            mainScale = (display.height + 80  - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_mainUiChangePos = 40
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + self.m_mainUiChangePos  )
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
    


    self:changeLocalViewNodePos( )
end


function CodeGameScreenMonsterPartyMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()

        local nodeLen = #self.m_lineSlotNodes
        for lineNodeIndex = nodeLen, 1, -1 do
            local lineNode = self.m_lineSlotNodes[lineNodeIndex]
            -- node = lineNode
            if lineNode ~= nil then -- TODO 打的补丁， 临时这样
                local preParent = lineNode.p_preParent
                if preParent ~= nil then
                    lineNode:runIdleAnim()
                end
            end
        end

        performWithDelay(self,function(  )
            self:resetMaskLayerNodes()
        end,3)
        performWithDelay(self,function(  )
            callFun()
        end,1)
        
    end,util_max(2,animTime),self:getModuleName())
end

--[[
    @desc: 如果触发了 freespin 时，将本次触发的bigwin 和 mega win 去掉
    time:2019-01-22 15:31:18
    @return:
]]
function CodeGameScreenMonsterPartyMachine:checkRemoveBigMegaEffect()
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect == true then
        if self.m_bProduceSlots_InFreeSpin == false then
            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
            self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
        end

    end

    -- 如果处于 freespin 中 那么大赢都不触发
    local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    if hasFsOverEffect == true  then -- or  self.m_bProduceSlots_InFreeSpin == true

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local freeSpinType = selfData.freeSpinType

        if freeSpinType ~= self.FS_GAME_TYPE_wolfMan then
            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
            self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
        end

    end

end

function CodeGameScreenMonsterPartyMachine:shakeSelfNode( func )
    local changePosY = 5
    local changePosX = 2
    local actionList2={}
    local oldPos = cc.p(self:findChild("BaseReel"):getPosition())

    for i=1,15 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end

    actionList2[#actionList2+1]=cc.CallFunc:create(function(  )
        if func then
            func()
        end
    end)

    for i=1,25 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end

    local seq2=cc.Sequence:create(actionList2)
    self:findChild("BaseReel"):runAction(seq2)


    local actionList3={}
    local oldPos3 = cc.p(self.m_gameBg:getPosition())
    for i=1,15 do
        actionList3[#actionList3+1]=cc.MoveTo:create(1/30,cc.p(oldPos3.x + changePosX ,oldPos3.y + changePosY))
        actionList3[#actionList3+1]=cc.MoveTo:create(1/30,cc.p(oldPos3.x,oldPos3.y))
    end
    for i=1,25 do
        actionList3[#actionList3+1]=cc.MoveTo:create(1/30,cc.p(oldPos3.x + changePosX ,oldPos3.y + changePosY))
        actionList3[#actionList3+1]=cc.MoveTo:create(1/30,cc.p(oldPos3.x,oldPos3.y))
    end

    local seq3=cc.Sequence:create(actionList3)
    self.m_gameBg:runAction(seq3)
end

function CodeGameScreenMonsterPartyMachine:shakeBGNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self.m_gameBg:getPosition())
    
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    local seq2=cc.Sequence:create(actionList2)
    self.m_gameBg:runAction(seq2)

end


return CodeGameScreenMonsterPartyMachine






