--[[
    引导界面
    author:{author}
    time:2021-11-10 17:55:23
]]
local HolidayChallenge_BaseGuideLayer = class("HolidayChallenge_BaseGuideLayer", BaseLayer)

function HolidayChallenge_BaseGuideLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.GUIDE_LAYER)
    if not self.m_activityConfig.ROAD_CONFIG.NO_IGNORE_AUTO_SCALE then
        self:setIgnoreAutoScale(true )
    end
end

function HolidayChallenge_BaseGuideLayer:initCsbNodes()
    for i = 1, 4 do
        local nodeGuide = self:findChild("node_guide_" .. i)
        if nodeGuide then
            nodeGuide:setVisible(false)
        end
    end
end

function HolidayChallenge_BaseGuideLayer:initView()
    self:updateView(1)
    -- 添加mask
    self:addMask()
end

-- function HolidayChallenge_BaseGuideLayer:onEnter()
--     -- 活动到期
--     -- gLobalNoticManager:addObserver(
--     --     self,
--     --     function(sender, params)
--     --         if params.name == ACTIVITY_REF.HolidayChallenge then
--     --             self:removeFromParent()
--     --         end
--     --     end,
--     --     ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
--     -- )
-- end

function HolidayChallenge_BaseGuideLayer:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function HolidayChallenge_BaseGuideLayer:updateView(_step)
    for i = 1, 4 do
        local nodeGuide = self:findChild("node_guide_" .. i)
        if nodeGuide then
            if i == _step then
                nodeGuide:setVisible(true)
            else
                nodeGuide:setVisible(false)
            end  
        end
    end
end

function HolidayChallenge_BaseGuideLayer:hideAllGuideNode()
    self:updateView(0)
end

function HolidayChallenge_BaseGuideLayer:addMask()
    self.m_mask = util_newMaskLayer()
    self.m_mask:setOpacity(128)
    local isTouch = false
    self.m_mask:onTouch(
        function(event)
            if not isTouch then
                return true
            end
            if event.name == "ended" then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_GUIDE_NEXT_STEP)
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
    self:findChild("node_mask"):addChild(self.m_mask)
end

function HolidayChallenge_BaseGuideLayer:setMaskVisible(_flag)
    self:findChild("node_mask"):setVisible(_flag)
    self.m_mask:setTouchEnabled(_flag)
end
return HolidayChallenge_BaseGuideLayer
