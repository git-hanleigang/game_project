--[[--
    聚合 - 轮盘道具奖励弹版
]]
local HolidayChallenge_BaseWheelRewardLayer = class("HolidayChallenge_BaseWheelRewardLayer", BaseLayer)

-- itemList道具名字,clickFunc点击回调,flyCoins=飞金币数量
function HolidayChallenge_BaseWheelRewardLayer:initDatas(itemList, clickFunc, flyCoins, theme)
    self.m_itemList = itemList or {}
    self.m_func = clickFunc
    self.m_coins = flyCoins or 0
    self.m_gems = 0

    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()

    local LPath = self.m_activityConfig.RESPATH.WHEEL_REWARD_FREE_LAYER
    -- 加载不同主题
    if theme and theme == "jackpot" then
        LPath = self.m_activityConfig.RESPATH.WHEEL_REWARD_PAY_LAYER
    end

    self:setLandscapeCsbName(LPath)

    self:setExtendData("HolidayChallenge_WheelRewardLayer")
    self._openClock = os.clock()

    self:initGemData()
end

function HolidayChallenge_BaseWheelRewardLayer:initGemData()
    for i, item_data in ipairs(self.m_itemList) do
        if item_data.p_icon and item_data.p_icon == "Gem" then
            self.m_gems = self.m_gems + item_data.p_num
        end
    end
end

function HolidayChallenge_BaseWheelRewardLayer:initView()
    local node_list = self:findChild("node_reward")
    if node_list then
        if self.m_itemList and table.nums(self.m_itemList) > 0 then
            local node = gLobalItemManager:createRewardListView(self.m_itemList, nil, self:getMaxCount())
            node_list:addChild(node)
        end
    end
end

-- 一行显示的最大数量
function HolidayChallenge_BaseWheelRewardLayer:getMaxCount()
    return 5
end

-- function HolidayChallenge_BaseWheelRewardLayer:playShowAction()
--     gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
--     HolidayChallenge_BaseWheelRewardLayer.super.playShowAction(self, "open")
-- end

-- function HolidayChallenge_BaseWheelRewardLayer:playHideAction()
--     HolidayChallenge_BaseWheelRewardLayer.super.playHideAction(self, "close")
-- end

function HolidayChallenge_BaseWheelRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function HolidayChallenge_BaseWheelRewardLayer:onClickMask()
    self:collectReward()
end

function HolidayChallenge_BaseWheelRewardLayer:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local btnName = sender:getName()
    self:collectReward(btnName)
end

function HolidayChallenge_BaseWheelRewardLayer:collectReward(btnName)
    if os.clock() - self._openClock <= 0.5 then
        return
    end
    if self.close then
        return
    end
    self.close = true
    self:flyCurrency(function()
        if not tolua.isnull(self) then
            self:closeUI(btnName)
        end
    end)
end

function HolidayChallenge_BaseWheelRewardLayer:closeUI(btnName)
    local function callFunc()
        if self.m_func then
            self.m_func(btnName)
            self.m_func = nil
        end 
    end
    HolidayChallenge_BaseWheelRewardLayer.super.closeUI(self, callFunc)
end

function HolidayChallenge_BaseWheelRewardLayer:flyCurrency(func)
    self.m_coins = self.m_coins or 0
    self.m_gems = self.m_gems or 0

    local btnCollect = self:findChild("btn_go")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local flyList = {}
        if self.m_coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos})
        end
        if self.m_gems > 0 then
            table.insert(flyList, {cuyType = FlyType.Gem, addValue = self.m_gems, startPos = startPos})
        end
        curMgr:playFlyCurrency(flyList, func)
    else
        if self.m_coins <= 0 then
            func()
            return
        end
        gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_coins, func)
    end
end

return HolidayChallenge_BaseWheelRewardLayer
