---
--xcyy
--2018年5月23日
--OrcaCaptainColorfulItem.lua
local PublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainColorfulItem = class("OrcaCaptainColorfulItem",util_require("Levels.BaseLevelDialog"))


function OrcaCaptainColorfulItem:initUI(params)
    self.m_parentView = params.parentView
    self.m_itemID = params.itemID     --索引ID
    self.m_isClicked = false    --是否已经点击

    -- self:createCsbNode("jackpotColorfulItem.csb")

    self.m_curRewardType = ""   --当前奖励类型
    self.m_curAniName = ""  --当前时间线

    self.goldSpine = util_spineCreate("OrcaCaptain_dfdc_jinbi", true, true)
    self:addChild(self.goldSpine)

    local coinsView = util_createAnimation("OrcaCaptain_dfdc_0.csb")
    util_spinePushBindNode(self.goldSpine,"wenzi",coinsView)
    self.goldSpine.coinsView = coinsView

    self:runUnClickIdleAni()
    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(150,150))
    layout:setTouchEnabled(true)
    self:addClick(layout)
    -- self:addClick(self:findChild("click"))
end

--[[
    设置具体的jackpot显示
]]
function OrcaCaptainColorfulItem:setJackpotTypeShow(rewardType)
    if self.goldSpine.coinsView then
        self.goldSpine.coinsView:findChild("mini"):setVisible(rewardType == "mini")
        self.goldSpine.coinsView:findChild("minor"):setVisible(rewardType == "minor")
        self.goldSpine.coinsView:findChild("major"):setVisible(rewardType == "major")
        self.goldSpine.coinsView:findChild("mega"):setVisible(rewardType == "mega")
        self.goldSpine.coinsView:findChild("grand"):setVisible(rewardType == "grand")
        self.goldSpine.coinsView:runCsbAction("idle")
    end
    self.m_curRewardType = rewardType
end

--[[
    重置显示及状态
]]
function OrcaCaptainColorfulItem:resetStatus()
    --重置层级
    self:getParent():setLocalZOrder(self.m_itemID)
    self.m_isClicked = false 
    self.m_curRewardType = ""
    self.m_curAniName = ""
    
    self:runUnClickIdleAni()
    -- 
    --设置默认显示
    self:setJackpotTypeShow("default")
end

--[[
    未打开状态idle
]]
function OrcaCaptainColorfulItem:runUnClickIdleAni()
    -- util_spinePlay(self.goldSpine, "idleframe",true)
    self:runAnim("idleframe",true)
end

--[[
    打开状态idle
]]
function OrcaCaptainColorfulItem:runClickedIdleAni()
    -- util_spinePlay(self.goldSpine, "idleframe2",true)
    self:runAnim("idleframe2",true)
end



--[[
    晃动idle
]]
function OrcaCaptainColorfulItem:runShakeAni(func)
    -- self:runAnim("idleframe3",false,function()
    --     self:runUnClickIdleAni()
    -- end)
end

--[[
    压黑动画
]]
function OrcaCaptainColorfulItem:runDarkAni()
    local startName = "darkstart"
    local idleName = "darkidle"
    if self.m_curAniName == "idleframe2" then
        startName = "darkstart2"
        idleName = "darkidle2"
    end
    util_setCascadeOpacityEnabledRescursion(self.goldSpine, true)
    util_setCascadeColorEnabledRescursion(self.goldSpine, true)
    self:runAnim(startName,false,function ()
        self:runAnim(idleName,true)
    end)
    -- util_spinePlay(self.goldSpine,startName)
    -- util_spineEndCallFunc(self.goldSpine,startName,function()
    --     util_spinePlay(self.goldSpine,idleName,true)
    -- end)
    if self.goldSpine.coinsView then
        self.goldSpine.coinsView:runCsbAction("darkstart",false,function ()
            self.goldSpine.coinsView:runCsbAction("darkidle",true)
        end)
    end
end

--[[
    显示奖励
]]
function OrcaCaptainColorfulItem:showRewardAni(rewardType,func)
    self:setJackpotTypeShow(rewardType)
    self:runAnim("switch",false,function ()
        self:runClickedIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示中奖动效
]]
function OrcaCaptainColorfulItem:getRewardAni(func)
    --中奖时对应的节点提到最上层
    self:getParent():setLocalZOrder(100 + self.m_itemID)
    self:runAnim("actionframe",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    默认按钮监听回调
]]
function OrcaCaptainColorfulItem:clickFunc(sender)
    --点击屏蔽
    if self.m_isClicked or self.m_parentView.m_isEnd then
        return
    end

    self.m_isClicked = true
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_color_click)
    --点击道具回调
    self.m_parentView:clickItem(self)
end

--[[
    执行动画
]]
function OrcaCaptainColorfulItem:runAnim(aniName,loop,func)
    if not loop then
        loop = false
    end
    self.m_curAniName = aniName
    -- self:runCsbAction(aniName,loop,func)
    -- 若为spine动画用下面的逻辑
    util_spinePlay(self.goldSpine,aniName,loop)
    if type(func) == "function" then
        util_spineEndCallFunc(self.goldSpine,aniName,function()
            func()
        end)
    end
end

--[[
    判定是否为相同类型
]]
function OrcaCaptainColorfulItem:isSameType(rewardType)
    if rewardType == self.m_curRewardType then
        return true
    end

    return false
end

return OrcaCaptainColorfulItem