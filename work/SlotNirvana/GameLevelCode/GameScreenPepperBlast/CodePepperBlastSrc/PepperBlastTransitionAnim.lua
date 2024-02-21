-- FreeGame的过场动画
local PepperBlastTransitionAnim = class("PepperBlastTransitionAnim",cc.Node)

function PepperBlastTransitionAnim:create()
    local node = PepperBlastTransitionAnim.new()

    return node
end

-- 构造函数
function PepperBlastTransitionAnim:ctor()
    self:initUI()
end

function PepperBlastTransitionAnim:initUI()
    local spineName = "PepperBlast_Freeguochang"
    self.m_spine = util_spineCreate(spineName, true, true)
    self:addChild(self.m_spine)
end
function PepperBlastTransitionAnim:delete()
    self:removeFromParent()
end


function PepperBlastTransitionAnim:playTransitionEffectStart(func)
    self:setVisible(true)
    -- star -> idleframe -> over
    local animName = "start"
    util_spinePlay(self.m_spine, animName)
    util_spineEndCallFunc(self.m_spine, animName, function()
        util_spinePlay(self.m_spine, "idleframe", true)
        if(nil~=func)then
            func()
        end
    end)
end

function PepperBlastTransitionAnim:playTransitionEffectOver(func)
    local animName = "over"
    util_spinePlay(self.m_spine, animName)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:setVisible(false)
        if(nil~=func)then
            func()
        end
        
    end)
end

return PepperBlastTransitionAnim