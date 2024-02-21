--每日任务气泡
local GuideNewDailyMission = class("GuideNewDailyMission", util_require("base.BaseView"))
function GuideNewDailyMission:initUI()
    self:createCsbNode("GuideNewUser/NewUserDailyMissionNode.csb")
    local node_w = self:findChild("node_w")
    local node_h = self:findChild("node_h")
    self.m_isPortrait = globalData.slotRunData.isPortrait
    if self.m_isPortrait then
        -- if node_w then
        --     node_w:setVisible(false)
        -- end
        self:setScale(0.7)
    else
        -- if node_h then
        --     node_h:setVisible(false)
        -- end
    end
    if node_h then
        node_h:setVisible(false)
    end
    self:show()
end

function GuideNewDailyMission:show()
    self:runCsbAction("show")
    performWithDelay(
        self,
        function()
            if self.hide then
                self:hide()
            end
        end,
        6
    )
end
function GuideNewDailyMission:hide(func)
    if self.m_isHide then
        if func then
            func()
        end
        return
    end
    self.m_isHide = true
    self:runCsbAction(
        "over",
        false,
        function()
            self:removeFromParent()
            if func then
                func()
            end
        end
    )
end
return GuideNewDailyMission
