---
--xcyy
--2018年5月23日
--RollingJackpotFreeJackpotBar.lua

local RollingJackpotFreeJackpotBar = class("RollingJackpotFreeJackpotBar",util_require("Levels.BaseLevelDialog"))
local ConfigInstance  = require("RollingJackpotPublicConfig"):getInstance()
-- local SoundConfig = ConfigInstance.SoundConfig

function RollingJackpotFreeJackpotBar:initUI()

    self:createCsbNode("RollingJackpot_Jackpot_free_dan_shell.csb")
    self.m_maxIndex = 7
    self.m_curRow = 3
    self.m_itemTable = {}
    for index = 1,self.m_maxIndex do
        local tempIndex = index + 2
        local item = util_createView("RollingJackpotSrc.RollingJackpotFreeJackpotItem", tempIndex)
        item:playIdle()
        self:findChild(string.format("item_%d", tempIndex)):addChild(item)
        table.insert(self.m_itemTable, item)
    end
    self:runCsbAction("idle3")
end


function RollingJackpotFreeJackpotBar:onEnter()
    -- -- 切换语言 不需要的话可以删除掉
    -- self:initLanguage()
    -- gLobalNoticManager:addObserver( self,function(target,data)
    --     self:initLanguage()
    -- end,GD.ViewEventType.CHANGE_LANGUAGE )
end

function RollingJackpotFreeJackpotBar:showAdd()
    
end
function RollingJackpotFreeJackpotBar:onExit()
    --gLobalNoticManager:removeAllObservers(self)
end

--默认按钮监听回调
function RollingJackpotFreeJackpotBar:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function RollingJackpotFreeJackpotBar:upReelAni(oldeNum, newNum)
    self.m_curRow = newNum
    local actionStr = string.format("%dto%d", oldeNum, newNum)
    local idleStr = string.format("idle%d", newNum)
    self:runCsbAction(actionStr, false, function()
        self:runCsbAction(idleStr, true)
    end)
end

--获取小块 index 这个索引值是服务器传过来的
function RollingJackpotFreeJackpotBar:getItemByIndex(index)
    local tempIndex = index - 2
    if tempIndex > 0 and tempIndex <= self.m_maxIndex then
        return self.m_itemTable[tempIndex]
    end
end


function RollingJackpotFreeJackpotBar:initJackpotInfos(row)
    self.m_curRow = row
    local curIndex = ConfigInstance:getGameData("currentIndex")
    for index = 1,self.m_maxIndex do
        local item = self.m_itemTable[index]
        local itemIndex = item.m_index
        local info = ConfigInstance:getLevelInfoByIndex(itemIndex)
        item:initData(info)
        item:playIdle()
        item:setVisible(index >= curIndex)
    end
    local idleStr = string.format("idle%d", self.m_curRow)
    self:runCsbAction(idleStr, true)
end


return RollingJackpotFreeJackpotBar