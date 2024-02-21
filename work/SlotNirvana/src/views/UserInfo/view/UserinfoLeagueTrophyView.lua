--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-07 14:47:54
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-07 14:48:23
FilePath: /SlotNirvana/src/views/UserInfo/view/UserinfoLeagueTrophyView.lua
Description: 比赛 巅峰赛中奖 奖杯信息
--]]
local TrophyInfoView = class("TrophyInfoView", BaseView)
function TrophyInfoView:initDatas(_data, _idx)
    TrophyInfoView.super.initDatas(self)
    self._infoData = _data
    self._idx = _idx
end
function TrophyInfoView:getCsbName()
    return "Activity/csd/Information_Summit/Information_Summit_trophy.csb"
end
function TrophyInfoView:initUI()
    TrophyInfoView.super.initUI(self)

    -- 奖杯图
    self:initIconUI()
    -- 奖杯数量
    self:initNumberUI()
end

-- 奖杯图
function TrophyInfoView:initIconUI()
    local infoType = self._infoData:getType()
    for i=1,3 do
        local node = self:findChild("sp_icon" .. i)
        node:setVisible(i == self._idx)
    end
end

-- 奖杯数量
function TrophyInfoView:initNumberUI()
    local spReddot = self:findChild("sp_reddot")
    local number = self._infoData:getNumber()
    local lbNumber = self:findChild("lb_number")
    lbNumber:setString(number)
end


local UserinfoLeagueTrophyView = class("UserinfoLeagueTrophyView", BaseView)
function UserinfoLeagueTrophyView:initDatas()
    UserinfoLeagueTrophyView.super.initDatas(self)

    self._data = globalData.userRunData:getLeagueTrophyData()
end

function UserinfoLeagueTrophyView:initUI()
    UserinfoLeagueTrophyView.super.initUI(self)

    -- 所有 奖杯信息
    self:initAllTrophyUI()
end

function UserinfoLeagueTrophyView:getCsbName()
    return "Activity/csd/Information_Summit/Information_Summit_stash_trophy_bg.csb"
end

-- 所有 奖杯信息
function UserinfoLeagueTrophyView:initAllTrophyUI()
    local dataList = self._data:getTrophyList()
    for i=1, #dataList do
        local data = dataList[i]
        local node = self:findChild("node_trophy" .. i)
        if not node or not data then
            break
        end

        local view = TrophyInfoView:create()
        view:initData_(data, i)
        node:addChild(view)
    end
end

return UserinfoLeagueTrophyView
