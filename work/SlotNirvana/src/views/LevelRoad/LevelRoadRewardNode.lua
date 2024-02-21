-- 等级里程碑进度界面
local LevelRoadRewardNode = class("LevelRoadRewardNode", util_require("base.BaseView"))

function LevelRoadRewardNode:initUI()
    LevelRoadRewardNode.super.initUI(self)
    self:initView()
end

local BUBBLE_TYPE = {
    SWELL = "Swell", -- 膨胀系数 + 小游戏
    FUNCTION = "Function", -- 解锁的功能
    ITEM = "Item", -- 道具
    COINS_ITEMS = "CoinsItems", --（老玩家）首次奖励
    ULOCK_GAME = "Game", -- 解锁关卡
}

-- type : Swell: 膨胀系数 + 小游戏 Function: 解锁的功能 Item: 道具
function LevelRoadRewardNode:initDatas(_params)
    local params = _params or {}
    self.m_phaseData = params.phaseData
    self.m_type = self.m_phaseData.type
    local curLevel = globalData.userRunData.levelNum
    self.m_isCanCollect = curLevel >= self.m_phaseData.level
    self.m_isTouch = false
end

function LevelRoadRewardNode:getCsbName()
    if self.m_type == BUBBLE_TYPE.SWELL then
        if globalData.slotRunData.isPortrait then
            return "LevelRoad/csd/Main_Portrait/LevelRoad_levelbar_reward_bubble_1_Portrait.csb"
        end
        return "LevelRoad/csd/LevelRoad_levelbar_reward_bubble_1.csb"
    elseif self.m_type == BUBBLE_TYPE.FUNCTION then
        if globalData.slotRunData.isPortrait then
            return "LevelRoad/csd/Main_Portrait/LevelRoad_levelbar_reward_bubble_2_Portrait.csb"
        end
        return "LevelRoad/csd/LevelRoad_levelbar_reward_bubble_2.csb"
    elseif self.m_type == BUBBLE_TYPE.ITEM then
        if globalData.slotRunData.isPortrait then
            return "LevelRoad/csd/Main_Portrait/LevelRoad_levelbar_reward_bubble_3_Portrait.csb"
        end
        return "LevelRoad/csd/LevelRoad_levelbar_reward_bubble_3.csb"
    elseif self.m_type == BUBBLE_TYPE.COINS_ITEMS then
        return "LevelRoad/csd/LevelRoad_levelbar_levelphase_gift.csb"
    elseif self.m_type == BUBBLE_TYPE.ULOCK_GAME then
        if globalData.slotRunData.isPortrait then
            return "LevelRoad/csd/Main_Portrait/LevelRoad_levelbar_reward_bubble_new_Portrait.csb"
        end
        return "LevelRoad/csd/LevelRoad_levelbar_reward_bubble_new.csb"
    end
end

function LevelRoadRewardNode:initCsbNodes()
    self.m_node_collect = self:findChild("node_collect")
    self.m_btn_collect = self:findChild("btn_collect")
    self.m_btn_collect:setSwallowTouches(false)
    if self.m_type == BUBBLE_TYPE.SWELL then
        -- type = swell 膨胀系数 + 小游戏
        self.m_sp_num_x = self:findChild("sp_num_x")
        self.m_lb_buff_num = self:findChild("lb_buff_num")
        self.m_lb_coin = self:findChild("lb_coin")
        self.m_sp_collect = self:findChild("sp_collect")
        self.m_sp_minigame_icon = self:findChild("sp_minigame_icon")
        self.m_node_propFrame = self:findChild("node_propFrame")
        self.m_node_Frame = self:findChild("node_Frame")
    elseif self.m_type == BUBBLE_TYPE.FUNCTION then
        -- type = function: 解锁的功能
        self.m_node_activity = self:findChild("node_activity")
        self.m_lb_activity_name = self:findChild("lb_activity_name")
    elseif self.m_type == BUBBLE_TYPE.ITEM or self.m_type == BUBBLE_TYPE.ULOCK_GAME then
        -- type = item: 道具
        self.m_node_item = self:findChild("node_item")
    end
end

function LevelRoadRewardNode:onEnter()
    LevelRoadRewardNode.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.m_isCanCollect then
                gLobalSoundManager:playSound("LevelRoad/sound/LevelRoad_bubble.mp3")
                self:runCsbAction("over", false, function()
                    if self.m_type == BUBBLE_TYPE.ULOCK_GAME then
                       self:checkPopUnlockGameLayer() 
                    end
                    self:setVisible(false)
                end, 60)
            end
        end,
        ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER
    )
    -- 请求领取奖励
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not params then
                self.m_isTouch = false
            end
        end,
        ViewEventType.NOTIFY_LEVELROAD_REQUEST_REWARD
    )
end

function LevelRoadRewardNode:initView()
    if self.m_type == BUBBLE_TYPE.SWELL then
        self:initSwell()
    elseif self.m_type == BUBBLE_TYPE.FUNCTION then
        self:initFunction()
    elseif self.m_type == BUBBLE_TYPE.ITEM or self.m_type == BUBBLE_TYPE.ULOCK_GAME then
        self:initItem()
    end
    self:initAnimation()
end

function LevelRoadRewardNode:initAnimation()
    if self.m_isCanCollect then
        self:runCsbAction("idle", true, nil, 60)
    else
        self:runCsbAction("idle2", true, nil, 60)
    end
end

function LevelRoadRewardNode:initSwell()
    local coins = self.m_phaseData.winUpTo or 0
    self.m_lb_coin:setString(util_formatCoins(coins, 9))
    local expansion = self.m_phaseData.expansion or 0
    self.m_lb_buff_num:setString("" .. expansion)
    local uiList = {
        {node = self.m_sp_num_x},
        {node = self.m_lb_buff_num}
    }
    util_alignCenter(uiList, nil, 150)
    local propFrame = nil
    local items = self.m_phaseData.items or {}
    if #items > 0 then
        for i, v in ipairs(items) do
            if string.find(v.p_icon, "MiniGame") then
                local iconPath = "PBRes/CommonItemRes/icon/" .. items[1].p_icon .. ".png"
                util_changeTexture(self.m_sp_minigame_icon, iconPath)
            end
            if string.find(v.p_icon, "PropFrame_") then
                propFrame = gLobalItemManager:createRewardNode(v, ITEM_SIZE_TYPE.REWARD)
            end
        end
    end
    if self.m_node_propFrame and propFrame then
        self.m_node_Frame:setVisible(true)
        self.m_node_propFrame:addChild(propFrame)
    else
        self.m_node_Frame:setVisible(false)
    end
    self.m_sp_collect:setVisible(self.m_isCanCollect)
end

function LevelRoadRewardNode:initFunction()
    local unLock = self.m_phaseData.unLock or {}
    local unLockName = self.m_phaseData.unlockName or {}
    local len = #unLock
    for i = 1, len do
        local iconName = unLock[i]
        local posX = -((len / 2) - 0.5) * 128 + 128 * (i - 1)
        local iconPath = "LevelRoad/icon/" .. iconName .. ".png"
        local iconSp = util_createSprite(iconPath)
        iconSp:setScale(0.4)
        iconSp:setPositionX(posX)
        self.m_node_activity:addChild(iconSp)

        local functionName = unLockName[i]
        if functionName then
            local LevelRoadRewardWordNode = util_createView("views.LevelRoad.LevelRoadRewardWordNode", functionName)
            if LevelRoadRewardWordNode then
                LevelRoadRewardWordNode:setPosition(posX, -50)
                self.m_node_activity:addChild(LevelRoadRewardWordNode)
            end
        end
    end
end

function LevelRoadRewardNode:initItem()
    local items = self.m_phaseData.items or {}
    local itemDataList = {}
    -- 通用道具
    if items and #items > 0 then
        for i, v in ipairs(items) do
            itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
        end
    end

    local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
    if itemNode then
        self.m_node_item:addChild(itemNode)
    end
    self.m_node_collect:setVisible(self.m_isCanCollect)
end

function LevelRoadRewardNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        if self.m_isCanCollect and not self.m_isTouch then
            self.m_isTouch = true
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            G_GetMgr(G_REF.LevelRoad):requestCollectReward()
        else
            if self.m_type == BUBBLE_TYPE.SWELL then
                G_GetMgr(G_REF.LevelRoad):showBoostTipLayer(self.m_phaseData)
            end
        end
    end
end

function LevelRoadRewardNode:getOffsetPos()
    if self.m_node_collect then
        return cc.p(self.m_node_collect:getPosition())
    end
    return cc.p(0, 0)
end

function LevelRoadRewardNode:checkPopUnlockGameLayer()
    local gameIdList = self.m_phaseData.unlockGameList or {}
    if #gameIdList == 0 then
        return
    end

    G_GetMgr(G_REF.LevelRoad):showUnlockGameLayer(gameIdList)
end

return LevelRoadRewardNode
