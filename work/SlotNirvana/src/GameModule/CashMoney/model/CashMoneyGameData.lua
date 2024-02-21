--[[
Author: dhs
Date: 2022-04-19 11:18:24
LastEditTime: 2022-05-12 22:42:05
LastEditors: bogon
Description: CashMoney 通用道具化 游戏数据解析
FilePath: /SlotNirvana/src/GameModule/CashMoney/model/CashMoneyGameData.lua
--]]
--[[
    optional int32 index = 1; //序号
    optional string keyId = 2;//S2
    optional string key = 3; //slots_casinocashlink_1p99
    optional string price = 4; //价格
    optional int64 expireAt = 5; //过期时间
    optional int64 expire = 6; //剩余时间
    repeated int32 result = 7; //结果数据
    optional int32 leftPlayTimes = 8; //剩余可玩次数
    optional int64 coins = 9; //倍率 (对应免费版CurrentOffer)
    optional int64 freeBase = 10; //免费金币基底（顶部显示的钱）
    optional int64 payBase = 11; //付费金币基底（顶部显示的钱）
    optional string source = 12;//来源
    optional bool isPay = 13;//是否付过费
    optional bool mark = 14;//是否带付费项
    optional int32 maxMultiple = 15;//付费最大倍率(对应工程 HighestOffer)
    optional int64 maxCoins = 16;//付费可能获得最大金币数(弹付费弹板时展示的钱也是最后付费玩完领奖的钱)
    repeated int64 payCoins = 17; //付费后每次的倍率(对应工程 CurrentOffer)
    optional string status = 18; //状态 INIT,PLAYING
    optional string freeConfig = 19; //免费配置
    optional string payConfig = 20; //付费配置
    optional bool reward = 21; //奖励是否领取
    optional string arenaMultiple = 22;
    optional string vipMultiply = 23; //vip bonus
    optional int64 totalCoins = 24;//赢得金币
    optional bool take = 25; //take Offer 是否点击过，take领取状态
    repeated CashMoneyPay payList = 26;//付费信息列表
    optional int32 payIndex = 27;//付费的索引 用来断线重连    
]]
local CashMoneyPayData = util_require("GameModule.CashMoney.model.CashMoneyPayData")
local CashMoneyGameData = class("CashMoneyGameData")

function CashMoneyGameData:ctor()
end

function CashMoneyGameData:parseData(_data)
    self.m_index = _data.index -- 小游戏编号
    self.m_keyId = _data.keyId
    self.m_key = _data.key
    self.m_price = _data.price
    self.m_expireAt = _data.expireAt
    self.expire = _data.expire
    self.m_leftPlayTimes = _data.leftPlayTimes
    self.m_source = _data.source
    self.m_isPay = _data.pay
    self.m_isMark = _data.mark
    self.m_status = _data.status
    self.m_freeConfig = self:splitFreeConfig(_data.freeConfig)
    self.m_payConfig = self:splitPayConfig(_data.payConfig)
    self.m_reward = _data.reward
    self.m_vipMultiply = _data.vipMultiply
    self.m_takeStatus = _data.take

    self.m_result = {} -- 带有每次Try的结果数组

    if _data.result and #_data.result > 0 then
        for i = 1, #_data.result do
            self.m_result[#self.m_result + 1] = _data.result[i]
        end
    end

    if _data.coins then
        self.m_coins = tonumber(_data.coins)
    end

    if _data.freeBase then
        self.m_freeBase = tonumber(_data.freeBase)
    end

    if _data.payBase then
        self.m_payBase = tonumber(_data.payBase)
    end

    if _data.maxMultiple then
        self.m_maxMultiple = tonumber(_data.maxMultiple)
    end

    if _data.maxCoins then
        self.m_maxCoins = tonumber(_data.maxCoins)
    end

    if _data.payCoins then
        -- 数组需要解析
        self.m_payCoins = self:parsePayCoins(_data.payCoins)
    end

    if _data.arenaMultiple then
        self.m_arenaMultiple = tonumber(_data.arenaMultiple)
    end

    if _data.totalCoins then
        self.m_totalCoins = tonumber(_data.totalCoins)
    end

    -- 新增数值，老用户需要判断
    self.m_payList = {}
    if _data.payList and #_data.payList > 0 then
        for i=1,#_data.payList do
            local payData = CashMoneyPayData:create()
            payData:parseData(_data.payList[i])
            table.insert(self.m_payList, payData)
        end
    end
    self.p_payIndex = _data.payIndex
end

function CashMoneyGameData:splitFreeConfig(_str)
    local strList = util_split(_str, ";")
    return strList
end

function CashMoneyGameData:splitPayConfig(_str)
    local strList = util_split(_str, ";")
    return strList
end

function CashMoneyGameData:parsePayCoins(_payCoins)
    if type(_payCoins) ~= "table" then
        return nil
    end

    local maxValue = 0
    local nCount = #(_payCoins)
    if  nCount > 0 then
        for i=1, nCount do
            local num = tonumber(_payCoins[i])

            if num > maxValue then
                maxValue = num
            end
        end
    end
    return maxValue
end

-- 获取小游戏ID
function CashMoneyGameData:getGameId()
    return self.m_index
end

function CashMoneyGameData:getKeyId(_payIndex)
    if self:isNewData() then
        local payData = self.m_payList[_payIndex]
        return payData:getKeyId()
    end    
    return self.m_keyId
end

function CashMoneyGameData:getKey(_payIndex)
    if self:isNewData() then
        local payData = self.m_payList[_payIndex]
        return payData:getKey()
    end        
    return self.m_key
end

function CashMoneyGameData:getPrice(_payIndex)
    if self:isNewData() then
        local payData = self.m_payList[_payIndex]
        return payData:getPrice()
    end    
    return self.m_price
end
-- 获取当前Try剩余次数
function CashMoneyGameData:getLeftPlayTimes()
    return self.m_leftPlayTimes
end
-- 获取当前小游戏结果数据（Try时哪些Money中了）
function CashMoneyGameData:getResult()
    return self.m_result
end
-- 获取小游戏数据来源
function CashMoneyGameData:getSource()
    return self.m_source
end
-- 获取付费状态
function CashMoneyGameData:getPayStatus()
    return self.m_isPay
end
-- 获取是否带付费项
function CashMoneyGameData:getMarkStatus()
    return self.m_isMark
end

-- 获取游戏状态
function CashMoneyGameData:getGameStatus()
    return self.m_status == "PLAYING"
end

-- 获取倍率
function CashMoneyGameData:getMagnification()
    return self.m_coins
end

-- 获取免费金币基底
function CashMoneyGameData:getFreeBase()
    return self.m_freeBase
end

-- 获取付费金币基底
function CashMoneyGameData:getPayBase(_payIndex)
    if self:isNewData() then
        local payData = self.m_payList[_payIndex]
        return payData:getPayBase()
    end      
    return self.m_payBase
end

-- 获取付费最大倍率
function CashMoneyGameData:getMaxPayMagnification(_payIndex)
    if self:isNewData() then
        local payData = self.m_payList[_payIndex]
        return payData:getMaxMultiple()
    end    
    return self.m_maxMultiple
end

-- 获取每次付费后可获得最大金币数
function CashMoneyGameData:getPayMaxCoinsReaward(_payIndex)
    if self:isNewData() then
        local payData = self.m_payList[_payIndex]
        return payData:getMaxCoins()
    end     
    return self.m_maxCoins
end

-- 获取付费后每次返回的倍率
function CashMoneyGameData:getPayMagnification()
    return self.m_payCoins or 0
end

-- 获取当前带有付费项的游戏是否已经领奖
function CashMoneyGameData:getRewardStatus()
    return self.m_reward
end

-- 获取freeConfig(这里是展示用的数值以及倍率)
function CashMoneyGameData:getFreeConfig()
    return self.m_freeConfig
end

-- 新老数据判断
function CashMoneyGameData:isNewData()
    if self.m_payList and #self.m_payList > 0 then
        return true
    end
    return false
end

-- 获取payConfig(这里是展示用的数值以及倍率)
function CashMoneyGameData:getPayConfig(_payIndex)
    if self:isNewData() then
        local payData = self.m_payList[_payIndex]
        if payData then
            return payData:getPayConfig()
        end
    end
    return self.m_payConfig
end

-- 获取vip加成
function CashMoneyGameData:getVipMultiply()
    return self.m_vipMultiply
end

--
function CashMoneyGameData:getArenaMultiply()
    local value = math.max(self.m_arenaMultiple or 0, 0)
    if value > 0 then
        return (value + 100) / 100
    else
        return 0
    end
end

-- 获取能够领取的奖励金币数
function CashMoneyGameData:getTotalCoins()
    return self.m_totalCoins or 0
end

-- 获取当前玩家点击Take按钮的状态
function CashMoneyGameData:getTakeOfferStatus()
    return self.m_takeStatus
end

function CashMoneyGameData:getExpireAt()
    return self.m_expireAt
end

-- 选择的档位，付费后断线重连时需要用到
function CashMoneyGameData:getSelectPayIndex()
    return self.p_payIndex
end

return CashMoneyGameData
