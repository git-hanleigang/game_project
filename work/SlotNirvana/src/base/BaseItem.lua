---
--smy
--2018年5月4日
--BaseItem.lua

local BaseItem = class("BaseItem",util_require("base.BaseView"))

BaseItem.NONE=-1 --未初始化阶段
BaseItem.ILDE=0  --待机阶段
BaseItem.CLICK=1  --点击宝箱
BaseItem.OPEN=2  --打开宝箱
BaseItem.OVER=3  --游戏结束展示未获得宝箱

BaseItem.m_game=nil             --baseGame
BaseItem.m_index=nil            --宝箱按钮索引
BaseItem.m_func=nil             --宝箱按钮点击回调
BaseItem.m_status=nil           --宝箱按钮状态

--------------------------- BASEGAME---------------------------
--按钮是否可以点击
function BaseItem:isIdle()
    return self.m_status==self.ILDE
end

function BaseItem:isOpen()
    return self.m_status==self.OPEN or self.m_status==self.OVER 
end

function BaseItem:onExit()
    scheduler.unschedulesByTargetName("BaseItem")
    
end

--按钮初始化
function BaseItem:initItem(game,index,func,idleTime)
    self.m_status=self.NONE
    self.m_game=game
    self.m_index=index
    self.m_func=func

    if idleTime and idleTime>0 then
        scheduler.performWithDelayGlobal(function()
            self:showIdle()
        end, idleTime,"BaseItem")
    else
        self:showIdle()
    end
    local touch =self:findChild("touch")
    if touch then
        self:addClick(touch)
    end
end

function BaseItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch" then
        self:clickItem()
    end
end

--按钮点击回调函
function BaseItem:clickItem()
    print("BaseItem:toClick game")
    --baseGame是否可以点击
    if not self.m_game:isTouch() then
        return
    end
    print("BaseItem:toClick click")
    --宝箱是否可以点击
    if not self:isIdle() then
        return
    end
    print("BaseItem:toClick index="..self.m_index)
    --设置宝箱点击动画
    self:showClick()
    --回调basegame传入方法
    self.m_func(self.m_index)
end
-----------------------------子类继承
--播放idle动画
function BaseItem:showIdle()
    self.m_status=self.ILDE
    -- self:runAnimByName(self.m_animMgr,"idle")
end

--播放click动画
function BaseItem:showClick()
    self.m_status=self.CLICK
    -- self:runAnimByName(self.m_animMgr,"click")
end

--播放open动画
function BaseItem:showOpen(selectData)
    self.m_status=self.OPEN
    -- self:runAnimByName(self.m_animMgr,"open")
end

--播放over动画
function BaseItem:showOver(selectData)
    self.m_status=self.OVER
    -- self:runAnimByName(self.m_animMgr,"over")
end

return BaseItem