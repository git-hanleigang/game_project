---
--island
--2018年4月12日
--FortuneGodSuperFreeStartView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local FortuneGodSuperFreeStartView = class("FortuneGodSuperFreeStartView", util_require("Levels.BaseLevelDialog"))


function FortuneGodSuperFreeStartView:initUI(data)
    

    local resourceFilename = "FortuneGod/SuperFreeSpinStart.csb"
    self:createCsbNode(resourceFilename)
    self.m_click = true
    self:showBeiShu(data.index)
    self:findChild("m_lb_num"):setString(data.num)
    self.m_callFun = data.func
    self:initViewData()
end

function FortuneGodSuperFreeStartView:initViewData()
    
    self.yuanBao = util_spineCreate("SuperFreeSpinStart",true,true)
    self:findChild("FortuneGod_tanban_yuanbao_7"):addChild(self.yuanBao)
    self:runCsbAction("start",false)
    util_spinePlay(self.yuanBao,"start",false)
    performWithDelay(self,function (  )
        self.m_click = false
        self:runCsbAction("idle",true)
        util_spinePlay(self.yuanBao,"idle",true)
    end,25/30)
    
    
end

function FortuneGodSuperFreeStartView:showBeiShu(index)
    if index == 2 then
        self:showBeiShu2(1)
    elseif index == 7 then
        self:showBeiShu2(2)
    elseif index == 13 then
        self:showBeiShu2(3)
    elseif index == 20 then
        self:showBeiShu2(4)
    end
end

function FortuneGodSuperFreeStartView:showBeiShu2(index)
    local imgName = {"FortuneGod_tanban_xinxi_2","FortuneGod_xiaoyouxi_xinxi_2_4","FortuneGod_xiaoyouxi_xinxi_3_5","FortuneGod_xiaoyouxi_xinxi_4_6"}
    for k,v in pairs(imgName) do
        local img =  self:findChild(v)
        if img then
            if k == index then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end
end

function FortuneGodSuperFreeStartView:onEnter()

    FortuneGodSuperFreeStartView.super.onEnter(self)
end

function FortuneGodSuperFreeStartView:onExit()

    FortuneGodSuperFreeStartView.super.onExit(self)

end

function FortuneGodSuperFreeStartView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        -- gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGods_Click_Collect.mp3")
        self.m_click = true
        util_spinePlay(self.yuanBao,"over",false)
        self:runCsbAction("over",false,function (  )
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end)
    end
end


return FortuneGodSuperFreeStartView

