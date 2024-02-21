--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:29:58
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/tournament/TrillionChallengeFlyLayer.lua
Description: 亿万赢钱挑战 任务领奖 时 Layer
--]]
local TrillionChallengeFlyLayer = class("TrillionChallengeFlyLayer", BaseLayer)

function TrillionChallengeFlyLayer:initDatas(_canColIdxList)
    TrillionChallengeFlyLayer.super.initDatas(self)
    self._canColIdxList = _canColIdxList or {}
    
    self:setShowActionEnabled(false) 
    self:setHideActionEnabled(false) 
    self:setLandscapeCsbName("Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_Fly_Layer.csb")
    self:setName("TrillionChallengeFlyLayer")
end

function TrillionChallengeFlyLayer:initView()
    local parent = self:findChild("node_center")
    local mainView = gLobalViewManager:getViewByName("TrillionChallengeMainLayer")
    local uiList = {}
    for _, idx in ipairs(self._canColIdxList) do
        local mainBoxRefNode = mainView:findChild("node_box_" .. idx)
        local posW = display.center
        if mainBoxRefNode then
            posW = mainBoxRefNode:convertToWorldSpace(cc.p(0, 0))
        end
        local flyView = util_createView("GameModule.TrillionChallenge.views.tournament.TrillionChallengeFlyBox", idx, posW)
        parent:addChild(flyView)

        table.insert(uiList, {node = flyView, anchor = cc.p(0.5, 0.5)})
    end
    util_alignCenter(uiList)
    self._flyViewList = uiList
end

function TrillionChallengeFlyLayer:playFlyAction(_cb)
    for _, info in ipairs(self._flyViewList) do
        local flyView = info.node

        while true do
            if tolua.isnull(flyView) then
                break
            end

            flyView:playFlyAction(self, function()
                if tolua.isnull(self.m_baseMaskUI) then
                    return
                end
                self.m_baseMaskUI:setOpacity(0)
                _cb()
            end)

            break
        end

    end
end

function TrillionChallengeFlyLayer:closeUI()
    if self._bClose then
        return
    end
    self._bClose = true
    TrillionChallengeFlyLayer.super.closeUI(self)
end

return TrillionChallengeFlyLayer