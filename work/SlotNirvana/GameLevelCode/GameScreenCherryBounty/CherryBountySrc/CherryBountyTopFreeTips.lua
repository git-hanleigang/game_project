--[[
    free提示
]]
local CherryBountyTopFreeTips = class("CherryBountyTopFreeTips", util_require("base.BaseView"))

function CherryBountyTopFreeTips:initUI(_machine)
    self.m_machine     = _machine
    self.m_targetCoins = 0

    self:createCsbNode("CherryBounty_xinxiqu_free.csb")
    self.m_labCsb = self:createLabelCsb()
    self:findChild("Node_shuzi"):addChild(self.m_labCsb)
    self.m_labCoins = self.m_labCsb:findChild("m_lb_coins")
end
function CherryBountyTopFreeTips:createLabelCsb()
    return util_createAnimation("CherryBounty_xinxiqu_free_shuzi.csb")
end

function CherryBountyTopFreeTips:onEnter()
    CherryBountyTopFreeTips.super.onEnter(self)
    self:playReelTipsIdle()
end
function CherryBountyTopFreeTips:playReelTipsIdle()
    self:runCsbAction("idle", true)
end


--时间线-收集
function CherryBountyTopFreeTips:playCollectAnim(_addCoins)
    local labCoins   = self.m_labCoins
    local startCoins = self.m_targetCoins
    local endCoins   = startCoins + _addCoins
    self.m_targetCoins = endCoins
    local jumpTime   = 15/30
    local coinRise   =  _addCoins / (jumpTime * 60)  
    local fnOver     = function() end
    local fnUpDate   = function()
        self:upDateLabelCoinsSize(self.m_labCoins)
    end
    util_jumpNumExtra(
        labCoins,
        startCoins,
        endCoins,
        coinRise,
        1/60,
        util_formatCoinsLN,
        {3}, 
        nil, 
        nil,
        fnOver,
        fnUpDate
    )

    local particle = self.m_labCsb:findChild("Particle_1")
    self.m_machine:playOnceParticleEffect(particle)
end
function CherryBountyTopFreeTips:stopUpDateJumpCoins()
    local labCoins   = self.m_labCoins
    labCoins:unscheduleUpdate()
end

--金额文本-初始化玩法金额
function CherryBountyTopFreeTips:initLabelCoins(_coins)
    self.m_targetCoins = _coins
    self:upDateLabelCoins(self.m_labCoins, _coins)
end
--金额文本-刷新金额
function CherryBountyTopFreeTips:upDateLabelCoins(_labCoins, _coins)
    local sCoins = ""
    if _coins > 0 then
        sCoins = util_formatCoinsLN(_coins, 3)
    end
    _labCoins:setString(sCoins)
    self:upDateLabelCoinsSize(_labCoins)
end
--金额文本-文本适配
function CherryBountyTopFreeTips:upDateLabelCoinsSize(_labCoins)
    self.m_machine:updateLabelSize({label=_labCoins, sx=0.64, sy=0.64}, 145)
end

return CherryBountyTopFreeTips