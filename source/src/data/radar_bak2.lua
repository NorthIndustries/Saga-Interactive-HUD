ping = (function()
local gCache = globals
ping = {}
ping.__index = ping
setmetatable(ping, self)
ping.list = {} -- table keyd on construct id
ping.list.__index = ping.list
ping.ord = {} -- ordered table of distance and pings
--ping.ord.__index = ping.ord
ping.wrk = {} -- abandoned constructs
ping.wrk.__index = ping.wrk
ping.stat = {} -- static/space
ping.dyn = {} -- dynamic
ping.str = "Data Pending..."
ping.wrkstr = "Data Pending..."
ping.statstr = "Data Pending..."	
ping.dynstr = "Data Pending..."		

function ping:new(contacts, id)

   self.list[id] = {}
   self.list[id].id = id
   self.list[id].d = contacts[gCache.radarFnMaps.getConstructDistance](id)
   self.list[id].n = contacts[gCache.radarFnMaps.getConstructName](id)
   self.list[id].s = contacts[gCache.radarFnMaps.getConstructSize](id)
   self.list[id].k = contacts[gCache.radarFnMaps.getConstructKind](id)
   self.list[id].t = contacts[gCache.radarFnMaps.getThreatRateFrom](id)
   self.list[id].w = contacts[gCache.radarFnMaps.isConstructAbandoned](id)
   
   	if self.list[id].w == 1 then
      table.insert(self.wrk,self.list[id])
   	end
   	if self.list[id].k == 4 or self.list[id].k == 6 or self.list[id].k == 7 then
		table.insert(self.stat,self.list[id])
	end
	if self.list[id].k == 5 then
		table.insert(self.dyn,self.list[id])
	end
   --local i = #self.ord + 1
   --self.ord[i] = self.list[id]
   --local priCap = math.min(#self.ord,20)
   --local testCap = 500

  -- if #self.ord < 1 then
   --   table.insert(self.ord,self.list[id])
  -- elseif #self.ord > testCap then
  --    table.insert(self.ord,self.list[id])
  -- elseif self.list[id].d > self.ord[priCap].d then
  --   table.insert(self.ord,self.list[id])
  -- else
 --    local f = function(a,b) return a.d < b.d end
  --   sins(self.ord,self.list[id],f)
  -- end
end

function ping:update(contacts, id)
   if self.list[id] then
      self.list[id].d = contacts[gCache.radarFnMaps.getConstructDistance](id)
      self.list[id].t = contacts[gCache.radarFnMaps.getThreatRateFrom](id)
   else
      self:new(contacts, id)
   end
end

function ping:sort()

   	if #self.ord > 1 then      
    	for i = 1, (#self.ord - 1) do
	 		if self.ord[i].d > self.ord[i+1].d then
	    		local foo = self.ord[i]
	    		self.ord[i] = self.ord[i+1]
	    		self.ord[i+1] = foo
	 		end
      	end
   	end
   	if #self.wrk > 1 then    
    	for i = 1, (#self.wrk - 1) do
	 		if self.wrk[i].d > self.wrk[i+1].d then
	    		local foo = self.wrk[i]
	    		self.wrk[i] = self.wrk[i+1]
	    		self.wrk[i+1] = foo
	 		end
      	end	
   	end
   	if #self.stat > 1 then
    	for i = 1, (#self.stat - 1) do
	 		if self.stat[i].d > self.stat[i+1].d then
	    		local foo = self.stat[i]
	    		self.stat[i] = self.stat[i+1]
	    		self.stat[i+1] = foo
	 		end
      	end
   	end	
   	if #self.dyn > 1 then     
    	for i = 1, (#self.dyn - 1) do
	 		if self.dyn[i].d > self.dyn[i+1].d then
	    		local foo = self.dyn[i]
	    		self.dyn[i] = self.dyn[i+1]
	    		self.dyn[i+1] = foo
	 		end
      	end
   	end
    return self		
end

 function ping:rdrsort()

    local contacts = activeRadar[globals.radarFnMaps.getConstructIds]()
    local ii = 0
    if contacts then
        for i, j in pairs(contacts) do
            ii = ii+1
            self:update(activeRadar, j)
            if ii > 30 then
            ii = 0
            coroutine.yield()
            end
        end
    end
    --ping:sort()
    local ocap = math.min(10,#self.ord)                
    self.str = [[--]]..#self.ord..[[-- </br>]]
    for i = 1, ocap do
        self.str = self.str..self.ord[i].id..[[ : ]]..self.ord[i].n..[[ ]]..utils.round(self.ord[i].d,2)..[[ </br>
        ]]
    end
	local wrkcap = math.min(10,#self.wrk)          
    self.wrkstr = [[--]]..#self.wrk..[[-- </br>]]
    for i = 1, wrkcap do
        self.wrkstr = self.wrkstr..self.wrk[i].id..[[ : ]]..self.wrk[i].n..[[ ]]..utils.round(self.wrk[i].d,2)..[[ </br>
        ]]
    end

	local statcap = math.min(10,#self.stat)   
    self.statstr = [[--]]..#self.stat..[[-- </br>]]
    for i = 1, statcap do
        self.statstr = self.statstr..self.stat[i].id..[[ : ]]..self.stat[i].n..[[ ]]..utils.round(self.stat[i].d,2)..[[ </br>
        ]]
    end
  
	local dyncap = math.min(10,#self.dyn)
    self.dynstr = [[--]]..#self.dyn..[[-- </br>]]
    for i = 1, dyncap do
        self.dynstr = self.dynstr..self.dyn[i].id..[[ : ]]..self.dyn[i].n..[[ ]]..utils.round(self.dyn[i].d,2)..[[ </br>
        ]]
    end
    return self
end

function ping:radarCo()
    local cont = coroutine.status(ping.rdrCo)
    if cont ~= "dead" then 
        local value, done = coroutine.resume(ping.rdrCo)
        if done then 
            --system.print("Done") 
        end
    elseif cont == "dead" then
        ping.rdrCo = coroutine.create(ping.rdrsort)
        local value, done = coroutine.resume(ping.rdrCo)
    end
end
ping.rdrCo = coroutine.create(ping.radarCo)


function ping:radarCleanCo()
    local cont = coroutine.status(ping.rdrClCo)
    if cont ~= "dead" then 
        local value, done = coroutine.resume(ping.rdrClCo)
        if done then 
            --system.print("Done") 
        end
    elseif cont == "dead" then
        ping.rdrClCo = coroutine.create(ping.radarClean)
        local value, done = coroutine.resume(ping.rdrClCo)
    end
end
ping.rdrClCo = coroutine.create(ping.radarCleanCo)

function ping:radarClean()
	local gCache = globals
    	--for i = 1, (#ping.list - 1) do
		--	if ping.list[i] == nil then
		--		table.remove(ping.list, i)
		--	end
      	--end
	if gCache.activeRadarRange ~= nil then
	if #self.wrk > 0 then      
    	for i = 1, (#self.wrk) do
			if activeRadar[gCache.radarFnMaps.getConstructDistance](self.wrk[i].id) == 0 then
				table.remove(self.wrk, i)
			end
      	end
		  coroutine.yield()
	end
	if #self.dyn > 0 then      
    	for i = 1, (#self.dyn) do
			if activeRadar[gCache.radarFnMaps.getConstructDistance](self.dyn[i].id) == 0 then
				table.remove(self.dyn, i)
			end
      	end
		  coroutine.yield()
   	end
	   if #self.stat > 0 then      
    	for i = 1, (#self.stat) do
			if activeRadar[gCache.radarFnMaps.getConstructDistance](self.stat[i].id) == 0 then
				table.remove(self.stat, i)
			end
      	end
		  coroutine.yield()
   	end
	end
    return self
end

return ping

end)()

function sins(t, v, f)
	f = f or function(a,b) return a < b end
	local s,m,e,x = 1,1,#t,0
	while s <= e do
	   m = math.floor((s+e)/2)
	   if f(v,t[m]) then
	  e,x = m-1,0
	   else
	  s,x = m+1,1
	   end
	end
	table.insert(t,(m+x),v)
	return (m+s) 
 end

	function onTimerRadar()
		ping.radarCleanCo()
	end

function onEventLeave(id)
	if ping.list[id] then
	ping.list[id] = nil
	end
end

function radarWidgetCreate()
    local _data = activeRadar.getWidgetData()--updateRadar(radarFilter)
    local _panel = system.createWidgetPanel("RADAR")
    local _widget = system.createWidget(_panel, "radar")
    radarDataID = system.createData(_data)
    system.addDataToWidget(radarDataID, _widget)
    return radarDataID
end