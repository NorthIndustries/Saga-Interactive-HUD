svg = { }

AlignEnum = { }
AlignEnum.Middle = 'middle'

-- Input parameters
-- bool         data.visible        Button visibility
-- number       data.x              Button x coordinate
-- number       data.y              Button y coordinate
-- string       data.text           Button text content
-- number       data.height         Button height
-- number       data.width          Button width
-- number       data.padding        Inner padding to offset contents by -- Why isn't this a vec2?
-- AlignEnum    data.align          Text alignment - Only AlignEnum.Middle supported atm
-- number       data.fontSize       Font size in %
-- number       data.activeUpdate   Function to call every update which returns button active bool
-- number       data.rounding       The background rectangle rounding
-- bool         data.active         Button active state
-- bool         data.hover          Button hover state
-- [str,bool]   data.dataAttributes Array of additional data attributes with bool states
-- string       data.svg            Custom svg

-- Output parameters (written to)
-- number       data.screenX        Screen x position
-- number       data.screenY        Screen y position
function svg.BuildButton(data)
	local svgTag = ''
    -- Back out if not visible
	if data.visible == false then return svgTag end

    -- Set some defaults in case nils
	if data.height == nil then data.height = 3 end
	if data.width == nil then data.width = 3 end
	if data.padding == nil then data.padding = 1 end
	if data.x == nil then data.x = 0 end
	if data.y == nil then data.y = 0 end

    -- Update screen position
	data.screenX = data.x
	data.screenY = data.y

    -- Content position
	local btx = data.screenX + data.padding
	local bty = data.screenY + data.padding

    -- Call .activeUpdate if it exists
	if data.activeUpdate ~= nil then
		data.active = data.activeUpdate(data)
	end

    -- Classes
	local class = 'uiButton'
	if data.disabled then class = class .. ' disabled' end
	if data.class then class = class .. ' ' .. data.class end

    -- Text anchor
	local textAnchor = 'text-anchor: start;'
	if data.align == AlignEnum.Middle then
		btx = data.screenX + data.width / 2
		textAnchor = 'text-anchor: middle;'
	end

    -- Font size
	local fontSize = ''
	if data.fontSize ~= nil then fontSize = 'font-size: '..data.fontSize..'%; ' end

    -- Rounding
	local r = ternary(data.rounding == nil, '', rx(data.r))

    -- Data-attributes
	local active = 'data-active="'.. ternary(data.active, 'true', 'false') .. '"'
	local hover = 'data-hover="'.. ternary(data.hover, 'true', 'false') .. '"'
    
    -- Additional data-attributes
	local dataStrings = {}
	if data.dataAttributes ~= nil then
		for dataName,state in pairs(data.dataAttributes) do
			table.insert(dataStrings, 'data-'..dataName..'="'..ternary(state, 'true', 'false')..'"')
		end
	end
	local dataString = table.concat(dataStrings, ' ')

    -- Build the SVG
    -- Group for easier targeting
	svgTag = svgTag .. '<g class="'..class..'" '..active..' '..hover..' '..dataString..'>'
    -- Background rectangle
	svgTag = svgTag .. '<rect'..r..' x="'..(data.screenX)..'vh" y="'..(data.screenY)..'vh" width="'..(data.width)..'vh" height="'..(data.height)..'vh" />'
	-- Text
    if data.text ~= nil then
		svgTag = svgTag .. '<text style="'..fontSize..textAnchor..'" x="'..(btx*0.54)..'%" y="'..(bty)..'%">'..(data.text)..'</text>'
	end
    -- Custom SVG
	if data.svg ~= nil then
		svgTag = svgTag .. '<svg x="'..(data.screenX)..'vh" y="'..(data.screenY)..'vh">'..(data.svg)..'</svg>'
	end
	svgTag = svgTag .. '</g>\n'
	return svgTag
end

function text(data)
	if data == nil then data = {} end
	if data.x == nil then data.x = 0 end
	if data.y == nil then data.y = 0 end
	local dataString = dataString(data.dataParameters)
	local class = class(data.class)
    local svgTag = '<text'..class..''..dataString..' x="'..(data.x)..'%" y="'..(data.y)..'%">'..(data.text)..'</text>'
    if data.outlined then
        class = class('outlined')
        svgTag = svgTag .. '<text'..class..''..dataString..' x="'..(data.x)..'%" y="'..(data.y)..'%">'..(data.text)..'</text>'
    end
	return svgTag
end

-- Create a <rect> svg element
function rect(data)
	if data.x == nil then data.x = 0 end
	if data.y == nil then data.y = 0 end
	if data.width == nil then data.width = 3 end
	if data.height == nil then data.height = 3 end
	local dataString = dataString(data.dataParameters)
	local class = class(data.class)
	return '<rect'..class..''..dataString..' x="'..(data.x)..'vh" y="'..(data.y)..'vh" width="'..(data.width)..'vh" height="'..(data.height)..'vh" />'
end

function class(class)
	local classes = {}
	if class ~= nil then
		if type(class) == 'table' then
			table.add(classes, class)
		elseif type(class) == 'string' then
			table.insert(classes, class)
		end
	end
	local class = ''
	if #classes > 0 then
		class = ' class="'..(table.concat(classes, ' '))..'"'
	end
	return class
end

function dataString(dataParameters)
	local data = {}
	if dataParameters ~= nil then
		for dataName,dataValue in pairs(dataParameters) do
			local dataVal = dataValue
			if type(dataValue) == 'boolean' then
				dataVal = ternary(dataValue, 'true', 'false')
			end
			table.insert(data, ' data-'..dataName..'="'..dataVal..'"')
		end
		return table.concat(data, ' ')
	else
		return ''
	end
end


function gradient(id, data, vertical)
	if vertical == nil then vertical = false end
	local coords = ternary(vertical,
		'x1="0%" y1="0%" x2="0%" y2="100%"',
		'x1="0%" y1="0%" x2="100%" y2="0%"'
	)
	local def = '<linearGradient id="'..id..'"'..coords..'>'
	local stopKeys = table.keys(data)
	table.sort(stopKeys)
	for i,k in ipairs(stopKeys) do
		local stop = k
		local val = data[k]
		if type(val) == 'table' then
			val = data[k][1]
			local opacity = data[k][2]
			def = def .. '<stop offset="'..stop..'%" stop-color="'..val..'" stop-opacity="'..opacity..'" />'
		else
			def = def .. '<stop offset="'..stop..'%" stop-color="'..val..'" />'
		end
	end
	def = def .. '</linearGradient>'
	return def
end

function rx(v) if v == nil then return '' else return ' rx="'..v..'" ry="'..v..'"' end end