--[[
    破产促销 buff气泡
]]
local BrokenSaleV2BuffBubble = class("BrokenSaleV2BuffBubble", BaseView)

function BrokenSaleV2BuffBubble:ctor()
    BrokenSaleV2BuffBubble.super.ctor(self)
end

function BrokenSaleV2BuffBubble:initDatas(_boxId)
    self.m_isHideBubble = true --气泡是否隐藏
    self.m_isActionTime = false --是否正在动画中
    self.m_isForceHide = false -- 是否强制隐藏
end

function BrokenSaleV2BuffBubble:getCsbName()
    return "BrokenSaleV2/csd/BrokenSale_qipao.csb"
end

function BrokenSaleV2BuffBubble:initUI()
    BrokenSaleV2BuffBubble.super.initUI(self)
end

--气泡显示动画
function BrokenSaleV2BuffBubble:runShowAmin()
    if self.m_isActionTime then
        return
    end
    if not self.m_isHideBubble then
        return
    end
    local showEndCallBack = function()
        local hideBubble = function()
            self:runHideAmin()
        end
        self.m_isHideBubble = false
        self.m_isActionTime = false
        performWithDelay(self, hideBubble, 6)
        self:runCsbAction("idle", true, nil, 60)
    end
    self.m_isActionTime = true
    self:runCsbAction("start", false, showEndCallBack, 60)
end

--气泡隐藏动画
function BrokenSaleV2BuffBubble:runHideAmin(_cb)
    if self.m_isActionTime then
        return
    end
    if self.m_isHideBubble then
        return
    end
    self.m_isActionTime = true
    self:stopAllActions()
    self:runCsbAction(
        "over",
        false,
        function()
            self.m_isActionTime = false
            self.m_isHideBubble = true
            if _cb then
                _cb()
            end
        end,
        60
    )
end

function BrokenSaleV2BuffBubble:showBubble()
    if self.m_isHideBubble then
        self:runShowAmin()
    else
        self:runHideAmin()
    end
end

return BrokenSaleV2BuffBubble
