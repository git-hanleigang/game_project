---
--xcyy
--2018年5月23日
--JollyFactoryFreeMultiBar.lua
local PublicConfig = require "JollyFactoryPublicConfig"
local JollyFactoryFreeMultiBar = class("JollyFactoryFreeMultiBar",util_require("Levels.BaseLevelDialog"))

local OFFSET_Y      =       50
local OFFSET_X      =       50


function JollyFactoryFreeMultiBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("JollyFactory_Free_tizi.csb")

    self.m_multiLbls = {}
    for index = 1,25 do
        local item = util_createAnimation("JollyFactory_Free_tizi_xiaoban.csb")
        local node = self:findChild("Node_multi_"..(index - 1))
        local pos = util_convertToNodeSpace(node,self)
        self:addChild(item)
        item:setLocalZOrder(index)
        item:setPosition(pos)
        if index > 8 and index <= 16 then
            item:findChild("Node_1"):setVisible(false)
            item:findChild("Node_2"):setVisible(true)
            item:findChild("Node_3"):setVisible(false)
        elseif index == 25 then
            item:findChild("Node_1"):setVisible(false)
            item:findChild("Node_2"):setVisible(false)
            item:findChild("Node_3"):setVisible(true)
        else
            item:findChild("Node_1"):setVisible(true)
            item:findChild("Node_2"):setVisible(false)
            item:findChild("Node_3"):setVisible(false)
        end
        item:findChild("m_lb_num_1_1"):setString(index.."X")
        item:findChild("m_lb_num_1_2"):setString(index.."X")
        item:findChild("m_lb_num_2_1"):setString(index.."X")
        item:findChild("m_lb_num_2_2"):setString(index.."X")

        self:updateLabelSize({label=item:findChild("m_lb_num_1_1"),sx=1,sy=1},90) 
        self:updateLabelSize({label=item:findChild("m_lb_num_1_2"),sx=1,sy=1},90) 
        self:updateLabelSize({label=item:findChild("m_lb_num_2_1"),sx=1,sy=1},90) 
        self:updateLabelSize({label=item:findChild("m_lb_num_2_2"),sx=1,sy=1},90) 

        item:findChild("chupeng_1"):setVisible(false)
        item:findChild("chupeng_2"):setVisible(false)
        item:findChild("chupeng_3"):setVisible(false)

        self.m_multiLbls[index] = item
    end

    self.m_curIndex = 1
    
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function JollyFactoryFreeMultiBar:initSpineUI()
    self.m_role_node = util_spineCreate("JollyFactory_juese",true,true)
    self:addChild(self.m_role_node)
    self.m_role_node:setLocalZOrder(200)
    self:runRoleIdle()

    self.m_box_spine = util_spineCreate("JollyFactory_Free_liwuhe",true,true)
    self:findChild("Node_Free_liwuhe"):addChild(self.m_box_spine)
    util_spinePlay(self.m_box_spine,'actionframe_guochang_idle')
    self.m_box_spine:setVisible(false)
end

function JollyFactoryFreeMultiBar:setBoxVisible(isShow)
    self.m_box_spine:setVisible(isShow)
end

--[[
    idle
]]
function JollyFactoryFreeMultiBar:runRoleIdle()
    if self.m_isIdle then
        return
    end
    self.m_isIdle = true
    util_spinePlay(self.m_role_node,"idle",true)
end

--[[
    跳
]]
function JollyFactoryFreeMultiBar:runJumpAni(endIndex,func)
    self:jumpToNextPos(self.m_curIndex + 1,endIndex,function()
        local curItem = self.m_multiLbls[endIndex]
        curItem:setLocalZOrder(100)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_tizi_multi"])
        curItem:runCsbAction("actionframe",false,function()
            curItem:setLocalZOrder(endIndex)
        end)
        
        self.m_machine:delayCallBack(80 / 60,function()
            

            if endIndex == 25 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_max_multi"])
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_get_max_multi"])
                self.m_machine:showLastSpinAni(function()
                    if type(func) == "function" then
                        func()
                    end
                end)
                self.m_machine:delayCallBack(2,function()
                    util_spinePlay(self.m_box_spine,'actionframe_guochang_idle2',true)
                end)
            else
                local startNode = curItem:findChild("m_lb_num_1_2")
                if endIndex > 8 and endIndex <= 16 then
                    startNode = curItem:findChild("m_lb_num_2_2")
                end
                self.m_machine:flyMultiAni(endIndex,startNode,function()
                    if type(func) == "function" then
                        func()
                    end
                end)
            end
            
            
        end)
        
    end)
end

function JollyFactoryFreeMultiBar:jumpToNextPos(nextIndex,endIndex,func)
    if nextIndex > endIndex then
        
        if type(func) == "function" then
            func()
        end
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_jump"])
    self.m_isIdle = false
    util_spinePlay(self.m_role_node,"jump")
    util_spineEndCallFunc(self.m_role_node,"jump",function()
        self:runRoleIdle()
        local callBack = function()
            self:jumpToNextPos(nextIndex + 1,endIndex,func)
        end
        
        if (nextIndex % 6) == 0 then
            self:moveDownAni(function()
                callBack()
            end)
        else
            callBack()
        end
        
    end)
    self.m_machine:delayCallBack(12 / 30,function()
        self:updateCurMultiShow(nextIndex)
    end)
    local posNode = self:findChild("Node_"..(nextIndex - 1))
    local pos = util_convertToNodeSpace(posNode,self)
    local actionList = {
        cc.DelayTime:create(2 / 30),
        cc.EaseSineInOut:create(cc.MoveTo:create(10 / 30,pos)) 
    }
    self.m_role_node:runAction(cc.Sequence:create(actionList))
    self.m_curIndex = nextIndex
end

--[[
    梯子下移
]]
function JollyFactoryFreeMultiBar:moveDownAni(func)
    local pos = self:getOffsetPos()
    local actionList = {
        cc.MoveTo:create(0.5,pos),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end)
    }

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_tizi_move_down"])
    self:runAction(cc.Sequence:create(actionList))
end

--[[
    重置界面
]]
function JollyFactoryFreeMultiBar:resetView(curIndex)
    self.m_curIndex = curIndex
    self:runRoleIdle()

    util_spinePlay(self.m_box_spine,'actionframe_guochang_idle')

    local posNode = self:findChild("Node_"..(curIndex - 1))
    self.m_role_node:setPosition(util_convertToNodeSpace(posNode,self))



    local pos = self:getOffsetPos()

    self:setPosition(pos)
    self:updateCurMultiShow(curIndex)
end

--[[
    获取偏移位置
]]
function JollyFactoryFreeMultiBar:getOffsetPos()
    local count = math.floor(self.m_curIndex / 6)
    local offset = 0
    if count > 0 then
        offset = (count - 1) * 30
    end
    
    local offsetY = OFFSET_Y * 6 * count + offset
    local offsetX = OFFSET_X * 6 * count
    if self.m_curIndex >= 6 and self.m_curIndex < 12 then
        offsetX  = -250
    elseif self.m_curIndex >= 12 and self.m_curIndex < 18 then
        offsetX  = 80
    elseif self.m_curIndex >= 18 and self.m_curIndex < 24 then
        offsetX  = -120
    elseif self.m_curIndex >= 24 then
        offsetX = -330
    else 
        offsetX = 0
    end

    return cc.p(offsetX,-offsetY)
end

--[[
    刷新当前位置倍数显示
]]
function JollyFactoryFreeMultiBar:updateCurMultiShow(curIndex)
    for index = 1,24 do
        local item = self.m_multiLbls[index]
        

        item:findChild("chupeng_1"):setVisible(false)
        item:findChild("chupeng_2"):setVisible(false)

        if index == curIndex then
            if index > 8 and index <= 16 then
                item:findChild("chupeng_2"):setVisible(true)
            else
                item:findChild("chupeng_1"):setVisible(true)
            end
        end
        
    end


    local item = self.m_multiLbls[#self.m_multiLbls]
    item:findChild("chupeng_3"):setVisible(curIndex == 25)
end



return JollyFactoryFreeMultiBar