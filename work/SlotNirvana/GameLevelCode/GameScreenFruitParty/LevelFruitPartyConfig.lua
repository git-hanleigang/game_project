--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFruitPartyConfig = class("LevelFruitPartyConfig", LevelConfigData)

local MAX_COUNT   =     9           --每隔多少个小块插入一组轮底

function LevelFruitPartyConfig:ctor()
      LevelConfigData.ctor(self)
      self.m_lundi_cfg = {}
      self.m_lundi_temp = {}
end

-- 特意配置的关卡 修改滚动节奏的表，优先级最高
function LevelFruitPartyConfig:parseCsvRunDataConfigData()
      LevelConfigData.parseCsvRunDataConfigData(self)
      local tempData = {3,2,1}
      local maxCount = MAX_COUNT
      for iCol = 1,self.p_columnNum do
            self.m_lundi_cfg[iCol] = {}
            local colKey = "reel_cloumn"..iCol
            --每9个位置随机插入轮底数据
            local count = 0
            local insertIndex = -1
            local tempIndex = 1
            for index = 1,#self[colKey] do
                  if insertIndex == -1 then
                        insertIndex = math.random(2,MAX_COUNT - 3) 
                  end

                  local curIndex = index % maxCount
                  if curIndex == 0 then
                        curIndex = maxCount
                  end

                  if curIndex < insertIndex or curIndex >= insertIndex + 3 or #self[colKey] - index + 1 < #self[colKey] % maxCount then
                        self.m_lundi_cfg[iCol][index] = 0
                  else
                        self.m_lundi_cfg[iCol][index] = tempData[tempIndex]
                        tempIndex = tempIndex + 1
                  end

                  --重置索引
                  if curIndex == maxCount  then
                        count = 0
                        insertIndex = -1
                        tempIndex = 1
                  end
            end
      end

      self.m_lundi_temp = clone(self.m_lundi_cfg)


      -- for iCol=1,#self.m_lundi_cfg do
      --       self:printData(self.m_lundi_cfg[iCol],iCol)
      -- end

end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelFruitPartyConfig:getNormalReelDatasByColumnIndex(columnIndex)
      local colKey = "reel_cloumn"..columnIndex
      return self[colKey]
end

--[[
      获取轮底
]]
function LevelFruitPartyConfig:getLunDiType(colIndex,index)
      if index == -1 then
            return 0
      end
      return self.m_lundi_temp[colIndex][index] or 0
end

--[[
      重置轮底
]]
function LevelFruitPartyConfig:resetLunDi()
      self.m_lundi_temp = clone(self.m_lundi_cfg)
end

--[[
      准备停止
]]
function LevelFruitPartyConfig:prepareStop(parentData,runLen,realLunDi,isQuickStop)
      
      local beginIndex = parentData.beginReelIndex 
      local colIndex = parentData.cloumnIndex

      local length = #self.m_lundi_temp[colIndex]
      
      

      local endIndex = beginIndex + runLen - 2
      if endIndex > length then
            endIndex = (endIndex % length)
      end

      --快停特殊处理
      if isQuickStop then
            endIndex = beginIndex
      end

      local preIndex = endIndex - 1
      if preIndex <= 0 then
            preIndex = length + preIndex
      end


      -- self:printData(self.m_lundi_temp[colIndex],colIndex)

      self:cleanNearRealLunDiData(colIndex,endIndex)
      
      -- self:printData(self.m_lundi_temp[colIndex],colIndex)

      -- local temp = {}
      -- for i = 1,3 do
      --       temp[i] =  realLunDi[i][colIndex]
      -- end
      -- temp[4] = endIndex
      -- self:printData(temp,colIndex)

      if realLunDi[3][colIndex] == 1 then --完整轮底 [3,2,1]
            self.m_lundi_temp[colIndex][endIndex] = 0
            self.m_lundi_temp[colIndex][preIndex] = 0
      elseif realLunDi[3][colIndex] == 2 then   --[0,3,2]
            self.m_lundi_temp[colIndex][endIndex] = 1
            
      elseif realLunDi[3][colIndex] == 3 then   --[0,0,3]
            self.m_lundi_temp[colIndex][endIndex] = 2

            local tempIndex = endIndex + 1
            if tempIndex > length then
                  tempIndex = tempIndex % length
            end
            self.m_lundi_temp[colIndex][tempIndex] = 1
      elseif realLunDi[1][colIndex] == 2 then --[2,1,0]
            self.m_lundi_temp[colIndex][preIndex] = 3

      elseif realLunDi[1][colIndex] == 1 then --[1,0,0]
            self.m_lundi_temp[colIndex][preIndex] = 2
            local tempIndex = preIndex - 1
            if tempIndex <= 0 then
                  tempIndex = length + tempIndex
            end
            self.m_lundi_temp[colIndex][tempIndex] = 3
      end

      -- self:printData(self.m_lundi_temp[colIndex],colIndex)
end

--[[
      打印数据
]]
function LevelFruitPartyConfig:printData(array,colIndex)
      local str = "col_"..colIndex..":"
      for iRow=1,#array do
            str = str.." "..array[iRow]
            
      end
      print(str)
end

--[[
      清理真实数据周围轮底
]]
function LevelFruitPartyConfig:cleanNearRealLunDiData(colIndex,endIndex)
      --每9个假滚数据才会有一组轮底,所以根据最终停止的索引清理对应区段的数据即可
      local maxIndex = MAX_COUNT
      local cleanIndex = math.floor((endIndex - 1) / maxIndex) 

      for index = 1,maxIndex do
            self.m_lundi_temp[colIndex][index + cleanIndex * maxIndex] = 0
      end
end

return  LevelFruitPartyConfig