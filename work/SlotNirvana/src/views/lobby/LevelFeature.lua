--
--大厅功能展示图节点
--
local LevelFeature = class("LevelFeature", util_require("base.BaseView"))

LevelFeature.m_contentLen = nil
function LevelFeature:initUI(info, index)
    self.m_info = info
    self.m_index = index

    self:createCsb()

    local content = self:findChild("content")
    local size = content:getContentSize()
    self.m_contentLen = size.width * 0.5

    local spShade = util_createSprite("newIcons/ui/hall_shade.png")
    if spShade then
        self:addChild(spShade, -1)
    end

    local borderMask = util_csbCreate("newIcons/Hall_border_mask.csb")
    if borderMask then
        self:addChild(borderMask, 10)
    end
    
    local touch = self:makeTouch(content, "FeatureHallNodeTouch_" .. self.m_index)
    self:addChild(touch, -1)
    self:addClick(touch)
end

-- 必须被重写
function LevelFeature:createCsb()
end

--根据content大小创建按钮监听
function LevelFeature:makeTouch(content, name)
    local touch = ccui.Layout:create()
    touch:setName(name)
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(false)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(content:getContentSize())
    touch:setClippingEnabled(false)
    touch:setBackGroundColorOpacity(0)
    return touch
end

function LevelFeature:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end

function LevelFeature:getContentLen()
    return self.m_contentLen
end

function LevelFeature:getOffsetPosX()
    return self.m_contentLen
end

return LevelFeature
