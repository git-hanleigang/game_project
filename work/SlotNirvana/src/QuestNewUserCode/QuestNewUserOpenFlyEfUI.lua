--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-13 17:53:26
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-13 17:53:39
FilePath: /SlotNirvana/src/QuestNewUserCode/QuestNewUserOpenFlyEfUI.lua
Description: 新手任务完成 fly 特效
--]]
local QuestNewUserOpenFlyEfUI = class("QuestNewUserOpenFlyEfUI", BaseView)

function QuestNewUserOpenFlyEfUI:getCsbName()
    return "QuestNewUser/Activity/csd/Novice_task_quest_open_pop_fly_ef.csb"
end

function QuestNewUserOpenFlyEfUI:initCsbNodes()
    QuestNewUserOpenFlyEfUI.super.initCsbNodes(self)

    self._particleTuowei = self:findChild("ef_tuowei")
    self._particleTuowei2 = self:findChild("ef_tuowei2")
    self._particleTuowei:setPositionType(0)
    self._particleTuowei2:setPositionType(0)
    self._particleOnce = self:findChild("ef_once")
end

function QuestNewUserOpenFlyEfUI:playFlyAct(_cb)
    self:move(cc.p(0, 0))

    self._particleTuowei:setVisible(false)
    self._particleTuowei2:setVisible(false)
    self:runCsbAction("show", false, function()
        self._particleTuowei:setVisible(true)
        self._particleTuowei2:setVisible(true)
        self._particleOnce:setVisible(false)

        local posW = self:getParent():convertToNodeSpace(display.center)
        local bezier = {}
        bezier[1] = cc.p(0, 0)
        bezier[2] = cc.p(0 + 200, posW.y + 200)
        bezier[3] = posW
        local moveAct =  cc.EaseSineIn:create( cc.BezierTo:create(1, bezier) )
        local endCb = cc.CallFunc:create(function()

            self._particleTuowei:setVisible(false)
            self._particleTuowei2:setVisible(false)
            self._particleOnce:setVisible(true)
            self._particleOnce:start()

            _cb()
        end)

        self:runAction(cc.Sequence:create(moveAct, endCb))
    end, 60)
end

return QuestNewUserOpenFlyEfUI