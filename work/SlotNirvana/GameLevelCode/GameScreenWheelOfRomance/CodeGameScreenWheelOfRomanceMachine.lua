---
-- island li
-- 2019年1月26日
-- CodeGameScreenWheelOfRomanceMachine.lua
-- 
-- 玩法：
-- 
--Fix ios
local WheelOfRomanceShopData = util_require("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopData")

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenWheelOfRomanceMachine = class("CodeGameScreenWheelOfRomanceMachine", BaseSlotoManiaMachine)

CodeGameScreenWheelOfRomanceMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWheelOfRomanceMachine.RANDOM_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenWheelOfRomanceMachine.COLLECT_CORNER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识

CodeGameScreenWheelOfRomanceMachine.SYMBOL_BIG_H1 = 100 -- 3H1  男
CodeGameScreenWheelOfRomanceMachine.SYMBOL_BIG_H2 = 101 -- 3H2  女

CodeGameScreenWheelOfRomanceMachine.SYMBOL_BIG_H1_WILD = 102 -- 3H1  男 wild
CodeGameScreenWheelOfRomanceMachine.SYMBOL_BIG_H2_WILD = 103 -- 3H2  女 wild

CodeGameScreenWheelOfRomanceMachine.SYMBOL_WHEEL_BONUS_LUCKY = 96 -- lucky bonus
CodeGameScreenWheelOfRomanceMachine.SYMBOL_WHEEL_BONUS_GRAND = 196 -- grand bonus

CodeGameScreenWheelOfRomanceMachine.SYMBOL_MYSTERY = 97 -- Myster

CodeGameScreenWheelOfRomanceMachine.m_vecReelRowNum = {4,3,4,3,4}

CodeGameScreenWheelOfRomanceMachine.LONGRUN_COL_ADD_WILD = 4 

CodeGameScreenWheelOfRomanceMachine.BONUS_TYPE_JACKPOT = "JACKPOT" -- 进入大圆盘
CodeGameScreenWheelOfRomanceMachine.BONUS_TYPE_WHEEL = "WHEEL" -- 进入竖版滚轮
CodeGameScreenWheelOfRomanceMachine.SHOP_TYPE_COINS = "COIN" -- 商店获得钱
CodeGameScreenWheelOfRomanceMachine.m_outLineStates = true

CodeGameScreenWheelOfRomanceMachine.m_collectAnim = false

CodeGameScreenWheelOfRomanceMachine.m_shopTriggerBonus = false

-- 构造函数
function CodeGameScreenWheelOfRomanceMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_isOnceClipNode = false
    self.m_spinRestMusicBG = true

    self.m_collectAnim = false

    self.m_slotsAnimNodeFps = 60
    self.m_lineFrameNodeFps = 60 
    self.m_baseDialogViewFps = 60
    self.m_outLineStates = true
    self.m_bOpenShop = false

    self.m_randomSymbolSwitch = true
    self.m_isFeatureOverBigWinInFree = true

    globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA = WheelOfRomanceShopData:new()


    --init
    self:initGame()
end

function CodeGameScreenWheelOfRomanceMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("WheelOfRomanceConfig.csv", "LevelWheelOfRomanceConfig.lua")

    
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWheelOfRomanceMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WheelOfRomance"  
end

function CodeGameScreenWheelOfRomanceMachine:shopIconClickCallFunc( sender, eventType )

    if eventType == ccui.TouchEventType.ended then
        
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offx=math.abs(endPos.x-beginPos.x)
        if offx<50 and globalData.slotRunData.changeFlag == nil then
            
            gLobalNoticManager:postNotification("SHOW_WHEELOFROMANCE_SHOP")
            

        end
    end
end

function CodeGameScreenWheelOfRomanceMachine:initMachineUI( )
    
    BaseSlotoManiaMachine.initMachineUI( self )

    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for i =1 ,#self.m_slotParents do
        local parentData = self.m_slotParents[i]
        
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)

        local node = cc.Node:create()
        parentData.slotParent:getParent():addChild(node,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)

        local slotParentNode_1 = cc.LayerColor:create(cc.c3b(0, 0, 0)) 
        slotParentNode_1:setOpacity(200)
        slotParentNode_1:setContentSize(reelSize.width, reelSize.height)
        slotParentNode_1:setPositionX(reelSize.width * 0.5)
        node:addChild(slotParentNode_1,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)

        self["colorLayer_"..i] = node
        node:setVisible(false)

    end

end


function CodeGameScreenWheelOfRomanceMachine:initUI()

    self.m_reelRunSound = "WheelOfRomanceSounds/WheelOfRomanceSounds_longRun.mp3"

    self.m_gameBg:setAutoScaleEnabled(false)

    self.m_gameBglight = util_createAnimation("GameScreenWheelOfRomanceBg_light.csb")
    self.m_gameBg:findChild("node_light"):addChild(self.m_gameBglight)
    self.m_gameBglight:runCsbAction("idleframe",true)

    self.m_gameBgYanHua = util_createAnimation("GameScreenWheelOfRomanceBg_YanHua.csb")
    self.m_gameBg:findChild("Node_Yanhua"):addChild(self.m_gameBgYanHua)
    self.m_gameBgYanHua:runCsbAction("yanhua1",true)
    

    self.m_gameBgmtl = util_createAnimation("GameScreenWheelOfRomanceBg_mtl.csb")
    self.m_gameBg:findChild("Node_mtl"):addChild(self.m_gameBgmtl)
    self.m_gameBgmtl:runCsbAction("idleframe",true)

    util_setCascadeOpacityEnabledRescursion(self.m_gameBg,true)

    self:runCsbAction("normal")

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_jackpotBar = util_createView("CodeWheelOfRomanceSrc.WheelOfRomanceJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)
    
    self:findChild("Node_Shop"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
    self.m_shopIcon = util_createAnimation("WheelOfRomance_shop_icon.csb")
    self:findChild("Node_Shop"):addChild(self.m_shopIcon)
    self.m_shopIcon:runCsbAction("idle",true)
    local shopClick = self.m_shopIcon:findChild("click")
    if shopClick then
        shopClick:addTouchEventListener(handler(self, self.shopIconClickCallFunc))
    end
    
    self.m_shopIcon_Tip = util_createView("CodeWheelOfRomanceSrc/WheelOfRomanceTipView","WheelOfRomance_shop_icon_Tip.csb")  
    self:addChild(self.m_shopIcon_Tip,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    local pos = util_getConvertNodePos(self.m_shopIcon:findChild("Node_Tip"),self.m_shopIcon_Tip )
    self.m_shopIcon_Tip:setPosition(pos)
    self.m_shopIcon_Tip:showView( )

    self.m_shopIcon_Tip_bg = util_createAnimation("WheelOfRomance_shop_Tip_0.csb") 
    self:findChild("Node_Shop"):addChild(self.m_shopIcon_Tip_bg)
    self.m_shopIcon_Tip_bg:setLocalZOrder(-1)
    self.m_shopIcon_Tip_bg:setVisible(true)
    
    self.m_shopIcon_Tip:setCallFunc(function(  )
        self.m_shopIcon_Tip_bg:setVisible(true)
        self.m_shopIcon_Tip_bg:runCsbAction("show")
    end,function(  )
        self.m_shopIcon_Tip_bg:runCsbAction("idle")
    end,function(  )
        self.m_shopIcon_Tip_bg:runCsbAction("over",false,function(  )
            self.m_shopIcon_Tip_bg:setVisible(false)
        end,60)
    end )

    self.m_qianShou = util_createAnimation("WheelOfRomance_qianshou.csb")
    self:findChild("Node_qianshou"):addChild(self.m_qianShou)
    self.m_qianShou:setVisible(false)
    
    
 

    self.m_GuoChangDarkBG = util_createAnimation("WheelOfRomance_dark.csb") 
    self:findChild("Node_GuoChang"):addChild(self.m_GuoChangDarkBG, - 1)
    self.m_GuoChangDarkBG:setVisible( false)
    self.m_GuoChangDarkBG:runCsbAction("idle")

    self.m_GuoChang = util_createAnimation("WheelOfRomance_guochang.csb") 
    self:findChild("Node_GuoChang"):addChild(self.m_GuoChang)
    self.m_GuoChang:setVisible(false)

    


    self.m_darkBG = util_createAnimation("WheelOfRomance_dark.csb") 
    self.m_clipParent:addChild(self.m_darkBG, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 1)
    self.m_darkBG:setVisible( false)
    self.m_darkBG:runCsbAction("idle")
    self.m_darkBG:setScale(5)


    self:findChild("Node_WheelQianShou"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 2)

    self.m_qianShouMan = util_spineCreate("WheelOfRomance_AddWildguchang_nan",true,true)
    self:findChild("Node_WheelQianShou"):addChild(self.m_qianShouMan)
    self.m_qianShouMan:setVisible(false)
    self.m_qianShouMan:setPositionX(0)

    self.m_qianShouGirl = util_spineCreate("WheelOfRomance_AddWildguochang_nv",true,true)
    self:findChild("Node_WheelQianShou"):addChild(self.m_qianShouGirl)
    self.m_qianShouGirl:setVisible(false)
    self.m_qianShouGirl:setPositionX(0)

    local posGirl = util_getConvertNodePos(self.m_bottomUI, self.m_qianShouGirl)
    self.m_qianShouGirl:setPositionY(posGirl.y + 390)
    local posMan = util_getConvertNodePos(self.m_bottomUI, self.m_qianShouMan)
    self.m_qianShouMan:setPositionY(posMan.y + 390)


    for i=1,5 do
        self["m_colorLayer_waitNode_"..i] = cc.Node:create()
        self:addChild(self["m_colorLayer_waitNode_"..i])
    end
    
    self.m_runDataWaitNode = cc.Node:create()
    self:addChild(self.m_runDataWaitNode) 

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
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
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "WheelOfRomanceSounds/music_WheelOfRomance_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenWheelOfRomanceMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "WheelOfRomanceSounds/music_WheelOfRomance_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenWheelOfRomanceMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self.m_portraitWheelView = util_createView("CodeWheelOfRomanceSrc.PortraitWheel.WheelOfRomanceFeatureMainView",self)
    self:findChild("Node_Wheel_1"):addChild(self.m_portraitWheelView)
    self.m_portraitWheelView:runCsbAction("idle")
    self.m_portraitWheelView:setVisible(false)


    self.m_circularWheelView = util_createView("CodeWheelOfRomanceSrc.CircularWheel.WheelOfRomanceWheelView",self)
    self:findChild("Node_Wheel_2"):addChild(self.m_circularWheelView)
    self.m_circularWheelView:runCsbAction("idleframe")
    self.m_circularWheelView:setVisible(false)
    if display.width == 1024 then
        self.m_circularWheelView:setPositionY(-50)
    end

    self.m_circularWheelJackpotBar = util_createView("CodeWheelOfRomanceSrc.WheelOfRomanceJackPotBarView",true)
    self:findChild("Node_jackpot_wheel"):addChild(self.m_circularWheelJackpotBar)
    self.m_circularWheelJackpotBar:initMachine(self)

    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()


    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collect = selfdata.collect or {}
    local points = collect.points or {}
    self:updateCollectPoints( points )

end

function CodeGameScreenWheelOfRomanceMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)


    gLobalNoticManager:addObserver(
        self,
        function(self, params)

            if self:shopIconCanClick() then

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

                self.m_bOpenShop = true
                self.m_bottomUI:showAverageBet()
                globalData.slotRunData.lastWinCoin = 0
                self.m_bottomUI:resetWinLabel()
                self.m_bottomUI:checkClearWinLabel()
                self:showShop(
                    function()                 
                        self.m_bOpenShop = false
                        self.m_bottomUI:hideAverageBet()
                        self.m_bShopOpen = false
                        self.m_shopMainView = nil

                        
                        self:removeSoundHandler()

                        if not self.m_shopTriggerBonus then
                            self:resetMusicBg(true)
                            self:setMaxMusicBGVolume()
                            self:reelsDownDelaySetMusicBGVolume( ) 
                            
                        end
                        
                        self.m_shopTriggerBonus = false

                        self:playGameEffect()
                    end
                )
            end

            
        end,
        "SHOW_WHEELOFROMANCE_SHOP"
    )
    
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local collect = selfdata.collect or {}
            local points = collect.points or {}
            self:updateCollectPoints(points )

        end,
        "WHEELOFROMANCE_SHOP_ITEM_CLICK"
    )
end

function CodeGameScreenWheelOfRomanceMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA = nil
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWheelOfRomanceMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BIG_H1 then
       return "Socre_WheelOfRomance_9_H"
    elseif symbolType == self.SYMBOL_BIG_H2 then
        return "Socre_WheelOfRomance_8_H"
    elseif symbolType == self.SYMBOL_BIG_H1_WILD then
        return "Socre_WheelOfRomance_9_H_Wild"
    elseif symbolType == self.SYMBOL_BIG_H2_WILD then
        return "Socre_WheelOfRomance_8_H_Wild"
    elseif symbolType == self.SYMBOL_WHEEL_BONUS_LUCKY then
        return "Socre_WheelOfRomance_Bonus_Lucky"
    elseif symbolType == self.SYMBOL_WHEEL_BONUS_GRAND then
        return "Socre_WheelOfRomance_Bonus_Grand"
    elseif symbolType == self.SYMBOL_MYSTERY then
        return "Socre_WheelOfRomance_1"
    end

    return nil
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenWheelOfRomanceMachine:MachineRule_initGame(  )

    -- 滚动层的父节点裁剪
    local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + 3)
    if clipNode then
        clipNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    end
    
end

--
--单列滚动停止回调
--
function CodeGameScreenWheelOfRomanceMachine:slotOneReelDown(reelCol)    
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol) 
   
    
    if reelCol == 3 and self:checkTriggerAddWIldLongRun() then
        
        self:showColorLayer(1 )
        self:showColorLayer(3 )
        self:showColorLayer(5 )

    end
    
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWheelOfRomanceMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWheelOfRomanceMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWheelOfRomanceMachine:MachineRule_SpinBtnCall()
    
    self.m_shopIcon_Tip:hideView()

    self:setNetMystery()

    self.m_outLineStates = false

    self:setMaxMusicBGVolume( )
   



    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWheelOfRomanceMachine:addSelfEffect()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local wildPositions = selfdata.wildPositions or {}
    if #wildPositions > 0 then
       -- 随机添加wild
       local selfEffect = GameEffectData.new()
       selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
       selfEffect.p_effectOrder = self.RANDOM_WILD_EFFECT
       self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
       selfEffect.p_selfEffectType = self.RANDOM_WILD_EFFECT -- 动画类型 
    end


    local points = selfdata.points or {}
    if #points > 0 then
        -- 收集角标
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_CORNER_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_CORNER_EFFECT -- 动画类型 
    end
        

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWheelOfRomanceMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.RANDOM_WILD_EFFECT then

        self:playRandomAddWildEffect(  effectData )

    elseif effectData.p_selfEffectType == self.COLLECT_CORNER_EFFECT then 

        self:playCollectCornerEffect(  effectData )

    end

    
    return true
end

function CodeGameScreenWheelOfRomanceMachine:playCollectCornerEffect( effectData )

    gLobalSoundManager:playSound("WheelOfRomanceSounds/music_WheelOfRomance_CollectCorner.mp3")

    self.m_collectAnim = true

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local points = selfdata.points or {}
    local time = 60/60
    for i=1,#points do

        local list = points[i]
        local cormerNum = list[2]
        local posIndex = list[1]
        local fixPos = self:getRowAndColByPos(posIndex)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX,SYMBOL_NODE_TAG)
        if symbolNode  then
            
            local cornerNode = symbolNode:getChildByName("CollectCorner")
            
            -- 对应位置创建好脚标
            local newCorn = util_createAnimation("WheelOfRomance_icon_shouji.csb")
            self.m_clipParent:addChild(newCorn,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 200)
            newCorn:runCsbAction("actionframe") -- 播放创建好的脚标动画
            if cormerNum then
                newCorn:findChild("m_lb_coins"):setString(cormerNum)
            end

            local pos = cc.p(util_getConvertNodePos(cornerNode,newCorn)) 
            newCorn:setPosition(pos)

            --移除小块内的脚标
            if cornerNode then
                cornerNode:removeFromParent()
            end

            
            local endPos = cc.p(util_getConvertNodePos(self.m_shopIcon:findChild("Node_Corner"),newCorn)) 
            local startPos = cc.p(util_getConvertNodePos(newCorn,self.m_shopIcon:findChild("Node_Corner")))

            local actionList = {}
            actionList[#actionList + 1] =cc.DelayTime:create(30/60)
            actionList[#actionList + 1] = cc.CallFunc:create(function(  )
                local Particle_1 = newCorn:findChild("Particle_1")
                if Particle_1 then
                    Particle_1:setPositionType(0)
                    Particle_1:setDuration(-1)
                end
                local Particle_2 = newCorn:findChild("Particle_2")
                if Particle_2 then
                    Particle_2:setPositionType(0)
                    Particle_2:setDuration(-1)
                end
            end)
            actionList[#actionList + 1] = cc.JumpTo:create(time - 30/60,endPos,30,1)
            actionList[#actionList + 1] = cc.CallFunc:create(function(  )
                newCorn:findChild("maobi"):setVisible(false)
                self.m_shopIcon:runCsbAction("fankui",false,function(  )
                    self.m_shopIcon:runCsbAction("idle",true)
                end,60)
                
                local Particle_1 = newCorn:findChild("Particle_1")
                if Particle_1 then
                    Particle_1:stopSystem()
                end
                local Particle_2 = newCorn:findChild("Particle_2")
                if Particle_2 then
                    Particle_2:stopSystem()
                end
            end)
            actionList[#actionList + 1] = cc.DelayTime:create(1)
            actionList[#actionList + 1] = cc.CallFunc:create(function(  )
                newCorn:setVisible(false)
                newCorn:removeFromParent()
            end)
            local sq = cc.Sequence:create(actionList)
            newCorn:runAction(sq)
                


        end 
    end


    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collect = selfdata.collect or {}
    local points = collect.points or {}
   

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )


        self:updateCollectPoints(points  )

        waitNode:removeFromParent()
    end,time)

    local waitTime = 0
    local isWait = false
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 then
        isWait = true
    end

    if isWait then
        waitTime = time
    end

    local waitNode_1 = cc.Node:create()
    self:addChild(waitNode_1)
    performWithDelay(waitNode_1,function(  )

        

        effectData.p_isPlay = true
        self:playGameEffect()

        waitNode_1:removeFromParent()
    end,waitTime)

   

  

end



function CodeGameScreenWheelOfRomanceMachine:playRandomAddWildEffect(  effectData )

    gLobalSoundManager:playSound("WheelOfRomanceSounds/music_WheelOfRomance_xianHua.mp3")

    self.m_gameBgYanHua:runCsbAction("yanhua2",true)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local wildPositions = selfdata.wildPositions or {}

    local boySymbolNode = self:getBigSymbolNode(2, 2)
    local boyAniNode = util_spineCreate("Socre_WheelOfRomance_9_H",true,true)
    self.m_clipParent:addChild(boyAniNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)
    local boyWorldPos = boySymbolNode:getParent():convertToWorldSpace(cc.p(boySymbolNode:getPositionX(), boySymbolNode:getPositionY()))
    local boyPos = self.m_clipParent:convertToNodeSpace(cc.p(boyWorldPos.x,boyWorldPos.y))
    boyAniNode:setPosition(boyPos)
    util_spinePlay(boyAniNode,"actionframe_shuiji")
    util_spineEndCallFunc(boyAniNode,"actionframe_shuiji",function(  )
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            boySymbolNode:setVisible(true)
            boyAniNode:removeFromParent()
            waitNode:removeFromParent()
        end,0)
        
    end)

    local girlSymbolNode = self:getBigSymbolNode(2, 4)
    girlSymbolNode:setVisible(false)
    local girlAniNode = util_spineCreate("Socre_WheelOfRomance_8_H",true,true)
    self.m_clipParent:addChild(girlAniNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)
    local  girlWorldPos = girlSymbolNode:getParent():convertToWorldSpace(cc.p(girlSymbolNode:getPositionX(), girlSymbolNode:getPositionY()))
    local  girlPos =  self.m_clipParent:convertToNodeSpace(cc.p(girlWorldPos.x, girlWorldPos.y))
    girlAniNode:setPosition( girlPos)

    util_spinePlay(girlAniNode,"actionframe_shuiji")
    util_spineEndCallFunc(girlAniNode,"actionframe_shuiji",function(  )

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            girlSymbolNode:setVisible(true)
            girlAniNode:removeFromParent()

            local waitTime = 0
            for i=1,#wildPositions do

                local symbolPosIndex = wildPositions[i]

                local pos = util_getOneGameReelsTarSpPos(self,symbolPosIndex)
                local wildAct = util_spineCreate("Socre_WheelOfRomance_Wild",true,true)
                self.m_clipParent:addChild(wildAct,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 1)
                wildAct:setPosition(pos)
                wildAct:setVisible(false)

                waitTime = waitTime + 0.1 * (i-1)

                local waitNode_3 = cc.Node:create()
                self:addChild(waitNode_3)
                performWithDelay(waitNode_3,function(  )

                    gLobalSoundManager:playSound("WheelOfRomanceSounds/music_WheelOfRomance_showWild.mp3")
                    
                    local symbolPosIndex_1 = symbolPosIndex

                    wildAct:setVisible(true)
                    util_spinePlay(wildAct,"actionframe2")
                    util_spineEndCallFunc(wildAct,"actionframe2",function(  )

                        local fixPos = self:getRowAndColByPos(symbolPosIndex_1)
                        local turnSymbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX,SYMBOL_NODE_TAG)
                        turnSymbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                        turnSymbolNode:changeSymbolImageByName( self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD) )

                        wildAct:setVisible(false)
                        local wildAct_1 = wildAct
                        performWithDelay(wildAct_1,function(  )
                            wildAct_1:removeFromParent()
                        end,0)
                    end)

                    waitNode_3:removeFromParent()
                end,waitTime)
                


            end
    

            boySymbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_BIG_H1_WILD), self.SYMBOL_BIG_H1_WILD)
            boySymbolNode:changeSymbolImageByName( self:getSymbolCCBNameByType(self, self.SYMBOL_BIG_H1_WILD) )
            girlSymbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_BIG_H2_WILD), self.SYMBOL_BIG_H2_WILD)
            girlSymbolNode:changeSymbolImageByName( self:getSymbolCCBNameByType(self, self.SYMBOL_BIG_H2_WILD) )


            boySymbolNode:runAnim("actionframe_wild")
            girlSymbolNode:runAnim("actionframe_wild")

            performWithDelay(waitNode,function(  )

                self.m_gameBgYanHua:runCsbAction("yanhua1",true)

                effectData.p_isPlay = true
                self:playGameEffect()


                waitNode:removeFromParent()

            end,waitTime + 2 + 0.1)
                
    
        end,0)

    end)

end


function CodeGameScreenWheelOfRomanceMachine:playEffectNotifyNextSpinCall( )

    BaseSlotoManiaMachine.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenWheelOfRomanceMachine:slotReelDown( )


    for i=1,self.m_iReelColumnNum do
        self:hideColorLayer(i )
    end

    BaseSlotoManiaMachine.slotReelDown(self)
end


function CodeGameScreenWheelOfRomanceMachine:getNextReelSymbolType( )
    
    return self.m_runSpinResultData.p_prevReel
end

--
--设置bonus scatter 层级
function CodeGameScreenWheelOfRomanceMachine:getBounsScatterDataZorder(symbolType )


    local order = BaseSlotoManiaMachine.getBounsScatterDataZorder(self,symbolType )

    if  symbolType ==  self.SYMBOL_BIG_H1  then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + TAG_SYMBOL_TYPE.SYMBOL_SCATTER + 2
    elseif symbolType ==  self.SYMBOL_BIG_H2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + TAG_SYMBOL_TYPE.SYMBOL_SCATTER + 1
    elseif symbolType ==  self.SYMBOL_WHEEL_BONUS_LUCKY then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    end
    
    return order

end

function CodeGameScreenWheelOfRomanceMachine:getFinalResultCurrReelRowNum( _iCol )
    return self.m_vecReelRowNum[_iCol]
end

function CodeGameScreenWheelOfRomanceMachine:getBigSymbolMaskRowCount( _iCol )
    
    return self.m_vecReelRowNum[_iCol]
end

--[[
    *********************
    过场动画
--]]
function CodeGameScreenWheelOfRomanceMachine:showGuoChang(_func )
    

    self.m_GuoChang:setVisible(true)
    self.m_GuoChang:runCsbAction("actionframe",false,function(  )
        if _func then
            _func()
        end

        self.m_GuoChang:setVisible(false)
    end,60)

    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function(  )
        self.m_GuoChangDarkBG:runCsbAction("over",false,function(  )
            self.m_GuoChangDarkBG:setVisible(false)
        end,60)
        node:removeFromParent()
    end,102/60)

end

--[[
    *********************
    压暗图
--]]
function CodeGameScreenWheelOfRomanceMachine:showDarkBg( _func )
    
    self.m_darkBG:setVisible(true)
    self.m_darkBG:runCsbAction("start",false,function(  )

        if _func then
            _func()
        end

        
    end,60)

end

function CodeGameScreenWheelOfRomanceMachine:hideDarkBg( _func )
    
    self.m_darkBG:runCsbAction("over",false,function(  )

        self.m_darkBG:setVisible(false)


        if _func then
            _func()
        end
    end,60)


end

-- 更新控制类数据
function CodeGameScreenWheelOfRomanceMachine:SpinResultParseResultData( spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata and selfdata.collect then
        local data = selfdata.collect
        globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:parseData(data)
    end
end

--[[
    ********************
    收集玩法    
--]]

function CodeGameScreenWheelOfRomanceMachine:updateCollectPoints( _points )

    self.m_shopIcon:findChild("m_lb_coins"):setString(util_formatCoins(_points,5))
    local node=self.m_shopIcon:findChild("m_lb_coins")
    self.m_shopIcon:updateLabelSize({label=node,sx=0.8,sy=0.8},106)
end

--添加收集角标

function CodeGameScreenWheelOfRomanceMachine:getSlotNodeWithPosAndType(symbolType , row, col ,isLastSymbol)
    local node = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self,symbolType, row, col,isLastSymbol)

    if not self.m_outLineStates  then
 
        self:addCollectCorner( node )

    end

    return node
end



function CodeGameScreenWheelOfRomanceMachine:checkIsAddCorner(_table,_value )
    
    for i=1,#_table do
        local list = _table[i]
        if list[1] then
            if list[1] == _value then
                return true ,list[2]
            end
        end
    end

    return false
end

function CodeGameScreenWheelOfRomanceMachine:addCollectCorner( _symbolNode )

    local cornerNode = _symbolNode:getChildByName("CollectCorner")
    if cornerNode then
        cornerNode:removeFromParent()
    end

    if _symbolNode then

        if _symbolNode:isLastSymbol() then
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local points = selfdata.points or {}
            
            local posIndex = self:getPosReelIdx(_symbolNode.p_rowIndex, _symbolNode.p_cloumnIndex) 

            local isAdd ,cormerNum = self:checkIsAddCorner(points,posIndex )
            if  isAdd then
                cornerNode = util_createAnimation("WheelOfRomance_icon_shouji.csb")
                _symbolNode:addChild(cornerNode,100)
                cornerNode:setName("CollectCorner")
                cornerNode:runCsbAction("idleframe")
                cornerNode:setPosition(60,-30)
                if cormerNum then
                    cornerNode:findChild("m_lb_coins"):setString(cormerNum)
                end
                
            end
            

        end

    end
    
   
    
   
end

-- 处理特殊关卡 遮罩层级
function CodeGameScreenWheelOfRomanceMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
   
end

function CodeGameScreenWheelOfRomanceMachine:playCustomSpecialSymbolDownAct( slotNode )
    
    CodeGameScreenWheelOfRomanceMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    local soundPath = nil
    if slotNode.p_symbolType == self.SYMBOL_WHEEL_BONUS_LUCKY  then

        local slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_WHEEL_BONUS_LUCKY,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE) 

        slotNode:runAnim("buling")

        soundPath = "WheelOfRomanceSounds/WheelOfRomanceSounds_TriggerBonusDown.mp3"
        


    elseif slotNode.p_symbolType == self.SYMBOL_BIG_H1 then

        if self:checkSymbolBig_H1_Full( ) then
            slotNode:runAnim("buling")
            soundPath = "WheelOfRomanceSounds/WheelOfRomanceSounds_Big_H1_Down.mp3"
            
        end
        
    elseif slotNode.p_symbolType == self.SYMBOL_BIG_H2 then

        if self:checkSymbolBig_H1_Full( ) then
            if self:checkSymbolBig_H2_Full( ) then
                slotNode:runAnim("buling") 
                soundPath = "WheelOfRomanceSounds/WheelOfRomanceSounds_Big_H2_Down.mp3"
            end
        end
        
    end

    if soundPath then
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    end
end

--[[
    *******************
    商店玩法    
--]]

function CodeGameScreenWheelOfRomanceMachine:shopIconCanClick()
    local isFreespin = self.m_bProduceSlots_InFreeSpin == true
    local isNormalNoIdle = self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE
    local isRunningEffect = self.m_isRunningEffect == true
    local isAutoSpin = self:getCurrSpinMode() == AUTO_SPIN_MODE
    local features = self.m_runSpinResultData.p_features or {}
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus
    if isFreespin or isNormalNoIdle or isFreespinOver or isRunningEffect or isAutoSpin then
        return false
    end
    
    if #features >= 2 then
        if features[2] == 5 then
            if bonusStatus and bonusStatus == "OPEN" then
                return false
            end
        end
    end

    return true
end

function CodeGameScreenWheelOfRomanceMachine:showShop(callback)
    if self.m_bShopOpen == true then
        return
    end
    self.m_bShopOpen = true

    self.m_shopTriggerBonus = false

    gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_open_shop.mp3")

    self:clearCurMusicBg()
    self:removeSoundHandler()
    self:setMaxMusicBGVolume()
    self:resetMusicBg(nil,"WheelOfRomanceSounds/music_WheelOfRomance_shop_bgm.mp3")

    local currCallFunc = function(  )
       
        if callback then
            callback()
        end
       
    end 

    self.m_shopMainView = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopMainView",self)
    self:addChild(self.m_shopMainView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:setEnterFlag(false)
    self.m_shopMainView:runCsbAction("start",false,function(  )
        self.m_shopMainView:runCsbAction("idle",true)
        globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:setEnterFlag(true)
    end,60)
    self.m_shopMainView:setPosition(display.width/2,display.height/2)
    self.m_shopMainView:setMachine(self)
    self.m_shopMainView:setCloseShopCallFun(currCallFunc)

end


function CodeGameScreenWheelOfRomanceMachine:initGameStatusData(gameData)
    BaseSlotoManiaMachine.initGameStatusData(self,gameData)


    -- 商店数据
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata and selfdata.collect then
        local data = selfdata.collect
        globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:parseData(data)
    end

    -- PortraitWheel数据 
    if gameData and gameData.gameConfig then
        if gameData.gameConfig.extra then
            if gameData.gameConfig.extra.portraitWheel then
                self.m_portraitWheel = gameData.gameConfig.extra.portraitWheel
            end
            
        end
    end

end


----
--- 处理spin 成功消息
--
function CodeGameScreenWheelOfRomanceMachine:updateNetWorkData(  )
    BaseSlotoManiaMachine.updateNetWorkData(self )

    self:setNetMystery(true)
    self:netBackUpdateReelDatas()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata and selfdata.collect then
        local data = selfdata.collect
        globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:parseData(data)
    end

end





--[[
    **********************
    遮罩    
--]]
function  CodeGameScreenWheelOfRomanceMachine:showColorLayer(_iCol )

    self["m_colorLayer_waitNode_".._iCol]:stopAllActions()

    local layerNode = self["colorLayer_".._iCol]

    util_playFadeInAction(layerNode,0.5)
    layerNode:setVisible(true)

end

function  CodeGameScreenWheelOfRomanceMachine:hideColorLayer( _iCol )

    
    self["m_colorLayer_waitNode_".._iCol]:stopAllActions()
    local layerNode = self["colorLayer_".._iCol]

    if layerNode:isVisible() then
        util_playFadeOutAction(layerNode,0.5)
        performWithDelay(self["m_colorLayer_waitNode_".._iCol] ,function(  )
            layerNode:setVisible(false)
        end,0.5)
    end
        

end




--[[
    *********************
    处理快滚    
--]]
---
--根据关卡玩法重新设置滚动信息
function CodeGameScreenWheelOfRomanceMachine:MachineRule_ResetReelRunData()


    
    if self:checkTriggerAddWIldLongRun( ) then

        for iCol = self.LONGRUN_COL_ADD_WILD, self.m_iReelColumnNum do
            local reelRunInfo = self.m_reelRunInfo
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            

            reelRunData:setReelLongRun(true)
            reelRunData:setNextReelLongRun(true)

            local reelLongRunTime = 2.5
            if iCol > self.LONGRUN_COL_ADD_WILD then
                reelLongRunTime = 0.5
                reelRunData:setReelLongRun(false)
                reelRunData:setNextReelLongRun(false)
            end

            local iRow = columnData.p_showGridCount
            local lastColLens = reelRunInfo[1]:getReelRunLen()
            if iCol ~= 1 then
                lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                reelRunInfo[iCol - 1 ]:setNextReelLongRun(true)
            end

            local colHeight = columnData.p_slotColumnHeight
            local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

            local preRunLen = reelRunData:getReelRunLen()
            reelRunData:setReelRunLen(runLen)

        end

    end
    

    self:setLastReelSymbolList()
end

function CodeGameScreenWheelOfRomanceMachine:checkSymbolBig_H1_Full( )
    local bigH1Num = 0
    for iRow = 1 ,(self.m_iReelRowNum - 1) do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][2]
        if symbolType == self.SYMBOL_BIG_H1 then
            bigH1Num = bigH1Num + 1  
        end
    end

    if bigH1Num ==  (self.m_iReelRowNum - 1)  then
        return true
    end

    return false
end

function CodeGameScreenWheelOfRomanceMachine:checkSymbolBig_H2_Full( )
    local bigH2Num = 0
    for iRow = 1 ,(self.m_iReelRowNum - 1) do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][4]
        if symbolType == self.SYMBOL_BIG_H2 then
            bigH2Num = bigH2Num + 1  
        end
    end

    if bigH2Num ==  (self.m_iReelRowNum - 1)  then
        return true
    end

    return false
end

function CodeGameScreenWheelOfRomanceMachine:checkTriggerAddWIldLongRun( )
    local bigH1Num = 0
    for iRow = 1 ,(self.m_iReelRowNum - 1) do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][2]
        if symbolType == self.SYMBOL_BIG_H1 then
            bigH1Num = bigH1Num + 1  
        end
    end

    if bigH1Num ==  (self.m_iReelRowNum - 1)  then
        return true
    end

    return false
end


function CodeGameScreenWheelOfRomanceMachine:createReelEffect(col)
    local reelEffectName = self.m_reelEffectName
    if col == 2 or col == 4 then
        reelEffectName = "WheelOfRomance_H2_run"
    end
    local reelEffectNode, effectAct = util_csbCreate(reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self.m_slotEffectLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end


--[[
    ********************
    工具函数    
--]]
function CodeGameScreenWheelOfRomanceMachine:getBigSymbolNode(iX, iY)
    local slotNode = nil
    if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[iY] ~= nil then
        local parentData = self.m_slotParents[iY]
        local slotParent = parentData.slotParent
        local bigSymbolInfos = self.m_bigSymbolColumnInfo[iY]
        for k = 1, #bigSymbolInfos do
            local bigSymbolInfo = bigSymbolInfos[k]
            for changeIndex=1,#bigSymbolInfo.changeRows do
                if bigSymbolInfo.changeRows[changeIndex] == iX then
                    slotNode = slotParent:getChildByTag(iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                    return slotNode, bigSymbolInfo.changeRows
                end
            end
        end
    end
    return slotNode
end



--[[
    ******************************
    轮盘bonus 玩法 
--]]

function CodeGameScreenWheelOfRomanceMachine:checkAddBonusFeatures()



    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

    self.m_isRunningEffect = true
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})



end
function CodeGameScreenWheelOfRomanceMachine:checkInitSpinWithEnterLevel( )

    local selfdata = self.m_initSpinData.p_selfMakeData or {}
    local features = self.m_initSpinData.p_features
    local bonusType = selfdata.bonusType
    if bonusType == nil then
        bonusType = selfdata.awardType
    end

    
    -- 竖版滚动添加 bonus gameEffect
    if features and #features == 1 then
        if self.m_initFeatureData  then
            if self.m_initFeatureData.p_status and self.m_initFeatureData.p_status ~= "CLOSED" then
                if bonusType == "WHEEL" then
                    self:checkAddBonusFeatures()
                end
                
            end
            
        end
    else
        if self.m_initFeatureData  then
            if self.m_initFeatureData.p_status and self.m_initFeatureData.p_status == "CLOSED" then
                self.m_initFeatureData = nil
            end
            
        end
    end
    
        


    return BaseSlotoManiaMachine.checkInitSpinWithEnterLevel(self )
end



function CodeGameScreenWheelOfRomanceMachine:showBonusSymbolTrigger(_symbolType )
    local isTriggerAction = false

    for iRow  = 1, self.m_iReelRowNum, 1 do
        for iCol = 1, self.m_iReelColumnNum, 1 do
            local tarSp = self:getFixSymbol( iCol , iRow, SYMBOL_NODE_TAG)
            
            if tarSp  then
                if  tarSp.p_symbolType == self.SYMBOL_WHEEL_BONUS_LUCKY then
                    tarSp:setVisible(false)   
                    tarSp:runAnim("idleframe2")    
                    local showOrder = self:getBounsScatterDataZorder(tarSp.p_symbolType) - iRow

                    local actNode = util_spineCreate(self:getSymbolCCBNameByType(self, _symbolType),true,true) 
                    self.m_clipParent:addChild(actNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + showOrder)

                    local pos = util_getOneGameReelsTarSpPos(self,self:getPosReelIdx(iRow, iCol) )
                    actNode:setPosition(pos)
                    util_spinePlay(actNode,"actionframe")
                    util_spineEndCallFunc(actNode, "actionframe", function()
                        performWithDelay(self,function(  )

                            actNode:removeFromParent()
                            tarSp:changeCCBByName(self:getSymbolCCBNameByType(self,_symbolType),_symbolType)
                            tarSp:runAnim("idleframe")
                            tarSp:setVisible(true)  

                        end,0)
                        
                    end)

                    isTriggerAction = true

                end
                
            end
        end

       
    end 

    return isTriggerAction 
end

function CodeGameScreenWheelOfRomanceMachine:showTriggerJackBonusAni( _func)


    self:showDarkBg( )

   
    local showCircularWheelQianShou = function(  )
        
        self:resetMusicBg(nil,"WheelOfRomanceSounds/music_WheelOfRomance_CircleWheel_bgm.mp3")

        local index = math.random(1,2)
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_xaigui_".. index .. ".mp3")

        self.m_qianShouMan:setVisible(true)
        util_spinePlay(self.m_qianShouMan,"actionframe")

        self.m_qianShouGirl:setVisible(true)
        util_spinePlay(self.m_qianShouGirl,"actionframe")
    end
   
    local moveDownReel = function(  )

        self:hideDarkBg( )
        self:runCsbAction("actionframe")
        
    end

    local seeFerrisWheel = function(  )
       
        self.m_qianShouMan:setVisible(false)
        self.m_qianShouGirl:setVisible(false)

        self.m_qianShou:setVisible(true)
        self.m_qianShou:runCsbAction("actionframe")
        self:runCsbAction("actionframe3")
        
    end

    local showWheel = function(  )
        
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_cirleWheel_Down.mp3")

        self.m_gameBg:runCsbAction("actionframe")
        
        self.m_qianShou:runCsbAction("over",false,function(  )
            self.m_qianShou:setVisible(false)
        end,60)
        self:runCsbAction("Wheelshow")
        
    end


    local triggerAniTime = 0
    local triggerAni =  self:showBonusSymbolTrigger(self.SYMBOL_WHEEL_BONUS_GRAND )
    if triggerAni then

        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_grandWheel_Trigger.mp3")

        triggerAniTime = 90 / 30
    end

    performWithDelay(self,function(  )

        self.m_gameBgYanHua:runCsbAction("yanhua2",true)

        showCircularWheelQianShou()

        performWithDelay(self,function(  )

            moveDownReel()

            performWithDelay(self,function(  )

                seeFerrisWheel()

                performWithDelay(self,function(  )
                    
                    showWheel()
    
                    if _func then
                        _func()
                    end
                        

                end,180/60)
                
            end,90/60)
            
        end,2)

    end, triggerAniTime)
end

function CodeGameScreenWheelOfRomanceMachine:showTriggerWheelBonusAni( _func)


    self:showDarkBg( )

    
    local showPortraitWheelQianShou = function(  )

        local index = math.random(1,2)
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_xaigui_".. index .. ".mp3")


        self:resetMusicBg(nil,"WheelOfRomanceSounds/music_WheelOfRomance_PortraitWheel_bgm.mp3")
        self.m_qianShouMan:setVisible(true)
        util_spinePlay(self.m_qianShouMan,"actionframe")

        self.m_qianShouGirl:setVisible(true)
        util_spinePlay(self.m_qianShouGirl,"actionframe")
    end
   
    local moveDownReel = function(  )

        self:runCsbAction("actionframe")
        
    end

    local seePortraitWheel = function(  )

        self.m_qianShouMan:setVisible(false)
        self.m_qianShouGirl:setVisible(false)

        self.m_qianShou:setVisible(true)
        self.m_qianShou:runCsbAction("actionframe")

        self:runCsbAction("actionframe1")
        
        self.m_GuoChangDarkBG:setVisible(true)
        self.m_GuoChangDarkBG:runCsbAction("idle")


        self.m_darkBG:setVisible(false)

    end

    local hideQianShou = function(  )
        

        self.m_qianShou:runCsbAction("over",false,function(  )
            self.m_qianShou:setVisible(false)
        end,60)

        
    end


   

    local triggerAniTime = 0
    local triggerAni =  self:showBonusSymbolTrigger(self.SYMBOL_WHEEL_BONUS_LUCKY )
    if triggerAni then

        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_luckyWheel_Trigger.mp3")

        triggerAniTime = 90 / 30
    end
    
    performWithDelay(self,function(  )

        self.m_gameBgYanHua:runCsbAction("yanhua2",true)

        showPortraitWheelQianShou()

        performWithDelay(self,function(  )

            moveDownReel()

            performWithDelay(self,function(  )

                seePortraitWheel()

                performWithDelay(self,function(  )

                    

                    self:showGuoChang( )  
                    
                    performWithDelay(self,function(  )

                        if _func then
                            _func()
                        end
        
                        performWithDelay(self,function(  )
                        
                            hideQianShou()

                            
        
                        end,60/60)
                    end,30/60)

                end,100/60)
                
            end,90/60)
            
        end,2)

    end, triggerAniTime)
end

function CodeGameScreenWheelOfRomanceMachine:showPortraitWheelToCircularWheelAni( _func)

    self.m_gameBgYanHua:runCsbAction("yanhua2",true)

    local seeFerrisWheel = function(  )


        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_SmallToBig_Wheel.mp3")


        self:resetMusicBg(nil,"WheelOfRomanceSounds/music_WheelOfRomance_CircleWheel_bgm.mp3")
        
        self.m_qianShouMan:setVisible(false)
        self.m_qianShouGirl:setVisible(false)

        self.m_qianShou:setVisible(true)
        self.m_qianShou:runCsbAction("actionframe")
        self:runCsbAction("actionframe2")
        
    end

    local showWheel = function(  )
        
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_cirleWheel_Down.mp3")
        
        self.m_gameBg:runCsbAction("actionframe")
        
        self.m_qianShou:runCsbAction("over",false,function(  )
            self.m_qianShou:setVisible(false)
        end,60)
        self:runCsbAction("Wheelshow")
        
    end

    seeFerrisWheel()

    performWithDelay(self,function(  )
        
        

        showWheel()

        if _func then
            _func()
        end
            

    end,80/60)
        
end

function CodeGameScreenWheelOfRomanceMachine:showOverWheelBonusAni( _func)
    
    gLobalSoundManager:playSound("WheelOfRomanceSounds/music_WheelOfRomance_baseReel_MoveUp.mp3")

    self.m_gameBg:runCsbAction("normal",false,function(  )
        self.m_gameBgYanHua:runCsbAction("yanhua1",true)
    end,60)
    self:runCsbAction("over1")
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        if _func then
            _func()
        end
        waitNode:removeFromParent()
    end,60/60)

end

function CodeGameScreenWheelOfRomanceMachine:showOverJackBonusAni( _func)
    
    gLobalSoundManager:playSound("WheelOfRomanceSounds/music_WheelOfRomance_baseReel_MoveUp.mp3")
    
    self.m_gameBg:runCsbAction("over",false,function(  )
        self.m_gameBgYanHua:runCsbAction("yanhua1",true)
    end,60)
    self:runCsbAction("over")

    performWithDelay(self,function(  )
        if _func then
            _func()
        end
    end,60/60)

end

function CodeGameScreenWheelOfRomanceMachine:showEffect_Bonus( effectData )
    local time = 0

    local winLines = self.m_reelResultLines
    if winLines and #winLines > 0 then
        time = self.m_changeLineFrameTime
    end
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local awardType = selfdata.awardType
    if awardType then
        time = 0
    end

    performWithDelay(self,function(  )
        -- 取消掉赢钱线的显示
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, false)
        self:clearWinLineEffect()
        BaseSlotoManiaMachine.showEffect_Bonus(self,effectData)
    end,time)

    return true
end

function CodeGameScreenWheelOfRomanceMachine:showCircularWheel( _func )

    local linebet =  self:getNetLineBet( )
    self.m_circularWheelJackpotBar:updateLinebet(linebet )
    
    self.m_circularWheelView:resetView()
    self.m_circularWheelView:findChild("click"):setVisible(false)
    self.m_circularWheelView:setVisible(true)
    self.m_circularWheelView:runCsbAction("show",false,function(  )
        self.m_circularWheelView:runCsbAction("idleframe",true)
        self.m_circularWheelView:findChild("click"):setVisible(true)
    end,60)
    self.m_circularWheelView:setWheelEndCall(function(  )

        self:showOverJackBonusAni( function(  )

            if _func then
                _func()
            end


        end)

    end )
end



function CodeGameScreenWheelOfRomanceMachine:showBonusGameView(effectData)

    self.m_shopIcon_Tip:setVisible(false)
    self.m_shopIcon_Tip_bg:setVisible(false)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusType = selfdata.bonusType 
    local awardType = selfdata.awardType
    if bonusType == nil then
        bonusType = awardType
    end
    
    if awardType then
        self.m_bottomUI:showAverageBet()
    end

    local wheelResult = selfdata.wheelResult or {}
    local number = wheelResult.number  -- 当前显示的轮子

    -- 触发是 服务器不传位置（number）默认为1
    -- 后续断线触发应该把服务器给的位置加一才是下次应该转的位置
    
    if number then
        local wheelData = wheelResult.wheel 
        local endIndex = wheelResult.index or 0 -- 返回数据的位置
        local endValue = endIndex + 1
        local wheelIndexData = wheelData[endValue]
        local _,moveStates = self.m_portraitWheelView:getAnlysisWheelNetData( wheelIndexData)
        number =  number + self.m_portraitWheelView:getMovePosDeviation(moveStates )
        

    else

        number = 1
    end


    -- 判断是否是 竖版滚轮最后一次结束触发了jackpot
    if number == self.m_portraitWheelView.JACKPOT_WHEEL_NUM then
        bonusType = self.BONUS_TYPE_JACKPOT
    end

    if bonusType then

        if bonusType == self.BONUS_TYPE_JACKPOT then

            local features = self.m_runSpinResultData.p_features or {}
            local beginCoins = self.m_runSpinResultData.p_bonusWinCoins or 0 
          
            if beginCoins > 0 then
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(beginCoins))
            else
                self.m_bottomUI:updateWinCount("")
            end

            
            
            self:showTriggerJackBonusAni( function(  )

                self.m_circularWheelView.m_triggerCoins = beginCoins

                self:showCircularWheel( function(  )


                    self.m_runSpinResultData.p_bonusWinCoins = nil
                    self.m_runSpinResultData.p_bonusStatus = nil
                    self.m_runSpinResultData.p_bonusExtra = nil

                    self.m_bottomUI:hideAverageBet()

                    self:resetMusicBg(true)
                    
                    effectData.p_isPlay = true
                    self:playGameEffect()

                end )
                
            end)

            
        elseif bonusType == self.BONUS_TYPE_WHEEL then
            
            self:showTriggerWheelBonusAni( function(  )

                self.m_portraitWheelView:updatePointPos( number  )

                local features = self.m_runSpinResultData.p_features or {}
                local beginCoins = self.m_runSpinResultData.p_bonusWinCoins or 0 
                self.m_portraitWheelView.m_oldBsWinCoins = beginCoins
                if beginCoins > 0 then
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(beginCoins))
                else
                    self.m_bottomUI:updateWinCount("")
                end
                
                gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_portraitWheel_Enter.mp3")

                self.m_portraitWheelView:restFeatureMainView( )
                self.m_portraitWheelView:setVisible(true)
                self.m_portraitWheelView:runCsbAction("show",false,function(  )
                    performWithDelay(self,function(  )
                        self.m_portraitWheelView:beginOneWheelRun( number )
                    end,2)
                   
                end,60)
                self.m_portraitWheelView:setWheelEndCall(function(  )

                    self:clearCurMusicBg()

                    local winCoins = self.m_runSpinResultData.p_bonusWinCoins or 0
                    -- 说明玩过竖版的滚轮玩法
                    self:showBonusOver(util_formatCoins(winCoins,50) ,function(  )

                        -- 更新游戏内每日任务进度条
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                        -- 通知bonus 结束， 以及赢钱多少
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{winCoins, GameEffect.EFFECT_BONUS})

                        local lastWinCoin = globalData.slotRunData.lastWinCoin
                        globalData.slotRunData.lastWinCoin = 0
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{winCoins,true,false})
                        globalData.slotRunData.lastWinCoin = lastWinCoin 

                        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(winCoins))

                        self:showOverWheelBonusAni( function(  )

                            self.m_runSpinResultData.p_bonusWinCoins = nil
                            self.m_runSpinResultData.p_bonusStatus = nil
                            self.m_runSpinResultData.p_bonusExtra = nil

                            self.m_bottomUI:hideAverageBet()

                            self:resetMusicBg(true)

                            effectData.p_isPlay = true
                            self:playGameEffect()
    
                            
                        end)

                    end)

                end, function(  )
                    
                   

                    -- 由竖版滚轮切换到大圆盘
                    self:showPortraitWheelToCircularWheelAni( function(  )
                        
                        local features = self.m_runSpinResultData.p_features or {}
                        local beginCoins = self.m_runSpinResultData.p_bonusWinCoins or 0 
                      
                        if beginCoins > 0 then
                            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(beginCoins))
                        else
                            self.m_bottomUI:updateWinCount("")
                        end
            
                        self.m_circularWheelView.m_triggerCoins = beginCoins

                        self:showCircularWheel( function(  )

                            self.m_runSpinResultData.p_bonusWinCoins = nil
                            self.m_runSpinResultData.p_bonusStatus = nil
                            self.m_runSpinResultData.p_bonusExtra = nil

                            self.m_bottomUI:hideAverageBet()

                            self:resetMusicBg(true)

                            effectData.p_isPlay = true
                            self:playGameEffect()

                        end )
                        
                    end)


                end)
                   

            end)


        end
    end

  
end

function CodeGameScreenWheelOfRomanceMachine:showShopLevelUpView(func)
    

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local levelUpCoins = selfdata.levelUpCoins

    local ownerlist={}
    ownerlist["m_lb_coins"]= util_formatCoins(levelUpCoins,50) 
    local view =  self:showDialog("ShopLevelUp",ownerlist,func)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},741)

    return view

end

function CodeGameScreenWheelOfRomanceMachine:showGrandBonusOver(_luckCoins,_jpCoins,_jpIndex,func)
    
    local grandIndex = 1
    local majorIndex = 2
    local minorIndex = 3
    local miniIndex = 4


    gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_portrairWheel_OverView.mp3")

    local ownerlist={}
    ownerlist["m_lb_coins_1"]=  util_formatCoins(_luckCoins,50) 
    ownerlist["m_lb_coins_2"]= util_formatCoins(_jpCoins,50)  
    ownerlist["m_lb_coins_3"]= util_formatCoins(_jpCoins + _luckCoins,50)   
    local view =  self:showDialog("BonusGameOver2",ownerlist,func)

    local grandImg = view:findChild("Grand")
    local majorImg = view:findChild("Major")
    local minorImg = view:findChild("Minor")
    local miniImg = view:findChild("Mini")

    if grandImg then
        grandImg:setVisible(false)
    end
    if majorImg then
        majorImg:setVisible(false)
    end
    if minorImg then
        minorImg:setVisible(false)
    end
    if miniImg then
        miniImg:setVisible(false)
    end
    

    if _jpIndex ==  grandIndex then
        if grandImg then
            grandImg:setVisible(true)
        end
    elseif _jpIndex ==  majorIndex then
        if majorImg then
            majorImg:setVisible(true)
        end
    elseif _jpIndex ==  minorIndex then
        if minorImg then
            minorImg:setVisible(true)
        end
    elseif _jpIndex ==  miniIndex then
        if miniImg then
            miniImg:setVisible(true)
        end
    end

    local node_1 = view:findChild("m_lb_coins_1")
    view:updateLabelSize({label=node_1,sx=0.53,sy=0.53},741)

    local node_2 = view:findChild("m_lb_coins_2")
    view:updateLabelSize({label=node_2,sx=0.53,sy=0.53},741)

    local node_3 = view:findChild("m_lb_coins_3")
    view:updateLabelSize({label=node_3,sx=0.53,sy=0.53},741)

    return view

end

function CodeGameScreenWheelOfRomanceMachine:showBonusOver(coins,func)
    
    gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_portrairWheel_OverView.mp3")

    local ownerlist={}
    ownerlist["m_lb_coins"]= coins
    local view =  self:showDialog("BonusGameOver",ownerlist,func)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},741)

    return view

end

function CodeGameScreenWheelOfRomanceMachine:showJackpotWinView(index,coins,func)
    


    local jackPotWinView = util_createView("CodeWheelOfRomanceSrc.WheelOfRomanceJackPotWinView", self)
    gLobalViewManager:showUI(jackPotWinView)

    jackPotWinView:findChild("root"):setScale(self.m_machineRootScale) 

    local curCallFunc = function(  )
        if func then
            func()
        end
    end
    jackPotWinView:initViewData(index,coins,curCallFunc)


end

function CodeGameScreenWheelOfRomanceMachine:getClickPageCellStatus( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local levelUpCoins = selfdata.levelUpCoins
    local awardType = selfdata.awardType or ""
    local winCoins = selfdata.winCoins or 0

    if awardType == self.BONUS_TYPE_JACKPOT then
        return globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_CIRCULAR_WHEEL
    elseif awardType == self.BONUS_TYPE_WHEEL then
        return globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_PORTRAIT_WHEEL
    elseif awardType == self.SHOP_TYPE_COINS then
        return tostring(winCoins) 
    end

end

function CodeGameScreenWheelOfRomanceMachine:checkAddShopFeatures(_func,_func2 )
    
    local features = self.m_runSpinResultData.p_features or {}
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local awardType = selfdata.awardType

    local isAdd = false

    if awardType and (awardType == self.BONUS_TYPE_JACKPOT or awardType == self.BONUS_TYPE_WHEEL) then
        self:checkAddBonusFeatures()
        
        isAdd = true
    end

    
    return isAdd
end


-- 新版假滚

function CodeGameScreenWheelOfRomanceMachine:setNetMystery(_isNetBack)

    self.m_runDataWaitNode:stopAllActions()

    local waitTime = 0
    if _isNetBack then
        waitTime = 0.5
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local mystery = selfdata.mysteryReplaceSignal or 0

    performWithDelay(self.m_runDataWaitNode,function(  )
        self.m_configData:setMysterSymbol(mystery)
    end,waitTime)
    
end

function CodeGameScreenWheelOfRomanceMachine:netBackUpdateReelDatas( )

    local slotsParents = self.m_slotParents

    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local reelDatas = self:checkUpdateReelDatas(parentData)

    end
end

function CodeGameScreenWheelOfRomanceMachine:getNetLineBet( )
      
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bets = selfdata.bets or globalData.slotRunData:getCurTotalBet()

    local awardType = selfdata.awardType 
    if awardType then
        if awardType == "WHEEL" then
            bets  = bets * 50
        else
            print("直接商店触发圆盘玩法使用平均bet")
        end
    else
        bets = globalData.slotRunData:getCurTotalBet()
    end
    

    return  bets

end

return CodeGameScreenWheelOfRomanceMachine






