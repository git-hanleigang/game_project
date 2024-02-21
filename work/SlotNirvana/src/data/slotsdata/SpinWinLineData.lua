---
--island
--2018年4月3日
--SpinWinLineData.lua
--
-- spin 赢钱线结果

local SpinWinLineData = class("SpinWinLineData")

SpinWinLineData.p_id = nil  -- line id
SpinWinLineData.p_amount = nil -- 本条线赢钱数量
SpinWinLineData.p_iconPos = nil  -- 本条线icon 轮盘位置从左上角开始

SpinWinLineData.p_type = nil -- 本条线的赢钱类型

SpinWinLineData.p_allLineSymbolNums = nil -- 存储每列存在的信号数量， 这个只有满线时才使用
SpinWinLineData.p_multiple = nil -- 总倍数
SpinWinLineData.p_lineAmount = nil -- 在满线情况下， 代表单线的赢钱
-- 构造函数
function SpinWinLineData:ctor()
      
      self.p_multiple = 1

end



return SpinWinLineData