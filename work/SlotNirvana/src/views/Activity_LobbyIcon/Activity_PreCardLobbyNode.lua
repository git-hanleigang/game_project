-- Created by jfwang on 2019-05-21.
-- 大厅入口
--
local Activity_PreCardLobbyNode = class("Activity_PreCardLobbyNode", util_require("base.BaseView"))

function Activity_PreCardLobbyNode:initUI(data)
    self:createCsbNode("Activity/CardsNode.csb")
    self.m_curActivityId = ""
    if data and data.activityId then
        self.m_curActivityId = data.activityId
    end
    self:initView()
    --升级消息
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateView()
        end,
        ViewEventType.SHOW_LEVEL_UP
    )
end

function Activity_PreCardLobbyNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
    if self.m_schduleCheckActivityLobbyID ~= nil then
        scheduler.unscheduleGlobal(self.m_schduleCheckActivityLobbyID)
        self.m_schduleCheckActivityLobbyID = nil
    end
end

function Activity_PreCardLobbyNode:initView()
end

--点击了活动node
function Activity_PreCardLobbyNode:clickLobbyNode()
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyPreCardIcon")
    local uiView = util_createView("Activity.Activity_PreCard")
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "btn_cards", DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
    end
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    self:openLayerSuccess()
end

function Activity_PreCardLobbyNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_cards" then
        self:clickLobbyNode()
    end
end

return Activity_PreCardLobbyNode
