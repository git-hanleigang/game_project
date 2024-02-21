-- quest 轮盘

local QuestWheel = class("QuestWheel", BaseLayer)

function QuestWheel:ctor()
    QuestWheel.super.ctor(self)
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestWheel)
    self:setExtendData("QuestWheel")
end

function QuestWheel:initCsbNodes()
    self.lb_coins = self:findChild("lb_coins")

    self.sp_wheel = self:findChild("sp_wheel") -- 轮盘
    -- 物品节点
    self.items = {}
    for i = 1, 8 do
        local node_item = self:findChild("node_item" .. i)
        table.insert(self.items, node_item)
    end

    self.btn_close = self:findChild("btn_close") -- 关闭按钮

    local ef_lizi1 = self:findChild("ef_lizi")
    local ef_lizi2 = self:findChild("ef_lizi_0")
    local ef_lizi3 = self:findChild("ef_lizi_0_0")
    local ef_lizi4 = self:findChild("ef_lizi_0_1")
    self.eff_particles = {ef_lizi1, ef_lizi2, ef_lizi3, ef_lizi4}
end

function QuestWheel:initDatas(wheel_data, p_coins, bl_complete)
    --{
    --    hitIndex = 1,
    --    p_items = {ShopItem, ShopItem}
    --}
    self.wheel_data = wheel_data
    self.p_coins = tonumber(p_coins)
    self.bl_complete = bl_complete

    self.bl_touchEnable = true
end

function QuestWheel:initView()
    self.btn_close:setVisible(not self.bl_complete)
    self:updateCoins()
    for idx, node_item in ipairs(self.items) do
        local rewards = self.wheel_data.p_items[idx]
        local rewards_list = {}
        local items = rewards:getItems()
        if items and #items > 0 then
            for i, item_data in ipairs(items) do
                if #rewards_list >= 2 then
                    break
                end
                local itemNode = gLobalItemManager:createRewardNode(item_data, ITEM_SIZE_TYPE.REWARD)
                if not tolua.isnull(itemNode) then
                    table.insert(rewards_list, itemNode)
                    node_item:addChild(itemNode)
                end
            end
        end
        local coins = rewards:getCoins()
        if coins and coins > 0 then
            if #rewards_list < 2 then
                local item_data = gLobalItemManager:createLocalItemData("Coins", coins, {p_limit = 3})
                local itemNode = gLobalItemManager:createRewardNode(item_data, ITEM_SIZE_TYPE.REWARD)
                if not tolua.isnull(itemNode) then
                    table.insert(rewards_list, itemNode)
                    node_item:addChild(itemNode)
                end
            end
        end

        if #rewards_list >= 2 then
            local distance = 40 -- 两张卡岔开的位移
            for i, node_item in ipairs(rewards_list) do
                node_item:setLocalZOrder(-1 * i)
                node_item:setScale(0.7)
                if i == 1 then
                    node_item:setPositionX(distance / 2 * -1)
                    node_item:setRotation(-15)
                else
                    node_item:setPositionX(distance / 2)
                    node_item:setRotation(30)
                end
            end
        end
    end
end

function QuestWheel:updateCoins()
    if self.p_coins and self.p_coins > 0 then
        self.lb_coins:setVisible(true)
        local quest_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if quest_data then
            if not self.bl_complete then
                if quest_data.p_questJackpot and quest_data.p_questJackpot > 0 then
                    self.p_coins = self.p_coins + quest_data.p_questJackpot
                end
            else
                if quest_data.m_lastBoxJackpot and quest_data.m_lastBoxJackpot > 0 then
                    self.p_coins = self.p_coins + quest_data.m_lastBoxJackpot
                end
            end
        end

        --Magic卡buff加成
        local buffmul = 1
        local buffInfo = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
        if buffInfo then
            local nMuti = tonumber(buffInfo.buffMultiple)
            buffmul = buffmul + nMuti / 100
        end
        local buffInfo_1 = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_QUESTICONS_MORE)
        if buffInfo_1 then
            local nMuti = tonumber(buffInfo_1.buffMultiple) -1
            buffmul = buffmul + nMuti 
        end
        
        self.p_coins = self.p_coins * buffmul
        self.lb_coins:setString(util_formatCoins(self.p_coins, 12))
    else
        self.lb_coins:setVisible(false)
    end
end

function QuestWheel:onShowedCallFunc()
    self:runCsbAction("show2", true)
    for idx, eff_particle in pairs(self.eff_particles) do
        if eff_particle then
            eff_particle:resetSystem()
            eff_particle:setPositionType(0)
        end
    end

    if self.bl_complete then
        self.bl_touchEnable = false
        self:onRolling()
    end
end

function QuestWheel:onRolling()
    if self:getActionByTag(1000) then
        return
    end
    self:runCsbAction("show", true)

    local round = 3 -- 转几圈
    local time = 2 -- 持续时间
    local act =
        cc.Sequence:create(
        cc.DelayTime:create(2),
        cc.CallFunc:create(
            function()
                local total = table.nums(self.items)
                local pic_range = 360 / total
                local range = math.random(-pic_range / 5, pic_range / 5)
                local reward_idx = self.wheel_data.hitIndex
                local endPos = (reward_idx - 1) * pic_range + range

                local rotate = cc.RotateBy:create(time, round * 360 - endPos - 90)
                self.sp_wheel:runAction(cc.Sequence:create(cc.EaseSineInOut:create(rotate)))

                gLobalSoundManager:playSound("QuestSounds/Quest_wheel_rooling.mp3")
            end
        ),
        cc.DelayTime:create(time + 1),
        cc.CallFunc:create(
            function()
                self:closeUI(
                    function()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_WHEEL_ROLL_OVER)
                    end
                )
            end
        )
    )
    act:setTag(1000)
    self:runAction(act)
end

function QuestWheel:clickFunc(_sander)
    if not self.bl_touchEnable then
        return
    end
    local name = _sander:getName()
    if name == "btn_close" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_WHEEL_ROLL_OVER)
            end
        )
    end
end

function QuestWheel:onEnter()
   QuestWheel.super.onEnter(self)
   gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateCoins()
        end,
        ViewEventType.NOTIFY_MULEXP_END
    )
end

function QuestWheel:closeUI(callFunc)
    QuestWheel.super.closeUI(self, callFunc)
    for idx, eff_particle in pairs(self.eff_particles) do
        if eff_particle then
            eff_particle:setVisible(false)
        end
    end
end

return QuestWheel
