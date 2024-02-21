local CastFishingFreeBatteryList = class("CastFishingFreeBatteryList",util_require("Levels.BaseLevelDialog"))
local CastFishingManager = require "CodeCastFishingSrc.CastFishingFish.CastFishingManager"
local CastFishingMusicConfig = require "CodeCastFishingSrc.CastFishingMusicConfig"


function CastFishingFreeBatteryList:initDatas(_params)
    self.m_machine = _params[1]
    
    self.m_clickState = false
    self.m_endCallBack = nil
end
function CastFishingFreeBatteryList:initUI()
    self:createCsbNode("CastFishing_FGpaotai.csb")

    self.m_batteryList = {}
    for i=1,5 do
        local batteryAnim = util_createView("CodeCastFishingSrc.CastFishingBattery.CastFishingBattery", {
            "CastFishing_FGpao.csb", 
            "CastFishing_FGpao",
            self.m_machine,
        })
        local parent = self:findChild(string.format("Node_pao_%d", i))
        parent:addChild(batteryAnim)
        -- 初始化数据和回调
        local battertIndex = i
        local data = {
            index = battertIndex,
        }
        batteryAnim:setBatteryData(data)
        batteryAnim:setBatteryClickCallBack(function()
            self:onBatteryClick(data)
        end)
        batteryAnim:addBatteryClickEvent()
        table.insert(self.m_batteryList, batteryAnim)
        batteryAnim:setVisible(false)
    end
end


function CastFishingFreeBatteryList:startGame(_data)
    self.fishingResult  = _data[1]
    self.m_endCallBack = _data[2]

    self:playStartAnim(function()
        self:setClickState(true)
        self:startBatteryListCountDown()
    end)
end
function CastFishingFreeBatteryList:endGame(_fishObjList)
    self:playOverAnim(function()
        if self.m_endCallBack then
            self.m_endCallBack(_fishObjList)
            self.m_endCallBack = nil
        end
    end)
end




function CastFishingFreeBatteryList:playStartAnim(_fun)
    --炮台
    for i,_battery in ipairs(self.m_batteryList) do
        _battery:setVisible(true)
        _battery:playSpineAnim("idleframe", true)
    end
    -- 底座出现
    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeBattery_chuxian)
    self:runCsbAction("start", false, function()
        _fun()
    end)
end
function CastFishingFreeBatteryList:playOverAnim(_fun)
    self:runCsbAction("over", false, function()
        _fun()
    end)
end

--[[
    倒计时相关
]]
function CastFishingFreeBatteryList:startBatteryListCountDown()
    local batteryList = self.m_batteryList
    local batteryAnim = batteryList[math.random(1, #batteryList)]
    local batteryData = batteryAnim.m_batteryData
    for i,_battery in ipairs(batteryList) do
        _battery:startCountDown(7, function()
            self:onBatteryClick(batteryData)
        end)
    end
end
function CastFishingFreeBatteryList:stopBatteryListCountDown()
    local batteryList = self.m_batteryList
    for i,_battery in ipairs(batteryList) do
        _battery:stopCountDown()
        _battery:playTimeLabOverAnim()
    end
end
--[[
    炮台点击
]]
function CastFishingFreeBatteryList:setClickState(_state)
    self.m_clickState = _state
end
function CastFishingFreeBatteryList:onBatteryClick(_batteryData)
    if not self.m_clickState then
        return
    end
    self:setClickState(false)
    self:stopBatteryListCountDown()

    local batteryAnim = self.m_batteryList[_batteryData.index]
    local batterySize = batteryAnim:getBatterySize()
    local bulletId  = 1
    local bulletWorldPos =  batteryAnim:getParent():convertToWorldSpace(cc.p(0, batterySize.height/2))
    
    local data = {}
    data.sMode         = CastFishingManager.StrMode.Free
    data.bulletId      = bulletId
    data.bulletPos     = bulletWorldPos
    data.fishingResult = self.fishingResult
    data.overFun       = function(_fishObjList)
        self:endGame(_fishObjList)
    end

    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeBattery_fire)
    batteryAnim:playSpineAnim("actionframe", false, function()
        batteryAnim:playSpineAnim("idleframe2", false)
    end)
    -- 其余炮台压暗
    for i,_battery in ipairs(self.m_batteryList) do
        if i ~= _batteryData.index then
            _battery:playSpineAnim("yaan", false)
        end
    end
    -- 第10帧发射炮弹
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        gLobalNoticManager:postNotification("CastFishingMachine_launchBullet", data)
        waitNode:removeFromParent()
    end, 9/30)
end



return CastFishingFreeBatteryList