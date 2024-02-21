
local HolidayChallenge_BaseMap_DoubleRewardNode = class("HolidayChallenge_BaseMap_DoubleRewardNode",BaseView)

function HolidayChallenge_BaseMap_DoubleRewardNode:initUI(_data)

    self.m_type = _data.type
    self.m_index = _data.index
    HolidayChallenge_BaseMap_DoubleRewardNode.super.initUI(self) 
    self:initView()
end

function HolidayChallenge_BaseMap_DoubleRewardNode:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self.m_activityRunData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    self.m_hasDouble = false
    local saleData = self.m_activityRunData:getHighPriceSaleData()
    if saleData then
        if saleData:getPay() then
            self.m_hasDouble = true
        end
    end
end

function HolidayChallenge_BaseMap_DoubleRewardNode:getCsbName()
    return self.m_activityConfig.RESPATH.MAP_DOUBLEREWARD_NODE
end

function HolidayChallenge_BaseMap_DoubleRewardNode:initCsbNodes()
    self.m_nodeReward  = self:findChild("node_RewardBoard")
end

function HolidayChallenge_BaseMap_DoubleRewardNode:initView()
    self.m_nodeReward  = self:findChild("node_RewardBoard")
    local payBoardPath =  "views.HolidayChallengeBase.HolidayChallenge_BaseRewardBoard"
    if self.m_activityConfig and self.m_activityConfig.CODE_PATH.REWARD_BOARD then
        payBoardPath = self.m_activityConfig.CODE_PATH.REWARD_BOARD
    end
    self.m_boardNode = util_createView(payBoardPath,{type = self.m_type, index = self.m_index})
    self.m_nodeReward:addChild(self.m_boardNode)

    if self.m_hasDouble then
        self:runCsbAction("end", false)
    else
        self:runCsbAction("begin", false)
    end
end

-- 车到达可领奖的点时播放的动画
function HolidayChallenge_BaseMap_DoubleRewardNode:playArriveCollectAction()
    self.m_boardNode:playArriveCollectAction()
end

function HolidayChallenge_BaseMap_DoubleRewardNode:playDoubleRewardAction()
    self.m_hasDouble = true
    if self.m_hasDouble then
        self:runCsbAction("start", false,function() 
            self:runCsbAction("end", false)
        end)
    end
end

function HolidayChallenge_BaseMap_DoubleRewardNode:onEnter( )
    --监听购买
    gLobalNoticManager:addObserver(
        self,
        function(sender,param)
            self:playDoubleRewardAction()
        end,
        ViewEventType.NOTIFY_HOLIDAYCHALLENGE_BUY_DOUBLE_REWARD
    )
end

return HolidayChallenge_BaseMap_DoubleRewardNode