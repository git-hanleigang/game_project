---
-- island li
-- 2019年1月26日
-- CodeGameScreenMedusaManiaMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "MedusaManiaPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenMedusaManiaMachine = class("CodeGameScreenMedusaManiaMachine", BaseNewReelMachine)

CodeGameScreenMedusaManiaMachine.m_chooseRootScale = 1
CodeGameScreenMedusaManiaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenMedusaManiaMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenMedusaManiaMachine.SYMBOL_SCORE_11 = 10
CodeGameScreenMedusaManiaMachine.SYMBOL_SCORE_102 = 101

CodeGameScreenMedusaManiaMachine.EFFECT_JACKPOT_PLAY = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenMedusaManiaMachine.EFFECT_COLLECT_PLAY = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenMedusaManiaMachine.EFFECT_CHANGE_WILD = GameEffect.EFFECT_SELF_EFFECT - 3


-- 构造函数
function CodeGameScreenMedusaManiaMachine:ctor()
    CodeGameScreenMedusaManiaMachine.super.ctor(self)
    self.m_isFeatureOverBigWinInFree = true

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_curCollectLevel = 1

    self.triggerScatterDelayTime = 0
    self.triggerWildDelayTime = 0
    self.m_freeSelectType = 1
    self.m_panelOpacity = 102
    --整个美杜莎加在specialNode上，字体加在大美杜莎上
    self.tblSpecialNode = {}

    --整个美杜莎上边的wild字体
    self.tblBigWildTextSpineData = {}

    --H1变成整体的wild动画（一列只有一个）
    self.tblWildSpine = {}

    --H1变成wild后，上边整个的wild字体，播放完后用单个的
    self.tblWildBigTextSpine = {}

    --H1变成wild后，上边单个的wild字体
    self.tblWildTextSpineData = {}

    --假滚拖尾
    self.m_falseParticleTbl = {}
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
 
    --init
    self:initGame()
end

function CodeGameScreenMedusaManiaMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("MedusaManiaConfig.csv", "MedusaManiaConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMedusaManiaMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MedusaMania"  
end

function CodeGameScreenMedusaManiaMachine:getBottomUINode()
    return "CodeMedusaManiaSrc.MedusaManiaBottomNode"
end

--小块
function CodeGameScreenMedusaManiaMachine:getBaseReelGridNode()
    return "CodeMedusaManiaSrc.MedusaManiaSlotNode"
end

function CodeGameScreenMedusaManiaMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_MedusaManiaView = util_createView("CodeMedusaManiaSrc.MedusaManiaView")
    -- self:findChild("xxxx"):addChild(self.m_MedusaManiaView)

    --遮罩
    self.m_panelUpList = self:createMedusaManiaMask(self)
   
    self.m_jackpotView = util_createView("CodeMedusaManiaSrc.MedusaManiaJackpotView", self)
    self:findChild("Node_duofuduocai"):addChild(self.m_jackpotView)
    self.m_jackpotView:setVisible(false)

    self.m_baseFreeSpinBar = util_createView("CodeMedusaManiaSrc.MedusaManiaFreespinBarView", self)
    self:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
 
    self.m_jackPotBar = util_createView("CodeMedusaManiaSrc.MedusaManiaJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    self.m_chooseView = util_createView("CodeMedusaManiaSrc.MedusaManiaChoosePlayView", self)
    self:addChild(self.m_chooseView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_chooseView:setVisible(false)

    self.m_fuCaiSpine = util_spineCreate("MedusaMania_dfdcjinbi",true,true)
    self:findChild("Node_pen"):addChild(self.m_fuCaiSpine)

    self.m_yuGaoSpine = util_spineCreate("Socre_MedusaMania_yugao",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_yuGaoSpine)
    self.m_yuGaoSpine:setVisible(false)

    local nodePenX, nodePenY = self:findChild("Node_pen"):getPosition()
    local penWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePenX, nodePenY))

    self.m_fuCaiCutScene = util_spineCreate("MedusaMania_dfdcjinbi",true,true)
    self.m_fuCaiCutScene:setPosition(penWorldPos)
    self:addChild(self.m_fuCaiCutScene, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_fuCaiCutScene:setVisible(false)

    local nodePosX, nodePosY = self:findChild("Node_cutScene"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))

    self.m_guoChangSpine = util_spineCreate("MedusaMania_guochang4",true,true)
    self.m_guoChangSpine:setPosition(worldPos)
    self:addChild(self.m_guoChangSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChangSpine:setVisible(false)

    self.m_guoChangSpine_2 = util_spineCreate("MedusaMania_guochang3",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_guoChangSpine_2)
    self.m_guoChangSpine_2:setVisible(false)

    self.m_tblGameBg = {}
    self.m_tblGameBg[1] = self.m_gameBg:findChild("base_bg")
    self.m_tblGameBg[2] = self.m_gameBg:findChild("free_bg")

    self.m_chooseCutSpine = util_spineCreate("MedusaMania_guochang1",true,true)
    self.m_gameBg:findChild("Node_bottom"):addChild(self.m_chooseCutSpine)
    self.m_chooseCutSpine:setVisible(false)

    self.m_chooseCutSpine_1 = util_spineCreate("MedusaMania_guochang1",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_chooseCutSpine_1)
    self.m_chooseCutSpine_1:setVisible(false)

    self.m_bottomCutSpine = util_spineCreate("MedusaMania_qpxc",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_bottomCutSpine)
    self.m_bottomCutSpine:setVisible(false)

    local fireLeft = util_createAnimation("MedusaMania_tanban_huoyan.csb")
    self:findChild("Node_Left_fire"):addChild(fireLeft)
    fireLeft:runCsbAction("animation0", true)

    local fireRight = util_createAnimation("MedusaMania_tanban_huoyan.csb")
    self:findChild("Node_Right_fire"):addChild(fireRight)
    fireRight:runCsbAction("animation0", true)

    self.m_ReelNode = self:findChild("Node_reel")

    --free下预告火圈专用
    self.m_freeFireSpine = util_spineCreate("Socre_MedusaMania_wenzi",true,true)
    -- local firePos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
    local clipTarPos = util_getOneGameReelsTarSpPos(self, 15)
    local posY = 1.5 * self.m_SlotNodeH
    clipTarPos.y = clipTarPos.y+posY
    self.m_freeFireSpine:setPosition(clipTarPos)
    self.m_clipParent:addChild(self.m_freeFireSpine, 100)
    self.m_freeFireSpine:setVisible(false)

    self.m_skip_click = self:findChild("Panel_skip_click")
    self.m_skip_click:setVisible(false)
    self:addClick(self.m_skip_click)

    self.m_scWaitWildNode = cc.Node:create()
    self:addChild(self.m_scWaitWildNode)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitCollectNode = cc.Node:create()
    self:addChild(self.m_scWaitCollectNode)

    self.m_panel_clipeNode = self:findChild("panel_clipeNode")

    --scatter震动
    --全屏幕防点击
    self.m_gobalTouchLayer = ccui.Layout:create()
    self.m_gobalTouchLayer:setContentSize(cc.size(50000, 50000))
    self.m_gobalTouchLayer:setAnchorPoint(cc.p(0, 0))
    self.m_gobalTouchLayer:setTouchEnabled(false)
    self.m_gobalTouchLayer:setSwallowTouches(false)
    -- self.m_gobalTouchLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    -- self.m_gobalTouchLayer:setBackGroundColor(cc.c3b(0, 150, 0))
    -- self.m_gobalTouchLayer:setBackGroundColorOpacity(150)
    self:addChild(self.m_gobalTouchLayer, GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN + 1)

    --先添加20个wild
    self:addWildTextEffect()

    self.m_chooseView:scaleMainLayer(self.m_chooseRootScale)
    self:changeBgSpine(1)
    self:setBaseIdle()
end


function CodeGameScreenMedusaManiaMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 4, 0, 1)
    end,0.2,self:getModuleName())
end

function CodeGameScreenMedusaManiaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    --添加假滚开始的index
    self:addReelFalseData()

    --判断五列哪一列假滚需要填充数据（从自己找的索引开始假滚，配和H1和wild），开始和结束
    self:resetReelData()

    CodeGameScreenMedusaManiaMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenMedusaManiaMachine:addObservers()
    CodeGameScreenMedusaManiaMachine.super.addObservers(self)
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

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgmType = "fg"
        else
            bgmType = "base"
        end

        local soundName = "MedusaManiaSounds/music_MedusaMania_last_win_"..bgmType.."_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenMedusaManiaMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local tempPosY = 0 - mainPosY

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
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        if display.width / display.height >= 1660/768 then
            mainScale = mainScale * 1.08
            tempPosY = tempPosY + 4
        elseif display.width / display.height >= 1530/768 then
            mainScale = mainScale * 1.08
            tempPosY = tempPosY + 4
        elseif display.width / display.height >= 1370/768 then
            tempPosY = tempPosY + 4
            mainScale = mainScale * 1.08
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 1.0
            tempPosY = tempPosY - 5
            self.m_chooseRootScale = 0.9
        elseif display.width / display.height >= 960/640 then
            mainScale = mainScale * 0.90
            self.m_chooseRootScale = 0.85
        elseif display.width / display.height >= 1024/768 then
            mainScale = mainScale * 0.82
            self.m_chooseRootScale = 0.77
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY+tempPosY)
    end
end

function CodeGameScreenMedusaManiaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMedusaManiaMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

--[[
    初始轮盘
]]
function CodeGameScreenMedusaManiaMachine:initRandomSlotNodes()
    if type(self.m_configData.isHaveInitReel) == "function" and self.m_configData:isHaveInitReel() then
        self:initSlotNodes()
        self:addInitSlotWildSpine()
    else
        if self.m_currentReelStripData == nil then
            self:randomSlotNodes()
        else
            self:randomSlotNodesByReel()
        end
    end
end

--初始轮盘
function CodeGameScreenMedusaManiaMachine:addInitSlotWildSpine()
    local changeWildPos = {1, 3, 6, 8, 11, 13, 16, 18}
    for k, pos in pairs(changeWildPos) do
        local fixPos = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if symbolNode then
            local wildImg = util_createSprite("MedusaManiaSymbol/MedusaMania_Wild.png")
            wildImg:setScale(0.5)
            wildImg:setName("initWildImg")
            symbolNode:addChild(wildImg, 100)
        end
    end

    --美杜莎
    local fixPos = self:getRowAndColByPos(2)
    local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
    local zorder = self:getCurWildZorder(fixPos.iY) + 10
    symbolNode:setLocalZOrder(zorder)

    local bigWildImg = util_createSprite("MedusaManiaSymbol/MedusaMania_BigWild.png")
    bigWildImg:setScale(0.5)
    bigWildImg:setName("initWildImg")
    symbolNode:addChild(bigWildImg, 100)

    if symbolNode then
        -- self:changeToMaskLayerSlotNode(symbolNode, true)
        local posY = 1.5*self.m_SlotNodeH
        bigWildImg:setPosition(cc.p(0, -posY))
    end
end

function CodeGameScreenMedusaManiaMachine:initGameUI()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData then
        if selfData.scatterlevel then
            self.m_curCollectLevel = selfData.scatterlevel
        end
    end
    self:refreshTopMiddleCoins()

    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        self:changeBgSpine(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)

        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        if fsExtraData and fsExtraData.kind then
            self:setFreeSelectType(fsExtraData.kind)
        end
    end
end

function CodeGameScreenMedusaManiaMachine:setFreeSelectType(_selectType)
    self.m_freeSelectType = _selectType
    self.m_baseFreeSpinBar:setCutFreeType(_selectType)
end

function CodeGameScreenMedusaManiaMachine:refreshTopMiddleCoins()
    if self.m_curCollectLevel then
        local actionFrameName = "idleframe"..self.m_curCollectLevel
        util_spinePlay(self.m_fuCaiSpine, actionFrameName, true)
    end
end

function CodeGameScreenMedusaManiaMachine:addReelFalseData()
    --随机每列的index开的的索引(1-4列)
    --1：有1个h1，2：有两个H1，3：有三个H1，4有4个H1
    
    -- 顶上插入H1小块
    self.tblBaseColRandomStartIndex = {}
    self.tblFreeColRandomStartIndex = {}
    --底部插入H1小块（停轮前）
    self.tblBaseColRandomEndIndex = {}
    self.tblFreeColRandomEndIndex = {}
    -- 一列最多有4个H1
    local symbolCount = 4
    --base
    for iCol=1, self.m_iReelColumnNum do
        local curColData = {}
        local curColEndData = {}
        table.insert(self.tblBaseColRandomStartIndex, curColData)
        table.insert(self.tblBaseColRandomEndIndex, curColEndData)
        for i=1, symbolCount do
            local curColCountData = {}
            local curColCountEndData = {}
            table.insert(self.tblBaseColRandomStartIndex[iCol], curColCountData)
            table.insert(self.tblBaseColRandomEndIndex[iCol], curColCountEndData)
        end
    end
    --free
    --free有三种假滚数据
    for i=1, 3 do
        local freeTypeStartTbl = {}
        local freeTypeEndTbl = {}
        table.insert(self.tblFreeColRandomStartIndex, freeTypeStartTbl)
        table.insert(self.tblFreeColRandomEndIndex, freeTypeEndTbl)

        for iCol=1, self.m_iReelColumnNum do
            local curColFgData = {}
            local curColFgEndData = {}
            table.insert(self.tblFreeColRandomStartIndex[i], curColFgData)
            table.insert(self.tblFreeColRandomEndIndex[i], curColFgEndData)

            for j=1, symbolCount do
                local curColCountFgData = {}
                local curColCountFgEndData = {}
                table.insert(self.tblFreeColRandomStartIndex[i][iCol], curColCountFgData)
                table.insert(self.tblFreeColRandomEndIndex[i][iCol], curColCountFgEndData)
            end
        end
    end

    -- 填充数据
    --base
    for iCol = 1, self.m_iReelColumnNum do
        local curColData = self.tblBaseColRandomStartIndex[iCol]
        local curColEndData = self.tblBaseColRandomEndIndex[iCol]
        local reelCount = self.m_configData.p_reelRunDatas[iCol]
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(iCol)
        for i=#reelDatas, 1, -1 do
            local symbolType = reelDatas[i]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                for j=1, symbolCount do
                    local curColCountData = curColData[j]
                    curColCountData[#curColCountData+1] = i-8+j

                    --底部数据
                    local curColCountEndData = curColEndData[j]
                    local count = i+1-reelCount-j+self.m_iReelRowNum
                    if count <= 0 then
                        count = count + #reelDatas
                    end
                    curColCountEndData[#curColCountEndData+1] = count
                end
            end
        end
    end

    --free
    for freeTypeIndex = 1, 3 do
        for iCol = 1, self.m_iReelColumnNum do
            local curColFgData = self.tblFreeColRandomStartIndex[freeTypeIndex][iCol]
            local curColFgEndData = self.tblFreeColRandomEndIndex[freeTypeIndex][iCol]
            local reelCount = self.m_configData.p_reelRunDatas[iCol]
            local reelFgDatas = self.m_configData:getFsReelDatasByColumnIndex(freeTypeIndex, iCol)
            for i=#reelFgDatas, 1, -1 do
                local symbolType = reelFgDatas[i]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    for j=1, symbolCount do
                        local curColCountFgData = curColFgData[j]
                        curColCountFgData[#curColCountFgData+1] = i-8+j
    
                        --底部数据
                        local curColCountFgEndData = curColFgEndData[j]
                        local count = i+1-reelCount-j+self.m_iReelRowNum
                        if count <= 0 then
                            count = count + #reelFgDatas
                        end
                        curColCountFgEndData[#curColCountFgEndData+1] = count
                    end
                end
            end
        end
    end
end

function CodeGameScreenMedusaManiaMachine:addWildTextEffect()
    local totalCount = self.m_iReelRowNum * self.m_iReelColumnNum
    for i=1, totalCount do
        local wildTextSpine = util_spineCreate("Socre_MedusaMania_9",true,true)
        local fixPos = self:getRowAndColByPos(i-1)
        local clipTarPos = util_getOneGameReelsTarSpPos(self, i-1)
        -- clipTarPos.x = clipTarPos.x + 30
        wildTextSpine:setPosition(clipTarPos)
        local zorder = 20-fixPos.iX - fixPos.iY
        self.m_clipParent:addChild(wildTextSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER-zorder)
        -- util_spinePlay(wildTextSpine, "idleframe2_1_wenzi", true)

        --存起来，播放连线使用
        local tempTbl = {}
        tempTbl.p_rowIndex = fixPos.iX
        tempTbl.p_cloumnIndex = fixPos.iY
        tempTbl.wildTextSpine = wildTextSpine
        tempTbl.m_actionframe = "actionframe1_wenzi"
        tempTbl.m_idleframe = "idleframe2_1_wenzi"
        wildTextSpine:setVisible(false)
        self.tblWildTextSpineData[i] = tempTbl
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMedusaManiaMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_MedusaMania_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_MedusaMania_11"
    elseif symbolType == self.SYMBOL_SCORE_102 then
        return "Socre_MedusaMania_wenzi"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMedusaManiaMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMedusaManiaMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

--顶部补块
function CodeGameScreenMedusaManiaMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local columnData = self.m_reelColDatas[parentData.cloumnIndex]
    local rowIndex = parentData.rowIndex + 1
    local symbolType = nil
    if self.m_bCreateResNode == false then
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = self:getResNodeSymbolType(parentData)
    end

    local m_colState = self.tblCurColTopSymbolData[parentData.cloumnIndex].m_state
    if m_colState then
        local colSymbolCount = self.tblCurColTopSymbolData[parentData.cloumnIndex].m_count
        if type(colSymbolCount) == "number" then
            if colSymbolCount > 0 then
                symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
            else
                symbolType = math.random(1, 5)
            end
        end
    else
        symbolType = math.random(1, 5)
    end
    -- if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --     symbolType = math.random(1, 5)
    -- end
    parentData.symbolType = symbolType
    if self.m_bigSymbolInfos[symbolType] ~= nil then
        parentData.order =  self:getBounsScatterDataZorder(symbolType) - rowIndex
    else
        parentData.order = self:getBounsScatterDataZorder(symbolType) - rowIndex
    end
    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    parentData.tag = parentData.cloumnIndex * SYMBOL_NODE_TAG + rowIndex
    parentData.reelDownAnima = nil
    parentData.reelDownAnimaSound = nil
    parentData.m_isLastSymbol = false
    parentData.rowIndex = rowIndex
end

--默认按钮监听回调
function CodeGameScreenMedusaManiaMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_skip_click" then
        self:runSkipWild()
    end
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenMedusaManiaMachine:MachineRule_initGame(  )

    
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenMedusaManiaMachine:initGameStatusData(gameData)
    local featureData = gameData.feature
    local spinData = gameData.spin
    if featureData and spinData then
        if featureData.features and #featureData.features == 2 then
            if featureData.features[2] == 1 then
                spinData.freespin = featureData.freespin
                spinData.reels = featureData.freespin.extra.reels
            else
                spinData.features = featureData.features
            end
        end
    end

    CodeGameScreenMedusaManiaMachine.super.initGameStatusData(self,gameData)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMedusaManiaMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

    if self.isPlayYuGao then
        self.isPlayYuGao = false
        for i = 1, #self.m_reelRunInfo do
            local runInfo = self.m_reelRunInfo[i]
            runInfo:setReelRunLen(runInfo.initInfo.reelRunLen)
            runInfo:setNextReelLongRun(runInfo.initInfo.bReelRun)      
            runInfo:setReelLongRun(true)
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenMedusaManiaMachine:slotOneReelDown(reelCol)    
    CodeGameScreenMedusaManiaMachine.super.slotOneReelDown(self,reelCol)
    local curReelCol = reelCol
   ---本列是否开始长滚
    local isTriggerLongRun = false
    if reelCol == 1 then
        self.isHaveLongRun = false
    end
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true
    end

    if isTriggerLongRun then
        self.isHaveLongRun = true
        self:playScatterSpine("idleframe3", reelCol)
        for i = 1, self.m_iReelColumnNum-1 do
            self:changeMaskVisible(true, i, true)
            self.m_panelUpList[i]:setVisible(true)
            self:playMaskFadeAction(true, 0.2, i, function()
                self:changeMaskVisible(true, i)
            end)
        end
    else
        if reelCol == self.m_iReelColumnNum and self.isHaveLongRun == true then
            --落地
            self.triggerScatterDelayTime = 23/30
            self:playScatterSpine("idleframe2", reelCol, true)
        end
    end

    --停轮后检查是否有拖尾，有的话直接删除
    for iRow = 1, self.m_iReelRowNum do
        local slotNode = self:getFixSymbol(curReelCol, iRow, SYMBOL_NODE_TAG)
        if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            slotNode:removeTuowei()
        end
    end
end

function CodeGameScreenMedusaManiaMachine:playScatterSpine(_spineName, _reelCol, isOver)
    performWithDelay(self.m_scWaitNode, function()
        for iCol = 1, _reelCol  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if _spineName == "idleframe3" and targSp.m_currAnimName ~= "idleframe3" then
                            targSp:runAnim(_spineName, true)
                        elseif _spineName == "idleframe2" then
                            targSp:runAnim(_spineName, true)
                        end
                    end
                end
            end
        end
    end, 0.1)
end

--[[
    @desc: 遮罩相关
]]
function CodeGameScreenMedusaManiaMachine:createMedusaManiaMask(_mainClass)
    --棋盘主类
    local tblMaskList = {}
    local mainClass = _mainClass or self
    
    for i=1, 5 do
        --单列卷轴尺寸
        local reel = mainClass:findChild("sp_reel_"..i-1)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()
        --棋盘尺寸
        local offsetSize = cc.size(5, 5)
        reelSize.width = reelSize.width * scaleX + offsetSize.width
        reelSize.height = reelSize.height * scaleY + offsetSize.height
        --遮罩尺寸和坐标
        local clipParent = mainClass.m_onceClipNode or mainClass.m_clipParent
        local panelOrder = 10000--REEL_SYMBOL_ORDER.REEL_ORDER_4--SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1

        local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
        panel:setOpacity(self.m_panelOpacity)
        panel:setContentSize(reelSize.width, reelSize.height)
        panel:setPosition(cc.p(posX - offsetSize.width / 2, posY - offsetSize.height / 2))
        clipParent:addChild(panel, panelOrder)
        panel:setVisible(false)
        tblMaskList[i] = panel
    end
    
    return tblMaskList
end

function CodeGameScreenMedusaManiaMachine:changeMaskVisible(_isVis, _reelCol, _isOpacity)
    if _isOpacity then
        self.m_panelUpList[_reelCol]:setVisible(_isVis)
        self.m_panelUpList[_reelCol]:setOpacity(0)
    else
        self.m_panelUpList[_reelCol]:setVisible(_isVis)
        self.m_panelUpList[_reelCol]:setOpacity(self.m_panelOpacity)
    end
end

function CodeGameScreenMedusaManiaMachine:playMaskFadeAction(_isFadeTo, _fadeTime, _reelCol, _fun)
    local fadeTime = _fadeTime or 0.1
    local opacity = self.m_panelOpacity

    local act_fade = _isFadeTo and cc.FadeTo:create(fadeTime, opacity) or cc.FadeOut:create(fadeTime)
    if not _isFadeTo then
        self.m_panelUpList[_reelCol]:setOpacity(opacity)
    end
    self.m_panelUpList[_reelCol]:setVisible(true)
    self.m_panelUpList[_reelCol]:runAction(act_fade)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            if _fun then
                _fun()
            end

            waitNode:removeFromParent()
        end,
        fadeTime
    )
end

function CodeGameScreenMedusaManiaMachine:beginReel()
    self.m_lineSlotNodes = {}
    self.m_curSpinIsQuickStop = false
    self.m_freeFireSpine:setVisible(false)
    CodeGameScreenMedusaManiaMachine.super.beginReel(self)
    self.m_panel_clipeNode:setClippingEnabled(true)

    --大wild、和大wild上边的字
    if self.tblSpecialNode and #self.tblSpecialNode > 0 then
        for i=1, #self.tblSpecialNode do
            if not tolua.isnull(self.tblSpecialNode[i]) then
                self.tblBigWildTextSpineData[i] = nil
                self.tblSpecialNode[i]:removeFromParent()
                self.tblSpecialNode[i] = nil
            end
        end
    end

    --H1变成的wild
    if self.tblWildTextSpineData and #self.tblWildTextSpineData > 0 then
        for i=1, #self.tblWildTextSpineData do
            local wildTextSpine = self.tblWildTextSpineData[i].wildTextSpine
            if not tolua.isnull(wildTextSpine) then
                -- wildTextSpine:removeFromParent()
                -- self.tblWildTextSpineData[i] = nil
                util_spinePlay(wildTextSpine, "idleframe2_1_wenzi", false)
                wildTextSpine:setVisible(false)
                self.tblWildTextSpineData[i].curPlayLine = false
            end
        end
    end

    --整列的wild小块移除
    if type(self.tblWildSpine) == "table" then
        for i=1, self.m_iReelColumnNum do
            local topWildNode = self.tblWildSpine[i]
            if not tolua.isnull(topWildNode) then
                topWildNode:removeFromParent()
                self.tblWildSpine[i] = nil
            end
        end
    end

    --整列的wild小块移除
    if type(self.tblWildBigTextSpine) == "table" then
        for i=1, self.m_iReelColumnNum do
            local wildBigTextSpine = self.tblWildBigTextSpine[i]
            if not tolua.isnull(wildBigTextSpine) then
                wildBigTextSpine:removeFromParent()
                self.tblWildBigTextSpine[i] = nil
            end
        end
    end
end

function CodeGameScreenMedusaManiaMachine:resetReelData()
    self.tblCurColTopSymbolData = {}
    self.tblCurColBottomData = {}
    for i=1, self.m_iReelColumnNum do
        local tempTopTbl = {}
        tempTopTbl.m_state = false
        tempTopTbl.m_count = 0
        table.insert(self.tblCurColTopSymbolData, tempTopTbl)

        local tempBottomTbl = {}
        tempBottomTbl.m_state = false
        tempBottomTbl.m_count = 0
        table.insert(self.tblCurColBottomData, tempBottomTbl)
    end
end

--判断顶部和底部信号
function CodeGameScreenMedusaManiaMachine:checkCurReelSymbolCount()
    self:resetReelData()

    local reelsData = self.m_runSpinResultData.p_reels
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = reelsData[iRow][iCol]
            self.tblCurColTopSymbolData[iCol].m_state = true
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                -- self.tblCurColTopSymbolData[iCol].m_state = true
                self.tblCurColTopSymbolData[iCol].m_count = self.tblCurColTopSymbolData[iCol].m_count + 1
            else
                break
            end
        end
    end

    --底部
    -- self.m_stcValidSymbolMatrix[iRow][iCol]
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolType = reelsData[iRow][iCol]
            self.tblCurColBottomData[iCol].m_state = true
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                -- self.tblCurColBottomData[iCol].m_state = true
                self.tblCurColBottomData[iCol].m_count = self.m_iReelRowNum - iRow + 1
                break
            end
        end
    end
end

function CodeGameScreenMedusaManiaMachine:updateNetWorkData()
    local callFunc = function()
        CodeGameScreenMedusaManiaMachine.super.updateNetWorkData(self)
    end

    self:checkCurReelSymbolCount()
    self.isPlayYuGao = false
    local featureDatas = self.m_runSpinResultData.p_features or {}

    -- if featureDatas and (featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureDatas[2] == SLOTO_FEATURE.FEATURE_FREESPIN) then
    if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        local randomNum = math.random(1, 10)
        if randomNum <= 4 then
            self.isPlayYuGao = true
            self.triggerScatterDelayTime = 15/30
        end
        -- self.isPlayYuGao = true
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --free下的整列wild预告
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.free_wild_position then
            local pos = selfData.free_wild_position[1]
            local fixPos = self:getRowAndColByPos(pos) 
            local posX = (fixPos.iY-3) * (self.m_SlotNodeW + 4)
            self.m_freeFireSpine:setPositionX(posX)
            self.m_freeFireSpine:setVisible(true)
            util_spinePlay(self.m_freeFireSpine, "actionframe4_guang", false)
            util_spineEndCallFunc(self.m_freeFireSpine, "actionframe4_guang", function()
                util_spinePlay(self.m_freeFireSpine, "idle4", true)
                callFunc()
            end)
        else
            callFunc() 
        end
    else
        if self.isPlayYuGao then
            self.m_yuGaoSpine:setVisible(true)
            gLobalSoundManager:playSound(self.m_publicConfig.Music_YuGao_Sound)
            util_spinePlay(self.m_yuGaoSpine, "yugao", false)
            util_spineEndCallFunc(self.m_yuGaoSpine, "yugao", function()
                self.m_yuGaoSpine:setVisible(false)
                callFunc()
            end)
        else
            callFunc() 
        end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMedusaManiaMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMedusaManiaMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

---
-- 显示bonus 触发的小游戏
function CodeGameScreenMedusaManiaMachine:showEffect_Bonus(effectData)
    self.m_beInSpecialGameTrigger = true

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停止播放背景音乐
    -- self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then
        self:showBonusAndScatterLineTip(
            bonusLineValue,
            function()
                self:showBonusGameView(effectData)
            end
        )
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playBonusTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenMedusaManiaMachine:showBonusGameView(_effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.triggerScatterDelayTime = 0
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- 停掉背景音乐
        -- self:clearCurMusicBg()

        local waitTime = 0
        self:shakeOneNodeForeverRootNode(1.5)
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                        local parent = slotNode:getParent()
                        if parent ~= self.m_clipParent then
                            slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                        else
                            slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 5)
                        end
                        slotNode:runAnim("actionframe")
                        local duration = slotNode:getAniamDurationByName("actionframe")
                        waitTime = util_max(waitTime,duration)
                    end
                end
            end
        end
        self:playScatterTipMusicEffect()
        performWithDelay(self,function(  )
            self:showCutScene(_effectData)
        end,waitTime)
    end, self.triggerScatterDelayTime)
end

--选择弹板之前就切场景
function CodeGameScreenMedusaManiaMachine:showCutScene(_effectData)
    self.m_chooseCutSpine:setVisible(true)
    self.m_bottomCutSpine:setVisible(true)
    util_spinePlay(self.m_chooseCutSpine, "idle2", true)
    util_spinePlay(self.m_bottomCutSpine, "xiachen", false)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Main_Down)
    self:runCsbAction("xiachen", false, function()
        self.m_bottomCutSpine:setVisible(false)
        self:runCsbAction("idle2", true)
        self:showChooseView(_effectData)
    end)
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenMedusaManiaMachine:showChooseView(effectData)
    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    self.m_chooseView:setVisible(true)
    self.m_chooseView:playSpineStart()
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startStart)
    self.m_chooseView:runCsbAction("start",false, function()
        self.m_chooseView:refreshData(endCallFunc)
        self.m_chooseView:runCsbAction("idle", true)
    end)
end

function CodeGameScreenMedusaManiaMachine:playBgCutSpine()
    util_spinePlay(self.m_chooseCutSpine, "actionframe3", false)
    util_spineFrameEvent(self.m_chooseCutSpine , "actionframe3","switch",function ()
        self.m_gameBg:runCsbAction("actionframe3", false)
    end)
end

function CodeGameScreenMedusaManiaMachine:playChooseCutScene(_callFunc)
    util_spinePlay(self.m_chooseCutSpine, "actionframe_guochang1", false)
    util_spinePlay(self.m_chooseCutSpine_1, "actionframe_guochang1", false)
    -- gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_CutScene)
    -- gLobalSoundManager:fadeOutBgMusic(1.5)
    util_spineFrameEvent(self.m_chooseCutSpine , "actionframe_guochang1","switch",function ()
        self.m_chooseCutSpine_1:setVisible(true)
        self.m_chooseCutSpine:setVisible(false)
        self:runCsbAction("idle", true)
        self.m_gameBg:runCsbAction("idle", true)
        self:changeBgSpine(2)
        if type(_callFunc) == "function" then
            _callFunc()
        end
    end)
    util_spineEndCallFunc(self.m_chooseCutSpine, "actionframe_guochang1", function()
        self.m_chooseCutSpine_1:setVisible(false)
    end)
end

-- 显示free spin
function CodeGameScreenMedusaManiaMachine:showEffect_FreeSpin(effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.triggerScatterDelayTime = 0
        self.m_beInSpecialGameTrigger = true
        local waitTime = 0
        if not self.m_bInSuperFreeSpin and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            -- 取消掉赢钱线的显示
            self:shakeOneNodeForeverRootNode(1.5)
            self:clearWinLineEffect()
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if slotNode then
                        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                            local parent = slotNode:getParent()
                            if parent ~= self.m_clipParent then
                                slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                            else
                                slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 5)
                            end
                            slotNode:runAnim("actionframe")
                            local duration = slotNode:getAniamDurationByName("actionframe")
                            waitTime = util_max(waitTime,duration)
                        end
                    end
                end
            end
            self:playScatterTipMusicEffect(true)
        end
        
        performWithDelay(self,function(  )
            self:showFreeSpinView(effectData)
        end,waitTime)
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    end, self.triggerScatterDelayTime)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenMedusaManiaMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("MedusaManiaSounds/music_MedusaMania_custom_enter_fs.mp3")

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local showFSView = function ( ... )
            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_More_startOver)
                self.m_baseFreeSpinBar:setIsRefresh(true)
                local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,true)

                local lightAni = util_createAnimation("MedusaMania_tanban_beiguang.csb")
                view:findChild("beiguang"):addChild(lightAni)
                lightAni:runCsbAction("animation0", true)

                for i = 1, 3 do
                    if i == self.m_freeSelectType then
                        view:findChild("num_"..i):setVisible(true)
                        view:findChild("chengbei"..i):setVisible(true)
                    else
                        view:findChild("num_"..i):setVisible(false)
                        view:findChild("chengbei"..i):setVisible(false)
                    end
                end
                util_setCascadeOpacityEnabledRescursion(view, true)
            end
        end
    
        --  延迟0.5 不做特殊要求都这么延迟
        performWithDelay(self,function(  )
            showFSView()    
        end,0.5)
    else
        -- 停掉背景音乐
        -- self:clearCurMusicBg()
        self:triggerFreeSpinCallFun()
        effectData.p_isPlay = true
        self:playGameEffect()
        self:changeBgSpine(2)
        -- local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
        --     self:triggerFreeSpinCallFun()
        --     effectData.p_isPlay = true
        --     self:playGameEffect()
        --     self:changeBgSpine(2)
        -- end)
    end
end

function CodeGameScreenMedusaManiaMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("MedusaManiaSounds/music_MedusaMania_over_fs.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local function callFunc()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_OverDialog)
        end, 5/60)
    end
    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_BgOver, 4, 0, 1)
    if globalData.slotRunData.lastWinCoin > 0 then
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:showCutSceneOverAni(function()
                    self:triggerFreeSpinOverCallFun()
                end)
            end)
        local fireLeft = util_createAnimation("MedusaMania_tanban_huoyan.csb")
        view:findChild("huoyan1"):addChild(fireLeft)
        fireLeft:runCsbAction("animation0", true)

        local fireRight = util_createAnimation("MedusaMania_tanban_huoyan.csb")
        view:findChild("huoyan2"):addChild(fireRight)
        fireRight:runCsbAction("animation0", true)

        for i =1, 3 do
            if i == self.m_freeSelectType then
                view:findChild("mul_"..i):setVisible(true)
            else
                view:findChild("mul_"..i):setVisible(false)
            end
        end
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.0,sy=1.0},708)
        view:setBtnClickFunc(callFunc)
        util_setCascadeOpacityEnabledRescursion(view, true)
    else
        local view = self:showFreeSpinOverNoWin(function()
            self:showCutSceneOverAni(function()
                self:triggerFreeSpinOverCallFun()
            end)
        end)

        local fireLeft = util_createAnimation("MedusaMania_tanban_huoyan.csb")
        view:findChild("huoyan1"):addChild(fireLeft)
        fireLeft:runCsbAction("animation0", true)

        local fireRight = util_createAnimation("MedusaMania_tanban_huoyan.csb")
        view:findChild("huoyan2"):addChild(fireRight)
        fireRight:runCsbAction("animation0", true)

        view:setBtnClickFunc(callFunc)
        util_setCascadeOpacityEnabledRescursion(view, true)
    end
end

function CodeGameScreenMedusaManiaMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FreeSpinOver_NoWin",nil,_func)
    return view
end

function CodeGameScreenMedusaManiaMachine:showCutSceneOverAni(_callFunc)
    self.m_guoChangSpine_2:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_BackBgCutScene)
    util_spinePlay(self.m_guoChangSpine_2, "actionframe_guochang3", false)
    util_spineFrameEvent(self.m_guoChangSpine_2 , "actionframe_guochang3","switch",function ()
        self:changeBgSpine(1)
    end)
    util_spineEndCallFunc(self.m_guoChangSpine_2, "actionframe_guochang3", function()
        self.m_guoChangSpine_2:setVisible(false)
        if type(_callFunc) == "function" then
            _callFunc()
        end
    end)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMedusaManiaMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMedusaManiaMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.isDuoFuDuoCai = false
    self.m_isAddBigWinLightEffect = true
    self.m_lineSlotNodes = {}

    local tblChangeWild = self:getCurReelWildData()
    -- if (selfData.change_position and #selfData.change_position > 0) or (self:getCurrSpinMode() == FREE_SPIN_MODE and selfData.free_wild_position) then
    if #tblChangeWild > 0 or (self:getCurrSpinMode() == FREE_SPIN_MODE and selfData.free_wild_position) then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = self.EFFECT_CHANGE_WILD
        effectData.p_selfEffectType = self.EFFECT_CHANGE_WILD
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end

    if selfData.jackpot then
        self.isDuoFuDuoCai = true
        self.m_isAddBigWinLightEffect = false
        local effectData = GameEffectData.new()
        local order = GameEffect.EFFECT_LINE_FRAME + 2
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = order
        effectData.p_selfEffectType = self.EFFECT_JACKPOT_PLAY
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end

    if selfData.sc_position and #selfData.sc_position > 0 then
        local effectData = GameEffectData.new()
        local order = self.EFFECT_COLLECT_PLAY
        if self.isDuoFuDuoCai then
            order = GameEffect.EFFECT_LINE_FRAME + 1
        end
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = order
        effectData.p_selfEffectType = self.EFFECT_COLLECT_PLAY
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMedusaManiaMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_CHANGE_WILD then
        performWithDelay(self.m_scWaitNode, function()
            self.triggerWildDelayTime = 0
            self:playChangeWild(effectData)
        end, self.triggerWildDelayTime)
    elseif effectData.p_selfEffectType == self.EFFECT_COLLECT_PLAY then
        performWithDelay(self.m_scWaitNode, function()
            self.triggerScatterDelayTime = 0
            self:playCollectScatter(effectData)
        end, self.triggerScatterDelayTime)
    elseif effectData.p_selfEffectType == self.EFFECT_JACKPOT_PLAY then
        self:playJackpotPlay(effectData)
    end
    
    return true
end

function CodeGameScreenMedusaManiaMachine:playChangeWild(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local changeLocs = selfData.change_position
    local freeWildPos = selfData.free_wild_position

    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    --h1-变wild
    local changeWildFunc = function(tblChangeWild)
        local groupWild, totalCount = self:getColGroup(changeLocs, tblChangeWild)
        local changeName = {"switchto_wild1", "switchto_wild2", "switchto_wild3", "switchto_wild4"}
        local changeTextName = {"switchto_wild1_wenzi", "switchto_wild2_wenzi", "switchto_wild3_wenzi", "switchto_wild4_wenzi"}
        local actionframeName = {"actionframe1", "actionframe2", "actionframe3", "actionframe4"}
        local idleframeName = {"idleframe2_1", "idleframe2_2", "idleframe2_3", "idleframe2_4"}
        local curPlayCount = 0
        local delayTime = 0
        if groupWild and #groupWild > 0 then
            for k,curGroup in pairs(groupWild) do
                local delayTime = (k-1)*0.2
                performWithDelay(self.m_scWaitWildNode, function()
                    local isLast = k == #groupWild and true or false
                    if isLast then
                        gLobalSoundManager:playSound(self.m_publicConfig.Music_Change_Wild)
                    end
                    for count,curColData in pairs(curGroup) do
                        local curCount = #curColData
                        local colData = curColData
                        local pos = tonumber(curColData[1])
                        local fixPos = self:getRowAndColByPos(pos)
                        local bottomNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                        if bottomNode then
                            -- self:changeToMaskLayerSlotNode(bottomNode, true, true)
                            local curCol = bottomNode.p_cloumnIndex
                            local topWildNode = self.tblWildSpine[curCol]
                            local wildBigTextSpine = self.tblWildBigTextSpine[curCol]
                            
                            topWildNode:setVisible(true)
                            wildBigTextSpine:setVisible(true)
                            util_spinePlay(wildBigTextSpine,changeTextName[curCount],false)
                            topWildNode:runAnim(changeName[curCount], false, function()
                                curPlayCount = curPlayCount + curCount
                                topWildNode:runAnim(idleframeName[curCount], true)

                                for i = 1, #colData do
                                    local wildTextSpine = self.tblWildTextSpineData[colData[i]+1].wildTextSpine
                                    util_spinePlay(wildTextSpine,"idleframe2_1_wenzi",true)
                                    wildTextSpine:setVisible(true)
                                end

                                if curPlayCount == totalCount and type(endCallFunc) == "function" and self:getCurSkipState() then
                                    self:setSkipData(nil, nil, nil, false)
                                    endCallFunc()
                                end
                            end)
                        end
                    end
                end, delayTime)
            end
        else
            if type(endCallFunc) == "function" and self:getCurSkipState() then
                self:setSkipData(nil, nil, nil, false)
                endCallFunc()
            end
        end
    end

    --先变wild，后把H1图标变成wild
    self:changeAllWild(changeLocs, freeWildPos, changeWildFunc, endCallFunc)
end

--H1变身时分组向外延伸，最多分两组（例如美杜莎在第三列，那么两组分别为2、4和1、5）
function CodeGameScreenMedusaManiaMachine:getColGroup(_changeLocs, _tblChangeWild)
    local changeLocs = _changeLocs
    local tblChangeWild = _tblChangeWild
    local totalCount = 0
    local totalColTbl = {}
    --base下最多有一个wild，free下最多有两个wild(整理好一列为单位向外延伸，因为有光圈的存在)
    if self:getCurrSpinMode() == FREE_SPIN_MODE and _tblChangeWild and #_tblChangeWild > 1 then
        local playAnimList = {}
        local animList = {}

        table.sort(changeLocs,function(a,b)
            return a > b
        end)
    
        for i=1,#changeLocs do
            local posIndex = changeLocs[i]
            local fixPos = self:getRowAndColByPos(posIndex)
            if not animList[fixPos.iY] then
                animList[fixPos.iY] = {}
            end
            table.insert( animList[fixPos.iY] , posIndex )
        end

        local addPlayAnimList = function(_list,_listIndex,_data,_dataIndex)
            if _data[_dataIndex] then
                if  not _list[_listIndex] then
                    _list[_listIndex] = {}
                end
                -- _data[_dataIndex].iCol = _dataIndex
                for i=1, #_data[_dataIndex] do
                    totalCount = totalCount + 1
                end
                table.insert( _list[_listIndex], _data[_dataIndex] )
                _data[_dataIndex] = nil
                return false
            else
                return true
            end
        end

        local beigenColNor = self:getRowAndColByPos(_tblChangeWild[1]).iY 
        local beigenColRod = self:getRowAndColByPos(_tblChangeWild[2]).iY 

        local addNum = 0

        while true do
            local listNum = #totalColTbl + 1
            addNum = addNum + 1

            -- nor为主，rod为辅
            -- nor 开始-》maxCol
            addPlayAnimList(totalColTbl,listNum,animList,beigenColNor + addNum)
            -- nor 开始-》minCol
            addPlayAnimList(totalColTbl,listNum,animList,beigenColNor - addNum)

            -- nor 开始-》maxCol
            addPlayAnimList(totalColTbl,listNum,animList,beigenColRod + addNum)
            -- nor 开始-》minCol
            addPlayAnimList(totalColTbl,listNum,animList,beigenColRod - addNum)

            if table_length(animList) == 0 then
                break
            end
        end
    else
        local fixPos = self:getRowAndColByPos(_tblChangeWild[1])
        local curCol = fixPos.iY
        for i=1, self.m_iReelColumnNum-1 do
            local tempColTbl = {}
            local lastCol = curCol - i
            local nextCol = curCol + i
            --wild的前一列
            if lastCol >= 1 and lastCol <= 5 then
                local tempTbl = {}
                for j=1, #changeLocs do
                    local pos = changeLocs[j]
                    local fixPos = self:getRowAndColByPos(pos)
                    if fixPos.iY == lastCol then
                        tempTbl[#tempTbl+1] = pos
                        totalCount = totalCount + 1
                    end
                end
                if #tempTbl > 0 then
                    table.sort( tempTbl, function(a, b)
                        return a > b
                    end)
                    tempColTbl[#tempColTbl+1] = tempTbl
                end
            end

            --wild的后一列
            if nextCol >= 1 and nextCol <= 5 then
                local tempTbl = {}
                for j=1, #changeLocs do
                    local pos = changeLocs[j]
                    local fixPos = self:getRowAndColByPos(pos)
                    if fixPos.iY == nextCol then
                        tempTbl[#tempTbl+1] = pos
                        totalCount = totalCount + 1
                    end
                end
                if #tempTbl > 0 then
                    table.sort( tempTbl, function(a, b)
                        return a > b 
                    end)
                    tempColTbl[#tempColTbl+1] = tempTbl
                end
            end
            
            if #tempColTbl > 0 then
                totalColTbl[#totalColTbl+1] = tempColTbl
            end
        end
    end
    
    return totalColTbl, totalCount
end

function CodeGameScreenMedusaManiaMachine:changeAllWild(_changeLocs, _freeWildPos, _changeWildFunc, endCallFunc)
    local changeLocs = _changeLocs
    local changeWildFunc = _changeWildFunc
    local tblChangeWild = self:getCurReelWildData()

    --第一个是常规的变美杜莎
    if tblChangeWild and #tblChangeWild > 0 then
        local pos = tblChangeWild[1]
        local fixPos = self:getRowAndColByPos(pos)
        local wildCount = fixPos.iX
        local wildRow = fixPos.iX
    
        --把wild下边需要改变的H1信号剔除（数值不好做，客户端处理）
        for kRow=1, wildRow do
            local index = self:getPosReelIdx(kRow, fixPos.iY)
            for k, _pos in pairs(changeLocs) do
                if index == _pos then
                    table.remove(changeLocs, k)
                end
            end
        end
    end

    --free下用渐隐的方式判断
    if self:getCurrSpinMode() == FREE_SPIN_MODE and _freeWildPos then
        local pos = _freeWildPos[1]
        local fixPos = self:getRowAndColByPos(pos)
        local wildCount = fixPos.iX
        local wildRow = fixPos.iX

        --把wild下边需要改变的H1信号剔除（数值不好做，客户端处理）
        for kRow=1, wildRow do
            local index = self:getPosReelIdx(kRow, fixPos.iY)
            for k, _pos in pairs(changeLocs) do
                if index == _pos then
                    table.remove(changeLocs, k)
                end
            end
        end
        self:playFreeChangeWild(_freeWildPos, tblChangeWild, changeLocs, changeWildFunc, endCallFunc)
    else
        self:playBaseChangeWild(tblChangeWild, changeLocs, changeWildFunc, endCallFunc)
    end
end

--free下变身wild（渐现）
function CodeGameScreenMedusaManiaMachine:playFreeChangeWild(_freeWildPos, tblChangeWild, changeLocs, changeWildFunc, endCallFunc)
    local idleframeName = {"idleframe2_1", "idleframe2_2", "idleframe2_3", "idleframe2_4"}

    local textActionName = {"actionframe_1_wenzi", "actionframe_2_wenzi", "actionframe_3_wenzi", "actionframe_4_wenzi"}
    local textIdleName = {"idleframe_1_wenzi", "idleframe_2_wenzi", "idleframe_3_wenzi", "idleframe_4_wenzi"}

    local pos = _freeWildPos[1]
    local fixPos = self:getRowAndColByPos(pos)
    local wildCount = fixPos.iX
    local wildRow = fixPos.iX

    local specialNode = cc.Node:create()

    local bigWild = util_spineCreate("Socre_MedusaMania_Wild_Medusa1_4",true,true)
    self.tblSpecialNode[#self.tblSpecialNode+1] = specialNode

    local bigWildText = util_spineCreate("Socre_MedusaMania_Wild_Medusa_wenzi",true,true)
    local tempTbl = {}
    tempTbl.bigWildText = bigWildText
    tempTbl.m_actionframe = textActionName[wildCount]
    tempTbl.m_idleframe = textIdleName[wildCount]
    tempTbl.p_cloumnIndex = fixPos.iY
    self.tblBigWildTextSpineData[#self.tblBigWildTextSpineData+1] = tempTbl
    bigWildText:setVisible(false)

    --加到最上边的小块上，因为最上边一定是wild，层级最高
    local symbolNode = self:getFixSymbol(fixPos.iY, wildCount, SYMBOL_NODE_TAG)
    local zorder = self:getCurWildZorder(fixPos.iY) + 10
    -- local symbolNode = self:getFixSymbol(fixPos.iY, 1, SYMBOL_NODE_TAG)
    symbolNode:setLocalZOrder(zorder)
    if symbolNode then
        self:changeToMaskLayerSlotNode(symbolNode, true)
        local posY = (wildCount/2-0.5)*self.m_SlotNodeH
        -- local posY = (wildCount*0.5-0.5)*self.m_SlotNodeH
        specialNode:setPosition(cc.p(0, -posY))

        specialNode:setName("bigSpecialWild")
        symbolNode:addChild(specialNode, 100)

        specialNode:addChild(bigWild, 5)
        specialNode:addChild(bigWildText, 10)
    end
    --下边的wild不播actionFrame
    for j=1, self.m_iReelRowNum do
        local node = self:getFixSymbol(fixPos.iY , j, SYMBOL_NODE_TAG)
        if node then
            node:setLineAnimName("idleframe")
            node:setIdleAnimName("idleframe")
        end
    end

    --变身美杜莎
    util_spinePlay(bigWild,"idleframe2_4_start",false)
    util_spinePlay(bigWildText,"actionframe_4_wenzi_start",false)
    bigWildText:setVisible(true)
    util_spineEndCallFunc(bigWild, "idleframe2_4_start", function()
        util_spinePlay(bigWild,idleframeName[wildCount],true)
        util_spinePlay(bigWildText,textIdleName[wildCount],true)
        if type(changeWildFunc) == "function" and self:getCurSkipState() then
            changeWildFunc(tblChangeWild)
        end
        self.m_freeFireSpine:setVisible(false)
    end)

    --free下播放完，再播放常规的
    if tblChangeWild and #tblChangeWild > 0 then
        tblChangeWild[#tblChangeWild+1] = _freeWildPos[1]
        self:playBaseChangeWild(tblChangeWild, changeLocs, nil, endCallFunc)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Wild_Appear)
        tblChangeWild[#tblChangeWild+1] = _freeWildPos[1]

        -- local pos = _freeWildPos[1]
        -- local fixPos = self:getRowAndColByPos(pos)
        -- local wildCount = fixPos.iX
        -- local wildRow = fixPos.iX

        -- --把wild下边需要改变的H1信号剔除（数值不好做，客户端处理）
        -- for kRow=1, wildRow do
        --     local index = self:getPosReelIdx(kRow, fixPos.iY)
        --     for k, _pos in pairs(changeLocs) do
        --         if index == _pos then
        --             table.remove(changeLocs, k)
        --         end
        --     end
        -- end

        --先把动画和数据加上，设置隐藏，跳过功能使用方便
        self:addChangeWildData(tblChangeWild, changeLocs)
        --设置跳过功能
        self:setSkipData(tblChangeWild, changeLocs, endCallFunc, true)   
    end
end

--常规变身wild
function CodeGameScreenMedusaManiaMachine:playBaseChangeWild(tblChangeWild, changeLocs, changeWildFunc, endCallFunc)
    local changeName = {"switch_changtiao1", "switch_changtiao2", "switch_changtiao3", "switch_changtiao4"}
    local strongChangeName = {"switch_changtiao1_qiang", "switch_changtiao2_qiang", "switch_changtiao3_qiang", "switch_changtiao4_qiang"}
    local idleframeName = {"idleframe2_1", "idleframe2_2", "idleframe2_3", "idleframe2_4"}

    local textActionName = {"actionframe_1_wenzi", "actionframe_2_wenzi", "actionframe_3_wenzi", "actionframe_4_wenzi"}
    local textIdleName = {"idleframe_1_wenzi", "idleframe_2_wenzi", "idleframe_3_wenzi", "idleframe_4_wenzi"}

    --第一个是常规的变美杜莎，第二个是free
    local pos = tblChangeWild[1]
    local fixPos = self:getRowAndColByPos(pos)
    local wildCount = fixPos.iX
    local wildRow = fixPos.iX

    -- --把wild下边需要改变的H1信号剔除（数值不好做，客户端处理）
    -- for kRow=1, wildRow do
    --     local index = self:getPosReelIdx(kRow, fixPos.iY)
    --     for k, _pos in pairs(changeLocs) do
    --         if index == _pos then
    --             table.remove(changeLocs, k)
    --         end
    --     end
    -- end
    
    local specialNode = cc.Node:create()

    local bigWild = util_spineCreate("Socre_MedusaMania_Wild_Medusa1_4",true,true)
    self.tblSpecialNode[#self.tblSpecialNode+1] = specialNode

    local bigWildText = util_spineCreate("Socre_MedusaMania_Wild_Medusa_wenzi",true,true)
    local tempTbl = {}
    tempTbl.bigWildText = bigWildText
    tempTbl.m_actionframe = textActionName[wildCount]
    tempTbl.m_idleframe = textIdleName[wildCount]
    tempTbl.p_cloumnIndex = fixPos.iY
    self.tblBigWildTextSpineData[#self.tblBigWildTextSpineData+1] = tempTbl
    bigWildText:setVisible(false)

    --先把动画和数据加上，设置隐藏，跳过功能使用方便
    self:addChangeWildData(tblChangeWild, changeLocs)
    --设置跳过功能
    self:setSkipData(tblChangeWild, changeLocs, endCallFunc, true)

    --加到最上边的小块上，因为最上边一定是wild，层级最高
    local symbolNode = self:getFixSymbol(fixPos.iY, wildCount, SYMBOL_NODE_TAG)
    local zorder = self:getCurWildZorder(fixPos.iY) + 10
    -- local symbolNode = self:getFixSymbol(fixPos.iY, 1, SYMBOL_NODE_TAG)
    symbolNode:setLocalZOrder(zorder)
    if symbolNode then
        self:changeToMaskLayerSlotNode(symbolNode, true)
        local posY = (wildCount/2-0.5)*self.m_SlotNodeH
        -- local posY = (wildCount*0.5-0.5)*self.m_SlotNodeH
        specialNode:setPosition(cc.p(0, -posY))

        specialNode:setName("bigSpecialWild")
        symbolNode:addChild(specialNode, 100)

        specialNode:addChild(bigWild, 5)
        specialNode:addChild(bigWildText, 10)
    end
    --下边的wild不播actionFrame
    for j=1, self.m_iReelRowNum do
        local node = self:getFixSymbol(fixPos.iY , j, SYMBOL_NODE_TAG)
        if node then
            node:setLineAnimName("idleframe")
            node:setIdleAnimName("idleframe")
        end
    end

    local changeActName = strongChangeName[wildCount]
    --先注释，后边可能会用
    -- local changeActName = changeName[wildCount]
    -- if self:getCurBigWildIsStrong(fixPos.iY, changeLocs) then
    --     changeActName = strongChangeName[wildCount]
    -- end

    gLobalSoundManager:playSound(self.m_publicConfig.Music_Wild_Spread)
    --变身美杜莎
    util_spinePlay(bigWild,changeActName,false)
    bigWild:registerSpineEventHandler(
        function(event) --通过registerSpineEventHandler这个方法注册
            if event.animation == changeActName then --根据动作名来区分
                if event.eventData.name == "kuosan" then --根据帧事件来区分
                    if type(changeWildFunc) == "function" and self:getCurSkipState() then
                        changeWildFunc(tblChangeWild)
                    end
                elseif event.eventData.name == "qiehuan" then --根据帧事件来区分
                    util_spinePlay(bigWildText,textIdleName[wildCount],true)
                    bigWildText:setVisible(true)
                end
            end
        end,
        sp.EventType.ANIMATION_EVENT
    )
    util_spineEndCallFunc(bigWild, changeActName, function()
        util_spinePlay(bigWild,idleframeName[wildCount],true)
    end)
end

function CodeGameScreenMedusaManiaMachine:addChangeWildData(tblChangeWild, changeLocs)
    local groupWild, totalCount = self:getColGroup(changeLocs, tblChangeWild)
    local curPlayCount = 0
    local delayTime = 0
    if groupWild and #groupWild > 0 then
        for k,curGroup in pairs(groupWild) do
            local isLast = k == #groupWild and true or false
            for count,curColData in pairs(curGroup) do
                local curCount = #curColData
                local colData = curColData
                local pos = tonumber(curColData[1])
                local fixPos = self:getRowAndColByPos(pos)
                local bottomNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if bottomNode then
                    self:changeToMaskLayerSlotNode(bottomNode, true, true)
                    local topWildNode = self:createMedusaManiaSymbol(self.SYMBOL_SCORE_102)
                    topWildNode:setName("smallWild")
                    bottomNode:addChild(topWildNode, 100)
                    local posY = (curCount/2-0.5)*self.m_SlotNodeH
                    topWildNode:setPosition(cc.p(0, posY))
                    topWildNode:setVisible(false)

                    --wild字体下边的整个Wild小块
                    local curCol = bottomNode.p_cloumnIndex
                    self.tblWildSpine[curCol] = topWildNode


                    local wildBigTextSpine = util_spineCreate("Socre_MedusaMania_wenzi_wenzi",true,true)
                    local clipTarPos = util_getOneGameReelsTarSpPos(self, pos)
                    local posY = (curCount/2-0.5)*self.m_SlotNodeH
                    clipTarPos.y = clipTarPos.y+posY
                    wildBigTextSpine:setPosition(clipTarPos)
                    local zorder = 10-curCol
                    self.m_clipParent:addChild(wildBigTextSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER-zorder)
                    wildBigTextSpine:setVisible(false)

                    --大wild字体
                    self.tblWildBigTextSpine[curCol] = wildBigTextSpine
                end

                for i = 1, #curColData do
                    local pos = tonumber(curColData[i])
                    local fixPos = self:getRowAndColByPos(pos) 
                    local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                    if symbolNode then
                        symbolNode:setLineAnimName("idleframe")
                        symbolNode:setIdleAnimName("idleframe")
                    end
                end
            end
        end
    end
end

--获取当前美杜莎两边是否有变身的H1（有的话需要用强的美杜莎变身）
function CodeGameScreenMedusaManiaMachine:getCurBigWildIsStrong(_col, changeLocs)
    local lastCol = _col - 1
    local nextCol = _col + 1
    --获取上一列是否有H1
    if lastCol >= 1 and lastCol <= 5 then
        for i=1, #changeLocs do
            local pos = changeLocs[i]
            local fixPos = self:getRowAndColByPos(pos)
            if fixPos.iY == lastCol then
                return true
            end
        end
    end

    --获取下一列是否有H1
    if nextCol >= 1 and nextCol <= 5 then
        for i=1, #changeLocs do
            local pos = changeLocs[i]
            local fixPos = self:getRowAndColByPos(pos)
            if fixPos.iY == nextCol then
                return true
            end
        end
    end

    return false
end

--获取轮盘上的wild数据
function CodeGameScreenMedusaManiaMachine:getCurReelWildData()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local tblChangeWild = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if self:getCurrSpinMode() == FREE_SPIN_MODE and selfData and selfData.free_wild_position then
                local fixPos = self:getRowAndColByPos(selfData.free_wild_position[1])
                if slotNode and slotNode.p_cloumnIndex ~= fixPos.iY and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    local index = self:getPosReelIdx(iRow, iCol)
                    tblChangeWild[#tblChangeWild+1] = index
                end
            else
                if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    local index = self:getPosReelIdx(iRow, iCol)
                    tblChangeWild[#tblChangeWild+1] = index
                end
            end
        end
    end
    return tblChangeWild
end

--获取一列中小块层级最高的那个zorder
function CodeGameScreenMedusaManiaMachine:getCurWildZorder(_col)
    local curCol = _col
    local tblZorderList = {}
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(curCol, iRow, SYMBOL_NODE_TAG)
        local zorder = targSp:getLocalZOrder()
        tblZorderList[#tblZorderList+1] = zorder
    end

    table.sort(tblZorderList, function(a, b)
        return a > b
    end)
    return tblZorderList[1]
end

--[[
    @desc: 
    author:{author}
    time:2022-09-28 14:21:47
    美杜莎跳过
]]
--美杜莎变身和H1变身直接变成idle
function CodeGameScreenMedusaManiaMachine:skipShowChangeWild(changeLocs, tblChangeWild)
    --h1-变wild
    local groupWild, totalCount = self:getColGroup(changeLocs, tblChangeWild)
    local idleframeName = {"idleframe2_1", "idleframe2_2", "idleframe2_3", "idleframe2_4"}
    local curPlayCount = 0
    local delayTime = 0
    if groupWild and #groupWild > 0 then
        for k,curGroup in pairs(groupWild) do
            local isLast = k == #groupWild and true or false
            for count,curColData in pairs(curGroup) do
                local curCount = #curColData
                local colData = curColData
                local pos = tonumber(curColData[1])
                local fixPos = self:getRowAndColByPos(pos)
                local bottomNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if bottomNode then
                    -- self:changeToMaskLayerSlotNode(bottomNode, true, true)
                    local curCol = bottomNode.p_cloumnIndex
                    local topWildNode = self.tblWildSpine[curCol]
                    topWildNode:setVisible(true)
                    curPlayCount = curPlayCount + curCount
                    topWildNode:runAnim(idleframeName[curCount], true)

                    local wildBigTextSpine = self.tblWildBigTextSpine[curCol]
                    wildBigTextSpine:setVisible(false)

                    for i = 1, #colData do
                        local wildTextSpine = self.tblWildTextSpineData[colData[i]+1].wildTextSpine
                        util_spinePlay(wildTextSpine,"idleframe2_1_wenzi",true)
                        wildTextSpine:setVisible(true)
                    end
                end
            end
        end
    end
end

function CodeGameScreenMedusaManiaMachine:playCollectScatter(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local collectLocs = selfData.sc_position
    local collectLevel = selfData.scatterlevel
    local delayTime = 15/30

    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
            effectData = nil
        end
    end

    for k,v in pairs(collectLocs) do
        local isLast = k == #collectLocs and true or false
        local pos = tonumber(v)
        local clipTarPos = util_getOneGameReelsTarSpPos(self, pos)
        local startPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
        local endPos = util_convertToNodeSpace(self:findChild("Node_pen"), self)

        local flyNode = util_spineCreate("Socre_MedusaMania_Scatter",true,true)
        flyNode:setPosition(startPos.x, startPos.y)
        self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)

        if isLast then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_Collect)
        end

        util_spinePlay(flyNode, "shouji", false)
        --收集不打断spin
        local lastClooectLevel = self.m_curCollectLevel
        local duoFuDuoCai = self.isDuoFuDuoCai
        local isTriggerFG = self:isTriggerFreeGame()
        if isLast and not duoFuDuoCai and not isTriggerFG then
            self.m_curCollectLevel = collectLevel
            endCallFunc()
        end

        util_playMoveToAction(flyNode, delayTime, endPos,function()
            flyNode:removeFromParent()
            if isLast then
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_FeedBack)
                local shoujiDelayTime = 20/30
                local collectName = "shouji"..lastClooectLevel
                util_spinePlay(self.m_fuCaiSpine, collectName, false)
                performWithDelay(self.m_scWaitNode, function()
                    if duoFuDuoCai then
                        local changeName = nil
                        local delayTime = 0
                        --1变3
                        if lastClooectLevel == 1 then
                            delayTime = 25/30
                            changeName = "switch3"
                        --2变3
                        elseif lastClooectLevel == 2 then
                            delayTime = 25/30
                            changeName = "switch2"
                        --3档不变
                        elseif lastClooectLevel == 3 then
                            delayTime = 0
                        end
                        if changeName then
                            gLobalSoundManager:playSound(self.m_publicConfig.Music_Top_AddCoins)
                            util_spinePlay(self.m_fuCaiSpine, changeName, false)
                        end
                        performWithDelay(self.m_scWaitCollectNode, function()
                            self.m_curCollectLevel = 3
                            self:refreshTopMiddleCoins()
                            if type(endCallFunc) == "function" then
                                endCallFunc()
                            end
                        end, delayTime)
                    else
                        if lastClooectLevel == collectLevel then
                            self:refreshTopMiddleCoins()
                            if isTriggerFG then
                                endCallFunc()
                            end
                        elseif collectLevel > lastClooectLevel then
                            local changeName = nil
                            local delayTime = 25/30
                            --1变2; 2变3
                            if lastClooectLevel == 1 then
                                if collectLevel == 2 then
                                    changeName = "switch1"
                                else
                                    changeName = "switch3"
                                end
                            --2变3
                            elseif lastClooectLevel == 2 and collectLevel == 3 then
                                changeName = "switch2"
                            end
                            if changeName then
                                gLobalSoundManager:playSound(self.m_publicConfig.Music_Top_AddCoins)
                                util_spinePlay(self.m_fuCaiSpine, changeName, false)
                            end
                            performWithDelay(self.m_scWaitCollectNode, function()
                                -- self.m_curCollectLevel = collectLevel
                                self:refreshTopMiddleCoins()
                                if isTriggerFG then
                                    endCallFunc()
                                end
                            end, delayTime)
                        end
                    end
                end, shoujiDelayTime)
            end
        end)
    end
end

function CodeGameScreenMedusaManiaMachine:shakeRootNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i = 1,10 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)
end

-- shake
function CodeGameScreenMedusaManiaMachine:shakeOneNodeForeverRootNode(time)
    
    self.m_gobalTouchLayer:setTouchEnabled(true)
    self.m_gobalTouchLayer:setSwallowTouches(true)

    local time2 = 0.07
    local time1 = math.max(0, time - time2)

    local root_shake = self
    local root_scale = self:getParent()

    local oldPos = cc.p(root_shake:getPosition())
    local oldRootPos = cc.p(root_scale:getPosition())
    local oldScale = root_scale:getScale()
    local changePosY = math.random( 1, 3)
    local changePosX = math.random( 1, 3)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    root_shake:runAction(action)

    local action1 = cc.ScaleTo:create(time1, 1.15)
    root_scale:runAction(action1)

    performWithDelay(self.m_scWaitNode,function()
        root_shake:stopAction(action)
        root_scale:stopAction(action1)
        root_shake:setPosition(oldPos)
        root_scale:setPosition(oldRootPos)
        
        local actionOver = cc.ScaleTo:create(time2, oldScale)
        root_scale:runAction(actionOver)
        performWithDelay(self,function()
            root_scale:stopAction(actionOver)
            root_scale:setScale(oldScale)
            if self.m_gobalTouchLayer then
                self.m_gobalTouchLayer:setTouchEnabled(false)
                self.m_gobalTouchLayer:setSwallowTouches(false)
            end
        end, time2)
    end, time1)
end


function CodeGameScreenMedusaManiaMachine:isTriggerFreeGame()
    local featureDatas = self.m_runSpinResultData.p_features or {}

    if featureDatas and (featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureDatas[2] == SLOTO_FEATURE.FEATURE_FREESPIN) then
        return true
    end
    return false
end

function CodeGameScreenMedusaManiaMachine:playJackpotPlay(effectData)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "pickFeature")
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins

    local collectLevel = selfData.scatterlevel
    self.m_curCollectLevel = collectLevel

    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
            effectData = nil
        end
    end

    self.m_fuCaiCutScene:setVisible(true)
    self.m_fuCaiSpine:setVisible(false)
    util_spinePlay(self.m_fuCaiCutScene, "actionframe", false)
    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Jackpot, 3, 0, 1)
    self.m_guoChangSpine:setVisible(true)
    util_spinePlay(self.m_guoChangSpine, "actionframe_guochang4", false)
    util_spineFrameEvent(self.m_guoChangSpine , "actionframe_guochang4","switch",function ()
        self:resetMusicBg(nil, self.m_publicConfig.Music_Jackpot_Bg)
        self:setMaxMusicBGVolume( )
        self.m_bottomUI:updateWinCount("")
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Jackpot_CutScene)
        self.m_fuCaiCutScene:setVisible(false)
        self.m_ReelNode:setVisible(false)
        self.m_jackpotView:setVisible(true)
        self.m_jackpotView:refreshData(selfData, endCallFunc)
    end)
    util_spineEndCallFunc(self.m_guoChangSpine, "actionframe_guochang4", function()
        self.m_guoChangSpine:setVisible(false)
        self.m_fuCaiSpine:setVisible(false)
    end)
    -- util_spineFrameEvent(self.m_fuCaiCutScene , "actionframe","guochang_start",function ()
        
    -- end)
end

function CodeGameScreenMedusaManiaMachine:setBaseIdle()
    self:runCsbAction("idle", true)
end

--判断当前是否为free最后一次spin
function CodeGameScreenMedusaManiaMachine:getCurIsFreeGameLastSpin()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        return true
    end
    return false
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenMedusaManiaMachine:checkFeatureOverTriggerBigWin(winAmonut, feature, isCurentLase)
    if winAmonut == nil then
        return
    end

    if isCurentLase and self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i = 1, #self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert(self.m_gameEffects, i + 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, i + 2, effectData)
                break
            end
        end
        if isAddEffect == false then
            for i = 1, #self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut

                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert(self.m_gameEffects, i + 1, delayEffect)

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert(self.m_gameEffects, i + 2, effectData)
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert(self.m_gameEffects, 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, 2, effectData)
            end
        end
    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()

    if feature == GameEffect.EFFECT_BONUS then
        self:addRewaedFreeSpinStartEffect()
        self:addRewaedFreeSpinOverEffect()
    end
end

function CodeGameScreenMedusaManiaMachine:jackpotGameOver(endCallFunc, runEndFunc)
    if not self:checkHasBigWin() then
        --检测大赢
        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS, true)
    end
    self.m_fuCaiSpine:setVisible(true)
    self:refreshTopMiddleCoins()
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Jackpot_BackBgCutScene)

    self.m_gameBg:runCsbAction("animation", false)
    self.m_guoChangSpine_2:setVisible(true)
    util_spinePlay(self.m_guoChangSpine_2, "actionframe_guochang3", false)
    gLobalSoundManager:fadeOutBgMusic(1.0)
    util_spineFrameEvent(self.m_guoChangSpine_2 , "actionframe_guochang3","switch",function ()
        self.m_ReelNode:setVisible(true)
        self:resetMusicBg()
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:changeBgSpine(2)
        else
            self:changeBgSpine(1)
        end
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end)
    util_spineEndCallFunc(self.m_guoChangSpine_2, "actionframe_guochang3", function()
        self.m_guoChangSpine_2:setVisible(false)
        if type(runEndFunc) == "function" then
            self:updateBottomEndCoins()
            runEndFunc()
        end
    end)
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenMedusaManiaMachine:checkHasGameEffect(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType and not self.m_gameEffects[i].p_isPlay then
            return true
        end
    end

    return false
end

function CodeGameScreenMedusaManiaMachine:createMedusaManiaSymbol(_symbolType)
    local symbol = util_createView("CodeMedusaManiaSrc.MedusaManiaSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenMedusaManiaMachine:addPlayEffect()
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if not featureDatas then
        return
    end

    for i = 1, #featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end

function CodeGameScreenMedusaManiaMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenMedusaManiaMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

---
-- 点击快速停止reel
--
function CodeGameScreenMedusaManiaMachine:newQuickStopReel(colIndex)
    self.m_curSpinIsQuickStop = true
    self.triggerWildDelayTime = 10/30
    --快停后检查是否有拖尾，有的话直接删除
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                slotNode:removeTuowei()
            end
        end
    end
    self:removeSlotNodeParticle()
    CodeGameScreenMedusaManiaMachine.super.newQuickStopReel(self, colIndex)
end

--清除拖尾
function CodeGameScreenMedusaManiaMachine:removeSlotNodeParticle()
    for i = 1, #self.m_falseParticleTbl do
        local particleNode = self.m_falseParticleTbl[i]
        if not tolua.isnull(particleNode) then
            particleNode:stopAllActions()
            particleNode:removeFromParent()
            self.m_falseParticleTbl[i] = nil
        end
    end
end

function CodeGameScreenMedusaManiaMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    if self.isHaveLongRun then
        for reelCol=1, self.m_iReelColumnNum-1 do
            self:playMaskFadeAction(false, 0.2, reelCol, function()
                self:changeMaskVisible(false, reelCol)
            end)
        end
    end

    CodeGameScreenMedusaManiaMachine.super.slotReelDown(self)
    self.m_panel_clipeNode:setClippingEnabled(false)
end

function CodeGameScreenMedusaManiaMachine:updateReelGridNode(_symbolNode)

    --scatter停轮后用spine
    if _symbolNode.m_isLastSymbol and _symbolNode.p_symbolType and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        _symbolNode:setIdleAnimName("idleframe2")
        _symbolNode:runAnim("idleframe2", true)
    end

    --H1信号停轮后设置连线和idle状态
    if _symbolNode.m_isLastSymbol and _symbolNode.p_symbolType and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        _symbolNode:setLineAnimName("actionframe")
        _symbolNode:setIdleAnimName("idleframe")
    end

    --wild在滚动过程中用金边拖尾
    if _symbolNode and _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        _symbolNode:setIdleAnimName("idleframe")
        _symbolNode:runAnim("idleframe", true)
        _symbolNode:addTuoweiParticle(self.m_slotParents[_symbolNode.p_cloumnIndex].slotParent, self.m_falseParticleTbl)
    end

    --修正层级
    if _symbolNode.p_symbolType then
        local showOrder = self:getBounsScatterDataZorder(_symbolNode.p_symbolType)
        _symbolNode.m_showOrder = showOrder
        _symbolNode:setLocalZOrder(showOrder)
    end

    self:removeSymbolCollectIcon(_symbolNode)
end

function CodeGameScreenMedusaManiaMachine:removeSymbolCollectIcon(_symbolNode)
    local smallWild = _symbolNode:getChildByName("smallWild")
    local bigSpecialWild = _symbolNode:getChildByName("bigSpecialWild")
    local initWildImg = _symbolNode:getChildByName("initWildImg")
    
    if smallWild then
        smallWild:removeFromParent()
    end
    if bigSpecialWild then
        bigSpecialWild:removeFromParent()
    end

    if initWildImg then
        initWildImg:removeFromParent()
    end
end

function CodeGameScreenMedusaManiaMachine:changeBgSpine(_bgType)
    -- 1.base；2.freespin
    for i=1, 2 do
        if i == _bgType then
            self.m_tblGameBg[i]:setVisible(true)
        else
            self.m_tblGameBg[i]:setVisible(false)
        end
    end
    self:setReelBgState(_bgType)
end

function CodeGameScreenMedusaManiaMachine:setReelBgState(_bgType)
    if _bgType == 1 then
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(false)
    else
        self:findChild("Node_free_reel"):setVisible(true)
        self:findChild("Node_base_reel"):setVisible(false)
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenMedusaManiaMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            self:setSpecialSpineLine(slotsNode)
            slotsNode:runLineAnim()
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

function CodeGameScreenMedusaManiaMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    self:setSpecialSpineLine(slotsNode)
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

--判断当前小块是否在连线上
function CodeGameScreenMedusaManiaMachine:curSymbolIsLine(_row, _col)
    local nodePos = self:getPosReelIdx(_row, _col)
    local linePos = self.m_runSpinResultData.p_winLines
    for k, v in pairs(linePos) do
        local iconPos = v.p_iconPos
        if iconPos then
            for i=1, #iconPos do
                if nodePos == iconPos[i] then
                    return true
                end
            end
        end
    end
    return false
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenMedusaManiaMachine:changeToMaskLayerSlotNode(slotNode, isTop, isAddZorder)
    if isTop then
        if self:curSymbolIsLine(slotNode.p_rowIndex, slotNode.p_cloumnIndex) then
            self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
        end
    else
        self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
    end

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = self:getClipParentChildShowOrder(slotNode)
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    local curZorder = slotNode.p_showOrder
    if isTop then
        curZorder = slotNode.p_showOrder + slotNode.p_rowIndex--+ REEL_SYMBOL_ORDER.REEL_ORDER_2
        if isAddZorder then
            --curZorder = curZorder + REEL_SYMBOL_ORDER.REEL_ORDER_2
        end
    end
    -- 切换图层
    -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
    util_changeNodeParent(self.m_clipParent, slotNode, self:getMaskLayerSlotNodeZorder(slotNode) + curZorder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end
    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

function CodeGameScreenMedusaManiaMachine:checkNotifyUpdateWinCoin(_winAmount)
    local winLines = self.m_reelResultLines

    -- if #winLines <= 0 then
    --     return
    -- end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if _winAmount then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {_winAmount, isNotifyUpdateTop})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

function CodeGameScreenMedusaManiaMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local lineFsWinAmount = self.m_runSpinResultData.p_fsWinCoins
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.jackpot and selfData.jackpot.winValue then
            local jackpotCoins = selfData.jackpot.winValue
            if self.isDuoFuDuoCai and jackpotCoins then
                lineFsWinAmount = lineFsWinAmount - jackpotCoins
            end
        end

        self:setLastWinCoin(lineFsWinAmount)

        local bottomWinCoin = self:getCurBottomWinCoins()
        local addCoins = lineFsWinAmount
        if bottomWinCoin and bottomWinCoin > 0 then
            addCoins = addCoins - bottomWinCoin
        end
        self:checkNotifyUpdateWinCoin(addCoins)
    else
        local lineWinAmount = self.m_runSpinResultData.p_winAmount
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.jackpot and selfData.jackpot.winValue then
            local jackpotCoins = selfData.jackpot.winValue
            if self.isDuoFuDuoCai and jackpotCoins then
                lineWinAmount = lineWinAmount - jackpotCoins
            end
        end
        self.m_bottomUI:updateWinCount("")
        self:setLastWinCoin(lineWinAmount)
        self:checkNotifyUpdateWinCoin(lineWinAmount)
    end

    -- self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                if frameIndex > #winLines then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                        self:showAllFrame(winLines)
                        self:playInLineNodes()
                        showLienFrameByIndex()
                    end
                    return
                end
                self:playInLineNodesIdle()
                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end
                    -- print("showLine ... ")
                    local lineData = winLines[frameIndex]

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- end
        self:showAllFrame(winLines) -- 播放全部线框

        -- if #winLines > 1 then
        showLienFrameByIndex()
    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end

        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines, 1)
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenMedusaManiaMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            self:setSpecialSpineIdle(slotsNode)
            slotsNode:runIdleAnim()
        end
    end
end

--播放连线动画判断变身后的wild、bigwild、wild字体是否需要播放
function CodeGameScreenMedusaManiaMachine:setSpecialSpineLine(_slotsNode)
    local curRow = _slotsNode.p_rowIndex
    local curCol = _slotsNode.p_cloumnIndex
    --变身后的wild播放连线
    for i=1, #self.tblWildTextSpineData do
        local wildTextSpine = self.tblWildTextSpineData[i].wildTextSpine
        local m_actionframe = self.tblWildTextSpineData[i].m_actionframe
        if not tolua.isnull(wildTextSpine) and not self.tblWildTextSpineData[i].curPlayLine and curRow == self.tblWildTextSpineData[i].p_rowIndex and curCol == self.tblWildTextSpineData[i].p_cloumnIndex then
            -- wildTextSpine:runAnim(m_actionframe, true)
            util_spinePlay(wildTextSpine,m_actionframe,true)
            self.tblWildTextSpineData[i].curPlayLine = true
        end
    end

    --变身后wild字体播放连线(bigwild)
    for i=1, #self.tblBigWildTextSpineData do
        local bigWildText = self.tblBigWildTextSpineData[i].bigWildText
        local m_actionframe = self.tblBigWildTextSpineData[i].m_actionframe
        if not tolua.isnull(bigWildText) and not self.tblBigWildTextSpineData[i].curPlayLine and curCol == self.tblBigWildTextSpineData[i].p_cloumnIndex then
            util_spinePlay(bigWildText, m_actionframe, true)
            self.tblBigWildTextSpineData[i].curPlayLine = true
        end
    end
end

--播放连线动画后播放idle判断变身后的wild、bigwild、wild字体是否需要播放
function CodeGameScreenMedusaManiaMachine:setSpecialSpineIdle(_slotsNode)
    local curRow = _slotsNode.p_rowIndex
    local curCol = _slotsNode.p_cloumnIndex
    --变身后的wild播放连线
    for i=1, #self.tblWildTextSpineData do
        local wildTextSpine = self.tblWildTextSpineData[i].wildTextSpine
        local m_idleframe = self.tblWildTextSpineData[i].m_idleframe
        if not tolua.isnull(wildTextSpine) and self.tblWildTextSpineData[i].curPlayLine and curRow == self.tblWildTextSpineData[i].p_rowIndex and curCol == self.tblWildTextSpineData[i].p_cloumnIndex then
            -- wildTextSpine:runAnim(m_idleframe, true)
            util_spinePlay(wildTextSpine,m_idleframe,true)
            self.tblWildTextSpineData[i].curPlayLine = false
        end
    end

    --变身后wild字体播放连线
    for i=1, #self.tblBigWildTextSpineData do
        local bigWildText = self.tblBigWildTextSpineData[i].bigWildText
        local m_idleframe = self.tblBigWildTextSpineData[i].m_idleframe
        if not tolua.isnull(bigWildText) and self.tblBigWildTextSpineData[i].curPlayLine and curCol == self.tblBigWildTextSpineData[i].p_cloumnIndex then
            util_spinePlay(bigWildText, m_idleframe, true)
            self.tblBigWildTextSpineData[i].curPlayLine = false
        end
    end
end

function CodeGameScreenMedusaManiaMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

--设置callFunc，在点击的时候跳过移除
function CodeGameScreenMedusaManiaMachine:setSkipData(tblChangeWild, changeLocs, endCallFunc, _state)
    self.m_tblChangeWild = tblChangeWild
    self.m_changeLocs = changeLocs
    self.m_skipFunc = endCallFunc
    self.m_skip_click:setVisible(_state)
    self.m_bottomUI:setSkipBtnVisible(_state)
end

function CodeGameScreenMedusaManiaMachine:runSkipWild()
    self.m_skip_click:setVisible(false)
    if type(self.m_skipFunc) == "function" then
        self.m_scWaitWildNode:stopAllActions()
        for i=1, self.m_iReelColumnNum do
            local topWildNode = self.tblWildSpine[i]
            if not tolua.isnull(topWildNode) then
                topWildNode:stopAllActions()
            end

            local wildBigTextSpine = self.tblWildBigTextSpine[i]
            if not tolua.isnull(wildBigTextSpine) then
                wildBigTextSpine:stopAllActions()
            end
        end
        self:skipShowChangeWild(self.m_changeLocs, self.m_tblChangeWild)
        self.m_bottomUI:setSkipBtnVisible(false)
        self.m_skipFunc()
        self.m_skipFunc = nil
        self.m_changeLocs = nil
        self.m_tblChangeWild = nil
        self:setSkipData(nil, nil, nil, false)
    end
end

function CodeGameScreenMedusaManiaMachine:getCurSkipState()
    return self.m_skip_click:isVisible()
end

--多福多彩出来后更新总钱
function CodeGameScreenMedusaManiaMachine:updateBottomEndCoins()
    local endCoins = 0
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
        endCoins = self.m_runSpinResultData.p_fsWinCoins
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
        endCoins = self.m_runSpinResultData.p_winAmount
    end
    local bottomWinCoin = self:getCurBottomWinCoins()
    local addWinCoin = endCoins - bottomWinCoin
    self:checkNotifyUpdateWinCoin(addWinCoin)
end

function CodeGameScreenMedusaManiaMachine:playhBottomLight(_endCoins, _endCallFunc)
    
    self.m_bottomUI:playCoinWinEffectUI(_endCallFunc)

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    self:setLastWinCoin(0)
    self:updateBottomUICoins(bottomWinCoin, _endCoins)
end

--BottomUI接口
function CodeGameScreenMedusaManiaMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenMedusaManiaMachine:getCurBottomWinCoins()
    local winCoin = 0
    local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == sCoins then
        return winCoin
    end
    if nil == self.m_bottomUI.m_updateCoinHandlerID then
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
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenMedusaManiaMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            end
        end
    end
end

function CodeGameScreenMedusaManiaMachine:checkSymbolBulingAnimPlay(_slotNode)
    if not self.m_curSpinIsQuickStop and _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD and _slotNode.p_cloumnIndex == self.m_iReelColumnNum then
        self.triggerWildDelayTime = 15/30
    end

    -- 和音效保持一致
    return self:checkSymbolBulingSoundPlay(_slotNode)
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenMedusaManiaMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                -- if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                -- end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenMedusaManiaMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_freeSelectType, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    --改变假滚索引值(关卡需求)
    local m_colState = self.tblCurColTopSymbolData[parentData.cloumnIndex].m_state
    if m_colState then
        local colSymbolCount = self.tblCurColTopSymbolData[parentData.cloumnIndex].m_count
        if colSymbolCount > 0 then
            local curColData = nil
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                local curFreeType = self.m_freeSelectType
                if not curFreeType then
                    curFreeType = 1
                end
                curColData = self.tblFreeColRandomStartIndex[curFreeType][parentData.cloumnIndex]
            else
                curColData = self.tblBaseColRandomStartIndex[parentData.cloumnIndex]
            end
            local randomIndex = util_random(1, #curColData[colSymbolCount])
            parentData.beginReelIndex = curColData[colSymbolCount][randomIndex]
            self.tblCurColTopSymbolData[parentData.cloumnIndex].m_state = false
        else
            if reelDatas[parentData.beginReelIndex] == TAG_SYMBOL_TYPE.SYMBOL_WILD or reelDatas[parentData.beginReelIndex] == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                parentData.beginReelIndex = 1
                self.tblCurColTopSymbolData[parentData.cloumnIndex].m_state = false
            end
        end
    end

    return reelDatas
end

--随机信号
function CodeGameScreenMedusaManiaMachine:getReelSymbolType(parentData)
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    if not self.m_isWaitingNetworkData then
        --改变假滚索引值(关卡需求)
        local m_colState = self.tblCurColBottomData[parentData.cloumnIndex].m_state
        if m_colState then
            local colSymbolCount = self.tblCurColBottomData[parentData.cloumnIndex].m_count
            if colSymbolCount > 0 then
                local curColData = nil
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    local curFreeType = self.m_freeSelectType
                    if not curFreeType then
                        curFreeType = 1
                    end
                    curColData = self.tblFreeColRandomEndIndex[curFreeType][parentData.cloumnIndex]
                else
                    curColData = self.tblBaseColRandomEndIndex[parentData.cloumnIndex]
                end
                local randomIndex = util_random(1, #curColData[colSymbolCount])
                parentData.beginReelIndex = curColData[colSymbolCount][randomIndex]
                self.tblCurColBottomData[parentData.cloumnIndex].m_state = false
            else
                if parentData.reelDatas[parentData.beginReelIndex] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    parentData.beginReelIndex = 1
                end
                -- local curColData = nil
                -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
                --     curColData = self.tblFreeColRandomEndIndex[parentData.cloumnIndex]
                -- else
                --     curColData = self.tblBaseColRandomStartIndex[parentData.cloumnIndex]
                -- end
                -- local randomCount = util_random(1, 3)
                -- local randomIndex = util_random(1, #curColData[1])
                -- parentData.beginReelIndex = curColData[randomCount][randomIndex]-parentData.cloumnIndex
                self.tblCurColBottomData[parentData.cloumnIndex].m_state = false
            end
        end
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    return symbolType
end

function CodeGameScreenMedusaManiaMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenMedusaManiaMachine:symbolBulingEndCallBack(node)
    if node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        node:runAnim("idleframe2", true)
    elseif node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        node:runAnim("idleframe", true)
    end
end

function CodeGameScreenMedusaManiaMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenMedusaManiaMachine:playScatterTipMusicEffect(_isFreeMore)
    if _isFreeMore then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_FreeGame_TriggerFree)
    else
        if self.m_ScatterTipMusicPath ~= nil then
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        end
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenMedusaManiaMachine:showBigWinLight(_func)
    local lightSpine = util_spineCreate("MedusaMania_bigwin",true,true)
    local lightAni = util_createAnimation("MedusaMania_bigwin.csb")

    local particleTbl = {}
    for i=1, 4 do
        particleTbl[i] = lightAni:findChild("Particle_"..i)
        particleTbl[i]:resetSystem()
    end

    self:findChild("Node_bigWin"):addChild(lightSpine)
    self:findChild("Node_bigWin"):addChild(lightAni)
    util_spinePlay(lightSpine, "actionframe", false)
    util_spineEndCallFunc(lightSpine, "actionframe", function()
        for i=1, 4 do
            particleTbl[i]:stopSystem()
        end
        -- lightAni:setVisible(false)
        lightSpine:setVisible(false)
        if type(_func) == "function" then
            _func()
        end
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Celebrate_Win)
    performWithDelay(self.m_scWaitNode, function()
        lightAni:removeFromParent()
        lightSpine:removeFromParent()
    end, 80/30)
    self:shakeRootNode()
end

return CodeGameScreenMedusaManiaMachine






