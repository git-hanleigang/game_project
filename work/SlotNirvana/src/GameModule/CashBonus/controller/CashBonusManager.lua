-- 大厅 每日轮盘 金库 银库 钞票游戏 管理器

local CashBonusNet = require("GameModule.CashBonus.net.CashBonusNet")
local CashBonusManager = class("CashBonusManager", BaseGameControl)

function CashBonusManager:ctor()
    CashBonusManager.super.ctor(self)
    self:setRefName(G_REF.CashBonus)
    self.cashBonusNet = CashBonusNet:getInstance()

    self.bl_isOpenDeluex = false
end

function CashBonusManager:parseData(data)
    local cashbonus_data = self:getData()
    if not cashbonus_data then
        cashbonus_data = require("GameModule.CashBonus.model.CashBonusData"):create()
        cashbonus_data:parseData(data)
        cashbonus_data:setRefName(G_REF.CashBonus)
        self:registerData(cashbonus_data)
    else
        cashbonus_data:parseData(data)
    end
end

-- 每日轮盘数据
function CashBonusManager:getWheelData()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    return cashbonus_data.p_wheelDaily
end

-- 付费轮盘数据
function CashBonusManager:getPayWheelData()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    return cashbonus_data.p_wheelPay
end

-- 铜库奖励数据
function CashBonusManager:getCashMoneyData()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    return cashbonus_data.p_megaCash
end

-- 银库奖励数据
function CashBonusManager:getSilverData()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    return cashbonus_data.p_silver
end

-- 金库奖励数据
function CashBonusManager:getGoldData()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    return cashbonus_data.p_gold
end

-- 增倍器数据
function CashBonusManager:getMultipleData()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    return cashbonus_data.p_multiple
end

-- 所有增倍器数据
function CashBonusManager:getAllMultipleData()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    return cashbonus_data.p_allMultiples
end

-- 获取登录天数
function CashBonusManager:getLoginDays()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    return cashbonus_data.p_loginDays or 0
end

--当前购买增加的jackpot值
function CashBonusManager:getJackpotData()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    return cashbonus_data.p_jackpotAddValue or 0
end

--当前购买增加的jackpot值
function CashBonusManager:setJackpotData(data)
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    cashbonus_data.p_jackpotAddValue = data
end

-- 金库领取提示
function CashBonusManager:parseCashVaultGame(data)
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    cashbonus_data:parseCashVaultGame(data)
end

function CashBonusManager:parseMegaData(data)
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    cashbonus_data:parseMegaData(data)
end

function CashBonusManager:parseAllMultipleDatas(multipleData)
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    if multipleData ~= nil and multipleData ~= "" then
        cashbonus_data:parseAllMultipleDatas(multipleData)
    end
end

function CashBonusManager:parseMultipleData(data)
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return
    end
    cashbonus_data:parseMultipleData(data)
end

--是否开启高倍场
function CashBonusManager:isOpenDeluex()
    return self.bl_isOpenDeluex
end

--是否开启高倍场
function CashBonusManager:setOpenDeluex(bl_open)
    self.bl_isOpenDeluex = bl_open
end

function CashBonusManager:sendActionCashBonus(_bonusType, _isWatchAds)
    self.cashBonusNet:sendActionCashBonus(_bonusType, _isWatchAds)
end

function CashBonusManager:sendActionCashVaultCollect(_type, _showCoins)
    self.cashBonusNet:sendActionCashVaultCollect(_type, _showCoins)
end

function CashBonusManager:sendActionCashMoneyRequest(act_type)
    self.cashBonusNet:sendActionCashMoneyRequest(act_type)
end

function CashBonusManager:refreshMultiply(func)
    if gLobalViewManager:getViewByExtendData("DailyBonusLayer") then
        self.m_delayRefreshMultiply = true
        if func then
            func()
        end
        return
    end
    self.cashBonusNet:refreshMultiply(func)
end

function CashBonusManager:checkDelayrefreshMultiply()
    if self.m_delayRefreshMultiply then
        self.m_delayRefreshMultiply = false
        self:refreshMultiply()
    end
end

function CashBonusManager:willMegaCollect()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return false
    end
    return cashbonus_data:willMegaCollect()
end

function CashBonusManager:willGoldCollect()
    local cashbonus_data = self:getRunningData()
    if not cashbonus_data then
        return false
    end
    return cashbonus_data:willGoldCollect()
end

-- 获取CashBonus 公用配置
function CashBonusManager:getBonusConfig()

    if not self.bonus_config then

        self.bonus_config = require("views.cashBonus.cashBonusMain.CashBonusConfig")

    end

    return self.bonus_config

end

return CashBonusManager
