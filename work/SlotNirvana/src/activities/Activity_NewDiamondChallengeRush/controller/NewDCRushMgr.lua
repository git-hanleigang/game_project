
local NewDCRushMgr = class("NewDCRushMgr", BaseActivityControl)
local NewDChallengeNet = require("activities.Activity_NewDiamondChallenge.net.NewDChallengeNet")

function NewDCRushMgr:ctor()
    NewDCRushMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewDCRush)
    self.m_Net = NewDChallengeNet:getInstance()
end

function NewDCRushMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. hallName .."HallNode"
end

function NewDCRushMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. slideName .."SlideNode"
end

function NewDCRushMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

-- function NewDCRushMgr:showPopLayer(popInfo, callback)
--     if not self:isCanShowPop() then
--         return nil
--     end

--     if popInfo and popInfo.clickFlag then
--         local view = util_createView("Activity_NewDChallenge.DCRush.DCRushLayer")
--         if view then
--             self:showLayer(view, ViewZorder.ZORDER_UI)
--         end
--         return view
--     end
--     return nil
-- end

function NewDCRushMgr:showRushLayer()
    local themeName = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getThemeName()
    if not self:isDownloadRes(themeName) then
        return
    end
    if self:getLayerByName("DCRushLayer") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.DCRush.DCRushLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function NewDCRushMgr:showRuleLayer()
    local themeName = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getThemeName()
    if not self:isDownloadRes(themeName) then
        return
    end
    if self:getLayerByName("DCRushRule") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.DCRush.DCRushRule")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--刷新任务
function NewDCRushMgr:sendRushRewardReq(_nIndex,_item)
    local successFunc = function(_netData)
        local callback = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_RED)
        end
        local params = {}
        params.index = _nIndex
        params.data = _item
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_RUSH_COLLECT,params)
        G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):showTaskRewardLayer(_item,callback,2)
    end
    local fileFunc = function()
        -- body
    end
    self.m_Net:sendRushRewardReq(_nIndex,successFunc,fileFunc)
end

function NewDCRushMgr:getRushUnReward()
    local data = self:getRunningData()
    local num = 0
    if data and #data:getItems() > 0 then
        for i,v in ipairs(data:getItems()) do
            if v:getStatus() == "COLLECT" and not v:getCollected() then
                num = num + 1
            end
        end
    end
    return num
end

return NewDCRushMgr
