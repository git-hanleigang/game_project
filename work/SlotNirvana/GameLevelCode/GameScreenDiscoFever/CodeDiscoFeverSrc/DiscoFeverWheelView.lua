---
--xcyy
--2018年5月23日
--DiscoFeverWheelView.lua

local DiscoFeverWheelView = class("DiscoFeverWheelView",util_require("base.BaseView"))
DiscoFeverWheelView.m_wheelSumIndex = 12
DiscoFeverWheelView.m_wheel = nil
DiscoFeverWheelView.m_callFunc = nil
DiscoFeverWheelView.m_endIndex = nil
DiscoFeverWheelView.m_wheelData = nil
DiscoFeverWheelView.m_machine = nil

function DiscoFeverWheelView:initUI(data)

    self:createCsbNode("DiscoFever_wheel.csb")

    self.m_wheel = require("CodeDiscoFeverSrc.DiscoFeverWheelAction"):create(self:findChild("wheel"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
     self:addChild(self.m_wheel)

    self:setWheelRotModel( )

    self.m_endIndex =  (data.m_endIndex + 1) 
    self.m_wheelData = data.m_wheelData 
    self.m_wheelDataExtra = data.m_wheelDataExtra 
    self.m_betlevel = data.m_betlevel 
    self.m_machine = data.m_machine

    -- points
    
    self.m_Points = util_createView("CodeDiscoFeverSrc.DiscoFeverPointsView")
    self:findChild("points"):addChild(self.m_Points)
    
    -- 按钮
    self.m_WheelBtn = util_createView("CodeDiscoFeverSrc.DiscoFeverWheelBtnView")
    self:findChild("btn_click"):addChild(self.m_WheelBtn)
    self.m_WheelBtn:runCsbAction("idle",true)

    local pro = (display.height / display.width) 
    if pro > 2 then
        self.m_Points:setPositionY(self.m_Points:getPositionY() + 50) 
        self.m_WheelBtn:setPositionY(self.m_WheelBtn:getPositionY() - 50) 
    end
    

    -- 中奖 (花边)
    self.m_EndWin_1 = util_createView("CodeDiscoFeverSrc.DiscoFeverEndWin_1_View")
    self:findChild("end_win_ani_1"):addChild(self.m_EndWin_1)
    self.m_EndWin_1:setVisible(false)
    -- 中奖 (圆边)
    self.m_EndWin_2 = util_createView("CodeDiscoFeverSrc.DiscoFeverEndWin_2_View")
    self:findChild("end_win_ani_2"):addChild(self.m_EndWin_2)
    self.m_EndWin_2:setVisible(false)

    -- 修改轮盘数据显示
    self:initWheelLable()
    
    -- 开启触摸监听
    self:setTouchLayer()

    self:findChild("Node_scatter"):setScale(1.5)
    self.m_scatter = util_spineCreate("Socre_DiscoFever_Scatter",true,true)
    self:findChild("Node_scatter"):addChild(self.m_scatter)
    util_spinePlay(self.m_scatter,"idleframe2",false)
    

end

function DiscoFeverWheelView:initWheelLable( )
    for k,v in pairs(self.m_wheelData) do
        local num = v
        local nodeName= "Node_"..k
        local Node = self:findChild(nodeName)
        local name = "DiscoFever_wheel_bar1"
        if k %2 == 0 then
            name = "DiscoFever_wheel_bar2"
        end
        local littleView = util_createView("CodeDiscoFeverSrc.DiscoFeverWheelLittleNodeView",name) 
        Node:addChild(littleView)
        local lab = littleView:findChild("BitmapFontLabel_13")
        if lab then
            lab:setString(num)
        end

        local id ,num = self:getActiId(k)
        if self.m_betlevel == 0 then
            littleView:runCsbAction("bar4")
        else
            if id == 1 then
                local txt = littleView:findChild("BitmapFontLabel_13_0")
                if txt and num then
                    txt:setString(num)
                end
            end

            littleView:runCsbAction("bar"..id)

        end
        
    end
end


function DiscoFeverWheelView:CheckActionType(data)
    
    local id = 4
    local num = nil
    local v = data

    if v.type == "wild" then
        id = 1
        num = v.num

    elseif v.type == "levelUp" then
        if v.num == 1 then
            id = 2
        elseif v.num == 2 then
            id = 3
        end
        
    elseif  v.type == "blank" then 
        id = 4
    end


    return id,num
end


function DiscoFeverWheelView:getActiId( index )
    local id = 4
    local num = nil

    for k,v in pairs(self.m_wheelDataExtra) do
        if index == k then
            id , num = self:CheckActionType(v)
            return id,num
        end
    end


    return id,num
end


function DiscoFeverWheelView:onEnter()
 
    
end


function DiscoFeverWheelView:onExit()
 
end

function DiscoFeverWheelView:setTouchLayer()
    local function onTouchBegan_callback(touch, event)
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        self:clickFunc()
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved_callback,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded_callback,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()    
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function DiscoFeverWheelView:clickFunc()
    if self.m_bIsTouched == true then
        return
    end
    gLobalSoundManager:playSound("DiscoFeverSounds/sound_DiscoFever_click_wheel.mp3")
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouched = true

    -- util_spinePlay(self.m_scatter,"idleframe3",true)

    self.m_WheelBtn:runCsbAction("actionframe")

    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    self:beginWheelAction()

end

function DiscoFeverWheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 50 --加速度
    wheelData.m_runV = 350--匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 100 --动态减速度
    wheelData.m_slowQ = 2 --减速圈数
    wheelData.m_stopV = 50 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel(false)
    self.m_wheel:recvData(self.m_endIndex)

    
end

function DiscoFeverWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()

        if self.m_machine then
            self.m_machine:clearCurMusicBg()
        end
        

        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_wheel_zhognjaing.mp3")

        self.m_Points:runCsbAction("actionframe",true)
        
        if self.m_endIndex % 2 ~= 0 then
            self.m_EndWin_1:setVisible(true)
            self.m_EndWin_1:runCsbAction("actionframe1",true)
        else
            self.m_EndWin_2:setVisible(true)
            self.m_EndWin_2:runCsbAction("actionframe1",true)
        end

        util_spinePlay(self.m_scatter,"idleframe2",false)

        performWithDelay(self,function(  )
            callBackFun()
        end,3)
        

    end
end

function DiscoFeverWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function DiscoFeverWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = (distance / targetStep) + 0.5
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
    --     -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_wheel_run.mp3")
        
        -- gLobalSoundManager:playSound("DiscoFeverSounds/sound_DiscoFever_wheel_rptate.mp3")       
    end
end

return DiscoFeverWheelView