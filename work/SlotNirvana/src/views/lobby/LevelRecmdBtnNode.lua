--[[
    
    author: 徐袁
    time: 2021-07-29 14:41:56
]]
local LevelRecmdBtnNode = class("LevelRecmdBtnNode", util_require("base.BaseView"))

-- function LevelRecmdBtnNode:initUI()
--     LevelRecmdShowNode.super.initUI(self)

--     -- self:initView()
-- end

function LevelRecmdBtnNode:initCsbNodes()
    self.m_palTouch = self:findChild("touch")
    self:addClick(self.m_palTouch)
    self.m_palTouch:setSwallowTouches(false)
end

function LevelRecmdBtnNode:getCsbName()
    return "newIcons/LevelRecmd/jiantou_zhedie.csb"
end

function LevelRecmdBtnNode:onEnter()
    LevelRecmdBtnNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.bDealTouch == false then
                return
            end
            
            local isPlaying = params.isPlaying or false
            self.m_palTouch:setTouchEnabled(not isPlaying)
            self.m_palTouch:setSwallowTouches(false)
        end,
        ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_ACTION
    )

end

function LevelRecmdBtnNode:idleOpened()
    self:runCsbAction("opened", false)
end

function LevelRecmdBtnNode:playOpenAction(callback)
    self:runCsbAction(
        "open",
        false,
        function()
            if callback then
                callback()
            end

            self:idleOpened()
        end,
        60
    )
end

function LevelRecmdBtnNode:idleClosed()
    self:runCsbAction("closed", false)
end

function LevelRecmdBtnNode:playCloseAction(callback)
    self:runCsbAction(
        "close",
        false,
        function()
            if callback then
                callback()
            end
            self:idleClosed()
        end,
        60
    )
end

function LevelRecmdBtnNode:setParentNode(_node)
    self.m_nodeParent = _node
end

--点击回调
function LevelRecmdBtnNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch" then
        -- 展示关卡
        if self.m_nodeParent then
            self.m_nodeParent:changeLevelsVisible()
        end
    end
end

return LevelRecmdBtnNode
