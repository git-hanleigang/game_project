---
--xcyy
--2018年5月23日
--AtlantisRespinView.lua
local RespinView = util_require("Levels.RespinView")
local AtlantisRespinView = class("AtlantisRespinView",RespinView)

local BASE_COL_INTERVAL = 1

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}
local TAG_LIGHT_SINGLE = 1001   --光效tag

local LIGHT_EFFECT = {
    "Yugao_Atlantis_2.csb",
    "Yugao_Atlantis_1.csb",
    "Yugao_Atlantis_0.csb",
    "Yugao_Atlantis.csb",
}

--滚动参数
local BASE_RUN_NUM = 20

function RespinView:initUI(respinNodeName)
    self.m_respinNodeName = respinNodeName 
    self.m_baseRunNum = BASE_RUN_NUM
 end

AtlantisRespinView.m_reSpinCurCount = 3
AtlantisRespinView.m_bonus_count = 0

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function AtlantisRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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
                print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
          end

          local status = nodeInfo.status
            if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(machineNode.p_symbolType) == true then
                  machineNode:runAnim("idleframe",true)
            end
          self:createRespinNode(machineNode, status)
    end

    self:readyMove()
end

function AtlantisRespinView:createRespinNode(symbolNode, status)

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

    self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
    
    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
    else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

    --快滚小块光效
    self.m_single_lights = {}
    --快滚小块信息
    self.m_qucikRespinNode = {}

end

--组织滚动信息 开始滚动
function AtlantisRespinView:startMove()
    self.m_machine:respinStartRun()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    self.m_reSpinCurCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount or 3
    if not self.m_machine.m_runSpinResultData.p_reSpinCurCount then
        release_print("**************Atlantis:p_reSpinCurCount is nil on startMove**************")
    end
    
    self.m_bonus_count = 0
    for i=1,#self.m_respinNodes do
          if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
            self.m_respinNodes[i]:startMove()
          else
            self.m_bonus_count = self.m_bonus_count + 1
          end
    end
    
end

--[[
    移除快滚框
]]
function AtlantisRespinView:removeLight(respinNode)
    local nodeTag = self.m_machine:getNodeTag(respinNode.p_colIndex,respinNode.p_rowIndex,SYMBOL_NODE_TAG)
    if respinNode.m_runLastNodeType == self.m_machine.SYMBOL_BONUS_LINK then
        --落地音效
        gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_bonus_down.mp3")
    end
    for index=1,#self.m_qucikRespinNode do
        local quickRunInfo = self.m_qucikRespinNode[index]
        if quickRunInfo.key == nodeTag then
            if self.m_single_lights[nodeTag] then
                self.m_single_lights[nodeTag]:removeFromParent(true)
            end
            break;
        end
    end
    
end

function AtlantisRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    local quickIndex = 0
    self.m_qucikRespinNode = {}
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local bFix = false 
        local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
        repsinNode:changeRunSpeed(false)
        repsinNode:changeResDis(false)
        --bonus数量
        local bonus_count = 0
        if self.m_machine.m_runSpinResultData.p_storedIcons then
            bonus_count = #self.m_machine.m_runSpinResultData.p_storedIcons
        end
        if not self.m_bonus_count then
            release_print("**************Atlantis:m_bonus_count is nil on setRunEndInfo**********")
        end
        if not self.m_reSpinCurCount then
            release_print("**************Atlantis:m_reSpinCurCount is nil on setRunEndInfo********")
        end
        if repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK and
          ((self.m_bonus_count and self.m_bonus_count >= 11) and 
          (self.m_reSpinCurCount and  self.m_reSpinCurCount <= 1)) then
            quickIndex = quickIndex + 1
            if self.m_bonus_count == 11 then
                if quickIndex == 1 then
                    runLong = quickIndex * 17
                else
                    runLong = quickIndex * 17 + (quickIndex - 1) * 17
                end
                
            elseif self.m_bonus_count == 12 then
                if quickIndex == 1 then
                    runLong = quickIndex * 25
                else
                    runLong = quickIndex * 25 + (quickIndex - 1) * 17
                end
            elseif self.m_bonus_count == 13 then
                if quickIndex == 1 then
                    runLong = quickIndex * 35
                else
                    runLong = quickIndex * 35
                end
            elseif self.m_bonus_count == 14 then
                runLong = quickIndex * 44
            end
            
            repsinNode:changeRunSpeed(true)
            repsinNode:changeResDis(true)
            --存储快滚的小块
            self.m_qucikRespinNode[#self.m_qucikRespinNode + 1] = {
                key = self.m_machine:getNodeTag(repsinNode.p_colIndex,repsinNode.p_rowIndex,SYMBOL_NODE_TAG),
                node = repsinNode
            }
        end

        for i=1, #storedNodeInfo do
            local stored = storedNodeInfo[i]
            if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                    repsinNode:setRunInfo(runLong, stored.type)
                    bFix = true
            end
        end
        
        for i=1,#unStoredReels do
            local data = unStoredReels[i]
            if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                    repsinNode:setRunInfo(runLong, data.type)
            end
        end
    end

    self:runQuickEffect()
end

--[[
      快滚特效
]]
function AtlantisRespinView:runQuickEffect()
    self.m_machine.m_lightEffectNode:removeAllChildren(true)
    for index=1,#self.m_qucikRespinNode do
        local quickRunInfo = self.m_qucikRespinNode[index]
        if not quickRunInfo.isEnd then
            if self.m_quickSoundId then
                gLobalSoundManager:stopAudio(self.m_quickSoundId)
                self.m_quickSoundId = nil
            end
            self.m_quickSoundId = gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_respin_quick_run.mp3")
            local light_effect = util_createAnimation(LIGHT_EFFECT[15 - self.m_bonus_count])
            light_effect:runCsbAction("run2",true)  --普通滚动状态
            self.m_machine.m_lightEffectNode:addChild(light_effect)
            light_effect:setPosition(util_convertToNodeSpace(quickRunInfo.node,self.m_machine.m_lightEffectNode))
            break;
        end
    end
end

--[[
      添加光效框 单个小块
]]
function AtlantisRespinView:addRespinLightEffect()
    self.m_machine.m_lightEffectNode:removeAllChildren(true)
    self.m_single_lights = {}
    --bonus数量
    local bonus_count = #self.m_machine.m_runSpinResultData.p_storedIcons
    --添加预告中奖框
    if bonus_count >= 11 and bonus_count < 15 then
        for key,endNode in pairs(self.m_respinNodes) do
            if endNode.m_lastNode and endNode.m_lastNode.p_symbolType ~= self.m_machine.SYMBOL_BONUS_LINK then
                local light_effect = util_createAnimation(LIGHT_EFFECT[15 - bonus_count])
                --存储快滚特效
                local nodeTag = self.m_machine:getNodeTag(endNode.p_colIndex,endNode.p_rowIndex,SYMBOL_NODE_TAG)
                self.m_single_lights[nodeTag] = light_effect
                light_effect:runCsbAction("run1",true)  --普通滚动状态
                light_effect:setVisible(false)
                self.m_machine.m_lightEffectNode:addChild(light_effect)
                light_effect:setPosition(util_convertToNodeSpace(endNode.m_lastNode,self.m_machine.m_lightEffectNode))
            end
        end
    end

    
end

--[[
    小块停止
]]
function AtlantisRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil then
        self.m_bonus_count = self.m_bonus_count + 1
        --快滚状态
        if #self.m_qucikRespinNode > 0 then
            self.m_machine.m_respin_bar:bonusCountChangeAni(self.m_bonus_count)
        end
        endNode:runAnim("buling",false,function(  )
            endNode:runAnim("idleframe",true)
        end) 
    end

    local nodeTag = self.m_machine:getNodeTag(endNode.p_cloumnIndex,endNode.p_rowIndex,SYMBOL_NODE_TAG)
    for index=1,#self.m_qucikRespinNode do
        local quickRunInfo = self.m_qucikRespinNode[index]
        if quickRunInfo.key == nodeTag then
            quickRunInfo.isEnd = true
            --播放下个快滚特效
            self:runQuickEffect()
            break;
        end
    end

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount then
        self.m_machine:respinRunEnd()
        if self.m_quickSoundId then
            gLobalSoundManager:stopAudio(self.m_quickSoundId)
            self.m_quickSoundId = nil
        end
    end
end

function AtlantisRespinView:oneReelDown(colIndex)
    for key,endNode in pairs(self.m_respinNodes) do
        if endNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK and #self.m_qucikRespinNode == 0 
        and endNode.p_colIndex == colIndex 
        and endNode.m_runLastNodeType == self.m_machine.SYMBOL_BONUS_LINK then
            --落地音效
            gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_bonus_down.mp3")
            break
        end
    end
    gLobalSoundManager:playSound(self.m_machine.m_reelDownSound)
end



return AtlantisRespinView