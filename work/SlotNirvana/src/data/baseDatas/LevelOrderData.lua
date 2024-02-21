--升级奖励显示顺序
local LevelOrderData = class("LevelOrderData")

LevelOrderData.p_name = nil         -- 名字 类型
LevelOrderData.p_position = nil     -- 顺序
LevelOrderData.p_openLevel = nil    -- 开启等级
LevelOrderData.p_closeLevel = nil   -- 关闭等级
LevelOrderData.p_open = nil         -- 是否开启

function LevelOrderData:ctor()

end
--是否开启
function LevelOrderData:isOpen()
    if self.p_openLevel and self.p_open then
        local curLevel = globalData.userRunData.levelNum
        if self.p_open == 1 and curLevel>=self.p_openLevel and curLevel<self.p_closeLevel then
            return true
        end
    end
    return false
end
return  LevelOrderData