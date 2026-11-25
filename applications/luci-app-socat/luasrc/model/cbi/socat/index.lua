local d = require("luci.dispatcher")
local uci = require("luci.model.uci").cursor()
local sys = require("luci.sys")
local json = require("luci.jsonc")

local raw_stat = sys.exec('ubus call service list \'{"name": "socat"}\'')
local socat_data = json.parse(raw_stat)
local instances = (socat_data and socat_data.socat and socat_data.socat.instances) or {}

m = Map("socat")
m.title = translate("Socat")
m.description = translate("Socat is a relay for bidirectional data transfer between two independent data channels.")

s = m:section(NamedSection, "global", "global")
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enable", translate("Enable"))
o.rmempty = false

s = m:section(TypedSection, "config", translate("Port Forwards"))
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"
s.extedit = d.build_url("admin", "services", "socat", "config", "%s")

function s.filter(self, section)
	return m:get(section, "protocol") == "port_forwards"
end

function s.create(self, section)
	math.randomseed(os.time())

	local alpha = "abcdef"
	local r_idx = math.random(1, #alpha)
	local first = alpha:sub(r_idx, r_idx)
	local raw_hex = sys.exec("dd if=/dev/urandom bs=4 count=1 2>/dev/null | hexdump -e '1/1 \"%02x\"'"):gsub("%s+", "")
	local rest = raw_hex:sub(1, 7)
	local short_id = first .. rest

	uci:section("socat", "config", short_id, {
		protocol = "port_forwards",
	})
	uci:commit("socat")

	luci.http.redirect(d.build_url("admin", "services", "socat", "config", short_id))
end

o = s:option(Flag, "enable", translate("Enable"))
o.width = "10%"
o.rmempty = false

o = s:option(DummyValue, "status", translate("Status"))
o.width = "10%"
o.rawhtml = true
o.cfgvalue = function(self, section)
	local enable = m:get(section, "enable")
	local port = m:get(section, "listen_port")

	if enable ~= "1" then
		return '<span style="color:gray">○ ' .. translate("Disabled") .. "</span>"
	end
	if not port or port == "" then
		return '<span style="color:orange">? ' .. translate("Not Configured") .. "</span>"
	end

	local is_running = false
	if instances[section] and instances[section].running then
		is_running = true
	end

	if is_running then
		return '<span style="color:green;font-weight:bold">● ' .. translate("正在运行") .. "</span>"
	else
		return '<span style="color:red;font-weight:bold">X ' .. translate("停止运行") .. "</span>"
	end
end

o = s:option(DummyValue, "remarks", translate("Remarks"))

o = s:option(DummyValue, "_listen_info", translate("Listen Protocol"))
o.cfgvalue = function(self, section)
	local family = m:get(section, "family") or ""
	local proto = (m:get(section, "proto") or "tcp"):upper()
	if proto == "SSL" then
		proto = "TLS"
	end
	local family_str = (family == "4" and "IPv4") or (family == "6" and "IPv6") or "IPv4/6"
	return string.format("%s-%s", family_str, proto)
end

o = s:option(DummyValue, "listen_port", translate("Listen port"))

o = s:option(DummyValue, "_dest_info", translate("Destination Protocol"))
o.cfgvalue = function(self, section)
	local dp = m:get(section, "dest_proto") or ""
	if dp == "" then
		return "-"
	end
	local proto = dp:match("^[a-z]+") or "tcp"
	local version = dp:match("%d$") or "4"
	return string.format("IPv%s-%s", version, proto:upper())
end

o = s:option(DummyValue, "dest_ip", translate("Destination address"))
o = s:option(DummyValue, "dest_port", translate("Destination port"))

o = s:option(DummyValue, "firewall_accept", translate("Firewall"))
o.width = "10%"
o.cfgvalue = function(self, section)
	local val = m:get(section, "firewall_accept") or "1"
	if val == "1" then
		return translate("Yes")
	else
		return translate("No")
	end
end

return m
