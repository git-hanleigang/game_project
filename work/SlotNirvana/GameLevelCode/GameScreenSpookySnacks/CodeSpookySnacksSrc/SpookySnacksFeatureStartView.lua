---
--xcyy
--2018年5月23日
--SpookySnacksFeatureStartView.lua
local PublicConfig = require "SpookySnacksPublicConfig"
local SpookySnacksFeatureStartView = class("SpookySnacksFeatureStartView",util_require("Levels.BaseLevelDialog"))


function SpookySnacksFeatureStartView:initUI(params)

    self:createCsbNode("SpookySnacks/FreeSpinStart.csb")
    self.featureType = params.featureType
    self.m_machine = params.machine
    self.featureNum = params.num
    self.endFunc = params.func
    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    local spineName = self:getSpineNameForType()
    self.tanban_spine = util_spineCreate(spineName, true, true)
    self:findChild("Node_start"):addChild(self.tanban_spine)

    self:addNumCsbForView()
    
    if self.featureType == "free" then
        self:showFreeStartView()
    elseif self.featureType == "respin" then
        return "Socre_SpookySnacks_Scatter"
    elseif self.featureType == "freeMore" then
        self:showFreeMoreView()
    end
    
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function SpookySnacksFeatureStartView:initSpineUI()
    
end

function SpookySnacksFeatureStartView:getSpineNameForType()
    if self.featureType == "free" then
        return "Socre_SpookySnacks_Scatter"
    elseif self.featureType == "respin" then
        return "Socre_SpookySnacks_Scatter"
    elseif self.featureType == "freeMore" then
        return "Socre_SpookySnacks_Scatter"
    end
end

function SpookySnacksFeatureStartView:showFreeStartView()
    local startName = "start_tanban"
    local idleName = "idle_tanban"
    local overName = "over_tanban"

    local startTime = self.tanban_spine:getAnimationDurationTime(startName)
    local idleTime = self.tanban_spine:getAnimationDurationTime(idleName)
    local overTime = self.tanban_spine:getAnimationDurationTime(overName)
    local node = cc.Node:create()
    self:addChild(node)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_freeSpinStart_start)
    end)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.tanban_spine,startName,false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(startTime)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.tanban_spine,idleName,false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(idleTime)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_freeSpinStart_over)
    end)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.tanban_spine,overName,false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(overTime)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        if self.endFunc then
            self.endFunc()
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actList))
end

function SpookySnacksFeatureStartView:showFreeMoreView()
    local autoName = "auto_tanban2"
    -- local overName = "over_tanban2"
    local autoTime = self.tanban_spine:getAnimationDurationTime(autoName)
    -- local overTime = self.tanban_spine:getAnimationDurationTime(overName)
    local node = cc.Node:create()
    self:addChild(node)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_freeSpinStart_More)
        util_spinePlay(self.tanban_spine,autoName,false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(autoTime)
    -- actList[#actList + 1] = cc.CallFunc:create(function ()
    --     util_spinePlay(self.tanban_spine,overName,false)
    -- end)
    -- actList[#actList + 1] = cc.DelayTime:create(overTime)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        if self.endFunc then
            self.endFunc()
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actList))
end

function SpookySnacksFeatureStartView:addNumCsbForView()
    local numView = util_createAnimation("SpookySnacks_morezi.csb")
    numView:findChild("m_lb_num"):setString(tonumber(self.featureNum))
    util_spinePushBindNode(self.tanban_spine,"zi_guadian",numView)
    self.tanban_spine.m_bindCsbNode = numView
end

return SpookySnacksFeatureStartView