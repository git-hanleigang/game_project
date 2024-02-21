--[[
    关卡转场
]]
local CalacasParadeTransfer = class("CalacasParadeTransfer", cc.Node)

function CalacasParadeTransfer:initData_(_machine)
    self.m_machine = _machine

    self:initUI()
end

function CalacasParadeTransfer:initUI()
    local scale = math.max(1.1, 1 / self.m_machine.m_machineRootScale * 0.8) 
    self:setScale(scale)
end

-- 通用播放
function CalacasParadeTransfer:playSpineTransferAnim(_spine, _animName, _switchTime, _fnSwitch, _fnOver)
    local animTime = _spine:getAnimationDurationTime(_animName)
    util_spinePlay(_spine, _animName, false)
    performWithDelay(_spine, function()
        _fnSwitch()
        performWithDelay(_spine, function()
            _spine:setVisible(false)
            _fnOver()
        end, animTime-_switchTime)
    end, _switchTime)
end

--free过场
-- function CalacasParadeTransfer:playFreeTransferAnim(_fnSwitch, _fnOver)
--     local spine = self:createFreeTransferAnim()
--     spine:setVisible(true)
--     self:playSpineTransferAnim(spine, "actionframe_guochang", 21/30, _fnSwitch, _fnOver)
-- end
-- function CalacasParadeTransfer:createFreeTransferAnim()
--     if not self.m_freeSpine then
--         self.m_freeSpine = util_spineCreate("PowerLottoJackpot_guochang1", true, true)
--         self:addChild(self.m_freeSpine)
--         self.m_freeSpine:setVisible(false)
--     end
--     return self.m_freeSpine
-- end

--Parade过场
function CalacasParadeTransfer:playParadeTransferAnim(_fnSwitch, _fnOver)
    local spineList  = self:createParadeTransferAnim()
    local switchTime = 81/30
    for i,v in ipairs(spineList) do
        local spine = spineList[i]
        spine:setVisible(true)
        if 1 == i then
            self:playSpineTransferAnim(spine, "actionframe_guochang", switchTime, _fnSwitch, _fnOver)
        else
            self:playSpineTransferAnim(spine, "actionframe_guochang", switchTime, function() end, function() end)
        end
    end

end
function CalacasParadeTransfer:createParadeTransferAnim()
    if not self.m_paradeSpine then
        local parent = self
        self.m_paradeSpine = {}
        for _index=1,3 do
            local order = _index*10
            local spine = util_spineCreate(string.format("CalacasParade_huache_guochang%d", _index), true, true)
            parent:addChild(spine, order)
            spine:setVisible(false)
            self.m_paradeSpine[_index] = spine
        end
    end
    return self.m_paradeSpine
end

--fireworks过场
function CalacasParadeTransfer:playFireworksTransferAnim(_fnSwitch, _fnOver)
    local spine = self:createFireworksTransferAnim()
    spine:setVisible(true)
    self:playSpineTransferAnim(spine, "actionframe_guochang", 51/30, _fnSwitch, _fnOver)
end
function CalacasParadeTransfer:createFireworksTransferAnim()
    if not self.m_fireworksSpine then
        local parent = self.m_machine.m_effectNodeUp
        self.m_fireworksSpine = util_spineCreate("CalacasParade_yanhua", true, true)
        parent:addChild(self.m_fireworksSpine)
        self.m_fireworksSpine:setPosition( util_convertToNodeSpace(self, parent) )
        self.m_fireworksSpine:setVisible(false)
    end
    return self.m_fireworksSpine
end


return CalacasParadeTransfer