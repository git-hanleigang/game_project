--[[
    @desc: new pass 第二货币促销
    author:csc
    time:2021-06-23 21:52:56
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local NewPassGemSaleConfig = class("NewPassGemSaleConfig")

-- optional int32 gems = 1;
-- repeated ShopItem items = 2;

function NewPassGemSaleConfig:ctor()
    -- 需要的gems 数量
    self.m_gems = 0
    -- 奖励道具
    self.m_rewards = {}
    --是否初始化数据
    self.m_initData = false 
end

function NewPassGemSaleConfig:parseData(data)
    if not data then
        return
    end
    -- 需要的gems 数量
    self.m_gems = data.gems

    self.m_rewards = {}
    if #data.items > 0 then
        for i = 1, #data.items do
            local _item = ShopItem:create()
            _item:parseData(data.items[i])
            table.insert(self.m_rewards, _item)
            self.m_initData = true 
        end
    else
        self.m_initData = false 
    end
end

function NewPassGemSaleConfig:getNeedsGems()
    return self.m_gems
end

function NewPassGemSaleConfig:getRewards()
    return self.m_rewards
end

function NewPassGemSaleConfig:isInitData()
    return self.m_initData
end

return NewPassGemSaleConfig
