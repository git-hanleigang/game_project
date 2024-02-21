-- 每日轮盘 金库 银库 钞票游戏 相关数据管理类

GD.CASHBONUS_TYPE = {
    BONUS_NONE = "BONUS_NONE", -- 无
    BONUS_SILVER = "SILVER", -- 银库
    BONUS_GOLD = "GOLD", -- 金库
    BONUS_WHEEL = "BONUS_WHEEL", -- 轮盘
    BONUS_WHEEL_PAY = "BONUS_WHEEL_PAY", -- 二次付费轮盘
    BONUS_MONEY = "BONUS_MONEY" -- 钞票游戏
}

GD.CASHBACK_BOX_TYPE = {
    ALL_WIN_SELECTED = "ALL_WIN_SELECTED", -- allwin
    COIN_SELECTED = "COIN_SELECTED", --
    ALL_WIN_NOT_SELECTED = "ALL_WIN_NOT_SELECTED", --
    COIN_NOT_SELECTED = "COIN_NOT_SELECTED" --
}

local WheelDetail = require("GameModule.CashBonus.model.WheelDetail")
local MultipleConfig = require("GameModule.CashBonus.model.MultipleConfig")
local MegaCashData = require("GameModule.CashBonus.model.MegaCashData")
local CashBonusIncreaseData = require("GameModule.CashBonus.model.CashBonusIncreaseData")
local CashBonusVaultData = require("GameModule.CashBonus.model.CashBonusVaultData")

local BaseGameModel = require("GameBase.BaseGameModel")
local CashBonusData = class("CashBonusData", BaseGameModel)

function CashBonusData:ctor()
    CashBonusData.super.ctor(self)
    self:setRefName(G_REF.CashBonus)
end

-- 解析数据
function CashBonusData:parseData(data)
    self.cashbonusDatas = {}

    if data:HasField("wheelDaily") then
        self:parseWheelData(data.wheelDaily) -- 免费轮盘
    end

    if data:HasField("wheelPay") then
        self:parsePayWheelData(data.wheelPay) -- 付费轮盘
    end

    if data:HasField("multiple") then
        self:parseMultipleData(data.multiple)
    end

    if data.cashVaults and #data.cashVaults > 0 then
        for idx, data in ipairs(data.cashVaults) do
            if data.type == CASHBONUS_TYPE.BONUS_GOLD then
                self:parseGoldVault(data)
            elseif data.type == CASHBONUS_TYPE.BONUS_SILVER then
                self:parseSilverVault(data)
            end
        end
    end

    if data:HasField("megaCash") then
        self:parseMegaData(data.megaCash)
    end

    self.p_loginDays = data.loginDays
end

-- 每日轮盘数据
function CashBonusData:parseWheelData(data)
    if not self.p_wheelDaily then
        self.p_wheelDaily = WheelDetail:create() -- 每日轮盘数据
    end
    self.p_wheelDaily:parseData(data)
end

-- 付费轮盘数据
function CashBonusData:parsePayWheelData(data)
    if not self.p_wheelPay then
        self.p_wheelPay = WheelDetail:create() -- 付费轮盘数据
    end
    self.p_wheelPay:parseData(data, true)
end

-- 解析增倍器数据
function CashBonusData:parseMultipleData(data)
    if not self.p_multiple then
        self.p_multiple = MultipleConfig:create() -- 翻倍器信息
    end
    self.p_multiple:parseData(data)
end

-- 解析所有增倍器的信息
function CashBonusData:parseAllMultipleDatas(datas)
    self.p_allMultiples = {}
    for i = 1, #datas do
        local data = datas[i]
        local multipleData = MultipleConfig:create()
        multipleData:parseData(data)

        self.p_allMultiples[#self.p_allMultiples + 1] = multipleData
    end
end

-- 金库数据
function CashBonusData:parseGoldVault(data)
    if not self.p_gold then
        self.p_gold = CashBonusVaultData:create()
    end
    self.p_gold:parseData(data)
end

-- 银库数据
function CashBonusData:parseSilverVault(data)
    if not self.p_silver then
        self.p_silver = CashBonusVaultData:create() -- 翻倍器信息
    end
    self.p_silver:parseData(data)
end

-- 钞票游戏数据
function CashBonusData:parseMegaData(data)
    if not self.p_megaCash then
        self.p_megaCash = MegaCashData:create() -- 翻倍器信息
    end
    self.p_megaCash:parseData(data)
end

-- 获得增倍器总数量
function CashBonusData:getMultipleCount()
    return #self.p_allMultiples
end

-- 获取当前可以领奖的 bonus 列表
function CashBonusData:getCurCollectBonus()
    if self:willMegaCollect() then
        --钞票游戏
        return CASHBONUS_TYPE.BONUS_MONEY
    elseif self:willWheelCollect() then
        -- 每日轮盘
        return CASHBONUS_TYPE.BONUS_WHEEL
    elseif self:willGoldCollect() then
        --金库
        return CASHBONUS_TYPE.BONUS_GOLD
    elseif self:willSliverCollect() then
        --银库
        return CASHBONUS_TYPE.BONUS_SILVER
    else
        return CASHBONUS_TYPE.BONUS_NONE
    end
end

-- 获取最近能收获 bonus
function CashBonusData:getCoolDownLateBonus()
    local sortBonusDatas = self:getCashBonusTimeNew()
    if #sortBonusDatas == 0 then
        return nil
    else
        table.sort(
            sortBonusDatas,
            function(a, b)
                if a.p_coolDown < b.p_coolDown then
                    return true
                end
                return false
            end
        )
        return sortBonusDatas[1]
    end
    return nil
end

function CashBonusData:getCashBonusTimeNew()
    local sortBonusDatas = {}
    local funBonusc = function(coolDownT, type, list)
        local data = {p_coolDown = coolDownT, type = type}
        list[#list + 1] = data
    end

    if self.p_wheelDaily then
        local wheel_time = self.p_wheelDaily:getLeftTime()
        funBonusc(wheel_time, CASHBONUS_TYPE.BONUS_WHEEL, sortBonusDatas)
    end

    if self.p_gold then
        local gold_time = self.p_gold:getLeftTime()
        funBonusc(gold_time, CASHBONUS_TYPE.BONUS_GOLD, sortBonusDatas)
    end

    if self.p_silver then
        local sliver_time = self.p_silver:getLeftTime()
        funBonusc(sliver_time, CASHBONUS_TYPE.BONUS_SILVER, sortBonusDatas)
    end

    return sortBonusDatas
end

-- 钞票游戏 可以领取
function CashBonusData:willMegaCollect()
    if self.p_megaCash then
        return self.p_megaCash:canCollect()
    end
    return false
end

-- 每日轮盘 可以领取
function CashBonusData:willWheelCollect()
    if self.p_wheelDaily then
        return self.p_wheelDaily:getLeftTime() <= 0
    end
    return false
end

-- 金库 可以领取
function CashBonusData:willGoldCollect()
    if self.p_gold then
        return self.p_gold:getLeftTime() <= 0
    end
    return false
end

-- 金库 可以领取
function CashBonusData:willSliverCollect()
    if self.p_silver then
        return self.p_silver:getLeftTime() <= 0
    end
    return false
end

-- 金库领取提示
function CashBonusData:parseCashVaultGame(data)
    self.m_cBPickGame = data

    if data.type == CASHBONUS_TYPE.BONUS_GOLD then
        self:parseGoldVault(data)
    elseif data.type == CASHBONUS_TYPE.BONUS_SILVER then
        self:parseSilverVault(data)
    end

    if data.extend and data.extend.highLimit then
        globalData.syncDeluexeClubData(data.extend.highLimit)
    end
end

function CashBonusData:getCashVaultGame()
    return self.m_cBPickGame
end

function CashBonusData:sortCashVaultGameBoxOrder(index)
    local tempF = self.m_cBPickGame.boxes[index] -- 假数据
    for i = 1, #self.m_cBPickGame.boxes do
        if self.m_cBPickGame.boxes[i].selected and i ~= index then
            local tempT = self.m_cBPickGame.boxes[i] -- 真实数据
            self.m_cBPickGame.boxes[index] = tempT
            self.m_cBPickGame.boxes[i] = tempF
        end
    end
end

function CashBonusData:getCashVaultBoxIsWinAll()
    local isWinAll = false
    for i = 1, #self.m_cBPickGame.boxes do
        if self.m_cBPickGame.boxes[i].selected then
            if self.m_cBPickGame.boxes[i].winAll then
                isWinAll = true
            end
            break
        end
    end
    return isWinAll
end

function CashBonusData:getCashVaultBoxType(index)
    local result = nil
    local boxItem = self.m_cBPickGame.boxes[index]
    if boxItem.selected then
        if boxItem.winAll then
            result = CASHBACK_BOX_TYPE.ALL_WIN_SELECTED
        else
            result = CASHBACK_BOX_TYPE.COIN_SELECTED
        end
    else
        if self:getCashVaultBoxIsWinAll() then
            result = CASHBACK_BOX_TYPE.COIN_SELECTED
        else
            if boxItem.winAll then
                result = CASHBACK_BOX_TYPE.ALL_WIN_NOT_SELECTED
            else
                result = CASHBACK_BOX_TYPE.COIN_NOT_SELECTED
            end
        end
    end
    return result
end

function CashBonusData:updateCashBonusIncrease(isInit)
    if isInit or not self.m_increaseList then
        self.m_increaseList = {}
        --大轮盘
        local wheelData = CashBonusIncreaseData:create()
        wheelData:parseWheelData(CASHBONUS_TYPE.BONUS_WHEEL, self.p_wheelDaily)
        self.m_increaseList[#self.m_increaseList + 1] = wheelData

        --金宝箱
        local goldData = CashBonusIncreaseData:create()
        goldData:parseBoxData(self.p_gold)
        self.m_increaseList[#self.m_increaseList + 1] = goldData

        --银宝箱
        local sliverData = CashBonusIncreaseData:create()
        sliverData:parseBoxData(self.p_silver)
        self.m_increaseList[#self.m_increaseList + 1] = sliverData
    else
        for i = 1, #self.m_increaseList do
            self.m_increaseList[i]:updateIncrese()
        end
    end
end
function CashBonusData:getCashBonusShowList()
    return self.m_increaseList
end

function CashBonusData:setMegaCashTakeData(cashMoneyTakeData)
    if self.p_megaCash then
        self.p_megaCash:setMegaCashTakeData(cashMoneyTakeData)
    end
end

return CashBonusData
