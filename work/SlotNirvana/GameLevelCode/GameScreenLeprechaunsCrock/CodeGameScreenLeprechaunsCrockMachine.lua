---
-- island li
-- 2019年1月26日
-- CodeGameScreenLeprechaunsCrockMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "LeprechaunsCrockPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenLeprechaunsCrockMachine = class("CodeGameScreenLeprechaunsCrockMachine", BaseNewReelMachine)

CodeGameScreenLeprechaunsCrockMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenLeprechaunsCrockMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- 自定义的小块类型 94
CodeGameScreenLeprechaunsCrockMachine.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2  -- 自定义的小块类型 95
CodeGameScreenLeprechaunsCrockMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  -- 自定义的小块类型 9
CodeGameScreenLeprechaunsCrockMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2  -- 自定义的小块类型 10
CodeGameScreenLeprechaunsCrockMachine.SYMBOL_SCORE_12 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3  -- 自定义的小块类型 11

CodeGameScreenLeprechaunsCrockMachine.SYMBOL_BONUS_COINS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8  -- 自定义的小块类型 101
CodeGameScreenLeprechaunsCrockMachine.SYMBOL_BONUS_FREE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9  -- 自定义的小块类型 102

CodeGameScreenLeprechaunsCrockMachine.EFFECT_Bonus_OpenBonusSymbol = GameEffect.EFFECT_SELF_EFFECT + 1  --打开金币bonus和金币buff
CodeGameScreenLeprechaunsCrockMachine.EFFECT_Bonus_OpenFeatureSymbol = GameEffect.EFFECT_SELF_EFFECT + 2  --打开玩法bonus和玩法buff
CodeGameScreenLeprechaunsCrockMachine.EFFECT_Bonus_Pick = GameEffect.EFFECT_SELF_EFFECT + 3  --多福多彩

-- 构造函数
function CodeGameScreenLeprechaunsCrockMachine:ctor()
    CodeGameScreenLeprechaunsCrockMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_bgmReelsDownDelayTime = 20
    self.m_spinRestMusicBG = true
    self.m_guoSpineType = 1 --锅的状态 1 表示普通 2表示金色
    self.m_stopLineFrame = false -- 翻转bonus前停止连线
    self.m_roleIdleIndex = 1 -- 角色播放索引
    self.m_guoNums = 0 --收集的 锅上面的数字 索引
    self.m_isPlayRoleEffect = true -- 收集buff的时候 角色只播放一次
    self.m_isTriggerLongRun = false --是否触发了快滚
    self.m_playSoundMoney = true --是否播放收集金币bonus音效
    self.m_playYuGaoSoundIndex = 1 --播放预告中奖音效索引
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
    self.m_publicConfig = PublicConfig
 
    --init
    self:initGame()
end

function CodeGameScreenLeprechaunsCrockMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("LeprechaunsCrockConfig.csv", "LevelLeprechaunsCrockConfig.lua")
    self.m_configData:initMachine(self)

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenLeprechaunsCrockMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LeprechaunsCrock"  
end


function CodeGameScreenLeprechaunsCrockMachine:initUI()
    
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建jackpot
    self.m_JackpotView = util_createView("CodeLeprechaunsCrockSrc.LeprechaunsCrockJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_JackpotView)
    self.m_JackpotView:initMachine(self)

    -- base下说明
    self.m_baseTips = util_createAnimation("LeprechaunsCrock_shangUI.csb")
    self:findChild("shangUI"):addChild(self.m_baseTips)
    self.m_baseTips:findChild("Node_FG"):setVisible(false)
    self.m_baseTips:runCsbAction("idle", true)

    -- 收集bonus的锅
    self.m_bonusCollectGuoSpine = util_spineCreate("LeprechaunsCrock_guo",true,true)
    self:findChild("guo"):addChild(self.m_bonusCollectGuoSpine)
    util_spinePlay(self.m_bonusCollectGuoSpine, "idle", true)
    self.m_bonusCollectGuoSpine.numsNode = util_createAnimation("LeprechaunsCrock_guo_shuzi.csb")
    util_spinePushBindNode(self.m_bonusCollectGuoSpine,"guadian",self.m_bonusCollectGuoSpine.numsNode)

    -- 角色
    self.m_jueSeSpine = util_spineCreate("LeprechaunsCrock_juese",true,true)
    self:findChild("juese"):addChild(self.m_jueSeSpine)
    self:playRoleIdle()

    -- 角色金币
    self.m_jueSeJinBiSpine = util_spineCreate("LeprechaunsCrock_juese",true,true)
    self:findChild("juese_jinbi"):addChild(self.m_jueSeJinBiSpine)
    self.m_jueSeJinBiSpine:setVisible(false)

    -- 跳过
    self.m_openBonusSkip = util_createView("CodeLeprechaunsCrockSrc.LeprechaunsCrockOpenBonusSkip", self)
    self:findChild("Node_openBonusSkip"):addChild(self.m_openBonusSkip)
    self.m_openBonusSkip:setVisible(false)

    -- pickBonus 界面
    self.m_bonusGame = util_createView("CodeLeprechaunsCrockSrc.LeprechaunsCrockBonusView", self)
    self:findChild("Node_pickBonus"):addChild(self.m_bonusGame)
    self.m_bonusGame:setVisible(false)

    -- 大赢动画
    self.m_bigwinEffect = util_spineCreate("LeprechaunsCrock_bigwin", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigwinEffect)
    self.m_bigwinEffect:setVisible(false)

    -- 预告动画
    self.m_yugaoEffect = util_createAnimation("LeprechaunsCrock_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_yugaoEffect)
    self.m_yugaoEffect:setVisible(false)

    self.m_yugaoEffectSpine = util_spineCreate("LeprechaunsCrock_yugao", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoEffectSpine)
    self.m_yugaoEffectSpine:setVisible(false)

    -- 过场动画
    self.m_guochangEffect = util_spineCreate("LeprechaunsCrock_guochang",true,true)
    self:findChild("Node_guochang"):addChild(self.m_guochangEffect)
    self.m_guochangEffect:setVisible(false)

    --forture coin棋盘压暗
    self.m_reelMask = util_createAnimation("LeprechaunsCrock_reel_dark.csb")
    self.m_clipParent:addChild(self.m_reelMask, REEL_SYMBOL_ORDER.REEL_ORDER_1-100)
    self.m_reelMask:setVisible(false)
    self.m_reelMask:setPosition(util_convertToNodeSpace(self:findChild("Node_mask"), self.m_clipParent))

    -- 背景蝴蝶
    self.m_hudie = util_spineCreate("LeprechaunsCrockBg_hudie",true,true)
    self.m_gameBg:findChild("Node_hudie"):addChild(self.m_hudie)

    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self:setReelBg(1)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "LeprechaunsCrock_totalwin.csb")
end

--[[
    播放角色动画
]]
function CodeGameScreenLeprechaunsCrockMachine:playRoleIdle( )
    local idleName = {"idleframe", "idleframe", "idleframe", "actionframe1", "idleframe", "idleframe", "idleframe", "actionframe2"}
    util_spinePlay(self.m_jueSeSpine, idleName[self.m_roleIdleIndex], false)
    util_spineEndCallFunc(self.m_jueSeSpine, idleName[self.m_roleIdleIndex], function ()
        self.m_roleIdleIndex = self.m_roleIdleIndex + 1
        if self.m_roleIdleIndex > #idleName then
            self.m_roleIdleIndex = 1
        end
        self:playRoleIdle()
    end)
end

function CodeGameScreenLeprechaunsCrockMachine:initFreeSpinBar()
    local node_bar = self:findChild("shangUI")
    self.m_baseFreeSpinBar = util_createView("CodeLeprechaunsCrockSrc.LeprechaunsCrockFreespinBarView",{machine = self})
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2free 3pickBonus
]]
function CodeGameScreenLeprechaunsCrockMachine:setReelBg(_BgIndex)
    
    if _BgIndex == 1 then
        self:findChild("Reel_base"):setVisible(true)
        self:findChild("Reel_FG"):setVisible(false)
        --隐藏棋盘背光
        self:findChild("guang"):setVisible(false)

        self.m_gameBg:findChild("Base"):setVisible(true)
        self.m_gameBg:findChild("FG"):setVisible(false)
        self.m_gameBg:findChild("dfdc"):setVisible(false)
        self.m_gameBg:runCsbAction("idle1", true)
        self.m_hudie:setVisible(true)
        util_spinePlay(self.m_hudie, "idle1", true)
    elseif _BgIndex == 2 then
        self:findChild("Reel_base"):setVisible(false)
        self:findChild("Reel_FG"):setVisible(true)
        --显示棋盘背光
        self:findChild("guang"):setVisible(true)

        self.m_gameBg:findChild("Base"):setVisible(false)
        self.m_gameBg:findChild("FG"):setVisible(true)
        self.m_gameBg:findChild("dfdc"):setVisible(false)
        self.m_gameBg:runCsbAction("idle2", true)
        self.m_hudie:setVisible(true)
        util_spinePlay(self.m_hudie, "idle2", true)
    elseif _BgIndex == 3 then
        self.m_gameBg:findChild("Base"):setVisible(false)
        self.m_gameBg:findChild("FG"):setVisible(false)
        self.m_gameBg:findChild("dfdc"):setVisible(true)
        self.m_gameBg:runCsbAction("idle3", true)
        self.m_hudie:setVisible(false)
    end
end

function CodeGameScreenLeprechaunsCrockMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.Sound_Enter_Game)

    end,0.4,self:getModuleName())
end

function CodeGameScreenLeprechaunsCrockMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenLeprechaunsCrockMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    
    if self.m_bProduceSlots_InFreeSpin then
        self:showChangeBonusSymbol()
    end
end

function CodeGameScreenLeprechaunsCrockMachine:addObservers()
    CodeGameScreenLeprechaunsCrockMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        else
            soundIndex = 3
        end

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_LeprechaunsCrock_free_lineFrame_" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_LeprechaunsCrock_lineFrame_" .. soundIndex]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenLeprechaunsCrockMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenLeprechaunsCrockMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

--[[
    使用的假滚是哪个
    假滚分为两组 一组有bonus 一组有scatter
]]
function CodeGameScreenLeprechaunsCrockMachine:getMachineBaseType()
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData then
        return self.m_runSpinResultData.p_selfMakeData.nextBaseReelsName
    end
end

function CodeGameScreenLeprechaunsCrockMachine:getMachineFreeType()
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData then
        return self.m_runSpinResultData.p_selfMakeData.nextFreeReelsName
    end
end

function CodeGameScreenLeprechaunsCrockMachine:initGameStatusData(gameData)
    
    CodeGameScreenLeprechaunsCrockMachine.super.initGameStatusData(self, gameData)

    if gameData.gameConfig.extra and gameData.gameConfig.extra.nextBaseReelsName then
        if self.m_runSpinResultData and not self.m_runSpinResultData.p_selfMakeData then
            self.m_runSpinResultData.p_selfMakeData = {}
        end
        self.m_runSpinResultData.p_selfMakeData.nextBaseReelsName = gameData.gameConfig.extra.nextBaseReelsName
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenLeprechaunsCrockMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BONUS then
        return "Socre_LeprechaunsCrock_Bonus_1"
    elseif symbolType == self.SYMBOL_BONUS2 then
        return "Socre_LeprechaunsCrock_Bonus_2"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_LeprechaunsCrock_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_LeprechaunsCrock_11"
    elseif symbolType == self.SYMBOL_SCORE_12 then
        return "Socre_LeprechaunsCrock_12"

    elseif symbolType == self.SYMBOL_BONUS_COINS then
        return "Socre_LeprechaunsCrock_Bonus_Coins"
    elseif symbolType == self.SYMBOL_BONUS_FREE then
        return "Socre_LeprechaunsCrock_Bonus_Free"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenLeprechaunsCrockMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenLeprechaunsCrockMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_12,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_COINS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_FREE,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenLeprechaunsCrockMachine:MachineRule_initGame(  )
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenLeprechaunsCrockMachine:slotOneReelDown(reelCol)    
    local isTriggerLongRun = CodeGameScreenLeprechaunsCrockMachine.super.slotOneReelDown(self,reelCol) 
    if not self.m_isTriggerLongRun then
        self.m_isTriggerLongRun = isTriggerLongRun
    end

    return isTriggerLongRun
end

function CodeGameScreenLeprechaunsCrockMachine:symbolBulingEndCallBack(_symbolNode)

    if _symbolNode and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_isTriggerLongRun and _symbolNode.p_cloumnIndex ~= self.m_iReelColumnNum then
            local Col = _symbolNode.p_cloumnIndex
            for iCol = 1, Col do
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol,iRow)
                    if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName ~= "idleframe2" then
                        -- local ccbNode = symbolNode:getCCBNode()
                        -- if ccbNode then
                        --     util_spineMix(ccbNode.m_spineNode, symbolNode.m_currAnimName, "idleframe2", 1)
                        -- end
                        symbolNode:runAnim("idleframe2", true)
                    end
                end
            end
        else
            _symbolNode:runAnim("idleframe3", true)
        end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenLeprechaunsCrockMachine:levelFreeSpinEffectChange()
    self.m_baseTips:setVisible(false)
    self:setReelBg(2)
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenLeprechaunsCrockMachine:levelFreeSpinOverChangeEffect()
    self.m_baseTips:setVisible(true)
    self:setReelBg(1)
end
---------------------------------------------------------------------------


----------- FreeSpin相关
---
----- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenLeprechaunsCrockMachine:showBonusAndScatterLineTip(lineValue, callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=symPosData.iX})
        if slotNode == nil then
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX)
        end

        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]
                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=bigSymbolInfo.startRowIndex})
                        break
                    end
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

-- 显示free spin
function CodeGameScreenLeprechaunsCrockMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self:stopLinesWinSound()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end
    
    if scatterLineValue ~= nil then
        --
        util_spinePlay(self.m_jueSeSpine, "actionframe_guzhang", false)
        util_spineEndCallFunc(self.m_jueSeSpine,"actionframe_guzhang",function ()
            self:playRoleIdle()
        end)
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end
        end
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            -- 停掉背景音乐
            self:clearCurMusicBg()
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_scatter_trigger_free)
        end
    else
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
        self:playTriggerEffectByBonus(true, function()
            self:showFreeSpinView(effectData)
        end)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

--[[
    触发玩法时 播放罐子和人物的触发
]]
function CodeGameScreenLeprechaunsCrockMachine:playTriggerEffectByBonus(_isFree, _func)
    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 角色触发动画
    util_spinePlay(self.m_jueSeSpine, "actionframe4", false)
    util_spineEndCallFunc(self.m_jueSeSpine,"actionframe4",function ()
        self:playRoleIdle()
    end)
    if _isFree then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonusFG_guanZi_trigger)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_coinsGuanZi_trigger)
    end

    -- 罐子触发动画
    local actionframeName = "actionframe2"
    local idleframeName = "idle"
    if self.m_guoSpineType == 2 then
        actionframeName = "actionframe3"
        idleframeName = "idle2"
    end
    util_spinePlay(self.m_bonusCollectGuoSpine, actionframeName, false)
    util_spineEndCallFunc(self.m_bonusCollectGuoSpine, actionframeName, function()
        util_spinePlay(self.m_bonusCollectGuoSpine, idleframeName, true)
    end)

    self:waitWithDelay(1, function()
        if _func then
            _func()
        end
    end)
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenLeprechaunsCrockMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("CodeLeprechaunsCrockSrc.LeprechaunsCrockDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end

    -- if self.m_root then
    --     self.m_root:addChild(view,999999)
    --     local wordPos=view:getParent():convertToWorldSpace(cc.p(view:getPosition()))
    --     local curPos=self.m_root:convertToNodeSpace(wordPos)
    --     view:setPosition(cc.pSub(cc.p(0,0),wordPos))
    -- else
    gLobalViewManager:showUI(view)
    -- end

    return view
end

-- FreeSpinstart
function CodeGameScreenLeprechaunsCrockMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        local view = nil
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_freeMoreView)

            view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_freeNums_add)
                self.m_baseFreeSpinBar:playFreeMoreEffect()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                -- 重置锅的状态
                if self.m_guoSpineType == 2 then
                    self.m_guoSpineType = 1
                    util_spinePlay(self.m_bonusCollectGuoSpine, "idle", true)
                end

                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect() 
            end)
            if self.m_guoSpineType == 2 then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_freeStartView_bonusBoost_start)
                view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_freeStartView_bonusBoost_over
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_freeStartView_start)
                view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_freeStartView_over
            end
            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_click
        end
        -- 添加彩带
        local caidaiNode = util_createAnimation("LeprechaunsCrock/FreeSpin_tanban_caidai.csb")
        view:findChild("Node_caidai"):addChild(caidaiNode)
        caidaiNode:runCsbAction("idle", true)
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

function CodeGameScreenLeprechaunsCrockMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_freeOverView_start)

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:levelFreeSpinOverChangeEffect()
            self:waitWithDelay(50/60, function()
                self:triggerFreeSpinOverCallFun()
            end)
        end)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_click
    view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_freeOverView_over
    
    -- 添加彩带
    local caidaiNode = util_createAnimation("LeprechaunsCrock/FreeSpin_tanban_caidai.csb")
    view:findChild("Node_caidai"):addChild(caidaiNode)
    caidaiNode:runCsbAction("idle", true)

    -- 添加角色
    local roleSpine = util_spineCreate("LeprechaunsCrock_juese", true, true)
    view:findChild("juese"):addChild(roleSpine)
    util_spinePlay(roleSpine, "tanban1_start", true)
    util_spineEndCallFunc(roleSpine, "tanban1_start", function()
        util_spinePlay(roleSpine, "idleframe_tanban1", true)
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1.05},570)

end

function CodeGameScreenLeprechaunsCrockMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenLeprechaunsCrockMachine:MachineRule_SpinBtnCall()
    -- 重置数据
    self.m_stopLineFrame = false
    if self.m_guoSpineType == 2 then
        self.m_guoSpineType = 1
        util_spinePlay(self.m_bonusCollectGuoSpine, "idle", true)
    end
    self.m_guoNums = 0
    self.m_isPlayRoleEffect = true
    self.m_isTriggerLongRun = false
    self.m_playSoundMoney = true
    --连续spin 切断连线音
    self:stopLinesWinSound()
    self:setMaxMusicBGVolume( )
   
    return false -- 用作延时点击spin调用
end

function CodeGameScreenLeprechaunsCrockMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local isPlayYuGao = self:getIsPlayYuGao()
    if isPlayYuGao then
        self:playYuGaoAct(function()
            self:produceSlots()

            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end

            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end)
    else
        self:produceSlots()

        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end

        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenLeprechaunsCrockMachine:addSelfEffect()

    if self:isTriggerBonusOpenSymbol() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_Bonus_OpenBonusSymbol 
    end
    
    -- 触发多福多彩的时候 大赢放在最后播放
    if self:isTriggerBonusGame() then
        if self:isTriggerOpenFeatureSymbol() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_Bonus_OpenFeatureSymbol 
        end

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_Bonus_Pick
    else
        --没有多福多彩的话 大赢在翻开玩法之前播放
        if self:isTriggerOpenFeatureSymbol() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_EPICWIN + 2
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_Bonus_OpenFeatureSymbol 
        end
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenLeprechaunsCrockMachine:MachineRule_playSelfEffect(effectData)
    
    if effectData.p_selfEffectType == self.EFFECT_Bonus_OpenBonusSymbol then
        self:showReelMask(function()
            self:playEffect_openBonusSymbol(function()
                self:playCreditIconsCollectAnim(function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end)  
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_Bonus_OpenFeatureSymbol then
        self:showReelMask(function()
            self:playEffect_bonusOpenSymbol_featureBuffIcons(function()
                self:playEffect_buffBonusSymbol(function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_Bonus_Pick then
        self:playEffect_collectBonusSymbol(function()
            self:playEffect_bonusGame(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end

    return true
end

--[[
    打开金币bonus图标和金币buff
]]
function CodeGameScreenLeprechaunsCrockMachine:isTriggerBonusOpenSymbol()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local coins = bonusInfo.coins or {}
    
    return  table.nums(coins) > 0
end

--[[
    判断是否有玩法bonus需要打开
]]
function CodeGameScreenLeprechaunsCrockMachine:isTriggerOpenFeatureSymbol()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local feature = bonusInfo.feature or {}
    local freeGame = bonusInfo.freeGame or {}
    local playBuff = bonusInfo.playBuff or {}

    return table.nums(feature) > 0 or table.nums(freeGame) > 0
end

-- 多福多彩玩法
function CodeGameScreenLeprechaunsCrockMachine:isTriggerBonusGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local feature = bonusInfo.feature or {}

    return table.nums(feature) > 0
end

--[[
    整合服务器数据 bonus相关
]]
function CodeGameScreenLeprechaunsCrockMachine:getBonusSymbolSortList()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local coins = bonusInfo.coins or {}
    local feature = bonusInfo.feature or {}
    local freeGame = bonusInfo.freeGame or {}
    local addCoinsBuff = bonusInfo.addCoinsBuff or {}
    local playBuff = bonusInfo.playBuff or {}

    local sortList = {}
    local addNewIconList = function(_pos, _multiply, _isOpen, _sortIndex)
        local iconData = {}
        iconData.pos = tonumber(_pos)
        iconData.multiply = tonumber(_multiply) --金币成倍系数
        iconData.isOpen = _isOpen
        iconData.sortIndex = _sortIndex --代表打开顺序 先打开金币 在打开金币buff 再打开玩法 再打开玩法buff
        table.insert(sortList, iconData)
    end

    for _pos, _iconData in pairs(coins) do
        addNewIconList(_pos, _iconData, true, 1)
    end
    for _pos, _iconData in pairs(feature) do
        addNewIconList(_pos, _iconData, false, 3)
    end
    for _pos, _iconData in pairs(freeGame) do
        addNewIconList(_pos, _iconData, false, 4)
    end
    for _pos, _iconData in pairs(addCoinsBuff) do
        addNewIconList(_pos, _iconData, true, 2)
    end
    for _pos, _iconData in pairs(playBuff) do
        addNewIconList(_pos, _iconData, false, 5)
    end
    table.sort(sortList, function(_dataA, _dataB)
        local fixPosA = self:getRowAndColByPos(_dataA.pos)
        local fixPosB = self:getRowAndColByPos(_dataB.pos)
        if fixPosA.iY == fixPosB.iY then
            if fixPosA.iX == fixPosB.iX then
                return _dataA.sortIndex < _dataA.sortIndex
            else
                return fixPosA.iX > fixPosB.iX
            end
        else
            return fixPosA.iY < fixPosB.iY
        end
    end)

    return sortList
end

--[[
    bonus1上显示的内容
]]
function CodeGameScreenLeprechaunsCrockMachine:showBonus1ByType(_slotsNode, _type, _multiply)
    if not tolua.isnull(_slotsNode) then
        _slotsNode:getCcbProperty("Node_money"):setVisible(_type == "Node_money")
        _slotsNode:getCcbProperty("Node_FG"):setVisible(_type == "Node_FG")
        _slotsNode:getCcbProperty("Node_Jackpot"):setVisible(_type == "Node_Jackpot")

        if _type == "Node_money" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            local isShowRed = self:getBonusCoinsMultiply(tonumber(_multiply))
            _slotsNode:getCcbProperty("m_lb_coins_1"):setVisible(not isShowRed)
            _slotsNode:getCcbProperty("m_lb_coins_2"):setVisible(isShowRed)
            if not isShowRed then
                _slotsNode:getCcbProperty("m_lb_coins_1"):setString(util_formatCoins(tonumber(_multiply) * lineBet, 3, false, true, true))
                self:updateLabelSize({label = _slotsNode:getCcbProperty("m_lb_coins_1"),sx = 0.9,sy = 0.9}, 237)
            else
                _slotsNode:getCcbProperty("m_lb_coins_2"):setString(util_formatCoins(tonumber(_multiply) * lineBet, 3, false, true, true))
                self:updateLabelSize({label = _slotsNode:getCcbProperty("m_lb_coins_2"),sx = 0.9,sy = 0.9}, 237)
            end
        elseif _type == "Node_FG" then
            _slotsNode:getCcbProperty("m_lb_num"):setString(_multiply)
        end
    end
end

--[[
    打开金币bonus
]]
function CodeGameScreenLeprechaunsCrockMachine:playEffect_openBonusSymbol(_func)
    self.m_openBonusSkip:setVisible(true)
    self.m_bottomUI:setSkipBonusBtnVisible(true)
    self.m_openBonusSkip:setSkipCallBack(function()
        self.m_openBonusSkip:stopAllActions()
        self:hideQuickStopBtn()
        -- 立即刷新所有bonus图标
        self:skipOpenBonusSymbolUpDateReel()
        self:playCoinsBuffEffect(_func)
    end)

    local bonusSortList = self:getBonusSymbolSortList()
    -- 依次翻开所有金币
    local animTime = 19/30
    local interval = 0.5
    for _index, _iconData in ipairs(bonusSortList) do
        local iconData = _iconData
        local slotsPos = iconData.pos
        local fixPos = self:getRowAndColByPos(slotsPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local delayTime = (_index - 1) * interval
        local isOpen = iconData.isOpen and (iconData.sortIndex == 1)
        performWithDelay(self.m_openBonusSkip,function()
            if slotsNode and slotsNode.p_symbolType then
                -- 只打开金币bonus
                if isOpen then 
                    slotsNode.multiply = _iconData.multiply --记录一下金币当前的倍数 buff计算的时候 用
                    self:showBonus1ByType(slotsNode, "Node_money", _iconData.multiply)

                    slotsNode:runAnim("actionframe", false)
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_fanzhuan)

                    self:playBonus1SpineEffect(slotsNode, "actionframe", "idleframe4", "JIN_Money")
                else
                    --此时不需要翻开的 在这个地方开始播放期待动画
                    if slotsNode.p_symbolType == self.SYMBOL_BONUS2 then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_teshu_fankai_no)
                        slotsNode:runAnim("idleframe3", true)
                    elseif slotsNode.p_symbolType == self.SYMBOL_BONUS then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_jackpot_fankai_no)
                        self:playBonus1SpineEffect(slotsNode, "actionframe2", "idleframe3")
                    end
                end
            end
        end, delayTime)
    end
    
    -- 下一步
    local delayTime = #bonusSortList * interval + animTime
    performWithDelay(self.m_openBonusSkip, function()
        self:hideQuickStopBtn()

        performWithDelay(self.m_openBonusSkip, function()
            self:playCoinsBuffEffect(_func)
        end, 0.4)
        
    end, delayTime)
end

--[[
    隐藏快停
]]
function CodeGameScreenLeprechaunsCrockMachine:hideQuickStopBtn( )
    self.m_openBonusSkip:clearSkipCallBack()
    self.m_openBonusSkip:setVisible(false)
    self.m_bottomUI:setSkipBonusBtnVisible(false)
end
--[[
    翻转金币buff
]]
function CodeGameScreenLeprechaunsCrockMachine:playCoinsBuffEffect(_func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local addCoinsBuff = bonusInfo.addCoinsBuff or {}

    local coinBonusBuffIndex = 1
    local interval = 2
    local buffAddTime = 1.3
    local bonusSortList = self:getBonusSymbolSortList()
    for _index, _iconData in ipairs(bonusSortList) do
        local iconData = _iconData
        local isOpen = iconData.isOpen and (iconData.sortIndex == 2)
        -- 只打开金币bonus buff
        if isOpen then 
            local slotsPos = iconData.pos
            local fixPos = self:getRowAndColByPos(slotsPos)
            local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if slotsNode and slotsNode.p_symbolType then
                local delayTime = (coinBonusBuffIndex - 1) * interval
                coinBonusBuffIndex = coinBonusBuffIndex + 1
                self:waitWithDelay(delayTime, function()
                    local spineName = "Credit"
                    if tonumber(iconData.multiply) == 2 then
                        spineName = "Super"
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_super_credit)
                    elseif tonumber(iconData.multiply) == 3 then
                        spineName = "Mega"
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_mega_credit)
                    else
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_credit)
                    end
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_teshu_fankai)
                    self:bonusChangeShow("actionframe", slotsNode, spineName, function()
                        slotsNode:runAnim("idleframe4", true)
                    end)
                end)

                local playBuffDelayTime = table.nums(addCoinsBuff) * interval + (coinBonusBuffIndex - 2) * (buffAddTime+0.15) + 0.5
                self:waitWithDelay(playBuffDelayTime, function()
                    slotsNode:setZOrder(slotsNode.m_showOrder + 1000 + tonumber(slotsPos))
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_boost_addCoins)
                    slotsNode:runAnim("actionframe2", false)
                    -- 金币buff对 金币生效
                    self:waitWithDelay(25/30, function()
                        self:updataCoinsBonusByBonusBuff(iconData.multiply)
                    end)
                end)
            end
        end
    end

    -- 下一步
    local delayTime = table.nums(addCoinsBuff) * interval + (coinBonusBuffIndex - 1) * (buffAddTime+0.35) + 0.5 + 0.4
    if coinBonusBuffIndex == 1 then
        delayTime = 0.4
    end
    self:waitWithDelay(delayTime, function()
        if _func then
            _func()
        end
    end)
end

--[[
    加钱buff给bonus加钱的时候 额外的效果
]]
function CodeGameScreenLeprechaunsCrockMachine:playCoinsBuffExtraEffect(_slotsNode, _addMultiply)
    local startPos = util_convertToNodeSpace(_slotsNode, self.m_effectNode)
    
    local flyNode = util_createAnimation("LeprechaunsCrock_jiaqian.csb")
    self.m_effectNode:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    flyNode:setScale(self.m_machineRootScale)
    flyNode:setPosition(startPos)

    local lineBet = globalData.slotRunData:getCurTotalBet()

    flyNode:findChild("m_lb_coins"):setString("+"..util_formatCoins(tonumber(_addMultiply) * lineBet, 3, false, true, true))
    self:updateLabelSize({label = flyNode:findChild("m_lb_coins"),sx = 0.9,sy = 0.9}, 237)

    flyNode:runCsbAction("actionframe", false, function()
        flyNode:removeFromParent()
        flyNode = nil
    end)
    
end

--[[
    每翻出一个金币buff 刷新一次金币bonus
]]
function CodeGameScreenLeprechaunsCrockMachine:updataCoinsBonusByBonusBuff(_multiply)
    local bonusSortList = self:getBonusSymbolSortList()
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_add_coins)

    for _index, _iconData in ipairs(bonusSortList) do
        local iconData = _iconData
        local slotsPos = iconData.pos
        local fixPos = self:getRowAndColByPos(slotsPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local isOpen = iconData.isOpen and (iconData.sortIndex == 1)
        if slotsNode and slotsNode.p_symbolType then
            if isOpen then 
                local actionName = "actionframe1_lan"
                -- 不同的倍数对应不同的时间线
                -- 1倍蓝色 2倍紫色 3倍红色
                if _multiply == 2 then
                    actionName = "actionframe1_zi"
                elseif _multiply == 3 then
                    actionName = "actionframe1_hong"
                end
                
                self:playBonus1SpineEffect(slotsNode, actionName, "idleframe4", "JIN_Money")

                slotsNode:runAnim("actionframe1", false, function()
                    -- slotsNode:runAnim("idleframe4", true)
                end)
                --加钱buff给bonus加钱的时候 额外的效果
                self:playCoinsBuffExtraEffect(slotsNode, _multiply * iconData.multiply)

                local oldMultily = slotsNode.multiply > 0 and slotsNode.multiply or iconData.multiply
                local newMultily = oldMultily + _multiply * iconData.multiply
                slotsNode.multiply = newMultily
                local lineBet = globalData.slotRunData:getCurTotalBet()

                self:jumpCoins(slotsNode, newMultily * lineBet, oldMultily * lineBet)
            end
        end
    end
end

-- 金币跳动
function CodeGameScreenLeprechaunsCrockMachine:jumpCoins(node, _coins, _curCoins)
    local curCoins = _curCoins or 0
    local lineBet = globalData.slotRunData:getCurTotalBet()
    -- 每秒60帧
    local coinRiseNum =  (_coins - _curCoins) / (0.8 * 60)

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    node.m_updateCoinsAction = schedule(self, function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < _coins and curCoins or _coins
        
        local sCoins = curCoins

        local multiply = sCoins / lineBet
        local isShowRed = self:getBonusCoinsMultiply(multiply)
        if not tolua.isnull(node) and node.getCcbProperty then
            node:getCcbProperty("m_lb_coins_1"):setVisible(not isShowRed)
            node:getCcbProperty("m_lb_coins_2"):setVisible(isShowRed)
            if not isShowRed then
                node:getCcbProperty("m_lb_coins_1"):setString(util_formatCoins(sCoins, 3, false, true, true))
                self:updateLabelSize({label = node:getCcbProperty("m_lb_coins_1"),sx = 0.9,sy = 0.9}, 237)
            else
                node:getCcbProperty("m_lb_coins_2"):setString(util_formatCoins(sCoins, 3, false, true, true))
                self:updateLabelSize({label = node:getCcbProperty("m_lb_coins_2"),sx = 0.9,sy = 0.9}, 237)
            end
        end

        if curCoins >= _coins then
            self:stopUpDateCoins(node)
        end
    end,0.008)
end

function CodeGameScreenLeprechaunsCrockMachine:stopUpDateCoins(node)
    if not tolua.isnull(node) then
        if node.m_updateCoinsAction then
            self:stopAction(node.m_updateCoinsAction)
            node.m_updateCoinsAction = nil
        end
    else
        print("-----")
    end
end

--[[
    跳过首次翻开bonus流程后立刻刷新轮盘
]]
function CodeGameScreenLeprechaunsCrockMachine:skipOpenBonusSymbolUpDateReel()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local coins = bonusInfo.coins or {}
    local addCoinsBuff = bonusInfo.addCoinsBuff or {}

    local fnChangeBonusSymbol = function(_pos, _iconData)
        local slotsPos = tonumber(_pos)
        local fixPos = self:getRowAndColByPos(slotsPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

        if slotsNode and slotsNode.p_symbolType == self.SYMBOL_BONUS then
            self:showBonus1ByType(slotsNode, "Node_money", _iconData)
            slotsNode.multiply = tonumber(_iconData)
            slotsNode:runAnim("idleframe7", true)
            local csbNode = slotsNode:getCCBNode()
            if csbNode.bonusSpineNode then
                csbNode.bonusSpineNode:setSkin("JIN_Money")
                util_spinePlay(csbNode.bonusSpineNode,"idleframe4",true)
            end
        end
    end

    -- 直接翻开
    --金币
    for _pos, _iconData in pairs(coins) do
        fnChangeBonusSymbol(_pos, _iconData)
    end

    -- 其他的播放待翻开期待
    local bonusSortList = self:getBonusSymbolSortList()
    for _index, _iconData in ipairs(bonusSortList) do
        local iconData = _iconData
        local slotsPos = iconData.pos
        local fixPos = self:getRowAndColByPos(slotsPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local isOpen = iconData.isOpen and (iconData.sortIndex == 1)
        if slotsNode and slotsNode.p_symbolType then
            if not isOpen then 
                --此时不需要翻开的 在这个地方开始播放期待动画
                if slotsNode.p_symbolType == self.SYMBOL_BONUS2 then
                    slotsNode:runAnim("idleframe3", true)
                elseif slotsNode.p_symbolType == self.SYMBOL_BONUS then
                    self:playBonus1SpineEffect(slotsNode, "actionframe2", "idleframe3")
                end
            end
        end
    end
end

--[[
    收集金币bonus
]]
function CodeGameScreenLeprechaunsCrockMachine:playCreditIconsCollectAnim(_func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local coins = bonusInfo.coins or {}
    local addCoinsBuff = bonusInfo.addCoinsBuff or {}

    local feature = bonusInfo.feature or {}
    local freeGame = bonusInfo.freeGame or {}

    local winCoins = 0
    -- 金币上所有的钱数
    for _pos, _iconData in pairs(coins) do
        local multip = tonumber(_iconData)
        for _posBuff, _iconDataBuff in pairs(addCoinsBuff) do
            multip = multip + tonumber(_iconDataBuff) * tonumber(_iconData)
        end
        local betValue = globalData.slotRunData:getCurTotalBet()
        local coins = betValue * multip
        winCoins = winCoins + coins
    end

    --底栏金币
    local bottomWinCoin = self:getCurBottomWinCoins()
    local lastWinCoin = bottomWinCoin + winCoins
    self:setLastWinCoin(lastWinCoin)
    
    -- 飞行动作
    local playFlyIndex = 0
    for _pos, _iconData in pairs(coins) do
        local pos = tonumber(_pos)
        playFlyIndex = playFlyIndex + 1
        local bJump = playFlyIndex == 1
        self:playBonusSymbolCollectAnim(pos, function()
            if bJump then
                local isUpdateTop = true
                if table.nums(feature) > 0 or table.nums(freeGame) > 0 or self.m_bProduceSlots_InFreeSpin then
                    isUpdateTop = false
                end
                self:updateBottomUICoins(0, winCoins, isUpdateTop, true, true)
                
                self:playGuoAndRoleEffect(false, function()
                    if table.nums(feature) > 0 then
                        if _func then
                            _func()
                        end
                    end
                end)
                if table.nums(feature) <= 0 then
                    self:hideReelMask()
                    if _func then
                        _func()
                    end
                end
            end
        end, "money")
    end
end

--[[
    bonus飞到收集的罐子处
]]
function CodeGameScreenLeprechaunsCrockMachine:playBonusSymbolCollectAnim(_pos, _func, _type, _isBuff)
    local iPos = tonumber(_pos)

    local fixPos = self:getRowAndColByPos(iPos)
    local slotsNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
    local startPos = cc.p(0, 0)
    if slotsNode and slotsNode.p_symbolType then
        startPos = util_convertToNodeSpace(slotsNode, self.m_effectNode)
    end
    local endPos = util_convertToNodeSpace(self:findChild("guo"), self.m_effectNode)
    endPos.y = endPos.y + 80
    
    local flyNode = cc.Node:create()
    if _type == "buff" then
        flyNode.bonusNode = util_spineCreate("Socre_LeprechaunsCrock_Bonus_2", true, true)
        flyNode.bonusNode:setSkin("FeatureBuff")
        flyNode:addChild(flyNode.bonusNode)
    else
        -- 飞行节点
        flyNode.bonusNode = util_createAnimation("Socre_LeprechaunsCrock_Bonus_1.csb")
        flyNode:addChild(flyNode.bonusNode)
        
        flyNode.bonusSpine = util_spineCreate("Socre_LeprechaunsCrock_Bonus_1", true, true)
        flyNode.bonusNode:findChild("Node_spine"):addChild(flyNode.bonusSpine)
        flyNode.bonusSpine:setSkin("JIN_Money")
    end

    self.m_effectNode:addChild(flyNode, iPos)
    flyNode:setScale(self.m_machineRootScale)
    flyNode:setPosition(startPos)

    flyNode.LiziNode = util_createAnimation("LeprechaunsCrock_shouji_tuowei.csb")
    flyNode:addChild(flyNode.LiziNode, -1)

    self:showBonusFlyNode(flyNode, _type, slotsNode)

    -- 飞行动作
    local distance = math.sqrt((endPos.x - startPos.x) * (endPos.x - startPos.x) + (endPos.y - startPos.y) * (endPos.y - startPos.y))
    local radius = distance/2
    local flyAngle = util_getAngleByPos(startPos, endPos)
    local offsetAngle = endPos.x > startPos.x and 90 or -90
    local pos1 = cc.p( util_getCirclePointPos(startPos.x, startPos.y, radius, flyAngle + offsetAngle) )
    local pos2 = cc.p( util_getCirclePointPos(endPos.x, endPos.y, radius/2, flyAngle + offsetAngle) )

    local delayTime = 0
    local flyTime  = 15/30
    if _type == "buff" then
        util_spinePlay(flyNode.bonusNode, "shouji")
        delayTime = 13/30
        flyTime = 17/30
    else
        if _type == "money" then
            delayTime = 17/30
            util_spinePlay(flyNode.bonusSpine, "shouji")
            flyNode.bonusNode:runCsbAction("shouji", false)
        else
            util_spinePlay(flyNode.bonusSpine, "shouji2")
            flyNode.bonusNode:runCsbAction("shouji2", false)
        end
    end

    if _type ~= "money" then
        -- 收集之后 棋盘上的图标播放静帧
        self:playIdleframeBonus(slotsNode)
    end

    flyNode:runAction(cc.Sequence:create(
        cc.DelayTime:create(delayTime),
        cc.CallFunc:create(function()
            if _type == "money" then
                -- 收集之后 棋盘上的图标播放静帧
                self:playIdleframeBonus(slotsNode)
                if self.m_playSoundMoney then
                    self.m_playSoundMoney = false
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_fly)
                end
            elseif _type == "buff" then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_boost_fly)
            elseif _type == "pick" then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_jackpot_feature_fly)
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_fly)
            end
        end),
        cc.BezierTo:create(flyTime, {pos1, pos2, endPos}),
        cc.CallFunc:create(function()
            for i=1,2 do
                local particle = flyNode.LiziNode:findChild("Particle_"..i)
                if particle then
                    particle:stopSystem()
                end
            end

            if _func then
                _func()
            end

            flyNode.bonusNode:setVisible(false)
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
end

--[[
    收集之后 棋盘上的图标播放静帧
]]
function CodeGameScreenLeprechaunsCrockMachine:playIdleframeBonus(_slotsNode)
    if _slotsNode and _slotsNode.p_symbolType then
        if _slotsNode.p_symbolType == self.SYMBOL_BONUS then
            _slotsNode:runAnim("idleframe7")
            self:playBonus1SpineEffect(_slotsNode, "idleframe7", "idleframe7")
        elseif _slotsNode.p_symbolType == self.SYMBOL_BONUS2 then
            _slotsNode:runAnim("idleframe5")
        end
    end
end

--[[
    收集bonus的时候 显示不同
]]
function CodeGameScreenLeprechaunsCrockMachine:showBonusFlyNode(_node, _type, _slotsNode)
    for i=1,2 do
        local particle = _node.LiziNode:findChild("Particle_"..i)
        particle:setDuration(1)     --设置拖尾时间(生命周期)
        particle:setPositionType(0)   --设置可以拖尾
        if particle then
            particle:resetSystem()
        end
    end

    if tolua.isnull(_node) or tolua.isnull(_node.bonusNode) then
        return
    end

    if _type == "buff" then
        _node.bonusNode:setSkin("FeatureBuff")
    else
        _node.bonusNode:findChild("Node_money"):setVisible(_type == "money")
        _node.bonusNode:findChild("Node_FG"):setVisible(_type == "free")
        _node.bonusNode:findChild("Node_Jackpot"):setVisible(_type == "pick")
        
        if _type == "money" then
            _node.bonusNode:findChild("m_lb_coins_1"):setVisible(true)
            _node.bonusNode:findChild("m_lb_coins_2"):setVisible(false)
            local coins = ""
            if _slotsNode and _slotsNode.p_symbolType then
                coins = _slotsNode:getCcbProperty("m_lb_coins_1"):getString()
                if _slotsNode:getCcbProperty("m_lb_coins_2"):isVisible() then
                    coins = _slotsNode:getCcbProperty("m_lb_coins_2"):getString()
                    _node.bonusNode:findChild("m_lb_coins_1"):setVisible(false)
                    _node.bonusNode:findChild("m_lb_coins_2"):setVisible(true)
                end
            end
            _node.bonusNode:findChild("m_lb_coins_1"):setString(coins)
            self:updateLabelSize({label = _node.bonusNode:findChild("m_lb_coins_1"),sx = 0.9,sy = 0.9}, 237)
            _node.bonusNode:findChild("m_lb_coins_2"):setString(coins)
            self:updateLabelSize({label = _node.bonusNode:findChild("m_lb_coins_2"),sx = 0.9,sy = 0.9}, 237)
        elseif _type == "free" then
            _node.bonusSpine:setSkin("JIN_FG")
            local freeNum = ""
            if _slotsNode and _slotsNode.p_symbolType then
                freeNum = _slotsNode:getCcbProperty("m_lb_num"):getString()
            end
            _node.bonusNode:findChild("m_lb_num"):setString(freeNum)
        elseif _type == "pick" then
            _node.bonusSpine:setSkin("JIN_Jackpot")
        end
    end
end

--[[
    bonus 上的金币大于5倍 显示红色
]]
function CodeGameScreenLeprechaunsCrockMachine:getBonusCoinsMultiply(_multiply)
    if _multiply >= 5 then
        return true
    end
    return false
end

--更新底栏金币
function CodeGameScreenLeprechaunsCrockMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--[[
    翻开玩法buff
]]
function CodeGameScreenLeprechaunsCrockMachine:playEffect_bonusOpenSymbol_featureBuffIcons(_func)
    local bonusSortList = self:getBonusSymbolSortList()
    -- 依次翻开玩法buff
    local animTime = 0.4
    local interval = 0.8
    
    local featureBonusBuffIndex = 1
    for _index, _iconData in ipairs(bonusSortList) do
        local iconData = _iconData
        
        local isOpen = (not iconData.isOpen) and (iconData.sortIndex == 5)
        if isOpen then 
            local delayTime = (featureBonusBuffIndex - 1) * interval
            featureBonusBuffIndex = featureBonusBuffIndex + 1

            local slotsPos = iconData.pos
            local fixPos = self:getRowAndColByPos(slotsPos)
            local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            
            self:waitWithDelay(delayTime, function()
                if slotsNode and slotsNode.p_symbolType then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_teshu_fankai)
                    self:bonusChangeShow("actionframe", slotsNode, "FeatureBuff", function()
                        slotsNode:runAnim("idleframe4")
                    end)
                end
            end)
        end
    end

    local delayTime = (featureBonusBuffIndex - 1) * interval + 30/30 + animTime
    if featureBonusBuffIndex == 1 then
        delayTime = 0
    end
    self:waitWithDelay(delayTime, function()
        -- BUFF BONUS
        self:playFeatureBuffFly(function()
            self:playEffect_bonusOpenSymbol(_func)
        end)
    end)
end

--[[
    翻开玩法bonus
]]
function CodeGameScreenLeprechaunsCrockMachine:playEffect_bonusOpenSymbol(_func)
    local animTime = 0.4
    local interval = 34/30

    local bonusSortList = self:getBonusSymbolSortList()

    -- 在打开玩法bonus
    local playFeatureIndex = 1
    for _index, _iconData in ipairs(bonusSortList) do
        local iconData = _iconData
        local isOpen = (not iconData.isOpen) and (iconData.sortIndex == 3 or iconData.sortIndex == 4)
        if isOpen then
            local slotsPos = iconData.pos
            local fixPos = self:getRowAndColByPos(slotsPos)
            local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            local delayTime = (playFeatureIndex - 1) * interval
            playFeatureIndex = playFeatureIndex + 1

            self:waitWithDelay(delayTime, function()
                if slotsNode and slotsNode.p_symbolType then
                    -- 表示触发pick玩法
                    if iconData.sortIndex == 3 then
                        self:showBonus1ByType(slotsNode, "Node_Jackpot")
                    else--表示触发free玩法
                        self:showBonus1ByType(slotsNode, "Node_FG", iconData.multiply)
                    end
                    slotsNode:setZOrder(slotsNode.m_showOrder + 1000 + tonumber(slotsPos))
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_fanzhuan)

                    slotsNode:runAnim("actionframe", false, function()
                        slotsNode:runAnim("idleframe7", true)
                    end)
                    local csbNode = slotsNode:getCCBNode()
                    if csbNode.bonusSpineNode then
                        if iconData.sortIndex == 3 then
                            csbNode.bonusSpineNode:setSkin("JIN_Jackpot")
                        else
                            csbNode.bonusSpineNode:setSkin("JIN_FG")
                        end
                        self:playBonus1Effect(csbNode.bonusSpineNode, "actionframe", "idleframe7")
                    end
                end
            end)
        end
    end

    local delayTime = (playFeatureIndex - 1) * interval + animTime
    self:waitWithDelay(delayTime, function()
        self:playBonusGameTriggerEffect(_func)
    end)
end

--[[
    free玩法的bonus飞到罐子
]]
function CodeGameScreenLeprechaunsCrockMachine:playEffect_buffBonusSymbol(_func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local freeGame = bonusInfo.freeGame or {}
    local playBuff = bonusInfo.playBuff or {}
    local playFlyIndex = 0

    if table.nums(freeGame) > 0 then
        for _pos, _ in pairs(freeGame) do
            playFlyIndex = playFlyIndex + 1
            local isFirst = playFlyIndex == 1
            self:playBonusSymbolCollectAnim(_pos, function()
                if isFirst then
                    self:hideReelMask(_func)
                    local isHave = self:getIsHaveFeatureBuff()
                    self:playGuoAndRoleEffect(isHave)
                end
            end, "free", true)
        end
    else
        self:hideReelMask()
        if _func then
            _func()
        end
    end
end

--[[
    玩法buff 加成bonus 飞
]]
function CodeGameScreenLeprechaunsCrockMachine:playFeatureBuffFly(_func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local playBuff = bonusInfo.playBuff or {}

    local newPlayBuff = {}
    for _pos, _ in pairs(playBuff) do
        table.insert(newPlayBuff, _pos)
    end

    -- 排序 从上到下 从左到右
    if #newPlayBuff > 1 then
        table.sort(newPlayBuff, function(_posA, _posB)
            local fixPosA = self:getRowAndColByPos(_posA)
            local fixPosB = self:getRowAndColByPos(_posB)
            if fixPosA.iY == fixPosB.iY then
                return fixPosA.iX > fixPosB.iX
            else
                return fixPosA.iY < fixPosB.iY
            end
        end)
    end

    local playBuffIndex = 0
    for _index, pos in ipairs(newPlayBuff) do
        playBuffIndex = playBuffIndex + 1
        local delayTime = playBuffIndex * 0.3
        self:waitWithDelay(delayTime, function()
            self:playBonusSymbolCollectAnim(pos, function()
                local actionframeName = nil
                if self.m_guoSpineType == 1 then
                    self.m_guoSpineType = 2
                    actionframeName = "switch"
                else
                    actionframeName = "actionframe1"
                end
                util_spinePlay(self.m_bonusCollectGuoSpine, actionframeName, false)
                util_spineEndCallFunc(self.m_bonusCollectGuoSpine, actionframeName, function()
                    util_spinePlay(self.m_bonusCollectGuoSpine, "idle2", true)
                end)

                if self.m_isPlayRoleEffect then
                    self.m_isPlayRoleEffect = false
                    --角色只播放一次
                    util_spinePlay(self.m_jueSeSpine, "actionframe_jingya", false)
                    util_spineEndCallFunc(self.m_jueSeSpine,"actionframe_jingya",function ()
                        self:playRoleIdle()
                    end)
                end

                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_boost_fly_fankui)

                self:showGuoNumsByBuff()
                
                if _index == #newPlayBuff then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_boost_fly_fankui_wow)
                    if _func then
                        _func()
                    end
                end
            end, "buff")
        end)
    end

    if #newPlayBuff <= 0 then
        if _func then
            _func()
        end
    end
end

--[[
    显示金色 锅上面的数字
]]
function CodeGameScreenLeprechaunsCrockMachine:showGuoNumsByBuff()
    self.m_guoNums = self.m_guoNums + 1
    -- 正常不会有问题 防止出错
    if self.m_guoNums > 3 then
        self.m_guoNums = 1
    end
    for i=1,3 do
        self.m_bonusCollectGuoSpine.numsNode:findChild("nums_"..i):setVisible(i == self.m_guoNums)
    end
end

--[[
    收集玩法的bonus飞到罐子
]]
function CodeGameScreenLeprechaunsCrockMachine:playEffect_collectBonusSymbol(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local feature = bonusInfo.feature or {}

    local playFlyIndex = 0
    for _pos, _ in pairs(feature) do
        playFlyIndex = playFlyIndex + 1
        local isFirst = playFlyIndex == 1
        self:playBonusSymbolCollectAnim(_pos, function()
            if isFirst then
                local isHave = self:getIsHaveFeatureBuff()
                self:playGuoAndRoleEffect(isHave, function()
                    if _fun then
                        _fun()
                    end
                end, "pick")
            end
        end, "pick")
    end
end

--[[
    收集 bonus的时候 锅的效果 和 角色的效果
]]
function CodeGameScreenLeprechaunsCrockMachine:playGuoAndRoleEffect(_isHaveBuff, _func, _bonusType)
    if _bonusType == "pick" then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_jackpot_feature_fly_fankui)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_fly_over)
    end

    local actionframeName = nil
    local idleName = nil
    if _isHaveBuff then
        actionframeName = "actionframe1"
        idleName = "idle2"
    else
        actionframeName = "actionframe"
        idleName = "idle"
    end
    util_spinePlay(self.m_bonusCollectGuoSpine, actionframeName, false)
    util_spineEndCallFunc(self.m_bonusCollectGuoSpine, actionframeName, function()
        util_spinePlay(self.m_bonusCollectGuoSpine, idleName, true)
        if _func then
            _func()
        end
    end)

    util_spinePlay(self.m_jueSeSpine, "actionframe_guzhang", false)
    util_spineEndCallFunc(self.m_jueSeSpine,"actionframe_guzhang",function ()
        self:playRoleIdle()
    end)
end

--[[
    重新整理pick玩法的数据
]]
function CodeGameScreenLeprechaunsCrockMachine:getPickBonusData(_list)
    local newList = {}
    for _index, _data in ipairs(_list) do
        for _jackpotName, _multiply in pairs(_data) do
            local jackpotData = {}
            jackpotData.jackpotName = _jackpotName
            jackpotData.multiply = _multiply
            table.insert(newList, jackpotData)
        end
    end
    
    return newList
end

--[[
    播放玩法 对应的bonus图标 触发动画
]]
function CodeGameScreenLeprechaunsCrockMachine:playBonusGameTriggerEffect(_func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local feature = bonusInfo.feature or {}
    local freeGame = bonusInfo.freeGame or {}
    local bonusData = table.nums(feature) > 0 and feature or freeGame

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_bonus_trigger)

    for _pos, _ in pairs(bonusData) do
        local fixPos = self:getRowAndColByPos(tonumber(_pos))
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if slotsNode and slotsNode.p_symbolType then

            slotsNode:runAnim("actionframe3", false, function()
                slotsNode:runAnim("idleframe7", true)
            end)

            self:playBonus1SpineEffect(slotsNode, "actionframe3", "idleframe7")
        end
    end

    self:waitWithDelay(45/30, function()
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenLeprechaunsCrockMachine:playEffect_bonusGame(_func)
    -- 播放罐子的触发动画
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "pickFeature")
    end
    self:playTriggerEffectByBonus(false, function()
        self:playGuoChangEffect(function()
            self:playEffect_bonusGameStage1()
        end, function()
            self:playEffect_bonusGameStage2(_func)
        end, true)
    end)
end

--[[
    切换pick玩法界面 处理数据
]]
function CodeGameScreenLeprechaunsCrockMachine:playEffect_bonusGameStage1()
    local selfData  = self.m_runSpinResultData.p_selfMakeData
    local bonusInfo = selfData.bonusInfo or {}
    local playBuffNums = bonusInfo.playBuff and table.nums(bonusInfo.playBuff) or 0

    --切换展示
    self:findChild("Node_baseOrFree"):setVisible(false)
    self:setReelBg(3)
    self.m_bonusGame:setVisible(true)
    self.m_bonusGame:resetUi(playBuffNums)

    -- 重置锅的状态
    if self.m_guoSpineType == 2 then
        self.m_guoSpineType = 1
        util_spinePlay(self.m_bonusCollectGuoSpine, "idle", true)
    end
end

--[[
    开始pick玩法
]]
function CodeGameScreenLeprechaunsCrockMachine:playEffect_bonusGameStage2(_func)
    local selfData  = self.m_runSpinResultData.p_selfMakeData
    local bonusInfo = selfData.bonusInfo or {}
    local bonusData = {} 
    bonusData.index = 1
    bonusData.pickJackpots = self:getPickBonusData(clone(selfData.pickJackpots))
    bonusData.extraJackpots = self:getPickBonusData(clone(selfData.extraJackpots))
    bonusData.getJackpot = clone(selfData.getJackpot)
    bonusData.playBuffNums = bonusInfo.playBuff and table.nums(bonusInfo.playBuff) or 0
    bonusData.bonusCoins = selfData.bonusCoins or 0

    -- 重置背景音乐
    self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_Pick_Bg)
    self:setMaxMusicBGVolume()
    local jackpotList = self:getJackpotData()
    self.m_bonusGame:startGame(bonusData, function()
        self:showJackpotView(jackpotList, function()
            self:playGuoChangEffect( 
                function()
                    --切换展示
                    if self.m_bProduceSlots_InFreeSpin then
                        self:setReelBg(2)
                    else
                        self:setReelBg(1)
                    end
                    self:findChild("Node_baseOrFree"):setVisible(true)
                    self.m_bonusGame:setVisible(false)
                end,
                function()
                    if not self.m_bProduceSlots_InFreeSpin then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                    end
                    self:resetMusicBg()
                    if _func then
                        _func()
                    end
                end
            )
        end)
    end)
end

function CodeGameScreenLeprechaunsCrockMachine:isLastFreeSpin()
    local collectLeftCount  = globalData.slotRunData.freeSpinCount
    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
    local bLast = self.m_bProduceSlots_InFreeSpin and collectLeftCount ~= collectTotalCount and 0 == collectLeftCount
    return bLast 
end

--[[
    重新构造jackpot赢钱数据
]]
function CodeGameScreenLeprechaunsCrockMachine:getJackpotData( )
    local jackpotCoins  = self.m_runSpinResultData.p_jackpotCoins
    local jackpotList = {}
    for _jackpotName, _coins in pairs(jackpotCoins) do
        jackpotList.name = _jackpotName
        jackpotList.coins = _coins
    end
    if jackpotList.name == "Grand" then
        jackpotList.index = 1
    elseif jackpotList.name == "Mega" then
        jackpotList.index = 2
    elseif jackpotList.name == "Major" then
        jackpotList.index = 3
    elseif jackpotList.name == "Minor" then
        jackpotList.index = 4
    elseif jackpotList.name == "Mini" then
        jackpotList.index = 5
    end
    return jackpotList
end

-- 展示jackpot弹板
function CodeGameScreenLeprechaunsCrockMachine:showJackpotView(_list, _fun)
    local jackpotData = _list
    if not jackpotData then
        _fun()
        return
    end
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(jackpotData.coins, jackpotData.index)
    local jackPotWinView = util_createView("CodeLeprechaunsCrockSrc.LeprechaunsCrockJackPotWinView", jackpotData)
    jackPotWinView:setOverAniRunFunc(function()
        if _fun then
            _fun()
        end
    end)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self)

    -- 刷新底栏
    local bottomWinCoin = self:getCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + jackpotData.coins)
    self:updateBottomUICoins(0, jackpotData.coins, false, true, false)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenLeprechaunsCrockMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenLeprechaunsCrockMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenLeprechaunsCrockMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( )
    end)

end

--[[
    检测添加大赢光效
]]
function CodeGameScreenLeprechaunsCrockMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_BIGWIN - 1
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

function CodeGameScreenLeprechaunsCrockMachine:slotReelDown()

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            --只有播期待的恢复idle状态
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName == "idleframe2" then
                local ccbNode = symbolNode:getCCBNode()
                if ccbNode then
                    util_spineMix(ccbNode.m_spineNode, symbolNode.m_currAnimName, "idleframe3", 0.5)
                end
                symbolNode:runAnim("idleframe3", true)
            end
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenLeprechaunsCrockMachine.super.slotReelDown(self)
end

function CodeGameScreenLeprechaunsCrockMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenLeprechaunsCrockMachine:getBottomUINode()
    return "CodeLeprechaunsCrockSrc.LeprechaunsCrockGameBottomNode"
end

function CodeGameScreenLeprechaunsCrockMachine:getBaseReelGridNode()
    return "CodeLeprechaunsCrockSrc.LeprechaunsCrockSlotNode"
end

--获取底栏金币
function CodeGameScreenLeprechaunsCrockMachine:getCurBottomWinCoins()
    local winCoin = 0

    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
        if "" == sCoins then
            return winCoin
        end
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end

--[[
    获取bonus1上的spine 执行动画
]]
function CodeGameScreenLeprechaunsCrockMachine:playBonus1SpineEffect(_slotsNode, _actionframeName, _idleName, _skinName)
    local csbNode = _slotsNode:getCCBNode()
    if csbNode.bonusSpineNode then
        if _skinName then
            csbNode.bonusSpineNode:setSkin(_skinName)
        end
        self:playBonus1Effect(csbNode.bonusSpineNode, _actionframeName, _idleName)
    end
end
--[[
    bonus1时间线
]]
function CodeGameScreenLeprechaunsCrockMachine:playBonus1Effect(_spine, _actionName, _idleName)
    util_spinePlay(_spine, _actionName, false)
    util_spineEndCallFunc(_spine, _actionName, function ()
        util_spinePlay(_spine, _idleName, true)
    end)
end

-- 循环处理轮盘小块
function CodeGameScreenLeprechaunsCrockMachine:baseReelSlotsNodeForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if isJumpFun then
                return
            end
        end
    end
end

--[[
    延时函数
]]
function CodeGameScreenLeprechaunsCrockMachine:waitWithDelay(time, endFunc)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(endFunc) == "function" then
                endFunc()
            end
        end,
        time
    )

    return waitNode
end

--[[
    判断这次spin 是否有buff
]]
function CodeGameScreenLeprechaunsCrockMachine:getIsHaveFeatureBuff( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local playBuff = bonusInfo.playBuff or {}
    if table.nums(playBuff) > 0 then
        return true
    else
        return false
    end
end

--[[
    连线和 玩法同时出现的时候 先显示连线赢钱
]]
function CodeGameScreenLeprechaunsCrockMachine:showLineFrame()
    local lineWinCoins  = self:getClientWinCoins()
    self.m_iOnceSpinLastWin = lineWinCoins
    local bottomWinCoin = 0
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        bottomWinCoin = self:getCurBottomWinCoins()
    end
    self:setLastWinCoin(bottomWinCoin + lineWinCoins)

    CodeGameScreenLeprechaunsCrockMachine.super.showLineFrame(self)
end

--[[
    特殊bonus 图标切换皮肤
]]
function CodeGameScreenLeprechaunsCrockMachine:bonusChangeShow(actionName,node,skinName,func)

    local ccbNode = node:getCCBNode()
    if not ccbNode then
        node:checkLoadCCbNode()
    end
    ccbNode = node:getCCBNode()
    if ccbNode then
        ccbNode.m_spineNode:setSkin(skinName)
    end
    node:runAnim(actionName,false,function()
        if func then
            func()
        end
    end)
end

function CodeGameScreenLeprechaunsCrockMachine:updateReelGridNode(symbolNode)

    local symbolType = symbolNode.p_symbolType
    if symbolType == self.SYMBOL_BONUS then
        self:setSpecialNodeScore(self,{symbolNode})
    end
end

--[[
     给 bonus1 小块进行 挂载spine
]]
function CodeGameScreenLeprechaunsCrockMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]

    if not symbolNode then
        return
    end

    if not symbolNode.p_symbolType then
        return
    end

    local csbNode = symbolNode:getCCBNode()
    --创建spine
    if not csbNode.bonusSpineNode then
        local spineNode = util_spineCreate("Socre_LeprechaunsCrock_Bonus_1",true,true)
        symbolNode:getCcbProperty("Node_spine"):addChild(spineNode)
        spineNode:setSkin("JIN_Money")
        util_spinePlay(spineNode,"idleframe",false)
        csbNode.bonusSpineNode = spineNode
    else
        util_spinePlay(csbNode.bonusSpineNode,"idleframe",false)
    end
end

function CodeGameScreenLeprechaunsCrockMachine:playCustomSpecialSymbolDownAct( slotNode )

    if slotNode and slotNode.p_symbolType == self.SYMBOL_BONUS then
        local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0)
        symbolNode:runAnim("idleframe")

        self:playBonus1SpineEffect(symbolNode, "buling", "idleframe2")
    end

    if slotNode and slotNode.p_symbolType == self.SYMBOL_BONUS2 then
        local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0)
        self:bonusChangeShow("buling", symbolNode, "Credit", function()
            symbolNode:runAnim("idleframe2")
        end)
    end
end

function CodeGameScreenLeprechaunsCrockMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local coins = bonusInfo.coins or {}
    local feature = bonusInfo.feature or {}

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end

    if notAdd then
        if table.nums(coins) > 0 or table.nums(feature) > 0 then
            notAdd = false
        end
    end

    return notAdd
end

--[[
    判断服务器返回的数据 是否触发预告
]]
function CodeGameScreenLeprechaunsCrockMachine:getIsPlayYuGao( )
    local reels = self.m_runSpinResultData.p_reels or {}
    local bonusNum = 0
    for _row, _colData in ipairs(reels) do
        for _col, _symbolType in ipairs(_colData) do
            if _symbolType == self.SYMBOL_BONUS or _symbolType == self.SYMBOL_BONUS2 then
                bonusNum = bonusNum + 1
            end
        end
    end

    self.m_symbolBonusCounts = bonusNum
    if bonusNum >= 6 or self:isTriggerOpenFeatureSymbol() then
        local random = math.random(1,10)
        if random <= 7 then
            return true
        else
            return false
        end
    else
        return false
    end
end
--[[
    播放预告中奖
]]
function CodeGameScreenLeprechaunsCrockMachine:playYuGaoAct(func)
    self.m_playYuGaoSoundIndex = self.m_playYuGaoSoundIndex + 1
    if self.m_playYuGaoSoundIndex > 2 then
        self.m_playYuGaoSoundIndex = 1
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_LeprechaunsCrock_yugao"..self.m_playYuGaoSoundIndex])

    self.m_yugaoEffect:setVisible(true)
    self.m_yugaoEffectSpine:setVisible(true)

    self.m_yugaoEffect:runCsbAction("actionframe")
    util_spinePlay(self.m_yugaoEffectSpine,"actionframe",false)
    util_spineEndCallFunc(self.m_yugaoEffectSpine,"actionframe",function ()
        self.m_yugaoEffect:setVisible(false)
        self.m_yugaoEffectSpine:setVisible(false)

        if func then
            func()
        end
    end)

    -- 角色动画
    util_spinePlay(self.m_jueSeSpine, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_jueSeSpine,"actionframe_yugao",function ()
        self:playRoleIdle()
    end)

    -- 角色金币动画
    self.m_jueSeJinBiSpine:setVisible(true)
    util_spinePlay(self.m_jueSeJinBiSpine, "actionframe_yugao_jinbi", false)
    util_spineEndCallFunc(self.m_jueSeJinBiSpine,"actionframe_yugao_jinbi",function ()
        self.m_jueSeJinBiSpine:setVisible(false)
    end)
end

--[[
    棋盘加压暗，在出现大于等于6个Bonus时，开始FortuneCoin结算时要压暗棋盘，Bonus图标在最上面
]]
function CodeGameScreenLeprechaunsCrockMachine:showReelMask(_func)
    local delayTime = 0
    if not self.m_stopLineFrame and self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
        delayTime = 1.1
    end

    if self.m_reelMask:isVisible() or self.m_symbolBonusCounts < 6 then
        self:waitWithDelay(delayTime, function()
            if 0 ~= delayTime then
                self.m_stopLineFrame = true
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()
            end
            if _func then
                _func()
            end
        end)
        return
    end
    -- sc取消提层
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        local symbolType = _slotsNode.p_symbolType
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local scParent = _slotsNode:getParent()
            if scParent == self.m_clipParent then
                _slotsNode:putBackToPreParent()
            end
        end
    end)

    self:waitWithDelay(delayTime, function()
        if 0 ~= delayTime then
            self.m_stopLineFrame = true
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
        end
        -- darkstart
        self.m_reelMask:setVisible(true)
        self.m_reelMask:runCsbAction("start", false, function()
            self.m_reelMask:runCsbAction("idle", true)
            if _func then
                _func()
            end
        end)
    end)
end

function CodeGameScreenLeprechaunsCrockMachine:hideReelMask(_func)
    if not self.m_reelMask:isVisible() then
        if _func then
            _func()
        end
        return
    end
    -- darkover
    self.m_reelMask:runCsbAction("over", false, function()
        self.m_reelMask:setVisible(false)
        if _func then
            _func()
        end
    end)
end

--[[
    过场动画
    _isStart 表示是否进入pick玩法
]]

function CodeGameScreenLeprechaunsCrockMachine:playGuoChangEffect(_func1, _func2, _isStart)
    if _isStart then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_guochang)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pickOver_guochang)
    end

    self.m_guochangEffect:setVisible(true)
    util_spinePlay(self.m_guochangEffect, "actionframe_guochang", false)

    -- 切换 24帧
    self:waitWithDelay(24/30, function()
        if _func1 then
            _func1()
        end
    end)

    -- 结束 65帧
    self:waitWithDelay(65/30, function()
        if _func2 then
            _func2()
        end
        self.m_guochangEffect:setVisible(false)
    end)
end

--[[
    断线重连的时候 显示bonus
]]
function CodeGameScreenLeprechaunsCrockMachine:showChangeBonusSymbol( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusInfo = selfData.bonusInfo or {}
    local coins = bonusInfo.coins or {}
    local addCoinsBuff = bonusInfo.addCoinsBuff or {}
    local feature = bonusInfo.feature or {}
    local freeGame = bonusInfo.freeGame or {}
    local playBuff = bonusInfo.playBuff or {}

    local fnChangeBonusSymbol = function(_pos, _iconData, _type)
        local slotsPos = tonumber(_pos)
        local fixPos = self:getRowAndColByPos(slotsPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

        if slotsNode and slotsNode.p_symbolType == self.SYMBOL_BONUS then
            local nodeType = "Node_money"
            local skinName = "JIN_Money"
            if _type == "money" then
                nodeType = "Node_money"
                skinName = "JIN_Money"
            elseif _type == "free" then
                nodeType = "Node_FG"
                skinName = "JIN_FG"
            end
            self:showBonus1ByType(slotsNode, nodeType, _iconData)
            slotsNode:runAnim("idleframe7", true)
            local csbNode = slotsNode:getCCBNode()
            if csbNode.bonusSpineNode then
                csbNode.bonusSpineNode:setSkin(skinName)
                util_spinePlay(csbNode.bonusSpineNode,"idleframe7",true)
            end
        elseif slotsNode and slotsNode.p_symbolType == self.SYMBOL_BONUS2 then
            if _type == "coinsBuff" then
                local spineName = "Credit"
                if tonumber(_iconData) == 2 then
                    spineName = "Super"
                elseif tonumber(_iconData) == 3 then
                    spineName = "Mega"
                end
                self:bonusChangeShow("idleframe5", slotsNode, spineName)
            elseif _type == "FeatureBuff" then
                self:bonusChangeShow("idleframe5", slotsNode, "FeatureBuff")
            end
        end
    end

    -- 直接翻开
    --金币
    for _pos, _iconData in pairs(coins) do
        fnChangeBonusSymbol(_pos, _iconData, "money")
    end

    --金币buff
    for _pos, _iconData in pairs(addCoinsBuff) do
        fnChangeBonusSymbol(_pos, _iconData, "coinsBuff")
    end

    --free玩法bonus
    for _pos, _iconData in pairs(freeGame) do
        fnChangeBonusSymbol(_pos, _iconData, "free")
    end

    --free玩法buff
    for _pos, _iconData in pairs(playBuff) do
        fnChangeBonusSymbol(_pos, _iconData, "FeatureBuff")
    end
end
--[[
    音效落地音效播放接口
    _soundType 不同档位的音效需要传入对应的信号值
    _maxSound 不同档位的音效需要传入等级最高的音效路径
    tip:有_soundType必然有_maxSound,无_soundType无_maxSound
]]
function CodeGameScreenLeprechaunsCrockMachine:playBulingSymbolSounds(_iCol, _soundName, _soundType)
    local soundId = nil
    local soundValue = _soundType or _soundName
    if soundValue == self.SYMBOL_BONUS2 then
        soundValue = self.SYMBOL_BONUS
    end

    if _iCol and _soundName then
        if self:getGameSpinStage() == QUICK_RUN then
            self:setQuickStopBulingSymbolSoundId(_soundName, soundValue)
        else
            local bulingInfos = self.m_symbolBulingSoundArray[_iCol]
            local Info = bulingInfos[tostring(soundValue)]
            if not Info then
                soundId = gLobalSoundManager:playSound(_soundName)
                self:setNormalBulingSymbolSoundId(_iCol, soundValue)
            end
        end
    end

    return soundId
end

--[[
    根据配置初始轮盘
]]
function CodeGameScreenLeprechaunsCrockMachine:initSlotNodes()
    CodeGameScreenLeprechaunsCrockMachine.super.initSlotNodes(self)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_BONUS_COINS then
                symbolNode:getCcbProperty("m_lb_coins_1"):setString(util_formatCoins(5 * lineBet, 3, false, true, true))
                self:updateLabelSize({label = symbolNode:getCcbProperty("m_lb_coins_1"),sx = 0.9,sy = 0.9}, 237)
            end
        end
    end
end

function CodeGameScreenLeprechaunsCrockMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenLeprechaunsCrockMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenLeprechaunsCrockMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    if self:isTriggerBonusGame() then
        self.m_isAddBigWinLightEffect = false
    end
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenLeprechaunsCrockMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
        local posY = self.m_bottomUI.m_bigWinLabCsb:getPositionY()
        posY = posY + 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    else
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.6)
    end
    
    
    --通用底部跳字动效
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    local params = {
        overCoins  = winCoins,
        jumpTime   = 1,
        animName   = "actionframe3",
    }
    self:playBottomBigWinLabAnim(params)
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenLeprechaunsCrockMachine:showBigWinLight(_func)
    -- local random = math.random(1, 3)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_LeprechaunsCrock_bigWin_yugao1"])

    self.m_bigwinEffect:setVisible(true)

    local actionName = "actionframe"

    util_spinePlay(self.m_bigwinEffect,actionName)
    util_spineEndCallFunc(self.m_bigwinEffect,actionName,function()
        self.m_bigwinEffect:setVisible(false)
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenLeprechaunsCrockMachine:scaleMainLayer()
    self.super.scaleMainLayer(self)
    local mainScale = self.m_machineRootScale
    if display.width / display.height <= 920/768 then
        mainScale = mainScale * 0.96
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 20)
    elseif display.width / display.height <= 1152/768 then
        mainScale = mainScale * 0.95
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 25)
    elseif display.width / display.height <= 1228/768 then
        mainScale = mainScale * 0.95
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 10)
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 25)   
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end

return CodeGameScreenLeprechaunsCrockMachine






