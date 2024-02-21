--塔形转轮
--PowerUpTowerLevel.lua

local PowerUpTowerLevel = class("PowerUpTowerLevel",util_require("base.BaseView"))

local ReelHelper = util_require("CodePowerUpSrc.ReelHelper")

PowerUpTowerLevel.itemList = nil

function PowerUpTowerLevel:initUI(data)
    self.levelData = data
    self:createCsbNode("PowerUp_bonus_reel.csb")

    self:findChild("lbs_leftLv"):setString(""..data.level)
    self:findChild("lbs_rightLv"):setString(""..data.level)
    self.m_mask = self:findChild("mask")
    self.m_mask:setVisible(false)

    self.m_conSize  = self:findChild("Panel_2"):getContentSize()
    self.typeList = self:dealType(self.levelData.wheelData[2],self.levelData.wheelData[3])

    self:initItem()

    self.m_reelHelper = ReelHelper:create()
    self.m_reelHelper:initReel(self.itemList)
end

function PowerUpTowerLevel:initItem()
    self.itemList = {}
    local startIndex = 1
    if self.levelData.wheelData[4] ~= nil then
        startIndex = self.levelData.wheelData[4] - 2 + 1  --服务器下标从0开始
    end
    if startIndex <= 0 then --左边界
        startIndex = #self.levelData.wheelData[2] - math.abs(startIndex)
    end

    for i=1,6 do
        local levelItem =  util_createView("CodePowerUpSrc.PowerUpTowerLevelItem",self.typeList,self.levelData.isLast)
        local itemSize = levelItem:getBgWidth()
        self.m_itemWidth = itemSize.width
        self:findChild("Panel_2"):addChild(levelItem)
        levelItem:setPosition((i-1/2)*itemSize.width,self.m_conSize.height/2)
        local coinsNum = self.levelData.wheelData[2][startIndex]
        levelItem:setViewData({num=coinsNum,index = startIndex})
        if self.levelData.wheelData[4] ~= nil and startIndex == (self.levelData.wheelData[4] + 1) then
            -- levelItem:showWinning()
        end
        self.itemList[i] = levelItem
        startIndex = startIndex + 1
        if startIndex > #self.levelData.wheelData[2] then --右边界
            startIndex = startIndex - #self.levelData.wheelData[2]
        end
    end
end

-- {reelWidth = 400,itemWidth = 100,elementNumber = 6, runData = {} ,runtime = 3,runV =3,stopV=0.5,stopA = 50}
--开始滚动
function PowerUpTowerLevel:beginReel(resultIndex,callBack)
    local wheelData = {reelWidth = self.m_conSize.width,itemWidth = self.m_itemWidth,elementNumber = 6,
        runData = self.levelData.wheelData[2],
        runtime = 3,runV =5,
        stopV=2,stopA = 2.5,lastV = 0.4,lastPara = 0.2}

     self.m_reelHelper:startRoll(resultIndex,wheelData,function()

        for i=1,#self.itemList do
            if self.itemList[i].m_index == resultIndex then
                self.itemList[i]:showWinning()
                gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_towerItemWin.mp3")
                break
            end
        end
        if callBack then
            callBack()
        end

    end)
end

function PowerUpTowerLevel:startIdle()
    local idleData = {reelWidth = self.m_conSize.width,itemWidth = self.m_itemWidth,
    elementNumber = 6,runData = self.levelData.wheelData[2],
    runtime = 30000000,runV =0.5,stopV=0.5,stopA = 50,lastV = 0.4,lastPara = 0.2}
    self.m_reelHelper:startIdle(idleData)
end

function PowerUpTowerLevel:changeState(state)
    if state then
        self.m_mask:setVisible(false)
        for i=1,#self.itemList do
            self.itemList[i]:showIdle()
        end

        self:startIdle()
    else
        self.m_mask:setVisible(true)
        for i=1,#self.itemList do
            self.itemList[i]:showStop()
        end
    end

end


function PowerUpTowerLevel:getBGHeight()
    return self:findChild("leftBg"):getContentSize().height
end

--数据 分类
function PowerUpTowerLevel:dealType(retab,speType)
    local list = {}
    copyTable(retab,list)
    table.sort(list, function(a,b)
        return tonumber(a) > tonumber(b)
    end)
    local temp = {}
    local index = 1
    for i=1,#list do
        if temp[list[i]] == nil then
            temp[list[i]] = index
            index = index+1
        end
    end
    return temp
end

function PowerUpTowerLevel:updateReel(dt)
    if self.m_reelHelper.m_isInit then
        self.m_reelHelper:updateReel(dt)
    end
end


function PowerUpTowerLevel:onExit()

end

--默认按钮监听回调
function PowerUpTowerLevel:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end


return PowerUpTowerLevel