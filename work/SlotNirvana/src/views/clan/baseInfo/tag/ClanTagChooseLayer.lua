--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-26 14:32:16
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-26 14:32:31
FilePath: /SlotNirvana/src/views/clan/baseInfo/tag/ClanTagChooseLayer.lua
Description: 公会 标签选择弹板
--]]
local ClanTagChooseLayer = class("ClanTagChooseLayer", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanTagChooseLayer:ctor()
    ClanTagChooseLayer.super.ctor(self)

    self:setExtendData("ClanTagChooseLayer") 
    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/ClubEstablish/Club_Choice.csb")
    self:addClickSound("btn_confirm", SOUND_ENUM.SOUND_HIDE_VIEW)
end

function ClanTagChooseLayer:initDatas(_list)
    ClanTagChooseLayer.super.initDatas(self)

    self.m_updateTagListFunc = function() end
    self.m_hadSelList = _list or {}
    self.m_tagNodeList = {}
end

function ClanTagChooseLayer:initView()
    ClanTagChooseLayer.super.initView(self)
    
    -- 所有tagUI
    self:initTagListUI()
    -- tag 数量Info
    self:updateTagNumUI()
end

-- 所有tagUI
function ClanTagChooseLayer:initTagListUI()
    for i=1, 9 do
        local parent = self:findChild("node_style"..i)
        local view = util_createView("views.clan.baseInfo.tag.ClanTagCellView", i, self)
        parent:addChild(view)
        self.m_tagNodeList[i] = view
    end
end
-- tag 数量Info
function ClanTagChooseLayer:updateTagNumUI()
    local lbTagNum = self:findChild("lb_tagNum")
    lbTagNum:setString(#self.m_hadSelList .. "/" .. ClanConfig.TAG_CAN_CHOOSE_MAX)
end

function ClanTagChooseLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_confirm" then
        self.m_updateTagListFunc(self.m_hadSelList)
        self:closeUI()
    end
end

function ClanTagChooseLayer:addNewTag(_aTag)
    table.insert(self.m_hadSelList, _aTag)
    self:updateTagNumUI()
end
function ClanTagChooseLayer:removeTag(_rTag)
    for _idx, _tag in pairs(self.m_hadSelList) do
        if tostring(_rTag) == tostring(_tag) then
            table.remove(self.m_hadSelList, _idx)
            break
        end
    end
    self:updateTagNumUI()
end
function ClanTagChooseLayer:removeFirstTag()
    if #self.m_hadSelList < 1 then
        return
    end
    local idx = table.remove(self.m_hadSelList, 1)
    self.m_tagNodeList[tonumber(idx)]:updateSelVisible()
    self:updateTagNumUI()
end
-- 监测tag是否已经选择
function ClanTagChooseLayer:checkHadSelect(_idx)
    local bExit = false
    for _, _tag in pairs(self.m_hadSelList) do
        if tostring(_idx) == tostring(_tag) then
            bExit = true
            break
        end
    end

    return bExit
end
function ClanTagChooseLayer:checkTagListFull()
    return #self.m_hadSelList == ClanConfig.TAG_CAN_CHOOSE_MAX
end

-- 更新 tagList方法
function ClanTagChooseLayer:setUpdateTagListFunc(_cb)
    if type(_cb) == "function" then 
        self.m_updateTagListFunc = _cb
    end
end

return ClanTagChooseLayer