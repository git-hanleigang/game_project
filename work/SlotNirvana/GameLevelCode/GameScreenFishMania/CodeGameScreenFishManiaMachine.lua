---
-- island li
-- 2019年1月26日
-- CodeGameScreenFishManiaMachine.lua
-- 
-- 玩法：
-- 

local FishManiaPlayConfig   = require "FishManiaPlayConfig"
local FishManiaShopData     = require "CodeFishManiaSrc.ShopListView.FishManiaShopData"

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseNewReelMachine    = require "Levels.BaseNewReelMachine"
local GameEffectData        = require "data.slotsdata.GameEffectData"
local CodeGameScreenFishManiaMachine = class("CodeGameScreenFishManiaMachine", BaseNewReelMachine)

CodeGameScreenFishManiaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画


CodeGameScreenFishManiaMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenFishManiaMachine.SYMBOL_SCORE_WILD_SCATTER = 100    --两个乘倍wild之间信号转换为普通wild时，如果转换之前信号为scatter 则转换为 wild_scatter
CodeGameScreenFishManiaMachine.SYMBOL_SCORE_WILD_MULT = 96
CodeGameScreenFishManiaMachine.SYMBOL_SCORE_WILD_3 = 95
CodeGameScreenFishManiaMachine.SYMBOL_SCORE_WILD_2 = 94
CodeGameScreenFishManiaMachine.SYMBOL_SCORE_WILD_1 = 93

CodeGameScreenFishManiaMachine.SYMBOL_SCORE_SUPERFREE_WILD_1 = 101 --superFree模式下 H级图标 变换的wild
CodeGameScreenFishManiaMachine.SYMBOL_SCORE_SUPERFREE_WILD_2 = 102
CodeGameScreenFishManiaMachine.SYMBOL_SCORE_SUPERFREE_WILD_3 = 103

CodeGameScreenFishManiaMachine.EFFECT_COLLECT_ICON              = GameEffect.EFFECT_SELF_EFFECT - 90 
CodeGameScreenFishManiaMachine.EFFECT_SHOWWILD_LOCK             = GameEffect.EFFECT_SELF_EFFECT - 80 
CodeGameScreenFishManiaMachine.EFFECT_SHOWWILD_COlLOCK          = GameEffect.EFFECT_SELF_EFFECT - 75  --base模式下两个红色wild之间的信号转换为wild

CodeGameScreenFishManiaMachine.EFFECT_NORMALFREE_SHOWLOCKWILD   = GameEffect.EFFECT_SELF_EFFECT - 70  --free模式滚出锁定wild
CodeGameScreenFishManiaMachine.EFFECT_NORMALFREE_LOCKWILDANIM   = GameEffect.EFFECT_SELF_EFFECT - 60  --free模式滚出锁定wild播放锁定动画

CodeGameScreenFishManiaMachine.EFFECT_SHOP_GUIDE                = GameEffect.EFFECT_SELF_EFFECT - 85  --商店购买引导 

CodeGameScreenFishManiaMachine.p_isInitIcon = false
CodeGameScreenFishManiaMachine.m_playFreeLockWildFlag = false
CodeGameScreenFishManiaMachine.m_newFreeLockWild = {}

--每个bet对应的锁定wild的位置和倍数
CodeGameScreenFishManiaMachine.m_lockWildBet = {}
CodeGameScreenFishManiaMachine.m_curTotalBet = 0
--当前展示的提示商店点索引
CodeGameScreenFishManiaMachine.m_curTipShopIndex = 0
--背景移动时间
CodeGameScreenFishManiaMachine.m_moveBgTime = 0.5
--是否可以点击
CodeGameScreenFishManiaMachine.m_isClick = true
-- superFree 结束有大赢 需要引导拍照
CodeGameScreenFishManiaMachine.m_superfreeBigWinPaiZhao = false

-- 构造函数
function CodeGameScreenFishManiaMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.p_isInitIcon = false
    globalMachineController.p_fishManiaPlayConfig   = FishManiaPlayConfig
    globalMachineController.p_fishManiaShopData     = FishManiaShopData.new()
    globalMachineController.p_fishManiaShopData:initCommodityCash()

    self.m_shopIndex = 1

    self.m_bonusOverView = nil
    self.m_bonusViewData = {}

    self.m_shopGuideFlage = false    --引导标记，是否在free结束后开启引导
    --init
    self:initGame()
end

function CodeGameScreenFishManiaMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

    globalMachineController.p_LogFishManiaShop = require("CodeFishManiaSrc.LogFishManiaShop"):create()
    globalMachineController.p_LogFishManiaShop.m_modeName = self.m_moduleName

end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFishManiaMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FishMania"  
end

function CodeGameScreenFishManiaMachine:initUI()


    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_baseFreeSpinBar = util_createView("CodeFishManiaSrc.FishManiaFreespinBarView",{"FishMania_FreeSpinNum.csb"})
    self:findChild("FreeSpinNum"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
    
    self.m_superFreeSpinBar = util_createView("CodeFishManiaSrc.FishManiaFreespinBarView",{"FishMania_superFreeSpinNum.csb"})
    self:findChild("FreeSpinNum"):addChild(self.m_superFreeSpinBar)
    self.m_superFreeSpinBar:setVisible(false)

    self.m_shopBar = util_createView("CodeFishManiaSrc.ShopBar.FishManiaShopBar")
    self:findChild("progress"):addChild(self.m_shopBar)
    --free模式的过场 包含四条鱼
    self.m_freeGuochang = util_createAnimation("FishMania_free_guochang.csb") 
    self:findChild("guochangNode"):addChild(self.m_freeGuochang)
    self.m_freeGuochang:setScale(1/self.m_machineRootScale)
    self.m_freeGuochang:setVisible(false)
    self.m_freeGuochang_fish = {}
    local fishSpineDir = {
        [6] = -1,
        [7] = 1,
        [8] = -1,
        [9] = 1,
    }
    for _spineIndex,_dir in pairs(fishSpineDir) do
        local spineFish = util_spineCreate(string.format("Socre_FishMania_%d", _spineIndex), true, true)
        table.insert(self.m_freeGuochang_fish, spineFish)
        spineFish:setVisible(false)
        self.m_freeGuochang:addChild(spineFish)
        spineFish:setScaleX(_dir)
    end
    --鱼缸，装饰品图层, 提示
    self.m_fishBoxItems = {}
    self.m_fishToyViews = {}
    self.m_fishBoxTips = {}
    for i=1,4 do
        local fishBoxItem = util_createView("CodeFishManiaSrc.FishBoxItem.FishManiaFishBoxItemView", i)
        local fishBoxParent = self:findChild(string.format("LittleLogo_%d", i))
        fishBoxParent:addChild(fishBoxItem)
        table.insert(self.m_fishBoxItems, fishBoxItem)

            local fishBoxTip  = util_createAnimation(string.format("FishMania_LittleLogo_%d_tip.csb", i))
            local tipNode = fishBoxItem:findChild("tip")
            local tipWorldPos = tipNode:getParent():convertToWorldSpace(cc.p(tipNode:getPosition()))
            fishBoxTip:setPosition(fishBoxParent:convertToNodeSpace(tipWorldPos))
            fishBoxParent:addChild(fishBoxTip)
            fishBoxTip:setVisible(false)
            table.insert(self.m_fishBoxTips, fishBoxTip)

        local fishToy = util_createView("CodeFishManiaSrc.ShopFishToy.FishManiaFishToyView",i,self)
        self:findChild("fishTank"):addChild(fishToy)
        fishToy:setVisible(false)
        fishToy:setPosition(0,0)
        table.insert(self.m_fishToyViews, fishToy)
    end
    --购买引导遮罩
    self.m_guideMask = self:findChild("guideMask")
    self.m_guideMask:setVisible(false)
    if self.m_machineRootScale < 1 then
        self.m_guideMask:setScale(1/self.m_machineRootScale)
    end
    
    -- superFree下的 背景和角色
    self.m_superFreeEffect = util_createAnimation("FishMania_superfree_effect.csb")
    self:findChild("superFreeJuese"):addChild(self.m_superFreeEffect)
    self.m_superFreeJuese = util_spineCreate(string.format("FishMania_fgjuese"), true, true)
    self:findChild("superFreeJuese"):addChild(self.m_superFreeJuese)
    self.m_superFreeEffect:setVisible(false)
    self.m_superFreeJuese:setVisible(false)
    --循环播放标记
    self.m_superFreePlayFlag = false
    

    --点击事件
    self:addClick(self:findChild("fishTankClick"))

    --滑动背景
    local gameBgParent = self:findChild("gameBg")
    self.m_otherGameBg = util_createAnimation("FishMania/GameScreenFishManiaBg.csb")
    gameBgParent:addChild(self.m_otherGameBg, 100)
    self.m_otherGameBg:setVisible(false)

    -- self.m_gameBg:setScale(self.m_machineRootScale)
    -- self.m_otherGameBg:setScale(self.m_machineRootScale)

    --背景idle
    self.m_gameBg:runCsbAction("base", true)
    self.m_otherGameBg:runCsbAction("base", true)

    -- 分享按钮
    self.m_shareBtn = util_createAnimation("FishMania_Share_Camera.csb")
    self:findChild("Camera"):addChild(self.m_shareBtn)
    self:addClick(self.m_shareBtn:findChild("Panel_click"))
    self.m_shareBtn:runCsbAction("idle",false)

    --提醒
    self.m_shareBtnTips = util_createAnimation("FishMania_Share_Tips.csb") 
    self.m_shareBtn:findChild("Node_Tips"):addChild(self.m_shareBtnTips)
    self.m_shareBtnTips:setVisible(false)

    --拍摄快门特效
    self.m_paisheEffect = util_createAnimation("FishMania_Share_Camera_paishe.csb") 
    self:findChild("guochangNode"):addChild(self.m_paisheEffect)
    self.m_paisheEffect:setScale(1/self.m_machineRootScale)
    self.m_paisheEffect:setVisible(false)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            --如果是free最后一次 则不返回,其余情况返回
            if not self.m_bProduceSlots_InFreeSpin or 0 ~= globalData.slotRunData.freeSpinCount then
                return
            end
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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundPrefix = ""
        --区分 superFree, free, base
        if self.m_bProduceSlots_InFreeSpin then
            if self.m_bInSuperFreeSpin then
                soundPrefix = "FishManiaSounds/FishMania_superFree_winCoin%d.mp3"
            else
                soundPrefix = "FishManiaSounds/FishMania_free_winCoin%d.mp3"
            end
        else
            soundPrefix = "FishManiaSounds/FishMania_base_winCoin%d.mp3"
        end
    
        local soundName = string.format(soundPrefix, soundIndex)
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        -- self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenFishManiaMachine:enterGamePlayMusic(  )
    self.m_FishManiaPlayEnterMusic = true
    self:playEnterGameSound( "FishManiaSounds/FishMania_enterLevel.mp3" )
    self:levelPerformWithDelay(4, function()
        self.m_FishManiaPlayEnterMusic = false
    end)
end

function CodeGameScreenFishManiaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self:addObservers()
    
    self:fishToyView_initFishToys()

    self.m_shopListView = util_createView("CodeFishManiaSrc.ShopListView.FishManiaShopListView",self)
    self:findChild("shopNode"):addChild(self.m_shopListView)
    self.m_shopListView:setVisible(false)
    self.m_shopListView:setPageIndex(self.m_shopListView.m_currPageIdex, false)

    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    
    --==进入关卡时 取服务器数据刷新一些控件展示
    
    local pickScore = globalMachineController.p_fishManiaShopData:getPickScore()
    self:shopBar_updateCoins(pickScore)
    self:shopBar_upDateShopBuyState()

    self:fishBox_upDateSelectState()
    for _shopIndex,_fishBox in ipairs(self.m_fishBoxItems) do
        _fishBox:upDateState()
    end
    self:openSelectShopView()
    

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local triggerSuperFree = true==self.m_bInSuperFreeSpin
    self.m_curTotalBet = globalData.slotRunData:getCurTotalBet()  

    if not triggerSuperFree then
        self:upDateReelLockWild(self.m_curTotalBet)
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then

    else
        if triggerSuperFree then
        else
            self:freeTriggerChangeWildLock()
        end
    end
    --商店购买引导
    -- self:shopBar_playFingerTipAnim()
    if self:isTriggerShopGuide(false) then
        if not self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) then
            --spin按钮
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
            self:playShopGuide(function() 
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,true})
            end)
        end
    end
    --==
    

    
end

function CodeGameScreenFishManiaMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    local p_fishManiaCfg = globalMachineController.p_fishManiaPlayConfig
    -- 商店翻页/点击鱼缸  
    gLobalNoticManager:addObserver(self,
        function(self,params)  
            self:stopSlideSwitchShopBg()

            local currPageIndex = params[1]
            self.m_shopIndex = currPageIndex
            self.m_shopListView.m_currPageIdex = currPageIndex
            self:updateGameBgForIndex(currPageIndex)
            self:hideAllFishToyView( )
            self:updateFishToyForIndex(currPageIndex)

            local shopIndex = globalMachineController.p_fishManiaShopData:getShowIndex()
            if self.m_shopIndex <= shopIndex then
                self:showShareBtn()
            else
                self.m_shareBtn:setVisible(false)
            end

        end,
        p_fishManiaCfg.EventName.UPDATE_MACHINE_FISH_TANK)
    --积分变更
    gLobalNoticManager:addObserver(self,function(self,params)
        self:noticCallBack_changePickScore(params)
    end,p_fishManiaCfg.EventName.PICKSCORE_CHANGE)
    --bet数值切换
    gLobalNoticManager:addObserver(self,function(self,params)
        self:noticCallBack_changeTotalBet(params)
    end,ViewEventType.NOTIFY_BET_CHANGE)
    --鱼缸点击
    gLobalNoticManager:addObserver(self,function(self,params)
        self:noticCallBack_fishBoxItemClick(params)
    end,p_fishManiaCfg.EventName.FISHBOX_CLICK)
end

function CodeGameScreenFishManiaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    
    self:clearBgMoveHandler()
    self.m_superFreePlayFlag = false

    scheduler.unschedulesByTargetName(self:getModuleName())

    globalMachineController.p_fishManiaPlayConfig   = nil
    globalMachineController.p_fishManiaShopData     = nil
    globalMachineController.p_LogFishManiaShop      = nil
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFishManiaMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_10  then
        return "Socre_FishMania_10"
    elseif symbolType == self.SYMBOL_SCORE_WILD_SCATTER  then  
        return "Socre_FishMania_Wild_Scatter"
    elseif symbolType == self.SYMBOL_SCORE_WILD_MULT  then
        return "Socre_FishMania_Wild_Mult"
    elseif symbolType == self.SYMBOL_SCORE_WILD_3 or 
            symbolType == self.SYMBOL_SCORE_WILD_2 or
            symbolType == self.SYMBOL_SCORE_WILD_1  then

        return "Socre_FishMania_Wild_X1"
        
    elseif symbolType == self.SYMBOL_SCORE_SUPERFREE_WILD_1  then
        return "Socre_FishMania_9"
    elseif symbolType == self.SYMBOL_SCORE_SUPERFREE_WILD_2  then
        return "Socre_FishMania_8"
    elseif symbolType == self.SYMBOL_SCORE_SUPERFREE_WILD_3  then
        return "Socre_FishMania_7"
    end
    
    
    return nil
end

--点击回调
function CodeGameScreenFishManiaMachine:clickEndFunc(sender)
    local name = sender:getName()

    if name == "fishTankClick" then

        --切换设置按钮的展示
        self:setLayer_switchSetLayerShow(self.m_shopIndex)
        self:onFishTankClick(sender)
    elseif name == "Panel_click" then
        --不可连续点击
        if not self.m_isClick then
            return
        end
        if self.m_shareBtnTips:isVisible() then
            self:showTipsOverView()
        end

        --关闭装饰品设置弹板
        self:setLayer_switchSetLayerShow(self.m_shopIndex)

        self.m_isClick = false
        self.m_paisheEffect:setVisible(true)
        gLobalSoundManager:playSound("FishManiaSounds/FishMania_share_paizhao.mp3")
        self:showShareZheZhao()
        self.m_paisheEffect:runCsbAction("actionframe",false,function()
            self:screenShotFishToy()
        end)
        
    end
end
----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenFishManiaMachine:MachineRule_initGame(  )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        self.m_bInSuperFreeSpin = selfData.triggerSuperFree

        --不是进入fs时 切背景
        if self.m_runSpinResultData.p_freeSpinsLeftCount ~= self.m_runSpinResultData.p_freeSpinsTotalCount then
            self:enterFreeSpinChangeShow()

            if self.m_bInSuperFreeSpin then
                self.m_bottomUI:showAverageBet()
                --superFree的背景角色动效
                self:showSuperFreeBgEffect()
                -- self:showSuperFreeJuese()
            end
        end

    end
    
end

--
--单列滚动停止回调
--
function CodeGameScreenFishManiaMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFishManiaMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFishManiaMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
---
-- 显示free spin
function CodeGameScreenFishManiaMachine:showEffect_FreeSpin(effectData)

    self.m_beInSpecialGameTrigger = true
    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            --!!!插入修改
            scatterLineValue.iLineSymbolNum = #scatterLineValue.vecValidMatrixSymPos
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
            self:showFreeSpinView(effectData)
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end
---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenFishManiaMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode==nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and
            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do

                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end

            end
        end

        if slotNode ~= nil then--这里有空的没有管
            --!!!有种特殊的 wild_scatter 触发动画是 actionframe2,因为之后这个信号都不参与连线了，所以直接修改连线动画即可
            if self.SYMBOL_SCORE_WILD_SCATTER == slotNode.p_symbolType then
                slotNode:setLineAnimName("actionframe2")
            end
            
            slotNode = self:setSlotNodeEffectParent(slotNode)
            animTime = util_max(animTime, slotNode:getAniamDurationByName( slotNode:getLineAnimName() ) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end
-- FreeSpinstart
function CodeGameScreenFishManiaMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("FishManiaSounds/music_FishMania_custom_enter_fs.mp3")

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local triggerSuperFree = true==self.m_bInSuperFreeSpin

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local count = self.m_runSpinResultData.p_freeSpinsTotalCount
            
            if triggerSuperFree then
                self:showSuperFreeSpinStart(function()

                    self:playFreeSpinGuoChang(function()
                        -- self:showSuperFreeJuese()

                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
           
                    self:levelPerformWithDelay(110/60, function()
                        --进入Free模式修改界面展示
                        local triggerSuperFree = true==self.m_bInSuperFreeSpin
                        self:enterFreeSpinChangeShow(triggerSuperFree)
                        --清理赢钱线
                        self.m_bottomUI:checkClearWinLabel()
                        --平均bet值 展示
                        self.m_bottomUI:showAverageBet()
                        --superFree的背景动效
                        self:showSuperFreeBgEffect()

                        self:superFreeTriggerChangeWildLock()

                        --商店列表打开状态先关闭
                        if self.m_shopListView.m_closeOrOpen then
                            self.m_shopListView:HideShopListView()
                        end
                    end)       
                end)
            else
                gLobalSoundManager:playSound("FishManiaSounds/FishMania_free_start.mp3")
                self:showFreeSpinStart(count,function()

                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()       
                end)
            end

        end
    end


    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        showFSView()  
    --  过场动画 
    else
        --普通
        if not triggerSuperFree then
            self:playFreeSpinGuoChang(function()
                showFSView()   
            end)
           
            self:levelPerformWithDelay(110/60, function()
                --进入Free模式修改界面展示
                local triggerSuperFree = true==self.m_bInSuperFreeSpin
                self:enterFreeSpinChangeShow(triggerSuperFree)

                self:freeTriggerChangeWildLock()
                
                --商店列表打开状态先关闭
                if self.m_shopListView.m_closeOrOpen then
                    self.m_shopListView:HideShopListView()
                end
            end)

        --super
        else
            showFSView()
        end
    end
end
--free过场
function CodeGameScreenFishManiaMachine:playFreeSpinGuoChang(_fun)
    --4 选 3
    local indexTab  = {1,2,3,4}
    local resultTab = {}
    while #resultTab < 3 and #indexTab > 0 do
        local fishIndex = table.remove(indexTab, math.random(1, #indexTab))
        table.insert(resultTab, fishIndex)
        
        local spineFish = self.m_freeGuochang_fish[fishIndex]
        local posNode = self.m_freeGuochang:findChild(string.format("Node_fish%d", #resultTab)) 
        if spineFish and posNode then
            util_changeNodeParent(posNode, spineFish)
            spineFish:setPosition(0, 0)
            util_spinePlay(spineFish, "actionframe0", true)
            spineFish:setVisible(true)
        end
    end
    

    self.m_freeGuochang:setVisible(true)
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_free_guochang.mp3")
    self.m_freeGuochang:runCsbAction("actionframe", false, function()
        if _fun then
            _fun()
        end

        for i,v in ipairs(self.m_freeGuochang_fish) do
            v:setVisible(false)
        end
        self.m_freeGuochang:setVisible(false)
    end)
end
function CodeGameScreenFishManiaMachine:enterFreeSpinChangeShow()
    self:showFreeSpinBar()
    self:freeBar_changeFreeSpinByCount()
    --滚轮背景
    self:findChild("reel_fs"):setVisible(true)
    --鱼缸
    for _shopIndex,_fishBox in ipairs(self.m_fishBoxItems) do
        _fishBox:setVisible(false)
    end 
    --商店
    self.m_shopBar:setVisible(false)
end
function CodeGameScreenFishManiaMachine:leaveFreeSpinChangeShow()
    self:hideFreeSpinBar()
    --滚轮背景
    self:findChild("reel_fs"):setVisible(false)
    --鱼缸
    for _shopIndex,_fishBox in ipairs(self.m_fishBoxItems) do
        _fishBox:setVisible(true)
    end 
    --商店
    self.m_shopBar:setVisible(true)
end
--superFree的提示 
function CodeGameScreenFishManiaMachine:changeFishBoxTipShow(_shopIndex, _isShow)
    --本次操作的提示类型
    local tipIndex = _shopIndex

    --没拿到，不弹
    local tip = self.m_fishBoxTips[tipIndex]
    if not tip then
        return
    end
    
    --没有传的话取对立状态
    if nil == _isShow then
        if tip:isVisible() and _shopIndex == self.m_curTipShopIndex then
            _isShow = false
        elseif not tip:isVisible() and _shopIndex ~= self.m_curTipShopIndex then
            _isShow = true
        --不处于以上的状况时，直接返回
        else
            return
        end
    --正在关闭/已经关闭后 执行了 手动点击关闭/自动关闭
    elseif not _isShow and (not tip:isVisible() or 0 == self.m_curTipShopIndex) then
        return
    end

    tip:stopAllActions()

    for i,v in ipairs(self.m_fishBoxTips) do
        v:setVisible(false)
    end
    tip:setVisible(true)

    local soundName = ""
    --修改本次展示的坐标
    if _isShow then
        local fishBoxItem = self.m_fishBoxItems[_shopIndex]
        if fishBoxItem then
            local tipNode = fishBoxItem:findChild("tip")
            util_changeNodeParent(tipNode, tip)
            tip:setPosition(0, 0)
        end
        --打开后3s关闭
        performWithDelay(tip, function()
            self:changeFishBoxTipShow(_shopIndex, false)
        end, 30/60+3)

        self.m_curTipShopIndex = _shopIndex
        soundName = "FishManiaSounds/FishMania_fishBoxTip_start.mp3"
    else
        self.m_curTipShopIndex = 0
        soundName = "FishManiaSounds/FishMania_fishBoxTip_over.mp3"
    end
    gLobalSoundManager:playSound(soundName)

    local actName = _isShow and "start" or "over"
    tip:runCsbAction(actName, false, function()
        if _isShow then
        else
            tip:setVisible(false)
        end
    end)
end
function CodeGameScreenFishManiaMachine:fishBoxClickChangeBg(_shopIndex)
    local p_shopData = globalMachineController.p_fishManiaShopData
    -- local progress = p_shopData:getShopProgress(_shopIndex)
    local shopIndex = p_shopData:getShowIndex()
    -- if progress >= 1 then
    if _shopIndex ~= self.m_shopIndex and _shopIndex <= shopIndex then
        self:showShareBtn()
        --商店打开的话切换一下
        if self.m_shopListView.m_closeOrOpen and _shopIndex ~= self.m_shopListView.m_currPageIdex then
            self.m_shopListView:setPageIndex(_shopIndex, false, false)
        end

        local eventName = globalMachineController.p_fishManiaPlayConfig.EventName.UPDATE_MACHINE_FISH_TANK
        local data = {_shopIndex}
        gLobalNoticManager:postNotification(eventName, data)

    end
end

function CodeGameScreenFishManiaMachine:showFreeSpinOverView()
    local triggerSuperFree = true==self.m_bInSuperFreeSpin
    self.m_bInSuperFreeSpin = false

   local strCoins     = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
   local fsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount

    if triggerSuperFree then

        self.m_bottomUI:hideAverageBet()
        --清空自由商店的装饰品购买数据
        local p_shopData = globalMachineController.p_fishManiaShopData
        p_shopData:superFreeOverClearData()
        
        --商店打开的话刷新一下
        if self.m_shopListView.m_closeOrOpen then
            self.m_shopListView:updateGoodsAtPageIndex(self.m_shopListView.m_currPageIdex)
        end

        local view = self:showSuperFreeSpinOver(fsTotalCount, strCoins,function()
    
            self:playFreeSpinGuoChang(function()
                
                --没有大赢直接展示，有大赢的话添加到大赢事件尾部
                if not self:isHasBigWin() then
                    if p_shopData:getShowIndex() < 4 then
                        -- superfree 结束引导拍照
                        self.m_paisheEffect:setVisible(true)
                        gLobalSoundManager:playSound("FishManiaSounds/FishMania_share_paizhao.mp3")
                        self:showShareZheZhao()
                        self.m_paisheEffect:runCsbAction("actionframe",false,function()
                            self:screenShotFishToy(function()
                                local shopIndex = p_shopData:getShowIndex()
                                -- self:updateFishToyForIndex(shopIndex)
                                -- self:checkSwitchBg()
                                local nextShopIndex = shopIndex ~= 4 and shopIndex+1 or shopIndex
                                self:slideSwitchShopBg(nextShopIndex, function()

                                    self:checkSwitchBg()

                                    self:checkSwitchFishBox(function()
                                        self:openSelectShopView()
                                    end)
                                end,true)

                                self:triggerFreeSpinOverCallFun()
                            end)
                        end)
                    else
                        self:checkSwitchFishBox(function()
                            self:openSelectShopView()
                        end)

                        self:triggerFreeSpinOverCallFun()
                    end
                    
                else
                    self.m_openSelectViewFlag = true
                    if p_shopData:getShowIndex() < 4 then
                        -- superFree 结束有大赢 需要引导拍照
                        self.m_superfreeBigWinPaiZhao = true
                    else
                        self.m_superfreeBigWinPaiZhao = false
                    end
                    self:triggerFreeSpinOverCallFun()
                end

            end)
            self:levelPerformWithDelay(110/60, function()
                -- local shopIndex = p_shopData:getShowIndex()
                -- if shopIndex == 4 then
                --     self:updateFishToyForIndex(shopIndex)
                --     self:checkSwitchBg()
                -- end
                
                self:clearWinLineEffect()
                self:superFreeOverChangeWildLock()
                
                --平均bet值 隐藏
                self.m_bottomUI:hideAverageBet()
                --背景角色
                self:hideSuperFreeJuese()

                self:leaveFreeSpinChangeShow()
            end)

        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.1,sy=1.1},540)
        
    else
        gLobalSoundManager:playSound("FishManiaSounds/FishMania_free_over.mp3")
        local view = self:showFreeSpinOver( strCoins, fsTotalCount,function()
            self:playFreeSpinGuoChang(function()
                --商店引导
                if self:isTriggerShopGuide(true) then
                    if not self:isHasBigWin() then
                        self:addShopGuideEffect()
                        if not self.m_isRunningEffect then
                            self:playGameEffect()
                        end
                    else
                        self.m_shopGuideFlage = true
                    end
                end

                self:triggerFreeSpinOverCallFun()
            end)
            self:levelPerformWithDelay(110/60, function()
                self:playFreeLockWildIdlefraem(false)
                self:freeOverChangeWildLock()

                self:leaveFreeSpinChangeShow()
            end)
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.1,sy=1.1},540)
    end
    
    
end


--free结束检测切换鱼缸和背景展示 解锁 -> 选择自定义商店
function CodeGameScreenFishManiaMachine:checkSwitchBg()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    --修改当前的商店索引
    if selfData.shopIndex then
        local p_shopData = globalMachineController.p_fishManiaShopData
        local oldIndex = p_shopData:getShowIndex()
        --更新数据
        local data = {
            shopIndex = selfData.shopIndex,
            selectIndex = selfData.selectSuperFree or 0,
        }
        p_shopData:parseShopData(data)

        local eventName = globalMachineController.p_fishManiaPlayConfig.EventName.UPDATE_MACHINE_FISH_TANK
        local data = {selfData.shopIndex}
        gLobalNoticManager:postNotification(eventName, data)
    end
end
function CodeGameScreenFishManiaMachine:checkSwitchFishBox(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    --修改当前的商店索引
    if selfData.shopIndex then
        local p_shopData = globalMachineController.p_fishManiaShopData
        local oldIndex = p_shopData:getShowIndex()

        --解锁新鱼缸
        if oldIndex ~= selfData.shopIndex then
            self:fishBox_playUnLockAnim(selfData.shopIndex, _fun)
        else
            local fishBox = self.m_fishBoxItems[selfData.shopIndex]
            fishBox:upDateState()

            if _fun then
                _fun()
            end
        end
        
        self:fishBox_upDateSelectState()
        self:shopBar_upDateShopBuyState()
        --商店打开的话刷新一下
        if self.m_shopListView.m_closeOrOpen then
            self.m_shopListView:setPageIndex(selfData.shopIndex)
        end
        
    end
    
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFishManiaMachine:MachineRule_SpinBtnCall()
    --商店列表打开状态先关闭 
    --bugly报错: m_shopListView is nil
    if self.m_shopListView and self.m_shopListView.m_closeOrOpen then
        self.m_shopListView:HideShopListView()
    end
    --商店提示
    if self.m_shopBar.m_tip:isVisible() then
        self.m_shopBar:changeTipShow()
    end
    --鱼缸提示
    if 0 ~= self.m_curTipShopIndex then
        self:changeFishBoxTipShow(self.m_curTipShopIndex, false)
    end
    --关闭装饰品设置弹板
    self:setLayer_switchSetLayerShow(self.m_shopIndex)

    self.p_isInitIcon = false

    self:stopLinesWinSound()
    self:setMaxMusicBGVolume( )
   
    return false -- 用作延时点击spin调用
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFishManiaMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then

        local scoreList = selfData.scoreList 
        if scoreList and table_length(scoreList) > 0 then
            local effectData            = GameEffectData.new()
            effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
            effectData.p_effectOrder    = self.EFFECT_COLLECT_ICON
            effectData.p_selfEffectType = self.EFFECT_COLLECT_ICON
            self.m_gameEffects[#self.m_gameEffects + 1] = effectData
                
        end

        local changeWild = selfData.changeWild
        if changeWild and table_length(changeWild) > 0  then
            local effectData            = GameEffectData.new()
            effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
            effectData.p_effectOrder    = self.EFFECT_SHOWWILD_LOCK
            effectData.p_selfEffectType = self.EFFECT_SHOWWILD_LOCK
            self.m_gameEffects[#self.m_gameEffects + 1] = effectData
        end
        -- local betStr = string.format("%d", globalData.slotRunData:getCurTotalBet()) 
        local betStr = tostring(toLongNumber(globalData.slotRunData:getCurTotalBet()))
        self:setLockWildBetList(betStr, changeWild)

        local normalWilds = selfData.normalWilds
        if normalWilds and table_length(normalWilds) > 0  then
            local effectData            = GameEffectData.new()
            effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
            effectData.p_effectOrder    = self.EFFECT_SHOWWILD_COlLOCK
            effectData.p_selfEffectType = self.EFFECT_SHOWWILD_COlLOCK
            self.m_gameEffects[#self.m_gameEffects + 1] = effectData
        end


        if self:isTriggerShopGuide(true) then
            local scatterCount = self:getSymbolCountWithReelResult(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            if scatterCount < 3 then
                self:addShopGuideEffect()
            end
        end
    else
        local triggerSuperFree = true==self.m_bInSuperFreeSpin
        -- if not triggerSuperFree then
            local freeWildPos = selfData.freeWildPos
            if freeWildPos then
                local effectData            = GameEffectData.new()
                effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
                effectData.p_effectOrder    = self.EFFECT_NORMALFREE_SHOWLOCKWILD
                effectData.p_selfEffectType = self.EFFECT_NORMALFREE_SHOWLOCKWILD
                self.m_gameEffects[#self.m_gameEffects + 1] = effectData
            end  
        -- end

        if not triggerSuperFree and freeWildPos then
            --没有连线直接播，有连线添加标记放在连线事件结束时播
            if #self.m_vecGetLineInfo ~= 0 then
                self.m_playFreeLockWildFlag = true
            else
                local effectData            = GameEffectData.new()
                effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
                effectData.p_effectOrder    = self.EFFECT_NORMALFREE_LOCKWILDANIM
                effectData.p_selfEffectType = self.EFFECT_NORMALFREE_LOCKWILDANIM
                self.m_gameEffects[#self.m_gameEffects + 1] = effectData
            end
        end
        
    end

end
function CodeGameScreenFishManiaMachine:addShopGuideEffect()
    local effectData            = GameEffectData.new()
    effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
    effectData.p_effectOrder    = self.EFFECT_SHOP_GUIDE
    effectData.p_selfEffectType = self.EFFECT_SHOP_GUIDE
    self.m_gameEffects[#self.m_gameEffects + 1] = effectData

    self.m_shopListView:setIsCanTouch(false)
end
-- @ _isAddScore 是否计算轮盘上的积分
function CodeGameScreenFishManiaMachine:isTriggerShopGuide(_isAddScore)
    local p_shopData = globalMachineController.p_fishManiaShopData
    local curSpend,allSpend = p_shopData:getShopSpend(1)
    if curSpend > 0 then
        return false
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local allScore = 0
    local curScore = p_shopData:getPickScore()
    local addScore = 0

    if _isAddScore then
        local scoreList = selfData.scoreList or {}
        for k,v in pairs(scoreList) do
            local score = tonumber(v.score)
            addScore = addScore + score
        end
    end
    
    allScore = curScore + addScore

    local shopData = p_shopData:getShopDataByIndex(1)
    if shopData then
        for index,commodity in ipairs(shopData) do
            if not commodity.buy and tonumber(commodity.price) <= allScore then
                return true
            end
        end
    end

    return false
end
---
function CodeGameScreenFishManiaMachine:isHaveSelfEffect(_selfEffectType)
    local effectList = self.m_gameEffects or {}
    for k,v in pairs(effectList) do
        local effectType = v.p_effectType
        if effectType == GameEffect.EFFECT_SELF_EFFECT then
            if _selfEffectType == v.p_selfEffectType then
                return true
            end
        end
    end

    return false
end
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFishManiaMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_COLLECT_ICON then
        self:playCollectIcon( )
        local delayTime = 0
        if self:isHaveSelfEffect(self.EFFECT_SHOP_GUIDE) then
            delayTime = 33/60 + 1
        end
        -- 要求播角标时可以立刻spin, 除非出现引导
        self:levelPerformWithDelay(delayTime, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    elseif effectData.p_selfEffectType == self.EFFECT_SHOWWILD_LOCK then
        self:showScoreWildLockEffect( effectData )
    elseif effectData.p_selfEffectType == self.EFFECT_SHOWWILD_COlLOCK then

        self:showNormalWildColLockEffect( effectData )

    elseif effectData.p_selfEffectType == self.EFFECT_NORMALFREE_SHOWLOCKWILD then 
        self:showNormalFreeShowWildLockEffect( effectData )

    elseif effectData.p_selfEffectType == self.EFFECT_NORMALFREE_LOCKWILDANIM then 
        self:playFreeLockWildAnim(false, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    
    elseif effectData.p_selfEffectType == self.EFFECT_SHOP_GUIDE then 
        self:playShopGuide(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

function CodeGameScreenFishManiaMachine:beginReel( )
    --禁用商店相关按钮
    self.m_shopBar:setIsCanTouch(false)
    --禁止回收按钮
    self:setLayer_upDateRecoveryBtnEnable(false)

    self:spineChangeScoreWildLock( function()
        CodeGameScreenFishManiaMachine.super.beginReel(self)
    end)

end

function CodeGameScreenFishManiaMachine:changeOneSymbol(_symbolNode, _symbolType)


    if _symbolNode.p_symbolImage ~= nil and _symbolNode.p_symbolImage:getParent() ~= nil then
        _symbolNode.p_symbolImage:removeFromParent()
    end
    _symbolNode.p_symbolImage = nil
    _symbolNode.m_ccbName = ""

    local ccbName = self:getSymbolCCBNameByType(self, _symbolType)
    _symbolNode:changeCCBByName(ccbName, _symbolType)
    if not self:isLockMultiplyWildSymbol(_symbolNode.p_symbolType) then
        _symbolNode:changeSymbolImageByName(ccbName)
        _symbolNode:resetReelStatus()
    end
    
    local order = self:getBounsScatterDataZorder(_symbolType ) - _symbolNode.p_rowIndex
    _symbolNode:setLocalZOrder(order)

    _symbolNode:setLineAnimName("actionframe")
    _symbolNode:setIdleAnimName("idleframe")


    self:initMultWildSymbol(_symbolNode)
end

function CodeGameScreenFishManiaMachine:spineChangeScoreWildLock( _func )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if _func then
            _func()
        end
        return
    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do

            local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_FIX_NODE_TAG) or self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbol and self:isLockMultiplyWildSymbol(symbol.p_symbolType) then
                if symbol.p_symbolType ~= self.SYMBOL_SCORE_WILD_1 then
                    --滚动开始时就提前减1
                    local symbolType = symbol.p_symbolType - 1
                    self:changeOneSymbol(symbol, symbolType)
                    self:initLockMultWildSymbol(symbol, {playIdle = true})
                end
            end

        end
    end

    self:levelPerformWithDelay(0, function()
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenFishManiaMachine:playShopGuide(_fun)
    self.m_shopGuideFlage = false

    local p_shopData = globalMachineController.p_fishManiaShopData

    self.m_guideMask:setVisible(true)
    local shopBarParent = self:findChild("progress")
    --播放指引
    self.m_shopBar:playFingerTipAnim()

    local guideTime = 15
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    --3.引导结束
    local guildEndFun = function()
        p_shopData:setGuideState(false)

        self.m_guideMask:setVisible(false)
        self.m_shopBar:setIsCanTouch(true)
        self.m_shopBar.m_fingertip:setVisible(false)

        if _fun then
            _fun()
        end 
        waitNode:removeFromParent()
    end

    --2.点击购买第一件商品
    local buyFirstCommodity = function()
        self.m_shopBar:setIsCanTouch(false)
        self.m_shopListView:setIsCanTouch(true)

        local fingertip = self.m_shopBar.m_fingertip
        
        local item = self.m_shopListView:getOneCommodityItem(1, 1)
        local btn_buy = item:findChild("btn_Buy")
        local worldPos = btn_buy:getParent():convertToWorldSpace(cc.p(btn_buy:getPosition())) 

        local oldPos = cc.p(fingertip:getPosition())
        local newPos =  fingertip:getParent():convertToNodeSpace(worldPos)

        fingertip:setPosition(newPos)

        local registerId = self.m_shopListView:registerBuyBtnClickCallBack( function(_registerId, _params)
            self.m_shopListView:unRegisterBuyBtnClickCallBack(_registerId)
            waitNode:stopAllActions()
            fingertip:setPosition(oldPos)
            guildEndFun()
        end) 
        performWithDelay(waitNode,function()
            self.m_shopListView:unRegisterBuyBtnClickCallBack(registerId)
            self.m_shopListView:clickFunc(btn_buy)
            fingertip:setPosition(oldPos)
            guildEndFun()
        end, guideTime)

    end

    --1.打开商店
    p_shopData:setGuideState(true)
    if self.m_shopListView.m_closeOrOpen then
        buyFirstCommodity()
    else
        local registerId = self.m_shopBar:registerShopBtnClickCallBack(function(_registerId)
            self.m_shopBar:unRegisterShopBtnClickCallBack(_registerId)
            waitNode:stopAllActions()
            buyFirstCommodity()
        end)
        performWithDelay(waitNode,function()
            self.m_shopBar:unRegisterShopBtnClickCallBack(registerId)
            self.m_shopBar:onShopBtnClick()
            buyFirstCommodity()
        end, guideTime)
    end
    
    
end
function CodeGameScreenFishManiaMachine:showScoreWildLockEffect( effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local changeWild = selfdata.changeWild or {}

    for k,v in pairs(changeWild) do
        local changePos = tonumber(k)
        local symbolType = tonumber(v)
        local fixPos = self:getRowAndColByPos(changePos)
        local symbolNode = nil
        if (symbolType == self.SYMBOL_SCORE_WILD_3) then
            symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG) 
        else
            symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_FIX_NODE_TAG) 
        end
        
        if symbolNode then
            --修改信号 切换层级 设置连线数据                    
            if symbolType == self.SYMBOL_SCORE_WILD_1 then
                symbolNode.m_symbolTag = SYMBOL_NODE_TAG
                symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            else
                symbolNode.m_symbolTag = SYMBOL_FIX_NODE_TAG
                symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            end
            
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            symbolNode.m_bInLine = true
            symbolNode:setLinePos(linePos)

            symbolNode:setTag(self:getNodeTag(fixPos.iY, fixPos.iX, symbolNode.m_symbolTag))

            self:changeOneSymbol(symbolNode,symbolType)
            self:initLockMultWildSymbol(symbolNode, {playIdle = false})
        else
            local msg = string.format("[CodeGameScreenFishManiaMachine:showScoreWildLockEffect] changePos=(%d) symbolType=(%d)", changePos, symbolType)
            self:pushSpinLog(msg)
            self:sendSpinLog()
            self:clearSpinLog()
        end
    end

    
    self:levelPerformWithDelay(0, function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end)
end

function CodeGameScreenFishManiaMachine:showNormalWildColLockEffect( effectData )


    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local normalWilds = selfdata.normalWilds or {}

    for i=1,#normalWilds do
        local changePos = normalWilds[i]
        local fixPos = self:getRowAndColByPos(changePos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if symbolNode then
            --scatter -> wild
            if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                self:changeOneSymbol(symbolNode, self.SYMBOL_SCORE_WILD_SCATTER)
                symbolNode:runAnim("switch", false, function()
                    symbolNode:runAnim("idleframe")
                end)
            -- other -> wild
            else
                self:changeOneSymbol(symbolNode, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                symbolNode:runAnim("chuxian", false, function()
                    symbolNode:runAnim("idleframe")
                end)
            end
        end
    end
    
    self:playChangeWildAnim()

    self:levelPerformWithDelay(40/30, function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end)
end
function CodeGameScreenFishManiaMachine:playChangeWildAnim()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local changeWild = selfdata.changeWild or {}
    local normalWilds = selfdata.normalWilds or {}

    local wildPos = {}
    for _pos,_symbolType in pairs(changeWild) do
        table.insert(wildPos, tonumber(_pos))
    end
    table.sort(wildPos, function(a, b)
        return a < b
    end)
    --获取指定行列的第一个和最后一个
    local getFirstAndLast = function(_col, _row)
        local first,last = 0,0
        --
        local value = _col or _row
        local getValue = function(_posIndex)
            local posData = self:getRowAndColByPos(_posIndex)
            if nil ~= _col then
                return posData.iY
            else
                return posData.iX
            end
        end
        --
        for _index=1,#wildPos do
            local posIndex = wildPos[_index]
            if value == getValue(posIndex) then
                first = posIndex
                break
            end
        end
        for _index=#wildPos,1,-1 do
            local posIndex = wildPos[_index]
            if value == getValue(posIndex) then
                last = posIndex
                break
            end
        end

        return first,last
    end
    --查看指定行列是否有变换的wild
    local isSwitchWild = function(_col, _row)
        local have = false
        --
        local value = _col or _row
        local getValue = function(_posIndex)
            local posData = self:getRowAndColByPos(_posIndex)
            if nil ~= _col then
                return posData.iY
            else
                return posData.iX
            end
        end
        --
        for i,_posIndex in ipairs(normalWilds) do
            if value == getValue(_posIndex) then
                have = true
                break
            end
        end

        return have
    end

    local dataList = {
        --[[
            [1] = {
                sPos = 0,              --起始wild坐标
                ePos = 4,              --结束wild坐标
                dir  = 0,              --0:横向波纹 1:竖向波纹
            }
        ]]
    }
    local parentNode = self:findChild("bowen")
    local isPlaySound = false
    for _index,_posIndex in pairs(wildPos) do

        local posData1 = self:getRowAndColByPos(_posIndex)
        --去后面找同行或者同列的wild坐标
        for _index2=_index+1,#wildPos do

            local posIndex2 = wildPos[_index2]
            local data = {}

            
            local posData2 = self:getRowAndColByPos(posIndex2)
            --同行
            if posData1.iX == posData2.iX then
                if isSwitchWild(nil, posData1.iX) then
                    data.dir = 0
                    --找到第一个和最后一个的坐标
                    local first,last = getFirstAndLast(nil, posData1.iX)
                    data.sPos = first
                    data.ePos = last
                end
                
            --同列
            elseif posData1.iY == posData2.iY then
                if isSwitchWild(posData1.iY) then
                    data.dir = 1
                    --找到第一个和最后一个的坐标
                    local first,last = getFirstAndLast(posData1.iY, nil)
                    data.sPos = first
                    data.ePos = last
                end
            end
            
            if data.dir then
                local have = false
                for k,_data in pairs(dataList) do
                    if (data.sPos == _data.sPos or data.sPos == _data.ePos) and 
                        (data.sPos + data.ePos == _data.sPos + _data.ePos) then

                        have = true
                        break
                    end
                end

                if not have then
                    table.insert(dataList, data)
                    --
                    if not isPlaySound then
                        isPlaySound = true
                        gLobalSoundManager:playSound("FishManiaSounds/FishMania_changeWild.mp3")
                    end
                    local fixPos1 = self:getRowAndColByPos(data.sPos)
                    local fixPos2 = self:getRowAndColByPos(data.ePos)

                    local slotParent1 = self:getReelParent(fixPos1.iY)
                    local slotParent2 = self:getReelParent(fixPos2.iY)

                    local worldPos1 = slotParent1:convertToWorldSpace( util_getPosByColAndRow(self, fixPos1.iY, fixPos1.iX) )
                    local worldPos2 = slotParent2:convertToWorldSpace( util_getPosByColAndRow(self, fixPos2.iY, fixPos2.iX) )
                    local centerPos = cc.p(worldPos1.x + (worldPos2.x - worldPos1.x)/2, worldPos1.y + (worldPos2.y - worldPos1.y)/2)
                    local nodePos1 = cc.p(parentNode:convertToNodeSpace(worldPos1))
                    local nodePos2 = cc.p(parentNode:convertToNodeSpace(worldPos2))
                    local centerNodePos = cc.p(parentNode:convertToNodeSpace(centerPos))

                    local rotation = 0==data.dir and 0 or 90
                    local scaleX = 1
                    if fixPos1.iY ~= fixPos2.iY then
                        scaleX = (math.abs(fixPos1.iY - fixPos2.iY)+1) / self.m_iReelColumnNum
                    elseif fixPos1.iX ~= fixPos2.iX then
                        scaleX = (math.abs(fixPos1.iX - fixPos2.iX)+1) / self.m_iReelRowNum * self.m_iReelRowNum / self.m_iReelColumnNum
                        -- scaleX = self.m_iReelRowNum / self.m_iReelColumnNum
                    end
                    -- 一个波纹两个星星
                    local bowen = util_createAnimation( "FishMania_wild_wild.csb" )
                    parentNode:addChild(bowen, 10)
                    bowen:setRotation(rotation)
                    bowen:setScaleX(scaleX)
                    bowen:setPosition(centerNodePos)
                    bowen:runCsbAction("actionframe", false, function()
                        bowen:removeFromParent()
                    end)

                    local star1 = util_createAnimation( "FishMania_wild_wild_xx.csb" )
                    parentNode:addChild(star1, 15)
                    star1:setRotation(rotation)
                    star1:setPosition(nodePos1)
                    local act_move1 = cc.MoveTo:create(40/60, nodePos2)
                    local act_callFun1 = cc.CallFunc:create(function()
                        star1:removeFromParent()
                    end)
                    star1:runAction(cc.Sequence:create(act_move1, act_callFun1))
                    star1:runCsbAction("actionframe", false, function()
                        star1:removeFromParent()
                    end)

                    local star2 = util_createAnimation( "FishMania_wild_wild_xx.csb" )
                    parentNode:addChild(star2, 15)
                    star2:setRotation(rotation)
                    star2:setPosition(nodePos2)
                    local act_move2 = cc.MoveTo:create(40/60, nodePos1)
                    local act_callFun2 = cc.CallFunc:create(function()
                        star2:removeFromParent()
                    end)
                    star2:runAction(cc.Sequence:create(act_move2, act_callFun2))
                    star2:runCsbAction("actionframe", false, function()
                        star2:removeFromParent()
                    end)
                end
            end
        end
        
    end
    



end

function CodeGameScreenFishManiaMachine:showNormalFreeShowWildLockEffect(effectData )
    local delayTime = 0

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freeWildPos = selfdata.freeWildPos or {}

    for k,v in pairs(freeWildPos) do
        local freeWildPosPos = tonumber(v)
        local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        local fixPos = self:getRowAndColByPos(freeWildPosPos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_FIX_NODE_TAG) 
        if symbolNode then
            if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolNode = nil
            end
        else
            symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG) 
        end
        
        if symbolNode then
            table.insert(self.m_newFreeLockWild, fixPos)

            symbolNode.m_symbolTag = SYMBOL_FIX_NODE_TAG
            symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            symbolNode.m_bInLine = true
            symbolNode:setLinePos(linePos)

            symbolNode:setTag(self:getNodeTag(fixPos.iY, fixPos.iX, symbolNode.m_symbolTag))

            self:changeOneSymbol(symbolNode, TAG_SYMBOL_TYPE.SYMBOL_WILD)
        end
    end

    
    self:levelPerformWithDelay(delayTime, function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end)
end
-- 锁定动画 -> idleframe
function CodeGameScreenFishManiaMachine:playFreeLockWildAnim(_isLineFrame,_fun)
    local lineFrameTime = _isLineFrame and 1 or 0
    local lockTime = 0
    local delayTime = 0   --lineFrameTime

    --有连线时 先清理连线
    self:levelPerformWithDelay(lineFrameTime, function()
        self:clearWinLineEffect()
    end)
    
    if #self.m_newFreeLockWild >0 then
        lockTime = 20/30
        -- delayTime = delayTime + 20/30

        --等一下第一轮连线
        self:levelPerformWithDelay(lineFrameTime, function()

            gLobalSoundManager:playSound("FishManiaSounds/FishMania_wild_fixed.mp3")

            for k,v in pairs(self.m_newFreeLockWild) do
                local fixPos = v
                local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_FIX_NODE_TAG) or self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    symbolNode:runAnim("lock")
                end
            end
            self.m_newFreeLockWild = {}
            
        end)
    end
    

    self:levelPerformWithDelay(delayTime, function()
        if _fun then
            _fun()
        end
    end)
    self:levelPerformWithDelay(lineFrameTime + lockTime, function()
        
        self:playFreeLockWildIdlefraem(true)
    end)
end
--是否播放循环的固定wild idleframe @_isLoop : 不循环的话就是直接重置为idleframe状态
function CodeGameScreenFishManiaMachine:playFreeLockWildIdlefraem(_isLoop,_fun)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freeWildPos = selfdata.freeWildPos or {}

    for k,v in pairs(freeWildPos) do
        local freeWildPosPos = tonumber(v)
        local fixPos = self:getRowAndColByPos(freeWildPosPos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_FIX_NODE_TAG) 
        if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            local frameName = _isLoop and "idleframe2" or "idleframe"
            symbolNode:runAnim(frameName, _isLoop)
        end
    end

    if _fun then
        _fun()
    end
end

--将轮盘上乘倍wild从 固定层级 -> 普通滚动层级
function CodeGameScreenFishManiaMachine:superFreeTriggerChangeWildLock()
    --使用当前bet存储的wild
    -- local curBetStr = string.format("%d", self.m_curTotalBet)
    local curBetStr = tostring(toLongNumber(self.m_curTotalBet))
    local changeWild = self.m_lockWildBet[curBetStr] and self.m_lockWildBet[curBetStr].changeWildMap  or {}

    for k,v in pairs(changeWild) do
        local changePos = tonumber(k)
        local symbolType = tonumber(v)
        local fixPos = self:getRowAndColByPos(changePos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_FIX_NODE_TAG) 

        if symbolNode then
            symbolNode.m_symbolTag = SYMBOL_NODE_TAG
            symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

            symbolNode:setTag(self:getNodeTag(fixPos.iY, fixPos.iX, symbolNode.m_symbolTag))
        end
    end
end
--将轮盘上乘倍wild从 普通滚动层级 -> 固定层级
function CodeGameScreenFishManiaMachine:superFreeOverChangeWildLock()
    --使用当前bet存储的wild
    -- local curBetStr = string.format("%d", self.m_curTotalBet)
    local curBetStr = tostring(toLongNumber(self.m_curTotalBet))
    local changeWild = self.m_lockWildBet[curBetStr] and self.m_lockWildBet[curBetStr].changeWildMap  or {}

    for k,v in pairs(changeWild) do
        local changePos = tonumber(k)
        local symbolType = tonumber(v)
        local fixPos = self:getRowAndColByPos(changePos)
        --最大程度拿到该位置小块 修改展示
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if not symbolNode then
            symbolNode = self:getReelGridNode(fixPos.iY,fixPos.iX)
        end

        if symbolNode then

            if symbolType == self.SYMBOL_SCORE_WILD_1 then
                symbolNode.m_symbolTag = SYMBOL_NODE_TAG
                symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            else
                symbolNode.m_symbolTag = SYMBOL_FIX_NODE_TAG
                symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            end
            
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            symbolNode.m_bInLine = true
            symbolNode:setLinePos(linePos)

            symbolNode:setTag(self:getNodeTag(fixPos.iY, fixPos.iX, symbolNode.m_symbolTag))

            self:changeOneSymbol(symbolNode,symbolType)
            self:initLockMultWildSymbol(symbolNode, {playIdle = true})
        end
    end
end
function CodeGameScreenFishManiaMachine:freeTriggerChangeWildLock( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freeWildPos = selfdata.freeWildPos or {}
    --使用当前bet存储的wild
    -- local curBetStr = string.format("%d", self.m_curTotalBet)
    local curBetStr = tostring(toLongNumber(self.m_curTotalBet))
    local changeWild = self.m_lockWildBet[curBetStr] and self.m_lockWildBet[curBetStr].changeWildMap  or {}

    -- for k,v in pairs(freeWildPos) do
    --     local freeWildPosPos = tonumber(v)
    for k,v in pairs(changeWild) do
        local freeWildPosPos = tonumber(k)
        local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        local fixPos = self:getRowAndColByPos(freeWildPosPos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_FIX_NODE_TAG) 
        if symbolNode then
            if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolNode = nil
            end
        else
            symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG) 
        end
        
        if symbolNode then
            self:changeOneSymbol(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD )
            self:removeSymbolCollectIcon(symbolNode)

            symbolNode.m_symbolTag = SYMBOL_FIX_NODE_TAG
            symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            symbolNode.m_bInLine = true
            symbolNode:setLinePos(linePos)

            symbolNode:setTag(self:getNodeTag(fixPos.iY, fixPos.iX, symbolNode.m_symbolTag))
        end
    end

    self:playFreeLockWildIdlefraem(true)
end

function CodeGameScreenFishManiaMachine:freeOverChangeWildLock( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freeWildPos = selfdata.freeWildPos or {}

    for k,v in pairs(freeWildPos) do
        local freeWildPosPos = tonumber(v)
        local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        local fixPos = self:getRowAndColByPos(freeWildPosPos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_FIX_NODE_TAG) 

        if symbolNode then
            symbolNode.m_symbolTag = SYMBOL_NODE_TAG
            symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            symbolNode.p_preLayerTag = symbolNode.p_layerTag

            symbolNode:setTag(self:getNodeTag(fixPos.iY, fixPos.iX, symbolNode.m_symbolTag))
        end
    end
    

    -- local changeWild = selfdata.changeWild or {}
    --使用当前bet存储的wild
    -- local curBetStr = string.format("%d", self.m_curTotalBet)
    local curBetStr = tostring(toLongNumber(self.m_curTotalBet))
    local changeWild = self.m_lockWildBet[curBetStr] and self.m_lockWildBet[curBetStr].changeWildMap  or {}
    for k,v in pairs(changeWild) do
        local changePos = tonumber(k)
        local symbolType = tonumber(v)
        local fixPos = self:getRowAndColByPos(changePos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_FIX_NODE_TAG) 
        if not symbolNode then
            symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG) 
        end
        if symbolNode then
           
            if symbolType == self.SYMBOL_SCORE_WILD_1 then
                symbolNode.m_symbolTag = SYMBOL_NODE_TAG
                symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                symbolNode.p_preLayerTag = symbolNode.p_layerTag
            else
                symbolNode.m_symbolTag = SYMBOL_FIX_NODE_TAG
                symbolNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                symbolNode.p_preLayerTag = symbolNode.p_layerTag
            end
            
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            symbolNode.m_bInLine = true
            symbolNode:setLinePos(linePos)

            symbolNode:setTag(self:getNodeTag(fixPos.iY, fixPos.iX, symbolNode.m_symbolTag))

            self:changeOneSymbol(symbolNode, symbolType)
        end

    end

end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFishManiaMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenFishManiaMachine:playEffectNotifyNextSpinCall( )

    BaseNewReelMachine.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenFishManiaMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    --打开回收按钮
    self:setLayer_upDateRecoveryBtnEnable(true)
    --恢复商店相关按钮
    self.m_shopBar:setIsCanTouch(true)

    BaseNewReelMachine.slotReelDown(self)
end


-- 初始化小块时 规避某个信号接口 （包含随机创建的两个函数，根据网络消息创建的函数）
function CodeGameScreenFishManiaMachine:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex,reelDatas  )
    
    if symbolType == self.SYMBOL_SCORE_WILD_3  
        or symbolType == self.SYMBOL_SCORE_WILD_2  
            or symbolType == self.SYMBOL_SCORE_WILD_1  
                or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD  then 

        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9

    end

    return symbolType
end
--刷新商店背景展示
function CodeGameScreenFishManiaMachine:updateGameBgForIndex( _currPageIndex)
    local p_shopData = globalMachineController.p_fishManiaShopData
    local maxPageCount = p_shopData:getShopPageCount()
    for _shopIndex=1,maxPageCount do
        if _shopIndex ~= maxPageCount or _currPageIndex == maxPageCount then
            local shopBgNode = self:getShopBgNode(_shopIndex)
            shopBgNode:setVisible( _shopIndex == _currPageIndex )
        end
    end
end
--获取Bg指定商店的背景
function CodeGameScreenFishManiaMachine:getShopBgNode(_shopIndex, _gameBgNode)
    local gameBg = _gameBgNode or self.m_gameBg
    local bgName = {
        [1] = "bg_Hawaii",
        [2] = "bg_Pirates",
        [3] = "bg_Greece",
    }
    local name = ""
    --自由商店的背景是选择商店的背景，没有选择默认为1
    if _shopIndex == globalMachineController.p_fishManiaPlayConfig.FishItemId.CustomId then
        local selectIndex = globalMachineController.p_fishManiaShopData:getSelectIndex()
        name = bgName[selectIndex] or bgName[1]
    else
        name = bgName[_shopIndex]
    end

    local shopBgNode = gameBg:findChild(name)

    return shopBgNode
end

function CodeGameScreenFishManiaMachine:hideAllFishToyView( )
    for _shopIndex,_fishToyView in ipairs(self.m_fishToyViews) do
        _fishToyView:setVisible(false)   
    end
end

function CodeGameScreenFishManiaMachine:updateFishToyForIndex( _currPageIndex)

    local fishToyView = self.m_fishToyViews[_currPageIndex]
    if fishToyView then
        fishToyView:upDateFishToyVisible()
        fishToyView:setVisible(true)   
    end

end

function CodeGameScreenFishManiaMachine:triggerBonusSuperFree(_param)
    --保存一些数据 (freeSpin,)
    local spinData = _param[2]
    local data = spinData.result

    if data.freespin ~= nil then
        self.m_runSpinResultData.p_freeSpinsTotalCount = data.freespin.freeSpinsTotalCount -- fs 总数量
        self.m_runSpinResultData.p_freeSpinsLeftCount = data.freespin.freeSpinsLeftCount -- fs 剩余次数
        self.m_runSpinResultData.p_fsMultiplier = data.freespin.fsMultiplier -- fs 当前轮数的倍数
        self.m_runSpinResultData.p_freeSpinNewCount = data.freespin.freeSpinNewCount -- fs 增加次数
        self.m_runSpinResultData.p_fsWinCoins = data.freespin.fsWinCoins -- fs 累计赢钱数量
        self.m_runSpinResultData.p_freeSpinAddList = data.freespin.freeSpinAddList
        self.m_runSpinResultData.p_newTrigger = data.freespin.newTrigger
        self.m_runSpinResultData.p_fsExtraData = data.freespin.extra
    end


    --插入freeSpin 事件
    local effectData = GameEffectData.new()
    effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    --播放事件
    self:playGameEffect()
end
---------------------------------弹版----------------------------------
function CodeGameScreenFishManiaMachine:isOpenBonusView()
    return nil~=self.m_bonusOverView
end
function CodeGameScreenFishManiaMachine:insertBonusViewData(_shopIndex, _commodityIndex, _data)
    --[[
        _data = {
            winCoin = 0,
            commodityId = 1,
        }
    ]]
    local fishToy = self:fishToy_getOneFishToy(_shopIndex, _commodityIndex)
    if fishToy then
        _data.commodityId = fishToy.m_initData.commodityId
        table.insert(self.m_bonusViewData, _data)

        if not self:isOpenBonusView() then
            --先用空表赋值，占位
            self.m_bonusOverView = {}
            -- --禁用商店相关按钮
            -- self.m_shopBar:setIsCanTouch(false)
            self:showBonusOver()
        end
    end
end
function CodeGameScreenFishManiaMachine:showBonusOver()
    if #self.m_bonusViewData < 1 then
        return
    end

    local p_shopData = globalMachineController.p_fishManiaShopData
    local data = table.remove(self.m_bonusViewData, 1)
    local ownerlist={}
    ownerlist["m_lb_coins"] = util_formatCoins(data.winCoin, 50) 

    gLobalSoundManager:playSound("FishManiaSounds/FishMania_bonusOver_start.mp3")
    local view =  self:showDialog("BonusOver",ownerlist)
    self.m_bonusOverView = view

    -- 装饰品挂点添加
    local parent = view:findChild("item")
    local csbName = p_shopData:getFishToyCsdPath(data.commodityId)
    local fishToy = util_createAnimation(csbName)
    parent:addChild(fishToy)
    util_setCascadeOpacityEnabledRescursion(parent, true)
    -- 缩放调整
    local logo = fishToy:findChild("logo")
    local logoScale = p_shopData:getCommodityBonusOverScale(data.commodityId)
    logo:setScale(logoScale)
    --装饰品出现动画
    local updateFishToyState = function(_fun)
        --装饰品重置状态为初始状态 设置按钮出现，装饰品层级调高
        self:fishToy_playShowAnim(data.shopIndex, data.commodityType)
        -- self:setLayer_switchSetLayerShow(data.shopIndex, data.commodityType)
        -- self:setLayer_upDateLocalZOrder(data.shopIndex, data.commodityType)
        if _fun then
            self:levelPerformWithDelay(40/30 , function()
                _fun()
            end)
        end
    end

    view:setOverAniRunFunc(function()
        --更新顶部金钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,{coins = globalData.userRunData.coinNum, isPlayEffect = true})

        updateFishToyState(function()
            --还有排队的
            if #self.m_bonusViewData > 0 then
                --over时间线时间
                self:levelPerformWithDelay(60/60, function()
                    self.m_bonusOverView = nil
                    self:showBonusOver()
                end)
            else
                self.m_bonusOverView = nil
                --恢复商店相关按钮
                self.m_shopBar:setIsCanTouch(true)
                --没有排队的检测下是否有收集完成回调
                if nil ~= data.bonusViewOverFun then
                    data.bonusViewOverFun()
                end
            end
        end)
            
    end)
   
    return view
end

function CodeGameScreenFishManiaMachine:showSuperFreeSpinOver(num,coins,func)
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_superFree_over.mp3")
    
    local ownerlist={}
    ownerlist["m_lb_coins"]=coins
    ownerlist["m_lb_num"]=num
    local view = self:showDialog("SuperFreeSpinOver",ownerlist,func)

    return view
end

function CodeGameScreenFishManiaMachine:showSuperFreeSpinStart(func)
    local soundName = string.format("FishManiaSounds/FishMania_superFree_start%d.mp3", math.random(1,2))
    gLobalSoundManager:playSound(soundName)

    local ownerlist={}
    local view = self:showDialog("SuperFreeSpinStart",ownerlist,func)


    local p_shopData = globalMachineController.p_fishManiaShopData
    local curShopIndex = p_shopData:getShowIndex() 
    if 4 == curShopIndex then
        local selectIndex = p_shopData:getSelectIndex() 
        curShopIndex = curShopIndex - 1 + selectIndex
    end
    
    for _shopIndex=1,6 do
        local tip = view:findChild(string.format("not%d", _shopIndex))
        if tip then
            tip:setVisible(_shopIndex==curShopIndex)
        end
    end

    return view
end

--[[
    *****************  收集角标相关  *********************    
--]]
function CodeGameScreenFishManiaMachine:updateReelGridNode(node)
    -- 添加角标
    self:createSymbolCollectIcon(node)

    if self:getCurrSpinMode() == FREE_SPIN_MODE  then
        if self.m_bInSuperFreeSpin then
            self:updateWildMultLab(node )
            self:initSuperFreeSwitchWild(node)
        end
    else
        self:initLockMultWildSymbol(node, {playIdle = true})
    end
    
    self:initMultWildSymbol(node)
end

function CodeGameScreenFishManiaMachine:getRandomWildMult( )
    return math.random(1,10)
end

function CodeGameScreenFishManiaMachine:updateWildMultLab(_node )


    local symbolNode = _node
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    

    if _node.p_symbolType == self.SYMBOL_SCORE_WILD_MULT then
        
        local score = 1

        --判断是否为真实数据
        if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 

            --获取真实分数
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local wildChange = selfdata.wildChange
            if wildChange then
                score = wildChange[tostring(self:getPosReelIdx(iRow, iCol))]
            end
            
        else
            --随机分数
            score = self:getRandomWildMult( )
        end

        local lbl_score = symbolNode:getCcbProperty("m_lb_coins")
        if lbl_score then
            lbl_score:setString("X" .. score)
        end
    end

   


    
    

end

function CodeGameScreenFishManiaMachine:removeSymbolCollectIcon( _symbolNode )
    local iconNode = _symbolNode:getChildByName("fishCollectIcon")
    if iconNode then
        iconNode:removeFromParent()
    end
end

-- 播放脚标收集
function CodeGameScreenFishManiaMachine:playCollectIcon( )
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_collect_icon.mp3")

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local scoreList = selfdata.scoreList 
    local pickScore = selfdata.pickScore or 0

    scoreList = clone(scoreList)
    if scoreList and table_length(scoreList) > 0 then

        local endNode = self.m_shopBar:findChild("jinbi")
        if endNode then

            for k,v in pairs(scoreList) do
                local score = tonumber(v.score)
                local pos = tonumber(v.pos)
                --移除角标
                local fixPos = self:getRowAndColByPos(pos)
                local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_FIX_NODE_TAG) or self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if symbolNode then
                    self:removeSymbolCollectIcon(symbolNode)
                else
                    print(fixPos.iY , fixPos.iX)
                end
    
                local clipTarPos = util_getOneGameReelsTarSpPos(self, pos)
                local startPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
                local endPos = util_convertToNodeSpace(endNode,self)
                local iconNode =  util_createAnimation("FishMania_symbolCoin.csb")
                self:addChild(iconNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1 )
                iconNode:setPosition(startPos.x + ( 40 * self.m_machineRootScale ),startPos.y - (40 * self.m_machineRootScale))
                iconNode:setScale(self.m_machineRootScale)
                -- 拖尾粒子
                local tuowei = util_createAnimation("FishMania_shop_tuowei.csb")
                iconNode:addChild(tuowei, -1)
                local particle = tuowei:findChild("Particle_1")
                particle:setPositionType(0)
                particle:setDuration(-1)
                particle:stopSystem()
                particle:resetSystem()

                local lab = iconNode:findChild("num")
                if lab then
                    lab:setString(score)
                end

                iconNode:runCsbAction("actionframe")
                self:levelPerformWithDelay(15/60, function()
                    util_playMoveToAction(iconNode,18/60,endPos,function(  )
                        iconNode:findChild("Sprite_1"):setVisible(false)
                        particle:stopSystem()
                        self:levelPerformWithDelay(43/60, function()
                            iconNode:removeFromParent()
                        end)
                    end)
                end)
            end 

            self:levelPerformWithDelay(33/60, function()
                self.m_shopBar:playCollectAnim()
                globalMachineController.p_fishManiaShopData:setPickScore(pickScore, true)
            end)
        end
            
            
    end
end

function CodeGameScreenFishManiaMachine:playCommodityBuyTuowei(_startPos, _delayTime, _fun)
    local p_shopData = globalMachineController.p_fishManiaShopData
    local curShopIndex = p_shopData:getShowIndex()
    local fishBox = self.m_fishBoxItems[curShopIndex]
    local progressNode = fishBox:findChild("progress")
    local startNodePos = self:convertToNodeSpace(_startPos)
    local endPos = progressNode:getParent():convertToWorldSpace(cc.p(progressNode:getPosition()))
    local rotation = util_getAngleByPos(_startPos, endPos)
    local distance = math.sqrt( math.pow( _startPos.x - endPos.x ,2) + math.pow( _startPos.y - endPos.y,2 )) 


    local tuowei = util_createAnimation("FishMania_goumai_tuowei.csb")
    self:addChild(tuowei, 9999) 
    tuowei:setPosition(startNodePos)
    tuowei:setRotation(- rotation)
    local spriteWidth = 451
    local scale = distance / spriteWidth
    tuowei:setScaleX(scale)
    if distance < spriteWidth then
        tuowei:setScaleY(scale  * 1.5)
    end
    

    tuowei:runCsbAction("actionframe", false, function()
        tuowei:removeFromParent()
    end)

    self:levelPerformWithDelay(_delayTime, function()
        if _fun then
            _fun()
        end
    end)
end
---
-- 根据类型将节点放回到pool里面去
-- @param node 需要放回去的node ，在放回去时该清理的要清理完毕， 以免出现node 已经添加到了parent ，但是去除来后再addChild进去
--
function CodeGameScreenFishManiaMachine:pushSlotNodeToPoolBySymobolType(symbolType, node)

        self:removeSymbolCollectIcon( node ) 

        CodeGameScreenFishManiaMachine.super.pushSlotNodeToPoolBySymobolType(self,symbolType, node)
end

-- 创建角标Csb
function CodeGameScreenFishManiaMachine:createSymbolCollectIcon(_symbolNode )

    if self.p_isInitIcon then
        return
    end

    
    self:removeSymbolCollectIcon( _symbolNode )

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local scoreList = selfdata.scoreList 

    if scoreList and table_length(scoreList) > 0 then

        if _symbolNode.p_rowIndex and _symbolNode.p_cloumnIndex and _symbolNode:isLastSymbol() then

            local posIndex = self:getPosReelIdx(_symbolNode.p_rowIndex,_symbolNode.p_cloumnIndex)
            local score = nil
            
            for k,v in pairs(scoreList) do
                local pos = tonumber(v.pos)
                if posIndex == pos then
                    score = tonumber(v.score)
                    break
                end
            end

            if score then

                local iconNode = util_createAnimation("FishMania_symbolCoin.csb")
                iconNode:setName("fishCollectIcon")
                _symbolNode:addChild(iconNode,10)
                iconNode:setPosition( 40, -40 )

                
                local lab = iconNode:findChild("num")
                if lab then
                    lab:setString(score)
                end
            end
        end
        
    end
end

function CodeGameScreenFishManiaMachine:setMainUiViwible(_states )
    local reelNode = self:findChild("reelNode")
    if reelNode then
        reelNode:setVisible(_states)
    end
    self.m_slotFrameLayer:setVisible(_states)
    self.m_slotEffectLayer:setVisible(_states)
end

function CodeGameScreenFishManiaMachine:isSuperFreeSwitchWild(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_SUPERFREE_WILD_1 or 
        _symbolType == self.SYMBOL_SCORE_SUPERFREE_WILD_2 or 
        _symbolType == self.SYMBOL_SCORE_SUPERFREE_WILD_3 then

        return true
    end

    return false
end

--[[
    事件通知
]]
function CodeGameScreenFishManiaMachine:noticCallBack_changePickScore(params)

    self:shopBar_jumpConis()
    self:shopBar_upDateShopBuyState()
    -- 修改为购买引导
    -- self:shopBar_playFingerTipAnim()
    --商店打开的话刷新一下
    if self.m_shopListView.m_closeOrOpen then
        self.m_shopListView:updateGoodsAtPageIndex(self.m_shopListView.m_currPageIdex)
    end
end
function CodeGameScreenFishManiaMachine:noticCallBack_changeTotalBet()
    local curTotalBet = globalData.slotRunData:getCurTotalBet( )

    -- 不同的bet切换才刷新框
    if self.m_curTotalBet ~=  curTotalBet  then
        --刷新轮盘
        self:upDateReelLockWild(curTotalBet)
        --停止连线
        self:clearWinLineEffect()

        self.m_curTotalBet = curTotalBet
    end
end
function CodeGameScreenFishManiaMachine:noticCallBack_fishBoxItemClick(_params)
    local shopIndex = _params[1]
    self:changeFishBoxTipShow(shopIndex)
    --
    self:fishBoxClickChangeBg(shopIndex)
end

--[[
    滑动背景
]]
--左右滑动切换背景和商店
function CodeGameScreenFishManiaMachine:onFishTankClick(_sender)
    if self.m_gameBgMoveHandler then
        return
    end

    local beginPos = _sender:getTouchBeganPosition()
    local endPos = _sender:getTouchEndPosition()
    local offPosX = endPos.x - beginPos.x
    if math.abs(offPosX) <= 5 then
        return
    end

    local p_shopData = globalMachineController.p_fishManiaShopData
    local offsetValue = offPosX > 0 and -1 or 1
    --当前展示的商店
    local curShowIndex = self.m_shopIndex 
    --当前收集的商店
    local curCollectIndex = p_shopData:getShowIndex()
    local nextShowIndex =  curShowIndex + offsetValue

    if 0 < nextShowIndex and nextShowIndex <= curCollectIndex then
        self:slideSwitchShopBg(nextShowIndex, function()
            local eventName = globalMachineController.p_fishManiaPlayConfig.EventName.UPDATE_MACHINE_FISH_TANK
            local data = {nextShowIndex}
            gLobalNoticManager:postNotification(eventName, data)
        end)
    end
end
--用滑动的方式切换背景展示
function CodeGameScreenFishManiaMachine:slideSwitchShopBg(_nextShopIndex, _fun, isOpen)
    local curShopIndex = self.m_shopIndex
    if curShopIndex == _nextShopIndex then
        if _fun then
            _fun()
        end
        return
    end

    -- 拍照按钮 处理
    local shopIndex = globalMachineController.p_fishManiaShopData:getShowIndex()
    if _nextShopIndex <= shopIndex then
        self:showShareBtn()
    else
        if isOpen then
            self:showShareBtn()
        else
            self.m_shareBtn:setVisible(false)
        end
        
    end

    --商店打开的话滑动一下
    if self.m_shopListView.m_closeOrOpen and _nextShopIndex ~= self.m_shopListView.m_currPageIdex then
        self.m_shopListView:setPageIndex(_nextShopIndex, true, false)
    end
    

    self.m_otherGameBg:setVisible(true)
    
    --背景
    local curShopBg = self:getShopBgNode(curShopIndex)
    local nextShopBg = self:getShopBgNode(_nextShopIndex, self.m_otherGameBg)
    self:changOtherGameBgShow(_nextShopIndex)
    --鱼池
    local curFishToyView = self.m_fishToyViews[curShopIndex]
    local nextFishToyView = self.m_fishToyViews[_nextShopIndex]
    self:updateFishToyForIndex(_nextShopIndex)
    --移动方向
    local offsetValue = _nextShopIndex < curShopIndex and 1 or -1

    local curBgPosX = curShopBg:getPositionX()
    local bgWidth = curShopBg:getContentSize().width * curShopBg:getScaleX()
    local nextBgPosX = bgWidth * -offsetValue
    nextShopBg:setPositionX(nextBgPosX)
    nextFishToyView:setPositionX(nextBgPosX)

    self:clearBgMoveHandler()
    local borderX = bgWidth/2 * offsetValue
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_gameBg_move.mp3")
    self.m_gameBgMoveHandler = scheduler.scheduleUpdateGlobal(function()
        local moveSpeed = bgWidth/60 / self.m_moveBgTime  --时间变量后期可修改 
        local moveDistance = moveSpeed * offsetValue
        local nextMovePosX = curShopBg:getPositionX() + moveDistance
        if math.abs(nextMovePosX) < bgWidth then
            curShopBg:setPositionX(nextMovePosX)
            curFishToyView:setPositionX(nextMovePosX)
            --
            nextMovePosX = curShopBg:getPositionX() + (-offsetValue * bgWidth)
            nextShopBg:setPositionX(nextMovePosX)
            nextFishToyView:setPositionX(nextMovePosX)
        else
            nextMovePosX = borderX

            curFishToyView:setVisible(false)
            self.m_otherGameBg:setVisible(false)

            curShopBg:setPositionX(0)
            curFishToyView:setPositionX(0)

            nextFishToyView:setPositionX(0)
        end

        if nextMovePosX == borderX then
            self:clearBgMoveHandler()

            if _fun then
                _fun()
            end
        end
    end)
end
--停止滑动切换，由外部直接切换
function CodeGameScreenFishManiaMachine:stopSlideSwitchShopBg()
    if not self.m_gameBgMoveHandler then
        return
    end

    local p_shopData = globalMachineController.p_fishManiaShopData
    local maxPageCount = p_shopData:getShopPageCount() 

    self:clearBgMoveHandler()
    self.m_otherGameBg:setVisible(false)

    for _shopIndex=1,maxPageCount-1 do
        self:getShopBgNode(_shopIndex):setPositionX(0)
    end
    for _shopIndex=1,maxPageCount do
        self.m_fishToyViews[_shopIndex]:setPositionX(0)
    end
end
function CodeGameScreenFishManiaMachine:clearBgMoveHandler()
    if self.m_gameBgMoveHandler then
        scheduler.unscheduleGlobal(self.m_gameBgMoveHandler)
        self.m_gameBgMoveHandler = nil
    end
end
function CodeGameScreenFishManiaMachine:getGameBgMoveState()
    if nil ~= self.m_gameBgMoveHandler then
        return true
    end

    return false
end

function CodeGameScreenFishManiaMachine:changOtherGameBgShow(_shopIndex)
    local p_shopData = globalMachineController.p_fishManiaShopData
    local maxPageCount = p_shopData:getShopPageCount()
    for _pageIndex=1,maxPageCount do
        if _pageIndex ~= maxPageCount or _shopIndex == maxPageCount then
            local shopBgNode = self:getShopBgNode(_pageIndex, self.m_otherGameBg)
            shopBgNode:setVisible( _pageIndex == _shopIndex )
        end
    end
end
---
-- 初始化上次游戏状态数据
--
function CodeGameScreenFishManiaMachine:initGameStatusData(gameData)

    if gameData.gameConfig ~= nil  then
        --商店购买数据
        if gameData.gameConfig.extra ~= nil  then
            globalMachineController.p_fishManiaShopData:parseShopData(gameData.gameConfig.extra)
        else
            --bugly: 商店数据不存在
            local msg = cjson.encode(gameData)
            release_print(msg)
        end

        --bet列表
        if gameData.gameConfig.bets ~= nil then
            self:initLockWildBetList(gameData.gameConfig.bets)
        end
    end
    --商店积分  先取special，如果special没有再取spin
    local pickScore = 0
    if gameData.special and gameData.special.selfData and gameData.special.selfData.pickScore then
        pickScore = gameData.special.selfData.pickScore
    elseif gameData.spin and gameData.spin.selfData and gameData.spin.selfData.pickScore then
        pickScore = gameData.spin.selfData.pickScore
    end
    globalMachineController.p_fishManiaShopData:setPickScore(pickScore)

    if gameData.special and gameData.spin then
        -- 一些数据优先使用 special 的
        local specialData = gameData.special
        local spinData = gameData.spin
        if specialData.avgBet then
            spinData.avgBet = specialData.avgBet
        end
        if specialData.features then
            spinData.features = specialData.features
        end
        if specialData.freespin then
            spinData.freespin = specialData.freespin
        end
        --
        local specialSelfData = gameData.special.selfData
        local spinSelfData = gameData.spin.selfData
        if specialSelfData and spinSelfData then
            if nil~=specialSelfData.triggerSuperFree then
                spinSelfData.triggerSuperFree = specialSelfData.triggerSuperFree
            end
        end
    end
    CodeGameScreenFishManiaMachine.super.initGameStatusData(self,gameData)
end
--[[
    乘倍wild锁定玩法
]]
function CodeGameScreenFishManiaMachine:initLockWildBetList(_betList)
    --[[
        "30000" = {
            changeWildMap = {
                "0" = "95"
            }
        }
    ]]
    if nil ~= _betList then
        self.m_lockWildBet = _betList
    end
end
--保存数据至本地
function CodeGameScreenFishManiaMachine:setLockWildBetList(_betStr, _wildList)
    if not self.m_lockWildBet[_betStr] then
        self.m_lockWildBet[_betStr] = {}
    end

    self.m_lockWildBet[_betStr].changeWildMap = _wildList or {}
end
function CodeGameScreenFishManiaMachine:upDateReelLockWild(_newBet)
    --重置当前盘面所有乘倍wild
    local curWildList = {}

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do

            local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_FIX_NODE_TAG) or self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            --检测同一格子是否有层级更低的小块，
            if symbol and self:isLockMultiplyWildSymbol(symbol.p_symbolType) then
                --轮盘低层级小块 直接移除
                local reelSymbol = self:getReelGridNode(iCol, iRow)
                if reelSymbol and reelSymbol~=symbol then
                    reelSymbol:removeFromParent()
                    self:pushSlotNodeToPoolBySymobolType(reelSymbol.p_symbolType, reelSymbol)
                end
                --降低层级
                symbol.m_symbolTag = SYMBOL_NODE_TAG
                symbol.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                symbol.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                symbol.p_preLayerTag = symbol.p_layerTag
                symbol:setTag(self:getNodeTag(symbol.p_cloumnIndex, symbol.p_rowIndex, symbol.m_symbolTag))

                --存wild位置并替换为随机小块
                --存一下
                local posData = (self.m_iReelRowNum-symbol.p_rowIndex) * self.m_iReelColumnNum + (symbol.p_cloumnIndex-1)
                curWildList[string.format("%d",posData)] = string.format("%d",symbol.p_symbolType)
                -- 拿个随机信号(不能是wild,scatter)
                -- local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex( symbol.p_cloumnIndex )
                -- local symbolType = symbol.p_symbolType
                -- while self:isLockMultiplyWildSymbol(symbolType) or 
                --         self:isSuperFreeSwitchWild(symbolType) or
                --         symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  do

                --     symbolType = self:getRandomReelType(symbol.p_cloumnIndex, reelDatas)
                -- end
                -- 第一四行拿 H1 ，第二三行拿 wild
                local initDatas = self.m_configData:getInitReelDatasByColumnIndex(symbol.p_cloumnIndex)
                local symbolType = initDatas[symbol.p_rowIndex]
                self:changeOneSymbol(symbol, symbolType)
            end
        end
    end

    -- --保存数据至本地
    -- if _isBetChange then
    --     local curBetStr = string.format("%d", self.m_curTotalBet)
    --     if table_length(curWildList) > 0 then
    --         self.m_lockWildBet[curBetStr] = {
    --             changeWildMap = curWildList
    --         }
    --     else
    --         self.m_lockWildBet[curBetStr] = nil
    --     end
    -- end
    
    --展示新bet的所有乘倍wild
    -- local betStr = string.format("%d", _newBet)
    local betStr = tostring(toLongNumber(_newBet))
    local newWildList = self.m_lockWildBet[betStr] and self.m_lockWildBet[betStr].changeWildMap or {}
    for _posData,_symbolType in pairs(newWildList) do
        local posDataValue = tonumber(_posData)
        local symbolType = tonumber(_symbolType)

        local fixPos = self:getRowAndColByPos(posDataValue)
        local iCol,iRow = fixPos.iY,fixPos.iX
        local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_FIX_NODE_TAG) or self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        if not symbol then
            symbol = self:getReelGridNode(iCol, iRow)
        end

        if symbol then
            if symbolType == self.SYMBOL_SCORE_WILD_1 then
                symbol.m_symbolTag = SYMBOL_NODE_TAG
                symbol.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                symbol.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            else
                symbol.m_symbolTag = SYMBOL_FIX_NODE_TAG
                symbol.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                symbol.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            end
            symbol.p_preLayerTag = symbol.p_layerTag
            symbol:setTag(self:getNodeTag(symbol.p_cloumnIndex, symbol.p_rowIndex, symbol.m_symbolTag))
            
            self:changeOneSymbol(symbol, symbolType)
            self:initLockMultWildSymbol(symbol, {playIdle = true})
        end
    end
end

function CodeGameScreenFishManiaMachine:isLockMultiplyWildSymbol(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_WILD_1 or   
        _symbolType == self.SYMBOL_SCORE_WILD_2 or
        _symbolType == self.SYMBOL_SCORE_WILD_3 then

        return true
    end

    return false
end

function CodeGameScreenFishManiaMachine:isMultiplyWildSymbol(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_WILD_MULT then
        return true
    end

    return false
end

--[[
    一些特殊的信号需要在加载时做一些特殊操作
]]
--superFree模式的变换wild
function CodeGameScreenFishManiaMachine:initSuperFreeSwitchWild(_symbol)
    if not self:isSuperFreeSwitchWild(_symbol.p_symbolType) then
        return
    end

    if _symbol.p_symbolImage ~= nil and _symbol.p_symbolImage:getParent() ~= nil then
        _symbol.p_symbolImage:removeFromParent()
        _symbol.p_symbolImage = nil
    end

    local lineName = "actionframe_wild"
    local idleName = "idleframe_wild"
    _symbol:setLineAnimName(lineName)
    _symbol:setIdleAnimName(idleName)

    _symbol:runIdleAnim()
end
--锁定的乘倍wild
function CodeGameScreenFishManiaMachine:initLockMultWildSymbol(_symbolNode, _params)
    if not self:isLockMultiplyWildSymbol(_symbolNode.p_symbolType) then
        return
    end
    local playIdle = true == _params.playIdle
    
    local index = _symbolNode.p_symbolType + 1 - self.SYMBOL_SCORE_WILD_1
    local lineName = string.format("actionframe%d", index)
    local idleName = string.format("idleframe%d", index)
    _symbolNode:setLineAnimName(lineName)
    _symbolNode:setIdleAnimName(idleName)

    if playIdle then
        _symbolNode:runIdleAnim()
    end
end
--普通乘倍wild
function CodeGameScreenFishManiaMachine:initMultWildSymbol(_symbolNode)
    if not self:isMultiplyWildSymbol(_symbolNode.p_symbolType) then
        return
    end
    _symbolNode:checkLoadCCbNode()

    local spineParent = _symbolNode:getCcbProperty("spineNode")
    if spineParent then
        local spineName = "Socre_FishMania_Wild"
        local spine = spineParent:getChildByName(spineName)
        if not spine then
            spine = util_spineCreate(spineName,true,true)
            spineParent:addChild(spine)
            spine:setName(spineName)
        end
         --挂载父节点 播放连线时，自己也播一下连线, 其他时间线播idleframe
         _symbolNode:registerAniamCallBackFun(function(_slotsNode)
            if "actionframe" == _symbolNode.m_currAnimName then
                util_spinePlay(spine, "actionframe2")
            else
                util_spinePlay(spine, "idleframe")
            end
        end)
    end
end
--[[
    界面装饰品相关
]]
function CodeGameScreenFishManiaMachine:fishToyView_initFishToys()
    for i,v in ipairs(self.m_fishToyViews) do
        v:initFishToys()
    end
end
-- 切换设置按钮的展示位置 --@ _commodityType，_commodityIndex(二选一传入，都不传则隐藏对应图层所有设置按钮)
function CodeGameScreenFishManiaMachine:setLayer_switchSetLayerShow(_shopIndex, _commodityType, _commodityIndex)
    local commodityIndex = _commodityIndex or globalMachineController.p_fishManiaShopData:getCommodityIndex(_shopIndex, _commodityType)

    local fishToyView = self.m_fishToyViews[_shopIndex]
    if fishToyView then
        for _index,_fishToy in pairs(fishToyView.m_fishToys) do
            if _index == commodityIndex then
                _fishToy:setVisible(true)
                _fishToy:setLayer_upDateScaleBtnEnable()
                _fishToy:setLayer_changeVisible(true)
                _fishToy:playFishToyMoveAction()
                
            else
                _fishToy:setLayer_changeVisible(false)
            end
        end
    end

end
--将触摸的装饰品提层至最高
function CodeGameScreenFishManiaMachine:setLayer_upDateLocalZOrder(_shopIndex, _commodityType, _commodityIndex)
    local p_shopData = globalMachineController.p_fishManiaShopData
    local commodityIndex = _commodityIndex or p_shopData:getCommodityIndex(_shopIndex, _commodityType)
    local fishToyView = self.m_fishToyViews[_shopIndex]

    if fishToyView then
        -- 界面装饰品层级重新排序 -> 单独将触摸装饰品层级调味料最高
        local sortList = {}
        for i,v in ipairs(fishToyView.m_fishToys) do
            sortList[i] = v
        end
        table.sort(sortList, function(a, b)
            if commodityIndex ~= a.m_initData.commodityIndex and commodityIndex ~= b.m_initData.commodityIndex then
                local order_a = a:getLocalZOrder()
                local order_b = b:getLocalZOrder()
                if order_a ~= order_b then
                    return order_a > order_b
                end

                local index_a = a.m_initData.commodityIndex
                local index_b = b.m_initData.commodityIndex

                return index_a > index_b
            else
                return commodityIndex == a.m_initData.commodityIndex
            end
            return false
        end)
        for i,v in ipairs(sortList) do
            v:setLocalZOrder(#sortList - i)
        end
    end
end

function CodeGameScreenFishManiaMachine:setLayer_upDateRecoveryBtnEnable(_enable)
    for _shopIndex,_fishToyView in ipairs(self.m_fishToyViews) do
        for _index,_fishToy in pairs(_fishToyView.m_fishToys) do
            _fishToy:setLayer_upDateRecoveryBtnEnable(_enable)
        end
    end
end

function CodeGameScreenFishManiaMachine:fishToy_playShowAnim(_shopIndex, _commodityType, _commodityIndex)
    local commodityIndex = _commodityIndex or globalMachineController.p_fishManiaShopData:getCommodityIndex(_shopIndex, _commodityType)
    local fishToyView = self.m_fishToyViews[_shopIndex]
    if fishToyView then
        gLobalSoundManager:playSound("FishManiaSounds/FishMania_fishToy_show.mp3")

        local fishToy = fishToyView.m_fishToys[commodityIndex] 
        fishToy:setVisible(true) 
        fishToy:reSetFishToyState()   
        fishToy:runAnim("show", false, function()
            fishToy:runAnim("actionframe2", true)
            --出现完毕后播放一下自由移动
            fishToy:playFishToyMoveAction()
        end)
    end
end
function CodeGameScreenFishManiaMachine:fishToy_flyToShop(_fishToy)
    local endWorldPos = self.m_shopBar:getShopLogoWorldPos()
    local endNodePos = _fishToy:getParent():convertToNodeSpace(endWorldPos)
    local time = 0.5
    local act_moveTo = cc.MoveTo:create(time, endNodePos)
    local act_scaleTo = cc.ScaleTo:create(time, 0.2)
    local act_callFun = cc.CallFunc:create(function()
        _fishToy:setVisible(false)
        _fishToy:reSetFishToyState()
        _fishToy:setLayer_upDateScaleBtnEnable()
        _fishToy:setIsCanTouch(true)

        --更新状态
        local p_shopData = globalMachineController.p_fishManiaShopData
        local fishToyData = _fishToy:getFishToyData()
        local data = {
            shopIndex = fishToyData.shopIndex,
            commodityId = fishToyData.commodityId,
            --
            state = p_shopData.COMMODITYSTATE.NOTSET,
        }
        p_shopData:upDateCommodityCash(data)
        
        if not self.m_shopListView:isVisible() then
            --跳转到当前装饰品的界面
            if self.m_shopBar.m_isCanTouch and self:getCurrSpinMode() ~= AUTO_SPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                self.m_shopListView:showShopListView()
                self.m_shopListView:setPageIndex(fishToyData.shopIndex, true)
            end

        else
            self.m_shopListView:setPageIndex(fishToyData.shopIndex, true)
        end
        
        
    end)

    local action = cc.Sequence:create(cc.Spawn:create(act_moveTo, act_scaleTo), act_callFun)
    _fishToy:runAction(action)
end

--获取一个装饰品
function CodeGameScreenFishManiaMachine:fishToy_getOneFishToy(_shopIndex, _commodityIndex)
    local fishToy = nil

    local fishToyView = self.m_fishToyViews[_shopIndex]
    if fishToyView then
        fishToy = fishToyView.m_fishToys[_commodityIndex]
    end

    return fishToy
end

--[[
    鱼缸相关
]]
function CodeGameScreenFishManiaMachine:fishBox_upDateSelectState()
    if self.m_fishBoxItems then
        local curShopIndex = globalMachineController.p_fishManiaShopData:getShowIndex()
        for _shopIndex,_fishBox in ipairs(self.m_fishBoxItems) do
            _fishBox:upDateSelectState(curShopIndex == _shopIndex)
            self:fishBox_upDateFishBoxShow(_shopIndex)
        end
    end
end
function CodeGameScreenFishManiaMachine:fishBox_upDateFishBoxShow(_shopIndex)
    local fishBox = self.m_fishBoxItems[_shopIndex]
    if fishBox then
        fishBox:upDateFishBoxShow()
    end
end
function CodeGameScreenFishManiaMachine:fishBox_jumpBottomProgress(_shopIndex)
    local fishBox = self.m_fishBoxItems[_shopIndex]
    if fishBox then
        local p_shopData = globalMachineController.p_fishManiaShopData
        local progress = p_shopData:getShopProgress(_shopIndex)
        fishBox:jumpBottomProgress(progress)
    end
end
function CodeGameScreenFishManiaMachine:fishBox_playUnLockAnim(_shopIndex, _fun)
    local fishBox = self.m_fishBoxItems[_shopIndex]
    if fishBox then
        fishBox:playUnLockAnim(_fun)
    end
end
function CodeGameScreenFishManiaMachine:fishBox_playCollectFinishAnim(_shopIndex, _fun)
    local fishBox = self.m_fishBoxItems[_shopIndex]
    if fishBox then
        fishBox:playCollectFinishAnim(_fun)
    end
end
--[[
    商店相关
]]
--购买装饰品后刷新展示
function CodeGameScreenFishManiaMachine:shopBar_buyUpDateShow(_data, _param)
    --[[
        _data = {
            pickScore = selfData.pickScore,
            avgBet    = selfData.avgBet,
            triggerSuperFreeSpin = selfData.triggerSuperFreeSpin,
            --
            winCoin = self.m_serverWinCoins,
            shopIndex = self.m_buyData.shopIndex,
            commodityType = self.m_buyData.commodityType,
            startPos = startPos,
    }
    ]]
    local p_shopData = globalMachineController.p_fishManiaShopData
    --刷数据 使用数据变更的事件通知金币刷新
    p_shopData:buyUpDateShopData(_data)
    local commodityIndex = p_shopData:getCommodityIndex(_data.shopIndex, _data.commodityType)
    local bonusData = {
        shopIndex = _data.shopIndex,
        commodityType = _data.commodityType,
        winCoin = _data.winCoin,
    }
    --购买音效 区分 鱼 和非鱼
    if p_shopData:isFish(_data.commodityType) then
        gLobalSoundManager:playSound("FishManiaSounds/FishMania_shopList_buy_fish.mp3")
    else
        local soundName = string.format("FishManiaSounds/FishMania_shopList_buy_%d.mp3", math.random(1,2))
        gLobalSoundManager:playSound(soundName)
    end
    
    
    
    --是否触发SuperFree
    self.m_avgBet = _data.avgBet
    self.m_bInSuperFreeSpin = _data.triggerSuperFree
    local triggerSuperFree = self.m_bInSuperFreeSpin
    if self.m_bInSuperFreeSpin then
        bonusData.bonusViewOverFun = function()
            self:triggerBonusSuperFree(_param)
        end
    end

    local progress = p_shopData:getShopProgress(_data.shopIndex)
    --飞行 -> 鱼缸进度条(0.5s) -> 完成动画/装饰品出现(40/30) -> bonusOver弹板  版本1
    --飞行 -> 鱼缸进度条(0.5s) -> bonusOver弹板 -> 完成动画/装饰品出现(40/30)  版本2
    self:playCommodityBuyTuowei(_data.startPos, 40/60, function()
        
        self:fishBox_jumpBottomProgress(_data.shopIndex)
        --0.5s 跳动时间 + 0.5 弹板间隔
        self:levelPerformWithDelay(0.5+0.5, function()
            --清理商店的购买数据
            self.m_shopListView.m_buyData = nil

            --收集完成
            if progress >=1 then
                gLobalSoundManager:playSound("FishManiaSounds/FishMania_fishBox_collectFinish.mp3")
                self:fishBox_playCollectFinishAnim(_data.shopIndex, function()
                    --bonus弹板数据
                    self:insertBonusViewData(_data.shopIndex, commodityIndex, bonusData)
                end)
            else
                --bonus弹板数据
                self:insertBonusViewData(_data.shopIndex, commodityIndex, bonusData)
            end

        end)
       
    end)
end

function CodeGameScreenFishManiaMachine:shopBar_upDateShopBuyState()
    self.m_shopBar:upDateShopBuyState()
end

function CodeGameScreenFishManiaMachine:shopBar_playFingerTipAnim()
    local p_shopData = globalMachineController.p_fishManiaShopData
    --手指指引 没有购买任何商品 且当前不在打开商店状态 播放引导动效
    local bCanBuy = p_shopData:getShopIsCanBuy()
    local curSpend,allSpend = p_shopData:getShopSpend(1) 
    local isOpenShop = self.m_shopListView.m_closeOrOpen
    if bCanBuy and curSpend <= 0 and not isOpenShop then
        self.m_shopBar:playFingerTipAnim()
    end
end
--直接刷新商店积分
function CodeGameScreenFishManiaMachine:shopBar_updateCoins(coins)
    if not coins then
        coins = globalMachineController.p_fishManiaShopData:getPickScore()
    end

    self.m_shopBar:updateCoins(coins)
end
--积分跳动
function CodeGameScreenFishManiaMachine:shopBar_jumpConis(coins)
    if not coins then
        coins = globalMachineController.p_fishManiaShopData:getPickScore()
    end

    self.m_shopBar:jumpConis(coins)
end

-- 打开自由商店选择界面
function CodeGameScreenFishManiaMachine:openSelectShopView()
    local p_shopData = globalMachineController.p_fishManiaShopData

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local data = {
        shopIndex = selfdata.shopIndex,
        selectSuperFree = selfdata.selectSuperFree,
    }
    p_shopData:parseShopData(data)

    local shopIndex = p_shopData:getShowIndex()
    local selectIndex = p_shopData:getSelectIndex()
    
    if 4 == shopIndex and 0 == selectIndex then

        local view = util_createView("CodeFishManiaSrc.FishManiaSelectShopView", {self})
        if globalData.slotRunData.machineData.p_portraitFlag then
            view.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalViewManager:showUI(view)

    end
end
--[[
    superFree角色相关
]]
function CodeGameScreenFishManiaMachine:showSuperFreeBgEffect()
    self.m_superFreeEffect:setVisible(true)
    self.m_superFreeEffect:runCsbAction("actionframe",true)
end
function CodeGameScreenFishManiaMachine:showSuperFreeJuese()
    self.m_superFreeJuese:setVisible(true)

    -- actionframe
    local playSpineAnim = function(_spineNode, _animName, _fun)
        util_spinePlay(_spineNode, _animName, false)
        util_spineEndCallFunc(_spineNode, _animName, _fun)
    end
    -- idleframe
    local playSpineIdleAnim = function(_idleIndex, _p_loopFun)
        if not self.m_superFreePlayFlag then
            return
        end
        local animName = ""
        if _idleIndex <=1 then
            animName = "idleframe"
        else
            animName = string.format("idleframe%d", _idleIndex) 
        end
        util_spinePlay(self.m_superFreeJuese, animName, false)
        util_spineEndCallFunc(self.m_superFreeJuese, animName, function()
            _idleIndex = _idleIndex < 3 and _idleIndex+1 or 1
            _p_loopFun(_idleIndex, _p_loopFun)
        end)
    end
    local loopPlayIdle = function()
        self.m_superFreePlayFlag = true
        playSpineIdleAnim(1, playSpineIdleAnim)
    end

    --1.
    playSpineAnim(self.m_superFreeJuese, "actionframe", function()
        --2
        playSpineAnim(self.m_superFreeJuese, "actionframe2", function()
            --3
            loopPlayIdle()
        end)
    end)
end
function CodeGameScreenFishManiaMachine:hideSuperFreeJuese()
    self.m_superFreePlayFlag = false

    util_setCsbVisible(self.m_superFreeEffect, false)
    self.m_superFreeJuese:setVisible(false)
end


function CodeGameScreenFishManiaMachine:levelPerformWithDelay(_time, _fun)
    if not self.m_waitNode then
        self.m_waitNode = cc.Node:create()
        self:addChild(self.m_waitNode)
    end

    performWithDelay(self.m_waitNode,function()

        _fun()

    end, _time)
end

-- ====================================================================================  一些特殊需求重写父类接口
-- 区分 free 和 superFree 音乐
function CodeGameScreenFishManiaMachine:getFreeSpinMusicBG()
    if self.m_bInSuperFreeSpin then
        return "FishManiaSounds/FishMania_musicSuperFsBg.mp3"
    else
        return self.m_fsBgMusicName
    end
end
--解决free中固定wild参与连线后，在下次滚动钱时间线被还原的问题
function CodeGameScreenFishManiaMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent,lineNode,nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)

                --!!! 处于普通fs模式且不为最后一次时 wild连线信号可恢复为 idle
                if (self:getCurrSpinMode() ~= FREE_SPIN_MODE or self.m_bInSuperFreeSpin or 0 == self.m_runSpinResultData.p_freeSpinsLeftCount)or 
                    lineNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    
                    lineNode:runIdleAnim()
                end
                
            end
        end
    end
end
-- 解决固定wild播放动画时机问题
function CodeGameScreenFishManiaMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end
    --!!! 21.08.17 不需要重置
    -- if self.m_bProduceSlots_InFreeSpin and not self.m_bInSuperFreeSpin then
    --     self:playFreeLockWildIdlefraem(false)
    -- end
    

    self:showLineFrame()
    --!!!新增
    local nextFun = function()
        if self.m_playFreeLockWildFlag then
            self.m_playFreeLockWildFlag = false

            self:playFreeLockWildAnim(true, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            nextFun()
        end, 0.5)
    else
        nextFun()
    end

    return true

end

-- 解决落地动画
function CodeGameScreenFishManiaMachine:playCustomSpecialSymbolDownAct( slotNode )
    CodeGameScreenFishManiaMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    if self:isLockMultiplyWildSymbol(slotNode.p_symbolType) then

        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,"FishManiaSounds/FishMania_redWild_down.mp3","LockMultiplyWildSymbol" )
        else
            gLobalSoundManager:playSound("FishManiaSounds/FishMania_redWild_down.mp3")
        end
        
        slotNode:runAnim("buling")
    end
end
-- 解决落地音效
function CodeGameScreenFishManiaMachine:setScatterDownScound()
    for i = 1, 5 do
        -- local scatterSound = string.format("FishManiaSounds/FishMania_scatter_down%d.mp3", i)
        -- self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = scatterSound
        local scatterSound = "FishManiaSounds/FishMania_scatter_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = scatterSound
    end
end

-- 解决返回出来的小块不是我需要的对应层级的小块
function CodeGameScreenFishManiaMachine:getFixSymbol(iCol, iRow, iTag)
    local fixSp = BaseSlotoManiaMachine.getFixSymbol(self,iCol, iRow, iTag)
    --拿高层小块拿不到时不去下面找, 低层级小块拿不到时从新滚动里面找
    if not fixSp and iTag == SYMBOL_NODE_TAG then
    -- if not fixSp then
        fixSp = self:getReelGridNode(iCol,iRow)
    end
    return fixSp
end

--两种模式的Free计数栏
function CodeGameScreenFishManiaMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar or not self.m_superFreeSpinBar then
        return
    end

    self.m_baseFreeSpinBar:setVisible(not self.m_bInSuperFreeSpin)
    self.m_superFreeSpinBar:setVisible(self.m_bInSuperFreeSpin)
end
function CodeGameScreenFishManiaMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar or not self.m_superFreeSpinBar then
        return
    end

    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    util_setCsbVisible(self.m_superFreeSpinBar, false)
end
function CodeGameScreenFishManiaMachine:freeBar_changeFreeSpinByCount()
    if not self.m_baseFreeSpinBar or not self.m_superFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:changeFreeSpinByCount()
    self.m_superFreeSpinBar:changeFreeSpinByCount()
end
--大赢结束事件
function CodeGameScreenFishManiaMachine:isHasBigWin()
    local bool = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            
        bool = true
    end

    return bool
end

function CodeGameScreenFishManiaMachine:showEffect_NewWin(effectData,winType)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    --!!!
    local selfFun = function()
        if self.m_openSelectViewFlag then
            self.m_openSelectViewFlag = false

            if self.m_superfreeBigWinPaiZhao then
                self.m_superfreeBigWinPaiZhao = false
                -- superfree 结束引导拍照
                self.m_paisheEffect:setVisible(true)
                gLobalSoundManager:playSound("FishManiaSounds/FishMania_share_paizhao.mp3")
                self:showShareZheZhao()
                self.m_paisheEffect:runCsbAction("actionframe",false,function()
                    self:screenShotFishToy(function()
                        local p_shopData = globalMachineController.p_fishManiaShopData
                        local shopIndex = p_shopData:getShowIndex()
                        -- self:updateFishToyForIndex(shopIndex)
                        -- self:checkSwitchBg()
                        local nextShopIndex = shopIndex ~= 4 and shopIndex+1 or shopIndex
                        self:slideSwitchShopBg(nextShopIndex, function()
                            -- local eventName = globalMachineController.p_fishManiaPlayConfig.EventName.UPDATE_MACHINE_FISH_TANK
                            -- local data = {nextShopIndex}
                            -- gLobalNoticManager:postNotification(eventName, data)

                            self:checkSwitchBg()

                            self:checkSwitchFishBox(function()
                                self:openSelectShopView()
                            end)
                        end,true)
                        
                    end)
                end)
            else
                local p_shopData = globalMachineController.p_fishManiaShopData
                local shopIndex = p_shopData:getShowIndex()
                self:updateFishToyForIndex(shopIndex)
                self:checkSwitchBg()
                
                self:checkSwitchFishBox(function()
                    self:openSelectShopView()
                end)
            end

        elseif self.m_shopGuideFlage then
            self:addShopGuideEffect()
            if not self.m_isRunningEffect then
                self:playGameEffect()
            end
        end

    end

    local bigMegaWin = util_createView("views.bigMegaWin.BigWinBg",winType)
    bigMegaWin:initViewData(self.m_llBigOrMegaNum,winType,
        function()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_OVER_BIGWIN_EFFECT,{winType = winType})

            -- cxc 2023年11月30日15:02:44  spinWin 需要监测弹（评分，绑定fb, 打开推送）
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("SpinWin", "SpinWin_" .. winType)
            if view then
                view:setOverFunc(function()
                    if not tolua.isnull(self) then
                        if self.playGameEffect then
                            selfFun()

                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    end
                end)
            else
                selfFun()

                effectData.p_isPlay = true
                self:playGameEffect()
            end
            
        end)
    gLobalViewManager:showUI(bigMegaWin)

end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenFishManiaMachine:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --!!! superFree假滚修改
        if self.m_bInSuperFreeSpin then
            reelDatas = self:getSuperFreeReelDatas(parentData)
        else
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        end
        
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas

end
function CodeGameScreenFishManiaMachine:getSuperFreeReelDatas(_parentData)
    local p_shopData = globalMachineController.p_fishManiaShopData

    local reelDatas = nil
    reelDatas = clone(self.m_configData:getFsReelDatasByColumnIndex(1, _parentData.cloumnIndex)) 

    local replaceList = {
        [1] = {
            [TAG_SYMBOL_TYPE.SYMBOL_SCORE_7] = self.SYMBOL_SCORE_SUPERFREE_WILD_3,
        },
        [2] = {
            [TAG_SYMBOL_TYPE.SYMBOL_SCORE_8] = self.SYMBOL_SCORE_SUPERFREE_WILD_2,
            [TAG_SYMBOL_TYPE.SYMBOL_SCORE_7] = self.SYMBOL_SCORE_SUPERFREE_WILD_3,
        },
        [3] = {
            [TAG_SYMBOL_TYPE.SYMBOL_SCORE_9] = self.SYMBOL_SCORE_SUPERFREE_WILD_1,
            [TAG_SYMBOL_TYPE.SYMBOL_SCORE_8] = self.SYMBOL_SCORE_SUPERFREE_WILD_2,
            [TAG_SYMBOL_TYPE.SYMBOL_SCORE_7] = self.SYMBOL_SCORE_SUPERFREE_WILD_3,
        },
    }
    --当前收集商店或者当前选择商店
    local shopIndex = p_shopData:getShowIndex()
    if shopIndex > 3 then
        shopIndex = p_shopData:getSelectIndex()
    end

    local replace = replaceList[shopIndex]

    for _index,_symbol in ipairs(reelDatas) do
        if  nil ~= replace[_symbol] then
            reelDatas[_index] = replace[_symbol]
        end
    end

    return reelDatas
end


function CodeGameScreenFishManiaMachine:firstSpinRestMusicBG( )
    
    if self.m_spinRestMusicBG  then
        --!!!
        --如果还在播放欢迎音效就停止
        if self.m_FishManiaPlayEnterMusic then
            self.m_FishManiaPlayEnterMusic = false
            if self.m_enterGameSoundId then
                gLobalSoundManager:stopAudio(self.m_enterGameSoundId)
                self.m_enterGameSoundId = nil
            end
        end

        self:resetMusicBg()
        self.m_spinRestMusicBG = false
    end

end
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
--@musicName 需要修改的音乐路径
-- 音效不希望在进入关卡时 发生进入关卡音乐和背景音乐一起播放的情况, 把其他活动弹板关闭恢复背景音乐时加判断
function CodeGameScreenFishManiaMachine:resetMusicBg(isMustPlayMusic,musicName)
    if self.m_FishManiaPlayEnterMusic then
        return
    end
    
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    self:resetCurBgMusicName(musicName)


    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
end

--[[
    发送后台日志重写的接口
]]
function CodeGameScreenFishManiaMachine:checkSpinError()
    return true
end

function CodeGameScreenFishManiaMachine:testView(str,str1 )
    
    local nowScene = cc.Director:getInstance():getRunningScene()
    if nowScene ~= nil  then
        local view = util_createView("views.logon.Logonfailure",false,true)
        nowScene:addChild(view,99999,99999)
        view:findChild("Logon_warning_2"):setVisible(false)
        view:findChild("lab_describ_1_1"):setString(str)
        view:findChild("lab_describ_2_1"):setString(str1)
    end
end

function CodeGameScreenFishManiaMachine:checkShareVersion( )
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios"  then
        supportVersion = "1.6.8"
    elseif platform == "android" then
        supportVersion = "1.6.0"
    elseif  platform == "mac" then
        supportVersion = "1.5.6"
    end
    if not util_isSupportVersion(supportVersion) then

        self:testView("util_isSupportVersion 版本号不对","" )
        return true
    end
end

function CodeGameScreenFishManiaMachine:screenShotFishToy(_func)

    -- 版本号检查
    if self:checkShareVersion( ) then
        return
    end
   
    if not  util_createTargetScreenSprite then
        -- 如果没有这个方法强制重新登录走热更
        if util_restartGame ~= nil then
            util_restartGame()
        end
        
        return
    end

    -- 暂停轮盘
    self:pauseMachine()

    local showNode = {}
    local childs = self:findChild("fishTank"):getParent():getChildren()
    for i, v in ipairs(childs) do
        if v:isVisible() then
            if v:getName() ~= "fishTank" and v:getName() ~= "gameBg" then
                v:setVisible(false)
                table.insert(showNode, v)
            end
        end
    end

    local fishTankPosX, fishTankPosY = self:findChild("fishTank"):getPosition()
    local height = 400 *  display.height / DESIGN_SIZE.height
    local rectPosY = fishTankPosY * display.height / DESIGN_SIZE.height
    local spr, rt = util_createTargetScreenSprite(self:findChild("fishTank"):getParent(), cc.rect(0, rectPosY-height/2,display.width, display.width*(453/590)))
    rt:retain()
    
    for i, v in ipairs(showNode) do
        v:setVisible(true)
    end
    
    local path =  "FishManiaShopShare.png"

    local releaseRtfunc = function (  )
        print("点击关闭")
        if tolua.isnull(rt) then
            rt:release()
        end
        --恢复轮盘
        self:resumeMachine()
        self.m_isClick = true

        self:showTipsOpenView()

        if _func then
            _func()
        end
    end

    local clickSave = function (  )
        print("点击保存")
        rt:saveToFile(path, true)

        releaseRtfunc()
    end
    
    local clickShare = function (  )
        print("点击分享")
        rt:saveToFileLua(path,true,function( fullPath )
            globalFaceBookManager:facebookSharePicture(fullPath, function( param  )
     
            end)
        end)

        releaseRtfunc()
    end

    local view = util_createView("CodeFishManiaSrc.FishMainaScreenShotFishToy")
    view:initViewData(spr, clickSave, clickShare, releaseRtfunc)
    gLobalViewManager:showUI(view)

    
end

function CodeGameScreenFishManiaMachine:showShareZheZhao( )
    local view = util_createView("CodeFishManiaSrc.FishMainaScreenZhezhao")
    gLobalViewManager:showUI(view)

    self:levelPerformWithDelay(75/60, function()
        view:clickCloseView()
    end)
end

-- 显示拍照按钮
function CodeGameScreenFishManiaMachine:showShareBtn( )
    self.m_shareBtn:setVisible(true)
    -- self.m_shareBtn:runCsbAction("over",false,function()
    --     self.m_shareBtn:runCsbAction("start",false,function()
            self.m_shareBtn:runCsbAction("idle",false)
    --     end)
    -- end)
    if self.m_shareBtnTips:isVisible() then
        self:showTipsOverView()
    end
end

--打开tips
function CodeGameScreenFishManiaMachine:showTipsOpenView( )
    self.m_shareBtnTips:setVisible(true)
    self.m_shareBtnTips:runCsbAction("start",false,function()
        self.m_shareBtnTips:runCsbAction("idle",true)
        self:levelPerformWithDelay(5, function()
            self:showTipsOverView()
        end)
    end)
    
end

--关闭tips
function CodeGameScreenFishManiaMachine:showTipsOverView( )

    self.m_shareBtnTips:runCsbAction("over",false,function()
        self.m_shareBtnTips:setVisible(false)
    end)
end

return CodeGameScreenFishManiaMachine






