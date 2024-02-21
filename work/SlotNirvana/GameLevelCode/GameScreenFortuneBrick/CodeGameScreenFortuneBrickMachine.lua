---
-- island li
-- 2019年1月26日
-- CodeGameScreenFortuneBrickMachine.lua
-- 
-- 玩法：
-- 

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenFortuneBrickMachine = class("CodeGameScreenFortuneBrickMachine", BaseSlotoManiaMachine)

CodeGameScreenFortuneBrickMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFortuneBrickMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenFortuneBrickMachine.BLUE_BONUS_SYMBOL_TYPE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

CodeGameScreenFortuneBrickMachine.CHANGE_BONUS_REEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3
CodeGameScreenFortuneBrickMachine.CHANGE_BONUS_REEL_FOR_WIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4

CodeGameScreenFortuneBrickMachine.m_winSoundsId = nil

CodeGameScreenFortuneBrickMachine.m_bonusReels = nil -- 本地bonus轮盘数据
CodeGameScreenFortuneBrickMachine.m_bonusReelsScoreBet = nil -- 本地bonus轮盘数据
CodeGameScreenFortuneBrickMachine.m_bonusReelsMap = nil -- 本地bonus轮盘数据
CodeGameScreenFortuneBrickMachine.m_bonusReelsData = nil -- 本地bonus轮盘数据每轮


-- 构造函数
function CodeGameScreenFortuneBrickMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_bonusReels = {}
    self.m_winSoundsId = nil
    self.m_BonusSoundsId = nil
    self.bonusScore = 0
    self.isInBonus = false
    self.m_bonusReelsData = {}
    self.m_isReconnection = false--是否是重连轮
    self.m_isSuperFree = false--是否是superfrees
    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end
function CodeGameScreenFortuneBrickMachine:initGame()
    -- bonus轮盘倍数表
    self.m_bonusReelsScoreBet = {5000,2500,2000,1500,1000,750,500,400,300,250,200,150,125,100}
    self.m_bonusReelsMap = {}
    --设置音效
	--初始化基本数据
	self:initMachine(self.m_moduleName)
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenFortuneBrickMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "FortuneBrickSounds/music_FortuneBrick_scatter_down.mp3"

        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
--适配
function CodeGameScreenFortuneBrickMachine:scaleMainLayer()
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
        local bottomMoveH = 30--底部空间尺寸，最后要下移距离
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

function CodeGameScreenFortuneBrickMachine:initUI()
    self.m_gameBg:setPositionY(self.m_machineNode:getPositionY())
    self.m_gameBg:findChild("root"):setScale(self.m_machineRootScale)

    self.m_wonBonusWinScoreView = util_createView("CodeFortuneBrickSrc.FortuneBrickBonusWinView")
    self:findChild("TOP"):addChild(self.m_wonBonusWinScoreView)

    self.m_wonBonusTimes = util_createView("CodeFortuneBrickSrc.FortuneBrickTimsBar")
    self:findChild("FreeSpin"):addChild(self.m_wonBonusTimes)
    -- util_setCsbVisible(self.m_wonBonusTimes,false)
    self:initFreeSpinBar()
    self.m_wonBonusTimes:runCsbAction("idle2")
    self.m_wonBonusTimes:setVisible(false)
   
    --添加轮盘遮罩
    self.m_reelMask = util_createAnimation("FortuneBrick_zhezhao.csb")
    self.m_clipParent:addChild(self.m_reelMask,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE)
    self.m_reelMask:setPositionY(175)

    self.m_RunDi = {}
    for i=1,5 do
        local longRunDi =  util_createAnimation("Socre_FortuneBrick_ReelRun_0.csb") 
        self.m_clipParent:addChild(longRunDi,1)
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_"..(i - 1)):getPosition()))
        table.insert( self.m_RunDi, longRunDi )
        longRunDi:setVisible(false)
    end

    --添加收集条
    self.m_collectBar = util_createAnimation("Socre_FortuneBrick_jindutiao.csb")
    self:findChild("FreeSpin"):addChild(self.m_collectBar)
    -- self.m_collectBar:playAction("shoujisaoguang",true)
    self.m_collectSymbolTab = {}
    for i = 1,5 do
        local collectSymbol = util_createAnimation("Socre_FortuneBrick_jindutiao_item.csb")
        self.m_collectBar:findChild("item_"..i):addChild(collectSymbol)
        table.insert(self.m_collectSymbolTab,collectSymbol)
        collectSymbol:setVisible(false)
    end
end

---
-- 初始化轮盘界面, 已进入游戏时初始化
--
function CodeGameScreenFortuneBrickMachine:initMachineGame()
    self.m_bonusReels = self.m_runSpinResultData["p_bonusReels"]
    self:initBoonusReels()
end

-- 断线重连 
function CodeGameScreenFortuneBrickMachine:MachineRule_initGame()
    self.m_isReconnection = true
end

--新滚动使用
function CodeGameScreenFortuneBrickMachine:updateReelGridNode(symblNode)
    if symblNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symblNode.p_symbolType == self.BLUE_BONUS_SYMBOL_TYPE then
        if self.m_isSuperFree == true then
            if symblNode:getCcbProperty("wildNode") then
                symblNode:getCcbProperty("wildNode"):setVisible(true)
            end
        else
            if symblNode:getCcbProperty("wildNode") then
                symblNode:getCcbProperty("wildNode"):setVisible(false)
            end
        end
    end
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFortuneBrickMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "FortuneBrick"  
end
function CodeGameScreenFortuneBrickMachine:getNetWorkModuleName()
    return "FortuneBrickV2"
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFortuneBrickMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_FortuneBrick_10"
    elseif symbolType == self.BLUE_BONUS_SYMBOL_TYPE then
        return "Socre_FortuneBrick_Bonus_supper"
    end

    return nil
end

function CodeGameScreenFortuneBrickMachine:getReelHeight()
    return 438 * 0.86
end

function CodeGameScreenFortuneBrickMachine:getReelWidth()
    return 718 * 0.86
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFortuneBrickMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.BLUE_BONUS_SYMBOL_TYPE,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

--单列滚动停止回调
function CodeGameScreenFortuneBrickMachine:slotOneReelDown(reelCol)    
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol) 
  
    self:SpecialSymbolDown(reelCol)

    if reelCol <= self:getMaxContinuityBonusCol() then
        -- body
        self:runSpecialSymbolAction(reelCol)
    elseif reelCol == (self:getMaxContinuityBonusCol() + 1) then
        self:stopSpecialSymbolAction(reelCol)
    end


    if reelCol == 5 then
        local wild = self:getFixSymbol(1,2,SYMBOL_NODE_TAG)
        local scatter = self:getFixSymbol(1,3,SYMBOL_NODE_TAG)
        local wildparent = wild:getParent()
        local scatterparent = scatter:getParent()
        local wildz = wild:getLocalZOrder()
        local scatterz = scatter:getLocalZOrder()
        print("...")
    end

    local rundi = self.m_RunDi[reelCol]
    if rundi:isVisible() then
        rundi:playAction("over",false,function()
            rundi:setVisible(false)
        end)
    end
    
end
--轮盘开始滚动
function CodeGameScreenFortuneBrickMachine:beginReel()
    self.m_isReconnection = false
    CodeGameScreenFortuneBrickMachine.super.beginReel(self)
end
function CodeGameScreenFortuneBrickMachine:stopSpecialSymbolAction( reelCol )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            if iCol < reelCol then
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol] 

                local isFsWild = false
                if self.m_bProduceSlots_InFreeSpin and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    isFsWild = true
                end

                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.BLUE_BONUS_SYMBOL_TYPE or isFsWild then
                    local iconpos = self:getPosReelIdx(iRow, iCol)
                    if not  self:checkIsInArray(iconpos) then
                        local node =  self.m_bonusReelsMap[iconpos + 1]
                        node:runAnim("idleframe",false)  
                        
                        local reel_Row,reel_Col =  self:getOneSymbolPos(self:getPosReelIdx(iRow,iCol))
                        local symbolNode =  self:getReelParent(reel_Col):getChildByTag(self:getNodeTag(reel_Col,reel_Row,SYMBOL_NODE_TAG))

                        symbolNode:runAnim("idleframe",false)
                    end
                    
                end
            end
            
        end
    end
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenFortuneBrickMachine:MachineRule_stopReelChangeData()
    self:restSpecialSymbolAction()
end


function CodeGameScreenFortuneBrickMachine:SpecialSymbolDown( reelCol )
    local isPlayScatterSounds = false
    local isPlayBonusSounds = false

    for iRow = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol] 

        local isFsWild = false
        if self.m_bProduceSlots_InFreeSpin and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            isFsWild = true
        end

        if  symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.BLUE_BONUS_SYMBOL_TYPE or isFsWild then
            
            -- local reel_Row,reel_Col =  self:getOneSymbolPos(self:getPosReelIdx(iRow,iCol))
            local symbolNode = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)--self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
            
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolNode:runAnim("buling")
                if not isPlayScatterSounds then
                    isPlayScatterSounds = true

                    local soundPath = "FortuneBrickSounds/music_FortuneBrick_scatter_down.mp3"
                    if self.playBulingSymbolSounds then
                        self:playBulingSymbolSounds( reelCol,soundPath )
                    else
                        gLobalSoundManager:playSound(soundPath)
                    end

                end
                
            else
                if reelCol <= self:getMaxContinuityBonusCol() then
                    symbolNode:runAnim("buling",true)
                    if not isPlayBonusSounds then
                        isPlayBonusSounds = true
                        local soundPath = "FortuneBrickSounds/music_FortuneBrick_bonus_reel_down_".. reelCol ..".mp3"
                        if self.playBulingSymbolSounds then
                            self:playBulingSymbolSounds( reelCol,soundPath,"FortuneBrick_bonus_reel_down" )
                        else
                            gLobalSoundManager:playSound(soundPath)
                        end
                    end
                else
                    symbolNode:runAnim("idleframe")
                end
            end
        end   
    end
end


function CodeGameScreenFortuneBrickMachine:restSpecialSymbolAction( reelCol )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
    
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol] 

            local isFsWild = false
            if self.m_bProduceSlots_InFreeSpin and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                isFsWild = true
            end

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.BLUE_BONUS_SYMBOL_TYPE or isFsWild then
                local iconpos = self:getPosReelIdx(iRow, iCol)
                if not  self:checkIsInArray(iconpos) then
                    local node =  self.m_bonusReelsMap[iconpos + 1]
                    node:runAnim("idleframe",false)  
                    
                    local reel_Row,reel_Col =  self:getOneSymbolPos(self:getPosReelIdx(iRow,iCol))
                    local symbolNode =  self:getReelParent(reel_Col):getChildByTag(self:getNodeTag(reel_Col,reel_Row,SYMBOL_NODE_TAG))

                    symbolNode:runAnim("idleframe",false)
                end
                
            end
            
        end
    end
end
function CodeGameScreenFortuneBrickMachine:runSpecialSymbolAction( reelCol )
    for iRow = 1, self.m_iReelRowNum do
        
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol] 

        local isFsWild = false
        if self.m_bProduceSlots_InFreeSpin and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            isFsWild = true
        end

        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.BLUE_BONUS_SYMBOL_TYPE or isFsWild then
            local iconpos = self:getPosReelIdx(iRow, reelCol)
            local node =  self.m_bonusReelsMap[iconpos + 1]

            if symbolType == self.BLUE_BONUS_SYMBOL_TYPE then
                node:runAnim("actionframe_super",true) 
            else
                node:runAnim("actionframe",true)  
            end
            
            gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_bonus_reel_down_".. reelCol ..".mp3")
        end
           
    end
end

function CodeGameScreenFortuneBrickMachine:getMaxContinuityBonusCol()
    local maxColIndex = 0
    
    local isContinuity = true

    for iCol = 1, self.m_iReelColumnNum do
        local bonusNum = 0
        
        for iRow = 1, self.m_iReelRowNum do
    
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol] 

            local isFsWild = false
            if self.m_bProduceSlots_InFreeSpin and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                isFsWild = true
            end

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.BLUE_BONUS_SYMBOL_TYPE or isFsWild then
                bonusNum = bonusNum + 1
                if isContinuity then
                    maxColIndex = iCol
                end
            end
            
        end
        if bonusNum == 0 then
            isContinuity = false
            break
        end
    end

    return maxColIndex
end

function CodeGameScreenFortuneBrickMachine:checkIsInArray( pos )
    local isIn = false
    
    for k,v in pairs(self.m_runSpinResultData.p_selfMakeData.bonusIcons) do
        local index = tonumber(k)
        if index == pos then
            isIn = true
            return isIn
        end
    end

    return isIn
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenFortuneBrickMachine:levelFreeSpinEffectChange()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"change_freespin")
    self:runCsbAction("change_freespin")
    self.m_wonBonusTimes:runCsbAction("idle1")
    self.m_wonBonusTimes:setVisible(true)
    self.m_collectBar:setVisible(false)

    if self.m_runSpinResultData.p_selfMakeData.freeSpinTriggerCnt == 5 then
        self.m_isSuperFree = true
        self.m_wonBonusTimes:findChild("FreeGames"):setVisible(false)
        self.m_wonBonusTimes:findChild("SuperFreeGames"):setVisible(true)
        self.m_bottomUI:showAverageBet()
    else
        self.m_isSuperFree = false
        self.m_wonBonusTimes:findChild("FreeGames"):setVisible(true)
        self.m_wonBonusTimes:findChild("SuperFreeGames"):setVisible(false)
    end
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenFortuneBrickMachine:levelFreeSpinOverChangeEffect()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"change_normal")
    self:runCsbAction("change_normal")
    self.m_wonBonusTimes:runCsbAction("idle2")
    self.m_wonBonusTimes:setVisible(false)
    self.m_collectBar:setVisible(true)
    self.m_isSuperFree = false
    self.m_bottomUI:hideAverageBet()
end
---------------------------------------------------------------------------



function CodeGameScreenFortuneBrickMachine:showFreeSpinView(effectData)
    -- 停掉背景音乐
    self:clearCurMusicBg()

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_enter_fs_view.mp3")
        
        self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,true)
    else
        if self.m_isReconnection == false then
            self:updateCollectBar(true)
        end
        performWithDelay(self,function ()
            gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_enter_fs_view.mp3")

            self:showFreeSpinStart(self.m_runSpinResultData.p_freeSpinsTotalCount,function()

                    self:triggerFreeSpinCallFun()

                    effectData.p_isPlay = true
                    self:playGameEffect()       
            end)
        end,1)
    end

end
function CodeGameScreenFortuneBrickMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    local freespinView = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func,BaseDialog.AUTO_TYPE_ONLY)
    
    if self.m_runSpinResultData.p_selfMakeData.freeSpinTriggerCnt == 5 then
        freespinView:findChild("FreeGames"):setVisible(false)
        freespinView:findChild("Free"):setVisible(false)
    else
        freespinView:findChild("SuperFreeGames"):setVisible(false)
        freespinView:findChild("Super"):setVisible(false)
    end
end
function CodeGameScreenFortuneBrickMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_freespin_over_view.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

        self:updateCollectBar(false)
        self:triggerFreeSpinOverCallFun()
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},480)

    if self.m_isSuperFree then
        view:findChild("freeNode"):setVisible(false)
    else
        view:findChild("superfreeNode"):setVisible(false)
    end
end
function CodeGameScreenFortuneBrickMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_num_super"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end
---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFortuneBrickMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    
    if self.m_BonusSoundsId then
        gLobalSoundManager:stopAudio(self.m_BonusSoundsId)
        self.m_BonusSoundsId = nil
    end

    self.isInBonus = false

    self:changeNodeColor( false )

    self:changeSelfBonusReelsAct()

    return false
end

function CodeGameScreenFortuneBrickMachine:changeSelfBonusReelsAct()
   
    for k,v in pairs(self.m_bonusReelsData) do
        local pos = k
        local node =  self.m_bonusReelsMap[pos]
        local score = v

        if node.score ~= score then
            --Score相关
            if node.scoreNode ~= nil then
                local symbolType1,ccbName1 =  self:getBonusReelsScoreTypeNameForNetData(score)
                node.scoreNode:changeCCBByName(ccbName1,symbolType1)
                node.scoreNode:getCcbProperty("score"):setString(score)
                node.scoreNode:runAnim("idleframe")
            end

            local symbolType,ccbName =  self:getBonusReelsTypeNameForNetData( score)
            node:changeCCBByName(ccbName,symbolType)
            node:getCcbProperty("score"):setVisible(false)
            node.score = score
            -- node:getCcbProperty("score"):setString(score)
        end
        
        node:runAnim("idleframe") 

    end
end

function CodeGameScreenFortuneBrickMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        
        gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_enter.mp3")
        scheduler.performWithDelayGlobal(function ()
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenFortuneBrickMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    self:updateCollectBar(false)
end

function CodeGameScreenFortuneBrickMachine:addObservers()
	BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end
        local index = util_random(1,4)
        local soundName = "FortuneBrickSounds/music_FortuneBrick_last_win_" .. index .. ".mp3"
        local soundTime = 2
        if index == 1 then
            soundTime = 2
        elseif index == 2 then
            soundTime = 2
        elseif index == 3 then
            soundTime = 1
        elseif index == 4 then
            soundTime = 2
        end

        self.m_winSoundsId =  globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenFortuneBrickMachine:onExit()
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

--[[
    @desc:  bonus 轮盘
    author:{author}
    time:2019-01-28 14:38:07
    @return:
]]
function CodeGameScreenFortuneBrickMachine:initBoonusReels()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do

            local score = self.m_bonusReels[4 - iRow][iCol] 
            local symbolType,ccbName =  self:getBonusReelsTypeNameForNetData(score)
            local node = SlotsNode:create()
            print("ccbName~ "..ccbName.."symbolType "..symbolType)
            node:initSlotNodeByCCBName(ccbName, symbolType)
            local iconpos = self:getPosReelIdx(iRow, iCol)
            print("self:getPosReelIdx(iRow, iCol)  "..iconpos)
            self:findChild("bonus_pos_"..iconpos):addChild(node)
            node:runAnim("idleframe",false)  
            node.iconpos = iconpos 
            node.score = score
            node.iRow = iRow
            node.iCol = iCol
            -- node:getCcbProperty("score"):setString(score)
            node:getCcbProperty("score"):setVisible(false)

            --将score拆出，达到降drawcall的目的
            local symbolType1,ccbName1 =  self:getBonusReelsScoreTypeNameForNetData(score)
            local scoreNode = SlotsNode:create()
            scoreNode:initSlotNodeByCCBName(ccbName1, symbolType1)
            self:findChild("score_pos_"..iconpos):addChild(scoreNode)
            scoreNode:runAnim("idleframe",false) 
            scoreNode:getCcbProperty("score"):setString(score)
            node.scoreNode = scoreNode

            table.insert( self.m_bonusReelsMap, node ) 
        end
    end

    table.sort( self.m_bonusReelsMap, function( a,b )
        return a.iconpos < b.iconpos 
    end )

    for k,v in pairs(self.m_bonusReelsMap) do
        table.insert( self.m_bonusReelsData, v.score )
    end

end

-- 获得bonus轮盘信号
function CodeGameScreenFortuneBrickMachine:getBonusReelsTypeNameForNetData( score)
    local typename = nil
    local symbolType = nil
    for k,v in pairs(self.m_bonusReelsScoreBet) do
        if tonumber(score) == v then
            local index = self:getBonusReelsTypename(k)
            typename = "Socre_FortuneBrick_Juzhen_"..index
            symbolType = index + 1000000
            return symbolType,typename
        end
    end
    
    return symbolType,typename
end

-- 获得bonus轮盘信号score
function CodeGameScreenFortuneBrickMachine:getBonusReelsScoreTypeNameForNetData(score)
    local typename = nil
    local symbolType = nil
    for k,v in pairs(self.m_bonusReelsScoreBet) do
        if tonumber(score) == v then
            local index = self:getBonusReelsTypename(k)
            typename = "Socre_FortuneBrick_Score_"..index
            symbolType = index + 10000000
            
            return symbolType,typename
        end
    end
    
    return symbolType,typename
end

function CodeGameScreenFortuneBrickMachine:getBonusReelsTypename( index )
    local pos = nil
    if index <= 3 then
        pos = 1
    elseif index > 3 and index <= 6 then
        pos = 2
    elseif index > 6 and index <= 9 then
        pos = 3
    elseif index > 9 and index <= 12 then
        pos = 4
    else
        pos = 5
    end
    return pos
end

function CodeGameScreenFortuneBrickMachine:getTableNum( array )
    local num = 0
    for k,v in pairs(array) do
        num = num + 1
    end

    return num
end


--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFortuneBrickMachine:MachineRule_afterNetWorkLineLogicCalculate()

    if self.m_runSpinResultData.p_selfMakeData then
        
        local m_blueBonusIcons = self.m_runSpinResultData.p_selfMakeData.blueBonusIcons
        self:reels_ChangeTypeForBlueBonus(m_blueBonusIcons)

        local m_change = self.m_runSpinResultData.p_selfMakeData.change
        if m_change then
           
            for kk,vv in pairs(m_change) do
                for k,v in pairs(self.m_bonusReelsData) do
                    local pos = tonumber(kk) +1
                    if k == pos then
                        self.m_bonusReelsData[pos] = vv
                        
                        break
                    end

                end
            end

        end

    end

    
end


function CodeGameScreenFortuneBrickMachine:reels_ChangeTypeForBlueBonus( data )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            
            local iconpos = self:getPosReelIdx(iRow, iCol)
            for k,v in pairs(data) do
                local pos = tonumber(k)
                if iconpos == pos then
                    self.m_stcValidSymbolMatrix[iRow][iCol] = self.BLUE_BONUS_SYMBOL_TYPE
                    print("----------------- 蓝色的bonus位置 ".. iconpos .." 个数 "..self:getTableNum(data).." 倍数 ".. v)
                    break
                end
            end

        end
    end

end

function CodeGameScreenFortuneBrickMachine:showBonusWin(func)
    local function newFunc()
        if func then
            func()
        end
    end
    local ownerlist={}
    self:showDialog("BonusWin",ownerlist,newFunc,BaseDialog.AUTO_TYPE_ONLY)
end
function CodeGameScreenFortuneBrickMachine:addBonusWinOverView()
    self.m_bonusWinOverView = util_createView("CodeFortuneBrickSrc.FortuneBrickBonusOverView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_bonusWinOverView.getRotateBackScaleFlag = function() return false end
    end
    gLobalViewManager:showUI(self.m_bonusWinOverView,nil,false)

    self.m_bonusWinOverView:findChild("root"):setScale(self.m_machineRootScale)

    local topWorldPos = self:findChild("TOP"):getParent():convertToWorldSpace(cc.p(self:findChild("TOP"):getPosition()))
    local biaotiziWorldPos = self.m_bonusWinOverView:findChild("biaotizi"):getParent():convertToWorldSpace(cc.p(self.m_bonusWinOverView:findChild("biaotizi"):getPosition()))
    self.m_bonusWinOverView:setPositionY(self.m_bonusWinOverView:getPositionY()+ topWorldPos.y - biaotiziWorldPos.y)
end
function CodeGameScreenFortuneBrickMachine:showBonusWinOver(coins,func)

    -- local strCoins=util_formatCoins(coins,30)

    -- local function newFunc()
    --     if func then
    --         func()
    --     end
    -- end
    -- local ownerlist={}
    -- ownerlist["m_lb_coins"]=strCoins
    gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_freespin_over_view.mp3")
    
    -- local view = self:showDialog("BonusOver",ownerlist,newFunc)
    -- local node=view:findChild("m_lb_coins")
    -- view:updateLabelSize({label=node,sx=1,sy=1},480)

    self.m_bonusWinOverView:playStartAni(func)
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFortuneBrickMachine:addSelfEffect()

    if self.m_runSpinResultData.p_selfMakeData then
        local m_change = self.m_runSpinResultData.p_selfMakeData.change
        local m_bonusPOS = self.m_runSpinResultData.p_selfMakeData.bonusIcons

        if type(m_change) == "table" then---- 剩余格子
            if self:getTableNum(m_change) >0   then
                if type(m_bonusPOS) == "table" and self:getTableNum(m_bonusPOS)  > 0 then
                    -- 赢钱改变轮盘
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.CHANGE_BONUS_REEL_FOR_WIN_EFFECT

                else
                    --普通改变轮盘
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT 
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.CHANGE_BONUS_REEL_EFFECT
                end
                
            end
        end
    end
      
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFortuneBrickMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.CHANGE_BONUS_REEL_EFFECT then
        self:changeBonusReelsAct(effectData)

    elseif effectData.p_selfEffectType == self.CHANGE_BONUS_REEL_FOR_WIN_EFFECT then
        
        self:changeBonusReelsActForWin(effectData)
    end
    
    


	return true
end
-- 显示轮盘上的遮罩
function CodeGameScreenFortuneBrickMachine:showReelZhezhao()
    self.m_reelMask:playAction("start",false)
end
-- 隐藏轮盘上的遮罩
function CodeGameScreenFortuneBrickMachine:hideReelZhezhao()
    self.m_reelMask:playAction("over",false)
end
-- 改变bonus轮盘显示
function CodeGameScreenFortuneBrickMachine:changeBonusReelsAct( effectData )

    local m_change = self.m_runSpinResultData.p_selfMakeData.change

    m_change = self:sortNetData(m_change)
    
    local dealyTime =  0
     
    local nextSpintime = dealyTime -- #m_change * dealyTime  + 0.5

    local index = 1
    for k,v in pairs(m_change) do
        local pos = v.pos
        local node =  self.m_bonusReelsMap[pos + 1]
        local score = v.score
        -- performWithDelay(self,function()

        node:runAnim("over",false,function()
            --Score相关
            if node.scoreNode ~= nil then
                local symbolType1,ccbName1 =  self:getBonusReelsScoreTypeNameForNetData(score)
                node.scoreNode:changeCCBByName(ccbName1,symbolType1)
                node.scoreNode:getCcbProperty("score"):setString(score)--
                node.scoreNode:runAnim("start") 
            end

            local symbolType,ccbName =  self:getBonusReelsTypeNameForNetData(score)
            node:changeCCBByName(ccbName,symbolType)
            node:getCcbProperty("score"):setVisible(false)
            node.score = score
            -- node:getCcbProperty("score"):setString(score)

            node:runAnim("start",false,function()
                if node.scoreNode ~= nil then
                    node.scoreNode:runAnim("idleframe")
                end
                node:runAnim("idleframe") 
            end) 
        end)         
        -- end, dealyTime * index )

        index = index + 1 

    end    


    performWithDelay(self,function()

        effectData.p_isPlay = true
        self:playGameEffect()
        
    end, nextSpintime )

end

-- 整理网络数据
function CodeGameScreenFortuneBrickMachine:sortNetData( netdata )
    local array = {}
    for k,v in pairs(netdata) do
        local pos = tonumber(k)
        local data = {}
        data.pos = pos
        data.score = v
        local reelRow,reelCol =  self:getOneSymbolPos(pos)
        data.reelRow = reelRow
        data.reelCol = reelCol
        if v > 0 then
            table.insert( array,  data )
        end
        
    end
  
    local sortdata = {}
    for iCol = 1 , self.m_iReelColumnNum do
        
        local sameRowData = {}
        for i = 1, #array do
                local  node = array[i]
                if node.reelCol == iCol then
                    sameRowData[#sameRowData + 1] = node
                end   
        end 
        table.sort( sameRowData, function(a, b)
                return b.reelRow  <  a.reelRow
        end)

        for i=1,#sameRowData do
            sortdata[#sortdata + 1] = sameRowData[i]
        end
    end

    array = sortdata
    
    return array
end


function CodeGameScreenFortuneBrickMachine:createFortuneBrickFly( startPos ,endPos,time,index,posCol,posRow )
    local WorldPos = self:findChild("bonus_pos_size"):convertToWorldSpace(cc.p(startPos))
    local Pos = cc.p(self.m_root:convertToNodeSpace(WorldPos))
    
    startPos = cc.p(Pos)
    local fly =  util_createView("CodeFortuneBrickSrc.FortuneBrickFly",index)
    fly:setPosition(startPos)
    -- fly:setScale(1.5)
    self.m_root:addChild(fly,300000)
    fly:findChild("Particle_fly"):setDuration(time)
    fly:setVisible(false)

    local soundID = index
    local changex  = 0
    performWithDelay(self,function()
        
        gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_bonus_reel_fly_"..soundID..".mp3")
        fly:setVisible(true)

        
        if posCol == 3 then
            if posRow == 1 then
                changex  =  60
            elseif posRow == 2 then
                changex  =  40
            else
                changex  =  10
            end
            
        end

        local animation = {}
        local bezier1 = {        
            cc.p(startPos.x + changex * -1   ,(startPos.y + endPos.y) /2),
            cc.p((startPos.x + endPos.x)/2 + changex   ,(startPos.y + endPos.y) /2),            
            cc.p( endPos.x ,endPos.y)
        }

        animation[#animation + 1] = cc.BezierTo:create(time/2,bezier1)
        animation[#animation + 1] = cc.CallFunc:create(function()
            
            performWithDelay(fly,function()
                fly:removeFromParent()
            end, time*2)
        end)

        fly:runAction(cc.Sequence:create(animation))
    end, time/2 )
end

function CodeGameScreenFortuneBrickMachine:updateBonusLable(node,endcoins,time,isBlue )
    -- time = 3
    local scoreNode = node
    if node.scoreNode ~= nil then
        scoreNode = node.scoreNode
    end

    local oldnum = tonumber(scoreNode:getCcbProperty("score"):getString()) 
    local temp = math.ceil((endcoins - oldnum )/ isBlue)

    local addcoins = nil
    addcoins = tonumber(temp)  
    local index = 1

    scoreNode:runAnim("start") 
    local num_1 = tonumber(scoreNode:getCcbProperty("score"):getString()) + addcoins
    scoreNode:getCcbProperty("score"):setString(num_1)

    
    local audio =  gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_blue_num_run"..isBlue..".mp3",false)
    -- gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_blue_num_run.mp3") 
    if isBlue > 1 then
        schedule(
            node,
            function()

                index = index + 1

                local num = tonumber(scoreNode:getCcbProperty("score"):getString()) 
                num = addcoins + num
                if num >= endcoins   then
                    num = endcoins
                end
                if tonumber(scoreNode:getCcbProperty("score"):getString()) ~= endcoins then
                    scoreNode:getCcbProperty("score"):setString(num)
                end

                if index >= isBlue then
                    scoreNode:getCcbProperty("score"):setString(endcoins)
                    if audio then
                        gLobalSoundManager:stopAudio(audio)
                        audio = nil
                    end
                    --gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_blue_num_run_end.mp3")
                    node:stopAllActions()
                end

                scoreNode:runAnim("start") 

            end,
            time
        )
    end
end

function CodeGameScreenFortuneBrickMachine:updateBonusLable1(node,endcoins,time )
    time = 3
    local scoreNode = node
    if node.scoreNode ~= nil then
        scoreNode = node.scoreNode
    end

    local oldnum = tonumber(scoreNode:getCcbProperty("score"):getString()) 
    local temp = math.ceil((endcoins - oldnum )/ (time / 0.05))
    -- temp = temp * 2
    local addcoins = ""
    addcoins = tonumber(temp)  
    
    local audio =  gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_blue_num_run.mp3",false)
    -- gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_blue_num_run.mp3") 
    schedule(
        node,
        function()
            local num = tonumber(scoreNode:getCcbProperty("score"):getString()) 
            num = addcoins + num
            if num >= endcoins   then
                num = endcoins
            end
            if tonumber(scoreNode:getCcbProperty("score"):getString()) ~= endcoins then
                scoreNode:getCcbProperty("score"):setString(num)
            else
                if audio then
                    gLobalSoundManager:stopAudio(audio)
                    audio = nil
                end
                gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_blue_num_run_end.mp3")
                node:stopAllActions()
            end
            print("stopAllActionsstopAllActionsstopAllActionsstopAllActions")
        end,
        0.01
    )
end

-- 改变bonus轮盘显示 赢钱
function CodeGameScreenFortuneBrickMachine:changeBonusReelsActForWin( effectData )

    self.isInBonus = true
    -- 停掉背景音乐
    self:clearCurMusicBg()

    local m_change = self.m_runSpinResultData.p_selfMakeData.change
    m_change = self:sortNetData(m_change)

    local m_bonusIcons = self.m_runSpinResultData.p_selfMakeData.bonusIcons
    m_bonusIcons = self:sortNetData(m_bonusIcons)

    local m_blueBonusIcons = self.m_runSpinResultData.p_selfMakeData.blueBonusIcons
    m_blueBonusIcons = self:sortNetData(m_blueBonusIcons)

    local dealyTime_1 = 20/30 -- WinOver 时间
    local dealyTime_2 = 2 -- over start 时间
    local dealyTime_3 = 4 + 1 + 1 -- showBonusWin 和 手动延时时间
    local dealyTime_4 = 48/30 -- 触发bonus等待时间
    local dealyTime_5 = 2.5 -- WinOverIdleframe 时间

    local dealyTime_6 = 15/30 -- 数字变化一次的时间

    local winIdleframe = function()
        for k,v in pairs(m_change) do
            local pos = v.pos
            local node =  self.m_bonusReelsMap[pos + 1]
            local reelRow,reelCol =  self:getOneSymbolPos(pos)
            print("winIdleframe  reelRow = "..reelRow.." reelCol = "..reelCol)      
            if self.m_stcValidSymbolMatrix[reelRow][reelCol] == self.BLUE_BONUS_SYMBOL_TYPE then
                node:runAnim("WinIdleframe_super",true)
            elseif self.m_stcValidSymbolMatrix[reelRow][reelCol] == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                node:runAnim("WinIdleframe",true)
            end
        end
    end
    
    local winAction = function()
        
        local index_blue = 0
        for k,v in pairs(m_blueBonusIcons) do
            local pos = v.pos
            local reelRow,reelCol =  self:getOneSymbolPos(pos)
            local score = v.score
            local node =  self.m_bonusReelsMap[pos + 1]
            local changeScore = 0
            for kk,vv in pairs(m_bonusIcons) do
                if v.pos == vv.pos  then
                    changeScore = vv.score + score
                    vv.score = changeScore
                    vv.isBlue = math.random(1,3)
                    break
                end
            end
        end
        
        local delayTime = 0
        local lastisBlue = 0
        local lastFlyTime = 0
        for k,v in pairs(m_bonusIcons) do
            local pos = v.pos
            local node =  self.m_bonusReelsMap[pos + 1]
            local lineBet = self:BaseMania_getLineBet()
            if self.m_isSuperFree then
                lineBet = self.m_avgBet/self.m_runSpinResultData.p_payLineCount
            end
            self.bonusScore = self.bonusScore + v.score * lineBet
            local endscore = self.bonusScore
            local reelRow,reelCol =  self:getOneSymbolPos(pos)
            local isBlue = 0
            local symbolNode = self:getFixSymbol(reelCol,reelRow,SYMBOL_NODE_TAG) --self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,reelRow,SYMBOL_NODE_TAG))
            if symbolNode.p_symbolType == self.BLUE_BONUS_SYMBOL_TYPE then
                isBlue = v.isBlue
            end
            local flyTime = 0
            performWithDelay(self,function()
                if isBlue > 0 then
                    flyTime = 0.5
                    local flyNode = util_createAnimation("Socre_FortuneBrick_jiaqianlizi.csb")
                    self:findChild("root"):addChild(flyNode)
                    local startWorldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
                    local startPos = self:findChild("root"):convertToNodeSpace(startWorldPos)
                    flyNode:setPosition(startPos)
                    flyNode:findChild("Particle_1"):setPositionType(0)
                    flyNode:findChild("Particle_1"):resetSystem()
                    local endWorldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                    local endPos = self:findChild("root"):convertToNodeSpace(endWorldPos)
                    local moveto = cc.MoveTo:create(flyTime,endPos)
                    
                    local func = cc.CallFunc:create(function ()
                        flyNode:findChild("Particle_1"):stopSystem()
                        self:updateBonusLable(node,v.score,dealyTime_6,isBlue)
                        performWithDelay(self,function ()
                            flyNode:removeFromParent()
                        end,0.5)
                    end)
                    local seq = cc.Sequence:create({moveto,func})
                    flyNode:runAction(seq)
                    gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_Collect_Gold2.mp3")
                end

                performWithDelay(self,function()
                    if symbolNode.p_symbolType == self.BLUE_BONUS_SYMBOL_TYPE then
                        node:runAnim("WinOver_super")
                    else
                        node:runAnim("WinOver")
                    end
                    gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_hide_bonus.mp3") 
                    self:createFortuneBrickFly(cc.p(self:findChild("bonus_pos_"..pos):getPosition()),cc.p(self:findChild("TOP"):getPosition()),1,node.p_symbolType%10,reelCol,reelRow)
                end,flyTime + isBlue * dealyTime_6 + 0.1 )
                
                performWithDelay(self,function()
                    gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_bonus_Win.mp3") 
                    -- self.m_wonBonusWinScoreView:showCollectCoin(endscore)
                    self.m_wonBonusWinScoreView:findChild("FortuneBricklogo_1"):setVisible(false)
                    self.m_bonusWinOverView:showCollectCoin(endscore)
                end, 1.2 + flyTime + isBlue * dealyTime_6 )
                lastisBlue = isBlue
                lastFlyTime = flyTime
            end, delayTime )
            delayTime = delayTime + 1.8 + isBlue * dealyTime_6 + flyTime
        end
        return delayTime + 1.2 + lastFlyTime + lastisBlue * dealyTime_6
    end

    local WinOverIdleframe = function()
        for k,v in pairs(m_bonusIcons) do
            local pos = v.pos
            local node =  self.m_bonusReelsMap[pos + 1]
            local reelRow,reelCol =  self:getOneSymbolPos(pos)

            node:runAnim("WinOverIdleframe",false)
            
            
        end
    end

    local changeBonusReels = function()
               
            local index_2 = 0
            for k,v in pairs(m_change) do
                local pos = v.pos
                local node =  self.m_bonusReelsMap[pos + 1]
                local score = v.score
                    --performWithDelay(self,function()
                self:setNodeLightColor(node )
                node:runAnim("over",false,function()
                    --Score相关
                    if node.scoreNode ~= nil then
                        local symbolType1,ccbName1 =  self:getBonusReelsScoreTypeNameForNetData(score)
                        node.scoreNode:changeCCBByName(ccbName1,symbolType1)
                        node.scoreNode:getCcbProperty("score"):setString(score)
                        node.scoreNode:runAnim("start") 
                    end

                    local symbolType,ccbName =  self:getBonusReelsTypeNameForNetData( score)
                    node:changeCCBByName(ccbName,symbolType)
                    node:getCcbProperty("score"):setVisible(false)
                    -- node:getCcbProperty("score"):setString(score)
                    
                    node:runAnim("start",false,function()
                        if node.scoreNode ~= nil then
                            node.scoreNode:runAnim("idleframe") 
                        end
                        node:runAnim("idleframe") 
                    end) 
                
                end) 
                    
                --end, dealyTime_2 * index_2 )

                index_2 = index_2 + 1 
            end          
    end

    -- 触发bonus 逻辑
    self:triggerBonus()
    -- 改变小轮盘未中奖小块的颜色
    self:changeNodeColor(true)

    performWithDelay(self,function()

        -- ------ 动画逻辑 ---- 
        winIdleframe()

        performWithDelay(self,function()               
            -- gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_enter_Bonus_view.mp3",false)

            -- self:showBonusWin(function()
                
                -- self.m_wonBonusWinScoreView:showStartCollect()

                local winActionTime = winAction()
                
                performWithDelay(self,function()
                    gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_bonus_EndWin.mp3")
                    self.m_wonBonusWinScoreView:runCsbAction("Settlement",false)
                    WinOverIdleframe()
                end, winActionTime )

                performWithDelay(self,function()

                    -- gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_bonus_EndWin.mp3")
                    local bonusOver  = function()
                        self.m_wonBonusWinScoreView:showOverCollect(function()
                            -- self.m_wonBonusWinScoreView.m_lightAction:showAction(nil,true)
                            self.m_wonBonusWinScoreView:runCsbAction("animation0",true)
                            self.m_wonBonusWinScoreView:findChild("FortuneBricklogo_1"):setVisible(true)
                        end)
            
                        -- 通知UI钱更新
                        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                            -- freeSpin下特殊玩法的算钱逻辑
                            if self.m_serverWinCoins == self.bonusScore  then
                                print("分数相等说明没有赢钱线的钱，得手动加钱")
                                
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})  
                                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
                            else
                                print("在算线钱的时候就已经把特殊玩法赢的钱加到总钱了，所以不用更新钱")
                                
                            end
            
                        else
                            if self.m_serverWinCoins == self.bonusScore then
                                -- self:checkSelfFeatureOverTriggerBigWin(self.m_serverWinCoins,GameEffect.EFFECT_BONUS)
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_serverWinCoins, GameEffect.EFFECT_BONUS})
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})
            
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
                            end
                            
                            
                        end
                        if self.bonusScore ~= self.m_serverWinCoins  then
                            -- dump(globalData.slotRunData.severGameJsonData,"网络数据")
                        end
                        
                        self.isInBonus = false
                        -- 重置回透明色
                        self:changeNodeColor(false)
                        self:hideReelZhezhao()
            
                        self.bonusScore = 0

                        changeBonusReels()

                        if self.m_BonusSoundsId then
                            gLobalSoundManager:stopAudio(self.m_BonusSoundsId)
                            self.m_BonusSoundsId = nil
                        end
            
        
                        performWithDelay(self,function()
                            self:resetMaskLayerNodes()
                            self:resetMusicBg()
                            effectData.p_isPlay = true
                            self:playGameEffect()  
                        end, dealyTime_2)
                        
                        
                    end
                    
                    self:showBonusWinOver(self.bonusScore,function()
                        bonusOver()
                        self.m_bonusWinOverView = nil
                    end)

                    -- 
                
                end, winActionTime +  dealyTime_5  )
            -- end)
        end, dealyTime_4 )
    end, 0.5 )
end
function CodeGameScreenFortuneBrickMachine:checkOperaSpinSuccess(param)
    self.m_avgBet = param[2].result.avgBet
    CodeGameScreenFortuneBrickMachine.super.checkOperaSpinSuccess(self,param)
end
function CodeGameScreenFortuneBrickMachine:triggerBonus()

    gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_trigger_bonus.mp3")

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol] 
            local isFsWild = false
            if self.m_bProduceSlots_InFreeSpin and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                isFsWild = true
            end
            
            
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.BLUE_BONUS_SYMBOL_TYPE or isFsWild then
                local node =  self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
                local iconpos = self:getPosReelIdx(iRow, iCol)
                if self:checkIsInArray(iconpos) then
                    self:setSlotNodeEffectParent(node)
                    node:runAnim("actionframe",true)
                end
            end
            
        end
    end
    self:showReelZhezhao()
    self:addBonusWinOverView()
end

function CodeGameScreenFortuneBrickMachine:getOneSymbolPos( pos )
    local Row = nil
    local Col = nil
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
    
            local iconpos = self:getPosReelIdx(iRow, iCol)
            
            if pos == iconpos  then
                Row = iRow
                Col = iCol
                return Row,Col
            end 

        end
    end

    return Row,Col
end

function CodeGameScreenFortuneBrickMachine:setNodeDarkColor( node )
    if node then
        -- node:getCcbProperty("Node_1"):setColor(cc.c3b(77, 77, 77)) -- 置灰
        node:runAnim("winidle_no",false)
    end
end

function CodeGameScreenFortuneBrickMachine:setNodeLightColor(node )
    if node then
        -- node:getCcbProperty("Node_1"):setColor(cc.c3b(255, 255, 255)) -- 无色
        node:runAnim("idleframe",false)
    end
end

function CodeGameScreenFortuneBrickMachine:changeNodeColor( isDark )
    for iCol = 1, self.m_iReelColumnNum do 
        for iRow = 1, self.m_iReelRowNum do
        
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol] 
    
            local isFsWild = false
            if self.m_bProduceSlots_InFreeSpin and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                isFsWild = true
            end

            local iconpos = self:getPosReelIdx(iRow, iCol)
            local node =  self.m_bonusReelsMap[iconpos + 1]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.BLUE_BONUS_SYMBOL_TYPE or isFsWild then
                if not  self:checkIsInArray(iconpos) then
                    if isDark then
                        self:setNodeDarkColor( node )
                    end
                end
            else
                -- node = self:findChild("bonus_pos_"..iconpos)
                
                if isDark then
                    
                    self:setNodeDarkColor( node )
                end
            end

            if not isDark  then
                self:setNodeLightColor(node )
            end
        end
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFortuneBrickMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

    local isAddRunInfo = false
        for iRow = 1, self.m_iReelRowNum do
        
            local symbolType = self.m_stcValidSymbolMatrix[iRow][1] 
            if self.m_bProduceSlots_InFreeSpin then

                if symbolType == self.BLUE_BONUS_SYMBOL_TYPE or symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    isAddRunInfo = true
                end
            else
                if symbolType == self.BLUE_BONUS_SYMBOL_TYPE or symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    isAddRunInfo = true
                end
            end
        end
    if isAddRunInfo then
        for i=2,self.m_iReelColumnNum do
            self.m_reelRunInfo[i]:setReelRunLen(self.m_reelRunInfo[i]:getReelRunLen() + 6)  
        end
        self:setLastReelSymbolList() 
    end
end

function CodeGameScreenFortuneBrickMachine:setReelRunInfo()
    self:setReelRunBonusScatter(false)
    self:setReelRunBonusScatter(true)
end
--设置长滚信息
function CodeGameScreenFortuneBrickMachine:setReelRunBonusScatter(bScatter)
    
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0

    local addLens = false
     
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        else
            if addLens == true then
                self.m_reelRunInfo[col]:setReelLongRun(false)
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 14) 
                self:setLastReelSymbolList()    
            end
        end

        local runLen = reelRunData:getReelRunLen()
  
        --统计bonus scatter 信息
        if bScatter then
            scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        else
            bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)

            if bonusNum ~= col then
                self.m_reelRunInfo[col]:setNextReelLongRun(false)
                bRunLong = false
            elseif bonusNum == col  then
                if bRunLong then
                    addLens = true
                end
            end
        end
    end --end  for col=1,iColumn do
end


-- --设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}


-- --设置bonus scatter 信息
function CodeGameScreenFortuneBrickMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
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

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount
    local bAdd = false

    for row = 1, iRow do
        local targetSymbolType = self:getSymbolTypeForNetData(column,row,runLen)
        local isTrue = false
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then

            if not self.m_bProduceSlots_InFreeSpin then
                if targetSymbolType == self.BLUE_BONUS_SYMBOL_TYPE or targetSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    isTrue = true
                end
            else
                if targetSymbolType == self.BLUE_BONUS_SYMBOL_TYPE or targetSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or targetSymbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    isTrue = true
                end 
            end
            
        else
            if targetSymbolType == symbolType then
                isTrue = true
            end
        end
        if isTrue then
            local bPlaySymbolAnima = bPlayAni
                if bAdd == false then
                    allSpecicalSymbolNum = allSpecicalSymbolNum + 1
                    bAdd = true
                end
                
                if bRun == true then
                    
                    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
    
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

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenFortuneBrickMachine:specialSymbolActionTreatment( node)
    if not node then
        return
    end

    local isChange = false
    if self.m_bProduceSlots_InFreeSpin then
        if node.p_symbolType == self.BLUE_BONUS_SYMBOL_TYPE or node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            isChange = true
        end
    else
        if node.p_symbolType == self.BLUE_BONUS_SYMBOL_TYPE or node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS  then
            isChange = true
        end  

    end
    if isChange  then 
        node:runAnim("buling",true)
        if node.p_cloumnIndex > self:getMaxContinuityBonusCol() or self:getMaxContinuityBonusCol() == 1 then
            node:runAnim("idleframe")
        end
    end
    
end

function CodeGameScreenFortuneBrickMachine:randomSlotNodesByReel()
    for colIndex=1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex=1,resultLen do
            
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = reelColData.p_showGridH      
            
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
           
            parentData.slotParent:addChild(node,
            node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * reelColData.p_showGridH + halfNodeH )
            node:runIdleAnim()
        end
    end
end

function CodeGameScreenFortuneBrickMachine:slotReelDown()
    CodeGameScreenFortuneBrickMachine.super.slotReelDown(self) 
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
end
function CodeGameScreenFortuneBrickMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenFortuneBrickMachine.super.playEffectNotifyNextSpinCall(self)
end

---
--添加金边
function CodeGameScreenFortuneBrickMachine:creatReelRunAnimation(col)
    CodeGameScreenFortuneBrickMachine.super.creatReelRunAnimation(self,col)
    local rundi = self.m_RunDi[col]
    if rundi then
        rundi:setVisible(true)
        rundi:playAction("show")
    end
end

function CodeGameScreenFortuneBrickMachine:updateCollectBar(isPlayAction)
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.freeSpinTriggerCnt then
        local process = self.m_runSpinResultData.p_selfMakeData.freeSpinTriggerCnt
        for i,collectSymbol in ipairs(self.m_collectSymbolTab) do
            if i < process then
                collectSymbol:setVisible(true)
                collectSymbol:playAction("idleframe")
            elseif i == process then
                collectSymbol:setVisible(true)
                if isPlayAction then
                    gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_freeCollect.mp3")
                    collectSymbol:playAction("animation")
                else
                    collectSymbol:playAction("idleframe")
                end
            else
                collectSymbol:setVisible(false)
                collectSymbol:playAction("idleframe")
            end
        end
    end
end

function CodeGameScreenFortuneBrickMachine:checkIsAddLastWinSomeEffect( )
    
    local notAdd  = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end

    if self.m_runSpinResultData.p_selfMakeData then
        local m_change = self.m_runSpinResultData.p_selfMakeData.change
        local m_bonusPOS = self.m_runSpinResultData.p_selfMakeData.bonusIcons

        if type(m_change) == "table" then---- 剩余格子
            if self:getTableNum(m_change) >0   then
                if type(m_bonusPOS) == "table" and self:getTableNum(m_bonusPOS)  > 0 then

                    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                        -- freespin触发了bonus赢钱玩法，需要显示大赢
                        notAdd = false
                    end
                    

                end
                
            end
        end
    end

    return notAdd
end

return CodeGameScreenFortuneBrickMachine