---
--xcyy
--2018年5月23日
--FortuneGodMapSmallItem.lua

local FortuneGodMapSmallItem = class("FortuneGodMapSmallItem",util_require("Levels.BaseLevelDialog"))


function FortuneGodMapSmallItem:initUI()

    self:createCsbNode("FortuneGod_xiaoguan_hongbao.csb")

    self.hongBao = util_spineCreate("FortuneGod_xiaoguan_Hongbao",true,true)
    self:findChild("hongBao"):addChild(self.hongBao)

    self.m_idleNode = cc.Node:create()
    self:addChild(self.m_idleNode)
    self:findChild("m_lb_coins"):setString("")
    self:findChild("FortuneGod_xiaoyouxi_duihao_2"):setVisible(false)
end

function FortuneGodMapSmallItem:idle()
    self.m_idleNode:stopAllActions()
    --随机一个时间
    local time = math.random(3,6)
    self:findChild("FortuneGod_xiaoyouxi_duihao_2"):setVisible(false)
    util_spinePlay(self.hongBao,"idleframe1_1",false)
    util_spineEndCallFunc(self.hongBao,"idleframe1_1",function (  )
        util_spinePlay(self.hongBao,"idleframe1_2",true)
    end)
    performWithDelay(self.m_idleNode,function (  )
        self:idle()
    end,time)
    
end

function FortuneGodMapSmallItem:click(func,LitterGameWin)
    local node = cc.Node:create()
    self:addChild(node)
    self.m_idleNode:stopAllActions()
    local actionList = {}
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_map_small_open.mp3")
        util_spinePlay(self.hongBao,"shouji",false)
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(0.5)
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        self:findChild("m_lb_coins"):setString(util_formatCoins(LitterGameWin,3))
        self:runCsbAction("actionframe")
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(0.5)
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        util_spinePlay(self.hongBao,"idleframe2",true)
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        if func then
            func()
        end
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))
end

function FortuneGodMapSmallItem:changeSmall( )
    self.m_idleNode:stopAllActions()
    --红包变暗
    util_spinePlay(self.hongBao,"bianan",false)
    performWithDelay(self,function (  )
        self:findChild("FortuneGod_xiaoyouxi_duihao_2"):setVisible(true)
        util_spinePlay(self.hongBao,"biananidle",true)
    end,0.5)
end

function FortuneGodMapSmallItem:completed()
    self.m_idleNode:stopAllActions()
    self:findChild("m_lb_coins"):setString("")
    self:findChild("FortuneGod_xiaoyouxi_duihao_2"):setVisible(true)
    util_spinePlay(self.hongBao,"biananidle",true)
end


return FortuneGodMapSmallItem