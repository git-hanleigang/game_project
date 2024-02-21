---
-- island li
-- 2019年1月26日
-- CodeGameScreenZeusMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local ZeusSlotFastNode = require "CodeZeusSrc.ZeusSlotFastNode"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenZeusMachine = class("CodeGameScreenZeusMachine", BaseFastMachine)

CodeGameScreenZeusMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画


CodeGameScreenZeusMachine.SYMBOL_MIDRUN_SYMBOL = 101
CodeGameScreenZeusMachine.SYMBOL_ROCK_SYMBOL = 102
CodeGameScreenZeusMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1


CodeGameScreenZeusMachine.SYMBOL_Coin_Grand_SYMBOL = 201
CodeGameScreenZeusMachine.SYMBOL_Coin_Major_SYMBOL = 202
CodeGameScreenZeusMachine.SYMBOL_Coin_Minor_SYMBOL = 203
CodeGameScreenZeusMachine.SYMBOL_Coin_Mini_SYMBOL = 204
CodeGameScreenZeusMachine.SYMBOL_Coin_zi_SYMBOL = 205

CodeGameScreenZeusMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2



CodeGameScreenZeusMachine.m_chipList = nil
CodeGameScreenZeusMachine.m_playAnimIndex = 0
CodeGameScreenZeusMachine.m_lightScore = 0
CodeGameScreenZeusMachine.m_hightBet = 10

local selectFreeSpinId = 1
local selectRespinId = 2

CodeGameScreenZeusMachine.m_scaleJackpotView = 0
-- 构造函数
function CodeGameScreenZeusMachine:ctor()
    BaseFastMachine.ctor(self)


    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0

    self.m_triggerShowCollectView = false
    self.m_chooseRepinNotCollect = false
    self.m_chooseRepin = false
    self.m_choiceTriggerRespin = false
    self.m_bonusCollectWin = false
    self.m_choiceRespinGame = false

    self.m_hightBet = 10


    self.m_RunDi = {}
    self.m_RunTop = {}
    self.m_collectList = {}

    self.isInBonus = false

    self.m_scaleJackpotView = 1
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenZeusMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("ZeusConfig.csv", "LevelZeusConfig.lua")
	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenZeusMachine:initReelsUIZOrder( )
    
    local nameList = {"Node_BG","Respin","jackpot","respinoverWin","root_zeusMan","Node_reel",
                    "Image_1","Node_reel_spin2","jindutiao"}

    for i=1,#nameList do

        local node = self:findChild(nameList[i])
        if node then
            node:setLocalZOrder(i)
        end
        
    end

    self:findChild("addWildNode"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    -- self:findChild("root_Act"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 9)
    -- self:findChild("Zeus_jackPoTip"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)
    self:findChild("SpinRemaining"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
    self:findChild("root_0"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 900)
    self:findChild("left_light"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)
    self:findChild("right_light"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)
    self:findChild("changeView"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)


    self:findChild("liugaung_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 800)
    self:findChild("liugaung_2"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 800)
    
 

end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenZeusMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i <= 2 then
            soundPath = "ZeusSounds/Zeus_scatter_down1.mp3"
        elseif i > 2 and i < 5 then
            soundPath = "ZeusSounds/Zeus_scatter_down2.mp3"
        else
            soundPath = "ZeusSounds/Zeus_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenZeusMachine:initUI()


    -- self.m_bottomUI:setVisible(false)
    -- self.m_topUI:setVisible(false)
    self.m_reelRunSound = "ZeusSounds/music_Zeus_LongRun.mp3"

    self:initReelsUIZOrder( )

    self:initFreeSpinBar() -- FreeSpinbar
    
    self.m_Zeus_jackPoTip = util_createView("CodeZeusSrc.ZeusJackPotTipView",self)
    self:findChild("Zeus_jackPoTip"):addChild(self.m_Zeus_jackPoTip)
    self.m_Zeus_jackPoTip:setVisible(false)
    
   
    self.m_ZeusMan = util_spineCreate("Zeus_hero",true,true)
    self:findChild("ZeusMan"):addChild(self.m_ZeusMan)
    self.m_ZeusMan:setPositionY(-140)
    util_spinePlay(self.m_ZeusMan,"idleframe",true)
    -- self.m_ZeusMan:setVisible(false)
 
    self.m_JackPotView = util_createView("CodeZeusSrc.ZeusJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_JackPotView)
    self.m_JackPotView:initMachine(self)
    self.m_JackPotView:runCsbAction("small",true)
    self.m_JackPotView:findChild("Panel_1"):setVisible(false)
    self.m_JackPotView:setScale(self.m_scaleJackpotView)
    

    self.m_freespinSpinbar = util_createView("CodeZeusSrc.ZeusFreespinBarView")
    self:findChild("SpinRemaining"):addChild(self.m_freespinSpinbar)
    self.m_freespinSpinbar:setVisible(false)
    self.m_baseFreeSpinBar = self.m_freespinSpinbar


    self.m_CollectBar = util_createView("CodeZeusSrc.ZeusLoadingBarView",self)
    self:findChild("jindutiao"):addChild(self.m_CollectBar)
    -- self.m_CollectBar:setVisible(false)
    
    self.m_changeView = util_createView("CodeZeusSrc.ZeusChangeView")
    self:findChild("changeView"):addChild(self.m_changeView)
    self.m_changeView:setVisible(false)
    
    self.m_respinSpinbar = util_createView("CodeZeusSrc.ZeusRespinBarView")
    self:findChild("SpinRemaining"):addChild(self.m_respinSpinbar)
    self.m_respinSpinbar:setVisible(false)

    self.m_respinWinBar =  util_createAnimation("Zeus_RespinWinner.csb")
    self:findChild("respinoverWin"):addChild(self.m_respinWinBar)
    self.m_respinWinBar:setVisible(false)

    self.m_respinWinBarEffect = util_createAnimation("Zeus_RespinWinner_0.csb")
    self.m_respinWinBar:findChild("Node_10"):addChild(self.m_respinWinBarEffect)
    self.m_respinWinBarEffect:runCsbAction("idleframe",true)
 
    
    for i=1,5 do

        local longRunDi =  util_createAnimation("Socre_Zeus_Run_0.csb") 
        self:findChild("root"):addChild(longRunDi,6) 
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_"..(i - 1)):getPosition()))
        table.insert( self.m_RunDi, longRunDi )
        longRunDi:setVisible(false)
    end

    for i=1,5 do

        local longRunTop =  util_createAnimation("Socre_Zeus_Run.csb") 
        self:findChild("root"):addChild(longRunTop,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + i) 
        longRunTop:setPosition(cc.p(self:findChild("sp_reel_"..(i - 1)):getPosition()))
        table.insert( self.m_RunTop, longRunTop )
        longRunTop:setVisible(false)
    end

    self.m_AddWildEffect = {}
    local AddWildEffect =  util_createAnimation("WinFrameZeus_runwild.csb") 
    self:findChild("addWildNode"):addChild(AddWildEffect) 
    AddWildEffect.LittleUI =  util_createAnimation("Zeus/ChooseCoin_1.csb") 
    AddWildEffect:findChild("Node_3"):addChild(AddWildEffect.LittleUI) 
    table.insert( self.m_AddWildEffect, AddWildEffect )
    AddWildEffect:setVisible(false)


    self:createLocalAnimation( )
    
    self.m_respin_LiuGuang_1 = util_createAnimation("RespinView/Zeus_RespinTopBar_1.csb") 
    self:findChild("liugaung_1"):addChild(self.m_respin_LiuGuang_1)
    self.m_respin_LiuGuang_1:setVisible(false)

    self.m_respin_LiuGuang_2 = util_createAnimation("RespinView/Zeus_RespinTopBar_1.csb") 
    self:findChild("liugaung_2"):addChild(self.m_respin_LiuGuang_2)
    self.m_respin_LiuGuang_2:setVisible(false)

    if globalData.slotRunData.isPortrait then

        local bangDownHeight = util_getSaveAreaBottomHeight()
        self:findChild("bonusCollectView"):setPositionY(self:findChild("bonusCollectView"):getPositionY()  + bangDownHeight )

    end


    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if self.m_bIsBigWin then

            self.m_light_left:runCsbAction("bigwin",true)
            self.m_light_reight:runCsbAction("bigwin",true)

            return
        end

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
            soundTime = 3
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
            soundTime = 3
        end

        if not self.m_bonusCollectWin then
            if self.m_winSoundsId == nil then
                local soundName = "ZeusSounds/music_Zeus_last_win_".. soundIndex .. ".mp3"
                self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
            end
        end
        

        if winRate and winRate > 0 then
            self.m_light_left:runCsbAction("littlewin",true)
            self.m_light_reight:runCsbAction("littlewin",true)
        end
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenZeusMachine:changeGameBG( isFeature )

    if self.m_gameLightBg then
        if isFeature then
            self.m_gameLightBg:runCsbAction("idleframe2",true)
            self.m_gameLightBg:findChild("Bg_Base"):setVisible(false)
            self.m_gameLightBg:findChild("Bg_Respin"):setVisible(true)
        else
            self.m_gameLightBg:runCsbAction("idleframe")
            self.m_gameLightBg:findChild("Bg_Base"):setVisible(true)
            self.m_gameLightBg:findChild("Bg_Respin"):setVisible(false)
        end  
    end
 
end


function CodeGameScreenZeusMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg

    self.m_gameLightBg = util_createView("CodeZeusSrc.ZeusGameBg")
    self:findChild("Node_BG"):addChild(self.m_gameLightBg)


    self.m_light_left = util_createAnimation("Zeus_Bg_left_light.csb")
    self:findChild("left_light"):addChild(self.m_light_left)
    self.m_light_left:runCsbAction("idleframe",true)
    -- self.m_light_left:setVisible(false)

    self.m_light_reight = util_createAnimation("Zeus_Bg_right_light.csb")
    self:findChild("right_light"):addChild(self.m_light_reight)
    self.m_light_reight:runCsbAction("idleframe",true)
    -- self.m_light_reight:setVisible(false)

    self:changeGameBG( )
    
    
end



-- 断线重连 
function CodeGameScreenZeusMachine:MachineRule_initGame(  )

    
    self:updateLoadingBar( )
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_light_left:runCsbAction("lighting",true)
        self.m_light_reight:runCsbAction("lighting",true)
        self.m_CollectBar:setVisible(false)

        self:findChild("jackpot"):setVisible(false)

        util_spinePlay(self.m_ZeusMan,"idleframe2",true)

        self:changeGameBG( true )
    end
    
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenZeusMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "Zeus"  
end

-- 继承底层respinView
function CodeGameScreenZeusMachine:getRespinView()
    return "CodeZeusSrc.ZeusRespinView"
end
-- 继承底层respinNode
function CodeGameScreenZeusMachine:getRespinNode()
    return "CodeZeusSrc.ZeusRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenZeusMachine:MachineRule_GetSelfCCBName(symbolType)
    
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_ROCK_SYMBOL  then
        return "Socre_Zeus_Light"
    elseif symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_Zeus_Coin_Silver"
    elseif symbolType == self.SYMBOL_MIDRUN_SYMBOL  then
        return "Socre_Zeus_Coin2"

    elseif symbolType == self.SYMBOL_Coin_Grand_SYMBOL  then
        return "Zeus_Node_Coin_Grand"
    elseif symbolType == self.SYMBOL_Coin_Major_SYMBOL  then
        return "Zeus_Node_Coin_Major"
    elseif symbolType == self.SYMBOL_Coin_Minor_SYMBOL  then
        return "Zeus_Node_Coin_Minor"
    elseif symbolType == self.SYMBOL_Coin_Mini_SYMBOL  then
        return "Zeus_Node_Coin_Mini"
    elseif symbolType == self.SYMBOL_Coin_zi_SYMBOL  then
        return "Zeus_Node_Coin_zi"

    end


    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenZeusMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
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

function CodeGameScreenZeusMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end


    return score
end

-- 给respin小块进行赋值
function CodeGameScreenZeusMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()

            
            self:getCcbDealHightLowScore( symbolNode, score )

            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode:getCcbProperty("m_lb_score") then
                symbolNode:getCcbProperty("m_lb_score"):setString(score)
            end
            if symbolNode:getCcbProperty("m_lb_score_0") then
                symbolNode:getCcbProperty("m_lb_score_0"):setString(score)
            end
            
        end

        symbolNode:runAnim("idleframe")
        if self:getCurrSpinMode() == RESPIN_MODE  then
            symbolNode:runAnim("actionframe1",true)
        end

        local lockNode = symbolNode
        local reelIdx = self:getPosReelIdx(lockNode.p_rowIndex, lockNode.p_cloumnIndex)
        if lockNode.p_symbolType == self.SYMBOL_ROCK_SYMBOL then
            if self:getCurrSpinMode() == RESPIN_MODE then
                if not  self:isInRockPosList(  reelIdx ) then
                    lockNode:runAnim("actionframe2",true)
                end
    
    
                local index = self:getPosReelIdx(lockNode.p_rowIndex, lockNode.p_cloumnIndex)
                self:changeRockSymbolImg( index,lockNode )
            end
            
          
        end

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end

            self:getCcbDealHightLowScore( symbolNode, score )

            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
                if symbolNode:getCcbProperty("m_lb_score_0") then
                    symbolNode:getCcbProperty("m_lb_score_0"):setString(score)
                end
            
                symbolNode:runAnim("idleframe")
            end
            
        end
        
    end

end


function CodeGameScreenZeusMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if symbolType == self.SYMBOL_FIX_SYMBOL or symbolType == self.SYMBOL_ROCK_SYMBOL  then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end


    if node.p_symbolType == self.SYMBOL_MIDRUN_SYMBOL then

        if node and node.getCcbProperty then
            node.m_specialRunUI = util_createView("CodeZeusSrc.ZeusRespinRunView",self)
            node:getCcbProperty("Node_Coin_zi"):addChild(node.m_specialRunUI)
        end
        

        -- 滚动停止
        -- local endData = {}
        -- endData.type = "Minor"
        -- self.m_specialRunUI:setEndValue(endData)
    end

 
    return node
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenZeusMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MIDRUN_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ROCK_SYMBOL,count =  2}


    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Coin_Grand_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Coin_Major_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Coin_Minor_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Coin_Mini_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Coin_zi_SYMBOL,count =  2}


    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenZeusMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or 
        symbolType == self.SYMBOL_MIDRUN_SYMBOL or 
        symbolType == self.SYMBOL_ROCK_SYMBOL then
        return true
    end
    return false



end

function CodeGameScreenZeusMachine:hideLongRunKuang( reelCol ,istriggerBonus )

    for iCol = 1,#self.m_reelRunAnima do

        if iCol <= reelCol  then

            -- local runTop = self.m_RunTop[iCol]

            -- if runTop:isVisible() then
            --     if reelCol ~= 5 or istriggerBonus then
            --         if not self:checkOneReelsSymbol( iCol,TAG_SYMBOL_TYPE.SYMBOL_SCATTER ) then
            --             runTop:playAction("end",false,function(  )
            --                 runTop:setVisible(false)
            --             end)
            --         end
            --     else

            --         runTop:playAction("end",false,function(  )
            --             runTop:setVisible(false)
            --         end)
    
                    
            --     end
                
                
            -- end
    

            local rundi = self.m_RunDi[iCol]
            if rundi:isVisible() then
                if reelCol ~= 5 or istriggerBonus then
                    if not self:checkOneReelsSymbol( iCol,TAG_SYMBOL_TYPE.SYMBOL_SCATTER ) then
                        rundi:playAction("end",false,function(  )
                            rundi:setVisible(false)
                        end)
                    end
                else
         
                    rundi:playAction("end",false,function(  )
                        rundi:setVisible(false)
                    end)

         
                    
                end
                
                
            end
        end

    end

end

function CodeGameScreenZeusMachine:showLongRunKuang( macCol)
    
    for iCol = 1, self.m_iReelColumnNum, 1 do
        
        if iCol < macCol then
            if self:checkOneReelsSymbol( iCol,TAG_SYMBOL_TYPE.SYMBOL_SCATTER ) then

                local rundi = self.m_RunDi[iCol]

                if rundi and not rundi:isVisible() then
                    rundi:setVisible(true)
                    rundi:playAction("open",true)
                end
        
                -- local runTop = self.m_RunTop[iCol]
        
                -- if runTop and not runTop:isVisible() then
                --     runTop:setVisible(true)
                --     runTop:playAction("open",true)
                -- end
            end

        elseif iCol == macCol then
            local rundi = self.m_RunDi[iCol]

            if rundi and not rundi:isVisible() then
                rundi:setVisible(true)
                rundi:playAction("open",true)
            end
    
            -- local runTop = self.m_RunTop[iCol]
    
            -- if runTop and not runTop:isVisible() then
            --     runTop:setVisible(true)
            --     runTop:playAction("open",true)
            -- end
        end
        

        

    end
end


function CodeGameScreenZeusMachine:checkOneReelsSymbol( iCol,symbolType )
    

    for iRow = 1, self.m_iReelRowNum do
        
        if self.m_runSpinResultData.p_reels[iRow][iCol] == symbolType  then 
            return true
        end

    end 


    return false
end

function CodeGameScreenZeusMachine:getOneSymboliColList( symbolType )

    local ScatteriColList = {}

    for iCol = 1, self.m_iReelColumnNum, 1 do
        for iRow = 1, self.m_iReelRowNum do
        
            if self.m_runSpinResultData.p_reels[iRow][iCol] == symbolType  then 
                table.insert( ScatteriColList, iCol )
            end
    
        end 
    end

    return ScatteriColList
    
end

---
--添加金边
function CodeGameScreenZeusMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
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

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)

    self:showLongRunKuang( col)

end

--
--单列滚动停止回调
--
function CodeGameScreenZeusMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1)
    and
    (self:getGameSpinStage( ) ~= QUICK_RUN
    or self.m_hasBigSymbol == true
    )
    then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound( reelCol) then
            local reelStopName = "ZeusSounds/music_Zeus_Reels_Stop_".. reelCol ..".mp3"
            gLobalSoundManager:playSound(reelStopName)
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        local reelStopName = "ZeusSounds/music_Zeus_Reels_Stop_".. reelCol ..".mp3"
        gLobalSoundManager:playSound(reelStopName)
    end



    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end
    

    local istriggerBonus = false
    local feature = self.m_runSpinResultData.p_features
    if feature and #feature > 1 and feature[2] == 5 then
        if not self:BaseMania_isTriggerCollectBonus() then
            istriggerBonus = true
        end
        
    end
    --最后列滚完之后隐藏长滚
    self:hideLongRunKuang( reelCol ,istriggerBonus )
   

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end


    

    local isplay= true
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        for iRow = 1, self.m_iReelRowNum do

            local node = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, iRow, SYMBOL_NODE_TAG))

            if node and node.p_symbolType then
                if self:isFixSymbol(node.p_symbolType) then
                    isHaveFixSymbol = true

                    node:runAnim("buling")
                end 
            end
            
        end
        if isHaveFixSymbol == true and isplay then
            isplay = false

                local soundPath = "ZeusSounds/music_Zeus_Bonus_Down.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

        end
    end
   
end

function CodeGameScreenZeusMachine:slotReelDown( )
    BaseFastMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
      
end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenZeusMachine:levelFreeSpinEffectChange()

    
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenZeusMachine:levelFreeSpinOverChangeEffect()

    
    
end
---------------------------------------------------------------------------

function CodeGameScreenZeusMachine:showFreeSpinStart(num,func)


    local freespindata =  self.m_runSpinResultData.p_fsExtraData or {}
    local wildTimes =  freespindata.wilds or 0

    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["WildNum"]=wildTimes
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenZeusMachine:showFreeSpinMore(num,func,isAuto)

    local function newFunc()
        self:resetMusicBg(true)  
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local freespindata =  self.m_runSpinResultData.p_fsExtraData or {}
    local wildTimes =  freespindata.wilds or 0

    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["WildNum"]=wildTimes

    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE,ownerlist,newFunc,BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE,ownerlist,newFunc)
    end
end



-- 触发freespin时调用
function CodeGameScreenZeusMachine:showFreeSpinView(effectData)

    
    self.isInBonus = true



    local showFreeSpinView = function ( ... )

        

        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("ZeusSounds/music_Zeus_OpenView.mp3")
            
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)

            local node=view:findChild("WildNum")
            view:updateLabelSize({label=node,sx=0.8,sy=0.8},107)

        else
            -- local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                self:freespinStartShowGuoChang( function(  )

                    self:findChild("root_zeusMan"):setVisible(false)

                    self:changeGameBG( true )

                    self:findChild("jackpot"):setVisible(false)

                    util_spinePlay(self.m_ZeusMan,"idleframe2",true)

                    self.m_CollectBar:setVisible(false)

                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect() 
                end,function(  )

                    

                end )

                      
            -- end)
            -- local node=view:findChild("WildNum")
            -- view:updateLabelSize({label=node,sx=0.8,sy=0.8},107)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            showFreeSpinView()    
    end,0)

end


---
--判断改变freespin的状态
function CodeGameScreenZeusMachine:changeFreeSpinModeStatus()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER

                for i=#self.m_vecSymbolEffectType,1,-1 do
                    local EffectType = self.m_vecSymbolEffectType[i]
                    if EffectType == GameEffect.EFFECT_BONUS then
                        table.remove( self.m_vecSymbolEffectType, i)
                    end
                end
            end
        end

    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
        end
    end

end

-- 触发freespin结束时调用
function CodeGameScreenZeusMachine:showFreeSpinOverView()
    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setVisible(false)
    end
    
   gLobalSoundManager:playSound("ZeusSounds/music_Zeus_overView.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

            self:featureOverAddBonusEffect( )

            self:showFreespinoverGuoChang( function(  )

                if self.m_touchSpinLayer then
                    self.m_touchSpinLayer:setVisible(true)
                end
                

                self:findChild("jackpot"):setVisible(true)
                self:changeGameBG(  )

                -- 调用此函数才是把当前游戏置为freespin结束状态
                self:triggerFreeSpinOverCallFun()

                self.m_CollectBar:setVisible(true)
                self.m_light_left:runCsbAction("idleframe",true)
                self.m_light_reight:runCsbAction("idleframe",true)
            end )
        

    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},493)

end

function CodeGameScreenZeusMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodeZeusSrc.ZeusJackPotWinView")
    
    self:showSelfUI( jackPotWinView )

    self.m_topUI.m_isNotCanClick = true

    local curCallFunc = function(  )
        if self.m_touchSpinLayer then
            self.m_touchSpinLayer:setVisible(true) 
        end
        
        self.m_topUI.m_isNotCanClick = false
        if func then
            func()
        end
    end

    jackPotWinView:initViewData(self,index,coins,curCallFunc)
end

-- 结束respin收集
function CodeGameScreenZeusMachine:playLightEffectEnd()
    
    performWithDelay(self,function(  )
        
        self:showRespinOverView() 

    end,1)
    

    

end

function CodeGameScreenZeusMachine:getNetWinCoins( index )
    
    local winLines = self.m_runSpinResultData.p_winLines or {}

    for i=1,#winLines do

        local lines = winLines[i]
        if lines.p_iconPos[1] == index  then

            return lines.p_amount
            
        end
        
    end


end

function CodeGameScreenZeusMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum)  then
            -- 如果全部都固定了，会中JackPot档位中的Grand
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local grandWinCoins = selfdata.grandWinCoins or 0

            local jackpotScore = grandWinCoins
            self.m_lightScore = self.m_lightScore + jackpotScore

            self:showRespinJackpot(
                1,
                jackpotScore,
                function()
                    -- self.m_respinEndActiom:setVisible(true)
                    -- self.m_respinEndActiom:runCsbAction("actionframe",false,function(  )
                    --     self.m_respinEndActiom:setVisible(false)
                    -- end)


                    self.m_respinWinBar:runCsbAction("chufa")
                    self.m_respinWinBar:findChild("BitmapFontLabel_1"):setString(util_getFromatMoneyStr(self.m_lightScore))
                    local node = self.m_respinWinBar:findChild("BitmapFontLabel_1")
                    self.m_respinWinBar:updateLabelSize({label=node,sx=1,sy=1},509)

                    -- self.m_bottomUI.m_normalWinLabel:setString(util_getFromatMoneyStr(self.m_lightScore))


                    -- 此处跳出迭代
                    self:playLightEffectEnd()        
                end
            )
        else
            -- 此处跳出迭代
            self:playLightEffectEnd()
        
        end
        return 
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = self:getPosReelIdx(iRow ,iCol)

    -- 根据网络数据获得当前固定小块的分数
    local score = self:getNetWinCoins( nFixIdx ) 
    
    local lockSymbolType = self:getLockSymbolType( nFixIdx , chipNode.p_symbolType )

    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = 1 --globalData.slotRunData:getCurTotalBet()
    
    if score ~= nil and lockSymbolType ~= nil then
        if lockSymbolType == "Coins" then
            addScore = score * lineBet
        elseif lockSymbolType == "Grand" then
            jackpotScore = score
            addScore = jackpotScore + addScore
            nJackpotType = 1
        elseif lockSymbolType == "Major" then
            jackpotScore = score
            addScore = jackpotScore + addScore
            nJackpotType = 2
        elseif lockSymbolType == "Minor" then
            jackpotScore =  score
            addScore =jackpotScore + addScore                  
            nJackpotType = 3
        elseif lockSymbolType == "Mini" then
            jackpotScore = score
            addScore =  jackpotScore + addScore                      
            nJackpotType = 4
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function runCollect()
        if chipNode.p_symbolType == self.SYMBOL_MIDRUN_SYMBOL then

            if chipNode.m_specialRunUI then

                local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                local spWheels = selfdata.spWheels
                local spWheelIndex = selfdata.spWheelIndex + 1
                
                -- 滚动停止
                local endData = {}
                endData.type = spWheels[spWheelIndex]
                if type(endData.type)  == "number" then
                    local lineBet = globalData.slotRunData:getCurTotalBet()
                    endData.score = lineBet * endData.type
                end
                chipNode.m_specialRunUI:setOverCallBackFun(function(  )
                    -- self:playChipCollectAnim() 
                end)
                chipNode.m_specialRunUI:setEndValue(endData)

                gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Bonus_mid_fangda.mp3")
                
                self:runMidNodeRewordAct(chipNode ,function(  )

                    

                    -- self.m_respinEndActiom:setVisible(true)
                    -- self.m_respinEndActiom:runCsbAction("actionframe",false,function(  )
                    --     self.m_respinEndActiom:setVisible(false)
                    -- end)
                    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_BonusJieSuan.mp3")

                    performWithDelay(self,function(  )
                        self.m_respinWinBar:runCsbAction("chufa")
                        self.m_respinWinBar:findChild("BitmapFontLabel_1"):setString(util_getFromatMoneyStr(self.m_lightScore))
                        local node = self.m_respinWinBar:findChild("BitmapFontLabel_1")
                        self.m_respinWinBar:updateLabelSize({label=node,sx=1,sy=1},509)

                        -- self.m_bottomUI.m_normalWinLabel:setString(util_getFromatMoneyStr(self.m_lightScore))
                    end,8/30)
                    

                    chipNode:runAnim("shouji")

                    self:runRespinCollectFlyAct(chipNode,self:findChild("respinoverWin"),"Socre_Zeus_Shouji",function(  )


                        if type(endData.type)  == "number"then
                    
                    
                            self.m_playAnimIndex = self.m_playAnimIndex + 1
                            self:playChipCollectAnim() 
                        else

                            self:showRespinJackpot(nJackpotType, jackpotScore , function()
                                self.m_playAnimIndex = self.m_playAnimIndex + 1
                                self:playChipCollectAnim() 
                            end)
                        
                        end
                        
                        
                    end,80)

                    
                end )

                
            end
            


        else

            gLobalSoundManager:playSound("ZeusSounds/music_Zeus_BonusJieSuan.mp3")

            if chipNode.p_symbolType == self.SYMBOL_ROCK_SYMBOL then
                chipNode:runAnim("shouji")
            else
                chipNode:runAnim("shouji")
            end
            

            self:runRespinCollectFlyAct(chipNode,self:findChild("respinoverWin"),"Socre_Zeus_Shouji",function(  )
                

            end,80)

            local waitNdoe = cc.Node:create()
            self:addChild(waitNdoe)
            performWithDelay(waitNdoe,function(  )

                self.m_respinWinBar:runCsbAction("chufa")
                self.m_respinWinBar:findChild("BitmapFontLabel_1"):setString(util_getFromatMoneyStr(self.m_lightScore))
                local node = self.m_respinWinBar:findChild("BitmapFontLabel_1")
                self.m_respinWinBar:updateLabelSize({label=node,sx=1,sy=1},509)

                if nJackpotType == 0 then
                    
                    self.m_playAnimIndex = self. m_playAnimIndex + 1
                    self:playChipCollectAnim() 
                else
                    self:showRespinJackpot(nJackpotType, jackpotScore , function()
                        self.m_playAnimIndex = self.m_playAnimIndex + 1
                        self:playChipCollectAnim() 
                    end)
                
                end

                waitNdoe:removeFromParent()
            end,0.4)

           
        end
        
    end
    
    

    runCollect()  

    
end



--结束移除小块调用结算特效
function CodeGameScreenZeusMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()
    
    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Respin_end.mp3")

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    performWithDelay(self,function(  )
        self.m_JackPotView:findChild("Panel_1"):setVisible(true)

        gLobalSoundManager:playSound("ZeusSounds/music_Zeus_OpenView.mp3")

        self.m_respinWinBar:findChild("BitmapFontLabel_1"):setString("")
        self.m_respinWinBar:setVisible(true)
        self.m_respinWinBar:runCsbAction("open",false,function(  )
            
            self:playChipCollectAnim()
            
        end)
        
    end,1.5)
    
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenZeusMachine:getRespinRandomTypes( )
    local symbolList = { TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenZeusMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_MIDRUN_SYMBOL, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_ROCK_SYMBOL, runEndAnimaName = "", bRandom = true},
    }

    return symbolList
end

function CodeGameScreenZeusMachine:showRespinView()

    self.isInBonus = true


    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    --先播放动画 再进入respin
    self:clearCurMusicBg()

    -- gLobalSoundManager:playSound("ZeusSounds/music_Zeus_respin_Trigger.mp3")

    performWithDelay(self,function(  )
        for iCol = 1, self.m_iReelColumnNum do

            for iRow = 1, self.m_iReelRowNum do
    
                local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
        
                if node and node.p_symbolType then
                    if self:isFixSymbol(node.p_symbolType) then
        
                        node:runAnim("actionframe1",true)
                    end 
                end
                
            end
    
        end
    end,0.05)
    
    
      


    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_respin_Trigger_daling.mp3")

    performWithDelay(self,function(  )
        self:showGuoChang( function(  )


            self.m_bottomUI:checkClearWinLabel()
    
            self:changeGameBG( true )
    
            self.m_light_left:runCsbAction("lighting",true)
            self.m_light_reight:runCsbAction("lighting",true)
    
            local nameList = {"jindutiao","Zeus_jackPoTip"}
    
            for i=1,#nameList do
                local node = self:findChild(nameList[i])
                if node then
                    node:setVisible(false)
                end 
            end
    
            self.m_RespinBar = util_createView("CodeZeusSrc.RespinBar.ZeusRespinTopBarView",self)
            self:findChild("Respin"):addChild(self.m_RespinBar)

            if globalData.slotRunData.machineData.p_portraitFlag then
                self.m_RespinBar.getRotateBackScaleFlag = function(  ) return false end
            end


            self.m_RespinBar:runCsbAction("idle",true)

            self.m_JackPotView:runCsbAction("big",true)
            
            self.m_RespinBar:runCsbAction("wait")
            

            --可随机的普通信息
            local randomTypes = self:getRespinRandomTypes( )
                        
            --可随机的特殊信号 
            local endTypes = self:getRespinLockTypes()

            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)

            
        end ,function(  )
            self:findChild("root_zeusMan"):setVisible(false)
        end )
    
    end,4)
        

    
    
end

function CodeGameScreenZeusMachine:initRespinView(endTypes, randomTypes)

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
            local nodelist = self.m_respinView:getAllCleaningNode()
            for i=1,#nodelist do
                local lockNode = nodelist[i]
                local reelIdx = self:getPosReelIdx(lockNode.p_rowIndex, lockNode.p_cloumnIndex)
                if lockNode.p_symbolType == self.SYMBOL_ROCK_SYMBOL then
                    if not  self:isInRockPosList(  reelIdx ) then
                        lockNode:runAnim("actionframe2",true)
                    else
                        lockNode:runAnim("actionframe1",true) 
                    end
                else

                    lockNode:runAnim("actionframe1",true)   
                end
                
            end

            

            self:reSpinEffectChange()
            self:playRespinViewShowSound()

            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)


            -- gLobalSoundManager:playSound("ZeusSounds/music_Zeus_OpenView.mp3")

            self:showReSpinStart(
            function()


                gLobalSoundManager:playSound("ZeusSounds/music_Zeus_respinbar_Start_Act.mp3")

                -- m_RespinBar 动画
                self.m_respin_LiuGuang_1:setVisible(true)
                self.m_respin_LiuGuang_1:runCsbAction("idle",false,function(  )
                    self.m_respin_LiuGuang_1:setVisible(false)
                end)

                self.m_respin_LiuGuang_2:setVisible(true)
                self.m_respin_LiuGuang_2:runCsbAction("idle",false,function(  )
                    self.m_respin_LiuGuang_2:setVisible(false)
                end)

                performWithDelay(self,function(  )
                    self.m_RespinBar:runCsbAction("start",false,function(  )
                        self.m_RespinBar:runCsbAction("idle",true)
                        -- 更改respin 状态下的背景音乐
                        self:changeReSpinBgMusic()

                        performWithDelay(self,function(  )
                            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                            self.m_rocketPositions = selfdata.rocketPositions 
                    
                            if self.m_rocketPositions then
                    
                                self.m_reSpinReelStartCallFunc = function(  )
                
                                    self:runNextReSpinReel()
                    
                                    self.m_reSpinReelStartCallFunc = nil
                                end
                    
                                self.m_actIndex = 0
                                self:runRocketFly(  )
                            else
                                self:runNextReSpinReel()
                            end
                        end,1)
                            
                    end)


                end,13 / 30)


                
            end)
            

        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

function CodeGameScreenZeusMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setVisible(false) 
    end
    
    if self.m_choiceRespinGame then
        self.m_choiceRespinGame = false
        if func then
            func()
        end

    else


        local ccbName = BaseDialog.DIALOG_TYPE_RESPIN_START
        local ownerlist = nil
        self.m_topUI.m_isNotCanClick = true

        local curCallFunc = function(  )
            if self.m_touchSpinLayer then
                self.m_touchSpinLayer:setVisible(true)
            end
            
            self.m_topUI.m_isNotCanClick = false
            if func then
                func()
            end
        end

        local view=util_createView("CodeZeusSrc.ZeusBaseDialog")
        view:initViewData(self,ccbName,curCallFunc,nil,nil,nil)
        view:updateOwnerVar(ownerlist)
        self:findChild("bonusViewNode"):addChild(view)

        if globalData.slotRunData.machineData.p_portraitFlag then
            view.getRotateBackScaleFlag = function(  ) return false end
        end

        --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
    end
    
end

--ReSpin开始改变UI状态
function CodeGameScreenZeusMachine:changeReSpinStartUI(respinCount)
    self.m_respinSpinbar:setVisible(true)
    self.m_respinSpinbar:changeRespinTimes(respinCount,true)
end

--ReSpin刷新数量
function CodeGameScreenZeusMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_respinSpinbar:changeRespinTimes(curCount)
   
end

--ReSpin结算改变UI状态
function CodeGameScreenZeusMachine:changeReSpinOverUI()
    self.m_respinSpinbar:setVisible(false)
end

function CodeGameScreenZeusMachine:showRespinOverView(effectData)


    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_overView.mp3")

    self.m_bottomUI.m_normalWinLabel:setString(util_getFromatMoneyStr(self.m_serverWinCoins))

    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()

        self:featureOverAddBonusEffect( )

        

        self:findChild("root_zeusMan"):setVisible(false)
        self:findChild("root_zeusMan"):setLocalZOrder(5)
        self:showGuoChang( function(  )


            self.m_JackPotView:findChild("Panel_1"):setVisible(false)

            self.m_respinWinBar:setVisible(false)

            self.m_JackPotView:runCsbAction("small",true)

            self:changeGameBG(  )

            self:setReelSlotsNodeVisible(true)
            -- 更新游戏内每日任务进度条 -- r
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
            self:removeRespinNode()

            self.m_choiceTriggerRespin = false
            self.m_chooseRepin = false
            self.m_choiceRespinGame = false
            
            
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg() 

            self.m_light_left:runCsbAction("idleframe",true)
            self.m_light_reight:runCsbAction("idleframe",true)

            self.m_RespinBar:removeFromParent()
            self.m_RespinBar = nil

            self:hideAllReelsNode( true )
        end , nil , true )

     
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)
end


-- --重写组织respinData信息
function CodeGameScreenZeusMachine:getRespinSpinData()
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


---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenZeusMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_bonusCollectWin = false

    self.isInBonus = false

    self.m_Zeus_jackPoTip:closeTip( )

    self.m_light_left:runCsbAction("idleframe",true)
    self.m_light_reight:runCsbAction("idleframe",true)

    self:setMaxMusicBGVolume( )
    self:removeSoundHandler( )

    return false -- 用作延时点击spin调用
end




function CodeGameScreenZeusMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("ZeusSounds/music_Zeus_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenZeusMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()


    if self:checkCanClickJackpotTip( ) then
        self.m_Zeus_jackPoTip:setVisible(true)
        self.m_Zeus_jackPoTip:runCsbAction("open",false,function(  )
            self.m_Zeus_jackPoTip:runCsbAction("idle")
            performWithDelay(self.m_Zeus_jackPoTip,function(  )
                self.m_Zeus_jackPoTip:runCsbAction("over",false,function(  )
                    self.m_Zeus_jackPoTip:setVisible(false)
                end)
            end,1.5)
        end)
    end

end

function CodeGameScreenZeusMachine:addObservers()
	BaseFastMachine.addObservers(self)

end

function CodeGameScreenZeusMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end



-- ------------玩法处理 -- 

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenZeusMachine:MachineRule_network_InterveneSymbolMap()

end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenZeusMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据
    
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenZeusMachine:addSelfEffect()

    self.m_collectList = {}
    if  globalData.slotRunData.currSpinMode ~= RESPIN_MODE and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
       
        if not self.m_chooseRepinNotCollect then
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = self.m_iReelRowNum, 1, -1 do
                    local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    if node then
                        if self:isFixSymbol(node.p_symbolType) then
                            if node.p_symbolType ~= self.SYMBOL_MIDRUN_SYMBOL  then
                                self.m_collectList[#self.m_collectList + 1] = node
                            end
                            
                        end
                    end
                end
            end
        end

        if self.m_chooseRepinNotCollect then
            self.m_chooseRepinNotCollect = false
        end
        
    end 

    if self.m_collectList and #self.m_collectList > 0 then

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FLY_COIN_EFFECT

    end

    self.m_triggerShowCollectView = false

     --是否触发收集小游戏(这里的判断条件不对)
    if self:BaseMania_isTriggerCollectBonus() then 

        self.m_triggerShowCollectView = true

    end

end

function CodeGameScreenZeusMachine:BaseMania_isTriggerCollectBonus()
    
    --(这里的判断条件不对，需要判断是否是 触发的收集bonus，因为选择也是用bonus触发)
    local features = self.m_runSpinResultData.p_features
    if features and features[2] and features[2] == 5 then

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusTypes =  selfdata.bonusTypes

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            if self:getCurrSpinMode() ~= RESPIN_MODE then
                if bonusTypes and bonusTypes[1] == "collect"  then
                    return true
                end
            end
            
        end
          
    end

end

function CodeGameScreenZeusMachine:getBonusCollectData( )

    local data = nil
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {} 
    local collectNetData = selfdata.collect
    if collectNetData then
        data = collectNetData
    end

    return data 

end

function CodeGameScreenZeusMachine:getProgress(collect)

    local collectTarget = collect.collectTarget
    local collects = collect.collects

    local percent =  collects / collectTarget * 100

    return percent
end


function CodeGameScreenZeusMachine:collectCoin(effectData)

    local flyTimes = 0.5


    local pecent = 0
    local collectData =  self:getBonusCollectData( )
    if collectData and type(collectData) == "table" then

        pecent = self:getProgress(collectData) or 0
    end


    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Collect_begin.mp3")

    for i = 1 ,#self.m_collectList do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:findChild("root_Act"):convertToNodeSpace(startPos)

        local CsbName = "Socre_Zeus_Light_fly2.csb"
        if node.p_symbolType  == self.SYMBOL_ROCK_SYMBOL then
            
            CsbName = "Socre_Zeus_Light_fly2.csb"
        end

        local coins =  util_createAnimation(CsbName) 
        coins:findChild("m_lb_score"):setString("")
        coins:findChild("m_lb_score_0"):setString("")

        

        if node.p_symbolType  ~= self.SYMBOL_ROCK_SYMBOL then

            -- local score = self:getReSpinSymbolScore(self:getPosReelIdx(node.p_rowIndex , node.p_cloumnIndex )) --获取分数（网络数据）

            -- self:findChildDealHightLowScore( coins, score )

            -- coins:findChild("m_lb_score"):setString(node:getCcbProperty("m_lb_score"):getString())
            -- coins:findChild("m_lb_score_0"):setString(node:getCcbProperty("m_lb_score"):getString())
        end

        
        coins:setPosition(newStartPos)
        self:findChild("root_Act"):addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)

        local endPos = cc.p(util_getConvertNodePos(self.m_CollectBar:findChild("collect_act"),coins))   
        coins:setVisible(false)

        

        -- node:runAnim("collect")
        -- performWithDelay(self,function(  )

            local Particle_1 = coins:findChild("Particle_1")

            if Particle_1 then
                Particle_1:setPositionType(0)
                Particle_1:setDuration(flyTimes * 2)
            end
            local Particle_2 = coins:findChild("Particle_2")
            if Particle_2 then
                Particle_2:setPositionType(0)
                Particle_2:setDuration(flyTimes * 2)
            end

            coins:setVisible(true)
            coins:playAction("collect")
            local actionList = {}
            actionList[#actionList + 1] =  cc.CallFunc:create(function(  )
            
                local actionList_1 = {}
                actionList_1[#actionList_1 + 1] =  cc.ScaleTo:create(flyTimes,0.6)
                local sq_1 = cc.Sequence:create(actionList_1)
                coins:findChild("Node_1"):runAction(sq_1)

            end)

            local pecent2 = pecent

            local BezierPos = {newStartPos, cc.p(endPos.x, newStartPos.y), endPos}
            actionList[#actionList + 1] =  cc.BezierTo:create(flyTimes, BezierPos)
            if i == 1 then
                actionList[#actionList + 1] =  cc.CallFunc:create(function(  )

                    
                    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Collect_end.mp3")
                    
                    self.m_CollectBar:runCsbAction("collect")

                    local pecent1 = pecent2

                    scheduler.performWithDelayGlobal(function (  )
                        self.m_CollectBar:updatePercent(pecent1)
                        
                    end,0.5,self:getModuleName())
                    
                end)
            end
            actionList[#actionList + 1]  = cc.CallFunc:create(function()

                coins:findChild("Node_1"):setVisible(false)

            end)

            actionList[#actionList + 1] = cc.DelayTime:create(flyTimes)
            actionList[#actionList + 1]  = cc.CallFunc:create(function()

                coins:stopAllActions()
                coins:removeFromParent()

            end)

            local sq = cc.Sequence:create(actionList)
            coins:runAction(sq)
        -- end,0.5)
        

        
    end

    if not self.m_triggerShowCollectView then

       -- performWithDelay(self,function(  )

            effectData.p_isPlay = true
            self:playGameEffect()
        --end,1.5 )  -- 播放完小块开始收集动画

    else

        performWithDelay(self,function(  )

            
            if pecent and pecent >= 100 then

                self:clearCurMusicBg()

                gLobalSoundManager:playSound("ZeusSounds/bonus_trigger_sound.mp3")
                
                self.m_CollectBar:runCsbAction("jiman",false,function(  )

                    if self.m_triggerShowCollectView then

                        gLobalSoundManager:playSound("ZeusSounds/bonus_trigger_2_sound.mp3")

                        performWithDelay(self,function(  )
                            effectData.p_isPlay = true
                            self:playGameEffect() 
                        end,1.5)

                        
                    end
                
                end)

            else
                if self.m_triggerShowCollectView then
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end
            

            
    
        end,flyTimes + 1.5 + 1.5  )  -- 加上进度条收集动画时间 ,播放完小块动画
        
        

    end

   

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenZeusMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.FLY_COIN_EFFECT then

        -- performWithDelay(self,function(  ) -- 落地播完在收集
            self:collectCoin(effectData)      
        -- end,0.25)
         
    end
    
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenZeusMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenZeusMachine:showDialog(ccbName,ownerlist,func,isAuto,index,soundName)


    self.m_topUI.m_isNotCanClick = true

    local curCallFunc = function(  )
        if self.m_touchSpinLayer then
            self.m_touchSpinLayer:setVisible(true) 
        end
        
        self.m_topUI.m_isNotCanClick = false
        if func then
            func()
        end
    end

    local view=util_createView("CodeZeusSrc.ZeusBaseDialog")
    view:initViewData(self,ccbName,curCallFunc,isAuto,index,soundName)
    view:updateOwnerVar(ownerlist)

    self:showSelfUI( view )


    
   
    return view
end

function CodeGameScreenZeusMachine:showSelfUI( View,zorder  )
    local centerYPos = display.height / 2
    local addZorder = -1
    if zorder then
        addZorder = zorder
    end
    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setVisible(false)
    end
    
    self:findChild("root_0"):addChild(View,addZorder)
    
    if globalData.slotRunData.machineData.p_portraitFlag then
        View.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = View })

    

    local addPosY = 0
    -- if display.height > 1535 then
    --     addPosY =  17 
    -- elseif display.height < 1121 then
    --     addPosY = 25 
    -- else
    --     addPosY = 15 
    -- end

    local wordPos= cc.p(0,centerYPos + addPosY)
    local curPos= cc.p(self:findChild("root_0"):convertToNodeSpace(wordPos)) 

    View:setPositionX(0)
    View:setPositionY( (curPos.y ) - (DESIGN_SIZE.height / 2) - ((display.height - DESIGN_SIZE.height)/2) )  



end

function CodeGameScreenZeusMachine:waitshowLines( func )
    
    local lines = self.m_reelResultLines
    local waitTimes = 0
    if lines ~= nil and #lines > 0 then

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = self.m_serverWinCoins / totalBet
        if winRate <= 0 then
            
            waitTimes = 0
        elseif winRate <= 1 then
            waitTimes = 1.7
        elseif winRate > 1 and winRate <= 3 then
            waitTimes = 1.7
        elseif winRate > 3 and winRate <= 6 then
            waitTimes = 3
        elseif winRate > 6 then
            waitTimes = 3
        end
        
    end


    performWithDelay(self,function(  )
        
        if func then
            func()
        end
    end,waitTimes)
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenZeusMachine:showEffect_Bonus(effectData)

    self.isInBonus = true
    
    self:waitshowLines( function(  )

        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
            self.m_questView:hideQuestView()
        end
    
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearFrames_Fun()
        self:clearWinLineEffect()
    
        -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
        local lineLen = #self.m_reelResultLines
        local bonusLineValue = nil
        for i=1,lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                bonusLineValue = lineValue
                table.remove(self.m_reelResultLines,i)
                break
            end
        end
    
        self.m_light_left:runCsbAction("lighting",true)
        self.m_light_reight:runCsbAction("lighting",true)
    
        -- 停止播放背景音乐
        self:clearCurMusicBg()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        -- 播放bonus 元素不显示连线
        if bonusLineValue ~= nil then
    
            self:showBonusAndScatterLineTip(bonusLineValue,function()
                self:showBonusGameView(effectData)
            end)
            bonusLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue
    
            -- 播放提示时播放音效
            self:playBonusTipMusicEffect()
        else
            self:showBonusGameView(effectData)
        end
    
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    end )

    


    return true
end

---
-- 根据Bonus Game 每关做的处理
--

function CodeGameScreenZeusMachine:showBonusGameView( effectData )
   

    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end


    self.m_bottomUI:checkClearWinLabel()


    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTypes =  selfdata.bonusTypes
    if bonusTypes and bonusTypes[1] then

        if bonusTypes[1] == "free"  then
            performWithDelay(self,function(  )
                
                
                gLobalSoundManager:playSound("ZeusSounds/music_Zeus_showChooseView.mp3")
                self:hideLongRunKuang( 5 )
                self:show_Choose_BonusGameView(effectData)
            end,1)
            

        elseif bonusTypes[1] == "collect"  then

            self:showCollectView( effectData  ) 
            
        end
    end


end

function CodeGameScreenZeusMachine:show_Choose_BonusGameView(effectData)
    

    self.m_topUI.m_isNotCanClick = true

    self.m_chooseView = util_createView("CodeZeusSrc.ZeusChooseView",self)
    -- self:showSelfUI( chooseView )

    self:findChild("bonusViewNode"):addChild(self.m_chooseView)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_chooseView.getRotateBackScaleFlag = function(  ) return false end
    end

    self.m_chooseView:setEndCall( function( selectId ) 


        self.m_topUI.m_isNotCanClick = false

        if selectId == selectRespinId then
            self.m_iFreeSpinTimes = 0 
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0      
            self.m_bProduceSlots_InFreeSpin = false

            self.m_choiceTriggerRespin  = true
            self.m_chooseRepin = true
            self.m_chooseRepinGame = true --选择respin
            self.m_chooseRepinNotCollect = true

            self.m_choiceRespinGame = true

            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮

            if self.m_chooseView then
                self.m_chooseView:removeFromParent()
    
                self.m_chooseView = nil
            end

        else
            self:bonusOverAddFreespinEffect( )
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
            
        end
        

    end)

    
    
end

function CodeGameScreenZeusMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()
    
    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型
    
    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
    self:getCurrSpinMode() ~= RESPIN_MODE and
    not self.m_choiceTriggerRespin
    then

        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()

    self.m_choiceTriggerRespin = false

    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)


end

function CodeGameScreenZeusMachine:callSpinBtn()

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_startSpinTime = nil
        end
    end

    
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToAutospinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToAutospinReelRunLen()
            end
        end
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE  then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToFreespinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToFreespinReelRunLen()
            end
        end
    end


    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    self:notifyClearBottomWinCoin()

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or toLongNumber(1)


    -- freespin时不做钱的计算
    if not self.m_choiceTriggerRespin and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and betCoin > totalCoin then
        --金币不足
        -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
        gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
        -- cxc 2023-12-05 15:57:06 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
        local checkOperaGuidePop = function()
            if tolua.isnull(self) then
                return
            end
            
            local betCoin = self:getSpinCostCoins() or toLongNumber(0)
            local totalCoin = globalData.userRunData.coinNum or 1
            if betCoin <= totalCoin then
                globalData.rateUsData:resetBankruptcyNoPayCount()
                self:showLuckyVedio()
                return
            end

            -- cxc 2023年12月02日13:57:48 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
            globalData.rateUsData:addBankruptcyNoPayCount()
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Bankruptcy", "BankruptcyNoPay_" .. globalData.rateUsData:getBankruptcyNoPayCount())
            if view then
                view:setOverFunc(util_node_handler(self, self.showLuckyVedio))
            else
                self:showLuckyVedio()
            end
        end
        gLobalPushViewControl:setEndCallBack(checkOperaGuidePop)
     
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
        end

    else
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
            self:getCurrSpinMode() ~= RESPIN_MODE and not self.m_choiceTriggerRespin
         then
            self:callSpinTakeOffBetCoin(betCoin)
            print("callSpinBtn  点击了spin14")
        else
            self.m_spinNextLevel = globalData.userRunData.levelNum
            self.m_spinNextProVal = globalData.userRunData.currLevelExper
            self.m_spinIsUpgrade = false
        end

        --统计quest spin次数
        self:staticsQuestSpinData()


        self:spinBtnEnProc()

        self:setGameSpinStage( GAME_MODE_ONE_RUN )

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)
        globalData.rateUsData:addSpinCount()

    end
    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end

function CodeGameScreenZeusMachine:playEffectNotifyNextSpinCall( )

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

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("ZeusSounds/Zeus_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("ZeusSounds/Zeus_spin.mp3")
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    elseif self.m_chooseRepin then
        gLobalSoundManager:playSound("ZeusSounds/Zeus_spin.mp3")
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end

end

function CodeGameScreenZeusMachine:setReelSlotsNodeParentVisible(status )
    for iCol = 1, self.m_iReelColumnNum do
        local slotParent = self:getReelParent(iCol)
        if slotParent then
            slotParent:setVisible(status)
        end
      
        local slotParentBig = self:getReelBigParent(iCol)
        if slotParentBig then

            slotParentBig:setVisible(status)
     
        end
    end
    if self.m_clipParentlds then
        self.m_clipParentlds:setVisible(status)
    end
end

function CodeGameScreenZeusMachine:hideAllReelsNode( states )
    
    local nameList = {"jackpot","root_zeusMan","Node_reel","Respin","Image_1","SpinRemaining","Node_reel_spin2","jindutiao","Zeus_jackPoTip"}

    for i=1,#nameList do
        local node = self:findChild(nameList[i])
        if node then
            node:setVisible(states)
        end 
    end

    self:setReelSlotsNodeParentVisible(states )
end

function CodeGameScreenZeusMachine:createCollectGameMainView( func )

    self:clearCurMusicBg()

    self:findChild("root_zeusMan"):setVisible(true)

    self:showGuoChang( function(  )

        self:resetMusicBg(nil,"ZeusSounds/music_Zeus_BonusCollectBg.mp3")

        self:changeGameBG( true )

        self:hideAllReelsNode( false )

        self.m_bonusCollectView = util_createView("CodeZeusSrc.BonusCollect.ZeusBonusMainView",self)
        self:findChild("bonusCollectView"):addChild(self.m_bonusCollectView)

        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_bonusCollectView.getRotateBackScaleFlag = function(  ) return false end
        end


        self.m_bonusCollectView:setEndCallFunc( function(  )


            self:updateLoadingBar( )

            self:hideAllReelsNode( true )

            if func then
                func()
            end

            self:resetMusicBg()

            self.m_bonusCollectView:removeFromParent()
            self.m_bonusCollectView = nil
        end)
    end ,function(  )
        self:findChild("root_zeusMan"):setVisible(false)
    end )


    
    
end

function CodeGameScreenZeusMachine:showFreespinStartrManShow(  )
    
    -- self:findChild("root_zeusMan"):setLocalZOrder(6)

    -- gLobalSoundManager:playSound("ZeusSounds/music_Zeus_GuoChang.mp3")

    self:findChild("root_zeusMan"):setVisible(true)

    util_spinePlay(self.m_ZeusMan,"actionframe2",false)

    performWithDelay(self,function(  )
        util_spinePlay(self.m_ZeusMan,"idleframe2",true)
    end,19/30)

end

function CodeGameScreenZeusMachine:showFreespinoverGuoChang( func ,func2 )
    
    -- self:findChild("root_zeusMan"):setLocalZOrder(6)

    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_GuoChang.mp3")

    util_spinePlay(self.m_ZeusMan,"actionframe4",false)

    util_spineFrameCallFunc(self.m_ZeusMan, "actionframe4", "Switch4", function(  )
        self.m_changeView:setVisible(true)
        self.m_changeView:runCsbAction("actionframe",false,function(  )
            self.m_changeView:setVisible(false)
        end)
        performWithDelay(self,function(  )
            if func then
                func()
            end
        end,8/30)
    end,function(  )

            if func2 then
                func2()
            end


                util_spinePlay(self.m_ZeusMan,"idleframe",true)
                self:findChild("root_zeusMan"):setLocalZOrder(3)

            

    end)

end

function CodeGameScreenZeusMachine:freespinStartShowGuoChang( func ,func2 , collectOver )
    
    -- self:findChild("root_zeusMan"):setLocalZOrder(6)

    -- if collectOver then
        
    --     gLobalSoundManager:playSound("ZeusSounds/music_Zeus_GuoChang_collectOver.mp3")
    -- else
    --     gLobalSoundManager:playSound("ZeusSounds/music_Zeus_GuoChang.mp3")
    -- end

    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_GuoChang_collectOver.mp3")
    
    -- self.m_ZeusMan:setVisible(false)
    util_spinePlay(self.m_ZeusMan,"actionframe",false)

    util_spineFrameCallFunc(self.m_ZeusMan, "actionframe", "Switch", function(  )

        -- self.m_ZeusMan:setVisible(true)

        self.m_changeView:setVisible(true)
        self.m_changeView:runCsbAction("actionframe",false,function(  )
            self.m_changeView:setVisible(false)
        end)
        performWithDelay(self,function(  )
            if func then
                func()
            end
        end,8/30)
    end,function(  )

            

            -- util_spinePlay(self.m_ZeusMan,"idleframe",true)
            self:findChild("root_zeusMan"):setLocalZOrder(3)

            if func2 then
                func2()
            end

    end)

end

function CodeGameScreenZeusMachine:showGuoChang( func ,func2, collectOver )
    
    -- self:findChild("root_zeusMan"):setLocalZOrder(6)

    if collectOver then
        
        gLobalSoundManager:playSound("ZeusSounds/music_Zeus_GuoChang_collectOver.mp3")
    else
        gLobalSoundManager:playSound("ZeusSounds/music_Zeus_GuoChang.mp3")
    end


    util_spinePlay(self.m_ZeusMan,"actionframe",false)

    util_spineFrameCallFunc(self.m_ZeusMan, "actionframe", "Switch", function(  )
        self.m_changeView:setVisible(true)
        self.m_changeView:runCsbAction("actionframe",false,function(  )
            self.m_changeView:setVisible(false)
        end)
        performWithDelay(self,function(  )
            if func then
                func()
            end
        end,8/30)
    end,function(  )

            

            util_spinePlay(self.m_ZeusMan,"idleframe",true)
            self:findChild("root_zeusMan"):setLocalZOrder(3)

            if func2 then
                func2()
            end

    end)

end

function CodeGameScreenZeusMachine:showBonusZeusHeroAct( func,func2)
    
    self:findChild("root_zeusMan"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1001)

    self.m_ZeusMan:setPositionY(230)

    if display.height > DESIGN_SIZE.height then
        local posY = (display.height - DESIGN_SIZE.height) * 0.5

        local node = self.m_ZeusMan
        if node then
            node:setPositionY(node:getPositionY() - posY )
        end
    end

    util_spinePlay(self.m_ZeusMan,"actionframe3",true)

    util_spineFrameCallFunc(self.m_ZeusMan, "actionframe3", "Switch2", function(  )
        self.m_changeView:setVisible(true)
        self.m_changeView:runCsbAction("actionframe",false,function(  )
            self.m_changeView:setVisible(false)
        end)
        performWithDelay(self,function(  )
            if func then
                func()
            end
        end,8/30)
    end,function(  )

        if func2 then
            func2()
        end
        self.m_ZeusMan:setPositionY(-140)
        util_spinePlay(self.m_ZeusMan,"idleframe",true)
        self:findChild("root_zeusMan"):setLocalZOrder(3)

        
    end)
end


function CodeGameScreenZeusMachine:showCollectView( effectData  )
    

    self.m_bonusCollectWin = true

    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Collect_Bonus_OpenView.mp3")

    self.m_bonusChooseView = nil

    local round = 0

    local collectData =  self:getBonusCollectData( )
    if collectData and type(collectData) == "table" then
        local progress = self:getProgress(collectData)
        if progress then
            self.m_CollectBar:setPercent(progress)
        end

        local roundId = collectData.collectRound
        if roundId then
            round = roundId
        end
        
    end

    if round == 0 then
        self.m_bonusChooseView = util_createView("CodeZeusSrc.BonusCollect.ZeusBonusChooseView_Two",self)
        
        self:findChild("bonusViewNode"):addChild(self.m_bonusChooseView)

        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_bonusChooseView.getRotateBackScaleFlag = function(  ) return false end
        end


    elseif round == 1 then
        self.m_bonusChooseView = util_createView("CodeZeusSrc.BonusCollect.ZeusBonusChooseView_Two",self)

        self:findChild("bonusViewNode"):addChild(self.m_bonusChooseView)

        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_bonusChooseView.getRotateBackScaleFlag = function(  ) return false end
        end

    
    elseif round == 2 then
        self.m_bonusChooseView = util_createView("CodeZeusSrc.BonusCollect.ZeusBonusChooseView_Three",self)
        if self.m_bonusChooseView then
            self:showSelfUI( self.m_bonusChooseView )
        end
    end

    

    self.m_topUI.m_isNotCanClick = true

    if round == 2 then
        
        self.m_bonusChooseView:setEndCallFunc(function(  )


        
            self.m_topUI.m_isNotCanClick = false

            self.m_bonusChooseView:removeFromParent()
            self.m_bonusChooseView = nil


            self:createCollectGameMainView( function(  )

                self.m_bonusCollectWin = false

                -- self:bonusOverAddRespinEffect( )
                -- self:bonusOverAddFreespinEffect( )
            
                effectData.p_isPlay = true
                self:playGameEffect() -- 播放下一轮
                
                

            end)

        end)


        
    else
        self.m_bonusChooseView:setEndCallFunc(function(  )

            self.m_bonusCollectWin = false

            self:resetMusicBg()

            self.m_topUI.m_isNotCanClick = false

            self.m_bonusChooseView:removeFromParent()
            self.m_bonusChooseView = nil
            self:updateLoadingBar( )
            
            -- self:bonusOverAddRespinEffect( )
            -- self:bonusOverAddFreespinEffect( )

            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮

            
        end)
    end
    
    
    
end

function CodeGameScreenZeusMachine:updateLoadingBar( )
    local collectData =  self:getBonusCollectData( )

    if collectData and type(collectData) == "table" then
        local progress = self:getProgress(collectData)
        if progress then
            self.m_CollectBar:setPercent(progress)
        end

        local round = collectData.collectRound
        if round then
            self.m_CollectBar:initBonusRound( round )
        end
        
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTimes =  selfdata.collectPlayCount
    if bonusTimes then
        self.m_CollectBar:findChild("BitmapFontLabel_3_0"):setString(bonusTimes)
    end
    
end

function CodeGameScreenZeusMachine:featureOverAddBonusEffect( )
    
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

        end
    end
end

function CodeGameScreenZeusMachine:bonusOverAddFreespinEffect( )
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

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

function CodeGameScreenZeusMachine:bonusOverAddRespinEffect( )
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_RESPIN then -- 有Respin
            globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
            if self:getCurrSpinMode() == RESPIN_MODE then
            else
                local respinEffect = GameEffectData.new()
                respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                if globalData.slotRunData.iReSpinCount == 0 and 
                #self.m_runSpinResultData.p_storedIcons == 15 then
                    respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                    respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                end
                self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                --发送测试特殊玩法
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
            end
        end
    end
end

function CodeGameScreenZeusMachine:initFeatureInfo(spinData,featureData)

   

    local bonusStates = self.m_runSpinResultData.p_bonusStatus

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTypes =  selfdata.bonusTypes

    if bonusTypes and bonusTypes[1] == "collectBonus"  then
        if bonusStates and bonusStates ~= "CLOSED" then

            self.isInBonus = true
            
            self.m_bonusCollectWin = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
            self:createCollectGameMainView( function(  )
        
                self.m_bonusCollectWin = false

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,true})
        

                -- self:bonusOverAddRespinEffect( )
                -- self:bonusOverAddFreespinEffect( )
            
                -- self:playGameEffect() -- 播放下一轮

            end)
        end
    end

    
    

    
end



--小块
function CodeGameScreenZeusMachine:getBaseReelGridNode()
    return "CodeZeusSrc.ZeusSlotFastNode"
end


---判断结算
function CodeGameScreenZeusMachine:reSpinReelDown(addNode)


    self.m_reSpinReelDownCallFunc = function(  )


        BaseFastMachine.reSpinReelDown(self,addNode)

        self.m_reSpinReelDownCallFunc = nil
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_rocketPositions = selfdata.rocketPositions 

    if self.m_rocketPositions then
        self.m_actIndex = 0
        self:runRocketFly(  )
    else
        self.m_reSpinReelDownCallFunc()
    end
    

end

function CodeGameScreenZeusMachine:getLockSymbolType( index , symbolType )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rocketTypes = selfdata.rocketTypes or {}


    if symbolType == self.SYMBOL_MIDRUN_SYMBOL  then
        

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local spWheels = selfdata.spWheels
        local spWheelIndex = selfdata.spWheelIndex + 1
        
        -- 滚动停止
        local endData = {}
        endData.type = spWheels[spWheelIndex]
        if type(endData.type)  == "number" then
            return "Coins"

        else
            return endData.type
        end

    elseif symbolType == self.SYMBOL_ROCK_SYMBOL  then

        for k,v in pairs(rocketTypes) do
            local pos = tonumber(k)
            local rockType = v
            if index == pos then
              return rockType
            end
        end

    else
        return "Coins"
    end

    
end

function CodeGameScreenZeusMachine:changeRockSymbolImg( index,node )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rocketTypes = selfdata.rocketTypes or {}

    for k,v in pairs(rocketTypes) do
        local pos = tonumber(k)
        local rockType = v
        if index == pos then

            node:getCcbProperty("zeus_coin_mini_4"):setVisible(false)
            node:getCcbProperty("zeus_coin_minor_5"):setVisible(false)
            node:getCcbProperty("zeus_coin_major_3"):setVisible(false)
            node:getCcbProperty("zeus_coin_grand_2"):setVisible(false)
            node:getCcbProperty("m_lb_score"):setVisible(false)
            node:getCcbProperty("m_lb_score_0"):setVisible(false)
            node:getCcbProperty("Socre_Zeus_Coin"):setVisible(false)
            

            if rockType == "Mini" then
                node:getCcbProperty("zeus_coin_mini_4"):setVisible(true)
            elseif rockType == "Minor" then
                node:getCcbProperty("zeus_coin_minor_5"):setVisible(true)
            elseif rockType == "Major" then
                node:getCcbProperty("zeus_coin_major_3"):setVisible(true)
            elseif rockType == "Grand" then
                node:getCcbProperty("zeus_coin_grand_2"):setVisible(true)
            elseif rockType == "Coins" then
                
                local score = self:getReSpinSymbolScore(self:getPosReelIdx(node.p_rowIndex , node.p_cloumnIndex )) --获取分数（网络数据）

                self:getCcbDealHightLowScore( node, score )

                node:getCcbProperty("Socre_Zeus_Coin"):setVisible(true)
            end
        end
    end

end

function CodeGameScreenZeusMachine:isInRockPosList(  index )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rocketPositions = selfdata.rocketPositions or {}

    for k,v in pairs(rocketPositions) do

        local pos = tonumber(k)

        if index == pos then


            return true

        end
    end

    return false
end

function CodeGameScreenZeusMachine:getRockDate( )
    
    local index = 0
    local data = {}
    for k,v in pairs(self.m_rocketPositions) do
        index = index + 1

        if index == self.m_actIndex  then
            data.m_reelNodePos = tonumber(k)
            data.m_RSBarPos = v

            return data
        end
    end
    
end

function CodeGameScreenZeusMachine:getTableNum(array )
    local num = 0

    for k,v in pairs(array) do
        num = num + 1
    end

    return num
end

function CodeGameScreenZeusMachine:runRocketFly(  )


    if self.m_actIndex == self:getTableNum( self.m_rocketPositions ) then

        if self.m_reSpinReelStartCallFunc then
            self.m_reSpinReelStartCallFunc()
        end
        
        if self.m_reSpinReelDownCallFunc then
            self.m_reSpinReelDownCallFunc()
        end


        return
    end

    self.m_actIndex = self.m_actIndex + 1

    local rocketData = self:getRockDate( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rocketToPositions = selfdata.rocketToPositions 
     

    local nodelist = self.m_respinView:getAllCleaningNode()
    local node = nil
    for i=1,#nodelist do
        local lockNode = nodelist[i]
        local reelIdx = self:getPosReelIdx(lockNode.p_rowIndex, lockNode.p_cloumnIndex)
        if reelIdx == rocketToPositions[self.m_actIndex] then -- rocketData.m_reelNodePos
            node = lockNode
            break
        end
    end

    

    performWithDelay(self,function(  )
        
        
        gLobalSoundManager:playSound("ZeusSounds/music_Zeus_respinbar_CollecLight.mp3")

        node:runAnim("actionframe",false,function(  )
            node:runAnim("actionframe2",true)
        end)

        
        self:runRespinCollectFlyAct(node,self.m_RespinBar:findChild("Node_1") ,"Socre_Zeus_Shouji",function(  )

            self.m_RespinBar:runCsbAction("shouji",false,function(  )

                self.m_RespinBar:runCsbAction("idle",true)
                
                self.m_RespinBar:beginRunAct( function(  )

                    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_respinbar_CollecLight_change_Nor.mp3")
    
                    self.m_RespinBar:runCsbAction("luodi",false,function(  )
                        self.m_RespinBar:runCsbAction("idle",true)
                    end)
    
                    performWithDelay(self,function(  )
                        self:runRocketFly(  )
                    end,1)
                    
                    
                end,self.m_actIndex)
    
                

            end)

            
            
        end)
    end,11/30)
    

    
    



end


function CodeGameScreenZeusMachine:getAngleByPos(p1,p2)  

    local p = {}  
    p.x = p2.x - p1.x  
    p.y = p2.y - p1.y  

    local r = math.atan2(p.y,p.x)*180/math.pi  
    print("夹角[-180 - 180]:",r)  
    return r  
end


function CodeGameScreenZeusMachine:runRespinCollectFlyAct(startNode,endNode,csbName,func,endAddY)

    -- 创建粒子
    local flyNode =  util_createAnimation( csbName ..".csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startPos = util_getConvertNodePos(startNode,flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = cc.p(util_getConvertNodePos(endNode,flyNode))
    if endAddY then
        endPos = cc.p(endPos.x,endPos.y + endAddY)
    end

    local angle = self:getAngleByPos(startPos,endPos)
    flyNode:findChild("Node_1"):setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:findChild("Node_1"):setScaleX(scaleSize / 342)

    flyNode:runCsbAction("actionframe",false,function(  )

            if func then
                func()
            end

            flyNode:stopAllActions()
            flyNode:removeFromParent()
    end)

    return flyNode

end

function CodeGameScreenZeusMachine:runMidNodeRewordAct(endNode ,func )
    
    local actTimes = 0.5

    local actNode = self:createOneActionSymbol2(endNode)
    local oldPos = cc.p(actNode:getPosition()) 
    
    if actNode.m_specialRunUI then
        if actNode.m_specialRunUI.m_FeatureNode then
            actNode.m_specialRunUI.m_FeatureNode.m_isPlaySound = true
        end
    end
    
    
    

    local posEndworldPos = self:findChild("actNodePos"):getParent():convertToWorldSpace(cc.p(self:findChild("actNodePos"):getPositionX(), self:findChild("actNodePos"):getPositionY()))
    local posEnd = self:convertToNodeSpace(cc.p(posEndworldPos.x,posEndworldPos.y))


    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        actNode:runAction(cc.Sequence:create(cc.CallFunc:create(function(  )
            actNode:runAction(cc.Sequence:create(cc.CallFunc:create(function(  )
                actNode:runCsbAction("actionframe",true)
            end)))
        end),cc.ScaleTo:create(actTimes,1.5)))
        
    end)
    actList[#actList + 1] = cc.DelayTime:create(actTimes)
    -- actList[#actList + 1] = cc.MoveTo:create(actTimes,cc.p(posEnd.x,posEnd.y ))
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        
        actNode:runCsbAction("idleframe",true)

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local spWheels = selfdata.spWheels
        local spWheelIndex = selfdata.spWheelIndex + 1

        local endData = {}
        endData.type = spWheels[spWheelIndex]
        if type(endData.type)  == "number" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            endData.score = lineBet * endData.type
        end
        actNode.m_specialRunUI:setOverCallBackFun(function(  )

            gLobalSoundManager:playSound("ZeusSounds/music_Zeus_MinBonus_RunDown.mp3") 

            local actList1 = {}
            actList1[#actList1 + 1] = cc.DelayTime:create(1.5)
            actList1[#actList1 + 1] = cc.CallFunc:create(function(  )
                actNode:runAction(cc.Sequence:create(cc.ScaleTo:create(actTimes,1)))
            end)
            actList1[#actList1 + 1] = cc.MoveTo:create(actTimes,cc.p(oldPos.x,oldPos.y))
            actList1[#actList1 + 1] = cc.CallFunc:create(function(  )

                endNode:setVisible(true)

                performWithDelay(self,function(  )
                    if func then
                        func()
                    end  
                end,0.5)
                
               
                actNode:stopAllActions()
                actNode:removeFromParent()


            end)

            local sq1 = cc.Sequence:create(actList1)
            actNode:runAction(sq1)
            
        end)
        actNode.m_specialRunUI:setEndValue(endData)

    end)

    local sq = cc.Sequence:create(actList)
    actNode:runAction(sq)
    


end
function CodeGameScreenZeusMachine:createOneActionSymbol2(endNode)

    if not endNode or not endNode.m_ccbName  then
        return
    end
    
    local fatherNode = endNode
    endNode:setVisible(false)
    
    local node= util_createAnimation( endNode.m_ccbName..".csb")

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self:addChild(node , 100000 + endNode.p_rowIndex)
    node:setPosition(pos)

    node.m_specialRunUI = util_createView("CodeZeusSrc.ZeusRespinRunView",self)
    node:findChild("Node_Coin_zi"):addChild(node.m_specialRunUI)

            
    return node
end

function CodeGameScreenZeusMachine:createOneActionSymbol(endNode)

    if not endNode or not endNode.m_ccbName  then
        return
    end
    
    local fatherNode = endNode
    endNode:setVisible(false)
    
    local node= util_createAnimation( endNode.m_ccbName..".csb")

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("root_0"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self:findChild("root_0"):addChild(node , 100000 + endNode.p_rowIndex)
    node:setPosition(pos)

    node.m_specialRunUI = util_createView("CodeZeusSrc.ZeusRespinRunView",self)
    node:findChild("Node_Coin_zi"):addChild(node.m_specialRunUI)

            
    return node
end

function CodeGameScreenZeusMachine:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        performWithDelay(self,function()
            local feature = self.m_runSpinResultData.p_features
            if self.m_chooseView ~= nil and feature and feature[2] and feature[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
                -- 第一次播放砸wild
                local fsData = self.m_runSpinResultData.p_fsExtraData

                for i=1,#self.m_AddWildEffect do
                    local effectNode = self.m_AddWildEffect[i]
                    if effectNode then
                        
                        


                        if effectNode.LittleUI then
                            effectNode:setVisible(true)
                            gLobalSoundManager:playSound("ZeusSounds/music_Zeus_OpenView.mp3")

                            local freespindata =  self.m_runSpinResultData.p_fsExtraData or {}
                            local wildTimes = freespindata.wilds or 0
                            local waitAddtimes =  175/30 / wildTimes - 0.005

                            effectNode.LittleUI:findChild("BitmapFontLabel_1"):setString(wildTimes)
                            effectNode:findChild("Panel_1"):setVisible(false)
                            
                            effectNode.LittleUI:runCsbAction("start",false,function(  )

                                
                                performWithDelay(self,function(  )
                                    effectNode:findChild("Panel_1"):setVisible(true)
                                    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_addWIldBegin_View.mp3")

                                    effectNode:runCsbAction("actionframe"..i)

                                    util_cutDownNum(effectNode.LittleUI:findChild("BitmapFontLabel_1"),wildTimes,0,-1,waitAddtimes)
                                end,0.5)
                                
                            end)
                            
                        end

                        
                    end
                end

                performWithDelay(self,function(  )
                    for i=1,#self.m_AddWildEffect do
                        local effectNode = self.m_AddWildEffect[i]
                        if effectNode then

                            if effectNode.LittleUI then

                                gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Collect_Bonus_OverView.mp3")

                                effectNode.LittleUI:runCsbAction("over",false,function(  )
                                    effectNode:setVisible(false)
    
                                    self:showFreespinStartrManShow(  )

                                    if self.m_chooseView then
                                        self.m_chooseView:removeFromParent()
                            
                                        self.m_chooseView = nil
                                    end

                                    self:requestSpinResult()

                                end)
                                
                            end

                            
                        end
                    end
                    
  
                    

                    

                end,175/30 + 15/30 + 0.5)



                

            else
                self:requestSpinResult()

            end
        end,0)
        
    else
        self:requestSpinResult() 
    end

    self.m_isWaitingNetworkData = true
    
    self:setGameSpinStage( WAITING_DATA )
    -- 设置stop 按钮处于不可点击状态
    if not self.m_chooseRepinGame  then
        if self:getCurrSpinMode() == RESPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Spin,false,true})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Stop,false,true})
        end
    end

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

-- 处理特殊关卡 遮罩层级
function CodeGameScreenZeusMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

---
--设置bonus scatter 层级
function CodeGameScreenZeusMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or self:isFixSymbol(symbolType) then
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


function CodeGameScreenZeusMachine:changeViewNodePos()

    if display.height > DESIGN_SIZE.height then
        local posY = (display.height - DESIGN_SIZE.height) * 0.5

        local nameList = {"Respin","Node_reel","Image_1",
                    "SpinRemaining","Node_reel_spin2",
                    "jindutiao","Zeus_jackPoTip","actNodePos","sp_reel_0","sp_reel_1",
                    "sp_reel_2","sp_reel_3","sp_reel_4"}

        for i=1,#nameList do

            local node = self:findChild(nameList[i])
            if node then
                -- node:setPositionY(node:getPositionY() - posY )
            end
            
        end


    end

   

end

function CodeGameScreenZeusMachine:scaleMainLayer()
    BaseFastMachine.scaleMainLayer(self)
    
    local m_light_Height =  1300 
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    local showHeight = (1660 / 2) + ((display.height / 2 ) - uiBH ) / self.m_machineRootScale 

    local lightScale = showHeight / m_light_Height  
    -- self.m_light_left:setScaleY(lightScale)
    -- self.m_light_reight:setScaleY(lightScale)

    self:adaptLeftAndRightLightPos()
end


function CodeGameScreenZeusMachine:adaptLeftAndRightLightPos()
    --计算出主轮盘缩的长度
    local disBoundary = 50                 --设一个跑马灯距离边界的距离
    self.m_light_left:setPositionY( 210)
    self.m_light_reight:setPositionY( 210)
    local scaleHalfWildth = math.abs(display.width * (1 - self.m_machineRootScale) ) / 2
    if scaleHalfWildth > disBoundary then 
        print(self.m_light_left:getPosition() .. " " .. self.m_light_reight:getPosition() )
        local moveX =  (scaleHalfWildth - disBoundary) / self.m_machineRootScale
        self.m_light_left:setPositionX( -moveX)
        self.m_light_reight:setPositionX( moveX)
        self.m_scaleJackpotView = 1 + moveX / display.width
    end

end

-- 显示paytableview 界面
function CodeGameScreenZeusMachine:showPaytableView()

    self.m_topUI.m_isNotCanClick = true

    --if self:checkIsinFeaute( ) then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    --end
    
    
    local csbFileName = "PayTableLayer" ..self.m_moduleName .. ".csb"
   
    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath =  CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return 
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = util_createView("base/BasePayTableView", sCsbpath) 
    self:showSelfUI( view,100 )
    if view then
        view:setOverFunc(function() 
            if self.m_touchSpinLayer then
                self.m_touchSpinLayer:setVisible(true)
            end
            
            self.m_topUI.m_isNotCanClick = false

            if self:checkIsinFeaute( ) then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
            
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
            gLobalViewManager:viewResume(function()
                globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
            end)
        end)
    end
end

function CodeGameScreenZeusMachine:checkIsinFeaute( )

    if self.m_runSpinResultData.p_features and #self.m_runSpinResultData.p_features > 1 then
        return false

    elseif self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then

        return false

    elseif  self.m_runSpinResultData.p_freeSpinsTotalCount ~= nil and 
                self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and 
                    self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then 

        return false        
        
    elseif  self.m_runSpinResultData.p_reSpinsTotalCount ~= nil and 
                self.m_runSpinResultData.p_reSpinsTotalCount > 0 and
                    self.m_runSpinResultData.p_reSpinCurCount > 0 then

        return false

    elseif  self.m_bonusCollectView then

        return false
    end

    return true
    
end

function CodeGameScreenZeusMachine:playrespinEndActiom( )
    self:playCoinWinEffectUI()
    -- self.m_respinEndActiom:setVisible(true)
    -- self.m_respinEndActiom:runCsbAction("actionframe",false,function(  )
    --     if self then
    --         self.m_respinEndActiom:setVisible(false)
    --     end
        
    -- end)
end

function CodeGameScreenZeusMachine:createLocalAnimation( )
    local pos = cc.p(self.m_bottomUI.m_normalWinLabel:getPosition()) 
    
    self.m_respinEndActiom = util_createAnimation("Zeus_Total_win.csb")  
    self.m_bottomUI.m_normalWinLabel:getParent():addChild(self.m_respinEndActiom,99999)
    self.m_respinEndActiom:setPosition(cc.p(pos.x ,pos.y))

    self.m_respinEndActiom:setVisible(false)
end

function CodeGameScreenZeusMachine:checkCanClickJackpotTip( )
    
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then

        return false

    elseif self.m_runSpinResultData.p_features and #self.m_runSpinResultData.p_features > 1 then
        return false

    elseif self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then

        return false

    elseif  self.m_runSpinResultData.p_freeSpinsTotalCount ~= nil and 
                self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and 
                    self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then 

        return false        
        
    elseif  self.m_runSpinResultData.p_reSpinsTotalCount ~= nil and 
                self.m_runSpinResultData.p_reSpinsTotalCount > 0 and
                    self.m_runSpinResultData.p_reSpinCurCount > 0 then

        return false

    end

    return true
end

--播放respin放回滚轴后播放的提示动画
function CodeGameScreenZeusMachine:checkRespinChangeOverTip(node,endAnimaName,loop)
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    end
end
---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenZeusMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()

    end

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
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenZeusMachine:checkTriggerINFreeSpin( )
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end

    if hasBonusFeature then
        if self.m_initSpinData.p_freeSpinsLeftCount  and 
            self.m_initSpinData.p_freeSpinsLeftCount == 0 then
                hasBonusFeature = false
        end  
    end

    local isInFs = false
    if hasFreepinFeature == false and 
            self.m_initSpinData.p_freeSpinsTotalCount ~= nil and 
            self.m_initSpinData.p_freeSpinsTotalCount > 0 and 
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or 
                (hasReSpinFeature == true  or hasBonusFeature == true)) then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs == true then
    
        self:changeFreeSpinReelData()
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        
        self:setCurrSpinMode( FREE_SPIN_MODE)

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end

        -- 发送事件显示赢钱总数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff=true
    end

    return isPlayGameEff
end



function CodeGameScreenZeusMachine:getBottomUINode( )
    return "CodeZeusSrc.ZeusGameBottomNode"
end

function CodeGameScreenZeusMachine:findChildDealHightLowScore( symbolNode, score )


    local lab = symbolNode:findChild("m_lb_score")
    local lab1 = symbolNode:findChild("m_lb_score_0")
    if lab then
        lab:setVisible(false)
    end
    if lab1 then
        lab1:setVisible(false)
    end

    if score >= self.m_hightBet and lab1 then
        lab1:setVisible(true)
    elseif lab then
        lab:setVisible(true)
    end
end

function CodeGameScreenZeusMachine:getCcbDealHightLowScore( symbolNode, score )

    local lab = symbolNode:getCcbProperty("m_lb_score")
    local lab1 = symbolNode:getCcbProperty("m_lb_score_0")
    if lab then
        lab:setVisible(false)
    end
    if lab1 then
        lab1:setVisible(false)
    end

    if score >= self.m_hightBet and lab1 then
        lab1:setVisible(true)
    elseif lab then
        lab:setVisible(true)
    end
end



function CodeGameScreenZeusMachine:dealSmallReelsSpinStates( )

    if self.m_chooseRepinGame then
        self.m_chooseRepinGame = false  
    end

    CodeGameScreenZeusMachine.super.dealSmallReelsSpinStates(self )

end



function CodeGameScreenZeusMachine:playEffectNotifyChangeSpinStatus( )
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                                        {SpinBtn_Type.BtnType_Auto,true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Auto,true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
                    self:normalSpinBtnCall()
                end, 0.5,self:getModuleName())
            end
        else
            if not self.m_chooseRepinGame  then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,true})
            end
            
        end
    end
end

function CodeGameScreenZeusMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if "free" == _sFeature then
        return
    end
    if CodeGameScreenZeusMachine.super.levelDeviceVibrate then
        CodeGameScreenZeusMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenZeusMachine






