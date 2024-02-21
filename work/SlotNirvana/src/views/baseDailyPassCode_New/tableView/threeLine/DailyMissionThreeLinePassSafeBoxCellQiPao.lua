--[[
    --新版每日任务pass主界面 标题
    csc 2021-06-21
]]
local DailyMissionThreeLinePassSafeBoxCellQiPao = class("DailyMissionThreeLinePassSafeBoxCellQiPao", BaseView)

function DailyMissionThreeLinePassSafeBoxCellQiPao:initDatas(_isGuide,isPortraitWindow)
    self.m_isGuide = _isGuide
    self.m_isPortraitWindow = isPortraitWindow
end

function DailyMissionThreeLinePassSafeBoxCellQiPao:initCsbNodes()
    self.m_nodeRewards = {}
    self.m_sp_qipao1 = self:findChild("sp_qipao1")
    if self.m_isPortraitWindow then
        self.m_sp_qipao1:setPositionX(100)
    else
        self.m_sp_qipao1:setPositionX(-100)
    end
    for i = 1, 3 do
        local nodeReward = self:findChild("node_reward" .. i)
        table.insert(self.m_nodeRewards, nodeReward)
    end
end

function DailyMissionThreeLinePassSafeBoxCellQiPao:getCsbName()
    return DAILYPASS_RES_PATH.DailyMissionPass_PassSafeBoxCellQiPao_ThreeLine  
end

function DailyMissionThreeLinePassSafeBoxCellQiPao:initUI()
    DailyMissionThreeLinePassSafeBoxCellQiPao.super.initUI(self)
end

function DailyMissionThreeLinePassSafeBoxCellQiPao:playStart(_over)
    self:runCsbAction("start", false, _over, 60)
end

function DailyMissionThreeLinePassSafeBoxCellQiPao:playIdle()
    self:runCsbAction("idle", false, nil, 60)
end

function DailyMissionThreeLinePassSafeBoxCellQiPao:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

function DailyMissionThreeLinePassSafeBoxCellQiPao:showView(_rewardData)
    if not gLobalDailyTaskManager:isWillUseNovicePass() then
        self:initRewards(_rewardData)
        self:playStart(
            function()
                if not tolua.isnull(self) then
                    self:playIdle()
                end
            end
        )
    end
    -- if not self.m_isGuide then
    -- end
    performWithDelay(
        self,
        function()
            if not tolua.isnull(self) then
                if self.m_isGuide and gLobalDailyTaskManager:getSafeBoxGuideId() == 0 then
                    gLobalNoticManager:postNotification(ViewEventType.EVENT_PASS_SAFTBOX_NEXT_GUIDE, {guideId = 1})
                else
                    self:closeUI()
                end
            end
        end,
        3
    )
    self:addTouchLayer()
end

-- 创建奖励道具
function DailyMissionThreeLinePassSafeBoxCellQiPao:initRewards(_rewardData)
    if not _rewardData then
        return
    end
    local iconNames = _rewardData:getIcons()
    if iconNames and #iconNames > 0 then
        for i = 1, #self.m_nodeRewards do
            local iconName = iconNames[i]
            if iconName then
                local itemData = gLobalItemManager:createLocalItemData(iconName, 1)
                itemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
                local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD)
                if itemNode then
                    self.m_nodeRewards[i]:addChild(itemNode)
                    itemNode:setScale(0.4)
                end
            end
        end
    end
end

function DailyMissionThreeLinePassSafeBoxCellQiPao:closeUI()
    if self.m_close then
        return
    end
    self.m_close = true
    self:playOver(
        function()
            if not tolua.isnull(self) then
                self:removeFromParent()
            end
        end
    )
end

function DailyMissionThreeLinePassSafeBoxCellQiPao:addTouchLayer()
    local mask = util_newMaskLayer()
    mask:setOpacity(0)
    -- mask:setSwallowTouches(false)
    local isTouch = false
    mask:onTouch(
        function(event)
            if not isTouch then
                return true
            end
            if event.name == "ended" then
                if self.m_isGuide and gLobalDailyTaskManager:getSafeBoxGuideId() == 0 then
                    gLobalNoticManager:postNotification(ViewEventType.EVENT_PASS_SAFTBOX_NEXT_GUIDE, {guideId = 1})
                else
                    self:closeUI()
                end
            end
            return true
        end,
        false,
        true
    )
    performWithDelay(
        self,
        function()
            isTouch = true
        end,
        0.5
    )
    self:addChild(mask)
end

return DailyMissionThreeLinePassSafeBoxCellQiPao
