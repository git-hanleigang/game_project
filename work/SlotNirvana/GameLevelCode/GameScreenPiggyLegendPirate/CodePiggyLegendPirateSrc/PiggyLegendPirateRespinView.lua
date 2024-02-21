local PiggyLegendPirateRespinView = class("PiggyLegendPirateRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

--repsinNode滚动完毕后 置换层级
function PiggyLegendPirateRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS1 then
                local reSpinNodePos = self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
                -- if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
                --     util_changeNodeParent(self,endNode,VIEW_ZORDER.REPSINNODE+20000)
                -- else
                    util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex + endNode.p_cloumnIndex)
                -- end
            end
            
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
        self.m_machine:waitWithDelay(0.2, function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
        end)
      end
end
--结束滚动播放落地
function PiggyLegendPirateRespinView:runNodeEnd(endNode)


    if endNode and endNode.p_symbolType == self.m_machine.SYMBOL_BONUS1  then

        local info = self:getEndTypeInfo(endNode.p_symbolType)
        if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            local reSpinNodePos = self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
            -- if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
            --     endNode:setScale(1.1)
            -- end
            self:playBonus1BulingSound(endNode.p_cloumnIndex, reSpinNodePos)
            
            endNode:runAnim(info.runEndAnimaName, false,function()
                local chipList = self:getAllCleaningNode()
                if self.m_machine.m_isPlayReSpinQuick and #chipList >= 15 then
                    endNode:runAnim("idle2",true)
                else
                    endNode:runAnim("idle2",true)
                end
                self:changeQuickNodeScale(endNode,true)
            end)
        end
    end

    if endNode and endNode.p_symbolType == self.m_machine.SYMBOL_BONUS3 then
        local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
        local bonus3Pos = self.m_machine:findChild("Node_respinBonus"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
        local bonus3TempNode =  util_spineCreate("Socre_PiggyLegendPirate_Bonus3", true, true) 
        self.m_machine:findChild("Node_respinBonus"):addChild(bonus3TempNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+10)
        
        local reSpinNodePos = self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
        -- if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
        --     bonus3TempNode:setScale(self.m_machine.m_machineRootScale*1.1)
        -- else
        --     bonus3TempNode:setScale(self.m_machine.m_machineRootScale)
        -- end
        bonus3TempNode:setPosition(bonus3Pos)
        bonus3TempNode.p_rowIndex = endNode.p_rowIndex
        bonus3TempNode.p_cloumnIndex = endNode.p_cloumnIndex
        util_spinePlay(bonus3TempNode,"buling",false)
        util_spineEndCallFunc(bonus3TempNode,"buling",function ()
            -- util_spinePlay(bonus3TempNode,"idle",false)
            self:changeQuickNodeScale(bonus3TempNode,true,true)
        end)
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_zhadan.mp3")
    end
    if endNode and endNode.p_symbolType == self.m_machine.SYMBOL_BONUS2 then
        self:changeQuickNodeScale(endNode,false)
    end
    --
end

function PiggyLegendPirateRespinView:changeQuickNodeScale(endNode,isPlay,isBonus3)
    -- local reSpinNodePos = self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
    -- if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
    --     if self.m_machine.m_respinView.m_lastOneTip.repsinNode and self.m_machine.m_respinView.m_lastOneTip.repsinNode.m_clipNode then
    --         local repsinNode = self.m_machine.m_respinView.m_lastOneTip.repsinNode.m_clipNode
    --         local scaleAction= cc.ScaleTo:create( 0.2, 1)
    --         local end_call =
    --             cc.CallFunc:create(
    --             function()
    --                 util_changeNodeParent(self.m_machine.m_respinView.m_lastOneTip.repsinNode.oldParent,repsinNode,1)
    --                 repsinNode:setPosition(self.m_machine.m_respinView.m_lastOneTip.repsinNode.position)
    --                 self.m_machine.m_respinView:removeChildByName("newClipNode")
    --                 self.m_machine.m_respinView:changeLastOneAnimTipVisible(false)
    --                 self.m_machine.m_reSpinBonusQuickPos = self.m_machine.m_runSpinResultData.p_rsExtraData.bonus3NextPos
    --             end
    --         )
    --         -- self.m_machine.m_respinView.m_lastOneTip.repsinNode.newClipNode:setScale(1)
    --         repsinNode:runAction( cc.Sequence:create(scaleAction,end_call))

    --         local scaleAction1 = cc.ScaleTo:create( 0.2, 1)
    --         self.m_machine.m_respinView.m_lastOneTip:runAction( cc.Sequence:create(scaleAction1 ))

    --         if isPlay then
    --             local scale = 1
    --             if isBonus3 then
    --                 scale = self.m_machine.m_machineRootScale
    --             end
    --             local scaleAction2 = cc.ScaleTo:create( 0.2, scale)
    --             local end_call2 =
    --             cc.CallFunc:create(
    --             function()
    --                 if endNode.p_symbolType and endNode.p_symbolType == self.m_machine.SYMBOL_BONUS1 then
    --                     endNode:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex + endNode.p_cloumnIndex)
    --                 end
    --             end)
                
    --             endNode:runAction( cc.Sequence:create(scaleAction2 ,end_call2))
    --         end
    --         -- local scaleAction2 = cc.ScaleTo:create( 0.5, 1)
    --         -- local end_call2 =
    --         --     cc.CallFunc:create(
    --         --     function()
    --         --         self.m_machine.m_respinView.m_lastOneTip.repsinNode.newClipNode:removeFromParent()
    --         --     end
    --         -- )
    --         -- self.m_machine.m_respinView.m_lastOneTip.repsinNode.newClipNode:runAction( cc.Sequence:create(scaleAction2,end_call2 ))
    --     end
    -- end
end

function PiggyLegendPirateRespinView:oneReelDown()
    
end

function PiggyLegendPirateRespinView:playBonus1BulingSound(col, reSpinNodePos)
    
    if self.m_machine.m_respinQuickStop then
        if not self.m_machine.m_respinBulingSound[col] then
            for i=1,5 do
                self.m_machine.m_respinBulingSound[i] = true
            end
            
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_BonusDown.mp3")
        end
    else
        if not self.m_machine.m_respinBulingSound[col] then
            self.m_machine.m_respinBulingSound[col] = true
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_BonusDown.mp3")
        end
    end
    if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_BonusDown.mp3")
    end 
end


-- bonus3 提示
function PiggyLegendPirateRespinView:playBonus3TipAnim(repsinNode)
    if repsinNode then
        local blank_symbol = repsinNode
        if(not self.m_lastOneTip)then
            if blank_symbol then

                self.m_lastOneTip = util_createAnimation("PiggyLegendPirate_respin_tishi.csb")
                self:addChild(self.m_lastOneTip, VIEW_ZORDER.REPSINNODE+10000)
        
                local wordPos = blank_symbol:getParent():convertToWorldSpace(cc.p(blank_symbol:getPosition()))
                self.m_lastOneTip:setPosition(self.m_lastOneTip:getParent():convertToNodeSpace(wordPos))
                self.m_lastOneTip:runCsbAction("actionframe", true)
                self.m_lastOneTip.repsinNode = repsinNode
            end
        else
            local wordPos = blank_symbol:getParent():convertToWorldSpace(cc.p(blank_symbol:getPosition()))
            self.m_lastOneTip:setPosition(self.m_lastOneTip:getParent():convertToNodeSpace(wordPos))
            self.m_lastOneTip:runCsbAction("actionframe", true)
            self.m_lastOneTip:setVisible(true)
            self.m_lastOneTip.repsinNode = repsinNode
        end
    end
end

function PiggyLegendPirateRespinView:changeLastOneAnimTipVisible(_visible)
    if(self.m_lastOneTip)then
        self.m_lastOneTip:setVisible(_visible)
    end
end

--[[
    重写接口
]]
-- 处理单格快滚
function PiggyLegendPirateRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    print("[PiggyLegendPirateRespinView:setRunEndInfo]")
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local bFix = false 

        local runData = self:getReSpinNodeRunData(repsinNode,repsinNode.p_colIndex, repsinNode.p_rowIndex)
        local runLong = runData.runLong

        for i=1, #storedNodeInfo do
            local stored = storedNodeInfo[i]
            if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                repsinNode:setRunInfo(runLong, stored.type)
                repsinNode:setRunSpeed(runData.runSpeed)

                bFix = true
            end
        end
        
        for i=1,#unStoredReels do
            local data = unStoredReels[i]
            if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                repsinNode:setRunInfo(runLong, data.type)
                repsinNode:setRunSpeed(runData.runSpeed)
            end
        end
    end
end
-- 处理快滚的提示动效
function PiggyLegendPirateRespinView:startMove()

    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local reSpinNodePos = self.m_machine:getPosReelIdx(repsinNode.p_rowIndex, repsinNode.p_colIndex)
        if self.m_machine.m_reSpinBonusQuickPos and reSpinNodePos == self.m_machine.m_reSpinBonusQuickPos then
            
            -- local startPos = repsinNode:getParent():convertToWorldSpace(cc.p(repsinNode:getPosition()))
            -- local startPosWorld = self:convertToNodeSpace(startPos)

            -- local nodeHeight = self.m_slotReelHeight / self.m_machineRow
            -- local size = cc.size(self.m_slotNodeWidth*1.1,nodeHeight*1.1 + 1)
            -- startPosWorld.x = startPosWorld.x - self.m_slotNodeWidth*1.1 / 2
            -- startPosWorld.y = startPosWorld.y - nodeHeight*1.1 / 2

            -- local newClipNode = util_createOneClipNode(RESPIN_CLIPMODE.RECT,size,startPosWorld)
            -- newClipNode:setAnchorPoint(cc.p(0.5,0.5))
            -- self:addChild(newClipNode,VIEW_ZORDER.REPSINNODE+9999)
            -- newClipNode:setName("newClipNode")

            -- repsinNode.oldParent = repsinNode.m_clipNode:getParent()
            -- repsinNode.position = cc.p(repsinNode.m_clipNode:getPosition())
            -- repsinNode.newClipNode = newClipNode

            -- util_changeNodeParent(newClipNode,repsinNode.m_clipNode,VIEW_ZORDER.REPSINNODE+9999)
            
            -- startPosWorld.x = startPosWorld.x + self.m_slotNodeWidth*1.1/ 2
            -- startPosWorld.y = startPosWorld.y + nodeHeight*1.1 / 2
            -- repsinNode.m_clipNode:setPosition(startPosWorld)

            self:playBonus3TipAnim(repsinNode)
            -- local scaleAction = cc.ScaleTo:create( 0.5, 1.1)
            -- local end_call =
            --             cc.CallFunc:create(
            --             function()
            --             end
            --         )
            -- repsinNode.m_clipNode:runAction( cc.Sequence:create(scaleAction, end_call ))

            -- local scaleAction1 = cc.ScaleTo:create( 0.5, 1.1)
            -- self.m_lastOneTip:runAction( cc.Sequence:create(scaleAction1 ))
            
            local chipList = self:getAllCleaningNode()
            if #chipList >= 15 then
                self.m_machine.m_isPlayReSpinQuick = true
                -- self:playIdle3ByQuick()
            end
        end
    end

    PiggyLegendPirateRespinView.super.startMove(self)
end


--[[
    其他工具
]]
-- 每个格子的滚动数据
function PiggyLegendPirateRespinView:getReSpinNodeRunData(repsinNode,_iCol, _iRow)
    local MOVE_SPEED = 1500     --滚动速度 像素/每秒
    repsinNode:setRunDis(20)

    local data = {
        isQuickRun = false,
        runLong    = self.m_baseRunNum + (_iCol- 1) * 3,
        runSpeed   = MOVE_SPEED
    }

    local chipList = self:getAllCleaningNode()
    if #chipList >= 15 then
        local reSpinNodePos = self.m_machine:getPosReelIdx(_iRow, _iCol)
        
        if reSpinNodePos == self.m_machine.m_reSpinBonusQuickPos then
            data.runLong  = data.runLong  * 3
            data.runSpeed = data.runSpeed * 3
            repsinNode:setRunDis(65)
        end
    else
        local reSpinNodePos = self.m_machine:getPosReelIdx(_iRow, _iCol)
        
        if reSpinNodePos == self.m_machine.m_reSpinBonusQuickPos then
            -- if _iCol < 3 then
            --     data.runLong  = data.runLong + 13
            -- else
            --     data.runLong  = data.runLong + 7
            -- end
            repsinNode:setRunDis(65)
        end
    end

    return data
end

-- 快滚的时候 小猪 播放idle3
function PiggyLegendPirateRespinView:playIdle3ByQuick( )
    local chipList = self:getAllCleaningNode()
    for i,vNode in ipairs(chipList) do
        vNode:runAnim("idle3_start", false,function()
            vNode:runAnim("idle3",true)
        end)
    end
end

--快滚结束的时候
function PiggyLegendPirateRespinView:playIdle3ByQuickOver( )
    -- local chipList = self:getAllCleaningNode()
    -- for i,vNode in ipairs(chipList) do
    --     vNode:runAnim("idle3_over", false,function()
    --         vNode:runAnim("idle2",true)
    --     end)
    -- end
end

--结束的时候
function PiggyLegendPirateRespinView:playActionframe3ByQuickOver()
    local chipList = self:getAllCleaningNode()
    -- gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_over_bonusSaoGuang.mp3")

    for i,vNode in ipairs(chipList) do
        vNode:runAnim("idle2",true)
    end
end

function PiggyLegendPirateRespinView:getSymbolQuickPos()
    local list = {}

    local chipList = self:getAllCleaningNode()

    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local isHave = false
            for i,v in ipairs(chipList) do
                if v.p_cloumnIndex == iCol and v.p_rowIndex == iRow then
                    isHave = true
                end
            end
            if not isHave then
                local reSpinNodePos = self.m_machine:getPosReelIdx(iRow, iCol)
                table.insert(list, reSpinNodePos)
            end
        end
        
    end
    if #list > 0 then
        local random = math.random(1, #list)
        return list[random]
    end
    return nil
end

-- 获取信号小块
function PiggyLegendPirateRespinView:getPiggyLegendPirateSymbolNode(iX, iY)
    local symbolNode = nil

    local reSpinNode = self:getRespinNode(iX, iY)
    if reSpinNode and reSpinNode.m_lastNode then
        return reSpinNode.m_lastNode
    end

    print("[PiggyLegendPirateRespinView:getPiggyLegendPirateSymbolNode] error ",iY,iX)
    return nil
end

-- 获取信号小块
function PiggyLegendPirateRespinView:getPiggyLegendPirateBonus1Node(iX, iY)
    local symbolNode = nil

    local childs = self:getAllCleaningNode()

    local reSpinChildren = nil
    for i=1,#childs do
        local node = childs[i]
        if iX == node.p_rowIndex and iY == node.p_cloumnIndex then
            reSpinChildren = node
        end
    end
    if reSpinChildren then
        return reSpinChildren
    end

    return nil
end

--
function PiggyLegendPirateRespinView:getSymbolList(_symbolType)
    local list = {}

    local childs = self:getChildren()

    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local symbol = self:getPiggyLegendPirateSymbolNode(iRow, iCol)
            if symbol and _symbolType == symbol.p_symbolType then
                list[#list + 1] =  symbol
            end
        end
        
    end

    return list
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function PiggyLegendPirateRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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

        local status = nodeInfo.status
        if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(machineNode.p_symbolType) == true then
            machineNode:runAnim("idle2",true)
        end
        self:createRespinNode(machineNode, status)

    end

    self.m_respinXian = util_createAnimation("PiggyLegendPirate_respinqipanxian.csb")
    self:addChild(self.m_respinXian, 100)

    -- self.m_respinXian = self.m_machine:findChild("Node_respinqipanxian")
    -- util_changeNodeParent(self, self.m_respinXian, 100)


    self:readyMove()
end

return PiggyLegendPirateRespinView
