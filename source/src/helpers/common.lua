function ternary(cond, T, F)
	if cond then return T else return F end
end

function print(a, depth, k, l)
	if depth ~= nil and l ~= nil and l > depth then return end
	if k == 'unit' or k == 'export' or k == '__index' then return end
	if l == nil then l = 0 end
	ls = string.rep(' - ', l)
	l = l + 1
	if type(a) == "table" then
		if k == nil then
			system.print(ls..'[table]')
		else
			system.print(ls..'['..k..'] [table]')
		end
		for key,val in pairs(a) do
			print(val, depth, key, l)
		end
	else
		local v = ''
		--print(type(a))
		if type(a) == "function" then
			v = "[function]"
		elseif type(a) == "thread" then
			v = "[thread]"
		elseif type(a) == "boolean" then
			v = ternary(a, "TRUE", "FALSE")
		elseif type(a) == "nil" then
			v = "[nil]"
		else
			v = a
		end
		if k == nil then
			--system.print(ls..'['..type(v)..'] '..v)
			system.print(ls..v)
		else
			system.print(ls..'['..k..'] '..tostring(v))
		end
	end
end
			
function printDistance(meters, larger)
	if meters == nil then return 'NaN' end
	if larger == nil then larger = false end
	local absMeters = math.abs(meters)
	if absMeters < ternary(larger, 1000, 10000) then
		return utils.round(meters)..' m'
	elseif absMeters < 200000 then
		local km = meters / 1000
		if km > 10 then
			return utils.round(km, 1)..' km'
		else
			return utils.round(km, 0.1)..' km'
		end
	else
		local su = meters / 200000
		if su > 10 then
			return utils.round(su, 1)..' su'
		else
			return utils.round(su, 0.1)..' su'
		end
	end
end

-- Add thousand separators
function thousands(a)
	local formatted = tostring(a)
	if a == nil then return a end
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
		if (k==0) then
			break
		end
	end
	return formatted
end

function split(str, pat)
	if str == nil then return str end
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t, cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end

function capitalise(str)
	return (str:gsub("^%l", string.upper))
end

function formatTimeString(seconds)
	if type(seconds) ~= 'number' then return seconds end
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds / 60 / 60 % 24)
	local minutes = math.floor(seconds / 60 % 60)
	local seconds = math.floor(seconds % 60)
	if seconds < 0 or hours < 0 or minutes < 0 then
		return "0s"
	end
	if days > 0 then 
		return days .. "d " .. hours .."h"
	elseif hours > 0 then
		return hours .. "h " .. minutes .. "m"
	elseif minutes > 0 then
		return minutes .. "m " .. seconds .. "s"
	else
		return seconds .. "s"
	end
end