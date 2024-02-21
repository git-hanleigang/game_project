
local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local ZeusVsHadesMiniMachine = class("ZeusVsHadesMiniMachine", BaseMiniMachine)

ZeusVsHadesMiniMachine.gameResumeFunc = nil
ZeusVsHadesMiniMachine.gameRunPause = nil

local Main_Reels = 1

-- 构造函数
function ZeusVsHadesMiniMachine:ctor()
    BaseMiniMachine.ctor(self)
    self.m_clipNode = {}--存储提高层级的图标
end

function ZeusVsHadesMiniMachine:initData_( data )
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_index = data.index
    self.m_parent = data.parent
    self.m_maxReelIndex = data.maxReelIndex

    --滚动节点缓存列表
    self.cacheNodeMap = {}
    --init
    self:initGame()
end

function ZeusVsHadesMiniMachine:initGame()
    --初始化基本数据
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ZeusVsHadesMiniConfig.csv", "LevelZeusVsHadesMiniConfig.lua")
    self:initMachine(self.m_moduleName)

end
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function ZeusVsHadesMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ZeusVsHades"
end
function ZeusVsHadesMiniMachine:getBaseReelGridNode()
    return "CodeZeusVsHadesSrc.ZeusVsHadesSlotNode"
end

function ZeusVsHadesMiniMachine:getMachineConfigName()
    local str = "Mini"
    return self.m_moduleName.. str .. "Config"..".csv"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function ZeusVsHadesMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function ZeusVsHadesMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function ZeusVsHadesMiniMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrameZeusVsHades_Huo"

    self:createCsbNode("ZeusVsHades/GameScreenZeusVsHadesNormalRightReel.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

function ZeusVsHadesMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    BaseMiniMachine.initMachine(self)
end
function ZeusVsHadesMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.m_parent.SYMBOL_SCORE_BONUS then
        self:setSpecialNodeScore(node)
    end
end
-- 根据行 列转化为位置(行数为从下往上数，位置是从左上开始数)
function ZeusVsHadesMiniMachine:getPosByRowAndCol(row,col)
	assert( row, " !! row is nil !! " )
	assert( col, " !! col is nil !! " )
	local cols_nums = self.m_iReelColumnNum	-- 滚轴的数量(列数)
	local rows_nums = self.m_iReelRowNum    -- 行的数量
	local pos
	pos = (col - 1) + (rows_nums - row) * cols_nums
	return pos
end
-- 给一些信号块上的数字进行赋值
function ZeusVsHadesMiniMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if symbolNode.p_symbolType == self.m_parent.SYMBOL_SCORE_BONUS then
        if symbolNode.m_numLabel == nil then
            symbolNode.m_numLabel = util_createAnimation("Socre_ZeusVsHades_Bonusshuzi.csb")
            symbolNode:addChild(symbolNode.m_numLabel,2)
        end
        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            if self.m_parent.m_runSpinResultData.p_selfMakeData and self.m_parent.m_runSpinResultData.p_selfMakeData.positionScores[2] then
                local pos = self:getPosByRowAndCol(iRow,iCol)
                local coinNum = self.m_parent.m_runSpinResultData.p_selfMakeData.positionScores[2][""..pos]
                if coinNum then
                    symbolNode.m_numLabel:findChild("m_lb_coins"):setString(util_formatCoins(coinNum, 3))
                    self:updateLabelSize({label = symbolNode.m_numLabel:findChild("m_lb_coins"),sx = 0.6,sy = 0.6},132)
                end
            end
        else
            local multiple = self.m_parent.m_configData:getFixSymbolPro()
            local lineBet = globalData.slotRunData:getCurTotalBet()
            symbolNode.m_numLabel:findChild("m_lb_coins"):setString(util_formatCoins(multiple * lineBet, 3))
            self:updateLabelSize({label = symbolNode.m_numLabel:findChild("m_lb_coins"),sx = 0.6,sy = 0.6},132)
        end
    end
end
----------------------------- 玩法处理 -----------------------------------
function ZeusVsHadesMiniMachine:addSelfEffect()
end

function ZeusVsHadesMiniMachine:MachineRule_playSelfEffect(effectData)
    return true
end
----主棋盘调用接口: 
--添加的事件会卡住其他事件进行 主棋盘的事件完毕后 会注销 迷你棋盘的对应事件
function ZeusVsHadesMiniMachine:MainReel_addSelfEffect(effect)
    local selfEffect = clone(effect)
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
end
--进入下一步
function ZeusVsHadesMiniMachine:MainReel_removeSelfEffect(effect)
    for _index,_effectData in ipairs(self.m_gameEffects) do
        if _effectData.p_selfEffectType == effect.p_selfEffectType and _effectData.p_isPlay == false then
            _effectData.p_isPlay = true
            self:playGameEffect()
            return
        end
    end
    self:playGameEffect()
end
function ZeusVsHadesMiniMachine:showEffect_Respin(effectData)

end
function ZeusVsHadesMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self)
    self:addObservers()
end

function ZeusVsHadesMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function ZeusVsHadesMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_parent:reelShowSpinNotify()
end

function ZeusVsHadesMiniMachine:quicklyStopReel(colIndex)
    ZeusVsHadesMiniMachine.super.quicklyStopReel(self,colIndex)
end

function ZeusVsHadesMiniMachine:onExit()
    BaseMiniMachine.onExit(self)
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

function ZeusVsHadesMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage( WAITING_DATA )
end

function ZeusVsHadesMiniMachine:beginMiniReel()
    self:setSymbolToReel()
    BaseMiniMachine.beginReel(self)
end

-- 消息返回更新数据
function ZeusVsHadesMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)
    self:updateNetWorkData()
end

function ZeusVsHadesMiniMachine:enterLevel()
    BaseMiniMachine.enterLevel(self)
end

function ZeusVsHadesMiniMachine:enterLevelMiniSelf()
    BaseMiniMachine.enterLevel(self)
end

function ZeusVsHadesMiniMachine:dealSmallReelsSpinStates()

end

-- 处理特殊关卡 遮罩层级
function ZeusVsHadesMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
--
--单列滚动停止回调
--
function ZeusVsHadesMiniMachine:slotOneReelDown(reelCol)
    ZeusVsHadesMiniMachine.super.slotOneReelDown(self,reelCol)
    for row = 1, self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(reelCol, row, SYMBOL_NODE_TAG)
        if symbolNode and symbolNode.p_symbolType == self.m_parent.SYMBOL_SCORE_BONUS then
            -- if symbolNode.m_numLabel ~= nil then
            --     symbolNode.m_numLabel.m_csbAct:retain()
            -- end
            self:setSymbolToClip(symbolNode)
            -- if symbolNode.m_numLabel ~= nil then
            --     symbolNode.m_numLabel.m_csbNode:runAction(symbolNode.m_numLabel.m_csbAct)
            --     symbolNode.m_numLabel.m_csbAct:release()
            -- end
            if symbolNode.m_numLabel ~= nil then
                symbolNode.m_numLabel:playAction("buling")
            end
            symbolNode:runAnim("buling",false,function ()
                if symbolNode.p_symbolType ~= nil then
                    symbolNode:runAnim("idleframe",true)
                end
            end)
        end
    end    
end

--将图标提到clipParent层
function ZeusVsHadesMiniMachine:setSymbolToClip(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = slotNode:getPositionY()
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX, slotNode.m_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)

    if slotNode.m_numLabel ~= nil then
        slotNode.m_numLabel.m_csbAct:retain()
    end

    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex * 10)
    self.m_clipNode[#self.m_clipNode + 1] = slotNode

    if slotNode.m_numLabel ~= nil then
        slotNode.m_numLabel.m_csbNode:runAction(slotNode.m_numLabel.m_csbAct)
        slotNode.m_numLabel.m_csbAct:release()
    end
    
    local linePos = {}
    linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
    slotNode:setLinePos(linePos)
end
--将某一个图标恢复到轮盘层
function ZeusVsHadesMiniMachine:setOneSymbolToReel(symbolNode)
    for i, slotNode in ipairs(self.m_clipNode) do
        if slotNode == symbolNode then
            local preParent = slotNode.m_preParent
            if preParent ~= nil then
                slotNode.p_layerTag = slotNode.m_preLayerTag

                local nZOrder = slotNode.m_showOrder
                nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.m_showOrder

                util_changeNodeParent(preParent, slotNode, nZOrder)
                slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)
                slotNode:runIdleAnim()
            end
            table.remove(self.m_clipNode,i)
            break
        end
    end
end
--将图标恢复到轮盘层
function ZeusVsHadesMiniMachine:setSymbolToReel()
    for i, slotNode in ipairs(self.m_clipNode) do
        local preParent = slotNode.m_preParent
        if preParent ~= nil then
            slotNode.p_layerTag = slotNode.m_preLayerTag

            local nZOrder = slotNode.m_showOrder
            nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.m_showOrder

            util_changeNodeParent(preParent, slotNode, nZOrder)
            slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)
            slotNode:runIdleAnim()
        end
    end
    self.m_clipNode = {}
end
--设置bonus scatter 层级
function ZeusVsHadesMiniMachine:getBounsScatterDataZorder(symbolType )
    return self.m_parent:getBounsScatterDataZorder(symbolType)
end

function ZeusVsHadesMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function ZeusVsHadesMiniMachine:checkGameResumeCallFun()
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

function ZeusVsHadesMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function ZeusVsHadesMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function ZeusVsHadesMiniMachine:resumeMachine()
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
function ZeusVsHadesMiniMachine:clearSlotoData()
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
function ZeusVsHadesMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)

end

function ZeusVsHadesMiniMachine:clearCurMusicBg()

end

function ZeusVsHadesMiniMachine:reelDownNotifyPlayGameEffect()
    ZeusVsHadesMiniMachine.super.reelDownNotifyPlayGameEffect(self)
    self.m_parent:setReelRunDownNotify()
end

--根据关卡玩法重新设置滚动信息
function ZeusVsHadesMiniMachine:MachineRule_ResetReelRunData()
    local endCol = self.m_parent:getSymbolEndCol(self.m_parent.SYMBOL_SCORE_BONUS)
    if endCol > 0 then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunInfo = self.m_reelRunInfo
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]
            local reelLongRunTime = 1

            if iCol > endCol then
                local iRow = columnData.p_showGridCount
                local lastColLens = reelRunInfo[1]:getReelRunLen()
                if iCol ~= 1 then
                    lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                    reelRunInfo[iCol - 1 ]:setNextReelLongRun(true)
                    reelLongRunTime = 1
                end

                local colHeight = columnData.p_slotColumnHeight
                local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    
                local preRunLen = reelRunData:getReelRunLen()
                reelRunData:setReelRunLen(runLen)

                if endCol ~= iCol then
                    reelRunData:setReelLongRun(true)
                    reelRunData:setNextReelLongRun(true)
                end
            else
                local lastColLens = reelRunInfo[endCol]:getReelRunLen()     
                local preRunLen = reelRunInfo[iCol].initInfo.reelRunLen
                local preEndColRunLen = reelRunInfo[endCol].initInfo.reelRunLen
                local addRunLen =  preRunLen - preEndColRunLen

                reelRunData:setReelRunLen(lastColLens + addRunLen)
                reelRunData:setReelLongRun(false)
                reelRunData:setNextReelLongRun(false)
            end
        end
    end
end

--[[
    @desc: 获得轮盘的位置
]]
function ZeusVsHadesMiniMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

function ZeusVsHadesMiniMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_parent.m_iOnceSpinLastWin,isNotifyUpdateTop})
end

----
-- 检测处理effect 结束后的逻辑
--
function ZeusVsHadesMiniMachine:operaEffectOver()

    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    self:playEffectNotifyChangeSpinStatus()

    if  not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,false)
        -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end
    if self.m_runSpinResultData and self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsLeftCount then
        if self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end

--重新设置假滚数据
function ZeusVsHadesMiniMachine:changeSlotReelDatas(_col)
    local slotsParents = self.m_slotParents

    local parentData = slotsParents[_col]
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local reelDatas = self:checkUpdateReelDatas(parentData)
    self:checkReelIndexReason(parentData)
    self:resetParentDataReel(parentData)
    self:checkChangeClipParent(parentData)
end
-- 设置假滚
function ZeusVsHadesMiniMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil or parentData.beginReelIndex > #reelDatas then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas

end
return ZeusVsHadesMiniMachine