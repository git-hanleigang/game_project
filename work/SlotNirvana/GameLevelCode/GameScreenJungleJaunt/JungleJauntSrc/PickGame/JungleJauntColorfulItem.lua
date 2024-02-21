---
--xcyy
--2018年5月23日
--JungleJauntColorfulItem.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntColorfulItem = class("JungleJauntColorfulItem",util_require("base.BaseView"))


function JungleJauntColorfulItem:initUI(params)
    self.m_parentView = params.parentView
    self.m_itemID = params.itemID     --索引ID
    self.m_isClicked = false    --是否已经点击

    self:createCsbNode("JungleJaunt_base_buff1_bianfu.csb")

    self.m_curRewardType = ""   --当前奖励类型
    self.m_curAniName = ""  --当前时间线

    --创建点击区域
    local layout = self:findChild("click")  
    self:addClick(layout)
end

function JungleJauntColorfulItem:initSpineUI()
    self.m_spine = util_spineCreate("JungleJaunt_base_buff1_sp",true,true)
    self:findChild("Node_spine"):addChild(self.m_spine)

    self.m_clickTX = util_spineCreate("JungleJaunt_base_buff1tx",true,true)
    self:findChild("Node_tx"):addChild(self.m_clickTX)
    self.m_clickTX:setVisible(false)

    self.m_clickTX2 = util_spineCreate("JungleJaunt_base_buff1tx2",true,true)
    self:findChild("Node_tx"):addChild(self.m_clickTX2)
    self.m_clickTX2:setVisible(false)

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function JungleJauntColorfulItem:onEnter()
    self.super.onEnter(self)
    self.m_parPos = cc.p(self:getParent():getPosition())
end


--[[
    设置具体的jackpot显示
]]
function JungleJauntColorfulItem:setHitBonusTypeShow(rewardType)
    self.m_curRewardType = rewardType
end

--[[
    重置显示及状态
]]
function JungleJauntColorfulItem:resetStatus()
    self.m_isClicked = true
    -- 重置位置
    self:getParent():setPosition(self.m_parPos)
    --重置层级
    self:getParent():setLocalZOrder(self.m_itemID)
    self.m_curRewardType = ""
    self.m_curAniName = ""
    --设置默认显示
    self:setHitBonusTypeShow("default")
    self.m_spine:setVisible(false)
end

function JungleJauntColorfulItem:beginClick()
    self.m_isClicked = false 
end

function JungleJauntColorfulItem:showAinm()
    self:runCsbAction("normal")
    local time = math.random(1,9) / 30
    self.m_spine:setVisible(false)
    performWithDelay(self.m_spine,function()
        self.m_spine:setVisible(true)
        util_spinePlay(self.m_spine,"start1")
        util_spineEndCallFunc(self.m_spine,"start1",function()
            util_spinePlay(self.m_spine,"idle1",true) 
        end)    
    end,time)
    return time
end


--[[
    显示奖励
]]
function JungleJauntColorfulItem:showRewardAni(rewardType,func,isEnd)
    self:setHitBonusTypeShow(rewardType)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_20)

    self.m_clickTX:setVisible(true)
    util_spinePlay(self.m_clickTX,"switch")
    util_spineEndCallFunc(self.m_clickTX,"switch",function()
        self.m_clickTX:setVisible(false)
    end)

    self:runAnim("start",false,function()
        if type(func) == "function" then
            func()
        end
    end)
    self.m_spine:stopAllActions()
    util_spinePlay(self.m_spine,"over"..self.m_itemID)
    util_spineEndCallFunc(self.m_spine,"over"..self.m_itemID,function()
        
    end)

    local isMul = not isEnd -- 因为数据的最后一位一定是赢钱，最后一位之前的都是倍数，所以这么判断
    local str = util_formatCoinsLN(rewardType,3)
    if isMul then
        str = "X" .. str 
    end
    self:findChild("chengbei"):setString(str)
end

function JungleJauntColorfulItem:noClickItemOver(_func)
    if self.m_isClicked == false then
        self.m_spine:stopAllActions()
        util_spinePlay(self.m_spine,"over"..self.m_itemID)
        util_spineEndCallFunc(self.m_spine,"over"..self.m_itemID,function()
            if type(_func) == "function" then
                _func()
            end
        end) 
    end
end



--[[
    显示中奖动效
]]
function JungleJauntColorfulItem:playEndRewardAni(_currCoins,_totalCoins,_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_22)

    self.m_clickTX:setVisible(true)
    util_spinePlay(self.m_clickTX,"switch")
    util_spineEndCallFunc(self.m_clickTX,"switch",function()
        self.m_clickTX:setVisible(false)
    end)

    self.m_clickTX2:setVisible(true)
    util_spinePlay(self.m_clickTX2,"switch2")
    util_spineEndCallFunc(self.m_clickTX2,"switch2",function()
        self.m_clickTX2:setVisible(false)
    end)

    self.m_clickTX2:setVisible(true)
    util_spinePlay(self.m_clickTX2,"switch2")
    util_spineEndCallFunc(self.m_clickTX2,"switch2",function()
        self.m_clickTX2:setVisible(false)
    end)

    


    --中奖时对应的节点提到最上层
    self:getParent():setLocalZOrder(100 + self.m_itemID)

    self:findChild("chengbei"):setString("") --util_formatCoinsLN(_currCoins,3)

    
    util_spinePlay(self.m_spine,"start2")
    util_spineEndCallFunc(self.m_spine,"start2",function()
        util_spinePlay(self.m_spine,"idle2",true)
    end)

    -- 更新钱
    local cLab = self.m_roadMain:findChild("m_lb_coins")

    util_playMoveToAction(self:getParent(), 15/30, cc.p(0,0))
    
    self:runAnim("start",false,function()  
        
        self:runCsbAction("shouji2")
        self.m_roadMain:runCsbAction("shouji2")
        
        cLab:setString(util_formatCoinsLN(_currCoins,30))
        self:updateLabelSize({label=cLab, sx = 0.65, sy = 0.65}, 656)

        performWithDelay(self.m_spine,function()
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_23)
            performWithDelay(self,function()
                if _totalCoins ~= _currCoins then
                    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_24)
                end
                local addValue = (_totalCoins - _currCoins) / 60
                util_jumpNumLN(cLab, _currCoins, _totalCoins, addValue, 1 / 60, {30}, nil, nil, function()
                    cLab:setString(util_formatCoinsLN(_totalCoins,30))
                    self:updateLabelSize({label=cLab, sx = 0.65, sy = 0.65}, 656)
        
                    if type(_func) == "function" then
                        _func()
                        _func = nil
                    end
        
                end, function()
                    self:updateLabelSize({label=cLab, sx = 0.65, sy = 0.65}, 656)
                end)
            end,(135 - 40)/60)
        end,40/60)
        
    end)
    
   
end

--[[
    默认按钮监听回调
]]
function JungleJauntColorfulItem:clickFunc(sender)

    --点击屏蔽
    if self.m_isClicked or self.m_parentView.m_isEnd or self.m_parentView.m_isEndClick then
        return
    end
    self.m_isClicked = true
    --点击道具回调
    self.m_parentView:clickItemFunc(self)
end

--[[
    执行动画
]]
function JungleJauntColorfulItem:runAnim(aniName,loop,func)
    if not loop then
        loop = false
    end
    self.m_curAniName = aniName
    self:runCsbAction(aniName,loop,func)
    -- 若为spine动画用下面的逻辑
    -- util_spinePlay(self.m_spine,aniName,loop)
    -- if type(func) == "function" then
    --     util_spineEndCallFunc(self.m_spine,aniName,function()
    --         func()
    --     end)
    -- end
end

--[[
    判定是否为相同类型
]]
function JungleJauntColorfulItem:isSameType(rewardType)
    if rewardType == self.m_curRewardType then
        return true
    end

    return false
end

function JungleJauntColorfulItem:setRoadMain(_roadMain)
    self.m_roadMain = _roadMain
end

return JungleJauntColorfulItem