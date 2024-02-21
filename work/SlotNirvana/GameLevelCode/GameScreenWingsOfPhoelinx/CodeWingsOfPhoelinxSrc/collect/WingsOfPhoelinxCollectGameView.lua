---
--xcyy
--2018年5月23日
--WingsOfPhoelinxCollectGameView.lua


local WingsOfPhoelinxCollectGameView = class("WingsOfPhoelinxCollectGameView",util_require("Levels.BaseLevelDialog"))
local GOLD_NUM = 13

WingsOfPhoelinxCollectGameView.m_click = false

function WingsOfPhoelinxCollectGameView:initUI(machine)
    self:createCsbNode("WingsOfPhoelinx/WingsOfPhoelinx_jackpotbg.csb")
    self.m_machine = machine
    self.clickIndex = 0
    self.m_jinbiClicked = false
    self:initLittleUINode()
    self.p_showEvent = globalMachineController.WingsOfPhoekinxConfig
end

--初始化金币
function WingsOfPhoelinxCollectGameView:initLittleUINode( )
    for i=1,GOLD_NUM do
        local fatherNodeName = "Node_jinbi_" .. i
        self["m_jinbi_"..i] = util_createAnimation("WingsOfPhoelinx_jinbida.csb")
        self["m_jinbi_"..i].isClick = false
        self["m_jinbi_"..i]:findChild("click"):addTouchEventListener(handler(self, self.jinBiClick))
        self["m_jinbi_"..i]:findChild("click"):setTag( i )
        self["m_jinbi_"..i]:runCsbAction("idleframe",true)
        self:findChild(fatherNodeName):addChild(self["m_jinbi_"..i])
    end
end

--结束时，将所有金币的点击隐藏
function WingsOfPhoelinxCollectGameView:restAllJinBiAnim( )
    self.clickIndex = 0
    for i=1,GOLD_NUM do
        local jinbi = self["m_jinbi_"..i] 
        -- jinbi:runCsbAction("idleframeDark")
        jinbi:findChild("click"):setVisible(false)
    end
end

function WingsOfPhoelinxCollectGameView:onEnter()

    WingsOfPhoelinxCollectGameView.super.onEnter(self)
end

function WingsOfPhoelinxCollectGameView:onExit()
    WingsOfPhoelinxCollectGameView.super.onExit(self)
end


-- 处理点击
function WingsOfPhoelinxCollectGameView:jinBiClick(_sender,eventType )
    if eventType == ccui.TouchEventType.ended then

        local beginPos = _sender:getTouchBeganPosition()
        local endPos = _sender:getTouchEndPosition()
        local offx=math.abs(endPos.x-beginPos.x)
        if offx<50 and globalData.slotRunData.changeFlag == nil then
            self:jinBiClickFunc(_sender )
        end
   
    end
end

function WingsOfPhoelinxCollectGameView:jinBiClickFunc(_sender )
    if self.m_jinbiClicked  then
        return
    end

    -- gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_mapBonus_click.mp3")
    -- 
    self.clickIndex = self.clickIndex + 1
    local index = _sender:getTag()
    local jinbi = self["m_jinbi_"..index] 
    jinbi.isClick = true        --金币已经点击标志

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local process = selfData.jackpot.process    --点击列表

    self:setGroupClickStates( index ,false )

    -- 播放点击金币的效果并根据服务器的数据显示对应的jackpot
    self:setJinbiUiInfo(jinbi,process[self.clickIndex],false)

    --结束点击（点击次数等于服务器下发的次数）
    if self.clickIndex == #process then
        self.m_jinbiClicked = true
        --金币闪烁一下
        performWithDelay(self,function (  )
            self:restAllJinBiAnim()
            self:setNotClickShow()
            local shanList,darkList = self:getWinGolds()
            
            for i,v in ipairs(shanList) do
                v:runCsbAction("actionframe2")
            end
            for i,v in ipairs(darkList) do
                v:runCsbAction("idleframe2")
            end
            performWithDelay(self,function (  )
                gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Jackpot_WingsOfPhoelinx_shan.mp3")
            end,0.8)
            
            performWithDelay(self,function (  )
                if self.m_endFunc then
                    self.m_endFunc()
                end
            end,3)
        end,1)

    end

end

--点击过后的金币
function WingsOfPhoelinxCollectGameView:setGroupClickStates(goldIndex,_states )
    local Jinbi = self["m_jinbi_"..goldIndex]
    Jinbi:findChild("click"):setVisible(_states)
end

--根据服务器字段控制点击的金币显示
function WingsOfPhoelinxCollectGameView:setJinbiUiInfo(_jinbiNode,_celltype,isOther )
    local type = self:getJackpotIndex(_celltype)
    if not type then return end
    for i=1,5 do
        if i == type then
            
            _jinbiNode:findChild("WingsOfPhoelinx_gold"..i):setVisible(true)
            if isOther then
                _jinbiNode:runCsbAction("actionframe1",false,function (  )
                    _jinbiNode:runCsbAction("idleframe2")
                end)
            else
                _jinbiNode.info = type
                if type == 5 then
                    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Jackpot_WingsOfPhoelinx_GoldFan_wild.mp3")
                else
                    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Jackpot_WingsOfPhoelinx_GoldFan.mp3")
                end
                
                _jinbiNode:runCsbAction("actionframe",false,function (  )
                    _jinbiNode:runCsbAction("idleframe1")
                end)
            end
            
        else
            _jinbiNode:findChild("WingsOfPhoelinx_gold"..i):setVisible(false)
        end
    end
    if isOther then
        
    else
        local tempList = {showType = type}
        --跑一个事件，进行jackpot刷新
        gLobalNoticManager:postNotification(globalMachineController.WingsOfPhoekinxConfig.EventName.JACKPOT_NUM_UPDATA,tempList)
    end
    
end

--特别注意 兼容工程minor为4，mini为3
function WingsOfPhoelinxCollectGameView:getJackpotIndex(type)
    if type == "grand" then
        return 1
    elseif type == "major" then
        return 2
    elseif type == "minor" then
        return 4
    elseif type == "mini" then
        return 3
    elseif type == "wild" then
        return 5
    end
    return nil
end

--设置上部jackpot显示
function WingsOfPhoelinxCollectGameView:setGoldAnimStates(goldIndex,_states)
    self.m_jinbiClicked = false
        
end

--未点击的显示
function WingsOfPhoelinxCollectGameView:getNotClickNum()
    local m_goldsList = {}
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local process = selfData.jackpot.process    --点击列表
    local num_1 = 0
    local num_2 = 0
    local num_3 = 0
    local num_4 = 0
    local num_5 = 0
    for i,v in ipairs(process) do
        if v == "grand" then
            num_1 = num_1 +1
        elseif v == "major" then
            num_2 = num_2 +1
        elseif v == "minor" then
            num_3 = num_3 +1
        elseif v == "mini" then
            num_4 = num_4 +1
        elseif v == "wild" then
            num_5 = num_5 +1
        end
    end
    if num_5 ~= 1 then
        table.insert(m_goldsList,"wild")
    end
    if num_4 ~= 3 then
        for i=1,3 - num_4 do
            table.insert(m_goldsList,"mini")
        end
    end
    if num_3 ~= 3 then
        for i=1,3 - num_3 do
            table.insert(m_goldsList,"minor")
        end
    end
    if num_2 ~= 3 then
        for i=1,3 - num_2 do
            table.insert(m_goldsList,"major")
        end
    end
    if num_1 ~= 3 then
        for i=1,3 - num_1 do
            table.insert(m_goldsList,"grand")
        end
    end
    return m_goldsList
end

--随机金币的显示
function WingsOfPhoelinxCollectGameView:upsetToList(list)
    if type(list) ~= "table" then
        return
    end
    local tab = {}
    local index = 1
    while #list ~= 0 do
        local n = math.random(0,#list)
        if list[n] ~= nil then
            tab[index] = list[n]
            index = index + 1
            table.remove(list,n)
        end
    end
    return tab
end

function WingsOfPhoelinxCollectGameView:setNotClickShow()
    local temp = self:getNotClickNum()
    local list = {}
    copyTable(temp,list)
    local tabList = self:upsetToList(list)
    local showIndex = 1 
    for i=1,GOLD_NUM do
        local jinbi = self["m_jinbi_"..i]
        if jinbi.isClick == false then
            self:setJinbiUiInfo(jinbi,tabList[showIndex],true)
            showIndex = showIndex + 1
        end
    end
end

--获取参加闪烁的金币
function WingsOfPhoelinxCollectGameView:getWinGolds( )
    local tempList = {}
    local tempList2 = {}
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local process = selfData.jackpot.process or {}    --点击列表 
    local winJackpot = selfData.jackpot.winJackpot or {}
    if #winJackpot > 1 then
        local showType = self:getJackpotIndex(winJackpot[1])
        local showType2 = self:getJackpotIndex(winJackpot[2])
        for i=1,GOLD_NUM do
            local jinbi = self["m_jinbi_"..i]
            if jinbi.isClick == true then
                if jinbi.info == showType or jinbi.info == 5 or jinbi.info == showType2 then
                    table.insert( tempList, jinbi )
                else
                    table.insert( tempList2, jinbi )
                end
            end
        end
    else
        local showType3 = self:getJackpotIndex(winJackpot[1])
        for i=1,GOLD_NUM do
            local jinbi = self["m_jinbi_"..i]
            if jinbi.isClick == true then
                if jinbi.info == showType3 or jinbi.info == 5 then
                    table.insert( tempList, jinbi )
                else
                    table.insert( tempList2, jinbi )
                end
            end
        end
    end
    
    return tempList,tempList2
end

function WingsOfPhoelinxCollectGameView:setEndFunc(func)
    self.m_endFunc = func
end

return WingsOfPhoelinxCollectGameView