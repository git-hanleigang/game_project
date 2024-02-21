--[[--
    小游戏 奖励界面
]]
local LSGameRewardUI = class("LSGameRewardUI", BaseLayer)

function LSGameRewardUI:initDatas(_over)
    LSGameRewardUI.super.initDatas(self)
    self.m_over = _over
    self.m_winCoins = self:getWinCoins() or 0
    self:setLandscapeCsbName(LuckyStampCfg.csbPath .. "rewardUI/NewLuckyStamp_Reward.csb")
end

function LSGameRewardUI:initCsbNodes()
    self.m_lbCoin = self:findChild("lb_coin")
    self.m_btnCollect = self:findChild("btn_collect")
end

function LSGameRewardUI:initView()
    self.m_lbCoin:setString(util_formatCoins(self.m_winCoins, 30))
    gLobalSoundManager:playSound(LuckyStampCfg.otherPath .. "music/rewards.mp3")
end

function LSGameRewardUI:collectReward()
    if self.m_collectReward then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.m_collectReward = true

    G_GetMgr(G_REF.LuckyStamp):requestCollect(
        function()
            if not tolua.isnull(self) then
                local coinNum = self.m_winCoins
                local startPos = self.m_btnCollect:getParent():convertToWorldSpace(cc.p(self.m_btnCollect:getPosition()))
                local flyList = {}
                if coinNum > 0 then
                    table.insert(flyList, {cuyType = FlyType.Coin, addValue = coinNum, startPos = startPos})
                end
                if #flyList > 0 then
                    G_GetMgr(G_REF.Currency):playFlyCurrency(
                        flyList,
                        function()
                            if not tolua.isnull(self) then
                                self:closeUI()
                            end
                        end
                    )
                else
                    self:closeUI()
                end
            end
        end
    )
end

function LSGameRewardUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function LSGameRewardUI:onClickMask()
    self:collectReward()
end

function LSGameRewardUI:onEnter()
    LSGameRewardUI.super.onEnter(self)
end

function LSGameRewardUI:closeUI(_over)
    LSGameRewardUI.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
            if self.m_over then
                self.m_over()
            end
        end
    )
end

function LSGameRewardUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        self:collectReward()
    end
end

function LSGameRewardUI:getWinIndex()
    if LuckyStampCfg.TEST_MODE == true then
        return 10
    end
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processData = data:getCurProcessData()
        if processData then
            return processData:getWinIndex()
        end
    end
    return nil
end

-- 获取戳的数据
function LSGameRewardUI:getStampData()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        return data:getCurProcessData()
    end
    return nil
end

function LSGameRewardUI:getWinBoxData()
    local winIndex = self:getWinIndex()
    if winIndex ~= nil then
        local stampData = self:getStampData()
        if stampData then
            return stampData:getLatticeDataByIndex(winIndex + 1)
        end
    end
    return nil
end

function LSGameRewardUI:getWinCoins()
    if LuckyStampCfg.TEST_MODE == true then
        return 1234567890
    end
    local boxData = self:getWinBoxData()
    if boxData then
        return boxData:getCoins()
    end
    return 0
end

return LSGameRewardUI
