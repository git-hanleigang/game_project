--[[
    等级里程碑 宝箱动画
]]
local LevelRoadBoxAnimation = class("LevelRoadBoxAnimation", BaseView)

function LevelRoadBoxAnimation:ctor()
    LevelRoadBoxAnimation.super.ctor(self)
end

function LevelRoadBoxAnimation:initDatas(_startPos, _endPos, _callFunc)
    self.m_startPos = _startPos or cc.p(0, 0)
    self.m_endPos = _endPos or cc.p(0, 0)
    self.m_callFunc = _callFunc
end

function LevelRoadBoxAnimation:getCsbName()
    return "LevelRoad/csd/LevelRoad_levelbar_levelphase_gift.csb"
end

function LevelRoadBoxAnimation:initUI()
    LevelRoadBoxAnimation.super.initUI(self)
    self:initView()
end

function LevelRoadBoxAnimation:initCsbNodes()
    self.m_node_box = self:findChild("node_levelphase")
end

function LevelRoadBoxAnimation:initView()

end

function LevelRoadBoxAnimation:onEnterFinish()
    LevelRoadBoxAnimation.super.onEnterFinish(self)
    local startPos = self.m_node_box:getParent():convertToNodeSpace(self.m_startPos)
    self.m_node_box:setPosition(startPos)
end

function LevelRoadBoxAnimation:playStartAni()
    self:runCsbAction(
        "start",
        false,
        function()
            self:playFlyAni()
        end,
        60
    )
end

function LevelRoadBoxAnimation:playFlyAni()
    local endPos = self.m_node_box:getParent():convertToNodeSpace(self.m_endPos)
    self:runCsbAction(
        "fly",
        false,
        function()
            self:playOpenAni()
        end,
        60
    )
    local action = cc.MoveTo:create(23 / 60, endPos)
    self.m_node_box:runAction(action)
end

function LevelRoadBoxAnimation:playOpenAni()
    self:runCsbAction(
        "open",
        false,
        function()
            self:playOverAni()
            if self.m_callFunc then
                self.m_callFunc()
            end
        end,
        60
    )
end

function LevelRoadBoxAnimation:playOverAni()
    self:runCsbAction(
        "over",
        false,
        function()
        end,
        60
    )
end

return LevelRoadBoxAnimation