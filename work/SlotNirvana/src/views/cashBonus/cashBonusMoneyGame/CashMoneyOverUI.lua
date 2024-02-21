--[[--
    cashbonus钞票小游戏
    结算界面
]]
local CashMoneyOverUI = class("CashMoneyOverUI", util_require("base.BaseView"))
local SOUND_RES = {
    click = "NewCashBonus/CashBonusMoney/music/cashMoney_click.mp3"
}
local DELAY_TIME = 0.35
function CashMoneyOverUI:initUI(baseCoins, netCallFunc)
    -- setDefaultTextureType("RGBA8888", nil)

    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    if cashMoneyData and cashMoneyData:getCashBonusDis() > 0 then
        self:createCsbNode("NewCashBonus/CashBonusMoney/CashGameResult_cashmoney_0.csb")
    else
        self:createCsbNode("NewCashBonus/CashBonusMoney/CashGameResult_cashmoney.csb")
    end

    self.m_baseCoinsLb = self:findChild("m_lb_baseCoins")
    self.m_vipLb = self:findChild("m_lb_vip_bonus")
    self.m_cashValueLb = self:findChild("m_lb_cash_value")
    self.m_totalCoinsLb = self:findChild("m_lb_total_coins")
    self.m_baseCoinsLb:setString("")
    self.m_vipLb:setString("")
    self.m_cashValueLb:setString("")
    self.m_totalCoinsLb:setString("")

    local lbDivi = self:findChild("m_lb_division")
    if lbDivi then
        lbDivi:setString("")
    end

    self.m_btn_collect = self:findChild("Button_collect")
    self.m_btn_collect:setTouchEnabled(false)
    self.m_btn_collect:setVisible(false)

    self.m_sp_deluxe = self:findChild("deluxe_extra")

    self:runCsbAction(
        "show",
        false,
        function()
            self:startNextLogic()
            self:runCsbAction("idle", true)
        end
    )

    self.m_baseCoins = baseCoins
    self.m_netCallFunc = netCallFunc
    self:initView()

    -- setDefaultTextureType("RGBA4444", nil)
end

function CashMoneyOverUI:collectFunc()
    if self.m_netCallFunc then
        self.m_netCallFunc()
    end
end

function CashMoneyOverUI:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_collect" then
        if self.Closed then
            return
        end
        if self.m_clicked then
            return
        end
        self.m_clicked = true

        -- self.m_btn_collect:setTouchEnabled(false)
        -- self.m_btn_collect:setBright(false)
        self.m_btn_collect:setTouchEnabled(false)
        gLobalSoundManager:playSound(SOUND_RES.click)
        self:collectFunc()
    end
end

function CashMoneyOverUI:closeUI()
    if self.Closed then
        return
    end
    self.Closed = true

    self:runCsbAction(
        "over",
        false,
        function()
            if not tolua.isnull(self) then
                self:removeFromParent()
            end
        end
    )

    gLobalDataManager:setBoolByField("newGuideShowNextCashBonus", false)
    gLobalDataManager:setNumberByField("newGuideShowCashMoneyCD", 0)
end

function CashMoneyOverUI:initView()
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

--飞金币
function CashMoneyOverUI:flyCoins(callBack)
    local endPos = globalData.flyCoinsEndPos
    local btnCollect = self:findChild("Button_collect")

    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local addCoins = G_GetMgr(G_REF.CashBonus):getCashMoneyData().p_totalCoins
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

function CashMoneyOverUI:checkDeluxe()
    if globalData.deluexeClubData:getDeluexeClubStatus() == true then
        return true
    end
    return false
    -- return true
end

function CashMoneyOverUI:startNextLogic()
    self:doNext()
end

function CashMoneyOverUI:doNext()
    self.m_index = (self.m_index or 0) + 1
    if self:checkDeluxe() then
        self:showDeluxeCallFun(self.m_index)
    else
        self:showNormalCallFun(self.m_index)
    end
end

-- 播放结果回调函数
function CashMoneyOverUI:showNormalCallFun(updateIndex)
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
    end
end

function CashMoneyOverUI:showDeluxeCallFun(updateIndex)
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
    end
end

-- 爆炸粒子效果
function CashMoneyOverUI:playBaoAnim(node)
    local eff = util_createAnimation("NewCashBonus/CashBonusNew/CashPickResultlbEff.csb")
    node:addChild(eff)
    eff:setPositionNormalized(cc.p(0.5, 0.5))
    eff:playAction("change")
end
-- 显示基础奖励
function CashMoneyOverUI:showBaseRewardFun()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    self.m_baseCoinsLb:setString(util_formatCoins(tonumber(self.m_baseCoins), 9))
    self:playBaoAnim(self.m_baseCoinsLb)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        DELAY_TIME
    )
end
-- 显示vip 加成奖励
function CashMoneyOverUI:showVipRewardFun()
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    self.m_vipLb:setString(cashMoneyData.p_vipMultiply)
    self:playBaoAnim(self.m_vipLb)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        DELAY_TIME
    )
end
-- 显示单价系数
function CashMoneyOverUI:showCashValueFun()
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    self.m_cashValueLb:setString(util_formatCoins(tonumber(cashMoneyData.p_cashMultiply), 4))
    self:playBaoAnim(self.m_cashValueLb)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        DELAY_TIME
    )
end

-- 显示段位系数
function CashMoneyOverUI:showDivisionValueFun()
    -- 判断是否有关卡挑战段位加成
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    if cashMoneyData and cashMoneyData:getCashBonusDis() > 0 then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
        local lbDivi = self:findChild("m_lb_division")
        lbDivi:setString(cashMoneyData:getCashBonusDis())
        self:playBaoAnim(lbDivi)
        performWithDelay(
            self,
            function()
                self:doNext()
            end,
            DELAY_TIME
        )
    else
        self:doNext()
    end
end

-- 显示总钱数
function CashMoneyOverUI:showTotalRewardFun(endCallFunc)
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT)
    self.m_totalCoinsLb:setString(util_formatCoins(cashMoneyData.p_totalCoins, 9))
    self:playBaoAnim(self.m_totalCoinsLb)
    performWithDelay(
        self,
        function()
            self:doNext()
        end,
        DELAY_TIME
    )
end

function CashMoneyOverUI:showDeluexeExtra(endCallFunc)
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

function CashMoneyOverUI:growBaseCoin(endCallFunc)
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
        DELAY_TIME
    )
end

function CashMoneyOverUI:showCollectBtn()
    self.m_btn_collect:setTouchEnabled(true)
    self.m_btn_collect:setVisible(true)
end

function CashMoneyOverUI:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local success = params.success
            local type = params.type
            self:sendCashMoneyCollectCallBack(success, type)
        end,
        ViewEventType.CASHBONUS_CASHMONEY_CALLBACK
    )
end

function CashMoneyOverUI:sendCashMoneyCollectCallBack(_success, _type)
    if _type == ActionType.MegaCashCollect then
        if _success then
            self:flyCoins(
                function()
                    self:closeUI()
                end
            )
        else
            self.m_clicked = false
        end
    end
end
return CashMoneyOverUI
