---
--island
--2017年8月13日
--CSVData.lua
--

local CSVData = class("CSVData")

---
--
-- 所有的csv 文件都继承于此， 必须实现parseData 函数
--


-- 构造函数
function CSVData:ctor()

end

--@param  content table 类型数据内容
--@return
function CSVData:parseData(content)
    -- 解析公共的内容
    assert(false,"must override parseData ， parseData is virtual")
end

---
--
function CSVData:clone()
    
end


return CSVData