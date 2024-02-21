--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-25 17:42:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-25 18:21:18
FilePath: /SlotNirvana/src/views/clan/baseInfo/region/ClanRegionView.lua
Description: 公会 选择地区界面
--]]
local ClanRegionView = class("ClanRegionView", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRegionView:getCsbName()
    return "Club/csd/ClubEstablish/Club_Create_team_Info_Show.csb"
end

function ClanRegionView:initCsbNodes()
    ClanRegionView.super.initCsbNodes(self)
end

function ClanRegionView:initUI()
    ClanRegionView.super.initUI(self)

    self:initTableView()
    self:hide()
end

function ClanRegionView:initTableView()
    local listView = self:findChild("ListView_1")
    listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)
    listView:onScroll(handler(self, self.onScrollEvt))
    self.m_listView = listView
    self.m_choosePosW = cc.p(0, 0)
end

function ClanRegionView:updateByType(_type, _hadSelType)
    self.m_hadSelType = _hadSelType
    if _type ~= self.m_type then
        self.m_chooseTag = 4
        self.m_type = _type
        self:reloadByType(self.m_type)
    end

    self.m_bTouch = false
    self:setVisible(true)
    self:runCsbAction("start", false, function() 
        self.m_bTouch = true

        local refNode = self:findChild("sp_region_bg2")
        local posW = refNode:convertToWorldSpaceAR(cc.p(0, 0))
        self.m_choosePosW = posW
    end, 60)
    gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.REGION_LIST_OPEN)
end

function ClanRegionView:reloadByType(_type)
    local data = clone(ClanManager:getStdCountryData(_type))
    for i=1, 3 do
        table.insert(data, 1, "")
        table.insert(data, "")
    end

    self:updateUI(data)
    self.m_curDataList = data
end

function ClanRegionView:updateUI(_list)
    self.m_listView:removeAllItems()
    local chooseNode = nil
    for i = 1, #_list do
        local layout = ccui.Layout:create()
        local view = util_createView("views.clan.baseInfo.region.ClanRegionCell")
        view:setName("ClanRegionCell")
        view:updateUI(_list[i])
        layout:addChild(view)
        layout:setContentSize(cc.size(280,60))
        view:move(280*0.5, 60*0.5)
        layout:setTag(i-1)
        if _list[i] == self.m_hadSelType then
            chooseNode = layout
        end
        self.m_listView:pushBackCustomItem(layout)
    end

    if self.m_hadSelType and #self.m_hadSelType > 0 then
        self:moveToEntryNode(chooseNode)
    end
end

function ClanRegionView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_confirm" and self.m_bTouch then
        self.m_bTouch = false
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        
        local data = self:getChooseData() or ""
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.UPDATE_CHOOSE_REGION_UI, {self.m_type, data})
        self:runCsbAction("over", false, util_node_handler(self, self.hide), 60)
        gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.REGION_LIST_OPEN)
    end
end

-- 添加 listView滑动事件
function ClanRegionView:onScrollEvt(event)
    local innerNode = self.m_listView:getInnerContainer()
    local localPos = innerNode:convertToNodeSpace(self.m_choosePosW)
    local children = self.m_listView:getChildren()
    local bMoveEnd = false
    -- SCROLLING_BEGAN 手动滑的 结束后矫正下位置
    if event.eventType == 10 then
        self.m_bCalcMoveCorrectNode = true
        self:clearCalcMoveEndAct()
        self.m_beganLocalPos = localPos
        local preNode = innerNode:getChildByTag(self.m_chooseTag-1)
        if preNode then
            preNode:getChildByName("ClanRegionCell"):stopSwing()
        end
        self.m_preChooseTag = self.m_chooseTag
        self.m_bTouch = false
    elseif event.eventType == 11 or event.eventType == 12 then
        local bScrolling = self.m_listView:isAutoScrolling() -- 只需要判断 autoScroll就行
        if bScrolling then
            -- 由于惯性还得滑动一段时间，滑动时间太长了 0.3后就不让滑动了
            local stopTime = 0
            local movePosY = math.abs(localPos.y - self.m_beganLocalPos.y)
            if movePosY > 150 then
                stopTime = 0.5
            elseif movePosY > 50 then
                stopTime = 0.3
            end
            self.m_calcMoveEndAct =
                performWithDelay(
                self,
                function()
                    self.m_listView:stopAutoScroll()
                    local event = {}
                    event.target = self.m_listView
                    event.eventType = 12
                    self:onScrollEvt(event)
                end,
                stopTime
            )
        end

        bMoveEnd = not bScrolling
    elseif event.eventType == 9 and self.m_bCalcMoveCorrectNode then
        local correctNode = self:getCorrectNode(localPos, children)
        local chooseTag = correctNode:getTag()+1
        if self.m_preChooseTag ~= chooseTag then
            gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.REGION_LIST_SCROLL)
        end
        self.m_preChooseTag = chooseTag
    end

    -- 滑动结束 并且手动滑动的才需要矫正
    if bMoveEnd and self.m_bCalcMoveCorrectNode then
        local correctNode = self:getCorrectNode(localPos, children)
        self:moveToEntryNode(correctNode)
    end
end

function ClanRegionView:getCorrectNode(_localPos, _children)
    local correctNode = nil
    local preSubY = nil
    -- local upDown = _localPos.y - self.m_beganLocalPos.y < 0 and "up" or "down"
    for idx, node in ipairs(_children) do
        local nodeRefY = node:getPositionY()  + 30
        -- if upDown == "up" then
        --     nodeRefY = nodeRefY + 60
        -- end
        local subY = math.abs(_localPos.y - nodeRefY)
        if not preSubY then
            preSubY = subY
            correctNode = node
        end
        if preSubY > subY then
            preSubY = subY
            correctNode = node
        end
    end

    return correctNode
end

-- 移动到指定 node
function ClanRegionView:moveToEntryNode(_node)
    if not _node then
        return
    end

    -- 重置 计算矫正sign 移动完毕不矫正了
    self.m_bCalcMoveCorrectNode = false
    self.m_listView:jumpToItem(_node:getTag(), cc.p(0.5, 0.5), cc.p(0.5, 0.5))
    self.m_chooseTag = _node:getTag()+1
    _node:getChildByName("ClanRegionCell"):swingWord()
    self.m_bTouch = true
end

-- 清除 滑动结束后 自动结束滑动act
function ClanRegionView:clearCalcMoveEndAct()
    if self.m_calcMoveEndAct then
        self:stopAction(self.m_calcMoveEndAct)
    end
end

function ClanRegionView:hide()
    self:runCsbAction("hide")
    self:setVisible(false)
end

-- 获取选择好的 data
function ClanRegionView:getChooseData()
    local chooseData = self.m_curDataList[self.m_chooseTag]
    if not chooseData or #chooseData == 0 then
        chooseData = self.m_curDataList[4]
    end
    return chooseData
end

return ClanRegionView