--[[
    --新版每日任务pass主界面  Reward Cell
    csc 2021-06-25
]]
local DailyMissionThreeLinePassRewardCell = class("DailyMissionThreeLinePassRewardCell", util_require("base.BaseView"))
function DailyMissionThreeLinePassRewardCell:initUI(_data)
    self.m_type = _data.type
    self.m_lock = _data.lock -- 是否只展示锁住的动画
    self.m_onlyShow = _data.onlyShow
    self.m_isPreview = _data.isPreview
    self.m_isPortrait = _data.isPortrait

    self:createCsbNode(self:getCsbName())

    self:initCsbNodes()
end

function DailyMissionThreeLinePassRewardCell:initCsbNodes()
    -- 读取csb 节点
    self.m_spNormal = self:findChild("sp_normal")
    self.m_nodeReward = self:findChild("node_reward")
    self.m_nodeQipao = self:findChild("node_qipao")
    self.m_labNum = self:findChild("lb_num")
    self.m_btnTouch = self:findChild("btn_touch")
    self.m_nodeEffect = self:findChild("node_ef_bjg")

    self.m_sprHighCoinMul = self:findChild("sp_x2")
    self.m_labMulNum = self:findChild("lb_jiaobiao")

    self.m_particle_1 = self:findChild("Particle_1")
end

function DailyMissionThreeLinePassRewardCell:getCsbName()
    if self.m_type == "season" then
        if self.m_isPortrait then
            return DAILYPASS_RES_PATH.DailyMissionPass_PassRewardSeasonCell_ThreeLine  
        else
            return DAILYPASS_RES_PATH.DailyMissionPass_PassRewardSeasonCell_ThreeLine  
        end
        
    elseif self.m_type == "premium" then
        if self.m_isPortrait then
        else
            
        end
        return DAILYPASS_RES_PATH.DailyMissionPass_PassRewardPremiumCell_ThreeLine  
    else
        if self.m_isPortrait then
        else
            
        end
        return DAILYPASS_RES_PATH.DailyMissionPass_PassRewardFreeCell_ThreeLine  
    end
end

function DailyMissionThreeLinePassRewardCell:getPayType()
    local payType = 0
    if self.m_type == "season" then
        payType = 1
    elseif self.m_type == "premium" then
        payType = 4
    end
    return payType
end

-- 刷新数据
function DailyMissionThreeLinePassRewardCell:updateData(_pointsInfo, _increase)
    if self.m_csbNode and self.m_csbAct then
        self.m_csbNode:stopAllActions()
    end
    self.m_bCanCollect = false
    self.m_pointsInfo = _pointsInfo
    self.m_isIncrease = _increase
    self:updateView()
end

function DailyMissionThreeLinePassRewardCell:updateView()
    self.m_btnTouch:setSwallowTouches(false)
    -- 刷新状态
    self:updateStatus()
    -- 判断底色
    self:updateBg()
    -- 加载道具
    self:addRewardNode()
    -- 加载特效节点
    self:addEffectNode()
end

function DailyMissionThreeLinePassRewardCell:updateStatus()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData then
        local actName = "idle"
        local bRepeat = false
        local currExp = actData:getCurExp()
        -- 先判断当前是否达到经验 可领取状态
        self.m_bCanCollect = false
        if currExp >= self.m_pointsInfo:getExp() then
            if self:getPayType() == 1 and actData:isUnlocked() then
                self.m_bCanCollect = true
            elseif self:getPayType() == 4 and actData:getCurrIsPayHigh() then
                self.m_bCanCollect = true
            else
                self.m_bCanCollect = true
            end
        end

        if self.m_bCanCollect then
            if not self.m_pointsInfo:getCollected() then
                if not self.m_isIncrease then
                    actName = "idle_claim" --如果还没有领取
                    bRepeat = true
                end
            else
                actName = "idle_gou" --已经领取过了
                if self.m_isPreview then
                    actName = "idle" --已经领取过了
                end
                self.m_bCanCollect = false
            end
        else
            -- 未到达进度的时候
            actName = "idle"
        end

        if self:getPayType() == 1 then -- 付费需要额外判断一次是否解锁 低档
            if actData:isUnlocked() == false then
                actName = "idle_lock"
                self.m_bUnlocked = false
                self.m_bCanCollect = false
                bRepeat = true
            else
                self.m_bUnlocked = true -- 已经解锁
            end

            if self.m_lock then -- 如果是默认锁住的状态,只播放锁住刷光动画
                actName = "idle_lock"
                self.m_bUnlocked = false
                self.m_bCanCollect = false
            end
        elseif self:getPayType() == 4 then -- 付费需要额外判断一次是否解锁 高档
            if actData:getCurrIsPayHigh() == false then
                actName = "idle_lock"
                self.m_bUnlocked = false
                self.m_bCanCollect = false
                bRepeat = true
            else
                self.m_bUnlocked = true -- 已经解锁
            end

            if self.m_lock then -- 如果是默认锁住的状态,只播放锁住刷光动画
                actName = "idle_lock"
                self.m_bUnlocked = false
                self.m_bCanCollect = false
            end
        end
        if self.m_onlyShow then
            actName = "idle"
            bRepeat = true
        end
        -- end
        self:runCsbActCheck(actName, bRepeat, nil, 60) --
    end
end

function DailyMissionThreeLinePassRewardCell:updateBg()
    if self.m_lock then
        local spLock = self:findChild("sp_lock")
        if spLock then
            spLock:setVisible(false)
        end
        if self:getPayType() > 0 then
            self:addClick(self.m_btnTouch)
        end
        self.m_labNum:setVisible(false)
        self.m_spNormal:setVisible(false)
        return
    end
end

function DailyMissionThreeLinePassRewardCell:addRewardNode()
    -- self.m_nodeReward:removeAllChildren()
    local oldItemNode = self.m_nodeReward:getChildByName("PassItemRewardNode")
    if self.m_sprHighCoinMul then
        self.m_sprHighCoinMul:setVisible(false)
    end
    local multiple = 1
    local rewards = self.m_pointsInfo:getRewards()
    local itemNode = self.m_nodeReward:getChildByName("PassItemRewardNode")
    if rewards.coins > 0 then
        --当前是金币奖励
        itemNode = gLobalDailyTaskManager:getItemNode(rewards, gLobalDailyTaskManager.ITEM_TYPE.TYPE_COIN, false, false, nil, oldItemNode)
        self.m_labNum:setString("$" .. rewards.p_coinsValue)
        multiple = self:getPayMultiple("coin")
    else
        local items = rewards.items
        if items and #items > 0 then
            multiple = self:getPayMultiple("item", items[1])
            itemNode = gLobalDailyTaskManager:getItemNode(rewards, gLobalDailyTaskManager.ITEM_TYPE.TYPE_ITEM, true, false, multiple, oldItemNode)
            if itemNode == nil then
                local errorMsg = "ERROR" .. ", itemData = " .. cjson.encode(rewards.items[1].p_icon .. " id = " .. rewards.items[1].p_id)
                util_sendToSplunkMsg("NewPassRewardCell", errorMsg)
            end
            if itemNode then
                -- csc 2021-11-28 17:59:04 这里是为了展示在newpass 奖励栏，所以要传入  multiple 去设置特殊道具显示个数
                items[1].forReward = true
                gLobalDailyTaskManager:setItemNodeByExtraData(items[1],itemNode,multiple)
                -- 设置字体
                local cellLabNode = itemNode:getValue()
                if cellLabNode then
                    cellLabNode:setVisible(false)
                    local strNum = cellLabNode:getString()
                    self.m_labNum:setString(strNum)
                end
            end
        end
    end
    if itemNode then
        if self.m_sprHighCoinMul and self:getPayType() > 0 then
            if multiple > 1 then
                if not self.m_lock then -- 特殊锁住的块没有特效
                    self.m_sprHighCoinMul:setVisible(true)
                    self.m_labMulNum:setString("X" .. multiple)
                end
            end
        end
        if not oldItemNode then
            itemNode:setScale(0.9)
            itemNode:setName("PassItemRewardNode")
            self.m_nodeReward:addChild(itemNode)
        end
    end
end


function DailyMissionThreeLinePassRewardCell:getBGEfectPath()
    if self.m_type == "season" then
        return DAILYPASS_RES_PATH.DailyMissionPass_SeasonCellBg_Effect_ThreeLine  
    elseif self.m_type == "premium" then
        return DAILYPASS_RES_PATH.DailyMissionPass_PremiumCellBg_Effect_ThreeLine  
    else
        return DAILYPASS_RES_PATH.DailyMissionPass_FreeCellBg_Effect_ThreeLine  
    end
end

function DailyMissionThreeLinePassRewardCell:addEffectNode()
    -- 移除动效节点
    -- self.m_nodeEffect:removeAllChildren()
    local nodeEfAni = self.m_nodeEffect:getChildByName("PassEffectNode")
    if not nodeEfAni then
        local effect_1_path = self:getBGEfectPath()
        nodeEfAni = util_createAnimation(effect_1_path)
        self.m_nodeEffect:addChild(nodeEfAni)
        nodeEfAni:setName("PassEffectNode")
    end
    if nodeEfAni then
        nodeEfAni:setVisible(false)
    end
    local isCheckPlay = true
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        isCheckPlay = false
    end
    
    if self.m_pointsInfo:getCollected() then -- 如果当前已经领过了， 不播放特效
        isCheckPlay = false
    end

    if self.m_lock then -- 特殊锁住的块没有特效
        isCheckPlay = false
    end

    if isCheckPlay and (self.m_pointsInfo:getLabelColor() == "1") then
        -- local effect_1_path = self:getBGEfectPath()
        -- if nodeEfAni and nodeEfAni:getCsbName() == effect_1_path then
        --     nodeEfAni:setVisible(true)
        -- else
        --     -- 特殊底板 + 转圈动效
        --     self.m_nodeEffect:removeAllChildren()
        --     nodeEfAni = util_createAnimation(effect_1_path)
        --     self.m_nodeEffect:addChild(nodeEfAni)
        --     nodeEfAni:setName("PassEffectNode")
        -- end
        nodeEfAni:setVisible(true)
        nodeEfAni:playAction("idle", true, nil, 60)
    else
        nodeEfAni:pauseForIndex(0)
    end
end

function DailyMissionThreeLinePassRewardCell:runCsbActCheck(_actName, _repeat, _func, _frame)
    self:reloadCsb()
    self:runCsbAction(_actName, _repeat, _func, _frame)
end

function DailyMissionThreeLinePassRewardCell:reloadCsb()
    if self.m_csbAct == nil or tolua.isnull(self.m_csbAct) then
        self.m_csbAct = util_actCreate(self:getCsbName())
        self.m_csbNode:runAction(self.m_csbAct)
    end
end

function DailyMissionThreeLinePassRewardCell:getPayMultiple(_type, _itemData)
    if self:getPayType() > 0 then
        return G_GetMgr(ACTIVITY_REF.NewPass):getRewardCellMultiple(_type, _itemData)
    end
    return 1
end
------------------------------- 外部调用方法 ------------------------
function DailyMissionThreeLinePassRewardCell:getTouchNode()
    return self.m_btnTouch
end

function DailyMissionThreeLinePassRewardCell:clickFunc(_sender)
    -- 只有锁定块能触发这个按钮效果
    local name = _sender:getName()
    if self.m_lock then
        if name == "btn_touch" then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            -- 如果是锁定块 点击要跳转到 pass 页
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_CLICK_CHANGE_PAGE)
        end
    end
end

function DailyMissionThreeLinePassRewardCell:onClick()
    print("----DailyMissionThreeLinePassRewardCell touch level = " .. self.m_pointsInfo:getLevel())
    if self.m_bCanCollect then
        self.m_bCanCollect = false
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_sendCollectMsg = true
        --可以领取
        local type = self:getPayType()
        local isNewUser = gLobalDailyTaskManager:isWillUseNovicePass()
        gLobalDailyTaskManager:sendActionPassRewardCollect(self.m_pointsInfo:getLevel(), type, false, isNewUser,true,true)
    else
        -- 弹出气泡
        -- 显示奖励信息气泡
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalNoticManager:postNotification(
            ViewEventType.NOTIFY_DAILYPASS_SHOW_REWARD_INFO,
            {
                level = self.m_pointsInfo:getLevel(),
                boxType = self.m_type,
                isPreview = self.m_isPreview,
                isPortrait = self.m_isPortrait
            }
        )
    end
end

function DailyMissionThreeLinePassRewardCell:collectUpdate(_param)
    --
    -- if not self.m_sendCollectMsg then
    --     return
    -- end
    if _param.index == self.m_pointsInfo:getLevel() then
        print("----csc 当前等级数据需要刷新！！！DailyMissionThreeLinePassRewardCell " .. _param.index)
        self.m_sendCollectMsg = nil
        local newPassCellData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getPassPointsInfo()
        local pointData = newPassCellData[_param.index + 1]
        local data = pointData.freeInfo
        if self:getPayType() == 1 then
            data =  pointData.payInfo
        elseif(self:getPayType() > 1) then
            data =  pointData.tripleInfo
        end
        self.m_bCanCollect = false
        -- 刷新动画
        self:runCsbActCheck(
            "dagou",
            false,
            function()
                self:updateData(data)
            end,
            60
        )
    end
end

function DailyMissionThreeLinePassRewardCell:collectAllUpdate()
    self.m_sendCollectMsg = nil
    local newPassCellData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getPassPointsInfo()
    local pointData = newPassCellData[self.m_pointsInfo:getLevel() + 1]
    local data = pointData.freeInfo
    if self:getPayType() == 1 then
        data =  pointData.payInfo
    elseif(self:getPayType() > 1) then
        data =  pointData.tripleInfo
    end
    -- 刷新动画
    if self.m_bCanCollect then
        self.m_bCanCollect = false
        self:runCsbActCheck(
            "dagou",
            false,
            function()
                self:updateData(data)
            end,
            60
        )
    else
        self:updateData(data)
    end
end

function DailyMissionThreeLinePassRewardCell:beforeClose()
    self:stopAllActions()
    if self.m_particle_1 then
        self.m_particle_1:setVisible(false)
    end
    if self.m_nodeEffect then
        self.m_nodeEffect:setVisible(false)
        self.m_nodeEffect:removeAllChildren()
    end
end

-- 展示解锁动画
function DailyMissionThreeLinePassRewardCell:showUnlockAction()
    if self.m_bUnlocked then
        return
    end
    -- 更新一下数据
    local newPassData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not newPassData then
        return
    end
    local newPassCellData = newPassData:getPassPointsInfo()
    local pointData = newPassCellData[self.m_pointsInfo:getLevel() + 1]

    local data = pointData.freeInfo
    if self:getPayType() == 1 then
        data =  pointData.payInfo
    elseif(self:getPayType() > 1) then
        data =  pointData.tripleInfo
    end
    self.m_pointsInfo = data

    if self:getPayType() > 0 then
        self:runCsbActCheck(
            "open",
            false,
            function()
                if self.m_bCanCollect then
                    self:runCsbActCheck(
                        "claim",
                        false,
                        function()
                            self:updateStatus()
                            -- 刷新奖励
                            self:addRewardNode()
                        end,
                        60
                    )
                else
                    self:updateStatus()
                    -- 刷新奖励
                    self:addRewardNode()
                end
            end,
            60
        )
    end
end

function DailyMissionThreeLinePassRewardCell:isCellByLevel(_level)
    if _level == self.m_pointsInfo:getLevel() then
        return true
    end
    return false
end

function DailyMissionThreeLinePassRewardCell:updateClaimStatus()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData then
        self.m_isIncrease = false
        if self:getPayType() > 0 then
            -- 付费的话需要判断当前有没有解锁
            if (actData:isUnlocked() and self:getPayType() == 1) or (actData:getCurrIsPayHigh() and self:getPayType() == 4) then
                self:runCsbActCheck(
                    "claim",
                    false,
                    function()
                        self:updateStatus()
                        self:addEffectNode()
                    end,
                    60
                )
            end
        else
            self:runCsbActCheck(
                "claim",
                false,
                function()
                    self:updateStatus()
                    self:addEffectNode()
                end,
                60
            )
        end
    end
end

return DailyMissionThreeLinePassRewardCell
