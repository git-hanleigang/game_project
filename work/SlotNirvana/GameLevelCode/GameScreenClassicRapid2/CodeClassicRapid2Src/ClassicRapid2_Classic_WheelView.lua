---
--xcyy
--2018年5月23日
--ClassicRapid2_Classic_WheelView.lua

local ClassicRapid2_Classic_WheelView = class("ClassicRapid2_Classic_WheelView",util_require("base.BaseView"))
ClassicRapid2_Classic_WheelView.m_wheelSumIndex = 20
ClassicRapid2_Classic_WheelView.m_wheel = nil
ClassicRapid2_Classic_WheelView.m_callFunc = nil
ClassicRapid2_Classic_WheelView.m_endIndex = nil
ClassicRapid2_Classic_WheelView.m_wheelData = nil

function ClassicRapid2_Classic_WheelView:initUI()

    self:createCsbNode("ClassicRapid2_Wheel.csb")

    self.m_wheel = require("CodeClassicRapid2Src.ClassicRapid2_Classic_WheelAction"):create(self:findChild("wheel"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
    end,function(distance,targetStep,isBack)
         -- 滚动实时调用
    end)
    self:addChild(self.m_wheel)

    self.m_selectEff = util_createAnimation("ClassicRapid2_Wheel_zhongjiang.csb")
    self:findChild("Node_Select"):addChild(self.m_selectEff)
    self.m_selectEff:setVisible(false)

    self:setWheelRotModel( )

    -- self.m_wheelData = data
    -- self.m_betlevel = betlevel

    -- 修改轮盘数据显示
    -- self:initWheelLable(data)

    -- self:runCsbAction("idleframe",true,nil,20)
    -- 开启触摸监听
    -- self:setTouchLayer()
end
-- function ClassicRapid2_Classic_WheelView:playActionFrame()
--     self:runCsbAction("actionframe",false,function()
--         self:runCsbAction("idleframe",true,nil,20)
--     end,20)
-- end

function ClassicRapid2_Classic_WheelView:setRunWheelData(endIndex)
    self.m_endIndex =  endIndex
end


function ClassicRapid2_Classic_WheelView:initWheelLable(wheelData)
    if self.m_wheelNode == nil then
        self.m_wheelNode = {}
        for i=1,#wheelData do
            local name = "ClassicRapid2_Wheel_text"
            if wheelData[i] == "jackpot" then
                name = "ClassicRapid2_Wheel_text1"
            end
            local nodeName= "wheel_text_"..i
            local Node = self:findChild(nodeName)
            self.m_wheelNode[i] = util_createView("CodeClassicRapid2Src.ClassicRapid2_Classic_WheelNodeView",name)
            Node:addChild(self.m_wheelNode[i])
        end

    end
    for i=1,#wheelData do
        local littleView = self.m_wheelNode[i]
        if wheelData[i] and wheelData[i] ~= "jackpot" then
            local str = util_formatCoins(tonumber(wheelData[i]),5)
            local coinsTab = self:ChangeStringToTable(str)
            littleView:setlabString(coinsTab)
        end
    end

    -- for k,v in pairs(wheelData) do
    --     local num = v


    --     local littleView = util_createView("CodeClassicRapid2Src.ClassicRapid2_Classic_WheelNodeView",name)
    --     Node:addChild(littleView)
    --     if num and num ~= "jackpot" then
    --         local str = util_formatCoins(tonumber(num),5)
    --         local coinsTab = self:ChangeStringToTable(str)

    --     end
    -- end
    -- for k,v in pairs(wheelData) do
    --     local num = v
    --     local nodeName= "wheel_text_"..k
    --     local Node = self:findChild(nodeName)
    --     local name = "ClassicRapid2_Wheel_text"
    --     if num == "jackpot" then
    --         name = "ClassicRapid2_Wheel_text1"
    --     end
    --     local littleView = util_createView("CodeClassicRapid2Src.ClassicRapid2_Classic_WheelNodeView",name)
    --     Node:addChild(littleView)
    --     if num and num ~= "jackpot" then
    --         local str = util_formatCoins(tonumber(num),5)
    --         local coinsTab = self:ChangeStringToTable(str)

    --         littleView:setlabString(coinsTab)
    --     end

    -- end
end

function ClassicRapid2_Classic_WheelView:ChangeStringToTable(str )

    if str == nil or type(str) ~= "string" then
       return {}
    end

    local strArray = {}

    local strLen = string.len( str )
    local index = 0
    for i=1,strLen do
        local charStr =  string.sub(str,i,i)
        if charStr ~= "," then -- 不要逗号
                table.insert( strArray, charStr )
            index = index + 1
        end

    end

    return strArray
end


function ClassicRapid2_Classic_WheelView:showActionFrame(type,callback)
    if type == 1 then
        -- POSITION_TYPE_FREE
        -- cc.POSITION_TYPE_GROUPED    = 0x2
-- cc.POSITION_TYPE_RELATIVE   = 0x1

        self:findChild("flashNode"):setVisible(true)
    else

        self:findChild("flashNode"):setVisible(false)
    end
    self:runCsbAction("actionframe",false,function()
        if callback then
            callback()
        end
    end,30)
end


function ClassicRapid2_Classic_WheelView:playLightAnim()
    self:runCsbAction("light",true,function()
    end,30)
end


function ClassicRapid2_Classic_WheelView:onEnter()


end


function ClassicRapid2_Classic_WheelView:onExit()

end

function ClassicRapid2_Classic_WheelView:setTouchLayer()
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

function ClassicRapid2_Classic_WheelView:clickFunc()
    if self.m_bIsTouched == true then
        return
    end
    -- gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_click_wheel.mp3")
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouched = true

    -- util_spinePlay(self.m_scatter,"idleframe3",true)


    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    self:beginWheelAction()

end


function ClassicRapid2_Classic_WheelView:resetView()
    self.m_selectEff:setVisible(false)
    self:findChild("wheel"):setRotation(0)
end

function ClassicRapid2_Classic_WheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 250 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 0 --匀速时间
    wheelData.m_slowA = 200 --动态减速度
    wheelData.m_slowQ = 2 --减速圈数
    wheelData.m_stopV = 100 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel(false)
    -- self.m_wheelTurn = gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_wheelTurn.mp3",true)

    self.m_wheel:recvData(self.m_endIndex)
end

function ClassicRapid2_Classic_WheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        -- if self.m_wheelTurn then
        --     gLobalSoundManager:stopAudio(self.m_wheelTurn)
        -- end
        self.m_selectEff:setVisible(true)
        self:playLightAnim()

        if self.m_endIndex == 1 then
            self.m_selectEff:playAction("actionframe2",true)
            gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_wheelJackpotReward.mp3")
        else
            self.m_selectEff:playAction("actionframe",true)
            gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_wheelReward.mp3")
        end
        performWithDelay(self,function(  )
            callBackFun()
        end,3)

        -- self:runCsbAction("actionframe",false,function()

        -- end,20)
    end
end

function ClassicRapid2_Classic_WheelView:setWheelRotModel( )

    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function ClassicRapid2_Classic_WheelView:setRotionAction( distance,targetStep,isBack )

    local temp = math.floor(distance / targetStep)
    if self.distance_now and self.distance_now ~= temp then
        self.distance_now = temp
        gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_wheelTurn.mp3")
    end

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
    --     -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now

        -- gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_wheel_rptate.mp3")
    end
end

return ClassicRapid2_Classic_WheelView