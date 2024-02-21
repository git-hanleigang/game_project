---
--xcyy
--2018年5月23日
--ReelRocksCollectProgress.lua

local ReelRocksCollectProgress = class("ReelRocksCollectProgress",util_require("base.BaseView"))
local COLLECT_NUM = 20

function ReelRocksCollectProgress:initUI()

    self:createCsbNode("ReelRocks_jindutiao.csb")

    

    self.kuangGongNode = self:findChild("ReelRocks_jindutiao_kuanggong")        
    self.kuangGong = util_spineCreate("ReelRocks_jindutiao_kuanggong",true,true)    --矿工
    self.kuangGongNode:addChild(self.kuangGong)
    util_spinePlay(self.kuangGong,"idleframe",true)

    
    -- self.collectTipView:setVisible(false)

    self:addClick(self:findChild("Node_tishi"))

    self.m_vecProgressItems = {}
    for i = 1, COLLECT_NUM, 1 do
        local item = util_createAnimation("ReelRocks_jindutiao_baoshi.csb")
        local baoShiNode = self:findChild("jindutiao_1_"..i)
        baoShiNode:addChild(item)
        item:playAction("idle2")
        self.m_vecProgressItems[#self.m_vecProgressItems + 1] = item
    end
    self.m_percet = 0
end

function ReelRocksCollectProgress:initProgress(collectNum)
    if collectNum == 0 then
        
    end
    for i = 1, collectNum, 1 do
        local item = self.m_vecProgressItems[i]
        item:playAction("idle")
    end
    self.m_percet = collectNum
end

function ReelRocksCollectProgress:updateProgress(addNum)
    for i = self.m_percet + 1, self.m_percet + addNum, 1 do
        local item = self.m_vecProgressItems[i]
        item:playAction("idle")
        
        -- local particle = item:findChild("Particle_1")
        -- particle:resetSystem()
    end
    self:collectPeople("actionframe")
    self.m_percet = self.m_percet + addNum
end

function ReelRocksCollectProgress:getEndNode(index)
    if self.m_percet ~= nil and self.m_percet + index <= COLLECT_NUM then
        return self.m_vecProgressItems[self.m_percet + index]
    end
end

function ReelRocksCollectProgress:resetProgress()
    for i = 1, #self.m_vecProgressItems, 1 do
        local item = self.m_vecProgressItems[i]
        item:playAction("idle2")
    end
    self.m_percet = 0
end

function ReelRocksCollectProgress:completedAnim()
    
    for i = 1, 20, 1 do
        local item = self.m_vecProgressItems[i]
        item:playAction("actionframe")
    end
    performWithDelay(self,function (  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_jiman.mp3")
        self:collectPeople("actionframe2")
    end,1)
end

function ReelRocksCollectProgress:collectPeople(actName)
    util_spinePlay(self.kuangGong,actName,false)
    util_spineEndCallFunc(self.kuangGong,actName,function (  )
        util_spinePlay(self.kuangGong,"idleframe",true)
    end)
end

function ReelRocksCollectProgress:onEnter()
 

end


function ReelRocksCollectProgress:onExit()
 
end

--默认按钮监听回调
function ReelRocksCollectProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Node_tishi" then
        -- self:clicTipView()
        gLobalNoticManager:postNotification("SHOW_BONUS_Tip")
    end
end



return ReelRocksCollectProgress