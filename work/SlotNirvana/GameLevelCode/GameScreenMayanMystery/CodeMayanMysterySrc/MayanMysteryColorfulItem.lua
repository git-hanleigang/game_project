---
--xcyy
--2018年5月23日
--MayanMysteryColorfulItem.lua
local PublicConfig = require "MayanMysteryPublicConfig"
local MayanMysteryColorfulItem = class("MayanMysteryColorfulItem",util_require("base.BaseView"))


function MayanMysteryColorfulItem:initUI(params)
    self.m_parentView = params.parentView
    self.m_itemID = params.itemID     --索引ID
    self.m_isClicked = false    --是否已经点击

    self:createCsbNode("MayanMystery_wanfa_pick.csb")

    self.m_curRewardType = ""   --当前奖励类型
    self.m_curAniName = ""  --当前时间线

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(200,170))
    layout:setTouchEnabled(true)
    self:addClick(layout)
end

--[[
    获取ID
]]
function MayanMysteryColorfulItem:getItemID()
    return self.m_itemID
end
--[[
    设置具体的jackpot显示
]]
function MayanMysteryColorfulItem:setJackpotTypeShow(rewardType, isNotDark)
    if rewardType ~= "" then
        self:findChild("Node_doublepick"):setVisible(rewardType == "Double")
        self:findChild("Node_rpizeupgrade"):setVisible(rewardType == "UPGRADE")
        if isNotDark then
            self:runAnim("idle1",true)
        else
            self:runAnim("dark_idle",true)
        end
    else
        self:runAnim("idle3", false)
    end

    self.m_curRewardType = rewardType
end

--[[
    重置显示及状态
]]
function MayanMysteryColorfulItem:resetStatus(rewardType)
    --默认空串,后期根据服务器数据进行修改
    if rewardType == "" then
        self.m_isClicked = false 
    else
        self.m_isClicked = true 
    end
    
    self.m_curRewardType = ""
    self.m_curAniName = ""

    --设置默认显示
    self:setJackpotTypeShow(rewardType, true)
end

--[[
    未打开状态idle
]]
function MayanMysteryColorfulItem:runUnClickIdleAni()
    self:runAnim("idle", false)
end

--[[
    打开状态idle
]]
function MayanMysteryColorfulItem:runClickedIdleAni()
    self:runAnim("idle1",true)
end

--[[
    晃动idle
]]
function MayanMysteryColorfulItem:runShakeAni()
    self:runUnClickIdleAni()
end

--[[
    压黑动画
]]
function MayanMysteryColorfulItem:runDarkAni()
    self:runAnim("dark", false, function()
        self:runAnim("dark_idle", true)
    end)
end

--[[
    显示奖励
]]
function MayanMysteryColorfulItem:showRewardAni(rewardType,func)
    self:setJackpotTypeShow(rewardType, true)
    self:runAnim("dianji",false,function ()
        self:runClickedIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示中奖动效
]]
function MayanMysteryColorfulItem:getRewardAni()
    self:runAnim("actionframe")
end

--[[
    默认按钮监听回调
]]
function MayanMysteryColorfulItem:clickFunc(sender)
    --点击屏蔽
    if self.m_isClicked or self.m_parentView.m_isEnd or self.m_parentView.m_isWaiting then
        return
    end

    self.m_isClicked = true

    --点击道具回调
    self.m_parentView:clickItem(self)
end

--[[
    执行动画
]]
function MayanMysteryColorfulItem:runAnim(aniName,loop,func)
    if not loop then
        loop = false
    end
    self.m_curAniName = aniName
    self:runCsbAction(aniName,loop,func)
end

--[[
    判定是否为相同类型
]]
function MayanMysteryColorfulItem:isSameType(rewardType)
    if rewardType == self.m_curRewardType then
        return true
    end

    return false
end

return MayanMysteryColorfulItem