--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:29:43
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/tournament/TrillionChallengeFlyBox.lua
Description: 亿万赢钱挑战 任务领奖  flyBox
--]]
local TrillionChallengeFlyBox = class("TrillionChallengeFlyBox", BaseView)

function TrillionChallengeFlyBox:initDatas(_idx, _flyPosW)
    TrillionChallengeFlyBox.super.initDatas(self)

    self._idx = _idx
    self._flyPosWStart = _flyPosW
end

function TrillionChallengeFlyBox:getCsbName()
    return "Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_Main_box_jiangli.csb"
end

function TrillionChallengeFlyBox:initUI() 
    TrillionChallengeFlyBox.super.initUI(self)

    local idx = self._idx
    local size = cc.size(100, 100)
    for i=1, 5 do
        local sp = self:findChild("sp_box_" .. i)
        if i == idx then
            size = sp:getContentSize()
        end
        sp:setVisible(i == idx)
    end
    self:setContentSize(size)
    self:setVisible(false)
end

function TrillionChallengeFlyBox:playFlyAction(_flyLayer, _cb)
    local endPosL = cc.p(self:getPosition())
    local startPosL = cc.p(self:getParent():convertToNodeSpaceAR(self._flyPosWStart or display.center))

    self:move(startPosL)
    self:setVisible(true)

    local bezier = {}
    bezier[1] = startPosL
    bezier[2] = cc.pAdd(startPosL, cc.p((endPosL.x - startPosL.x) * 0.5, 200))
    bezier[3] = endPosL
    local time = 33 / 60
    local moveAct = cc.EaseSineIn:create( cc.BezierTo:create(time, bezier) )
    local flyAct = cc.CallFunc:create(function()
        self:runCsbAction("fly")
    end)
    local spawn = cc.Spawn:create(moveAct, flyAct)
    local openAct = cc.CallFunc:create(function()
        self:runCsbAction("open", false, function()
            if tolua.isnull(_flyLayer) then
                return
            end

            _flyLayer:closeUI()
        end, 60)
    end)
    local delayTime = cc.DelayTime:create((65 - 33)/60)
    local openRewardAct = cc.CallFunc:create(_cb)
    local actList = {
        spawn,
        openAct,
        delayTime,
        openRewardAct
    }
    self:runAction(cc.Sequence:create(actList))
end

return TrillionChallengeFlyBox