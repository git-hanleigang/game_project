---
--xcyy
--2018年5月23日
--ClawStallMapView.lua
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallMapView = class("ClawStallMapView",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_LEFT          =       1001    
local BTN_TAG_RIGHT         =       1002   

function ClawStallMapView:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("ClawStall_Map.csb")

    local contentLayer = util_createView("CodeClawStallSrc.ClawStallMapContentLayer",{machine = self.m_machine,parent = self})
    self:findChild("Node_drag"):addChild(contentLayer)
    local mapLayer = util_createView("CodeClawStallSrc.ClawStallMapLayer", self:findChild("Node_drag"), cc.p(0,0))
    self.m_mapLayer = mapLayer
    self.m_contentLayer = contentLayer

    self:findChild("Button_left"):setTag(BTN_TAG_LEFT)
    self:findChild("Button_right"):setTag(BTN_TAG_RIGHT)
end

--[[
    加载地图内容
]]
function ClawStallMapView:loadMapContent()
    local maxMoveLen = self.m_contentLayer:loadData()
    self.m_mapLayer:setMoveLen(-maxMoveLen)

    local posIndex = self.m_machine.m_collectProcess.pos
    self:resetPlayerPos(posIndex)
end

--[[
    重置玩家位置
]]
function ClawStallMapView:resetPlayerPos(posIndex)
    local pos,moveDistance = self.m_contentLayer:getPlayerPos(posIndex)
    --设置当前玩家位置
    self.m_contentLayer:setPlayerPos(pos,posIndex)
    --移动地图
    self.m_mapLayer:move(-moveDistance)

end

--[[
    移动玩家动画
]]
function ClawStallMapView:movePlayerAni(func)
    local posIndex = self.m_machine.m_collectProcess.pos or 0
    if posIndex == 0 then
        posIndex = #self.m_machine.m_mapList
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_move_player)
    self.m_contentLayer:movePlayer(posIndex - 1,posIndex,function(  )
        if type(func) == "function" then
            func()
        end
    end)
end

--默认按钮监听回调
function ClawStallMapView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if tag == BTN_TAG_LEFT then --左翻页
        local curDistance = self.m_mapLayer.contentPosition_x
        curDistance = curDistance + 800
        --移动地图
        self.m_mapLayer:move(curDistance,0.3)
    elseif tag == BTN_TAG_RIGHT then --右翻页
        local curDistance = self.m_mapLayer.contentPosition_x
        curDistance = curDistance - 800
        --移动地图
        self.m_mapLayer:move(curDistance,0.3)
    end
end

--[[
    显示界面
]]
function ClawStallMapView:showView(canTouchMove,func)
    self.m_machine.m_reelLayOut:setClippingEnabled(true)
    self.m_mapLayer:setMoveEnabled(canTouchMove)
    self:findChild("Node_btn"):setVisible(canTouchMove)
    self:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_map)
    self:runCsbAction("start",false,function(  )
        if type(func) == "function" then
            func()
        end
    end)
    
    -- self.m_contentLayer:refreshView()
end

--[[
    隐藏界面
]]
function ClawStallMapView:hideView(func)
    self.m_machine.m_reelLayOut:setClippingEnabled(false)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_hide_map)
    self:runCsbAction("over",false,function(  )
        self:setVisible(false)
        self.m_contentLayer:refreshView()

        --刷新地图位置
        local posIndex = self.m_machine.m_collectProcess.pos
        self:resetPlayerPos(posIndex)
        if type(func) == "function" then
            func()
        end
    end)
    
end
return ClawStallMapView