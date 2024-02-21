--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-22 14:31:19
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-22 14:31:31
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/NewUserExpandGuideView.lua
Description: 扩圈系统 引导面板
--]]
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local NewUserExpandGuideView = class("NewUserExpandGuideView", BaseView)

function NewUserExpandGuideView:initDatas(_tipId)
    NewUserExpandGuideView.super.initDatas(self)

    -- 引导id
    self.m_tipId = _tipId
end

function NewUserExpandGuideView:getCsbName()
    if self.m_tipId == "t003" or self.m_tipId == "t004" or self.m_tipId == "t005" then
        -- 引导 关卡1 关卡2 引导 关卡3
        return "NewUser_Expend/Activity/csd/Guide/NewUser_Guide_2.csb"
    elseif self.m_tipId == "t006" then
        -- 引导 障碍物 -- 解锁规则
        return "NewUser_Expend/Activity/csd/Guide/NewUser_Guide_3.csb"
    elseif self.m_tipId == "t008" then
        -- 引导 大厅 进入slot
        return "NewUser_Expend/Activity/csd/Guide/NewUser_Guide_4.csb"
    end
end

function NewUserExpandGuideView:initUI()
    NewUserExpandGuideView.super.initUI(self)

    if self.m_tipId == "t003" or self.m_tipId == "t004" or self.m_tipId == "t005" then
        self:updateLbUI()
    end
end

function NewUserExpandGuideView:updateLbUI()
    local lb = self:findChild("lb_bubble")
    local str = "Tap Game 1"
    if self.m_tipId == "t004" then
        str = "Tap Game 2"
    elseif self.m_tipId == "t005" then
        str = "Tap Game 3"
    end
    lb:setString(str)
    util_AutoLine(lb, str, 200, true)
end

function NewUserExpandGuideView:onExit()
    NewUserExpandGuideView.super.onExit(self)
    
    if self.m_tipId == "t006" then
        performWithDelay(display.getRunningScene(), function()
            gLobalNoticManager:postNotification(NewUserExpandConfig.EVENT_NAME.NOTIFY_CHECK_GUIDE_EXPAND_ENTRY)
        end, 0.2)
    end
    gLobalNoticManager:postNotification(NewUserExpandConfig.EVENT_NAME.NOTIFY_RESET_GUIDE_TASK_VIEW_SWALLOW, self.m_tipId == "t008")
end

return NewUserExpandGuideView