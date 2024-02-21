---
-- island li
-- 2019年1月26日
-- CodeGameScreenAChristmasCarolMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "AChristmasCarolPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenAChristmasCarolMachine = class("CodeGameScreenAChristmasCarolMachine", BaseSlotoManiaMachine)

CodeGameScreenAChristmasCarolMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenAChristmasCarolMachine.SYMBOL_BASE_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 --94
CodeGameScreenAChristmasCarolMachine.SYMBOL_BASE_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 --95
CodeGameScreenAChristmasCarolMachine.SYMBOL_BASE_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3 --96
CodeGameScreenAChristmasCarolMachine.SYMBOL_RESPIN_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4 --97
CodeGameScreenAChristmasCarolMachine.SYMBOL_RESPIN_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5 --98
CodeGameScreenAChristmasCarolMachine.SYMBOL_10 = 9
CodeGameScreenAChristmasCarolMachine.SYMBOL_EMPTY = 100   -- 空信号
CodeGameScreenAChristmasCarolMachine.SYMBOL_EMPTY1 = 101   -- 临时 空信号

CodeGameScreenAChristmasCarolMachine.m_chipList = nil
CodeGameScreenAChristmasCarolMachine.m_playAnimIndex = 0
CodeGameScreenAChristmasCarolMachine.m_lightScore = 0 

-- 自定义动画的标识
CodeGameScreenAChristmasCarolMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --收集bonus玩法
CodeGameScreenAChristmasCarolMachine.MOVE_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --wild上下移动

-- 构造函数
function CodeGameScreenAChristmasCarolMachine:ctor()
    CodeGameScreenAChristmasCarolMachine.super.ctor(self)
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0 

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true
    self.m_collectBallSpineList = {}
    self.m_collectRoleSpineList = {}
    self.m_betCollectList = {} -- 存储不同bet对应的数据
    self.m_flyLiZiList = {} --预创建多个粒子
    self.m_addCoinsLiZiList = {}
    self.m_addCoinsLiZiIndex = 0
    self.m_respinReelsList = {}
    self.m_isPlayUpdateRespinNums = true --是否播放刷新respin次数
    self.m_respinJiManNodeList = {}
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}
    self.m_isPlayBarOver = true
    --init
    self:initGame()
end

function CodeGameScreenAChristmasCarolMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenAChristmasCarolMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "AChristmasCarol"  
end

function CodeGameScreenAChristmasCarolMachine:initUI()
    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    self:initJackPotBarView() 

    -- 预创建base下收集需要用到的粒子
    for index = 1, 15 do
        local flyNode = util_createAnimation("AChristmasCarol_bouns_lizi.csb")
        self.m_effectNode:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
        flyNode:setVisible(false)
        table.insert(self.m_flyLiZiList, flyNode)
    end

    -- 预创建respin下每列差一个特效(两个棋盘 10列)
    for index = 1, 5 do
        local respinReelsNode = util_createAnimation("AChristmasCarol_respin_chayige.csb")
        self:findChild("Node_respin_reels_kuang"):addChild(respinReelsNode)
        respinReelsNode:setVisible(false)
        table.insert(self.m_respinReelsList, respinReelsNode)
    end

    -- respin加钱动画粒子
    for index = 1, 15 do
        local flyNode = util_createAnimation("AChristmasCarol_respin_tw.csb")
        self.m_effectNode:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
        flyNode:setVisible(false)
        table.insert(self.m_addCoinsLiZiList, flyNode)
    end

    --mini轮盘
    self.m_miniMachine = util_createView("AChristmasCarolSrc.AChristmasCarolMiniMachine",{parent = self})
    self:findChild("Node_respin_double_sets"):addChild(self.m_miniMachine)
    self.m_miniMachine:setVisible(false)
    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniMachine.m_touchSpinLayer)
    end

    -- respin每列集满动画
    for index = 1, 10 do
        local light_effect = util_createAnimation("AChristmasCarol_respin_zhenglie.csb")
        if index <= 5 then
            self:findChild("Node_jiman"):addChild(light_effect)
        else
            self.m_miniMachine:findChild("Node_jiman"):addChild(light_effect)
        end
        light_effect:setVisible(false)
        table.insert(self.m_respinJiManNodeList, light_effect)
    end

    -- 预创建respin下每列差一个特效(两个棋盘 10列)
    for index = 6, 10 do
        local respinReelsNode = util_createAnimation("AChristmasCarol_respin_chayige.csb")
        self.m_miniMachine:findChild("Node_respin_reels_kuang"):addChild(respinReelsNode)
        respinReelsNode:setVisible(false)
        table.insert(self.m_respinReelsList, respinReelsNode)
    end

    -- respin 计数框
    self.m_respinBarView = util_createView("AChristmasCarolSrc.AChristmasCarolRespinBar", {machine = self})
    self:findChild("Node_respin_spinnum"):addChild(self.m_respinBarView)
    self.m_respinBarView:setVisible(false)

    -- respin grand框
    self.m_respinGrandBarView = util_createView("AChristmasCarolSrc.AChristmasCarolRespinGrandBar", {machine = self})
    self:findChild("Node_respin_grand_bar"):addChild(self.m_respinGrandBarView)
    self.m_respinGrandBarView:setVisible(false)

    -- respin 单个棋盘的时候 tips
    self.m_respinTips = util_createAnimation("AChristmasCarol_respin_tips.csb")
    self:findChild("Node_respin_tips"):addChild(self.m_respinTips)
    self.m_respinTips:runCsbAction("idle", true)
    self.m_respinTips:setVisible(false)

    -- respin 触发的时候 压暗
    self.m_respinTriggerDark = util_createAnimation("AChristmasCarol_dark.csb")
    self:findChild("Node_dark"):addChild(self.m_respinTriggerDark)
    self.m_respinTriggerDark:runCsbAction("idle", true)
    self.m_respinTriggerDark:setVisible(false)

    self:changeCoinWinEffectUI(self:getModuleName(), "AChristmasCarol_totalwin.csb")

    self:setReelBg(1)
    self:addColorLayer()
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenAChristmasCarolMachine:initSpineUI()
    for index=1, 3 do
        -- 收集的三种球
        self.m_collectBallSpineList[index] = util_spineCreate("AChristmasCarol_base_buffball", true, true)
        self:findChild("Node_buffball_"..index):addChild(self.m_collectBallSpineList[index], 1)
        util_spinePlay(self.m_collectBallSpineList[index], "idle"..index.."_1", true)

        self.m_collectBallSpineList[index].m_shengJiSpine = util_spineCreate("AChristmasCarol_buffball_shengjitx", true, true)
        self:findChild("Node_buffball_"..index):addChild(self.m_collectBallSpineList[index].m_shengJiSpine, 2)
        self.m_collectBallSpineList[index].m_shengJiSpine:setVisible(false)
    end

    for index=1, 3 do
        -- 收集的三种球 后面的人物 
        if index == 2 then
            self.m_collectRoleSpineList[index] = util_spineCreate("AChristmasCarol_base_npc2", true, true)
            self:findChild("npc_"..index):addChild(self.m_collectRoleSpineList[index])
        else
            self.m_collectRoleSpineList[index] = util_spineCreate("AChristmasCarol_base_juese", true, true)
            self:findChild("npc_"..index):addChild(self.m_collectRoleSpineList[index])
        end
        util_spinePlay(self.m_collectRoleSpineList[index], "idle2_"..index, true)
    end

    -- 预告动画
    self.m_yugaoSpineEffect = util_spineCreate("AChristmasCarol_yugao", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpineEffect)
    self.m_yugaoSpineEffect:setVisible(false)

    -- 大赢前 预告动画
    self.m_bigWinEffect1 = util_spineCreate("AChristmasCarol_bigwin_bg", true, true)
    self:findChild("Node_bigwin_bg"):addChild(self.m_bigWinEffect1)
    self.m_bigWinEffect1:setVisible(false)

    self.m_bigWinEffect2 = util_spineCreate("AChristmasCarol_bigwin", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigWinEffect2)
    local startPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self:findChild("Node_bigwin"))
    self.m_bigWinEffect2:setPosition(startPos)
    self.m_bigWinEffect2:setVisible(false)

    -- respin过场动画
    self.m_respinGuoChangEffect = util_spineCreate("AChristmasCarol_base_juese", true, true)
    self:findChild("Node_yugao"):addChild(self.m_respinGuoChangEffect)
    self.m_respinGuoChangEffect:setVisible(false)

    -- respin 单个棋盘的时候 大角色
    self.m_respinRoleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
    self:findChild("Node_respin_npc"):addChild(self.m_respinRoleSpine)
    self.m_respinRoleSpine:setVisible(false)

    -- respin 触发玩法进入respin的时候 次数增加为4次
    self.m_respinAddNumsSpine = util_spineCreate("AChristmasCarol_respin_tx", true, true)
    self:findChild("Node_yugao"):addChild(self.m_respinAddNumsSpine)
    self.m_respinAddNumsSpine:setVisible(false)
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2respin第一种 3respin第两种 4respin第三种 5respin多种
]]
function CodeGameScreenAChristmasCarolMachine:setReelBg(_BgIndex)
    if _BgIndex ~= 1 then
        if self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 0 then
            _BgIndex = 2
        elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
            _BgIndex = 3
        elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
            _BgIndex = 4
        else
            _BgIndex = 5
        end
    end
    self.m_gameBg:findChild("base"):setVisible(_BgIndex == 1)
    self.m_gameBg:findChild("buff_1"):setVisible(_BgIndex == 2)
    self.m_gameBg:findChild("buff_2"):setVisible(_BgIndex == 3)
    self.m_gameBg:findChild("buff_3"):setVisible(_BgIndex == 4)
    self.m_gameBg:findChild("buff_group"):setVisible(_BgIndex == 5)
    self:findChild("Node_base_kuang"):setVisible(_BgIndex == 1)
    self:findChild("Node_respin_kuang"):setVisible(_BgIndex ~= 1)
    self:findChild("Node_base_reel"):setVisible(_BgIndex == 1)
    self:findChild("Node_respin_reel"):setVisible(_BgIndex ~= 1)
end

--[[
    每列添加滚动遮罩
]]
function CodeGameScreenAChristmasCarolMachine:addColorLayer()
    self.m_colorLayers = {}
    for i = 1, self.m_iReelColumnNum do
        --单列卷轴尺寸
        local reel = self:findChild("sp_reel_"..i-1)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()
        --棋盘尺寸
        local offsetSize = cc.size(4.5, 4.5)
        reelSize.width = reelSize.width * scaleX + offsetSize.width
        reelSize.height = reelSize.height * scaleY + offsetSize.height
        --遮罩尺寸和坐标
        local clipParent = self.m_onceClipNode or self.m_clipParent
        local panelOrder = 10000--REEL_SYMBOL_ORDER.REEL_ORDER_4--SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1

        local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
        panel:setOpacity(0)
        panel:setContentSize(reelSize.width, reelSize.height)
        panel:setPosition(cc.p(posX - offsetSize.width / 2, posY - offsetSize.height / 2))
        clipParent:addChild(panel, panelOrder)
        panel:setVisible(false)
        self.m_colorLayers[i] = panel
    end
end

--[[
    显示滚动遮罩
]]
function CodeGameScreenAChristmasCarolMachine:showColorLayer()
    for index, maskNode in ipairs(self.m_colorLayers) do
        maskNode:setVisible(true)
        maskNode:setOpacity(0)
        maskNode:runAction(cc.FadeTo:create(0.3, 150))
    end
end

--[[
    列滚动停止 渐隐
]]
function CodeGameScreenAChristmasCarolMachine:reelStopHideMask(col)
    local maskNode = self.m_colorLayers[col]
    local fadeAct = cc.FadeTo:create(0.1, 0)
    local func = cc.CallFunc:create( function()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct, func))
end

function CodeGameScreenAChristmasCarolMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_enter_game)
    end)
end

function CodeGameScreenAChristmasCarolMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenAChristmasCarolMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self.m_curTotalBet = toLongNumber(globalData.slotRunData:getCurTotalBet() or 0)
    self:updataCollectEffectByComeIn(true)
end

function CodeGameScreenAChristmasCarolMachine:addObservers()
    CodeGameScreenAChristmasCarolMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = toLongNumber(params[1])
        
        local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= toLongNumber(1) then
            soundIndex = 1
        elseif winRate > toLongNumber(1) and winRate <= toLongNumber(3) then
            soundIndex = 2
        elseif winRate > toLongNumber(3) then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = self.m_publicConfig.SoundConfig["sound_AChristmasCarol_winLines" .. soundIndex]
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updataCollectEffectByComeIn(false)
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenAChristmasCarolMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenAChristmasCarolMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenAChristmasCarolMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BASE_BONUS1  then
        return "Socre_AChristmasCarol_Bonus_1"
    elseif symbolType == self.SYMBOL_BASE_BONUS2 then
        return "Socre_AChristmasCarol_Bonus_3"
    elseif symbolType == self.SYMBOL_BASE_BONUS3 then
        return "Socre_AChristmasCarol_Bonus_2"
    elseif symbolType == self.SYMBOL_RESPIN_BONUS1 then
        return "Socre_AChristmasCarol_Chip_1"
    elseif symbolType == self.SYMBOL_RESPIN_BONUS2 then
        return "Socre_AChristmasCarol_Chip_2"
    elseif symbolType == self.SYMBOL_10 then
        return "Socre_AChristmasCarol_10"
    elseif symbolType == self.SYMBOL_EMPTY or symbolType == self.SYMBOL_EMPTY1 then
        return "Socre_AChristmasCarol_empty"
    end 
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenAChristmasCarolMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenAChristmasCarolMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BASE_BONUS1,count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BASE_BONUS2,count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BASE_BONUS3,count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_RESPIN_BONUS1,count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_RESPIN_BONUS2,count = 2}
    return loadNode
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenAChristmasCarolMachine:initGameStatusData(gameData)
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.bonusnum then
        self.m_betCollectList = gameData.gameConfig.extra.bonusnum
    end
    CodeGameScreenAChristmasCarolMachine.super.initGameStatusData(self, gameData)
    
end

--[[
    每次spin 保存bet对应的数据
]]
function CodeGameScreenAChristmasCarolMachine:updateBetNetReelsData(_runSpinResultData, _totalBet)
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        local selfdata = _runSpinResultData.p_selfMakeData or {}
        local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet() or 0)
        if not _totalBet then
            _totalBet = totalBet
        end
        if selfdata and selfdata.bonuslist then
            local collectData = self.m_betCollectList[tostring(_totalBet)]
            if collectData == nil then
                self.m_betCollectList[tostring(_totalBet)] = {}
                self.m_betCollectList[tostring(_totalBet)].bonuslist = selfdata.bonuslist
            else
                self.m_betCollectList[tostring(_totalBet)].bonuslist = selfdata.bonuslist
            end
        else
            local collectData = self.m_betCollectList[tostring(_totalBet)]
            if collectData == nil then
                self.m_betCollectList[tostring(_totalBet)] = {}
            end
        end
    end
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenAChristmasCarolMachine:MachineRule_initGame()
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenAChristmasCarolMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenAChristmasCarolMachine:slotOneReelDown(reelCol)    
    CodeGameScreenAChristmasCarolMachine.super.slotOneReelDown(self,reelCol)
    self:reelStopHideMask(reelCol)
end

--[[
    滚轮停止
]]
function CodeGameScreenAChristmasCarolMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenAChristmasCarolMachine.super.slotReelDown(self)
end

function CodeGameScreenAChristmasCarolMachine:beginReel()
    self:showColorLayer()
    self.m_isPlayShengJiSound = true
    self.m_curTotalBet = toLongNumber(globalData.slotRunData:getCurTotalBet() or 0)
    CodeGameScreenAChristmasCarolMachine.super.beginReel(self)
end

function CodeGameScreenAChristmasCarolMachine:reelSchedulerCheckAddNode(parentData, zOrder, preY, halfH, parentY, slotParent)
    if parentData.isReeling == true then
        -- 判断哪些元素需要移除出显示列表

        local columnData = self.m_reelColDatas[parentData.cloumnIndex]
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth

        if moveDiff <= 0 then
            local createNextSlotNode = function()
                local node = self:getSlotNodeWithPosAndType(parentData.symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
                local posY = preY + columnData.p_showGridH * 0.5

                node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

                zOrder = zOrder + parentData.order

                node.p_slotNodeH = columnData.p_showGridH
                node.p_symbolType = parentData.symbolType
                node.p_preSymbolType = parentData.preSymbolType
                node.p_showOrder = parentData.order

                node.p_reelDownRunAnima = parentData.reelDownAnima

                node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
                node.p_layerTag = parentData.layerTag

                local slotParentBig = parentData.slotParentBig
                -- 添加到显示列表
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, parentData.order, parentData.tag)
                else
                    slotParent:addChild(node, parentData.order, parentData.tag)
                end

                if node.p_symbolType ~= self.SYMBOL_BASE_BONUS1 and node.p_symbolType ~= self.SYMBOL_BASE_BONUS2 and node.p_symbolType ~= self.SYMBOL_BASE_BONUS3 then
                    node:runIdleAnim()
                end
                
                if parentData.isHide then
                    node:setVisible(false)
                end

                if self.m_bigSymbolInfos[node.p_symbolType] ~= nil then
                    local symbolCount = self.m_bigSymbolInfos[node.p_symbolType]

                    preY = posY + (symbolCount - 0.5) * columnData.p_showGridH
                else
                    preY = posY + 0.5 * columnData.p_showGridH -- 计算创建偏移位置到顶部区域y坐标
                end

                moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
                -- lastNode = node

                -- 创建下一个节点
                if parentData.isLastNode == true then -- 本列最后一个节点移动结束
                    -- 执行回弹, 如果不执行回弹判断是否执行
                    parentData.isReeling = false
                    -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
                    -- 创建一个假的小块 在回滚停止后移除
                    self:createResNode(parentData, node)
                else
                    -- 计算moveDiff 距离是否大于一个 格子， 如果是那么循环补齐多个格子， 以免中间缺失创建
                    self:createSlotNextNode(parentData)
                end
            end

            createNextSlotNode() -- 创建一次

            while (moveDiff < 0 and parentData.isReeling == true) do
                createNextSlotNode()
            end
        else
        end -- end if moveDiff <= 0 then

        self:changeSlotsParentZOrder(zOrder, parentData, slotParent) -- 重新设置zorder
    end -- end if parentData.isReeling == true
end

---------------------------------------------------------------------------

--[[
    进入关卡 刷新收集区域的状态
]]
function CodeGameScreenAChristmasCarolMachine:updataCollectEffectByComeIn(_isComeIn)
    if not _isComeIn then
        for _, _node in ipairs(self.m_flyLiZiList) do
            if _node:isVisible() then
                _node:stopAllActions()
                _node:setVisible(false)
            end
        end
        local runSpinResultData = clone(self.m_runSpinResultData or {})
        self:updateBetNetReelsData(runSpinResultData, self.m_curTotalBet)
    end

    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet() or 0)
    local collectData = self.m_betCollectList[tostring(totalBet)]
    for index = 1, 3 do
        if collectData and collectData.bonuslist then
        else
            collectData = {}
            collectData.bonuslist = {1, 1, 1}
        end
        util_spinePlay(self.m_collectBallSpineList[index], "idle"..index.."_"..collectData.bonuslist[index], true)
        if collectData.bonuslist[index] == 1 then
            self.m_collectRoleSpineList[index]:setVisible(false)
        else
            self.m_collectRoleSpineList[index]:setVisible(true)
            util_spinePlay(self.m_collectRoleSpineList[index], "idle"..collectData.bonuslist[index].."_"..index, true)
        end
    end
end

--[[
    判断是否触发收集bonus
]]
function CodeGameScreenAChristmasCarolMachine:isTriggerBonusCollect()
    local reels = self.m_runSpinResultData.p_reels or {}
    local specialBonusList = {}
    for _row, _colData in ipairs(reels) do
        for _col, _symbolType in ipairs(_colData) do
            if _symbolType == self.SYMBOL_BASE_BONUS1 or _symbolType == self.SYMBOL_BASE_BONUS2 or _symbolType == self.SYMBOL_BASE_BONUS3 then
                local pos = (_row - 1) * self.m_iReelColumnNum + (_col - 1)
                local data = {pos = pos, symbolType = _symbolType}
                table.insert(specialBonusList, data)
            end
        end
    end
    return specialBonusList
end

--[[
    判断是否触发wild移动
]]
function CodeGameScreenAChristmasCarolMachine:isTriggerMoveWild()
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfMakeData.basewild and #selfMakeData.basewild > 0 then
        for _col, _colType in ipairs(selfMakeData.basewild) do
            if _colType > 0 then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenAChristmasCarolMachine:MachineRule_network_InterveneSymbolMap()
    self.m_moveWildColList = {}
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local reels = self.m_runSpinResultData.p_reels or {}
    if selfMakeData.basewild and #selfMakeData.basewild > 0 then
        for _col, _colType in ipairs(selfMakeData.basewild) do
            if _colType > 0 then
                local moveRow = 2 -- 需要移动的行数
                if reels[2] and reels[2][_col] and reels[2][_col] == 92 then
                    moveRow = 1
                end
                if reels[1] and reels[1][_col] and reels[1][_col] == 92 then
                    local moveWildData = {col = _col, direction = "down", moveRow = moveRow}
                    table.insert(self.m_moveWildColList, moveWildData)
                end
                if reels[3] and reels[3][_col] and reels[3][_col] == 92 then
                    local moveWildData = {col = _col, direction = "up", moveRow = moveRow}
                    table.insert(self.m_moveWildColList, moveWildData)
                end
            end
        end
    end
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenAChristmasCarolMachine:addSelfEffect()
    if #self:isTriggerBonusCollect() > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型
    end

    if self:isTriggerMoveWild() then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.MOVE_WILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.MOVE_WILD_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenAChristmasCarolMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
        self:collectSpecialBonus_effect(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.MOVE_WILD_EFFECT then
        self:playMoveWild_effect(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    return true
end

--[[
    收集特殊bonus
]]
function CodeGameScreenAChristmasCarolMachine:collectSpecialBonus_effect(_func)
    local isPlayCollect = {true, true, true}
    local runSpinResultData = clone(self.m_runSpinResultData or {})
    local specialBonusList = self:isTriggerBonusCollect()
    for _index, _data in ipairs(specialBonusList) do
        local fixPos = self:getRowAndColByPos(_data.pos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if slotsNode and slotsNode.p_symbolType then
            local symbolType = clone(slotsNode.p_symbolType)
            if _index == 1 then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_bonus_collect)
            end
            slotsNode:runAnim("shouji", false, function()
                slotsNode:runAnim("idleframe1", true)
            end)
            self:playBonusSymbolCollectAnim(slotsNode, function()
                if isPlayCollect[symbolType-93] then
                    isPlayCollect[symbolType-93] = false
                    self:updataCollectEffect(symbolType, runSpinResultData)
                end
            end, function()
                if _index == #specialBonusList then
                    if _func then
                        _func()
                    end
                end
            end, function()
                if _index == #specialBonusList then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_bonus_collect_end)
                    self:updateBetNetReelsData(runSpinResultData)
                end
            end)
        end
    end
end

--[[
    收集动画之后 更新人物 和 球的动画
]]
function CodeGameScreenAChristmasCarolMachine:updataCollectEffect(_symbolType, _runSpinResultData)
    local index = _symbolType - 93
    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet() or 0)
    local collectData = clone(self.m_betCollectList[tostring(totalBet)] or {})
    local selfdata = _runSpinResultData.p_selfMakeData
    if selfdata and selfdata.bonuslist then
        local curBonusData = selfdata.bonuslist[index]
        if self:getIsPlayEffect() then
            local reExtra = _runSpinResultData.p_rsExtraData or {}
            if reExtra.mode then
                local modeType = 0
                if index == 1 then
                    modeType = math.floor(tonumber(reExtra.mode)/100)
                elseif index == 2 then
                    modeType = math.floor((tonumber(reExtra.mode)%100)/10)
                elseif index == 3 then
                    modeType = (tonumber(reExtra.mode)%100)%10
                end

                if modeType == 1 then
                    curBonusData = 3
                end
            end
        end
        if collectData and collectData.bonuslist then
        else
            collectData = {}
            collectData.bonuslist = {}
            collectData.bonuslist[index] = 1
        end

        if collectData.bonuslist[index] == curBonusData then -- 没有升级
            util_spinePlay(self.m_collectBallSpineList[index], "shouji"..index.."_"..curBonusData, false)
            util_spineEndCallFunc(self.m_collectBallSpineList[index], "shouji"..index.."_"..curBonusData, function ()
                util_spinePlay(self.m_collectBallSpineList[index], "idle"..index.."_"..curBonusData, true)
            end) 
        else
            if collectData.bonuslist[index] == 1 and curBonusData == 2 then
            else
                self.m_collectBallSpineList[index].m_shengJiSpine:setVisible(true)
                util_spinePlay(self.m_collectBallSpineList[index].m_shengJiSpine, "shengji"..index, false)
                util_spineEndCallFunc(self.m_collectBallSpineList[index].m_shengJiSpine, "shengji"..index, function ()
                    self.m_collectBallSpineList[index].m_shengJiSpine:setVisible(false)
                end)
            end

            util_spinePlay(self.m_collectBallSpineList[index], "shengji"..index.."_"..collectData.bonuslist[index].."_"..curBonusData, false)
            util_spineEndCallFunc(self.m_collectBallSpineList[index], "shengji"..index.."_"..collectData.bonuslist[index].."_"..curBonusData, function ()
                util_spinePlay(self.m_collectBallSpineList[index], "idle"..index.."_"..curBonusData, true)
            end)
        end
        if curBonusData == 1 then
            self.m_collectRoleSpineList[index]:setVisible(false)
        else
            self.m_collectRoleSpineList[index]:setVisible(true)
            if collectData.bonuslist[index] == curBonusData then
                util_spinePlay(self.m_collectRoleSpineList[index], "actionframe_fankui"..curBonusData.."_"..index, false)
                util_spineEndCallFunc(self.m_collectRoleSpineList[index], "actionframe_fankui"..curBonusData.."_"..index, function ()
                    util_spinePlay(self.m_collectRoleSpineList[index], "idle"..curBonusData.."_"..index, true)
                end)
            else
                if self.m_isPlayShengJiSound then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_AChristmasCarol_collect"..collectData.bonuslist[index].."_"..curBonusData])
                end
                self.m_isPlayShengJiSound = false
                util_spinePlay(self.m_collectRoleSpineList[index], "shengji"..index.."_"..collectData.bonuslist[index].."_"..curBonusData, false)
                util_spineEndCallFunc(self.m_collectRoleSpineList[index], "shengji"..index.."_"..collectData.bonuslist[index].."_"..curBonusData, function ()
                    util_spinePlay(self.m_collectRoleSpineList[index], "idle"..curBonusData.."_"..index, true)
                end)
            end
        end
    end
end

--[[
    收集特殊bonus 飞行动画
]]
function CodeGameScreenAChristmasCarolMachine:playBonusSymbolCollectAnim(_slotsNode, _func1, _func2, _func3)
    local startPos = util_convertToNodeSpace(_slotsNode, self.m_effectNode)
    local endPos = util_convertToNodeSpace(self:findChild("Node_buffball_"..(_slotsNode.p_symbolType-93)), self.m_effectNode)
    
    local flyNode = nil
    for _, _node in ipairs(self.m_flyLiZiList) do
        if not _node:isVisible() then
            flyNode = _node
            break
        end
    end
    flyNode:setPosition(startPos)
    flyNode:setVisible(true)

    for index = 1, 3 do
        flyNode:findChild("Node_"..index):setVisible((_slotsNode.p_symbolType-93) == index)
    end
    
    local particle = {}
    if not tolua.isnull(flyNode) then
        for particleIndex = 1, 2 do
            particle[particleIndex] = flyNode:findChild("Particle_"..(_slotsNode.p_symbolType-93).."_"..particleIndex)
            if particle[particleIndex] then
                particle[particleIndex]:setDuration(1)     --设置拖尾时间(生命周期)
                particle[particleIndex]:setPositionType(0)   --设置可以拖尾
                particle[particleIndex]:resetSystem()
            end
        end
    end

    local isTriggerRespin = self:getIsPlayEffect()
    flyNode:runAction(cc.Sequence:create(
        cc.CallFunc:create(function()
            if not isTriggerRespin then
                if _func2 then
                    _func2()
                end
            end
        end),
        cc.MoveTo:create(24/30, cc.p(endPos.x, endPos.y+60)),
        cc.CallFunc:create(function()
            if _func1 then
                _func1()
            end

            if _func3 then
                _func3()
            end

            for particleIndex = 1, 2 do
                if not tolua.isnull(particle[particleIndex]) then
                    particle[particleIndex]:stopSystem()
                end
            end
        end),
        cc.DelayTime:create(0.5),
        cc.CallFunc:create(function()
            if isTriggerRespin then
                self:delayCallBack(0.5, function()
                    if _func2 then
                        _func2()
                    end
                end)
            end
        end),
        cc.CallFunc:create(function()
            flyNode:setVisible(false)
        end)
    ))
end

--[[
    wild上下移动
]]
function CodeGameScreenAChristmasCarolMachine:playMoveWild_effect(_func)
    if self:checkHasBigWin() then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_wild_move_sound)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_wild_move)

    for _, _data in ipairs(self.m_moveWildColList) do
        local child = self:getReelParent(_data.col):getChildren()
        for _,node in ipairs(child) do
            if node and node.p_symbolType and node.p_rowIndex and node.p_rowIndex < 4 then
                local nodeList = {}
                local posEnd = cc.p(node:getPosition())
                if _data.direction == "up" then 
                    posEnd.y = posEnd.y + self.m_SlotNodeW * _data.moveRow
                else
                    posEnd.y = posEnd.y - self.m_SlotNodeW * _data.moveRow
                end

                if node.p_symbolType == 92 then
                    node.p_rowIndex = 1
                    if _data.direction == "up" then 
                        node:runAnim("actionframe_move2", false)
                    else
                        node:runAnim("actionframe_move1", false)
                    end
                else
                    table.insert(nodeList, node)
                end

                local actionList = {}
                actionList[#actionList + 1] = cc.MoveTo:create(15/30, posEnd)
                actionList[#actionList + 1] = cc.CallFunc:create(function ()
                    for index=1,#nodeList do
                        local node = nodeList[index]
                        if not tolua.isnull(node) then
                            self:moveDownCallFun(node) 
                        end
                    end
                end)
                local seq = cc.Sequence:create(actionList)
                node:runAction(seq)
            end
        end
    end

    self:delayCallBack(35/30, function()
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenAChristmasCarolMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenAChristmasCarolMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

-- free和freeMore特殊需求
function CodeGameScreenAChristmasCarolMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        else
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
            -- globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenAChristmasCarolMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

function CodeGameScreenAChristmasCarolMachine:checkRemoveBigMegaEffect()
    CodeGameScreenAChristmasCarolMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenAChristmasCarolMachine:getShowLineWaitTime()
    local time = CodeGameScreenAChristmasCarolMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    --insert-getShowLineWaitTime
    return time
end

----------------------------新增接口插入位---------------------------------------------


-- 继承底层respinView
function CodeGameScreenAChristmasCarolMachine:getRespinView()
    return "AChristmasCarolSrc.AChristmasCarolRespinView"    
end

-- 继承底层respinNode
function CodeGameScreenAChristmasCarolMachine:getRespinNode()
    return "AChristmasCarolSrc.AChristmasCarolRespinNode"    
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenAChristmasCarolMachine:getReSpinSymbolScore(id, isCurRespin)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if isCurRespin then
        storedIcons = rsExtraData.storedIcons or {}
    end
    local score = 0
    local type = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            type = values[3]
        end
    end

    return score, type
end

function CodeGameScreenAChristmasCarolMachine:randomDownRespinSymbolScore(symbolType)
    local multi = 0
    multi = self.m_configData:getFixSymbolPro()

    return multi, "normal"
end

--[[
    获取bonus小块上的label
]]
function CodeGameScreenAChristmasCarolMachine:getLblOnBonusSymbol(_symbolNode, _isCopy)
    local spine = nil
    if _isCopy then
        spine = _symbolNode
    else
        if _symbolNode.checkLoadCCbNode then
        else
            print("qqq")
        end
        local aniNode = _symbolNode:checkLoadCCbNode()
        spine = aniNode.m_spineNode
    end
    local lblName = "Socre_AChristmasCarol_Bonus_coin.csb"
    if spine and not spine.m_lbl_score then
        local label = util_createAnimation(lblName)
        util_spinePushBindNode(spine,"shuzi",label)
        spine.m_lbl_score = label
    end

    return spine.m_lbl_score
end

-- 给respin小块进行赋值
function CodeGameScreenAChristmasCarolMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score = 0
    local type = nil
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        score, type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
    else
        score, type = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
    end

    if symbolNode and symbolNode.p_symbolType then
        symbolNode.m_score = score
        local symbolType = symbolNode.p_symbolType

        self:showBonusJackpotOrCoins(symbolNode, score, type)

        if symbolType == self.SYMBOL_BASE_BONUS1 or symbolType == self.SYMBOL_BASE_BONUS2 or symbolType == self.SYMBOL_BASE_BONUS3 then
            if self:getGameSpinStage( ) > IDLE and self:getGameSpinStage() ~= QUICK_RUN then
                if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
                    symbolNode:runAnim("idleframe", false)
                else
                    symbolNode:runAnim("idleframe2", false)
                end
            else
                symbolNode:runAnim("idleframe", false)
            end
        end
    end
end

--[[
    处理bonus上的数字 判断是否需要保留一位小数
]]
function CodeGameScreenAChristmasCarolMachine:setBonusCoins(_nScore, _score)
    local unitList = "KMBT"
    local lnscore = tostring(_nScore)
    local lscore = tostring(_score)
    local nstrLen = string.len(lnscore)
    local str = string.sub(lscore, 2, 2)
    if string.find(unitList, string.sub(lnscore, 2, 2)) and str ~= "0" then
        return string.sub(lnscore, 1, 1).."."..str ..string.sub(lnscore, 2, nstrLen) 
    end
    return _nScore
end

--[[
    显示bonus上的信息
]]
function CodeGameScreenAChristmasCarolMachine:showBonusJackpotOrCoins(symbolNode, score, type, _isCopy)
    local csbNode = self:getLblOnBonusSymbol(symbolNode, _isCopy)
    csbNode:runCsbAction("idleframe")
    --普通信号
    if type == "normal" then
        csbNode:findChild("Node_jackpot"):setVisible(false)
        csbNode:findChild("Node_double"):setVisible(false)
        csbNode:findChild("Node_1"):setVisible(true)
        if score ~= nil then
            local lineBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
            score = score * lineBet
            local nScore = self:setBonusCoins(util_formatCoinsLN(score, 3), score)
            local label = csbNode:findChild("m_lb_coins")
            label:setString(nScore)
            self:updateLabelSize({label = label,sx = 1,sy = 1}, 150)
        end
    else
        if score == 0 then
            csbNode:findChild("Node_1"):setVisible(false)
            csbNode:findChild("Node_double"):setVisible(false)
            csbNode:findChild("Node_jackpot"):setVisible(true)
            csbNode:findChild("grand"):setVisible(type == "grand")
            csbNode:findChild("major"):setVisible(type == "major")
            csbNode:findChild("minor"):setVisible(type == "minor")
            csbNode:findChild("mini"):setVisible(type == "mini")
        else
            csbNode:findChild("Node_1"):setVisible(false)
            csbNode:findChild("Node_jackpot"):setVisible(false)
            csbNode:findChild("Node_double"):setVisible(true)
            csbNode:findChild("grand_2"):setVisible(type == "grand")
            csbNode:findChild("major_2"):setVisible(type == "major")
            csbNode:findChild("minor_2"):setVisible(type == "minor")
            csbNode:findChild("mini_2"):setVisible(type == "mini")
            if score ~= nil then
                local lineBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
                score = score * lineBet
                local nScore = self:setBonusCoins(util_formatCoinsLN(score, 3), score)
                local label = csbNode:findChild("m_lb_coins_2")
                label:setString("+"..nScore)
                self:updateLabelSize({label = label,sx = 1,sy = 1}, 150)
            end
        end
    end
end

function CodeGameScreenAChristmasCarolMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    end    
end

--[[
    判断是否为bonus小块
]]
function CodeGameScreenAChristmasCarolMachine:isFixSymbol(symbolType)
    local bonusAry = {
        self.SYMBOL_BASE_BONUS1,
        self.SYMBOL_BASE_BONUS2,
        self.SYMBOL_BASE_BONUS3,
        self.SYMBOL_RESPIN_BONUS1,
        -- self.SYMBOL_RESPIN_BONUS2,
    }

    for k,bonusType in pairs(bonusAry) do
        if symbolType == bonusType then
            return true
        end
    end
    
    return false
end

--[[
    显示jackpot弹板
]]
function CodeGameScreenAChristmasCarolMachine:showRespinJackpot(index, coins, func)
    local view = util_createView("AChristmasCarolSrc.AChristmasCarolJackpotWinView",{
        jackpotType = index,
        winCoin = coins,
        machine = self,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

-- 结束respin收集
function CodeGameScreenAChristmasCarolMachine:playLightEffectEnd()
    if self.m_modeType[2] == 1 then
        self.m_miniMachine:respinOver()
    end
    -- 通知respin结束
    self:respinOver() 
end

function CodeGameScreenAChristmasCarolMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        self:delayCallBack(0.5, function (  )
            -- 此处跳出迭代
            self:playBonusEffectOfRespinEnd(function()
                self:playLightEffectEnd()
            end)
        end)
        return 
    end

    local addScore = toLongNumber(0)
    local jackpotCoins = toLongNumber(0)
    local chipNode = self.m_chipList[self.m_playAnimIndex]
    if chipNode then
        local iCol = chipNode.p_cloumnIndex
        local iRow = chipNode.p_rowIndex
        -- 根据网络数据获得当前固定小块的分数
        local score = 0
        local type = nil
        
        if chipNode.m_up then
            score, type = self.m_miniMachine:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
        else
            score, type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) 
        end
        
        local nJackpotType = 0
        local nType = nil
        if type ~= "normal" then
            if type == "grand" then
                nJackpotType = 1
                nType = "Grand"
            elseif type == "major" then
                nJackpotType = 2
                nType = "Major"
            elseif type == "minor" then
                nJackpotType = 3
                nType = "Minor"
            elseif type == "mini" then
                nJackpotType = 4
                nType = "Mini"
            end

            jackpotCoins = toLongNumber(self:getJackpotCoins(nType))
        end
        local lineBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
        addScore = addScore + score * lineBet + jackpotCoins

        self.m_lightScore = self.m_lightScore + addScore
    
        if nJackpotType == 0 then
            self:playBonusJieSuanEffect(chipNode, addScore, false, nJackpotType, function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim()
            end)
        else
            self:playBonusJieSuanEffect(chipNode, addScore, true, nJackpotType, function()
                self:delayCallBack(0.5, function()
                    self:showRespinJackpot(nType, jackpotCoins, function()
                        self.m_playAnimIndex = self.m_playAnimIndex + 1
                        self:playChipCollectAnim()
                    end)
                end)
            end)
        end
    else
        self.m_playAnimIndex = self.m_playAnimIndex + 1
        self:playChipCollectAnim()
    end
end

--[[
    获得jackpot具体数值
]]
function CodeGameScreenAChristmasCarolMachine:getJackpotCoins(_type)
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for _jackpotType, _coins in pairs(jackpotCoins) do
        if _jackpotType == _type then
            return _coins
        end
    end
    return 0
end

--[[
    bonus上数字 时间线
]]
function CodeGameScreenAChristmasCarolMachine:playBonusZiEffect(_node, _actionName)
    local aniNode = _node:checkLoadCCbNode()
    local spine = aniNode.m_spineNode
    spine.m_lbl_score:runCsbAction(_actionName)
end

--[[
    结算每个bonus的动画
]]
function CodeGameScreenAChristmasCarolMachine:playBonusJieSuanEffect(_node, _addCoins, _isJackpot, _nJackpotType, _func)
    local jiesuanName = "jiesuan1"
    if _isJackpot then
        jiesuanName = "jiesuan2"
    end

    if not tolua.isnull(_node) then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_jiesuan_collect)
        local nodePos = util_convertToNodeSpace(_node, self.m_effectNode)
        local oldParent = _node:getParent()
        local oldPosition = cc.p(_node:getPosition())
        util_changeNodeParent(self.m_effectNode, _node, 0)
        _node:setPosition(nodePos)
        _node:runAnim(jiesuanName, false, function()
            if not tolua.isnull(_node) then
                util_changeNodeParent(oldParent, _node, REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - _node.p_rowIndex + _node.p_cloumnIndex)
                _node:setPosition(oldPosition)
                _node:runAnim("dark", false)
                self:playBonusZiEffect(_node, "dark")
            end
        end)
    end
    
    local delayTime = 0.5
    if self.m_modeType[2] == 1 then
        delayTime = 0.3
    end
    self:delayCallBack(delayTime, function ()
        if _func then
            _func()
        end
    end)

    self:playCoinWinEffectUI(function()
        self.m_bottomUI.coinBottomEffectNode:setVisible(true)
    end)
    -- 刷新底栏
    self:setCurBottomWinCoins(_addCoins, true)
end

--设置底栏金币
function CodeGameScreenAChristmasCarolMachine:setCurBottomWinCoins(_addCoins, _bJump)
    local bottomWinCoin = self:getCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + tonumber(tostring(_addCoins)))
    self.m_bottomUI.m_changeLabJumpTime = 0.2
    self:updateBottomUICoins(0, _addCoins, false, _bJump, false)
    self.m_bottomUI.m_changeLabJumpTime = nil
end

--获取底栏金币
function CodeGameScreenAChristmasCarolMachine:getCurBottomWinCoins()
    return self.m_bottomUI.m_spinWinCount or toLongNumber(0)
end

--更新底栏金币
function CodeGameScreenAChristmasCarolMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--结束移除小块调用结算特效
function CodeGameScreenAChristmasCarolMachine:reSpinEndAction()
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- self:clearCurMusicBg()

    -- 获得所有固定的respinBonus小块
    local downChipList = self.m_respinView:getAllCleaningNode()

    if self.m_modeType[2] == 1 then
        local upChipList = self.m_miniMachine.m_respinView:getAllCleaningNode()
        for _index, _chipNode in ipairs(upChipList) do
            _chipNode.m_up = true
            table.insert(self.m_chipList, _chipNode)
        end
    end

    for _index, _chipNode in ipairs(downChipList) do
        _chipNode.m_up = false
        table.insert(self.m_chipList, _chipNode)
    end 

    local grandStarSpine = self.m_respinGrandBarView.m_grandStarSpine[_col]

    self.m_respinGrandBarView:playResetEffect()
    if self.m_modeType[2] == 1 then
        self.m_miniMachine.m_respinGrandBarView:playResetEffect()
    end
    self:playChipCollectAnim()
end

--[[
    结算前 播放触发动画
]]
function CodeGameScreenAChristmasCarolMachine:playBonusEffectOfRespinEnd(_func)
    if _func then
        _func()
    end
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenAChristmasCarolMachine:getRespinRandomTypes()
    local symbolList = { self.SYMBOL_RESPIN_BONUS1,
        self.SYMBOL_RESPIN_BONUS2,
        self.SYMBOL_BASE_BONUS1,
        self.SYMBOL_BASE_BONUS2,
        self.SYMBOL_BASE_BONUS3,
        self.SYMBOL_EMPTY,
        self.SYMBOL_EMPTY1
    }
    return symbolList    
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenAChristmasCarolMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_EMPTY1, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_BASE_BONUS1, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_BASE_BONUS2, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_BASE_BONUS3, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_RESPIN_BONUS1, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_RESPIN_BONUS2, runEndAnimaName = "buling", bRandom = true}
    }
    return symbolList    
end

--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function CodeGameScreenAChristmasCarolMachine:checkTriggerInReSpin()
    local isPlayGameEff = false
    self:getTriggerRespinType()
    if not self:isRespinEnd() then
        --手动添加freespin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        local reSpinEffect = GameEffectData.new()
        reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
        reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

        self.m_isRunningEffect = true

        if self.checkControlerReelType and self:checkControlerReelType() then
            globalMachineController.m_isEffectPlaying = true
        end

        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

---
-- 触发respin 玩法
--
function CodeGameScreenAChristmasCarolMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:levelDeviceVibrate(6, "respin")
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node and (self:isFixSymbol(node.p_symbolType) or node.p_symbolType == self.SYMBOL_RESPIN_BONUS2) then
                    local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(node:getPosition()))
                    local pos = self.m_slotParents[node.p_cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                    self:changeBaseParent(node)
                    node:setPosition(pos)
                end
            end
        end
    end

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            1.5,
            self:getModuleName()
        )
    else
        self:delayCallBack(0.5, function()
            self:showRespinView(effectData)
        end)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenAChristmasCarolMachine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
                self:getRandomList()
                if self.m_modeType[2] == 1 then
                    self.m_miniMachine:setSpinResultData(self.m_runSpinResultData)
                end

                self:stopRespinRun()

                self:setGameSpinStage(GAME_MODE_ONE_RUN)

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
            end
        else
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
        return true
    end
    return false
end

--接收到数据开始停止滚动
function CodeGameScreenAChristmasCarolMachine:stopRespinRun()
    local storedNodeInfo = self:getRespinSpinData()
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    
    if self.m_modeType[2] == 1 then
        self.m_miniMachine:stopRespinRun()
    end
end

--- respin 快停
function CodeGameScreenAChristmasCarolMachine:quicklyStop()
    self.m_respinView:quicklyStop()
    if self.m_modeType[2] == 1 then
        self.m_miniMachine:quicklyStop()
    end
end

--[[
    主要用来判断是否显示触发动画
]]
function CodeGameScreenAChristmasCarolMachine:getIsPlayEffect( )
    local features = self.m_runSpinResultData.p_features or {}
    if #features > 1 and features[2] == 3 then
        return true
    end
    return false
end

--[[
    下棋盘收集grand字母的个数
]]
function CodeGameScreenAChristmasCarolMachine:getDownReelsGrandNums( )
    local reExtra = self.m_runSpinResultData.p_rsExtraData or {}
    local nums = 0
    if reExtra.five then
        for _, _colType in ipairs(reExtra.five) do
            if _colType == 1 then
                nums = nums + 1
            end
        end
    end
    return nums
end

--[[
    respin玩法的时候 显示 隐藏相关资源
]]
function CodeGameScreenAChristmasCarolMachine:showRespinFeature(_isShow)
    self.m_respinGrandBarView:setVisible(_isShow)
    if self.m_modeType[2] ~= 1 then
        self.m_respinTips:setVisible(_isShow)
        self.m_respinTips.m_grandNum = self:getDownReelsGrandNums()
        self.m_respinTips:findChild("m_lb_num"):setString(self.m_respinTips.m_grandNum)
        self.m_respinRoleSpine:setVisible(_isShow)
        self.m_respinRoleSpine:setPositionX(0)
    end
    
    local actionName = "idle4_1"
    if self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 0 then
        actionName = "idle4_1"
        self.m_respinRoleSpine:setPositionX(-70)
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
        actionName = "idle4_2"
        self.m_respinRoleSpine:setPositionX(-40)
    elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
        actionName = "idle5"
    end 
    util_spinePlay(self.m_respinRoleSpine, actionName, true)

    -- base界面的三个角色 和 收集球
    if not _isShow then
        local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet() or 0)
        local collectData = self.m_betCollectList[tostring(totalBet)] or {}
        for index = 1, 3 do
            if self.m_modeType[index] == 1 then
                self.m_collectBallSpineList[index]:setVisible(not _isShow)
                util_spinePlay(self.m_collectBallSpineList[index], "idle"..index.."_1", true)
                self.m_collectRoleSpineList[index]:setVisible(_isShow)
            else
                self.m_collectBallSpineList[index]:setVisible(not _isShow)
                if collectData.bonuslist[index] == 1 then
                    self.m_collectRoleSpineList[index]:setVisible(_isShow)
                else
                    self.m_collectRoleSpineList[index]:setVisible(not _isShow)
                    util_spinePlay(self.m_collectRoleSpineList[index], "idle"..collectData.bonuslist[index].."_"..index, true)
                end
            end
        end
    else
        for index = 1, 3 do
            self.m_collectBallSpineList[index]:setVisible(not _isShow)
            self.m_collectRoleSpineList[index]:setVisible(not _isShow)
        end
    end
end

--[[
    respin玩法 三种触发状态
]]
function CodeGameScreenAChristmasCarolMachine:getTriggerRespinType( )
    local reExtra = self.m_runSpinResultData.p_rsExtraData or {}
    self.m_modeType = {}
    if reExtra.mode then
        self.m_modeType[1] = math.floor(tonumber(reExtra.mode)/100)
        self.m_modeType[2] = math.floor((tonumber(reExtra.mode)%100)/10)
        self.m_modeType[3] = (tonumber(reExtra.mode)%100)%10
    else
        self.m_modeType = {0, 0, 0}
    end
end

--[[
    respin触发大角色 音效
]]
function CodeGameScreenAChristmasCarolMachine:playRoleTriggerSound()
    if self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 0 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_role_trigger1)
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_role_trigger2)
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_role_trigger3)
    elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_role_trigger1_2)
    elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_role_trigger1_3)
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 1 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_role_trigger2_3)
    elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 1 and self.m_modeType[3] == 1 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_role_trigger1_2_3)
    end
end

--[[
    respin 相关
]]
function CodeGameScreenAChristmasCarolMachine:showRespinView()
    local delayTime = 3
    local reExtra = self.m_runSpinResultData.p_rsExtraData or {}
    if reExtra.mode then
        self:getTriggerRespinType()
        self:playRoleTriggerSound()
        for index = 1, 3 do
            if self.m_modeType[index] == 1 then
                local pos = util_convertToNodeSpace(self.m_collectBallSpineList[index], self:findChild("Node_new"))
                util_changeNodeParent(self:findChild("Node_new"), self.m_collectBallSpineList[index], 2)
                self.m_collectBallSpineList[index]:setPosition(pos)
                util_spinePlay(self.m_collectBallSpineList[index], "actionframe"..index, false)
                util_spineEndCallFunc(self.m_collectBallSpineList[index], "actionframe"..index, function ()
                    util_spinePlay(self.m_collectBallSpineList[index], "idle"..index.."_1", true)
                end)

                local pos = util_convertToNodeSpace(self.m_collectRoleSpineList[index], self:findChild("Node_new"))
                util_changeNodeParent(self:findChild("Node_new"), self.m_collectRoleSpineList[index], 1)
                self.m_collectRoleSpineList[index]:setPosition(pos)
                self.m_collectRoleSpineList[index]:setVisible(true)
                util_spineMix(self.m_collectRoleSpineList[index], "idle3_"..index, "actionframe"..index, 0.2)
                util_spinePlay(self.m_collectRoleSpineList[index], "actionframe"..index, false)
                util_spineEndCallFunc(self.m_collectRoleSpineList[index], "actionframe"..index, function ()
                    util_spinePlay(self.m_collectRoleSpineList[index], "idle3_"..index, true)
                end)
            end
        end
        self.m_respinTriggerDark:setVisible(true)
        self.m_respinTriggerDark:runCsbAction("start", false, function()
            self.m_respinTriggerDark:runCsbAction("idle", true)
        end)
        self:delayCallBack(delayTime, function()
            for index = 1, 3 do
                if self.m_modeType[index] == 1 then
                    util_changeNodeParent(self:findChild("Node_buffball_"..index), self.m_collectBallSpineList[index], 0)
                    self.m_collectBallSpineList[index]:setPosition(cc.p(0, 0))
                    util_changeNodeParent(self:findChild("npc_"..index), self.m_collectRoleSpineList[index], 0)
                    self.m_collectRoleSpineList[index]:setPosition(cc.p(0, 0))
                end
            end
            self.m_respinTriggerDark:runCsbAction("over", false, function()
                self.m_respinTriggerDark:setVisible(false)
            end)
        end)
    end

    --先播放动画 再进入respin
    self:clearCurMusicBg()
    self:stopLinesWinSound()

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )
    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()

    local funcCallBack1 = function()
        if self.m_modeType[2] == 1 then
            self.m_jackPotBarView:setVisible(false)
            self.m_doubleJackPotBarView:setVisible(true)
            self.m_miniMachine:setSpinResultData(self.m_runSpinResultData,true)
            self.m_miniMachine:triggerReSpinCallFun(endTypes, randomTypes)
            self.m_miniMachine.m_respinGrandBarView:updateRespinGrand()
        end
        for index = 1, 3 do
            if self.m_modeType[index] == 1 then
                self.m_collectRoleSpineList[index]:setVisible(false)
            end
        end

        self:checkChangeBaseParent()
    end

    local funcCallBack2 = function()
        --构造盘面数据
        self:triggerReSpinCallFun(endTypes, randomTypes)
        self:setReelBg()
        self:showRespinFeature(true)
        self.m_respinGrandBarView:updateRespinGrand()
        
        self.m_bottomUI.m_spinWinCount = 0
        self:setLastWinCoin(0)
        self:updateBottomUICoins(0, self.m_runSpinResultData.p_resWinCoins, false, false, false)
    end

    local funcCallBack3 = function()
        self:runQuickEffect()
        self:playJiManEffect(nil, true)
        
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        if self.m_modeType[2] == 1 then
            self.m_miniMachine:changeReSpinUpdateUI(self.m_runSpinResultData.p_rsExtraData.reSpinCurCount, true)
        end
        self:runNextReSpinReel()
    end

    --进入respin玩法流程
    self:showBeginRespinGameView(delayTime, funcCallBack1, funcCallBack2, funcCallBack3)
end

--[[
    respin玩法开始
]]
function CodeGameScreenAChristmasCarolMachine:showBeginRespinGameView(_delayTime, _funcCallBack1, _funcCallBack2, _funcCallBack3)
    self:delayCallBack(_delayTime, function()
        self:showReSpinStart(function(  )
            self:playGuoChangReSpinEffect(function()
                if _funcCallBack1 then
                    _funcCallBack1()
                end
            end, function()
                if _funcCallBack2 then
                    _funcCallBack2()
                end
            end, function()
                -- 进入respin 之后 滚动之前的动画
                self:comeInRespinEffect(function(  )
                    if _funcCallBack3 then
                        _funcCallBack3()
                    end
                end)
            end)
        end)
    end)
end

function CodeGameScreenAChristmasCarolMachine:showReSpinStart(func)
    local respinStartName = "ReSpinStart"
    if self.m_modeType[1] == 1 and self.m_modeType[2] == 1 and self.m_modeType[3] == 1 then
        respinStartName = "ReSpinStart_All"
    end
    local roleSpine, roleSpine2 = nil
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_startView_start)
    local view = self:showDialog(respinStartName, nil, func)
    if respinStartName == "ReSpinStart" then
        if self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 0 then
            view:findChild("Node_buff_1"):setVisible(true)
            view:findChild("Node_tx1"):setVisible(true)
            roleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
            view:findChild("Node_buff_1_juese1"):addChild(roleSpine)
            util_spinePlay(roleSpine, "idleframe_tanban1", true)

            local ballSpine = util_spineCreate("AChristmasCarol_tb_ball", true, true)
            view:findChild("Node_qiu_buff_1"):addChild(ballSpine)
            util_spinePlay(ballSpine, "idle_buff_1", true)
        elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
            view:findChild("Node_buff_2"):setVisible(true)
            view:findChild("Node_tx2"):setVisible(true)
            roleSpine = util_spineCreate("AChristmasCarol_base_npc2", true, true)
            view:findChild("Node_buff_2_juese2"):addChild(roleSpine)
            util_spinePlay(roleSpine, "idleframe_tanban1", true)

            local ballSpine = util_spineCreate("AChristmasCarol_tb_ball", true, true)
            view:findChild("Node_qiu_buff_2"):addChild(ballSpine)
            util_spinePlay(ballSpine, "idle_buff_2", true)
        elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
            view:findChild("Node_buff_3"):setVisible(true)
            view:findChild("Node_tx3"):setVisible(true)
            roleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
            view:findChild("Node_buff_3_juese3"):addChild(roleSpine)
            util_spinePlay(roleSpine, "idleframe_tanban2", true)

            local ballSpine = util_spineCreate("AChristmasCarol_tb_ball", true, true)
            view:findChild("Node_qiu_buff_3"):addChild(ballSpine)
            util_spinePlay(ballSpine, "idle_buff_3", true)
        elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
            view:findChild("Node_double_1"):setVisible(true)
            view:findChild("Node_tx12"):setVisible(true)

            roleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
            view:findChild("Node_double_1_juese1"):addChild(roleSpine)
            util_spinePlay(roleSpine, "idleframe_tanban5", true)

            roleSpine2 = util_spineCreate("AChristmasCarol_base_npc2", true, true)
            view:findChild("Node_double_1_juese2"):addChild(roleSpine2)
            util_spinePlay(roleSpine2, "idleframe_tanban2", true)

            local ballSpine1 = util_spineCreate("AChristmasCarol_tb_ball", true, true)
            view:findChild("Node_double1_qiu_buff_1"):addChild(ballSpine1)
            util_spinePlay(ballSpine1, "idle_buff_1", true)

            local ballSpine2 = util_spineCreate("AChristmasCarol_tb_ball", true, true)
            view:findChild("Node_double1_qiu_buff_2"):addChild(ballSpine2)
            util_spinePlay(ballSpine2, "idle_buff_2", true)
        elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
            view:findChild("Node_double_2"):setVisible(true)
            view:findChild("Node_tx13"):setVisible(true)

            roleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
            view:findChild("Node_double_2_juese13"):addChild(roleSpine)
            util_spinePlay(roleSpine, "idleframe_tanban3", true)

            local ballSpine1 = util_spineCreate("AChristmasCarol_tb_ball", true, true)
            view:findChild("Node_double2_qiu_buff_1"):addChild(ballSpine1)
            util_spinePlay(ballSpine1, "idle_buff_1", true)

            local ballSpine3 = util_spineCreate("AChristmasCarol_tb_ball", true, true)
            view:findChild("Node_double2_qiu_buff_3"):addChild(ballSpine3)
            util_spinePlay(ballSpine3, "idle_buff_3", true)
        elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 1 then
            view:findChild("Node_double_3"):setVisible(true)
            view:findChild("Node_tx23"):setVisible(true)

            roleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
            view:findChild("Node_double_3_juese3"):addChild(roleSpine)
            util_spinePlay(roleSpine, "idleframe_tanban4", true)

            roleSpine2 = util_spineCreate("AChristmasCarol_base_npc2", true, true)
            view:findChild("Node_double_3_juese2"):addChild(roleSpine2)
            util_spinePlay(roleSpine2, "idleframe_tanban2", true)

            local ballSpine2 = util_spineCreate("AChristmasCarol_tb_ball", true, true)
            view:findChild("Node_double3_qiu_buff_2"):addChild(ballSpine2)
            util_spinePlay(ballSpine2, "idle_buff_2", true)

            local ballSpine3 = util_spineCreate("AChristmasCarol_tb_ball", true, true)
            view:findChild("Node_double3_qiu_buff_3"):addChild(ballSpine3)
            util_spinePlay(ballSpine3, "idle_buff_3", true)
        end
    else
        roleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
        view:findChild("Node_juese13"):addChild(roleSpine)
        util_spinePlay(roleSpine, "idleframe_tanban6", true)

        roleSpine2 = util_spineCreate("AChristmasCarol_base_npc2", true, true)
        view:findChild("Node_juese2"):addChild(roleSpine2)
        util_spinePlay(roleSpine2, "idleframe_tanban3", true)

        local ballSpine1 = util_spineCreate("AChristmasCarol_tb_ball", true, true)
        view:findChild("Node_qiu_buff_1"):addChild(ballSpine1)
        util_spinePlay(ballSpine1, "idle_buff_1", true)

        local ballSpine2 = util_spineCreate("AChristmasCarol_tb_ball", true, true)
        view:findChild("Node_qiu_buff_2"):addChild(ballSpine2)
        util_spinePlay(ballSpine2, "idle_buff_2", true)

        local ballSpine3 = util_spineCreate("AChristmasCarol_tb_ball", true, true)
        view:findChild("Node_qiu_buff_3"):addChild(ballSpine3)
        util_spinePlay(ballSpine3, "idle_buff_3", true)
    end
    view:findChild("root"):setScale(self.m_machineRootScale)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_AChristmasCarol_click
    view:setBtnClickFunc(function (  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_startView_over)
        if respinStartName == "ReSpinStart" then
            if self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 0 then
                util_spinePlay(roleSpine, "idleframe_tanban1_out", false)
            elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
                util_spinePlay(roleSpine, "idleframe_tanban1_out", false)
            elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
                util_spinePlay(roleSpine, "idleframe_tanban2_out", false)
            elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
                util_spinePlay(roleSpine, "idleframe_tanban5_out", false)
                util_spinePlay(roleSpine2, "idleframe_tanban2_out", false)
            elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
                util_spinePlay(roleSpine, "idleframe_tanban3_out", false)
            elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 1 then
                util_spinePlay(roleSpine, "idleframe_tanban4_out", false)
                util_spinePlay(roleSpine2, "idleframe_tanban2_out", false)
            end
        else
            util_spinePlay(roleSpine, "idleframe_tanban6_out", false)
            util_spinePlay(roleSpine2, "idleframe_tanban3_out", false)
        end
    end)
end

function CodeGameScreenAChristmasCarolMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenAChristmasCarolMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if symbolType < self.SYMBOL_BASE_BONUS1 then
                symbolType = self.SYMBOL_EMPTY
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end

function CodeGameScreenAChristmasCarolMachine:setReelSlotsNodeVisible(status)
    CodeGameScreenAChristmasCarolMachine.super.setReelSlotsNodeVisible(self, status)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(status)
            end
        end
    end
end

function CodeGameScreenAChristmasCarolMachine:triggerChangeRespinNodeInfo(respinNodeInfo)
    local reExtra = self.m_runSpinResultData.p_rsExtraData or {}
    local curStoredIcons = {}
    local isNext = true
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and (symbolNode.p_symbolType == self.SYMBOL_RESPIN_BONUS1 or symbolNode.p_symbolType == self.SYMBOL_RESPIN_BONUS2) then
                isNext = false
                break
            end
        end
    end
    if isNext then
        for _, _data in ipairs(reExtra.storedIcons) do
            local isNeed = true
            for _, _base_data in ipairs(reExtra.base_storedIcons) do
                if _data[1] == _base_data[1] then
                    isNeed = false
                end
            end
            if isNeed then
                table.insert(curStoredIcons, _data)
            end
        end
        for _, _data in ipairs(curStoredIcons) do
            local pos = self:getRowAndColByPos(_data[1])
            for _, _respinInfo in ipairs(respinNodeInfo) do
                if pos.iX == _respinInfo.ArrayPos.iX and pos.iY == _respinInfo.ArrayPos.iY then
                    _respinInfo.Type = self.SYMBOL_EMPTY1
                end
            end
        end
    end

    if self.m_runSpinResultData.p_rsExtraData.collect and #self.m_runSpinResultData.p_rsExtraData.collect > 0 then
        for _, _data in ipairs(self.m_runSpinResultData.p_rsExtraData.collect) do
            local fixPos = self:getRowAndColByPos(_data[1])
            for _, _respinInfo in ipairs(respinNodeInfo) do
                if fixPos.iX == _respinInfo.ArrayPos.iX and fixPos.iY == _respinInfo.ArrayPos.iY then
                    _respinInfo.Type = self.SYMBOL_EMPTY
                end
            end
        end
    end
end

--[[
    进入respin 之后 滚动之前的动画
    bonusBoost extraSpin doubleSet
]]
function CodeGameScreenAChristmasCarolMachine:comeInRespinEffect(_func)
    if self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 0 then
        self:resetMusicBg(nil,"AChristmasCarolSounds/music_AChristmasCarol_respin1.mp3")
        self:playExtraSpinEffect(_func)
    elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
        self:resetMusicBg(nil,"AChristmasCarolSounds/music_AChristmasCarol_respin2.mp3")
        self:playExtraSpinEffect(_func)
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
        self:resetMusicBg(nil,"AChristmasCarolSounds/music_AChristmasCarol_respin1.mp3")
        self:playBonusBoostEffect(_func)
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
        self:resetMusicBg(nil,"AChristmasCarolSounds/music_AChristmasCarol_respin1.mp3")
        self:playDoubleSetEffect(_func)
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 1 then
        self:resetMusicBg(nil,"AChristmasCarolSounds/music_AChristmasCarol_respin2.mp3")
        self:playDoubleSetEffect(_func)
    elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 1 then
        if self.m_modeType[3] == 0 then
            self:resetMusicBg(nil,"AChristmasCarolSounds/music_AChristmasCarol_respin2.mp3")
        else
            self:resetMusicBg(nil,"AChristmasCarolSounds/music_AChristmasCarol_respin3.mp3")
        end
        self:playDoubleExtraSpinSetEffect(_func)
    end
end

--[[
    播放extraSpin 模式的动画
]]
function CodeGameScreenAChristmasCarolMachine:playExtraSpinEffect(_func)
    self.m_respinAddNumsSpine:setVisible(true)
    local modeTypeNums = 0
    for index = 1, 3 do
        if index ~= 2 then
            if self.m_modeType[index] == 1 then
                modeTypeNums = modeTypeNums + 1
            end
        end
    end
    local actionName = "actionframe_add1"
    if self.m_modeType[2] == 1 then
        actionName = "actionframe_add3"
        self.m_miniMachine.m_respinBarView:playBarStartEffect(true, true)
        self.m_respinBarView:playBarStartEffect(true)
    else
        actionName = "actionframe_add"..modeTypeNums
        self.m_respinBarView:playBarStartEffect(true)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_add_barNums)

    util_spinePlay(self.m_respinAddNumsSpine, actionName, false)
    if self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 0 then
        util_spineMix(self.m_respinRoleSpine, "idle4_1", "actionframe4_1", 0.2)
        util_spinePlay(self.m_respinRoleSpine, "actionframe4_1", false)
        util_spineEndCallFunc(self.m_respinRoleSpine, "actionframe4_1", function()
            util_spinePlay(self.m_respinRoleSpine, "idle4_1", true)
        end)
    end
    
    self:delayCallBack(45/30, function()
        self:playRespinBonusFlyEffect(function()
            if _func then
                _func()
            end
        end)
    end)
end

--[[
    播放bonusBoost 模式的动画
]]
function CodeGameScreenAChristmasCarolMachine:playBonusBoostEffect(_func)
    self.m_respinBarView:playBarStartEffect(false)
    self:playRespinBonusFlyEffect(function()
        if _func then
            _func()
        end
    end)
end

--[[
    播放doubleSet 模式的动画
]]
function CodeGameScreenAChristmasCarolMachine:playDoubleSetEffect(_func)
    self.m_miniMachine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_add_reels)
    self:runCsbAction("actionframe_copy", false)
    self.m_miniMachine:playReelStartEffect(function()
        self.m_respinBarView:playBarStartEffect(false)
        self.m_miniMachine.m_respinBarView:playBarStartEffect(false, true)
        self:delayCallBack(0.5, function()
            self:playRespinBonusFlyEffect(function()
                self:delayCallBack(0.5, function()
                    if _func then
                        _func()
                    end
                end)
            end)
        end)
    end)
end

--[[
    播放doubleSet extraSpin 模式的动画
]]
function CodeGameScreenAChristmasCarolMachine:playDoubleExtraSpinSetEffect(_func)
    self.m_miniMachine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_add_reels)
    self:runCsbAction("actionframe_copy", false)
    self.m_miniMachine:playReelStartEffect(function()
        self.m_respinBarView:runCsbAction("idle", false)
        self.m_miniMachine.m_respinBarView:runCsbAction("idle", false)
        self:delayCallBack(0.5, function()
            self:playExtraSpinEffect(function()
                self:delayCallBack(0.5, function()
                    if _func then
                        _func()
                    end
                end)
            end)
        end)
    end)
end

--[[
    开始respin的时候 bonus图标落下来
]]
function CodeGameScreenAChristmasCarolMachine:playRespinBonusFlyEffect(_func)
    local reExtra = self.m_runSpinResultData.p_rsExtraData or {}
    local isFly = true
    local addIndex = #reExtra.storedIcons
    if reExtra.storedIcons_up and #reExtra.storedIcons_up > 0 then
        addIndex = #reExtra.storedIcons > #reExtra.storedIcons_up and #reExtra.storedIcons or #reExtra.storedIcons_up
    end

    local delayTime = 32/30 + addIndex * 0.2
    if self.m_runSpinResultData.p_features and #self.m_runSpinResultData.p_features == 1 then
        isFly = false
        delayTime = 2/30
    end

    if isFly then
        local downData = self:getNewSortData(reExtra.base_storedIcons, reExtra.storedIcons)
        local upData = {}
        if reExtra.storedIcons_up and #reExtra.storedIcons_up > 0 then
            upData = self:getNewSortData(reExtra.base_storedIcons, reExtra.storedIcons_up)
        end

        for _index, _data in ipairs(downData) do
            self:delayCallBack(0.2 * (_index - 1), function()
                local fixPos = self:getRowAndColByPos(_data[1])
                local respinNode = self.m_respinView:getRespinNode(fixPos.iX, fixPos.iY)
                if respinNode and isFly then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_bonus_start)
                    self:playBonusSymbolFlyAnim(respinNode)
                end
            end)
        end
        if reExtra.storedIcons_up and #reExtra.storedIcons_up > 0 then
            for _index, _data in ipairs(upData) do
                self:delayCallBack(0.2 * (_index - 1), function()
                    local fixPos = self:getRowAndColByPos(_data[1])
                    local respinNode = self.m_miniMachine.m_respinView:getRespinNode(fixPos.iX, fixPos.iY)
                    if respinNode and isFly then
                        self:playBonusSymbolFlyAnim(respinNode)
                    end
                end)
            end
        end
    end

    self:delayCallBack(delayTime, function()
        if _func then
            _func()
        end
    end)
end

--[[
    重新排序数据
]]
function CodeGameScreenAChristmasCarolMachine:getNewSortData(_baseStoredIcons, _storedIcons)
    table.sort(_baseStoredIcons, function(a, b)
        return tonumber(a[1]) < tonumber(b[1])
    end)

    local curStoredIcons = {}
    for _, _data in ipairs(_storedIcons) do
        local isBase = false
        for _, _baseData in ipairs(_baseStoredIcons) do
            if _data[1] == _baseData[1] then
                isBase = true
            end
        end
        if not isBase then
            table.insert(curStoredIcons, _data)
        end
    end

    table.sort(curStoredIcons, function(a, b)
        return tonumber(a[1]) < tonumber(b[1])
    end)

    local newStoredIcons = clone(_baseStoredIcons)
    for _, _data in ipairs(curStoredIcons) do
        table.insert(newStoredIcons, _data)
    end

    return newStoredIcons
end

--[[
    收集特殊bonus 飞行动画
]]
function CodeGameScreenAChristmasCarolMachine:playBonusSymbolFlyAnim(_slotsNode)
    local startPos = util_convertToNodeSpace(self:findChild("Node_yugao"), self.m_effectNode)
    local endPos = util_convertToNodeSpace(_slotsNode, self.m_effectNode)
    startPos.y = startPos.y + display.height/2 + 100
    startPos.x = endPos.x

    local flyNode = util_spineCreate("Socre_AChristmasCarol_Chip_1", true, true)
    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    util_spinePlay(flyNode, "actionframe_luo", false)

    flyNode:runAction(cc.Sequence:create(
        cc.MoveTo:create(13/30, endPos),
        cc.CallFunc:create(function()
            if self:isFixSymbol(_slotsNode.m_baseFirstNode.p_symbolType) then
                self:changeSymbolType(_slotsNode.m_baseFirstNode, self.SYMBOL_RESPIN_BONUS1, true)
                _slotsNode.m_baseFirstNode:runAnim("idleframe1", true)
                local score, type = self:getReSpinSymbolScore(self:getPosReelIdx(_slotsNode.m_baseFirstNode.p_rowIndex, _slotsNode.m_baseFirstNode.p_cloumnIndex),true)
                _slotsNode.m_baseFirstNode.m_score = score
                self:showBonusJackpotOrCoins(_slotsNode.m_baseFirstNode, score, type)
                _slotsNode.m_baseFirstNode:setVisible(false)
            end
        end),
        cc.DelayTime:create(19/30),
        cc.CallFunc:create(function()
            if not self:isFixSymbol(_slotsNode.m_baseFirstNode.p_symbolType) then
                self:changeSymbolType(_slotsNode.m_baseFirstNode, self.SYMBOL_RESPIN_BONUS1, true)
                _slotsNode.m_baseFirstNode:runAnim("idleframe1", true)
                local score, type = self:getReSpinSymbolScore(self:getPosReelIdx(_slotsNode.m_baseFirstNode.p_rowIndex, _slotsNode.m_baseFirstNode.p_cloumnIndex),true)
                _slotsNode.m_baseFirstNode.m_score = score
                self:showBonusJackpotOrCoins(_slotsNode.m_baseFirstNode, score, type)
            else
                _slotsNode.m_baseFirstNode:setVisible(true)
            end
            local aniNode = _slotsNode.m_baseFirstNode:checkLoadCCbNode()
            local spine = aniNode.m_spineNode
            if spine.m_lbl_score then
                spine.m_lbl_score:runCsbAction("start1")
            end
        end),
        cc.RemoveSelf:create()
    ))
end

--ReSpin开始改变UI状态
function CodeGameScreenAChristmasCarolMachine:changeReSpinStartUI(respinCount)
    
end

--ReSpin刷新数量
function CodeGameScreenAChristmasCarolMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_isPlayBarOver = true
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_respinBarView:updateRespinCount(curCount, totalCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenAChristmasCarolMachine:changeReSpinOverUI()
        
end

function CodeGameScreenAChristmasCarolMachine:respinOver()
    -- 更新游戏内每日任务进度条
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    -- self:removeRespinNode()
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT-1
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
    self:sortGameEffects()

    self:delayCallBack(0.5, function()
        self:showRespinOverView()
    end)
end

function CodeGameScreenAChristmasCarolMachine:showRespinOverView(effectData)
    local strCoins = util_formatCoinsLN(self.m_serverWinCoins, 30)
    local view=self:showReSpinOver(strCoins,function()
        self:playGuoChangReSpinEffect(function()
            if self.m_modeType[2] == 1 then
                self.m_miniMachine.m_respinBarView:setVisible(false)
                self.m_jackPotBarView:setVisible(true)
                self.m_doubleJackPotBarView:setVisible(false)
                self.m_miniMachine:removeRespinNode()
                self.m_miniMachine:setVisible(false)
                self.m_miniMachine:setReelSlotsNodeVisible(true)
            end
        end, function()
            self:setReelBg(1)
            self.m_respinBarView:setVisible(false)
            self:showRespinFeature(false)

            self:setReelSlotsNodeVisible(true)
            self:removeRespinNode()
        end, function()
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg()
        end, true)
    end)

    local triggerNums = 0
    for index = 1, 3 do
        if self.m_modeType[index] == 1 then
            triggerNums = triggerNums + 1
        end
    end 
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_AChristmasCarol_respin_overView_start"..triggerNums])
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_AChristmasCarol_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_overView_over)
    end)

    -- 添加光
    local guangNode = util_createAnimation("AChristmasCarol/ReSpinOver_guang.csb")
    view:findChild("Node_guang"):addChild(guangNode)
    guangNode:runCsbAction("idle", true)
    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(view:findChild("Node_guang"), true)

    -- 角色
    local roleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
    view:findChild("Node_juese1"):addChild(roleSpine)
    util_spinePlay(roleSpine, "idleframe_tanban11", true)
    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_juese1"), true)
    util_setCascadeColorEnabledRescursion(view:findChild("Node_juese1"), true)

    local role2Spine = util_spineCreate("AChristmasCarol_base_npc2", true, true)
    view:findChild("Node_juese2"):addChild(role2Spine)
    util_spinePlay(role2Spine, "idleframe_tanban1", true)
    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_juese2"), true)
    util_setCascadeColorEnabledRescursion(view:findChild("Node_juese2"), true)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},654)
    
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
   respin结束 把respin小块放回对应滚轴位置
]]
function CodeGameScreenAChristmasCarolMachine:checkChangeRespinFixNode(node)
    if node.p_symbolType == self.SYMBOL_RESPIN_BONUS1 then
        node:runAnim("idleframe1",true)
        self:playBonusZiEffect(node, "idleframe")
    else
        local randType = math.random(0, self.SYMBOL_10)
        self:changeSymbolType(node,randType)
    end
    CodeGameScreenAChristmasCarolMachine.super.checkChangeRespinFixNode(self, node)
end

--结束移除小块调用结算特效
function CodeGameScreenAChristmasCarolMachine:removeRespinNode()
    CodeGameScreenAChristmasCarolMachine.super.removeRespinNode(self)
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and (symbolNode.p_symbolType == self.SYMBOL_RESPIN_BONUS1 or symbolNode.p_symbolType == self.SYMBOL_RESPIN_BONUS2) then
                local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                symbolNode:setPosition(curPos)
            end
        end
    end
end

-- --重写组织respinData信息
function CodeGameScreenAChristmasCarolMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo    
end

-- --假滚lua解析配置
function CodeGameScreenAChristmasCarolMachine:getMachineConfigParseLuaName()
    return "LevelAChristmasCarolConfig.lua"
end

function CodeGameScreenAChristmasCarolMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("AChristmasCarolSrc.AChristmasCarolJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpotbar"):addChild(self.m_jackPotBarView) --修改成自己的节点

    self.m_doubleJackPotBarView = util_createView("AChristmasCarolSrc.AChristmasCarolDoubleJackPotBarView")
    self.m_doubleJackPotBarView:initMachine(self)
    self:findChild("Node_respin_jackpotbar"):addChild(self.m_doubleJackPotBarView) --修改成自己的节点
    self.m_doubleJackPotBarView:setVisible(false)
end

--[[
    播放预告中奖统一接口
]]
function CodeGameScreenAChristmasCarolMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance() then
        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end)
        
    else
        if type(_func) == "function" then
            _func()
        end
    end    
end

--[[
    播放预告中奖动画
    预告中奖通用规范
    命名:关卡名+_yugao
    时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
    挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
    下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
]]
function CodeGameScreenAChristmasCarolMachine:playFeatureNoticeAni(func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_yugao)

    self.b_gameTipFlag = true
    self.m_yugaoSpineEffect:setVisible(true)
    util_spinePlay(self.m_yugaoSpineEffect,"actionframe",false)
    util_spineEndCallFunc(self.m_yugaoSpineEffect, "actionframe" ,function ()
        self.m_yugaoSpineEffect:setVisible(false)
    end) 

    --动效执行时间
    local aniTime = 3
    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown(5)

    self:delayCallBack(aniTime - delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)  
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenAChristmasCarolMachine:showBigWinLight(func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_bigwin_yugao)

    local rootNode = self:findChild("root")
    util_shakeNode(rootNode,5,10,2)

    self.m_bigWinEffect1:setVisible(true)
    self.m_bigWinEffect2:setVisible(true)

    util_spinePlay(self.m_bigWinEffect1, "actionframe_bigwin")
    util_spineEndCallFunc(self.m_bigWinEffect1, "actionframe_bigwin", function()
        self.m_bigWinEffect1:setVisible(false)
    end)

    local actionName = "actionframe_bigwin2"
    if self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        actionName = "actionframe_bigwin1"
    end
    util_spinePlay(self.m_bigWinEffect2, actionName)
    util_spineEndCallFunc(self.m_bigWinEffect2, actionName, function()
        self.m_bigWinEffect2:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    respin玩法过场
]]
function CodeGameScreenAChristmasCarolMachine:playGuoChangReSpinEffect(_func1, _func2, _func3, _isEnd)
    local actionName = "actionframe_guochang123" --125帧
    if self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 0 then
        actionName = "actionframe_guochang1" --125帧
        if _isEnd then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_end_guochang1)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_guochang1)
        end
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
        actionName = "actionframe_guochang2" --120帧
        if _isEnd then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_end_guochang2)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_guochang2)
        end
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
        actionName = "actionframe_guochang3" --120帧
        if _isEnd then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_end_guochang3)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_guochang3)
        end
    elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 1 and self.m_modeType[3] == 0 then
        actionName = "actionframe_guochang12" --125帧
        if _isEnd then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_end_guochang1_2)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_guochang1_2)
        end
    elseif self.m_modeType[1] == 1 and self.m_modeType[2] == 0 and self.m_modeType[3] == 1 then
        actionName = "actionframe_guochang13" --125帧
        if _isEnd then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_end_guochang1_3)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_guochang1_3)
        end
    elseif self.m_modeType[1] == 0 and self.m_modeType[2] == 1 and self.m_modeType[3] == 1 then
        actionName = "actionframe_guochang23" --120帧
        if _isEnd then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_end_guochang2_3)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_guochang2_3)
        end
    else
        if _isEnd then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_end_guochang1_2_3)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_guochang1_2_3)
        end
    end

    self.m_respinGuoChangEffect:setVisible(true)
    util_spinePlay(self.m_respinGuoChangEffect, actionName, false)

    self:delayCallBack(50/30, function()
        if _func1 then
            _func1()
        end
    end)

    self:delayCallBack(80/30, function()
        if _func2 then
            _func2()
        end
    end)

    util_spineEndCallFunc(self.m_respinGuoChangEffect, actionName ,function ()
        self.m_respinGuoChangEffect:setVisible(false)
        if _func3 then
            _func3()
        end
    end)
end

--开始滚动
function CodeGameScreenAChristmasCarolMachine:startReSpinRun()
    self.m_downReelCount = 0
    self.m_isPlayUpdateRespinNums = true
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}
    self.m_curRespinNodeList = {}
    self.m_isPlayGrandJiManSound = true

    if self:isRespinEnd() then
        return
    end

    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    self:requestSpinReusltData()

    --mini轮开始滚动
    if self.m_modeType[2] == 1 then
        self.m_miniMachine:startReSpinRun()
    end
    --下面的轮盘停了但是上面还没停
    if self.m_runSpinResultData.p_reSpinCurCount <= 0 then
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.RUN)
        self:oneReSpinReelDown()
        return
    end

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    self.m_respinView:startMove()
    -- self:moveRootNodeAction()
end

--[[
    respin是否结束
]]
function CodeGameScreenAChristmasCarolMachine:isRespinEnd( )
    local isRespinEnd = false
    local extraCount = 0
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData and rsExtraData.reSpinCurCount then
        extraCount = rsExtraData.reSpinCurCount
    end

    if self.m_modeType[2] == 0 and self.m_runSpinResultData.p_reSpinCurCount == 0 then
        isRespinEnd = true
    elseif self.m_modeType[2] == 1 and self.m_runSpinResultData.p_reSpinCurCount == 0 and extraCount == 0 then
        isRespinEnd = true
    end
    return isRespinEnd
end

---判断结算
function CodeGameScreenAChristmasCarolMachine:reSpinReelDown()
    self:runQuickEffect()

    self:oneReSpinReelDown()
end

--[[
    快滚特效 respin
]]
function CodeGameScreenAChristmasCarolMachine:runQuickEffect()
    local bonusColList = {}
    local bonusColList_up = {}
    for _col = 1, 5 do
        bonusColList[_col] = {}
        bonusColList_up[_col] = {}
    end
    local isPlaySound = true

    local getQuickRunNode = function()
        if self.m_respinView then
            if self.m_runSpinResultData.p_reSpinCurCount > 0 then
                for _index = 1, #self.m_respinView.m_respinNodes do
                    local repsinNode = self.m_respinView.m_respinNodes[_index]
                    if repsinNode.m_runLastNodeType ~= self.SYMBOL_RESPIN_BONUS1 and repsinNode.m_runLastNodeType ~= self.SYMBOL_RESPIN_BONUS2 then
                        table.insert(bonusColList[repsinNode.p_colIndex], repsinNode)
                    end
                end
            end

            for _col = 1, 5 do
                if #bonusColList[_col] == 1 then
                    local respinNode = bonusColList[_col][1]
                    local startPos = util_convertToNodeSpace(respinNode, self:findChild("Node_respin_reels_kuang"))
                    self.m_respinReelsList[_col]:setPosition(startPos)
                    if not self.m_respinReelsList[_col]:isVisible() then
                        self.m_respinReelsList[_col]:setVisible(true)
                        if isPlaySound then
                            isPlaySound = false
                            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_quick_run_start)
                        end
                        self.m_respinReelsList[_col]:runCsbAction("start", false, function()
                            self.m_respinReelsList[_col]:runCsbAction("idle", true)
                        end)
                    end
                else
                    if self.m_respinReelsList[_col]:isVisible() then
                        self.m_respinReelsList[_col]:runCsbAction("over", false, function()
                            self.m_respinReelsList[_col]:setVisible(false)
                        end)
                    end
                end
            end
        end
    end

    if self.m_modeType[2] == 1 then
        getQuickRunNode()
        if self.m_miniMachine.m_respinView then
            if self.m_runSpinResultData.p_rsExtraData.reSpinCurCount and self.m_runSpinResultData.p_rsExtraData.reSpinCurCount > 0 then
                for _index = 1, #self.m_miniMachine.m_respinView.m_respinNodes do
                    local repsinNode = self.m_miniMachine.m_respinView.m_respinNodes[_index]
                    if repsinNode.m_runLastNodeType ~= self.SYMBOL_RESPIN_BONUS1 and repsinNode.m_runLastNodeType ~= self.SYMBOL_RESPIN_BONUS2 then
                        table.insert(bonusColList_up[repsinNode.p_colIndex], repsinNode)
                    end
                end
            end

            for _col = 1, 5 do
                if #bonusColList_up[_col] == 1 then
                    local respinNode = bonusColList_up[_col][1]
                    local startPos = util_convertToNodeSpace(respinNode, self.m_miniMachine:findChild("Node_respin_reels_kuang"))
                    self.m_respinReelsList[_col+5]:setPosition(startPos)
                    if not self.m_respinReelsList[_col+5]:isVisible() then
                        self.m_respinReelsList[_col+5]:setVisible(true)
                        if isPlaySound then
                            isPlaySound = false
                            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_quick_run_start)
                        end
                        self.m_respinReelsList[_col+5]:runCsbAction("start", false, function()
                            self.m_respinReelsList[_col+5]:runCsbAction("idle", true)
                        end)
                    end
                else
                    if self.m_respinReelsList[_col+5]:isVisible() then
                        self.m_respinReelsList[_col+5]:runCsbAction("over", false, function()
                            self.m_respinReelsList[_col+5]:setVisible(false)
                        end)
                    end
                end
            end
        end
    else
        getQuickRunNode()
    end
end

--[[
    respin每次停轮之后 的处理
]]
function CodeGameScreenAChristmasCarolMachine:oneReSpinReelDown( )
    -- self:removeLightRespin()
    if self.m_runSpinResultData.p_reSpinCurCount <= 0 then
        if self.m_isPlayBarOver then
            self.m_isPlayBarOver = false
            self.m_respinBarView:playBarOverEffect(self.m_runSpinResultData.p_reSpinsTotalCount)
            self.m_respinGrandBarView:playResetEffect()
        end
    end

    self:setGameSpinStage(STOP_RUN)

    self.m_downReelCount = self.m_downReelCount + 1
    local maxCount = self.m_modeType[2] == 1 and 2 or 1

    if self.m_downReelCount < maxCount then
        return
    end

    self:checkAddBonusSymbolScore(function()
        self:playJiManEffect(function()
            self:updateQuestUI()
            if self:isRespinEnd() then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

                --quest
                self:updateQuestBonusRespinEffectData()

                --加0.5s延时
                self:delayCallBack(0.5,function()
                    --结束
                    self:reSpinEndAction()
                end)

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

                self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
                self.m_isWaitingNetworkData = false

                return
            end

            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            
            -- if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
            --     self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            -- end
            --继续
            self:runNextReSpinReel()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end)
    end)
end

--[[
    bonusBoost玩法 加钱
]]
function CodeGameScreenAChristmasCarolMachine:checkAddBonusSymbolScore(_func)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    --下棋盘
    local addStoredIcons = rsExtraData.add_storedIcons or {}
    --上棋盘
    local addUpStoredIcons = rsExtraData.add_storedIcons_up or {}

    table.sort(addStoredIcons, function(a, b)
        local fixPos1 = self:getRowAndColByPos(a[1])
        local fixPos2 = self:getRowAndColByPos(b[1])
        if fixPos1.iY == fixPos2.iY then
            return fixPos1.iX > fixPos2.iX
        end
        return fixPos1.iY < fixPos2.iY
    end)

    table.sort(addUpStoredIcons, function(a, b)
        local fixPos1 = self:getRowAndColByPos(a[1])
        local fixPos2 = self:getRowAndColByPos(b[1])
        if fixPos1.iY == fixPos2.iY then
            return fixPos1.iX > fixPos2.iX
        end
        return fixPos1.iY < fixPos2.iY
    end)

    local allAddStoreIcons = {}
    local endFinalstoredIconsIndex = 0

    for _index, _data in ipairs(addUpStoredIcons) do
        _data[3] = "up"
        table.insert(allAddStoreIcons, _data)
    end
    
    for _index, _data in ipairs(addStoredIcons) do
        _data[3] = "down"
        table.insert(allAddStoreIcons, _data)
    end

    if #allAddStoreIcons > 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        self:delayCallBack(0.5, function()
            for _sIconsIndex, _data in ipairs(allAddStoreIcons) do
                local fixPos = self:getRowAndColByPos(_data[1])
                local startNode = nil
                local endFinalstoredIcons = {}
                if _data[3] == "up" then
                    startNode = self.m_miniMachine.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
                    endFinalstoredIcons = rsExtraData.storedIcons_up or {}
                else
                    startNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
                    endFinalstoredIcons = rsExtraData.storedIcons or {}
                end
                table.sort(endFinalstoredIcons, function(a, b)
                    local fixPos1 = self:getRowAndColByPos(a[1])
                    local fixPos2 = self:getRowAndColByPos(b[1])
                    if fixPos1.iY == fixPos2.iY then
                        return fixPos1.iX > fixPos2.iX
                    end
                    return fixPos1.iY < fixPos2.iY
                end)
                self:delayCallBack(3*(_sIconsIndex-1), function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_bonus2_trigger)

                    local bonus2Spine = self:createRespinAddBonus(startNode)
                    util_spinePlay(bonus2Spine, "actionframe", false)
                    table.insert(self.m_curRespinNodeList, bonus2Spine)
    
                    self:delayCallBack(2, function()
                        endFinalstoredIconsIndex = 0

                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_bonus2_add)
                        util_spinePlay(bonus2Spine, "actionframe_add", false)

                        for _index, _dataList in ipairs(endFinalstoredIcons) do
                            local fixEndPos = self:getRowAndColByPos(_dataList[1])
                            local respinNode = nil
                            if _data[3] == "up" then
                                respinNode = self.m_miniMachine.m_respinView:getRespinEndNode(fixEndPos.iX, fixEndPos.iY)
                            else
                                respinNode = self.m_respinView:getRespinEndNode(fixEndPos.iX, fixEndPos.iY)
                            end
                            if respinNode then
                                self:playExtraSpinFlyEffect(startNode, respinNode, bonus2Spine, function()
                                    self:playAddCoinsBonusEffect(respinNode, _dataList[1], _data[2], _dataList[3], _data[3])
                                    endFinalstoredIconsIndex = endFinalstoredIconsIndex + 1
                                    if _sIconsIndex == #allAddStoreIcons and endFinalstoredIconsIndex == #endFinalstoredIcons then
                                        --加钱流程之后 延迟1秒
                                        self:delayCallBack(1, function()
                                            self:changeBonus2ToBonus1(allAddStoreIcons, function()
                                                if _func then
                                                    _func()
                                                end
                                            end)
                                        end)
                                    end
                                end)
                            end
                        end
                    end)
                end)
            end
        end)
    else
        if _func then
            _func()
        end
    end
end

--[[
    修改图标层级
]]
function CodeGameScreenAChristmasCarolMachine:changeNodeZOrder(_node, _actionName)
    if not tolua.isnull(_node) then
        local nodePos = util_convertToNodeSpace(_node, self.m_effectNode)
        local oldParent = _node:getParent()
        local oldPosition = cc.p(_node:getPosition())
        _node.m_oldParent = oldParent
        _node.m_oldPosition = oldPosition
        util_changeNodeParent(self.m_effectNode, _node, 0)
        _node:setPosition(nodePos)
        _node:runAnim(_actionName, false, function()
            if not tolua.isnull(_node) then
                util_changeNodeParent(oldParent, _node, REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - _node.p_rowIndex + _node.p_cloumnIndex)
                _node:setPosition(oldPosition)
            end
        end)
    end
end

--[[
    respin加钱 创建临时图标
]]
function CodeGameScreenAChristmasCarolMachine:createRespinAddBonus(_node)
    local bonus2Spine = util_spineCreate("Socre_AChristmasCarol_Chip_2", true, true)
    self.m_effectNode:addChild(bonus2Spine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
    local startPos = util_convertToNodeSpace(_node, self.m_effectNode)
    bonus2Spine:setPosition(startPos)
    bonus2Spine.m_oldNode = _node
    _node:setVisible(false)

    return bonus2Spine
end

--[[
    bonus2图标 变成 bonus1
]]
function CodeGameScreenAChristmasCarolMachine:changeBonus2ToBonus1(_allAddStoreIcons, _func)
    for _, _node in ipairs(self.m_curRespinNodeList) do
        if not tolua.isnull(_node) then
            _node.m_oldNode:setVisible(true)
            _node:removeFromParent()
        end
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_bonus2_change)

    for _sIconsIndex, _data in ipairs(_allAddStoreIcons) do
        local fixPos = self:getRowAndColByPos(_data[1])
        local startNode = nil
        if _data[3] == "up" then
            startNode = self.m_miniMachine.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
        else
            startNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
        end

        local bonus2Spine = util_spineCreate("Socre_AChristmasCarol_Chip_2", true, true)
        self.m_effectNode:addChild(bonus2Spine)
        local startPos = util_convertToNodeSpace(startNode, self.m_effectNode)
        bonus2Spine:setPosition(startPos)
        util_spinePlay(bonus2Spine, "switch", false)
        self:delayCallBack(26/30, function()
            if not tolua.isnull(bonus2Spine) then
                bonus2Spine:removeFromParent()
            end
        end)
        startNode:setVisible(false)

        self:delayCallBack(9/30, function()
            startNode:setVisible(true)
            self:changeSymbolType(startNode, self.SYMBOL_RESPIN_BONUS1, true)
            startNode:runAnim("switch", false, function()
                startNode:runAnim("idleframe1", true)
            end)
            local score = _data[2]
            startNode.m_score = score
            self:showBonusJackpotOrCoins(startNode, score, "normal")

            local aniNode = startNode:checkLoadCCbNode()
            local spine = aniNode.m_spineNode
            if spine.m_lbl_score then
                spine.m_lbl_score:runCsbAction("start")
            end
        end)
    end
    
    self:delayCallBack(1, function()
        if _func then
            _func()
        end
    end)
end

--[[
    播放extraSpin 模式 多加一个计数位置的飞行动画
]]
function CodeGameScreenAChristmasCarolMachine:playExtraSpinFlyEffect(_startNode, _endNode, _bonus2Spine, _func)
    local startPos = util_convertToNodeSpace(_startNode, self.m_effectNode)
    local endPos = util_convertToNodeSpace(_endNode, self.m_effectNode)
    self.m_addCoinsLiZiIndex = self.m_addCoinsLiZiIndex + 1
    if self.m_addCoinsLiZiIndex > 15 then
        self.m_addCoinsLiZiIndex = 1
    end

    local flyNode = self.m_addCoinsLiZiList[self.m_addCoinsLiZiIndex]
    flyNode:setPosition(startPos)
    flyNode:setVisible(false)

    local particle = nil
    if not tolua.isnull(flyNode) then
        for ParticleIndex = 1, 2 do
            particle = flyNode:findChild("Particle_"..ParticleIndex)
            if particle then
                particle:resetSystem()
                particle:setPositionType(0)
            end
        end
    end
    local seq = cc.Sequence:create({
        cc.DelayTime:create(15/30),
        cc.CallFunc:create(function()
            flyNode:setVisible(true)
        end),
        -- cc.BezierTo:create(15/30,{cc.p(startPos.x , startPos.y), cc.p(endPos.x, startPos.y), endPos}),
        cc.MoveTo:create(15/30, endPos),
        cc.CallFunc:create(function()
            if not tolua.isnull(flyNode) then
                for ParticleIndex = 1, 2 do
                    particle = flyNode:findChild("Particle_"..ParticleIndex)
                    if particle then
                        particle:stopSystem()
                    end
                end
            end

            if _func then
                _func()
            end
        end)
    })

    flyNode:runAction(seq)
end

--[[
    给respin棋盘上的小块 加钱动画
]]
function CodeGameScreenAChristmasCarolMachine:playAddCoinsBonusEffect(_respinNode, _pos, _addCoins, _bonusType, _upAndDown)
    _respinNode:runAnim("actionframe_shengji", false, function()
        _respinNode:runAnim("idleframe1", true)
    end)

    local symbol_node = _respinNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()

    -- 图标上的反馈动画
    local startPos = util_convertToNodeSpace(_respinNode, self.m_effectNode)
    --加钱
    local addCoinsNode = util_createAnimation("AChristmasCarol_respin_Boost_coins.csb")
    self.m_effectNode:addChild(addCoinsNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)
    addCoinsNode:setPosition(startPos)
    local lineBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local nScore = self:setBonusCoins(util_formatCoinsLN(_addCoins*lineBet, 3), _addCoins*lineBet)
    addCoinsNode:findChild("m_lb_coins"):setString("+"..nScore)
    addCoinsNode:runCsbAction("shengji", false, function()
        if not tolua.isnull(addCoinsNode) then
            addCoinsNode:removeFromParent()
        end
    end)

    if spineNode.m_lbl_score then
        local coinsNode = spineNode.m_lbl_score
        local score = _respinNode.m_score +_addCoins
        if _bonusType == "normal" then
            self:jumpCoinsUp(coinsNode, score*lineBet, _respinNode.m_score*lineBet, coinsNode, false)
        else
            if not tolua.isnull(coinsNode) then
                coinsNode:findChild("Node_jackpot"):setVisible(false)
                coinsNode:findChild("Node_1"):setVisible(false)
                coinsNode:findChild("Node_double"):setVisible(true)
                coinsNode:findChild("grand_2"):setVisible(_bonusType == "grand")
                coinsNode:findChild("major_2"):setVisible(_bonusType == "major")
                coinsNode:findChild("minor_2"):setVisible(_bonusType == "minor")
                coinsNode:findChild("mini_2"):setVisible(_bonusType == "mini")

                local labCoins = coinsNode:findChild("m_lb_coins_2")
                if _respinNode.m_score == 0 then
                    labCoins:setString("+"..util_formatCoinsLN(1, 3))
                else
                    local nScore = self:setBonusCoins(util_formatCoinsLN(_respinNode.m_score*lineBet, 3), _respinNode.m_score*lineBet)
                    labCoins:setString(nScore)
                end
                local nScore = self:setBonusCoins(util_formatCoinsLN(score*lineBet, 3), score*lineBet)
                labCoins:setString("+"..nScore)
                self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 150)
            end
            self:jumpCoinsUp(coinsNode, score*lineBet, _respinNode.m_score*lineBet, coinsNode, true)
        end
        _respinNode.m_score = score
    end
end

-- 金币跳动
function CodeGameScreenAChristmasCarolMachine:jumpCoinsUp(node, _coins, _curCoins, _coinsNode, _isJackpot)
    if not tolua.isnull(node) then
        local coins = tonumber(tostring(_coins))
        local curCoins = tonumber(tostring(_curCoins)) or 0
        -- 每秒60帧
        local coinRiseNum = (coins - curCoins) / (0.5 * 60)

        local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
        coinRiseNum = tonumber(str)
        coinRiseNum = math.ceil(coinRiseNum)

        node.m_updateCoinsAction = schedule(self, function()
            curCoins = curCoins + coinRiseNum
            curCoins = curCoins < coins and curCoins or coins
            
            local sCoins = curCoins

            if not tolua.isnull(node) then
                local labCoins
                if _isJackpot then
                    labCoins = node:findChild("m_lb_coins_2")
                    local nScore = self:setBonusCoins(util_formatCoinsLN(_coins, 3), _coins)
                    labCoins:setString("+"..nScore)
                else
                    labCoins = node:findChild("m_lb_coins")
                    local nScore = self:setBonusCoins(util_formatCoinsLN(_coins, 3), _coins)
                    labCoins:setString(nScore)
                end
                self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 150)
            end

            if curCoins >= coins then
                self:stopUpDateCoinsUp(node)
            end
        end,0.008)
    end
end

function CodeGameScreenAChristmasCarolMachine:stopUpDateCoinsUp(node)
    if not tolua.isnull(node) then
        if node.m_updateCoinsAction then
            self:stopAction(node.m_updateCoinsAction)
            node.m_updateCoinsAction = nil
        end
    end
end

--[[
    棋盘集满动画
]]
function CodeGameScreenAChristmasCarolMachine:playJiManEffect(_func, _isComeIn)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local jiManColList = {0,0,0,0,0}
    local jiManColListUp = {0,0,0,0,0}
    local isJiManCol = false
    if rsExtraData.collect and #rsExtraData.collect > 0 then
        for _, _collectData in ipairs(rsExtraData.collect) do
            local fixPos = self:getRowAndColByPos(_collectData[1])
            if jiManColList[fixPos.iY] == 0 then
                jiManColList[fixPos.iY] = 1
                isJiManCol = true
            end
        end
    end

    if rsExtraData.collect_up and #rsExtraData.collect_up > 0 then
        for _, _collectData in ipairs(rsExtraData.collect_up) do
            local fixPos = self:getRowAndColByPos(_collectData[1])
            if jiManColListUp[fixPos.iY] == 0 then
                jiManColListUp[fixPos.iY] = 1
                isJiManCol = true
            end
        end
    end

    if isJiManCol and not _isComeIn then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})

        self:createJiManEffect(jiManColList, jiManColListUp, function()
            self:playGrandJackpotEffect(function()
                self:getRespinCollectData(function()
                    if _func then
                        _func()
                    end
                end)
            end)
        end)
    else
        if _func then
            _func()
        end
    end
end

--[[
    集满动画
]]
function CodeGameScreenAChristmasCarolMachine:createJiManEffect(_jiManColList, _jiManColListUp, _func)
    local delayTime = 0
    for _col, _type in ipairs(_jiManColList) do
        if _type == 1 then
            delayTime = self:showJiManEffect(false, _col)
        end
    end

    for _col, _type in ipairs(_jiManColListUp) do
        if _type == 1 then
            delayTime = self:showJiManEffect(true, _col)
        end
    end

    self:delayCallBack(delayTime, function()
        local nums = self:getDownReelsGrandNums()
        if self.m_respinTips.m_grandNum ~= nums then
            self.m_respinTips:runCsbAction("actionframe", false)
            self:delayCallBack(20/60, function()
                self.m_respinTips:findChild("m_lb_num"):setString(nums)
                self.m_respinTips.m_grandNum = nums
            end)
        end

        if _func then
            _func()
        end
    end)
end

--[[
    显示集满列的动画
]]
function CodeGameScreenAChristmasCarolMachine:showJiManEffect(_isUpReel, _col)
    local delayTime = 0
    local light_effect = self.m_respinJiManNodeList[_col]
    local reelNode = self:findChild("sp_reel_" .. (_col - 1))
    local grandStarSpine = self.m_respinGrandBarView.m_grandStarSpine[_col]
    local reelsType = "down"

    if _isUpReel then
        reelsType = "up"
        light_effect = self.m_respinJiManNodeList[_col + 5]
        reelNode = self.m_miniMachine:findChild("sp_reel_" .. (_col - 1))
        grandStarSpine = self.m_miniMachine.m_respinGrandBarView.m_grandStarSpine[_col]
    end

    if not light_effect:isVisible() then
        delayTime = 40/60
        light_effect:setVisible(true)
        local startPos = util_convertToNodeSpace(reelNode, self:findChild("Node_jiman"))
        if _isUpReel then
            startPos = util_convertToNodeSpace(reelNode, self.m_miniMachine:findChild("Node_jiman"))
            if self.m_respinReelsList[_col+5]:isVisible() then
                self.m_respinReelsList[_col+5]:runCsbAction("over", false, function()
                    self.m_respinReelsList[_col+5]:setVisible(false)
                end)
            end
        else
            if self.m_respinReelsList[_col]:isVisible() then
                self.m_respinReelsList[_col]:runCsbAction("over", false, function()
                    self.m_respinReelsList[_col]:setVisible(false)
                end)
            end
        end
        light_effect:setPosition(startPos)
        light_effect:runCsbAction("start", false,function()
            light_effect:runCsbAction("idle", true)
        end)

        if not grandStarSpine:isVisible() then
            if self.m_isPlayGrandJiManSound then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_grand_start)
            end
            if self:getGameSpinStage() == QUICK_RUN then
                self.m_isPlayGrandJiManSound = false
            end

            grandStarSpine.grandZiNode:findChild("light_".._col):setVisible(true)
            grandStarSpine:setVisible(true)
            util_spinePlay(grandStarSpine, "start", false)
            util_spineEndCallFunc(grandStarSpine, "start", function ()
                util_spinePlay(grandStarSpine, "idle", true)
            end)

            if reelsType == "down" then
                self.m_respinGrandBarView:playJiManEffectByChaYiGe()
            else
                self.m_miniMachine.m_respinGrandBarView:playJiManEffectByChaYiGe()
            end
        end
    end

    return delayTime
end

--[[
    集齐一列 收集相关
]]
function CodeGameScreenAChristmasCarolMachine:getRespinCollectData(_func)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local respinNodeList = {}
    local respinColNodeList = {}
    -- 处理上棋盘收集整列
    if rsExtraData.collect_up and #rsExtraData.collect_up > 0 then
        table.sort(rsExtraData.collect_up, function(a, b)
            local fixPos1 = self:getRowAndColByPos(a[1])
            local fixPos2 = self:getRowAndColByPos(b[1])
            if fixPos1.iY == fixPos2.iY then
                return fixPos1.iX > fixPos2.iX
            end
            return fixPos1.iY < fixPos2.iY
        end)

        for _, _collectData in ipairs(rsExtraData.collect_up) do
            local fixPos = self:getRowAndColByPos(_collectData[1])
            for _index = 1, #self.m_miniMachine.m_respinView.m_respinNodes do
                local repsinNode = self.m_miniMachine.m_respinView.m_respinNodes[_index]
                if repsinNode.p_colIndex == fixPos.iY and repsinNode.p_rowIndex == fixPos.iX then
                    local nodeData = {}
                    nodeData.node = repsinNode
                    nodeData.data = _collectData
                    nodeData.m_newCol = repsinNode.p_colIndex
                    table.insert(respinNodeList, nodeData)

                    if respinColNodeList[tostring(repsinNode.p_colIndex)] then
                        table.insert(respinColNodeList[tostring(repsinNode.p_colIndex)], nodeData)
                    else
                        respinColNodeList[tostring(repsinNode.p_colIndex)] = {}
                        table.insert(respinColNodeList[tostring(repsinNode.p_colIndex)], nodeData)
                    end
                end
            end
        end
    end

    -- 处理下棋盘收集整列
    if rsExtraData.collect and #rsExtraData.collect > 0 then
        table.sort(rsExtraData.collect, function(a, b)
            local fixPos1 = self:getRowAndColByPos(a[1])
            local fixPos2 = self:getRowAndColByPos(b[1])
            if fixPos1.iY == fixPos2.iY then
                return fixPos1.iX > fixPos2.iX
            end
            return fixPos1.iY < fixPos2.iY
        end)

        for _, _collectData in ipairs(rsExtraData.collect) do
            local fixPos = self:getRowAndColByPos(_collectData[1])
            for _index = 1, #self.m_respinView.m_respinNodes do
                local repsinNode = self.m_respinView.m_respinNodes[_index]
                if repsinNode.p_colIndex == fixPos.iY and repsinNode.p_rowIndex == fixPos.iX then
                    local nodeData = {}
                    nodeData.node = repsinNode
                    nodeData.data = _collectData
                    nodeData.m_newCol = repsinNode.p_colIndex + 5
                    table.insert(respinNodeList, nodeData)

                    if respinColNodeList[tostring(repsinNode.p_colIndex + 5)] then
                        table.insert(respinColNodeList[tostring(repsinNode.p_colIndex + 5)], nodeData)
                    else
                        respinColNodeList[tostring(repsinNode.p_colIndex + 5)] = {}
                        table.insert(respinColNodeList[tostring(repsinNode.p_colIndex + 5)], nodeData)
                    end
                end
            end
        end
    end

    self.m_respinCollectIndex = 0
    self.m_respinColCollectIndex = 0
    self:delayCallBack(0.7, function()
        self:playCollectByJiQiReels(respinNodeList, respinColNodeList, _func)
    end)
end

--[[
    集齐一列 收集相关
]]
function CodeGameScreenAChristmasCarolMachine:playCollectByJiQiReels(_respinNodeList, _respinColNodeList, _func)
    if #_respinNodeList > 0 then
        self.m_respinCollectIndex = self.m_respinCollectIndex + 1
        if self.m_respinCollectIndex > #_respinNodeList then
            self:delayCallBack(15/30, function()
                local respinColNodeList = {}
                for _newCol, _data in pairs(_respinColNodeList) do
                    table.insert(respinColNodeList, _data)
                end
                table.sort(respinColNodeList, function(a, b)
                    return tonumber(a[1].m_newCol) < tonumber(b[1].m_newCol)
                end)

                self:playCollectColByJiQiReels(respinColNodeList, _func)
            end)
        else
            if self.m_respinCollectIndex % 4 == 1 then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_col_collect_fangda)
            end
            local _nodeData = _respinNodeList[self.m_respinCollectIndex]
            local node = _nodeData.node.m_baseFirstNode
            node:runAnim("fangda", false)
            local nodePos = util_convertToNodeSpace(node, self.m_effectNode)
            node.m_oldParent = node:getParent()
            node.m_oldPosition = cc.p(node:getPosition())
            util_changeNodeParent(self.m_effectNode, node, 10 - node.p_rowIndex)
            node:setPosition(nodePos)

            self:delayCallBack(2/30, function()
                self:playCollectByJiQiReels(_respinNodeList, _respinColNodeList, _func)
            end)
        end
    else
        if _func then
            _func()
        end
    end
end

function CodeGameScreenAChristmasCarolMachine:playCollectColByJiQiReels(_respinColNodeList, _func)
    if #_respinColNodeList > 0 then
        self.m_respinColCollectIndex = self.m_respinColCollectIndex + 1
        if self.m_respinColCollectIndex > #_respinColNodeList then
            for _index, _node in ipairs(self.m_respinJiManNodeList) do
                if _node:isVisible() then
                    _node:runCsbAction("over", false,function()
                        _node:setVisible(false)
                    end)
                end
            end

            self:delayCallBack(1, function()
                if _func then
                    _func()
                end
            end)
        else
            local _nodeList = _respinColNodeList[self.m_respinColCollectIndex]
            table.sort(_nodeList, function(a, b)
                return a.node.p_rowIndex < b.node.p_rowIndex
            end)
            local jackpotList = {}
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_AChristmasCarol_respin_col_collect)
            for _index, _nodeData in ipairs(_nodeList) do
                local coins, jackpotCoins = self:getCollectBonusCoins(_nodeData.data[2], _nodeData.data[3])
                _nodeData.node.m_coins = coins
                if jackpotCoins > toLongNumber(0) then
                    local jackpotData = {type = _nodeData.data[3], coins = jackpotCoins}
                    table.insert(jackpotList, jackpotData)
                end
                
                self:delayCallBack(0.2*(_index-1), function()
                    self:playCollectByJiQiReelsEffect(_nodeData.node, _nodeData.data, function()
                        -- 刷新底栏
                        self:setCurBottomWinCoins(_nodeData.node.m_coins, false)
                        if _index == 1 then
                            self:playCoinWinEffectUI(function()
                                self.m_bottomUI.coinBottomEffectNode:setVisible(true)
                            end)
                        end
                        
                        if _index == #_nodeList then
                            if #jackpotList > 0 then
                                if #jackpotList == 1 then
                                    self:showRespinJackpot(jackpotList[1].type, jackpotList[1].coins, function()
                                        self:playCollectColByJiQiReels(_respinColNodeList, _func)
                                    end)
                                elseif #jackpotList == 2 then
                                    self:showRespinJackpot(jackpotList[1].type, jackpotList[1].coins, function()
                                        self:showRespinJackpot(jackpotList[2].type, jackpotList[2].coins, function()
                                            self:playCollectColByJiQiReels(_respinColNodeList, _func)
                                        end)
                                    end)
                                elseif #jackpotList == 3 then
                                    self:showRespinJackpot(jackpotList[1].type, jackpotList[1].coins, function()
                                        self:showRespinJackpot(jackpotList[2].type, jackpotList[2].coins, function()
                                            self:showRespinJackpot(jackpotList[3].type, jackpotList[3].coins, function()
                                                self:playCollectColByJiQiReels(_respinColNodeList, _func)
                                            end)
                                        end)
                                    end)
                                end
                            end
                        end
                    end)
                end)
            end
            if #jackpotList == 0 then
                self:delayCallBack(15/30 + 0.2*2, function()
                    self:playCollectColByJiQiReels(_respinColNodeList, _func)
                end)
            end
        end
    else
        if _func then
            _func()
        end
    end
end

--[[
    显示bonus上的信息
]]
function CodeGameScreenAChristmasCarolMachine:getCollectBonusCoins(score, type)
    local lineBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local coins = toLongNumber(0)
    local jackpotCoins = toLongNumber(0)
    if type == "normal" then
        if score ~= nil then
            coins = score * lineBet
        end
    else
        local nType = nil
        if type == "grand" then
            nType = "Grand"
        elseif type == "major" then
            nType = "Major"
        elseif type == "minor" then
            nType = "Minor"
        elseif type == "mini" then
            nType = "Mini"
        end

        jackpotCoins = toLongNumber(self:getJackpotCoins(nType))
        if score ~= nil then
            coins = score * lineBet + jackpotCoins
        end
    end
    
    return coins, jackpotCoins
end

--[[
    集齐一列 收集相关 飞行动画
]]
function CodeGameScreenAChristmasCarolMachine:playCollectByJiQiReelsEffect(_slotsNode, _collectData, _func)
    local startPos = util_convertToNodeSpace(_slotsNode, gLobalViewManager.p_ViewLayer)
    local endPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, gLobalViewManager.p_ViewLayer)

    local flyNode = util_spineCreate("Socre_AChristmasCarol_Chip_1", true, true)
    gLobalViewManager.p_ViewLayer:addChild(flyNode)
    self:showBonusJackpotOrCoins(flyNode, _collectData[2], _collectData[3], true)
    flyNode:setPosition(startPos)

    if not tolua.isnull(_slotsNode.m_baseFirstNode) then
        local node = _slotsNode.m_baseFirstNode
        if node.m_oldParent then
            util_changeNodeParent(node.m_oldParent, node, REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - node.p_rowIndex + node.p_cloumnIndex)
        end
        if node.m_oldPosition then
            _slotsNode.m_baseFirstNode:setPosition(node.m_oldPosition)
        end
    end

    _slotsNode.m_baseFirstNode:runAnim("jiesuan3", false, function()
        _slotsNode.m_baseFirstNode:runAnim("dark", false)
        self:playBonusZiEffect(_slotsNode.m_baseFirstNode, "dark")

        _slotsNode:setFirstSlotNode(_slotsNode.m_baseFirstNode)
        _slotsNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end)
    util_spinePlay(flyNode, "fly", false)
    flyNode.m_lbl_score:runCsbAction("fly")

    flyNode:runAction(cc.Sequence:create(
        cc.MoveTo:create(20/30, endPos),
        cc.CallFunc:create(function()
            if _func then
                _func()
            end
        end),
        cc.DelayTime:create(5/30),
        cc.RemoveSelf:create()
    ))
end

---- lighting 断线重连时，随机转盘数据
function CodeGameScreenAChristmasCarolMachine:respinModeChangeSymbolType()
    -- 下棋盘 断线进来 有98 改成97
    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
        local storedIcons = self.m_initSpinData.p_storedIcons
        local finalstoredIcons = self.m_initSpinData.p_rsExtraData.finalstoredIcons
        if storedIcons and #storedIcons > 0 and finalstoredIcons and #finalstoredIcons > 0 then
            self.m_initSpinData.p_storedIcons = self.m_initSpinData.p_rsExtraData.finalstoredIcons
            for row = 1, 3 do
                for col = 1, 5 do
                    if self.m_initSpinData.p_reels[row] then
                        if self.m_initSpinData.p_reels[row][col] and self.m_initSpinData.p_reels[row][col] == self.SYMBOL_RESPIN_BONUS2 then
                            self.m_initSpinData.p_reels[row][col] = self.SYMBOL_RESPIN_BONUS1
                        end
                    end
                end
            end

            if #self.m_initSpinData.p_rsExtraData.collect > 0 then
                for _, _data in ipairs(self.m_initSpinData.p_rsExtraData.collect) do
                    local fixPos = self:getRowAndColByPos(_data[1])
                    for index = 1, 3 do
                        self.m_initSpinData.p_reels[index][fixPos.iY] = self.SYMBOL_EMPTY
                    end
                end
            end
        end
    end

    -- 上棋盘 断线进来 有98 改成97
    if self.m_initSpinData.p_rsExtraData and self.m_initSpinData.p_rsExtraData.reSpinsTotalCount and self.m_initSpinData.p_rsExtraData.reSpinsTotalCount > 0 then
        local storedIcons = self.m_initSpinData.p_rsExtraData.storedIcons_up
        local finalstoredIcons = self.m_initSpinData.p_rsExtraData.finalstoredIcons_up
        if storedIcons and #storedIcons > 0 and finalstoredIcons and #finalstoredIcons > 0 then
            self.m_initSpinData.p_rsExtraData.storedIcons_up = self.m_initSpinData.p_rsExtraData.finalstoredIcons_up
            if self.m_initSpinData.p_selfMakeData and self.m_initSpinData.p_selfMakeData.reels then
                for row = 1, 3 do
                    for col = 1, 5 do
                        if self.m_initSpinData.p_selfMakeData.reels[row] then
                            if self.m_initSpinData.p_selfMakeData.reels[row][col] and self.m_initSpinData.p_selfMakeData.reels[row][col] == self.SYMBOL_RESPIN_BONUS2 then
                                self.m_initSpinData.p_selfMakeData.reels[row][col] = self.SYMBOL_RESPIN_BONUS1
                            end
                        end
                    end
                end
            end

            if #self.m_initSpinData.p_rsExtraData.collect_up > 0 then
                for _, _data in ipairs(self.m_initSpinData.p_rsExtraData.collect_up) do
                    local fixPos = self:getRowAndColByPos(_data[1])
                    for index = 1, 3 do
                        self.m_initSpinData.p_selfMakeData.reels[index][fixPos.iY] = self.SYMBOL_EMPTY
                    end
                end
            end
        end
    end

    CodeGameScreenAChristmasCarolMachine.super.respinModeChangeSymbolType(self)
end

--[[
    respin结束 播放中奖grand动画
]]
function CodeGameScreenAChristmasCarolMachine:playGrandJackpotEffect(_func)
    local reExtra = self.m_runSpinResultData.p_rsExtraData or {}
    local isPlayGrand = true
    local isPlayGrandUp = true
    if reExtra.five then
        for _, _colType in ipairs(reExtra.five) do
            if _colType == 0 then
                isPlayGrand = false
                break
            end
        end
    end

    if self.m_modeType[2] == 1 then
        if reExtra.five_up then
            for _, _colType in ipairs(reExtra.five_up) do
                if _colType == 0 then
                    isPlayGrandUp = false
                    break
                end
            end
        end
    else
        isPlayGrandUp = false
    end
    
    if isPlayGrand and not isPlayGrandUp then
        local jackpotCoins = self:getJackpotCoins("Grand")
        self.m_respinGrandBarView:playTriggerEffect(function()
            self:showRespinJackpot("Grand", jackpotCoins, function()
                self.m_respinTips:runCsbAction("actionframe", false)
                self:delayCallBack(20/60, function()
                    self.m_respinTips:findChild("m_lb_num"):setString(0)
                    self.m_respinTips.m_grandNum = 0
                end)

                self:showGrandJackpotCoins(jackpotCoins)
                self:delayCallBack(0.5, function()
                    if _func then
                        _func()
                    end
                end)
            end)
        end)
    elseif not isPlayGrand and isPlayGrandUp then
        local jackpotCoins = self:getJackpotCoins("Grand")
        self.m_miniMachine.m_respinGrandBarView:playTriggerEffect(function()
            self:showRespinJackpot("Grand", jackpotCoins, function()
                self:showGrandJackpotCoins(jackpotCoins)
                self:delayCallBack(0.5, function()
                    if _func then
                        _func()
                    end
                end)
            end)
        end)
    elseif isPlayGrand and isPlayGrandUp then
        local jackpotCoins = self:getJackpotCoins("Grand")
        self.m_respinGrandBarView:playTriggerEffect(function()
            self:showRespinJackpot("Grand", jackpotCoins, function()
                self:showGrandJackpotCoins(jackpotCoins)
                self:delayCallBack(0.5, function()
                    self.m_miniMachine.m_respinGrandBarView:playTriggerEffect(function()
                        self:showRespinJackpot("Grand", jackpotCoins, function()
                            self:showGrandJackpotCoins(jackpotCoins)
                            self:delayCallBack(0.5, function()
                                if _func then
                                    _func()
                                end
                            end)
                        end)
                    end)
                end)
            end)
        end)
    else
        if _func then
            _func()
        end
    end 
end

--[[
   显示grand金币
]]
function CodeGameScreenAChristmasCarolMachine:showGrandJackpotCoins(_jackpotCoins)
    gLobalSoundManager:playSound("AChristmasCarolSounds/sound_AChristmasCarol_respin_grand_collect_end.mp3")
    self:playCoinWinEffectUI()
    -- 刷新底栏
    self:setCurBottomWinCoins(_jackpotCoins, true)
end

--[[
    @desc: 计算每条应前线
    time:2020-07-21 20:48:31
    @return:
]]
function CodeGameScreenAChristmasCarolMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenAChristmasCarolMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenAChristmasCarolMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
                    _slotNode:runAnim("idleframe", false)

                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    _slotNode:setPositionY(curPos.y)

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                    _slotNode.m_bInLine = true
                    _slotNode:setLinePos(linePos)

                    --回弹
                    local newSpeedActionTable = {}
                    for i = 1, #speedActionTable do
                        if i == #speedActionTable then
                            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                            local resTime = self.m_configData.p_reelResTime
                            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                            local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                        else
                            newSpeedActionTable[i] = speedActionTable[i]
                        end
                    end

                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                    _slotNode:runAction(actSequenceClone)
                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                self:playBulingAnimFunc(_slotNode,symbolCfg)
            end
        end
    end
end

--[[
    判断棋盘上 是否存在特殊图标
]]
function CodeGameScreenAChristmasCarolMachine:isHaveSpeBonusByReels(_reels)
    local reels = _reels
    if reels then
        for row = 1, 3 do
            for col = 1, 5 do
                if reels[row] and reels[row][col] and 
                reels[row][col] == self.SYMBOL_RESPIN_BONUS2 then
                    return true
                end
            end
        end
    end
    return false
end

--[[
    检测播放bonus落地音效
]]
function CodeGameScreenAChristmasCarolMachine:checkPlayBonusDownSound(_node, _isHave)
    local colIndex = _node.p_cloumnIndex
    if not self.m_bonus_down[colIndex] then
        if self:getGameSpinStage() == QUICK_RUN then 
            if _isHave == nil then
                _isHave = self:isHaveSpeBonusByReels(self.m_runSpinResultData.p_reels)
            end
            if _isHave then
                gLobalSoundManager:playSound("AChristmasCarolSounds/sound_AChristmasCarolSounds_bonus_buling2.mp3")
            else
                gLobalSoundManager:playSound("AChristmasCarolSounds/sound_AChristmasCarolSounds_bonus_buling1.mp3")
            end
        else
            --播放bonus
            if _node.p_symbolType == self.SYMBOL_RESPIN_BONUS2 then
                gLobalSoundManager:playSound("AChristmasCarolSounds/sound_AChristmasCarolSounds_bonus_buling2.mp3")
            elseif _node.p_symbolType == self.SYMBOL_RESPIN_BONUS1 then
                gLobalSoundManager:playSound("AChristmasCarolSounds/sound_AChristmasCarolSounds_bonus_buling1.mp3")
            end
        end
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_bonus_down[iCol] = true
        end
    else
        self.m_bonus_down[colIndex] = true
    end
end

--[[
    respin单列停止
]]
function CodeGameScreenAChristmasCarolMachine:respinOneReelDown(colIndex,isQuickStop)
    if not self.m_respinReelDownSound[colIndex] then
        if not isQuickStop then
            gLobalSoundManager:playSound("AChristmasCarolSounds/sound_AChristmasCarol_reelDown.mp3")
        else
            gLobalSoundManager:playSound("AChristmasCarolSounds/sound_AChristmasCarol_reelDownQuickStop.mp3")
        end
    end

    self.m_respinReelDownSound[colIndex] = true
    if isQuickStop then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_respinReelDownSound[iCol] = true
        end
    end
end

function CodeGameScreenAChristmasCarolMachine:scaleMainLayer()
    CodeGameScreenAChristmasCarolMachine.super.scaleMainLayer(self)
    local mainScale = self.m_machineRootScale
    local ratio = display.height / display.width
    local mainPosY = 0
    if ratio >= 1370/768 then
        mainScale = mainScale * 0.99
        mainPosY = 6
    elseif ratio >= 1228/768 then
        mainScale = mainScale * 1
    elseif ratio >= 1152/768 then
        mainScale = mainScale * 1.04
        mainPosY = 15
    elseif ratio >= 1024/768 then
        mainScale = mainScale * 1.1
        mainPosY = 25
    elseif ratio >= 920/768 then
        mainScale = mainScale * 1.15
        mainPosY = 25
    else
        mainScale = mainScale * 1.15
        mainPosY = 25
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

--[[
    根据配置初始轮盘
]]
function CodeGameScreenAChristmasCarolMachine:initSlotNodes()
    CodeGameScreenAChristmasCarolMachine.super.initSlotNodes(self)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if self:isFixSymbol(node.p_symbolType) then
                    local symbolNode = util_setSymbolToClipReel(self, iCol, iRow, node.p_symbolType, 0)
                    symbolNode:runAnim("idleframe1", true)
                end
            end
        end
    end
end

return CodeGameScreenAChristmasCarolMachine






