--[[
    author:maqun
    time:2021-08-24 14:23:40
]]
local BaseGuideUI = class("BaseGuideUI", BaseView)

function BaseGuideUI:initUI()
    BaseGuideUI.super.initUI(self)
    self:initView()
end

-- 子类实现
function BaseGuideUI:getCsbName()
    assert(false, "---- 子类必须实现 ----")
end

function BaseGuideUI:initDatas(_guideId, _bottomTouchEnabled, _bottomSwallow, _topTouchEnabled, _topSwallow, _bottomOpacity)
    BaseGuideUI.super.initDatas(self)
    self.m_guideId = _guideId or 1 -- 引导步骤
    self.m_bottomTouchEnabled = _bottomTouchEnabled or false
    self.m_bottomSwallow = _bottomSwallow or false
    self.m_topTouchEnabled = _topTouchEnabled or false
    self.m_topSwallow = _topSwallow or false
    self.m_bottomOpacity = _bottomOpacity or 190
end

function BaseGuideUI:initCsbNodes()
end

function BaseGuideUI:initView()
    self:initBottomLayer()
    self:initHighNode()
    self:initTopLayer()
end

function BaseGuideUI:initBottomLayer()
    local bottomLayer = self:createLayer("bottomLayer", self.m_bottomTouchEnabled, self.m_bottomSwallow, self.m_bottomOpacity)
    self:addChild(bottomLayer, -1)
end

function BaseGuideUI:initTopLayer()
    -- local topLayer = self:createLayer("topLayer", self.m_bottomSwallow, 255)
    -- self:addChild(topLayer)
end

function BaseGuideUI:initHighNode()
end

function BaseGuideUI:createLayer(_touchName, _touchEnabled, _isSwallow, _opacity)
    local touch = ccui.Layout:create()
    touch:setName(_touchName)
    touch:setTag(10)
    touch:setTouchEnabled(_touchEnabled)
    touch:setSwallowTouches(_isSwallow)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(cc.size(display.width, display.height))
    touch:setClippingEnabled(false)
    touch:setBackGroundColorOpacity(0)
    return touch
end
return BaseGuideUI
