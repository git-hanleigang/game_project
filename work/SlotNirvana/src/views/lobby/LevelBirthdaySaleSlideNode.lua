--[[
    生日礼物促销 轮播图
--]]
local LevelBirthdaySaleSlideNode = class("LevelBirthdaySaleSlideNode", BaseView)

function LevelBirthdaySaleSlideNode:getCsbName()
    return "Activity_Birthday/Promotion/Icons/Promotion_BirthdaySlide.csb"
end

function LevelBirthdaySaleSlideNode:initUI()
    LevelBirthdaySaleSlideNode.super.initUI(self)

    self:runCsbAction("idle", true)
end

--点击回调
function LevelBirthdaySaleSlideNode:MyclickFunc()
    self:clickLayer()
end

function LevelBirthdaySaleSlideNode:clickLayer()
    G_GetMgr(ACTIVITY_REF.Birthday):showBirthdayPromotionLayer()
end

return LevelBirthdaySaleSlideNode