--[[--
    鲨鱼
]]
local CSMainBoxMonster = class("CSMainBoxMonster", BaseView)

function CSMainBoxMonster:initDatas(_isGrey)
    self.m_isGrey = _isGrey
end

function CSMainBoxMonster:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_Box_Monster.csb"
end

function CSMainBoxMonster:initCsbNodes()
    self.m_spBox1 = self:findChild("sp_box_normal")
end

function CSMainBoxMonster:initUI()
    CSMainBoxMonster.super.initUI(self)
    self:initRewardColor()
end

function CSMainBoxMonster:playStart(_over)
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("hide_idle", false, _over, 60)
        end,
        60
    )
end

function CSMainBoxMonster:playOtherStart(_over)
    self:runCsbAction("hide_idle", false, _over, 60)
end

function CSMainBoxMonster:playHideIdle()
    self:runCsbAction("hide_idle", true, nil, 60)
end

function CSMainBoxMonster:playDisappear(_over)
    self:runCsbAction("hide_idle", false, _over, 60)
end

function CSMainBoxMonster:playOtherDisappear(_index, _over)
    self:runCsbAction(
        "hide_idle",
        false,
        function()
            if _over then
                _over(_index)
            end
        end,
        60
    )
end

function CSMainBoxMonster:initRewardColor()
    local color = self.m_isGrey and cc.c3b(127, 115, 150) or cc.c3b(255, 255, 255)
    self.m_spBox1:setColor(color)
end

return CSMainBoxMonster
