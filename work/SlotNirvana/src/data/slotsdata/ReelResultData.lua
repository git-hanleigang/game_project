--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-11-28 17:46:07
--
local ReelResultData = class("ReelResultData")

ReelResultData.p_startIndex = 0 -- 在滚轮上的索引位置
ReelResultData.p_reelResultSymbols = nil
ReelResultData.p_resultLen = nil

function ReelResultData:ctor()
      self.p_startIndex = 0
      self.p_reelResultSymbols = {}
      self.p_resultLen = 0
end

function ReelResultData:clear(  )
      self.p_startIndex = 0
      for i = #self.p_reelResultSymbols , -1 , 1 do
            self.p_reelResultSymbols[i] = nil
      end
      self.p_resultLen = 0
end

return  ReelResultData