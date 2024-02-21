--[[
    引导界面
    author:{author}
    time:2021-11-10 17:55:23
]]
local QuestNewChapterChoseGuideView = class("QuestNewChapterChoseGuideView", BaseLayer)

function QuestNewChapterChoseGuideView:initDatas(callback)
    self.m_callback = callback
    self:setLandscapeCsbName(QUESTNEW_RES_PATH.QuestNewChapterChoseGuideView)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setIgnoreAutoScale(true)
end

function QuestNewChapterChoseGuideView:initCsbNodes()
    
end

function QuestNewChapterChoseGuideView:initView()
    self:updateView(1)
    -- 添加mask
    self:addMask()
end

function QuestNewChapterChoseGuideView:onEnter()
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.QuestNew then
                self:removeFromParent()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
    self:runCsbAction("start", false,function ()
        self:runCsbAction("idle",true)
    end)
end

function QuestNewChapterChoseGuideView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function QuestNewChapterChoseGuideView:updateView(_step)

end

function QuestNewChapterChoseGuideView:hideAllGuideNode()
    self:updateView(0)
end

function QuestNewChapterChoseGuideView:addMask()
    self.m_mask = util_newMaskLayer()
    self.m_mask:setOpacity(185)
    local isTouch = false
    self.m_mask:onTouch(
        function(event)
            if not isTouch then
                return true
            end
            if event.name == "ended" then
                if self.m_callback then
                    self.m_callback()
                end
                self:removeFromParent()
                G_GetMgr(ACTIVITY_REF.QuestNew):saveGuideOver()
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


return QuestNewChapterChoseGuideView
