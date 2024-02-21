--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-04-04 11:46:26
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-04-04 11:46:36
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/ExpandTaskBaseUI.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local ExpandTaskBaseUI = class("ExpandTaskBaseUI", BaseView)

-- 任务背景
function ExpandTaskBaseUI:updateSpBgUI()
end

-- 任务Lb
function ExpandTaskBaseUI:initLbTaskUI()
end

-- 更新任务状态
function ExpandTaskBaseUI:updateTaskState(_state)
end

-- 点击去玩游戏
function ExpandTaskBaseUI:gotoGame()
end

function ExpandTaskBaseUI:updateVisible()
    self:setVisible(false)
end

return ExpandTaskBaseUI