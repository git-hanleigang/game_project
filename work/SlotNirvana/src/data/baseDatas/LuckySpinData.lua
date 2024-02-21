--[[
    author:{author}
    time:2019-04-18 21:53:40
]]

local LuckySpinData = class("LuckySpinData")

LuckySpinData.p_price = nil         -- 价格
LuckySpinData.p_product = nil       -- 商品 Key
LuckySpinData.p_coins = nil         -- 基础金币
LuckySpinData.p_score = nil         -- pay table
LuckySpinData.p_isExist = nil
LuckySpinData.p_enjoyStatus = false -- 触发先享后付

function LuckySpinData:ctor( )
    self.p_isExist = false
end

function LuckySpinData:parseData( data )
    self.p_price = data.price
    self.p_product = data.product                 
    self.p_coins = data.coins  
    self.p_score = cjson.decode(data.score)
    self.p_isExist = true         
    self.p_enjoyStatus = data.enjoyStatus or false         
end

function LuckySpinData:resetData()
    self.p_price = nil
    self.p_product = nil      
    self.p_coins = nil
    self.p_score = nil
    self.p_isExist = false  
    self.p_enjoyStatus = false         
end

function LuckySpinData:isExist()
    return self.p_isExist
end

return LuckySpinData