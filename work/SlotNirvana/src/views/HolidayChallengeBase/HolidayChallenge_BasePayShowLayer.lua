--[[
    独立日新版聚合挑战 规则弹板
    author:csc
    time:2021-05-31
]]
local HolidayChallenge_BasePayShowLayer = class("HolidayChallenge_BasePayShowLayer", BaseLayer)

function HolidayChallenge_BasePayShowLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.UNLOCKPAYShow_LAYER)
    self:setExtendData("HolidayChallengePayShowLayer")
end

function HolidayChallenge_BasePayShowLayer:initCsbNodes()
    -- 界面上的奖励点
    self.m_nodeRewardItem = {}
    self.m_nodeRewardStarNum = {}
    for i = 1,5 do
        local node = self:findChild("node_reward"..i)
        table.insert(self.m_nodeRewardItem,node)

        local labStar = self:findChild("lb_num"..i)
        table.insert(self.m_nodeRewardStarNum,labStar)
    end

    self:startButtonAnimation("btn_go", "sweep", true) 
end

function HolidayChallenge_BasePayShowLayer:initView()
    local data = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    if data then

        for i = 1 ,5 do
            --加载购买可解锁的道具
            local nodeItem = self.m_nodeRewardItem[i]
            local payRewardData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getPayRewardDataByIndex(i)
            local itemNode = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getItemNode(payRewardData,ITEM_SIZE_TYPE.REWARD,true,true)
            if itemNode then
                nodeItem:addChild(itemNode)
            end
            --加载可获得奖励的数量
            local nodeLab = self.m_nodeRewardStarNum[i]
            nodeLab:setString(payRewardData:getPoints())
        end
    end   
end

-- 重写父类方法 
function HolidayChallenge_BasePayShowLayer:onShowedCallFunc()
    -- 展开动画
    self:runCsbAction("idle", true, nil, 60)
end

-- 重写父类方法 
function HolidayChallenge_BasePayShowLayer:onEnter()
    HolidayChallenge_BasePayShowLayer.super.onEnter(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.HolidayChallenge then
                self:removeFromParent()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function HolidayChallenge_BasePayShowLayer:onExit()
    HolidayChallenge_BasePayShowLayer.super.onExit(self)
end

function HolidayChallenge_BasePayShowLayer:clickFunc(sender)
    if self.m_isIncAction then
        return
    end
    self.m_isIncAction = true

    local name = sender:getName()
    if name == "btn_close" or name == "btn_go"  then
        self:closeUI()
    end
end

return HolidayChallenge_BasePayShowLayer
