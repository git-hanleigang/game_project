local CastFishingBonusBatteryList = class("CastFishingBonusBatteryList",util_require("Levels.BaseLevelDialog"))
local CastFishingManager = require "CodeCastFishingSrc.CastFishingFish.CastFishingManager"
local CastFishingMusicConfig = require "CodeCastFishingSrc.CastFishingMusicConfig"


function CastFishingBonusBatteryList:initDatas(_params)
    self.m_machine = _params[1]

    self.m_data = {}
    self.m_clickState = false
    self.m_endCallBack = nil
    self.m_bonusFishingData = nil
end
function CastFishingBonusBatteryList:initUI()
    self:createCsbNode("CastFishing_Upshotpaotai.csb")

    self.m_batteryList = self:createBatteryList(false)
    self.m_specialBatteryList = self:createBatteryList(true)

    util_setCascadeOpacityEnabledRescursion(self, true)
end



function CastFishingBonusBatteryList:setBatteryData(_data)
    --[[
        _data = {
            bSpecial = true,
        }
    ]]
    self.m_data = _data
end
function CastFishingBonusBatteryList:startGame(_fishingResult, _fun)
    self.fishingResult  = _fishingResult
    self.m_endCallBack = _fun

    self:setClickState(true)
    self:startBatteryListCountDown(self.m_data.bSpecial)
end
function CastFishingBonusBatteryList:endGame()
    local nextFun = self.m_endCallBack
    self.m_endCallBack = nil
    if "function" == type(nextFun) then
        nextFun()
    end
end

-- 暗idle
function CastFishingBonusBatteryList:playGrayIdleAnim()
    local batteryList = self:getBatteryList(self.m_data.bSpecial)
    for i,_battery in ipairs(batteryList) do
        _battery:playSpineAnim("anidle", false)
    end
end

-- 循环亮idle
function CastFishingBonusBatteryList:playIdleAnim()
    local batteryList = self:getBatteryList(self.m_data.bSpecial)
    for i,_battery in ipairs(batteryList) do
        _battery:playSpineAnim("idleframe", true)
    end
end
function CastFishingBonusBatteryList:playOverAnim(_fun)
    -- self:runCsbAction("over", false, function()
        _fun()
    -- end)
end

function CastFishingBonusBatteryList:upDateBatteryType()
    local commonNode = self:findChild("Node_common")
    local specialNode = self:findChild("Node_special")
    commonNode:setVisible(not self.m_data.bSpecial)
    specialNode:setVisible(self.m_data.bSpecial)
end
--[[
    倒计时相关
]]
function CastFishingBonusBatteryList:startBatteryListCountDown(bSpecial)
    local batteryList = self:getBatteryList(self.m_data.bSpecial) 
    local batteryAnim = batteryList[math.random(1, #batteryList)]
    local batteryData = batteryAnim.m_batteryData
    for i,_battery in ipairs(batteryList) do
        _battery:startCountDown(7, function()
            self:onBatteryClick(batteryData)
        end)
    end
end
function CastFishingBonusBatteryList:stopBatteryListCountDown(bSpecial)
    local batteryList = self:getBatteryList(self.m_data.bSpecial) 
    for i,_battery in ipairs(batteryList) do
        _battery:stopCountDown()
        _battery:playTimeLabOverAnim()
    end
end
--[[
    炮台列表处理
]]
function CastFishingBonusBatteryList:createBatteryList(bSpecial)
    local csbName   = bSpecial and "CastFishing_superUpshotpao.csb" or "CastFishing_Upshotpao.csb"
    local spineName = bSpecial and "CastFishing_Upshotpao_2" or "CastFishing_Upshotpao_1"

    local batteryList = {}
    for i=1,5 do
        local parentName = bSpecial and string.format("Node_specialPao_%d", i) or string.format("Node_pao_%d", i)
        local parent     = self:findChild(parentName)
        local batteryAnim  = util_createView("CodeCastFishingSrc.CastFishingBattery.CastFishingBattery", {
            csbName, 
            spineName,
            self.m_machine,
        })
        parent:addChild(batteryAnim)
        local battertIndex = i
        local batteryData = {
            bSpecial = bSpecial,
            index = battertIndex,
        }
        batteryAnim:setBatteryData(batteryData)
        local fnClickCallBack = function()
            self:onBatteryClick(batteryData)
        end
        batteryAnim:setBatteryClickCallBack(fnClickCallBack)
        batteryAnim:addBatteryClickEvent()
        table.insert(batteryList, batteryAnim)
    end

    return batteryList
end
function CastFishingBonusBatteryList:getBatteryList(bSpecial)
    local batteryList = bSpecial and self.m_specialBatteryList or self.m_batteryList
    return batteryList
end
--[[
    炮台点击
]]
function CastFishingBonusBatteryList:setClickState(_state)
    self.m_clickState = _state
end
function CastFishingBonusBatteryList:onBatteryClick(_batteryData)
    if not self.m_clickState then
        return
    end
    if not self.fishingResult then
        return
    end
    self:setClickState(false)
    self:stopBatteryListCountDown(self.m_data.bSpecial)

    local batteryList = self:getBatteryList(self.m_data.bSpecial)
    local batteryAnim = batteryList[_batteryData.index]
    local batterySize = batteryAnim:getBatterySize()
    -- 子弹类型由场景判断创建
    local bulletId    = self.m_data.bSpecial and 100 or 2
    local bulletWorldPos =  batteryAnim:getParent():convertToWorldSpace(cc.p(0, batterySize.height/2))
    
    local data = {}
    data.sMode         = CastFishingManager.StrMode.Bonus
    data.bulletId      = bulletId
    data.bulletPos     = bulletWorldPos
    data.fishingResult = self.fishingResult
    data.overFun       = function(_fishObjList)
        local data  = {}
        data.bLaser      = self.m_data.bSpecial
        data.bBonus      = true
        data.fishObjList = _fishObjList
        data.nextFun     = function()
            self:endGame()
        end
        gLobalNoticManager:postNotification("CastFishingMachine_bonusBulletOverCallBack", data)
    end
    self.fishingResult  = nil

    if self.m_data.bSpecial then
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_superBonus_fire)
    else
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeBattery_fire)
    end
    batteryAnim:playSpineAnim("actionframe", false)
    -- 炮台压暗
    for i,_battery in ipairs(batteryList) do
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

return CastFishingBonusBatteryList