--[[
    
]]

local BaseSidekicksInterludeLayer = class("BaseSidekicksInterludeLayer", BaseLayer)

function BaseSidekicksInterludeLayer:initDatas(_seasonIdx, _func, _id)
    self.m_seasonIdx = _seasonIdx
    self.m_callFunc = _func
    self.m_id = _id

    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)
    self:setMaskEnabled(false)
    self:setExtendData("BaseSidekicksInterludeLayer")
end

function BaseSidekicksInterludeLayer:initView()
    local path = string.format("Sidekicks_%s/spine/chuanglian", self.m_seasonIdx)
    local sound = string.format("Sidekicks_%s/sound/Sidekicks_changeLayer.mp3", self.m_seasonIdx)
    if self.m_id == 2 then
        path = string.format("Sidekicks_%s/spine/Sidekicks_lianzi", self.m_seasonIdx)
        sound = string.format("Sidekicks_%s/sound/Sidekicks_openMainLayer.mp3", self.m_seasonIdx)
    end

    self.m_spine = util_spineCreate(path, true, true, 1)
    self:addChild(self.m_spine)
    self.m_spine:setPosition(display.cx, display.cy)
    gLobalSoundManager:playSound(sound)
end

function BaseSidekicksInterludeLayer:onEnter()
    BaseSidekicksInterludeLayer.super.onEnter(self)

    util_spinePlay(self.m_spine, "start", false)
    util_spineEndCallFunc(self.m_spine, "start", function ()
        if self.m_callFunc then
            self.m_callFunc()
        end

        if self.m_id == 1 then
            util_spinePlay(self.m_spine, "over", false)
            util_spineEndCallFunc(self.m_spine, "over", function ()
                self:setVisible(false)
                performWithDelay(self, function ()
                    self:closeUI()
                end, 0.1)
            end)
        else 
            self:setVisible(false)
            performWithDelay(self, function ()
                self:closeUI()
            end, 0.1)
        end
    end)
end

return BaseSidekicksInterludeLayer
