---
--island
--2017年8月25日
--LineTypeTag.lua
-- 这个数据结构只用于初始化每条线的信息

local LineTypeTag = class("LineTypeTag")

LineTypeTag.iLineTypeIdx = nil  --创建属性
--LineTypeTag.stcColor = nil -- 
LineTypeTag.iLineMapInfo = nil -- 

-- 构造函数
function LineTypeTag:ctor()
    self.iLineTypeIdx = 0
    
    -- 初始化 REEL_COLUMN_NUMBER 长度的数组
    self.iLineMapInfo = table_createArr(REEL_COLUMN_NUMBER,0)
    
--    self.stcColor = {
--        rR = 0,
--        rG = 0,
--        rB = 0,
--        rA = 0
--    }
end



return LineTypeTag