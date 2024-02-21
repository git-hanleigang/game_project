

local ClassicCashRespinView = class("ClassicCashRespinView", util_require("Levels.RespinView"))
local PublicConfig = require "ClassicCashPublicConfig"                           


-- 这一关没有滚出的grand（全满算grand）
ClassicCashRespinView.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

ClassicCashRespinView.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
ClassicCashRespinView.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
ClassicCashRespinView.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

-- 特殊bonus
ClassicCashRespinView.SYMBOL_MID_LOCK = 105 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 
ClassicCashRespinView.SYMBOL_ADD_WILD = 106 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13  
ClassicCashRespinView.SYMBOL_TWO_LOCK = 107 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14 
ClassicCashRespinView.SYMBOL_Double_BET = 108 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15 

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 20

local TAG_LIGHT_SINGLE = 1002

function ClassicCashRespinView:initUI(respinNodeName)
      self.m_respinNodeName = respinNodeName 
      self.m_baseRunNum = BASE_RUN_NUM
      self.m_reelRespinRunSoundTag = nil
end

function ClassicCashRespinView:setOutLineBonus(states )
      self.m_isInBonus = states
end

-- 是不是 respinBonus小块
function ClassicCashRespinView:isSpecialFixSymbol(symbolType)
      if symbolType == self.SYMBOL_MID_LOCK or 
          symbolType == self.SYMBOL_ADD_WILD or 
          symbolType == self.SYMBOL_TWO_LOCK or 
          symbolType == self.SYMBOL_Double_BET or
          symbolType == self.SYMBOL_FIX_SYMBOL or
          symbolType == self.SYMBOL_FIX_MINI or
          symbolType == self.SYMBOL_FIX_MINOR or
          symbolType == self.SYMBOL_FIX_MAJOR then
          return true
      end
      return false
end

function ClassicCashRespinView:createRespinNode(symbolNode, status)
      ClassicCashRespinView.super.createRespinNode(self, symbolNode, status)

      if self:isSpecialFixSymbol(symbolNode.p_symbolType) then
            symbolNode:runAnim("idleframe2", true)
            -- if self.m_isInBonus then

            -- else
            --       symbolNode:runAnim("idleframe2", true)
            -- end 
      end
  end

  --[[
    添加respin光效框
]]
function ClassicCashRespinView:addRespinLightEffect()
    -- 
    local reels = self.m_machine.m_runSpinResultData.p_reels

    local bonus_count = self:getLinkCount()
    local totalCount = self.m_machine.m_iReelRowNum * self.m_machine.m_iReelColumnNum

    if bonus_count < totalCount then
        self.m_machine.m_effectNode_respin:removeAllChildren(true)
    end

    if bonus_count == totalCount-1 then
        for key,endNode in pairs(self.m_respinNodes) do
            if endNode.m_lastNode and not self:isSpecialFixSymbol(endNode.m_lastNode.p_symbolType) and
            not self.m_machine.m_effectNode_respin:getChildByTag(TAG_LIGHT_SINGLE) then
                local light_effect = util_createAnimation("WinFrameClassicCash_tishikuang.csb")
                light_effect:runCsbAction("actionframe", true)
                
                self.m_machine.m_effectNode_respin:removeAllChildren(true)
                self.m_machine.m_effectNode_respin:addChild(light_effect)
                light_effect:setTag(TAG_LIGHT_SINGLE)
                light_effect:setPosition(util_convertToNodeSpace(endNode.m_lastNode,self.m_machine.m_effectNode_respin))

                if self.m_reelRespinRunSoundTag then
                      gLobalSoundManager:stopAudio(self.m_reelRespinRunSoundTag)
                      self.m_reelRespinRunSoundTag = nil
                end
                self.m_reelRespinRunSoundTag = gLobalSoundManager:playSound(PublicConfig.Music_Respin_QuickRun)
                break
            end
        end
    end
end

function ClassicCashRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0
      
      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end
end

--组织滚动信息 开始滚动
function ClassicCashRespinView:startMove()
      --添加光效
      self:addRespinLightEffect()
      self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
      self.m_respinNodeRunCount = 0
      self.m_respinNodeStopCount = 0
      for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                  self.m_respinNodes[i]:startMove()
            end
      end
end

function ClassicCashRespinView:runNodeEnd(endNode)

      local info = self:getEndTypeInfo(endNode.p_symbolType)

      local node = endNode

      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            if self.curColPlaySound then
                  if node.p_symbolType == self.SYMBOL_FIX_SYMBOL or node.p_symbolType == self.SYMBOL_FIX_MINI or node.p_symbolType == self.SYMBOL_FIX_MINOR or node.p_symbolType == self.SYMBOL_FIX_MAJOR then
                        gLobalSoundManager:playSound(PublicConfig.Music_Bonus_BuLing)
                  elseif node.p_symbolType == self.SYMBOL_MID_LOCK or node.p_symbolType == self.SYMBOL_ADD_WILD or node.p_symbolType == self.SYMBOL_TWO_LOCK or node.p_symbolType == self.SYMBOL_Double_BET then
                        gLobalSoundManager:playSound(PublicConfig.Music_Special_Bonus_BuLing)
                  end
                  self.curColPlaySound = nil
            end
            
            endNode:runAnim(info.runEndAnimaName, false,function(  )
                  if self:isSpecialFixSymbol(node.p_symbolType) then
                        node:runAnim("idleframe2", true)
                        -- if self.m_isInBonus then
                  
                        -- else
                        --       node:runAnim("idleframe2", true)
                        -- end
                  end
                 
            end)

            if node.m_labUI then
                  -- node.m_labUI:runCsbAction("buling")
            end
      end  

end

function ClassicCashRespinView:oneReelDown(iCol)
      -- body
      self.curColPlaySound = iCol
      if self.m_reelRespinRunSoundTag then
            gLobalSoundManager:stopAudio(self.m_reelRespinRunSoundTag)
            self.m_reelRespinRunSoundTag = nil
      end

      if not self.isQuickRun then
            self.m_machine:slotLocalOneReelDown(iCol)
      end
end

function ClassicCashRespinView:quicklyStop()
      if self.m_reelRespinRunSoundTag then
            gLobalSoundManager:stopAudio(self.m_reelRespinRunSoundTag)
            self.m_reelRespinRunSoundTag = nil
      end

      for i=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[i]
            if repsinNode:getNodeRunning() then
                  repsinNode:quicklyStop()
            end
      end

      self:changeTouchStatus(ENUM_TOUCH_STATUS.QUICK_STOP)
      gLobalSoundManager:playSound(PublicConfig.Music_Reel_QuickStop_Sound)
end

---获取所有参与结算节点
function ClassicCashRespinView:getAllCleaningNode()
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

            for i=1,#sameRowNode do
                  sortNode[#sortNode + 1] = sameRowNode[i]
            end
      end
      cleaningNodes = sortNode
      return cleaningNodes
end

--[[
      获取Link图标数量
]]
function ClassicCashRespinView:getLinkCount()
      local reels = self.m_machine.m_runSpinResultData.p_reels
      local link_count = 0
      local last_index = -1
      for rowIndex=1, self.m_machine.m_iReelRowNum do
          for colIndex=1, self.m_machine.m_iReelColumnNum do
            if self:isSpecialFixSymbol(reels[rowIndex][colIndex]) then --判断是否为bonus图标
                  link_count = link_count + 1
              else
                  last_index = rowIndex
              end 
          end
      end
      return link_count
  end

return ClassicCashRespinView