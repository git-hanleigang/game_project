---
--island
--2018年4月11日
--CollectData.lua
--

local CollectData = class("CollectData")

CollectData.p_collectTotalCount = nil  --通用数值， 例如freespin count  ， respin count等信息
CollectData.p_collectLeftCount = nil -- 
CollectData.p_collectCoinsPool = nil  -- 例如两种选择
CollectData.p_collectChangeCount = nil -- 选择的是第几个， 
-- 构造函数
function CollectData:ctor()
    
end


---
-- 解析feature 数据
-- 
function CollectData:parseCollectData(data)
    self.p_collectTotalCount=data.collectTotalCount
    self.p_collectLeftCount = data.collectLeftCount
    self.p_collectCoinsPool = data.collectCoinsPool
    self.p_collectChangeCount = data.collectChangeCount
end


return CollectData