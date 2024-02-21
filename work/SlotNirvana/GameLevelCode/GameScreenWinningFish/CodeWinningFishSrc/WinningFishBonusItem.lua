--[[
    收集玩法按钮
]]

local WinningFishBonusItem = class("WinningFishBonusItem",util_require("base.BaseView"))

local FISH_TAG         =       1001

local FISH_NAME = {
    "WinningFish_shoujiyu_01_1",
    "WinningFish_shoujiyu_03_3",
    "WinningFish_shoujiyu_05_5",
    "WinningFish_shoujiyu_07_7",
    "WinningFish_shoujiyu_09_9",
    "WinningFish_shoujiyu_11_11",
    "WinningFish_shoujiyu_13_13",
    "WinningFish_shoujiyu_15_15",
    "WinningFish_shouji_baoxiang_1"      
}

local FISH_RES_GRAY = {
    "common/WinningFish_shoujiyu_02.png",
    "common/WinningFish_shoujiyu_04.png",
    "common/WinningFish_shoujiyu_06.png",
    "common/WinningFish_shoujiyu_08.png",
    "common/WinningFish_shoujiyu_10.png",
    "common/WinningFish_shoujiyu_12.png",
    "common/WinningFish_shoujiyu_14.png",
    "common/WinningFish_shoujiyu_16.png",
    "common/WinningFish_shouji_baoxiang.png"        --宝箱 后期改资源
}


function WinningFishBonusItem:initUI(params)
    self:createCsbNode("Socre_WinningFish_Bonus.csb")

    self:runCsbAction("idleframe",true,nil,60) 

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(100,100))
    layout:setTouchEnabled(true)
    self:addClick(layout)

    self.sp_icon = self:findChild("WinningFish_shoujit_yushi_03_1")

    self.m_callBack = params and params.callBack       --按钮回调
    self.m_index = params and params.index             --当前索引
end


function WinningFishBonusItem:onEnter()

end

function WinningFishBonusItem:onExit()

end

--[[
    刷新UI
]]
function WinningFishBonusItem:refreshUI(resultData)
    self.sp_icon:setVisible(true)
    self:findChild("Node_2"):removeAllChildren(true)
    self:pauseForIndex(175)

    local bonus = resultData.p_bonus
    if not bonus then
        return
    end

    local index = table.indexof(bonus.choose,self.m_index)
    if index then
        local fishID = tonumber(bonus.content[index])
        self:refreshFish(fishID,2)
    end
end

--[[
    刷新金鱼
]]
function WinningFishBonusItem:refreshFish(fishID)
    self.sp_icon:setVisible(false)
    

    local node = self:findChild("Node_2")
    node:removeAllChildren(true)
    local menu = util_createAnimation("Socre_WinningFish_Bonus_menu_0.csb")
    for index,name in pairs(FISH_NAME) do
        menu:findChild(name):setVisible(index == fishID)
    end
    node:addChild(menu)
    menu:runCsbAction("idle_a",false)

    self:runCsbAction("idle2",false)
end

--[[
    执行开启动画
]]
function WinningFishBonusItem:runOpenAni(fishID,func1,func2)
    local node = self:findChild("Node_2")
    node:removeAllChildren(true)

    local menu = util_createAnimation("Socre_WinningFish_Bonus_menu_0.csb")
    for index,value in pairs(FISH_NAME) do
        menu:findChild(value):setVisible(index == fishID)
    end
    menu:runCsbAction("idle",false)
    node:addChild(menu)
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameIndex = 230,    --关键帧数  帧动画用
                    callBack = function(  )
                        if type(func1) == "function" then
                            func1()
                        end
                    end,
                }       --关键帧回调
            },   
            callBack = function( )
                self:runCsbAction("idle2",false)
                util_runAnimations({
                    {
                        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                        node = menu,   --执行动画节点  必传参数
                        actionName = "start", --动作名称  动画必传参数,单延时动作可不传
                        fps = 60,    --帧率  可选参数
                    },
                    {
                        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                        node = menu,   --执行动画节点  必传参数
                        actionName = "idle_a", --动作名称  动画必传参数,单延时动作可不传
                        fps = 60,    --帧率  可选参数
                    }
                })
                if type(func2) == "function" then
                    func2()
                end
            end,   --回调函数 可选参数
        }
    })  
end

--[[
    摇摆动画
]]
function WinningFishBonusItem:runSwingAni( )
    self:runCsbAction("idleframe",false)
end


--[[
    点击回调
]]
function WinningFishBonusItem:clickFunc(sender)
    if type(self.m_callBack) == "function" then
        self:m_callBack(sender,self.m_index)
    end
end

return WinningFishBonusItem