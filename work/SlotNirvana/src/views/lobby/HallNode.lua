--展示图
local HallNode = class("HallNode", util_require("base.BaseView"))

function HallNode:initUI(data)
    self:createCsbNode(data.path)
    self:runCsbAction("idle", true)

    local spShade = util_createSprite("newIcons/ui/hall_shade.png")
    if spShade then
        self:addChild(spShade, -1)
    end

    local borderMask = util_csbCreate("newIcons/Hall_border_mask.csb")
    if borderMask then
        self:addChild(borderMask, 10)
    end

    self.m_data = data.param
    self:initView()
    -- self:updateView()
    local content = self:findChild("content")
    if content then
        content:setPosition(cc.p(0, 0))
    -- content:setScale(1.02)
    end

    local stencil = util_createSprite("newIcons/ui/hall_clipping.png")
    if stencil then
        local clip_node = cc.ClippingNode:create()
        clip_node:setAlphaThreshold(0.05)
        clip_node:setStencil(stencil)
        -- clip_node:setInverted(true)
        self:addChild(clip_node)
        util_changeNodeParent(clip_node, self.m_csbNode)
    end
end

function HallNode:initView()
end

function HallNode:updateView()
end

function HallNode:onEnter()
    self:updateView()
    --刷新轮播图数据
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateView()
        end,
        ViewEventType.UPDATE_SLIDEANDHALL_FINISH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateView()
        end,
        ViewEventType.NOTIFY_ACTIVITY_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not self.m_data then
                release_print("触发活动结束检测事件，该活动数据异常。活动名称：" .. self.__cname)
            end
            local _refName = self.m_data:getRefName()
            if _refName ~= "" and _refName == (params.name or "") then
                self:updateView()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function HallNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

-- 点击是否播点击音效
function HallNode:isClickPlaySound()
    return false
end

function HallNode:clickStartFunc(_sander)
    _sander:setSwallowTouches(false)
end

return HallNode
