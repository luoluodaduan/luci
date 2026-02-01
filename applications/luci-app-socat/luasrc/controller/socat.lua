module("luci.controller.socat", package.seeall)

function index()
	if not require("nixio.fs").access("/usr/bin/socat") then
		return
	end

	entry({ "admin", "services", "socat" }, alias("admin", "services", "socat", "index"), _("Socat"), 100).dependent = true
	entry({ "admin", "services", "socat", "index" }, cbi("socat/index")).leaf = true
	entry({ "admin", "services", "socat", "config" }, cbi("socat/config")).leaf = true
	entry({ "admin", "services", "socat", "status" }, call("act_status")).leaf = true
end

function act_status()
	local sys = require("luci.sys")
	local json = require("luci.jsonc")
	local http = require("luci.http")
	local raw_stat = sys.exec('ubus call service list \'{"name": "socat"}\'')
	local data = json.parse(raw_stat)
	local response = { instances = {} }

	if data and data.socat and data.socat.instances then
		response.instances = data.socat.instances
	end

	http.prepare_content("application/json")
	http.write_json(response)
end
