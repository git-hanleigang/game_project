--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-11-28 15:10:43
--
local ReelStripData = class("ReelStripData")
local ReelResultData = util_require("data.slotsdata.ReelResultData")

ReelStripData.p_reelDatas = nil
ReelStripData.p_resultData = nil

function ReelStripData:ctor()

    self.p_reelDatas = {}
end

--[[
    @desc: 解析滚动数据
    time:2018-11-28 15:11:38
    --@data: 
    @return:
]]
function ReelStripData:parseReelDatas( colIndex, data )

      local reelData = self.p_reelDatas[colIndex]

      if reelData == nil then
            reelData = {totalWeight = 0}
            self.p_reelDatas[colIndex] = reelData
      end

      local verStrs = util_string_split(data,";")
      local totalWeight = 0
      for i=1,#verStrs do
            local str = verStrs[i]
            local symbolInfo = util_string_split(str,"-",true)
            if symbolInfo[2] > 0 then  -- 权重如果为0 ， 那么不用作信号随机
                  reelData[#reelData + 1] = symbolInfo
                  reelData.totalWeight = reelData.totalWeight + symbolInfo[2]
            end
            
      end
      -- print("...")
end
--[[
    @desc: 返回一组reel symbol 信号
    time:2018-11-28 15:17:07
    @param colIndex 列索引
    @param resultLen 结果长度
    @return:  返回随机到位置的symbol 数组
]]
function ReelStripData:getReelSymbols( colIndex, resultLen )

      if self.p_resultData == nil then
            self.p_resultData = ReelResultData:create()
      else
            self.p_resultData:clear()
      end

      local reelData = self.p_reelDatas[colIndex]

      local random = util_random(1,reelData.totalWeight)
      
      -- if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE then
      --       if colIndex == 1 then
      --             random = 53
      --       elseif colIndex == 2 then
      --             random = 53
      --       elseif colIndex == 3 then
      --             random = 53
      --       elseif colIndex == 4 then
      --             random = 53
      --       elseif colIndex == 5 then      
      --             random = 1
      --       end
      -- end



      local preValue = 0

      local startIndex = -1

      for i=1,#reelData do
            local symbolInfo = reelData[i]
            if symbolInfo[2] ~= 0 then  -- 为0的概率不做处理
                  if random > preValue and random <= preValue + symbolInfo[2] then
                        startIndex = i
                        break
                  end
                  preValue = preValue + symbolInfo[2]
            end
            
      end
      self.p_resultData.p_startIndex = startIndex
      self.p_resultData.p_resultLen = resultLen

      -- release_print("reel 位置 信息" .. startIndex .. "  " .. resultLen)

      for j=0,resultLen - 1 do

            local index = startIndex + j
            if index > #reelData then
                  index = index - #reelData
            end

            self.p_resultData.p_reelResultSymbols[j+1] = reelData[index][1]
      end
      return self.p_resultData
end

--[[
    @desc: 获取 滚轮的 bigwin 数据
    time:2018-12-29 18:08:18
    --@startIndex:
	--@colIndex:
	--@resultLen: 
    @return:
]]
function ReelStripData:getReelSymbolsBigWin( startIndex ,colIndex , resultLen )

      if self.p_resultData == nil then
            self.p_resultData = ReelResultData:create()
      else
            self.p_resultData:clear()
      end

      local reelData = self.p_reelDatas[colIndex]

      self.p_resultData.p_startIndex = startIndex
      self.p_resultData.p_resultLen = resultLen

      for j=0,resultLen - 1 do

            local index = startIndex + j
            if index > #reelData then
                  index = index - #reelData
            end

            self.p_resultData.p_reelResultSymbols[j+1] = reelData[index][1]
      end
      return self.p_resultData
end



function ReelStripData:getTotalWeight( colIndex )
      local reelData = self.p_reelDatas[colIndex]

      return reelData.totalWeight
end

return  ReelStripData