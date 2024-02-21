---
-- island li
-- 2019年1月26日
-- CodeGameScreenWingsOfPhoelinxMachine.lua
-- 
-- 玩法：
-- 
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenWingsOfPhoelinxMachine = class("CodeGameScreenWingsOfPhoelinxMachine", BaseSlotoManiaMachine)

CodeGameScreenWingsOfPhoelinxMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWingsOfPhoelinxMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenWingsOfPhoelinxMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
--特殊bonus
CodeGameScreenWingsOfPhoelinxMachine.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1   --带钱bonus
CodeGameScreenWingsOfPhoelinxMachine.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2   -- winBonus
CodeGameScreenWingsOfPhoelinxMachine.SYMBOL_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3   -- X2Bonus
CodeGameScreenWingsOfPhoelinxMachine.SYMBOL_BONUS4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4   -- X5Bonus

CodeGameScreenWingsOfPhoelinxMachine.SYMBOL_WILD2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10   --长条wild  103

CodeGameScreenWingsOfPhoelinxMachine.SYMBOL_RS_SCORE_BLANK = 100        --空小块

CodeGameScreenWingsOfPhoelinxMachine.COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10 -- 收集玩法以及free下边大wild玩法
CodeGameScreenWingsOfPhoelinxMachine.COLLECT_OVER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 -- 多福多彩玩法

--link下玩法
CodeGameScreenWingsOfPhoelinxMachine.BONUS_THREE = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集玩法
CodeGameScreenWingsOfPhoelinxMachine.BONUS_FIVE = GameEffect.EFFECT_SELF_EFFECT - 2 -- 收集玩法
CodeGameScreenWingsOfPhoelinxMachine.BONUS_ALL = GameEffect.EFFECT_SELF_EFFECT - 3 -- 收集玩法


CodeGameScreenWingsOfPhoelinxMachine.m_chipList = nil
CodeGameScreenWingsOfPhoelinxMachine.m_playAnimIndex = 0
CodeGameScreenWingsOfPhoelinxMachine.m_lightScore = 0

local runStatus = {
    DUANG = 1,
    NORUN = 2
}


-- 构造函数
function CodeGameScreenWingsOfPhoelinxMachine:ctor()
    CodeGameScreenWingsOfPhoelinxMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_collectList = nil
    self.m_bigWildNodeTab = {}--大wild对象存储表
    --中奖预告
    self.m_playWinningNotice = false
    self.wildslevel = 1
    self.m_clipNode = {}--存储提高层级的图标

	--init
	self:initGame()
end

function CodeGameScreenWingsOfPhoelinxMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("WingsOfPhoelinxConfig.csv", "LevelWingsOfPhoelinxConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  



function CodeGameScreenWingsOfPhoelinxMachine:initUI()

    self.m_gameBg:runCsbAction("bace")

    self:initFreeSpinBar() -- FreeSpinbar

    local colorLayers = util_createReelMaskColorLayers( self , SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 10 ,cc.c3b(0, 0, 0),200,self:findChild("reelNode")) 

    for i=1,5 do
        self["m_colorLayer_waitNode_"..i] = cc.Node:create()
        self:addChild(self["m_colorLayer_waitNode_"..i])

        self["colorLayer_"..i] = colorLayers[i]
        if i >1 and i<5 then
            local dark = self["colorLayer_"..i]:getChildren()
            if dark  then
                local size = dark[1]:getContentSize()
                dark[1]:setContentSize(size.width, size.height) 
            end
        end
        
        
    end

    self.m_jackPotBar = util_createView("CodeWingsOfPhoelinxSrc.WingsOfPhoelinxJackPotBarView")  --jackpot
    self:findChild("Node_jackpotkuang"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    self.m_jackPotBar:setVisible(true)
    --
    self.m_jinbidui = util_spineCreate("WingsOfPhoelinx_shouji",true,true)   --金币堆
    self:findChild("Node_jinbidui"):addChild(self.m_jinbidui)
    self.m_jinbidui:setVisible(true)
    util_spinePlay(self.m_jinbidui,"idleframe",true)
 
    self.m_jackpotShow = util_createView("CodeWingsOfPhoelinxSrc.WingsOfPhoelinxJackPotShowView")  --收集玩法jackpot显示
    self:findChild("Node_jackpotxianshi"):addChild(self.m_jackpotShow)
    self.m_jackpotShow:initMachine(self)
    self.m_jackpotShow:setVisible(false)

    local node_bar = self:findChild("Node_bonuscishukuang")
    self.m_respinBar = util_createView("CodeWingsOfPhoelinxSrc.WingsOfPhoelinxBonusBarView")        --Respin次数框
    node_bar:addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)

    --respin钱数框
    self.m_respinCollectView = util_createView("CodeWingsOfPhoelinxSrc.WingsOfPhoelinxRespinCoinsCollectView")
    self:findChild("Node_bonusjishukuang"):addChild(self.m_respinCollectView)
    self.m_respinCollectView:setVisible(false)

    --jackpot字
    self.m_gameTip = util_createAnimation("WingsOfPhoelinx_jackpotwenzikuang.csb")
    self:findChild("Node_jackpotwenzikuang"):addChild(self.m_gameTip)
    self.m_gameTip:setVisible(false)

    self.yuGaoView = util_createView("CodeWingsOfPhoelinxSrc.WingsOfPhoelinxFreeYuGaoView")  --jackpot
    self:findChild("Node_freeyugao"):addChild(self.yuGaoView)
    self.yuGaoView:setVisible(false)

    self.m_GuoChangView = util_spineCreate("WingsOfPhoelinx_guochang",true,true)            --过场
    self:addChild(self.m_GuoChangView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
    self.m_GuoChangView:setPosition(display.width/2,display.height/2)
    self.m_GuoChangView:setVisible(false)  

    self.m_CollectGuoChang = util_spineCreate("WingsOfPhoelinx_shouji",true,true)            --多福多彩过场
    self:addChild(self.m_CollectGuoChang,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
    self.m_CollectGuoChang:setPosition(display.width/2,display.height/2)
    self.m_CollectGuoChang:setVisible(false)  

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
            soundIndex = 4
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end
        local soundName = nil
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "WingsOfPhoelinxSounds/music_WingsOfPhoelinx_free_win_".. soundIndex .. ".mp3"
        else
            soundName = "WingsOfPhoelinxSounds/music_WingsOfPhoelinx_last_win_".. soundIndex .. ".mp3"
        end
        
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            self.m_winSoundsId = nil
        end)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end



-- 断线重连 
function CodeGameScreenWingsOfPhoelinxMachine:MachineRule_initGame(  )

    self:initCollectShow()
    
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWingsOfPhoelinxMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "WingsOfPhoelinx"  
end

-- 继承底层respinView
function CodeGameScreenWingsOfPhoelinxMachine:getRespinView()
    return "CodeWingsOfPhoelinxSrc.WingsOfPhoelinxRespinView"
end
-- 继承底层respinNode
function CodeGameScreenWingsOfPhoelinxMachine:getRespinNode()
    return "CodeWingsOfPhoelinxSrc.WingsOfPhoelinxRespinNode"
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWingsOfPhoelinxMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_WingsOfPhoelinx_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_WingsOfPhoelinx_11"
    elseif symbolType == self.SYMBOL_BONUS1  then
        return "Socre_WingsOfPhoelinx_bonus_0"
    elseif symbolType == self.SYMBOL_BONUS2 then
        return "Socre_WingsOfPhoelinx_bonus_3"
    elseif symbolType == self.SYMBOL_BONUS3 then
        return "Socre_WingsOfPhoelinx_bonus_1"
    elseif symbolType == self.SYMBOL_BONUS4 then
        return "Socre_WingsOfPhoelinx_bonus_2"
    elseif symbolType == self.SYMBOL_RS_SCORE_BLANK then
        return "Socre_WingsOfPhoelinx_bonusdi"
    elseif symbolType == self.SYMBOL_WILD2 then
        return "Socre_WingsOfPhoelinx_Wild2"
    end
    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenWingsOfPhoelinxMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = nil
    storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    return score
end

-- 根据网络数据获得respinBonus小块的分数，如果成倍与钱数同时出现，则用specialBonus的倍率
function CodeGameScreenWingsOfPhoelinxMachine:getReSpinSymbolScoreForspecialBonus(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = nil
    --
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local specialBonus = rsExtraData.specialBonus or {}
    local reel = {}
    if #specialBonus > 0 then
        local tempList = specialBonus[#specialBonus]
        reel = tempList.reel
    end
    if #reel > 0 then
        storedIcons = reel
    else
        storedIcons = self.m_runSpinResultData.p_storedIcons
    end
    
    local score = nil
    local idNode = nil
    for i,v in ipairs(storedIcons) do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    return score
end

function CodeGameScreenWingsOfPhoelinxMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_BONUS1 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end


    return score
end

-- 给respin小块进行赋值
function CodeGameScreenWingsOfPhoelinxMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.SYMBOL_BONUS1 then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScoreForspecialBonus(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            symbolNode:getCcbProperty("m_lb_num"):setString(score)
            self:updateLabelSize({label = symbolNode:getCcbProperty("m_lb_num"),sx = 0.5,sy = 0.5},300)
        end

        symbolNode:runAnim("idleframe")

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil   then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)
                symbolNode:getCcbProperty("m_lb_num"):setString(score)
                self:updateLabelSize({label = symbolNode:getCcbProperty("m_lb_num"),sx = 0.5,sy = 0.5},300)
                symbolNode:runAnim("idleframe")
            end
        end
    end

end

function CodeGameScreenWingsOfPhoelinxMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_BONUS1 then
        self:setSpecialNodeScore(self,{node})
    end
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWingsOfPhoelinxMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenWingsOfPhoelinxMachine.super.getPreLoadSlotNodes(self)

    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD2,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenWingsOfPhoelinxMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS1 or 
        symbolType == self.SYMBOL_BONUS2 or 
        symbolType == self.SYMBOL_BONUS3 or 
        symbolType == self.SYMBOL_BONUS4  then
        return true
    end
    return false
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenWingsOfPhoelinxMachine:specialSymbolActionTreatment( node)
    -- 21.12.08-落地提层回弹 改用底层新增接口和新的配置字段 SymbolBulingAnim_
    -- if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --     --修改小块层级
    --     local scatterOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
    --     local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,scatterOrder)
    --     symbolNode:runAnim("buling")
    -- end

end

function CodeGameScreenWingsOfPhoelinxMachine:playCustomSpecialSymbolDownAct( slotNode )

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        if slotNode and  self:isFixSymbol(slotNode.p_symbolType) then
            -- 21.12.08-落地提层回弹 改用底层新增接口和新的配置字段 SymbolBulingAnim_
            -- local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_BONUS1,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            -- symbolNode:runAnim("buling")

            self:playScatterBonusSound(slotNode)
        end
        -- respinbonus落地音效
        -- gLobalSoundManager:playSound("WingsOfPhoelinxSounds/music_WingsOfPhoelinx_fall_" .. reelCol ..".mp3") 
    end


end

--
--
function CodeGameScreenWingsOfPhoelinxMachine:slotOneReelDown(reelCol)    
    CodeGameScreenWingsOfPhoelinxMachine.super.slotOneReelDown(self,reelCol) 
    if reelCol == 5 then
        self.m_playWinningNotice = false
    end
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenWingsOfPhoelinxMachine:levelFreeSpinEffectChange()
    self.m_gameBg:runCsbAction("free",true)
    
end
---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenWingsOfPhoelinxMachine:levelFreeSpinOverChangeEffect()
    self.m_gameBg:runCsbAction("freetobace",false,function (  )
        self.m_gameBg:runCsbAction("bace")
    end)
end
---------------------------------------------------------------------------

function CodeGameScreenWingsOfPhoelinxMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("Node_freecishu")
        self.m_baseFreeSpinBar = util_createView("CodeWingsOfPhoelinxSrc.WingsOfPhoelinxFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
        self.m_baseFreeSpinBar:setPosition(0, 0)
    end
end

function CodeGameScreenWingsOfPhoelinxMachine:showEffect_FreeSpin(effectData)

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
        --由于scatter提层，导致原来播放触发找不到小块，将提层小块放回原来的层级
        self:checkChangeBaseParent()
        performWithDelay(self,function (  )
            self:showBonusAndScatterLineTip(scatterLineValue,function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end)
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        end,0.2)
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end

-- function CodeGameScreenWingsOfPhoelinxMachine:showScatterTrigger(lineValue,callFun)
--     local frameNum = lineValue.iLineSymbolNum

--     local animTime = 0

    
--         for iCol=1,self.m_iReelColumnNum do
--             for iRow=1,self.m_iReelRowNum do
--                 local symbol = self:getFixSymbol(iCol, iRow,SYMBOL_NODE_TAG)
--                 if symbol ~= nil and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then--这里有空的没有管
--                     self:checkChangeBaseParent()        --将提层的小块放回到原来层级，不然会导致小块不会滚走
--                     symbol = self:setSlotNodeEffectParent(symbol)    --播放Scatter动画不循环
--                     symbol:runAnim("actionframe")
        
--                     animTime = util_max(animTime, symbol:getAniamDurationByName(symbol:getLineAnimName()) )
--                 end
--             end
--         end

--         self:palyBonusAndScatterLineTipEnd(animTime,callFun)
-- end

-- 触发freespin时调用
function CodeGameScreenWingsOfPhoelinxMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("WingsOfPhoelinxSounds/music_WingsOfPhoelinx_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:showGuoChang(function (  )
                    self:findChild("reel_base"):setVisible(false)
                    self:findChild("reel_free"):setVisible(true)
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()  
                end,true)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

function CodeGameScreenWingsOfPhoelinxMachine:showFreeSpinStart(num,func,isAuto)
    
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Free_WingsOfPhoelinx_freeStart.mp3")
    local freeSpinView = util_createView("CodeWingsOfPhoelinxSrc.WingsOfPhoelinxFreespinStart")
    freeSpinView:initView(num,func)
    -- self:addChild(freeSpinView,990)
    gLobalViewManager:showUI(freeSpinView)
    freeSpinView:showFreeAct()
end

-- 触发freespin结束时调用
function CodeGameScreenWingsOfPhoelinxMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("WingsOfPhoelinxSounds/music_WingsOfPhoelinx_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:findChild("reel_base"):setVisible(true)
            self:findChild("reel_free"):setVisible(false)
        -- 调用此函数才是把当前游戏置为freespin结束状态
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.98,sy=0.98},697)

end

-- --------------------freespin结束-------------------

-- --------------------respin玩法---------------------

function CodeGameScreenWingsOfPhoelinxMachine:showRespinView()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
    else
        --先停止刷钱调度器，更新顶部的钱，然后清理底栏的钱数
        self.m_bottomUI:resetWinLabel()
        self.m_bottomUI:notifyTopWinCoin()
        self.m_bottomUI:checkClearWinLabel()
    end
    
    self:checkChangeBaseParent()
    self:clearCurMusicBg()
    --播放触发动画
    local curBonusList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS1 then
                    local symbolNode = util_setSymbolToClipReel(self,iCol, iRow, self.SYMBOL_BONUS1,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                    curBonusList[#curBonusList + 1] = node
                -- elseif node.p_symbolType == 90 then
                --     node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - 100)
                end
            end
        end
    end
    --如果有长wild，降低层级到棋盘
    self.bigWildList = {}
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do
            local slotParentBig = self:getReelBigParent(iCol)
            if slotParentBig then
                local childs = slotParentBig:getChildren()
                for j = 1, #childs do
                    local node = childs[j]
                    if node.p_symbolType and node.p_symbolType == self.SYMBOL_WILD2 then
                        node:setVisible(false)
                        --创建一个假的小块
                        local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_WILD2, 1, iCol, false)
                        self.m_clipParent:addChild(targSp,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE - 2)
                        local pos1= util_convertToNodeSpace(node,self.m_clipParent)
                        targSp:setPosition(pos1)
                        table.insert(self.bigWildList, targSp)
                    end
                end
            end
        end
    end
    self:showColorLayer()
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_bonus_Triggerlink.mp3")
    for i,v in ipairs(curBonusList) do
        v:runAnim("actionframe3",false,function (  )
            v:runAnim("idleframe",true)
        end)
    end
    performWithDelay(self,function (  )
        --将self.m_clipParent层小块放回滚轴层
        self:hideColorLayer()
        self:checkChangeBaseParent()
        self:showRespinStartView(function (  )
            -- self:clearCurMusicBg()
            self.m_respinBar:resetLastNum()
    
            --可随机的普通信息
            local randomTypes = self:getRespinRandomTypes( )
    
            --可随机的特殊信号 
            local endTypes = self:getRespinLockTypes()
            
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
            
        end)
    end,2)
end

function CodeGameScreenWingsOfPhoelinxMachine:showRespinStartView(func)
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/music_WingsOfPhoelinx_Link_Start.mp3")
    self:showDialog("BonusStart",nil,func,true)
end

function CodeGameScreenWingsOfPhoelinxMachine:initRespinView(endTypes, randomTypes)

    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)
    self:showGuoChang(function (  )
        self.m_respinView:initRespinElement(
            respinNodeInfo,
            self.m_iReelRowNum,
            self.m_iReelColumnNum,
            function()
                self:reSpinEffectChange()
                self:playRespinViewShowSound()
                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)
                -- 更改respin 状态下的背景音乐
                self:changeReSpinBgMusic()
                self:runNextReSpinReel()
            
            end
        )
    end,false)
    --隐藏 盘面信息
    for i,v in ipairs(self.bigWildList) do
        v:removeFromParent()
    end
    self.bigWildList = {}
    self:setReelSlotsNodeVisible(false)
end

-- 结束respin收集
function CodeGameScreenWingsOfPhoelinxMachine:playLightEffectEnd()
    performWithDelay(self,function (  )
        self.m_respinBar:setVisible(false)
        self.m_respinCollectView:setOverFunc(function(  )
            self.m_respinView:resetActNodeList()
            self.m_respinView:resetActNode()
            performWithDelay(self,function(  )
               -- 通知respin结束
                self:respinOver() 
            end,0)
            
        end)
        self.m_respinCollectView:setOverShow()
    end,1.5)
end

function CodeGameScreenWingsOfPhoelinxMachine:playChipCollectAnim()
    --依次收集小块上的钱数
    -- self.m_chipList

    if self.m_playAnimIndex > #self.m_chipList then
        -- 此处跳出迭代
        self:playLightEffectEnd()
        return 
        
    end
    local endNode = self:findChild("Node_bonusjishukuang_shuoji")
    local endPos = util_convertToNodeSpace(endNode,self)
    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = util_convertToNodeSpace(chipNode,self)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            

    -- -- 根据网络数据获得当前固定小块的分数
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) 
    
    local addScore = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()
    
    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        end
    end

    local function runCollect()
        local node = cc.Node:create()
        self:addChild(node)
        local actList = {}
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            
            chipNode:runAnim("actionframe")
        end)
        actList[#actList + 1] = cc.DelayTime:create(24/60)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_bonus_TriggerOver.mp3")
            self:runFlyLineAct(nodePos,endPos,function (  )
                self.m_respinCollectView:UpdateWinLabel(addScore)
                self.m_respinCollectView:runCsbAction("actionframe1")
            end,true)
        end)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim()
            node:removeFromParent()
        end)
        node:runAction(cc.Sequence:create( actList))
        
    end
    
    runCollect()    

end



--结束移除小块调用结算特效
function CodeGameScreenWingsOfPhoelinxMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    
    --WingsOfPhoelinx_bonus_TriggerOver
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_overCollect.mp3")
    for i,v in ipairs(self.m_chipList) do
        local tempNode = self.m_chipList[i]
        tempNode:runAnim("actionframe4")
    end
    performWithDelay(self,function (  )
        self:playChipCollectAnim()
    end,2)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenWingsOfPhoelinxMachine:getRespinRandomTypes( )
    local symbolList = {
        self.SYMBOL_BONUS1,
        self.SYMBOL_BONUS2,
        self.SYMBOL_BONUS3,
        self.SYMBOL_BONUS4,
        self.SYMBOL_RS_SCORE_BLANK,
    }
    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenWingsOfPhoelinxMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_BONUS1, runEndAnimaName = "", bRandom = true},
    }

    return symbolList
end

---判断结算
function CodeGameScreenWingsOfPhoelinxMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    
    --在此处播放对应的特效


    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
        self.m_respinBar:updateOverTimes(self.m_runSpinResultData.p_reSpinsTotalCount)
        --quest
        self:updateQuestBonusRespinEffectData()

           --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount , GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    
    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end

    self.changeScoreIndex = 1
    self.collectScoreIndex = 1
    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    
    --判断是否有成倍和wild收钱
    if self:isHaveChangeScoreOrWild() == 0 then
        --继续
        self:runNextReSpinReel()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    elseif self:isHaveChangeScoreOrWild() == 1 or self:isHaveChangeScoreOrWild() == 2 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        local newNode = self.m_respinView:getWildRespinNode()
        if self:isHaveChangeScoreOrWild() == 1 then
            gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_Trigger_Two.mp3")
        elseif self:isHaveChangeScoreOrWild() == 2 then
            gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_Trigger_Five.mp3")
        end
        newNode:runAnim("actionframe2")
        performWithDelay(self,function (  )
            self:checkChangeCoinsEffect()
        end,1)
    elseif self:isHaveChangeScoreOrWild() == 3 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        --创建一个临时小块，用于播放展示
        performWithDelay(self,function (  )
            self.winNode = util_createAnimation("Socre_WingsOfPhoelinx_bonus_3.csb")
            local newNode = self.m_respinView:getWildRespinNode()
            local pos = util_convertToNodeSpace(newNode,self.m_clipParent)
            self.m_clipParent:addChild(self.winNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE +5)
            self.winNode:setPosition(pos)
            gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_Trigger_Instantwin.mp3")
            self.winNode:playAction("actionframe2")
            performWithDelay(self,function (  )
                self:checkWIldCoinsEffect()
            end,1)
        end,0.2)
    end
end

function CodeGameScreenWingsOfPhoelinxMachine:isHaveChangeScoreOrWild( )
    local isHaveIndex = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local specialBonus = rsExtraData.specialBonus or {}
    local kind = nil
    if #specialBonus > 0 then
        local tempList = specialBonus[#specialBonus]
        if tempList then
            kind = tempList.kind
        end
        if kind then
            local type = tonumber(kind[2])
            if self:isChangeSybolType(type) == 1 then
                isHaveIndex = 1
            elseif self:isChangeSybolType(type) == 2 then
                isHaveIndex = 2
            elseif self:isChangeSybolType(type) == 3 then
                isHaveIndex = 3
            end
        end
    end
   
    return isHaveIndex
end

function CodeGameScreenWingsOfPhoelinxMachine:isChangeSybolType(type)
    if type == self.SYMBOL_BONUS3 then
        return 1
    elseif type == self.SYMBOL_BONUS4 then
        return 2
    elseif type == self.SYMBOL_BONUS2 then
        return 3
    end
    return 0
end

--成倍小块播放加钱
function CodeGameScreenWingsOfPhoelinxMachine:checkChangeCoinsEffect( )
    --获取到成倍小块，根据类型播放粒子，改变其他bonus小块上的钱数
    local pos = nil
    local num = 1
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local specialBonus = rsExtraData.specialBonus or {}
    
    local kind = nil
    local multi = nil
    if #specialBonus > 0 then
        local tempList = specialBonus[#specialBonus]
        if tempList then
            kind = tempList.kind
            multi = tempList.multi
        end

        if multi and kind then
            pos = kind[1]
            local type = tonumber(kind[2])
            if self:isChangeSybolType(type) == 1 then
                num = 5
            elseif self:isChangeSybolType(type) == 2 then
                num = 2
            end
        end
    end
    
    --getRespinNode
    local respinPos = self:getRowAndColByPos(pos)
    local WildRespinNode = self.m_respinView:getRespinNode(respinPos.iX,respinPos.iY)

    local newNode = self.m_respinView:getWildRespinNode()
        
    local worldPos = WildRespinNode:getParent():convertToWorldSpace(cc.p(WildRespinNode:getPositionX(),WildRespinNode:getPositionY()))
    local startPos = util_convertToNodeSpace(WildRespinNode,self)
    
    -- 获得所有固定的respinBonus小块
    local scoreList = self.m_respinView:getAllCleaningNode()  
    -- 此处跳出迭代
    if self.changeScoreIndex > #scoreList then
        self.changeScoreIndex = 1
        --继续
        self.m_respinView:restOtherList()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        self:runNextReSpinReel()
        return
    end
    local chipList = self.m_respinView:getAllCleaningNode() 
    local chipNode = chipList[self.changeScoreIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = util_convertToNodeSpace(chipNode,self)
    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            

    -- -- 根据网络数据获得当前固定小块的分数
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
    local lineBet = globalData.slotRunData:getCurTotalBet()
    score = score * lineBet
    --播放粒子
    newNode:runAnim("actionframe")
    -- performWithDelay(self,function (  )
        gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_flyChengbei.mp3")
        self:runFlyLineAct(startPos,nodePos,function (  )
            self.changeScoreIndex = self.changeScoreIndex + 1
            score = util_formatCoins(score, 3)
            chipNode:getCcbProperty("m_lb_num"):setString(score)
            self:updateLabelSize({label = chipNode:getCcbProperty("m_lb_num"),sx = 0.5,sy = 0.5},300)
            self:checkChangeCoinsEffect()
        end)
        performWithDelay(self,function (  )
            chipNode:runAnim("actionframe2",false,function (  )
                chipNode:runAnim("idleframe2",true)
            end)
        end,22/60)
    -- end,0.5)
end

--wild小块播放收钱
function CodeGameScreenWingsOfPhoelinxMachine:checkWIldCoinsEffect( )
    --如果是wild小块，播放收集粒子到板子上，并刷新钱数
    --这里储存着小块的绝对位置和钱数
    local scoreList = self.m_respinView:getAllCleaningNode()  
    local endNode = self:findChild("Node_bonusjishukuang_shuoji")
    local endPos = util_convertToNodeSpace(endNode,self)
    -- 此处跳出迭代
    if self.collectScoreIndex > #scoreList then
        self.m_respinView:restOtherList()
        self.winNode:removeFromParent()
        --继续
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        self:runNextReSpinReel()
        return
    end
    local chipList = self.m_respinView:getAllCleaningNode()
    local chipNode = chipList[self.collectScoreIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = util_convertToNodeSpace(chipNode,self)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            

    -- -- 根据网络数据获得当前固定小块的分数
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
    local lineBet = globalData.slotRunData:getCurTotalBet()
    score = score * lineBet
    local newNode = self.m_respinView:getWildRespinNode()
    local node = cc.Node:create()
    self:addChild(node)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_InstantWin.mp3")
        self.winNode:playAction("actionframe")
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        self:runFlyLineAct(nodePos,endPos,function (  )
            self.m_respinCollectView:UpdateWinLabel(score)
            self.m_respinCollectView:runCsbAction("actionframe1")
        end,true)
    end)
    actList[#actList + 1] = cc.DelayTime:create(24/60)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        self.collectScoreIndex = self.collectScoreIndex +1
        self:checkWIldCoinsEffect()
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create( actList))
end


--ReSpin开始改变UI状态
function CodeGameScreenWingsOfPhoelinxMachine:changeReSpinStartUI(respinCount,totaltimes)
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("baseandfreekuang"):setVisible(false)
    self:findChild("jackpotandbonuskuang"):setVisible(true)
    self.m_jackPotBar:setVisible(false)
    self.m_jinbidui:setVisible(false)
    self.m_gameBg:runCsbAction("link",true)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local winCoins = rsExtraData.win or nil
    self.m_respinCollectView.m_click = true
    self.m_respinCollectView:resetLabel(winCoins)
    self.m_respinCollectView:setVisible(true)
    self.m_respinCollectView:runCsbAction("idleframe")
    self.m_respinBar:setVisible(true)
    self.m_respinBar:updateTimes(respinCount,totaltimes)
end

--ReSpin刷新数量
function CodeGameScreenWingsOfPhoelinxMachine:changeReSpinUpdateUI(curCount)
    self.m_respinBar:updateTimes(curCount,self.m_runSpinResultData.p_reSpinsTotalCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenWingsOfPhoelinxMachine:changeReSpinOverUI()
    --free里触发，结算时显示
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:findChild("reel_base"):setVisible(false)
        self:findChild("reel_free"):setVisible(true)
        self.m_baseFreeSpinBar:setVisible(true)
        self.m_gameBg:runCsbAction("free",true)
    else
        self.m_gameBg:runCsbAction("bace")
    end
    --修改respin小块的ccbName
    self:changeRespinOverCCbName()
    self:findChild("baseandfreekuang"):setVisible(true)
    self:findChild("jackpotandbonuskuang"):setVisible(false)
    self.m_jinbidui:setVisible(true)
    self.m_jackPotBar:setVisible(true)
    self.m_respinBar:setVisible(false)
    self.m_respinCollectView:setVisible(false)
end

function CodeGameScreenWingsOfPhoelinxMachine:changeRespinOverCCbName( )
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow,SYMBOL_NODE_TAG)
            if symbol ~= nil and symbol.p_symbolType ~= self.SYMBOL_BONUS1  then
                local type = math.random(1,10)
                symbol:changeCCBByName(self:getSymbolCCBNameByType(self, type), type)
            end
        end
    end
end

function CodeGameScreenWingsOfPhoelinxMachine:showRespinOverView(effectData)
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.m_lightScore = 0
        self:resetMusicBg() 
end


-- --重写组织respinData信息
function CodeGameScreenWingsOfPhoelinxMachine:getRespinSpinData()
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

-- -------------收集玩法-----------------

function CodeGameScreenWingsOfPhoelinxMachine:getWildSymbol(wildList)
    local tempList = {}
    for i=1,#wildList do
        local pos = wildList[i]
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if targSp then
            table.insert(tempList,targSp)
        end
    end
    return tempList
end

--初始化金币堆显示
function CodeGameScreenWingsOfPhoelinxMachine:initCollectShow( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wild = selfData.wild or {}          --本次spin增加的wild数量
    local wildslevel = selfData.wildlevel or 1      --wild总数量
    local idleAct , shoujiAct = self:showGoldDuiAct(wildslevel)
    self.wildslevel = wildslevel
    util_spinePlay(self.m_jinbidui,idleAct,true)
end

function CodeGameScreenWingsOfPhoelinxMachine:getListLen(list)
    local num = 0
    for k,v in pairs(list) do
        num = num + 1
    end
    return num 
end

function CodeGameScreenWingsOfPhoelinxMachine:updataCollectShow(func)
    local function flyCollectEffect( wildList,func)
        local endNode = self:findChild("Node_jinbidui_shouji")
        local endPos = util_convertToNodeSpace(endNode,self)
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local jackpot = selfData.jackpot or {}
        local wild = selfData.wild or {}          --本次spin增加的wild数量
        local wildslevel = selfData.wildlevel or 1      --wild总数量
        gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_collect_wild.mp3")
        for i=1,#wildList do
            local pos = wildList[i]
            local fixPos = self:getRowAndColByPos(pos)
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if targSp then
                
                local startPos = util_convertToNodeSpace(targSp,self)
                performWithDelay(self,function (  )
                    --增加判断，是否有连线
                    local isShowLine = false
                    for i,v in ipairs(self.m_lineSlotNodes) do
                        if v.p_symbolType == 92 then
                            isShowLine = true
                        end
                    end
                    if isShowLine then
                        targSp:runAnim("shouji",function (  )
                            targSp:runAnim("actionframe",true)
                        end)
                    else
                        targSp:runAnim("shouji")
                    end
                    
                    --收集wild到金币堆
                    self:runFlyCollectAct(pos,startPos,endPos,function (  )
                        --金币碗升级
                        if wildslevel ~= self.wildslevel then
                            --触发了多福多彩玩法
                            if self:getListLen(jackpot) ~= 0 then
                                local idleAct , shoujiAct = self:showGoldDuiAct(self.wildslevel)
                                
                                util_spinePlay(self.m_jinbidui,shoujiAct,false)
                                util_spineEndCallFunc(self.m_jinbidui,shoujiAct,function (  )
                                    util_spinePlay(self.m_jinbidui,idleAct,true)
                                end)
                                performWithDelay(self,function (  )
                                    if func then
                                        func()
                                    end
                                end,0.3)
                            else
                                local idleAct , shoujiAct = self:showGoldDuiAct(wildslevel)
                                if self.wildslevel == 1 then
                                    util_spinePlay(self.m_jinbidui,"switch",false)
                                    util_spineEndCallFunc(self.m_jinbidui,"switch",function (  )
                                        util_spinePlay(self.m_jinbidui,idleAct,true)
                                    end)
                                elseif self.wildslevel == 2 then
                                    util_spinePlay(self.m_jinbidui,"switch2",false)
                                    util_spineEndCallFunc(self.m_jinbidui,"switch2",function (  )
                                        util_spinePlay(self.m_jinbidui,idleAct,true)
                                    end)
                                elseif self.wildslevel == 3 then
                                    util_spinePlay(self.m_jinbidui,shoujiAct,false)
                                    util_spineEndCallFunc(self.m_jinbidui,shoujiAct,function (  )
                                        util_spinePlay(self.m_jinbidui,idleAct,true)
                                    end)
                                end
                                performWithDelay(self,function (  )
                                    if func then
                                        func()
                                    end
                                end,0.3)
                                self.wildslevel = wildslevel
                            end
                            
                        else
                            --金币碗未升级
                            local idleAct , shoujiAct = self:showGoldDuiAct(self.wildslevel)
                            util_spinePlay(self.m_jinbidui,shoujiAct,false)
                            util_spineEndCallFunc(self.m_jinbidui,shoujiAct,function (  )
                                util_spinePlay(self.m_jinbidui,idleAct,true)
                                performWithDelay(self,function (  )
                                    if func then
                                        func()
                                    end
                                end,0.3)
                            end)
                        end
                    end)   
                end,0.2)
            end
        end
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wild = selfData.wild or {}          --本次spin增加的wild数量
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then       --free状态下先收集再变成长条
        --根据wild位置信息播放粒子效果
        flyCollectEffect(wild)
        performWithDelay(self,function (  )
            local time = self:wildSmallChangeBig(wild)
        end,1)
        performWithDelay(self,function (  )
            if func then
                func()
            end
        end,2.5)
    else
        --根据wild位置信息播放粒子效果
        flyCollectEffect(wild)
        if selfData.jackpot and selfData.jackpot.process then
            performWithDelay(self,function (  )
                if func then
                    func()
                end
            end,3) 
        else
            performWithDelay(self,function (  )
                if func then
                    func()
                end
            end,0.1)
        end
         
    end
    
end


--根据数量播放效果
function CodeGameScreenWingsOfPhoelinxMachine:showGoldDuiAct(num)
    if num == 1 then
        return "idleframe","shouji"
    elseif num == 2 then
        return "idleframe2","shouji2"
    elseif num == 3 then
        return "idleframe3","shouji3"
    end
end

--将小wild一整列变成一个大wild
function CodeGameScreenWingsOfPhoelinxMachine:wildSmallChangeBig()
    local time = 1
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Free_WingsOfPhoelinx_Wild_Show.mp3")
    for _, node in pairs(self.m_collectList) do
        time = time + 0.5
        local iCol = node.p_cloumnIndex
        local maxZOrder = 0
        local nodeList = {}     --储存出现wild列的小块，进行移除
        local wildNodeList = {} 
        for j = 1, self.m_iReelRowNum , 1 do
            local otherNode =  self:getFixSymbol(iCol , j, SYMBOL_NODE_TAG)
            if otherNode ~= nil and otherNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                table.insert(nodeList,otherNode)
                if maxZOrder <  otherNode:getLocalZOrder() then
                    maxZOrder = otherNode:getLocalZOrder()
                end
            elseif otherNode ~= nil and otherNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                table.insert( wildNodeList, node)
            end
        end
        self:addBigWildInfo(node)
        
        --根据wild不同行数播放不同的时间线
        if node.p_rowIndex == 1 then
            node:runAnim("switch4")
        elseif node.p_rowIndex == 2 then
            node:runAnim("switch3")
        elseif node.p_rowIndex == 3 then
            node:runAnim("switch2")
        elseif node.p_rowIndex == 4 then
            node:runAnim("switch1")
        end
        performWithDelay(self,function (  )
            for i=1,#nodeList do
                local node = nodeList[i]
                if node then
                    self:moveDownCallFun(node, node.p_cloumnIndex)      --删除小块（调用这个函数为了回收小块到池中去）
                end 
            end
        end,0.5)
        
        performWithDelay(self,function (  )
            local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_WILD2, 1, iCol, false)   --创建长条小块

            if targSp then 

                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                local linePos = {}
                for row = 1,self.m_iReelRowNum do
                    linePos[#linePos + 1] = {iX = row, iY = iCol}
                end
                
                targSp.m_bInLine = true
                targSp:setLinePos(linePos)
                --
                self:getReelBigParent(iCol):addChild(targSp,maxZOrder * 1000, targSp.p_cloumnIndex * SYMBOL_NODE_TAG + targSp.p_rowIndex)
                targSp.p_rowIndex = 1
                
                local pos =  cc.p(self:getPosByColAndRow(iCol, 1))

                targSp:setPosition(pos)

                
                targSp:setLocalZOrder( REEL_SYMBOL_ORDER.REEL_ORDER_1 - targSp.p_rowIndex + self:getBounsScatterDataZorder(targSp.p_symbolType ))
                
                for i=1,#wildNodeList do
                    local node = wildNodeList[i]
                    if node then
                        self:moveDownCallFun(node, node.p_cloumnIndex)      --删除小块（调用这个函数为了回收小块到池中去）
                    end 
                end
                
            end
        end,1)
        
    end
    return time
end

function CodeGameScreenWingsOfPhoelinxMachine:getPosByColAndRow(col, row)
    local posX = self.m_SlotNodeW
    local posY = (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

function CodeGameScreenWingsOfPhoelinxMachine:addBigWildInfo(node)
    local stepCount = 1
    local icol = node.p_cloumnIndex
    -- 处理大信号信息
    if self.m_hasBigSymbol == true then
        self.m_bigSymbolColumnInfo = {}
    else
        self.m_bigSymbolColumnInfo = nil
    end

    local iColumn = self.m_iReelColumnNum
    local iRow = self.m_iReelRowNum

    for colIndex=1,iColumn do
        
        local isBigSymbolCol = false
        if colIndex == icol then
            isBigSymbolCol = true
        end

        local rowIndex=1
        if isBigSymbolCol then
            while true do
                if rowIndex > iRow then
                    break
                end
                local symbolType = 0
                if isBigSymbolCol then
                    symbolType = self.SYMBOL_WILD2
                end
                -- 判断是否有大信号内容
                if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil  then
    
                    local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG,changeRows = {}}
                    
                    
                    local colDatas = self.m_bigSymbolColumnInfo[colIndex]
                    if colDatas == nil then
                        colDatas = {}
                        self.m_bigSymbolColumnInfo[colIndex] = colDatas
                    end           
    
                    colDatas[#colDatas + 1] = bigInfo     
    
                    local symbolCount = self.m_bigSymbolInfos[symbolType]
    
                    local hasCount = symbolCount
    
                    bigInfo.changeRows[#bigInfo.changeRows + 1] = rowIndex
    
    
                    if symbolCount == hasCount or rowIndex > 1 then  -- 表明从对应索引开始的
                        bigInfo.startRowIndex = rowIndex
                    else
    
                        bigInfo.startRowIndex = rowIndex - (symbolCount - hasCount)
                    end
    
                    rowIndex = rowIndex + hasCount - 1  -- 跳过上面有的
    
                end -- end if ~= nil 
    
                rowIndex = rowIndex + 1
            end
    
        end

        
    end
end


-- ------------------------多福多彩玩法----------------------------
function CodeGameScreenWingsOfPhoelinxMachine:showCollectOverGameStart(func)
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Jackpot_WingsOfPhoelinx_startView.mp3")
    self:showDialog("JackpotStart",nil,func,BaseDialog.AUTO_TYPE_ONLY)
end

--多福多彩过场
function CodeGameScreenWingsOfPhoelinxMachine:showJackpotGuoChang(func)
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Jackpot_WingsOfPhoelinx_GuoChang.mp3")
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildslevel = selfData.wildlevel or 1      --wild数量的阶段
    --根据阶段播放金币堆的时间线
    if self.wildslevel == 1 then
        util_spinePlay(self.m_jinbidui,"actionframe",false)
        util_spineEndCallFunc(self.m_jinbidui,"actionframe",function (  )
            util_spinePlay(self.m_jinbidui,"idleframe",true)
        end)
    elseif self.wildslevel == 2 then
        util_spinePlay(self.m_jinbidui,"actionframe2",false)
        util_spineEndCallFunc(self.m_jinbidui,"actionframe2",function (  )
            util_spinePlay(self.m_jinbidui,"idleframe2",true)
        end)
    elseif self.wildslevel == 3 then
        util_spinePlay(self.m_jinbidui,"actionframe3",false)
        util_spineEndCallFunc(self.m_jinbidui,"actionframe3",function (  )
            util_spinePlay(self.m_jinbidui,"idleframe3",true)
        end)
    end
    self.wildslevel = wildslevel

    self.m_CollectGuoChang:setVisible(true)
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Jackpot_WingsOfPhoelinx_allGold.mp3")
    util_spinePlay(self.m_CollectGuoChang,"guochang",false)
    util_spineEndCallFunc(self.m_CollectGuoChang,"guochang",function (  )
        self.m_CollectGuoChang:setVisible(false)
    end)
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,2)
end

function CodeGameScreenWingsOfPhoelinxMachine:collectOverGameShow(effectData)

    self:removeSoundHandler() -- 移除监听
    self:clearCurMusicBg()
    self:showJackpotGuoChang(function (  )
        self.m_baseFreeSpinBar:setVisible(false)
        self:findChild("baseandfreekuang"):setVisible(false)
        self:findChild("jackpotandbonuskuang"):setVisible(true)
        
        self.m_gameBg:runCsbAction("link",true)
        self:findChild("reelNode"):setVisible(false)
        self.m_jackPotBar:setVisible(false)
        self.m_jackpotShow:setVisible(true)
        self.m_gameTip:setVisible(true)
        self:showCollectOverGameStart()
        self.m_jackpotGameView = util_createView("CodeWingsOfPhoelinxSrc.collect.WingsOfPhoelinxCollectGameView",self)
        self:findChild("Node_jackpotbg"):addChild(self.m_jackpotGameView)
        -- self:clearCurMusicBg()
        self:resetMusicBg(nil,"WingsOfPhoelinxSounds/music_WingsOfPhoelinx_jackpot.mp3")
        self.m_jackpotGameView:setEndFunc(function (  )
            --free里触发，结算时显示
            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                self.m_baseFreeSpinBar:setVisible(true)
                self:findChild("reel_base"):setVisible(false)
                self:findChild("reel_free"):setVisible(true)
                self.m_gameBg:runCsbAction("linktofree",function (  )
                    self.m_gameBg:runCsbAction("free")
                end)

            else
                self.m_gameBg:runCsbAction("linktobace",function (  )
                    self.m_gameBg:runCsbAction("bace")
                end)
            end
            self:findChild("baseandfreekuang"):setVisible(true)
            self:findChild("jackpotandbonuskuang"):setVisible(false)
            self:findChild("reelNode"):setVisible(true)
            self.m_jackPotBar:setVisible(true)
            self.m_jackpotShow:resetShowAct()
            self.m_jackpotShow:setVisible(false)
            self.m_gameTip:setVisible(false)
            self.m_jackpotGameView:removeFromParent()
            self:showJackpotWinForData(effectData)
            
        end)
    end)
    
end
--根据服务器给的字段展示jackpot弹板
function CodeGameScreenWingsOfPhoelinxMachine:showJackpotWinForData(effectData)
    self:clearCurMusicBg()
    self.m_gameBg:runCsbAction("bace")
    --重置金币堆
    self:initCollectShow()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local winJackpot = selfData.jackpot.winJackpot
    local jackpotNum = #winJackpot   --服务器下发的jackpot数量
    if jackpotNum > 1 then         --中多个jackpot 
        self:showJackpotWinViewTwo(function (  )
            -- self:clearCurMusicBg()
            self:resetMusicBg() 
            if #self.m_runSpinResultData.p_winLines == 0 then
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount,self.COLLECT_OVER_EFFECT)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,true})
            end
            
            if effectData then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end)
    else
        self:showJackpotWinView(function (  )       --中单个jackpot
            -- self:clearCurMusicBg()
            self:resetMusicBg() 
            if #self.m_runSpinResultData.p_winLines == 0 then
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount,self.COLLECT_OVER_EFFECT)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,true})
            end
            if effectData then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end)
    end
end

function CodeGameScreenWingsOfPhoelinxMachine:getJackpotIndex(type)
    if type == "grand" then
        return 1
    elseif type == "major" then
        return 2
    elseif type == "minor" then
        return 3
    elseif type == "mini" then
        return 4
    end
    return nil
end

--展示jackpot赢钱
function CodeGameScreenWingsOfPhoelinxMachine:showJackpotWinView(func)
    -- gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_InstantWin.mp3")
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local winJackpot = selfData.jackpot.winJackpot
    local index = self:getJackpotIndex(winJackpot[1])
    local coins = self:BaseMania_getJackpotScore(index)
    -- index 1- 4 grand - mini
    local jackPotWinView = util_createView("CodeWingsOfPhoelinxSrc.WingsOfPhoelinxJackPotWinView",index,self)
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

--根据不同搭配，返回不同的index，用来做弹板显示
function CodeGameScreenWingsOfPhoelinxMachine:getTwoJackpotIndex(type1,type2)
    if type1 == "mini" and type2 == "minor" then
        return 1
    elseif type1 == "mini" and type2 == "major" then
        return 2
    elseif type1 == "minor" and type2 == "major" then
        return 3
    end
end

function CodeGameScreenWingsOfPhoelinxMachine:showJackpotWinViewTwo(func)
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local winJackpot = selfData.jackpot.winJackpot
    local index1 = self:getJackpotIndex(winJackpot[1])
    local index2 = self:getJackpotIndex(winJackpot[2])
    local index3 = 0
    local coins1 = 0
    local coins2 = 0
    --1-4 分别为grand-mini
    if index1 > index2 then
        coins1 = self:BaseMania_getJackpotScore(index2)       --保证coins1和index1为大的一个
        coins2 = self:BaseMania_getJackpotScore(index1)
        index3 = self:getTwoJackpotIndex(winJackpot[1],winJackpot[2])
    else
        coins1 = self:BaseMania_getJackpotScore(index1)
        coins2 = self:BaseMania_getJackpotScore(index2)
        index3 = self:getTwoJackpotIndex(winJackpot[2],winJackpot[1])
    end
    
    local jackPotWinView = util_createView("CodeWingsOfPhoelinxSrc.WingsOfPhoelinxJackPotWinViewTwo")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    local curCallFunc = function(  )
        if func then
            func()
        end
    end
    jackPotWinView:initViewData(index1,index2,index3,coins1,coins2,curCallFunc)
end
-- ------------------------多福多彩玩法结束----------------------------

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWingsOfPhoelinxMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume()
    if self.m_winSoundsId then
        
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil

    end
    return false -- 用作延时点击spin调用
end




function CodeGameScreenWingsOfPhoelinxMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
       self:playEnterGameSound( "WingsOfPhoelinxSounds/music_WingsOfPhoelinx_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenWingsOfPhoelinxMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWingsOfPhoelinxMachine.super.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenWingsOfPhoelinxMachine:addObservers()
	CodeGameScreenWingsOfPhoelinxMachine.super.addObservers(self)

end

function CodeGameScreenWingsOfPhoelinxMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWingsOfPhoelinxMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end



-- ------------玩法处理 -- 

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWingsOfPhoelinxMachine:addSelfEffect()
    self.m_collectList = nil
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node then
                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    if not self.m_collectList then
                        self.m_collectList = {}
                    end
                    self.m_collectList[#self.m_collectList + 1] = node
                end
            end
        end
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if self.m_collectList and #self.m_collectList > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_EFFECT -- 动画类型 
    end
    if selfData.jackpot and selfData.jackpot.process then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_OVER_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_OVER_EFFECT -- 动画类型 
    end
        

end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWingsOfPhoelinxMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_EFFECT then
        self:updataCollectShow(function (  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.COLLECT_OVER_EFFECT then
        self:collectOverGameShow(effectData)      --多福多彩玩法
    end

	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenWingsOfPhoelinxMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


function CodeGameScreenWingsOfPhoelinxMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenWingsOfPhoelinxMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenWingsOfPhoelinxMachine:operaEffectOver()
    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = false
    end

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    self:playEffectNotifyChangeSpinStatus()

    

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end

function CodeGameScreenWingsOfPhoelinxMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenWingsOfPhoelinxMachine.super.slotReelDown(self)
end

--respin收集粒子
function CodeGameScreenWingsOfPhoelinxMachine:runFlyLineAct(startPos,endPos,func,isCollect)
    --计算旋转角度
    local rotation = util_getAngleByPos(startPos,endPos)
    --计算两点之间距离
    local distance = math.sqrt(math.pow(startPos.x - endPos.x , 2) + math.pow(startPos.y - endPos.y , 2))
    -- -- 创建粒子
    local flyNode =  nil
    local soundName = ""
    if isCollect then
        -- soundName = "WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_InstantWin.mp3"
        flyNode =  util_createAnimation("WingsOfPhoelinx_Bonus_shouji_tuowei.csb")
    else
        flyNode =  util_createAnimation("WingsOfPhoelinx_Bonus_chengbei_tuowei.csb")
        soundName = "WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_flyChengbei.mp3"
    end
    self:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    flyNode:setPosition(startPos)
    flyNode:setRotation(-rotation)
    flyNode:setScaleX(distance/488)
    if isCollect then
        flyNode:setScaleX(distance/381)
    end
    -- self.winNode:playAction("actionframe")
    if soundName ~= "" then
        gLobalSoundManager:playSound(soundName)
    end
    flyNode:runCsbAction("actionframe",false,function (  )
        flyNode:removeFromParent()
    end)
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,22/60)
end

--针对于收集wild的粒子
function CodeGameScreenWingsOfPhoelinxMachine:runFlyCollectAct(pos,startPos,endPos,func)
    local fixPos = self:getRowAndColByPos(pos)
    local col = fixPos.iY
    -- -- 创建粒子
    local flyNode1 =  util_createAnimation("WingsOfPhoelinx_Wild_shouji_tuowei_1.csb")
    local flyNode2 =  util_createAnimation("WingsOfPhoelinx_Wild_shouji_tuowei_1.csb")

    self:addChild(flyNode1,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    self:addChild(flyNode2,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    flyNode1:setPosition(cc.p(startPos.x,startPos.y))
    flyNode2:setPosition(cc.p(startPos.x,startPos.y))
    local particle1 = flyNode1:findChild("Particle_1")
    local particle2 = flyNode2:findChild("Particle_1")
    local actList1 = {}
    local actList2 = {}
    actList1[#actList1 + 1] = cc.CallFunc:create(function (  )
        flyNode1:runCsbAction("actionframe")
        particle1:setDuration(-1)     --设置拖尾时间(生命周期)
        particle1:setPositionType(0)   --设置可以拖尾
        particle1:resetSystem()
    end)
    actList2[#actList2 + 1] = cc.CallFunc:create(function (  )
        flyNode2:runCsbAction("actionframe")
        particle2:setDuration(-1)     --设置拖尾时间(生命周期)
        particle2:setPositionType(0)   --设置可以拖尾
        particle2:resetSystem()
    end)
    if col == 4 or col == 5 then
        actList1[#actList1 + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x-90 , startPos.y), cc.p(endPos.x - 190, startPos.y), endPos})
        actList2[#actList2 + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x+90 , startPos.y), cc.p(startPos.x + 190, endPos.y), endPos})

    elseif col == 3 then
        actList1[#actList1 + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x-90 , startPos.y), cc.p(startPos.x - 190, endPos.y), endPos})
        actList2[#actList2 + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x+90 , startPos.y), cc.p(startPos.x + 190, startPos.y), endPos})

    else
        actList1[#actList1 + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x-90 , startPos.y), cc.p(startPos.x - 190, endPos.y), endPos})
        actList2[#actList2 + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x+90 , startPos.y), cc.p(endPos.x + 190, startPos.y), endPos})

    end
    -- actList1[#actList1 + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x - 90 , startPos.y), cc.p(startPos.x - 90, endPos.y), endPos})
    -- actList2[#actList2 + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x + 90 , startPos.y), cc.p(endPos.x, startPos.y), endPos})
    actList1[#actList1 + 1] = cc.CallFunc:create(function (  )
        if func then
            func()
        end
    end)
    -- actList[#actList + 1] = cc.DelayTime:create(15/60)
    actList1[#actList1 + 1] = cc.CallFunc:create(function (  )
        particle1:stopSystem()--移动结束后将拖尾停掉
        flyNode1:removeFromParent()
    end)
    actList2[#actList2 + 1] = cc.CallFunc:create(function (  )
        particle2:stopSystem()
        flyNode2:removeFromParent()
    end)
    flyNode1:runAction(cc.Sequence:create( actList1))
    flyNode2:runAction(cc.Sequence:create( actList2))
end

function CodeGameScreenWingsOfPhoelinxMachine:showGuoChang(func,isLink)
    if isLink then
        gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_GuoChang.mp3")
    else
        gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Free_WingsOfPhoelinx_GuoChang.mp3")
    end
    self.m_GuoChangView:setVisible(true)
    
    util_spinePlay(self.m_GuoChangView,"actionframe",false)
    util_spineEndCallFunc(self.m_GuoChangView,"actionframe",function (  )
        self.m_GuoChangView:setVisible(false)
    end)
    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,1)
    
end

--中奖预告
function CodeGameScreenWingsOfPhoelinxMachine:winningNotice(func)
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Free_WingsOfPhoelinx_YuGao.mp3")
    self.yuGaoView:setVisible(true)

    self.yuGaoView:showYuGao(function (  )
        self.yuGaoView:setVisible(false)
        if func then
            func()
        end
    end)
end

--消息返回时判断是否播放中奖预告
function CodeGameScreenWingsOfPhoelinxMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    
    local num = 0
    local reels = self.m_runSpinResultData.p_reels
    if reels and #reels > 0 then
        for i,v in ipairs(reels) do
            for j,type in ipairs(v) do
                if type == 90 then
                    num = num + 1
                end
            end
        end
    end
    if num >= 3 then
        
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            local random = math.random(1,3)
            if random < 2 then
                --播放预告动画
                self.m_playWinningNotice = true
                self:winningNotice(function (  )
                    self:produceSlots()         --将它写在此处为了等self.m_playWinningNotice设为true
                    local isWaitOpera = self:checkWaitOperaNetWorkData()    --每一步都加上，防止后续修改遗漏条件
                    if isWaitOpera == true then
                        return
                    end
                    self.m_isWaitingNetworkData = false
                    self:operaNetWorkData()  -- end
                end)
            else
                self:produceSlots()
                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end
                self.m_isWaitingNetworkData = false
                self:operaNetWorkData()  -- end
            end
        else
            self:produceSlots()
            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end
            self.m_isWaitingNetworkData = false
            self:operaNetWorkData()  -- end
        end
    else
        self:produceSlots()
        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()  -- end
    end
    
end

--压暗层
function CodeGameScreenWingsOfPhoelinxMachine:showColorLayer( )
    for i=1,5 do
        self["m_colorLayer_waitNode_"..i]:stopAllActions()
        local layerNode = self["colorLayer_"..i]
        util_playFadeInAction(layerNode,0.1)
        layerNode:setVisible(true)
    end
end

function CodeGameScreenWingsOfPhoelinxMachine:hideColorLayer( )
    for i=1,5 do
        self["m_colorLayer_waitNode_"..i]:stopAllActions()
        local layerNode = self["colorLayer_"..i]
        util_playFadeOutAction(layerNode,0.1)
        layerNode:setVisible(true)
        performWithDelay(self["m_colorLayer_waitNode_"..i] ,function(  )
            layerNode:setVisible(false)
        end,0.1)
    end
end

--设置bonus scatter 信息
function CodeGameScreenWingsOfPhoelinxMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
    if (nextReelLong and symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then     --如果有中奖预告就不播放快滚
        nextReelLong = not self.m_playWinningNotice
    end

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
                if (nextReelLong and symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                    nextReelLong = not self.m_playWinningNotice
                end
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

function CodeGameScreenWingsOfPhoelinxMachine:scaleMainLayer()
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
    if display.height/display.width <= 640/960 and display.height/display.width > 768/1228 then
        mainScale = 1
    end
    if globalData.slotRunData.isPortrait == true then
       print("AllStar 不是竖版")
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + 8)
        util_csbScale(self.m_gameBg.m_csbNode, mainScale)
    end
    
end

function CodeGameScreenWingsOfPhoelinxMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "WingsOfPhoelinxSounds/WingsOfPhoelinx_scatter_down.mp3"
        local soundPathBonus = "WingsOfPhoelinxSounds/WingsOfPhoelinx_bonus_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
        self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = soundPathBonus
    end
end

-- 特殊信号下落时播放的音效
function CodeGameScreenWingsOfPhoelinxMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then

        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil
        local soundType = slotNode.p_symbolType
        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end
            
            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        elseif slotNode.p_symbolType == self.SYMBOL_BONUS1 then
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            else
                soundPath = SOUND_ENUM.MUSIC_SPECIAL_BONUS
            end
        end

        if soundPath then
            self:playBulingSymbolSounds( iCol,soundPath,soundType )
        end
    end
end

function CodeGameScreenWingsOfPhoelinxMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenWingsOfPhoelinxMachine:checkFeatureOverTriggerBigWin( winAmonut , feature)
    if winAmonut == nil then
        return
    end
    
    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i=1,#self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert( self.m_gameEffects, i + 1, delayEffect )

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert( self.m_gameEffects, i + 2, effectData )
                break
            end
        end
        if isAddEffect == false then
            for i=1,#self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut


                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert( self.m_gameEffects, i + 1, delayEffect )

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert( self.m_gameEffects, i + 2, effectData )
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert( self.m_gameEffects, 1, delayEffect )

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert( self.m_gameEffects, 2, effectData )
            end
        end

    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()

    if feature == GameEffect.EFFECT_BONUS then
        self:addRewaedFreeSpinStartEffect( )
        self:addRewaedFreeSpinOverEffect( )
    end
    
end

function CodeGameScreenWingsOfPhoelinxMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)


    -- slotParent:getParent():setLocalZOrder(zOrder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

return CodeGameScreenWingsOfPhoelinxMachine
