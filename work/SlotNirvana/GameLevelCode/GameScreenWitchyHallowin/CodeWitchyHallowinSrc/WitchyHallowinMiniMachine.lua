---
-- xcyy
-- 2018-12-18 
-- WitchyHallowinMiniMachine.lua
--
--

local BaseMiniReelMachine = require "Levels.BaseReel.BaseMiniReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local WitchyHallowinMiniMachine = class("WitchyHallowinMiniMachine", BaseMiniReelMachine)




WitchyHallowinMiniMachine.m_machineIndex = nil -- csv 文件模块名字

WitchyHallowinMiniMachine.gameResumeFunc = nil
WitchyHallowinMiniMachine.gameRunPause = nil



local Main_Reels = 1


-- 构造函数
function WitchyHallowinMiniMachine:ctor()
    WitchyHallowinMiniMachine.super.ctor(self)

    
end

function WitchyHallowinMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent 
    self.m_maxReelIndex = data.maxReelIndex 


    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function WitchyHallowinMiniMachine:initGame()


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function WitchyHallowinMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WitchyHallowin"
end

-- 继承底层respinView
function WitchyHallowinMiniMachine:getRespinView()
    return self.m_parent:getRespinView()
end
-- 继承底层respinNode
function WitchyHallowinMiniMachine:getRespinNode()
    return self.m_parent:getRespinNode()
end

function WitchyHallowinMiniMachine:getMachineConfigName()

    local str = "WitchyHallowinConfig.csv"

    return str
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function WitchyHallowinMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function WitchyHallowinMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function WitchyHallowinMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("WitchyHallowin_shenghang.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    self:initReSpinBar()
end

function WitchyHallowinMiniMachine:initReSpinBar()
    local node_bar = self:findChild("Node_Respinbar")
    self.m_respinBar = util_createView("CodeWitchyHallowinSrc.WitchyHallowinRespinBar",{machine = self})
    node_bar:addChild(self.m_respinBar)
end

--[[
    刷新当前respin剩余次数
]]
function WitchyHallowinMiniMachine:changeReSpinUpdateUI(curCount,isInit)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_respinBar:updateRespinCount(curCount,totalCount,isInit)
end

--
---
--
function WitchyHallowinMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    WitchyHallowinMiniMachine.super.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function WitchyHallowinMiniMachine:addSelfEffect()

 
end


function WitchyHallowinMiniMachine:MachineRule_playSelfEffect(effectData)
    
    -- if effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT  then
        
    -- end

    return true
end




function WitchyHallowinMiniMachine:onEnter()
    WitchyHallowinMiniMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    
end

function WitchyHallowinMiniMachine:addObservers( )
    WitchyHallowinMiniMachine.super.addObservers(self)
end



function WitchyHallowinMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function WitchyHallowinMiniMachine:playEffectNotifyChangeSpinStatus( )


end

function WitchyHallowinMiniMachine:quicklyStopReel(colIndex)


end

function WitchyHallowinMiniMachine:onExit()
    WitchyHallowinMiniMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function WitchyHallowinMiniMachine:removeObservers()
    WitchyHallowinMiniMachine.super.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end



function WitchyHallowinMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function WitchyHallowinMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    WitchyHallowinMiniMachine.super.beginReel(self)

end


-- 消息返回更新数据
function WitchyHallowinMiniMachine:netWorkCallFun(spinResult)

    -- self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    -- self:updateNetWorkData()
end

function WitchyHallowinMiniMachine:enterLevel( )
    WitchyHallowinMiniMachine.super.enterLevel(self)
end

function WitchyHallowinMiniMachine:enterLevelMiniSelf( )

    WitchyHallowinMiniMachine.super.enterLevel(self)
    
end

function WitchyHallowinMiniMachine:dealSmallReelsSpinStates( )
    
end



-- 处理特殊关卡 遮罩层级
function WitchyHallowinMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function WitchyHallowinMiniMachine:getBounsScatterDataZorder(symbolType )
   
    return self.m_parent:getBounsScatterDataZorder(symbolType )

end



function WitchyHallowinMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function WitchyHallowinMiniMachine:checkGameResumeCallFun( )
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end

function WitchyHallowinMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function WitchyHallowinMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function WitchyHallowinMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end



---
-- 清空掉产生的数据
--
function WitchyHallowinMiniMachine:clearSlotoData()
    
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then

        for i=#self.m_lineDataPool,1,-1 do
            self.m_lineDataPool[i] = nil
        end

    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function WitchyHallowinMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function WitchyHallowinMiniMachine:clearCurMusicBg( )
    
end


function WitchyHallowinMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()

end

--[[
    刷新小块
]]
function WitchyHallowinMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    end
end

-- 给respin小块进行赋值
function WitchyHallowinMiniMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score = 0
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
    else
        score =  self.m_parent:randomDownRespinSymbolScore(symbolNode.p_symbolType)
    end

    if symbolNode and symbolNode.p_symbolType then
        symbolNode.m_score = score
        local symbolType = symbolNode.p_symbolType

        local csbNode = self.m_parent:getLblOnBonusSymbol(symbolNode)

        if symbolType == self.m_parent.SYMBOL_BONUS or symbolType == self.m_parent.SYMBOL_BONUS_BLUE or symbolType == self.m_parent.SYMBOL_BONUS_PURPLE or symbolType == self.m_parent.SYMBOL_BONUS_RED then
            csbNode:findChild("m_lb_coins"):setVisible(true)
            csbNode:findChild("jackpot"):setVisible(false)
            if score ~= nil then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                local multi = score / lineBet
                score = util_formatCoins(score, 3)
                local label = csbNode:findChild("m_lb_coins")
                label:setString(score)

                local labelGold = csbNode:findChild("m_lb_coins_0")
                labelGold:setString(score)
                if multi >= 5 then
                    csbNode:findChild("m_lb_coins"):setVisible(false)
                    csbNode:findChild("m_lb_coins_0"):setVisible(true)
                else
                    csbNode:findChild("m_lb_coins"):setVisible(true)
                    csbNode:findChild("m_lb_coins_0"):setVisible(false)
                end
            end
            
        else
            csbNode:findChild("m_lb_coins"):setVisible(false)
            csbNode:findChild("m_lb_coins_0"):setVisible(false)
            csbNode:findChild("jackpot"):setVisible(true)
            csbNode:findChild("major"):setVisible(symbolType == self.m_parent.SYMBOL_BONUS_MAJOR)
            csbNode:findChild("minor"):setVisible(symbolType == self.m_parent.SYMBOL_BONUS_MINOR)
            csbNode:findChild("mini"):setVisible(symbolType == self.m_parent.SYMBOL_BONUS_MINI)
        end
    end

end

-- 根据网络数据获得respinBonus小块的分数
function WitchyHallowinMiniMachine:getReSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local multi = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            multi = values[2]
        end
    end

    if multi == nil then
       return 0
    end

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multi * lineBet

    return score
end


function WitchyHallowinMiniMachine:showRespinView()

    -- --可随机的普通信息
    -- local randomTypes = self.m_parent:getRespinRandomTypes( )

    -- --可随机的特殊信号 
    -- local endTypes = self.m_parent:getRespinLockTypes()
    
    -- --构造盘面数据
    -- self:triggerReSpinCallFun(endTypes, randomTypes)
end

--触发respin
function WitchyHallowinMiniMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()
    self.m_respinBar:setComplete(false)
    self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,true)
    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

function WitchyHallowinMiniMachine:initRespinView(endTypes, randomTypes)
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
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--[[
    设置respinbar是否显示
]]
function WitchyHallowinMiniMachine:setRespinBarShow(isShow)
    self.m_respinBar:setVisible(isShow)
    if isShow then
        if self.m_runSpinResultData.p_reSpinsTotalCount == 4 then
            self.m_respinBar:showFourNumAni(function(  )
                
            end)
        else
            self.m_respinBar:showThreeNumAni()
        end
    end
    
    
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function WitchyHallowinMiniMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if not self:isFixSymbol(symbolType) then
                symbolType = self.m_parent.SYMBOL_EMPTY
            elseif symbolType == self.m_parent.SYMBOL_BONUS_PURPLE or symbolType == self.m_parent.SYMBOL_BONUS_RED or symbolType == self.m_parent.SYMBOL_BONUS_BLUE then
                symbolType = self.SYMBOL_BONUS
            end
            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_parent.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_parent.m_machineRootScale

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

--[[
    设置spin结果数据
]]
function WitchyHallowinMiniMachine:setSpinResultData(result,isInit)
    self.m_runSpinResultData = clone(result)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local respinExtraData = self.m_runSpinResultData.p_rsExtraData
    self.m_runSpinResultData.p_reels = selfData.addreels
    self.m_runSpinResultData.p_reelsData = selfData.addreels
    if isInit or not selfData.addshow_storedIcons then
        self.m_runSpinResultData.p_storedIcons = selfData.addstoredIcons
    else
        self.m_runSpinResultData.p_storedIcons = selfData.addshow_storedIcons
    end
    
    self.m_runSpinResultData.p_reSpinCurCount = selfData.add_reSpinCurCount
end

---判断结算
function WitchyHallowinMiniMachine:reSpinReelDown(addNode)
    self:setGameSpinStage(STOP_RUN)
    self.m_parent:oneRespinDown()

    if self.m_respinBar.m_isComplete then
        return
    end
    
    if self.m_runSpinResultData.p_reSpinCurCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    else
        self.m_respinBar:completeAni()
    end

    

end

--开始滚动
function WitchyHallowinMiniMachine:startReSpinRun()
    if self.m_runSpinResultData.p_reSpinCurCount <= 0 then
        self:reSpinReelDown()
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

    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end
    self.m_respinView:startMove()
end

function WitchyHallowinMiniMachine:respinOver()
    self:setReelSlotsNodeVisible(true)

    self:removeRespinNode()

    self:triggerReSpinOverCallFun(0)
end

function WitchyHallowinMiniMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_preReSpinStoredIcons = nil
    
    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0
end

--[[
    检测玩法1添加bonus分数
]]
function WitchyHallowinMiniMachine:checkAddBonusSymbolScore(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_runSpinResultData.p_storedIcons = selfData.addstoredIcons
    local randomcredit = selfData.addrandomcredit
    if randomcredit then
        for index, data in ipairs(randomcredit) do
            self:updateScoreOnSymbol(data[1],data[2])
        end
    end

    self.m_parent:delayCallBack(40 / 60,function(  )
        if type(func) == "function" then
            func()
        end
    end)
    
end

--[[
   刷新小块分数
]]
function WitchyHallowinMiniMachine:updateScoreOnSymbol(posIndex,addMul,func)
    local pos = self:getRowAndColByPos(posIndex)
    local iCol,iRow = pos.iY,pos.iX
    local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol,iRow)
    local symbolNode = respinNode.m_baseFirstNode
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == self.m_parent.SYMBOL_BONUS then

        local startNode = self.m_parent.m_spine_sorceress.m_startNode_single
        if self.m_parent.m_isDoubleReels then
            startNode = self.m_parent.m_spine_sorceress.m_startNode_double
        end
        self.m_parent:runFlyLineAct(startNode,symbolNode,function(  )
            local score = self:getReSpinSymbolScore(posIndex) --获取分数（网络数据）
            if score ~= nil then
                symbolNode:runAnim("sho2ji",false,function(  )
                    symbolNode:runAnim("idleframe2",true)
                end)
                local csbNode = self.m_parent:getLblOnBonusSymbol(symbolNode)
                local label = csbNode:findChild("m_lb_coins")
                local labelGold = csbNode:findChild("m_lb_coins_0")

                local addScore = addMul * lineBet
                self.m_parent:jumpCoins(label,labelGold,symbolNode.m_score,score,function(  )
                    score = util_formatCoins(score, 3)
                    label:setString(score)
                    labelGold:setString(score)
                end)
                --加钱动画
                local addAni = util_createAnimation("WitchyHallowin_Moneychange.csb")
                csbNode:findChild("Node_Moneychange"):addChild(addAni)
                addAni:runCsbAction("actionframe",false,function(  )
                    addAni:removeFromParent()
                    respinNode:hideChangeMoneyTipAni()
                end)
                local str = util_formatCoins(addScore, 3)
                addAni:findChild("BitmapFontLabel_1"):setString("+"..str)
                
                symbolNode.m_score = score
            end
        end)
    end
end

--[[
    判断是否为bonus小块
]]
function WitchyHallowinMiniMachine:isFixSymbol(symbolType)
    return self.m_parent:isFixSymbol(symbolType)
end

--[[
    respin单列停止
]]
function WitchyHallowinMiniMachine:respinOneReelDown(colIndex,isQuickStop)
    self.m_parent:respinOneReelDown(colIndex,isQuickStop)
end

--[[
    拉镜头时图标播期待动画
]]
function WitchyHallowinMiniMachine:showExpectAni( )
    self.m_respinView:showExpectAni()
end

return WitchyHallowinMiniMachine
