---
--xcyy
--2018年5月23日
--BunnyBountyRespinStartView.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyRespinStartView = class("BunnyBountyRespinStartView",util_require("Levels.BaseLevelDialog"))


function BunnyBountyRespinStartView:initUI(params)
    self.m_machine = params.machine
    self.m_endFunc = params.func
    self.rowCount = params.rowCount
    self.m_rootScale = params.scale
    local ownerlist = params.ownerlist
    self:createCsbNode("BunnyBounty/ReSpinStart.csb")

    self:findChild("Button_1"):setTouchEnabled(false)

    for index = 4,6 do
        if self:findChild("rowCount_"..index) then
            self:findChild("rowCount_"..index):setVisible(false)
        end
    end

    self:updateOwnerVar(ownerlist)

    --兔子
    self.m_spine = util_spineCreate("BunnyBounty_juese",true,true)
    self:findChild("spine"):addChild(self.m_spine)

    self:findChild("root"):setScale(self.m_rootScale)
    

    self:showView()
end


--[[
    显示界面
]]
function BunnyBountyRespinStartView:showView(func)
    if self.rowCount == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_show_respin_start)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_show_respin_start_double)
    end
    
    self:runCsbAction("start",false,function()
        local function idleFunc()
            self:runCsbAction("idle",true)
            self:findChild("Button_1"):setTouchEnabled(true)
            if type(func) == "function" then
                func()
            end
        end
        
        if self.rowCount == 3 then
            idleFunc()
        else
            for index = 3,6 do
                if self:findChild("rowCount_"..index) then
                    self:findChild("rowCount_"..index):setVisible(true)
                end
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_BunnyBounty_change_respin_count_"..(self.rowCount - 3)])
            
            local aniName = "actionframe"..(self.rowCount - 3)
            self:runCsbAction(aniName,false,function()
                self:runCsbAction("actionframe_over",false,function()
                    idleFunc()
                end)
                
                for index = 3,6 do
                    if self:findChild("rowCount_"..index) then
                        self:findChild("rowCount_"..index):setVisible(index == self.rowCount)
                    end
                end
            end)
        end
        
        
    end)

    util_spinePlay(self.m_spine,"tanban_start")
    util_spineEndCallFunc(self.m_spine,"tanban_start",function()
        util_spinePlay(self.m_spine,"tanban_idle",true)
    end)
end

--默认按钮监听回调
function BunnyBountyRespinStartView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    self:findChild("Button_1"):setTouchEnabled(false)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_btn_click)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_change_scene_to_respin)
    self.m_machine:changeSceneToRespin(function()
        self:showOver()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end
    end)

    
end

--[[
    结束动画
]]
function BunnyBountyRespinStartView:showOver(func)
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        
        performWithDelay(self,function()
            self:removeFromParent()
        end,0.1)
    end)
end


return BunnyBountyRespinStartView