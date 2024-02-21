---
--xcyy
--2018年5月23日
--OZBonus_LittleNode.lua

local OZBonus_LittleNode = class("OZBonus_LittleNode",util_require("base.BaseView"))

local lucky_id = 1
local Major_id = 2
local Minor_id = 3
local Mini_id = 4
local Txt_id = 5

local csbNameList = {"OZ_wheel_lucky","OZ_wheel_Major","OZ_wheel_Minor","OZ_wheel_Mini","OZ_Wheel_text_0"}

OZBonus_LittleNode.m_posindex = nil

function OZBonus_LittleNode:initUI(data)


   self.m_posindex = data.posIndex
        

    local csbPath =  csbNameList[data.csbid] 
    self:createCsbNode(csbPath ..".csb")


    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end


function OZBonus_LittleNode:onEnter()
 

end

function OZBonus_LittleNode:showAdd()
    
end
function OZBonus_LittleNode:onExit()
 
end

--默认按钮监听回调
function OZBonus_LittleNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return OZBonus_LittleNode