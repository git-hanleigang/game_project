--
-- 每个滚轮的列信息
-- Author:{author}
-- Date: 2018-11-28 20:22:15
--
local ReelColumnData = class("ReelColumnData")

ReelColumnData.p_colIndex = nil  -- 列索引

ReelColumnData.p_resultLen = nil -- 数据结果长度
ReelColumnData.p_lineCalculatePos = nil  -- 参与连线计算的位置信息

----------  显示部分内容 ----------
ReelColumnData.p_showGridH = nil  -- 每个格子的高度 、 宽度

ReelColumnData.p_showGridCount = nil  -- 用来做滚动创建的使用，

-- 这块在初始化machine 时设置
ReelColumnData.p_slotColumnPosX = nil  -- 列的位置信息， 宽高等
ReelColumnData.p_slotColumnPosY = nil
ReelColumnData.p_slotColumnWidth = nil
ReelColumnData.p_slotColumnHeight = nil

function ReelColumnData:ctor()
      self.p_showGridH = 0
end
--[[
    @desc: 返回参与连线的索引位置
    time:2018-12-06 15:08:27
    @return:
]]
function ReelColumnData:getLinePosLen( )
      local lineLen = table_length(self.p_lineCalculatePos)
      return lineLen
end

--[[
    @desc: 检测行号是否在 连线计算列表里面
    time:2018-11-29 19:40:31
    --@lineRow: 需要检测的行数
    @return:
]]
function ReelColumnData:checkRowInLine( lineRow )
      if self.p_lineCalculatePos == nil or self.p_lineCalculatePos[lineRow] == nil then
            return false
      end
      return true
end

--[[
    @desc: 设置显示单列的格子数量
    time:2018-12-01 11:12:46
    --@colCount: 
    @return:
]]
function ReelColumnData:updateShowColCount( colCount )
      self.p_showGridCount = colCount
      if colCount == 0 then
            self.p_showGridH = 0
      else
            self.p_showGridH = self.p_slotColumnHeight / colCount
      end
end

--[[
    @desc: 更新列的信息
    time:2018-11-28 20:35:54
    --@colIndex:  列位置
	--@resultLen:  结果长度
    @return:
]]
function ReelColumnData:updateColInfo( colIndex, resultLen  )

      self.p_colIndex = colIndex
      self.p_resultLen = resultLen
      self.p_lineCalculatePos = {}

      for i=1,self.p_resultLen do
            self.p_lineCalculatePos[i] = i
      end

end

function ReelColumnData:resetColInfo( )
      self.p_lineCalculatePos = {}
      
      for i=1,self.p_resultLen do
            self.p_lineCalculatePos[i] = i
      end
end

--[[
    @desc: 手动更新每列的计算连线位置信息
    time:2018-11-28 20:37:33
    --@args: 
    @return:
]]
function ReelColumnData:updateLinePos( ... )
      local args={...}
      self.p_lineCalculatePos = {}
      for i=1,#args do
            local posIdx = args[i]
            self.p_lineCalculatePos[posIdx] = posIdx
      end
end

return  ReelColumnData