--[[--
    道具奖励弹版
]]
local ItemRewardLayer = class("ItemRewardLayer", BaseLayer)

function ItemRewardLayer:ctor()
    ItemRewardLayer.super.ctor(self)

    self.m_coins = toLongNumber(0)
end

-- itemList道具名字,clickFunc点击回调,flyCoins=飞金币数量,skipRotate = 横竖屏适配
function ItemRewardLayer:initDatas(itemList, clickFunc, flyCoins, skipRotate, theme, nodeSize)
    self.m_itemList = itemList
    self.m_func = clickFunc

    self.m_coins:setNum(flyCoins)
    
    self.m_gems = 0
    self.m_theme = theme
    self.m_nodeSize = nodeSize

    local LPath = "PBRes/CommonItemRes/ItemRewardLayer.csb"
    local PPath = "PBRes/CommonItemRes/ItemRewardLayer_shu.csb"
    -- 加载不同主题
    if theme == "BlackFriday" then
        LPath = "PBRes/CommonItemRes/Common_RewardLayer_BlackFriday22.csb"
        -- PPath =  待做
    elseif theme == "Christmas2022" then
        LPath = "PBRes/CommonItemRes/Common_RewardLayer_Christmas2022.csb"
    elseif theme == "Christmas2023" then
        LPath = "PBRes/CommonItemRes/Common_RewardLayer_Christmas2023.csb"
        self.m_showActName = "start"
        -- PPath =  待做
    elseif theme == "Activity_BalloonRush" then
        LPath = "PBRes/CommonItemRes/CollectLayer_BalloonRush.csb"
        PPath = "PBRes/CommonItemRes/CollectLayer_BalloonRush_shu.csb"
    elseif theme == "Activity_RainbowRush" then
        LPath = "PBRes/CommonItemRes/CollectLayer_RainbowRush.csb"
        PPath = "PBRes/CommonItemRes/CollectLayer_RainbowRush_shu.csb"
    elseif theme == "NoviceTrail" then
        LPath = "Activity/Activity_NoviceTrail/csd/heng/NoviceTrail_Reward_heng.csb"
        PPath = "Activity/Activity_NoviceTrail/csd/shu/NoviceTrail_Reward_shu.csb"
        self.m_showActName = "start"
    end

    self:setLandscapeCsbName(LPath)
    self:setPortraitCsbName(PPath)

    self:setExtendData("ItemRewardLayer")
    self._openClock = os.clock()

    self:initGemData()
end

function ItemRewardLayer:initGemData()
    for i, item_data in ipairs(self.m_itemList) do
        if item_data.p_icon and item_data.p_icon == "Gem" then
            self.m_gems = self.m_gems + item_data.p_num
        end
    end
end

function ItemRewardLayer:initView()
    local node_list = self:findChild("node_list")
    if node_list then
        if self.m_itemList and table.nums(self.m_itemList) > 0 then
            local node = gLobalItemManager:createRewardListView(self.m_itemList, nil, self:getMaxCount(), self.m_nodeSize)
            node_list:addChild(node)
        end
    end
end

-- 一行显示的最大数量
function ItemRewardLayer:getMaxCount()
    if globalData.slotRunData.isPortrait == true then
        return 4
    end
    return 5
end

-- 弹板显示动画
function ItemRewardLayer:playShowAction()
    if self.m_showActName then
        local soundPath = self.m_commonShowSound or "Sounds/soundOpenView.mp3"
        gLobalSoundManager:playSound(soundPath)
    end
    ItemRewardLayer.super.playShowAction(self, self.m_showActName)
end

function ItemRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function ItemRewardLayer:onKeyBack()
    self:collectReward()
end

function ItemRewardLayer:onClickMask()
    self:collectReward()
end

function ItemRewardLayer:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local btnName = sender:getName()
    self:collectReward(btnName)
end

function ItemRewardLayer:collectReward(btnName)
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

function ItemRewardLayer:closeUI(btnName)
    local function callFunc()
        if self.m_func then
            self.m_func(btnName)
            self.m_func = nil
        end 
    end
    ItemRewardLayer.super.closeUI(self, callFunc)
end

function ItemRewardLayer:flyCurrency(func)
    self.m_gems = self.m_gems or 0
    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local flyList = {}
        if toLongNumber(self.m_coins) > toLongNumber(0) then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos})
        end
        if self.m_gems > 0 then
            table.insert(flyList, {cuyType = FlyType.Gem, addValue = self.m_gems, startPos = startPos})
        end
        curMgr:playFlyCurrency(flyList, func)
    else
        if toLongNumber(self.m_coins) <= toLongNumber(0) then
            func()
            return
        end
        gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_coins, func)
    end
end

return ItemRewardLayer
