--[[
    关卡转场
]]
local TripleBingoTransfer = class("TripleBingoTransfer", cc.Node)

function TripleBingoTransfer:initData_(_params)
    --[[
        _params = {
        }
    ]]
    self.m_data = _params

    self:initUI()
end

function TripleBingoTransfer:initUI()
    --角色接蛋
    self.m_transferSpine    = util_spineCreate("TripleBingo_guochang", true, true)
    self:addChild(self.m_transferSpine)
    self.m_transferSpine:setVisible(false)
    --延时节点
    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode)
end



function TripleBingoTransfer:playFreeTransferAnim(_fnSwitch, _fnOver)
    self.m_transferSpine:setVisible(true)
    util_spinePlay(self.m_transferSpine, "actionframe_guochang", false)

    performWithDelay(self.m_delayNode, function()
        _fnSwitch()

        performWithDelay(self.m_delayNode, function()
            self.m_transferSpine:setVisible(false)
            _fnOver()
        end, 30/30)

    end, 30/30)
end

return TripleBingoTransfer