---
--smy
--2018年4月26日
--BonusItem.lua

local BonusItem = class("BonusItem",util_require("base.BaseView"))

-- show  -开场的
-- idleframe
-- down  --点击
-- black --
-- 


function BonusItem:initUI()
    self:createCsbNode("FivePande/Bonusltem.csb")
    local touch=self:findChild("touch")
    self:addClick(touch)

    self.m_spinePanda = util_spineCreate("Socre_FivePande_Bonusltem",true,true)
    self:findChild("Node_18"):addChild(self.m_spinePanda)

    self.m_csbOwner["m_lb_mul"]:setString("")
    self.m_csbOwner["sp_keep"]:setVisible(false)
end

function BonusItem:initItem(game,index,func)
    self.m_game=game
    self.m_index=index
    self.m_func=func
    self.isClick=false
    self.isShowItem = false
end

function BonusItem:toClick()
    release_print("BonusItem:toClick game")
    if not self.m_game:isTouch() then
        return
    end
    print("BonusItem:toClick click")
    if self.isClick then
        return
    end
    release_print("BonusItem:isClickNow game")
    -- 还没发送完数据 不让继续点 以防误触
    if self.m_game.isClickNow then
        return
    end

    release_print("BonusItem:toClick index="..self.m_index)
    self.m_game.isClickNow = true

    performWithDelay(self,function()
        self.m_game.isClickNow = false
    end,0.2)

    -- self:runCsbAction("click")
    print("BonusItem:toClick index="..self.m_index)
    self.isClick=true
    self.m_func(self.m_index)

end

function BonusItem:showItemStart()

    
    util_spinePlay(self.m_spinePanda,"start")
    -- self:runCsbAction("show")
end

function BonusItem:showIdle()
    if self.isShowItem or self.isClick then
        return
    end

    -- self:runCsbAction("idle")
    local time=math.random(3,8)*0.4
    performWithDelay(self,function()
        if self.isShowItem or self.isClick then
            return
        end
        if self.isShowItem == false then
            util_spinePlay(self.m_spinePanda,"idleframe",true)
            -- self:runCsbAction("idleframe",true)
        end
    end,time)
    
end

function BonusItem:showClick(content,isKeep)
    self.isShowItem=true
    self.isClick=true
    self.m_csbOwner["m_lb_mul"]:setString("*"..content)
    util_spinePlay(self.m_spinePanda,"dark")
    -- self:runCsbAction("down")
    self.m_csbOwner["sp_keep"]:setVisible(isKeep)
    gLobalSoundManager:playSound("FivePandeSounds/music_FivePande_item_open.mp3")


    local actNode = util_createAnimation("FivePande/Bonusltem_0.csb")
    self:addChild(actNode,1)
    actNode:runCsbAction("show",false,function(  )
        actNode:setVisible(false)
    end)
    actNode:findChild("Particle_1_0"):resetSystem()
    actNode:findChild("Particle_1"):resetSystem()

end

function BonusItem:showOver(content,isKeep)
    self.isClick=true
    self.m_csbOwner["m_lb_mul"]:setString("*"..content)
    util_spinePlay(self.m_spinePanda,"dark")
    -- self:runCsbAction("black")
    self.m_csbOwner["sp_keep"]:setVisible(isKeep)
    if isKeep then
        self.m_csbOwner["sp_keep"]:setColor(cc.c3b(96, 96, 96))
    end
    self.m_csbOwner["m_lb_mul"]:setColor(cc.c3b(96, 96, 96))
    
end


function BonusItem:onEnter()

end

function BonusItem:onExit()

end


function BonusItem:clickFunc(sender )
    self:toClick()
end


return BonusItem