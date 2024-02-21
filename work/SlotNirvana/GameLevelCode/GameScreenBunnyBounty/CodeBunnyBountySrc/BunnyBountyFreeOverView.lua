---
--xcyy
--2018年5月23日
--BunnyBountyFreeOverView.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyFreeOverView = class("BunnyBountyFreeOverView",util_require("Levels.BaseLevelDialog"))


function BunnyBountyFreeOverView:initUI(params)
    self.m_machine = params.machine
    self.m_endFunc = params.endFunc
    self.m_keyFunc = params.keyFunc
    self.m_rootScale = params.scale
    local ownerlist = params.ownerlist--
    self:createCsbNode("BunnyBounty/FreeSpinOver.csb")

    local light = util_createAnimation("BunnyBounty_tanban_guang.csb")
    light:runCsbAction("idle",true)
    self:findChild("Node_guang"):addChild(light)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_guang"),true)

    self:findChild("Button_1"):setTouchEnabled(false)

    self:updateOwnerVar(ownerlist)

    --兔子
    self.m_spine = util_spineCreate("BunnyBounty_juese",true,true)
    self:findChild("spine"):addChild(self.m_spine)

    self:findChild("root"):setScale(self.m_rootScale)

    local node= self:findChild("m_lb_coins")
    self:updateLabelSize({label=node,sx=1,sy=1},666)

    

    self:showView()
end


--[[
    显示界面
]]
function BunnyBountyFreeOverView:showView(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_show_free_over)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        self:findChild("Button_1"):setTouchEnabled(true)
        if type(func) == "function" then
            func()
        end
    end)

    util_spinePlay(self.m_spine,"tanban3_start")
    util_spineEndCallFunc(self.m_spine,"tanban3_start",function()
        util_spinePlay(self.m_spine,"tanban3_idle",true)
    end)
end

--默认按钮监听回调
function BunnyBountyFreeOverView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    self:findChild("Button_1"):setTouchEnabled(false)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_btn_click)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_change_scene_to_base_from_free)
    self.m_machine:changeSceneToFree(function()
        self:showOver()
        if type(self.m_keyFunc) == "function" then
            self.m_keyFunc()
        end
    end,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        self:removeFromParent()
    end)

    
end

--[[
    结束动画
]]
function BunnyBountyFreeOverView:showOver(func)
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        
    end)
    util_spinePlay(self.m_spine,"tanban3_over")
end


return BunnyBountyFreeOverView