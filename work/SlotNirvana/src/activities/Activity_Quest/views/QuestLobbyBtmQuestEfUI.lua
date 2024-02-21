--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-15 14:11:06
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-15 14:11:40
FilePath: /SlotNirvana/src/activities/Activity_Quest/views/QuestLobbyBtmQuestEfUI.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local QuestLobbyBtmQuestEfUI = class("QuestLobbyBtmQuestEfUI", BaseView)

function QuestLobbyBtmQuestEfUI:getCsbName()
    return "Activity_LobbyIconRes/Activity_QuestRefresh.csb"
end

function QuestLobbyBtmQuestEfUI:initUI()
    QuestLobbyBtmQuestEfUI.super.initUI(self)

    -- 普通quest node
    self:initQuestNormalUI()
end

-- 普通quest node
function QuestLobbyBtmQuestEfUI:initQuestNormalUI()
    local view = util_createView("views.Activity_LobbyIcon.Activity_QuestLobbyNode")
    local parent = self:findChild("node_quest")
    parent:addChild(view)
end

function QuestLobbyBtmQuestEfUI:playUnlock(_cb)
    _cb =  _cb or function()    end
    self:runCsbAction("start", false, function()
        _cb()
        self:runCsbAction("show")
    end, 60)
end

return QuestLobbyBtmQuestEfUI