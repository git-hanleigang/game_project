--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-05-09
--
local LuaList = require("common.LuaList")
local FindItemInfo = require "data.baseDatas.FindItemInfo"
local FindData = class("FindData")

FindData.p_findNum = nil      --当前收集数量
FindData.p_maxNum = nil       --最大收集数量
FindData.p_findItems = nil    --物品信息
FindData.p_helps = nil        --剩余次数
FindData.p_IsNewItem = nil    --是否检索到新物品
FindData.p_seconds = nil      --额外增加倒计时秒数
FindData.p_deadline = nil     --额外增加倒计时过期时间

FindData.p_lostSeconds = nil  --find小游戏中剩余倒计时
FindData.p_hadFinds = nil     --find小游戏中找到的物品id
FindData.p_useGuide = nil     --find小游戏引导，是否完成
FindData.p_difficulty = nil   --find活动掉落难度级别
FindData.p_amount = nil       --find活动期间支付累计
FindData.p_allItems = nil     --所有物品信息
FindData.p_activityId = nil   --活动id

FindData.p_newItemQueue = nil --新增物品队列
FindData.m_IsInitData = nil   --该数据是否已同步数据
FindData.m_showPromotionView = false

FindData.m_newItemData = nil

FindData.m_showFindViewAgain = nil

function FindData:ctor()
      self.p_newItemQueue = LuaList.new()
      self.p_allItems = {}
end

function FindData:parseData(data)
      self.p_findNum = data.findNum
      self.p_maxNum = data.maxNum

      --物品信息
      if self.p_findItems == nil or self.p_findNum == 0 then
            self.p_findItems = {}
      end

      --每次同步FindData，都计算一下，找出那些物品是新找到的
      self:clearNewItemQueue()
      if data.findItems ~= nil and data.findItems ~= "" then
            local d = data.findItems
            if d ~= nil and #d > 0 then
                  self.m_newItemData = {}
                  for i=1,#d do
                        local itemId = tonumber(d[i].itemId)
                        local sale = self:getItemInfo(itemId)
                        if sale == nil then
                              local sale = FindItemInfo:create()
                              sale:parseData(d[i])
                              self.p_findItems[#self.p_findItems+1] = sale
                              self.p_newItemQueue:push(sale)

                              self.m_newItemData[#self.m_newItemData+1] = sale
                        else
                              sale:parseData(d[i])
                        end
                  end
            end
      end

      --获得所有道具
      if data.allItems ~= nil and data.allItems ~= "" then
            local d = data.allItems
            if d ~= nil and #d > 0 then
                  self.p_allItems = {}
                  for i=1,#d do
                        local sale = FindItemInfo:create()
                        sale:parseData(d[i])
                        self.p_allItems[#self.p_allItems+1] = sale
                  end
            end
      end

      if data.helps < 0 then
            self.p_helps = 0
      else
            self.p_helps = data.helps
      end

      self.p_IsNewItem = data.getItem
      self.p_seconds = data.seconds
      self.p_deadline = tonumber(data.deadline)

      self.p_lostSeconds = data.lostSeconds
      if data.hadFinds ~= nil and #data.hadFinds > 0 then
            self.p_hadFinds = {}
            for i=1,#data.hadFinds do
                  self.p_hadFinds[#self.p_hadFinds+1] = data.hadFinds[i]
            end
      else
            self.p_hadFinds = nil
      end
      self.p_useGuide = data.useGuide
      self.p_difficulty = data.difficulty
      self.p_amount = data.amount
      self.p_activityId = data.activityId
      self.m_IsInitData = true
end

--是否存在道具列表
function FindData:isExistAllItems()
      if self.p_allItems and #self.p_allItems >0 then
            return true
      end
      return false
end

--获取buff加成持续时间
function FindData:getExtraBuffExpire()
      local tempTime = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPY_FIND_EXTRATIME)
      return tempTime
end
--获取buff加成
function FindData:getExtraBuffTimes()
      local buffData = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPY_FIND_EXTRATIME)
      if buffData and buffData.buffDuration then
            local mul = tonumber(buffData.buffMultiple)
            if mul then
                  return mul
            end
      end
      return 0
end

function FindData:sendGetPropsLog()
      if self.m_newItemData and #self.m_newItemData > 0 then
            gLobalSendDataManager:getLogFindActivity():sendFindTaskLog(2, self.m_newItemData)
      end
end

--获得双倍持续时间
function FindData:getDoubleBuffExpire()
      local tempTime = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPY_FIND_DOUBLEPRIZE)
      return tempTime
end

--是否已经有了该物品数据
function FindData:getItemInfo(itemId)
      for i=1,#self.p_findItems do
            local d = self.p_findItems[i]
            if d and d.p_itemId == itemId then
                  return d
            end
      end

      return nil
end

--获取新查找到的物品信息
function FindData:getNewItemQueue()
      return self.p_newItemQueue
end

function FindData:clearNewItemQueue()
      self.p_newItemQueue:clear()
end

--判断是否集齐
function FindData:IsFinish()
      return self.p_findNum == self.p_maxNum
      -- return self.p_findNum == self.p_maxNum and self.p_IsNewItem
end

--完成弹窗主动关闭，将标识更新
function FindData:unenableNewItem()
      self.p_IsNewItem = false
end

--获取分页数据
function FindData:getPageData(page)
      local ret = {}
      if not self.p_findItems or #self.p_findItems <= 0 then
            return ret
      end

      local startIndex = (page-1) * FINDITEM_MAX_COUNT
      if startIndex > #self.p_findItems then
            return ret
      end

      local endIndex = page*FINDITEM_MAX_COUNT
      if endIndex > #self.p_findItems then
            endIndex = #self.p_findItems
      end

      for i=startIndex,endIndex do
            ret[#ret+1] = self.p_findItems[i]
      end


      return ret
end

--是否需要恢复findView
function FindData:IsNeedRecovery()
      if self.p_useGuide and  self.p_hadFinds ~= nil and #self.p_hadFinds > 0 then
            return true
      end

      return false
end
function FindData:addFindedItem(itemId)
      if not self.p_hadFinds then
            self.p_hadFinds = {}
      end
      self.p_hadFinds[#self.p_hadFinds+1] = itemId
end


--是否有数据
function FindData:IsHaveData()
      return self.m_IsInitData ~= nil
end

return  FindData