--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-13 14:49:50
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-13 15:02:26
FilePath: /SlotNirvana/src/QuestNewUserCode/QuestNewUserOpenEfUI.lua
Description: 新手quest 宣传弹板 光圈特效
--]]
local QuestNewUserOpenEfUI = class("QuestNewUserOpenEfUI", BaseView)

function QuestNewUserOpenEfUI:getCsbName()
    return "QuestNewUser/Activity/csd/NewUser_QuestLayer_popview_ef.csb"
end

function QuestNewUserOpenEfUI:initCsbNodes()
    QuestNewUserOpenEfUI.super.initCsbNodes(self)

    self._particleOnce = self:findChild("ef_once")
end

function QuestNewUserOpenEfUI:playShowAct()
    self._particleOnce:start()
    self:runCsbAction("show", false, function()
        self:removeSelf()
    end, 60)

end

return QuestNewUserOpenEfUI