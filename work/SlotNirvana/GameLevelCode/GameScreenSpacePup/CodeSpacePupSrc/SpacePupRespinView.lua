---
--xcyy
--2018年5月23日
--SpacePupRespinView.lua

local PublicConfig = require "SpacePupPublicConfig"
local SpacePupRespinView = class("SpacePupRespinView",util_require("Levels.RespinView"))

--滚动参数
local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3

local TAG_LIGHT = 1001
local TAG_LIGHT_SINGLE = 1002

function SpacePupRespinView:initUI(respinNodeName)
    self.m_respinNodeName = respinNodeName 
    self.m_baseRunNum = BASE_RUN_NUM
    self.m_reelRespinRunSoundTag = {}
    self.m_playLightSound = true
 end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function SpacePupRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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
          if self.m_machine:getCurSymbolIsBonus(machineNode.p_symbolType) then
                machineNode:runAnim("idleframe4", true)
          end
          if nodeInfo.isVisible then
                -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
          end

          local status = nodeInfo.status
          self:createRespinNode(machineNode, status)
    end

    self:readyMove()
end

function SpacePupRespinView:runNodeEnd(endNode)
    -- if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
    --     for index=1,5 do
                    
    --         self:addRespinLightEffectSingle(index)
    --         --刷新次数
    --         self.m_machine:refreshRespinTimes(2,index)
    --         --添加光效
    --         self:addRespinLightEffect(index)
    --     end
    -- end
    self:newOneReelDown(endNode)
    --bonus落地
    if self.m_machine:getCurSymbolIsBonus(endNode.p_symbolType) then
        endNode:runAnim("buling", false, function()
            endNode:runAnim("idleframe4", true)
        end)
        if self.curColPlaySound then
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Bonus_buling)
            self.curColPlaySound = nil
        end
    end
end

--回弹后的down
function SpacePupRespinView:newOneReelDown(endNode)
    --判断是否是该列最后一个格子滚动结束
    local lastColNodeRow = endNode.p_rowIndex 
    for i=1,#self.m_respinNodes do
          local respinNode = self.m_respinNodes[i]
          if respinNode.p_colIndex == endNode.p_cloumnIndex and respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                if respinNode.p_rowIndex < lastColNodeRow  then
                      lastColNodeRow = respinNode.p_rowIndex 
                end
          end
    end
    if endNode.p_rowIndex == lastColNodeRow then
        local curCol = endNode.p_cloumnIndex
        self:addRespinLightEffectSingle(curCol)
        --刷新次数
        self.m_machine:refreshRespinTimes(2,curCol)
        --添加光效
        self:addRespinLightEffect(curCol)
    end
end

function SpacePupRespinView:oneReelDown(iCol)
    -- body
    self.curColPlaySound = iCol

    local colSoundTag = self.m_reelRespinRunSoundTag[iCol]
    if colSoundTag then
        gLobalSoundManager:stopAudio(colSoundTag)
        self.m_reelRespinRunSoundTag[iCol] = nil
    end
    if iCol == self.m_machineColmn then
        self.m_reelRespinRunSoundTag = {}
    end

    if not self.isQuickRun then
        self.m_machine:slotLocalOneReelDown(iCol)
  end
end

function SpacePupRespinView:quicklyStop()
    for iCol=1, self.m_machineColmn do
        local colSoundTag = self.m_reelRespinRunSoundTag[iCol]
        if colSoundTag then
            gLobalSoundManager:stopAudio(colSoundTag)
            self.m_reelRespinRunSoundTag[iCol] = nil
        end
    end
    for i=1,#self.m_respinNodes do
          local repsinNode = self.m_respinNodes[i]
          if repsinNode:getNodeRunning() then
             repsinNode:quicklyStop()
          end
    end

    self:changeTouchStatus(ENUM_TOUCH_STATUS.QUICK_STOP)
    self.isQuickRun = true
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Reel_QuickStop_Sound)
end

--[[
      添加光效框 单个小块
]]
function SpacePupRespinView:addRespinLightEffectSingle(colIndex)
    --无次数的列移除光效框
    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData
    local times = rsExtraData.reSpinTimes[colIndex]
    

    local reels = self.m_machine.m_runSpinResultData.p_reels
    local bonus_count = 0
    local last_index = -1
    for rowIndex=1,self.m_machine.m_iReelRowNum do
        if reels[rowIndex][colIndex] == self.m_machine.SYMBOL_SCORE_BONUS then --判断是否为bonus图标
            bonus_count = bonus_count + 1
        else
            last_index = rowIndex
        end
    end

    if times <= 0 and bonus_count < 4 then
        self.m_machine.m_effectNode_respin[colIndex]:removeAllChildren(true)
        return
    end

    if bonus_count == 3 and last_index ~= -1 then
        for key,endNode in pairs(self.m_respinNodes) do
            if endNode.m_lastNode and endNode.m_lastNode.p_cloumnIndex == colIndex and 
            endNode.m_lastNode.p_symbolType ~= self.m_machine.SYMBOL_SCORE_BONUS  and
            not self.m_machine.m_effectNode_respin[colIndex]:getChildByTag(TAG_LIGHT_SINGLE) then
                local light_effect = util_createAnimation("SpacePup_respin_qdk.csb")
                light_effect:runCsbAction("actionframe", true)

                for i=1, 5 do
                    local jackpotNode = light_effect:findChild("Node_jackpot_"..i)
                    if jackpotNode then
                        if i == colIndex then
                            jackpotNode:setVisible(true)
                        else
                            jackpotNode:setVisible(false)
                        end
                    end
                end
                
                self.m_machine.m_effectNode_respin[colIndex]:removeAllChildren(true)
                self.m_machine.m_effectNode_respin[colIndex]:addChild(light_effect)
                light_effect:setTag(TAG_LIGHT_SINGLE)
                light_effect:setPosition(util_convertToNodeSpace(endNode.m_lastNode,self.m_machine.m_effectNode_respin[colIndex]))
                break
            end
        end
    end
end

--[[
    添加respin光效框 整列
]]
function SpacePupRespinView:addRespinLightEffect(colIndex)
    -- 
    local reels = self.m_machine.m_runSpinResultData.p_reels

    local bonus_count = self:getLinkCount(colIndex)
    local reelNode = self.m_machine:findChild("sp_reel_" .. (colIndex - 1))
    if bonus_count >= 4 and not self.m_machine.m_effectNode_respin[colIndex]:getChildByTag(TAG_LIGHT) then
        self.m_machine.m_effectNode_respin[colIndex]:removeAllChildren(true)
        self.m_machine:setLastRespinIsWinState(true)
        local light_effect = util_createAnimation("SpacePup_respin_tsk.csb")
        if self.m_playLightSound then
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Repin_BonusFull)
            self.m_playLightSound = false
        end
        light_effect:runCsbAction("actionframe", false, function()
            light_effect:runCsbAction("idle", true)
            self.m_machine:setLastRespinIsWinState(false)
        end)

        for i=1, 5 do
            local jackpotNode = light_effect:findChild("Node_jackpot_"..i)
            if jackpotNode then
                if i == colIndex then
                    jackpotNode:setVisible(true)
                else
                    jackpotNode:setVisible(false)
                end
            end
        end

        self.m_machine.m_effectNode_respin[colIndex]:addChild(light_effect)
        light_effect:setTag(TAG_LIGHT)
        light_effect:setPosition(util_convertToNodeSpace(reelNode,self.m_machine.m_effectNode_respin[colIndex]))
        self.m_machine:playTriggerCurColBonus(colIndex)
    end
end

--[[
      结算光效
]]
function SpacePupRespinView:cleanEffect(colIndex,callBack)
    local light_effect = self.m_machine.m_effectNode_respin[colIndex]:getChildByTag(TAG_LIGHT)
    if light_effect then
        light_effect:runCsbAction("over", false, function()
            self.m_machine.m_effectNode_respin[colIndex]:removeAllChildren(true)
            if type(callBack) == "function" then
                callBack()
            end
        end)
    else
        self.m_machine.m_effectNode_respin[colIndex]:removeAllChildren(true)
        if type(callBack) == "function" then
            callBack()
        end
    end
end

--[[
      获取该列Link图标数量
]]
function SpacePupRespinView:getLinkCount(colIndex)
    local reels = self.m_machine.m_runSpinResultData.p_reels
    local link_count = 0
    local last_index = -1
    for rowIndex=1,self.m_machine.m_iReelRowNum do
        if reels[rowIndex][colIndex] == self.m_machine.SYMBOL_SCORE_BONUS then --判断是否为bonus图标
            link_count = link_count + 1
        else
            last_index = rowIndex
        end
    end
    return link_count
end

function SpacePupRespinView:setSpecialClipNode()
    self.m_respinColorNode = {}
    for iCol = 1, self.m_machineColmn do
        for iRow = self.m_machineRow, 1, -1 do
            local clipNode = self.m_clipNodesData[iCol][iRow]
            clipNode:setVisible(true)
        end
    end
end

--组织滚动信息 开始滚动
function SpacePupRespinView:startMove()
    self.m_playLightSound = true
    self.isQuickRun = false
    --断线重连后恢复界面用
    for index=1,5 do
        self.m_machine:refreshRespinTimes(1,index)
        --添加光效
        self:addRespinLightEffect(index)
        self:addRespinLightEffectSingle(index)
  end
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    local reSpinTimes = self.m_machine.m_runSpinResultData.p_rsExtraData.reSpinTimes
    for i=1,#self.m_respinNodes do
        local isActive = reSpinTimes[self.m_respinNodes[i].p_colIndex] > 0
        if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK and isActive then
            self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
            self.m_respinNodes[i]:startMove()
        end
    end
end

function SpacePupRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    local quickIndex = 0

    local quickReelTbl = {}
    for j=1,#self.m_respinNodes do
          local repsinNode = self.m_respinNodes[j]
          local bFix = false 
          local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL

          local linkCount = self:getLinkCount(repsinNode.p_colIndex)
          if self.m_machine.m_runSpinResultData.p_rsExtraData then
                --需要快滚的列
                local rollColumns = self.m_machine.m_runSpinResultData.p_rsExtraData.rollColumns
                --设置快滚
                local light_effect = self.m_machine.m_effectNode_respin[repsinNode.p_colIndex]:getChildByTag(TAG_LIGHT_SINGLE)
                if rollColumns and table.indexof(rollColumns,repsinNode.p_colIndex - 1) and light_effect and repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                    light_effect:runCsbAction("actionframe2", true)
                    quickIndex = quickIndex + 1
                    runLong = quickIndex * 70
                    repsinNode:changeRunSpeed(true)
                    repsinNode:changeResDis(true)
                    quickReelTbl[#quickReelTbl+1] = repsinNode.p_colIndex
                    local lastCol = repsinNode.p_colIndex - 1
                    for iCol=1, lastCol do
                        local colSoundTag = self.m_reelRespinRunSoundTag[iCol]
                        if colSoundTag then
                            gLobalSoundManager:stopAudio(colSoundTag)
                            self.m_reelRespinRunSoundTag[iCol] = nil
                        end
                    end
                    self.m_reelRespinRunSoundTag[repsinNode.p_colIndex] = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Respin_QuickRun)
                end
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
                    if #quickReelTbl > 0 then
                        local isSetState = false
                        local m_colIndex = 1
                        --先处理快滚
                        for j=1, #quickReelTbl do
                            local curCol = quickReelTbl[j]
                            if curCol == repsinNode.p_colIndex then
                                repsinNode:setRunInfo(runLong, data.type)
                                isSetState = true
                                m_colIndex = curCol
                                break
                            end
                        end
                        if not isSetState then
                            if repsinNode.p_colIndex > m_colIndex then
                                repsinNode:setRunInfo(runLong+30, data.type)
                            else
                                repsinNode:setRunInfo(runLong, data.type)
                            end
                        end
                    else
                        repsinNode:setRunInfo(runLong, data.type)
                    end
                end
          end
    end
end


return SpacePupRespinView
