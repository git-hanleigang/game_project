--[[
    @desc: 点击经验条后，显示升级需要经验和 奖励金币
    time:2019-04-12 12:18:49
    @return:
]]
local LevelTips = class("LevelTips", util_require("base.BaseView"))
LevelTips.m_isAction = nil

local OFFSET_HEIGHT = -15
function LevelTips:initUI(data)
    self:createCsbNode("LevelTips/LevelTips.csb")
    -- self:setPosition(130,-30)

    self.m_node_normal = self:findChild("node_normal")
    self.m_node_doubleExp = self:findChild("node_doubleExp")
    self.m_node_doubleCoins = self:findChild("node_doubleCoins")
    self.m_node_doubleAll = self:findChild("node_doubleAll")

    self.m_node_doubleboost = self:findChild("node_doubleboost")
    self.m_node_doubleboost2 = self:findChild("node_doubleboost2")

    self.m_lab_doubleExp = self:findChild("m_lb_doubleExp")
    self.m_lab_doubleAll = self:findChild("m_lb_doubleAll")
    self.m_lab_doubleboost = self:findChild("m_lb_doubleboost")

    -- if globalData.slotRunData.isPortrait == true then
    --     if not gLobalViewManager:isLobbyView() then
    --         self:setPosition(50,-30)
    --     end
    -- end

    self.m_oriPosY = self:getPositionY()

    self:setVisible(false)
end

function LevelTips:show(buffType)
    if self.m_isAction then
        return
    end

    --当前buff类型
    self.m_curBuffType = buffType

    self.m_node_normal:setVisible(false)
    self.m_node_doubleExp:setVisible(false)
    self.m_node_doubleCoins:setVisible(false)
    self.m_node_doubleAll:setVisible(false)
    self.m_node_doubleboost:setVisible(false)
    self.m_node_doubleboost2:setVisible(false)

    local multipleExp = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_DOUBLE_EXP) --经验多倍奖励
    local curLevel = globalData.userRunData.levelNum
    local curData = globalData.userRunData:getLevelUpRewardInfo(curLevel)
    local maxExp = globalData.userRunData:getPassLevelNeedExperienceVal()
    local upgradeNeedExp = maxExp - globalData.userRunData.currLevelExper
    upgradeNeedExp = upgradeNeedExp > 0 and upgradeNeedExp or 0
    -- self:setPositionY(-35)

    -- 这里获取的buff里, level boom 是等级+1 的值
    local multipleCoin = globalData.buffConfigData:getAllCoinBuffMultiple(curLevel, curLevel + 1)
    -- local multipleCoin = globalData.buffConfigData:getBuffMultipleByType(self.m_curBuffType)  --金币多倍奖励
    if multipleExp > 1 then
        if multipleCoin > 1 then
            if BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN == self.m_curBuffType then
                self:showDoubleAll(curData.p_coins, upgradeNeedExp, multipleCoin, multipleExp)
            elseif BUFFTYPY.BUFFTYPY_LEVEL_BOOM == self.m_curBuffType or BUFFTYPY.BUFFTYPY_LEVEL_BURST == self.m_curBuffType then
                self:showDoubleLevelBoom(curData.p_coins, multipleCoin)
            else
                self:showDoubleExp(curData.p_coins, upgradeNeedExp, multipleCoin, multipleExp)
            end
        else
            self:showDoubleExp(curData.p_coins, upgradeNeedExp, multipleCoin, multipleExp)
        end
    else
        if multipleCoin > 1 then
            if BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN == self.m_curBuffType then
                self:showDoubleCoins(curData.p_coins, upgradeNeedExp, multipleCoin, multipleExp)
            elseif BUFFTYPY.BUFFTYPY_LEVEL_BOOM == self.m_curBuffType or BUFFTYPY.BUFFTYPY_LEVEL_BURST == self.m_curBuffType then
                self:showLevelBoom(curData.p_coins, upgradeNeedExp, multipleCoin)
            else
                -- self:setPositionY(-30)
                self:showNormal(curData.p_coins, upgradeNeedExp, multipleCoin, multipleExp)
            end
        else
            -- self:setPositionY(-30)
            self:showNormal(curData.p_coins, upgradeNeedExp, multipleCoin, multipleExp)
        end
    end

    self.m_isAction = true
    self:setVisible(true)
    self:runCsbAction("start")
    gLobalViewManager:addAutoCloseTips(
        self,
        function()
            if not tolua.isnull(self) then
                self:hide()
            end
        end
    )
end

--显示普通
function LevelTips:showNormal(coins, exp, multipleCoin, multipleExp)
    self.m_node_normal:setVisible(true)
    local m_lb_exp = self.m_node_normal:getChildByName("m_lb_exp")
    local m_lb_coins = self.m_node_normal:getChildByName("m_lb_coins")
    if m_lb_exp then
        m_lb_exp:setString(util_formatCoins(exp, 30))
    end
    if m_lb_coins then
        m_lb_coins:setString(util_formatCoins(coins, 30) .. " COINS")
    end
end
--双倍经验
function LevelTips:showDoubleExp(coins, exp, multipleCoin, multipleExp)
    self:setPositionY(self.m_oriPosY + OFFSET_HEIGHT)
    self.m_node_doubleExp:setVisible(true)
    local multiple = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_DOUBLE_EXP)
    self.m_lab_doubleExp:setString(multiple)
    local m_lb_coins = self.m_node_doubleExp:getChildByName("m_lb_coins")
    if m_lb_coins then
        m_lb_coins:setString(util_formatCoins(coins, 30) .. " COINS")
    end
end

--双倍金币
function LevelTips:showDoubleCoins(coins, exp, multipleCoin, multipleExp)
    self:setPositionY(self.m_oriPosY + OFFSET_HEIGHT)
    self.m_node_doubleCoins:setVisible(true)
    local m_lb_exp = self.m_node_doubleCoins:getChildByName("m_lb_exp")
    local m_lb_baseCoins = self.m_node_doubleCoins:getChildByName("m_lb_baseCoins")
    local m_lb_coins = self.m_node_doubleCoins:getChildByName("m_lb_coins")
    if m_lb_exp then
        m_lb_exp:setString(util_formatCoins(exp, 30))
    end
    if m_lb_baseCoins then
        m_lb_baseCoins:setString(util_formatCoins(coins, 30) .. " COINS")
    end
    if m_lb_coins then
        m_lb_coins:setString(util_formatCoins(coins * multipleCoin, 30) .. " COINS")
    end
end

--全部双倍
function LevelTips:showDoubleAll(coins, exp, multipleCoin, multipleExp)
    self:setPositionY(self.m_oriPosY + OFFSET_HEIGHT)
    self.m_node_doubleAll:setVisible(true)
    local multiple = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_DOUBLE_EXP)
    self.m_lab_doubleAll:setString(multiple)
    local m_lb_baseCoins = self.m_node_doubleAll:getChildByName("m_lb_baseCoins")
    local m_lb_coins = self.m_node_doubleAll:getChildByName("m_lb_coins")
    if m_lb_baseCoins then
        m_lb_baseCoins:setString(util_formatCoins(coins, 30) .. " COINS")
    end
    if m_lb_coins then
        m_lb_coins:setString(util_formatCoins(coins * multipleCoin, 30) .. " COINS")
    end
end

--双倍经验 + levelBoom
function LevelTips:showDoubleLevelBoom(coins, multipleCoin)
    self:setPositionY(self.m_oriPosY + OFFSET_HEIGHT)
    self.m_node_doubleboost:setVisible(true)
    local multiple = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_DOUBLE_EXP)
    self.m_lab_doubleboost:setString(multiple)
    local m_lb_baseCoins = self.m_node_doubleboost:getChildByName("m_lb_baseCoins")
    local m_lb_coins = self.m_node_doubleboost:getChildByName("m_lb_coins")
    if m_lb_baseCoins then
        m_lb_baseCoins:setString(util_formatCoins(coins, 30) .. " COINS")
    end

    if m_lb_coins then
        m_lb_coins:setString(util_formatCoins(coins * multipleCoin, 30) .. " COINS")
    end
end

--levelBoom
function LevelTips:showLevelBoom(coins, exp, multipleCoin)
    self:setPositionY(self.m_oriPosY + OFFSET_HEIGHT)
    self.m_node_doubleboost2:setVisible(true)

    local m_lb_exp_coins = self.m_node_doubleboost2:getChildByName("m_lb_exp")
    local m_lb_baseCoins = self.m_node_doubleboost2:getChildByName("m_lb_baseCoins")
    local m_lb_coins = self.m_node_doubleboost2:getChildByName("m_lb_coins")
    if m_lb_exp_coins then
        m_lb_exp_coins:setString(util_formatCoins(exp, 30) .. " COINS")
    end

    if m_lb_baseCoins then
        m_lb_baseCoins:setString(util_formatCoins(coins, 30) .. " COINS")
    end

    if m_lb_coins then
        m_lb_coins:setString(util_formatCoins(coins * multipleCoin, 30) .. " COINS")
    end
end

function LevelTips:onKeyBack()
end

function LevelTips:hide()
    self:runCsbAction(
        "over",
        false,
        function()
            self.m_isAction = false
            self:setVisible(false)
        end,
        60
    )
end

return LevelTips
