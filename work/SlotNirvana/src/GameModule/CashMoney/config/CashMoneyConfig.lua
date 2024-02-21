--[[
Author: dhs
Date: 2022-04-19 11:13:10
LastEditTime: 2022-05-25 12:28:54
LastEditors: bogon
Description: CashMoney 功能道具通用化 配置文件
FilePath: /SlotNirvana/src/GameModule/CashMoney/config/CashMoneyConfig.lua
--]]
local CashMoneyConfig = {}
local NORMAL_RES_PATH = "NewCashBonus/CashMoney/CashBonusMoney/"
local PAID_RES_PATH = "NewCashBonus/CashMoney/CashBonusMoneyPaid/"
local COMMON_MUSIC_PATH = "NewCashBonus/CashMoney/CommonRes/music/"
CashMoneyConfig.NORMAL_ROLL_NODE = {
    "node_cash1-l",
    "node_cash1-r",
    "node_cash2",
    "node_cash2-l",
    "node_cash3",
    "node_cash3-r",
    "node_cash4",
    "node_cash4-r",
    "node_cash5-l",
    "node_maxcash",
    "node_chengbei_0",
    "node_chengbei1_0"
}

CashMoneyConfig.PAID_ROLL_NODE = {
    "node_cash1-l",
    "node_cash1-r",
    "node_cash2",
    "node_cash2-l",
    "node_cash3",
    "node_cash3-r",
    "node_cash4",
    "node_cash4-r",
    "node_cash5-l",
    "node_maxcash",
    "node_chengbei",
    "node_chengbei1"
}
-- 这个供第一次进入付费版动效使用，从上到下做动效展示
CashMoneyConfig.PAID_ROLL_START_EFFECT = {
    {
        "node_cash3-r",
        "node_cash4",
        "node_cash5-l"
    },
    {
        "node_cash4-r",
        "node_cash2",
        "node_cash1-l"
    },
    {
        "node_cash1-r",
        "node_cash3",
        "node_cash2-l"
    },
    {
        "node_chengbei",
        "node_maxcash",
        "node_chengbei1"
    }
}

CashMoneyConfig.BanList = {1, 1}
CashMoneyConfig.isInBanList = function(_index)
    local banValue = CashMoneyConfig.BanList[_index]
    if banValue and banValue == 1 then
        return true
    end
    return false
end

CashMoneyConfig.TIME_DEALY = {
    DELAY_AFTER_CURTAIN = 0.8,
    DELAY_SELECT_INTERVAL = 1,
    DELAY_SHOW_OVERUI = 1,
    VIP_SHOW_TIME = 4
}

CashMoneyConfig.NORMAL_EFFECT_PATH = {
    MainLayer = NORMAL_RES_PATH .. "CashMoneyMainLayer.csb",
    -- 特效 --
    CashMoney_Roll = NORMAL_RES_PATH .. "Cashmoney_Roll.csb",
    CashMoney_SG_Kuang = NORMAL_RES_PATH .. "Cashmoney_SG_Kuang.csb",
    CashMoney_SG_Logo = NORMAL_RES_PATH .. "Cashmoney_SG_Logo.csb",
    Cashmoney_SG_Take = NORMAL_RES_PATH .. "Cashmoney_SG_Take.csb",
    Cashmoney_SG_Try = NORMAL_RES_PATH .. "Cashmoney_SG_Try.csb",
    Cashmoney_Result = NORMAL_RES_PATH .. "CashGameResult_cashmoney.csb",
    Cashmoney_Result0 = NORMAL_RES_PATH .. "CashGameResult_cashmoney_0.csb"
}

CashMoneyConfig.PAID_EFFECT_PATH = {
    MainLayer = "CashMoneyPaidMainLayer.csb",
    -- 特效 --
    CashMoney_Roll = PAID_RES_PATH .. "Cashmoney_Roll_0.csb",
    CashMoney_SG_Kuang = PAID_RES_PATH .. "node_SG_kuang.csb",
    CashMoney_SG_Logo = PAID_RES_PATH .. "node_SG_logo.csb",
    Cashmoney_SG_Take = PAID_RES_PATH .. "node_SG_try.csb",
    Cashmoney_SG_Try = PAID_RES_PATH .. "node_SG_try.csb",
    Cashmoney_Result = PAID_RES_PATH .. "CashMoneyPaidResult.csb",
    Cashmoney_Result0 = PAID_RES_PATH .. "CashMoneyPaidResult_0.csb"
}
CashMoneyConfig.DATA_TYPE = {
    CASHBONUS = "CashBonus", -- 正常从CashBonus里获得游戏数据
    PUT = "Put" -- 渠道投放获得的数据
}

CashMoneyConfig.NORMAL_SOUND_RES = {
    COMMON_MUSIC_PATH .. "cashMoney_lan.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_lan.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_cheng.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_cheng.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_huang.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_huang.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_lv.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_lv.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_fen.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_hong.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_jiabei.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_jiabei.mp3"
}

CashMoneyConfig.PAID_SOUND_RES = {
    COMMON_MUSIC_PATH .. "cashMoney_lan.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_lan.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_cheng.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_cheng.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_huang.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_huang.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_lv.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_lv.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_fen.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_fen.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_jiabei.mp3",
    COMMON_MUSIC_PATH .. "cashMoney_jiabei.mp3"
}

CashMoneyConfig.COMMON_MUSIC = {
    curtain = COMMON_MUSIC_PATH .. "cashMoney_curtain.mp3",
    showOver = COMMON_MUSIC_PATH .. "cashMoney_showOver.mp3",
    waitClick = COMMON_MUSIC_PATH .. "cashMoney_waitClick.mp3",
    click = COMMON_MUSIC_PATH .. "cashMoney_click.mp3",
    selectNormal = COMMON_MUSIC_PATH .. "cashMoney_selectNormal.mp3",
    selectDouble = COMMON_MUSIC_PATH .. "cashMoney_selectDouble.mp3",
    roll = COMMON_MUSIC_PATH .. "cashMoney_roll.mp3",
    jiabei = COMMON_MUSIC_PATH .. "cashMoney_jiabei.mp3",
    startFirst = COMMON_MUSIC_PATH .. "cashMoney_paidNormal.mp3", -- 付费版动效普通音效
    startFinal = COMMON_MUSIC_PATH .. "cashMoney_paidBeiLv.mp3"
}

CashMoneyConfig.NORMAL_ROLL_NODE_PATH = NORMAL_RES_PATH
CashMoneyConfig.PAID_ROLL_NODE_PATH = PAID_RES_PATH

return CashMoneyConfig
