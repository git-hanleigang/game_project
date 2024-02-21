local KangaPocketsFreeStartView = class("KangaPocketsFreeStartView",util_require("Levels.BaseDialog"))
local KangaPocketsPublicConfig = require "KangaPocketsPublicConfig"

function KangaPocketsFreeStartView:openDialog()
    local spineParent = self:findChild("Node_spineRole")
    self.m_kangaPocketsRole = util_createView("CodeKangaPocketsSrc.KangaPocketsRoleSpine", {})
    spineParent:addChild(self.m_kangaPocketsRole)
    self.m_kangaPocketsRole:playFreeStartCollectStartAnim(function()
        self.m_allowClick = true
    end)
    self.m_allowClick = false

    KangaPocketsFreeStartView.super.openDialog(self)
end


function KangaPocketsFreeStartView:showidle()
    KangaPocketsFreeStartView.super.showidle(self)
    --循环播放
    self:runCsbAction(self.m_idle_name, true)
end
function KangaPocketsFreeStartView:showOver(name)
    if self.m_bKangaPocketsShowOver then
        return
    end
    self.m_bKangaPocketsShowOver = true
    
    self:playCollectCommonSymbolAnim(function()
        -- self.m_kangaPocketsRole:runAction(cc.Sequence:create(
        --     cc.MoveBy:create(6/60, cc.p(display.width/2, 0)),
        --     cc.CallFunc:create(function()
        --         self.m_kangaPocketsRole:setVisible(false)
        --         KangaPocketsFreeStartView.super.showOver(self, name)
        --     end)
        -- ))
        self.m_kangaPocketsRole:playFreeStartCollectOverAnim(
            function()
                KangaPocketsFreeStartView.super.showOver(self, name)
            end,
            function()
                self.m_kangaPocketsRole:setVisible(false)
            end
        )
    end)
end

function KangaPocketsFreeStartView:playCollectCommonSymbolAnim(_fun)
    local flyNodeNameList = {
        "sp_symbol_9",
        "sp_symbol_10",
        "sp_symbol_J",
        "sp_symbol_Q",
        "sp_symbol_K",
        "sp_symbol_A",
    }
    local flyTime   = 0.5
    -- local interval  = 0.25
    local scaleTo   = 0.7
    local endNode   = self:findChild("Node_collect")
    local endPos    = util_convertToNodeSpace(endNode, self:findChild("Node_3"))
    for i,_nodeName in ipairs(flyNodeNameList) do
        local flyNode   = self:findChild(_nodeName)
        -- local delayTime = (i - 1) * interval
        local startPos  = cc.p(flyNode:getPosition())
        local distance    = math.sqrt((endPos.x - startPos.x) * (endPos.x - startPos.x) + (endPos.y - startPos.y) * (endPos.y - startPos.y))
        local radius      = distance/2
        local flyAngle    = util_getAngleByPos(startPos, endPos)
        local offsetAngle = endPos.x > startPos.x and 90 or -90
        local pos1 = cc.p( util_getCirclePointPos(startPos.x, startPos.y, radius*2, flyAngle + offsetAngle) )
        local pos2 = cc.p( util_getCirclePointPos(endPos.x, endPos.y, radius*2, flyAngle + offsetAngle) )
        flyNode:runAction(cc.Sequence:create(
            -- cc.DelayTime:create(delayTime),
            cc.DelayTime:create(0.5),
            cc.Spawn:create(cc.ScaleTo:create(flyTime, scaleTo), cc.BezierTo:create(flyTime, {pos1, pos2, endPos})),
            cc.CallFunc:create(function()
                flyNode:setVisible(false)
            end)
        ))
    end

    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_RoleSpine_FreeStartCollect)
    self.m_kangaPocketsRole:playFreeStartCollectAnim(function()
        _fun()
    end)
end

return KangaPocketsFreeStartView