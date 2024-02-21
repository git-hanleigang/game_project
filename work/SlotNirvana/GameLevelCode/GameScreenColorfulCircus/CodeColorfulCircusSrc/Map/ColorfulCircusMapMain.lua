
local ColorfulCircusMapMain = class("ColorfulCircusMapMain",util_require("Levels.BaseLevelDialog"))

local STAGE_NUM = 20
local JUMPNODE_ADD_POSY = 0
function ColorfulCircusMapMain:initUI(_machine, data, pos)
    self.m_bIsShow = false
    self.m_bMapCanTouch = true
    self.m_currPos = pos

    self.m_bIsCanBack = false

    self.m_machine = _machine
    self.m_mapInfo = data
    self:createCsbNode("ColorfulCircus/MapColorfulCircus.csb")
    
    self.m_items = {}
    self.m_beginAnimIdx = 1
    self:initMap()

    self.m_nodeSignal = cc.Node:create()
    self:findChild("Node_9"):addChild(self.m_nodeSignal, 28)
    
    self.m_signal = util_createAnimation("ColorfulCircus_map_jiantou.csb")
    self.m_nodeSignal:addChild(self.m_signal)
    --箭头spine
    self.m_signalSpine = util_spineCreate("ColorfulCircus_map_jiantou",true,true)
    self.m_signal:findChild("spine_node"):addChild(self.m_signalSpine)
    util_spinePlay(self.m_signalSpine,"idleframe",true)

    if pos == 0 then
        self:setArrowInitPos(  )
    else
        local node = self:findChild("Node_map_".. pos)
        local endPos = cc.p(util_getConvertNodePos(node,self.m_nodeSignal))
        if data[pos] and data[pos].type == "BIG" then
            self.m_nodeSignal:setPosition(endPos.x, endPos.y + JUMPNODE_ADD_POSY)
        else
            self.m_nodeSignal:setPosition(endPos.x, endPos.y)
        end
    end
    util_setCascadeOpacityEnabledRescursion(self, true)

    for i=1,20 do
        self:findChild("Node_map_".. i):setLocalZOrder(i)
    end
    self:findChild("Button_1"):setLocalZOrder(30)
end

function ColorfulCircusMapMain:setNodeOrder(idx, order)
    for i=1,20 do
        if i == idx then
            self:findChild("Node_map_".. i):setLocalZOrder(order)
        end
    end
end

function ColorfulCircusMapMain:setArrowInitPos(  )
    local node = self:findChild("Node_map_0")
    local endPos = cc.p(util_getConvertNodePos(node,self.m_nodeSignal))
    self.m_nodeSignal:setPosition(endPos.x, endPos.y)
end

function ColorfulCircusMapMain:resetMapPos( pos )
    self.m_currPos = pos

    self:setArrowInitPos(  )
end

function ColorfulCircusMapMain:initMap()
    for i=1,STAGE_NUM do
        local itemNode = self:findChild("Node_map_" .. i)
        local itemView = util_createView("CodeColorfulCircusSrc.Map.ColorfulCircusMapItem", self, i)
        itemNode:addChild(itemView, i)
        itemView:setPosition(cc.p(0, 0))
        self.m_items[i] = itemView

        if i <= self.m_currPos then
            self.m_items[i]:completed()
        else
            self.m_items[i]:idle()
        end
    end
end

function ColorfulCircusMapMain:updatePos(pos)
    self:vecNodeReset( pos ,self.m_mapInfo)

    -- local posY = self.m_mapLayer:getLevelPosY(pos)

    -- local size = self.m_machine.m_topPosY - self.m_machine.m_downPosY

    -- if  pos<= 4 and  math.abs(posY) < size then
    --     posY = 0
    -- else
    --     posY = - (math.abs(posY) - size + 720)
    -- end

    -- self.m_mapLayer:setPositionY( posY )

end

function ColorfulCircusMapMain:vecNodeReset( _pos,_data )


    for i = 1, #self.m_items, 1 do
        local item = self.m_items[i]
        if i <= _pos then
            item:completed()
        else
            item:idle()
        end
        
    end

    if _pos == 0 then
    else
        local node = self:findChild("Node_map_".._pos)
        local endPos = cc.p(util_getConvertNodePos(node,self.m_nodeSignal))
        if _data[_pos] and _data[_pos].type == "BIG" then
            self.m_nodeSignal:setPosition(endPos.x, endPos.y + JUMPNODE_ADD_POSY)
        else
            self.m_nodeSignal:setPosition(endPos.x, endPos.y)
        end
    end

    
end

--默认按钮监听回调
function ColorfulCircusMapMain:clickFunc(_sender)
    local name = _sender:getName()
    local tag = _sender:getTag()

    if not self.m_bIsShow  then
        return
    end

    -- -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_map_move_left_right.mp3")

    -- local currPos = self:getCurrPos( )

    if name == "Button_1" and self.m_bIsCanBack then

        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")

        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end

    
end


function ColorfulCircusMapMain:mapAppear(func)

    -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_map_close_open.mp3")

    self.m_bIsShow = true
    self.m_bIsCanBack = false
    
    self:updatePos(self.m_currPos)
    self:setVisible(true)
    gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_show_map.mp3")


    for i=1,STAGE_NUM do
        if self.m_items[i] then
            self.m_items[i]:setVisible(false)
        end
    end
    self.m_signalSpine:setVisible(false)

    self:runCsbAction("start",false,function (  )
        self:runCsbAction("dainji_idle", true)
        -- if func ~= nil then
        --     func()
        -- end
    end)
    
    performWithDelay(self, function (  )
        self.m_beginAnimIdx = STAGE_NUM
        self:runBeginAnim(function (  )
            self.m_bIsCanBack = true
            if func ~= nil then
                func()
            end
        end)
        
    end, 8/60)    

end

function ColorfulCircusMapMain:runBeginAnim( _func )
    if self.m_items[self.m_beginAnimIdx] then
        self.m_items[self.m_beginAnimIdx]:setVisible(true)
        self.m_items[self.m_beginAnimIdx]:runBeginAnim(self.m_beginAnimIdx <= self.m_currPos)
        if self.m_currPos == self.m_beginAnimIdx then
            self.m_signalSpine:setVisible(true)
            util_spinePlay(self.m_signalSpine,"start",false)
            util_spineEndCallFunc(self.m_signalSpine, "start", function()
                util_spinePlay(self.m_signalSpine,"idleframe",true)
            end)
        end
        -- if self.m_beginAnimIdx <= self.m_currPos then
            -- if self.m_beginAnimIdx % 5 ~= 0 then
                -- if self.m_items[self.m_beginAnimIdx]:findChild("gou") then
                --     self.m_items[self.m_beginAnimIdx]:findChild("gou"):setVisible(true)
                -- end
            -- end
        -- end
        
        performWithDelay(self, function (  )
            self.m_beginAnimIdx = self.m_beginAnimIdx - 1
            if self.m_beginAnimIdx <= 0 then
                if self.m_currPos == 0 then
                    self.m_signalSpine:setVisible(true)
                    util_spinePlay(self.m_signalSpine,"start",false)
                    util_spineEndCallFunc(self.m_signalSpine, "start", function()
                        util_spinePlay(self.m_signalSpine,"idleframe",true)
                    end)
                end

                performWithDelay(self, function (  )
                    if _func then
                        _func()
                    end
                end, 20/30)     --延时个  箭头初始start的时间
                
            else
                self:runBeginAnim( _func )
            end
        end, 3/60)  
    end
end

function ColorfulCircusMapMain:mapDisappear(func)

    -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_map_close_open.mp3")
    

    self.m_bMapCanTouch = true
    self.m_bIsShow = false
    -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_hide_map.mp3")


    -- for i=1,STAGE_NUM do
    --     if self.m_items[i] then
    --         self.m_items[i]:overAnim()
    --     end
    -- end
    -- util_spinePlay(self.m_signalSpine,"over",true)

    self:runCsbAction("over",false,function (  )
        self:setVisible(false)
        if func ~= nil then
            func()
        end
    end)
end

function ColorfulCircusMapMain:signalMove(callBack, bonusData, pos,LitterGameWin)
    if pos < 1 then
        self.m_currPos = pos

        self.m_items[pos]:click(function()

            if callBack ~= nil then

                callBack()

            end
        end,LitterGameWin)

        self:vecNodeReset( pos ,self.m_mapInfo)
        return
    end

    local info = bonusData[pos]
    local node = self:findChild("Node_map_"..pos)
    local oldNode = self:findChild("Node_map_"..(pos - 1))
    local startPos = cc.p(util_getConvertNodePos(oldNode,self.m_nodeSignal))
    local endPos = cc.p(util_getConvertNodePos(node,self.m_nodeSignal))
    local actList = {}
    

    actList[#actList + 1] = cc.CallFunc:create(function()
        util_spinePlay(self.m_signalSpine,"actionframe",false)
        util_spineEndCallFunc(self.m_signalSpine, "actionframe", function()
            util_spinePlay(self.m_signalSpine,"idleframe",true)
        end)
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_collect_move.mp3")
    end)
    actList[#actList + 1] = cc.DelayTime:create(7/30)

    local nodeMove = cc.MoveTo:create(8/30,endPos)

    actList[#actList + 1] = nodeMove

    actList[#actList + 1] = cc.CallFunc:create(function()

        -- self.m_signal:runCsbAction("idle",true)
        -- util_spinePlay(self.m_signalSpine,"actionframe",false)
        -- util_spineEndCallFunc(self.m_signalSpine, "actionframe", function()
        --     util_spinePlay(self.m_signalSpine,"idleframe",true)
        -- end)

        self.m_currPos = pos

        self.m_items[pos]:click(function()

            if callBack ~= nil then

                callBack()

            end
        end,LitterGameWin)

    end)

    self.m_nodeSignal:runAction(cc.Sequence:create(actList))


end



function ColorfulCircusMapMain:onEnter()
    ColorfulCircusMapMain.super.onEnter(self)
end

function ColorfulCircusMapMain:onExit()
    ColorfulCircusMapMain.super.onExit(self)
end

function ColorfulCircusMapMain:getMapIsShow()
    return self.m_bIsShow
end

function ColorfulCircusMapMain:getMapCanTouch()
    return self.m_bMapCanTouch
end

function ColorfulCircusMapMain:setMapCanTouch(touch)
    self.m_bMapCanTouch = touch
end

return ColorfulCircusMapMain