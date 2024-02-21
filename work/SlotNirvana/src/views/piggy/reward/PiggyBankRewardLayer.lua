--[[
    结算界面
]]
local PiggyBankRewardLayer = class("PiggyBankRewardLayer", BaseLayer)

function PiggyBankRewardLayer:initDatas()
    self:setLandscapeCsbName("PigBank2022/csb/reward/PiggyBank_reward.csb")
    self:setPortraitCsbName("PigBank2022/csb/reward/PiggyBank_reward_Portrait.csb")
    self:setShowActionEnabled(false)
end

function PiggyBankRewardLayer:initCsbNodes()
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
    self.m_particle = self:findChild("ef_lizi")
    self.m_btnCollect = self:findChild("btn_collect")
end

function PiggyBankRewardLayer:initView()
    -- 金币奖励展示
    self:initCoins()
    self.m_isStarting = true
    gLobalSoundManager:playSound("PigBank2022/other/music/reward_open.mp3")
    self:runCsbAction(
        "show",
        false,
        function()
            self.m_isStarting = false
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
end

function PiggyBankRewardLayer:initCoins()
    local coinNum = self:getCoinNum()
    self.m_lbCoin:setString(util_getFromatMoneyStr(coinNum))
    local UIList = {}
    UIList[#UIList + 1] = {node = self.m_spCoin, scale = 0.85, anchor = cc.p(0.5, 0.5)}
    UIList[#UIList + 1] = {node = self.m_lbCoin, scale = 0.65, anchor = cc.p(0.5, 0.5), alignX = 2, alignY = 2}
    util_alignCenter(UIList, nil, 700)
end

--购买之后更新存储信息
function PiggyBankRewardLayer:buyAfterInitData()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_PIGBANK_DATA)
end

function PiggyBankRewardLayer:buySuccessOver()
    if self.m_collecting then
        return
    end
    self.m_collecting = true
    self:buyAfterInitData()
    local startPos = self.m_btnCollect:getParent():convertToWorldSpace(cc.p(self.m_btnCollect:getPosition()))
    local baseCoins = globalData.topUICoinCount
    local rewardCoins = globalData.userRunData.coinNum - baseCoins
    gLobalViewManager:pubPlayFlyCoin(
        startPos,
        globalData.flyCoinsEndPos,
        baseCoins,
        rewardCoins,
        function()
            self:closeUI()
        end
    )
end

function PiggyBankRewardLayer:canClick()
    if self.m_isStarting then
        return false
    end
    if self:isHiding() then
        return false
    end
    if self.m_collecting then
        return false
    end
    return true
end

function PiggyBankRewardLayer:closeUI(_over)
    if self.m_closed then
        return
    end
    self.m_closed = true
    self.m_particle:setVisible(false)
    local mainLayer = gLobalViewManager:getViewByName("PiggyBankLayer")
    if mainLayer then
        mainLayer:closeUI()
    end
    PiggyBankRewardLayer.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
            G_GetMgr(G_REF.PiggyBank):doRewardDropFunc()
        end
    )
end

function PiggyBankRewardLayer:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "btn_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buySuccessOver()
    end
end

function PiggyBankRewardLayer:getCoinNum()
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    local coins = piggyBankData:getRewardCoin() or 0
    return coins
end

return PiggyBankRewardLayer
