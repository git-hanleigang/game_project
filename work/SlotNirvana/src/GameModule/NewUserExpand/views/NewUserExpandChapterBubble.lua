--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-07 17:00:17
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-07 17:01:26
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/NewUserExpandChapterBubble.lua
Description: 扩圈系统 任务章节 解锁气泡
--]]
local NewUserExpandChapterBubble = class("NewUserExpandChapterBubble", BaseView)

function NewUserExpandChapterBubble:initDatas(_desc)
    NewUserExpandChapterBubble.super.initDatas(self)

    self.m_desc = _desc
end

function NewUserExpandChapterBubble:getCsbName()
    return "NewUser_Expend/Activity/csd/NewUser_StopCell_Bubble.csb"
end

function NewUserExpandChapterBubble:initUI()
    NewUserExpandChapterBubble.super.initUI(self)

    -- 初始化气泡 描述
    self:initBubbleDescUI()
    self:setVisible(false)
end

-- 初始化气泡 描述
function NewUserExpandChapterBubble:initBubbleDescUI()
    local lbDesc = self:findChild("lb_mission")
    lbDesc:setString(self.m_desc)
    util_AutoLine(lbDesc, self.m_desc, 155, true)
end

function NewUserExpandChapterBubble:switchBubbleVisible()
    local bVisible = self:isVisible()
    self:stopAllActions()

    local actName = "close"
    local cb
    if not bVisible then
        self:setVisible(true)
        actName = "open"
        cb = function()
            performWithDelay(self, function(  )
                self:switchBubbleVisible()
            end, 3)
            self:runCsbAction("idle")
        end
    else
        cb = function()
            self:setVisible(false)
        end
    end
    self:runCsbAction(actName, false, cb, 60) 
end

-- 强制 显示气泡
function NewUserExpandChapterBubble:showBubbleVisible()
    self:stopAllActions()

    self:setVisible(true)
    self:runCsbAction("idle")
end

return NewUserExpandChapterBubble