

local TreasureToadRespinNode = class("TreasureToadRespinNode",util_require("Levels.RespinNode"))
TreasureToadRespinNode.SYMBOL_RS_SCORE_BLANK = 100
TreasureToadRespinNode.SYMBOL_RS_SCORE_BLANK1 = 101
TreasureToadRespinNode.SYMBOL_FIX_SYMBOL = 94
TreasureToadRespinNode.SYMBOL_FIX_SYMBOL1 = 95
TreasureToadRespinNode.SYMBOL_FIX_SYMBOL2 = 96

local NODE_TAG = 10
local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20
-- local m_decelerSpeed = nil

-- 构造函数
function TreasureToadRespinNode:ctor()
      TreasureToadRespinNode.super.ctor(self)
      self.m_isQuick = false    
      self.m_parentView = nil
      self.isChangeExpectation = false
      self.dtNum = 0
      self.isAbTest = false
end

-- 是不是 respinBonus小块
function TreasureToadRespinNode:isFixSymbol(symbolType)
      if symbolType == self.SYMBOL_FIX_SYMBOL or 
          symbolType == self.SYMBOL_FIX_SYMBOL1 or 
          symbolType == self.SYMBOL_FIX_SYMBOL2 or 
          symbolType == self.SYMBOL_RS_SCORE_BLANK then
          return true
      end
      return false
end

--获得下一个小块
function TreasureToadRespinNode:getBaseNextNode(nodeType,score)
      local node = nil
      if self.m_runNodeNum == 0 then
          --最后一个小块
          node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex, true)
      else
          node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex, false)
      end
      if self:getTypeIsEndType(nodeType ) == false then
          node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
      else
          node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
      end
      node.score = score
      node.p_symbolType = nodeType
      return node
end

function TreasureToadRespinNode:getRandomTypeForMiddle(isMiddle)
      if isMiddle then
            local randomType = math.random(1,6)
            if randomType == 1 then
                  return self.SYMBOL_FIX_SYMBOL1
            elseif randomType == 2 then
                  return self.SYMBOL_FIX_SYMBOL2
            else
                  return self.SYMBOL_RS_SCORE_BLANK1
            end
      else
            local randomType = math.random(1,6)
            if randomType == 1 then
                  return self.SYMBOL_FIX_SYMBOL
            else
                  return self.SYMBOL_RS_SCORE_BLANK
            end
      end
end

--创建下一个节点
function TreasureToadRespinNode:baseCreateNextNode()
      if self.m_isGetNetData == true then
          self.m_runNodeNum = self.m_runNodeNum - 1
      end
      --创建下一个
      local nodeType,score = self:getBaseNodeType()
      if self.m_runNodeNum ~= 0 then
            if self.p_rowIndex == 2 and self.p_colIndex == 3 then
                  nodeType = self:getRandomTypeForMiddle(true)
            else
                  nodeType = self:getRandomTypeForMiddle(false) 
            end
      end
      local node = self:getBaseNextNode(nodeType,score)
      --最后一个小块
      if self.m_runNodeNum == 0 then
          self.m_lastNode = node
      end
      self:playCreateSlotsNodeAnima(node)
      node:setTag(NODE_TAG) 
      self.m_clipNode:addChild(node)
      --赋值给下一个节点
      self.m_baseNextNode = node
      self:updateBaseNodePos()
      self:changeNodeDisplay( node )
  end

--子类继承修改节点显示内容
function TreasureToadRespinNode:changeNodeDisplay(node)

      local isShowNode = self:isFixSymbol(node.p_symbolType)
      if isShowNode then
            if node.p_symbolType == self.SYMBOL_RS_SCORE_BLANK then
                  
                  if node.p_rowIndex == 2 and node.p_cloumnIndex == 3 then
                        self:changeNodeShow2(node)
                  end
                  node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
            else
                  node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
            end
      else
            if node.p_symbolType ~= self.SYMBOL_RS_SCORE_BLANK then
                  self:changeNodeShow(node)
            end
            node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
      end
      if node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
            node:runAnim("idleframe2_2",true)
      end
end

function TreasureToadRespinNode:changeNodeShow(symbol_node)
      if(not symbol_node)then
          return
      end
      if symbol_node.p_rowIndex == 2 and symbol_node.p_cloumnIndex == 3 then
            self:changeNodeShow2(symbol_node)
      else
            local blankType = self.SYMBOL_RS_SCORE_BLANK
            local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
            symbol_node:changeCCBByName(ccbName, blankType)
            symbol_node:changeSymbolImageByName( ccbName )
      end
  
      
end

function TreasureToadRespinNode:changeNodeShow2(symbol_node)
      if(not symbol_node)then
            return
        end
      local blankType = self.SYMBOL_RS_SCORE_BLANK1
      local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
      symbol_node:changeCCBByName(ccbName, blankType)
      symbol_node:changeSymbolImageByName( ccbName )
end

--设置滚动速度
function TreasureToadRespinNode:changeRunSpeed(isQuick)
      if isQuick then
          self:setRunSpeed(math.ceil(MOVE_SPEED * 1.5))
      else
          self:setRunSpeed(MOVE_SPEED)
      end
end

function TreasureToadRespinNode:setDtNum(num)
      self.dtNum = num
end

function TreasureToadRespinNode:setResDis(isLong)
      if isLong then
            self.m_resDis = 70
      else
            self.m_resDis = RES_DIS
      end
      
end

function TreasureToadRespinNode:setEcpectation(isChangeExpectation)
      if self.p_rowIndex == 2 and self.p_colIndex == 3 then
            self.isChangeExpectation = isChangeExpectation
      end
end

function TreasureToadRespinNode:changeRunNodeNum()          --修改数量
      if self.p_rowIndex == 2 and self.p_colIndex == 3 and self.m_runNodeNum > 2 then
            self.m_runNodeNum = 2
            
      end
end

function TreasureToadRespinNode:changeRunNodeNum2()         --修改数量
      if self.p_rowIndex == 2 and self.p_colIndex == 3 then
            self.m_runNodeNum = 50
            
      end
end

--ABtest
function TreasureToadRespinNode:setIsABTest(isAbTest)
      self.isAbTest = isAbTest
end

--刷新滚动
function TreasureToadRespinNode:baseUpdateMove(dt)
      if self.isAbTest then
            if globalData.slotRunData.gameRunPause then
                  return
            end
            --其他位置停轮后
            if self.isChangeExpectation then
                  self.dtNum = self.dtNum + 1
                  --四秒是240帧
                  if self.dtNum >= 200 then
                        --将滚动的数量变为2，滚动开始时设置的块数非常大
                        self:changeRunNodeNum()
                  else
                        --速度递减
                        self.m_moveSpeed = self.m_moveSpeed - 9
                        if self.m_moveSpeed < 100 then
                              self.m_moveSpeed = 100
                        end
                  end
            end
            self.m_baseCurDistance = self.m_baseCurDistance+ self:getBaseMoveDis(dt)
            if self.m_baseCurDistance-self.m_baseLastDistance >=self.m_slotNodeHeight then
                  --计算滚动距离
                  -- self.m_baseMoveCount = math.floor((self.m_baseCurDistance-self.m_baseLastDistance)/self.m_slotNodeHeight)
                  -- self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight*self.m_baseMoveCount
                  self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight
                  --改变小块
                  self:baseChangeNextNode()
                  --检测是否结束
                  if self:baseCheckOverMove() then
                  --结束滚动
                        self:baseOverMove()
                  end
            else
                  --刷新小块坐标
                  self:updateBaseNodePos()
            end
            
      else
            TreasureToadRespinNode.super.baseUpdateMove(self,dt)
      end
      
end

--裁切遮罩透明度
function TreasureToadRespinNode:initClipOpacity(opacity)
      -- if opacity and opacity>0 then
      --       local pos = cc.p(0, 0)
      --       local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
      --       local spPath = "Common/TreasureToad_spin_rell.png"
      --       opacity = 255
      --       local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
      --       self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
      -- end
end

return TreasureToadRespinNode