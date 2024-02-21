--respinnode和respinview的基类、这俩应该分别继承目前没有修改
local BaseRespin = class("BaseRespin", cc.Node)
BaseRespin.m_symbolTypeEnd = nil
BaseRespin.m_symbolRandomType = nil

BaseRespin.m_slotNodeWidth = nil
BaseRespin.m_slotNodeHeight = nil

BaseRespin.m_slotReelWidth = nil
BaseRespin.m_slotReelHeight = nil

BaseRespin.m_machine = nil
BaseRespin.m_machineRow = nil
BaseRespin.m_machineCol = nil

BaseRespin.getSlotNodeBySymbolType = nil
BaseRespin.pushSlotNodeToPoolBySymobolType = nil

BaseRespin.m_clipNodesData = nil          --裁切区域

function BaseRespin:ctor()
      self:initBaseRespin()
end

function BaseRespin:initBaseRespin()
      self:registerScriptHandler( function(tag)
          if "enter" == tag then
              self:onBaseEnter()
          elseif "exit" == tag then
              self:onBaseExit()
          end
      end )
end

--初始化数据 通过 util_createView 创建的view会自动调用
function BaseRespin:initData_(...)
      self.m_baseData={...}
      if self.initUI then
          self:initUI(...)
      end
end

--传入内存池与machine使用同一个池
function BaseRespin:setCreateAndPushSymbolFun(funcGetSlotNode, funcPushNodeToPool)
      self.getSlotNodeBySymbolType = funcGetSlotNode
      self.pushSlotNodeToPoolBySymobolType = funcPushNodeToPool
end
      
--传入高亮类型 随机类型
function BaseRespin:setEndSymbolType(symbolTypeEnd, symbolRandomType)
      self.m_symbolTypeEnd = symbolTypeEnd
      self.m_symbolRandomType = symbolRandomType 
end

function BaseRespin:setMachine(machine)
    self.m_machine = machine
end

function BaseRespin:setMachineType(col, row)
      self.m_machineRow = row
      self.m_machineCol = col
end
---------------------------------裁切相关 START
--使用方式 
--respinview 初始化initRespinElement中 setMachineType之后调用initClipNodes
--respinnode 调用initClipNode(getClipNode(col,row)) --initClipNode实现检测如果传入了clipnode就不创建新的
--获取真实宽高
function BaseRespin:getReelInfo(machineElement)
      --寻找第一个节点坐标
      local startPos = nil
      local endPos = nil
      for i=1,#machineElement do
            local nodeInfo = machineElement[i]
            if nodeInfo.ArrayPos.iX==1 and nodeInfo.ArrayPos.iY == 1 then
                  startPos = self:convertToNodeSpace(nodeInfo.Pos)
            end
            if nodeInfo.ArrayPos.iX==self.m_machineRow and nodeInfo.ArrayPos.iY == self.m_machineCol then
                  endPos = self:convertToNodeSpace(nodeInfo.Pos)
            end
            if startPos and endPos then
                  --对角线小块坐标差值/小块数量
                  local slotWidth = (endPos.x-startPos.x)/(self.m_machineCol-1)
                  local slotHeight = (endPos.y-startPos.y)/(self.m_machineRow-1)
                  return startPos,cc.size(slotWidth,slotHeight)
            end
      end
      return nil
end

--选填配置configParams
--     configParams["clipOffsetSize"]     --裁切修正大小 默认cc.size(0,0)
--     configParams["clipType"]           --裁切类型 1.单个、2.合并行 默认1
--     configParams["clipMode"]           --裁切方式 1.矩形、2.模板 默认1
--     configParams["clipPos"]            --初始坐标 默认cc.p(-clipSize.width*0.5,-clipSize.height*0.5)
--     configParams["clipOffsetPos"]      --初始坐标 默认cc.p(0,0)
--初始化裁切节点
function BaseRespin:initClipNodes(machineElement,clipType,configParams)
      local startPos,clipSize = self:getReelInfo(machineElement)
      if not startPos then
            return
      end
      --裁切配置
      local config = {
            iColNum = self.m_machineCol,
            iRowNum = self.m_machineRow,
            clipSize = clipSize,
            --选填配置
            clipType = clipType,     --裁切类型 1.单个、2.合并行 默认1
      }
      --附加参数
      if configParams then
            for key,value in pairs(configParams) do
                  config[key] = value
            end
      end
      self.m_clipNodesData = util_createClipNodes(config)
      local baseNode = self.m_clipNodesData.baseNode
      self:addChild(baseNode)
      baseNode.originalPos = startPos
      baseNode:setPosition(startPos)
      baseNode:setTag(-13031) --乱写的防止自己被检测到
end
--修正整体盘面位置
function BaseRespin:changeClipBaseNode(offSetPos)
      if not self.m_clipNodesData  then
            return
      end
      self:setClipNodePos(self.m_clipNodesData.baseNode,offSetPos)
end
--修正行裁切位置
function BaseRespin:changeClipRowNode(row,offSetPos)
      if not self.m_clipNodesData or not row then
            return
      end
      if self.m_clipNodesData.clipType == RESPIN_CLIPTYPE.COMBINE and self.m_clipNodesData.rowClips then
            --行裁切
            self:setClipNodePos(self.m_clipNodesData.rowClips[row],offSetPos)
      end
end
--修正小块裁切位置
function BaseRespin:changeClipCellNode(col,row,offSetPos)
      local clipNode = self:getClipNode(col,row)
      self:setClipNodePos(clipNode,offSetPos)
end
--修正裁切坐标
function BaseRespin:setClipNodePos(clipNode,offSetPos)
      if clipNode and offSetPos then
            if not clipNode.originalPos then
                  clipNode.originalPos = cc.p(clipNode:getPosition())
            end
            clipNode:setPosition(cc.pAdd(clipNode.originalPos,offSetPos))
      end
end
--单个格子裁切节点（如果合并行了只是模拟裁切节点真实裁切节点需要getRowClipNode(row)获得）
function BaseRespin:getClipNode(col,row)
      if self.m_clipNodesData and col and row then
            return self.m_clipNodesData[col][row]
      end
      return nil
end
--按行合并后每行裁切节点
function BaseRespin:getRowClipNode(row)
      if self.m_clipNodesData and self.m_clipNodesData.rowClips then
            return self.m_clipNodesData.rowClips[row]
      end
      return nil
end
---------------------------------裁切相关 END

--设置repinnode宽高
function BaseRespin:initRespinSize(respinNodeWidth, respinNodeHeight, reelWidth, reelHeight)
      self.m_slotNodeWidth = respinNodeWidth
      self.m_slotNodeHeight = respinNodeHeight

      self.m_slotReelWidth = reelWidth
      self.m_slotReelHeight = reelHeight
end

--获取随机小块
function BaseRespin:randomSymbolRandomType()   
   local randomIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_symbolRandomType + 1
   local nodeType = self.m_symbolRandomType[randomIndex]  
   return  nodeType 
end


--信号是否是高亮
function BaseRespin:getTypeIsEndType(symbolType)
   for i=1,#self.m_symbolTypeEnd do
      local type = self.m_symbolTypeEnd[i].type
      if type == symbolType then
         return true
      end
   end
   return false
end

--获取信号
function BaseRespin:getEndTypeInfo(symbolType)
      for i=1,#self.m_symbolTypeEnd do
         local type = self.m_symbolTypeEnd[i].type
         if type == symbolType then
            return self.m_symbolTypeEnd[i]
         end
      end
      return nil
end

--随机获取end信号
function BaseRespin:getRandomEndType()
      local randomInfos = {}
      for i=1,#self.m_symbolTypeEnd do           
         local bRamdom = self.m_symbolTypeEnd[i].bRandom
         if bRamdom == nil or bRamdom == true then

            randomInfos[#randomInfos + 1] = self.m_symbolTypeEnd[i]
         end
      end
      if #randomInfos > 0 then
            local randomIndex = xcyy.SlotsUtil:getArc4Random() % #randomInfos + 1
            local info = randomInfos[randomIndex]  
            return info.type
      end
      return nil
end
   
   

function BaseRespin:onBaseEnter()
      if self.onEnter then self:onEnter() end
  end
  
function BaseRespin:onBaseExit() 
      if self.onExit then self:onExit() end 
end

return BaseRespin