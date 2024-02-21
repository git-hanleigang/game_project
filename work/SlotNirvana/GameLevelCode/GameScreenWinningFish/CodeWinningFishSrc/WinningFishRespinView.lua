
local RespinView = util_require("Levels.RespinView")
local WinningFishRespinView = class("WinningFishRespinView",RespinView)

local BASE_COL_INTERVAL = 3

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

local TAG_LIGHT                     =           1001
local TAG_LIGHT_SINGLE              =           1002

local LIGHT_CSB = {                 --整列光效
      "Socre_WinningFish_ChipJiman_mini.csb",
      "Socre_WinningFish_ChipJiman_minor.csb",
      "Socre_WinningFish_ChipJiman_major.csb",
      "Socre_WinningFish_ChipJiman_grand.csb",
      "Socre_WinningFish_ChipJiman_mega.csb",
}

local LIGHT_SINGLE_CSB = {          --小格光效
      "Socre_WinningFish_ChipRUN_mini.csb",
      "Socre_WinningFish_ChipRUN_minor.csb",
      "Socre_WinningFish_ChipRUN_major.csb",
      "Socre_WinningFish_ChipRUN_grand.csb",
      "Socre_WinningFish_ChipRUN_mega.csb",
}

local WIN_EFFECT_CSB = {
      "Socre_WinningFish_ChipJimanZJ_mini.csb",
      "Socre_WinningFish_ChipJimanZJ_minor.csb",
      "Socre_WinningFish_ChipJimanZJ_major.csb",
      "Socre_WinningFish_ChipJimanZJ_grand.csb",
      "Socre_WinningFish_ChipJimanZJ_mega.csb",
}

WinningFishRespinView.m_single_lights = {}
WinningFishRespinView.m_quick_sounds = {}

function WinningFishRespinView:createRespinNode(symbolNode, status)

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
      
      respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),210)
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
  
      self.m_single_lights = {}
  end

--[[
      隐藏背景
]]
function WinningFishRespinView:hideNodeBg(colIndex)
      for i=1,#self.m_respinNodes do
            if colIndex == self.m_respinNodes[i].p_colIndex then
                  self.m_respinNodes[i].m_colorNode:setVisible(false)
            end
            
      end
end

function WinningFishRespinView:readyMove()
      local params = {}
      params[1] = {
            type = "delay",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            delayTime = 0.5,
            callBack = function( )
                  self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
                  if self.m_startCallFunc then
                        self.m_startCallFunc()
                  end
            end,   --回调函数 可选参数
      }   
      util_runAnimations(params)
end

--[[
      组织滚动信息 开始滚动
]]
function WinningFishRespinView:startMove()

      --断线重连后恢复界面用
      for index=1,5 do
            self.m_machine:refreshRespinTimes(1,index)
            --添加光效
            self:addRespinLightEffect(index)
            self:addRespinLightEffectSingle(index)
      end
      
      self.m_bonusNum = 0
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

function WinningFishRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
      local quickIndex = 0

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
                        quickIndex = quickIndex + 1
                        runLong = quickIndex * 70
                        repsinNode:changeRunSpeed(true)
                        repsinNode:changeResDis(true)
                        self.m_single_lights[repsinNode.p_colIndex] = {effect = light_effect}
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
                        repsinNode:setRunInfo(runLong, data.type)
                  end
            end
      end

      --快滚特效
      self:runQuickEffect()
end

--[[
      快滚特效
]]
function WinningFishRespinView:runQuickEffect( )
      for colIndex=1,self.m_machine.m_iReelColumnNum do
            if self.m_single_lights[colIndex] and not self.m_single_lights[colIndex].isPlayed then
                  self.m_single_lights[colIndex].isPlayed = true
                  local light_effect = self.m_single_lights[colIndex].effect
                  light_effect:runCsbAction("run1",true)
                  
                  self.m_quick_sounds[colIndex] = gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_quick_single.mp3")
                  break
            end
      end
end

function WinningFishRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil  then
            endNode:runAnim("buling",false,function(  )
                  endNode:runAnim("idleframe",true)
            end) 
      end   



      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
            for key,repsinNode in pairs(self.m_respinNodes) do
                  repsinNode:changeRunSpeed(false)
                  repsinNode:changeResDis(false)
            end

            self.m_quick_sounds = {}

            for index=1,5 do
                  
                  self:addRespinLightEffectSingle(index)
                  --刷新次数
                  self.m_machine:refreshRespinTimes(2,index)
                  --添加光效
                  self:addRespinLightEffect(index)
                  
            end 
      end

end

--[[
      移除没有次数的列的光效
]]
function WinningFishRespinView:removeLightWithoutTimes(colIndex)
      --无次数的列移除光效框
      local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData
      local times = rsExtraData.reSpinTimes[colIndex]
      local link_count = self:getLinkCount(colIndex)

      if times <= 0 then
            if self.m_quick_sounds[colIndex] then
                  gLobalSoundManager:stopAudio(self.m_quick_sounds[colIndex])
                  self.m_quick_sounds[colIndex] = nil
            end
            self.m_machine.m_effectNode_respin[colIndex]:removeAllChildren(true)
            self.m_single_lights[colIndex] = nil
      end
end

function WinningFishRespinView:oneReelDown(colIndex)
      if self.m_single_lights[colIndex] then
            for key,value in pairs(self.m_single_lights) do
                  if not value.isPlayed then
                        self:runQuickEffect()
                        break
                  end
            end
      end

      local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData
      local times = rsExtraData.reSpinTimes[colIndex]
      --落地音效
      if times == 3 then
            self.m_bonusNum = self.m_bonusNum + 1
            gLobalSoundManager:playSound(self.m_machine.m_bonusBulingSoundArry[self.m_bonusNum])
      end

      --触发winner后,次数会变为0,需手动计算是否激活winner
      local link_count = self:getLinkCount(colIndex)
      if link_count >= 4 then
            self.m_bonusNum = self.m_bonusNum + 1
            gLobalSoundManager:playSound(self.m_machine.m_bonusBulingSoundArry[self.m_bonusNum])
      end
end

--[[
      获取该列Link图标数量
]]
function WinningFishRespinView:getLinkCount(colIndex)
      local reels = self.m_machine.m_runSpinResultData.p_reels
      local link_count = 0
      local last_index = -1
      for rowIndex=1,self.m_machine.m_iReelRowNum do
          if reels[rowIndex][colIndex] == self.m_machine.SYMBOL_BONUS_LINK then --判断是否为link图标
              link_count = link_count + 1
          else
              last_index = rowIndex
          end
      end
      return link_count
end

--[[
      添加光效框 单个小块
]]
function WinningFishRespinView:addRespinLightEffectSingle(colIndex)
      --无次数的列移除光效框
      local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData
      local times = rsExtraData.reSpinTimes[colIndex]
      

      local reels = self.m_machine.m_runSpinResultData.p_reels
      local link_count = 0
      local last_index = -1
      for rowIndex=1,self.m_machine.m_iReelRowNum do
          if reels[rowIndex][colIndex] == self.m_machine.SYMBOL_BONUS_LINK then --判断是否为link图标
              link_count = link_count + 1
          else
              last_index = rowIndex
          end
      end 

      if times <= 0 and link_count < 4 then
            self.m_machine.m_effectNode_respin[colIndex]:removeAllChildren(true)
            self.m_single_lights[colIndex] = nil
            return
      end

      if link_count == 3 and last_index ~= -1 then --and endNode.p_symbolType ~= self.m_machine.SYMBOL_BONUS_LINK then
            for key,endNode in pairs(self.m_respinNodes) do
                  if endNode.m_lastNode and endNode.m_lastNode.p_cloumnIndex == colIndex and 
                  endNode.m_lastNode.p_symbolType ~= self.m_machine.SYMBOL_BONUS_LINK  and
                  not self.m_machine.m_effectNode_respin[colIndex]:getChildByTag(TAG_LIGHT_SINGLE) then
                        local light_effect = util_createAnimation(LIGHT_SINGLE_CSB[colIndex])
                        light_effect:runCsbAction("run2",true)
                        
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
function WinningFishRespinView:addRespinLightEffect(colIndex)
      -- 
      local reels = self.m_machine.m_runSpinResultData.p_reels
  
      local link_count = self:getLinkCount(colIndex)
      local reelNode = self.m_machine:findChild("sp_reel_" .. (colIndex - 1))
      if link_count >= 4 and not self.m_machine.m_effectNode_respin[colIndex]:getChildByTag(TAG_LIGHT) then
            self.m_machine.m_effectNode_respin[colIndex]:removeAllChildren(true)
            local light_effect = util_createAnimation(LIGHT_CSB[colIndex])
            util_runAnimations({
                  {
                        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                        node = light_effect,   --执行动画节点  必传参数
                        actionName = "jiman_start", --动作名称  动画必传参数,单延时动作可不传
                        fps = 60,    --帧率  可选参数
                        callBack = function(  )
                              light_effect:runCsbAction("jiman_idle",true)
                        end,   --回调函数 可选参数
                    }
            })
            self.m_machine.m_effectNode_respin[colIndex]:addChild(light_effect)
            light_effect:setTag(TAG_LIGHT)
            light_effect:setPosition(util_convertToNodeSpace(reelNode,self.m_machine.m_effectNode_respin[colIndex]))
            self.m_machine.m_respin_bg[colIndex]:setVisible(true)
            self:hideNodeBg(colIndex)
      end
end

--[[
      结算光效
]]
function WinningFishRespinView:cleanEffect(colIndex,callBack)
      self.m_machine.m_effectNode_respin[colIndex]:removeAllChildren(true)
      local reelNode = self.m_machine:findChild("sp_reel_" .. (colIndex - 1))
      local light_effect = util_createAnimation(LIGHT_CSB[colIndex])
      light_effect:runCsbAction("jiman_idle2",true)
      self.m_machine.m_effectNode_respin[colIndex]:addChild(light_effect)
      light_effect:setPosition(util_convertToNodeSpace(reelNode,self.m_machine.m_effectNode_respin[colIndex]))

      local win_effect = util_createAnimation(WIN_EFFECT_CSB[colIndex])
      self.m_machine.m_clipParent:addChild(win_effect, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 150) 
      -- self.m_machine.m_effectNode_respin[colIndex]:addChild(win_effect)
      win_effect:setPosition(util_convertToNodeSpace(reelNode,self.m_machine.m_clipParent))
      util_runAnimations({
            {
                  type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                  node = win_effect,   --执行动画节点  必传参数
                  actionName = "jiman_win", --动作名称  动画必传参数,单延时动作可不传
                  fps = 60,    --帧率  可选参数
                  soundFile = "WinningFishSounds/sound_winningFish_jackpot_win_start.mp3",
                  keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                      {
                          keyFrameIndex = 32,    --关键帧数  帧动画用
                          callBack = function (  )
                              light_effect:runCsbAction("jiman_over")
                              self.m_machine.m_jackpotPool[colIndex]:winAni()
                          end,
                      }       --关键帧回调
                  },   
                  callBack = function(  )
                        win_effect:removeFromParent(true)
                  end,   --回调函数 可选参数
            },
            {
                  type = "delay",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                  node = self,   --执行动画节点  必传参数
                  delayTime = 1.5,
                  callBack = function(  )
                        if type(callBack) == "function" then
                              callBack()
                        end
                  end,   --回调函数 可选参数
            }
      })
end

--获取所有参与结算节点
function WinningFishRespinView:getAllCleaningNode()
      --从 从上到下 左到右排序
      local cleaningNodes = {}
      local childs = self:getChildren()

      for i=1,#childs do
            local node = childs[i]
            if node:getTag() == self.REPIN_NODE_TAG  and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
                  cleaningNodes[#cleaningNodes + 1] =  node
            end
      end


      --排序
      local sortNode = {}
      for iCol = 1 , self.m_machineColmn do
            
            local sameRowNode = {}
            for i = 1, #cleaningNodes do
                  local  node = cleaningNodes[i]
                  if node.p_cloumnIndex == iCol then
                        sameRowNode[#sameRowNode + 1] = node
                  end   
            end 
            table.sort( sameRowNode, function(a, b)
                  return b.p_rowIndex  <  a.p_rowIndex
            end)
            sortNode[iCol] = sameRowNode
      end
      cleaningNodes = sortNode
      return cleaningNodes
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function WinningFishRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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

return WinningFishRespinView