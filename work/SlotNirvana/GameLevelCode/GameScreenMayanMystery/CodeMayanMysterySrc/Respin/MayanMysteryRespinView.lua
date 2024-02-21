local MayanMysteryRespinView = class("MayanMysteryRespinView", util_require("Levels.RespinView"))
local PublicConfig = require "MayanMysteryPublicConfig"

local TAG_LIGHT = 2000   --集齐
local TAG_SELECT = 3000  --随机列中奖提示

local BASE_COL_INTERVAL = 3

local TOP_ZORDER = 10000

local MOVE_SPEED = 1500

local VIEW_ZORDER = {
    NORMAL = 100,
    REPSINNODE = 2,
    BGLIGHT = 200,
    MAX = 9999
}

MayanMysteryRespinView.SYMBOL_EMPTY = 100

function MayanMysteryRespinView:ctor(params)
    MayanMysteryRespinView.super.ctor(self,params)
    self.m_effectNode_respin = {}  --待集齐特效框
    self.m_effectNode_respinCol = {}  --满列特效
    self.m_quickRunSound = {}
end

--[[
    单格停止
]]
function MayanMysteryRespinView:runNodeEnd(endNode)

    if endNode.p_symbolType ~= self.SYMBOL_EMPTY then
        if self.m_machine.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_machine.m_isPlayUpdateRespinNums then
            self.m_machine:changeReSpinUpdateUI(self.m_machine.m_runSpinResultData.p_reSpinCurCount)
            self.m_machine.m_isPlayUpdateRespinNums = false
        end
    end
    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        self.m_machine:setGameSpinStage(QUICK_RUN)
    end

    self.m_machine:checkPlayBonusDownSound(endNode)

    local p_cloumnIndex = endNode.p_cloumnIndex
    self:stopQuickRunEffect(endNode)

    if self:isLastSpin() then
        self:runRespinNode(p_cloumnIndex + 1, true)
    end

    -- self:playJiQiEffectByCol(p_cloumnIndex)

    local bonusNum = self:addRespinLightEffectSingle(p_cloumnIndex)
    if bonusNum and bonusNum == 3 then
        self.m_machine:playUpdataRespinCountEffect(table.nums(self.m_effectNode_respinCol))
        endNode:runAnim("buling2", false)
    else
        local info = self:getEndTypeInfo(endNode.p_symbolType)
        if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            endNode:runAnim(info.runEndAnimaName, false)
        end
    end
end

--[[
    每列最后一个bonus集齐的时候 效果
]]
function MayanMysteryRespinView:playJiQiEffectByCol(_col)
    local p_reels = self.m_machine.m_runSpinResultData.p_reels
    local reels = self.m_machine.m_runSpinResultData.p_selfMakeData.respinReels or p_reels
    local count  = 0
    for _row = 1, 3 do
        if(reels[_row][_col] == self.m_machine.SYMBOL_BONUS )then
            count = count + 1
        end
    end
    if count >= 3 then
        self.m_machine:playJiQiEffectByRespinCil()
    end
end

--开始滚动
--_col滚动的列
function MayanMysteryRespinView:runRespinNode( _col , _action)
    local colrespins, p_colindex = self:findNextColRespinNode(_col)
    if(#colrespins > 0)then
        for _, _node in ipairs(colrespins) do
            local runCount = self.m_reelRunDatas[p_colindex]
            _node:setRunLong(runCount)
    
            if(_action)then
                self:checkNodePlayRunEffect(_node)
            end
        end
    end
end

--获取可以滚动列
function MayanMysteryRespinView:findNextColRespinNode(_col)
    local colrespins = {}
    local col = 0
    for _index = _col, 5 do
        colrespins = {}
        for i = 1, #self.m_respinNodes do
            local repsinNode = self.m_respinNodes[i]
            if(repsinNode.p_colIndex == _index and repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK)then
                table.insert(colrespins, repsinNode)
            end
        end
    
        if(#colrespins > 0)then
            col = _index
            break
        end
    end
    return colrespins,col
 end
  
--[[
    播放图标落地音效
]]
function MayanMysteryRespinView:playSymbolDownSound(symbolType)
    
end

---获取所有参与结算节点
function MayanMysteryRespinView:getAllCleaningNode()
    local cleanNodes = MayanMysteryRespinView.super.getAllCleaningNode(self)
    return cleanNodes
end

--[[
    检测是否需要快滚(子类重写)
]]
function MayanMysteryRespinView:checkNeedQuickRun(respinNode)

    --是否为最后一次spin
    if self.m_reSpinCurCount and self.m_reSpinCurCount <= 1 then
        
    end

    return false
end

function MayanMysteryRespinView:getScaleMax()
    return cc.ScaleTo:create(10/60, 1.3)
end
  
function MayanMysteryRespinView:getScaleMin()
    return cc.ScaleTo:create(10/60, 1.0)
end

--[[
    显示快滚特效(子类重写)
]]
function MayanMysteryRespinView:showQuickRunEffect(respinNode)
    local pos = cc.p(respinNode:getPosition())

end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function MayanMysteryRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    self.m_machineRow = machineRow 
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    self:setMachineType(machineColmn, machineRow)
    self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
    self.m_machineElementData = machineElement
    for i=1,#machineElement do
        local nodeInfo = machineElement[i]
        local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

        local pos = self:convertToNodeSpace(nodeInfo.Pos)
        machineNode:setPosition(pos)
        self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
        machineNode:setVisible(nodeInfo.isVisible)
        if nodeInfo.isVisible then
            -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
        end
        if nodeInfo.Type == 92 or nodeInfo.Type == self.m_machine.SYMBOL_WILD_2 then
            local wildTimes = self.m_machine.m_runSpinResultData.p_selfMakeData.oldfixed_wild_times or 0
            local idleName = self.m_machine:getWildTimeLine(3, wildTimes)
            machineNode:runAnim(idleName, true)
        end
        if nodeInfo.Type == self.m_machine.SYMBOL_BONUS then
            machineNode:setScale(0.95)
        end
        local status = nodeInfo.status
        self:createRespinNode(machineNode, status)
    end

    local linesNode = util_createAnimation("MayanMystery_respinLines.csb")
    self:addChild(linesNode, REEL_SYMBOL_ORDER.REEL_ORDER_2 + 100)

    self:readyMove()
end

function MayanMysteryRespinView:createRespinNode(symbolNode, status)

    local respinNode = util_createView(self.m_respinNodeName)
    respinNode:setMachine(self.m_machine)
    respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
    respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
    respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
    respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)
    
    respinNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
    respinNode:setReelDownCallBack(function(symbolType, status)
      if self.respinNodeEndCallBack ~= nil then
            self:respinNodeEndCallBack(symbolType, status)
      end
    end, function(symbolType)
      if self.respinNodeEndBeforeResCallBack ~= nil then
            self:respinNodeEndBeforeResCallBack(symbolType)
      end
    end)
    local colorNode = util_createAnimation("Socre_MayanMystery_Empty.csb")
    colorNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
    self:addChild(colorNode, VIEW_ZORDER.REPSINNODE - 100)
    colorNode:setScale(1.05)

    self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
    
    respinNode:initClipNode(nil,130)
    -- respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
        util_changeNodeParent(self,symbolNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex)
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end

    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

--repsinNode滚动完毕后 置换层级
function MayanMysteryRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    if status == RESPIN_NODE_STATUS.LOCK then
        local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
        local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
        util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - endNode.p_rowIndex + endNode.p_cloumnIndex)
        endNode:setTag(self.REPIN_NODE_TAG)
        endNode:setPosition(pos)
    end
    self:runNodeEnd(endNode)

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
       gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
    end
end

function MayanMysteryRespinView:checkQuickCols(  )
    local p_reels = self.m_machine.m_runSpinResultData.p_reels
    local reels = self.m_machine.m_runSpinResultData.p_selfMakeData.respinReels or p_reels
    local columns = 0
    local cols = {}
    local count  = 0
    for _col = 1, 5 do
        count = 0
        for _row = 1, 3 do
            if(reels[_row][_col] == self.m_machine.SYMBOL_BONUS )then
            count = count + 1
            end
        end
    
        if(count == 2)then
            columns = columns + 1
            table.insert(cols, _col)
        end
    end
    self.m_quiclRunColDates = cols
end
  
function MayanMysteryRespinView:getQuickCols(  )
   
    return self.m_quiclRunColDates
end
  
function MayanMysteryRespinView:restQuickCols(  )
    self.m_quiclRunColDates = {}
end

function MayanMysteryRespinView:isLastSpin()
    local quickClos = self:getQuickCols()
    local respinCount = self.m_machine.m_reSpinCurCount
    if(#quickClos > 0 and respinCount == 0)then
        return true
    end
    return false
end

--[[
    添加respin光效框 整列
]]
function MayanMysteryRespinView:addRespinLightEffect(colIndex, isComeInRespin)
    local reelNode = self.m_machine.m_respinNodeView:findChild("sp_reel_" .. (colIndex - 1))
    if not self:getChildByTag(TAG_LIGHT + colIndex) then
        if self.m_isPlayKuangColSound then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_reel_man)
            local random = math.random(1, 100)
            if random <= 30 then
                if not self.m_isPlayWellDone then
                    self.m_isPlayWellDone = true
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_reel_man_wellDone)
                end
            end
        end
        if isComeInRespin or self.m_machine:getGameSpinStage() == QUICK_RUN then
            self.m_isPlayKuangColSound = false
        end

        local light_effect1 = util_createAnimation("MayanMystery_Bonus_jiman_2.csb")
        self:addChild(light_effect1, 1000)
        local reelSize = reelNode:getContentSize()
        local pos = cc.p(util_convertToNodeSpace(reelNode, self))
        light_effect1:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)
        light_effect1:runCsbAction("show", false,function()
            light_effect1:removeFromParent()
        end)

        -- 集满列
        local light_effect = util_createAnimation("MayanMystery_Bonus_jiman.csb")
        self:addChild(light_effect, VIEW_ZORDER.BGLIGHT+colIndex)
        light_effect:findChild("Node_lan"):setVisible(true)
        light_effect:runCsbAction("show", false,function()
            light_effect:runCsbAction("idle", true)
        end)
        
        light_effect:setTag(TAG_LIGHT + colIndex)
        local reelSize = reelNode:getContentSize()
        local pos = cc.p(util_convertToNodeSpace(reelNode, self))
        light_effect:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)
    
        self.m_effectNode_respinCol[colIndex] = light_effect
    end
end

--[[
      添加光效框 单个小块
]]
function MayanMysteryRespinView:addRespinLightEffectSingle(colIndex, isComeInRespin)
    local times = self.m_machine.m_runSpinResultData.p_reSpinCurCount
  
    local p_reels = self.m_machine.m_runSpinResultData.p_reels
    local reels = self.m_machine.m_runSpinResultData.p_selfMakeData.respinReels or p_reels
    local link_count = 0
    local last_index = -1
    for rowIndex = 1, self.m_machine.m_iReelRowNum do
        if reels[rowIndex][colIndex] == self.m_machine.SYMBOL_BONUS then
            link_count = link_count + 1
        else
            last_index = rowIndex
        end
    end
  
    if link_count > 2 then
        if(link_count == 3)then
            if(self.m_effectNode_respin[colIndex])then
                local tips = self.m_effectNode_respin[colIndex]
                tips:runCsbAction("over", false,function()
                    tips:setVisible(false)
                    tips:removeFromParent()
                    self.m_effectNode_respin[colIndex] = nil
                    if self.m_quickRunSound[colIndex] then
                        gLobalSoundManager:stopAudio(self.m_quickRunSound[colIndex])
                        self.m_quickRunSound[colIndex] = nil
                    end
                end)
            end

            self:addRespinLightEffect(colIndex, isComeInRespin)
            return 3
        end
    end
  
    if link_count == 2 and last_index ~= -1 then
        local allEndNode = self:getAllEndSlotsNode()
        for _, endNode in ipairs(allEndNode) do
            if endNode.p_symbolType ~= self.m_machine.SYMBOL_BONUS and endNode.p_cloumnIndex == colIndex then
                if not self.m_effectNode_respin[colIndex] then
                    local light_effect = util_createAnimation("MayanMystery_respin_tishi.csb")
                    light_effect:runCsbAction("start", false,function()
                        light_effect:runCsbAction("idle", true)
                    end)
                    if self.m_isPlayKuangSound then
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_kuang_start)
                    end
                    if isComeInRespin or self.m_machine:getGameSpinStage() == QUICK_RUN then
                        self.m_isPlayKuangSound = false
                    end
                    
                    self:addChild(light_effect, TOP_ZORDER+colIndex)
                    self.m_effectNode_respin[colIndex] = light_effect
                    light_effect:setPosition(util_convertToNodeSpace(endNode, self))
                else
                    self:playDaiJiqi(colIndex, endNode)
                end
        
                break
            end
        end
    end
    return nil
end

--播放待集齐效果
function MayanMysteryRespinView:playDaiJiqi( colindex, endNode )
    if(self.m_effectNode_respin[colindex] and not self.m_effectNode_respin[colindex]:isVisible())then
        self.m_effectNode_respin[colindex]:show()
        self.m_effectNode_respin[colindex]:runCsbAction("start", false,function()
            self.m_effectNode_respin[colindex]:runCsbAction("idle", true)
        end)
    end
end

--[[
  随机列 定格特效
]]
function MayanMysteryRespinView:addRespinSelectedEffect(colIndex)
    local reelNode = self.m_machine.m_respinNodeView:findChild("sp_reel_" .. (colIndex - 1))
    if not self:getChildByTag(TAG_SELECT + colIndex) then
        local light_effect = util_createAnimation("MayanMystery_Bonus_jiman_2.csb")
        self:addChild(light_effect, VIEW_ZORDER.MAX)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_col_select)
        light_effect:setTag(TAG_SELECT + colIndex)
        local reelSize = reelNode:getContentSize()
        local pos = cc.p(util_convertToNodeSpace(reelNode, self))
        light_effect:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)
        light_effect:runCsbAction("actionframe", false,function()
            light_effect:removeFromParent()
        end)
    end
end

function MayanMysteryRespinView:randomMultipleCol(cols, stopIndex )
    local effects = {}
    local effectsUp = {}
    self.m_stopIndex = stopIndex
    for _index = 1, #cols do
        local node = self.m_effectNode_respinCol[cols[_index]]
        table.insert(effects, node)

        local reelNode = self.m_machine.m_respinNodeView:findChild("sp_reel_" .. (cols[_index] - 1))
        local light_effect1 = util_createAnimation("MayanMystery_Bonus_jiman_2.csb")
        self:addChild(light_effect1, 500)
        local reelSize = reelNode:getContentSize()
        local pos = cc.p(util_convertToNodeSpace(reelNode, self))
        light_effect1:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)
        light_effect1:runCsbAction("run", true)
        light_effect1:setVisible(false)
        table.insert(effectsUp, light_effect1)
    end
    
    if not self.m_scheduleRandomNode then
        self.m_scheduleRandomNode = cc.Node:create()
        self:addChild(self.m_scheduleRandomNode)
    end

    local index = 1
    local needDt = 0.25
    local schedt = 0
    local totaltime = 0
    local totalColNum = 0
  
    local function _stopEffect()
        self.m_scheduleRandomNode:unscheduleUpdate()
        self:addRespinSelectedEffect(stopIndex)
        
        for _, _node in ipairs(effectsUp) do
            _node:removeFromParent()
        end
        effectsUp = {}

        local anim = effects[index]
        if not tolua.isnull(anim) then
            anim:playAction("show2",false,function()
                anim:playAction("idle2",true)
            end)
        end

        local noSelect = {}
        for _, _col in ipairs(cols) do
            if _col ~= stopIndex then
                table.insert(noSelect, _col)
            end
        end
        self.m_machine:showColorLayerByRespin(noSelect)
    end
  
    local function _update()
        totalColNum = totalColNum + 1
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_random_col)
        effects[index]:playAction("idle1",true)
        effectsUp[index]:setVisible(true)
        effects[index]:setVisible(true)
    
        needDt = needDt - 0.05
        
        --加速
        if(needDt <= 0.11)then
            needDt = 0.11
        end
        
        --减速
        if(totalColNum >= 9)then
            needDt = needDt + 0.15
            if needDt > 0.5 then
                needDt = 0.5
            end
        end
    
        for i,v in ipairs(effects) do
            if(i~=index)then
                v:setVisible(false)
                effectsUp[i]:setVisible(false)
            end
        end
            
        if(cols[index] == stopIndex)then
            local endTime = 2.7
            if #cols > 2 then --每多一列 加0.5秒
                endTime = endTime + 0.5 * (#cols - 1)
            end
            --判读时间是否还够跑
            if(totaltime > endTime)then
                --时间够了.停这里。
                _stopEffect()
            end
        end
  
        index = index + 1
        if(index > #effects)then
            index = 1
        end
    end
  
    self.m_scheduleRandomNode:unscheduleUpdate()
    self.m_scheduleRandomNode:onUpdate( function( dt )
        schedt = schedt + dt
        totaltime = totaltime + dt
    
        if(schedt >= needDt)then
            _update()
            schedt = 0
        end
    end)
end

--[[
    停止加倍等待
]]
function MayanMysteryRespinView:stopRuneffect( colindex )
    local node = self.m_effectNode_respinCol[colindex]
    if not tolua.isnull(node) then
        node:playAction("over",false,function()
            node:playAction("actionframe",false,function()
                node:playAction("idle1",true)
            end)
        end)
    end
end

--[[
    乘倍加钱
]]
function MayanMysteryRespinView:updateMultiple(col, mult, callBack)
    local columnsBonus = {}
    local bonus = self:getAllCleaningNode()
  
    for i,slot in ipairs(bonus) do
        if(slot.p_cloumnIndex == col)then
            table.insert(columnsBonus,slot)
        end
    end
    
    local delay = 0
    for _mulIndex = 2, mult do
        for i = 1,#columnsBonus do
            local p_bonus = columnsBonus[i]
            local idex = self.m_machine:getPosReelIdx(p_bonus.p_rowIndex, p_bonus.p_cloumnIndex)
            local coin = self.m_machine:getReSpinSymbolScore(idex)
            local totalcoin = coin
            local temp_mult = self.m_machine.m_respinColMul[col]
            totalcoin = totalcoin * temp_mult

            local actions = {}
            local money = totalcoin * _mulIndex
            
            actions[#actions + 1] = cc.DelayTime:create(delay)
            actions[#actions + 1] = cc.CallFunc:create(function()
                p_bonus:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + 100)
                self.m_machine:changeBonusCoins(p_bonus, money, true)
                self.m_machine.m_respinRoll:playItemXbei()
                p_bonus:runAnim("xbei", false, function()
                    p_bonus:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - p_bonus.p_rowIndex + p_bonus.p_cloumnIndex)
                end)
            end)

            p_bonus:runAction(cc.Sequence:create(actions))
        end
        performWithDelay(self,function ()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_bonus_coins_add)
        end, delay)
    
        delay = delay + 18 / 30 + 0.15
    end
  
    performWithDelay(self,function ()
        if callBack then
            callBack()
        end
    end,
    delay + 1)
end

--[[
    播放加倍等待
]]
function MayanMysteryRespinView:playRuneffect( colindex )
    self.m_stopIndex = colindex
    local node = self.m_effectNode_respinCol[colindex]
    if not tolua.isnull(node) then
        node:playAction("show2",false,function()
            node:playAction("idle2",true)
        end)
    end
end

--[[
    停止快滚音效
]]
function MayanMysteryRespinView:stopQuickRunSound( )
    for _, _soundId in pairs(self.m_quickRunSound) do
        if _soundId then
            gLobalSoundManager:stopAudio(_soundId)
        end
    end
    self.m_quickRunSound = {}
end

--移除所有光效框
function MayanMysteryRespinView:removeAllSingle()
    self:stopQuickRunSound()

    for _, effnode in pairs(self.m_effectNode_respin) do
        if not tolua.isnull(effnode) then
            effnode:playAction("over", false,function()
                effnode:setVisible(false)
                effnode:removeFromParent()
            end)
        end
    end
    self.m_effectNode_respin = {}
end
  
--移除待集齐和集齐
function MayanMysteryRespinView:removeAllColEffect()
    for _, effnode in pairs(self.m_effectNode_respinCol) do
        if not tolua.isnull(effnode) then
            effnode:setVisible(false)
            effnode:playAction("over2", false,function()
                effnode:setVisible(false)
                effnode:removeFromParent()
            end)
        end
    end
    self.m_effectNode_respinCol = {}
end

--判断RespinNode是否播放快滚效果.放大
--_respinNode:
function MayanMysteryRespinView:checkNodePlayRunEffect(_respinNode)
    local quickClos = self:getQuickCols()
  
    local respinCount = self.m_machine.m_reSpinCurCount
    if self:isLastSpin() then
        if _respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK and table.indexof(quickClos, _respinNode.p_colIndex) then
            if self.m_effectNode_respin[_respinNode.p_colIndex] then
                self:stopQuickRunSound()
                self.m_quickRunSound[_respinNode.p_colIndex] = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_quickRun)

                self.m_effectNode_respin[_respinNode.p_colIndex]:show()
                self.m_effectNode_respin[_respinNode.p_colIndex]:runAction(self:getScaleMax())
                self.m_effectNode_respin[_respinNode.p_colIndex]:setLocalZOrder( _respinNode.p_colIndex + TOP_ZORDER*2)

                if _respinNode then
                    _respinNode.m_isPlayQuickRun = true
                    _respinNode:runAction(self:getScaleMax())
                    _respinNode:setLocalZOrder(TOP_ZORDER*2)
                end
            end
        end
    end
end

--找到这列 空格子位置
function MayanMysteryRespinView:getNullNodePosByCol( _col )
    local pos = {iX = 0, iY = 0}
    for _, endNode in pairs(self.m_respinNodes) do
        if (
            endNode.m_lastNode and endNode.m_lastNode.p_cloumnIndex == _col and endNode.m_lastNode.p_symbolType ~= self.m_machine.SYMBOL_BONUS
            and endNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK
        )
        then
            --
            pos.iX = endNode.m_lastNode.p_cloumnIndex
            pos.iY = endNode.m_lastNode.p_rowIndex
            break
        end
    end
    return pos
end

function MayanMysteryRespinView:stopQuickRunEffect( endNode )
    local respinNode = nil
    for i=1,#self.m_respinNodes do
        local rspNode = self.m_respinNodes[i]
        if rspNode.p_colIndex == endNode.p_cloumnIndex and rspNode.p_rowIndex == endNode.p_rowIndex then
            respinNode = rspNode
            break
        end
    end
  
    --如果这个位置还是空 那么恢复速度
    local pos = self:getNullNodePosByCol(endNode.p_cloumnIndex)
    if pos.iX == endNode.p_cloumnIndex and pos.iY == endNode.p_rowIndex then
        if self.m_machine.m_reSpinCurCount == 0 then
            if respinNode then
                respinNode:changeRunSpeed(false)
                respinNode:changeResDis(false)
            end
        end
    end
    if self.m_machine.m_reSpinCurCount == 0 then
        local temp_colIndex = endNode.p_cloumnIndex   --endNode 有可能被释放掉这里记录下他的列
        if self.m_effectNode_respin[temp_colIndex] then
            self.m_effectNode_respin[temp_colIndex]:runAction(cc.Sequence:create(
                self:getScaleMin(),
                cc.CallFunc:create(function()
                    if self.m_effectNode_respin[temp_colIndex] then
                        self.m_effectNode_respin[temp_colIndex]:runCsbAction("idle", true)
                    end
                end)
            ))
            self.m_effectNode_respin[temp_colIndex]:setLocalZOrder(TOP_ZORDER + temp_colIndex)
                
            if respinNode then
                respinNode.m_isPlayQuickRun = false
                respinNode:runAction(self:getScaleMin())
                respinNode:setLocalZOrder(VIEW_ZORDER.REPSINNODE)
            end

            if self.m_quickRunSound[temp_colIndex] then
                gLobalSoundManager:stopAudio(self.m_quickRunSound[temp_colIndex])
                self.m_quickRunSound[temp_colIndex] = nil
            end
        end
    end
end

function MayanMysteryRespinView:startMove()
    self.m_isPlayKuangSound = true
    self.m_isPlayKuangColSound = true
    self.m_isPlayWellDone = false
    self.m_quickRunSound = {}
    self:stopQuickRunSound()

    --找到第一列快滚列
    local colrespins,p_beginRunColindex = self:findNextColRespinNode(1)
    local quickClos = self:getQuickCols()
  
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    for i=1,#self.m_respinNodes do
        if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
            self.m_respinNodes[i]:startMove()
    
            local repsinNode = self.m_respinNodes[i]
            if self:isLastSpin() then
                --有快滚列
                --且是spin最后一次才快滚
                if(
                    repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK
                    and
                    table.indexof(quickClos,repsinNode.p_colIndex)
                )then
                    repsinNode:changeRunSpeed(true)
                    repsinNode:changeResDis(true)
        
                    if p_beginRunColindex == repsinNode.p_colIndex then
                        self:checkNodePlayRunEffect(repsinNode)
                    end
                end
            end
        end
    end
    if self:isLastSpin() then
        if table.nums(self.m_effectNode_respin) > 0 then
            for _col, _effectNode in pairs(self.m_effectNode_respin) do
                if not tolua.isnull(_effectNode) then
                    _effectNode:runCsbAction("run", true)
                end
            end
        end
    end
end

function MayanMysteryRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    local runLongList = {}
  
    local respinCount = self.m_machine.m_reSpinCurCount
    local quickClos = self:getQuickCols()
  
    local baseLong = self.m_baseRunNum
    local def = BASE_COL_INTERVAL
  
    local runLongClos = {baseLong,def,def,def,def}
  
    for j = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local bFix = false
    
        local longRunTotalNum = 0
    
        local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
    
        if self:isLastSpin() then
            local longRunStartReel = quickClos[1]
            local longNum = math.floor( 2.5 * (MOVE_SPEED * 2) / self.m_slotNodeHeight )
            local interval = BASE_COL_INTERVAL
    
            if(table.indexof(quickClos,repsinNode.p_colIndex))then
                runLongClos[repsinNode.p_colIndex] = longNum
            else
                runLongClos[repsinNode.p_colIndex] = interval
            end
        end
    
        for i = 1, #storedNodeInfo do
            local stored = storedNodeInfo[i]
            if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                if self:isLastSpin() then
                    repsinNode:setRunInfo(0, stored.type)
                else
                    repsinNode:setRunInfo(runLong, stored.type)
                end
                bFix = true
            end
        end
    
        for i = 1, #unStoredReels do
            local data = unStoredReels[i]
            if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                if self:isLastSpin() then
                    repsinNode:setRunInfo(0, data.type)
                else
                    repsinNode:setRunInfo(runLong, data.type)
                end
            end
        end
    end
    --找到第一列滚动块
    self.m_reelRunDatas = runLongClos
    
    if self:isLastSpin() then
        self:runRespinNode(1)
    end
end

function MayanMysteryRespinView:oneReelDown(colIndex)
    self.m_machine:respinOneReelDown(colIndex,self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP)
end

return MayanMysteryRespinView 