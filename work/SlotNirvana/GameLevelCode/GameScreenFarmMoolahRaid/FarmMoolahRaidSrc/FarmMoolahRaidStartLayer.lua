--人鱼blast 特殊事件选择弹板
local FarmMoolahRaidStartLayer = class("FarmMoolahRaidStartLayer", BaseLayer)

function FarmMoolahRaidStartLayer:ctor()
    FarmMoolahRaidStartLayer.super.ctor(self)
    self:setLandscapeCsbName("FarmMoolahRaid/FreeSpinStart.csb")
    self:setExtendData("FarmMoolahRaidStartLayer")
    self:setClickSound("FarmMoolahRaidSounds/sound_FarmMoolah_click.mp3")
end

function FarmMoolahRaidStartLayer:initDatas(_data,_callback)
    self.m_data = _data
    self.m_over = _callback
end



function FarmMoolahRaidStartLayer:initCsbNodes()
    self.m_lb_num = self:findChild("m_lb_num")
end

function FarmMoolahRaidStartLayer:initView()
    self.m_lb_num:setString(globalData.slotRunData.freeSpinCount)
    local buffs = self.m_data
    if buffs then
        self:upDataBuffInfo(buffs)
    end
end

function FarmMoolahRaidStartLayer:upDataBuffInfo(_buffData)
    for i=1,4 do
        local data = _buffData[i]
        if i ~= 4 then
            local vaule = self:findChild("m_lb_num_buff"..i.."_1")
            vaule:setString(data.value)
            if i == 3 then
                vaule:setString(data.value.."X")
            elseif i == 1 then
                local lva = tonumber(data.value)
                if lva > 0 then
                    lva = lva - 1
                end
                vaule:setString(lva)
            end
        else
            local num = tonumber(data.value)
            for k=1,num do
                self:findChild("J"..k):setVisible(true)
            end
        end
        local lb_lv = self:findChild("m_lb_num_buff"..i)
        lb_lv:setString(data.level)
    end
end

function FarmMoolahRaidStartLayer:clickFunc(sender)

    local senderName = sender:getName()
    if senderName == "Button_1" then
        gLobalSoundManager:playSound("FarmMoolahRaidSounds/sound_FarmMoolah_click.mp3")
        gLobalSoundManager:playSound("FarmMoolahRaidSounds/sound_FarmMoolah_startover.mp3")
        self:closeUI(function()
            if self.m_over then
                self.m_over()
            end
        end)
    end
end

function FarmMoolahRaidStartLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, function()
    end)
end

function FarmMoolahRaidStartLayer:playShowAction()
    FarmMoolahRaidStartLayer.super.playShowAction(self, "start", false)
end

function FarmMoolahRaidStartLayer:registerListener()
    FarmMoolahRaidStartLayer.super.registerListener(self)
end

return FarmMoolahRaidStartLayer
