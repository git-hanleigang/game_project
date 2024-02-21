---
--xcyy
--2018年5月23日
--RocketPupFreeStartView.lua
local RocketPupFreeStartView = class("RocketPupFreeStartView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "RocketPupPublicConfig"

function RocketPupFreeStartView:initUI(params)
    self.m_machine = params.machine
    self.m_endFunc = params.func
    self.m_rootScale = params.scale
    local ownerlist = params.ownerlist--
    self:createCsbNode("RocketPup/FreeSpinStart.csb")

    self:findChild("Button_1"):setTouchEnabled(false)

    self:updateOwnerVar(ownerlist)
    self:updataBuffs(ownerlist["buffs"])

    -- --兔子
    -- self.m_spine = util_spineCreate("BunnyBounty_juese",true,true)
    -- self:findChild("spine"):addChild(self.m_spine)

    self:findChild("root"):setScale(self.m_rootScale)
    

    self:showView()
end

function RocketPupFreeStartView:updataBuffs(_buffData)
    if not _buffData or #_buffData == 0 then
        return
    end
    for i=1,3 do
        local item = {}
        local data = _buffData[i]
        local lv = self:findChild("m_lb_level"..i)
        lv:setString(data.level)
        if i == 3 then
            if tonumber(data.level) == 1 then
                self:findChild("wenan3_0"):setVisible(true)
                self:findChild("wenan3"):setVisible(false)
            else
                self:findChild("wenan3_0"):setVisible(false)
                self:findChild("wenan3"):setVisible(true)
            end
            for j=1,4 do
                local spX = self:findChild("qc"..j)
                if spX then
                    spX:setVisible(j <= tonumber(data.value))
                end
            end
        else
            local vaule = self:findChild("m_lb_value"..i)
            vaule:setString(data.value)
            if i == 2 then
                local lva = tonumber(data.value)
                if lva > 0 then
                    lva = lva - 1
                end
                vaule:setString(lva)
            end
        end
    end
end


--[[
    显示界面
]]
function RocketPupFreeStartView:showView(func)
    -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_show_free_start)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        self:findChild("Button_1"):setTouchEnabled(true)
        if type(func) == "function" then
            func()
        end
    end)

    -- util_spinePlay(self.m_spine,"tanban2_start")
    -- util_spineEndCallFunc(self.m_spine,"tanban2_start",function()
    --     util_spinePlay(self.m_spine,"tanban2_idle",true)
    -- end)
end

--默认按钮监听回调
function RocketPupFreeStartView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    self:findChild("Button_1"):setTouchEnabled(false)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RocketPup_click)

    -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_change_scene_to_free)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RocketPup_show_freeover)
    self:showOver()

end

--[[
    结束动画
]]
function RocketPupFreeStartView:showOver(func)
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end
        performWithDelay(self,function()
            self:removeFromParent()
        end,0.1)
    end)
    -- util_spinePlay(self.m_spine,"tanban2_over")
end


return RocketPupFreeStartView