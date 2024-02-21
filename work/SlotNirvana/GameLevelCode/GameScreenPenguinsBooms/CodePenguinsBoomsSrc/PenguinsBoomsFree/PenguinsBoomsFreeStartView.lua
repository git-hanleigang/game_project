local PenguinsBoomsFreeStartView = class("PenguinsBoomsFreeStartView",util_require("Levels.BaseDialog"))
local PublicConfig = require "PenguinsBoomsPublicConfig"

PenguinsBoomsFreeStartView.m_penguinsBoomsData = {}

function PenguinsBoomsFreeStartView:setPenguinsBoomsFreeStartViewData(_data)
    --[[
        _data = {
            freeTimes = 0
            scTimes   = {}
        }
    ]]
    self.m_penguinsBoomsData = _data
end


function PenguinsBoomsFreeStartView:openDialog()
    self.m_allowClick = false
    self:updatePenguinsBoomsFreeStartView()
    PenguinsBoomsFreeStartView.super.openDialog(self)
end

function PenguinsBoomsFreeStartView:updatePenguinsBoomsFreeStartView()
    --数字  
    local sTimes   = ""
    local scTimes  = self.m_penguinsBoomsData.scTimes or {}
    local timesCount = 0 
    for k,times in pairs(scTimes) do
        timesCount = timesCount + 1
        if "" ~= sTimes then
            sTimes = sTimes .. "+"
        end
        sTimes = sTimes .. times
    end
    local labTimes = self:findChild("m_lb_num")
    labTimes:setString(sTimes)

    if timesCount <= 1 then
        self:updateLabelSize({label=labTimes, sx=1.5, sy=1.5}, 232)
    else
        self:updateLabelSize({label=labTimes, sx=1.2, sy=1.2}, 543)
    end
    --鸟
    local spine = util_spineCreate("Socre_PenguinsBooms_7",true,true)
    self:findChild("Node_niaoSpine"):addChild(spine)
    local startName = "start_tanban"
    local idleName  = "idle_tanban"
    util_spinePlay(spine, startName, false)
    util_spineEndCallFunc(spine, startName, function()
        util_spinePlay(spine, idleName, true)
    end)

end

function PenguinsBoomsFreeStartView:showidle()
    PenguinsBoomsFreeStartView.super.showidle(self)
    self:playTimesAddAnim(function()
        self.m_allowClick = true
    end)
end
--次数相加
function PenguinsBoomsFreeStartView:playTimesAddAnim(_fun)
    local scTimes    = self.m_penguinsBoomsData.scTimes or {}
    local timesCount = 0 
    for k,v in pairs(scTimes) do
        timesCount = timesCount + 1
    end
    if timesCount <= 1 then
        _fun()
        return
    end

    --文本父节点放大缩小
    local labParent = self:findChild("Node_num")
    local actList = {}
    table.insert(actList, cc.ScaleTo:create(9/60, 1.07))
    table.insert(actList, cc.ScaleTo:create(9/60, 0.25))
    table.insert(actList, cc.ScaleTo:create(15/60, 1.07))
    table.insert(actList, cc.ScaleTo:create(9/60, 1))
    labParent:runAction(cc.Sequence:create(actList))

    -- 延时一下 再合成数字
    performWithDelay(self:findChild("Node_addbd"),function()
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeStartView_add)
        --爆光
        local lightCsb = util_createAnimation("PenguinsBooms_tb_addbd.csb")
        self:findChild("Node_addbd"):addChild(lightCsb)
        lightCsb:runCsbAction("add")
        --合成数字
        local freeTimes = self.m_penguinsBoomsData.freeTimes or 0
        local sTimes    = string.format("%d", freeTimes)
        local labTimes = self:findChild("m_lb_num")
        labTimes:setString(sTimes)
        self:updateLabelSize({label=labTimes, sx=1.5, sy=1.5}, 232)
        performWithDelay(lightCsb,function()
            _fun()
        end, 30/60)
    end, 18/60)
end
return PenguinsBoomsFreeStartView