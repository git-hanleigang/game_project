---
--xcyy
--2018年5月23日
--BunnyBountyFreeStartView.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyFreeStartView = class("BunnyBountyFreeStartView",util_require("Levels.BaseLevelDialog"))


function BunnyBountyFreeStartView:initUI(params)
    self.m_machine = params.machine
    self.m_endFunc = params.func
    self.m_rootScale = params.scale
    local ownerlist = params.ownerlist--
    self:createCsbNode("BunnyBounty/FreeSpinStart.csb")

    self:findChild("Button_1"):setTouchEnabled(false)

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
function BunnyBountyFreeStartView:showView(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_show_free_start)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        self:findChild("Button_1"):setTouchEnabled(true)
        if type(func) == "function" then
            func()
        end
    end)

    util_spinePlay(self.m_spine,"tanban2_start")
    util_spineEndCallFunc(self.m_spine,"tanban2_start",function()
        util_spinePlay(self.m_spine,"tanban2_idle",true)
    end)
end

--默认按钮监听回调
function BunnyBountyFreeStartView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    self:findChild("Button_1"):setTouchEnabled(false)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_btn_click)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_change_scene_to_free)
    self.m_machine:changeSceneToFree(function()
        self:showOver()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end
    end)

    
end

--[[
    结束动画
]]
function BunnyBountyFreeStartView:showOver(func)
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        
        performWithDelay(self,function()
            self:removeFromParent()
        end,0.1)
    end)
    util_spinePlay(self.m_spine,"tanban2_over")
end


return BunnyBountyFreeStartView