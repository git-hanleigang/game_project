---
--xcyy
--2018年5月23日
--BeatlesModeItem.lua

--一些行为是通过事件驱动，一些没有 原因:后面一些需求来回变 就没有添加相关的事件
local BeatlesModeItem = class("BeatlesModeItem",util_require("base.BaseView"))
local BeatlesBaseData = require "CodeBeatlesSrc.BeatlesBaseData"

local mode_csb = {
    "Beatles_ui_Multiplier.csb",
    "Beatles_ui_ExtraLines.csb",
    "Beatles_ui_SymbolReplaced.csb",
    "Beatles_ui_WildReels.csb",
    "Beatles_ui_WildsAdded.csb",
}

-- local mode_juese = {
--     {},
--     {}
-- }

function BeatlesModeItem:initUI(index)
    self.m_index = index
    self.m_num = 0
    self:createCsbNode(mode_csb[index])
    self.m_role = util_spineCreate("BeatleBeat_juese_"..index, true, true)
    self:findChild("juese"):addChild(self.m_role)
    self.m_light = util_createAnimation("Beatles_HighLights2.csb")
    self:findChild("Node_hightlights"):addChild(self.m_light)
    self.m_light:setVisible(false)
    self.m_light.m_state = 2 --主要用于重复开启灯光的问题
    -- local ratio = display.height/display.width
    -- if  ratio < 768/1024 then
    --     self.m_light:findChild("Particle_1"):setPositionY(215)
    -- end
    self:playerRoleIdle()
end


function BeatlesModeItem:onEnter()
    self:addObservers()
end

function BeatlesModeItem:addObservers()
    gLobalNoticManager:addObserver(self,function(self,params)  --设置或者初始化num
        self:resetCount()
    end,"MODEITEMNUM_BEATLES")

    gLobalNoticManager:addObserver(self,function(self,params)  --设置num的显示状态
        self:setNumbarVisible(params)
    end,"MODEITEMNUM_NUMBAR")  

    gLobalNoticManager:addObserver(self,function(self,params)  --设置灯光
        self:showLight(false)
    end,"MODEITELIGHT_BEATLES")

    gLobalNoticManager:addObserver(self,function(self,params)  --bouns收集快停需要用到
        self:updataCountByBouns()
    end,"MODEIBOUNS_BEATLES")

    local obser_key = "MODEITEMUPDATA_BEATLES_"..self.m_index
    gLobalNoticManager:addObserver(self,function(self,params)  --更新num
        self:updataCount()
    end,obser_key)

    local obser_key4 = "MODEITEMUPDATA_BEATLES_SUB_"..self.m_index
    gLobalNoticManager:addObserver(self,function(self,params)  --更新num --
        self:updataCountSub(params)
    end,obser_key4)

    local obser_key2 = "MODEITEMNUM_BEATLES_"..self.m_index
    gLobalNoticManager:addObserver(self,function(self,params)  --设置或者初始化num
        self:resetCount()
    end,obser_key2)

    local obser_key3 = "MODEITEMTIP_BEATLES_"..self.m_index
    gLobalNoticManager:addObserver(self,function(self,params)  --提示
        self:showRoleTip()
    end,obser_key3)
end

function BeatlesModeItem:showAdd()
    
end
function BeatlesModeItem:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

--默认按钮监听回调
function BeatlesModeItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


function BeatlesModeItem:resetCount()
    local mode_data = BeatlesBaseData:getInstance():getDataByKey("modes")
    local num = mode_data[self.m_index] or 0
    self.m_num = num
    self:findChild("m_lb_num"):setString(tostring(num))
end

function BeatlesModeItem:updataCount(index)
    local spin_num = BeatlesBaseData:getInstance():getDataByKey("spin_num")
    local mode_data = BeatlesBaseData:getInstance():getDataByKey("modes")
    local num = mode_data[self.m_index] or 0
    
    if spin_num == 10 then -- base下快停 第十次的时候 不能在更新了
        return
    end
    if num == self.m_num then
        return
    end
    
    self.m_num = num
    self:findChild("m_lb_num"):setString(tostring(self.m_num))
    self:runCsbAction("actionframe")
end

function BeatlesModeItem:updataCountSub(isEnd)
    self.m_num  = self.m_num - 1
    local mode_data = BeatlesBaseData:getInstance():getDataByKey("modes")
    local num = mode_data[self.m_index] or 0
    self.m_num = math.max(num, self.m_num)
    if isEnd then
        self.m_num = num
    end
    self:findChild("m_lb_num"):setString(tostring(self.m_num))
    self:runCsbAction("actionframe2")

end

function BeatlesModeItem:getNumWorldPos()
    local worldPos = self:findChild("m_lb_num"):getParent():convertToWorldSpace( cc.p(self:findChild("m_lb_num"):getPosition()))
    return worldPos
end

-- levevs表示free玩法里面 商店进入的需要显示次数
function BeatlesModeItem:setNumbarVisible(params)
    if params.levels then
        self:findChild("m_lb_num"):setString(tostring(params.levels[tonumber(self.m_index)+1]))
        self:findChild("collect"):setVisible(true)
    else
        if params.active then
            self:resetCount()
            self:runCsbAction("actionframe4")
        else
            self:runCsbAction("idle")
        end
        self:findChild("collect"):setVisible(params.active)
    end
    
end

--角色常态spineAni
function BeatlesModeItem:playerRoleIdle()

    self:showFreeIdle()
end

function BeatlesModeItem:showLight(isMustShow)
    local mode_data = BeatlesBaseData:getInstance():getDataByKey("modes")
    local num = mode_data[self.m_index] or 0
    if (isMustShow == false and num <= 0) or  self.m_light.m_state == 1 then
        return
    end
    self.m_light:setVisible(true)
    self.m_light:playAction("start", false,function()
        self.m_light:playAction("idle2", true)
        self.m_light.m_state = 1
    end)
    
end

function BeatlesModeItem:hideLight()
    if self.m_light.m_state ~= 2 then
        self.m_light:playAction("over", false, function()
            self.m_light:setVisible(false)
            self.m_light.m_state = 2
        end, 60)
    end
end

function BeatlesModeItem:showRoleTip()
    self.m_role:stopAllActions()
    local ani_str = "actionframe"

    util_spinePlay(self.m_role, ani_str, false)
    util_spineEndCallFunc(
        self.m_role,
        ani_str,
        function()
            self:showRoleLightIdle()        
        end
    )
end

function BeatlesModeItem:showFreeIdle()  --现在与playerRoleIdle方法一样是因为需求变更导致
    -- self.m_role:stopAllActions()
    local random = math.random(1,10)
    local idleName = "idleframe"
    if random <= 8 then
        idleName = "idleframe2"
    end
    if self.m_index == 2 or self.m_index == 3 then
        idleName = "idleframe"
    end
    util_spinePlay(self.m_role, idleName, false)
    util_spineEndCallFunc(
        self.m_role,
        idleName,
        function()
           self:showFreeIdle()
        end
    )
end


function BeatlesModeItem:showRoleLightIdle()
    -- self.m_role:stopAllActions()
    util_spinePlay(self.m_role, "idleframe3", true)
end

--获取次数
function BeatlesModeItem:getFeatureNum()
    return self.m_num
end

--取消spine监听
function BeatlesModeItem:unregisterSpineEvent()
    self.m_role:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
    self.m_role:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
end

function BeatlesModeItem:playRoleVoice()
    local randomId = math.random(1,4)
    local sound_voice = string.format("BeatlesSounds/Sound_Beatles_role%d_voice%d.mp3", self.m_index, randomId)
    gLobalSoundManager:playSound(sound_voice)
end

function BeatlesModeItem:updataCountByBouns(index)
    local spin_num = BeatlesBaseData:getInstance():getDataByKey("spin_num")
    local mode_data = BeatlesBaseData:getInstance():getDataByKey("modes")
    local num = mode_data[self.m_index] or 0
    if num == self.m_num then
        return
    end
    if spin_num == 10 then-- base下快停 第十次的时候 不能在更新了
        return
    end
    self.m_num = num
    self:findChild("m_lb_num"):setString(tostring(self.m_num))
    self:runCsbAction("actionframe3")
end

return BeatlesModeItem