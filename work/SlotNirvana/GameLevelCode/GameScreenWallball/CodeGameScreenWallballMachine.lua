---
-- island li
-- 2019年1月26日
-- CodeGameScreenWallballMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenWallballMachine = class("CodeGameScreenWallballMachine", BaseNewReelMachine)

CodeGameScreenWallballMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenWallballMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型

CodeGameScreenWallballMachine.m_vecReelBalls = nil

CodeGameScreenWallballMachine.SHOW_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
CodeGameScreenWallballMachine.SHOW_ADD_MULTIPLES_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识


local BALL_RESULT = 
{
    replaceSignal777 = 1,
    replaceSignal77 = 2,
    multiple = 3,
    wholeColumn = 4,
    Grand = 5,
    Minor = 6,
    Major = 7,
    addFreeSpin = 8
}

-- 构造函数
function CodeGameScreenWallballMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_vecReelBalls = {}
    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end

function CodeGameScreenWallballMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("WallballConfig.csv", "LevelWallballConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
    self.m_validLineSymNum = 2
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWallballMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Wallball"  
end

--[[
    初始化黑色遮罩层
]]
function CodeGameScreenWallballMachine:initLayerBlack()

    local colorLayers = util_createReelMaskColorLayers( self ,REEL_SYMBOL_ORDER.REEL_ORDER_2 ,cc.c3b(0, 0, 0),130)
    self.m_layer_colors = colorLayers
    for key,layer in pairs(self.m_layer_colors) do
        layer:setVisible(false)
    end
end

--[[
    显示黑色遮罩层
]]
function CodeGameScreenWallballMachine:showLayerBlack(isShow)
    for key,layer in pairs(self.m_layer_colors) do
        if isShow then
            layer:setVisible(true)
            util_playFadeInAction(layer,0.1)
        else
            util_playFadeOutAction(layer,0.1)
            self:delayCallBack(0.1,function()
                layer:setVisible(false)
            end)
        end
        
    end
end


function CodeGameScreenWallballMachine:initUI()

    self.m_scatterBulingSoundArry = {}
    self.m_scatterBulingSoundArry["auto"] = "WallballSounds/sound_Wallball_scatter_down.mp3"

    self:setReelRunSound("WallballSounds/sound_Wallball_quick_run.mp3")
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_WallballView = util_createView("CodeWallballSrc.WallballView")
    -- self:findChild("xxxx"):addChild(self.m_WallballView)

    self.m_freespinBar = util_createView("CodeWallballSrc.WallballFreespinBarView")
    self:findChild("Freespin"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)

    self.m_nodeTip = util_createView("CodeWallballSrc.WallballTip")
    self:findChild("tishi"):addChild(self.m_nodeTip)
    
    self.m_jackpotCollect = util_createView("CodeWallballSrc.WallballJackpotCollect")
    self:findChild("shoujitiao"):addChild(self.m_jackpotCollect)
    self.m_jackpotCollect:setVisible(false)

    self.m_jackpotBar = util_createView("CodeWallballSrc.WallballJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)

    self.m_guochangEffect = util_spineCreate("Wallball_juese", true, true)
    self:addChild(self.m_guochangEffect, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self.m_guochangEffect:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_guochangEffect:setVisible(false)

    self.m_reel_ui = util_createAnimation("Wallball_reel_ui.csb")
    self:findChild("rell"):addChild(self.m_reel_ui,REEL_SYMBOL_ORDER.REEL_ORDER_2 - 100)

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    self:initLayerBlack()
 
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
        end

        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName = "WallballSounds/sound_Wallball_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            self.m_winSoundsId = nil
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenWallballMachine:guochangAnim(animation, endFunc, frame, frameFunc)
    self.m_guochangEffect:setVisible(true)
    gLobalSoundManager:playSound("WallballSounds/sound_Wallball_"..animation..".mp3")
    if animation == "actionframe3" then
        local animID = math.random(3, 4)
        animation = "actionframe"..animID
    end
    util_spinePlay(self.m_guochangEffect, animation)
    if frame ~= nil then
        util_spineFrameCallFunc(self.m_guochangEffect, animation, frame, function()
            if frameFunc ~= nil then
                frameFunc()
            end
        end, function()
            if endFunc ~= nil then
                endFunc()
            end
            self.m_guochangEffect:setVisible(false)
        end)
    else
        util_spineEndCallFunc(self.m_guochangEffect, animation, function()
            if endFunc ~= nil then
                endFunc()
            end
            self.m_guochangEffect:setVisible(false)
        end)
    end
end

function CodeGameScreenWallballMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("WallballSounds/sound_Wallball_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenWallballMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_ballGrids = util_createView("CodeWallballSrc.ZenPinball",{machine = self})
    self:findChild("wangge"):addChild(self.m_ballGrids)
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenWallballMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

end

function CodeGameScreenWallballMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWallballMachine:MachineRule_GetSelfCCBName(symbolType)

    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWallballMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenWallballMachine:MachineRule_initGame(  )

    
end

function CodeGameScreenWallballMachine:slotReelDown()
    local delayTime = 0

    for i = #self.m_vecReelBalls, 1, -1 do
        local ball = self.m_vecReelBalls[i]
        ball:changeAim()
        table.remove(self.m_vecReelBalls, i)
        delayTime = 0.5
    end

    performWithDelay(self, function()
        BaseNewReelMachine.slotReelDown(self)
        if #self.m_reelResultLines == 0 then
            -- scheduler.performWithDelayGlobal(function()
                if self.m_nodeMultiple ~= nil then
                    self.m_nodeMultiple:removeFromParent()
                    self.m_nodeMultiple = nil
                end
            -- end, 0.8, self:getModuleName())
        end
    end, delayTime)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenWallballMachine:showEffect_LineFrame(effectData)


    if self.m_nodeMultiple ~= nil then
        gLobalSoundManager:playSound("WallballSounds/sound_Wallball_jackpot_fly.mp3")
        local parent = self.m_bottomUI.m_normalWinLabel:getParent()
        local worldPos = self.m_nodeMultiple:getParent():convertToWorldSpace(cc.p(self.m_nodeMultiple:getPosition()))
        local startPos = parent:convertToNodeSpace(worldPos)
        local endPos = cc.p(self.m_bottomUI.m_normalWinLabel:getPosition())
        util_changeNodeParent(parent, self.m_nodeMultiple)
        self.m_nodeMultiple:setPosition(startPos)
        self.m_nodeMultiple:runCsbAction("shouji")
        self.m_nodeMultiple:runAction(cc.Sequence:create(cc.MoveTo:create(0.3, endPos), cc.CallFunc:create(function()
            gLobalSoundManager:playSound("WallballSounds/sound_Wallball_jackpt_collect.mp3")
            local effect, act = util_csbCreate("Wallball_board_multiwins_shouji.csb")
            parent:addChild(effect)
            effect:setPosition(endPos)
            util_csbPlayForKey(act, "actionframe", false, function()
                effect:removeFromParent()
            end)
            self.m_nodeMultiple:removeFromParent()
            self.m_nodeMultiple = nil
        end)))
    end

    return BaseNewReelMachine.showEffect_LineFrame(self, effectData)
end

--
--单列滚动停止回调
--
function CodeGameScreenWallballMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWallballMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.totalJackpots then
        self.m_jackpotCollect:showDotIdle(self.m_runSpinResultData.p_selfMakeData.totalJackpots)
        -- for key, value in pairs(self.m_runSpinResultData.p_selfMakeData.totalJackpots) do
        --     if key == "Minor" and value == 1 then
        --         self.m_jackpotBar:showJackpotLight(key)
        --     elseif key == "Major" and value == 2 then
        --         self.m_jackpotBar:showJackpotLight(key)
        --     elseif key == "Grand" and value == 3 then
        --         self.m_jackpotBar:showJackpotLight(key)
        --     end
        -- end
    end
    self.m_ballGrids:initSpecialRender( "FeatureGame" )
    self.m_freespinBar:setVisible(true)
    self.m_freespinBar:changeFreeSpinByCount()
    self.m_nodeTip:setVisible(false)
    self.m_jackpotCollect:setVisible(true)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle2")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWallballMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenWallballMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("WallballSounds/music_Wallball_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            -- self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            --     effectData.p_isPlay = true
            --     self:playGameEffect()
            -- end,true)
            -- gLobalSoundManager:setBackgroundMusicVolume(0)
            self:guochangAnim("actionframe2", function()
                effectData.p_isPlay = true
                self:playGameEffect()
                self:resetMusicBg()
            end)
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            performWithDelay(self, function()
                self.m_freespinBar:changeFreeSpinByCount()
                if self.m_addFreeSpin ~= nil then
                    self.m_addFreeSpin:removeFromParent()
                    self.m_addFreeSpin = nil
                end
                
            end, 1)
        else
            self:guochangAnim("actionframe", function()
                gLobalSoundManager:playSound("WallballSounds/sound_Wallball_show_fs_window.mp3")
                local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()       
                end)
                local light = util_createView("CodeWallballSrc.WallballSkyLight")
                view:findChild("light"):addChild(light)
            end, "show1", function()
                self.m_ballGrids:initSpecialRender( "FeatureGame" )
                self.m_freespinBar:setVisible(true)
                self.m_freespinBar:changeFreeSpinByCount()
                self.m_nodeTip:setVisible(false)
                self.m_jackpotCollect:setVisible(true)
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle2")
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenWallballMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("WallballSounds/sound_Wallball_fs_over.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},650)
    local light = util_createView("CodeWallballSrc.WallballSkyLight")
    view:findChild("light"):addChild(light)
    performWithDelay(self, function()
        self.m_ballGrids:initSpecialRender( "BaseGame" )
        self.m_freespinBar:setVisible(false)
        self.m_jackpotCollect:setVisible(false)
        self.m_jackpotCollect:resetJackpot()
        self.m_nodeTip:setVisible(true)
        
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle1")
    end, 0.5)
end

function CodeGameScreenWallballMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()
        self:playScatterTriggerIdle()
        callFun()
    end,util_max(2,animTime),self:getModuleName())
end

function CodeGameScreenWallballMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE



    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        local animName = slotNode:getLineAnimName()
        slotNode:runAnim(animName)
    end
    return slotNode
end

function CodeGameScreenWallballMachine:playScatterTriggerIdle()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil and lineNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- TODO 打的补丁， 临时这样
            lineNode:runAnim("idleframe2",true)
        end
    end
end

--[[
    @desc: Jackpot 弹框
    author:{author}
    time:2020-08-04 11:41:08
    @return:
]]
function CodeGameScreenWallballMachine:showJackpotWinView(jackpot, coins, func)
    gLobalSoundManager:setBackgroundMusicVolume(0.4)
    gLobalSoundManager:playSound("WallballSounds/sound_Wallball_show_jackpot.mp3")
    local view = util_createView("CodeWallballSrc.WallballJackpotOver")
    view:initViewData(jackpot, coins, self, func)
    local light = util_createView("CodeWallballSrc.WallballSkyLight")
    view:findChild("light"):addChild(light)
    gLobalViewManager:showUI(view)
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWallballMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    if self.m_nodeMultiple ~= nil then
        self.m_nodeMultiple:removeFromParent()
        self.m_nodeMultiple = nil
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    if self.m_rewardSound then
        gLobalSoundManager:stopAudio(self.m_rewardSound)
        self.m_rewardSound = nil
    end

    if self.m_jackpotCollect:isVisible() == true then
        self.m_jackpotCollect:hideEffect()
    end

    self.m_ballGrids:clearMutiBalls()

    self:setMaxMusicBGVolume()
    self:removeSoundHandler()

    return false -- 用作延时点击spin调用
end

function CodeGameScreenWallballMachine:playEffectNotifyNextSpinCall( )

    BaseNewReelMachine.playEffectNotifyNextSpinCall(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

  
    
end

-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenWallballMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenWallballMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end

function CodeGameScreenWallballMachine:updateNetWorkData()
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.balls ~= nil
     and #self.m_runSpinResultData.p_selfMakeData.balls > 0 then
        self.m_ballTotalNum = #self.m_runSpinResultData.p_selfMakeData.balls
        local gameStatus = "BaseGame"
        if self.m_bProduceSlots_InFreeSpin == true then
            gameStatus = "FeatureGame"
        end
        local delayTime = 1
        if self.m_bProduceSlots_InFreeSpin == true then
            local vecBalls = {}
            local id = math.random(1, 3)
            for i = 1, #self.m_runSpinResultData.p_selfMakeData.balls, 1 do
                local ballInfo = self.m_runSpinResultData.p_selfMakeData.balls[i]
                local endReel = nil
                if ballInfo.name == "wholeColumn" then
                    endReel = ballInfo.replaceColumn
                end
                local info = {}
                info.sType = BALL_RESULT[ballInfo.name] 
                info.nReel = endReel
                info.ballInfo = ballInfo
                vecBalls[#vecBalls + 1] = info
            end
            self.m_ballGrids:createBalls(gameStatus, vecBalls, function(reelID, index)
                self:ballEndCall(reelID, index)
            end, 1)
        else
            self:guochangAnim("actionframe3", nil, "show2", function()
                -- for i = 1, #self.m_runSpinResultData.p_selfMakeData.balls, 1 do
                local id = math.random(1, 3)
                gLobalSoundManager:playSound("WallballSounds/sound_Wallball_ball_start_"..id..".mp3")
                local ballInfo = self.m_runSpinResultData.p_selfMakeData.balls[1]
                local endReel = nil
                if ballInfo.name == "wholeColumn" then
                    endReel = ballInfo.replaceColumn
                end
                local list = {{sType = BALL_RESULT[ballInfo.name], nReel = endReel}}
                self.m_ballGrids:createBalls(gameStatus, list, function(reelID, index)
                    self:ballEndCall(reelID, index)
                end, 1)
                -- end
            end)
        end
    else
        BaseNewReelMachine.updateNetWorkData(self)
    end
end

function CodeGameScreenWallballMachine:ballEndCall(reelID, index)
    
    local ballInfo = self.m_runSpinResultData.p_selfMakeData.balls[index]
    if ballInfo.name ~= "multiple" then
        if self.m_rewardSound == nil then
            self.m_rewardSound = gLobalSoundManager:playSound("WallballSounds/sound_Wallball_"..ballInfo.name..".mp3")
        else
            performWithDelay(self, function()
                if self.m_rewardSound then
                    gLobalSoundManager:stopAudio(self.m_rewardSound)
                    self.m_rewardSound = nil
                end
                self.m_rewardSound = gLobalSoundManager:playSound("WallballSounds/sound_Wallball_"..ballInfo.name..".mp3")
            end, 1)
        end      
    end
    

    gLobalSoundManager:playSound("WallballSounds/sound_Wallball_reel_reward.mp3")
    if ballInfo.name == "replaceSignal777" or ballInfo.name == "replaceSignal77" then
        self:change7Anim(ballInfo)
    elseif ballInfo.name == "wholeColumn" then
        local iCol = ballInfo.replaceColumn
        for i = 1, self.m_iReelRowNum do
            performWithDelay(self, function()
                local symble = util_createView("CodeWallballSrc.WallballReelBall", ballInfo.name)
                self:addNewSymble(symble, iCol, i)
            end, (self.m_iReelRowNum - i) * 0.3)
        end
        performWithDelay(self, function()
            self.m_ballTotalNum = self.m_ballTotalNum - 1
            if self.m_ballTotalNum == 0 then
                self.m_ballGrids:resetBallAnim()
                BaseNewReelMachine.updateNetWorkData(self)
            end
        end, 1)
    elseif ballInfo.name == "multiple" then
        local multiBalls = self.m_ballGrids:getMultisBalls()
        if multiBalls and #multiBalls > 0 then
            for key,ball in pairs(multiBalls) do
                if ball.isMultis then
                    ball:findChild("labMultip"):setString(ballInfo.winMultiple.."x")
                end
            end
        end
        
        -- local multiple = util_createView("CodeWallballSrc.WallballReelBall", ballInfo.name)
        -- self:addEffectNode(multiple, reelID)
        -- local worldPos = self:getWorldPos(1, 3)
        -- local endPos = self.m_slotEffectLayer:convertToNodeSpace(worldPos)
        -- endPos.y = endPos.y - 70
        -- local moveTo = cc.MoveTo:create(0.3, endPos)
        -- local scale = cc.ScaleTo:create(0.3, 0.5)
        -- local spwan = cc.Spawn:create(moveTo, scale)
        -- multiple:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        --     multiple:showIdle()
        -- end), spwan, cc.CallFunc:create(function()
        --     if self.m_nodeMultiple == nil then
        --         self.m_nodeMultiple = multiple
        --         self.m_nodeMultiple.mul = ballInfo.winMultiple
        --     else
        --         local mul = ballInfo.winMultiple * self.m_nodeMultiple.mul
        --         self.m_nodeMultiple:setMultipNum(mul)
        --         multiple:removeFromParent()
        --     end
        --     self.m_ballTotalNum = self.m_ballTotalNum - 1
        --     if self.m_ballTotalNum == 0 then
        --         self.m_ballGrids:resetBallAnim()
        --         BaseNewReelMachine.updateNetWorkData(self)
        --     end
        -- end)))
        -- multiple:setMultipNum(ballInfo.winMultiple)
        BaseNewReelMachine.updateNetWorkData(self)
    elseif ballInfo.name == "addFreeSpin" then
        self.m_addFreeSpin = util_createView("CodeWallballSrc.WallballReelBall", ballInfo.name)
        self:addEffectNode(self.m_addFreeSpin, reelID)
        self.m_ballTotalNum = self.m_ballTotalNum - 1
        if self.m_ballTotalNum == 0 then
            self.m_ballGrids:resetBallAnim()
            BaseNewReelMachine.updateNetWorkData(self)
        end
    elseif ballInfo.name == "Minor" or ballInfo.name == "Grand" or ballInfo.name == "Major" then
        local jackpot = util_createView("CodeWallballSrc.WallballReelBall", ballInfo.name)
        self:addEffectNode(jackpot, reelID)
        local endPos = self.m_jackpotCollect:getEndPos(ballInfo.name)
        endPos = self.m_slotEffectLayer:convertToNodeSpace(endPos)
        local moveTo = cc.MoveTo:create(0.5, endPos)
        local scale = cc.ScaleTo:create(0.5, 0.2)
        local spwan = cc.Spawn:create(moveTo, scale)
        jackpot:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
            gLobalSoundManager:playSound("WallballSounds/sound_Wallball_jackpot_fly.mp3")
            jackpot:showIdle()
        end), spwan, cc.CallFunc:create(function()
            jackpot:removeFromParent()
            self.m_jackpotCollect:showCollect(ballInfo.name)
            gLobalSoundManager:playSound("WallballSounds/sound_Wallball_jackpt_collect.mp3")
            if self.m_runSpinResultData.p_selfMakeData.jackPotWinCoins then
                for i = 1, #self.m_runSpinResultData.p_selfMakeData.jackPotWinCoins, 1 do
                    self.m_jackpotBar:showJackpotLight(self.m_runSpinResultData.p_selfMakeData.jackPotWinCoins[i].jackpot)
                end
            end
            self.m_ballTotalNum = self.m_ballTotalNum - 1
            if self.m_ballTotalNum == 0 then
                self.m_ballGrids:resetBallAnim()
                BaseNewReelMachine.updateNetWorkData(self)
            end
        end)))
    else
        print("test")
    end
    
end

function CodeGameScreenWallballMachine:addNewSymble(node, iCol, iRow, specailZorder)
    local zorder = specailZorder or 0
    self.m_clipParent:addChild(node,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - zorder - iRow)
    local worldPos = self:getWorldPos(iRow, iCol)
    local symblePos = self.m_clipParent:convertToNodeSpace(worldPos)
    node:setPosition(symblePos)
    self.m_vecReelBalls[#self.m_vecReelBalls + 1] = node
end

function CodeGameScreenWallballMachine:addEffectNode(node, iCol)
    self.m_slotEffectLayer:addChild(node)
    local worldPos = self:getWorldPos(2, iCol)
    local symblePos = self.m_slotEffectLayer:convertToNodeSpace(worldPos)
    node:setPosition(symblePos)
end

function CodeGameScreenWallballMachine:getWorldPos(iRow, iCol)
    local iX = 71
    local iY = self.m_SlotNodeH * (iRow - 0.5)
    local colNodeName = "sp_reel_" .. (iCol- 1)
    local reel = self:findChild(colNodeName)
    local reelPos = cc.p(iX, iY)
    local worldPos = reel:convertToWorldSpace(reelPos)
    return worldPos
end

function CodeGameScreenWallballMachine:change7Anim(ballInfo)
    local vecPos = ballInfo.replacePos
    local average = math.floor(#vecPos / 3)
    local cycle = 1
    local vecTmepPos = {}
    local delayTime = 0.3
    while true do
        if average == 0 or cycle == 3 then
            vecTmepPos = vecPos
        else
            for i = 1, cycle, 1 do
                local randomID = math.random(1, #vecPos)
                vecTmepPos[#vecTmepPos + 1] = vecPos[randomID]
                table.remove(vecPos, randomID)
            end
        end
        for i = #vecTmepPos, 1, -1 do
            local index = vecTmepPos[i]
            local pos = self:getRowAndColByPos(index)
            performWithDelay(self, function()
                local symble = util_createView("CodeWallballSrc.WallballReelBall", ballInfo.name)
                self:addNewSymble(symble, pos.iY, pos.iX, 100)
            end, (cycle - 1) * 0.3)
            table.remove(vecTmepPos, i)
        end
        cycle = cycle + 1
        if #vecPos == 0 then
            performWithDelay(self, function()
                self.m_ballTotalNum = self.m_ballTotalNum - 1
                if self.m_ballTotalNum == 0 then
                    self.m_ballGrids:resetBallAnim()
                    BaseNewReelMachine.updateNetWorkData(self)
                end
            end, cycle * 0.3)
            break
        end
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWallballMachine:addSelfEffect()
    
        -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.DROP_BALL_EFFECT -- 动画类型
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.jackPotWinCoins then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.SHOW_JACKPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SHOW_JACKPOT_EFFECT -- 动画类型
    end



    local ballInfos = self.m_runSpinResultData.p_selfMakeData.balls
    if ballInfos then
        for key,info in pairs(ballInfos) do
            --判断是否中了加倍的小球
            if info.name == "multiple" then
                -- 自定义动画创建方式
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.SHOW_ADD_MULTIPLES_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.SHOW_ADD_MULTIPLES_EFFECT -- 动画类型
                break
            end
        end
        
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWallballMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.SHOW_JACKPOT_EFFECT then

        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
       
        -- effectData.p_isPlay = true
        -- self:playGameEffect()
        performWithDelay(self, function()
            self:showJackpotWin(effectData)
        end, 2)
    elseif effectData.p_selfEffectType == self.SHOW_ADD_MULTIPLES_EFFECT then   --加倍小球射激光动效
        local func = function()
            self.m_ballGrids:resetBallAnim()
            effectData.p_isPlay = true
            self:playGameEffect()
        end
        local multiBalls = self.m_ballGrids:getMultisBalls()
        if multiBalls and #multiBalls > 0 then
            self:showLayerBlack(true)
            self:delayCallBack(0.1,function()
                for key,ball in pairs(multiBalls) do
                    ball:runCsbAction("actionframe2")
                    self:delayCallBack(15 / 30,function()
                        self:runFlyLineAct(ball,self:findChild("bao"))
                    end)
                end
                gLobalSoundManager:playSound("WallballSounds/sound_Wallball_launch.mp3")
            end)

            self:delayCallBack((15 + 30) / 30,function()
                self:showLayerBlack(false)
                func()
            end)
        else
            func()
        end
        
    end

    
	return true
end

function CodeGameScreenWallballMachine:showJackpotWin(effectData)
    local jackpotWins = self.m_runSpinResultData.p_selfMakeData.jackPotWinCoins[1]
    self:showJackpotWinView(jackpotWins.jackpot, jackpotWins.winCoins, function()
        if #self.m_runSpinResultData.p_selfMakeData.jackPotWinCoins == 1 then
            self:setMaxMusicBGVolume()
            self:removeSoundHandler()
            self.m_jackpotBar:hideJackpotLight()
            effectData.p_isPlay = true
            self:playGameEffect()
            if #self.m_reelResultLines == 0 then
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_runSpinResultData.p_fsWinCoins))
            end
        else
            table.remove(self.m_runSpinResultData.p_selfMakeData.jackPotWinCoins, 1)
            performWithDelay(self, function()
                self:showJackpotWin(effectData)
            end, 0.8)
        end
    end)
    
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenWallballMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

--[[
    飞粒子动画
]]
function CodeGameScreenWallballMachine:runFlyLineAct(startNode,endNode,keyFunc,endFunc)

    -- 创建粒子
    local flyNode =  util_createAnimation("Wallball_qipan_jiguang.csb")
    self.m_effectNode:addChild(flyNode)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
    
    flyNode:setPosition(startPos)

    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:setScaleX(scaleSize / 422 )

    flyNode:runCsbAction("actionframe",false,function()
        if type(endFunc) == "function" then
            endFunc()
        end
        flyNode:removeFromParent()
    end)

    self:delayCallBack(10 / 30,function()
        --爆炸动画
        local ani = util_createAnimation("Wallball_qipan_bao.csb")
        self:findChild("rell"):addChild(ani,REEL_SYMBOL_ORDER.REEL_ORDER_2 - 110)
        ani:setPosition(util_convertToNodeSpace(endNode,self:findChild("rell")))
        ani:runCsbAction("actionframe",false,function()
            ani:removeFromParent()
            if type(keyFunc) == "function" then
                keyFunc()
            end
        end)
    end)
    return flyNode

end

--[[
    延迟回调
]]
function CodeGameScreenWallballMachine:delayCallBack(time, func)
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

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

function CodeGameScreenWallballMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == 4 then
        if nodeNum == 1  then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum < 2  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    else
        return runStatus.DUANG, false
    end
end

function CodeGameScreenWallballMachine:scaleMainLayer()
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
        local addY =  10
        mainScale = display.height / (self:getReelHeight() + uiH + uiBH)
        if display.height >= DESIGN_SIZE.height then
            mainScale = DESIGN_SIZE.height / (self:getReelHeight() + uiH + uiBH)
            addY = - 15
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + addY)
    end

end

function CodeGameScreenWallballMachine:getReelHeight( )
    if display.height >= DESIGN_SIZE.height then
        return 900
    else
        return 1010
    end
end

return CodeGameScreenWallballMachine






