local UserInfoData = class("UserInfoData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function UserInfoData:ctor()
    self.defult_head = 1
    self.head_list = {0, 1, 20, 21, 22, 23, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19}
    self.avter_list = {}
    self.avter_Idlist = {}
    self.chooseItem = {}
end

function UserInfoData:getHeadList()
	return self.head_list
end
function UserInfoData:setDefultHead(_idx)
    self.defult_head = _idx
end

function UserInfoData:getDefultHead()
    return self.defult_head
end

function UserInfoData:getBagItem()
	return self.bagItems or {}
end

function UserInfoData:getChooseItem()
	return self.chooseItem
end

function UserInfoData:setChooseItem(_item)
	self.chooseItem = _item
end

function UserInfoData:paseBagItem(_data)
	self.bagItems = {}
	if _data ~= nil and #_data > 0 then
		for i,v in ipairs(_data) do
			local item = self:paseItem(v)
			table.insert(self.bagItems,item)
		end
		self.chooseItem = self.bagItems[1]
	end
end

function UserInfoData:paseItem(_data)
	-- body
	local item = {}
	if _data ~= nil then
		local info = _data.item.itemInfo
		item.name = info.name
		item.num = _data.item.num
		item.description = info.description
		item.id = _data.item.id
		local open = _data.open
		item.open = open
		item.activityId = _data.item.activityId

		local shopData = ShopItem:create()
		shopData:parseData(_data.item)
		shopData.p_mark = nil
		local shop = shopData
		item.shop = shop
	end
	return item
end

function UserInfoData:getCashData()
	return G_GetMgr(G_REF.AvatarFrame):getData():getOpenSlotIdList()
end

function UserInfoData:getAvterList()
	local data = G_GetMgr(G_REF.AvatarFrame):getFrameStaticData()
    local item_list = data.m_frameCfg_slot.m_cfgFrameIdInfoList
	return item_list
end

function UserInfoData:getDefultAvr()
	local id = G_GetMgr(G_REF.UserInfo):getChooseAvr()
	local avr_list = G_GetMgr(G_REF.UserInfo):getCfAllList()
	local _data = {}
	for i,v in ipairs(avr_list) do
		if id == v.id then
			_data = v
		end
	end
	return _data
end

return UserInfoData