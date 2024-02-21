--[[
Author: dhs
Date: 2022-04-24 14:44:39
LastEditTime: 2022-05-23 15:27:45
LastEditors: bogon
Description: CashMoney 道具通用化 通用结算界面
FilePath: /SlotNirvana/src/GameModule/CashMoney/view/CashMoneyResultBaseView.lua
--]]
local CashMoneyResultBaseView = class("CashMoneyResultBaseView", BaseView)

local DELAY_TIME = 0.35

function CashMoneyResultBaseView:ctor(gameId)
    CashMoneyResultBaseView.super.ctor(self)
    self.m_gameId = gameId
end

-- ***************************************** 子类重写 ************************************ --
function CashMoneyResultBaseView:getCsbName()
    return ""
end

function CashMoneyResultBaseView:getCashVaule()
    return nil
end

function CashMoneyResultBaseView:closeCallBack()
    return nil
end
-- ***************************************** 子类重写 ************************************ --

function CashMoneyResultBaseView:initUI()
    CashMoneyResultBaseView.super.initUI(self)
    -- setDefaultTextureType("RGBA8888", nil)
    local gameData = G_GetMgr(G_REF.CashMoney):getDataByGameId(self.m_gameId)

    self.m_baseCoinsLb = self:findChild("m_lb_baseCoins")
    self.m_vipLb = self:findChild("m_lb_vip_bonus")
    self.m_cashValueLb = self:findChild("m_lb_cash_value")
    self.node_coins = self:findChild("node_coins")
    self.lb_coin = self:findChild("lb_coin")
    self.m_totalCoinsLb = self:findChild("m_lb_total_coins")

    if not self.m_baseCoinsLb then
        local csbName = self:getCsbName()
        local fileNamePath = cc.FileUtils:getInstance():fullPathForFilename(csbName)
        release_print("没有 结算 csb  = " .. fileNamePath)
        local fileSize = cc.FileUtils:getInstance():getFileSize(fileNamePath)
        local logMsg = "fileNamePath:" .. tostring(fileNamePath) .. ",fileSize:" .. tostring(fileSize)
        util_sendToSplunkMsg("CashMoneyResultBaseView", fileNamePath)
    end

    self.m_baseCoinsLb:setString("")
    self.m_vipLb:setString("")
    self.m_cashValueLb:setString("")
    self.m_totalCoinsLb:setString("")
    self.lb_coin:setVisible(false)
    local lbDivi = self:findChild("m_lb_division")
    if lbDivi then
        lbDivi:setString("")
    end

    self.m_btn_collect = self:findChild("Button_collect")
    self.m_btn_collect:setTouchEnabled(false)
    self.m_btn_collect:setVisible(false)

    self.m_sp_deluxe = self:findChild("deluxe_extra")

    -- util_performWithDelay(
    --     self,
    --     function()
    --         self:startNextLogic()
    --     end,
    --     0.7
    -- )
    self:runCsbAction(
        "show",
        false,
        function()
            self:startNextLogic()
            -- self:runCsbAction("idle", true)
        end,
        30
    )

    self.m_baseCoins = 0

    local isPay = gameData:getPayStatus()
    if isPay then
        -- if gameData:getArenaMultiply() > 0 then
        --     local selectPayIndex = G_GetMgr(G_REF.CashMoney):getSelectPayIndex()
        --     self.m_baseCoins = gameData:getMaxPayMagnification(selectPayIndex)
        -- else
        --     --付费最大倍率(对应工程 HighestOffer)
        -- end
        self.m_baseCoins = gameData:getPayMagnification()
    else
        self.m_baseCoins = gameData:getMagnification()
    end

    self.m_gameSource = gameData:getSource()

    self:initView()

    -- setDefaultTextureType("RGBA4444", nil)
end

function CashMoneyResultBaseView:initView()
    if not self:checkDeluxe() then
        self.m_sp_deluxe:setVisible(false)
    else
        local labExtra = self:findChild("labExra")
        if labExtra ~= nil then
            labExtra:setString(globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD .. "%")
            self:updateLabelSize({label = labExtra}, 54)
        end
    end

    local sp_vipBoostTip = self:findChild("sp_vipBoostTip")
    if sp_vipBoostTip then
        sp_vipBoostTip:setVisible(false)
        local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
        if vipBoost and vipBoost:isOpenBoost() then
            sp_vipBoostTip:setVisible(true)
        end
    end
end

-- *************************************** Effect ******************************* --
function CashMoneyResultBaseView:checkDeluxe()
    if globalData.deluexeClubData:getDeluexeClubStatus() == true then
        return true
    end
    return false
end

function CashMoneyResultBaseView:checkGameSource()
    local gameData = G_GetMgr(G_REF.CashMoney):getDataByGameId(self.m_gameId)
    local gameSource = gameData:getSource()
    return gameSource == "CashBonus"
end

function CashMoneyResultBaseView:startNextLogic()
    self:doNext()
end

function CashMoneyResultBaseView:doNext()
    self.m_index = (self.m_index or 0) + 1
    if self:checkDeluxe() and self:checkGameSource() then
        self:showDeluxeCallFun(self.m_index)
    else
        self:showNormalCallFun(self.m_index)
    end
end

-- 播放结果回调函数
function CashMoneyResultBaseView:showNormalCallFun(updateIndex)
    if updateIndex == 1 then
        self:showBaseRewardFun()
    elseif updateIndex == 2 then
        self:showVipRewardFun()
    elseif updateIndex == 3 then
        self:showCashValueFun()
    elseif updateIndex == 4 then
        self:showDivisionValueFun()
    elseif updateIndex == 5 then
        self:showTotalRewardFun()
    elseif updateIndex == 6 then
        self:showCollectBtn()
    elseif updateIndex == 6 then
        self:runCsbAction("idle", true, nil, 30)
    end
end

function CashMoneyResultBaseView:showDeluxeCallFun(updateIndex)
    if updateIndex == 1 then
        self:showBaseRewardFun()
    elseif updateIndex == 2 then
        self:showDeluexeExtra()
    elseif updateIndex == 3 then
        self:growBaseCoin()
    elseif updateIndex == 4 then
        self:showVipRewardFun()
    elseif updateIndex == 5 then
        self:showCashValueFun()
    elseif updateIndex == 6 then
        self:showDivisionValueFun()
    elseif updateIndex == 7 then
        self:showTotalRewardFun()
    elseif updateIndex == 8 then
        self:showCollectBtn()
    elseif updateIndex == 9 then
        self:runCsbAction("idle", true, nil, 30)
    end
end

-- 爆炸粒子效果
function CashMoneyResultBaseView:playBaoAnim(node)
    local eff = util_createAnimation("NewCashBonus/CashMoney/CashBonusMoney/Cashmoney_eff.csb")
    node:addChild(eff)
    eff:setPositionNormalized(cc.p(0.5, 0.5))
    eff:playAction("change")
end
-- 显示基础奖励
function CashMoneyResultBaseView:showBaseRewardFun()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    self.m_baseCoinsLb:setString(util_formatCoins(tonumber(self.m_baseCoins), 9))
    self.m_baseCoinsLb:setVisible(true)
    self.m_baseCoinsLb:setScale(1)
    self.m_baseCoinsLb:runAction(cc.FadeIn:create(5 / 30))
    self:playBaoAnim(self.m_baseCoinsLb)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        10 / 30
    )
end
-- 显示vip 加成奖励
function CashMoneyResultBaseView:showVipRewardFun()
    local gameData = G_GetMgr(G_REF.CashMoney):getDataByGameId(self.m_gameId)
    local vipMultiply = gameData:getVipMultiply()

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    self.m_vipLb:setString(vipMultiply)
    self.m_vipLb:setVisible(true)
    self.m_vipLb:setScale(1)
    self.m_vipLb:runAction(cc.FadeIn:create(5 / 30))
    self:playBaoAnim(self.m_vipLb)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        10 / 30
    )
end

-- 显示单价系数
function CashMoneyResultBaseView:showCashValueFun()
    local cashMultiply = self:getCashValue()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    self.m_cashValueLb:setString(util_formatCoins(cashMultiply, 4))
    self.m_cashValueLb:setVisible(true)
    self.m_cashValueLb:setScale(1)
    self.m_cashValueLb:runAction(cc.FadeIn:create(5 / 30))
    self:playBaoAnim(self.m_cashValueLb)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        10 / 30
    )
end

-- 显示段位系数
function CashMoneyResultBaseView:showDivisionValueFun()
    -- 判断是否有关卡挑战段位加成
    local gameData = G_GetMgr(G_REF.CashMoney):getDataByGameId(self.m_gameId)

    if gameData and gameData:getArenaMultiply() > 0 then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
        local lbDivi = self:findChild("m_lb_division")
        lbDivi:setString(gameData:getArenaMultiply())
        lbDivi:setVisible(true)
        lbDivi:runAction(cc.FadeIn:create(5 / 30))
        self:playBaoAnim(lbDivi)
        performWithDelay(
            self,
            function()
                self:doNext()
            end,
            20 / 30
        )
    else
        self:doNext()
    end
end

-- 显示总钱数
function CashMoneyResultBaseView:showTotalRewardFun(endCallFunc)
    local gameData = G_GetMgr(G_REF.CashMoney):getDataByGameId(self.m_gameId)
    local totalCoins = gameData:getTotalCoins()
    -- lb_sumCoin
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    self.m_totalCoinsLb:setString(util_formatCoins(totalCoins, 9))
    util_alignCenter({{node = self.lb_coin, alignX = 7}, {node = self.m_totalCoinsLb}})
    self.lb_coin:setVisible(true)
    -- self.node_coins:setScale(1)
    self.lb_coin:runAction(cc.FadeIn:create(5 / 30))
    if not tolua.isnull(self.node_coins) then
        self.node_coins:setVisible(true)
        self.node_coins:runAction(cc.FadeIn:create(5 / 30))
        self:playBaoAnim(self.node_coins)
    end
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        5 / 30
    )
end

function CashMoneyResultBaseView:showDeluexeExtra(endCallFunc)
    --抛物线飞倍数
    local startPos = cc.p(self.m_sp_deluxe:getPosition())
    local endPos = cc.p(self.m_baseCoinsLb:getPosition())
    local radian = 75 * math.pi / 180
    local height = 250
    local q1x = startPos.x + (endPos.x - startPos.x) / 4
    local q1 = cc.p(q1x, height + startPos.y + math.cos(radian) * q1x)
    local q2x = startPos.x + (endPos.x - startPos.x) / 2
    local q2 = cc.p(q2x, height + startPos.y + math.cos(radian) * q2x)
    local bez = cc.BezierTo:create(0.6, {q1, q2, endPos})
    local seq = cc.Sequence:create(cc.ScaleTo:create(0.2, 3), cc.ScaleTo:create(0.4, 1.5))
    local spw = cc.Spawn:create(bez, seq)
    self.m_sp_deluxe:runAction(spw)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        0.6
    )
end

function CashMoneyResultBaseView:growBaseCoin(endCallFunc)
    --倍数飞到位置滚动基础钱
    self.m_sp_deluxe:setVisible(false)
    local multiple = globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD
    local extraNum = self.m_baseCoins * multiple / 100
    local addValue = extraNum / 15
    util_jumpNum(self.m_baseCoinsLb, self.m_baseCoins, extraNum + tonumber(self.m_baseCoins), addValue, 0.02, {30})
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        20 / 30
    )
end

function CashMoneyResultBaseView:showCollectBtn()
    self.m_btn_collect:setTouchEnabled(true)
    self.m_btn_collect:setVisible(true)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        1 / 30
    )
end

--飞金币
function CashMoneyResultBaseView:flyCoins(callBack)
    local gameData = G_GetMgr(G_REF.CashMoney):getDataByGameId(self.m_gameId)
    local totalCoins = gameData:getTotalCoins()

    local endPos = globalData.flyCoinsEndPos
    local btnCollect = self:findChild("Button_collect")

    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local addCoins = totalCoins
    local baseCoins = globalData.topUICoinCount

    gLobalViewManager:pubPlayFlyCoin(
        startPos,
        endPos,
        baseCoins,
        addCoins,
        function()
            if callBack ~= nil then
                callBack()
            end
        end
    )
end

return CashMoneyResultBaseView
