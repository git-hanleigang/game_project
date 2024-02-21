---
--xcyy
--2018年5月23日
--FortuneGodMapBigItem.lua

local FortuneGodMapBigItem = class("FortuneGodMapBigItem",util_require("Levels.BaseLevelDialog"))

local BIG_LEVEL = {
    LEVEL1 = 2,
    LEVEL2 = 7,
    LEVEL3 = 13,
    LEVEL4 = 20
}

function FortuneGodMapBigItem:initUI(data)
    local itemFile = self:changeFile(data)
    self:createCsbNode(itemFile)

    self.posIndex = data.selfPos
    if self.posIndex == BIG_LEVEL.LEVEL4 then
        self.yuanBao = util_spineCreate("FortuneGod_daguan_chengbei_5to100",true,true)
        self:findChild("Node_1"):addChild(self.yuanBao)
    else
        self.yuanBao = util_spineCreate("FortuneGod_daguan_Chengbei",true,true)
        self:findChild("Node_1"):addChild(self.yuanBao)
    end
    self.actList = self:getAnimName(self.posIndex)
    self.m_idleNode = cc.Node:create()
    self:addChild(self.m_idleNode)
    
    self:findChild("FortuneGod_xiaoyouxi_duihao_1"):setVisible(false)
end

function FortuneGodMapBigItem:changeFile(data)
    if data.selfPos == BIG_LEVEL.LEVEL1 then
        return "FortuneGod_daguan_chengbei_2to5.csb"
    elseif data.selfPos == BIG_LEVEL.LEVEL2 then
        return "FortuneGod_daguan_chengbei_2to10.csb"
    elseif data.selfPos == BIG_LEVEL.LEVEL3 then
        return "FortuneGod_daguan_chengbei_3to25.csb"
    elseif data.selfPos == BIG_LEVEL.LEVEL4 then
        return "FortuneGod_daguan_chengbei_5to100.csb"
    else
        return "FortuneGod_daguan_chengbei_2to5.csb"
    end
end

function FortuneGodMapBigItem:getAnimName(pos)
    if pos == 2 then
        return {"2to5idle1","2to5idle2","2to5actionframe","2to5an","2to5anidle"}
    elseif pos == 7 then
        return {"2to10idle1","2to10idle2","2to10actionframe","2to10an","2to10anidle"}
    elseif pos == 13 then
        return {"3to25idle1","3to25idle2","3to25actionframe","3to25an","3to25anidle"}
    elseif pos == 20 then
        return {"5to10actionframe","idleactionframe","actionframe","bianhei","bianhei"}
    end
    return nil
end

function FortuneGodMapBigItem:idle()
    self:runCsbAction("idle")
    -- local actList = self:getAnimName(self.posIndex)
    self.m_idleNode:stopAllActions()
    --随机一个时间
    local time = math.random(3,6)
    self:findChild("FortuneGod_xiaoyouxi_duihao_1"):setVisible(false)
    util_spinePlay(self.yuanBao,self.actList[1],false)
    util_spineEndCallFunc(self.yuanBao,self.actList[1],function (  )
        util_spinePlay(self.yuanBao,self.actList[2],true)
    end)
    performWithDelay(self.m_idleNode,function (  )
        self:idle()
    end,time)
end

function FortuneGodMapBigItem:click(func)
    local node = cc.Node:create()
    self:addChild(node)
    local actionList = {}
    self.m_idleNode:stopAllActions()
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_BigItemShow.mp3")
        util_spinePlay(self.yuanBao,self.actList[3],false)
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(2)
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        --打钩
        self:findChild("FortuneGod_xiaoyouxi_duihao_1"):setVisible(true)
        --文字框变黑
        self:runCsbAction("bianan")
        util_spinePlay(self.yuanBao,self.actList[4],false)
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(0.5)
    if self.posIndex ~= BIG_LEVEL.LEVEL4 then
        actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            --文字框黑idle
            self:runCsbAction("anidle")
            util_spinePlay(self.yuanBao,self.actList[5],true)
        end)
    end
    
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        if func then
            func()
        end
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))

end

function FortuneGodMapBigItem:completed()
    -- self:runCsbAction("idle2", true)
    self.m_idleNode:stopAllActions()
    self:findChild("FortuneGod_xiaoyouxi_duihao_1"):setVisible(true)
    --文字框黑idle
    self:runCsbAction("anidle")
    util_spinePlay(self.yuanBao,self.actList[5],true)
end


return FortuneGodMapBigItem