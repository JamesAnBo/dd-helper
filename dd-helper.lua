--[[
This addon requires drawdistance by atom0s (Link below).
Thanks to:
	atom0s for drawdistance: https://github.com/AshitaXI/Ashita-v4beta/tree/main/addons/drawdistance
	lin for minimap-helper: https://github.com/mousseng/xitools/tree/master/addons/minimap-helper
--]]

addon.name      = 'drawdistance-helper';
addon.author    = 'Aesk';
addon.version   = '1.0.0';
addon.desc      = 'Changes draw distance based on zone ID';
addon.link      = 'https://github.com/JamesAnBo/';

require('common');
local chat = require('chat');
local zones = require('ddh-zones')

ddh = T{
	normaldraw = 10, --Prefered standard drawdistance
	lowdraw = 1, --Prefered low draw distance.
	ptr = 0, --Leave this at 0.
};
local currentZone = nil;
local lowZones = zones.lowZones;

local function Contains(array, value)
    for i = 1, #array do
        if array[i] == value then
            return true
        end
    end

    return false
end

local function setDrawDistance()
	local drawdistance = ddh.normaldraw;

	if Contains(lowZones, currentZone) then
		drawdistance = ddh.lowdraw;
	end
	AshitaCore:GetChatManager():QueueCommand(1, '/drawdistance setmob '..drawdistance);
	AshitaCore:GetChatManager():QueueCommand(1, '/drawdistance setworld '..drawdistance);
end

local function getDrawdistance()
	local mptr = ashita.memory.read_uint32(ddh.ptr + 0x0F);
	local wptr = ashita.memory.read_uint32(ddh.ptr + 0x07);
	dworld = ashita.memory.read_float(wptr);
	dmob = ashita.memory.read_float(mptr);  
	PPrint('Draw distances: World - '..tostring(dworld)..' | Mob - '.. tostring(dmob));
end

--[[
* event: load
* desc : Event called when the addon is being loaded.
--]]
ashita.events.register('load', 'load_cb', function ()
    ddh.ptr = ashita.memory.find('FFXiMain.dll', 0, '8BC1487408D80D', 0, 0);
    if (ddh.ptr == 0) then
        error(chat.header('dd-helper'):append(chat.error('Error: Failed to locate draw distance pointer.')));
        return;
    end
	currentZone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0)
	setDrawDistance();
end);

--[[
* event: packet_in
* desc : Event called when the addon is processing incoming packets.
--]]
ashita.events.register('packet_in', 'packet_in_cb', function (e)
	if e.id == 0x000A then
		currentZone = struct.unpack('i2', e.data, 0x30 + 1)
		setDrawDistance();
		return;
	end
end);

--[[
* event: command
* desc : Event called when the addon is processing a command.
--]]
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/ddh') then
        return;
    end

    -- Block all related commands..
    e.blocked = true;
	
	PPrint('Zone ID: '..tostring(currentZone))
	getDrawdistance()
end);

function PPrint(txt)
	print(chat.header(addon.name):append(chat.message(txt)));
end

