---
--xcyy
--2018年5月23日
--WolfSmashSmallMapView.lua

local WolfSmashSmallMapView = class("WolfSmashSmallMapView",util_require("Levels.BaseLevelDialog"))


function WolfSmashSmallMapView:initUI(machine)

    self:createCsbNode("WolfSmash/DiTu.csb")
    self.m_machine = machine
    self.pigMultipleList = {}

    local firstPoint = util_createAnimation("WolfSmash_dituqidian.csb")
    self:findChild("Node_dituqidian"):addChild(firstPoint)
end

function WolfSmashSmallMapView:changeChengBeiShow(coinsView,multiple)
    local curChild = {
        "Node_X2",
        "Node_X3",
        "Node_X5",
        "Node_X10",
    }
    for i,v in ipairs(curChild) do
        coinsView:findChild(v):setVisible(false)
    end
    if multiple == 2 then
        coinsView:findChild(curChild[1]):setVisible(true)
    elseif multiple == 3 then
        coinsView:findChild(curChild[2]):setVisible(true)
    elseif multiple == 5 then
        coinsView:findChild(curChild[3]):setVisible(true)
    elseif multiple == 10 then
        coinsView:findChild(curChild[4]):setVisible(true)
    end
end

function WolfSmashSmallMapView:getPigMultiple(multiple)
    local pigSpine = util_spineCreate("Socre_WolfSmash_Bonus",true,true)
    if multiple == 10 then
        pigSpine:setSkin("gold")
    else
        pigSpine:setSkin("red")
    end
    local cocosName = "WolfSmash_chengbei.csb"
    local coinsView = util_createAnimation(cocosName)
    self:changeChengBeiShow(coinsView,multiple)
    util_spinePushBindNode(pigSpine,"cb",coinsView)
    coinsView:runCsbAction("idle")
    pigSpine.multiple = multiple
    return pigSpine
end

function WolfSmashSmallMapView:createPigForMap(index,multiple,clickPigIndex)
    if self.m_machine.curClickType == 5 then
        return
    end
    
    local pigItem = self:getPigMultiple(multiple)
    self.pigMultipleList[#self.pigMultipleList + 1] = pigItem
    pigItem.clickPigIndex = clickPigIndex
    self:findChild("Node_P"..index):addChild(pigItem)
    util_spinePlay(pigItem, "start", false)
    util_spineEndCallFunc(pigItem, "start", function()
        util_spinePlay(pigItem, "idleframe2_2", true)
    end)
end

function WolfSmashSmallMapView:getEndNode(index)
    return self:findChild("Node_P"..index)
end

function WolfSmashSmallMapView:showPigForIndex(index)
    local pigItem = self.pigMultipleList[index]
    if pigItem then
        pigItem:setVisible(true)
    end
    
end

function WolfSmashSmallMapView:restAllPig()
    for i,v in ipairs(self.pigMultipleList) do
        v:removeFromParent()
    end
    self.pigMultipleList = {}
end

return WolfSmashSmallMapView