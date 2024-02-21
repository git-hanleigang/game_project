
local BaseView = require("base.BaseView")
local HolidayChallenge_BaseRewardBoard = class("HolidayChallenge_BaseRewardBoard", BaseView)

function HolidayChallenge_BaseRewardBoard:initUI(_data)

    self.m_type = _data.type
    self.m_index = _data.index

    self.m_bCanCollect = false
    self.m_bUnlocked  = true

    self.m_bSendCollect = false
    self.m_bClick = true -- 是否能点击
    
    HolidayChallenge_BaseRewardBoard.super.initUI(self) 
    self:initView()
end
function HolidayChallenge_BaseRewardBoard:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
end

function HolidayChallenge_BaseRewardBoard:getCsbName()
    if self:isPayType() then
        return self.m_activityConfig.RESPATH.REWARDBOARD_PAY_NODE 
    else
        return self.m_activityConfig.RESPATH.REWARDBOARD_FREE_NODE
    end
    return self.m_activityConfig.RESPATH.REWARDBOARD_FREE_NODE
end

function HolidayChallenge_BaseRewardBoard:initCsbNodes()
    self.m_nodeReward  = self:findChild("node_reward")

    self.m_touchPanel = self:findChild("touch_panel")
    self.m_nodeQipao = self:findChild("node_qipao")
    self:addClick(self.m_touchPanel)
end

function HolidayChallenge_BaseRewardBoard:isPayType( )
    if self.m_type == "pay" then
        return true
    elseif self.m_type == "free" then
        return false
    end
end

function HolidayChallenge_BaseRewardBoard:initView()
    local isOpen = G_GetMgr(ACTIVITY_REF.HolidayChallenge):isCanShowLayer()
    if isOpen then
        self:updateData()
        -- 展示道具
        local itemNode = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getItemNode(self.m_rewardData,ITEM_SIZE_TYPE.REWARD,true,true)
        if itemNode then
            self.m_nodeReward:addChild(itemNode)
        end
        -- 刷新状态
        self:updateLockStatus()
    end
end

--[[
    @desc:更新状态
]]
function HolidayChallenge_BaseRewardBoard:updateLockStatus()
    local actData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    if actData then
        local actName = "idle"
        local bRepeat = false
        if actData:getCurrentPoints() >= self.m_rewardData:getPoints() then
            self.m_bCanCollect = true
        end
        
        if self.m_bCanCollect then
            if not self.m_rewardData:getCollected() then 
                actName = "idle1" --如果还没有领取
                bRepeat = true
            else
                actName = "idle2" --已经领取过了
                self.m_bCanCollect = false
            end
        else
            -- 未到达进度的时候
            actName = "idle"
        end

        if self:isPayType() then -- 付费需要额外判断一次是否解锁
            if actData:getUnlocked() == false then 
                actName = "lock"
                self.m_bUnlocked = false
            else
                self.m_bUnlocked = true -- 已经解锁
                bRepeat = true
            end
        end
        -- end
        self:runCsbAction(actName, bRepeat, nil,60) -- 
    end
end

function HolidayChallenge_BaseRewardBoard:updateData( )
    if self:isPayType() then
        self.m_rewardData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getPayRewardDataByIndex(self.m_index)
    else
        self.m_rewardData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRewardDataByIndex(self.m_index)
    end
end

function HolidayChallenge_BaseRewardBoard:clickFunc(sender)
    if self.m_btnTouch  or not self.m_bClick then
        return
    end
    local name = sender:getName()

    if name == "touch_panel" then
        -- 额外动画
        if self:isPayType() then
            if self.m_bUnlocked == false then  --没解锁的话需要播放没解锁的动画
                self.m_btnTouch = true
                -- 弹出付费弹板
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):createPayLayer()
                self.m_btnTouch = false
                return
            end 
        end

        if not self.m_bCanCollect then
            -- 展示气泡
            return 
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_btnTouch = true
        -- 发送服务器消息收集奖励
        self.m_bSendCollect = true
        local points = self.m_rewardData:getPoints()
        local phase = self.m_rewardData:getPhase()
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):sendCollectReq(phase,points,self.m_type)
        print("------- 发送服务器消息收集奖励")
    end
end

function HolidayChallenge_BaseRewardBoard:playCollectAction(_rewardItems)
    self:runCsbAction("actionframe", false, function (  )
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):openCollectRewardLayer(_rewardItems)
        self:runCsbAction("idle2", false, nil,60)
    end,60)
end

-- 车到达可领奖的点时播放的动画
function HolidayChallenge_BaseRewardBoard:playArriveCollectAction()
    -- 需要判断解锁状态
    if self:isPayType() then -- 付费需要额外判断一次是否解锁
        if self.m_bUnlocked then --解锁的状态下可以播放
            gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.BOARD_COLLECTSHOW_MP3)
            self:runCsbAction("collect_show", false, function(  )
                self:updateLockStatus()
            end , 60 )
        else
            --如果当前没解锁，需要播放一个锁摆动的动画
            self:updateLockStatus()
        end
    else
        -- 免费的奖励直接播放
        gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.BOARD_COLLECTSHOW_MP3)
        self:runCsbAction("collect_show", false, function(  )
            self:updateLockStatus()
        end , 60 )
    end

end

function HolidayChallenge_BaseRewardBoard:onEnter( )
    -- 监听领奖结果
    gLobalNoticManager:addObserver(
        self,
        function(sender,param)
            if self.m_bSendCollect then
                if param.isSuccess == false then --领取失败了的话,可以重新领取
                    self.m_btnTouch = false 
                else
                    self:updateData()
                    self:playCollectAction(param.rewardItems) -- 领取成功播放动画
                end
                self.m_bSendCollect = false
            end
        end,
        ViewEventType.NOTIFY_HOLIDAYCHALLENGE_COLLECT_REWARD
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:removeBoxRewardInfo(params)
        end,
        ViewEventType.NOTIFY_HOLIDAYCHALLENGE_REMOVE_QIPAO
    )
    --监听购买
    gLobalNoticManager:addObserver(
        self,
        function(sender,param)
            self:updateData()
            self:updateLockStatus() -- 领取成功之后刷新状态
        end,
        ViewEventType.NOTIFY_HOLIDAYCHALLENGE_BUYSUCCESS
    )

    gLobalNoticManager:addObserver(self,
    function(target, params)
        self.m_bClick = params.flag
    end,ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE)
end

return HolidayChallenge_BaseRewardBoard
