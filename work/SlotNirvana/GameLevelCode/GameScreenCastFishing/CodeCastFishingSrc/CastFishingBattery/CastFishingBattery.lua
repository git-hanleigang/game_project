--[[
    各个场景炮台的基类
]]
local CastFishingBattery = class("CastFishingBattery",util_require("Levels.BaseLevelDialog"))

--[[
    _params = {
        csbPath,
        spinePath,
    }
]]
function CastFishingBattery:initDatas(_params)
    self.m_csbName   = _params[1]
    self.m_spineName = _params[2]
    self.m_machine   = _params[3]

    self.m_batteryData = nil
    self.m_clickCallBack = nil
end
function CastFishingBattery:initUI()
    self:createCsbNode(self.m_csbName)
    self:createSpineAnim()
    self:createTimeLab()
    self:createGuideAnim()
end


function CastFishingBattery:setBatteryData(_data)
    self.m_batteryData = _data
end

--[[
    挂载spine
]]
function CastFishingBattery:createSpineAnim()
    self.m_spineAnim = util_spineCreate(self.m_spineName,true,true)
    self:findChild("Node_Spine"):addChild(self.m_spineAnim)
end
function CastFishingBattery:playSpineAnim(_name,_loop,_fun)
    util_spinePlay(self.m_spineAnim, _name, _loop)
    util_spineEndCallFunc(self.m_spineAnim, _name, function()
        if nil ~= _fun then
            _fun()
        end    
    end) 
end
function CastFishingBattery:getBatterySize()
    local size = cc.size(130, 150)
    return size
end
--[[
    点击事件
]]
function CastFishingBattery:addBatteryClickEvent()
    local layClick = self:findChild("Panel_click")
    self:addClick(layClick)
end
function CastFishingBattery:setBatteryClickCallBack(_fun)
    self.m_clickCallBack = _fun
end
function CastFishingBattery:clickFunc(sender)
    local name = sender:getName()
    if "Panel_click" == name then
        if nil ~= self.m_clickCallBack then
            self.m_clickCallBack(self.m_batteryData)
        end
    end
end
--[[
    倒计时事件
]]
function CastFishingBattery:createTimeLab()
    self.m_labCountDown = util_createAnimation("CastFishing_time.csb")
    self:findChild("Node_countDown"):addChild(self.m_labCountDown)
    util_setCsbVisible(self.m_labCountDown, false)
end
function CastFishingBattery:startCountDown(_time, _fun)
    util_setCsbVisible(self.m_labCountDown, true)
    self:stopCountDown()
    self:playGuideAnim()

    self.m_labCountDown:runCsbAction("idle", true)
    self:changeTimeLab(_time)
    self.m_upDateCountDown = schedule(self.m_labCountDown, function()
        if self.m_machine:checkGameRunPause() then
            return
        end

        _time = _time - 1
        self:changeTimeLab(_time)
        if _time <= 0 then
            if _fun then
                _fun()
            end
        end
    end, 1)
end
function CastFishingBattery:stopCountDown()
    if nil ~= self.m_upDateCountDown then
        self.m_labCountDown:stopAction(self.m_upDateCountDown)
        self.m_upDateCountDown = nil
    end
    self.m_labCountDown:pause()
    self:stopGuideAnim()
end
function CastFishingBattery:changeTimeLab(_time)
    local lab = self.m_labCountDown:findChild("m_lb_num")
    lab:setString(tostring(_time))
end

function CastFishingBattery:playTimeLabOverAnim()
    util_setCsbVisible(self.m_labCountDown, false)
end
--[[
    倒计时引导
]]
function CastFishingBattery:createGuideAnim()
    self.m_guideCsb = util_createAnimation("CastFishing_guide.csb")
    self:findChild("Node_guide"):addChild(self.m_guideCsb)
    util_setCsbVisible(self.m_guideCsb, false)
end
function CastFishingBattery:playGuideAnim()
    util_setCsbVisible(self.m_guideCsb, true)
    self.m_guideCsb:runCsbAction("idle", true)
end
function CastFishingBattery:stopGuideAnim()
    util_setCsbVisible(self.m_guideCsb, false)
end

return CastFishingBattery